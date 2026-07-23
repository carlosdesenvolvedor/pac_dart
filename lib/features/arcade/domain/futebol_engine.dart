/// Resultado de uma cobrança do Gol de Dart.
enum Chute { gol, defesa }

/// Gol de Dart: disputa de pênaltis em [cobrancas] rodadas. Cada opção de
/// resposta é um canto do gol — acertar o desafio de SINTAXE manda a bola
/// no canto certo (gol); errar entrega nas luvas do goleiro.
class FutebolEngine {
  final int cobrancas;

  int rodada = 0;
  int gols = 0;
  int defesas = 0;

  FutebolEngine({this.cobrancas = 5});

  bool get terminou => rodada >= cobrancas;
  bool get perfeito => gols == cobrancas;

  /// Executa a cobrança da rodada atual.
  Chute chutar({required bool certa}) {
    if (terminou) return Chute.defesa;
    rodada++;
    if (certa) {
      gols++;
      return Chute.gol;
    }
    defesas++;
    return Chute.defesa;
  }

  /// 20 pontos por gol + 30 de bônus pela cobrança perfeita.
  int get pontos => gols * 20 + (perfeito ? 30 : 0);
}
