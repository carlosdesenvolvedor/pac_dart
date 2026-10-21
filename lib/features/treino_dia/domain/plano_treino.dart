import 'dart:convert';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// "⚡ Treino do dia": o plano de ~10 min montado com o que a pessoa já tem (revisão, palavras,
/// ouvir, rali; no Dart/C#, quizzes de revisão + rali). Puro Dart, sem Flutter — toda regra é
/// função do "agora" que chega de fora.
///
/// Plano FASE-9 (§5): os blocos são trocados como lista inteira; [PlanoTreino.mesclar] junta o
/// aparelho com a nuvem.

/// Exercícios somados na meta do dia ao concluir um treino que valeu (1× por conta por dia).
const bonusTreino = 3;

/// O título da sessão avulsa do "🎧 Ouvir" que o treino abre (é por ele que o painel a reconhece).
const tituloOuvirTreino = '⚡ Treino do dia';

enum TipoBloco { revisao, palavras, ouvir, rali, quiz }

enum EstadoBloco { pendente, feito, pulado }

enum SituacaoTreino { pendente, emAndamento, concluido }

/// Uma etapa do treino.
class BlocoTreino extends Equatable {
  /// `revisao` | `palavras` | `ouvir` | `rali` | `quiz:<t>:<l>`.
  final String id;
  final TipoBloco tipo;
  final EstadoBloco estado;

  /// Quanto foi planejado, para o subtítulo (frases, palavras, perguntas…).
  final int qtd;

  /// Só `revisao`: os cartões planejados; 0 nos outros.
  final int qtd2;

  /// A estimativa mostrada na tela (≥ 1).
  final int minutos;

  /// revisadas / palavras / ouvidas / pontos / acertos.
  final int resultado;

  /// Só `quiz`: o total de perguntas; 0 nos outros.
  final int total;

  /// Só `quiz`: a trilha e a lição; -1 nos outros.
  final int t, l;

  /// Marcado feito porque não havia nada a fazer quando começou ([BlocoVazio]). Não vale para o bônus.
  final bool vazio;

  const BlocoTreino({
    required this.id,
    required this.tipo,
    this.estado = EstadoBloco.pendente,
    this.qtd = 0,
    this.qtd2 = 0,
    this.minutos = 1,
    this.resultado = 0,
    this.total = 0,
    this.t = -1,
    this.l = -1,
    this.vazio = false,
  });

  BlocoTreino copyWith({EstadoBloco? estado, int? resultado, int? total, bool? vazio}) => BlocoTreino(
        id: id,
        tipo: tipo,
        estado: estado ?? this.estado,
        qtd: qtd,
        qtd2: qtd2,
        minutos: minutos,
        resultado: resultado ?? this.resultado,
        total: total ?? this.total,
        t: t,
        l: l,
        vazio: vazio ?? this.vazio,
      );

  bool get resolvido => estado != EstadoBloco.pendente;

  /// Etapa de estudo de verdade (dá exercícios no hábito): revisão, palavras e quiz.
  bool get ativo => tipo == TipoBloco.revisao || tipo == TipoBloco.palavras || tipo == TipoBloco.quiz;

  /// O que conta para o bônus: feito e não [vazio].
  bool get feitoDeVerdade => estado == EstadoBloco.feito && !vazio;

  /// Chaves curtas `i,y,e,q,q2,m,r,n,t,l,z`; os valores padrão ficam de fora (os blocos são
  /// trocados como lista inteira, nunca mesclados chave a chave).
  Map<String, dynamic> toJson() => {
        'i': id,
        'y': tipo.name,
        if (estado != EstadoBloco.pendente) 'e': estado.name,
        if (qtd != 0) 'q': qtd,
        if (qtd2 != 0) 'q2': qtd2,
        if (minutos != 1) 'm': minutos,
        if (resultado != 0) 'r': resultado,
        if (total != 0) 'n': total,
        if (t != -1) 't': t,
        if (l != -1) 'l': l,
        if (vazio) 'z': true,
      };

  /// Tolerante: tipo desconhecido (ou lixo) → null (o bloco é descartado).
  static BlocoTreino? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['i'];
    final tipo = _enumDe(TipoBloco.values, j['y']);
    if (id is! String || id.isEmpty || tipo == null) return null;
    return BlocoTreino(
      id: id,
      tipo: tipo,
      estado: _enumDe(EstadoBloco.values, j['e']) ?? EstadoBloco.pendente,
      qtd: _naoNegativo(j['q']) ?? 0,
      qtd2: _naoNegativo(j['q2']) ?? 0,
      minutos: _naoNegativo(j['m']) ?? 1,
      resultado: _naoNegativo(j['r']) ?? 0,
      total: _naoNegativo(j['n']) ?? 0,
      t: _naoNegativo(j['t']) ?? -1,
      l: _naoNegativo(j['l']) ?? -1,
      vazio: j['z'] == true,
    );
  }

  @override
  List<Object?> get props => [id, tipo, estado, qtd, qtd2, minutos, resultado, total, t, l, vazio];
}

/// O treino de um dia num curso.
class PlanoTreino extends Equatable {
  /// `diaDe(agora)` — o dia do calendário local.
  final int dia;

  /// `Linguagem.id`.
  final String curso;
  final List<BlocoTreino> blocos;

  /// ≤ 6: `chaveDaFrase` das frases revisadas neste treino (o trecho do 🎧 Ouvir).
  final List<String> ouvirChaves;

  /// ≤ 12: as palavras (EN) treinadas neste treino (o foco do 🏁 Rali).
  final List<String> palavrasFoco;

  /// Nenhuma etapa de estudo ativo (revisão/palavras/quiz).
  final bool curto;

  /// Montado com "Começar assim mesmo" antes de todas as fontes carregarem.
  final bool incompleto;

  /// Este plano já passou pelo passo do bônus (ganho ou não).
  final bool bonus;

  /// ms desde 1970.
  final int editadoEm;

  const PlanoTreino({
    required this.dia,
    required this.curso,
    this.blocos = const [],
    this.ouvirChaves = const [],
    this.palavrasFoco = const [],
    this.curto = false,
    this.incompleto = false,
    this.bonus = false,
    this.editadoEm = 0,
  });

  PlanoTreino copyWith({
    int? dia,
    String? curso,
    List<BlocoTreino>? blocos,
    List<String>? ouvirChaves,
    List<String>? palavrasFoco,
    bool? curto,
    bool? incompleto,
    bool? bonus,
    int? editadoEm,
  }) =>
      PlanoTreino(
        dia: dia ?? this.dia,
        curso: curso ?? this.curso,
        blocos: blocos ?? this.blocos,
        ouvirChaves: ouvirChaves ?? this.ouvirChaves,
        palavrasFoco: palavrasFoco ?? this.palavrasFoco,
        curto: curto ?? this.curto,
        incompleto: incompleto ?? this.incompleto,
        bonus: bonus ?? this.bonus,
        editadoEm: editadoEm ?? this.editadoEm,
      );

  /// Etapas feitas ou puladas.
  int get resolvidos => blocos.where((b) => b.resolvido).length;

  /// A estimativa do treino inteiro.
  int get minutos => blocos.fold(0, (s, b) => s + b.minutos);

  /// Etapas feitas de verdade (um bloco [BlocoTreino.vazio] não conta).
  int get feitos => blocos.where((b) => b.feitoDeVerdade).length;

  bool get concluido => blocos.isNotEmpty && blocos.every((b) => b.resolvido);

  bool get algumAtivoResolvido => blocos.any((b) => b.ativo && b.resolvido);

  /// A primeira etapa pendente (null = nada falta).
  BlocoTreino? get proximo {
    for (final b in blocos) {
      if (!b.resolvido) return b;
    }
    return null;
  }

  SituacaoTreino get situacao => concluido
      ? SituacaoTreino.concluido
      : resolvidos == 0
          ? SituacaoTreino.pendente
          : SituacaoTreino.emAndamento;

  /// O plano vale o bônus do treino ([bonusTreino]): concluído, ainda sem passar pelo bônus, nem
  /// curto nem incompleto, com ao menos uma etapa ativa feita de verdade com resultado e ≥ 2 feitas
  /// (ou todas, se o plano tem menos).
  bool get merecebonus =>
      concluido &&
      !bonus &&
      !curto &&
      !incompleto &&
      blocos.any((b) => b.ativo && b.feitoDeVerdade && b.resultado > 0) &&
      feitos >= math.min(2, blocos.length);

  /// Até 6 frases para o 🎧 Ouvir; até 12 palavras para o foco do 🏁 Rali.
  static const maxOuvir = 6, maxFoco = 12;

  /// `curto` de uma lista de blocos: nenhuma etapa de estudo ativo.
  static bool curtoDe(Iterable<BlocoTreino> blocos) => !blocos.any((b) => b.ativo);

  /// Muda o estado da etapa [id] ([resultado]/[total] trocam só quando vêm; [vazio] sempre). Sem a
  /// etapa, ou sem mudança nenhuma, devolve o próprio plano.
  PlanoTreino marcar(String id, EstadoBloco e,
      {int? resultado, int? total, bool vazio = false, required int agoraMs}) {
    final i = blocos.indexWhere((b) => b.id == id);
    if (i < 0) return this;
    final n = blocos[i].copyWith(estado: e, resultado: resultado, total: total, vazio: vazio);
    if (n == blocos[i]) return this;
    return copyWith(blocos: [...blocos]..[i] = n, editadoEm: agoraMs);
  }

  /// Põe [novos] (etapas ativas cujo id o plano ainda não tem) na frente, recalcula [curto] e limpa
  /// [incompleto] quando [fontesCompletas]. Só vale enquanto `!algumAtivoResolvido` e o plano não está
  /// [concluido] (um curto já terminado fica terminado: "Feito hoje ✓ — volte amanhã"). Sem mudança
  /// nenhuma, devolve o próprio plano.
  PlanoTreino completar(List<BlocoTreino> novos, {required bool fontesCompletas, required int agoraMs}) {
    if (concluido || algumAtivoResolvido) return this;
    final ids = {for (final b in blocos) b.id};
    final entram = [
      for (final b in novos)
        if (b.ativo && ids.add(b.id)) b,
    ];
    final incompletoDepois = incompleto && !fontesCompletas;
    if (entram.isEmpty && incompletoDepois == incompleto) return this;
    final todos = [...entram, ...blocos];
    return copyWith(blocos: todos, curto: curtoDe(todos), incompleto: incompletoDepois, editadoEm: agoraMs);
  }

  /// Sem repetidas, até 6.
  PlanoTreino anotarOuvir(Iterable<String> chaves, {required int agoraMs}) {
    final l = _uniao(ouvirChaves, chaves, maxOuvir);
    return _mesmaLista(l, ouvirChaves) ? this : copyWith(ouvirChaves: l, editadoEm: agoraMs);
  }

  /// Sem repetidas, até 12.
  PlanoTreino anotarFoco(Iterable<String> ens, {required int agoraMs}) {
    final l = _uniao(palavrasFoco, ens, maxFoco);
    return _mesmaLista(l, palavrasFoco) ? this : copyWith(palavrasFoco: l, editadoEm: agoraMs);
  }

  PlanoTreino comBonus({required int agoraMs}) => copyWith(bonus: true, editadoEm: agoraMs);

  /// `{"v":1,"d","c","b","o","f","k","p","x","m"}` — SEMPRE com todas as chaves de cima (false e []
  /// inclusive): na nuvem o campo é trocado inteiro, e nenhuma chave velha pode sobreviver.
  Map<String, dynamic> toJson() => {
        'v': 1,
        'd': dia,
        'c': curso,
        'b': [for (final b in blocos) b.toJson()],
        'o': ouvirChaves,
        'f': palavrasFoco,
        'k': curto,
        'p': incompleto,
        'x': bonus,
        'm': editadoEm,
      };

  /// Tolerante: `v != 1` ou lixo → null. Sem nenhuma etapa que se aproveite (lixo, ou só tipos de uma
  /// versão mais nova) também → null: um plano vazio nunca acaba e travaria o dia inteiro.
  static PlanoTreino? fromJson(Object? j) {
    if (j is! Map || j['v'] != 1) return null;
    final dia = _naoNegativo(j['d']);
    final curso = j['c'];
    final b = j['b'];
    if (dia == null || curso is! String || b is! List) return null;
    final blocos = <BlocoTreino>[];
    final ids = <String>{};
    for (final e in b) {
      final bloco = BlocoTreino.fromJson(e);
      if (bloco != null && ids.add(bloco.id)) blocos.add(bloco);
    }
    if (blocos.isEmpty) return null;
    List<String> textos(Object? v, int max) =>
        v is List ? _uniao(const [], [for (final e in v) if (e is String) e], max) : const [];
    return PlanoTreino(
      dia: dia,
      curso: curso,
      blocos: blocos,
      ouvirChaves: textos(j['o'], maxOuvir),
      palavrasFoco: textos(j['f'], maxFoco),
      curto: j['k'] == true,
      incompleto: j['p'] == true,
      bonus: j['x'] == true,
      editadoEm: _naoNegativo(j['m']) ?? 0,
    );
  }

  /// Junta o plano do aparelho com o da nuvem (plano FASE-9 §5):
  /// - um lado nulo → o outro; cursos diferentes → [a];
  /// - dias diferentes → o dia mais novo;
  /// - mesmo dia: a base é o lado com mais etapas resolvidas (empate: o editado por último; depois
  ///   uma ordem fixa do conteúdo, para não depender de quem vem primeiro). Cada etapa fica com o
  ///   estado mais adiantado (feito > pulado > pendente), o maior resultado/total, e `vazio` de quem
  ///   venceu o estado (empate: só é vazio se os dois forem). Etapas que só o outro lado tem (um
  ///   `completar` feito lá) entram se a base ainda não resolveu nenhuma etapa ativa: as ativas na
  ///   frente, as outras no fim. bonus = a ou b; incompleto = a e b; frases/palavras unidas.
  static PlanoTreino? mesclar(PlanoTreino? a, PlanoTreino? b) {
    if (a == null) return b;
    if (b == null || a == b) return a;
    if (a.curso != b.curso) return a;
    if (a.dia != b.dia) return a.dia > b.dia ? a : b;
    final base = _ordem(a, b) >= 0 ? a : b;
    final outro = identical(base, a) ? b : a;

    final doOutro = {for (final x in outro.blocos) x.id: x};
    final daBase = {for (final x in base.blocos) x.id};
    final juntos = <BlocoTreino>[];
    for (final x in base.blocos) {
      final y = doOutro[x.id];
      juntos.add(y == null ? x : _juntarBloco(x, y));
    }
    final soNoOutro = [for (final y in outro.blocos) if (!daBase.contains(y.id)) y];
    final blocos = base.algumAtivoResolvido || soNoOutro.isEmpty
        ? juntos
        : [
            for (final y in soNoOutro) if (y.ativo) y,
            ...juntos,
            for (final y in soNoOutro) if (!y.ativo) y,
          ];
    return PlanoTreino(
      dia: base.dia,
      curso: base.curso,
      blocos: blocos,
      ouvirChaves: _uniao(base.ouvirChaves, outro.ouvirChaves, maxOuvir),
      palavrasFoco: _uniao(base.palavrasFoco, outro.palavrasFoco, maxFoco),
      curto: curtoDe(blocos),
      incompleto: a.incompleto && b.incompleto,
      bonus: a.bonus || b.bonus,
      editadoEm: math.max(a.editadoEm, b.editadoEm),
    );
  }

  /// > 0: [a] é a base; < 0: [b]. Só dá 0 quando os dois são iguais.
  static int _ordem(PlanoTreino a, PlanoTreino b) {
    for (final c in [a.resolvidos.compareTo(b.resolvidos), a.editadoEm.compareTo(b.editadoEm)]) {
      if (c != 0) return c;
    }
    return jsonEncode(a.toJson()).compareTo(jsonEncode(b.toJson()));
  }

  static int _peso(EstadoBloco e) => switch (e) {
        EstadoBloco.feito => 2,
        EstadoBloco.pulado => 1,
        EstadoBloco.pendente => 0,
      };

  static BlocoTreino _juntarBloco(BlocoTreino x, BlocoTreino y) {
    final px = _peso(x.estado), py = _peso(y.estado);
    final venceu = px >= py ? x : y;
    return x.copyWith(
      estado: venceu.estado,
      resultado: math.max(x.resultado, y.resultado),
      total: math.max(x.total, y.total),
      vazio: px == py ? x.vazio && y.vazio : venceu.vazio,
    );
  }

  @override
  List<Object?> get props =>
      [dia, curso, blocos, ouvirChaves, palavrasFoco, curto, incompleto, bonus, editadoEm];
}

/// [base] + [mais], sem repetidas nem vazias, na ordem em que apareceram, até [max].
List<String> _uniao(Iterable<String> base, Iterable<String> mais, int max) {
  final vistos = <String>{};
  final l = <String>[];
  for (final s in [...base, ...mais]) {
    if (l.length >= max) break;
    if (s.isNotEmpty && vistos.add(s)) l.add(s);
  }
  return List.unmodifiable(l);
}

bool _mesmaLista(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Um inteiro ≥ 0 de um número qualquer do JSON (null se não for).
int? _naoNegativo(Object? v) => v is num && v.isFinite && v >= 0 ? v.toInt() : null;

T? _enumDe<T extends Enum>(List<T> valores, Object? nome) {
  for (final v in valores) {
    if (v.name == nome) return v;
  }
  return null;
}
