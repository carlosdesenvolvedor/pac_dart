import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/auth/data/auth_repository.dart';
import 'package:pac_dart/features/auth/domain/app_user.dart';
import 'package:pac_dart/features/auth/presentation/auth_cubit.dart';
import 'package:pac_dart/features/auth/presentation/login_page.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth fake controlável pelo teste.
class _FakeAuthRepo implements AuthRepository {
  final _ctrl = StreamController<AppUser?>();
  AppUser? _atual;
  bool cadastrou = false;

  void emitir(AppUser? u) {
    _atual = u;
    _ctrl.add(u);
  }

  @override
  Stream<AppUser?> get mudancas => _ctrl.stream;
  @override
  AppUser? get atual => _atual;
  @override
  Future<void> entrar(String email, String senha) async => emitir(AppUser(uid: 'u', email: email));
  @override
  Future<void> cadastrar(String email, String senha) async {
    cadastrou = true;
    emitir(AppUser(uid: 'novo', email: email));
  }

  @override
  Future<void> redefinirSenha(String email) async {}
  @override
  Future<void> sair() async => emitir(null);
}

void main() {
  Mixart.usarGoogleFonts = false;

  group('AuthCubit', () {
    test('começa desconhecido e reage ao stream (autenticado/não)', () async {
      final repo = _FakeAuthRepo();
      final cubit = AuthCubit(repo);
      expect(cubit.state.status, AuthStatus.desconhecido);

      repo.emitir(const AppUser(uid: 'x', email: 'a@b.c'));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, AuthStatus.autenticado);
      expect(cubit.state.user?.email, 'a@b.c');

      repo.emitir(null);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, AuthStatus.naoAutenticado);
      await cubit.close();
    });

    test('apelido usa a parte antes do @', () {
      expect(const AppUser(uid: 'u', email: 'carlos@teste.com').apelido, 'carlos');
      expect(const AppUser(uid: 'u').apelido, 'você');
    });
  });

  testWidgets('sem login, o app mostra a tela de login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = _FakeAuthRepo();
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(repo),
      progressoBuilder: (_) => LocalProgressoRepository(),
    ));
    repo.emitir(null); // não autenticado
    await tester.pump();
    await tester.pump();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Entrar'), findsWidgets);
    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // e-mail + senha
    expect(tester.takeException(), isNull);
  });

  testWidgets('cadastro exige senha de 6+ caracteres', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = _FakeAuthRepo();
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(repo),
      progressoBuilder: (_) => LocalProgressoRepository(),
    ));
    repo.emitir(null);
    await tester.pump();
    await tester.pump();

    // muda para "Criar conta", preenche e-mail e senha curta
    await tester.tap(find.text('Criar conta'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'novo@pac.dart');
    await tester.enterText(find.byType(TextField).last, '123');
    await tester.tap(find.text('Criar conta e começar'));
    await tester.pump();

    expect(find.text('Mínimo de 6 caracteres'), findsOneWidget);
    expect(repo.cadastrou, isFalse); // não chamou o cadastro
    expect(tester.takeException(), isNull);
  });
}
