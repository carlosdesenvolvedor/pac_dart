import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/setlist.dart';

/// Onde moram as setlists do "🎧 Ouvir".
abstract class SetlistsRepository {
  /// Lê o banco. Nunca lança nem devolve nulo: sem nada gravado (ou com dado estragado) é o vazio.
  Future<BancoSetlists> carregar();

  /// Grava o banco inteiro (é um estado: gravar duas vezes é inofensivo). Nunca lança.
  Future<void> salvar(BancoSetlists b);

  /// Só a cópia do aparelho, sem esperar a rede (a tela mostra já; a nuvem chega pelo [carregar]).
  Future<BancoSetlists> carregarLocal();

  /// Grava só a cópia do aparelho, na hora (fechar/recarregar a aba logo depois não perde a mudança).
  Future<void> salvarLocal(BancoSetlists b);
}

/// No aparelho: um texto JSON em `en_setlists_{uid}`.
class LocalSetlistsRepository implements SetlistsRepository {
  final String uid;
  LocalSetlistsRepository(this.uid);

  String get chave => 'en_setlists_$uid';

  @override
  Future<BancoSetlists> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      return BancoSetlists.fromJsonString(p.getString(chave));
    } catch (_) {
      return const BancoSetlists();
    }
  }

  @override
  Future<void> salvar(BancoSetlists b) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(chave, b.toJsonString());
    } catch (_) {}
  }

  @override
  Future<BancoSetlists> carregarLocal() => carregar();

  @override
  Future<void> salvarLocal(BancoSetlists b) => salvar(b);
}

/// Em memória (testes).
class MemoriaSetlistsRepository implements SetlistsRepository {
  BancoSetlists banco;

  /// Quantas vezes [salvar] foi chamado (os testes conferem que as gravações se juntam).
  int salvos = 0;

  MemoriaSetlistsRepository([this.banco = const BancoSetlists()]);

  @override
  Future<BancoSetlists> carregar() async => banco;

  @override
  Future<void> salvar(BancoSetlists b) async {
    salvos++;
    banco = b;
  }

  /// Em memória não há cópia do aparelho à parte: é a mesma leitura.
  @override
  Future<BancoSetlists> carregarLocal() => carregar();

  /// Em memória não há cópia do aparelho à parte: só o [salvar] grava.
  @override
  Future<void> salvarLocal(BancoSetlists b) async {}
}

/// Na nuvem, com cópia no aparelho: UM documento `users/{uid}/setlists/v1`, campo `b` (o banco em JSON).
/// Como o banco de palavras: a leitura mescla aparelho × nuvem ([BancoSetlists.mesclar]), a gravação vai
/// primeiro ao aparelho e junta com a nuvem numa transação; qualquer falha da nuvem é engolida.
class FirestoreSetlistsRepository implements SetlistsRepository {
  final String uid;
  final FirebaseFirestore? _dbInjetado;
  final SetlistsRepository _local;

  FirestoreSetlistsRepository(this.uid, {FirebaseFirestore? db, SetlistsRepository? local})
      : _dbInjetado = db,
        _local = local ?? LocalSetlistsRepository(uid);

  static const colecao = 'setlists';
  static const documento = 'v1';
  static const campo = 'b';

  DocumentReference<Map<String, dynamic>> get _doc =>
      (_dbInjetado ?? FirebaseFirestore.instance).collection('users').doc(uid).collection(colecao).doc(documento);

  /// O limite de cada ida à nuvem. Sem rede o `set` do Firestore só termina quando o servidor confirma
  /// (a escrita já ficou na fila local dele): sem limite, a leitura e a fila de gravações do cubit
  /// ficariam presas até a rede voltar.
  static const espera = Duration(seconds: 5);

  @override
  Future<BancoSetlists> carregarLocal() => _local.carregar();

  @override
  Future<void> salvarLocal(BancoSetlists b) => _local.salvar(b);

  @override
  Future<BancoSetlists> carregar() async {
    final local = await _local.carregar();
    BancoSetlists remoto;
    try {
      remoto = BancoSetlists.fromJsonString((await _doc.get().timeout(espera)).data()?[campo] as String?);
    } catch (_) {
      return local;
    }
    final junto = BancoSetlists.mesclar(local, remoto);
    if (junto != remoto) {
      try {
        await _enviar(junto);
      } catch (_) {}
    }
    return _descerParaOAparelho(junto);
  }

  @override
  Future<void> salvar(BancoSetlists b) async {
    await _local.salvar(b);
    BancoSetlists? junto;
    try {
      final doc = _doc;
      junto = await (_dbInjetado ?? FirebaseFirestore.instance).runTransaction((tx) async {
        final remoto = BancoSetlists.fromJsonString((await tx.get(doc)).data()?[campo] as String?);
        final j = BancoSetlists.mesclar(b, remoto);
        if (j != remoto) tx.set(doc, {campo: j.toJsonString()}, SetOptions(merge: true));
        return j;
      }).timeout(espera * 2);
    } catch (_) {
      try {
        final remoto = BancoSetlists.fromJsonString((await _doc.get().timeout(espera)).data()?[campo] as String?);
        final j = BancoSetlists.mesclar(b, remoto);
        if (j != remoto) await _enviar(j);
        junto = j;
      } catch (_) {}
    }
    if (junto != null && junto != b) await _descerParaOAparelho(junto);
  }

  /// Junta [b] com a cópia do aparelho DE AGORA (o cubit pode ter gravado uma mudança mais nova enquanto a
  /// nuvem respondia — gravar [b] por cima a apagaria) e grava se mudou.
  Future<BancoSetlists> _descerParaOAparelho(BancoSetlists b) async {
    final atual = await _local.carregar();
    final j = BancoSetlists.mesclar(atual, b);
    if (j != atual) await _local.salvar(j);
    return j;
  }

  Future<void> _enviar(BancoSetlists b) =>
      _doc.set({campo: b.toJsonString()}, SetOptions(merge: true)).timeout(espera);
}
