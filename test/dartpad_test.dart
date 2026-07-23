import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/core/util/codigo_executavel.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/curso/presentation/widgets/code_view.dart';
import 'package:pac_dart/features/dartpad/dartpad_embed.dart';
import 'package:pac_dart/features/dartpad/dartpad_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  testWidgets('sem "rodar" quando o trecho não vira programa que compila',
      (tester) async {
    final typing = TypingBloc()..add(const TrechoCarregado('case >= 90:'));
    addTearDown(typing.close);
    await tester.pumpWidget(BlocProvider.value(
      value: typing,
      child: MaterialApp(
        theme: Mixart.tema(),
        home: Scaffold(body: CodeView(onAvancar: () {})), // podeRodar: false
      ),
    ));
    await tester.pump();
    expect(find.text('rodar'), findsNothing);
    expect(find.text('copiar'), findsOneWidget);
  });

  test('o contexto da lição entra no programa gerado', () {
    final codigo = codigoExecutavel('p.x = 5;', false,
        contexto: ['class Ponto {\n  int x = 0;\n}', 'var p = Ponto();']);
    expect(codigo, contains('class Ponto'));
    expect(codigo, contains('var p = Ponto();'));
  });

  test('completa o que a lição nunca declarou, marcando', () {
    final codigo = codigoExecutavel('var n = nums.length;', false);
    expect(codigo, contains('nums = [1, 2, 3]'));
    expect(codigo, contains('← completado'));
  });

  test('fora do navegador o DartPad não embute (import condicional)', () {
    // Nos testes (VM) vale o stub: a tela cai no plano B em vez de quebrar.
    expect(dartPadEmbutivel, isFalse);
  });

  test('o código enviado ao DartPad é um programa completo', () {
    expect(codigoExecutavel("var nome = 'Ana';", false), contains('void main() {'));
    expect(codigoExecutavel('Text("oi")', true), contains("import 'package:flutter/material.dart'"));
    expect(codigoExecutavel('void main() => print(1);', false), 'void main() => print(1);');
  });

  testWidgets('o botão "rodar" abre a tela do DartPad com o exercício',
      (tester) async {
    final typing = TypingBloc()..add(const TrechoCarregado("var nome = 'Ana';"));
    addTearDown(typing.close);

    await tester.pumpWidget(BlocProvider.value(
      value: typing,
      child: MaterialApp(
        theme: Mixart.tema(),
        home: Scaffold(
          body: CodeView(onAvancar: () {}, titulo: 'Variáveis', podeRodar: true),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('rodar'), findsOneWidget);
    expect(find.text('copiar'), findsOneWidget);

    await tester.tap(find.text('rodar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(DartPadPage), findsOneWidget);
    expect(find.text('RODAR NO DARTPAD'), findsOneWidget);
    expect(find.text('Variáveis'), findsOneWidget);
    // plano B (VM): mostra o código já embrulhado em main()
    expect(find.textContaining('void main() {'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
