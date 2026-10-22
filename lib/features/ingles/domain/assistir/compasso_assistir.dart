import 'dart:math' as math;

import '../../../arcade/domain/historia_turismo.dart';
import '../../../arcade/domain/simulacao_historia.dart';
import '../../presentation/ouvir/ouvir_state.dart';
import '../config_ouvir.dart';
import '../fila_ouvir.dart';
import 'historia_licao.dart';

/// 📺 O compasso do "Escutar assistindo": as contas puras que ligam o estado do 🎧 Ouvir ao passo da
/// historinha (âncora da faixa, vão final, os mudos que cabem no silêncio, letras pela voz).
///
/// Tudo puro (sem Flutter): o `RoteiroSeguidor` usa, o `assistir_compasso_test` prende (plano §3.3, §3.4, §6.6).

/// O que o palco mostra agora.
enum MomentoAssistir { fala, traducao, pense, vao, vaoFinal, parado }

/// Um trecho de passos mudos para tocar num vão.
class TrechoMudo {
  final HistoriaLicao historia;

  /// (cena, passo), na ordem.
  final List<(int, int)> passos;

  /// Corta para a cena do 1º passo (esmaecer) antes de animar.
  final bool abreCena;

  /// A âncora a que o trecho leva (na abertura: a cena dela; sem mudos, o palco mostra o estado de logo antes
  /// dela). null no "rabo" (os mudos depois da âncora atual).
  final (int, int)? destino;

  const TrechoMudo({required this.historia, required this.passos, this.abreCena = false, this.destino});
}

abstract final class CompassoAssistir {
  static const minimoPorPasso = .35, folgaDoVao = .9, minimoParaAbrir = .6;

  /// Eco (I2): fração do vão em que o balão fica antes dos mudos (.7). Os mudos usam o resto.
  static const fracaoDoEco = .7;

  static MomentoAssistir momento(OuvirState st, {required bool viuTraducao}) {
    if (st.status != StatusOuvir.tocando) return MomentoAssistir.parado;
    switch (st.fase) {
      case FaseOuvir.ouvindo:
        return MomentoAssistir.fala;
      case FaseOuvir.traducao:
        return MomentoAssistir.traducao;
      case FaseOuvir.pense:
        return MomentoAssistir.pense;
      case FaseOuvir.respiro || FaseOuvir.suaVez:
        final f = st.atual;
        return ehVaoFinal(
          fase: st.fase,
          vez: st.vez,
          de: st.de,
          modo: st.config.modo,
          viuTraducao: viuTraducao,
          temPt: f != null && f.pt.trim().isNotEmpty,
        )
            ? MomentoAssistir.vaoFinal
            : MomentoAssistir.vao;
    }
  }

  /// `modoEfetivo = temPt ? modo : soIngles`; vão final = `fase ∈ {respiro, suaVez}` && `vez == de` &&
  /// (`modoEfetivo` ≠ inglês→português ou já houve `traducao` depois da última FalaEn desta faixa).
  static bool ehVaoFinal({
    required FaseOuvir fase,
    required int vez,
    required int de,
    required ModoOuvir modo,
    required bool viuTraducao,
    required bool temPt,
  }) {
    if (fase != FaseOuvir.respiro && fase != FaseOuvir.suaVez) return false;
    if (vez != de) return false;
    final efetivo = temPt ? modo : ModoOuvir.soIngles;
    return efetivo != ModoOuvir.inglesPortugues || viuTraducao;
  }

  /// A âncora da faixa na história (null = a frase não está nela).
  static (int, int)? ancora(HistoriaLicao h, Faixa f) => h.ancoras[f.chave];

  /// O `d` do último `Silencio` de `passosDa` (segundos).
  static double vaoFinal(Faixa f, ConfigOuvir c, {required bool fimDeLicao}) {
    final passos = passosDa(f, c, fimDeLicao: fimDeLicao);
    for (final p in passos.reversed) {
      if (p is Silencio) return p.d.inMilliseconds / 1000;
    }
    return 0;
  }

  /// Os trechos de mudos que tocam no vão (plano §3.4), na ordem:
  /// 1. a próxima faixa está na MESMA história ([identical]) e DEPOIS da âncora atual → os mudos entre as duas
  ///    âncoras; em cenas diferentes, o rabo da cena atual + a abertura da cena nova (`abreCena`) com os mudos
  ///    do começo dela até a próxima âncora;
  /// 2. senão (outra lição, pulo para trás, fim da fila) → o rabo (os mudos logo depois da âncora atual, até a
  ///    próxima âncora ou o fim da cena) e, se sobrar ≥ [minimoParaAbrir] do [vao] (null = tempo à vontade)
  ///    depois do rabo em tempo real, a abertura da próxima história: o estado de logo antes da âncora + os
  ///    mudos colados antes dela.
  ///
  /// Os estados vêm da `linhaDoTempo` (cumulativa): qualquer passo mostrado é coerente. Lista vazia = nada a
  /// animar (o balão fica até a próxima faixa).
  static List<TrechoMudo> planoDoVao({
    required HistoriaLicao atual,
    required (int, int) ancoraAtual,
    HistoriaLicao? proxima,
    (int, int)? ancoraProxima,
    double? vao,
  }) {
    final (c, p) = ancoraAtual;
    if (c < 0 || c >= atual.cenas.length) return const [];
    final falas = atual.cenas[c].falas;
    // o rabo: os mudos colados depois da âncora atual (até a próxima âncora ou o fim da cena)
    final rabo = <(int, int)>[
      for (var k = p + 1; k < falas.length && falas[k].mudo; k++) (c, k),
    ];
    final prox = proxima, ap = ancoraProxima;
    if (prox != null && ap != null && identical(prox, atual) && _depois(ap, ancoraAtual)) {
      final (c2, p2) = ap;
      if (c2 == c) {
        final entre = <(int, int)>[
          for (var k = p + 1; k < p2 && k < falas.length; k++)
            if (falas[k].mudo) (c, k),
        ];
        return entre.isEmpty ? const [] : [TrechoMudo(historia: atual, passos: entre)];
      }
      if (c2 >= atual.cenas.length) return const [];
      final fim = <(int, int)>[
        for (var k = p + 1; k < falas.length; k++)
          if (falas[k].mudo) (c, k),
      ];
      final novas = atual.cenas[c2].falas;
      final comeco = <(int, int)>[
        for (var k = 0; k < p2 && k < novas.length; k++)
          if (novas[k].mudo) (c2, k),
      ];
      return [
        if (fim.isNotEmpty) TrechoMudo(historia: atual, passos: fim),
        TrechoMudo(historia: atual, passos: comeco, abreCena: true, destino: ap),
      ];
    }
    final r = <TrechoMudo>[if (rabo.isNotEmpty) TrechoMudo(historia: atual, passos: rabo)];
    if (prox != null && ap != null && ap.$1 >= 0 && ap.$1 < prox.cenas.length) {
      final tempoDoRabo = rabo.fold(0.0, (s, cp) => s + duracaoMuda(falas[cp.$2]));
      final sobra = vao == null ? double.infinity : vao * folgaDoVao - tempoDoRabo;
      if (sobra >= minimoParaAbrir) {
        final (c2, p2) = ap;
        final novas = prox.cenas[c2].falas;
        var k = p2.clamp(0, novas.length);
        while (k > 0 && novas[k - 1].mudo) {
          k--;
        }
        r.add(TrechoMudo(
          historia: prox,
          passos: [for (var j = k; j < p2 && j < novas.length; j++) (c2, j)],
          abreCena: true,
          destino: ap,
        ));
      }
    }
    return r;
  }

  /// [a] vem depois de [b] na história (cena, passo).
  static bool _depois((int, int) a, (int, int) b) => a.$1 > b.$1 || (a.$1 == b.$1 && a.$2 > b.$2);

  /// A duração de um passo mudo: a conta do `_mudoDe` do Turismo, sem o cartão de título.
  static double duracaoMuda(FalaHistoria f) {
    var d = SimulacaoCena.duracaoDe(f.acao) ?? 1.2;
    for (final r in f.reacoes) {
      final a = r.acao;
      if (a != null) d = math.max(d, SimulacaoCena.duracaoDe(a) ?? 0);
      if (r.efeito != null) d = math.max(d, 1.2);
    }
    if (f.efeito != null) d = math.max(d, 1.2);
    for (final m in f.objetos) {
      d = math.max(d, _duracaoObjeto(m.acao));
    }
    return math.max(.8, d);
  }

  /// O mesmo do `RoteiroHistoria.duracaoObjeto`: `passa` 1.6; `voa` 1.2; os outros .6.
  static double _duracaoObjeto(AcaoObjeto a) => switch (a) {
        AcaoObjeto.passa => 1.6,
        AcaoObjeto.voa => 1.2,
        _ => .6,
      };

  /// soma / (vão × folga); ≤1 tempo real; >1 acelera; infinity = salta para o estado final.
  static double fatorDeTempo(List<double> duracoes, double vao) {
    if (duracoes.isEmpty) return 1;
    final util = vao * folgaDoVao;
    if (!(util > 0) || util / duracoes.length < minimoPorPasso) return double.infinity;
    final soma = duracoes.fold(0.0, (a, d) => a + d);
    return soma / util;
  }

  /// A1 22 · A2 26 · B1/B2 30 (× fator).
  static double letrasPorSegundo(NivelIngles n, double fator) =>
      fator *
      switch (n) {
        NivelIngles.a1 => 22,
        NivelIngles.a2 => 26,
        NivelIngles.b1 || NivelIngles.b2 => 30,
      };

  /// Letras pela voz (I3): len × clamp(segundoDaVoz / (segundosDaFaixa / fator), 0, 1). null = sem dado
  /// da voz (o seguidor cai em letrasPorSegundo depois de 0,6 s sem FalaEmCurso da frase).
  static int? letrasPelaVoz({
    required int total,
    required double? segundoDaVoz,
    required double? segundosDaFaixa,
    required double fator,
  }) {
    final s = segundoDaVoz, d = segundosDaFaixa;
    if (s == null || d == null || !(d > 0) || !(fator > 0)) return null;
    return (total * (s / (d / fator)).clamp(0.0, 1.0)).floor();
  }

  /// As faixas da mesma lição que a faixa [i] na fila: `[inicio, fim)`.
  static ({int inicio, int fim}) licaoDaFaixa(List<Faixa> fila, int i) {
    if (fila.isEmpty) return (inicio: 0, fim: 0);
    final k = i.clamp(0, fila.length - 1);
    var inicio = k;
    while (inicio > 0 && !fila[inicio].primeiraDaLicao) {
      inicio--;
    }
    var fim = k + 1;
    while (fim < fila.length && !fila[fim].primeiraDaLicao) {
      fim++;
    }
    return (inicio: inicio, fim: fim);
  }
}
