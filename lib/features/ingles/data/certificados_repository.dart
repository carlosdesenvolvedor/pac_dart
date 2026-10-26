import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/certificado.dart';

/// 🎓 Os certificados emitidos (`certificados/<codigo>` no Firestore): qualquer um LÊ um certificado pelo código
/// (a página pública de verificação, sem login); só o dono cria o dele e ninguém altera (firestore.rules).
abstract interface class CertificadosRepository {
  /// Grava o certificado novo (falha se o código já existe: o Firestore barra a "atualização").
  Future<void> emitir(Certificado c);

  /// O certificado do [codigo], ou null.
  Future<Certificado?> buscar(String codigo);

  /// Os certificados da conta [uid] (o mais recente primeiro).
  Future<List<Certificado>> daConta(String uid);
}

class FirestoreCertificadosRepository implements CertificadosRepository {
  final FirebaseFirestore _db;
  FirestoreCertificadosRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  static const colecao = 'certificados';

  CollectionReference<Map<String, dynamic>> get _col => _db.collection(colecao);

  @override
  Future<void> emitir(Certificado c) => _col.doc(c.codigo).set(c.toJson());

  @override
  Future<Certificado?> buscar(String codigo) async {
    final d = await _col.doc(codigo).get();
    return d.exists ? Certificado.fromJson(codigo, d.data()) : null;
  }

  @override
  Future<List<Certificado>> daConta(String uid) async {
    final q = await _col.where('uid', isEqualTo: uid).get();
    final r = [for (final d in q.docs) ?Certificado.fromJson(d.id, d.data())];
    r.sort((a, b) => b.emitidoEm.compareTo(a.emitidoEm));
    return r;
  }
}

/// Em memória (testes e sem Firebase).
class MemoriaCertificadosRepository implements CertificadosRepository {
  final Map<String, Certificado> docs = {};

  @override
  Future<void> emitir(Certificado c) async {
    if (docs.containsKey(c.codigo)) throw StateError('código já existe');
    docs[c.codigo] = c;
  }

  @override
  Future<Certificado?> buscar(String codigo) async => docs[codigo];

  @override
  Future<List<Certificado>> daConta(String uid) async =>
      [for (final c in docs.values) if (c.uid == uid) c]..sort((a, b) => b.emitidoEm.compareTo(a.emitidoEm));
}
