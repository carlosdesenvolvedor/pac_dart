import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/audio_usuario.dart';

/// Onde moram os áudios que o aluno anexou às frases. A chave é a da frase
/// (`Revisao.chave` do texto em inglês).
abstract interface class AudioUsuarioRepository {
  /// Que frases têm áudio (sem baixar o áudio).
  Future<Map<String, InfoAudio>> indice();

  /// O áudio da frase [chave], ou null.
  Future<ClipeAudio?> carregar(String chave);

  /// Guarda (ou troca) o áudio da frase [chave].
  Future<void> salvar(String chave, ClipeAudio clipe);

  Future<void> remover(String chave);
}

/// Só na memória (testes e probe sem Firebase).
class MemoriaAudioUsuarioRepository implements AudioUsuarioRepository {
  final Map<String, ClipeAudio> _clipes = {};

  /// Quantas vezes um clipe foi baixado (os testes conferem o cache).
  int downloads = 0;

  @override
  Future<Map<String, InfoAudio>> indice() async => {for (final e in _clipes.entries) e.key: InfoAudio(e.value.mime, e.value.tamanho)};

  @override
  Future<ClipeAudio?> carregar(String chave) async {
    downloads++;
    return _clipes[chave];
  }

  @override
  Future<void> salvar(String chave, ClipeAudio clipe) async => _clipes[chave] = clipe;

  @override
  Future<void> remover(String chave) async => _clipes.remove(chave);
}

/// Na nuvem: `users/{uid}/audio/{chave}` guarda os bytes do arquivo como veio
/// (`b`, mais o tipo `m` e o tamanho `n`) e um documento `_idx` guarda o índice
/// (`i`: chave → "tipo|tamanho"), para saber quais frases têm áudio com UMA leitura
/// em vez de baixar todos. Um clipe custa 1 leitura quando toca pela 1ª vez na sessão.
class FirestoreAudioUsuarioRepository implements AudioUsuarioRepository {
  static const idIndice = '_idx';

  final String uid;
  final FirebaseFirestore _db;

  FirestoreAudioUsuarioRepository(this.uid, {FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users').doc(uid).collection('audio');

  @override
  Future<Map<String, InfoAudio>> indice() async {
    final dados = (await _col.doc(idIndice).get()).data()?['i'];
    final r = <String, InfoAudio>{};
    if (dados is Map) {
      for (final e in dados.entries) {
        final info = InfoAudio.decodificar(e.value);
        if (info != null) r['${e.key}'] = info;
      }
    }
    return r;
  }

  @override
  Future<ClipeAudio?> carregar(String chave) async {
    final d = (await _col.doc(chave).get()).data();
    final b = d?['b'], m = d?['m'];
    if (b is! Blob || m is! String || !FormatosAudio.mimes.contains(m)) return null;
    return ClipeAudio(Uint8List.fromList(b.bytes), m);
  }

  @override
  Future<void> salvar(String chave, ClipeAudio clipe) {
    final lote = _db.batch()
      ..set(_col.doc(chave), {'b': Blob(clipe.bytes), 'm': clipe.mime, 'n': clipe.tamanho})
      ..set(
        _col.doc(idIndice),
        {'i': {chave: InfoAudio(clipe.mime, clipe.tamanho).codificar()}},
        SetOptions(merge: true),
      );
    return lote.commit();
  }

  @override
  Future<void> remover(String chave) {
    final lote = _db.batch()
      ..delete(_col.doc(chave))
      ..set(_col.doc(idIndice), {'i': {chave: FieldValue.delete()}}, SetOptions(merge: true));
    return lote.commit();
  }
}
