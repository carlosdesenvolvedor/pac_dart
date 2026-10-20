import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/banco_palavras.dart';

/// Onde mora o banco de palavras do aluno ("Minhas palavras").
abstract interface class PalavrasRepository {
  /// Lê o banco. Nunca lança nem devolve nulo: sem nada gravado (ou com dado estragado) é o vazio.
  Future<BancoPalavras> carregar();

  /// Grava o banco inteiro (é um estado: gravar duas vezes é inofensivo). Nunca lança.
  Future<void> salvar(BancoPalavras banco);
}

/// No aparelho: um texto JSON em `en_palavras_{uid}`.
class LocalPalavrasRepository implements PalavrasRepository {
  final String uid;
  LocalPalavrasRepository(this.uid);

  String get chave => 'en_palavras_$uid';

  @override
  Future<BancoPalavras> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      return BancoPalavras.decodificar(p.getString(chave));
    } catch (_) {
      return BancoPalavras.vazio;
    }
  }

  @override
  Future<void> salvar(BancoPalavras banco) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(chave, banco.codificar());
    } catch (_) {}
  }
}

/// Em memória (testes).
class MemoriaPalavrasRepository implements PalavrasRepository {
  BancoPalavras banco;

  /// Quantas vezes [salvar] foi chamado (os testes conferem que as gravações se juntam).
  int salvos = 0;

  MemoriaPalavrasRepository([this.banco = BancoPalavras.vazio]);

  @override
  Future<BancoPalavras> carregar() async => banco;

  @override
  Future<void> salvar(BancoPalavras banco) async {
    salvos++;
    this.banco = banco;
  }
}

/// Na nuvem, com cópia no aparelho: UM documento `users/{uid}/palavras/v1`, campo `b` (o banco em JSON
/// compacto) — fora do `users/{uid}`, que o progresso lê inteiro várias vezes na abertura. Como o
/// hábito: o Firestore só é tocado quando há o que ler/gravar (testes sem Firebase seguem no aparelho),
/// a leitura mescla aparelho × nuvem, a gravação vai primeiro ao aparelho e qualquer falha da nuvem
/// (sem rede, regra ainda não publicada) é engolida — o banco segue no aparelho.
class FirestorePalavrasRepository implements PalavrasRepository {
  final String uid;
  final FirebaseFirestore? _dbInjetado;
  final PalavrasRepository _local;

  FirestorePalavrasRepository(this.uid, {FirebaseFirestore? db, PalavrasRepository? local})
      : _dbInjetado = db,
        _local = local ?? LocalPalavrasRepository(uid);

  static const colecao = 'palavras';
  static const documento = 'v1';
  static const campo = 'b';

  DocumentReference<Map<String, dynamic>> get _doc =>
      (_dbInjetado ?? FirebaseFirestore.instance).collection('users').doc(uid).collection(colecao).doc(documento);

  @override
  Future<BancoPalavras> carregar() async {
    final local = await _local.carregar();
    BancoPalavras remoto;
    try {
      remoto = BancoPalavras.decodificar((await _doc.get()).data()?[campo]);
    } catch (_) {
      return local;
    }
    final junto = BancoPalavras.mesclar(local, remoto);
    if (junto != remoto) {
      try {
        await _enviar(junto);
      } catch (_) {}
    }
    if (junto != local) await _local.salvar(junto);
    return junto;
  }

  /// Aparelho primeiro; na nuvem, JUNTA com o que já está lá (numa transação: lê, mescla, grava) — outro
  /// aparelho aberto pode ter gravado cartões/lápides depois que este carregou, e um `set` cego os
  /// apagaria. Sem transação (sem rede), tenta uma leitura simples (o cache serve) + mescla; se nem
  /// isso der, a nuvem fica para a próxima gravação/abertura (o [carregar] de lá sobe o que faltar).
  @override
  Future<void> salvar(BancoPalavras banco) async {
    await _local.salvar(banco);
    BancoPalavras? junto;
    try {
      final doc = _doc;
      junto = await (_dbInjetado ?? FirebaseFirestore.instance).runTransaction((tx) async {
        final remoto = BancoPalavras.decodificar((await tx.get(doc)).data()?[campo]);
        final j = BancoPalavras.mesclar(banco, remoto);
        if (j != remoto) tx.set(doc, {campo: j.codificar()}, SetOptions(merge: true));
        return j;
      });
    } catch (_) {
      try {
        final remoto = BancoPalavras.decodificar((await _doc.get()).data()?[campo]);
        final j = BancoPalavras.mesclar(banco, remoto);
        if (j != remoto) await _enviar(j);
        junto = j;
      } catch (_) {}
    }
    // o que veio da nuvem também fica no aparelho (vale se a nuvem sumir depois)
    if (junto != null && junto != banco) await _local.salvar(junto);
  }

  Future<void> _enviar(BancoPalavras b) => _doc.set({campo: b.codificar()}, SetOptions(merge: true));
}
