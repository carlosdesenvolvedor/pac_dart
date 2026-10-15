import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/cota_ia.dart';

/// Onde mora a cota de uso da IA. Mesmo desenho do hábito: aparelho primeiro, nuvem junto.
abstract interface class CotaRepository {
  Future<CotaIa> carregar();
  Future<void> salvar(CotaIa cota);
}

/// No aparelho (offline, testes, probe): JSON em `ia_cota_v1` (com [uid]: `ia_cota_v1:{uid}`).
class LocalCotaRepository implements CotaRepository {
  static const chaveBase = 'ia_cota_v1';
  final String? uid;

  /// A pref base (o "toque na palavra" tem cota própria, só no aparelho).
  final String base;
  LocalCotaRepository({this.uid, this.base = chaveBase});

  String get chave => uid == null ? base : '$base:$uid';

  @override
  Future<CotaIa> carregar() async {
    try {
      final texto = (await SharedPreferences.getInstance()).getString(chave);
      return texto == null ? CotaIa.vazia : CotaIa.fromJson(jsonDecode(texto));
    } catch (_) {
      return CotaIa.vazia;
    }
  }

  @override
  Future<void> salvar(CotaIa cota) async {
    try {
      await (await SharedPreferences.getInstance()).setString(chave, jsonEncode(cota.toJson()));
    } catch (_) {}
  }
}

/// Na nuvem: o campo `ia_cota` de `users/{uid}` (as regras que existem já cobrem; a exclusão da
/// conta apaga o documento e a cota junto), com cópia no aparelho. Sem Firebase iniciado
/// (testes de tela) o Firestore só é tocado ao ler/gravar, então tudo segue no aparelho.
class FirestoreCotaRepository implements CotaRepository {
  final String uid;
  final FirebaseFirestore? _dbInjetado;
  final CotaRepository _local;

  FirestoreCotaRepository(this.uid, {FirebaseFirestore? db, CotaRepository? local})
      : _dbInjetado = db,
        _local = local ?? LocalCotaRepository(uid: uid);

  DocumentReference<Map<String, dynamic>> get _doc =>
      (_dbInjetado ?? FirebaseFirestore.instance).collection('users').doc(uid);

  @override
  Future<CotaIa> carregar() async {
    final local = await _local.carregar();
    CotaIa remota;
    try {
      remota = CotaIa.fromJson((await _doc.get()).data()?['ia_cota']);
    } catch (_) {
      return local;
    }
    final junta = CotaIa.mesclar(local, remota);
    try {
      if (junta != remota) await _enviar(junta);
    } catch (_) {}
    if (junta != local) await _local.salvar(junta);
    return junta;
  }

  /// Aparelho primeiro; a nuvem depois (se falhar, lança e o cubit engole).
  @override
  Future<void> salvar(CotaIa cota) async {
    await _local.salvar(cota);
    await _enviar(cota);
  }

  /// `merge: true`: só o campo `ia_cota` muda.
  Future<void> _enviar(CotaIa c) => _doc.set({'ia_cota': c.toJson()}, SetOptions(merge: true));
}
