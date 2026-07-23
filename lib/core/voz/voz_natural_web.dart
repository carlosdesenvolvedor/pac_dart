import 'dart:js_interop';
import 'dart:typed_data';

// o package:web exporta um Float32List de interop que SOMBREIA o de
// dart:typed_data — escondemos para usar o de verdade + .toJS
import 'package:web/web.dart' hide Float32List;

/// Player do áudio PCM16 da voz neural, direto no Web Audio (sem <audio>,
/// sem arquivo): converte as amostras pra Float32 e toca num BufferSource.
const suportado = true;

AudioContext? _ctx;
AudioBufferSourceNode? _atual;

void tocaPcm16(List<int> pcm, int taxa) {
  final ctx = _ctx ??= AudioContext();
  if (ctx.state == 'suspended') ctx.resume();
  paraTudo();

  final bytes = Uint8List.fromList(pcm);
  final amostras = Int16List.view(bytes.buffer, 0, bytes.length ~/ 2);
  final f32 = Float32List(amostras.length);
  for (var i = 0; i < amostras.length; i++) {
    f32[i] = amostras[i] / 32768.0;
  }

  final buffer = ctx.createBuffer(1, amostras.length, taxa.toDouble());
  buffer.copyToChannel(f32.toJS, 0);

  final fonte = ctx.createBufferSource()..buffer = buffer;
  fonte.connect(ctx.destination);
  fonte.start();
  _atual = fonte;
}

void paraTudo() {
  try {
    _atual?.stop();
  } catch (_) {
    // já tinha terminado — tudo bem
  }
  _atual = null;
}
