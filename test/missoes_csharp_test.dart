import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/gerador_missoes.dart';
import 'package:pac_dart/features/arcade/domain/missao.dart';
import 'package:pac_dart/features/arcade/presentation/missao_page.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/curso/presentation/widgets/code_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lógica Animada no PAC·C#: a missão N da trilha T é a MESMA do Dart (mesmo
/// sorteio → mesma resposta, mesmas opções, mesma animação), só que o código
/// e os textos que citam sintaxe falam C# idiomático.
void main() {
  Missao cs(int t, int i) => missaoPara(t, i, linguagem: Linguagem.csharp);

  final digitaveis = <String>{
    for (var c = 0x20; c < 0x7F; c++) String.fromCharCode(c),
    '\n',
    ...'áàâãéêíóôõúüçÁÀÂÃÉÊÍÓÔÕÚÜÇ'.split(''),
  };

  test('determinístico, e o Dart continua sendo o padrão', () {
    expect(cs(1, 3), cs(1, 3));
    expect(cs(2, 7), cs(2, 7));
    expect(cs(1, 3) == cs(1, 4), isFalse);
    expect(missaoPara(1, 3, linguagem: Linguagem.dart), missaoPara(1, 3));
    expect(cs(1, 3).codigo, isNot(missaoPara(1, 3).codigo));
  });

  test('mesma resposta, opções, passos e dados que a missão Dart', () {
    for (var t = 0; t < 50; t++) {
      for (var i = 0; i < 40; i++) {
        final d = missaoPara(t, i);
        final c = cs(t, i);
        final onde = 'trilha $t missão $i (${d.titulo})';
        expect(c.cena, d.cena, reason: onde);
        expect(c.titulo, d.titulo, reason: onde);
        expect(c.pergunta, d.pergunta, reason: onde);
        expect(c.pontos, d.pontos, reason: onde);
        expect(c.certa, d.certa, reason: onde);
        expect(c.opcoes[c.certa], d.opcoes[d.certa], reason: onde);
        // só o distrator "sem interpolação" do crachá mostra sintaxe
        if (d.titulo != 'O Crachá Mágico') expect(c.opcoes, d.opcoes, reason: onde);
        expect([for (final p in c.passos) p.muda], [for (final p in d.passos) p.muda],
            reason: onde);
        expect(c.dados, d.dados, reason: onde);
        expect(c.dicas, hasLength(d.dicas.length), reason: onde);
        // cada print do Dart vira um Console.WriteLine
        expect('Console.WriteLine('.allMatches(c.codigo).length,
            'print('.allMatches(d.codigo).length,
            reason: onde);
      }
    }
  });

  test('o estoque C# também passa dos MILHARES: ≥ 1000 códigos únicos em 1280', () {
    final codigos = <String>{
      for (var t = 0; t < 32; t++)
        for (var i = 0; i < 40; i++) cs(t, i).codigo,
    };
    expect(codigos.length, greaterThanOrEqualTo(1000),
        reason: 'só ${codigos.length} códigos distintos em 1280 missões');
  });

  test('código C# digitável, no estilo do curso e sem sintaxe de Dart', () {
    const dart = [
      'print(', 'final ', "'", '.length', '.add(', '.where(', '.toList()', 'toUpperCase',
      'containsKey', '.values', 'String?', 'for (var', 'for (final', '} else {',
    ];
    for (var t = 0; t < 50; t++) {
      for (var i = 0; i < 40; i++) {
        final m = cs(t, i);
        final onde = 'trilha $t missão $i (${m.titulo})\n${m.codigo}';
        for (final ch in m.codigo.split('').toSet()) {
          expect(digitaveis.contains(ch), isTrue, reason: '$onde\nnão-digitável: "$ch"');
        }
        for (final trecho in dart) {
          expect(m.codigo.contains(trecho), isFalse, reason: '$onde\ntem "$trecho" do Dart');
        }
        for (final linha in m.codigo.split('\n')) {
          final texto = linha.trimLeft();
          expect(linha.length, lessThanOrEqualTo(60), reason: '$onde\nlinha longa: $linha');
          expect(linha, isNot(endsWith(' ')), reason: onde);
          expect((linha.length - texto.length) % 4, 0, reason: '$onde\nindentação: $linha');
          // Allman: chave sozinha na linha
          if (texto.endsWith('{')) expect(texto, '{', reason: '$onde\n$linha');
          if (texto.startsWith('}')) expect(texto, anyOf('}', '};'), reason: '$onde\n$linha');
        }
      }
    }
  });

  test('os textos que citam sintaxe também falam C#', () {
    final dartNoTexto =
        RegExp(r"\bprint\b|\blength\b|toUpperCase|containsKey|\.add\(|\bMap\b|for-in|'|\$[a-z]");
    for (var t = 0; t < 50; t++) {
      for (var i = 0; i < 40; i++) {
        final m = cs(t, i);
        final textos = [
          m.historia, m.pergunta, m.explica, ...m.dicas, ...m.opcoes,
          for (final p in m.passos) p.legenda,
        ];
        for (final texto in textos) {
          expect(dartNoTexto.hasMatch(texto), isFalse,
              reason: 'trilha $t missão $i (${m.titulo}): "$texto"');
        }
      }
    }
  });

  testWidgets('no PAC·C# a missão mostra, cobra e anima o código C#', (tester) async {
    Mixart.usarGoogleFonts = false;
    SharedPreferences.setMockInitialValues({});
    Linguagem.atual = Linguagem.csharp;
    addTearDown(() => Linguagem.atual = Linguagem.dart);
    tester.view.physicalSize = const Size(1000, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: const MissaoPage(
          trilhaIdx: 0, trilhaNome: 'Primeiros Passos', trilhaEmoji: '🌱', indiceInicial: 0),
    ));
    await tester.pump();
    await tester.pump();

    // ATO 1: o cartão já mostra o código C#
    final missao = cs(0, 0);
    expect(missao.codigo, contains('Console.WriteLine'));
    expect(find.text(missao.codigo, findRichText: true), findsOneWidget);
    final alvo = find.text(missao.opcoes[missao.certa], findRichText: true).last;
    await tester.ensureVisible(alvo);
    await tester.pump();
    await tester.tap(alvo);
    await tester.pump();
    expect(find.textContaining('Previsão certeira'), findsOneWidget);

    // ATO 2: o motor cobra o código C#, com o destaque do C#
    await tester.tap(find.text('Digitar pra destravar →'));
    await tester.pump();
    expect(tester.widget<CodeView>(find.byType(CodeView)).variante, 'cs');
    final bloc = BlocProvider.of<TypingBloc>(tester.element(find.byType(CodeView)));
    expect(bloc.state.chars.join(), missao.codigo);
    var guarda = 0;
    while (!bloc.state.concluido && guarda++ < 400) {
      bloc.add(TeclaDigitada(bloc.state.chars[bloc.state.idx]));
      await tester.pump();
    }
    expect(bloc.state.concluido, isTrue);
    await tester.pump();

    // ATO 3 e 4: a animação roda até a vitória, com a explicação em C#
    for (var i = 0; i <= missao.passos.length + 1; i++) {
      await tester.pump(const Duration(milliseconds: 1250));
    }
    expect(find.text('MISSÃO CUMPRIDA!'), findsOneWidget);
    expect(find.text('💡 ${missao.explica}'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
  });
}
