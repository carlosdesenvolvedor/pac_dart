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

/// A página já recebeu um gesto do usuário (tecla, clique, toque)? Antes
/// disso o navegador não deixa tocar nada: o AudioContext nasce suspenso, o
/// `<audio>.play()` é recusado e o `speechSynthesis` fica mudo. Navegador
/// sem a API (Safari < 16.4): supõe que sim, como antes.
bool get liberado {
  try {
    return window.navigator.userActivation.hasBeenActive;
  } catch (_) {
    return true;
  }
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

/// Um sino: senoide com ataque macio (sem o "clique" do ataque instantâneo)
/// e cauda longa, mais um parcial agudo e curto que dá o brilho de metal.
void _sino(double freq, double dur, {double atraso = 0, double volume = .05}) {
  final ctx = _audio;
  final t0 = ctx.currentTime + atraso;
  void parcial(double f, double d, double v) {
    final osc = ctx.createOscillator()..type = 'sine';
    osc.frequency.setValueAtTime(f, t0);
    final ganho = ctx.createGain();
    ganho.gain.setValueAtTime(0.0001, t0);
    ganho.gain.linearRampToValueAtTime(v, t0 + .018);
    ganho.gain.exponentialRampToValueAtTime(0.0001, t0 + d);
    osc.connect(ganho);
    ganho.connect(ctx.destination);
    osc.start(t0);
    osc.stop(t0 + d + .05);
  }

  parcial(freq, dur, volume);
  parcial(freq * 2.76, dur * .35, volume * .22); // parcial inarmônico de sino
}

void tocar(Som som) {
  // sem gesto ainda: as notas ficariam agendadas no relógio parado do
  // contexto suspenso e sairiam todas juntas na primeira tecla
  if (!liberado) return;
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
    case Som.combo:
      _nota('square', 784, 784, .07, volume: .10);
      _nota('square', 1175, 1175, .12, atraso: .07, volume: .10);
    case Som.largada:
      _nota('square', 880, 880, .28, volume: .13);
      _nota('triangle', 1760, 1760, .28, volume: .06);
    case Som.ancora:
      // dó–mi–sol–si dedilhado e deixado soar: calmo, nada de fliperama
      _sino(523.25, 1.9, volume: .055);
      _sino(659.25, 1.8, atraso: .07, volume: .045);
      _sino(783.99, 1.7, atraso: .14, volume: .04);
      _sino(987.77, 1.6, atraso: .21, volume: .03);
  }
}


// ---------- ronco do motor (Dart Turismo) ----------
// Duas ondas (serra grave + quadrada uma oitava acima) num passa-baixas:
// rumor de motor que sobe de tom e abre o filtro com a velocidade.
OscillatorNode? _motorOsc;
OscillatorNode? _motorOsc2;
GainNode? _motorGanho;
BiquadFilterNode? _motorFiltro;

void motorRonco(double intensidade) {
  final ctx = _audio;
  if (_motorOsc == null) {
    final filtro = ctx.createBiquadFilter()..type = 'lowpass';
    filtro.frequency.value = 320;
    filtro.Q.value = 1.1;
    final ganho = ctx.createGain();
    ganho.gain.value = 0;
    final osc = ctx.createOscillator()..type = 'sawtooth';
    osc.frequency.value = 44;
    final osc2 = ctx.createOscillator()..type = 'square';
    osc2.frequency.value = 88.5;
    osc.connect(filtro);
    osc2.connect(filtro);
    filtro.connect(ganho);
    ganho.connect(ctx.destination);
    osc.start();
    osc2.start();
    _motorOsc = osc;
    _motorOsc2 = osc2;
    _motorGanho = ganho;
    _motorFiltro = filtro;
  }
  final t = ctx.currentTime;
  _motorOsc!.frequency.setTargetAtTime(44 + 130 * intensidade, t, .1);
  _motorOsc2!.frequency.setTargetAtTime(88.5 + 260 * intensidade, t, .1);
  _motorFiltro!.frequency.setTargetAtTime(280 + 1100 * intensidade, t, .15);
  _motorGanho!.gain.setTargetAtTime(.01 + .05 * intensidade, t, .12);
}

void motorParar() {
  final ganho = _motorGanho;
  if (ganho == null) return;
  final ctx = _audio;
  ganho.gain.setTargetAtTime(0, ctx.currentTime, .06);
  _motorOsc?.stop(ctx.currentTime + .4);
  _motorOsc2?.stop(ctx.currentTime + .4);
  _motorOsc = null;
  _motorOsc2 = null;
  _motorGanho = null;
  _motorFiltro = null;
}
