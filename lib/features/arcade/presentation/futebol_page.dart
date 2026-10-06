import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import 'banco_arcade.dart';
import '../domain/baralho.dart';
import '../domain/desafio.dart';
import '../domain/dicas_dart.dart';
import '../domain/futebol_engine.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/campanha.dart';
import 'widgets/cenario.dart';
import 'widgets/gol3d.dart';

/// ⚽ Gol de Dart — campanha em FASES: séries de 5 pênaltis de SINTAXE.
/// Cada opção é um canto do gol; 3+ gols na série avançam de fase — o
/// estádio muda de clima, os desafios sobem de nível e o relógio do chute
/// aperta. A bola voa em arco, a defesa sacode a trave, Esc pausa.
class FutebolPage extends StatefulWidget {
  /// Semente do sorteio (fixa nos testes; null = aleatório de verdade).
  final int? semente;
  const FutebolPage({super.key, this.semente});

  @override
  State<FutebolPage> createState() => _FutebolPageState();
}

class _FutebolPageState extends State<FutebolPage>
    with WidgetsBindingObserver, PausaDeJogo<FutebolPage>, CampanhaDeFases<FutebolPage> {
  static const _cantos = ['CANTO ESQUERDO', 'MEIO DO GOL', 'CANTO DIREITO'];

  late math.Random _rnd;
  late BaralhoDesafios _baralho;
  late FutebolEngine _engine;
  late List<Desafio> _fila;
  int _idx = 0;

  int _golsRun = 0;
  int _defesasRun = 0;

  final List<Chute> _historico = [];
  bool _revelado = false;
  int? _zonaBola; // null durante a espera (ou no estouro do relógio)
  int _zonaGoleiro = 1;
  bool _estourou = false;

  /// Sacode a trave a cada defesa.
  int _tremor = 0;

  int _restante = 20;
  Timer? _relogio;
  Timer? _avanco;

  Desafio get _desafio => _fila[_idx];

  /// O relógio do chute aperta a cada fase (20s → … → 8s).
  int get _tempoDoChute => (20 - 2 * (fase - 1)).clamp(8, 20);

  @override
  String get jogoId => 'futebol';

  @override
  int get pontosDoMotor => _engine.pontos;

  /// Pausa vale a qualquer momento da série (até na espera entre chutes —
  /// o relógio só volta a contar quando o jogador voltar).
  @override
  bool get emPartida => true;

  @override
  void initState() {
    super.initState();
    _comecarRun();
  }

  @override
  void dispose() {
    _relogio?.cancel();
    _avanco?.cancel();
    super.dispose();
  }

  // ---------- campanha ----------

  void _comecarRun() {
    _rnd = math.Random(widget.semente);
    _baralho = BaralhoDesafios(rnd: _rnd, tipo: TipoDesafio.sintaxe, banco: BancoArcade.desafios(context, TipoDesafio.sintaxe));
    setState(() {
      zerarCampanha();
      _golsRun = 0;
      _defesasRun = 0;
    });
    _comecarFase();
  }

  void _comecarFase() {
    _relogio?.cancel();
    _avanco?.cancel();
    setState(() {
      _engine = FutebolEngine();
      _fila = _baralho.sortear(_engine.cobrancas, fase);
      _idx = 0;
      _historico.clear();
      _revelado = false;
      _zonaBola = null;
      _zonaGoleiro = 1;
      _estourou = false;
      _restante = _tempoDoChute;
    });
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    pausarSeEscondido();
  }

  void _acumula() {
    _golsRun += _engine.gols;
    _defesasRun += _engine.defesas;
  }

  void _venceuFase() {
    _relogio?.cancel();
    _avanco?.cancel();
    _acumula();
    registrarFaseVencida();
  }

  void _proximaFase() {
    avancarFase();
    _comecarFase();
  }

  Future<void> _fimDeJogo({bool somaFaseAtual = true}) {
    if (pontuado) return Future.value();
    _relogio?.cancel();
    _avanco?.cancel();
    if (somaFaseAtual) _acumula();
    return encerrar(somaFaseAtual: somaFaseAtual);
  }

  // ---------- a série ----------

  void _tick() {
    if (pausado || _revelado || acabou || faseVencida) return;
    setState(() => _restante--);
    if (_restante <= 0) _chutar(null);
  }

  /// [zona] é a opção escolhida (0/1/2); null = o relógio estourou.
  void _chutar(int? zona) {
    if (_revelado || acabou || faseVencida || pausado) return;
    final certa = zona != null && zona == _desafio.certa;
    final resultado = _engine.chutar(certa: certa);
    Sons.toca(resultado == Chute.gol ? Som.gol : Som.defesa);
    setState(() {
      _revelado = true;
      _estourou = zona == null;
      _zonaBola = zona;
      _historico.add(resultado);
      if (certa) {
        // goleiro pula num canto ERRADO — a bola morre no canto certo
        final outras = [0, 1, 2]..remove(zona);
        _zonaGoleiro = outras[_rnd.nextInt(outras.length)];
      } else {
        // defendeu: as luvas vão exatamente aonde a bola foi
        _zonaGoleiro = zona ?? 1;
        _tremor++;
      }
    });
    if (_engine.terminou) {
      _avanco = Timer(const Duration(milliseconds: 2000), () {
        _engine.gols >= 3 ? _venceuFase() : _fimDeJogo();
      });
    } else {
      _avanco = Timer(
        Duration(milliseconds: resultado == Chute.gol ? 1700 : 2900),
        () => setState(() {
          _idx++;
          _revelado = false;
          _zonaBola = null;
          _zonaGoleiro = 1;
          _estourou = false;
          _restante = _tempoDoChute;
        }),
      );
    }
  }

  KeyEventResult _tecla(FocusNode node, KeyEvent e) {
    if (teclaDePausa(e)) return KeyEventResult.handled;
    if (e is! KeyDownEvent || pausado) return KeyEventResult.ignored;
    final zona = switch (e.logicalKey) {
      LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1 || LogicalKeyboardKey.arrowLeft => 0,
      LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2 || LogicalKeyboardKey.arrowDown => 1,
      LogicalKeyboardKey.digit3 || LogicalKeyboardKey.numpad3 || LogicalKeyboardKey.arrowRight => 2,
      _ => null,
    };
    if (zona == null) return KeyEventResult.ignored;
    _chutar(zona);
    return KeyEventResult.handled;
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
                      rotulo: 'ARCADE · SINTAXE',
                      titulo: '⚽ Gol de ${BancoArcade.linguagem}',
                      chips: [
                        ChipPlacar('FASE', '$fase'),
                        ChipPlacar('TOTAL', '$pontosParciais', cor: Mixart.brand),
                        ChipPlacar('GOLS', '${_engine.gols}'),
                        ChipPlacar('COBRANÇA',
                            '${(_engine.rodada + (acabou || faseVencida ? 0 : 1)).clamp(1, _engine.cobrancas)}/${_engine.cobrancas}'),
                      ],
                      acao: BotaoPausa(onTap: podePausar ? pausar : null),
                    ),
                    const SizedBox(height: 14),
                    Tremor(gatilho: _tremor, child: _gol()),
                    const SizedBox(height: 10),
                    _placarBolinhas(),
                    const SizedBox(height: 14),
                    BarraTempo(restante: _restante, total: _tempoDoChute),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Mixart.brandSub,
                        border: Border.all(color: Mixart.brandDim),
                        borderRadius: BorderRadius.circular(Mixart.radiusMd),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Text(_desafio.pergunta,
                              style: Mixart.ui(size: 14.5, weight: FontWeight.w600)
                                  .copyWith(height: 1.5)),
                        ),
                        const SizedBox(width: 10),
                        SeloNivel(_desafio.nivel),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    if (_desafio.codigo.isNotEmpty) ...[
                      CartaoCodigo(_desafio.codigo),
                      const SizedBox(height: 12),
                    ],
                    _opcoes(),
                    const SizedBox(height: 10),
                    SizedBox(height: 40, child: _feedback()),
                  ],
                ),
                if (pausado)
                  PausaOverlay(onContinuar: retomar, onSair: () => Navigator.of(context).pop()),
                if (faseVencida)
                  FaseVencida(
                    fase: fase,
                    pontosFase: comFator(pontosDoMotor),
                    pontosTotal: pontosTotal,
                    dica: dicaDaFase(fase),
                    aviso: '${fase == 1 ? 'entram desafios de nível 2 e ' : fase == 2 ? 'chegam os chefões de nível 3 e ' : ''}'
                        'o relógio do chute aperta pra ${(20 - 2 * fase).clamp(8, 20)}s!',
                    onProxima: _proximaFase,
                    onParar: () => _fimDeJogo(somaFaseAtual: false),
                  ),
                if (acabou)
                  FimDeJogo(
                    emoji: fasesVencidas > 0 ? '🏆' : '🧤',
                    titulo: fasesVencidas > 0 ? 'FIM DA CAMPANHA!' : 'O GOLEIRO LEVOU A MELHOR…',
                    subtitulo:
                        'Você marcou $_golsRun gol${_golsRun == 1 ? '' : 's'} em ${fasesVencidas + 1} série${fasesVencidas == 0 ? '' : 's'} — 3+ gols avançam de fase.',
                    pontos: pontosTotal,
                    novoRecorde: novoRecorde,
                    celebrar: fasesVencidas > 0,
                    noRanking: ranking != null,
                    stats: [
                      ('FASES', '$fasesVencidas'),
                      ('GOLS', '$_golsRun'),
                      ('DEFESAS', '$_defesasRun'),
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

  Widget _gol() {
    final gol = _revelado && _historico.isNotEmpty && _historico.last == Chute.gol;
    return Stack(children: [
      // o estádio em perspectiva: gramado, arquibancada, trave com rede,
      // goleiro que mergulha e a bola voando em arco
      Gol3D(
        fase: fase,
        zonaBola: _zonaBola,
        zonaGoleiro: _zonaGoleiro,
        revelado: _revelado,
        chuteId: _idx + fase * 100,
      ),
      // crachá da fase
      Positioned(
        left: 10,
        top: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xCC10131A),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${emojiDaFase(fase)} FASE $fase · ${nomeDaFase(fase)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      if (_revelado)
        Positioned.fill(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Mixart.spring,
              builder: (_, t, child) => Transform.scale(scale: t, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xE6010101),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _estourou ? '⏱ TEMPO ESGOTADO!' : (gol ? 'GOOOOL! 🎉' : 'DEFENDEU! 🧤'),
                  style: Mixart.display(
                      size: 24, color: gol ? Mixart.brand : Mixart.danger),
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _placarBolinhas() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (var i = 0; i < _engine.cobrancas; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            i < _historico.length ? (_historico[i] == Chute.gol ? '⚽' : '🧤') : '·',
            style: TextStyle(fontSize: 17, color: Mixart.textFaint),
          ),
        ),
    ]);
  }

  Widget _opcoes() {
    final botoes = [
      for (var i = 0; i < _desafio.opcoes.length; i++)
        BotaoOpcao(
          indice: i,
          codigo: _desafio.opcoes[i],
          cantoRotulo: _cantos[i],
          revelado: _revelado,
          ehCerta: i == _desafio.certa,
          ehEscolhida: i == _zonaBola,
          onTap: () => _chutar(i),
        ),
    ];
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth >= 680) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final b in botoes) ...[
            Expanded(child: b),
            if (b != botoes.last) const SizedBox(width: 10),
          ],
        ]);
      }
      return Column(children: [
        for (final b in botoes) Padding(padding: const EdgeInsets.only(bottom: 8), child: b),
      ]);
    });
  }

  Widget _feedback() {
    if (!_revelado) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('⌨️ 1 · 2 · 3 (ou ← ↓ →) escolhem o canto · Esc pausa',
            style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
      );
    }
    final gol = _historico.isNotEmpty && _historico.last == Chute.gol;
    if (gol) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('⚽ No ângulo! O goleiro nem viu.',
            style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        _estourou
            ? '⏱ Demorou demais — o goleiro ficou com ela. ${_desafio.explica}'
            : '🧤 Defendeu! ${_desafio.explica}',
        style: Mixart.ui(size: 12.5, weight: FontWeight.w600, color: Mixart.danger)
            .copyWith(height: 1.35),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
