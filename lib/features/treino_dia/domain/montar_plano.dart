import 'dart:math' as math;

import 'plano_treino.dart';

/// O que há para o treino de hoje, já contado (a leitura dos cubits mora em `lerFontes`).
///
/// Plano FASE-9 §5.1.
class FontesTreino {
  final bool ingles;

  /// Frases de memória (sentido direto) que vencem e têm frase no curso, antes do limite.
  final int frasesDevidas;

  /// Cartões invertidos que vencem + os novos que cabem na cota do dia, antes do limite.
  final int cartoes;

  /// Só palavras TREINÁVEIS (en e pt não vazios). [palavrasFracas] = `treinoSemDevidas(...).length`
  /// (inclui as `palavrasDoAluno` nunca treinadas).
  final int teimosas, palavrasDevidas, palavrasFracas;

  /// Há `OuvirCubit` (só no inglês).
  final bool temOuvir;

  /// Dart/C#: as lições candidatas ao quiz de revisão, já em ordem ([escolherQuizes]).
  final List<(int, int)> quizes;

  /// Alguma fonte ainda não tinha carregado quando estes números foram lidos.
  final bool incompleta;

  const FontesTreino({
    this.ingles = false,
    this.frasesDevidas = 0,
    this.cartoes = 0,
    this.teimosas = 0,
    this.palavrasDevidas = 0,
    this.palavrasFracas = 0,
    this.temOuvir = false,
    this.quizes = const [],
    this.incompleta = false,
  });
}

/// Os limites do plano e de cada etapa quando ela começa.
abstract final class LimitesTreino {
  static const frases = 8, cartoes = 4, palavras = 6, ouvir = 6, quizes = 2;
}

/// Monta o plano do dia a partir de [f] (tabela no plano FASE-9 §5.1). `incompleto = f.incompleta`.
PlanoTreino montarPlano(FontesTreino f, {required int dia, required String curso, required int agoraMs}) {
  final blocos = [
    ..._blocosAtivos(f),
    if (f.ingles && f.temOuvir) const BlocoTreino(id: 'ouvir', tipo: TipoBloco.ouvir, qtd: LimitesTreino.ouvir),
    const BlocoTreino(id: 'rali', tipo: TipoBloco.rali, minutos: 2),
  ];
  return PlanoTreino(
    dia: dia,
    curso: curso,
    blocos: blocos,
    curto: PlanoTreino.curtoDe(blocos),
    incompleto: f.incompleta,
    editadoEm: agoraMs,
  );
}

/// As etapas de estudo ativo (revisão/palavras no inglês; quizzes no Dart/C#), na ordem do plano.
List<BlocoTreino> _blocosAtivos(FontesTreino f) {
  if (!f.ingles) {
    return [
      for (final (t, l) in f.quizes.take(LimitesTreino.quizes))
        BlocoTreino(id: 'quiz:$t:$l', tipo: TipoBloco.quiz, qtd: 10, minutos: 4, t: t, l: l),
    ];
  }
  final frases = math.min(LimitesTreino.frases, math.max(0, f.frasesDevidas));
  final cartoes = math.min(LimitesTreino.cartoes, math.max(0, f.cartoes));
  final palavras = [f.teimosas, f.palavrasDevidas, f.palavrasFracas].firstWhere((n) => n > 0, orElse: () => 0);
  return [
    if (frases + cartoes > 0)
      BlocoTreino(
        id: 'revisao',
        tipo: TipoBloco.revisao,
        qtd: frases,
        qtd2: cartoes,
        minutos: math.max(1, ((frases * 25 + cartoes * 10) / 60).ceil()),
      ),
    if (palavras > 0)
      BlocoTreino(
        id: 'palavras',
        tipo: TipoBloco.palavras,
        qtd: math.min(LimitesTreino.palavras, palavras),
        minutos: 2,
      ),
  ];
}

/// Melhora um plano `incompleto`/`curto`: as etapas ativas que [montarPlano] daria com [f] e que [p]
/// ainda não tem. Devolve [p] sem mudar quando `p.algumAtivoResolvido`.
///
/// Os quizzes novos só entram até completar [LimitesTreino.quizes] no plano.
PlanoTreino completarPlano(PlanoTreino p, FontesTreino f, {required int agoraMs}) {
  if (p.concluido || p.algumAtivoResolvido) return p;
  final ids = {for (final b in p.blocos) b.id};
  var quizes = p.blocos.where((b) => b.tipo == TipoBloco.quiz).length;
  final novos = <BlocoTreino>[];
  for (final b in _blocosAtivos(f)) {
    if (ids.contains(b.id)) continue;
    if (b.tipo == TipoBloco.quiz) {
      if (quizes >= LimitesTreino.quizes) continue;
      quizes++;
    }
    novos.add(b);
  }
  return p.completar(novos, fontesCompletas: !f.incompleta, agoraMs: agoraMs);
}

/// Dart/C#: as lições concluídas que têm quiz. Primeiro as sem nota, depois a menor nota (relativa
/// ao tamanho do quiz: ver [nota]); empates giram com [dia] (hash estável de `dia*31+t*1009+l`). No máximo [max].
///
/// [temQuiz] é caro (roda `gerarQuiz`): só é chamado percorrendo os candidatos já ordenados, e para
/// assim que achar [max].
List<(int, int)> escolherQuizes({
  /// (t,l) das lições concluídas, montado percorrendo trilhas/lições com `st.licaoConcluida(t,l)` —
  /// nunca lendo `concluidas` (que também guarda 'proj:', 'master:' e 'desafio:').
  required List<(int, int)> concluidas,

  /// A nota RELATIVA ao tamanho do quiz (o `lerFontes` passa os acertos de `st.quizNotas` em ‰ das
  /// perguntas da lição): os quizzes têm de 4 a 10 perguntas, e um 6/6 não é pior que um 7/8. Null =
  /// lição sem nota.
  required int? Function(int t, int l) nota,

  /// `(t,l) => temQuiz(st, t, l)`.
  required bool Function(int t, int l) temQuiz,
  required int dia,
  int max = LimitesTreino.quizes,
}) {
  if (max <= 0) return const [];
  final candidatas = <(int, int)>{...concluidas}.toList();
  final notas = {for (final c in candidatas) c: nota(c.$1, c.$2)};
  final giro = {for (final c in candidatas) c: _mistura(dia * 31 + c.$1 * 1009 + c.$2)};
  candidatas.sort((a, b) {
    final na = notas[a], nb = notas[b];
    if ((na == null) != (nb == null)) return na == null ? -1 : 1;
    if (na != null && nb != null && na != nb) return na.compareTo(nb);
    final g = giro[a]!.compareTo(giro[b]!);
    if (g != 0) return g;
    return a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2);
  });
  final escolhidas = <(int, int)>[];
  for (final c in candidatas) {
    if (escolhidas.length >= max) break;
    if (temQuiz(c.$1, c.$2)) escolhidas.add(c);
  }
  return escolhidas;
}

/// Hash estável e barato (o mesmo no app e na web: tudo cabe em 31 bits e nenhum produto passa de 2^53).
int _mistura(int x) {
  x &= 0x7fffffff;
  x = ((x ^ (x >> 15)) * 0x2c1b3) & 0x7fffffff;
  x = ((x ^ (x >> 13)) * 0x297a2d) & 0x7fffffff;
  return x ^ (x >> 16);
}
