// "🎯 Escolher palavras": as palavras de uma lição para estudar sozinhas, a folha que marca só algumas
// e o "Treinar esta palavra" do balão da palavra tocada.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/dicionario_ingles.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/palavras_novas.dart';
import 'package:pac_dart/features/ingles/presentation/escolher_palavras.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/traducao_palavra.dart';

Trecho _t(String cod, {String dica = '', String alvo = '', String quem = '', String id = ''}) =>
    Trecho(cod: cod, dica: dica, out: '', alvo: alvo, quem: quem, id: id);

const _dic = Dicionario({
  'are': 'são, estão, é, está (de be)',
  'you': 'você, vocês',
  'there': 'lá, ali',
  'ana': 'Ana (nome)',
  'idea': 'ideia',
  'good': 'bom, boa',
  'me': 'me, mim',
  'call': 'ligar; ligação',
  'at': 'em, às',
  'is': 'é, está',
  'a': 'um, uma',
});

final _licao = Licao(nome: 'Primeira chamada', emoji: '📞', id: 't1.a', trechos: [
  _t('Are you there, Ana?', dica: 'Você está aí, Ana?', quem: 'ana', id: 'f-1'),
  _t('Good idea! Call me at 9.', dica: 'Boa ideia! Me liga às 9.', alvo: 'idea', id: 'f-2'),
  _t('Zorbleflax is a good idea.', dica: '…', id: 'f-3'),
]);

IndicePalavras _indice() => IndicePalavras.de([
      Trilha(nivel: 'T1', emoji: '1', licoes: [_licao]),
    ], _dic);

Widget _folha({Set<String> marcadas = const {}, List<String>? ouvidas, void Function(List<PalavraNova>?)? aoFechar}) {
  final ind = _indice();
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final r = await showModalBottomSheet<List<PalavraNova>>(
                context: context,
                isScrollControlled: true,
                builder: (_) => FolhaEscolherPalavras(
                  licao: _licao,
                  palavras: ind.palavrasParaEstudar(_licao),
                  novas: {for (final p in ind.novasDe(_licao.id)) p.chave},
                  marcadas: marcadas,
                  ouvir: ouvidas?.add,
                ),
              );
              aoFechar?.call(r);
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('IndicePalavras.palavrasParaEstudar', () {
    test('as novas primeiro, depois todas as outras na ordem (inclusive you/there/me), sem nomes nem números', () {
      final ind = _indice();
      final ps = ind.palavrasParaEstudar(_licao);
      final novas = [for (final p in ind.novasDe(_licao.id)) p.chave];
      expect(novas, isNotEmpty);
      expect([for (final p in ps.take(novas.length)) p.chave], novas);
      final chaves = [for (final p in ps) p.chave];
      for (final w in ['are', 'you', 'there', 'good', 'idea', 'call', 'me', 'at', 'is', 'a']) {
        expect(chaves, contains(w), reason: w);
      }
      expect(chaves, isNot(contains('ana')));
      expect(chaves, isNot(contains('9')));
      expect(chaves, isNot(contains('zorbleflax')));
      expect(chaves.toSet().length, chaves.length, reason: 'sem repetir');
    });

    test('cada palavra traz a tradução curta e uma frase da própria lição', () {
      final there = _indice().palavrasParaEstudar(_licao).firstWhere((p) => p.chave == 'there');
      expect(there.pt, 'lá');
      expect(there.licaoId, 't1.a');
      expect(there.exemplo, 'Are you there, Ana?');
      expect(there.exemploPt, 'Você está aí, Ana?');
    });
  });

  group('FolhaEscolherPalavras', () {
    testWidgets('marca só as tocadas, fala ao marcar e devolve na ordem da lição', (t) async {
      final ouvidas = <String>[];
      List<PalavraNova>? r;
      await t.pumpWidget(_folha(ouvidas: ouvidas, aoFechar: (v) => r = v));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.text('Marque as palavras'), findsOneWidget);
      await t.tap(find.byKey(const Key('palavra-there')));
      await t.tap(find.byKey(const Key('palavra-you')));
      await t.pump();
      expect(ouvidas, ['there', 'you']);
      expect(find.text('Treinar 2 palavras'), findsOneWidget);
      // tocar de novo desmarca (e não fala)
      await t.tap(find.byKey(const Key('palavra-you')));
      await t.tap(find.byKey(const Key('palavra-me')));
      await t.pump();
      expect(ouvidas, ['there', 'you', 'me']);
      await t.tap(find.byKey(const Key('palavras-treinar')));
      await t.pumpAndSettle();
      expect([for (final p in r!) p.chave], ['there', 'me']);
    });

    testWidgets('a palavra do balão já vem marcada; "Só as novas" e "Marcar todas"', (t) async {
      List<PalavraNova>? r;
      await t.pumpWidget(_folha(marcadas: {'there'}, aoFechar: (v) => r = v));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.text('Treinar 1 palavra'), findsOneWidget);
      final novas = _indice().novasDe(_licao.id);
      await t.tap(find.byKey(const Key('palavras-so-novas')));
      await t.pump();
      expect(find.text(novas.length == 1 ? 'Treinar 1 palavra' : 'Treinar ${novas.length} palavras'), findsOneWidget);
      await t.tap(find.byKey(const Key('palavras-todas')));
      await t.pump();
      final total = _indice().palavrasParaEstudar(_licao).length;
      expect(find.text('Treinar $total palavras'), findsOneWidget);
      expect(find.text('Desmarcar'), findsOneWidget);
      await t.tap(find.byKey(const Key('palavras-treinar')));
      await t.pumpAndSettle();
      expect(r!.length, total);
    });
  });

  group('balão da palavra', () {
    setUp(() => DicionarioIngles.usarParaTestes(_dic));
    tearDown(() => DicionarioIngles.usarParaTestes(null));

    testWidgets('"Treinar esta palavra" só aparece com o callback e devolve a palavra', (t) async {
      String? treinada;
      const tocada = PalavraTocada(palavra: 'there', frase: 'Are you there, Ana?');
      await t.pumpWidget(const MaterialApp(home: Scaffold(body: ConteudoBalaoPalavra(palavra: tocada))));
      await t.pump();
      expect(find.byKey(const Key('treinar-palavra')), findsNothing);
      await t.pumpWidget(MaterialApp(
        home: Scaffold(body: ConteudoBalaoPalavra(palavra: tocada, onTreinar: (w) => treinada = w)),
      ));
      await t.pump();
      await t.tap(find.byKey(const Key('treinar-palavra')));
      expect(treinada, 'there');
    });
  });
}
