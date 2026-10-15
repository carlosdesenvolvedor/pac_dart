import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../data/exclusao_de_conta.dart';
import '../domain/app_user.dart';

enum AuthStatus { desconhecido, autenticado, naoAutenticado }

class AuthState extends Equatable {
  final AuthStatus status;
  final AppUser? user;

  const AuthState._(this.status, this.user);
  const AuthState.desconhecido() : this._(AuthStatus.desconhecido, null);
  const AuthState.naoAutenticado() : this._(AuthStatus.naoAutenticado, null);
  const AuthState.autenticado(AppUser user) : this._(AuthStatus.autenticado, user);

  @override
  List<Object?> get props => [status, user];
}

/// Acompanha o estado de login. As ações do formulário (entrar/cadastrar)
/// lançam [AuthException] em caso de erro — a tela de login trata isso.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repo;

  /// Os passos da exclusão de conta (null = o app não oferece excluir, como nos testes).
  final ExclusaoDeConta? exclusao;
  StreamSubscription<AppUser?>? _sub;

  AuthCubit(this.repo, {this.exclusao}) : super(const AuthState.desconhecido()) {
    _sub = repo.mudancas.listen((u) {
      emit(u == null ? const AuthState.naoAutenticado() : AuthState.autenticado(u));
    });
  }

  Future<void> entrar(String email, String senha) => repo.entrar(email, senha);
  Future<void> cadastrar(String email, String senha) => repo.cadastrar(email, senha);
  Future<void> redefinirSenha(String email) => repo.redefinirSenha(email);
  Future<void> sair() => repo.sair();

  /// Exclui a conta de vez (exigência da Apple e do Google): confirma a senha, apaga
  /// os dados do usuário e, por último, o login — nessa ordem, para não sobrar conta
  /// sem dados nem dados sem dono. Erros viram [AuthException]. Ao fim o login muda
  /// sozinho (stream) e o app volta para a tela de entrada.
  Future<void> excluirConta(String senha) async {
    final uid = state.user?.uid;
    final e = exclusao;
    if (uid == null || e == null) throw const AuthException('Entre na conta primeiro.');
    await e.reautenticar(senha);
    try {
      await e.apagarDados(uid);
    } catch (_) {
      throw const AuthException('Não consegui apagar seus dados agora. Confira a internet e tente de novo.');
    }
    await e.excluirLogin();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
