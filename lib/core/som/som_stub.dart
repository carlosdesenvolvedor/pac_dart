import 'sons.dart';

/// Fora da web (testes na VM, desktop sem áudio): silêncio educado — vale
/// para todos os efeitos, inclusive a âncora do inglês.
void tocar(Som som) {}

/// Fora da web não há política de autoplay: sempre "liberado".
bool get liberado => true;

/// Fora da web não há motor pra roncar.
void motorRonco(double intensidade) {}

void motorParar() {}
