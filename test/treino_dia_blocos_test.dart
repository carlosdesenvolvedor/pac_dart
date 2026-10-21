// "⚡ Treino do dia" (FASE-9, grupo D): a leitura das fontes e a escolha do que cada etapa usa —
// escolherPalavras (teimosas > devidas > fracas, só as treináveis), rodarPalavras sem nada treinável
// (BlocoVazio, nenhuma rota), trechoParaOuvir (frases revisadas → última lição concluída → lição atual;
// nada no Dart) e lerFontes (contagens, espera do índice, prazo com fonte travada, quizzes do Dart).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/presentation/arcade_page.dart' show treinoSemDevidas;
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/erros_palavra.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/setlist.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/domain/teimosas.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/treino_dia/domain/plano_treino.dart';
import 'package:pac_dart/features/treino_dia/presentation/blocos_treino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ingles_baralhos_test.dart' show RepoMemoria;

final _agora = DateTime(2026, 10, 21, 10);
final _hoje = Revisao.dia(_agora);

/// CursoBloc de verdade num estado fixo.
class CursoFixo extends CursoBloc {
  CursoFixo(CursoState s) : super(loader: CurriculoLoader(), progresso: LocalProgressoRepository()) {
    emit(s);
  }
}

/// Repositório da revisão que só entrega os cartões quando [liberar] é chamado.
class RepoTravado extends RepoMemoria {
  final _c = Completer<void>();
  RepoTravado([super.iniciais]);
  void liberar() => _c.complete();
  @override
  Future<Map<String, CartaoSrs>> carregar() async {
    await _c.future;
    return super.carregar();
  }
}

Trecho _f(String id, String cod, String dica) => Trecho(cod: cod, dica: dica, out: '', id: id, quem: 'mike');

/// Inglês: "Cores" (8 frases), "Casa" (3) e um texto da pessoa no fim.
final trilhasEn = [
  Trilha(nivel: 'Primeiro contato', emoji: '👋', etapa: 'A1 · Fundação', licoes: [
    Licao(nome: 'Cores', emoji: '🎨', id: 'en.cores', trechos: [
      for (var i = 1; i <= 8; i++) _f('c$i', 'The color number $i is blue.', 'A cor número $i é azul.'),
    ]),
    Licao(nome: 'Casa', emoji: '🏠', id: 'en.casa', trechos: [
      _f('h1', 'My house is big.', 'Minha casa é grande.'),
      _f('h2', 'The kitchen is clean.', 'A cozinha está limpa.'),
      _f('h3', 'Open the window.', 'Abra a janela.'),
    ]),
  ]),
  const Trilha(nivel: 'Meus textos', emoji: '📝', etapa: 'Meus textos', textoId: 't1', licoes: [
    Licao(nome: 'Parte 1', emoji: '📝', id: 'txt-t1-1', trechos: [
      Trecho(cod: 'The garden is lovely.', dica: 'O jardim é lindo.', out: ''),
    ]),
  ]),
];

CursoState estadoEn({Set<String> concluidas = const {}, int t = 0, int l = 0}) => CursoState(
      status: CursoStatus.pronto,
      linguagem: Linguagem.ingles,
      trilhas: trilhasEn,
      concluidas: concluidas,
      trilhaIdx: t,
      licaoIdx: l,
    );

const dicTeste = Dicionario({
  'color': 'cor',
  'blue': 'azul',
  'house': 'casa',
  'kitchen': 'cozinha',
  'window': 'janela',
  'clean': 'limpo',
});

/// Uma teimosa de verdade (2 erros em 2 vistas hoje).
PalavraDoBanco teimosa(String en, String pt) => aplicarEvidencias(
      PalavraDoBanco(en: en, pt: pt, origem: OrigemPalavra.minha),
      [
        for (var i = 0; i < 2; i++)
          EvidenciaPalavra(chave: en, peso: pesoDaFonte(FonteErro.licao), falha: 1, fonte: FonteErro.licao),
      ],
      _hoje,
    ).$1;

/// Uma palavra com cartão vencido ontem.
PalavraDoBanco devida(String en, String pt) => PalavraDoBanco(
      en: en,
      pt: pt,
      origem: OrigemPalavra.minha,
      cartao: CartaoSrs(estabilidade: 3, dificuldade: 5, ultimoDia: _hoje - 4, proximoDia: _hoje - 1),
    );

/// Errada nos jogos e nunca treinada (fraca).
PalavraDoBanco fraca(String en, String pt) =>
    PalavraDoBanco(en: en, pt: pt, origem: OrigemPalavra.minha, vistasJogo: 3, errosJogo: 3);

BancoPalavras banco(List<PalavraDoBanco> ps) => BancoPalavras(palavras: {for (final p in ps) p.chave: p});

Future<PalavrasCubit> palavrasProntas(BancoPalavras b, {Future<Dicionario> Function()? dic}) async {
  final c = PalavrasCubit(
    repo: MemoriaPalavrasRepository(b),
    agora: () => _agora,
    carregarDicionario: dic ?? () async => dicTeste,
  );
  await c.carregar();
  await c.prepararIndice(trilhasEn);
  return c;
}

/// Um cartão de frase vencido.
CartaoSrs cartaoVencido() => CartaoSrs(estabilidade: 2, dificuldade: 5, ultimoDia: _hoje - 3, proximoDia: _hoje - 1);

/// Monta os providers e devolve um contexto debaixo deles.
Future<BuildContext> contexto(WidgetTester tester,
    {required CursoBloc curso, PalavrasCubit? palavras, RevisaoCubit? revisao}) async {
  late BuildContext ctx;
  await tester.pumpWidget(MultiBlocProvider(
    providers: [
      BlocProvider<CursoBloc>.value(value: curso),
      if (palavras != null) BlocProvider<PalavrasCubit>.value(value: palavras),
      if (revisao != null) BlocProvider<RevisaoCubit>.value(value: revisao),
    ],
    child: MaterialApp(
      theme: Mixart.tema(),
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold(body: SizedBox.shrink());
      }),
    ),
  ));
  return ctx;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => Linguagem.atual = Linguagem.dart);

  group('escolherPalavras', () {
    test('teimosas vêm primeiro (no máximo 6)', () async {
      final c = await palavrasProntas(banco([
        for (final w in ['alpha', 'bravo', 'charlie', 'delta', 'echo', 'foxtrot', 'golf']) teimosa(w, 'pt-$w'),
        devida('house', 'casa'),
        fraca('window', 'janela'),
      ]));
      final e = escolherPalavras(c, estadoEn())!;
      expect(e.$1, OrigemPalavras.teimosas);
      expect(e.$2, hasLength(6));
      expect(e.$2.toSet().difference({'alpha', 'bravo', 'charlie', 'delta', 'echo', 'foxtrot', 'golf'}), isEmpty);
      await c.close();
    });

    test('sem teimosas: as devidas; sem devidas: as fracas', () async {
      final c1 = await palavrasProntas(banco([devida('house', 'casa'), devida('kitchen', 'cozinha'), fraca('window', 'janela')]));
      expect(_lista(escolherPalavras(c1, estadoEn())), (OrigemPalavras.devidas, 'house,kitchen'));
      await c1.close();
      final c2 = await palavrasProntas(banco([fraca('window', 'janela')]));
      expect(_lista(escolherPalavras(c2, estadoEn())), (OrigemPalavras.fracas, 'window'));
      await c2.close();
    });

    test('teimosas e devidas sem tradução não contam: cai nas fracas, ou null', () async {
      final semPt = [teimosa('quokka', ''), devida('wombat', '')];
      final c1 = await palavrasProntas(banco([...semPt, fraca('window', 'janela')]));
      expect(c1.teimosas(), isNotEmpty, reason: 'a teimosa existe, só não é treinável');
      expect(_lista(escolherPalavras(c1, estadoEn())), (OrigemPalavras.fracas, 'window'));
      await c1.close();
      final c2 = await palavrasProntas(banco(semPt));
      expect(escolherPalavras(c2, estadoEn()), isNull);
      await c2.close();
    });

    testWidgets('rodarPalavras sem nada treinável → BlocoVazio, nenhuma rota empurrada', (tester) async {
      final c = (await tester.runAsync(() => palavrasProntas(banco([teimosa('quokka', ''), devida('wombat', '')]))))!;
      final curso = CursoFixo(estadoEn());
      final obs = _Rotas();
      late BuildContext ctx;
      await tester.pumpWidget(MultiBlocProvider(
        providers: [BlocProvider<CursoBloc>.value(value: curso), BlocProvider<PalavrasCubit>.value(value: c)],
        child: MaterialApp(
          navigatorObservers: [obs],
          home: Builder(builder: (b) {
            ctx = b;
            return const SizedBox.shrink();
          }),
        ),
      ));
      final empurradas = obs.empurradas;
      final fim = await rodarPalavras(ctx);
      expect(fim, isA<BlocoVazio>());
      expect((fim as BlocoVazio).aviso, AvisosTreino.semPalavras);
      expect(obs.empurradas, empurradas);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await c.close();
        await curso.close();
      });
    });
  });

  group('trechoParaOuvir', () {
    const vazio = PlanoTreino(dia: 1, curso: 'ingles');

    test('as frases revisadas no treino: um item daFrase cada (no máximo 6)', () {
      final p = vazio.copyWith(ouvirChaves: ['h2', 'c3', 'nao-existe', 'h1']);
      final itens = trechoParaOuvir(estadoEn(), p);
      expect([for (final i in itens) (i.tipo, i.ref)], [
        (TipoItem.frase, 'h2'),
        (TipoItem.frase, 'c3'),
        (TipoItem.frase, 'h1'),
      ]);
      expect(itens.first.licaoId, 'en.casa');
    });

    test('sem frases revisadas: a última lição concluída, UM item com 6 frases (6 faixas na fila)', () {
      // "Casa" (t0,l1) não foi feita: a última concluída é "Cores", com 8 frases → as 6 primeiras
      final st = estadoEn(concluidas: {'en.cores', 'txt-t1-1'}, l: 1);
      final itens = trechoParaOuvir(st, vazio);
      expect(itens, hasLength(1));
      expect(itens.single.tipo, TipoItem.trecho);
      expect(itens.single.chaves, ['c1', 'c2', 'c3', 'c4', 'c5', 'c6']);
      final fila = resolverFila(IndiceOuvir.de(trilhasEn), itens, duracaoDe: (_) => 2, temGravacao: (_) => false);
      expect(fila.faixas, hasLength(6), reason: 'o alvo do painel são as faixas, não os itens');
      expect(fila.faixas.first.en, 'The color number 1 is blue.');
    });

    test('nada concluído: a lição atual (prévia), inteira quando cabe', () {
      final itens = trechoParaOuvir(estadoEn(l: 1), vazio);
      expect(itens, hasLength(1));
      expect(itens.single.tipo, TipoItem.licao, reason: '3 frases ≤ 6: o doTrecho vira a lição inteira');
      expect(itens.single.ref, 'en.casa');
    });

    test('Dart: nada para ouvir', () {
      final st = CursoState(status: CursoStatus.pronto, linguagem: Linguagem.dart, trilhas: trilhasEn);
      expect(trechoParaOuvir(st, vazio.copyWith(ouvirChaves: ['h1'])), isEmpty);
    });
  });

  group('lerFontes', () {
    testWidgets('inglês: conta revisão, cartões e palavras — e espera o índice ficar pronto', (tester) async {
      // os cubits (e o Completer) nascem na zona de verdade: o runAsync espera eventos deles, e um Future
      // criado na zona falsa só avança com pump
      late final Completer<Dicionario> dicPronto;
      final (_, revisao, palavras) = (await tester.runAsync(() async => (
            dicPronto = Completer<Dicionario>(),
            RevisaoCubit(
              repo: RepoMemoria({'c1': cartaoVencido(), 'c2': cartaoVencido(), 'h1': cartaoVencido()}),
              agora: () => _agora,
            ),
            PalavrasCubit(
              repo: MemoriaPalavrasRepository(banco([
                teimosa('alpha', 'alfa'),
                teimosa('bravo', 'bravo'),
                teimosa('quokka', ''), // sem tradução: não conta
                devida('house', 'casa'),
                devida('wombat', ''), // sem tradução: não conta
                fraca('window', 'janela'),
              ])),
              agora: () => _agora,
              carregarDicionario: () => dicPronto.future,
            ),
          )))!;
      final curso = CursoFixo(estadoEn(concluidas: {'en.casa'}));
      final ctx = await contexto(tester, curso: curso, palavras: palavras, revisao: revisao);
      await tester.runAsync(() async {
        final leitura = lerFontes(ctx);
        var pronta = false;
        unawaited(leitura.then((_) => pronta = true));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(pronta, isFalse, reason: 'o índice das palavras ainda não ficou pronto');
        dicPronto.complete(dicTeste);
        final f = await leitura;
        expect(f.ingles, isTrue);
        expect(f.incompleta, isFalse);
        expect(f.frasesDevidas, 3);
        expect(f.cartoes, 0);
        expect(f.teimosas, 2);
        expect(f.palavrasDevidas, 1);
        expect(f.palavrasFracas, treinoSemDevidas(palavras, curso.state).length);
        expect(f.palavrasFracas, greaterThan(0), reason: 'a fraca e as nunca treinadas da lição concluída');
        expect(f.temOuvir, isFalse, reason: 'sem OuvirCubit');
        expect(f.quizes, isEmpty);
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await revisao.close();
        await palavras.close();
        await curso.close();
      });
    });

    testWidgets('palavrasFracas = treinoSemDevidas (as nunca treinadas da lição incluídas), sem as sem tradução',
        (tester) async {
      final palavras = (await tester.runAsync(() => palavrasProntas(banco([fraca('window', 'janela'), fraca('zebra', '')]))))!;
      final curso = CursoFixo(estadoEn(concluidas: {'en.casa'}));
      final ctx = await contexto(tester, curso: curso, palavras: palavras);
      final f = (await tester.runAsync(() => lerFontes(ctx)))!;
      final esperadas = treinoSemDevidas(palavras, curso.state);
      expect(f.palavrasFracas, esperadas.length);
      expect([for (final p in esperadas) p.chave], contains('window'));
      expect([for (final p in esperadas) p.chave], isNot(contains('zebra')));
      expect(esperadas.length, greaterThan(1), reason: 'as palavras da lição concluída que nunca foram treinadas');
      expect(f.frasesDevidas, 0, reason: 'sem RevisaoCubit: 0, e não é incompleta');
      expect(f.incompleta, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await palavras.close();
        await curso.close();
      });
    });

    testWidgets('com prazo zero e a revisão travada: incompleta, revisão 0; sem prazo, espera e conta',
        (tester) async {
      // o repositório (com o Completer) nasce na zona de verdade
      final repo = (await tester.runAsync(() async => RepoTravado({'c1': cartaoVencido(), 'c2': cartaoVencido()})))!;
      final revisao = (await tester.runAsync(() async => RevisaoCubit(repo: repo, agora: () => _agora)))!;
      final curso = CursoFixo(estadoEn());
      final ctx = await contexto(tester, curso: curso, revisao: revisao);
      await tester.runAsync(() async {
        final rapida = await lerFontes(ctx, ate: Duration.zero);
        expect(rapida.incompleta, isTrue);
        expect(rapida.frasesDevidas, 0);
        final completa = lerFontes(ctx);
        var pronta = false;
        unawaited(completa.then((_) => pronta = true));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(pronta, isFalse);
        repo.liberar();
        final f = await completa;
        expect(f.incompleta, isFalse);
        expect(f.frasesDevidas, 2);
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await revisao.close();
        await curso.close();
      });
    });

    testWidgets('Dart: as lições concluídas com quiz, a sem nota primeiro e depois a menor nota', (tester) async {
      Trecho tr(String cod, String dica) => Trecho(cod: cod, dica: dica, out: 'ok');
      Licao licao(String id, String nome) => Licao(nome: nome, emoji: '📦', id: id, trechos: [
            tr("if (lista.isNotEmpty) {\n  print(lista.first);\n}", 'evita mexer numa lista vazia'),
            tr("for (var i = 0; i < 3; i++) {\n  print(i);\n}", 'repete três vezes'),
            tr("var nomes = ['Ana', 'Léo'];", 'cria uma lista de nomes'),
            tr("nomes.add('Rui');", 'põe um nome no fim'),
            tr('nomes.removeAt(0);', 'tira o primeiro'),
          ]);
      final curso = CursoFixo(CursoState(
        status: CursoStatus.pronto,
        linguagem: Linguagem.dart,
        trilhas: [
          Trilha(nivel: 'Listas', emoji: '📦', licoes: [
            licao('d.a', 'A'),
            licao('d.b', 'B'),
            licao('d.c', 'C'),
            licao('d.d', 'D'),
          ]),
        ],
        // 'proj:'/'master:' também moram aqui e são ignorados; 'd.d' não foi concluída
        concluidas: const {'d.a', 'd.b', 'd.c', 'proj:0:0', 'master:1'},
        quizNotas: const {'d.a': 9, 'd.b': 3, 'd.d': 1},
      ));
      final ctx = await contexto(tester, curso: curso);
      final f = (await tester.runAsync(() => lerFontes(ctx)))!;
      expect(f.ingles, isFalse);
      expect(f.incompleta, isFalse);
      expect(f.temOuvir, isFalse);
      expect(f.quizes, [(0, 2), (0, 1)]);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(curso.close);
    });

    testWidgets('Dart: a nota é relativa ao tamanho do quiz — 7 de 8 vem antes de um 6 de 6 perfeito',
        (tester) async {
      Licao licao(String id, int n) => Licao(nome: id, emoji: '📦', id: id, trechos: [
            for (var i = 0; i < n; i++) Trecho(cod: 'var x$i = $i;', dica: 'guarda o número $i', out: '$i'),
          ]);
      final curso = CursoFixo(CursoState(
        status: CursoStatus.pronto,
        linguagem: Linguagem.dart,
        trilhas: [
          Trilha(nivel: 'Números', emoji: '🔢', licoes: [licao('d.seis', 6), licao('d.oito', 8), licao('d.dez', 10)]),
        ],
        concluidas: const {'d.seis', 'd.oito', 'd.dez'},
        // em acertos absolutos a ordem seria 6, 7, 9 — e o 6/6 perfeito iria para a revisão
        quizNotas: const {'d.seis': 6, 'd.oito': 7, 'd.dez': 9},
      ));
      final ctx = await contexto(tester, curso: curso);
      final f = (await tester.runAsync(() => lerFontes(ctx)))!;
      expect(f.quizes, [(0, 1), (0, 2)], reason: '7/8 = 87,5% e 9/10 = 90%; o 6/6 fica de fora');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(curso.close);
    });
  });
}

/// O par com a lista virada texto (record com List não compara por valor).
(OrigemPalavras, String)? _lista((OrigemPalavras, List<String>)? e) => e == null ? null : (e.$1, e.$2.join(','));

class _Rotas extends NavigatorObserver {
  int empurradas = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => empurradas++;
}
