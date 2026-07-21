import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Liga/desliga a narração por voz (TTS pt-BR) e fala as dicas.
class VozCubit extends Cubit<bool> {
  final FlutterTts _tts = FlutterTts();

  VozCubit() : super(false) {
    _configurar();
  }

  Future<void> _configurar() async {
    try {
      await _tts.setLanguage('pt-BR');
      await _tts.setSpeechRate(.9);
    } catch (_) {
      // plataforma sem TTS: o toggle continua funcionando, só não fala
    }
  }

  void alternar() {
    if (state) _parar();
    emit(!state);
  }

  Future<void> falar(String texto) async {
    if (!state) return;
    await falarSempre(texto);
  }

  Future<void> falarSempre(String texto) async {
    try {
      await _tts.stop();
      await _tts.speak(texto);
    } catch (_) {}
  }

  Future<void> _parar() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _parar();
    return super.close();
  }
}
