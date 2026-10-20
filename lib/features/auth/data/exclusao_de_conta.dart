import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_repository.dart' show AuthException;

/// Os três passos de excluir a conta (exigência da Apple e do Google), separados para
/// que a ordem seja do cubit e o Firebase fique de fora dos testes.
abstract interface class ExclusaoDeConta {
  /// Confirma a identidade com a senha (o Firebase só deixa excluir quem entrou há pouco).
  Future<void> reautenticar(String senha);

  /// Apaga o que o app guarda do usuário no Firestore.
  Future<void> apagarDados(String uid);

  /// Apaga o login (Firebase Auth).
  Future<void> excluirLogin();
}

class FirebaseExclusaoDeConta implements ExclusaoDeConta {
  final FirebaseAuth _auth;
  final FirebaseFirestore? _db;

  FirebaseExclusaoDeConta(this._auth, {FirebaseFirestore? db}) : _db = db;

  @override
  Future<void> reautenticar(String senha) async {
    final u = _auth.currentUser;
    final email = u?.email;
    if (u == null || email == null) throw const AuthException('Entre na conta primeiro.');
    try {
      await u.reauthenticateWithCredential(EmailAuthProvider.credential(email: email, password: senha));
    } on FirebaseAuthException catch (e) {
      throw AuthException(switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'Senha incorreta.',
        'too-many-requests' => 'Muitas tentativas. Tente de novo em instantes.',
        'network-request-failed' => 'Sem conexão. Verifique sua internet.',
        _ => 'Não deu certo (${e.code}). Tente novamente.',
      });
    }
  }

  /// `users/{uid}` (progresso), as subcoleções da revisão do inglês e `ranking/{uid}`
  /// num lote só: ou sai tudo ou nada.
  @override
  Future<void> apagarDados(String uid) => apagarDadosDoUsuario(_db ?? FirebaseFirestore.instance, uid);

  @override
  Future<void> excluirLogin() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code == 'requires-recent-login'
          ? 'Por segurança, entre de novo e tente excluir logo em seguida.'
          : 'Não deu certo (${e.code}). Tente novamente.');
    }
  }
}

/// Apagar `users/{uid}` NÃO apaga as subcoleções: os cartões (`srs`) e o histórico
/// (`srs_log`) da revisão do inglês, os textos (`textos`) e o banco de palavras (`palavras`) precisam sair junto — a Apple e o Google exigem
/// que a exclusão leve tudo (inclusive os áudios que o aluno anexou, achados pelo índice).
/// Em lotes de até 500 operações: no uso normal cabe um só (16 blocos + `_meta` + 1 doc por mês).
Future<void> apagarDadosDoUsuario(FirebaseFirestore db, String uid) async {
  final doc = db.collection('users').doc(uid);
  final subdocs = [
    ...(await doc.collection('srs').get()).docs.map((d) => d.reference),
    ...(await doc.collection('srs_log').get()).docs.map((d) => d.reference),
    // os textos colados que viraram lições e o banco de palavras do inglês
    ...(await doc.collection('textos').get()).docs.map((d) => d.reference),
    ...(await doc.collection('palavras').get()).docs.map((d) => d.reference),
  ];
  // os áudios do aluno: lê só o ÍNDICE (listar a coleção baixaria todos os arquivos)
  final audios = doc.collection('audio');
  final indice = (await audios.doc('_idx').get()).data()?['i'];
  if (indice is Map) subdocs.addAll([for (final chave in indice.keys) audios.doc('$chave')]);
  subdocs.add(audios.doc('_idx'));
  // o lote aceita 500 operações: as 2 primeiras são do usuário e do ranking
  for (var i = 0; i < subdocs.length || i == 0; i += 498) {
    final lote = db.batch();
    if (i == 0) {
      lote
        ..delete(doc)
        ..delete(db.collection('ranking').doc(uid));
    }
    for (final ref in subdocs.skip(i).take(498)) {
      lote.delete(ref);
    }
    await lote.commit();
  }
}
