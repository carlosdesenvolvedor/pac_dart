import 'dart:math' as math;
import 'dart:typed_data';

import 'sons.dart';

/// Os efeitos sonoros do app FORA do navegador: a mesma "partitura" de
/// `som_web.dart` (osciladores com envelope), mas calculada em Dart e entregue
/// como WAV (mono, 16 bits) para um player comum tocar — no celular não há
/// Web Audio. Código puro: roda (e é testado) na VM, sem plugin.
const taxaDeAmostragem = 22050;

/// Quanto o WAV é mais alto que o ganho cru da versão web (que sai por um
/// destino de áudio de laptop; no celular o alto-falante pede mais).
const _ganhoMestre = 2.2;

typedef _Nota = ({String tipo, double de, double ate, double dur, double atraso, double volume, bool sino});

_Nota _n(String tipo, double de, double ate, double dur, {double atraso = 0, double volume = .14}) =>
    (tipo: tipo, de: de, ate: ate, dur: dur, atraso: atraso, volume: volume, sino: false);

_Nota _sino(double freq, double dur, {double atraso = 0, double volume = .05}) =>
    (tipo: 'sine', de: freq, ate: freq, dur: dur, atraso: atraso, volume: volume, sino: true);

/// As notas de [som]. [alterna] só vale para o `waka` (sobe/desce a cada tecla).
List<_Nota> _partitura(Som som, {bool alterna = false}) => switch (som) {
      Som.waka => [alterna ? _n('triangle', 420, 190, .07, volume: .10) : _n('triangle', 190, 420, .07, volume: .10)],
      Som.erro => [_n('square', 130, 95, .12, volume: .09)],
      Som.blip => [_n('sine', 660, 990, .09)],
      Som.tiro => [_n('square', 950, 220, .08, volume: .10)],
      Som.explosao => [_n('square', 320, 55, .18, volume: .13), _n('sawtooth', 200, 40, .22, volume: .07)],
      Som.turbo => [_n('sawtooth', 220, 920, .20, volume: .11)],
      Som.gol => [
          _n('square', 523, 523, .09),
          _n('square', 659, 659, .09, atraso: .09),
          _n('square', 784, 784, .14, atraso: .18),
        ],
      Som.defesa => [_n('sine', 330, 140, .22, volume: .12)],
      Som.fanfarra => [
          _n('square', 523, 523, .11),
          _n('square', 659, 659, .11, atraso: .11),
          _n('square', 784, 784, .11, atraso: .22),
          _n('square', 1047, 1047, .26, atraso: .33),
        ],
      Som.fase => [
          _n('triangle', 392, 392, .09),
          _n('triangle', 523, 523, .09, atraso: .09),
          _n('triangle', 659, 659, .16, atraso: .18),
        ],
      Som.tique => [_n('sine', 520, 520, .05, volume: .07)],
      Som.decolar => [_n('sawtooth', 180, 1250, .45, volume: .10)],
      Som.misterio => [_n('sine', 880, 440, .30, volume: .10), _n('sine', 1108, 554, .30, atraso: .05, volume: .06)],
      Som.combo => [_n('square', 784, 784, .07, volume: .10), _n('square', 1175, 1175, .12, atraso: .07, volume: .10)],
      Som.largada => [_n('square', 880, 880, .28, volume: .13), _n('triangle', 1760, 1760, .28, volume: .06)],
      Som.ancora => [
          _sino(523.25, 1.9, volume: .055),
          _sino(659.25, 1.8, atraso: .07, volume: .045),
          _sino(783.99, 1.7, atraso: .14, volume: .04),
          _sino(987.77, 1.6, atraso: .21, volume: .03),
        ],
    };

/// O WAV (cabeçalho + PCM 16 bits mono) do efeito [som].
Uint8List sintetizarWav(Som som, {bool alterna = false}) {
  final notas = _partitura(som, alterna: alterna);
  var fim = 0.0;
  for (final n in notas) {
    fim = math.max(fim, n.atraso + n.dur + .08);
  }
  final buf = Float64List((fim * taxaDeAmostragem).ceil());
  for (final n in notas) {
    if (n.sino) {
      // sino: ataque macio + parcial inarmônico agudo e curto (o "brilho de metal")
      _parcialDeSino(buf, n.de, n.atraso, n.dur, n.volume);
      _parcialDeSino(buf, n.de * 2.76, n.atraso, n.dur * .35, n.volume * .22);
    } else {
      _oscilador(buf, n);
    }
  }
  return _empacotar(buf, ganho: _ganhoMestre);
}

/// Um ciclo do ronco do motor, para tocar em laço: serra grave + quadrada uma
/// oitava acima, passadas por um passa-baixas. 50 Hz e 100 Hz cabem em número
/// inteiro de ciclos em 1 s, então a emenda do laço não estala. A velocidade
/// do carro vira `playbackRate`.
Uint8List sintetizarMotor() {
  const taxa = taxaDeAmostragem;
  const segundos = 2; // o 1º segundo aquece o filtro e é jogado fora
  final bruto = Float64List(taxa * segundos);
  for (var i = 0; i < bruto.length; i++) {
    final t = i / taxa;
    final serra = 2 * ((50 * t) % 1) - 1;
    final quadrada = ((100 * t) % 1) < .5 ? 1.0 : -1.0;
    bruto[i] = serra * .5 + quadrada * .25;
  }
  final a = math.exp(-2 * math.pi * 600 / taxa); // passa-baixas de um polo, ~600 Hz
  var y = 0.0;
  for (var i = 0; i < bruto.length; i++) {
    y = (1 - a) * bruto[i] + a * y;
    bruto[i] = y;
  }
  return _empacotar(Float64List.sublistView(bruto, taxa), normalizar: .8);
}

double _onda(String tipo, double fase) => switch (tipo) {
      'square' => fase < .5 ? 1.0 : -1.0,
      'sawtooth' => 2 * fase - 1,
      'triangle' => 4 * (fase < .5 ? fase : 1 - fase) - 1,
      _ => math.sin(2 * math.pi * fase),
    };

/// Oscilador [tipo] de [de] a [ate] Hz (rampa exponencial) com ataque
/// instantâneo e decaimento exponencial até 0,0001, como o do Web Audio.
void _oscilador(Float64List buf, _Nota n) {
  final ini = (n.atraso * taxaDeAmostragem).round();
  final amostras = ((n.dur + .02) * taxaDeAmostragem).round();
  final k = n.ate == n.de ? 0.0 : math.log(n.ate / n.de);
  for (var i = 0; i < amostras && ini + i < buf.length; i++) {
    final t = i / taxaDeAmostragem;
    final u = math.min(t, n.dur) / n.dur;
    // fase = integral da frequência (em ciclos); depois do fim da rampa a frequência fica em `ate`
    final ciclos = k == 0
        ? n.de * t
        : n.de * n.dur / k * (math.exp(k * u) - 1) + (t > n.dur ? n.ate * (t - n.dur) : 0);
    final ganho = n.volume * math.pow(.0001 / n.volume, u);
    buf[ini + i] += ganho * _onda(n.tipo, ciclos - ciclos.floorToDouble());
  }
}

void _parcialDeSino(Float64List buf, double freq, double atraso, double dur, double volume) {
  final ini = (atraso * taxaDeAmostragem).round();
  final amostras = ((dur + .05) * taxaDeAmostragem).round();
  const ataque = .018;
  for (var i = 0; i < amostras && ini + i < buf.length; i++) {
    final t = i / taxaDeAmostragem;
    final ganho = t < ataque
        ? .0001 + (volume - .0001) * t / ataque
        : volume * math.pow(.0001 / volume, math.min(1.0, (t - ataque) / (dur - ataque)));
    buf[ini + i] += ganho * math.sin(2 * math.pi * freq * t);
  }
}

/// PCM 16 bits mono dentro de um WAV. [normalizar] leva o pico a esse valor (0–1);
/// senão aplica [ganho] cru. Nunca passa de ±1 (corta).
Uint8List _empacotar(Float64List amostras, {double ganho = 1, double? normalizar}) {
  var g = ganho;
  if (normalizar != null) {
    var pico = 0.0;
    for (final v in amostras) {
      pico = math.max(pico, v.abs());
    }
    g = pico == 0 ? 1 : normalizar / pico;
  }
  final dados = ByteData(44 + amostras.length * 2);
  void texto(int pos, String s) {
    for (var i = 0; i < s.length; i++) {
      dados.setUint8(pos + i, s.codeUnitAt(i));
    }
  }

  texto(0, 'RIFF');
  dados.setUint32(4, 36 + amostras.length * 2, Endian.little);
  texto(8, 'WAVE');
  texto(12, 'fmt ');
  dados.setUint32(16, 16, Endian.little); // tamanho do bloco fmt
  dados.setUint16(20, 1, Endian.little); // PCM
  dados.setUint16(22, 1, Endian.little); // mono
  dados.setUint32(24, taxaDeAmostragem, Endian.little);
  dados.setUint32(28, taxaDeAmostragem * 2, Endian.little); // bytes por segundo
  dados.setUint16(32, 2, Endian.little); // bytes por quadro
  dados.setUint16(34, 16, Endian.little); // bits
  texto(36, 'data');
  dados.setUint32(40, amostras.length * 2, Endian.little);
  for (var i = 0; i < amostras.length; i++) {
    final v = (amostras[i] * g).clamp(-1.0, 1.0);
    dados.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  return dados.buffer.asUint8List();
}
