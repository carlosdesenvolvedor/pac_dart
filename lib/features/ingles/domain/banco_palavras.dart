// O banco de palavras do aluno no PAC·ENGLISH ("Minhas palavras"): as palavras
// que ele treinou, adicionou, editou ou tirou dos jogos — com o cartão FSRS de
// cada uma e o que aconteceu com ela no Arcade. As palavras das lições NÃO
// moram aqui (saem do currículo + lições concluídas); só o que não dá para
// recalcular. Fica num lugar à parte dos cartões de frase (RevisaoCubit):
// palavra treinada não infla o "vencem hoje" das frases. Dart puro.
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'palavras_novas.dart';
import 'revisao.dart';
import 'srs.dart';
import 'teimosas.dart' show EstadoSugestao, cargaEm;

export 'revisao.dart' show ResultadoRevisao;

/// De onde a palavra veio.
enum OrigemPalavra {
  /// De uma lição do curso (treinada depois da lição, no baú da unidade…).
  licao('l'),

  /// A pessoa escreveu ("➕ Adicionar palavra").
  minha('m'),

  /// Guardada numa leitura (texto colado, "Meus cartões").
  leitura('r');

  final String codigo;
  const OrigemPalavra(this.codigo);

  static OrigemPalavra deCodigo(Object? c) =>
      OrigemPalavra.values.firstWhere((o) => o.codigo == c, orElse: () => OrigemPalavra.licao);
}

/// O quanto a palavra está firme na memória (o medidor de 4 pontinhos).
enum ForcaPalavra { nova, fraca, boa, firme }

/// Uma palavra do banco. A chave é `en` em minúsculas ([chave]).
class PalavraDoBanco extends Equatable {
  final String en;
  final String pt;
  final OrigemPalavra origem;
  final String? licaoId;
  final String? exemplo;

  /// Quando entrou no banco e quando mudou por último (ms desde 1970) — na mescla entre aparelhos, a
  /// edição mais nova vale para a tradução, o "nos jogos" e o "removida".
  final int criadaEm;
  final int atualizadoEm;

  /// A memória da palavra (null = nunca treinada).
  final CartaoSrs? cartao;

  /// Quantas vezes apareceu nos jogos e quantas a pessoa errou.
  final int vistasJogo;
  final int errosJogo;

  /// Entra nos jogos do Arcade (a pessoa pode tirar).
  final bool noJogo;

  /// Apagada (lápide: some em todos os aparelhos na próxima mescla).
  final bool removida;

  // ---------- "palavras teimosas" (teimosas.dart) ----------

  /// A carga de erro E e as exposições N (pesadas, com meia-vida de 14 dias) e o dia do último
  /// decaimento: E e N valem para [cargaDia]; [cargaEm] traz para hoje.
  final double cargaErro;
  final double cargaVistas;
  final int cargaDia;

  /// Quantas vezes errou de vez (lições, revisões, cartões e treino) — o "errou 7x".
  final int errosTotal;
  final int ultimoErroDia;

  /// Acertos limpos seguidos (no máximo um por dia) e o dia do último.
  final int acertosSeguidos;
  final int ultimoAcertoDia;

  /// Já foi teimosa (e ainda não foi dominada).
  final bool foiTeimosa;

  /// O dia em que foi DOMINADA (0 = nunca).
  final int dominadaEm;

  /// Não sugerir antes deste dia ("Já sei essa", treinada hoje).
  final int naoSugerirAte;

  const PalavraDoBanco({
    required this.en,
    required this.pt,
    this.origem = OrigemPalavra.licao,
    this.licaoId,
    this.exemplo,
    this.criadaEm = 0,
    this.atualizadoEm = 0,
    this.cartao,
    this.vistasJogo = 0,
    this.errosJogo = 0,
    this.noJogo = true,
    this.removida = false,
    this.cargaErro = 0,
    this.cargaVistas = 0,
    this.cargaDia = 0,
    this.errosTotal = 0,
    this.ultimoErroDia = 0,
    this.acertosSeguidos = 0,
    this.ultimoAcertoDia = 0,
    this.foiTeimosa = false,
    this.dominadaEm = 0,
    this.naoSugerirAte = 0,
  });

  String get chave => en.toLowerCase();

  /// A palavra pronta para uma sessão de treino.
  PalavraNova get comoPalavraNova => PalavraNova(en: en, pt: pt, ptCompleta: pt, licaoId: licaoId ?? '', exemplo: exemplo ?? '');

  PalavraDoBanco copyWith({
    String? en,
    String? pt,
    OrigemPalavra? origem,
    String? licaoId,
    String? exemplo,
    int? criadaEm,
    int? atualizadoEm,
    CartaoSrs? cartao,
    int? vistasJogo,
    int? errosJogo,
    bool? noJogo,
    bool? removida,
    double? cargaErro,
    double? cargaVistas,
    int? cargaDia,
    int? errosTotal,
    int? ultimoErroDia,
    int? acertosSeguidos,
    int? ultimoAcertoDia,
    bool? foiTeimosa,
    int? dominadaEm,
    int? naoSugerirAte,
  }) =>
      PalavraDoBanco(
        en: en ?? this.en,
        pt: pt ?? this.pt,
        origem: origem ?? this.origem,
        licaoId: licaoId ?? this.licaoId,
        exemplo: exemplo ?? this.exemplo,
        criadaEm: criadaEm ?? this.criadaEm,
        atualizadoEm: atualizadoEm ?? this.atualizadoEm,
        cartao: cartao ?? this.cartao,
        vistasJogo: vistasJogo ?? this.vistasJogo,
        errosJogo: errosJogo ?? this.errosJogo,
        noJogo: noJogo ?? this.noJogo,
        removida: removida ?? this.removida,
        cargaErro: cargaErro ?? this.cargaErro,
        cargaVistas: cargaVistas ?? this.cargaVistas,
        cargaDia: cargaDia ?? this.cargaDia,
        errosTotal: errosTotal ?? this.errosTotal,
        ultimoErroDia: ultimoErroDia ?? this.ultimoErroDia,
        acertosSeguidos: acertosSeguidos ?? this.acertosSeguidos,
        ultimoAcertoDia: ultimoAcertoDia ?? this.ultimoAcertoDia,
        foiTeimosa: foiTeimosa ?? this.foiTeimosa,
        dominadaEm: dominadaEm ?? this.dominadaEm,
        naoSugerirAte: naoSugerirAte ?? this.naoSugerirAte,
      );

  static double _dec2(double v) => (v * 100).roundToDouble() / 100;

  /// Compacto (milhares cabem num documento): só os campos que fogem do padrão.
  Map<String, dynamic> toJson() => {
        'e': en,
        'p': pt,
        if (origem != OrigemPalavra.licao) 'o': origem.codigo,
        if (licaoId != null && licaoId!.isNotEmpty) 'l': licaoId,
        if (exemplo != null && exemplo!.isNotEmpty) 'x': exemplo,
        if (criadaEm != 0) 'c': criadaEm,
        if (atualizadoEm != 0) 'u': atualizadoEm,
        if (cartao != null) 'k': cartao!.codificar(),
        if (vistasJogo != 0) 'v': vistasJogo,
        if (errosJogo != 0) 'r': errosJogo,
        if (!noJogo) 'j': 0,
        if (removida) 'd': 1,
        if (_dec2(cargaErro) != 0) 'ce': _dec2(cargaErro),
        if (_dec2(cargaVistas) != 0) 'cv': _dec2(cargaVistas),
        if (cargaDia != 0) 'cd': cargaDia,
        if (errosTotal != 0) 'el': errosTotal,
        if (ultimoErroDia != 0) 'ue': ultimoErroDia,
        if (acertosSeguidos != 0) 'ok': acertosSeguidos,
        if (ultimoAcertoDia != 0) 'od': ultimoAcertoDia,
        if (foiTeimosa) 'ft': 1,
        if (dominadaEm != 0) 'dm': dominadaEm,
        if (naoSugerirAte != 0) 'ni': naoSugerirAte,
      };

  /// Null quando não dá para ler (sem `e`).
  static PalavraDoBanco? fromJson(Object? bruto) {
    if (bruto is! Map) return null;
    final en = bruto['e'];
    if (en is! String || en.trim().isEmpty) return null;
    int inteiro(Object? v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
    String? texto(Object? v) => v is String && v.isNotEmpty ? v : null;
    double real(Object? v) {
      final d = v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
      return d.isFinite && d > 0 ? d : 0;
    }

    int natural(Object? v) => inteiro(v).clamp(0, 1 << 30);
    return PalavraDoBanco(
      en: en.trim(),
      pt: bruto['p'] is String ? bruto['p'] as String : '',
      origem: OrigemPalavra.deCodigo(bruto['o']),
      licaoId: texto(bruto['l']),
      exemplo: texto(bruto['x']),
      criadaEm: inteiro(bruto['c']),
      atualizadoEm: inteiro(bruto['u']),
      cartao: bruto['k'] == null ? null : CartaoSrs.decodificar(bruto['k']),
      vistasJogo: inteiro(bruto['v']).clamp(0, 1 << 30),
      errosJogo: inteiro(bruto['r']).clamp(0, 1 << 30),
      noJogo: bruto['j'] != 0,
      removida: bruto['d'] == 1,
      cargaErro: real(bruto['ce']),
      cargaVistas: real(bruto['cv']),
      cargaDia: natural(bruto['cd']),
      errosTotal: natural(bruto['el']),
      ultimoErroDia: natural(bruto['ue']),
      acertosSeguidos: natural(bruto['ok']),
      ultimoAcertoDia: natural(bruto['od']),
      foiTeimosa: bruto['ft'] == 1 || bruto['ft'] == true,
      dominadaEm: natural(bruto['dm']),
      naoSugerirAte: natural(bruto['ni']),
    );
  }

  @override
  List<Object?> get props => [
        en, pt, origem, licaoId, exemplo, criadaEm, atualizadoEm, cartao, vistasJogo, errosJogo, noJogo, removida,
        cargaErro, cargaVistas, cargaDia, errosTotal, ultimoErroDia, acertosSeguidos, ultimoAcertoDia, foiTeimosa,
        dominadaEm, naoSugerirAte,
      ];
}

/// O banco inteiro: as palavras (pela chave em minúsculas) e as que estão "em treino" agora (as mais
/// recentes primeiro — elas vêm na frente nos jogos).
class BancoPalavras extends Equatable {
  final Map<String, PalavraDoBanco> palavras;
  final List<String> emTreino;

  /// Quando [emTreino] mudou (ms): na mescla, vale a lista do lado mais novo.
  final int emTreinoEm;

  static const maxEmTreino = 24;

  /// Quando e quantas vezes o app ofereceu treinar as teimosas (e os "Agora não").
  final EstadoSugestao sugestao;

  const BancoPalavras({
    this.palavras = const {},
    this.emTreino = const [],
    this.emTreinoEm = 0,
    this.sugestao = EstadoSugestao.vazio,
  });

  static const vazio = BancoPalavras();

  PalavraDoBanco? operator [](String en) => palavras[en.toLowerCase()];

  /// As que não foram apagadas.
  Iterable<PalavraDoBanco> get ativas => palavras.values.where((p) => !p.removida);

  /// Quantas palavras (não apagadas) há no banco.
  int get tamanho => ativas.length;

  bool get vazioDeVerdade => ativas.isEmpty;

  /// Põe (ou troca) [p].
  BancoPalavras com(PalavraDoBanco p) =>
      BancoPalavras(palavras: {...palavras, p.chave: p}, emTreino: emTreino, emTreinoEm: emTreinoEm, sugestao: sugestao);

  /// Troca o estado das sugestões de teimosas.
  BancoPalavras comSugestao(EstadoSugestao s) =>
      s == sugestao ? this : BancoPalavras(palavras: palavras, emTreino: emTreino, emTreinoEm: emTreinoEm, sugestao: s);

  /// [ens] passam para a frente do "em treino" (no máximo [maxEmTreino]).
  BancoPalavras comEmTreino(Iterable<String> ens, int agora) {
    final novas = [for (final e in ens) e.toLowerCase()];
    final lista = <String>[];
    for (final k in [...novas, ...emTreino]) {
      if (!lista.contains(k)) lista.add(k);
      if (lista.length >= maxEmTreino) break;
    }
    return BancoPalavras(palavras: palavras, emTreino: lista, emTreinoEm: agora, sugestao: sugestao);
  }

  /// Sem as entradas que só existiam por causa de erros antigos: de lição, sem cartão, nos jogos, nunca
  /// teimosa nem dominada, sem ser foco, com a carga de erro já quase zerada (< 0,2 em [hoje]) e um último
  /// erro DE VERDADE (com data e com carga gravada) há mais de 90 dias. Nunca poda as candidatas a fraca
  /// (sem cartão, 2+ erros nos jogos) nem as sem data de erro (as de antes das teimosas, as só de erros
  /// parciais). Só o aparelho: na nuvem a entrada continua (a mescla a traz de volta — sem lápide).
  /// Nada a podar = o mesmo banco.
  BancoPalavras podado(int hoje) {
    List<String>? fora;
    for (final e in palavras.entries) {
      final p = e.value;
      if (p.origem != OrigemPalavra.licao ||
          p.cartao != null ||
          !p.noJogo ||
          p.removida ||
          p.foiTeimosa ||
          p.dominadaEm != 0 ||
          (p.errosTotal == 0 && p.cargaErro == 0 && p.errosJogo == 0) ||
          p.ultimoErroDia <= 0 ||
          p.cargaDia <= 0 ||
          p.errosJogo >= 2 ||
          emTreino.contains(e.key) ||
          cargaEm(p, hoje) >= 0.2 ||
          p.ultimoErroDia >= hoje - 90) {
        continue;
      }
      (fora ??= []).add(e.key);
    }
    if (fora == null) return this;
    final r = {...palavras}..removeWhere((k, _) => fora!.contains(k));
    return BancoPalavras(palavras: r, emTreino: emTreino, emTreinoEm: emTreinoEm, sugestao: sugestao);
  }

  /// A força de [p] em [hoje]: sem cartão = nova; estabilidade < 2 dias = fraca, < 10 = boa, senão firme.
  static ForcaPalavra forca(PalavraDoBanco? p, int hoje) {
    final c = p?.cartao;
    if (c == null) return ForcaPalavra.nova;
    if (c.estabilidade < 2) return ForcaPalavra.fraca;
    if (c.estabilidade < 10) return ForcaPalavra.boa;
    return ForcaPalavra.firme;
  }

  /// As que vencem até [hoje] (as mais atrasadas primeiro).
  List<PalavraDoBanco> devidas(int hoje) => [
        for (final p in ativas)
          if (p.cartao != null && p.cartao!.devidaEm(hoje)) p,
      ]..sort((a, b) {
          final d = a.cartao!.proximoDia.compareTo(b.cartao!.proximoDia);
          return d != 0 ? d : a.chave.compareTo(b.chave);
        });

  /// As fracas que ainda NÃO venceram (cartão com memória curta, ou errada várias vezes nos jogos
  /// sem nunca ter sido treinada) — as mais erradas primeiro.
  List<PalavraDoBanco> fracas(int hoje) => [
        for (final p in ativas)
          if ((p.cartao != null && !p.cartao!.devidaEm(hoje) && p.cartao!.estabilidade < 2) ||
              (p.cartao == null && p.errosJogo >= 2))
            p,
      ]..sort((a, b) {
          final e = b.errosJogo.compareTo(a.errosJogo);
          return e != 0 ? e : a.chave.compareTo(b.chave);
        });

  // ---------- gravação ----------

  Map<String, dynamic> toJson() => {
        'p': [for (final p in palavras.values) p.toJson()],
        if (emTreino.isNotEmpty) 't': emTreino,
        if (emTreinoEm != 0) 'te': emTreinoEm,
        if (sugestao != EstadoSugestao.vazio) 's': sugestao.toJson(),
      };

  static BancoPalavras fromJson(Object? bruto) {
    if (bruto is! Map) return vazio;
    final lista = bruto['p'];
    final palavras = <String, PalavraDoBanco>{};
    if (lista is List) {
      for (final item in lista) {
        final p = PalavraDoBanco.fromJson(item);
        if (p != null) palavras[p.chave] = p;
      }
    }
    final t = bruto['t'];
    final te = bruto['te'];
    return BancoPalavras(
      palavras: palavras,
      emTreino: t is List ? [for (final e in t) if (e is String && e.isNotEmpty) e.toLowerCase()].take(maxEmTreino).toList() : const [],
      emTreinoEm: te is int ? te : (te is num ? te.toInt() : 0),
      sugestao: EstadoSugestao.fromJson(bruto['s']),
    );
  }

  /// Texto JSON compacto.
  String codificar() => jsonEncode(toJson());

  /// Nunca lança: lixo (ou nada) vira o banco vazio.
  static BancoPalavras decodificar(Object? texto) {
    if (texto == null) return vazio;
    try {
      return fromJson(texto is String ? jsonDecode(texto) : texto);
    } catch (_) {
      return vazio;
    }
  }

  /// Junta o banco deste aparelho com o da nuvem, palavra a palavra:
  /// - a edição mais nova ([PalavraDoBanco.atualizadoEm]) vale para tradução, "nos jogos" e "removida";
  /// - os contadores dos jogos ficam com o maior;
  /// - o cartão que vale é o revisado por último (empate: o com mais revisões);
  /// - o "em treino" vem do lado que mexeu nele por último;
  /// - teimosas: a carga (E, N, dia) vem inteira do lado decaído por último (empate: o que dominou
  ///   naquele dia, depois a maior E) — nunca soma os dois lados; a sequência de acertos vem do lado com o evento
  ///   mais novo; a marca de teimosa só de um lado que errou depois de dominar; o resto, o maior;
  /// - as sugestões vêm do lado que ofereceu por último.
  static BancoPalavras mesclar(BancoPalavras local, BancoPalavras nuvem) {
    final r = <String, PalavraDoBanco>{};
    for (final k in {...local.palavras.keys, ...nuvem.palavras.keys}) {
      final a = local.palavras[k], b = nuvem.palavras[k];
      if (a == null || b == null) {
        r[k] = (a ?? b)!;
        continue;
      }
      final nova = b.atualizadoEm > a.atualizadoEm ? b : a;
      final cartao = _melhorCartao(a.cartao, b.cartao);
      final criada = a.criadaEm == 0 ? b.criadaEm : (b.criadaEm == 0 ? a.criadaEm : (a.criadaEm < b.criadaEm ? a.criadaEm : b.criadaEm));
      // mesmo dia: o lado que dominou NAQUELE dia (a carga já cortada a 30%) antes da maior E
      bool dominouNoDia(PalavraDoBanco x) => x.dominadaEm > 0 && x.dominadaEm == x.cargaDia;
      final carga = b.cargaDia > a.cargaDia ||
              (b.cargaDia == a.cargaDia &&
                  (dominouNoDia(b) != dominouNoDia(a) ? dominouNoDia(b) : b.cargaErro > a.cargaErro))
          ? b
          : a;
      int ev(PalavraDoBanco x) => x.ultimoErroDia > x.ultimoAcertoDia ? x.ultimoErroDia : x.ultimoAcertoDia;
      final seq = ev(b) > ev(a) ? b : a;
      int maior(int x, int y) => x > y ? x : y;
      final dm = maior(a.dominadaEm, b.dominadaEm);
      // a marca de teimosa de um lado só vale se veio de um erro DEPOIS de dominar (a nuvem guarda o ft de
      // antes de dominar; sem isso ele voltaria a cada gravação)
      bool ft(PalavraDoBanco x) => x.foiTeimosa && (dm == 0 || x.ultimoErroDia > dm);
      r[k] = PalavraDoBanco(
        en: nova.en,
        pt: nova.pt,
        origem: nova.origem,
        licaoId: nova.licaoId ?? a.licaoId ?? b.licaoId,
        exemplo: nova.exemplo ?? a.exemplo ?? b.exemplo,
        criadaEm: criada,
        atualizadoEm: nova.atualizadoEm,
        cartao: cartao,
        vistasJogo: a.vistasJogo > b.vistasJogo ? a.vistasJogo : b.vistasJogo,
        errosJogo: a.errosJogo > b.errosJogo ? a.errosJogo : b.errosJogo,
        noJogo: nova.noJogo,
        removida: nova.removida,
        cargaErro: carga.cargaErro,
        cargaVistas: carga.cargaVistas,
        cargaDia: carga.cargaDia,
        errosTotal: maior(a.errosTotal, b.errosTotal),
        ultimoErroDia: maior(a.ultimoErroDia, b.ultimoErroDia),
        acertosSeguidos: seq.acertosSeguidos,
        ultimoAcertoDia: seq.ultimoAcertoDia,
        foiTeimosa: ft(a) || ft(b),
        dominadaEm: dm,
        naoSugerirAte: maior(a.naoSugerirAte, b.naoSugerirAte),
      );
    }
    final treino = nuvem.emTreinoEm > local.emTreinoEm ? nuvem : local;
    final sug = nuvem.sugestao.ultimaMs > local.sugestao.ultimaMs ? nuvem.sugestao : local.sugestao;
    return BancoPalavras(palavras: r, emTreino: treino.emTreino, emTreinoEm: treino.emTreinoEm, sugestao: sug);
  }

  static CartaoSrs? _melhorCartao(CartaoSrs? a, CartaoSrs? b) {
    if (a == null || b == null) return a ?? b;
    if (a.ultimoDia != b.ultimoDia) return a.ultimoDia > b.ultimoDia ? a : b;
    return b.revisoes > a.revisoes ? b : a;
  }

  @override
  List<Object?> get props => [palavras, emTreino, emTreinoEm, sugestao];
}

/// A nota de uma palavra num treino: vale a PIOR 1ª tentativa entre os passos dela. Sem um passo de
/// lembrar de verdade ([recordou] falso: só escolher/parear, que é reconhecer), a nota para em "hesitou".
ResultadoRevisao notaDoTreino(Iterable<ResultadoRevisao> tentativas, {bool recordou = true}) {
  var pior = ResultadoRevisao.acertou;
  for (final t in tentativas) {
    if (t.index < pior.index) pior = t;
  }
  if (!recordou && pior == ResultadoRevisao.acertou) return ResultadoRevisao.hesitou;
  return pior;
}

/// O cartão de [p] depois de treinada [hoje] com [resultado]. Palavra nova ganha cartão (volta amanhã);
/// a mesma palavra treinada de novo no MESMO dia só muda se errou (senão a memória inflaria à toa).
PalavraDoBanco agendar(PalavraDoBanco p, ResultadoRevisao resultado, int hoje, {AgendadorFsrs? agendador, int? agora}) {
  final a = agendador ?? AgendadorFsrs();
  final nota = notaDoResultado(resultado);
  final c = p.cartao;
  final CartaoSrs novo;
  if (c == null) {
    novo = a.novo(hoje, nota: nota);
  } else if (c.ultimoDia >= hoje) {
    novo = resultado == ResultadoRevisao.errou ? _lapsoNoMesmoDia(a, c, nota, hoje) : c;
  } else {
    novo = a.avaliar(c, nota, hoje);
  }
  return p.copyWith(cartao: novo, atualizadoEm: agora ?? p.atualizadoEm);
}

/// Errou uma palavra já revisada HOJE: é um lapso de verdade — o FSRS avalia (revisão de curto prazo:
/// revisões e lapsos sobem, dificuldade e estabilidade seguem dali) e ela volta amanhã. Nunca zera o
/// histórico (e, com mais revisões, ganha a mescla com o cartão de outro aparelho do mesmo dia).
CartaoSrs _lapsoNoMesmoDia(AgendadorFsrs a, CartaoSrs c, Rating nota, int hoje) {
  CartaoSrs r;
  try {
    r = a.avaliar(c, nota, hoje);
  } catch (_) {
    r = c;
  }
  return CartaoSrs(
    estabilidade: r.estabilidade,
    dificuldade: r.dificuldade,
    ultimoDia: hoje > c.ultimoDia ? hoje : c.ultimoDia,
    proximoDia: hoje + 1,
    revisoes: c.revisoes + 1,
    lapsos: c.lapsos + 1,
    suspenso: c.suspenso,
  );
}

/// A palavra que a pessoa quer adicionar, limpa (aspas curvas viram retas, sem espaços nas pontas,
/// sem acento), ou o motivo de não servir.
({String en, String? erro}) validarPalavraNova(String bruto, BancoPalavras banco) {
  var s = bruto
      .replaceAll(RegExp('[‘’ʼ`´]'), "'")
      .replaceAll(RegExp('[“”]'), '"')
      .trim()
      .replaceAll(RegExp(r'''^["']+|["']+$'''), '')
      .trim();
  s = _semAcento(s);
  if (s.isEmpty) return (en: s, erro: 'Escreva a palavra em inglês');
  if (!RegExp(r'^[A-Za-z]{2,14}$').hasMatch(s)) {
    return (en: s, erro: 'Use só letras, sem espaço nem acento (até 14)');
  }
  final ja = banco[s];
  if (ja != null && !ja.removida) return (en: s, erro: 'Essa palavra já está no seu banco');
  return (en: s, erro: null);
}

String _semAcento(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
  const para = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = de.indexOf(ch);
    b.write(i >= 0 ? para[i] : ch);
  }
  return b.toString();
}
