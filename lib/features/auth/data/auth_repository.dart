import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';

/// Erro de autenticação já traduzido para o usuário.
class AuthException implements Exception {
  final String mensagem;
  const AuthException(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Envolve o FirebaseAuth expondo um contrato simples em português.
class AuthRepository {
  final FirebaseAuth _auth;
  AuthRepository(this._auth);

  AppUser? _map(User? u) => u == null ? null : AppUser(uid: u.uid, email: u.email);

  /// Emite o usuário atual sempre que o login muda (entrar/sair).
  Stream<AppUser?> get mudancas => _auth.authStateChanges().map(_map);

  AppUser? get atual => _map(_auth.currentUser);

  Future<void> entrar(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: senha);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_traduz(e.code));
    }
  }

  Future<void> cadastrar(String email, String senha) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email.trim(), password: senha);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_traduz(e.code));
    }
  }

  Future<void> redefinirSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_traduz(e.code));
    }
  }

  Future<void> sair() => _auth.signOut();

  String _traduz(String code) => switch (code) {
        'invalid-email' => 'E-mail inválido.',
        'user-disabled' => 'Esta conta foi desativada.',
        'user-not-found' => 'Não achamos nenhuma conta com esse e-mail.',
        'wrong-password' || 'invalid-credential' => 'E-mail ou senha incorretos.',
        'email-already-in-use' => 'Já existe uma conta com esse e-mail.',
        'weak-password' => 'A senha é muito fraca (use 6+ caracteres).',
        'operation-not-allowed' => 'Login por e-mail/senha não está habilitado no Firebase.',
        'too-many-requests' => 'Muitas tentativas. Tente de novo em instantes.',
        'network-request-failed' => 'Sem conexão. Verifique sua internet.',
        _ => 'Não deu certo ($code). Tente novamente.',
      };
}
