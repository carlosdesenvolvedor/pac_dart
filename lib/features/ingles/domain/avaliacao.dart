import 'revisao.dart';

/// Como foi uma digitação DE MEMÓRIA (níveis com pistas, esqueleto ou
/// escondida). Cópia não gera nota: copiar acerta quase tudo e não diz nada
/// sobre memória.
class DesempenhoFrase {
  /// Palavras da frase e quantas saíram certas (sem dica e com no máximo 1
  /// tecla errada; palavras de até 3 letras não toleram erro).
  final int palavras, palavrasOk;

  /// Letras reveladas por dica (Tab ou depois de errar duas vezes).
  final int dicas;

  /// Letras da frase (para a proporção de dicas).
  final int letras;

  /// Apertou "não sei" (Esc) e viu a frase.
  final bool desistiu;

  /// Índices das palavras que saíram erradas (para sublinhar no feedback).
  final Set<int> palavrasErradas;

  const DesempenhoFrase({
    required this.palavras,
    required this.palavrasOk,
    this.dicas = 0,
    this.letras = 1,
    this.desistiu = false,
    this.palavrasErradas = const {},
  });

  double get acerto => palavras == 0 ? 1 : palavrasOk / palavras;

  /// Nota (dossiê 01 §4.3, sem a parte de velocidade):
  /// errou = desistiu, menos de 80% das palavras ou dicas em 30%+ das letras;
  /// hesitou = alguma palavra errada ou alguma dica; acertou = limpa.
  ResultadoRevisao get resultado {
    if (desistiu || acerto < .8 || dicas >= letras * .3) return ResultadoRevisao.errou;
    if (acerto < 1 || dicas > 0) return ResultadoRevisao.hesitou;
    return ResultadoRevisao.acertou;
  }
}

/// Uma palavra da frase: onde começa e termina (letras, dígitos e o
/// apóstrofo/hífen de dentro dela).
typedef Palavra = ({int ini, int fim});

/// As palavras de [frase], na ordem.
List<Palavra> palavrasDe(String frase) {
  final r = <Palavra>[];
  final re = RegExp(r"[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*");
  for (final m in re.allMatches(frase)) {
    r.add((ini: m.start, fim: m.end));
  }
  return r;
}

/// Avalia a digitação de [frase] (o texto que valeu — se o motor trocou
/// para uma alternativa, é ela) pelos erros por posição e pelas posições
/// reveladas. [dicasExtras]: ouvir o áudio antes de terminar (DESIGN §2.4).
/// Erro só de maiúscula não entra aqui (TypingState.errosDeCaixa).
DesempenhoFrase avaliarDigitacao(
  String frase, {
  required Map<int, int> errosPorPosicao,
  Set<int> reveladas = const {},
  bool desistiu = false,
  int dicasExtras = 0,
}) {
  final ps = palavrasDe(frase);
  var ok = 0;
  final erradas = <int>{};
  for (var w = 0; w < ps.length; w++) {
    final p = ps[w];
    var erros = 0;
    var revelou = false;
    // erro em espaço/pontuação não é falha de memória: só as letras contam
    for (var i = p.ini; i < p.fim; i++) {
      erros += errosPorPosicao[i] ?? 0;
      if (reveladas.contains(i)) revelou = true;
    }
    final tolera = (p.fim - p.ini) <= 3 ? 0 : 1;
    if (!revelou && erros <= tolera) {
      ok++;
    } else {
      erradas.add(w);
    }
  }
  final letras = RegExp(r'[A-Za-z0-9]').allMatches(frase).length;
  return DesempenhoFrase(
    palavras: ps.length,
    palavrasOk: ok,
    dicas: reveladas.length + dicasExtras,
    letras: letras == 0 ? 1 : letras,
    desistiu: desistiu,
    palavrasErradas: erradas,
  );
}
