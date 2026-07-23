/// Ritmo do rival na Corrida do Código.
enum Dificuldade {
  facil('Fácil', '🐢', 'O rival anda a cada 6s', Duration(seconds: 6), 1.0),
  normal('Normal', '🚗', 'O rival anda a cada 4s', Duration(seconds: 4), 1.5),
  dificil('Difícil', '🚀', 'O rival anda a cada 3s', Duration(seconds: 3), 2.0);

  final String rotulo;
  final String emoji;
  final String descricao;

  /// De quanto em quanto tempo a CPU avança um passo.
  final Duration intervaloCpu;

  /// Multiplicador de pontos da partida.
  final double multiplicador;

  const Dificuldade(this.rotulo, this.emoji, this.descricao, this.intervaloCpu, this.multiplicador);
}

/// Corrida do Código: você avança acertando desafios de LÓGICA; a CPU avança
/// no relógio. Errar derrapa — e ainda dá um passo de graça pro rival.
class CorridaEngine {
  /// Passos até a linha de chegada.
  final int pista;
  final Dificuldade dificuldade;

  int posJogador = 0;
  int posCpu = 0;
  int acertos = 0;
  int erros = 0;

  /// Respostas certas em até [limiteTurbo] — valem passo dobrado.
  int turbos = 0;

  static const limiteTurbo = Duration(seconds: 6);

  CorridaEngine({this.pista = 8, required this.dificuldade});

  bool get terminou => posJogador >= pista || posCpu >= pista;
  bool get venceu => posJogador >= pista;

  /// Resposta do jogador. Certa avança 1 (2 com turbo); errada dá 1 passo
  /// à CPU. Ignorada se a corrida já acabou.
  void responder({required bool certa, required bool turbo}) {
    if (terminou) return;
    if (certa) {
      acertos++;
      if (turbo) turbos++;
      posJogador = (posJogador + (turbo ? 2 : 1)).clamp(0, pista);
    } else {
      erros++;
      posCpu = (posCpu + 1).clamp(0, pista);
    }
  }

  /// Relógio do rival: a CPU anda um passo.
  void tickCpu() {
    if (terminou) return;
    posCpu = (posCpu + 1).clamp(0, pista);
  }

  /// Pontuação da partida (só vale no fim).
  int get pontos {
    final base = acertos * 15 + turbos * 5 + (venceu ? 50 : 10);
    return (base * dificuldade.multiplicador).round();
  }
}
