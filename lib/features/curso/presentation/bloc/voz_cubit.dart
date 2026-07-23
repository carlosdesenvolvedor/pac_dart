import 'dart:async';

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
      await _escolherMelhorVoz();
    } catch (_) {
      // plataforma sem TTS: o toggle continua funcionando, só não fala
    }
  }

  /// O navegador costuma ter várias vozes pt-BR — a padrão é a mais
  /// robótica. Caçamos a melhor: as "Google" (de rede, no Chrome) soam
  /// muito mais naturais que as locais.
  Future<void> _escolherMelhorVoz() async {
    try {
      final vozes = (await _tts.getVoices as List?) ?? const [];
      Map? melhor;
      var nota = -1;
      for (final v in vozes) {
        final m = Map<String, dynamic>.from(v as Map);
        final nome = '${m['name'] ?? ''}';
        final locale = '${m['locale'] ?? ''}'.toLowerCase().replaceAll('_', '-');
        if (!locale.startsWith('pt')) continue;
        var pontos = locale.contains('br') ? 2 : 1;
        if (nome.contains('Google')) pontos += 4; // voz de rede do Chrome
        if (nome.toLowerCase().contains('natural')) pontos += 3;
        if (pontos > nota) {
          nota = pontos;
          melhor = m;
        }
      }
      if (melhor != null) {
        await _tts.setVoice({
          'name': '${melhor['name']}',
          'locale': '${melhor['locale']}',
        });
      }
    } catch (_) {}
  }

  void alternar() {
    if (state) _parar();
    emit(!state);
  }

  /// Espera você "assentar" no exercício antes de narrar. A narração
  /// AUTOMÁTICA usa a melhor voz do navegador: a cota da voz neural é de
  /// ~10 áudios/DIA no plano grátis — guardamos pro Prof. Dash e pros
  /// toques explícitos no 🔊, que é onde ela brilha.
  Timer? _aguarda;

  Future<void> falar(String texto) async {
    if (!state) return;
    _aguarda?.cancel();
    _natural.parar();
    try {
      await _tts.stop();
    } catch (_) {}
    _aguarda = Timer(const Duration(milliseconds: 900), () => _falarSistema(texto));
  }

  Future<void> _falarSistema(String texto) async {
    try {
      await _tts.stop();
      await _tts.speak(texto);
    } catch (_) {}
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
    _aguarda?.cancel();
    _parar();
    return super.close();
  }
}
