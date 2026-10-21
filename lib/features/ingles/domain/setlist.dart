import 'dart:convert';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../curso/domain/curriculo.dart';
import 'baralhos.dart';
import 'revisao.dart';

/// O que um item de setlist aponta (resolvido na hora de tocar contra `CursoState.trilhas`):
/// uma frase, um pedaço escolhido de uma lição, a lição, a unidade, a etapa (A1…DEV) ou o curso todo.
enum TipoItem { frase, trecho, licao, trilha, etapa, curso }

/// Como terminou um "➕ Pôr na setlist".
enum ResultadoAdicao { adicionado, jaEstava, cheia }

final _sorteio = math.Random();

/// Id novo de item: 'i' + micros (base 36) + 2 letras sorteadas.
String novoIdItem() => _novoId('i');

String _novoId(String prefixo) {
  const letras = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  return '$prefixo$micros${letras[_sorteio.nextInt(letras.length)]}${letras[_sorteio.nextInt(letras.length)]}';
}

int get _agoraMs => DateTime.now().millisecondsSinceEpoch;

/// Lê um inteiro de um JSON qualquer (int, double ou texto); senão, [padrao].
int _int(Object? v, [int padrao = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? padrao;
  return padrao;
}

String _txt(Object? v) => v is String ? v : '';

/// Um item da setlist ("🎧 Ouvir"). Guarda só a referência (e um retrato para exibir/tocar se ela quebrar).
class ItemSetlist extends Equatable {
  /// [novoIdItem].
  final String id;
  final TipoItem tipo;

  /// Ver a tabela de refs do plano (FASE-8): chave da frase, id da lição, baralhoId da unidade,
  /// código da etapa ou '' (curso).
  final String ref;

  /// Só `trecho`: as chaves (`chaveDaFrase`) das frases escolhidas, na ordem da lição.
  final List<String> chaves;

  /// frase/trecho: onde procurar primeiro; '' nos outros tipos.
  final String licaoId;

  /// O rótulo de exibição (retrato; vale quando a ref quebra).
  final String rotulo;

  /// Só `frase`: retrato do texto, para uma frase órfã ainda tocar; '' nos outros tipos.
  final String en, pt;

  /// ms desde 1970.
  final int criadoEm;

  const ItemSetlist({
    required this.id,
    required this.tipo,
    required this.ref,
    this.chaves = const [],
    this.licaoId = '',
    required this.rotulo,
    this.en = '',
    this.pt = '',
    required this.criadoEm,
  });

  /// O que identifica o item para não repetir na mesma setlist.
  String get assinatura => '${tipo.name}|$ref|${chaves.join(',')}';

  /// Uma frase do curso (ou de um texto do aluno). Guarda o EN/PT de retrato.
  factory ItemSetlist.daFrase(Trecho f, {Licao? licao}) => ItemSetlist(
        id: novoIdItem(),
        tipo: TipoItem.frase,
        ref: chaveDaFrase(f),
        licaoId: licao?.id ?? '',
        rotulo: '“${f.cod}”',
        en: f.cod,
        pt: f.dicaPlana,
        criadoEm: _agoraMs,
      );

  /// Do navegador de cartões; chave = `Revisao.chave(en)`.
  factory ItemSetlist.daTexto({required String en, required String pt}) => ItemSetlist(
        id: novoIdItem(),
        tipo: TipoItem.frase,
        ref: Revisao.chave(en),
        rotulo: '“$en”',
        en: en,
        pt: Trecho.semTags(pt),
        criadoEm: _agoraMs,
      );

  /// 1 frase → `frase`; todas → `licao`; senão → `trecho`. As escolhidas entram na ordem da lição
  /// (sem repetir); as que não são da lição são ignoradas. Nenhuma válida → a lição inteira.
  factory ItemSetlist.doTrecho(Licao l, List<Trecho> escolhidas) {
    final querer = {for (final f in escolhidas) chaveDaFrase(f)};
    final vistas = <String>{};
    final daLicao = <Trecho>[
      for (final f in l.trechos)
        if (querer.contains(chaveDaFrase(f)) && vistas.add(chaveDaFrase(f))) f,
    ];
    final total = {for (final f in l.trechos) chaveDaFrase(f)}.length;
    if (daLicao.isEmpty || daLicao.length >= total) return ItemSetlist.daLicao(l);
    if (daLicao.length == 1) return ItemSetlist.daFrase(daLicao.first, licao: l);
    return ItemSetlist(
      id: novoIdItem(),
      tipo: TipoItem.trecho,
      ref: l.id,
      chaves: [for (final f in daLicao) chaveDaFrase(f)],
      licaoId: l.id,
      rotulo: '${l.nome} · ${daLicao.length} frases',
      criadoEm: _agoraMs,
    );
  }

  factory ItemSetlist.daLicao(Licao l) =>
      ItemSetlist(id: novoIdItem(), tipo: TipoItem.licao, ref: l.id, rotulo: l.nome, criadoEm: _agoraMs);

  factory ItemSetlist.daTrilha(Trilha t) => ItemSetlist(
      id: novoIdItem(), tipo: TipoItem.trilha, ref: t.baralhoId, rotulo: 'Unidade: ${t.nivel}', criadoEm: _agoraMs);

  /// ref = [codigoEtapa] de [etapa].
  factory ItemSetlist.daEtapa(String etapa) {
    final codigo = codigoEtapa(etapa);
    return ItemSetlist(id: novoIdItem(), tipo: TipoItem.etapa, ref: codigo, rotulo: 'Etapa $codigo', criadoEm: _agoraMs);
  }

  factory ItemSetlist.doCurso() =>
      ItemSetlist(id: novoIdItem(), tipo: TipoItem.curso, ref: '', rotulo: 'Curso inteiro', criadoEm: _agoraMs);

  /// 'A1 · Fundação' → 'A1' (… 'DEV').
  static String codigoEtapa(String etapa) => etapa.split('·').first.trim();

  /// JSON curto (ver o plano): chaves vazias ficam de fora.
  Map<String, dynamic> toJson() => {
        'i': id,
        't': tipo.name,
        if (ref.isNotEmpty) 'r': ref,
        if (chaves.isNotEmpty) 'k': chaves,
        if (licaoId.isNotEmpty) 'l': licaoId,
        if (rotulo.isNotEmpty) 'n': rotulo,
        if (en.isNotEmpty) 'en': en,
        if (pt.isNotEmpty) 'pt': pt,
        'c': criadoEm,
      };

  /// Tolerante nos campos; mas um `tipo` desconhecido (ou sem id) lança [FormatException] — quem lê o
  /// banco ([BancoSetlists.fromJsonString]) descarta o item.
  factory ItemSetlist.fromJson(Map<String, dynamic> j) {
    final id = _txt(j['i']);
    final nomeTipo = j['t'];
    final tipo = TipoItem.values.where((t) => t.name == nomeTipo).firstOrNull;
    if (id.isEmpty || tipo == null) throw FormatException('item de setlist inválido: $j');
    final k = j['k'];
    return ItemSetlist(
      id: id,
      tipo: tipo,
      ref: _txt(j['r']),
      chaves: k is List ? [for (final c in k) if (c is String && c.isNotEmpty) c] : const [],
      licaoId: _txt(j['l']),
      rotulo: _txt(j['n']),
      en: _txt(j['en']),
      pt: _txt(j['pt']),
      criadoEm: _int(j['c']),
    );
  }

  @override
  List<Object?> get props => [id, tipo, ref, chaves, licaoId, rotulo, en, pt, criadoEm];
}

/// Uma setlist do aluno.
class Setlist extends Equatable {
  final String id, nome, emoji;
  final List<ItemSetlist> itens;
  final int criadoEm, editadoEm;

  /// Lápide (apagada; some da lista, mas ganha a mescla com outro aparelho).
  final bool apagada;

  const Setlist({
    required this.id,
    required this.nome,
    this.emoji = '🎧',
    this.itens = const [],
    required this.criadoEm,
    required this.editadoEm,
    this.apagada = false,
  });

  Setlist copyWith({
    String? id,
    String? nome,
    String? emoji,
    List<ItemSetlist>? itens,
    int? criadoEm,
    int? editadoEm,
    bool? apagada,
  }) =>
      Setlist(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        emoji: emoji ?? this.emoji,
        itens: itens ?? this.itens,
        criadoEm: criadoEm ?? this.criadoEm,
        editadoEm: editadoEm ?? this.editadoEm,
        apagada: apagada ?? this.apagada,
      );

  /// Frases de cada tipo, na média do curso (602 lições, 121 unidades, 5.308 frases): a conta exata
  /// precisa das trilhas (`contarFrases` em fila_ouvir.dart).
  static const _frasesPorLicao = 9, _frasesPorUnidade = 44, _frasesPorEtapa = 885, _frasesNoCurso = 5308;

  /// Quantas frases, aproximado (não é gravado).
  int get frasesAprox {
    var n = 0;
    for (final i in itens) {
      n += switch (i.tipo) {
        TipoItem.frase => 1,
        TipoItem.trecho => i.chaves.isEmpty ? _frasesPorLicao : i.chaves.length,
        TipoItem.licao => _frasesPorLicao,
        TipoItem.trilha => _frasesPorUnidade,
        TipoItem.etapa => _frasesPorEtapa,
        TipoItem.curso => _frasesNoCurso,
      };
    }
    return n;
  }

  Map<String, dynamic> toJson() => {
        if (nome.isNotEmpty) 'n': nome,
        if (emoji != '🎧' && emoji.isNotEmpty) 'e': emoji,
        'c': criadoEm,
        'm': editadoEm,
        if (apagada) 'x': true,
        'i': apagada ? const [] : [for (final i in itens) i.toJson()],
      };

  /// Tolerante: itens estragados (ou de um tipo que esta versão não conhece) ficam de fora.
  static Setlist fromJson(String id, Map<String, dynamic> j) {
    final apagada = j['x'] == true;
    final itens = <ItemSetlist>[];
    final lidos = j['i'];
    if (!apagada && lidos is List) {
      for (final e in lidos) {
        try {
          if (e is Map) itens.add(ItemSetlist.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
    }
    final emoji = _txt(j['e']);
    return Setlist(
      id: id,
      nome: _txt(j['n']),
      emoji: emoji.isEmpty ? '🎧' : emoji,
      itens: itens,
      criadoEm: _int(j['c']),
      editadoEm: _int(j['m']),
      apagada: apagada,
    );
  }

  @override
  List<Object?> get props => [id, nome, emoji, itens, criadoEm, editadoEm, apagada];
}

/// Todas as setlists do aluno (um documento só: `users/{uid}/setlists/v1`, campo `b`).
///
/// Imutável: cada operação devolve um banco novo (ou o MESMO objeto quando nada muda — o cubit usa isso
/// para não gravar à toa).
class BancoSetlists extends Equatable {
  static const maxSetlists = 50, maxItens = 300, maxBytes = 900000;

  /// Lápides mais velhas que isso saem ao gravar ([toJsonString]).
  static const diasLapide = 90;

  /// O nome quando a pessoa não dá um (e o da setlist criada sozinha no primeiro ➕).
  static const nomePadrao = 'Minha setlist';

  final Map<String, Setlist> porId;
  final String ultimaUsada;

  /// Marca da poda (ms): o `editadoEm` da lápide mais nova que já saiu deste banco ([toJsonString]).
  /// Na [mesclar], uma setlist que só o OUTRO lado tem e não foi editada depois dessa marca é a que foi
  /// apagada e podada aqui — o aparelho parado há mais de [diasLapide] dias não a ressuscita.
  final int podadoAte;

  const BancoSetlists({this.porId = const {}, this.ultimaUsada = '', this.podadoAte = 0});

  /// As não apagadas, a editada mais recentemente primeiro.
  List<Setlist> get visiveis =>
      [for (final s in porId.values) if (!s.apagada) s]..sort((a, b) => b.editadoEm.compareTo(a.editadoEm));

  /// A setlist [id] se existe e não foi apagada.
  Setlist? viva(String id) {
    final s = porId[id];
    return s == null || s.apagada ? null : s;
  }

  BancoSetlists _com(Setlist s, {String? ultimaUsada}) =>
      BancoSetlists(porId: {...porId, s.id: s}, ultimaUsada: ultimaUsada ?? this.ultimaUsada, podadoAte: podadoAte);

  /// Cria e já marca como a última usada. Com [maxSetlists] visíveis, não cria: devolve `(this, '')`.
  (BancoSetlists, String) criar(String nome, {String emoji = '🎧', required int agora}) {
    if (visiveis.length >= maxSetlists) return (this, '');
    var id = _novoId('s');
    while (porId.containsKey(id)) {
      id = _novoId('s');
    }
    final n = nome.trim();
    final s = Setlist(
      id: id,
      nome: n.isEmpty ? nomePadrao : n,
      emoji: emoji.trim().isEmpty ? '🎧' : emoji.trim(),
      criadoEm: agora,
      editadoEm: agora,
    );
    return (_com(s, ultimaUsada: id), id);
  }

  /// Nome vazio mantém o atual. Setlist inexistente/apagada (ou nada mudou): o mesmo banco.
  BancoSetlists renomear(String id, String nome, {String? emoji, required int agora}) {
    final s = viva(id);
    if (s == null) return this;
    final n = nome.trim();
    final e = emoji?.trim() ?? '';
    final novoNome = n.isEmpty ? s.nome : n;
    final novoEmoji = e.isEmpty ? s.emoji : e;
    if (novoNome == s.nome && novoEmoji == s.emoji) return this;
    return _com(s.copyWith(nome: novoNome, emoji: novoEmoji, editadoEm: agora));
  }

  /// Vira lápide (sem itens). Se era a última usada, ninguém fica no lugar.
  BancoSetlists apagar(String id, {required int agora}) {
    final s = viva(id);
    if (s == null) return this;
    return _com(s.copyWith(apagada: true, itens: const [], editadoEm: agora),
        ultimaUsada: ultimaUsada == id ? '' : ultimaUsada);
  }

  /// Põe no fim. Repetido (mesma [ItemSetlist.assinatura]) → `jaEstava`; no limite de itens ou de bytes
  /// (ou setlist inexistente/apagada) → `cheia`. Adicionar (ou já estar) marca a setlist como a última usada.
  (BancoSetlists, ResultadoAdicao) adicionar(String setlistId, ItemSetlist item, {required int agora}) {
    final s = viva(setlistId);
    if (s == null) return (this, ResultadoAdicao.cheia);
    if (s.itens.any((i) => i.assinatura == item.assinatura)) return (usar(setlistId), ResultadoAdicao.jaEstava);
    if (s.itens.length >= maxItens) return (this, ResultadoAdicao.cheia);
    final novo = _com(s.copyWith(itens: [...s.itens, item], editadoEm: agora), ultimaUsada: setlistId);
    if (utf8.encode(novo.toJsonString(agora: agora)).length > maxBytes) return (this, ResultadoAdicao.cheia);
    return (novo, ResultadoAdicao.adicionado);
  }

  BancoSetlists remover(String setlistId, String itemId, {required int agora}) {
    final s = viva(setlistId);
    if (s == null || !s.itens.any((i) => i.id == itemId)) return this;
    return _com(s.copyWith(itens: [for (final i in s.itens) if (i.id != itemId) i], editadoEm: agora));
  }

  /// Desfazer uma remoção: volta [item] na posição [indice] (limitada à lista). Se ele (ou um igual)
  /// já está lá, nada muda.
  BancoSetlists restaurar(String setlistId, ItemSetlist item, int indice, {required int agora}) {
    final s = viva(setlistId);
    if (s == null || s.itens.any((i) => i.id == item.id || i.assinatura == item.assinatura)) return this;
    final itens = [...s.itens]..insert(indice.clamp(0, s.itens.length), item);
    return _com(s.copyWith(itens: itens, editadoEm: agora));
  }

  /// Tira o item da posição [de] e o põe em [para] — a posição FINAL dele (no `onReorder` do
  /// `ReorderableListView`, quem chama desconta 1 quando `para > de`). [para] é limitado à lista.
  BancoSetlists mover(String setlistId, int de, int para, {required int agora}) {
    final s = viva(setlistId);
    if (s == null || de < 0 || de >= s.itens.length) return this;
    final destino = para.clamp(0, s.itens.length - 1);
    if (destino == de) return this;
    final itens = [...s.itens];
    final item = itens.removeAt(de);
    itens.insert(destino, item);
    return _com(s.copyWith(itens: itens, editadoEm: agora));
  }

  /// Marca a setlist como a última usada (não conta como edição: não muda `editadoEm`).
  BancoSetlists usar(String setlistId) {
    if (setlistId == ultimaUsada || viva(setlistId) == null) return this;
    return BancoSetlists(porId: porId, ultimaUsada: setlistId, podadoAte: podadoAte);
  }

  /// Por setlist, ganha o maior `editadoEm`; no empate, a lápide (e, igualadas, a da nuvem).
  /// `ultimaUsada` vem de [local] (aparelho novo, sem nenhuma: a da nuvem); apontando para uma setlist
  /// que ficou apagada (ou de fora), vira ''. Uma setlist viva que só um lado tem e não foi editada
  /// depois da [podadoAte] do outro lado fica de fora: o outro a apagou e a lápide já foi podada.
  static BancoSetlists mesclar(BancoSetlists local, BancoSetlists nuvem) {
    final r = <String, Setlist>{};
    for (final id in {...local.porId.keys, ...nuvem.porId.keys}) {
      final a = local.porId[id], b = nuvem.porId[id];
      if (a == null || b == null) {
        final s = (a ?? b)!;
        final marcaDoOutro = a == null ? local.podadoAte : nuvem.podadoAte;
        if (!s.apagada && s.editadoEm <= marcaDoOutro) continue;
        r[id] = s;
      } else if (a.editadoEm != b.editadoEm) {
        r[id] = a.editadoEm > b.editadoEm ? a : b;
      } else {
        r[id] = a.apagada && !b.apagada ? a : b;
      }
    }
    var u = local.ultimaUsada.isNotEmpty ? local.ultimaUsada : nuvem.ultimaUsada;
    final s = r[u];
    if (s == null || s.apagada) u = '';
    final marca = local.podadoAte > nuvem.podadoAte ? local.podadoAte : nuvem.podadoAte;
    return BancoSetlists(porId: r, ultimaUsada: u, podadoAte: marca);
  }

  /// O JSON gravado (ver o plano): `{"v":1,"u":…,"p":…,"s":{id: setlist}}`. Poda lápides com mais de
  /// [diasLapide] dias (relógio [agora] em ms; padrão: agora) e guarda em `p` a marca da poda
  /// ([podadoAte]).
  String toJsonString({int? agora}) {
    final limite = (agora ?? _agoraMs) - diasLapide * Duration.millisecondsPerDay;
    var marca = podadoAte;
    final ficam = <String, Object?>{};
    for (final s in porId.values) {
      if (s.apagada && s.editadoEm < limite) {
        if (s.editadoEm > marca) marca = s.editadoEm;
      } else {
        ficam[s.id] = s.toJson();
      }
    }
    return jsonEncode({
      'v': 1,
      if (ultimaUsada.isNotEmpty) 'u': ultimaUsada,
      if (marca > 0) 'p': marca,
      's': ficam,
    });
  }

  /// Nunca lança: dado estragado → banco vazio (e uma setlist estragada fica de fora sozinha).
  static BancoSetlists fromJsonString(String? s) {
    if (s == null || s.isEmpty) return const BancoSetlists();
    try {
      final j = jsonDecode(s);
      if (j is! Map) return const BancoSetlists();
      final porId = <String, Setlist>{};
      final lista = j['s'];
      if (lista is Map) {
        for (final e in lista.entries) {
          try {
            final id = e.key;
            if (id is String && id.isNotEmpty && e.value is Map) {
              porId[id] = Setlist.fromJson(id, Map<String, dynamic>.from(e.value as Map));
            }
          } catch (_) {}
        }
      }
      final p = j['p'];
      return BancoSetlists(porId: porId, ultimaUsada: _txt(j['u']), podadoAte: p is num && p > 0 ? p.toInt() : 0);
    } catch (_) {
      return const BancoSetlists();
    }
  }

  @override
  List<Object?> get props => [porId, ultimaUsada, podadoAte];
}
