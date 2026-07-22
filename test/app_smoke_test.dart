import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/auth/data/auth_repository.dart';
import 'package:pac_dart/features/auth/domain/app_user.dart';
import 'package:pac_dart/features/auth/presentation/auth_cubit.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/presentation/pages/mapa_page.dart';
import 'package:pac_dart/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth fake já autenticado — evita tocar no Firebase real nos testes.
class _FakeAuthRepo implements AuthRepository {
  static const _user = AppUser(uid: 'teste-uid', email: 'teste@pac.dart');
  @override
  Stream<AppUser?> get mudancas => Stream.value(_user);
  @override
  AppUser? get atual => _user;
  @override
  Future<void> entrar(String email, String senha) async {}
  @override
  Future<void> cadastrar(String email, String senha) async {}
  @override
  Future<void> redefinirSenha(String email) async {}
  @override
  Future<void> sair() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // em teste não há rede: usa fontes do sistema
  Mixart.usarGoogleFonts = false;

  testWidgets('app monta, carrega o currículo e processa digitação', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      await tester.pumpWidget(PacDartApp(
        authCubitOverride: AuthCubit(_FakeAuthRepo()),
        progressoBuilder: (_) => LocalProgressoRepository(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump(); // aplica o login → cria o CursoBloc
      // dá tempo real para o rootBundle ler assets/curriculo.json
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await tester.pump(); // currículo carregado → HomePage
    });
    await tester.pump();
    await tester.pump();

    // HUD e primeiro exercício visíveis
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // digita os 4 primeiros caracteres do primeiro trecho: "var nome = 'Ana';"
    await tester.enterText(find.byType(TextField), 'var ');
    await tester.pump();

    // sem erros no console (segue ocioso) e sem exceções
    expect(find.textContaining('Digite o código acima'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // abre o Mapa da Jornada
    await tester.tap(find.text('Mapa'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Mapa da Jornada'), findsOneWidget);
    expect(find.textContaining('Sua jornada'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // toca no rótulo da primeira lição (Variáveis) → folha com Praticar/Quiz
    final noLicao =
        find.descendant(of: find.byType(MapaPage), matching: find.text('Variáveis')).first;
    await tester.ensureVisible(noLicao);
    await tester.pump();
    await tester.tap(noLicao);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Quiz da lição'), findsOneWidget);

    // entra no quiz
    await tester.tap(find.text('Quiz da lição'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('QUIZ ·'), findsOneWidget);
    expect(find.textContaining('Qual código'), findsOneWidget);

    // digita uma resposta qualquer e envia com Enter → veredito aparece
    await tester.enterText(find.byType(TextField).last, 'resposta errada');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.textContaining('Errou'), findsOneWidget);
    expect(find.textContaining('Enter para a próxima'), findsOneWidget);

    // Enter de novo → próxima pergunta (veredito some)
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.textContaining('Errou'), findsNothing);
    expect(find.textContaining(RegExp(r'^2/\d+$')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
