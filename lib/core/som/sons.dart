import 'package:shared_preferences/shared_preferences.dart';

import 'som_stub.dart' if (dart.library.js_interop) 'som_web.dart' as motor;

/// Os efeitos sonoros do PAC·DART — todos SINTETIZADOS na hora com Web
/// Audio (osciladores + envelopes): zero assets, zero dependências, cara
/// de fliperama 8-bit.
enum Som {
  /// Tecla certa no treino (alterna dois tons, waka-waka).
  waka,

  /// Tecla/resposta errada (zumbido curto).
  erro,

  /// Acerto pontual (opção certa, palavra completa, trecho concluído).
  blip,

  /// Tiro do Pac na Chuva de Código.
  tiro,

  /// Palavra destruída (queda grave rápida).
  explosao,

  /// Turbo/palavra perfeita (varredura subindo).
  turbo,

  /// Gol! (três notas subindo).
  gol,

  /// Defesa/derrota pontual (queda).
  defesa,

  /// Vitória/missão cumprida (arpejo de fanfarra).
  fanfarra,

  /// Passou de fase/nível (arpejo curto).
  fase,

  /// Tique sutil (passo da animação, contagem).
  tique,

  /// Decolagem (varredura longa).
  decolar,

  /// 🔮 Ajuda misteriosa (glissando descendo, clima de mistério).
  misterio,
}

/// Liga/desliga global (persistido por dispositivo) + disparo dos efeitos.
/// `toca` é fire-and-forget e NUNCA lança: som é tempero, não dependência.
abstract final class Sons {
  static const _chave = 'som_ligado';
  static bool ligado = true;

  static Future<void> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      ligado = p.getBool(_chave) ?? true;
    } catch (_) {}
  }

  static Future<void> alternar() async {
    ligado = !ligado;
    if (ligado) toca(Som.blip); // feedback imediato de que voltou
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_chave, ligado);
    } catch (_) {}
  }

  static void toca(Som som) {
    if (!ligado) return;
    try {
      motor.tocar(som);
    } catch (_) {
      // sem áudio (teste/navegador bloqueou): o jogo segue mudo e feliz
    }
  }
}
