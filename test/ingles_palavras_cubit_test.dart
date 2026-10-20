// PalavrasCubit: ações antes de carregar, gravações juntadas, treino → cartões FSRS, índice e
// vocabulário dos jogos.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/erros_palavra.dart';
import 'package:pac_dart/features/ingles/domain/palavras_novas.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/domain/teimosas.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';

/// Repositório que só termina de carregar quando o teste mandar.
class _RepoLento implements PalavrasRepository {
  final carregou = Completer<BancoPalavras>();
  final gravados = <BancoPalavras>[];
  Completer<void>? travaGravacao;

  @override
  Future<BancoPalavras> carregar() => carregou.future;

  @override
  Future<void> salvar(BancoPalavras banco) async {
    gravados.add(banco);
    final t = travaGravacao;
    if (t != null) await t.future;
  }
}

const _dic = Dicionario({
  'coffee': 'café',
  'morning': 'manhã',
  'tired': 'cansado',
  'please': 'por favor',
  'the': 'o, a',
});

final _trilhas = [
  const Trilha(nivel: 'T1', emoji: '1', etapa: 'A1 · Fundação', licoes: [
    Licao(nome: 'L1', emoji: '☕', id: 't1.l1', trechos: [
      Trecho(cod: 'Coffee, please.', dica: 'Café, por favor.', out: ''),
      Trecho(cod: 'Good morning, I am tired.', dica: 'Bom dia, estou cansado.', out: ''),
    ]),
  ]),
];

void main() {
  final agora = DateTime(2026, 10, 20, 9);
  final hoje = Revisao.dia(agora);

  PalavrasCubit cubit(PalavrasRepository repo) => PalavrasCubit(
        repo: repo,
        agora: () => agora,
        agendador: AgendadorFsrs(fuzz: false),
        carregarDicionario: () async => _dic,
      );

  test('ações feitas antes de o banco carregar mudam a tela já e entram por cima do que veio gravado', () async {
    final repo = _RepoLento();
    final c = cubit(repo);
    expect(c.adicionar('apple', 'maçã'), isNull);
    c.focar(['apple']);
    expect(c.state.banco['apple']!.pt, 'maçã', reason: 'a tela muda na hora');
    expect(c.state.carregado, isFalse);
    expect(repo.gravados, isEmpty, reason: 'nada é gravado antes de ler');
    repo.carregou.complete(const BancoPalavras().com(const PalavraDoBanco(en: 'pear', pt: 'pera', atualizadoEm: 1)));
    await c.carregar();
    expect(c.state.carregado, isTrue);
    expect(c.state.banco.palavras.keys.toSet(), {'apple', 'pear'});
    expect(c.state.banco.emTreino, ['apple']);
    await c.gravacoes;
    expect(repo.gravados.last, c.state.banco);
    await c.close();
  });

  test('gravações juntam: durante uma gravação lenta, só o estado mais novo vai depois', () async {
    final repo = _RepoLento()..carregou.complete(BancoPalavras.vazio);
    final c = cubit(repo);
    await c.carregar();
    repo.travaGravacao = Completer<void>();
    c.adicionar('apple', 'maçã');
    c.adicionar('pear', 'pera');
    c.adicionar('kiwi', 'kiwi');
    c.alternarJogo('kiwi');
    expect(repo.gravados, hasLength(1));
    repo.travaGravacao!.complete();
    repo.travaGravacao = null;
    await c.gravacoes;
    expect(repo.gravados, hasLength(2));
    expect(repo.gravados.last.palavras.keys.toSet(), {'apple', 'pear', 'kiwi'});
    expect(repo.gravados.last['kiwi']!.noJogo, isFalse);
    await c.close();
  });

  test('adicionar recusa repetida/sem tradução; editar, remover (lápide) e alternarJogo', () async {
    final repo = MemoriaPalavrasRepository();
    final c = cubit(repo);
    await c.carregar();
    expect(c.adicionar('apple', 'maçã'), isNull);
    expect(c.adicionar('Apple', 'maçã'), 'Essa palavra já está no seu banco');
    expect(c.adicionar('ice cream', 'sorvete'), isNotNull);
    expect(c.adicionar('pear', '  '), isNotNull);
    c.editar('apple', pt: 'maçã vermelha');
    expect(c.state.banco['apple']!.pt, 'maçã vermelha');
    c.remover('apple');
    expect(c.state.banco['apple']!.removida, isTrue);
    expect(c.state.banco.tamanho, 0);
    expect(c.adicionar('apple', 'maçã'), isNull, reason: 'a apagada pode voltar');
    await c.gravacoes;
    expect(repo.banco['apple']!.removida, isFalse);
    await c.close();
  });

  test('registrarTreino cria cartões que vencem depois e põe as palavras em treino', () async {
    final c = cubit(MemoriaPalavrasRepository());
    await c.carregar();
    const coffee = PalavraNova(en: 'coffee', pt: 'café', licaoId: 't1.l1');
    const tired = PalavraNova(en: 'tired', pt: 'cansado', licaoId: 't1.l1');
    c.registrarTreino({
      'coffee': (ResultadoRevisao.acertou, coffee),
      'tired': (ResultadoRevisao.errou, tired),
    });
    final b = c.state.banco;
    expect(b['coffee']!.cartao!.proximoDia, greaterThan(hoje));
    expect(b['tired']!.cartao!.proximoDia, greaterThan(hoje));
    expect(b['coffee']!.origem, OrigemPalavra.licao);
    expect(b['coffee']!.licaoId, 't1.l1');
    expect(b.emTreino, containsAll(['coffee', 'tired']));
    expect(c.devidasHoje, isEmpty);
    expect(c.forcaDe('coffee'), isNot(ForcaPalavra.nova));
    // registrarJogo: só contadores, sem mexer no cartão
    final cartao = b['coffee']!.cartao;
    c.registrarJogo({'coffee': (3, 1), 'unknown': (2, 0)});
    expect(c.state.banco['coffee']!.vistasJogo, 3);
    expect(c.state.banco['coffee']!.errosJogo, 1);
    expect(c.state.banco['coffee']!.cartao, cartao);
    expect(c.state.banco['unknown'], isNull, reason: 'vista sem erro não entra no banco');
    await c.close();
  });

  test('registrarJogo: palavra nova só entra com tradução e se não for de função/nome', () async {
    final c = cubit(MemoriaPalavrasRepository());
    await c.carregar();
    // sem índice ainda: fora de tudo não entra (antes entrava com pt vazio)
    c.registrarJogo({'serendipity': (1, 2), 'the': (0, 3)});
    expect(c.state.banco['serendipity'], isNull);
    expect(c.state.banco['the'], isNull, reason: 'palavra de função, mesmo sem índice');
    await c.prepararIndice(_trilhas);
    c.registrarJogo({'serendipity': (1, 2), 'the': (1, 3), 'coffee': (1, 1)});
    expect(c.state.banco['serendipity'], isNull, reason: 'sem tradução nenhuma: não entra');
    expect(c.state.banco['the'], isNull, reason: 'palavra de função não vira "fraca"');
    expect(c.state.banco['coffee']!.pt, 'café');
    expect(c.state.banco['coffee']!.origem, OrigemPalavra.licao);
    // a tradução que o jogo mostrou (palavra solta de "Meus cartões"): entra com ela, origem leitura
    c.registrarJogo({'serendipity': (1, 2)}, traducoes: const {'serendipity': 'acaso feliz'});
    final s = c.state.banco['serendipity']!;
    expect(s.pt, 'acaso feliz');
    expect(s.origem, OrigemPalavra.leitura);
    expect(s.errosJogo, 2);
    // da lista fixa dos jogos: a tradução dela
    final fixa = traducoesEn.keys.firstWhere((k) => !stopwordsEn.contains(k) && !_dic.entradas.containsKey(k));
    c.registrarJogo({fixa: (0, 1)});
    expect(c.state.banco[fixa]!.pt, traducoesEn[fixa]);
    expect(c.state.banco.palavras.values.where((p) => p.pt.isEmpty), isEmpty);
    await c.close();
  });

  test('registrarMemoria: palavra de função não ganha cartão (a não ser que a pessoa a tenha posto)', () async {
    final c = cubit(MemoriaPalavrasRepository());
    await c.carregar();
    await c.prepararIndice(_trilhas);
    expect(c.adicionar('with', 'com'), isNull);
    c.registrarMemoria({
      'the': ResultadoRevisao.acertou,
      'coffee': ResultadoRevisao.acertou,
      'with': ResultadoRevisao.acertou,
    });
    expect(c.state.banco['the'], isNull);
    expect(c.state.banco['coffee']!.cartao, isNotNull);
    expect(c.state.banco['with']!.cartao, isNotNull, reason: 'a própria pessoa adicionou');
    await c.close();
  });

  test('índice, palavras novas da lição e vocabulário dos jogos (só inglês, só com índice)', () async {
    final c = cubit(MemoriaPalavrasRepository());
    await c.carregar();
    final st = CursoState(
      status: CursoStatus.pronto,
      trilhas: _trilhas,
      linguagem: Linguagem.ingles,
      concluidas: const {'t1.l1'},
    );
    expect(c.novasDaLicao(st, _trilhas.first.licoes.first), isEmpty, reason: 'sem índice ainda');
    expect(c.vocabularioJogo(st), isNull);
    final ind = await c.prepararIndice(_trilhas);
    expect(c.state.indice, same(ind));
    expect(c.novasDaLicao(st, _trilhas.first.licoes.first).map((p) => p.en), containsAll(['coffee', 'morning', 'tired']));
    final v = c.vocabularioJogo(st)!;
    expect(v.todas, containsAll(['coffee', 'morning', 'tired']));
    expect(v.traducao('coffee'), 'café');
    expect(c.vocabularioJogo(CursoState(status: CursoStatus.pronto, trilhas: _trilhas)), isNull, reason: 'Dart');
    expect(c.palavrasDoAluno(st).map((p) => p.en), containsAll(['coffee', 'morning', 'tired']));
    await c.close();
  });

  testWidgets('PalavrasCubit.de é null sem o provider', (tester) async {
    var procurou = false;
    PalavrasCubit? achado;
    await tester.pumpWidget(Builder(builder: (context) {
      achado = PalavrasCubit.de(context);
      procurou = true;
      return const SizedBox();
    }));
    expect(procurou, isTrue);
    expect(achado, isNull);
  });

  group('teimosas', () {
    final trilhasT = [
      const Trilha(nivel: 'T1', emoji: '1', etapa: 'A1 · Fundação', licoes: [
        Licao(nome: 'L1', emoji: '☕', id: 't1.l1', trechos: [
          Trecho(cod: 'Coffee, please.', dica: 'Café, por favor.', out: ''),
          Trecho(cod: 'Good morning, I am tired.', dica: 'Bom dia, estou cansado.', out: ''),
          Trecho(cod: 'Mike is tired.', dica: 'O Mike está cansado.', out: '', quem: 'mike'),
        ]),
      ]),
    ];
    // tired: teimosa, último erro anteontem, 1 acerto limpo ontem
    PalavraDoBanco teimosaQuaseDominada() => PalavraDoBanco(
          en: 'tired',
          pt: 'cansado',
          licaoId: 't1.l1',
          cargaErro: 2,
          cargaVistas: 2,
          cargaDia: hoje - 1,
          errosTotal: 3,
          ultimoErroDia: hoje - 2,
          acertosSeguidos: 1,
          ultimoAcertoDia: hoje - 1,
          foiTeimosa: true,
        );
    PalavraDoBanco teimosa(String en) =>
        PalavraDoBanco(en: en, pt: 'pt-$en', cargaErro: 2, cargaVistas: 2, cargaDia: hoje, errosTotal: 3, ultimoErroDia: hoje);

    Future<PalavrasCubit> pronto([BancoPalavras banco = BancoPalavras.vazio, MemoriaPalavrasRepository? repo]) async {
      final c = cubit(repo ?? MemoriaPalavrasRepository(banco));
      await c.carregar();
      await c.prepararIndice(trilhasT);
      return c;
    }

    test('chaveDeTreino: filtros, forma do curso, base do curso, dicionário; null sem índice', () async {
      final c = cubit(MemoriaPalavrasRepository());
      await c.carregar();
      expect(c.chaveDeTreino('coffee'), isNull, reason: 'sem índice nada é capturado');
      await c.prepararIndice(trilhasT);
      expect(c.chaveDeTreino('Coffee'), 'coffee');
      expect(c.chaveDeTreino('coffees'), 'coffee', reason: 'a base do curso');
      expect(c.chaveDeTreino('mornings'), 'morning');
      for (final w in ['the', 'I', 'am', "I'm", 'ab', 'mp3', 'Mike', 'zzzq']) {
        expect(c.chaveDeTreino(w), isNull, reason: w);
      }
      await c.close();
    });

    test('registrarErros: cria só com falha ≥ 1, emite uma vez e devolve as dominadas', () async {
      final c = await pronto();
      final emitidos = <PalavrasState>[];
      final sub = c.stream.listen(emitidos.add);
      final dom = c.registrarErros(const [
        EvidenciaPalavra(chave: 'tired', peso: 1, falha: 1, fonte: FonteErro.licao),
        EvidenciaPalavra(chave: 'coffee', peso: 1, falha: .5, fonte: FonteErro.licao),
        EvidenciaPalavra(chave: 'morning', peso: 1, falha: 0, fonte: FonteErro.licao),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(dom, isEmpty);
      expect(emitidos, hasLength(1));
      final b = c.state.banco;
      expect(b['tired']!.errosTotal, 1);
      expect(b['tired']!.pt, 'cansado');
      expect(b['tired']!.cartao, isNull, reason: 'erro nunca cria cartão');
      expect(b['coffee'], isNull);
      expect(b['morning'], isNull);
      await sub.cancel();
      await c.close();

      final c2 = await pronto(BancoPalavras.vazio.com(teimosaQuaseDominada()));
      expect(c2.registrarErros(const [EvidenciaPalavra(chave: 'tired', peso: 1, falha: 0, fonte: FonteErro.revisao)]),
          ['tired']);
      expect(c2.state.banco['tired']!.dominadaEm, hoje);
      expect(c2.dominadas.map((p) => p.en), ['tired']);
      await c2.close();
    });

    test('registrarJogo com falhas alimenta a carga (peso do jogo, N pelas vistas) sem crédito limpo', () async {
      final c = await pronto();
      c.registrarJogo({'coffee': (2, 1)}, fonte: FonteErro.rali, falhas: {'coffee': 1.0});
      final p = c.state.banco['coffee']!;
      expect(p.errosJogo, 1);
      expect(p.cargaErro, closeTo(.5, 1e-9));
      expect(p.cargaVistas, closeTo(1, 1e-9));
      expect(p.errosTotal, 0);
      c.registrarJogo({'coffee': (1, 1)}, fonte: FonteErro.turismo);
      expect(c.state.banco['coffee']!.cargaErro, closeTo(.5 + .3 * .5, 1e-9), reason: 'f = min(1, erros/2)');
      await c.close();
    });

    test('Chuva pelo registrarJogo: uma partida = uma evidência com teto dos dois lados (falha ≤ 1, N ≤ 2)', () async {
      // copiar uma teimosa 8 vezes numa partida não a tira da lista (antes: N += 4 → 0,58)
      final c = await pronto(BancoPalavras.vazio.com(teimosa('tired')));
      expect(c.teimosas().map((p) => p.en), ['tired']);
      c.registrarJogo({'tired': (8, 0)}, fonte: FonteErro.chuva, falhas: {'tired': 0});
      var p = c.state.banco['tired']!;
      expect(p.cargaVistas, closeTo(2 + .5 * PalavrasCubit.vistasMaxPorPartida, 1e-9));
      expect(pontuacaoTeimosa(p, hoje), closeTo(.92, 1e-9));
      expect(c.teimosas().map((p) => p.en), ['tired']);
      await c.close();

      // 4 quedas em 6 vistas numa partida só: E += 0,5, N += 1 — uma partida sozinha não marca
      final c2 = await pronto();
      c2.registrarJogo({'tired': (2, 4)}, fonte: FonteErro.chuva, falhas: {'tired': 1});
      p = c2.state.banco['tired']!;
      expect((p.cargaErro, p.cargaVistas), (.5, 1.0));
      expect(ehTeimosa(p, hoje), isFalse);
      // mais 3 partidas em que ela só cai: E 2, N 2,5 → pontuação 1,02 → SIM
      for (var i = 0; i < 3; i++) {
        c2.registrarJogo({'tired': (0, 2)}, fonte: FonteErro.chuva, falhas: {'tired': 1});
      }
      p = c2.state.banco['tired']!;
      expect(p.cargaErro, closeTo(2, 1e-9));
      expect(p.cargaVistas, closeTo(2.5, 1e-9));
      expect(ehTeimosa(p, hoje), isTrue);
      expect(p.foiTeimosa, isTrue);
      expect(p.acertosSeguidos, 0, reason: 'jogo nunca dá crédito limpo');
      await c2.close();
    });

    test('registrarTreino devolve as dominadas e não sugere as treinadas até amanhã', () async {
      final c = await pronto(BancoPalavras.vazio.com(teimosaQuaseDominada()).com(teimosa('because')));
      const tired = PalavraNova(en: 'tired', pt: 'cansado', licaoId: 't1.l1');
      const because = PalavraNova(en: 'because', pt: 'porque');
      final dom = c.registrarTreino({
        'tired': (ResultadoRevisao.acertou, tired),
        'because': (ResultadoRevisao.errou, because),
      });
      expect(dom, ['tired']);
      expect(c.state.banco['tired']!.naoSugerirAte, hoje + 1);
      expect(c.state.banco['because']!.naoSugerirAte, hoje + 1);
      expect(c.state.banco['because']!.errosTotal, 4);
      expect(c.state.banco['tired']!.cartao, isNotNull);
      expect(c.teimosas(), isEmpty, reason: 'because adiada até amanhã; tired dominada');
      await c.close();
    });

    test('sugestão: mínimo, mostrada (intervalo), Agora não, aceitar; jaSei; comoPalavraNova; quantas', () async {
      final banco = BancoPalavras.vazio.com(teimosa('because')).com(teimosa('enough')).com(teimosa('though'));
      final c = await pronto(banco);
      expect(c.quantasTeimosas, 3);
      expect(c.sugestao(LocalSugestao.fimDeLicao), isNull, reason: 'sem erro nesta lição');
      final s = c.sugestao(LocalSugestao.fimDeLicao, daSessao: {'coffee': 1.0})!;
      expect(s.daSessao, isFalse);
      expect(s.palavras.first, 'coffee');
      expect(s.itens.first, ('coffee', 'café', 1));
      expect(s.itens.map((i) => i.$1), containsAll(['because', 'enough', 'though']));
      final sessao = c.sugestao(LocalSugestao.fimDeJogo, daSessao: {'coffee': 2.0, 'tired': 1.5})!;
      expect(sessao.daSessao, isTrue);
      expect(sessao.vezes['coffee'], 2);
      c.marcarMostrada();
      expect(c.state.banco.sugestao.mostradasHoje, 1);
      expect(c.sugestao(LocalSugestao.fimDeLicao, daSessao: {'coffee': 2.0, 'tired': 2.0}), isNull, reason: '20 min');
      expect(c.sugestao(LocalSugestao.fimDeRevisao, daSessao: {'coffee': 2.0, 'tired': 2.0}), isNotNull);
      expect(c.adiar(), 1);
      expect(c.sugestao(LocalSugestao.fimDeRevisao, daSessao: {'coffee': 2.0, 'tired': 2.0}), isNull, reason: 'amanhã');
      c.aceitar();
      expect(c.state.banco.sugestao.recusasSeguidas, 0);
      c.jaSei('because');
      expect(c.state.banco['because']!.naoSugerirAte, hoje + 14);
      expect(c.teimosas().map((p) => p.en), isNot(contains('because')));
      expect(c.quantasTeimosas, 2);
      final cafe = c.comoPalavraNova('coffee');
      expect((cafe.en, cafe.pt, cafe.exemplo), ('coffee', 'café', 'Coffee, please.'));
      expect(c.comoPalavraNova('though').pt, 'pt-though', reason: 'fora do curso: a do banco');
      await c.gravacoes;
      await c.close();
    });

    test('licaoDePalavras usa frases do curso e o exemplo de reserva', () async {
      final c = await pronto();
      final st = CursoState(status: CursoStatus.pronto, trilhas: trilhasT, linguagem: Linguagem.ingles, concluidas: const {'t1.l1'});
      final t = c.licaoDePalavras(['tired', 'coffee'], st)!;
      expect(t.titulo, startsWith('🔥 Teimosas · '));
      expect(t.frases.map((f) => f.en), containsAll(['Good morning, I am tired.', 'Coffee, please.']));
      expect(c.licaoDePalavras(['tired', 'coffee'], st, evitar: {'Good morning, I am tired.', 'Mike is tired.'}), isNull);
      await c.close();
    });

    test('gravar poda a entrada só de erro antigo', () async {
      const velha = PalavraDoBanco(en: 'stale', pt: 'velho', cargaErro: .3, cargaVistas: 1, cargaDia: 1, errosTotal: 1, ultimoErroDia: 1);
      final repo = MemoriaPalavrasRepository(BancoPalavras.vazio.com(velha));
      final c = await pronto(BancoPalavras.vazio, repo);
      expect(c.adicionar('apple', 'maçã'), isNull);
      await c.gravacoes;
      expect(repo.banco['stale'], isNull);
      expect(repo.banco['apple'], isNotNull);
      await c.close();
    });
  });
}
