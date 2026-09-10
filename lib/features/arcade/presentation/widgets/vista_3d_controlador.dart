/// Ponte da página com a vista 3D: a página manda o estado do motor a cada
/// tick por aqui (60 Hz) e redesenha o HUD em Flutter só a cada 2 frames —
/// metade do trabalho do CanvasKit, que pesa em GPU fraca.
class Vista3DControlador {
  void Function()? _enviar;

  /// A vista registra como receber o estado (null ao sair de cena).
  void ligar(void Function()? enviar) => _enviar = enviar;

  /// Manda o estado atual do motor pra cena 3D (no-op sem vista ligada).
  void enviar() => _enviar?.call();
}
