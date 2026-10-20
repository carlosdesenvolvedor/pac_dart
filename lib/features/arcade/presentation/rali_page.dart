import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../../../core/ui/festa.dart';
import '../domain/corrida_engine.dart';
import '../domain/dicas_dart.dart';
import '../domain/digitar_palavra.dart';
import '../../ingles/domain/erros_palavra.dart';
import '../../ingles/domain/revisao.dart';
import '../../ingles/domain/teimosas.dart';
import '../../ingles/presentation/acoes_teimosas.dart';
import '../../ingles/presentation/palavras_cubit.dart';
import '../domain/personagem.dart';
import '../domain/tropecos.dart';
import '../domain/vocabulario_jogo.dart';
import 'banco_arcade.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/legenda_traducao.dart';
import 'widgets/campanha.dart';
import 'widgets/campo_teclas.dart';
import 'widgets/cenario.dart';
import 'widgets/painel_tropecos.dart';

/// Passo da CPU no Rali. No Dart e no C# é o de sempre: acelera 8% por fase, com piso de 1,8 s. No inglês
/// ([ingles]) acelera só 5% por fase (piso de 2,4 s) e dá folga para a [palavra] da vez — +140 ms por letra
/// acima de 5 e +25% (ler a tradução) ou +40% de [memoria]. É recalculado a cada passo, então palavra
/// comprida ganha tempo e a curta segue no ritmo.
@visibleForTesting
Duration intervaloCpuRali({
  required int baseMs,
  required int fase,
  required String palavra,
  bool ingles = false,
  bool memoria = false,
}) {
  if (!ingles) {
    final ms = (baseMs * math.pow(0.92, fase - 1)).round();
    return Duration(milliseconds: math.max(1800, ms));
  }
  var ms = math.max(2400.0, baseMs * math.pow(0.95, fase - 1));
  ms += 140 * math.min(9, math.max(0, palavra.length - 5));
  ms *= memoria ? 1.4 : 1.25;
  return Duration(milliseconds: ms.round());
}

/// 🏁 Rali de Digitação — campanha em FASES: cada palavra digitada faz seu
/// personagem andar (perfeita = turbo, anda 2). Largada 3-2-1, medidor da
/// CPU na pista, fila das próximas palavras à vista e pausa com Esc. Venceu
/// a corrida? Fase nova, cenário novo, CPU mais rápida — os pontos vão
/// ACUMULANDO até a CPU te pegar (ou você parar e guardar o que juntou).
class RaliPage extends StatefulWidget {
  /// Semente do sorteio (fixa nos testes; null = aleatório de verdade).
  final int? semente;
  const RaliPage({super.key, this.semente});

  @override
  State<RaliPage> createState() => _RaliPageState();
}

class _RaliPageState extends State<RaliPage>
    with
        WidgetsBindingObserver,
        PausaDeJogo<RaliPage>,
        CampanhaDeFases<RaliPage>,
        SingleTickerProviderStateMixin {
  Dificuldade? _dificuldade;
  CorridaEngine? _engine;
  late math.Random _rnd;
  List<String> _fila = const [];
  int _idx = 0;
  final _palavra = ProgressoPalavra();

  /// Inglês: o vocabulário da fase (tradução embaixo), o banco do aluno e o placar por palavra.
  VocabularioJogo? _vocab;
  PalavrasCubit? _palavrasCubit;
  final _placar = PlacarPalavras();

  /// Inglês (teimosas): os tropeços da partida (fora do modo memória, que já vira revisão), a oferta entre
  /// as fases (as palavras do painel) e a do fim de jogo — no máximo uma por partida. [_feedbackFixo]: o
  /// aviso "escapou 2x" fica na linha de feedback até a próxima palavra completa.
  TropecosDoJogo? _tropecos;
  List<(String, String?, int)>? _itensFase;
  SugestaoTeimosas? _sug;
  bool _jaOfereceu = false;
  bool _feedbackFixo = false;

  /// 🧠 Modo memória (só inglês): a tradução aparece grande e a palavra em inglês fica escondida (só a
  /// 1ª letra; o resto aparece enquanto você digita). Cada palavra vira uma revisão no banco (FSRS).
  bool _memoria = false;
  final Map<String, ResultadoRevisao> _lembradas = {};

  /// Modo memória travado: erros seguidos na letra atual, as letras reveladas da palavra (em âmbar) e
  /// se alguma foi revelada (aí a palavra conta como "errou" na revisão).
  static const errosParaRevelar = 3;
  int _errosLetra = 0;
  final Set<int> _reveladas = {};

  void _carregarPalavra(String w) {
    _palavra.carregar(w);
    _errosLetra = 0;
    _reveladas.clear();
  }

  /// Tab no modo memória: revela a próxima letra escondida (em âmbar; a 1ª já aparece), conta como erro
  /// e a palavra vira "errou".
  void _revelarLetra() {
    final e = _engine;
    if (!_memoria || e == null || acabou || faseVencida || pausado || _contagem || _palavra.completa) return;
    var j = _palavra.idx;
    while (j < _palavra.alvo.length && (j == 0 || _reveladas.contains(j))) {
      j++;
    }
    if (j >= _palavra.alvo.length) return; // já está tudo à vista
    Sons.toca(Som.erro);
    setState(() {
      _palavra.errosPalavra++;
      _errosTeclas++;
      _marcarRevelada(j);
    });
  }

  void _marcarRevelada([int? i]) {
    _reveladas.add(i ?? _palavra.idx);
    _errosLetra = 0;
    _ultimoErrou = false; // a letra aparece em âmbar (a revelação já é o aviso)
  }

  void _enviarMemoria() {
    if (_lembradas.isEmpty) return;
    _palavrasCubit?.registrarMemoria(Map.of(_lembradas));
    _lembradas.clear();
  }

  int _palavrasRun = 0;
  int _turbosRun = 0;

  int _errosTeclas = 0;
  int _charsCertos = 0;
  DateTime? _inicio;
  Duration _pausas = Duration.zero;
  DateTime? _pausaDesde;
  bool _ultimoErrou = false;
  String _feedback = '';

  bool _contagem = false;
  bool _chama = false;

  late final AnimationController _cpuCtrl = AnimationController(vsync: this)
    ..addStatusListener(_cpuCompletou);
  Timer? _relogio; // só pro PPM respirar
  Timer? _chamaTimer;

  @override
  String get jogoId => 'rali';

  @override
  int get pontosDoMotor => _engine?.pontos ?? 0;

  @override
  bool get emPartida => _engine != null && !_contagem;

  @override
  void initState() {
    super.initState();
    _palavrasCubit = BancoArcade.palavras(context);
    if (_palavrasCubit != null) _tropecos = TropecosDoJogo();
    PersonagemStore.carregar().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _relogio?.cancel();
    _chamaTimer?.cancel();
    _cpuCtrl.dispose();
    _placar.enviar(_palavrasCubit, fonte: FonteErro.rali, tropecos: _tropecos);
    _enviarMemoria();
    super.dispose();
  }

  // ---------- campanha ----------

  Duration _intervaloCpu() {
    final atual = _fila.isEmpty ? '' : _fila[_idx.clamp(0, _fila.length - 1)];
    return intervaloCpuRali(
      baseMs: _dificuldade!.intervaloCpu.inMilliseconds,
      fase: fase,
      palavra: atual,
      ingles: _vocab != null,
      memoria: _memoria,
    );
  }

  void _comecarRun(Dificuldade d) {
    setState(() {
      _dificuldade = d;
      _rnd = math.Random(widget.semente);
      zerarCampanha();
      _palavrasRun = 0;
      _turbosRun = 0;
      _errosTeclas = 0;
      _charsCertos = 0;
      _inicio = null;
      _pausas = Duration.zero;
      if (_palavrasCubit != null) _tropecos = TropecosDoJogo();
      _itensFase = null;
      _sug = null;
      _jaOfereceu = false;
    });
    _comecarFase();
  }

  void _comecarFase() {
    _cpuCtrl.stop();
    _relogio?.cancel();
    setState(() {
      _engine = CorridaEngine(pista: 12, dificuldade: _dificuldade!);
      // fase 3 em diante entram as palavras compridas (StatelessWidget…)
      final vocab = _vocab = BancoArcade.soDigitacao ? BancoArcade.vocabulario(context) : null;
      _fila = BancoArcade.baralhoRali(context, _rnd, comLongas: fase >= 3, vocab: vocab);
      if (_memoria && vocab != null) {
        // de memória só vale palavra que tem tradução para mostrar
        final comTraducao = [for (final w in _fila) if (vocab.traducao(w) != null) w];
        if (comTraducao.isNotEmpty) _fila = comTraducao;
      }
      _idx = 0;
      _carregarPalavra(_fila[0]);
      _ultimoErrou = false;
      _feedback = '';
      _feedbackFixo = false;
      _itensFase = null;
      _chama = false;
      _contagem = true;
    });
  }

  void _largada() {
    if (!mounted || acabou || _engine == null) return;
    setState(() {
      _contagem = false;
      _inicio ??= DateTime.now();
    });
    _cpuCtrl.duration = _intervaloCpu();
    _cpuCtrl.forward(from: 0);
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !acabou && !faseVencida && !pausado) setState(() {});
    });
    pausarSeEscondido();
  }

  void _cpuCompletou(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    final e = _engine;
    if (e == null || acabou || faseVencida || pausado || _contagem) return;
    setState(e.tickCpu);
    if (e.terminou) {
      _fimDeJogo();
      return;
    }
    _cpuCtrl.duration = _intervaloCpu();
    _cpuCtrl.forward(from: 0);
  }

  @override
  void aoPausar() {
    _cpuCtrl.stop();
    _pausaDesde = DateTime.now();
  }

  @override
  void aoRetomar() {
    final desde = _pausaDesde;
    if (desde != null) _pausas += DateTime.now().difference(desde);
    _pausaDesde = null;
    if (_engine == null || acabou || faseVencida) return;
    _cpuCtrl.forward();
  }

  void _acumula(CorridaEngine e) {
    _palavrasRun += e.acertos;
    _turbosRun += e.turbos;
  }

  void _venceuFase() {
    _cpuCtrl.stop();
    _relogio?.cancel();
    _acumula(_engine!);
    _oferecerEntreFases();
    registrarFaseVencida();
  }

  /// Inglês: entre as fases, o painel das palavras que escaparam (se a política deixar; uma vez por
  /// partida). Chame antes do setState que abre a [FaseVencida].
  void _oferecerEntreFases() {
    final cubit = _palavrasCubit, t = _tropecos;
    if (_jaOfereceu || cubit == null || t == null || t.somas.isEmpty) return;
    final itens = BancoArcade.itensDoJogo(t, _vocab, cubit: cubit);
    if (itens.isEmpty) return;
    if (cubit.sugestao(LocalSugestao.entreFases, daSessao: BancoArcade.daSessao(cubit, t)) == null) return;
    _jaOfereceu = true;
    cubit.marcarMostrada();
    _itensFase = itens;
  }

  /// Inglês: a oferta do fim de jogo (se ainda não houve oferta nesta partida e a política deixar).
  void _oferecerFim() {
    final cubit = _palavrasCubit, t = _tropecos;
    if (_jaOfereceu || cubit == null || t == null || t.somas.isEmpty) return;
    final sug = cubit.sugestao(LocalSugestao.fimDeJogo, daSessao: BancoArcade.daSessao(cubit, t));
    if (sug == null) return;
    _jaOfereceu = true;
    cubit.marcarMostrada();
    _sug = sug;
  }

  Widget? _painelFase() {
    final itens = _itensFase, cubit = _palavrasCubit;
    if (itens == null || cubit == null) return null;
    final chaves = BancoArcade.chavesDe(cubit, [for (final (w, _, _) in itens) w]);
    return PainelTropecos(
      palavras: itens,
      // treina e volta para esta mesma tela de fase vencida
      onTreinar: () => treinarTeimosas(context, chaves, origem: 'rali'),
      onFocar: () {
        jogarComTeimosas(context, chaves, dentroDoJogo: true);
        _proximaFase();
      },
    );
  }

  Widget? _ofertaFim(Dificuldade d) {
    final s = _sug;
    if (s == null) return null;
    return OfertaTeimosasFim(
      sugestao: s,
      onTreinar: () => treinarTeimosas(context, s.palavras, origem: 'rali').then((_) {
        if (mounted) setState(() => _sug = null);
      }),
      onRevanche: () {
        jogarComTeimosas(context, s.palavras, dentroDoJogo: true);
        _comecarRun(d);
      },
      onAgoraNao: _palavrasCubit?.adiar,
    );
  }

  /// Inglês: a linha das palavras anotadas na pausa (null sem nada).
  Widget? _anotadas() {
    final t = BancoArcade.linhaAnotadas(_tropecos);
    return t == null ? null : LinhaAnotadas(t);
  }

  void _proximaFase() {
    avancarFase();
    _comecarFase();
  }

  Future<void> _fimDeJogo({bool somaFaseAtual = true}) {
    if (pontuado) return Future.value();
    _cpuCtrl.stop();
    _relogio?.cancel();
    _placar.enviar(_palavrasCubit, fonte: FonteErro.rali, tropecos: _tropecos);
    _enviarMemoria();
    _oferecerFim();
    if (somaFaseAtual) _acumula(_engine!);
    return encerrar(somaFaseAtual: somaFaseAtual);
  }

  /// Palavras por minuto (5 toques = 1 palavra), descontando as pausas.
  int get _ppm {
    final ini = _inicio;
    if (ini == null) return 0;
    var pausas = _pausas;
    final desde = _pausaDesde;
    if (desde != null) pausas += DateTime.now().difference(desde);
    final min = (DateTime.now().difference(ini) - pausas).inMilliseconds / 60000.0;
    if (min <= 0) return 0;
    return (_charsCertos / 5 / min).round();
  }

  void _tecla(String ch) {
    final e = _engine;
    if (e == null || acabou || faseVencida || pausado || _contagem || ch.trim().isEmpty) return;
    final certa = _palavra.teclar(ch);
    if (!certa) {
      if (_palavrasCubit != null && !_memoria) _placar.errou(_palavra.alvo);
      Sons.toca(Som.erro);
      setState(() {
        _errosTeclas++;
        _ultimoErrou = true;
        // de memória, travou na mesma letra: ela aparece (em âmbar) e a palavra fica como "errou"
        if (_memoria && ++_errosLetra >= errosParaRevelar) _marcarRevelada();
      });
      return;
    }
    setState(() {
      _charsCertos++;
      _ultimoErrou = false;
      _errosLetra = 0;
      if (_feedback.isNotEmpty && _palavra.idx == 1 && !_feedbackFixo) _feedback = '';
      if (_palavra.completa) {
        final perfeita = _palavra.errosPalavra == 0;
        if (_palavrasCubit != null && !_memoria) _placar.viu(_palavra.alvo);
        final aviso = _memoria ? null : _tropecouNaPalavra();
        if (_memoria) _lembrou(_palavra.alvo, _palavra.errosPalavra, revelou: _reveladas.isNotEmpty);
        e.responder(certa: true, turbo: perfeita);
        Sons.toca(perfeita ? Som.turbo : Som.blip);
        _feedback = aviso ?? (perfeita ? '🔥 Palavra perfeita — TURBO!' : '⚡ Acelerou!');
        _feedbackFixo = aviso != null;
        _chama = perfeita;
        _idx++;
        _carregarPalavra(_fila[_idx % _fila.length]);
      }
    });
    if (_chama) {
      _chamaTimer?.cancel();
      _chamaTimer = Timer(const Duration(milliseconds: 1100), () {
        if (mounted) setState(() => _chama = false);
      });
    }
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
      body: Focus(
        onKeyEvent: (_, ev) {
          if (teclaDePausa(ev)) return KeyEventResult.handled;
          // modo memória: Tab revela a próxima letra (conta como erro)
          if (_memoria && _engine != null && ev is KeyDownEvent && ev.logicalKey == LogicalKeyboardKey.tab) {
            _revelarLetra();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Stack(children: [
                // atrás da pausa/fase vencida/fim, a pista congela (o Pac para de mastigar, a chama do
                // turbo para); os overlays ficam fora e seguem animando
                TickerMode(
                enabled: jogoAnimando,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    CabecalhoJogo(
                      rotulo: 'ARCADE · DIGITAÇÃO',
                      titulo: '🏁 Rali de Digitação',
                      chips: e == null
                          ? const []
                          : [
                              ChipPlacar('FASE', '$fase'),
                              ChipPlacar('TOTAL', '$pontosParciais', cor: Mixart.brand),
                              ChipPlacar('PPM', '$_ppm'),
                              ChipPlacar('ERROS', '$_errosTeclas',
                                  cor: _ultimoErrou ? Mixart.danger : null),
                            ],
                      acao: e == null ? null : BotaoPausa(onTap: podePausar ? pausar : null),
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
                          'sem nenhum erro é TURBO (anda 2). O medidor sob a CPU mostra '
                          'quando ela vai andar. Venceu? Vem outra fase com cenário novo e '
                          'CPU mais rápida — e os pontos vão somando até a CPU te pegar. '
                          'Palavras compridas entram na fase 3! Esc pausa.',
                          style: Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (BancoArcade.soDigitacao) ...[
                        _chaveMemoria(),
                        const SizedBox(height: 16),
                      ],
                      SeletorDificuldade(onEscolher: _comecarRun),
                    ] else ...[
                      PistaPro(
                        posJogador: e.posJogador,
                        posCpu: e.posCpu,
                        pista: e.pista,
                        fase: fase,
                        turbo: _chama,
                        cargaCpu: _cpuCtrl,
                      ),
                      const SizedBox(height: 18),
                      _cartaoPalavra(),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 26,
                        child: Text(
                          _feedback.isNotEmpty
                              ? _feedback
                              : _memoria && _vocab != null
                                  ? '🧠 travou? Tab mostra a letra (ou $errosParaRevelar erros nela) · Esc pausa'
                                  : '⌨️ é só digitar — errou, a letra não anda (e conta erro) · Esc pausa',
                          style: _feedback.isNotEmpty
                              ? Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)
                              : Mixart.ui(size: 11.5, color: Mixart.textFaint),
                        ),
                      ),
                      CampoTeclas(onChar: _tecla),
                    ],
                  ],
                ),
                ),
                if (_contagem)
                  ContagemRegressiva(
                    onFim: _largada,
                    legenda: '${emojiDaFase(fase)} FASE $fase · ${nomeDaFase(fase)} — dedos a postos',
                  ),
                if (pausado)
                  PausaOverlay(
                      onContinuar: retomar, onSair: () => Navigator.of(context).pop(), extra: _anotadas()),
                if (faseVencida)
                  FaseVencida(
                    fase: fase,
                    pontosFase: comFator(pontosDoMotor),
                    pontosTotal: pontosTotal,
                    dica: dicaDaFase(fase),
                    aviso: fase + 1 == 3
                        ? 'a CPU acelera e entram as palavras COMPRIDAS!'
                        : 'a CPU fica ainda mais rápida!',
                    onProxima: _proximaFase,
                    onParar: () => _fimDeJogo(somaFaseAtual: false),
                    extra: _painelFase(),
                  ),
                if (acabou && e != null)
                  FimDeJogo(
                    emoji: fasesVencidas > 0 ? '🏆' : '🤖',
                    titulo: fasesVencidas > 0 ? 'FIM DA CAMPANHA!' : 'A CPU VENCEU…',
                    subtitulo: fasesVencidas > 0
                        ? 'Você venceu $fasesVencidas fase${fasesVencidas > 1 ? 's' : ''} e digitou $_palavrasRun palavras.'
                        : 'Palavra perfeita dá TURBO — capriche e tente de novo!',
                    pontos: pontosTotal,
                    novoRecorde: novoRecorde,
                    celebrar: fasesVencidas > 0,
                    noRanking: ranking != null,
                    stats: [
                      ('FASES', '$fasesVencidas'),
                      ('PALAVRAS', '$_palavrasRun'),
                      ('TURBOS', '$_turbosRun'),
                      ('PPM', '$_ppm'),
                      ('ERROS', '$_errosTeclas'),
                    ],
                    onDeNovo: () => _comecarRun(e.dificuldade),
                    onSair: () => Navigator.of(context).pop(),
                    extra: _ofertaFim(e.dificuldade),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  /// Inglês: a palavra do Rali saiu — vista, e falha de min(1, erros/2) se tropeçou. Devolve o texto do
  /// aviso quando ela escapou pela 2ª vez (ou null).
  String? _tropecouNaPalavra() {
    final t = _tropecos;
    if (t == null) return null;
    final w = _palavra.alvo;
    t.vista(w);
    final erros = _palavra.errosPalavra;
    if (erros <= 0) return null;
    t.falha(w, math.min(1.0, erros / 2));
    final a = t.aviso(w);
    return a == null ? null : BancoArcade.textoAviso(a, t.vezes(a));
  }

  /// A palavra lembrada: sem erro = acertou, 1–3 = hesitou, mais (ou com letra revelada) = errou
  /// (fica o pior da partida).
  void _lembrou(String palavra, int erros, {bool revelou = false}) {
    final r = revelou
        ? ResultadoRevisao.errou
        : erros == 0
        ? ResultadoRevisao.acertou
        : erros <= 3
            ? ResultadoRevisao.hesitou
            : ResultadoRevisao.errou;
    final antes = _lembradas[palavra];
    if (antes == null || r.index < antes.index) _lembradas[palavra] = r;
  }

  /// A chave do modo memória na tela de início (só no inglês).
  Widget _chaveMemoria() {
    return Material(
      color: _memoria ? Mixart.brandSub : Mixart.surface,
      borderRadius: BorderRadius.circular(Mixart.radiusMd),
      child: InkWell(
        key: const Key('rali-memoria'),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        onTap: () => setState(() => _memoria = !_memoria),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          decoration: BoxDecoration(
            border: Border.all(color: _memoria ? Mixart.brand : Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Row(children: [
            const Text('🧠', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Modo memória', style: Mixart.display(size: 15)),
                const SizedBox(height: 2),
                Text('A tradução aparece grande e você escreve a palavra em inglês de cabeça — '
                    'cada uma vira uma revisão das suas palavras.',
                    style: Mixart.ui(size: 11.5, color: Mixart.textMuted).copyWith(height: 1.4)),
              ]),
            ),
            Switch(
              value: _memoria,
              activeThumbColor: Mixart.onBrand,
              activeTrackColor: Mixart.brand,
              onChanged: (v) => setState(() => _memoria = v),
            ),
          ]),
        ),
      ),
    );
  }

  /// Modo memória: a tradução grande e a palavra em inglês escondida (1ª letra + o que já digitou).
  Widget _cartaoMemoria() {
    final alvo = _palavra.alvo;
    final idx = _palavra.idx;
    final ambar = escurecer(CoresFesta.ambar, quanto: .2, soNoClaro: true);
    final proximas = [
      for (var k = 1; k <= 2; k++) _fila[(_idx + k) % _fila.length],
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(
            color: _ultimoErrou ? Mixart.danger : Mixart.border, width: _ultimoErrou ? 1.6 : 1),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(children: [
        Text('PALAVRA ${_idx + 1} · 🧠 DE MEMÓRIA',
            style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.textFaint)
                .copyWith(letterSpacing: 2)),
        const SizedBox(height: 10),
        Text(_traducao(alvo) ?? '',
            key: const Key('rali-memoria-pt'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Mixart.display(size: 30)),
        const SizedBox(height: 10),
        Semantics(
          label: 'escreva em inglês, começa com ${alvo.isEmpty ? '' : alvo[0]}',
          excludeSemantics: true,
          child: Text.rich(
            TextSpan(children: [
              for (var i = 0; i < alvo.length; i++)
                TextSpan(
                  text: i < idx || i == 0 || _reveladas.contains(i) ? alvo[i] : '_',
                  style: TextStyle(
                    // revelada (Tab ou 3 erros) fica em âmbar, mesmo depois de digitada
                    color: _reveladas.contains(i)
                        ? (i == idx && _ultimoErrou ? Colors.white : ambar)
                        : i < idx
                            ? Mixart.brand
                            : (i == idx ? (_ultimoErrou ? Colors.white : Mixart.text) : Mixart.textFaint),
                    backgroundColor: i == idx ? (_ultimoErrou ? Mixart.danger : Mixart.brandSub) : null,
                    fontWeight: i < idx || _reveladas.contains(i) ? FontWeight.w700 : null,
                  ),
                ),
            ]),
            style: Mixart.mono(size: 26).copyWith(letterSpacing: 6, height: 1.2),
          ),
        ),
        const SizedBox(height: 12),
        Text('a seguir: ${proximas.map((p) => _traducao(p) ?? '…').join('  ·  ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Mixart.ui(size: 11, color: Mixart.textFaint)),
      ]),
    );
  }

  Widget _cartaoPalavra() {
    if (_memoria && _vocab != null) return _cartaoMemoria();
    final alvo = _palavra.alvo;
    final idx = _palavra.idx;
    final proximas = [
      for (var k = 1; k <= 2; k++) _fila[(_idx + k) % _fila.length],
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
        if (_traducao(alvo) != null) ...[
          const SizedBox(height: 4),
          LegendaTraducao(_traducao(alvo), tamanho: 15, maxLargura: 320),
        ],
        const SizedBox(height: 12),
        // a fila à vista: quem lê na frente digita sem tropeçar
        if (_vocab == null)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('a seguir: ', style: Mixart.ui(size: 11, color: Mixart.textFaint)),
            for (final p in proximas) ...[
              Text(p, style: Mixart.mono(size: 12.5, color: Mixart.textMuted)),
              if (p != proximas.last)
                Text('  ·  ', style: Mixart.ui(size: 11, color: Mixart.textFaint)),
            ],
          ])
        else
          // inglês: cada próxima palavra com a tradução embaixo
          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('a seguir: ', style: Mixart.ui(size: 11, color: Mixart.textFaint).copyWith(height: 1.45)),
            for (var k = 0; k < proximas.length; k++) ...[
              if (k > 0) Text('  ·  ', style: Mixart.ui(size: 11, color: Mixart.textFaint).copyWith(height: 1.45)),
              Flexible(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(proximas[k],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mixart.mono(size: 12.5, color: Mixart.textMuted)),
                  LegendaTraducao(_traducao(proximas[k]), tamanho: 10, maxLargura: 90),
                ]),
              ),
            ],
          ]),
      ]),
    );
  }

  /// A tradução de [palavra] (só no inglês).
  String? _traducao(String palavra) => _vocab?.traducao(palavra);
}
