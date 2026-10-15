import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/habito.dart';

/// Onde mora o hábito (sequência, meta do dia, congelamentos) da pessoa.
abstract interface class HabitoRepository {
  /// Lê o hábito. Nunca devolve nulo: sem nada gravado (ou com dado estragado) é o padrão.
  Future<Habito> carregar();

  /// Grava o hábito inteiro (é um estado, não um evento: gravar duas vezes é inofensivo).
  Future<void> salvar(Habito habito);
}

/// No aparelho (offline, testes, probe): um texto JSON em `habito_v1`. Com [uid]
/// a chave leva o dono (`habito_v1:{uid}`) — quando serve de cópia da nuvem, duas
/// contas no mesmo aparelho não misturam a sequência.
class LocalHabitoRepository implements HabitoRepository {
  static const chaveBase = 'habito_v1';

  final String? uid;
  LocalHabitoRepository({this.uid});

  String get chave => uid == null ? chaveBase : '$chaveBase:$uid';

  @override
  Future<Habito> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      final texto = p.getString(chave);
      return texto == null ? Habito.vazio : Habito.fromJson(jsonDecode(texto));
    } catch (_) {
      // JSON corrompido ou sem armazenamento: recomeça do padrão, sem derrubar a tela
      return Habito.vazio;
    }
  }

  @override
  Future<void> salvar(Habito habito) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(chave, jsonEncode(habito.toJson()));
    } catch (_) {}
  }
}

/// Na nuvem: o campo `habito` (um mapa) do próprio `users/{uid}` — as regras que
/// já existem cobrem, e a exclusão da conta apaga o documento (e o hábito junto).
/// Cada aparelho guarda também uma cópia local: dá para estudar sem internet e,
/// ao voltar, o que estiver adiantado de um lado ou do outro prevalece
/// ([Habito.mesclar]).
class FirestoreHabitoRepository implements HabitoRepository {
  final String uid;
  final FirebaseFirestore? _dbInjetado;
  final HabitoRepository _local;

  /// O Firestore só é tocado quando há o que ler/gravar: sem Firebase iniciado (testes de tela
  /// que montam o app inteiro) o hábito segue no aparelho em vez de derrubar a construção.
  FirestoreHabitoRepository(this.uid, {FirebaseFirestore? db, HabitoRepository? local})
      : _dbInjetado = db,
        _local = local ?? LocalHabitoRepository(uid: uid);

  DocumentReference<Map<String, dynamic>> get _doc =>
      (_dbInjetado ?? FirebaseFirestore.instance).collection('users').doc(uid);

  /// Mescla a cópia local com a da nuvem e deixa os dois lados iguais. Sem rede, vale o
  /// que há no aparelho (e a nuvem se acerta no próximo carregar ou salvar).
  @override
  Future<Habito> carregar() async {
    final local = await _local.carregar();
    Habito remoto;
    try {
      remoto = Habito.fromJson((await _doc.get()).data()?['habito']);
    } catch (_) {
      return local;
    }
    final junto = Habito.mesclar(local, remoto);
    // o que a nuvem não tinha (estudou offline) sobe agora; o que o aparelho não tinha, desce
    try {
      if (junto != remoto) await _enviar(junto);
    } catch (_) {}
    if (junto != local) await _local.salvar(junto);
    return junto;
  }

  /// Local primeiro (não depende de rede); a nuvem depois — se falhar, lança, e quem
  /// chamou decide (o cubit engole: o aparelho já guardou).
  @override
  Future<void> salvar(Habito habito) async {
    await _local.salvar(habito);
    await _enviar(habito);
  }

  /// `merge: true`: só o campo `habito` muda; `concluidas`, `recorde` etc. ficam como estão.
  Future<void> _enviar(Habito h) => _doc.set({'habito': h.toJson()}, SetOptions(merge: true));
}
