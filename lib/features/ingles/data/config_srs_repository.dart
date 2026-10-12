import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/config_srs.dart';

/// Onde moram os ajustes da revisão. Nunca lança: sem armazenamento, vale o padrão.
abstract interface class ConfigSrsRepository {
  Future<ConfigSrs> carregar();
  Future<void> salvar(ConfigSrs config);
}

/// No aparelho (offline, testes, probe).
class LocalConfigSrsRepository implements ConfigSrsRepository {
  static const _chave = 'en_srs_cfg';

  @override
  Future<ConfigSrs> carregar() async {
    try {
      return ConfigSrs.decodificar((await SharedPreferences.getInstance()).getString(_chave));
    } catch (_) {
      return ConfigSrs.padrao;
    }
  }

  @override
  Future<void> salvar(ConfigSrs config) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_chave, config.codificar());
    } catch (_) {}
  }
}

/// Na nuvem: um campo `en_srs_cfg` (texto JSON) no próprio `users/{uid}` — as
/// regras que já existem cobrem. Os ajustes acompanham a pessoa entre aparelhos.
class FirestoreConfigSrsRepository implements ConfigSrsRepository {
  final String uid;
  final FirebaseFirestore _db;

  FirestoreConfigSrsRepository(this.uid, {FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc => _db.collection('users').doc(uid);

  @override
  Future<ConfigSrs> carregar() async {
    try {
      return ConfigSrs.decodificar((await _doc.get()).data()?['en_srs_cfg']);
    } catch (_) {
      return ConfigSrs.padrao;
    }
  }

  @override
  Future<void> salvar(ConfigSrs config) async {
    try {
      await _doc.set({'en_srs_cfg': config.codificar()}, SetOptions(merge: true));
    } catch (_) {}
  }
}
