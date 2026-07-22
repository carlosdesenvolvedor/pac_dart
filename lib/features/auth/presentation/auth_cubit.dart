import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
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
  StreamSubscription<AppUser?>? _sub;

  AuthCubit(this.repo) : super(const AuthState.desconhecido()) {
    _sub = repo.mudancas.listen((u) {
      emit(u == null ? const AuthState.naoAutenticado() : AuthState.autenticado(u));
    });
  }

  Future<void> entrar(String email, String senha) => repo.entrar(email, senha);
  Future<void> cadastrar(String email, String senha) => repo.cadastrar(email, senha);
  Future<void> redefinirSenha(String email) => repo.redefinirSenha(email);
  Future<void> sair() => repo.sair();

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
