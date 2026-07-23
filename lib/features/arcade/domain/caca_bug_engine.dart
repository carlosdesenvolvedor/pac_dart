import 'desafio.dart';

/// Caça-Bug: em cada rodada aparece um trecho com UMA linha defeituosa;
/// clique nela antes de o tempo acabar. Sobrar segundos vale bônus.
class CacaBugEngine {
  final List<DesafioBug> rodadas;

  int rodada = 0;
  int acertos = 0;
  int pontos = 0;

  CacaBugEngine({required this.rodadas});

  bool get terminou => rodada >= rodadas.length;
  DesafioBug get atual => rodadas[rodada];

  /// Tempo da rodada: aperta conforme o nível do bug.
  Duration get tempoRodada => Duration(seconds: (16 - atual.nivel * 2).clamp(6, 14));

  /// Clicou na linha [linha] com [segundosRestantes] no relógio.
  /// Devolve se acertou; a rodada avança dos dois jeitos.
  bool escolher(int linha, int segundosRestantes) {
    if (terminou) return false;
    final acertou = linha == atual.linhaComBug;
    if (acertou) {
      acertos++;
      pontos += 10 + segundosRestantes;
    }
    rodada++;
    return acertou;
  }

  /// O relógio zerou: conta como erro e a rodada passa.
  void estourouTempo() {
    if (terminou) return;
    rodada++;
  }
}
