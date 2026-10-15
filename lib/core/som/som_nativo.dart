import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'sintetizador.dart';
import 'sons.dart';

/// Os efeitos sonoros no Android e no iOS: o [sintetizador] gera os WAVs
/// (mesma partitura da versão web), gravados uma vez numa pasta temporária, e
/// cada efeito toca por um `AudioPool` (SoundPool no Android: latência baixa,
/// que é o que a tecla do treino pede). No desktop e nos testes da VM não faz
/// nada — vale o silêncio educado do `som_stub`.
final bool _ativo = Platform.isAndroid || Platform.isIOS;

/// Celular não tem a trava de autoplay do navegador.
bool get liberado => true;

bool _contextoPronto = false;
Directory? _pasta;
final _piscinas = <String, Future<AudioPool?>>{};
bool _wakaAlterna = false;

Future<void> _prepararContexto() async {
  if (_contextoPronto) return;
  _contextoPronto = true;
  try {
    // os efeitos se misturam ao que já toca (a voz, a música do usuário) e
    // obedecem à chave de silêncio do iPhone
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, respectSilence: true).build(),
    );
  } catch (_) {}
}

Future<File> _gravar(String nome, Uint8List wav) async {
  final pasta = _pasta ??= await Directory('${Directory.systemTemp.path}/paclingo_som').create(recursive: true);
  return File('${pasta.path}/$nome.wav').writeAsBytes(wav, flush: true);
}

Future<AudioPool?> _piscina(String chave, Uint8List Function() wav) => _piscinas.putIfAbsent(chave, () async {
      try {
        await _prepararContexto();
        final arquivo = await _gravar(chave, wav());
        return await AudioPool.create(source: DeviceFileSource(arquivo.path), maxPlayers: 4);
      } catch (_) {
        return null;
      }
    });

void tocar(Som som) {
  if (!_ativo) return;
  if (som == Som.waka) _wakaAlterna = !_wakaAlterna;
  final alterna = _wakaAlterna;
  final chave = som == Som.waka ? (alterna ? 'waka_a' : 'waka_b') : som.name;
  unawaited(() async {
    try {
      final p = await _piscina(chave, () => sintetizarWav(som, alterna: alterna));
      await p?.start();
    } catch (_) {}
  }());
}

// ---------- ronco do motor (Dart Turismo) ----------
// Um laço de 1 s tocado em loop; a velocidade do carro vira velocidade de
// reprodução (o tom sobe) e volume.
AudioPlayer? _motor;
Future<void>? _iniciandoMotor;
int _geracaoMotor = 0;
double _ultimaIntensidade = -1;
DateTime _ultimoEnvio = DateTime.fromMillisecondsSinceEpoch(0);

void motorRonco(double intensidade) {
  if (!_ativo) return;
  final agora = DateTime.now();
  // chamado a cada frame: só repassa ao player quando mudou de verdade
  if (_motor != null &&
      ((intensidade - _ultimaIntensidade).abs() < .03 ||
          agora.difference(_ultimoEnvio) < const Duration(milliseconds: 100))) {
    return;
  }
  _ultimaIntensidade = intensidade;
  _ultimoEnvio = agora;
  unawaited(_atualizarMotor(intensidade));
}

Future<void> _atualizarMotor(double intensidade) async {
  try {
    final g = _geracaoMotor;
    if (_motor == null) {
      _iniciandoMotor ??= _iniciarMotor(g);
      await _iniciandoMotor;
    }
    final m = _motor;
    if (m == null || g != _geracaoMotor) return;
    await m.setPlaybackRate(.9 + 1.1 * intensidade);
    await m.setVolume(.12 + .38 * intensidade);
  } catch (_) {}
}

Future<void> _iniciarMotor(int geracao) async {
  try {
    await _prepararContexto();
    final arquivo = await _gravar('motor', sintetizarMotor());
    final m = AudioPlayer();
    await m.setReleaseMode(ReleaseMode.loop);
    await m.setVolume(.12);
    await m.play(DeviceFileSource(arquivo.path));
    if (geracao != _geracaoMotor) {
      await m.dispose(); // pararam o motor enquanto ele ligava
      return;
    }
    _motor = m;
  } catch (_) {
    _iniciandoMotor = null;
  }
}

void motorParar() {
  _geracaoMotor++;
  final m = _motor;
  _motor = null;
  _iniciandoMotor = null;
  _ultimaIntensidade = -1;
  if (m != null) unawaited(m.dispose().catchError((Object _) {}));
}
