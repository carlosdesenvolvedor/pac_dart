import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/banco_desafios.dart';
import '../domain/caca_bug_engine.dart';
import '../domain/desafio.dart';
import '../domain/dicas_dart.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/cenario.dart';

/// 🐞 Caça-Bug — campanha em FASES de 8 rodadas: ache a linha defeituosa
/// antes de o relógio zerar. 5+ bugs caçados avançam de fase — o cenário
/// muda e o relógio fica 10% mais apressado. Pontos acumulam.
class CacaBugPage extends StatefulWidget {
  /// Semente do sorteio (fixa nos testes; null = aleatório de verdade).
  final int? semente;
  const CacaBugPage({super.key, this.semente});

  @override
  State<CacaBugPage> createState() => _CacaBugPageState();
}

class _CacaBugPageState extends State<CacaBugPage> {
  static const _rodadas = 8;
  static const _paraPassar = 5;

  RankingCubit? _ranking;
  late math.Random _rnd;
  late CacaBugEngine _engine;
  late DesafioBug _bug;
  int _numRodada = 1;
  int _tempoTotal = 14;
  int _restante = 14;

  int _fase = 1;
  int _fasesVencidas = 0;
  int _pontosTotal = 0;
  int _acertosRun = 0;

  bool _revelado = false;
  bool _acertou = false;
  int? _linhaEscolhida;
  int _ganho = 0;

  Timer? _relogio;
  Timer? _avanco;

  bool _faseVencida = false;
  bool _acabou = false;
  bool _novoRecorde = false;
  bool _pontuado = false;

  double get _fator => 1 + 0.1 * (_fase - 1);

  @override
  void initState() {
    super.initState();
    _ranking = RankingCubit.de(context);
    _comecarRun();
  }

  @override
  void dispose() {
    _relogio?.cancel();
    _avanco?.cancel();
    final resto = _pontosParciais();
    if (!_pontuado && resto > 0) _ranking?.arcadeJogado('cacaBug', resto);
    super.dispose();
  }

  int _pontosParciais() {
    final parcial =
        (!_faseVencida && !_acabou) ? (_engine.pontos * _fator).round() : 0;
    return _pontosTotal + parcial;
  }

  // ---------- campanha ----------

  void _comecarRun() {
    _rnd = math.Random(widget.semente);
    setState(() {
      _fase = 1;
      _fasesVencidas = 0;
      _pontosTotal = 0;
      _acertosRun = 0;
      _acabou = false;
      _novoRecorde = false;
      _pontuado = false;
    });
    _comecarFase();
  }

  void _comecarFase() {
    _relogio?.cancel();
    _avanco?.cancel();
    _engine = CacaBugEngine(
        rodadas: sortearBugs(quantidade: _rodadas, rnd: _rnd, banco: bancoBugs));
    setState(() {
      _faseVencida = false;
      _carregaRodada(1);
    });
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _venceuFase() {
    Sons.toca(Som.fase);
    _relogio?.cancel();
    _avanco?.cancel();
    setState(() {
      _fasesVencidas++;
      _pontosTotal += (_engine.pontos * _fator).round();
      _acertosRun += _engine.acertos;
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
    _relogio?.cancel();
    _avanco?.cancel();
    setState(() {
      if (somaFaseAtual) {
        _pontosTotal += (_engine.pontos * _fator).round();
        _acertosRun += _engine.acertos;
      }
      _faseVencida = false;
      _acabou = true;
    });
    Sons.toca(_fasesVencidas > 0 ? Som.fanfarra : Som.defesa);
    final recorde = await _ranking?.arcadeJogado('cacaBug', _pontosTotal);
    if (mounted && recorde == true) setState(() => _novoRecorde = true);
  }

  // ---------- rodadas ----------

  /// Lê a rodada ATUAL do engine para o estado da tela (o relógio aperta
  /// 10% por fase).
  void _carregaRodada(int numero) {
    _bug = _engine.atual;
    _numRodada = numero;
    _tempoTotal = (_engine.tempoRodada.inSeconds * math.pow(0.9, _fase - 1))
        .round()
        .clamp(4, 20);
    _restante = _tempoTotal;
    _revelado = false;
    _acertou = false;
    _linhaEscolhida = null;
    _ganho = 0;
  }

  void _tick() {
    if (_revelado || _acabou || _faseVencida) return;
    setState(() => _restante--);
    if (_restante > 0) return;
    // relógio zerou: o bug escapou
    Sons.toca(Som.erro);
    setState(() {
      _engine.estourouTempo();
      _revelado = true;
      _acertou = false;
      _linhaEscolhida = null;
    });
    _agendaProxima(const Duration(milliseconds: 2600));
  }

  void _escolher(int linha) {
    if (_revelado || _acabou || _faseVencida) return;
    final sobra = _restante;
    setState(() {
      _acertou = _engine.escolher(linha, sobra);
      _ganho = _acertou ? 10 + sobra : 0;
      _linhaEscolhida = linha;
      _revelado = true;
    });
    Sons.toca(_acertou ? Som.blip : Som.erro);
    _agendaProxima(Duration(milliseconds: _acertou ? 1400 : 2600));
  }

  void _agendaProxima(Duration espera) {
    _avanco = Timer(espera, () {
      if (_engine.terminou) {
        _engine.acertos >= _paraPassar ? _venceuFase() : _fimDeJogo();
      } else {
        setState(() => _carregaRodada(_numRodada + 1));
      }
    });
  }

  KeyEventResult _tecla(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    const teclas = [
      [LogicalKeyboardKey.digit1, LogicalKeyboardKey.numpad1],
      [LogicalKeyboardKey.digit2, LogicalKeyboardKey.numpad2],
      [LogicalKeyboardKey.digit3, LogicalKeyboardKey.numpad3],
      [LogicalKeyboardKey.digit4, LogicalKeyboardKey.numpad4],
      [LogicalKeyboardKey.digit5, LogicalKeyboardKey.numpad5],
      [LogicalKeyboardKey.digit6, LogicalKeyboardKey.numpad6],
    ];
    for (var i = 0; i < teclas.length && i < _bug.linhas.length; i++) {
      if (teclas[i].contains(e.logicalKey)) {
        _escolher(i);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: Focus(
        autofocus: true,
        onKeyEvent: _tecla,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Stack(children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    CabecalhoJogo(
                      rotulo: 'ARCADE · ATENÇÃO',
                      titulo: '🐞 Caça-Bug',
                      chips: [
                        ChipPlacar('FASE', '$_fase'),
                        ChipPlacar('RODADA', '$_numRodada/$_rodadas'),
                        ChipPlacar('CAÇADOS', '${_engine.acertos}'),
                        ChipPlacar('TOTAL', '${_pontosParciais()}', cor: Mixart.brand),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _faixaCenario(),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Mixart.brandSub,
                        border: Border.all(color: Mixart.brandDim),
                        borderRadius: BorderRadius.circular(Mixart.radiusMd),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('🎯', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Missão: ${_bug.missao}.\nUma linha estraga tudo — clique nela! '
                            '(cace $_paraPassar+ bugs pra avançar de fase)',
                            style: Mixart.ui(size: 13.5, weight: FontWeight.w600)
                                .copyWith(height: 1.5),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    _relogioBarra(),
                    const SizedBox(height: 14),
                    _codigo(),
                    const SizedBox(height: 12),
                    SizedBox(height: 58, child: _veredito()),
                  ],
                ),
                if (_faseVencida)
                  FaseVencida(
                    fase: _fase,
                    pontosFase: (_engine.pontos * _fator).round(),
                    pontosTotal: _pontosTotal,
                    dica: dicaDaFase(_fase),
                    aviso: 'o relógio fica 10% mais apressado — olho vivo!',
                    onProxima: _proximaFase,
                    onParar: () => _fimDeJogo(somaFaseAtual: false),
                  ),
                if (_acabou)
                  FimDeJogo(
                    emoji: _fasesVencidas > 0 ? '🏆' : '🐞',
                    titulo: _fasesVencidas > 0 ? 'FIM DA CAMPANHA!' : 'OS BUGS ESCAPARAM…',
                    subtitulo:
                        'Você esmagou $_acertosRun bugs — cace $_paraPassar+ por fase pra seguir viagem.',
                    pontos: _pontosTotal,
                    novoRecorde: _novoRecorde,
                    celebrar: _fasesVencidas > 0,
                    stats: [
                      ('FASES', '$_fasesVencidas'),
                      ('CAÇADOS', '$_acertosRun'),
                    ],
                    onDeNovo: _comecarRun,
                    onSair: () => Navigator.of(context).pop(),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- pedaços ----------

  /// Faixa fina de cenário: mostra o mundo da fase atual.
  Widget _faixaCenario() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Mixart.radiusMd),
      child: SizedBox(
        height: 74,
        child: Stack(children: [
          Positioned.fill(child: CenarioFase(fase: _fase)),
          Positioned.fill(child: Container(color: const Color(0x2906070B))),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xCC10131A),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${emojiDaFase(_fase)} FASE $_fase · ${nomeDaFase(_fase)}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _relogioBarra() {
    final urgente = _restante <= 3;
    return Row(children: [
      Icon(Icons.timer_outlined, size: 15, color: urgente ? Mixart.danger : Mixart.textMuted),
      const SizedBox(width: 8),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (_restante / _tempoTotal).clamp(0, 1),
            minHeight: 7,
            backgroundColor: Mixart.surfaceHi,
            color: urgente ? Mixart.danger : Mixart.brand,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text('${_restante.clamp(0, 99)}s',
          style: Mixart.mono(size: 12, color: urgente ? Mixart.danger : Mixart.textMuted)),
    ]);
  }

  Widget _codigo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Mixart.bg,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(children: [
        for (var i = 0; i < _bug.linhas.length; i++) _linha(i),
      ]),
    );
  }

  Widget _linha(int i) {
    final ehBug = i == _bug.linhaComBug;
    final escolhidaErrada = _revelado && _linhaEscolhida == i && !ehBug;

    Color? fundo;
    Color borda = Colors.transparent;
    if (_revelado && ehBug) {
      fundo = _acertou ? Mixart.brandSub : const Color(0x22F2555A);
      borda = _acertou ? Mixart.brand : Mixart.danger;
    } else if (escolhidaErrada) {
      borda = Mixart.danger;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: fundo ?? Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _revelado ? null : () => _escolher(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(color: borda),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              SizedBox(
                width: 26,
                child: Text('${i + 1}',
                    style: Mixart.mono(size: 11.5, color: Mixart.textFaint)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: CodigoRealcado(_bug.linhas[i], tamanho: 13.5),
                ),
              ),
              if (_revelado && ehBug)
                Text(_acertou ? '🐞 +$_ganho pts' : '🐞 era aqui',
                    style: Mixart.ui(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: _acertou ? Mixart.brand : Mixart.danger)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _veredito() {
    if (!_revelado) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('⌨️ os números 1–${_bug.linhas.length} escolhem a linha',
            style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
      );
    }
    final titulo = _acertou
        ? '🎉 Bug esmagado!'
        : (_linhaEscolhida == null ? '⏱ O bug escapou pelo relógio!' : '❌ Essa linha estava sã.');
    return Align(
      alignment: Alignment.topLeft,
      child: Text('$titulo ${_bug.explica}',
          style: Mixart.ui(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: _acertou ? Mixart.brand : Mixart.danger)
              .copyWith(height: 1.4),
          maxLines: 3,
          overflow: TextOverflow.ellipsis),
    );
  }
}
