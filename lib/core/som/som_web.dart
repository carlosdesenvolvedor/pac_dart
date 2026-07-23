import 'package:web/web.dart';

import 'sons.dart';

/// Sintetizador 8-bit com Web Audio: cada efeito é um punhado de
/// osciladores com envelope, agendados no relógio do próprio AudioContext.
AudioContext? _ctx;
bool _wakaAlterna = false;

AudioContext get _audio {
  final ctx = _ctx ??= AudioContext();
  // navegadores suspendem áudio até o primeiro gesto — como todo `tocar`
  // nasce de tecla/clique, dá pra retomar aqui mesmo.
  if (ctx.state == 'suspended') ctx.resume();
  return ctx;
}

/// Uma "nota": oscilador [tipo] indo de [de] a [ate] Hz em [dur] segundos,
/// com ataque instantâneo e decaimento exponencial. [atraso] agenda no futuro.
void _nota(
  String tipo,
  double de,
  double ate,
  double dur, {
  double atraso = 0,
  double volume = .14,
}) {
  final ctx = _audio;
  final t0 = ctx.currentTime + atraso;
  final osc = ctx.createOscillator()..type = tipo;
  osc.frequency.setValueAtTime(de, t0);
  if (ate != de) osc.frequency.exponentialRampToValueAtTime(ate, t0 + dur);
  final ganho = ctx.createGain();
  ganho.gain.setValueAtTime(volume, t0);
  ganho.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
  osc.connect(ganho);
  ganho.connect(ctx.destination);
  osc.start(t0);
  osc.stop(t0 + dur + .02);
}

void tocar(Som som) {
  switch (som) {
    case Som.waka:
      _wakaAlterna = !_wakaAlterna;
      _wakaAlterna
          ? _nota('triangle', 420, 190, .07, volume: .10)
          : _nota('triangle', 190, 420, .07, volume: .10);
    case Som.erro:
      _nota('square', 130, 95, .12, volume: .09);
    case Som.blip:
      _nota('sine', 660, 990, .09);
    case Som.tiro:
      _nota('square', 950, 220, .08, volume: .10);
    case Som.explosao:
      _nota('square', 320, 55, .18, volume: .13);
      _nota('sawtooth', 200, 40, .22, volume: .07);
    case Som.turbo:
      _nota('sawtooth', 220, 920, .20, volume: .11);
    case Som.gol:
      _nota('square', 523, 523, .09);
      _nota('square', 659, 659, .09, atraso: .09);
      _nota('square', 784, 784, .14, atraso: .18);
    case Som.defesa:
      _nota('sine', 330, 140, .22, volume: .12);
    case Som.fanfarra:
      _nota('square', 523, 523, .11);
      _nota('square', 659, 659, .11, atraso: .11);
      _nota('square', 784, 784, .11, atraso: .22);
      _nota('square', 1047, 1047, .26, atraso: .33);
    case Som.fase:
      _nota('triangle', 392, 392, .09);
      _nota('triangle', 523, 523, .09, atraso: .09);
      _nota('triangle', 659, 659, .16, atraso: .18);
    case Som.tique:
      _nota('sine', 520, 520, .05, volume: .07);
    case Som.decolar:
      _nota('sawtooth', 180, 1250, .45, volume: .10);
    case Som.misterio:
      _nota('sine', 880, 440, .30, volume: .10);
      _nota('sine', 1108, 554, .30, atraso: .05, volume: .06);
  }
}
