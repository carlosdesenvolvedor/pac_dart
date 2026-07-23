import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/jogador_ranking.dart';

/// Placar público entre jogadores (coleção `ranking`, um doc por uid).
/// Todo logado LÊ o ranking inteiro; cada um só ESCREVE o próprio doc
/// (regras em firestore.rules).
abstract interface class RankingRepository {
  /// Soma [deltas] (pontos, teclas, erros, licoes…) no doc do jogador,
  /// gravando junto o apelido público.
  Future<void> somar(String uid, String apelido, Map<String, int> deltas);

  /// Guarda a melhor pontuação de um joguinho. Devolve se virou recorde.
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos);

  /// Melhores jogadores por pontos (o refinamento por critério é local).
  Future<List<JogadorRanking>> top({int limite = 100});
}

class FirestoreRankingRepository implements RankingRepository {
  final FirebaseFirestore _db;

  FirestoreRankingRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db.collection('ranking').doc(uid);

  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) {
    final dados = <String, dynamic>{
      'apelido': apelido,
      'atualizadoEm': FieldValue.serverTimestamp(),
      for (final e in deltas.entries)
        if (e.value != 0) e.key: FieldValue.increment(e.value),
    };
    return _doc(uid).set(dados, SetOptions(merge: true));
  }

  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async {
    final atual = (await _doc(uid).get()).data() ?? const {};
    final recordes = (atual['arcade'] as Map?) ?? const {};
    final melhor = ((recordes[jogo] as num?) ?? 0).toInt();
    if (pontos <= melhor) return false;
    // merge:true faz merge profundo do mapa — só a chave do jogo muda.
    await _doc(uid).set({
      'apelido': apelido,
      'arcade': {jogo: pontos},
    }, SetOptions(merge: true));
    return true;
  }

  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async {
    final snap = await _db
        .collection('ranking')
        .orderBy('pontos', descending: true)
        .limit(limite)
        .get();
    return [for (final d in snap.docs) JogadorRanking.deDados(d.id, d.data())];
  }
}
