import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/som/sons.dart';
import '../../../ranking/presentation/ranking_cubit.dart';

/// Pausa de jogo: manual (Esc ou o botão ⏸) e AUTOMÁTICA quando o app sai
/// da frente (outra aba, ligação, janela sem foco) — ninguém perde pra CPU
/// por ter atendido a campainha. Cada jogo congela seus relógios nos ganchos
/// [aoPausar]/[aoRetomar].
mixin PausaDeJogo<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  bool pausado = false;

  /// Só há o que pausar com partida rodando (não na escolha, no overlay de
  /// fim/fase, nem na contagem regressiva).
  bool get podePausar;

  void aoPausar() {}
  void aoRetomar() {}

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) pausar();
  }

  void pausar() {
    if (pausado || !podePausar || !mounted) return;
    setState(() => pausado = true);
    aoPausar();
  }

  void retomar() {
    if (!pausado || !mounted) return;
    setState(() => pausado = false);
    Sons.toca(Som.blip);
    aoRetomar();
  }

  void alternarPausa() => pausado ? retomar() : pausar();

  /// Começou uma partida enquanto o app estava escondido (largada 3-2-1
  /// terminou com a aba em segundo plano): já nasce pausada.
  void pausarSeEscondido() {
    final estado = WidgetsBinding.instance.lifecycleState;
    if (estado != null && estado != AppLifecycleState.resumed) pausar();
  }

  /// Esc alterna a pausa. Devolve se a tecla foi consumida.
  bool teclaDePausa(KeyEvent e) {
    if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.escape) return false;
    if (pausado) {
      retomar();
      return true;
    }
    if (!podePausar) return false;
    pausar();
    return true;
  }
}

/// Campanha em FASES compartilhada pelos jogos: pontos da fase valem +10%
/// por fase, o total acumula, "fase vencida" abre o overlay, e o fim publica
/// o total no ranking UMA vez (sair no meio publica o parcial no dispose).
mixin CampanhaDeFases<T extends StatefulWidget> on State<T>, PausaDeJogo<T> {
  /// Id do jogo no ranking ('corrida' | 'futebol' | 'cacaBug' | 'rali').
  String get jogoId;

  /// Pontos crus do motor da fase em andamento (0 se nenhuma).
  int get pontosDoMotor;

  /// Há uma fase de verdade rodando (motor vivo, sem contagem/overlay)?
  bool get emPartida;

  RankingCubit? ranking;

  int fase = 1;
  int fasesVencidas = 0;
  int pontosTotal = 0;

  bool faseVencida = false;
  bool acabou = false;
  bool novoRecorde = false;
  bool pontuado = false;

  double get fator => 1 + 0.1 * (fase - 1);
  int comFator(int pontos) => (pontos * fator).round();

  /// Total + o que a fase atual já rendeu (o que iria pro ranking agora).
  int get pontosParciais =>
      pontosTotal + ((faseVencida || acabou) ? 0 : comFator(pontosDoMotor));

  @override
  bool get podePausar => emPartida && !acabou && !faseVencida;

  @override
  void initState() {
    super.initState();
    ranking = RankingCubit.de(context);
  }

  @override
  void dispose() {
    final resto = pontosParciais;
    if (!pontuado && resto > 0) ranking?.arcadeJogado(jogoId, resto);
    super.dispose();
  }

  /// Nova campanha do zero (chame dentro de um setState).
  void zerarCampanha() {
    fase = 1;
    fasesVencidas = 0;
    pontosTotal = 0;
    faseVencida = false;
    acabou = false;
    novoRecorde = false;
    pontuado = false;
    pausado = false;
  }

  /// A fase foi vencida: soma os pontos (com fator) e abre o overlay.
  void registrarFaseVencida() {
    Sons.toca(Som.fase);
    setState(() {
      fasesVencidas++;
      pontosTotal += comFator(pontosDoMotor);
      faseVencida = true;
    });
  }

  /// Fecha o overlay e sobe a fase (o jogo monta a fase nova em seguida).
  void avancarFase() {
    setState(() {
      fase++;
      faseVencida = false;
    });
  }

  /// Fim da campanha: soma (ou não) a fase corrente, publica o total no
  /// ranking e descobre se virou recorde pessoal.
  Future<void> encerrar({bool somaFaseAtual = true}) async {
    if (pontuado) return;
    pontuado = true;
    setState(() {
      if (somaFaseAtual) pontosTotal += comFator(pontosDoMotor);
      faseVencida = false;
      acabou = true;
      pausado = false;
    });
    Sons.toca(fasesVencidas > 0 ? Som.fanfarra : Som.defesa);
    final recorde = await ranking?.arcadeJogado(jogoId, pontosTotal);
    if (mounted && recorde == true) setState(() => novoRecorde = true);
  }
}
