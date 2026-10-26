import 'entrada_resposta.dart';
import 'revisao.dart';
import 'roteiro.dart';
import 'srs.dart';

/// 🌱 A "revisão leve" (pedido do dono, 26/out/2026: "o meu está forçando muito a memória, e o aluno desiste"):
/// cada frase da revisão vem com a AJUDA que a memória dela pede — a fraca reaparece escrita e falada antes de
/// ser cobrada, a média vem com blocos, iniciais ou só o áudio, e só a forte vem de memória. A cada revisão
/// certa a frase fica mais forte e a ajuda diminui sozinha; errou, desce um degrau. As PROVAS (da lição, do
/// nivelamento, do certificado) continuam de memória. Dart puro.
enum AjudaRevisao {
  /// 👀 A frase escrita e falada: copiar (o reencontro). Não gera nota — a nota vem de outra volta dela.
  reencontro('👀', 'Reencontro', 'Lembra dessa? Ouça e copie a frase'),

  /// 🧩 Montar com os blocos das palavras.
  montar('🧩', 'Montar', 'Monte a frase com os blocos'),

  /// 🔍 Só a primeira letra de cada palavra.
  iniciais('🔍', 'Iniciais', 'Complete: só as iniciais estão à vista'),

  /// 👂 Ouvir (sem o texto em inglês) e escrever.
  ouvir('👂', 'Ouvir', 'Ouça e escreva o que ouviu'),

  /// ▁ Só os tracinhos: o tamanho de cada palavra.
  esqueleto('▁', 'Tracinhos', 'Só o tamanho das palavras está à vista'),

  /// 🧠 De memória: só a tradução.
  memoria('🧠', 'De memória', 'Digite em inglês, de memória');

  const AjudaRevisao(this.emoji, this.rotulo, this.instrucao);
  final String emoji, rotulo, instrucao;

  /// Como a frase aparece no FraseView.
  ModoFrase get modo => switch (this) {
        reencontro => ModoFrase.ver,
        iniciais => ModoFrase.pistas,
        esqueleto => ModoFrase.esqueleto,
        // os blocos ficam no lugar do texto (como na 🔁 Revisão até aqui)
        montar || ouvir || memoria => ModoFrase.memoria,
      };

  /// Como a pessoa responde.
  EntradaResposta get entrada => this == montar ? EntradaResposta.montar : EntradaResposta.digitar;

  /// O ouvir esconde o português e toca a frase sozinho.
  bool get soAudio => this == ouvir;

  /// Gera nota para a revisão espaçada? (copiar não lembra nada)
  bool get daNota => this != reencontro;

  /// Um degrau mais fácil (para a volta de uma frase errada).
  AjudaRevisao get maisFacil => switch (this) {
        memoria || esqueleto => iniciais,
        ouvir || iniciais => montar,
        montar || reencontro => reencontro,
      };
}

/// A força da memória de uma frase, pelo cartão dela na revisão espaçada.
enum ForcaDaFrase { fraca, media, forte }

/// Fraca: sem cartão, esqueceu depois de aprender (lapso) há pouco, ou lembra por menos de 4 dias.
/// Forte: lembra por 21 dias ou mais. O resto é média.
ForcaDaFrase forcaDe(CartaoSrs? c) {
  if (c == null || c.estabilidade < 4) return ForcaDaFrase.fraca;
  if (c.estabilidade >= 21) return ForcaDaFrase.forte;
  return ForcaDaFrase.media;
}

/// A ajuda da 1ª volta da frase na sessão, pela força dela; entre as opções da mesma força, varia pela frase e
/// pela revisão (o mesmo cartão não vem sempre do mesmo jeito). [podeOuvir] = há som (não está no "não posso
/// escutar"); [podeMontar] = a frase tem palavras para montar.
AjudaRevisao ajudaPelaMemoria(CartaoSrs? c, String cod, {bool podeOuvir = true, bool podeMontar = true}) {
  final opcoes = switch (forcaDe(c)) {
    ForcaDaFrase.fraca => const [AjudaRevisao.reencontro],
    ForcaDaFrase.media => [
        if (podeMontar) AjudaRevisao.montar,
        AjudaRevisao.iniciais,
        if (podeOuvir) AjudaRevisao.ouvir,
      ],
    ForcaDaFrase.forte => const [AjudaRevisao.esqueleto, AjudaRevisao.memoria, AjudaRevisao.memoria],
  };
  final semente = cod.codeUnits.fold<int>(c?.revisoes ?? 0, (h, u) => (h * 31 + u) & 0x7fffffff);
  return opcoes[semente % opcoes.length];
}

/// A nota que vai para a revisão espaçada: de memória e só com os tracinhos valem inteiro; com iniciais, blocos
/// ou só o áudio, o acerto vira "tropeço" (a frase volta um pouco antes, sem zerar); errar é errar. O reencontro
/// (copiar) não dá nota (null).
ResultadoRevisao? notaComAjuda(ResultadoRevisao r, AjudaRevisao a) => switch (a) {
      AjudaRevisao.reencontro => null,
      AjudaRevisao.memoria || AjudaRevisao.esqueleto => r,
      _ => r == ResultadoRevisao.acertou ? ResultadoRevisao.hesitou : r,
    };

/// Um passo da sessão: a frase [indice] (da lista de entrada) com a [ajuda]. [vale] = é o passo que dá a nota
/// da frase (só um por frase).
typedef PassoLeve = ({int indice, AjudaRevisao ajuda, bool vale});

/// A ordem da sessão: cada frase na ajuda de [ajudaDe]; a do reencontro ganha, mais adiante (3 frases depois, ou
/// no fim), uma volta que VALE nota de montar. Tipos misturados: nunca 3 seguidos da mesma ajuda (troca de lugar
/// com o próximo diferente, quando dá).
List<PassoLeve> planoDaSessao(int nFrases, AjudaRevisao Function(int i) ajudaDe) {
  final passos = <PassoLeve>[];
  final pendentes = <(int, int)>[]; // (frase, a partir de que posição a volta pode entrar)
  for (var i = 0; i < nFrases; i++) {
    final a = ajudaDe(i);
    passos.add((indice: i, ajuda: a, vale: a.daNota));
    if (!a.daNota) pendentes.add((i, passos.length + 3));
    // as voltas que já podem entrar
    for (final p in [...pendentes]) {
      if (passos.length >= p.$2) {
        passos.add((indice: p.$1, ajuda: AjudaRevisao.montar, vale: true));
        pendentes.remove(p);
      }
    }
  }
  for (final p in pendentes) {
    passos.add((indice: p.$1, ajuda: AjudaRevisao.montar, vale: true));
  }
  // nunca 3 seguidos do mesmo jeito (e nunca a mesma frase duas vezes seguidas); o reencontro e a volta dele
  // não mudam de lugar (a volta tem de vir depois)
  final comVolta = {for (final p in passos) if (!p.ajuda.daNota) p.indice};
  bool fixo(PassoLeve p) => comVolta.contains(p.indice);
  for (var k = 2; k < passos.length; k++) {
    if (passos[k].ajuda == passos[k - 1].ajuda && passos[k].ajuda == passos[k - 2].ajuda && !fixo(passos[k])) {
      final j = passos.indexWhere(
          (p) => p.ajuda != passos[k].ajuda && p.indice != passos[k - 1].indice && !fixo(p), k + 1);
      if (j > 0) {
        final t = passos[k];
        passos[k] = passos[j];
        passos[j] = t;
      }
    }
  }
  return passos;
}
