/// Ponte da página com a vista 3D: a página manda o estado do motor a cada
/// tick por aqui (60 Hz) e redesenha o HUD em Flutter só a cada 2 frames —
/// metade do trabalho do CanvasKit, que pesa em GPU fraca.
class Vista3DControlador {
  void Function()? _enviar;
  void Function(int ms)? _abaixarMusica;

  /// A vista registra como receber o estado (null ao sair de cena).
  void ligar(void Function()? enviar) => _enviar = enviar;

  /// A vista 3D registra como abaixar a 🎸 música (null ao sair de cena; a vista em Canvas não tem música).
  void ligarMusica(void Function(int ms)? abaixar) => _abaixarMusica = abaixar;

  /// Manda o estado atual do motor pra cena 3D (no-op sem vista ligada).
  void enviar() => _enviar?.call();

  /// 🔊 Abaixa a música da fase por [ms] (a palavra falada por cima) — o mesmo volume da batida.
  /// No-op sem a vista 3D.
  void abaixarMusica(int ms) => _abaixarMusica?.call(ms);
}
