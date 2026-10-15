import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/texto_salvo.dart';

/// Onde moram os textos que a pessoa colou e viraram lições.
abstract interface class TextosRepository {
  /// Do mais novo para o mais antigo.
  Future<List<TextoSalvo>> carregar();
  Future<void> salvar(TextoSalvo texto);
  Future<void> apagar(String id);
}

/// No aparelho/navegador (shared_preferences), uma lista por conta. Nunca
/// lança: sem armazenamento ou com dado quebrado, a lista só vem vazia.
class LocalTextosRepository implements TextosRepository {
  final String uid;
  LocalTextosRepository(this.uid);

  String get _chave => 'en_textos_$uid';

  @override
  Future<List<TextoSalvo>> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      final bruto = p.getString(_chave);
      if (bruto == null) return const [];
      final lista = jsonDecode(bruto);
      if (lista is! List) return const [];
      return [for (final e in lista) ?TextoSalvo.fromJson(e)]..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    } catch (_) {
      return const [];
    }
  }

  Future<void> _gravar(List<TextoSalvo> textos) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chave, jsonEncode([for (final t in textos) t.toJson()]));
    } catch (_) {}
  }

  @override
  Future<void> salvar(TextoSalvo texto) async {
    final todos = (await carregar()).where((t) => t.id != texto.id).toList()..add(texto);
    await _gravar(todos);
  }

  @override
  Future<void> apagar(String id) async {
    await _gravar((await carregar()).where((t) => t.id != id).toList());
  }

  /// Troca a lista inteira (é o espelho da nuvem, ver [FirestoreTextosRepository]).
  Future<void> gravarTodos(List<TextoSalvo> textos) => _gravar(textos);
}

/// O que falta mandar para a nuvem neste aparelho (guardado em `en_textos_sync_{uid}`).
class _Sync {
  /// Já subiu, uma vez, o que existia só neste aparelho. Depois disso a nuvem manda.
  bool migrado;
  final Set<String> salvar, apagar;
  _Sync({this.migrado = false, Set<String>? salvar, Set<String>? apagar})
      : salvar = salvar ?? {},
        apagar = apagar ?? {};
}

/// Na nuvem, com espelho no aparelho: cada texto é um documento em `users/{uid}/textos/{id}`, e a conta
/// inteira vê os mesmos textos em qualquer aparelho. O espelho (o mesmo de [LocalTextosRepository]) deixa o
/// app funcionar sem rede e é de onde saem os textos que a pessoa criou ANTES de a nuvem existir.
///
/// - Salvar e apagar valem no aparelho na hora (a lição aparece sem esperar a rede) e vão para a nuvem em
///   seguida. Se a nuvem falhar (sem rede, regras ainda não publicadas), a operação fica anotada como
///   pendente e é refeita na próxima vez que a lista for carregada: nunca se perde um texto.
/// - Carregar lê a nuvem, aplica o que está pendente e devolve a lista mesclada (e a guarda no espelho).
/// - Na PRIMEIRA vez neste aparelho, o que só existe nele sobe. Depois disso a nuvem manda: um texto que
///   sumiu de lá (apagado em outro aparelho) sai do espelho e não volta.
class FirestoreTextosRepository implements TextosRepository {
  /// Acima disto o documento não cabe no limite de 1 MiB do Firestore: esse texto fica só no aparelho.
  static const maxBytes = 900000;

  final String uid;
  final FirebaseFirestore _db;
  final LocalTextosRepository _local;
  final Duration _espera;

  FirestoreTextosRepository(this.uid, {FirebaseFirestore? db, LocalTextosRepository? local, Duration espera = const Duration(seconds: 6)})
      : _db = db ?? FirebaseFirestore.instance,
        _local = local ?? LocalTextosRepository(uid),
        _espera = espera;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users').doc(uid).collection('textos');
  String get _chaveSync => 'en_textos_sync_$uid';

  /// Sobe a cada salvar/apagar; quem muda os textos enquanto uma rodada de envio está no ar faz a rodada
  /// deixar as pendências como estão (a próxima as refaz: gravar duas vezes o mesmo texto não custa nada).
  int _n = 0;
  Future<void> _fila = Future.value();
  Future<void> _envio = Future.value();

  /// O envio em andamento (os testes esperam por ele; o app não precisa).
  @visibleForTesting
  Future<void> get enviado => _envio;

  static bool _cabe(TextoSalvo t) => utf8.encode(jsonEncode(t.toJson())).length <= maxBytes;

  Future<_Sync> _lerSync() async {
    try {
      final bruto = (await SharedPreferences.getInstance()).getString(_chaveSync);
      final j = bruto == null ? null : jsonDecode(bruto);
      if (j is! Map) return _Sync();
      Set<String> ids(Object? v) => v is List ? {for (final e in v) if (e is String) e} : {};
      return _Sync(migrado: j['m'] == true, salvar: ids(j['s']), apagar: ids(j['a']));
    } catch (_) {
      return _Sync();
    }
  }

  /// Lê, muda e grava o estado, uma operação de cada vez.
  Future<void> _mutar(void Function(_Sync s) mudar) {
    final c = _fila.then((_) async {
      final s = await _lerSync();
      mudar(s);
      try {
        final p = await SharedPreferences.getInstance();
        await p.setString(_chaveSync, jsonEncode({'m': s.migrado, 's': s.salvar.toList(), 'a': s.apagar.toList()}));
      } catch (_) {}
    });
    _fila = c.catchError((_) {});
    return c;
  }

  /// Manda para a nuvem; devolve os ids que ela confirmou (nada aqui lança).
  Future<Set<String>> _empurrar(Iterable<TextoSalvo> subir, Iterable<String> apagar) async {
    final ok = <String>{};
    Future<void> um(String id, Future<void> Function() acao) async {
      try {
        await acao().timeout(_espera);
        ok.add(id);
      } catch (e) {
        debugPrint('TEXTOS $id não foi para a nuvem: $e');
      }
    }

    await Future.wait([
      for (final t in subir) um(t.id, () => _col.doc(t.id).set(t.toJson())),
      for (final id in apagar) um(id, () => _col.doc(id).delete()),
    ]);
    return ok;
  }

  @override
  Future<List<TextoSalvo>> carregar() async {
    final n0 = _n;
    final locais = await _local.carregar();
    final nuvem = <String, TextoSalvo>{};
    try {
      final snap = await _col.get().timeout(_espera);
      for (final d in snap.docs) {
        final t = TextoSalvo.fromJson(d.data());
        if (t != null) nuvem[t.id] = t;
      }
    } catch (e) {
      debugPrint('TEXTOS sem a nuvem, valem os do aparelho: $e');
      return locais;
    }

    final s = await _lerSync();
    final lista = {...nuvem};
    final subir = <String, TextoSalvo>{};
    for (final t in locais) {
      final naNuvem = nuvem[t.id];
      if (!_cabe(t)) {
        lista[t.id] = t; // grande demais para a nuvem: fica só aqui
      } else if (s.salvar.contains(t.id)) {
        lista[t.id] = subir[t.id] = t; // mexido aqui e ainda não enviado: vale o do aparelho
      } else if (!s.migrado) {
        // primeira vez neste aparelho: o que só existe aqui sobe; o mesmo id nos dois lados une as frases
        final u = naNuvem == null ? t : _unir(naNuvem, t);
        lista[t.id] = u;
        if (u != naNuvem) subir[t.id] = u;
      }
      // migrado e sem pendência: a nuvem manda (o texto foi apagado em outro aparelho)
    }
    for (final id in s.apagar) {
      lista.remove(id);
    }

    final ok = await _empurrar(subir.values, s.apagar);
    final subiuTudo = subir.keys.every(ok.contains);
    await _mutar((x) {
      if (_n != n0) return; // mexeram nos textos durante a leitura: a próxima rodada refaz
      x.salvar.removeAll(ok);
      x.apagar.removeAll(ok);
      if (subiuTudo) x.migrado = true;
    });

    final ordenada = lista.values.toList()..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    if (_n == n0) await _local.gravarTodos(ordenada);
    return ordenada;
  }

  /// Os dois lados têm o mesmo texto (só acontece com "Meus cartões", de id fixo): a união das frases.
  static TextoSalvo _unir(TextoSalvo nuvem, TextoSalvo local) {
    final tem = {for (final f in nuvem.frases) f.en.toLowerCase()};
    final extras = [for (final f in local.frases) if (tem.add(f.en.toLowerCase())) f];
    return extras.isEmpty ? nuvem : nuvem.comFrases([...nuvem.frases, ...extras]);
  }

  @override
  Future<void> salvar(TextoSalvo texto) async {
    _n++;
    await _local.salvar(texto);
    if (_cabe(texto)) {
      await _mutar((s) {
        s.apagar.remove(texto.id);
        s.salvar.add(texto.id);
      });
      _envio = _enviar();
    }
  }

  @override
  Future<void> apagar(String id) async {
    _n++;
    await _local.apagar(id);
    await _mutar((s) {
      s.salvar.remove(id);
      s.apagar.add(id);
    });
    _envio = _enviar();
  }

  /// Manda o que está pendente (a rede fica fora da fila: um envio lento não trava quem carrega a lista).
  Future<void> _enviar() async {
    final n0 = _n;
    final s = await _lerSync();
    if (s.salvar.isEmpty && s.apagar.isEmpty) return;
    final locais = {for (final t in await _local.carregar()) t.id: t};
    final ok = await _empurrar([for (final id in s.salvar) ?locais[id]], s.apagar);
    await _mutar((x) {
      if (_n != n0) return;
      x.salvar.removeWhere((id) => ok.contains(id) || !locais.containsKey(id));
      x.apagar.removeAll(ok);
    });
  }
}
