import 'package:shared_preferences/shared_preferences.dart';

import 'historia_turismo.dart';

/// 📖 O que o aluno já viu da história do English Turismo e as preferências do player (SharedPreferences,
/// prefixo `en_`: só o inglês).
///
/// Tudo à prova de falha: se o armazenamento não responder, leitura devolve o padrão e gravação some em
/// silêncio (o desenho nunca trava por causa das prefs).
abstract final class ProgressoHistoria {
  static const chaveVistos = 'en_turismo_historia_vistos'; // StringList: 'i7' (abertura vista), 'f7' (chegada vista), 'c7' (chegada assistida até o fim)
  static const chaveTraducao = 'en_turismo_historia_pt'; // bool, default true
  static const chaveVoz = 'en_turismo_historia_voz'; // bool, default true
  static const chaveAuto = 'en_turismo_historia_auto'; // bool, default true
  static const chaveLenta = 'en_turismo_historia_lenta'; // bool, default false
  static const chavePerdidos = 'en_turismo_historia_perdidos'; // bool, default false (aviso "capítulos perdidos" já mostrado)

  /// 'i7' (abertura) / 'f7' (chegada).
  static String id(int pista, ParteDoCapitulo p) => '${p == ParteDoCapitulo.intro ? 'i' : 'f'}$pista';

  /// 'c7': a chegada da pista 7 foi assistida até o fim (pular não conta).
  static String idAssistido(int pista) => 'c$pista';

  static Future<Set<String>> vistos() async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList(chaveVistos) ?? const <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// Marca a parte como vista; chegada [assistido] até o fim marca também 'c7'.
  /// Abertura assistida não ganha marca extra (só a chegada conta para o troféu 📖).
  static Future<void> marcarVisto(int pista, ParteDoCapitulo parte, {bool assistido = false}) async {
    try {
      final p = await SharedPreferences.getInstance();
      final antes = p.getStringList(chaveVistos) ?? const <String>[];
      final novos = [
        id(pista, parte),
        if (assistido && parte == ParteDoCapitulo.fim) idAssistido(pista),
      ].where((v) => !antes.contains(v)).toList();
      if (novos.isEmpty) return;
      await p.setStringList(chaveVistos, [...antes, ...novos]);
    } catch (_) {}
  }

  static Future<bool> _lerBool(String chave, bool padrao) async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(chave) ?? padrao;
    } catch (_) {
      return padrao;
    }
  }

  static Future<void> _gravarBool(String chave, bool v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(chave, v);
    } catch (_) {}
  }

  /// Tradução PT embaixo do balão (padrão: visível).
  static Future<bool> traducao() => _lerBool(chaveTraducao, true);
  static Future<void> salvarTraducao(bool v) => _gravarBool(chaveTraducao, v);

  /// Voz da história ligada (padrão: sim).
  static Future<bool> voz() => _lerBool(chaveVoz, true);
  static Future<void> salvarVoz(bool v) => _gravarBool(chaveVoz, v);

  /// 📖 Auto: abertura e chegada tocam sozinhas na primeira vez (padrão: sim).
  static Future<bool> auto() => _lerBool(chaveAuto, true);
  static Future<void> salvarAuto(bool v) => _gravarBool(chaveAuto, v);

  /// 🐢 da história (própria, independente da lenta do curso; padrão: desligada).
  static Future<bool> lenta() => _lerBool(chaveLenta, false);
  static Future<void> salvarLenta(bool v) => _gravarBool(chaveLenta, v);

  /// As velocidades da voz da história que o 🐢 percorre (1 = normal).
  static const velocidades = [1.0, .85, .7, .5];
  static const chaveVelocidade = 'en_turismo_historia_vel'; // double ∈ [velocidades], default 1

  /// Velocidade da voz da história. Sem a pref nova, quem tinha a 🐢 antiga ligada fica em .85
  /// (a 🐢 antiga era ~.8); valor fora da lista → o mais perto.
  static Future<double> velocidade() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getDouble(chaveVelocidade);
      if (v != null && v.isFinite) return velocidadeMaisPerto(v);
      return (p.getBool(chaveLenta) ?? false) ? .85 : 1.0;
    } catch (_) {
      return 1.0;
    }
  }

  static Future<void> salvarVelocidade(double v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(chaveVelocidade, velocidadeMaisPerto(v));
    } catch (_) {}
  }

  static double velocidadeMaisPerto(double v) {
    var melhor = velocidades.first;
    for (final x in velocidades) {
      if ((x - v).abs() < (melhor - v).abs()) melhor = x;
    }
    return melhor;
  }

  /// O aviso "capítulos perdidos" já apareceu? (mostra uma vez só)
  static Future<bool> perdidosAvisado() => _lerBool(chavePerdidos, false);
  static Future<void> marcarPerdidosAvisado() => _gravarBool(chavePerdidos, true);
}
