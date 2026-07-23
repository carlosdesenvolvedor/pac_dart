import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/corrida_engine.dart';
import '../domain/dicas_dart.dart';
import '../domain/digitar_palavra.dart';
import '../domain/palavras_dart.dart';
import '../domain/personagem.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/campo_teclas.dart';

/// 🏁 Rali de Digitação — campanha em FASES: cada palavra digitada faz seu
/// personagem andar (perfeita = turbo, anda 2). Venceu a corrida? Fase nova,
/// cenário novo, CPU mais rápida — e os pontos vão ACUMULANDO até a CPU te
/// pegar (ou você parar e guardar o que juntou).
class RaliPage extends StatefulWidget {
  /// Semente do sorteio (fixa nos testes; null = aleatório de verdade).
  final int? semente;
  const RaliPage({super.key, this.semente});

  @override
  State<RaliPage> createState() => _RaliPageState();
}

class _RaliPageState extends State<RaliPage> {
  RankingCubit? _ranking;

  Dificuldade? _dificuldade;
  CorridaEngine? _engine;
  late math.Random _rnd;
  List<String> _fila = const [];
  int _idx = 0;
  final _palavra = ProgressoPalavra();

  int _fase = 1;
  int _fasesVencidas = 0;
  int _pontosTotal = 0;
  int _palavrasRun = 0;
  int _turbosRun = 0;

  int _errosTeclas = 0;
  int _charsCertos = 0;
  DateTime? _inicio;
  bool _ultimoErrou = false;
  String _feedback = '';

  Timer? _cpuTimer;
  Timer? _relogio; // só pro PPM respirar

  bool _faseVencida = false;
  bool _acabou = false;
  bool _novoRecorde = false;
  bool _pontuado = false;

  @override
  void initState() {
    super.initState();
    _ranking = RankingCubit.de(context);
    PersonagemStore.carregar().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cpuTimer?.cancel();
    _relogio?.cancel();
    // saiu no meio da campanha: os pontos juntados não se perdem
    final resto = _pontosParciais();
    if (!_pontuado && resto > 0) _ranking?.arcadeJogado('rali', resto);
    super.dispose();
  }

  // ---------- campanha ----------

  double get _fator => 1 + 0.1 * (_fase - 1);

  Duration _intervaloCpu() {
    final base = _dificuldade!.intervaloCpu.inMilliseconds;
    final ms = (base * math.pow(0.92, _fase - 1)).round();
    return Duration(milliseconds: math.max(1800, ms));
  }

  int _pontosParciais() {
    final e = _engine;
    final parcial =
        (e != null && !_faseVencida && !_acabou) ? (e.pontos * _fator).round() : 0;
    return _pontosTotal + parcial;
  }

  void _comecarRun(Dificuldade d) {
    setState(() {
      _dificuldade = d;
      _rnd = math.Random(widget.semente);
      _fase = 1;
      _fasesVencidas = 0;
      _pontosTotal = 0;
      _palavrasRun = 0;
      _turbosRun = 0;
      _errosTeclas = 0;
      _charsCertos = 0;
      _inicio = DateTime.now();
      _acabou = false;
      _novoRecorde = false;
      _pontuado = false;
    });
    _comecarFase();
  }

  void _comecarFase() {
    _cpuTimer?.cancel();
    _relogio?.cancel();
    setState(() {
      _engine = CorridaEngine(pista: 12, dificuldade: _dificuldade!);
      // fase 3 em diante entram as palavras compridas (StatelessWidget…)
      _fila = baralhoRali(_rnd, comLongas: _fase >= 3);
      _idx = 0;
      _palavra.carregar(_fila[0]);
      _ultimoErrou = false;
      _feedback = '';
      _faseVencida = false;
    });
    _cpuTimer = Timer.periodic(_intervaloCpu(), (_) => _tickCpu());
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_acabou && !_faseVencida) setState(() {});
    });
  }

  void _tickCpu() {
    final e = _engine;
    if (e == null || _acabou || _faseVencida) return;
    setState(e.tickCpu);
    if (e.terminou) _fimDeJogo();
  }

  void _venceuFase() {
    Sons.toca(Som.fase);
    final e = _engine!;
    _cpuTimer?.cancel();
    _relogio?.cancel();
    setState(() {
      _fasesVencidas++;
      _pontosTotal += (e.pontos * _fator).round();
      _palavrasRun += e.acertos;
      _turbosRun += e.turbos;
      _faseVencida = true;
    });
  }

  void _proximaFase() {
    setState(() => _fase++);
    _comecarFase();
  }

  Future<void> _fimDeJogo({bool somaFaseAtual = true}) async {
    if (_pontuado) return;
    _pontuado = true;
    _cpuTimer?.cancel();
    _relogio?.cancel();
    final e = _engine!;
    setState(() {
      if (somaFaseAtual) {
        _pontosTotal += (e.pontos * _fator).round();
        _palavrasRun += e.acertos;
        _turbosRun += e.turbos;
      }
      _faseVencida = false;
      _acabou = true;
    });
    Sons.toca(_fasesVencidas > 0 ? Som.fanfarra : Som.defesa);
    final recorde = await _ranking?.arcadeJogado('rali', _pontosTotal);
    if (mounted && recorde == true) setState(() => _novoRecorde = true);
  }

  int get _ppm {
    final ini = _inicio;
    if (ini == null) return 0;
    final min = DateTime.now().difference(ini).inMilliseconds / 60000.0;
    if (min <= 0) return 0;
    return (_charsCertos / 5 / min).round();
  }

  void _tecla(String ch) {
    final e = _engine;
    if (e == null || _acabou || _faseVencida || ch.trim().isEmpty) return;
    final certa = _palavra.teclar(ch);
    if (!certa) {
      Sons.toca(Som.erro);
      setState(() {
        _errosTeclas++;
        _ultimoErrou = true;
      });
      return;
    }
    setState(() {
      _charsCertos++;
      _ultimoErrou = false;
      if (_feedback.isNotEmpty && _palavra.idx == 1) _feedback = '';
      if (_palavra.completa) {
        final perfeita = _palavra.errosPalavra == 0;
        e.responder(certa: true, turbo: perfeita);
        Sons.toca(perfeita ? Som.turbo : Som.blip);
        _feedback = perfeita ? '🔥 Palavra perfeita — TURBO!' : '⚡ Acelerou!';
        _idx++;
        _palavra.carregar(_fila[_idx % _fila.length]);
      }
    });
    if (e.terminou) {
      e.venceu ? _venceuFase() : _fimDeJogo();
    }
  }

  // ---------- telas ----------

  @override
  Widget build(BuildContext context) {
    final e = _engine;
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Stack(children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  CabecalhoJogo(
                    rotulo: 'ARCADE · DIGITAÇÃO',
                    titulo: '🏁 Rali de Digitação',
                    chips: e == null
                        ? const []
                        : [
                            ChipPlacar('FASE', '$_fase'),
                            ChipPlacar('TOTAL', '${_pontosParciais()}', cor: Mixart.brand),
                            ChipPlacar('PPM', '$_ppm'),
                            ChipPlacar('ERROS', '$_errosTeclas',
                                cor: _ultimoErrou ? Mixart.danger : null),
                          ],
                  ),
                  const SizedBox(height: 16),
                  if (e == null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Mixart.brandSub,
                        border: Border.all(color: Mixart.brandDim),
                        borderRadius: BorderRadius.circular(Mixart.radiusMd),
                      ),
                      child: Text(
                        'Digite a palavra para ACELERAR: palavra completa é um passo, '
                        'sem nenhum erro é TURBO (anda 2). Venceu? Vem outra fase com '
                        'cenário novo e CPU mais rápida — e os pontos vão somando até '
                        'a CPU te pegar. Palavras compridas entram na fase 3!',
                        style: Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SeletorDificuldade(onEscolher: _comecarRun),
                  ] else ...[
                    PistaPro(
                        posJogador: e.posJogador,
                        posCpu: e.posCpu,
                        pista: e.pista,
                        fase: _fase),
                    const SizedBox(height: 18),
                    _cartaoPalavra(),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 26,
                      child: Text(
                        _feedback.isNotEmpty
                            ? _feedback
                            : '⌨️ é só digitar — errou, a letra não anda (e conta erro)',
                        style: _feedback.isNotEmpty
                            ? Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)
                            : Mixart.ui(size: 11.5, color: Mixart.textFaint),
                      ),
                    ),
                    CampoTeclas(onChar: _tecla),
                  ],
                ],
              ),
              if (_faseVencida)
                FaseVencida(
                  fase: _fase,
                  pontosFase: (_engine!.pontos * _fator).round(),
                  pontosTotal: _pontosTotal,
                  dica: dicaDaFase(_fase),
                  aviso: _fase + 1 == 3
                      ? 'a CPU acelera e entram as palavras COMPRIDAS!'
                      : 'a CPU fica ainda mais rápida!',
                  onProxima: _proximaFase,
                  onParar: () => _fimDeJogo(somaFaseAtual: false),
                ),
              if (_acabou && e != null)
                FimDeJogo(
                  emoji: _fasesVencidas > 0 ? '🏆' : '🤖',
                  titulo: _fasesVencidas > 0 ? 'FIM DA CAMPANHA!' : 'A CPU VENCEU…',
                  subtitulo: _fasesVencidas > 0
                      ? 'Você venceu $_fasesVencidas fase${_fasesVencidas > 1 ? 's' : ''} e digitou $_palavrasRun palavras.'
                      : 'Palavra perfeita dá TURBO — capriche e tente de novo!',
                  pontos: _pontosTotal,
                  novoRecorde: _novoRecorde,
                    celebrar: _fasesVencidas > 0,
                  stats: [
                    ('FASES', '$_fasesVencidas'),
                    ('PALAVRAS', '$_palavrasRun'),
                    ('TURBOS', '$_turbosRun'),
                    ('PPM', '$_ppm'),
                    ('ERROS', '$_errosTeclas'),
                  ],
                  onDeNovo: () => _comecarRun(e.dificuldade),
                  onSair: () => Navigator.of(context).pop(),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _cartaoPalavra() {
    final alvo = _palavra.alvo;
    final idx = _palavra.idx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(
            color: _ultimoErrou ? Mixart.danger : Mixart.border, width: _ultimoErrou ? 1.6 : 1),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(children: [
        Text('PALAVRA ${_idx + 1}',
            style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.textFaint)
                .copyWith(letterSpacing: 2)),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: alvo.substring(0, idx),
              style: TextStyle(color: Mixart.brand, fontWeight: FontWeight.w700),
            ),
            if (idx < alvo.length)
              TextSpan(
                text: alvo[idx],
                style: TextStyle(
                  color: _ultimoErrou ? Colors.white : Mixart.text,
                  backgroundColor: _ultimoErrou ? Mixart.danger : Mixart.brandSub,
                ),
              ),
            if (idx + 1 < alvo.length)
              TextSpan(text: alvo.substring(idx + 1), style: TextStyle(color: Mixart.textMuted)),
          ]),
          style: Mixart.mono(size: 30).copyWith(letterSpacing: 1.5, height: 1.2),
        ),
      ]),
    );
  }
}
