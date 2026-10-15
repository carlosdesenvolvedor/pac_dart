import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/auth/data/auth_repository.dart';
import 'package:pac_dart/features/auth/data/exclusao_de_conta.dart';
import 'package:pac_dart/features/auth/domain/app_user.dart';
import 'package:pac_dart/features/auth/presentation/auth_cubit.dart';
import 'package:pac_dart/features/auth/presentation/excluir_conta_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

/// Registra a ordem dos passos da exclusão de conta.
class _ExclusaoFake implements ExclusaoDeConta {
  final passos = <String>[];
  bool falhaNosDados = false;

  @override
  Future<void> reautenticar(String senha) async {
    passos.add('reautenticar');
    if (senha != 'certa') throw const AuthException('Senha incorreta.');
  }

  @override
  Future<void> apagarDados(String uid) async {
    passos.add('dados:$uid');
    if (falhaNosDados) throw Exception('sem rede');
  }

  @override
  Future<void> excluirLogin() async => passos.add('login');
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
      linguagemInicial: Linguagem.dart,
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
      linguagemInicial: Linguagem.dart,
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

  group('excluir a conta', () {
    Future<(AuthCubit, _ExclusaoFake)> logado() async {
      final repo = _FakeAuthRepo();
      final exclusao = _ExclusaoFake();
      final cubit = AuthCubit(repo, exclusao: exclusao);
      repo.emitir(const AppUser(uid: 'u1', email: 'a@b.c'));
      await Future<void>.delayed(Duration.zero);
      return (cubit, exclusao);
    }

    test('confirma a senha, apaga os dados e SÓ ENTÃO o login (nessa ordem)', () async {
      final (cubit, exclusao) = await logado();
      await cubit.excluirConta('certa');
      expect(exclusao.passos, ['reautenticar', 'dados:u1', 'login']);
    });

    test('senha errada: nada é apagado', () async {
      final (cubit, exclusao) = await logado();
      await expectLater(cubit.excluirConta('errada'), throwsA(isA<AuthException>()));
      expect(exclusao.passos, ['reautenticar']);
    });

    test('falha ao apagar os dados: o login fica (não sobra dado sem dono nem conta sem dado)', () async {
      final (cubit, exclusao) = await logado();
      exclusao.falhaNosDados = true;
      await expectLater(cubit.excluirConta('certa'), throwsA(isA<AuthException>()));
      expect(exclusao.passos, ['reautenticar', 'dados:u1']);
    });

    test('sem usuário logado (ou sem o recurso) não exclui nada', () async {
      final semLogin = AuthCubit(_FakeAuthRepo(), exclusao: _ExclusaoFake());
      await expectLater(semLogin.excluirConta('certa'), throwsA(isA<AuthException>()));
    });

    testWidgets('o diálogo explica, exige a senha, mostra o erro e some quando exclui', (tester) async {
      final repo = _FakeAuthRepo();
      final exclusao = _ExclusaoFake();
      final cubit = AuthCubit(repo, exclusao: exclusao);
      repo.emitir(const AppUser(uid: 'u1', email: 'ana@b.c'));
      await tester.pump();
      await tester.pumpWidget(MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(onPressed: () => mostrarExcluirConta(ctx), child: const Text('abrir')),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir minha conta'), findsOneWidget);
      expect(find.textContaining('ana@b.c'), findsOneWidget);

      // sem senha: pede
      await tester.tap(find.text('Excluir definitivamente'));
      await tester.pump();
      expect(find.text('Digite sua senha para confirmar.'), findsOneWidget);
      expect(exclusao.passos, isEmpty);

      // senha errada: mostra o erro do repositório e continua aberto
      await tester.enterText(find.byType(TextField), 'errada');
      await tester.tap(find.text('Excluir definitivamente'));
      await tester.pumpAndSettle();
      expect(find.text('Senha incorreta.'), findsOneWidget);
      expect(find.text('Excluir minha conta'), findsOneWidget);

      // senha certa: exclui e fecha
      await tester.enterText(find.byType(TextField), 'certa');
      await tester.tap(find.text('Excluir definitivamente'));
      await tester.pumpAndSettle();
      expect(exclusao.passos.last, 'login');
      expect(find.text('Excluir minha conta'), findsNothing);
    });
  });
}
