import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/linguagem/linguagem.dart';
import '../domain/plano_treino.dart';

/// Onde mora o "⚡ Treino do dia" de um curso (o plano de hoje e o andamento).
///
/// Mesmo desenho do `habito_repository.dart` (plano FASE-9 §6.1).
abstract interface class TreinoDiaRepository {
  /// Nunca lança: nada gravado ou dado estragado → null.
  Future<PlanoTreino?> carregar();

  /// Termina quando o aparelho gravou; a nuvem não é esperada (offline ela só termina quando o
  /// servidor confirma) e o erro dela é engolido. Se lançar, o cubit engole.
  Future<void> salvar(PlanoTreino p);
}

/// No aparelho: um texto JSON em `treino_dia_v1:{curso}` (com [uid]: `treino_dia_v1:{uid}:{curso}`).
class LocalTreinoDiaRepository implements TreinoDiaRepository {
  static const chaveBase = 'treino_dia_v1';

  final String? uid;
  final String curso;
  LocalTreinoDiaRepository({this.uid, required this.curso});

  String get chave => uid == null ? '$chaveBase:$curso' : '$chaveBase:$uid:$curso';

  @override
  Future<PlanoTreino?> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      final texto = p.getString(chave);
      return texto == null ? null : PlanoTreino.fromJson(jsonDecode(texto));
    } catch (_) {
      // JSON corrompido ou sem armazenamento: plano novo, sem derrubar a tela
      return null;
    }
  }

  @override
  Future<void> salvar(PlanoTreino plano) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(chave, jsonEncode(plano.toJson()));
    } catch (_) {}
  }
}

/// Em memória (testes).
class MemoriaTreinoDiaRepository implements TreinoDiaRepository {
  PlanoTreino? plano;

  /// Quantas vezes [salvar] foi chamado.
  int gravacoes = 0;

  MemoriaTreinoDiaRepository([PlanoTreino? inicial]) : plano = inicial;

  @override
  Future<PlanoTreino?> carregar() async => plano;

  @override
  Future<void> salvar(PlanoTreino p) async {
    gravacoes++;
    plano = p;
  }
}

/// Na nuvem: o campo `{prefixo}treino_dia` do próprio `users/{uid}` ('treino_dia', 'cs_treino_dia',
/// 'en_treino_dia') — as regras que já existem cobrem. Cada aparelho guarda também uma cópia local, e
/// o que estiver adiantado de um lado ou do outro prevalece ([PlanoTreino.mesclar]).
class FirestoreTreinoDiaRepository implements TreinoDiaRepository {
  final String uid;
  final Linguagem linguagem;
  final FirebaseFirestore? _dbInjetado;
  final TreinoDiaRepository _local;

  FirestoreTreinoDiaRepository(this.uid,
      {required this.linguagem, FirebaseFirestore? db, TreinoDiaRepository? local})
      : _dbInjetado = db,
        _local = local ?? LocalTreinoDiaRepository(uid: uid, curso: linguagem.id);

  /// O campo deste curso em `users/{uid}`.
  String get campo => '${linguagem.prefixoProgresso}treino_dia';

  DocumentReference<Map<String, dynamic>> get _doc =>
      (_dbInjetado ?? FirebaseFirestore.instance).collection('users').doc(uid);

  /// Quanto a leitura da nuvem pode esperar antes de valer só o aparelho (plano FASE-9 §9.1).
  static const prazoLeitura = Duration(seconds: 10);

  /// Mescla a cópia local com a da nuvem e deixa os dois lados iguais. Sem rede (ou nuvem lenta
  /// além de [prazoLeitura]), vale o aparelho.
  @override
  Future<PlanoTreino?> carregar() async {
    final local = await _local.carregar();
    PlanoTreino? remoto;
    try {
      remoto = PlanoTreino.fromJson((await _doc.get().timeout(prazoLeitura)).data()?[campo]);
    } catch (_) {
      return local;
    }
    final junto = PlanoTreino.mesclar(local, remoto);
    if (junto == null) return null;
    // sem esperar a nuvem: offline a escrita só termina quando o servidor confirma
    if (junto != remoto) _enviarSemEsperar(junto);
    if (junto != local) await _local.salvar(junto);
    return junto;
  }

  /// O aparelho é esperado; a nuvem vai sem esperar. Offline uma escrita do Firestore só termina
  /// quando o servidor confirma — esperá-la travaria a fila do cubit e as mudanças seguintes nunca
  /// chegariam ao aparelho. O próprio Firestore mantém as escritas pendentes em ordem.
  @override
  Future<void> salvar(PlanoTreino p) async {
    await _local.salvar(p);
    _enviarSemEsperar(p);
  }

  PlanoTreino? _aEnviar;
  Future<void>? _enviando;

  /// Completa quando a fila da nuvem esvazia (testes).
  Future<void> get envios => _enviando ?? Future<void>.value();

  /// A nuvem em ordem e sem empilhar (o mesmo "a mais nova vence" do cubit): enquanto uma escrita
  /// espera o servidor, só o plano mais novo segue depois. Erro é engolido — o aparelho já guardou.
  void _enviarSemEsperar(PlanoTreino p) {
    _aEnviar = p;
    _enviando ??= _esvaziarNuvem();
  }

  Future<void> _esvaziarNuvem() async {
    try {
      while (_aEnviar != null) {
        final vez = _aEnviar!;
        _aEnviar = null;
        try {
          await _enviar(vez);
        } catch (_) {}
      }
    } finally {
      _enviando = null;
    }
  }

  /// `update({campo: …})`: o campo inteiro é trocado (nenhuma chave velha sobrevive dentro dele) e o
  /// resto de `users/{uid}` (hábito, concluídas…) fica como está. Conta sem documento ainda: `set`
  /// com `merge` (não há o que apagar).
  ///
  /// Não é `set(…, SetOptions(mergeFields: [campo]))`, que no Firestore de verdade faria o mesmo,
  /// porque o `FakeFirebaseFirestore` dos testes ignora `mergeFields` e apaga o documento inteiro.
  /// Segunda trava: [PlanoTreino.toJson] escreve SEMPRE todas as chaves de cima, então nem uma
  /// mescla profunda deixaria um `x: true` de ontem para trás.
  Future<void> _enviar(PlanoTreino p) async {
    final dados = {campo: p.toJson()};
    try {
      await _doc.update(dados);
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') rethrow;
      await _doc.set(dados, SetOptions(merge: true));
    }
  }
}
