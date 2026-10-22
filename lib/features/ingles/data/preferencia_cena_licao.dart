import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎬 A chave "🎬 Cena / 🙂 Rosto" do cartão da lição de inglês (SharedPreferences, prefixo `en_`): ligada, o
/// cartão da tradução mostra a CENA da historinha da lição (o mesmo palco do 📺 Escutar assistindo, na âncora
/// da frase atual); desligada, o rosto de quem fala (como antes). Fica salva neste aparelho.
///
/// Tudo à prova de falha: sem armazenamento, a leitura devolve o [padrao] e a gravação some em silêncio.
abstract final class PreferenciaCenaLicao {
  static const chave = 'en_cena_licao';

  /// O valor sem pref gravada (a cena ligada). Os testes antigos, que medem o cartão com o rosto, usam
  /// `false` (o `test/flutter_test_config.dart` troca antes de cada arquivo).
  @visibleForTesting
  static bool padrao = true;

  /// A pref já lida de um [SharedPreferences] aberto (o palco lê junto das outras).
  static bool de(SharedPreferences p) {
    try {
      return p.getBool(chave) ?? padrao;
    } catch (_) {
      return padrao;
    }
  }

  static Future<bool> ler() async {
    try {
      final p = await SharedPreferences.getInstance();
      return de(p);
    } catch (_) {
      return padrao;
    }
  }

  static Future<void> salvar(bool ligada) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(chave, ligada);
    } catch (_) {}
  }
}
