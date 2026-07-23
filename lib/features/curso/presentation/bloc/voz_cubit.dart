import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/voz/voz_natural.dart';

/// Liga/desliga a narração por voz e fala as dicas: primeiro tenta a voz
/// NEURAL do Gemini (natural, estilo assistente moderno); se não der
/// (cota/rede/plataforma), cai na voz do sistema sem drama.
class VozCubit extends Cubit<bool> {
  final FlutterTts _tts = FlutterTts();
  final VozNatural _natural;

  VozCubit({VozNatural? natural})
      : _natural = natural ?? VozNatural(),
        super(false) {
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
    _natural.parar();
    try {
      await _tts.stop();
    } catch (_) {}
    if (await _natural.falar(texto)) return;
    try {
      await _tts.speak(texto);
    } catch (_) {}
  }

  Future<void> _parar() async {
    _natural.parar();
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
