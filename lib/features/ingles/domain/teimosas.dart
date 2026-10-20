// "🔥 Palavras teimosas" do PAC·ENGLISH — o MODELO: cada palavra carrega uma "carga de erro" que decai
// (meia-vida de 14 dias). Erro soma, exposição dilui; a palavra vira teimosa quando a pontuação passa de
// 0,8 com carga de verdade (ou com lapsos no cartão). Dois acertos limpos em dias diferentes, depois do
// último erro, a DOMINAM. Aqui também mora a política de quando OFERECER o treino (sem encher o saco).
// Dart puro.
import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'banco_palavras.dart';
import 'erros_palavra.dart';

/// A meia-vida da carga de erro, em dias.
const meiaVidaDias = 14;

/// Quanto sobra de uma carga depois de [dias] (1 com 0 dias; 0,5 com 14).
double fatorDecaimento(int dias) => dias <= 0 ? 1 : math.pow(0.5, dias / meiaVidaDias).toDouble();

/// A carga de erro E de [p] trazida para [hoje].
double cargaEm(PalavraDoBanco p, int hoje) =>
    p.cargaErro == 0 ? 0 : p.cargaErro * fatorDecaimento(hoje - p.cargaDia);

/// As exposições N de [p] trazidas para [hoje].
double vistasEm(PalavraDoBanco p, int hoje) =>
    p.cargaVistas == 0 ? 0 : p.cargaVistas * fatorDecaimento(hoje - p.cargaDia);

/// A taxa de erro suavizada: (E + 0,3) / (N + 2).
double taxaDeErro(PalavraDoBanco p, int hoje, {double extra = 0}) =>
    (cargaEm(p, hoje) + extra + 0.3) / (vistasEm(p, hoje) + 2);

/// A pontuação de teimosia: E·taxa + 0,4 por lapso do cartão (até 5) + 0,5 se o cartão está difícil (≥ 7).
/// [extra]: carga a mais só para mostrar (as palavras das frases sanguessugas), nunca gravada.
double pontuacaoTeimosa(PalavraDoBanco p, int hoje, {double extra = 0}) {
  final e = cargaEm(p, hoje) + extra;
  final c = p.cartao;
  final lapsos = math.min(c?.lapsos ?? 0, 5);
  return e * taxaDeErro(p, hoje, extra: extra) + 0.4 * lapsos + (c != null && c.dificuldade >= 7 ? 0.5 : 0);
}

/// [p] é teimosa em [hoje]? Pontuação ≥ 0,8 e carga de verdade (E ≥ 1,8) ou 2+ lapsos no cartão.
/// DOMINADA e sem erro de verdade desde então: não (os lapsos do cartão nunca descem — sem isso ela
/// continuaria na lista e seria dominada de novo, em ciclo).
bool ehTeimosa(PalavraDoBanco p, int hoje, {double extra = 0}) {
  if (p.removida) return false;
  if (p.dominadaEm > 0 && p.ultimoErroDia <= p.dominadaEm) return false;
  if (pontuacaoTeimosa(p, hoje, extra: extra) < 0.8) return false;
  return cargaEm(p, hoje) + extra >= 1.8 || (p.cartao?.lapsos ?? 0) >= 2;
}

/// O medidor 🔥 (1–3) de uma teimosa pela pontuação.
int chamasDe(PalavraDoBanco p, int hoje) {
  final s = pontuacaoTeimosa(p, hoje);
  if (s >= 3) return 3;
  if (s >= 1.5) return 2;
  return 1;
}

/// Quantas vezes a palavra "te deu trabalho" (o badge "Nx"): os erros de vez (lições, revisões, cartões,
/// treino), os lapsos do cartão (quem já tinha cartão antes das teimosas) ou, nas que só erraram nos
/// jogos, os erros dos jogos; no mínimo 1.
int vezesDe(PalavraDoBanco p) =>
    math.max(math.max(1, p.cartao?.lapsos ?? 0), math.max(p.errosTotal, p.errosJogo));

/// Aplica [evs] (todas da mesma palavra) a [p] em [hoje]: decai a carga até hoje e soma (E += Σ peso·falha,
/// N += Σ peso·vistas). Errou de vez → "errou Nx" (fora dos jogos), último erro = hoje e a sequência zera.
/// Acerto limpo fora dos jogos (que são cópia) → +1 na sequência, no máximo uma vez por dia e só se a
/// palavra pesa (E ≥ 0,5) ou já foi teimosa. Ficou teimosa → marca. DOMINADA: já foi teimosa, 2 acertos
/// limpos em dias diferentes depois do último erro → dominada hoje, a carga cai a 30% e a marca sai.
/// Devolve a palavra nova e se foi dominada agora.
(PalavraDoBanco, bool) aplicarEvidencias(PalavraDoBanco p, Iterable<EvidenciaPalavra> evs, int hoje) {
  final lista = evs.toList();
  if (lista.isEmpty) return (p, false);
  final k = p.cargaDia == 0 ? 1.0 : fatorDecaimento(hoje - p.cargaDia);
  var e = p.cargaErro * k;
  var n = p.cargaVistas * k;
  var el = p.errosTotal, ue = p.ultimoErroDia, ok = p.acertosSeguidos, od = p.ultimoAcertoDia;
  var errou = false, limpa = false;
  for (final ev in lista) {
    final f = ev.falha.clamp(0.0, 1.0);
    final w = ev.peso < 0 ? 0.0 : ev.peso;
    e += w * f;
    n += w * (ev.vistas < 0 ? 0 : ev.vistas);
    if (f >= 1) {
      errou = true;
      if (!ev.fonte.deJogo) el++;
    } else if (f <= 0 && !ev.fonte.deJogo) {
      limpa = true;
    }
  }
  if (errou) {
    ue = hoje;
    ok = 0;
  }
  var r = p.copyWith(
    cargaErro: e,
    cargaVistas: n,
    cargaDia: hoje > p.cargaDia ? hoje : p.cargaDia,
    errosTotal: el,
    ultimoErroDia: ue,
    acertosSeguidos: ok,
    ultimoAcertoDia: od,
  );
  final creditou = !errou && limpa && od < hoje && (e >= 0.5 || p.foiTeimosa);
  if (creditou) r = r.copyWith(acertosSeguidos: ok + 1, ultimoAcertoDia: hoje);
  if (!r.foiTeimosa && ehTeimosa(r, hoje)) r = r.copyWith(foiTeimosa: true);
  // só um acerto de verdade (agora) domina: um jogo nunca "termina" a teimosa
  if (creditou && r.foiTeimosa && r.acertosSeguidos >= 2 && r.ultimoAcertoDia > r.ultimoErroDia) {
    r = r.copyWith(dominadaEm: hoje, foiTeimosa: false, acertosSeguidos: 0, cargaErro: r.cargaErro * 0.3);
    return (r, true);
  }
  return (r, false);
}

/// As teimosas do banco em [hoje] (no máximo [max]): sem as adiadas ("Já sei essa", treinadas hoje), da
/// mais teimosa para a menos (empate: a errada por último, depois a ordem alfabética). [extras]: chaves
/// que ganham +1 de carga só nesta conta (as palavras das frases sanguessugas) — nunca gravado.
List<PalavraDoBanco> palavrasTeimosas(BancoPalavras banco, int hoje, {int max = 8, Iterable<String> extras = const []}) {
  final mais = {for (final x in extras) x.toLowerCase()};
  final r = <(PalavraDoBanco, double)>[];
  for (final p in banco.ativas) {
    if (p.naoSugerirAte > hoje) continue;
    final extra = mais.contains(p.chave) ? 1.0 : 0.0;
    if (!ehTeimosa(p, hoje, extra: extra)) continue;
    r.add((p, pontuacaoTeimosa(p, hoje, extra: extra)));
  }
  r.sort((a, b) {
    final s = b.$2.compareTo(a.$2);
    if (s != 0) return s;
    final u = b.$1.ultimoErroDia.compareTo(a.$1.ultimoErroDia);
    return u != 0 ? u : a.$1.chave.compareTo(b.$1.chave);
  });
  return [for (final x in r.take(max)) x.$1];
}

// ---------- quando oferecer ----------

/// Onde o app pode oferecer "treinar só elas".
enum LocalSugestao { fimDeLicao, entreFases, fimDeJogo, fimDeRevisao }

/// O histórico das ofertas (guardado no banco, chave 's'): quando foi a última (ms e dia), quantas hoje,
/// até que dia ficou adiada e quantos "Agora não" seguidos.
class EstadoSugestao extends Equatable {
  final int ultimaMs;
  final int ultimaDia;
  final int mostradasHoje;
  final int adiadaAteDia;
  final int recusasSeguidas;

  const EstadoSugestao({
    this.ultimaMs = 0,
    this.ultimaDia = 0,
    this.mostradasHoje = 0,
    this.adiadaAteDia = 0,
    this.recusasSeguidas = 0,
  });

  static const vazio = EstadoSugestao();

  /// Intervalo mínimo entre duas ofertas (menos no fim de uma revisão).
  static const intervaloMs = 20 * 60 * 1000;

  /// No máximo quantas ofertas por dia.
  static const maxPorDia = 3;

  Map<String, dynamic> toJson() => {
        if (ultimaMs != 0) 'm': ultimaMs,
        if (ultimaDia != 0) 'd': ultimaDia,
        if (mostradasHoje != 0) 'n': mostradasHoje,
        if (adiadaAteDia != 0) 'a': adiadaAteDia,
        if (recusasSeguidas != 0) 'r': recusasSeguidas,
      };

  static EstadoSugestao fromJson(Object? bruto) {
    if (bruto is! Map) return vazio;
    // nada de `1 << 53`: no web (dart2js) um shift de 32+ dá 0 e zeraria tudo — só os negativos viram 0
    int i(Object? v) {
      final n = v is int ? v : (v is num && v.isFinite ? v.toInt() : int.tryParse('$v') ?? 0);
      return n < 0 ? 0 : n;
    }
    return EstadoSugestao(
      ultimaMs: i(bruto['m']),
      ultimaDia: i(bruto['d']),
      mostradasHoje: i(bruto['n']),
      adiadaAteDia: i(bruto['a']),
      recusasSeguidas: i(bruto['r']),
    );
  }

  EstadoSugestao copyWith({int? ultimaMs, int? ultimaDia, int? mostradasHoje, int? adiadaAteDia, int? recusasSeguidas}) =>
      EstadoSugestao(
        ultimaMs: ultimaMs ?? this.ultimaMs,
        ultimaDia: ultimaDia ?? this.ultimaDia,
        mostradasHoje: mostradasHoje ?? this.mostradasHoje,
        adiadaAteDia: adiadaAteDia ?? this.adiadaAteDia,
        recusasSeguidas: recusasSeguidas ?? this.recusasSeguidas,
      );

  @override
  List<Object?> get props => [ultimaMs, ultimaDia, mostradasHoje, adiadaAteDia, recusasSeguidas];
}

/// Pode oferecer agora? Não se adiada até depois de hoje, se já ofereceu 3 vezes hoje, ou se a última foi
/// há menos de 20 minutos (o fim de uma revisão escapa dessa última regra).
bool podeOferecer(EstadoSugestao e, int hoje, int agoraMs, LocalSugestao local) {
  if (hoje < e.adiadaAteDia) return false;
  if (e.ultimaDia == hoje && e.mostradasHoje >= EstadoSugestao.maxPorDia) return false;
  if (local != LocalSugestao.fimDeRevisao && e.ultimaMs != 0 && agoraMs - e.ultimaMs < EstadoSugestao.intervaloMs) {
    return false;
  }
  return true;
}

/// A oferta apareceu (fechar com Enter/Continuar NÃO é recusa: só conta como mostrada).
EstadoSugestao sugestaoMostrada(EstadoSugestao e, int hoje, int agoraMs) => e.copyWith(
      ultimaMs: agoraMs,
      ultimaDia: hoje,
      mostradasHoje: e.ultimaDia == hoje ? e.mostradasHoje + 1 : 1,
    );

/// "Agora não": volta amanhã; no 3º seguido, só daqui a 3 dias.
EstadoSugestao sugestaoAdiada(EstadoSugestao e, int hoje) {
  final r = e.recusasSeguidas + 1;
  return e.copyWith(recusasSeguidas: r, adiadaAteDia: hoje + (r >= 3 ? 3 : 1));
}

/// Aceitou (treinar, jogar ou virar lição): as recusas zeram.
EstadoSugestao sugestaoAceita(EstadoSugestao e) => e.copyWith(recusasSeguidas: 0);

/// Uma oferta: as palavras (chaves, as da sessão primeiro), quantas vezes cada uma deu trabalho e se a
/// oferta é desta sessão ("Essas palavras te deram trabalho") ou das teimosas de sempre ("Você errou
/// muitas vezes"). [formas] e [traducoes] (chave → como se escreve / tradução curta) vêm do cubit.
class SugestaoTeimosas extends Equatable {
  final List<String> palavras;
  final Map<String, int> vezes;
  final bool daSessao;
  final Map<String, String> formas;
  final Map<String, String> traducoes;

  const SugestaoTeimosas({
    required this.palavras,
    this.vezes = const {},
    this.daSessao = true,
    this.formas = const {},
    this.traducoes = const {},
  });

  /// Pronto para o [CartaoTeimosas]: (como se escreve, tradução, vezes).
  List<(String, String, int)> get itens => [
        for (final k in palavras) (formas[k] ?? k, traducoes[k] ?? '', vezes[k] ?? 1),
      ];

  SugestaoTeimosas comTextos({Map<String, String>? formas, Map<String, String>? traducoes}) => SugestaoTeimosas(
        palavras: palavras,
        vezes: vezes,
        daSessao: daSessao,
        formas: formas ?? this.formas,
        traducoes: traducoes ?? this.traducoes,
      );

  @override
  List<Object?> get props => [palavras, vezes, daSessao, formas, traducoes];
}

/// A soma de falha que faz uma palavra "da sessão" contar para a oferta.
const somaDaSessao = 1.5;

/// Monta a oferta (ou null, abaixo do mínimo). Mínimo: 2+ palavras DESTA sessão com soma de falha ≥ 1,5;
/// ou 3+ teimosas de sempre e pelo menos um erro de verdade nesta sessão (soma ≥ 1). Palavras: as da
/// sessão (soma ≥ 1, da maior soma para a menor), depois as [globais], no máximo [max].
SugestaoTeimosas? montarSugestao({
  required Map<String, double> daSessao,
  required List<PalavraDoBanco> globais,
  int max = 8,
}) {
  final fortes = [for (final e in daSessao.entries) if (e.value >= somaDaSessao) e.key];
  final algumErro = daSessao.values.any((v) => v >= 1);
  final regraSessao = fortes.length >= 2;
  final regraGlobal = globais.length >= 3 && algumErro;
  if (!regraSessao && !regraGlobal) return null;
  final daSessaoOrdenadas = [for (final e in daSessao.entries) if (e.value >= 1) e]
    ..sort((a, b) {
      final s = b.value.compareTo(a.value);
      return s != 0 ? s : a.key.compareTo(b.key);
    });
  final porChave = {for (final p in globais) p.chave: p};
  final palavras = <String>[];
  final vezes = <String, int>{};
  for (final e in daSessaoOrdenadas) {
    if (palavras.length >= max) break;
    final k = e.key.toLowerCase();
    if (palavras.contains(k)) continue;
    palavras.add(k);
    final p = porChave[k];
    vezes[k] = math.max(e.value.round(), p == null ? 1 : vezesDe(p));
  }
  for (final p in globais) {
    if (palavras.length >= max) break;
    if (palavras.contains(p.chave)) continue;
    palavras.add(p.chave);
    vezes[p.chave] = vezesDe(p);
  }
  if (palavras.isEmpty) return null;
  return SugestaoTeimosas(
    palavras: palavras,
    vezes: vezes,
    daSessao: regraSessao,
    formas: {for (final p in globais) p.chave: p.en},
    traducoes: {for (final p in globais) if (p.pt.isNotEmpty) p.chave: p.pt},
  );
}
