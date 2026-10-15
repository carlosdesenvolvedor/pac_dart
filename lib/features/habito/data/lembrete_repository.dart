import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/lembrete.dart';

/// Onde mora a configuração do lembrete (ligado, horário). É do APARELHO: nada vai ao Firestore.
abstract interface class LembreteRepository {
  /// Lê a configuração. Nunca devolve nulo: sem nada gravado (ou com dado estragado) é o padrão (desligado, 20:00).
  Future<ConfigLembrete> carregar();
  Future<void> salvar(ConfigLembrete config);
}

/// No aparelho, em `lembrete_v1` — com [uid] a chave leva o dono (`lembrete_v1:{uid}`): duas contas no mesmo
/// aparelho não misturam o horário.
class LocalLembreteRepository implements LembreteRepository {
  static const chaveBase = 'lembrete_v1';

  final String? uid;
  LocalLembreteRepository({this.uid});

  String get chave => uid == null ? chaveBase : '$chaveBase:$uid';

  @override
  Future<ConfigLembrete> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      final texto = p.getString(chave);
      return texto == null ? ConfigLembrete.padrao : ConfigLembrete.fromJson(jsonDecode(texto));
    } catch (_) {
      return ConfigLembrete.padrao;
    }
  }

  @override
  Future<void> salvar(ConfigLembrete config) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(chave, jsonEncode(config.toJson()));
    } catch (_) {}
  }
}
