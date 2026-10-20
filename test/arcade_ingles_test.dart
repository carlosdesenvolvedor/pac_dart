// BancoArcade no inglês: o vocabulário dos jogos vem das lições (via PalavrasCubit), com tradução;
// sem os providers, as listas fixas com tradução; e no Dart/C# tudo continua idêntico.
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/arcade/domain/palavras_csharp.dart';
import 'package:pac_dart/features/arcade/domain/palavras_dart.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/arcade/domain/vocabulario_jogo.dart';
import 'package:pac_dart/features/arcade/presentation/banco_arcade.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CursoBloc parado num estado pronto (nenhum evento é tratado).
class _CursoFake extends CursoBloc {
  _CursoFake(CursoState s) : super(loader: CurriculoLoader(), progresso: LocalProgressoRepository()) {
    emit(s);
  }
}

const _dic = Dicionario({
  'want': 'querer',
  'tea': 'chá',
  'milk': 'leite',
  'cake': 'bolo',
  'bread': 'pão',
  'apple': 'maçã',
  'juice': 'suco',
  'rice': 'arroz',
  'soup': 'sopa',
  'fish': 'peixe',
  'egg': 'ovo',
  'salt': 'sal',
  'sugar': 'açúcar',
  'lunch': 'almoço',
  'cheese': 'queijo',
});

final _trilhas = [
  const Trilha(nivel: 'T1', emoji: '🍽️', etapa: 'A1 · Fundação', licoes: [
    Licao(nome: 'Comida', emoji: '🍞', id: 't1.l1', trechos: [
      Trecho(cod: 'I want tea, milk, cake and bread.', dica: 'Quero chá, leite, bolo e pão.', out: ''),
      Trecho(cod: 'Apple juice, rice, soup and fish.', dica: 'Suco de maçã, arroz, sopa e peixe.', out: ''),
      Trecho(cod: 'Egg, salt, sugar, cheese, lunch.', dica: 'Ovo, sal, açúcar, queijo, almoço.', out: ''),
    ]),
  ]),
];

const _st = CursoState(status: CursoStatus.pronto, linguagem: Linguagem.ingles, concluidas: {'t1.l1'});

/// Monta os providers (ou não) e devolve o context de dentro.
Future<BuildContext> _contexto(WidgetTester tester, {CursoBloc? curso, PalavrasCubit? palavras}) async {
  late BuildContext ctx;
  Widget filho = Builder(builder: (c) {
    ctx = c;
    return const SizedBox();
  });
  if (palavras != null) filho = BlocProvider.value(value: palavras, child: filho);
  if (curso != null) filho = BlocProvider.value(value: curso, child: filho);
  await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: filho));
  return ctx;
}

void main() {
  SharedPreferences.setMockInitialValues({});
  tearDown(() => Linguagem.atual = Linguagem.dart);

  test('traducoesEn cobre exatamente as três listas fixas do inglês', () {
    final todas = {...palavrasCurtasEn, ...palavrasMediasEn, ...palavrasLongasEn}.map((w) => w.toLowerCase()).toSet();
    expect(traducoesEn.keys.toSet(), todas);
    expect(traducoesEn.values.where((t) => t.trim().isEmpty), isEmpty);
  });

  testWidgets('inglês sem providers: as listas fixas (mesmas instâncias), todas com tradução', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    final ctx = await _contexto(tester);
    final v = BancoArcade.vocabulario(ctx);
    expect(identical(v.curtas, palavrasCurtasEn), isTrue);
    expect(identical(v.longas, palavrasLongasEn), isTrue);
    for (final w in v.todas) {
      expect(v.traducao(w), isNotNull, reason: w);
    }
    expect(BancoArcade.palavras(ctx), isNull);
    // o baralho do Rali sai das mesmas palavras, sem repetir
    final b = BancoArcade.baralhoRali(ctx, Random(1), comLongas: true);
    expect(b.toSet(), v.todas.toSet());
    expect(b.length, b.toSet().length);
  });

  testWidgets('Dart e C#: as listas de sempre (mesmas instâncias) e o mesmo baralho do Rali', (tester) async {
    final ctx = await _contexto(tester);
    Linguagem.atual = Linguagem.dart;
    final v = BancoArcade.vocabulario(ctx);
    expect(identical(v.curtas, palavrasCurtas), isTrue);
    expect(identical(v.medias, palavrasMedias), isTrue);
    expect(identical(v.longas, palavrasLongas), isTrue);
    expect(v.traducoes, isEmpty);
    for (final semente in [1, 3, 9]) {
      for (final longas in [false, true]) {
        expect(BancoArcade.baralhoRali(ctx, Random(semente), comLongas: longas),
            baralhoRaliDe(Random(semente), comLongas: longas));
        expect(BancoArcade.baralhoRali(ctx, Random(semente), comLongas: longas),
            baralhoRali(Random(semente), comLongas: longas));
      }
    }
    Linguagem.atual = Linguagem.csharp;
    final cs = BancoArcade.vocabulario(ctx);
    expect(identical(cs.curtas, palavrasCurtasCs), isTrue);
    expect(BancoArcade.baralhoRali(ctx, Random(4)), baralhoRaliDe(Random(4)));
    expect(BancoArcade.palavras(ctx), isNull);
  });

  testWidgets('inglês com o curso e o cubit: as palavras da lição entram no jogo e o foco vem primeiro no Rali',
      (tester) async {
    Linguagem.atual = Linguagem.ingles;
    final cubit = PalavrasCubit(repo: MemoriaPalavrasRepository(), carregarDicionario: () async => _dic);
    final curso = _CursoFake(CursoState(
      status: CursoStatus.pronto,
      trilhas: _trilhas,
      linguagem: Linguagem.ingles,
      concluidas: _st.concluidas,
    ));
    await tester.runAsync(cubit.carregar);
    final ctx = await _contexto(tester, curso: curso, palavras: cubit);

    // antes do índice: a reserva fixa
    expect(identical(BancoArcade.vocabulario(ctx).curtas, palavrasCurtasEn), isTrue);

    await tester.runAsync(() => cubit.prepararIndice(_trilhas));
    final v = BancoArcade.vocabulario(ctx);
    expect(v.curtas, containsAll(['tea', 'milk', 'cake', 'bread', 'apple', 'juice', 'rice', 'soup', 'fish', 'egg']));
    expect(v.medias, contains('cheese'));
    expect(v.traducao('bread'), 'pão');
    expect(v.traducao('cheese'), 'queijo');
    expect(BancoArcade.palavras(ctx), same(cubit));

    // foco: as palavras treinadas vão para a frente do baralho, seja qual for a semente
    cubit.focar(['soup', 'cheese']);
    for (final semente in [0, 1, 2, 3]) {
      final b = BancoArcade.baralhoRali(ctx, Random(semente));
      expect(b.take(2).toSet(), {'soup', 'cheese'}, reason: 'semente $semente');
      expect(b.length, b.toSet().length);
    }

    // o placar da partida vai para o banco: erro numa palavra nova a põe no banco
    final placar = PlacarPalavras()
      ..viu('tea')
      ..errou('fish')
      ..errou('fish');
    placar.enviar(cubit);
    expect(placar.vazio, isTrue);
    expect(cubit.state.banco['fish']?.errosJogo, 2);
    BancoArcade.registrarJogo(ctx, {'fish': (1, 0)});
    expect(cubit.state.banco['fish']?.vistasJogo, 1);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await cubit.gravacoes;
      await cubit.close();
      await curso.close();
    });
  });

  test('baralhoDoVocabulario: sem repetir, longas só com comLongas, foco na frente', () {
    const v = VocabularioJogo(
      curtas: ['cat', 'dog', 'sun'],
      medias: ['window', 'garden', 'cat'],
      longas: ['beautiful'],
      foco: {'garden'},
    );
    final b = BancoArcade.baralhoDoVocabulario(v, Random(2));
    expect(b.first, 'garden');
    expect(b.toSet(), {'cat', 'dog', 'sun', 'window', 'garden'});
    expect(b.length, 5);
    expect(BancoArcade.baralhoDoVocabulario(v, Random(2), comLongas: true), contains('beautiful'));
  });
}
