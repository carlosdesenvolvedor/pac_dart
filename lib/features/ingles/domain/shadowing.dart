import 'package:equatable/equatable.dart';

import 'avaliacao.dart' show palavrasDe;
import 'avaliacao_fala.dart';
import 'comparar_resposta.dart';
import 'srs.dart';

/// Shadowing (Fase 3, parte 2): a pessoa OUVE a frase (sem vê-la), REPETE falando e a fala é
/// conferida palavra por palavra pelo reconhecedor ([avaliarFala]). Aqui só a regra, em Dart puro:
/// as tentativas, a nota que combina e a conferência no formato que o cartão já mostra.

/// Quantas vezes a pessoa pode tentar antes de a frase aparecer.
const maxTentativasShadowing = 3;

/// A partir de que fração de palavras certas (na melhor tentativa) ainda vale "Difícil".
const limiarShadowing = 0.70;

/// A nota que combina com o resultado. Perfeita de primeira = Bom; perfeita depois de tentar de novo,
/// ou boa o bastante ([limiarShadowing]) = Difícil; menos que isso, desistir ou não falar = Errei.
/// "Fácil" só a pessoa escolhe (como na conferência escrita).
Rating notaDoShadowing({required int tentativas, required AvaliacaoFala? melhor, bool desistiu = false}) {
  if (desistiu || melhor == null || tentativas <= 0) return Rating.again;
  if (melhor.perfeita) return tentativas == 1 ? Rating.good : Rating.hard;
  if (melhor.palavras > 0 && melhor.acertos / melhor.palavras >= limiarShadowing) return Rating.hard;
  return Rating.again;
}

/// As tentativas de UM cartão. Imutável: cada fala conferida gera uma sessão nova.
class SessaoShadowing extends Equatable {
  final List<AvaliacaoFala> tentativas;
  const SessaoShadowing([this.tentativas = const []]);

  /// Perfeita, ou já gastou todas as tentativas: o cartão vira.
  bool get encerrou => perfeita || tentativas.length >= maxTentativasShadowing;

  bool get perfeita => tentativas.any((t) => t.perfeita);

  /// A tentativa de mais acertos (em empate, a primeira).
  AvaliacaoFala? get melhor {
    AvaliacaoFala? m;
    for (final t in tentativas) {
      if (m == null || t.acertos > m.acertos) m = t;
    }
    return m;
  }

  /// A fala conferida. O reconhecedor que não ouviu palavra nenhuma NÃO é tentativa (não castiga);
  /// depois de encerrar nada entra.
  SessaoShadowing registrar(AvaliacaoFala a) {
    if (a.nada || encerrou) return this;
    return SessaoShadowing([...tentativas, a]);
  }

  Rating notaSugerida({bool desistiu = false}) =>
      notaDoShadowing(tentativas: tentativas.length, melhor: melhor, desistiu: desistiu);

  @override
  List<Object?> get props => [tentativas];
}

/// A melhor tentativa no formato do cartão (a frase com as palavras certas/erradas marcadas e o que foi
/// ouvido), para a tela reaproveitar o verso e o "sua resposta". Null sem tentativa. [sugerida] é a nota.
ComparacaoResposta? comparacaoDoShadowing(String frase, SessaoShadowing s, {required Rating sugerida}) {
  final m = s.melhor;
  if (m == null) return null;
  final esperada = <Segmento>[];
  var pos = 0;
  final ps = palavrasDe(frase);
  for (var w = 0; w < ps.length; w++) {
    if (ps[w].ini > pos) esperada.add(Segmento(frase.substring(pos, ps[w].ini)));
    esperada.add(Segmento(frase.substring(ps[w].ini, ps[w].fim), w < m.palavrasOk.length ? m.palavrasOk[w] : false));
    pos = ps[w].fim;
  }
  if (pos < frase.length) esperada.add(Segmento(frase.substring(pos)));
  final ouvidas = <Segmento>[];
  for (var i = 0; i < m.ouvidas.length; i++) {
    if (i > 0) ouvidas.add(const Segmento(' '));
    ouvidas.add(Segmento(m.ouvidas[i], m.ouvidaCasou[i]));
  }
  final casadas = m.ouvidaCasou.where((b) => b).length;
  return ComparacaoResposta(
    esperada: esperada,
    digitada: ouvidas,
    cobertura: m.palavras == 0 ? 0 : m.acertos / m.palavras,
    precisao: m.ouvidas.isEmpty ? 0 : casadas / m.ouvidas.length,
    exata: m.perfeita,
    sugerida: sugerida,
  );
}
