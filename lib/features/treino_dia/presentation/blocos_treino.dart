import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../arcade/presentation/arcade_page.dart' show treinoSemDevidas;
import '../../arcade/presentation/rali_page.dart';
import '../../curso/domain/quiz.dart' show tamanhoDoQuiz;
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../curso/presentation/fluxo_licao.dart';
import '../../curso/presentation/pages/quiz_page.dart';
import '../../habito/domain/habito.dart' show diaDe;
import '../../ingles/domain/baralhos.dart' show chaveDaFrase;
import '../../ingles/domain/fila_ouvir.dart' show IndiceOuvir;
import '../../ingles/domain/palavras_novas.dart';
import '../../ingles/domain/setlist.dart';
import '../../ingles/presentation/acoes_teimosas.dart';
import '../../ingles/presentation/fixacao.dart';
import '../../ingles/presentation/ouvir/ouvir_acoes.dart' show rotaArcade;
import '../../ingles/presentation/ouvir/ouvir_cubit.dart';
import '../../ingles/presentation/palavras_cubit.dart';
import '../../ingles/presentation/revisao_cubit.dart';
import '../../ingles/presentation/treino_palavras.dart';
import '../domain/montar_plano.dart';
import '../domain/plano_treino.dart';
import 'treino_dia_cubit.dart';

/// A ponte entre o "⚡ Treino do dia" e as sessões que já existem: lê as fontes para montar o plano e
/// abre cada etapa (revisão, palavras, rali, quiz). O plano é atualizado pela página, nunca aqui.

/// Os avisos da faixa quando uma etapa não tinha nada a fazer ao começar ([BlocoVazio]).
abstract final class AvisosTreino {
  static const revisaoEmDia = '✓ Nada vencendo agora — você já está em dia.';
  static const semPalavras = '✓ Nenhuma palavra pendente agora.';
  static const semOuvir = '✓ Nada para ouvir agora.';
  static const semQuiz = '✓ Esta lição não tem quiz agora.';
}

/// O rótulo do botão que devolve a pessoa ao hub (quiz e rali).
const rotuloVoltarAoTreino = 'Continuar o treino →';

/// Lê as fontes (inglês: `RevisaoCubit.carregado`, `PalavrasCubit.carregar()` e depois
/// `prepararIndice(trilhas)`; Dart/C#: o progresso do `CursoBloc`). Nunca lança. Cubit ausente conta
/// 0 (e NÃO é incompleta). Com [ate], para de esperar no prazo e devolve o que tem, com `incompleta =
/// true` se alguma fonte presente não tinha carregado; sem [ate], espera todas.
Future<FontesTreino> lerFontes(BuildContext c, {Duration? ate}) async {
  // tudo capturado antes do 1º await (o contexto pode sumir enquanto espera)
  CursoBloc? curso;
  try {
    curso = BlocProvider.of<CursoBloc>(c, listen: false);
  } catch (_) {}
  final revisao = RevisaoCubit.de(c);
  final palavras = PalavrasCubit.de(c);
  final temOuvir = OuvirCubit.de(c) != null;
  final dia = TreinoDiaCubit.de(c)?.hoje ?? diaDe(DateTime.now());
  if (curso == null) return const FontesTreino();
  // o prazo é um só para todas as fontes (um Timer cancelável: nada fica pendurado depois)
  final prazo = Completer<void>();
  final relogio = ate == null ? null : Timer(ate, prazo.complete);
  try {
    return await _lerFontes(curso, revisao, palavras,
        temOuvir: temOuvir, dia: dia, prazo: ate == null ? null : prazo.future);
  } catch (_) {
    return const FontesTreino(incompleta: true);
  } finally {
    relogio?.cancel();
  }
}

Future<FontesTreino> _lerFontes(CursoBloc curso, RevisaoCubit? revisao, PalavrasCubit? palavras,
    {required bool temOuvir, required int dia, Future<void>? prazo}) async {
  Future<void> esperar(Future<void> f) async {
    final seguro = f.catchError((Object _) {});
    if (prazo == null) return seguro;
    return Future.any([seguro, prazo]);
  }

  final cursoPronto = curso.state.status != CursoStatus.carregando
      ? Future<void>.value()
      : curso.stream.firstWhere((s) => s.status != CursoStatus.carregando).then((_) {});
  await esperar(cursoPronto);
  var st = curso.state;
  if (st.status == CursoStatus.carregando) return const FontesTreino(incompleta: true);

  if (!st.ehIngles) {
    List<(int, int)> quizes = const [];
    try {
      quizes = escolherQuizes(
        concluidas: [
          for (var t = 0; t < st.trilhas.length; t++)
            for (var l = 0; l < st.trilhas[t].licoes.length; l++)
              if (st.licaoConcluida(t, l)) (t, l),
        ],
        // os acertos em ‰ das perguntas do quiz da lição (de 4 a 10): um 6/6 não é pior que um 7/8
        nota: (t, l) {
          final acertos = st.quizNotas[st.chave(t, l)];
          if (acertos == null) return null;
          final n = tamanhoDoQuiz(st.trilhas[t].licoes[l]);
          return n <= 0 ? acertos : acertos * 1000 ~/ n;
        },
        temQuiz: (t, l) => temQuiz(st, t, l),
        dia: dia,
      );
    } catch (_) {}
    return FontesTreino(quizes: quizes);
  }

  // inglês: as duas fontes carregam juntas
  final revisaoPronta = revisao == null || revisao.state.carregado
      ? Future<void>.value()
      : revisao.stream.firstWhere((s) => s.carregado).then((_) {});
  final trilhas = st.trilhas;
  final palavrasProntas = palavras == null
      ? Future<void>.value()
      : palavras.carregar().then((_) => palavras.prepararIndice(trilhas)).then((_) {});
  await Future.wait([esperar(revisaoPronta), esperar(palavrasProntas)]);
  st = curso.state;

  var incompleta = false;
  var frases = 0, cartoes = 0;
  if (revisao != null) {
    if (revisao.state.carregado) {
      try {
        final itens = itensDaRevisao(revisao, st.trilhas);
        frases = itens.diretas.length;
        cartoes = itens.invertidas.length;
      } catch (_) {}
    } else {
      incompleta = true;
    }
  }
  var teimosas = 0, devidas = 0, fracas = 0;
  if (palavras != null) {
    if (palavras.state.carregado && palavras.state.indice != null) {
      try {
        teimosas = _teimosasTreinaveis(palavras).length;
        devidas = _devidasTreinaveis(palavras).length;
        fracas = treinoSemDevidas(palavras, st).where(_treinavel).length;
      } catch (_) {}
    } else {
      incompleta = true;
    }
  }
  return FontesTreino(
    ingles: true,
    frasesDevidas: frases,
    cartoes: cartoes,
    teimosas: teimosas,
    palavrasDevidas: devidas,
    palavrasFracas: fracas,
    temOuvir: temOuvir,
    incompleta: incompleta,
  );
}

/// Como uma etapa terminou.
sealed class FimDoBloco {
  const FimDoBloco();
}

/// Feita: o resultado (revisadas, palavras, pontos, acertos…) e o que o plano anota.
class BlocoFeito extends FimDoBloco {
  final int resultado;

  /// Só quiz: o total de perguntas.
  final int total;

  /// Revisão: `chaveDaFrase` das frases respondidas (o trecho do 🎧 Ouvir).
  final List<String> chavesOuvir;

  /// Palavras: as palavras (EN) treinadas (o foco do 🏁 Rali).
  final List<String> foco;

  const BlocoFeito({this.resultado = 0, this.total = 0, this.chavesOuvir = const [], this.foco = const []});
}

/// Nada a fazer quando começou → feita com 0, `vazio: true`, e o aviso na faixa.
class BlocoVazio extends FimDoBloco {
  final String aviso;
  const BlocoVazio(this.aviso);
}

/// Saiu no meio → continua pendente.
class BlocoInterrompido extends FimDoBloco {
  const BlocoInterrompido();
}

/// `abrirRevisao(limiteFrases: 8, limiteCartoes: 4, modoTreino: true)`.
Future<FimDoBloco> rodarRevisao(BuildContext c) async {
  if (RevisaoCubit.de(c) == null) return const BlocoVazio(AvisosTreino.revisaoEmDia);
  final fim = await abrirRevisao(c,
      limiteFrases: LimitesTreino.frases, limiteCartoes: LimitesTreino.cartoes, modoTreino: true);
  if (!fim.terminou) return const BlocoInterrompido();
  // nada vencia quando a etapa começou (revisou em outro lugar no meio-tempo)
  if (fim.respondidas == 0) return const BlocoVazio(AvisosTreino.revisaoEmDia);
  final vistas = <String>{};
  return BlocoFeito(
    resultado: fim.respondidas,
    chavesOuvir: [
      for (final f in fim.revisadas)
        if (vistas.add(chaveDaFrase(f))) chaveDaFrase(f),
    ].take(LimitesTreino.ouvir).toList(),
  );
}

/// Teimosas > devidas > fracas (até 6), em modo treino.
Future<FimDoBloco> rodarPalavras(BuildContext c) async {
  final cubit = PalavrasCubit.de(c);
  CursoState? st;
  try {
    st = BlocProvider.of<CursoBloc>(c, listen: false).state;
  } catch (_) {}
  if (cubit == null || st == null) return const BlocoVazio(AvisosTreino.semPalavras);
  // as teimosas podem ter nascido na revisão de agora: a escolha é feita só aqui, na hora
  final escolha = _escolher(cubit, st);
  if (escolha == null) return const BlocoVazio(AvisosTreino.semPalavras);
  final (origem, lista) = escolha;
  final r = await switch (origem) {
    OrigemPalavras.teimosas =>
      treinarTeimosas(c, [for (final p in lista) p.chave], origem: 'treinoDoDia', modoTreino: true),
    OrigemPalavras.devidas => abrirTreinoPalavras(c, lista, titulo: '🔤 Palavras do dia', modoTreino: true),
    OrigemPalavras.fracas => abrirTreinoPalavras(c, lista, titulo: '🔤 Treino de palavras', modoTreino: true),
  };
  if (r == null) return const BlocoInterrompido();
  final vistas = <String>{};
  return BlocoFeito(
    resultado: r.palavras.length,
    foco: [
      for (final p in r.palavras)
        if (p.deJogo && vistas.add(p.chave)) p.en,
    ],
  );
}

/// Inglês: `focar(p.palavrasFoco)`; todos: `RaliPage(treino: true)`.
Future<FimDoBloco> rodarRali(BuildContext c, PlanoTreino p) async {
  final nav = Navigator.of(c);
  final palavras = PalavrasCubit.de(c);
  CursoState? st;
  try {
    st = BlocProvider.of<CursoBloc>(c, listen: false).state;
  } catch (_) {}
  if (palavras != null && st != null && st.ehIngles) {
    // o vocabulário dos jogos precisa do índice; as palavras do treino vêm primeiro (~30 min no Arcade)
    try {
      await palavras.prepararIndice(st.trilhas);
    } catch (_) {}
    if (p.palavrasFoco.isNotEmpty) palavras.focar(p.palavrasFoco);
  }
  if (!nav.mounted) return const BlocoInterrompido();
  final r = await nav.push(MaterialPageRoute<ResultadoFaseTreino>(
    builder: (_) => const RaliPage(treino: true),
    settings: const RouteSettings(name: rotaArcade),
  ));
  // ganhou ou perdeu, a fase foi jogada; pausa → Sair volta null (fica pendente)
  return r == null ? const BlocoInterrompido() : BlocoFeito(resultado: r.pontos);
}

/// `QuizPage(emSequencia: false, semente: sementeQuiz(t,l) ^ (dia * 7919), rotuloFim:, onTerminou:)`.
Future<FimDoBloco> rodarQuiz(BuildContext c, BlocoTreino b, int dia) async {
  CursoState? st;
  try {
    st = BlocProvider.of<CursoBloc>(c, listen: false).state;
  } catch (_) {}
  if (st == null ||
      b.t < 0 ||
      b.t >= st.trilhas.length ||
      b.l < 0 ||
      b.l >= st.trilhas[b.t].licoes.length ||
      !temQuiz(st, b.t, b.l)) {
    return const BlocoVazio(AvisosTreino.semQuiz);
  }
  final trilha = st.trilhas[b.t];
  (int, int)? fim;
  await Navigator.of(c).push(MaterialPageRoute<bool>(
    builder: (_) => QuizPage(
      trilhaIdx: b.t,
      licaoIdx: b.l,
      licao: trilha.licoes[b.l],
      poolTrilha: poolDaTrilha(trilha),
      // false de propósito: sem "A seguir: a próxima lição", sem "Pular quiz" em cima do "Pular esta etapa"
      emSequencia: false,
      semente: sementeQuiz(b.t, b.l) ^ (dia * 7919),
      rotuloFim: rotuloVoltarAoTreino,
      onTerminou: (acertos, total) => fim ??= (acertos, total),
    ),
  ));
  final f = fim;
  return f == null ? const BlocoInterrompido() : BlocoFeito(resultado: f.$1, total: f.$2);
}

/// O trecho do 🎧 Ouvir, no máximo [max] FRASES (faixas): `ouvirChaves` (um item `daFrase` cada) →
/// a última lição concluída (UM item `doTrecho` com ≤ [max] trechos) → a lição atual. Vazio fora do
/// inglês. O número de itens NÃO é o alvo: o painel usa `ouvir.state.fila.length` depois de tocar.
List<ItemSetlist> trechoParaOuvir(CursoState st, PlanoTreino p, {int max = LimitesTreino.ouvir}) {
  if (!st.ehIngles || st.trilhas.isEmpty || max <= 0) return const [];
  // 1. as frases que a pessoa acabou de revisar
  if (p.ouvirChaves.isNotEmpty) {
    final indice = IndiceOuvir.de(st.trilhas);
    final itens = <ItemSetlist>[];
    for (final k in p.ouvirChaves) {
      if (itens.length >= max) break;
      final pos = indice.frase(k);
      if (pos == null) continue;
      final licao = st.trilhas[pos.t].licoes[pos.l];
      itens.add(ItemSetlist.daFrase(licao.trechos[pos.f], licao: licao));
    }
    if (itens.isNotEmpty) return itens;
  }
  // 2. a última lição concluída do curso (a de maior (t,l), fora os textos da pessoa)
  for (var t = st.trilhas.length - 1; t >= 0; t--) {
    final tr = st.trilhas[t];
    if (tr.propria) continue;
    for (var l = tr.licoes.length - 1; l >= 0; l--) {
      if (!st.licaoConcluida(t, l) || tr.licoes[l].trechos.isEmpty) continue;
      return [ItemSetlist.doTrecho(tr.licoes[l], tr.licoes[l].trechos.take(max).toList())];
    }
  }
  // 3. a lição atual (uma prévia do que vem)
  if (st.trilhaIdx < 0 || st.trilhaIdx >= st.trilhas.length) return const [];
  final tr = st.trilhas[st.trilhaIdx];
  if (st.licaoIdx < 0 || st.licaoIdx >= tr.licoes.length) return const [];
  final atual = tr.licoes[st.licaoIdx];
  if (atual.trechos.isEmpty) return const [];
  return [ItemSetlist.doTrecho(atual, atual.trechos.take(max).toList())];
}

/// De onde vieram as palavras da etapa 🔥 Palavras.
enum OrigemPalavras { teimosas, devidas, fracas }

/// Puro (testável sem widgets): cada fonte é filtrada para palavras TREINÁVEIS (en e pt não vazios)
/// ANTES de escolher; null quando nada treinável sobra (→ [BlocoVazio]).
(OrigemPalavras, List<String>)? escolherPalavras(PalavrasCubit c, CursoState st,
    {int max = LimitesTreino.palavras}) {
  final e = _escolher(c, st, max: max);
  return e == null ? null : (e.$1, [for (final p in e.$2) p.chave]);
}

(OrigemPalavras, List<PalavraNova>)? _escolher(PalavrasCubit c, CursoState st, {int max = LimitesTreino.palavras}) {
  if (max <= 0) return null;
  final teimosas = _teimosasTreinaveis(c);
  if (teimosas.isNotEmpty) return (OrigemPalavras.teimosas, teimosas.take(max).toList());
  final devidas = _devidasTreinaveis(c);
  if (devidas.isNotEmpty) return (OrigemPalavras.devidas, devidas.take(max).toList());
  final fracas = treinoSemDevidas(c, st).where(_treinavel).toList();
  if (fracas.isNotEmpty) return (OrigemPalavras.fracas, fracas.take(max).toList());
  return null;
}

/// A mesma regra de `treinarTeimosas` / `treinoSemDevidas`: dá para treinar só com inglês E tradução.
bool _treinavel(PalavraNova p) => p.en.trim().isNotEmpty && p.pt.trim().isNotEmpty;

/// As teimosas de hoje como o treino vai vê-las (`comoPalavraNova`), sem repetir, só as treináveis.
List<PalavraNova> _teimosasTreinaveis(PalavrasCubit c) {
  final vistas = <String>{};
  return [
    for (final p in c.teimosas(max: 1 << 30))
      if (vistas.add(p.chave)) c.comoPalavraNova(p.chave),
  ].where(_treinavel).toList();
}

/// As palavras do banco que vencem hoje (as mais atrasadas primeiro), só as treináveis.
List<PalavraNova> _devidasTreinaveis(PalavrasCubit c) =>
    [for (final p in c.devidasHoje) p.comoPalavraNova].where(_treinavel).toList();
