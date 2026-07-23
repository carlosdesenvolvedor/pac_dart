/// Progresso de digitação de UMA palavra (usado no Rali).
/// Sem backspace: tecla errada só conta erro e a posição não anda.
class ProgressoPalavra {
  String alvo = '';
  int idx = 0;
  int errosPalavra = 0;

  void carregar(String palavra) {
    alvo = palavra;
    idx = 0;
    errosPalavra = 0;
  }

  bool get completa => alvo.isNotEmpty && idx >= alvo.length;

  /// Devolve se a tecla estava certa (comparação exata — Dart tem maiúsculas).
  bool teclar(String ch) {
    if (completa || alvo.isEmpty) return false;
    if (alvo[idx] == ch) {
      idx++;
      return true;
    }
    errosPalavra++;
    return false;
  }
}
