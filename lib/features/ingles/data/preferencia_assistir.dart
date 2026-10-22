import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📺 A preferência do "Escutar assistindo" (SharedPreferences, prefixo `en_`: só o inglês): se o desenho
/// estava ligado no "Tocando agora" e se o selo "novo" do botão já saiu.
///
/// [valor] é lido de forma SÍNCRONA no `initState` do `TocandoPage` (sem piscar foto → palco): ele é
/// carregado uma vez ao abrir o `OuvirPage` ou o mini-player ([carregar]) e muda na hora no [salvar].
/// Tudo à prova de falha: sem armazenamento, leitura devolve false e gravação some em silêncio.
abstract final class PreferenciaAssistir {
  static const chave = 'en_ouvir_assistir';
  static const chaveNovidade = 'en_ouvir_assistir_visto';

  /// Leitura síncrona (I9). false até carregar; carregado uma vez ao abrir o OuvirPage ou o mini-player.
  static final ValueNotifier<bool> valor = ValueNotifier(false);

  static Future<void>? _carregando;

  /// Idempotente; erro → fica false (e o próximo chamado tenta de novo).
  static Future<void> carregar() {
    final emCurso = _carregando;
    if (emCurso != null) return emCurso;
    final futuro = _carregar();
    _carregando = futuro;
    return futuro;
  }

  static Future<void> _carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      valor.value = p.getBool(chave) ?? false;
    } catch (_) {
      _carregando = null;
    }
  }

  /// false sem pref / com erro.
  static Future<bool> ligado() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(chave) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Atualiza [valor] na hora; grava com try/catch.
  static Future<void> salvar(bool ligado) async {
    valor.value = ligado;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(chave, ligado);
    } catch (_) {}
  }

  /// true até o 1º uso (o selo "novo" do botão 📺).
  static Future<bool> mostrarNovidade() async {
    try {
      final p = await SharedPreferences.getInstance();
      return !(p.getBool(chaveNovidade) ?? false);
    } catch (_) {
      return false;
    }
  }

  static Future<void> marcarNovidadeVista() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(chaveNovidade, true);
    } catch (_) {}
  }

  /// Volta ao estado de antes de carregar (testes).
  @visibleForTesting
  static void reiniciar() {
    _carregando = null;
    valor.value = false;
  }
}
