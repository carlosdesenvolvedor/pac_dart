import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/srs.dart';

/// Onde mora a revisão espaçada do inglês: chave da frase → cartão, mais o
/// histórico de revisões.
abstract interface class RevisaoRepository {
  Future<Map<String, CartaoSrs>> carregar();

  /// Grava vários cartões de uma vez (fim de lição, fim de revisão).
  Future<void> salvar(Map<String, CartaoSrs> cartoes);

  /// Acrescenta revisões ao histórico (nunca apaga).
  Future<void> registrarHistorico(List<EntradaHistorico> entradas);

  /// O histórico, do mais antigo ao mais novo; [desdeDia] corta o começo.
  Future<List<EntradaHistorico>> carregarHistorico({int? desdeDia});
}

/// Converte o que veio gravado (formato novo OU o antigo de Leitner) em cartões.
Map<String, CartaoSrs> _decodificar(Map<dynamic, dynamic> bruto) {
  final m = <String, CartaoSrs>{};
  for (final e in bruto.entries) {
    final c = CartaoSrs.decodificar(e.value);
    if (c != null) m['${e.key}'] = c;
  }
  return m;
}

List<EntradaHistorico> _entradas(Iterable<Object?> brutas, int? desdeDia) =>
    [for (final b in brutas) ?EntradaHistorico.decodificar(b)]
        .where((e) => desdeDia == null || e.dia >= desdeDia)
        .toList()
      ..sort((a, b) => a.dia.compareTo(b.dia));

/// No aparelho (offline, testes, probe). Lê também o mapa antigo `en_revisao`
/// (caixas de Leitner), convertido na hora; o que já foi revisado no motor novo
/// (`en_srs`) prevalece.
class LocalRevisaoRepository implements RevisaoRepository {
  static const _chave = 'en_srs';
  static const _legado = 'en_revisao';
  static const _chaveHistorico = 'en_srs_log';

  /// O histórico local guarda só as últimas revisões (o da nuvem é completo).
  static const maxHistorico = 5000;

  Map<String, dynamic> _mapa(SharedPreferences p, String chave) {
    try {
      final v = jsonDecode(p.getString(chave) ?? '{}');
      return v is Map<String, dynamic> ? v : {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<Map<String, CartaoSrs>> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      return {..._decodificar(_mapa(p, _legado)), ..._decodificar(_mapa(p, _chave))};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> salvar(Map<String, CartaoSrs> cartoes) async {
    if (cartoes.isEmpty) return;
    try {
      final p = await SharedPreferences.getInstance();
      final atual = _mapa(p, _chave);
      for (final e in cartoes.entries) {
        atual[e.key] = e.value.codificar();
      }
      await p.setString(_chave, jsonEncode(atual));
    } catch (_) {}
  }

  @override
  Future<void> registrarHistorico(List<EntradaHistorico> entradas) async {
    if (entradas.isEmpty) return;
    try {
      final p = await SharedPreferences.getInstance();
      final todas = [...(p.getStringList(_chaveHistorico) ?? const <String>[]), for (final e in entradas) e.codificar()];
      await p.setStringList(_chaveHistorico, todas.length > maxHistorico ? todas.sublist(todas.length - maxHistorico) : todas);
    } catch (_) {}
  }

  @override
  Future<List<EntradaHistorico>> carregarHistorico({int? desdeDia}) async {
    try {
      final p = await SharedPreferences.getInstance();
      return _entradas(p.getStringList(_chaveHistorico) ?? const [], desdeDia);
    } catch (_) {
      return [];
    }
  }
}

/// Na nuvem, em BLOCOS: `users/{uid}/srs/b00…b15` com os cartões repartidos
/// pela chave da frase (um mapa `c` por bloco) e `users/{uid}/srs_log/AAAA-MM`
/// com o histórico do mês. Abrir o app custa ~17 leituras, não uma por frase, e
/// nenhum documento passa de ~50 KB (o antigo mapa dentro de `users/{uid}`
/// estourava o limite de 1 MiB com mais cartões).
///
/// Migração: sem o documento `_meta`, o mapa antigo `en_revisao` do
/// `users/{uid}` é convertido e gravado de uma vez (lote atômico, junto com o
/// `_meta`). O mapa antigo NÃO é apagado — dá para voltar à versão anterior.
class FirestoreRevisaoRepository implements RevisaoRepository {
  /// Quantos blocos de cartões (fixo: a chave decide o bloco, sem reorganizar).
  static const blocos = 16;
  static const _meta = '_meta';

  final String uid;
  final FirebaseFirestore _db;

  FirestoreRevisaoRepository(this.uid, {FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc => _db.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> get _colBlocos => _doc.collection('srs');
  CollectionReference<Map<String, dynamic>> get _colHistorico => _doc.collection('srs_log');

  /// O bloco (`b00`…`b15`) de uma frase — função só da chave, para sempre (NÃO
  /// mudar: trocaria o bloco dos cartões já gravados). Só usa números que cabem
  /// no `double` do JS, então dá o mesmo resultado na web e no celular; o módulo
  /// primo espalha bem frases parecidas ("I like apples." / "I like pears.").
  static String idDoBloco(String chave) {
    var h = 0;
    for (final c in chave.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return 'b${((h % 65521) % blocos).toString().padLeft(2, '0')}';
  }

  @override
  Future<Map<String, CartaoSrs>> carregar() async {
    final snap = await _colBlocos.get();
    var migrado = false;
    final cartoes = <String, CartaoSrs>{};
    for (final d in snap.docs) {
      if (d.id == _meta) {
        migrado = true;
        continue;
      }
      final c = d.data()['c'];
      if (c is Map) cartoes.addAll(_decodificar(c));
    }
    if (migrado) return cartoes;

    final legado = (await _doc.get()).data()?['en_revisao'];
    if (legado is Map && legado.isNotEmpty) {
      // o que já foi revisado no motor novo (sem `_meta` ainda) prevalece
      final todos = {..._decodificar(legado), ...cartoes};
      unawaited(_gravar(todos, comMeta: true).then((_) {}, onError: (_) {}));
      return todos;
    }
    unawaited(_colBlocos.doc(_meta).set({'migrado': true}).then((_) {}, onError: (_) {}));
    return cartoes;
  }

  @override
  Future<void> salvar(Map<String, CartaoSrs> cartoes) async {
    if (cartoes.isEmpty) return;
    await _gravar(cartoes, comMeta: false);
  }

  /// Um lote só: ou entram todos os blocos (e o `_meta`) ou nenhum. `merge`
  /// é profundo no mapa `c` — só as chaves enviadas mudam.
  Future<void> _gravar(Map<String, CartaoSrs> cartoes, {required bool comMeta}) {
    final porBloco = <String, Map<String, String>>{};
    for (final e in cartoes.entries) {
      (porBloco[idDoBloco(e.key)] ??= {})[e.key] = e.value.codificar();
    }
    final lote = _db.batch();
    porBloco.forEach((id, c) => lote.set(_colBlocos.doc(id), {'c': c}, SetOptions(merge: true)));
    if (comMeta) lote.set(_colBlocos.doc(_meta), {'migrado': true});
    return lote.commit();
  }

  static String _mes(int dia) {
    final d = DateTime.utc(1970, 1, 1 + dia);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> registrarHistorico(List<EntradaHistorico> entradas) async {
    if (entradas.isEmpty) return;
    final porMes = <String, List<String>>{};
    for (final e in entradas) {
      (porMes[_mes(e.dia)] ??= []).add(e.codificar());
    }
    final lote = _db.batch();
    porMes.forEach((mes, linhas) =>
        lote.set(_colHistorico.doc(mes), {'r': FieldValue.arrayUnion(linhas)}, SetOptions(merge: true)));
    await lote.commit();
  }

  @override
  Future<List<EntradaHistorico>> carregarHistorico({int? desdeDia}) async {
    final snap = await _colHistorico.get();
    return _entradas([
      for (final d in snap.docs)
        if (d.data()['r'] case final List r) ...r,
    ], desdeDia);
  }
}
