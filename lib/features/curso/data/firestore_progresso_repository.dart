import 'package:cloud_firestore/cloud_firestore.dart';

import 'progresso_repository.dart';

/// Progresso na nuvem: um documento por usuário em `users/{uid}`.
/// Campos: concluidas (lista "t:l"), quizNotas (mapa "t:l"→int),
/// trilha, licao, recorde.
class FirestoreProgressoRepository implements ProgressoRepository {
  final String uid;
  final FirebaseFirestore _db;

  FirestoreProgressoRepository(this.uid, {FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc => _db.collection('users').doc(uid);

  Future<Map<String, dynamic>> _dados() async {
    final snap = await _doc.get();
    return snap.data() ?? const {};
  }

  @override
  Future<Set<String>> concluidas() async {
    final d = await _dados();
    return ((d['concluidas'] as List?)?.map((e) => e.toString()) ?? const <String>[]).toSet();
  }

  @override
  Future<void> marcarConcluida(String chave) =>
      _doc.set({'concluidas': FieldValue.arrayUnion([chave])}, SetOptions(merge: true));

  @override
  Future<(int, int)> posicao() async {
    final d = await _dados();
    return ((d['trilha'] as int?) ?? 0, (d['licao'] as int?) ?? 0);
  }

  @override
  Future<void> salvarPosicao(int trilha, int licao) =>
      _doc.set({'trilha': trilha, 'licao': licao}, SetOptions(merge: true));

  @override
  Future<Map<String, int>> quizNotas() async {
    final d = await _dados();
    final bruto = (d['quizNotas'] as Map?) ?? const {};
    return bruto.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
  }

  @override
  Future<void> salvarQuizNota(String chave, int acertos) async {
    final notas = await quizNotas();
    if ((notas[chave] ?? -1) >= acertos) return; // guarda só a melhor
    // merge:true faz merge profundo do mapa — só a chave muda.
    await _doc.set({
      'quizNotas': {chave: acertos}
    }, SetOptions(merge: true));
  }

  @override
  Future<int> recorde() async {
    final d = await _dados();
    return (d['recorde'] as int?) ?? 0;
  }

  @override
  Future<void> salvarRecorde(int score) async {
    if (score > await recorde()) {
      await _doc.set({'recorde': score}, SetOptions(merge: true));
    }
  }
}
