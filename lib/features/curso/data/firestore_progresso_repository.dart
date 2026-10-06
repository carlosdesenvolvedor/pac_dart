import 'package:cloud_firestore/cloud_firestore.dart';

import 'progresso_repository.dart';

/// Progresso na nuvem: um documento por usuário em `users/{uid}`.
/// Campos: concluidas (lista "t:l"), quizNotas (mapa "t:l"→int),
/// projetos (lista "proj:t:i"/"master:i"), trilha, licao, recorde.
///
/// Cada vertente usa um [prefixo] nos campos do MESMO documento: o Dart fica
/// sem prefixo (os campos de sempre) e o C# usa `cs_` (cs_concluidas,
/// cs_quizNotas…). As regras do Firestore valem por documento, então campo
/// novo não precisa de deploy de regras.
class FirestoreProgressoRepository implements ProgressoRepository {
  final String uid;
  final String prefixo;
  final FirebaseFirestore _db;

  FirestoreProgressoRepository(this.uid, {FirebaseFirestore? db, this.prefixo = ''})
      : _db = db ?? FirebaseFirestore.instance;

  String _c(String campo) => '$prefixo$campo';

  DocumentReference<Map<String, dynamic>> get _doc => _db.collection('users').doc(uid);

  Future<Map<String, dynamic>> _dados() async {
    final snap = await _doc.get();
    return snap.data() ?? const {};
  }

  @override
  Future<Set<String>> concluidas() async {
    final d = await _dados();
    return ((d[_c('concluidas')] as List?)?.map((e) => e.toString()) ?? const <String>[]).toSet();
  }

  @override
  Future<void> marcarConcluida(String chave) =>
      _doc.set({_c('concluidas'): FieldValue.arrayUnion([chave])}, SetOptions(merge: true));

  @override
  Future<(int, int)> posicao() async {
    final d = await _dados();
    return ((d[_c('trilha')] as int?) ?? 0, (d[_c('licao')] as int?) ?? 0);
  }

  @override
  Future<void> salvarPosicao(int trilha, int licao) =>
      _doc.set({_c('trilha'): trilha, _c('licao'): licao}, SetOptions(merge: true));

  @override
  Future<Map<String, int>> quizNotas() async {
    final d = await _dados();
    final bruto = (d[_c('quizNotas')] as Map?) ?? const {};
    return bruto.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
  }

  @override
  Future<void> salvarQuizNota(String chave, int acertos) async {
    final notas = await quizNotas();
    if ((notas[chave] ?? -1) >= acertos) return; // guarda só a melhor
    // merge:true faz merge profundo do mapa — só a chave muda.
    await _doc.set({
      _c('quizNotas'): {chave: acertos}
    }, SetOptions(merge: true));
  }

  @override
  Future<Set<String>> projetosFeitos() async {
    final d = await _dados();
    return ((d[_c('projetos')] as List?)?.map((e) => e.toString()) ?? const <String>[]).toSet();
  }

  @override
  Future<void> marcarProjetoFeito(String chave) =>
      _doc.set({_c('projetos'): FieldValue.arrayUnion([chave])}, SetOptions(merge: true));

  @override
  Future<int> recorde() async {
    final d = await _dados();
    return (d[_c('recorde')] as int?) ?? 0;
  }

  @override
  Future<void> salvarRecorde(int score) async {
    if (score > await recorde()) {
      await _doc.set({_c('recorde'): score}, SetOptions(merge: true));
    }
  }
}
