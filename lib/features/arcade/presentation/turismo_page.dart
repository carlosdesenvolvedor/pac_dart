import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'banco_arcade.dart';
import 'voz_jogo.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../../ingles/data/voz_ingles.dart';
import '../../ingles/domain/erros_palavra.dart';
import '../../ingles/domain/teimosas.dart';
import '../../ingles/presentation/acoes_teimosas.dart';
import '../../ingles/presentation/palavras_cubit.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/baralho_fases.dart';
import '../domain/historia_turismo.dart';
import '../domain/personagem.dart';
import '../domain/progresso_historia.dart';
import '../domain/progresso_turismo.dart';
import '../domain/tropecos.dart';
import '../domain/turismo.dart';
import '../data/engenheiro_gt.dart';
import '../data/historia_turismo_repo.dart';
import 'historia/galeria_historia.dart';
import 'historia/player_historia.dart';
import 'widgets/ambiente_turismo.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/aviso_arcade.dart';
import 'widgets/campanha.dart';
import 'widgets/campo_teclas.dart';
import 'widgets/legenda_traducao.dart';
import 'widgets/linha_fase.dart';
import 'widgets/minimapa.dart';
import 'widgets/painel_tropecos.dart';
import 'widgets/tutorial_turismo.dart';
import 'widgets/vista_3d.dart';
import 'widgets/vista_3d_controlador.dart';

/// 🏎️ Dart Turismo — campeonato de digitação em 10 pistas pseudo-3D (30 no English Turismo).
/// Cada portal marca a faixa livre com uma PALAVRA: digite-a pra entrar na
/// faixa. Toda tecla certa acelera; parar de digitar é ir parando; cruzar o
/// portal numa faixa bloqueada é batida. Feche a pista dentro do tempo pra
/// liberar a próxima — ouro, prata ou bronze pelo relógio.
///
/// 📖 No inglês, com [historia] ou [carregarHistoria], cada pista tem um capítulo de "The Golden Wheel":
/// a abertura toca antes da corrida e a chegada 1,2 s depois do resultado (uma vez cada, com "📖 Auto").
class TurismoPage extends StatefulWidget {
  /// Semente da pista (fixa nos testes; null = aleatória).
  final int? semente;

  /// Abre direto correndo esta pista (1–10; 1–30 no inglês); null = tela do campeonato.
  final int? pistaInicial;

  /// A engenheira de pista (IA) — injetável nos testes.
  final EngenheiroGt? engenheiro;

  /// 📖 A história já carregada (testes). Só vale no inglês.
  final HistoriaTurismo? historia;

  /// 📖 Carrega a história dos JSON (o hub liga). Só vale no inglês: Dart e C# nunca carregam.
  final bool carregarHistoria;

  /// 📖 A voz dos desenhos (testes); null = uma `VozIngles` própria da página.
  final VozIngles? vozHistoria;
  const TurismoPage({
    super.key,
    this.semente,
    this.pistaInicial,
    this.engenheiro,
    this.historia,
    this.carregarHistoria = false,
    this.vozHistoria,
  });

  @override
  State<TurismoPage> createState() => _TurismoPageState();
}

enum _Tela { campeonato, corrida }

class _TurismoPageState extends State<TurismoPage>
    with WidgetsBindingObserver, PausaDeJogo<TurismoPage>, SingleTickerProviderStateMixin {
  RankingCubit? _ranking;
  EstadoCampeonato _campeonato = EstadoCampeonato.vazio;
  String _carro = carrosGt.first.id;
  String _avisoGaragem = '';
  int _moedasCorrida = 0;

  /// Muda a cada corrida: a vista 3D é recriada do zero (cena da pista nova).
  int _corridaId = 0;

  /// 🎮 Modo SETAS (← → ↑ ↓) em vez de digitação — escolha salva.
  bool _modoSetas = false;
  bool _gas = false;
  bool _freio = false;
  final _foco = FocusNode(debugLabel: 'turismo');

  /// Câmera da vista 3D (C troca; escolha salva).
  String _camera = camerasGt.first;

  /// 🎸 Música da fase (escolha salva) e 🎧 o debrief da engenheira.
  bool _musica = true;
  String? _radio;

  /// ⚙️ Qualidade da vista 3D e tremor de câmera (escolhas salvas).
  String _qualidade = qualidadesGt.first;
  bool _tremor = true;

  /// 📖 Tutorial da 1ª corrida (por modo) e 🗺️ o traçado pro minimapa.
  bool _tutorial = false;
  List<Offset> _tracado = const [];

  /// A cena 3D recebe o estado a cada tick por aqui; o HUD redesenha a
  /// ~30 Hz (por TEMPO, não por frame: num monitor de 120 Hz continua 30).
  final _vista = Vista3DControlador();
  double _desdeHud = 0;

  /// Sem 3D (nativo, ou web sem o módulo) a estrada em Canvas só anda no setState: redesenha a
  /// cada 2 frames (60 fps em tela de 120 Hz). O limite de ~30 Hz por tempo é só pro HUD sobre o 3D.
  bool _quadroPar = false;

  /// A cena 3D está pronta pra largar? (sem 3D, sempre; com 3D, quando o
  /// JS terminou de carregar tráfego, texturas e shaders — ou após 60 s)
  bool _cenaPronta = true;
  Timer? _esperaCena;

  /// 👻 O fantasma da pista atual, 📊 as estatísticas e 🏆 os troféus novos.
  VoltaFantasma? _fantasma;
  bool _bateuFantasma = false;
  EstatisticasGt _estatisticas = EstatisticasGt.vazio;
  List<TrofeuGt> _trofeusNovos = const [];

  _Tela _tela = _Tela.campeonato;
  PistaGt? _pista;
  TurismoEngine? _engine;
  late final Ticker _ticker; // criado no initState, ligado só na partida
  Duration _ultimo = Duration.zero;

  /// O Ticker só roda com o carro na pista (da largada até a pausa/o fim): no campeonato, no tutorial,
  /// na contagem, na pausa e no resultado ele não pede frame (no navegador cada frame redesenha a tela
  /// inteira). Ao religar, o 1º passo conta a partir do último frame desenhado ([_religadoEm]); na volta
  /// da pausa, no máximo do tamanho do último passo jogado ([_ultimoDt]) — o carro não "pula".
  Duration? _religadoEm;
  bool _retomando = false;
  double _ultimoDt = 1 / 60;
  double _relogio = 0;
  double _ultimoRonco = -1;

  bool _contagem = false;
  bool _acabou = false;
  bool _pontuado = false;
  bool _novoRecorde = false;
  bool _campeao = false;

  /// Inglês: o banco de palavras do aluno e o que aconteceu com cada palavra (portal perdido = erro).
  PalavrasCubit? _palavrasCubit;
  final _placar = PlacarPalavras();

  /// Inglês (teimosas, só digitando): os tropeços da corrida, o aviso "escapou 2x" na pista e a oferta
  /// "treinar só elas" da tela de fim.
  TropecosDoJogo? _tropecos;
  String? _avisoTropeco;
  SugestaoTeimosas? _sug;

  static const _setas = ['⬅ ESQUERDA', '⬆ MEIO', '➡ DIREITA'];

  /// As pistas do curso atual: 30 no inglês, 10 no Dart/C# (mesma lista `pistasGt` de sempre).
  List<PistaGt> get _pistas => pistasTurismo(ingles: BancoArcade.soDigitacao);

  /// Os troféus do curso atual (o inglês ganha 🌍 volta ao mundo, 🏆 lenda e 📖 história).
  List<TrofeuGt> get _trofeusDoCurso => trofeusDoTurismo(ingles: BancoArcade.soDigitacao);

  // ---------- 📖 história (só no inglês) ----------

  /// A história vale nesta página? Só no inglês e só com opt-in ([TurismoPage.historia] ou
  /// [TurismoPage.carregarHistoria]): os testes antigos e o Dart/C# nunca carregam os JSON.
  bool get _historiaAtiva =>
      BancoArcade.soDigitacao && (widget.historia != null || widget.carregarHistoria);
  HistoriaTurismo? _historia;
  Future<HistoriaTurismo?>? _futuroHistoria;

  /// O que já foi visto (`i7`/`f7`/`c7`) e a pref "📖 Auto" (as cenas tocam sozinhas uma vez).
  Set<String> _vistos = const {};
  bool _historiaAuto = true;

  /// Guarda de reentrada do [_correr] (toque duplo, "de novo" rápido): um player por vez.
  bool _abrindoCena = false;

  /// Uma rota da história (player ou galeria) está por cima: o campo de teclas da corrida fica fora do
  /// foco (senão ele "rouba" o teclado do desenho) e volta novo ([_geracaoTeclas]) quando a rota fecha.
  bool _cenaAberta = false;
  int _geracaoTeclas = 0;

  /// A chegada que abre sozinha 1,2 s depois do resultado; [_fichaChegada] invalida a que já disparou.
  Timer? _chegadaAgendada;
  int _fichaChegada = 0;
  static const _esperaChegada = Duration(milliseconds: 1200);

  /// O [_fim] gravando (registro, fantasma, estatísticas, moedas, campeonato, troféus): "📖 Continue a
  /// história" espera ele acabar antes de abrir o player (plano 6.4). O ranking (rede) não entra aqui.
  Completer<void>? _gravandoFim;

  /// A voz dos desenhos: a injetada ou uma própria (criada só quando um desenho abre).
  VozIngles? _vozPropria;
  VozIngles get _vozHistoria => widget.vozHistoria ?? (_vozPropria ??= VozIngles());

  /// Temporadas (inglês): o cartão da pista mais longe (rola até ele ao abrir) e as recolhidas.
  final _chaveCartaoMax = GlobalKey(debugLabel: 'turismo-cartao-max');
  bool _rolouAteMax = false;
  final Set<int> _temporadasRecolhidas = {};
  static const _temporadas = [
    (de: 1, ate: 10, nome: 'Word Grand Tour'),
    (de: 11, ate: 20, nome: 'World Tour'),
    (de: 21, ate: 30, nome: 'Legends'),
  ];

  /// As palavras na tela, pra quem precisa achá-las (testes): as dos portais e a de combustível.
  static const _chavesPalavra = [Key('turismo-palavra-0'), Key('turismo-palavra-1')];
  static const _chaveGas = Key('turismo-gas');

  /// Inglês (digitando): o baralho por FASE do campeonato — cada corrida é uma fase, com palavras novas
  /// (o vocabulário roda inteiro antes de alguma voltar) e as que você errou ou demorou mais voltando pra
  /// revisar 🔁 logo no começo da próxima. Vive enquanto a página vive (corrida após corrida); null no Dart,
  /// no C# e no modo setas. [_deck]: o da corrida na pista — a largada mostra o resumo dele
  /// ('Pista 2 · 49 palavras · 32 novas · 17 pra revisar 🔁').
  BaralhoFases? _baralho;
  DeckFase? _deck;
  int _corridasIngles = 0;

  /// O tempo de cada palavra (da 1ª tecla certa à última, sem as pausas — a espera do freio automático e a
  /// contagem ficam de fora sozinhas: ninguém digita nelas) e as teclas erradas até ela sair.
  final _crono = CronometroPalavra();
  int _errosNaPalavra = 0;

  /// 🔊 Inglês: a palavra falada quando a pessoa TRAVA nela — no portal (1ª letra certa) e na de
  /// combustível (idem), nunca quando aparece: a de combustível entra no instante em que o portal é
  /// completado e, falada ali, cortaria a do portal ainda soando. No modo SETAS (ninguém digita, nada
  /// trava) a do portal é falada quando ele vira o alvo à frente do carro ([_falarPortalSetas]).
  /// [_vozPortal]/[_vozTravada]/[_vozGas]: o que já foi falado (só se compara). Na web a música abaixa
  /// enquanto a palavra soa.
  final _voz = VozDoJogo();
  Portal? _vozPortal;
  int? _vozTravada;
  String? _vozGas;
  static const _duckVozMs = 1400;

  void _falar(String w) {
    if (_voz.falar(w, pausado: pausado, acabou: _acabou)) _vista.abaixarMusica(_duckVozMs);
  }

  /// Fala o alvo em que a pessoa travou (a palavra do portal ou a de combustível), se mudou desde a última vez.
  void _falarAlvoNovo(TurismoEngine e) {
    final p = e.portalParaDigitar;
    final travada = p == null ? null : e.palavraTravada;
    if (p != null && travada != null) {
      if (identical(p, _vozPortal) && travada == _vozTravada) return;
      _vozPortal = p;
      _vozTravada = travada;
      _falar(p.palavras[travada]);
      return;
    }
    // a de combustível: falada na 1ª letra certa; enquanto não começou (ou saiu), a próxima é nova
    final gas = p == null ? e.palavraGas : null;
    if (gas == null || e.gasDigitadas == 0) {
      _vozGas = null;
      return;
    }
    if (identical(gas, _vozGas)) return;
    _vozGas = gas;
    _falar(gas);
  }

  /// Modo setas: fala a palavra do portal que acabou de virar o alvo ([TurismoEngine.portalAtual]) —
  /// o 1º na largada, cada seguinte no instante em que o carro cruza o anterior: um portal fica a ~2,8 s
  /// do outro na velocidade máxima, tempo de ouvir antes de chegar. Uma vez por portal, nunca de novo
  /// (nem ao voltar da pausa). É a palavra que o cartão mostra (a da 1ª faixa livre, com a tradução):
  /// com duas saídas a 2ª fica muda — falada logo depois, cortaria a 1ª ainda soando. Nas setas não há
  /// palavra de combustível. Com a voz desligada nada é marcado: religada no meio, o portal da vez fala.
  void _falarPortalSetas(TurismoEngine e) {
    final p = e.portalAtual;
    if (p == null || p.palavras.isEmpty || identical(p, _vozPortal)) return;
    _vozPortal = p;
    _falar(p.palavras.first);
  }

  void _alternarVoz() {
    Sons.toca(Som.blip);
    _voz.alternar();
    setState(() {});
  }

  @override
  bool get podePausar => _tela == _Tela.corrida && _engine != null && !_contagem && !_acabou && !_tutorial;

  @override
  void initState() {
    super.initState();
    _ranking = RankingCubit.de(context);
    _palavrasCubit = BancoArcade.palavras(context);
    _ticker = createTicker(_tick);
    PersonagemStore.carregar().then((_) {
      if (mounted) setState(() {});
    });
    if (_historiaAtiva) _iniciarHistoria();
    // o modo (⌨️/🎮), o carro e a câmera salvos entram ANTES da corrida direta
    _carregarCampeonato().then((_) {
      final inicial = widget.pistaInicial;
      if (inicial != null && mounted) {
        _correr(_pistas[(inicial - 1).clamp(0, _pistas.length - 1)]);
      } else {
        _rolarAtePistaMax();
      }
    });
    if (BancoArcade.soDigitacao) {
      VozDoJogo.carregarPreferencia().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// 📖 A história injetada ou carregada dos JSON (quando chega, os cartões ganham a linha 📖), o que já
  /// foi visto e a pref "📖 Auto".
  void _iniciarHistoria() {
    final injetada = widget.historia;
    if (injetada != null) {
      _historia = injetada;
    } else {
      final f = _futuroHistoria = HistoriaTurismoRepo.carregar();
      f.then((h) {
        if (mounted && h != null) setState(() => _historia = h);
      });
    }
    _recarregarVistos();
  }

  Future<void> _recarregarVistos() async {
    final vistos = await ProgressoHistoria.vistos();
    final auto = await ProgressoHistoria.auto();
    if (!mounted) return;
    setState(() {
      _vistos = vistos;
      _historiaAuto = auto;
    });
  }

  /// A história pronta para tocar: espera o carregamento no máximo 3 s (falha ou demora = sem cena).
  Future<HistoriaTurismo?> _historiaPronta() async {
    final h = _historia;
    if (h != null) return h;
    final f = _futuroHistoria;
    if (f == null) return null;
    try {
      return await f.timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    }
  }

  /// Inglês com temporadas: ao abrir, rola até o cartão da pista mais longe liberada (a 1 já está à vista
  /// logo abaixo das opções; rolar ali só esconderia a explicação de quem está começando).
  /// O cartão ainda pode não estar montado no 1º quadro: tenta de novo nos próximos ([tentativa] até 5) e
  /// só marca [_rolouAteMax] quando achou (a lista do campeonato monta tudo de uma vez: `cacheExtent`).
  void _rolarAtePistaMax({int tentativa = 0}) {
    if (_rolouAteMax || !mounted || _pistas.length <= pistasClassicas || _campeonato.pistaMax <= 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _rolouAteMax || _tela != _Tela.campeonato) return;
      final ctx = _chaveCartaoMax.currentContext;
      if (ctx == null) {
        if (tentativa < 5) {
          _rolarAtePistaMax(tentativa: tentativa + 1);
          WidgetsBinding.instance.scheduleFrame();
        }
        return;
      }
      _rolouAteMax = true;
      final reduzir = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      Scrollable.ensureVisible(ctx,
          alignment: .3, duration: reduzir ? Duration.zero : const Duration(milliseconds: 350));
    });
  }

  Future<void> _carregarCampeonato() async {
    final c = await ProgressoTurismo.carregar(totalPistas: _pistas.length);
    final carro = await ProgressoTurismo.carroEscolhido();
    final setas = await ProgressoTurismo.modoSetas();
    final camera = await ProgressoTurismo.camera();
    final musica = await ProgressoTurismo.musicaLigada();
    final qualidade = await ProgressoTurismo.qualidade();
    final tremor = await ProgressoTurismo.tremorLigado();
    final estatisticas = await ProgressoTurismo.estatisticas();
    if (mounted) {
      setState(() {
        _campeonato = c;
        _carro = carro;
        _modoSetas = setas;
        _camera = camera;
        _musica = musica;
        _qualidade = qualidade;
        _tremor = tremor;
        _estatisticas = estatisticas;
      });
    }
  }

  void _escolherModo(bool setas) {
    if (_modoSetas == setas) return;
    Sons.toca(Som.blip);
    setState(() => _modoSetas = setas);
    ProgressoTurismo.escolherModo(setas: setas);
  }

  void _escolherQualidade(String q) {
    if (_qualidade == q) return;
    Sons.toca(Som.blip);
    setState(() => _qualidade = q);
    ProgressoTurismo.escolherQualidade(q);
  }

  void _alternarTremor() {
    Sons.toca(Som.blip);
    setState(() => _tremor = !_tremor);
    ProgressoTurismo.ligarTremor(_tremor);
  }

  void _fecharTutorial() {
    if (!_tutorial) return;
    Sons.toca(Som.largada);
    setState(() => _tutorial = false);
    ProgressoTurismo.marcarTutorial(setas: _modoSetas);
    if (_modoSetas) _foco.requestFocus();
  }

  void _alternarMusica() {
    Sons.toca(Som.blip);
    setState(() => _musica = !_musica);
    ProgressoTurismo.ligarMusica(_musica);
  }

  void _proximaCamera() {
    final i = camerasGt.indexOf(_camera);
    final nova = camerasGt[(i + 1) % camerasGt.length];
    Sons.toca(Som.blip);
    setState(() => _camera = nova);
    ProgressoTurismo.escolherCamera(nova);
  }

  /// Modo setas: ← → trocam de faixa na hora.
  void _virar(int delta) {
    final e = _engine;
    if (e == null || !e.porSetas || _contagem || pausado || _acabou) return;
    final antes = e.faixa;
    e.virar(delta);
    if (e.faixa != antes) {
      Sons.toca(Som.waka);
      setState(() {});
    }
  }

  /// Teclado global: Esc pausa; no modo setas, ← → ↑ ↓ (ou A D W S) dirigem
  /// e C troca a câmera.
  KeyEventResult _teclaGlobal(KeyEvent ev) {
    if (teclaDePausa(ev)) return KeyEventResult.handled;
    final e = _engine;
    if (e == null || !e.porSetas || _tela != _Tela.corrida) return KeyEventResult.ignored;
    final k = ev.logicalKey;
    final baixo = ev is KeyDownEvent;
    final solto = ev is KeyUpEvent;
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
      if (baixo) _virar(-1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD) {
      if (baixo) _virar(1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) {
      if (baixo) _gas = true;
      if (solto) _gas = false;
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS) {
      if (baixo) _freio = true;
      if (solto) _freio = false;
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyC && baixo) {
      _proximaCamera();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _escolherCarro(String id) async {
    final carro = carrosGt.firstWhere((c) => c.id == id);
    if (!_campeonato.temCarro(id)) {
      final comprou = await ProgressoTurismo.comprarCarro(id);
      if (!mounted) return;
      if (!comprou) {
        Sons.toca(Som.erro);
        setState(() => _avisoGaragem =
            'Faltam ${carro.preco - _campeonato.moedas} moedas pro ${carro.nome} — pegue as fichas na pista!');
        return;
      }
      Sons.toca(Som.fanfarra);
      setState(() => _avisoGaragem = '🎉 ${carro.nome} é seu!');
      await _carregarCampeonato();
    } else {
      setState(() => _avisoGaragem = '');
    }
    if (!mounted) return;
    setState(() => _carro = id);
    ProgressoTurismo.escolherCarro(id);
  }

  @override
  void dispose() {
    _voz.encerrar();
    _ticker.dispose();
    _esperaCena?.cancel();
    _cancelarChegada();
    _vozPropria?.parar();
    _foco.dispose();
    Sons.motorParar();
    _publicarParcial();
    super.dispose();
  }

  /// Saiu no meio: as palavras digitadas valem ponto mesmo assim.
  void _publicarParcial() {
    _placar.enviar(_palavrasCubit,
        fonte: FonteErro.turismo, tropecos: _tropecos, lentas: _baralho?.tirarLentasParaBanco() ?? const {});
    final e = _engine;
    if (e == null || _pontuado || e.pontos <= 0) return;
    _pontuado = true;
    _ranking?.arcadeJogado('turismo', e.pontos);
  }

  @override
  void aoPausar() {
    Sons.motorParar();
    _desligarTicker();
    _voz.calar();
    _crono.pausar();
  }

  @override
  void aoRetomar() {
    _crono.retomar();
    if (_tela == _Tela.corrida && _engine != null && !_acabou && !_contagem) _ligarTicker(retomando: true);
  }

  void _ligarTicker({bool retomando = false}) {
    if (_ticker.isActive) return;
    _religadoEm = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    _retomando = retomando;
    _ticker.start();
  }

  void _desligarTicker() {
    if (_ticker.isActive) _ticker.stop();
  }

  // ---------- corrida ----------

  /// Corre a pista [p]. No inglês com história, a abertura do capítulo toca ANTES (rota opaca, sem UI
  /// sobre a vista 3D); a guarda [_abrindoCena] garante um player só para toques repetidos.
  Future<void> _correr(PistaGt p) async {
    if (_abrindoCena) return;
    _abrindoCena = true;
    var abriuCena = false;
    try {
      _desligarTicker();
      Sons.motorParar();
      _cancelarChegada();
      if (_historiaAtiva) {
        final (seguir, abriu) = await _aberturaDaHistoria(p);
        abriuCena = abriu;
        if (!mounted || !seguir) return;
      }
      await _montarCorrida(p);
    } finally {
      _abrindoCena = false;
    }
    // o teclado volta para a corrida depois do pop (digitando, o campo de teclas novo pega o foco sozinho)
    if (abriuCena && mounted && _modoSetas) _foco.requestFocus();
  }

  /// 📖 A abertura do capítulo da pista [p], se ainda não foi vista e "📖 Auto" está ligado. Antes, uma
  /// vez só, o aviso dos capítulos perdidos para quem chega no meio. Devolve (seguir para a corrida?,
  /// abriu alguma cena?): "Ver do começo" abre a galeria e NÃO corre agora.
  Future<(bool, bool)> _aberturaDaHistoria(PistaGt p) async {
    final h = await _historiaPronta();
    if (!mounted) return (false, false);
    final cap = h?.capitulo(p.numero);
    if (h == null || cap == null) return (true, false);
    final vistos = await ProgressoHistoria.vistos();
    final auto = await ProgressoHistoria.auto();
    if (!mounted) return (false, false);
    if (!auto || vistos.contains(ProgressoHistoria.id(p.numero, ParteDoCapitulo.intro))) return (true, false);
    final perdidos = [
      for (var k = 1; k < p.numero; k++)
        if (h.capitulo(k) != null && !vistos.contains(ProgressoHistoria.id(k, ParteDoCapitulo.intro))) k,
    ];
    if (perdidos.isNotEmpty && !await ProgressoHistoria.perdidosAvisado()) {
      await ProgressoHistoria.marcarPerdidosAvisado();
      if (!mounted) return (false, false);
      final escolha = await _comCenaAberta(
          () => abrirCapitulosPerdidos(context, historia: h, ate: p.numero - 1, perdidos: perdidos));
      if (!mounted) return (false, true);
      if (escolha == EscolhaPerdidos.doComeco) {
        _abrirGaleria();
        return (false, true);
      }
    }
    await _abrirCena(cap, ParteDoCapitulo.intro);
    return (mounted, true);
  }

  /// Roda [abrir] (uma rota/diálogo da história) com o campo de teclas da corrida fora do foco.
  Future<T> _comCenaAberta<T>(Future<T> Function() abrir) async {
    if (mounted) setState(() => _cenaAberta = true);
    try {
      return await abrir();
    } finally {
      if (mounted) {
        setState(() {
          _cenaAberta = false;
          _geracaoTeclas++;
        });
      }
    }
  }

  /// Toca a [parte] do capítulo [cap] e, ao voltar, relê o que foi visto. Depois da chegada, relê o
  /// campeonato: a do capítulo 30 assistida até o fim abre o 📖 (o player grava `c30` só ao voltar, depois
  /// de o [_fim] já ter calculado os troféus novos — então ele entra aqui, como troféu novo).
  Future<void> _abrirCena(CapituloHistoria cap, ParteDoCapitulo parte) async {
    _voz.calar();
    await _comCenaAberta(() => abrirCenaDaHistoria(
          context,
          capitulo: cap,
          parte: parte,
          voz: _vozHistoria,
          creditos: parte == ParteDoCapitulo.fim && cap.pista == pistasGtIngles.length,
        ));
    if (!mounted) return;
    await _recarregarVistos();
    if (parte == ParteDoCapitulo.fim && mounted) await _conferirTrofeusDaHistoria();
  }

  Future<void> _conferirTrofeusDaHistoria() async {
    final antes = _campeonato;
    await _carregarCampeonato();
    if (!mounted) return;
    final novos = [
      for (final t in _trofeusDoCurso)
        if (!t.ganhou(_estatisticas, antes) && t.ganhou(_estatisticas, _campeonato) && !_trofeusNovos.contains(t)) t,
    ];
    if (novos.isEmpty) return;
    Sons.toca(Som.fanfarra);
    if (_acabou) setState(() => _trofeusNovos = [..._trofeusNovos, ...novos]);
  }

  /// 📖 Galeria da história (rever capítulos, resumo até aqui).
  Future<void> _abrirGaleria() async {
    final h = _historia;
    if (h == null || !mounted) return;
    Sons.toca(Som.blip);
    await _comCenaAberta(() => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => GaleriaHistoriaPage(
            historia: h,
            pistaMax: _campeonato.pistaMax,
            chegadas: _chegadas,
            voz: _vozHistoria,
          ),
        )));
    if (!mounted) return;
    await _recarregarVistos();
    if (mounted) await _conferirTrofeusDaHistoria();
  }

  /// As pistas com a chegada liberada na galeria: terminadas (com tempo) ou com a chegada já vista.
  Set<int> get _chegadas => {
        for (var n = 1; n <= _pistas.length; n++)
          if (_campeonato.tempoDe(n) != null || _vistos.contains(ProgressoHistoria.id(n, ParteDoCapitulo.fim))) n,
      };

  /// 📖 O botão "📖" do cartão: toca a abertura do capítulo (sem correr).
  Future<void> _reverAbertura(int pista) async {
    final cap = _historia?.capitulo(pista);
    if (cap == null || _abrindoCena) return;
    _abrindoCena = true;
    try {
      Sons.toca(Som.blip);
      await _abrirCena(cap, ParteDoCapitulo.intro);
    } finally {
      _abrindoCena = false;
    }
  }

  /// "📖 Continue a história" / "📖 Rever final" do overlay de fim.
  Future<void> _verChegada(int pista) async {
    final cap = _historia?.capitulo(pista);
    if (cap == null || _abrindoCena || _cenaAberta) return;
    _cancelarChegada();
    _abrindoCena = true;
    try {
      // o resultado termina de gravar antes (moedas, estatísticas, campeonato e troféus já calculados)
      final corrida = _corridaId;
      await _gravandoFim?.future;
      if (!mounted || _corridaId != corrida || !_acabou || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
      await _abrirCena(cap, ParteDoCapitulo.fim);
    } finally {
      _abrindoCena = false;
    }
  }

  /// A chegada abre sozinha [_esperaChegada] depois do resultado (o jogador vê o overlay primeiro), se a
  /// corrida ainda é a mesma, "📖 Auto" está ligado e ela nunca foi vista. Cancelada por [_correr], "Sair",
  /// "Campeonato", "Próxima" e [dispose].
  void _agendarChegada(int pista, int corrida) {
    _cancelarChegada();
    final ficha = _fichaChegada;
    _chegadaAgendada = Timer(_esperaChegada, () => _chegadaSozinha(pista, corrida, ficha));
  }

  void _cancelarChegada() {
    _chegadaAgendada?.cancel();
    _chegadaAgendada = null;
    _fichaChegada++;
  }

  Future<void> _chegadaSozinha(int pista, int corrida, int ficha) async {
    // ... e só com o Turismo à vista: nada de abrir por cima do treino das teimosas ou de outro diálogo/rota
    bool valida() =>
        mounted &&
        ficha == _fichaChegada &&
        _corridaId == corrida &&
        _acabou &&
        !_abrindoCena &&
        !_cenaAberta &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    _chegadaAgendada = null;
    if (!valida()) return;
    final cap = _historia?.capitulo(pista);
    if (cap == null) return;
    final auto = await ProgressoHistoria.auto();
    final vistos = await ProgressoHistoria.vistos();
    if (!auto || vistos.contains(ProgressoHistoria.id(pista, ParteDoCapitulo.fim)) || !valida()) return;
    _abrindoCena = true;
    try {
      await _abrirCena(cap, ParteDoCapitulo.fim);
    } finally {
      _abrindoCena = false;
    }
    if (mounted && _modoSetas) _foco.requestFocus();
  }

  void _alternarHistoriaAuto() {
    Sons.toca(Som.blip);
    setState(() => _historiaAuto = !_historiaAuto);
    ProgressoHistoria.salvarAuto(_historiaAuto);
  }

  /// O fluxo de sempre: tutorial, fantasma, baralho da fase e a corrida na tela.
  Future<void> _montarCorrida(PistaGt p) async {
    final tutorial = !await ProgressoTurismo.tutorialVisto(setas: _modoSetas);
    final fantasma = await ProgressoTurismo.fantasma(p.numero);
    if (!mounted) return;
    // inglês: as palavras das lições (com a tradução); Dart/C#: o vocabulário fixo da pista
    final vocab = BancoArcade.soDigitacao ? BancoArcade.vocabulario(context) : null;
    final pool = vocab == null ? null : p.vocabularioCom(vocab);
    // inglês digitando: a corrida é a próxima fase do baralho (o tamanho = os portais da pista: uma palavra
    // digitada por portal — com duas saídas, a 2ª vem de fora do baralho)
    DeckFase? deck;
    if (vocab != null && pool != null && pool.isNotEmpty && !_modoSetas) {
      final b = _baralho ??= BaralhoFases(
        rnd: math.Random(widget.semente),
        dificeis: BancoArcade.dificeisDoBanco(_palavrasCubit, vocab),
        reenfileirarNaFase: true,
      );
      deck = b.abrirFase(
        fase: ++_corridasIngles,
        pool: pool,
        tamanho: math.max(1, TurismoEngine.portaisDaPista(p)),
        foco: vocab.foco,
      );
    }
    _crono.zerar();
    _errosNaPalavra = 0;
    setState(() {
      _pista = p;
      _deck = deck;
      _engine = TurismoEngine(
        pista: p,
        rnd: math.Random(widget.semente),
        modo: _modoSetas ? ModoControle.setas : ModoControle.digitacao,
        vocabulario: pool,
        traducoes: vocab?.traducoes ?? const {},
        esperaPalavra: true,
        // inglês: sem "tempo esgotado" — quem está aprendendo termina a pista; o tempo vale a medalha
        semLimiteDeTempo: BancoArcade.soDigitacao,
        fonte: deck == null ? null : _baralho,
      );
      _tracado = tracadoDaPista([for (final s in _engine!.segmentos) s.curva],
          comprimento: TurismoEngine.comprimentoSegmento);
      _tutorial = tutorial;
      _fantasma = fantasma;
      _bateuFantasma = false;
      _trofeusNovos = const [];
      // a contagem 3-2-1 só começa com a cena pronta (o loading fica na tela)
      _cenaPronta = !Vista3D.disponivel;
      _esperaCena?.cancel();
      if (!_cenaPronta) _esperaCena = Timer(const Duration(seconds: 60), _cenaFicouPronta);
      _corridaId++;
      _gas = false;
      _freio = false;
      _radio = null;
      _tela = _Tela.corrida;
      _contagem = true;
      _acabou = false;
      _pontuado = false;
      _novoRecorde = false;
      _campeao = false;
      pausado = false;
      _tropecos = _palavrasCubit != null && !_modoSetas ? TropecosDoJogo() : null;
      _avisoTropeco = null;
      _sug = null;
      _vozPortal = null;
      _vozTravada = null;
      _vozGas = null;
    });
  }

  void _cenaFicouPronta() {
    if (!mounted || _cenaPronta) return;
    _esperaCena?.cancel();
    setState(() => _cenaPronta = true);
  }

  void _largada() {
    if (!mounted || _engine == null) return;
    setState(() => _contagem = false);
    _ligarTicker();
    pausarSeEscondido();
    if (_modoSetas) _foco.requestFocus();
  }

  void _voltarAoCampeonato() {
    _cancelarChegada();
    _desligarTicker();
    _publicarParcial();
    Sons.motorParar();
    _voz.calar();
    _crono.zerar();
    _errosNaPalavra = 0;
    setState(() {
      _tela = _Tela.campeonato;
      _engine = null;
      _pista = null;
      _acabou = false;
      _contagem = false;
      pausado = false;
    });
    _carregarCampeonato();
  }

  void _tick(Duration elapsed) {
    var dt = (elapsed - _ultimo).inMicroseconds / 1e6;
    final religado = _religadoEm;
    if (religado != null) {
      // 1º frame depois de (re)ligar: o elapsed recomeçou do zero
      dt = (SchedulerBinding.instance.currentSystemFrameTimeStamp - religado).inMicroseconds / 1e6;
      if (_retomando) dt = math.min(dt, _ultimoDt);
      _religadoEm = null;
    }
    _ultimo = elapsed;
    final e = _engine;
    if (e == null || _tela != _Tela.corrida || _contagem || pausado || _acabou || !mounted) return;
    if (dt > .1) dt = .1;
    if (dt > 0) _ultimoDt = dt;
    final colisoesAntes = e.colisoes;
    final fichasAntes = e.fichasPegas;
    final limposAntes = e.portaisLimpos;
    if (e.porSetas) {
      // sem campo de texto, o foco do teclado tem que ficar na página
      if (!_foco.hasFocus) _foco.requestFocus();
      e.pedais(dt, gas: _gas, freio: _freio);
    }
    final contar = _palavrasCubit != null && !e.porSetas;
    final ordAntes = contar ? e.ordinalDoPortalAtual : 0;
    e.tick(dt);
    if (contar) _contarPortais(e, ordAntes);
    if (e.porSetas && e.correndo && _voz.ativa) _falarPortalSetas(e);
    _drenarPerdas(e);
    _relogio += dt;
    _vista.enviar();
    _desdeHud += dt;
    _quadroPar = !_quadroPar;
    final aconteceu = e.colisoes > colisoesAntes || e.fichasPegas > fichasAntes || !e.correndo;
    if ((Vista3D.disponivel ? _desdeHud >= .03 : _quadroPar) || aconteceu) {
      _desdeHud = 0;
      setState(() {});
    }
    if (e.portaisLimpos > limposAntes) Sons.toca(Som.turbo);
    if (e.colisoes > colisoesAntes) Sons.toca(Som.explosao);
    if (e.fichasPegas > fichasAntes) Sons.toca(Som.blip);
    // o ronco sintetizado só entra sem o 3D (que toca o motor gravado)
    if (!Vista3D.disponivel && _relogio - _ultimoRonco > .08) {
      _ultimoRonco = _relogio;
      Sons.motorRonco(.06 + e.fracaoVel * .94);
    }
    if (!e.correndo) _fim();
  }

  /// Inglês: os portais que o carro acabou de cruzar — palavra digitada = vista; portal perdido =
  /// erro em cada palavra dele.
  void _contarPortais(TurismoEngine e, int ordAntes) {
    final ordDepois = e.ordinalDoPortalAtual;
    for (var k = ordAntes; k < ordDepois && k < e.portais.length; k++) {
      final p = e.portais[k];
      if (p.livre) {
        _placar.viu(p.palavras[p.digitado]);
        _tropecos?.vista(p.palavras[p.digitado]);
      } else {
        p.palavras.forEach(_placar.errou);
      }
    }
  }

  void _tecla(String ch) {
    final e = _engine;
    if (e == null || _contagem || pausado || _acabou || ch.trim().isEmpty) return;
    final multAntes = e.multiplicador;
    final portalAntes = e.portalParaDigitar;
    final gasAntes = portalAntes == null ? e.palavraGas : null;
    final r = e.teclar(ch);
    if (r == TeclaGt.completou && gasAntes != null && _palavrasCubit != null) {
      _placar.viu(gasAntes);
      _tropecos?.vista(gasAntes);
    }
    if (_baralho != null && e.fonte != null) _cronometrar(r, portalAntes, gasAntes);
    if (r == TeclaGt.completou || r == TeclaGt.errou) _drenarPerdas(e);
    if (_voz.ativa && (r == TeclaGt.avancou || r == TeclaGt.completou)) _falarAlvoNovo(e);
    setState(() {});
    switch (r) {
      case TeclaGt.avancou:
        Sons.toca(Som.waka);
      case TeclaGt.completou:
        Sons.toca(Som.turbo);
        if (e.multiplicador > multAntes) Sons.toca(Som.combo);
      case TeclaGt.errou:
        Sons.toca(Som.erro);
      case TeclaGt.nada:
        break;
    }
  }

  /// Inglês (baralho por fase): o relógio da palavra liga na 1ª tecla certa; cada tecla errada até ela sair
  /// conta pra ela; ao completar, o baralho fica sabendo (erros e ms por letra) — a errada volta como
  /// combustível ainda nesta corrida e, com a lenta, na frente da próxima. [portal]/[gas]: o alvo de antes
  /// da tecla (a palavra completada é a de combustível, ou a que o portal marcou).
  void _cronometrar(TeclaGt r, Portal? portal, String? gas) {
    switch (r) {
      case TeclaGt.avancou:
        _crono.iniciar();
      case TeclaGt.errou:
        _errosNaPalavra++;
      case TeclaGt.completou:
        final w = gas ?? (portal != null && portal.digitado >= 0 ? portal.palavras[portal.digitado] : null);
        // palavra de 1 letra: o relógio nem ligou (ms null)
        final ms = _crono.msPorLetra(w ?? '');
        if (w != null) _baralho?.registrar(w, erros: _errosNaPalavra, msPorLetra: ms);
        _errosNaPalavra = 0;
        // duas saídas: fugir da 🔁 pela outra faixa não livra a palavra — volta como combustível
        if (gas == null && portal != null && portal.digitado >= 0) {
          for (var i = 0; i < portal.palavras.length; i++) {
            if (i != portal.digitado && portal.ehRevisao(i)) _baralho?.devolver(portal.palavras[i]);
          }
        }
      case TeclaGt.nada:
        break;
    }
  }

  /// Inglês: o que o motor anotou de tropeço ([TurismoEngine.perdas]) vai para os tropeços da corrida; na
  /// 2ª escapada de uma palavra, o aviso na pista.
  void _drenarPerdas(TurismoEngine e) {
    final t = _tropecos;
    if (t == null || e.perdas.isEmpty) return;
    for (final x in e.perdas.entries) {
      t.falha(x.key, x.value);
    }
    e.perdas.clear();
    final w = e.ultimaPerdida;
    final a = w == null ? null : t.aviso(w, pode: !_contagem && !pausado);
    if (a != null) setState(() => _avisoTropeco = BancoArcade.textoAviso(a, t.vezes(a)));
  }

  /// Inglês: a oferta "treinar só elas" da tela de fim (uma por corrida), se a política deixar.
  void _oferecerTeimosas() {
    final cubit = _palavrasCubit, t = _tropecos;
    if (cubit == null || t == null || t.somas.isEmpty || _sug != null) return;
    final sug = cubit.sugestao(LocalSugestao.fimDeJogo, daSessao: BancoArcade.daSessao(cubit, t));
    if (sug == null) return;
    cubit.marcarMostrada();
    _sug = sug;
  }

  Widget _ofertaFim(SugestaoTeimosas s, PistaGt pista) => OfertaTeimosasFim(
        sugestao: s,
        onTreinar: () {
          _cancelarChegada(); // a chegada automática não abre por cima do treino
          treinarTeimosas(context, s.palavras, origem: 'turismo').then((_) {
            if (mounted) setState(() => _sug = null);
          });
        },
        onRevanche: () {
          jogarComTeimosas(context, s.palavras, dentroDoJogo: true);
          _correr(pista);
        },
        onAgoraNao: _palavrasCubit?.adiar,
      );

  /// Inglês: a linha das palavras anotadas na pausa (null sem nada).
  Widget? _anotadas() {
    final t = BancoArcade.linhaAnotadas(_tropecos);
    return t == null ? null : LinhaAnotadas(t);
  }

  Future<void> _fim() async {
    if (_engine == null || _pista == null || _acabou) return;
    final gravando = _gravandoFim = Completer<void>();
    try {
      await _fimCorrida();
    } finally {
      if (!gravando.isCompleted) gravando.complete();
    }
  }

  Future<void> _fimCorrida() async {
    final e = _engine;
    final pista = _pista;
    if (e == null || pista == null || _acabou) return;
    _desligarTicker();
    Sons.motorParar();
    _voz.calar();
    _crono.zerar();
    _errosNaPalavra = 0;
    // inglês: os tropeços vão para o banco já (antes das esperas) e a oferta entra na tela de fim
    _drenarPerdas(e);
    _placar.enviar(_palavrasCubit,
        fonte: FonteErro.turismo, tropecos: _tropecos, lentas: _baralho?.tirarLentasParaBanco() ?? const {});
    _oferecerTeimosas();
    setState(() {
      _acabou = true;
      pausado = false;
      _campeao = e.terminou && pista.numero == _pistas.length && e.medalha > 0;
      _moedasCorrida = e.moedas + moedasPorMedalha[e.medalha];
      _radio = null;
    });
    _pedirDebrief(e);
    if (e.terminou) {
      Sons.toca(e.medalha == 3 ? Som.fanfarra : Som.fase);
      await ProgressoTurismo.registrar(
        pista: pista.numero,
        medalha: e.medalha,
        tempo: e.tempoFinal!,
        totalPistas: _pistas.length,
        chegarLibera: e.semLimiteDeTempo,
      );
      // 👻 a melhor volta vira (ou continua sendo) o fantasma da pista
      final antes = _fantasma;
      final bateu = antes == null || e.tempoFinal! < antes.tempo;
      if (bateu) await ProgressoTurismo.salvarFantasma(pista.numero, VoltaFantasma(e.tempoFinal!, e.gravacao));
      _bateuFantasma = antes != null && bateu;
    } else {
      Sons.toca(Som.defesa);
    }
    // 📊 estatísticas e 🏆 troféus que abriram com esta corrida
    final statsAntes = _estatisticas;
    final statsDepois = statsAntes.somar(e, bateuFantasma: _bateuFantasma);
    await ProgressoTurismo.salvarEstatisticas(statsDepois);
    final campAntes = _campeonato;
    if (_moedasCorrida > 0) await ProgressoTurismo.ganharMoedas(_moedasCorrida);
    if (!_pontuado) {
      _pontuado = true;
      // 🌐 o ranking vai pela rede (Firestore, sem prazo — offline a escrita fica pendente): corre em paralelo
      // e não segura o campeonato, os troféus nem a chegada; o "novo recorde" acende quando ele responder
      final corrida = _corridaId;
      unawaited(_ranking?.arcadeJogado('turismo', e.pontosFinais).then((recorde) {
        if (mounted && recorde && _corridaId == corrida) setState(() => _novoRecorde = true);
      }, onError: (Object _) {}));
    }
    await _carregarCampeonato();
    if (!mounted) return;
    setState(() {
      _estatisticas = statsDepois;
      _trofeusNovos = [
        for (final t in _trofeusDoCurso)
          if (!t.ganhou(statsAntes, campAntes) && t.ganhou(statsDepois, _campeonato)) t,
      ];
    });
    if (_trofeusNovos.isNotEmpty) Sons.toca(Som.fanfarra);
    // 📖 a chegada só depois de TODA a persistência local (registro, fantasma, estatísticas, moedas,
    // campeonato e troféus; o ranking segue em paralelo): abre sozinha 1,2 s depois, por um timer cancelável
    // — nunca um await da cena aqui
    if (e.terminou && _historiaAtiva && _historia?.capitulo(pista.numero) != null) {
      _agendarChegada(pista.numero, _corridaId);
    }
  }

  /// 🎧 A engenheira (Gemini, ou a de bolso) comenta a corrida que acabou.
  Future<void> _pedirDebrief(TurismoEngine e) async {
    final id = _corridaId;
    final carro = carrosGt.firstWhere((c) => c.id == _carro, orElse: () => carrosGt.first).nome;
    final texto = await (widget.engenheiro ?? EngenheiroGt()).debrief(TelemetriaGt.de(e, carro: carro));
    if (mounted && _corridaId == id) setState(() => _radio = texto);
  }

  String _seg(double s) => '${s.toStringAsFixed(1)}s';

  // ---------- telas ----------

  @override
  Widget build(BuildContext context) {
    final e = _engine;
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: Focus(
        focusNode: _foco,
        onKeyEvent: (_, ev) => _teclaGlobal(ev),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              // a corrida merece a tela: até 1400 px no desktop (o campeonato
              // continua em coluna de leitura)
              constraints: BoxConstraints(maxWidth: _tela == _Tela.corrida ? 1400 : 920),
              child: Stack(children: [
                if (_tela == _Tela.campeonato || e == null) _telaCampeonato() else _telaCorrida(e),
                if (_tutorial && _pista != null)
                  TutorialTurismo(porSetas: _modoSetas, onLargar: _fecharTutorial)
                else if (_contagem && _cenaPronta && _pista != null)
                  ContagemRegressiva(
                    onFim: _largada,
                    legenda: '${AmbienteTurismo.de(_pista!.tema).emoji} ${_pista!.nome} — '
                        '${_modoSetas ? 'segure ↑ pra acelerar' : 'digite pra acelerar'}',
                  ),
                // inglês: o que esta fase traz (novas e as que voltam pra revisar 🔁)
                if (!_tutorial && _contagem && _cenaPronta && _pista != null && _deck != null)
                  LinhaFase.naContagem('Pista ${_pista!.numero} · ${_deck!.resumo()}'),
                if (pausado) PausaOverlay(onContinuar: retomar, onSair: _voltarAoCampeonato, extra: _anotadas()),
                if (_acabou && e != null && _pista != null) _fimDaCorrida(e, _pista!),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _telaCampeonato() {
    return ListView(
      // a grade da temporada é um filho só, bem abaixo das opções: no celular ela ficava fora do cache
      // (sem montar) e o "rola até a pista mais longe" (D20) não achava o cartão. Monta tudo de uma vez.
      cacheExtent: 100000,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
      children: [
        CabecalhoJogo(
          rotulo: 'ARCADE · DIGITAÇÃO',
          titulo: '🏎️ ${BancoArcade.linguagem} Turismo',
          chips: [
            ChipPlacar('MOEDAS', '🪙 ${_campeonato.moedas}', cor: Mixart.brand),
            ChipPlacar('MEDALHAS', '${_campeonato.totalMedalhas}/${_pistas.length}'),
            ChipPlacar('OUROS', '${_campeonato.ouros}'),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Mixart.brandSub,
            border: Border.all(color: Mixart.brandDim),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Text(
            BancoArcade.soDigitacao
                ? 'Campeonato de ${_pistas.length} pistas em 3D com as palavras das SUAS lições — a '
                    'tradução aparece embaixo. Cada portal marca a faixa LIVRE com uma palavra: digite-a '
                    'pra entrar na faixa e passar limpo — o tráfego das outras faixas arranca quando você '
                    'chega, e encostar nele é batida. Toda tecla certa acelera; parar de digitar é ir '
                    'parando. Passe por cima das fichas (hi, yes, wow…) na faixa livre pra ganhar 🪙 '
                    'moedas, que compram os carros da garagem. '
                    '${_historiaAtiva ? 'Chegue ao fim para liberar a próxima pista e o próximo capítulo' : 'Chegue ao fim para liberar a próxima pista'}'
                    ' — o relógio vale 🥇 ouro, 🥈 prata ou 🥉 bronze. Cada corrida traz palavras novas (e mais '
                    'delas a cada pista); as que você errar ou demorar voltam pra revisão 🔁. Esc pausa.'
                :
            'Campeonato de ${_pistas.length} pistas em 3D. Cada portal marca a faixa LIVRE '
            'com uma palavra: digite-a pra entrar na faixa e passar limpo — o tráfego das '
            'outras faixas arranca quando você chega, e encostar nele é batida. Toda tecla '
            'certa acelera; parar de digitar é ir parando. Passe por cima das fichas de '
            'programação (=>, { }, async…) na faixa livre pra ganhar 🪙 moedas, que compram '
            'os carros da garagem. Feche a pista no tempo pra liberar a próxima: 🥇 ouro, '
            '🥈 prata ou 🥉 bronze. Esc pausa.',
            style: Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.55),
          ),
        ),
        const SizedBox(height: 14),
        _seletorModo(),
        const SizedBox(height: 18),
        _garagem(),
        const SizedBox(height: 18),
        _trofeus(),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (context, box) {
          final colunas = box.maxWidth >= 640 ? 2 : 1;
          final largura = (box.maxWidth - (colunas - 1) * 12) / colunas;
          Widget grade(Iterable<PistaGt> pistas) => Wrap(spacing: 12, runSpacing: 12, children: [
                for (final p in pistas) SizedBox(width: largura, child: _cartaoPista(p)),
              ]);
          // Dart/C#: as 10 de sempre, sem cabeçalho
          if (_pistas.length <= pistasClassicas) return grade(_pistas);
          // inglês: 3 temporadas (a 1ª sempre aberta; a 2ª e a 3ª recolhem no cabeçalho)
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < _temporadas.length; i++)
              if (_temporadas[i].de <= _pistas.length) ...[
                if (i > 0) const SizedBox(height: 18),
                _cabecalhoTemporada(i),
                if (!_temporadasRecolhidas.contains(i)) ...[
                  const SizedBox(height: 10),
                  grade(_pistas.where((p) => p.numero >= _temporadas[i].de && p.numero <= _temporadas[i].ate)),
                ],
              ],
          ]);
        }),
        const SizedBox(height: 18),
        Text(
          'Créditos 3D · Carros: Porsche 911 (930) Turbo 1975, Nissan Skyline R34 GT-R, Honda NSX 1990, '
          'Mazda Miata MX-5 NA e Toyota Corolla AE86 Trueno, por Lexyc16 (sketchfab.com/Lexyc16), '
          'licença CC BY 4.0 · Céus HDRI, texturas e postes: Poly Haven (CC0) · Som do motor: "Car Engine Loop" '
          'por qubodup (OpenGameArt), CC BY 3.0 · Som da batida: qubodup (CC0) · Músicas: Kevin MacLeod '
          '(incompetech.com), licença CC BY 4.0 · Fachadas dos prédios: ambientCG (CC0) · Rochas, arbustos e '
          'árvores: Poly Haven (CC0) · Pneu cantando: audible-edge (OpenGameArt, CC BY 3.0) · '
          'Engenheira de pista: Gemini · Motor 3D: three.js (MIT).'
          '${BancoArcade.soDigitacao ? ' · História e desenhos: originais do Paclingo · Vozes da história: voz do sistema.' : ''}',
          style: Mixart.ui(size: 10.5, color: Mixart.textFaint).copyWith(height: 1.5),
        ),
      ],
    );
  }

  /// Cabeçalho de uma temporada do inglês: nome, faixa de pistas e medalhas; a 2ª e a 3ª recolhem.
  Widget _cabecalhoTemporada(int i) {
    final t = _temporadas[i];
    final ate = math.min(t.ate, _pistas.length);
    final medalhas = _campeonato.medalhasEntre(t.de, ate);
    final recolhida = _temporadasRecolhidas.contains(i);
    final titulo = Row(children: [
      Expanded(
        child: Text('${t.nome.toUpperCase()} (${t.de}–$ate)',
            style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 2)),
      ),
      Text('🏅 $medalhas/${ate - t.de + 1}', style: Mixart.ui(size: 11, color: Mixart.textMuted)),
      if (i > 0) ...[
        const SizedBox(width: 6),
        Icon(recolhida ? Icons.expand_more : Icons.expand_less, size: 18, color: Mixart.textMuted),
      ],
    ]);
    final caixa = Container(
      key: Key('turismo-temporada-${i + 1}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Mixart.brandDim)),
      ),
      child: titulo,
    );
    if (i == 0) return Semantics(header: true, child: caixa);
    return Semantics(
      header: true,
      button: true,
      expanded: !recolhida,
      label: 'temporada ${t.nome}',
      child: InkWell(
        onTap: () => setState(() => recolhida ? _temporadasRecolhidas.remove(i) : _temporadasRecolhidas.add(i)),
        child: caixa,
      ),
    );
  }

  /// ⌨️ Digitação (o modo de aprender) ou 🎮 Setas (corrida clássica).
  Widget _seletorModo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('COMO DIRIGIR',
          style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.textMuted)
              .copyWith(letterSpacing: 2)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _opcaoModo(false, '⌨️ Digitação', 'as palavras são o volante — e treinam você'),
        _opcaoModo(true, '🎮 Setas', '← → trocam de faixa · ↑ acelera · ↓ freia'),
      ]),
      const SizedBox(height: 14),
      Text('⚙️ OPÇÕES',
          style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.textMuted)
              .copyWith(letterSpacing: 2)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        _botaoMusica(),
        if (BancoArcade.soDigitacao)
          BotaoVozJogo(key: const Key('arcade-voz'), onTap: _alternarVoz, compacto: false),
        // 📖 a galeria da história e se as cenas tocam sozinhas
        if (_historiaAtiva && _historia != null)
          KeyedSubtree(
            key: const Key('turismo-historia'),
            child: _botaoPilula('📖 História', ativo: true, rotulo: 'abrir a história', onTap: _abrirGaleria),
          ),
        if (_historiaAtiva)
          KeyedSubtree(
            key: const Key('turismo-historia-auto'),
            child: _botaoPilula(
              _historiaAuto ? '📖 Auto' : '📖 Manual',
              ativo: _historiaAuto,
              rotulo: _historiaAuto
                  ? 'história automática: as cenas tocam sozinhas'
                  : 'história manual: as cenas só pelo botão 📖',
              onTap: _alternarHistoriaAuto,
            ),
          ),
        _botaoPilula(
          '${_tremor ? '📳' : '🚫'} Tremor ${_tremor ? 'ligado' : 'desligado'}',
          ativo: _tremor,
          rotulo: 'tremor de câmera ${_tremor ? 'ligado' : 'desligado'}',
          onTap: _alternarTremor,
        ),
        Text('Qualidade 3D:', style: Mixart.ui(size: 11, color: Mixart.textMuted)),
        for (final q in qualidadesGt)
          _botaoPilula(nomesQualidade[q]!,
              ativo: _qualidade == q, rotulo: 'qualidade ${nomesQualidade[q]}', onTap: () => _escolherQualidade(q)),
      ]),
      const SizedBox(height: 8),
      Text(
        'Câmera: ${nomesCamera[_camera]} — na corrida, o botão 🎥 (ou a tecla C no modo setas) troca. '
        'Qualidade Alta usa céus 2k e texturas 1k (carrega mais, fica mais bonito); Auto escolhe Leve em celular.',
        style: Mixart.ui(size: 11, color: Mixart.textFaint),
      ),
    ]);
  }

  Widget _opcaoModo(bool setas, String titulo, String legenda) {
    final escolhido = _modoSetas == setas;
    return Semantics(
      button: true,
      selected: escolhido,
      label: 'modo $titulo',
      child: Material(
        color: escolhido ? Mixart.brandSub : Mixart.surface,
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          onTap: () => _escolherModo(setas),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                  color: escolhido ? Mixart.brand : Mixart.border, width: escolhido ? 1.8 : 1),
              borderRadius: BorderRadius.circular(Mixart.radiusMd),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: Mixart.display(size: 13, color: escolhido ? Mixart.brand : Mixart.text)),
              Text(legenda, style: Mixart.ui(size: 10.5, color: Mixart.textMuted)),
            ]),
          ),
        ),
      ),
    );
  }

  /// Pílula de opção (liga/desliga ou escolha).
  Widget _botaoPilula(String texto, {required bool ativo, required String rotulo, required VoidCallback onTap}) {
    return Semantics(
      button: true,
      selected: ativo,
      label: rotulo,
      child: Material(
        color: ativo ? Mixart.brandSub : Mixart.surface,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: ShapeDecoration(
              shape: StadiumBorder(side: BorderSide(color: ativo ? Mixart.brand : Mixart.border)),
            ),
            child: Text(texto,
                style: Mixart.ui(size: 11, weight: FontWeight.w700, color: ativo ? Mixart.brand : Mixart.text)),
          ),
        ),
      ),
    );
  }

  /// 🎸 Liga/desliga a trilha de rock da fase.
  Widget _botaoMusica() {
    return Semantics(
      button: true,
      toggled: _musica,
      label: 'música ${_musica ? 'ligada' : 'desligada'}',
      child: Material(
        color: _musica ? Mixart.brandSub : Mixart.surface,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: _alternarMusica,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: ShapeDecoration(
              shape: StadiumBorder(side: BorderSide(color: _musica ? Mixart.brand : Mixart.border)),
            ),
            child: Text('🎸 Rock ${_musica ? 'ligado' : 'desligado'}',
                style: Mixart.ui(size: 11, weight: FontWeight.w700, color: _musica ? Mixart.brand : Mixart.text)),
          ),
        ),
      ),
    );
  }

  /// Botão 🎥 do HUD: gira entre as câmeras.
  Widget _botaoCamera() {
    return Semantics(
      button: true,
      label: 'câmera: ${nomesCamera[_camera]}',
      child: Material(
        color: Mixart.surface,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: _proximaCamera,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: ShapeDecoration(
              shape: StadiumBorder(side: BorderSide(color: Mixart.border)),
            ),
            child: Text('🎥 ${nomesCamera[_camera]}', style: Mixart.ui(size: 11, weight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  /// 🏆 Troféus e 📊 estatísticas acumuladas.
  Widget _trofeus() {
    final s = _estatisticas;
    final trofeus = _trofeusDoCurso;
    final ganhos = trofeus.where((t) => t.ganhou(s, _campeonato)).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TROFÉUS · $ganhos/${trofeus.length}',
          style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.textMuted)
              .copyWith(letterSpacing: 2)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ChipPlacar('CORRIDAS', '${s.corridas}'),
        ChipPlacar('KM', s.km.toStringAsFixed(1)),
        ChipPlacar('PALAVRAS', '${s.palavras}'),
        ChipPlacar('FICHAS', '${s.fichas}'),
        ChipPlacar('VOLTAS LIMPAS', '${s.voltasLimpas}'),
        ChipPlacar('MELHOR COMBO', '${s.melhorCombo}'),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in trofeus) _cartaoTrofeu(t, t.ganhou(s, _campeonato)),
      ]),
    ]);
  }

  Widget _cartaoTrofeu(TrofeuGt t, bool ganhou) {
    return Semantics(
      label: 'troféu ${t.nome} ${ganhou ? 'conquistado' : 'bloqueado'}',
      child: Opacity(
        opacity: ganhou ? 1 : .5,
        child: Container(
          width: 168,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: ganhou ? Mixart.brandSub : Mixart.surface,
            border: Border.all(color: ganhou ? Mixart.brand : Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Row(children: [
            Text(ganhou ? t.emoji : '🔒', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.nome, style: Mixart.display(size: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(t.como, style: Mixart.ui(size: 10, color: Mixart.textMuted), maxLines: 2),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  /// A garagem: escolha do carro (modelo 3D real na corrida).
  Widget _garagem() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('GARAGEM · 🪙 ${_campeonato.moedas} moedas',
          style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.textMuted)
              .copyWith(letterSpacing: 2)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final c in carrosGt) _cartaoCarro(c),
      ]),
      if (_avisoGaragem.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(_avisoGaragem, style: Mixart.ui(size: 11.5, weight: FontWeight.w600, color: Mixart.brand)),
      ],
    ]);
  }

  Widget _cartaoCarro(CarroGt c) {
    final meu = _campeonato.temCarro(c.id);
    final escolhido = _carro == c.id;
    final daPra = meu || _campeonato.moedas >= c.preco;
    return Material(
      color: Mixart.surface,
      borderRadius: BorderRadius.circular(Mixart.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        onTap: () => _escolherCarro(c.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
                color: escolhido ? Mixart.brand : Mixart.border, width: escolhido ? 1.8 : 1),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Opacity(
            opacity: meu ? 1 : (daPra ? .85 : .55),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(escolhido ? '🏎️' : (meu ? '🚗' : '🔒'), style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              // celular 360: o "🪙 420 moedas" quebra a linha em vez de vazar do cartão
              Flexible(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.nome, style: Mixart.display(size: 13)),
                  Text(
                    meu ? c.apelido : '${c.apelido} · 🪙 ${c.preco} moedas${daPra ? ' — toque pra comprar' : ''}',
                    style: Mixart.ui(size: 10.5, color: daPra && !meu ? Mixart.brand : Mixart.textMuted),
                  ),
                ]),
              ),
              if (escolhido) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle, size: 16, color: Mixart.brand),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _cartaoPista(PistaGt p) {
    final liberada = _campeonato.liberada(p.numero);
    final medalha = _campeonato.medalhaDe(p.numero);
    final tempo = _campeonato.tempoDe(p.numero);
    final mundo = AmbienteTurismo.de(p.tema);
    // 📖 o capítulo da pista (só nas liberadas: o título não adianta a história)
    final cap = liberada && _historiaAtiva ? _historia?.capitulo(p.numero) : null;
    return Opacity(
      key: p.numero == _campeonato.pistaMax ? _chaveCartaoMax : null,
      opacity: liberada ? 1 : .55,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: medalha == 3 ? Mixart.brand : Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Mixart.surfaceHi, Mixart.surface],
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: liberada ? Mixart.brand : Mixart.surfaceHi,
                shape: BoxShape.circle,
              ),
              child: Text('${p.numero}',
                  style: Mixart.display(size: 15, color: liberada ? Mixart.onBrand : Mixart.textMuted)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.nome, style: Mixart.display(size: 15.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  '${mundo.emoji} ${mundo.nome} · ${p.dificuldade} · '
                  '${(p.distancia / 1000).toStringAsFixed(1)} km · '
                  '${BancoArcade.soDigitacao ? 'bronze até' : 'limite'} ${p.tempoLimite.round()}s',
                  style: Mixart.ui(size: 11, color: Mixart.textMuted),
                ),
                if (p.tituloMusica.isNotEmpty)
                  Text('🎸 ${p.tituloMusica}', style: Mixart.ui(size: 10.5, color: Mixart.textFaint)),
                if (cap != null)
                  Text('📖 Chapter ${cap.pista} · ${cap.titulo.en}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mixart.ui(size: 11, weight: FontWeight.w600, color: Mixart.brand)),
              ]),
            ),
            const SizedBox(width: 8),
            Column(children: [
              Text(emojisMedalha[medalha], style: const TextStyle(fontSize: 24)),
              if (tempo != null)
                Text(_seg(tempo), style: Mixart.mono(size: 10.5, color: Mixart.textMuted)),
            ]),
          ]),
          const SizedBox(height: 10),
          if (liberada)
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (cap != null) ...[
                Tooltip(
                  message: 'Ver a abertura do capítulo ${cap.pista} (sem correr)',
                  child: OutlinedButton(
                    key: Key('turismo-capitulo-${p.numero}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Mixart.brand,
                      side: BorderSide(color: Mixart.brandDim),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      minimumSize: const Size(44, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    onPressed: () => _reverAbertura(p.numero),
                    child: Semantics(
                      label: 'abertura do capítulo ${cap.pista}',
                      excludeSemantics: true,
                      child: const Text('📖', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Mixart.brand,
                  foregroundColor: Mixart.onBrand,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  textStyle: Mixart.ui(size: 12.5, weight: FontWeight.w700),
                ),
                onPressed: () => _correr(p),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(medalha > 0 ? 'Correr de novo' : 'Correr'),
              ),
            ])
          else
            Text('🔒 vença a pista ${p.numero - 1} pra liberar',
                style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
        ]),
      ),
    );
  }

  Widget _telaCorrida(TurismoEngine e) {
    final pista = _pista!;
    final urgente = !e.semLimiteDeTempo && e.tempoRestante <= 10;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: CabecalhoJogo(
          rotulo: 'PISTA ${pista.numero}/${_pistas.length} · ${pista.dificuldade.toUpperCase()}',
          titulo: '🏎️ ${pista.nome}',
          chips: [
            // inglês: o tempo corre pra frente, com a melhor medalha que ainda dá
            if (e.semLimiteDeTempo)
              ChipPlacar('TEMPO', '${_seg(e.tempo)} ${emojisMedalha[pista.medalha(e.tempo)]}')
            else
              ChipPlacar('TEMPO', _seg(e.tempoRestante), cor: urgente ? Mixart.danger : null),
            _chipPulsante(e.moedas, ChipPlacar('MOEDAS', '🪙 ${e.moedas}', cor: Mixart.brand)),
            ChipPlacar('PALAVRAS', '${e.palavras}'),
            ChipPlacar('COMBO', e.multiplicador > 1 ? 'x${e.multiplicador}' : '${e.combo}/5',
                cor: e.multiplicador > 1 ? Mixart.brand : null),
            if (e.porSetas) ChipPlacar('PORTAIS', '${e.portaisLimpos}') else ChipPlacar('ERROS', '${e.erros}'),
            if (_fantasma != null) _chipFantasma(e),
            // 🔊 junto dos chips (no celular, a linha do 🎥 e da pausa não tem espaço)
            // (nas setas também: lá a palavra do portal é falada quando ele vira o alvo)
            if (BancoArcade.soDigitacao) BotaoVozJogo(key: const Key('arcade-voz'), onTap: _alternarVoz),
          ],
          acao: Row(mainAxisSize: MainAxisSize.min, children: [
            _botaoCamera(),
            const SizedBox(width: 8),
            BotaoPausa(onTap: podePausar ? pausar : null),
          ]),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Stack(children: [
            Positioned.fill(
              child: Vista3D(
                key: ValueKey('vista3d-$_corridaId'),
                engine: e,
                relogio: _relogio,
                carro: _carro,
                trafego: [for (final c in carrosGt) if (c.id != _carro) c.id],
                som: Sons.ligado,
                pausado: pausado,
                camera: _camera,
                musica: _musica,
                qualidade: _qualidade,
                tremor: _tremor,
                fantasma: _fantasma,
                onPronto: _cenaFicouPronta,
                controlador: _vista,
              ),
            ),
            // os overlays sobre a vista 3D ficam juntos (uma camada só por cima do canvas do three);
            // a barra tem camada própria: só repinta quando a bolinha anda um pixel ou o km muda
            Positioned(left: 12, top: 12, right: 136, child: RepaintBoundary(child: _barraProgresso(e))),
            Positioned(
              right: 12,
              top: 12,
              child: Minimapa(
                tracado: _tracado,
                posicao: e.posicao,
                comprimentoSegmento: TurismoEngine.comprimentoSegmento,
              ),
            ),
            if (_avisoTropeco != null) AvisoArcade(_avisoTropeco!, top: 56, direita: 136),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: e.porSetas ? _cartaoSetas(e) : _cartaoPalavra(e),
      ),
      if (e.porSetas)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: BotoesSetas(
            gas: _gas,
            freio: _freio,
            onVirar: _virar,
            onGas: (v) => setState(() => _gas = v),
            onFreio: (v) => setState(() => _freio = v),
          ),
        )
      else
        // 📖 com um desenho por cima, o campo invisível não pode pedir o foco de volta (roubaria o
        // teclado do player); quando o desenho fecha, um campo novo nasce com autofocus
        ExcludeFocus(
          excluding: _cenaAberta,
          child: CampoTeclas(key: ValueKey('turismo-teclas-$_geracaoTeclas'), onChar: _tecla),
        ),
    ]);
  }

  /// Dá um pulo quando o valor muda (a moeda recém-pega "chega" no placar).
  Widget _chipPulsante(int valor, Widget chip) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('pulso-$valor'),
      tween: Tween(begin: valor == 0 ? 1.0 : 1.45, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(scale: t, child: child),
      child: chip,
    );
  }

  /// 👻 Quantos segundos à frente (verde) ou atrás (vermelho) do fantasma.
  Widget _chipFantasma(TurismoEngine e) {
    final f = _fantasma!;
    final delta = e.tempo - f.tempoEm(e.posicao);
    final naFrente = delta <= 0;
    return ChipPlacar(
      '👻 FANTASMA',
      '${naFrente ? '−' : '+'}${delta.abs().toStringAsFixed(1)}s',
      cor: naFrente ? const Color(0xFF57C765) : Mixart.danger,
    );
  }

  Widget _barraProgresso(TurismoEngine e) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCC10131A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(children: [
        Text('${(e.posicao / 1000).toStringAsFixed(2)} km',
            style: Mixart.mono(size: 11, color: Colors.white)),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 12,
            child: LayoutBuilder(builder: (context, box) {
              // pixel inteiro: a bolinha só repinta quando anda de verdade
              final x = (e.progresso * (box.maxWidth - 10)).floorToDouble();
              return Stack(children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 5,
                  child: Container(height: 2, color: Colors.white.withValues(alpha: .35)),
                ),
                Positioned(
                  left: x,
                  top: 1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Mixart.brand,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Mixart.brandDim, blurRadius: 6)],
                    ),
                  ),
                ),
              ]);
            }),
          ),
        ),
        const SizedBox(width: 8),
        const Text('🏁', style: TextStyle(fontSize: 12)),
      ]),
    );
  }

  /// Modo setas: a faixa livre do próximo portal, a sua, e os controles.
  Widget _cartaoSetas(TurismoEngine e) {
    final p = e.portalAtual;
    final proximo = e.proximoPortal;
    final livres = p == null ? '' : p.faixas.map((f) => _setas[f]).join('  ou  ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: p != null ? Mixart.brandDim : Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(children: [
        Semantics(
          label: p == null ? 'reta final' : 'faixa livre: $livres',
          excludeSemantics: true,
          child: Text(
            p == null ? '🏁 RETA FINAL' : 'FAIXA LIVRE  $livres',
            style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          p == null
              ? 'segure ↑ até a bandeirada'
              : '${p.palavras.first}${_entreParenteses(e, p.palavras.first)}  ·  portal em ${(p.z - e.posicao).clamp(0, 9999).round()} m'
                  '${proximo == null ? '' : '  ·  a seguir: ${_setas[proximo.faixas.first].substring(0, 1)}'}',
          style: Mixart.mono(size: 14, color: Mixart.textMuted),
        ),
        const SizedBox(height: 8),
        Text(
          'sua faixa: ${_setas[e.faixa]}   ·   ← → trocam de faixa · ↑ acelera · ↓ freia · C câmera',
          style: Mixart.ui(size: 11, color: Mixart.textFaint),
        ),
      ]),
    );
  }

  Widget _cartaoPalavra(TurismoEngine e) {
    final p = e.portalParaDigitar;
    final gas = e.palavraGas;
    final atual = e.portalAtual;
    final proximo = e.proximoPortal;
    Widget aSeguir() => proximo == null
        ? const SizedBox.shrink()
        : Row(mainAxisSize: MainAxisSize.min, children: [
            Text('  ·  a seguir: ', style: Mixart.ui(size: 11, color: Mixart.textFaint)),
            if (proximo.ehRevisao(0)) ...[const MarcaRevisao(), const SizedBox(width: 4)],
            Text('${_setas[proximo.faixas.first].substring(0, 1)} ${proximo.palavras.first}',
                style: Mixart.mono(size: 12, color: Mixart.textMuted)),
            if (e.traducao(proximo.palavras.first) != null)
              Text(_entreParenteses(e, proximo.palavras.first),
                  style: Mixart.ui(size: 10, weight: FontWeight.w600, color: Mixart.textFaint)),
          ]);
    // inglês: as linhas de baixo (com as traduções) encolhem em vez de vazar no celular
    final ingles = e.traducoes.isNotEmpty;
    Widget linha(List<Widget> filhos) => ingles
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: filhos),
          )
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: filhos);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: p != null ? Mixart.brandDim : Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: p != null
          // o portal na vez: cada faixa livre com sua palavra
          ? Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < p.faixas.length; i++) ...[
                  if (i > 0) const SizedBox(width: 28),
                  // inglês: duas palavras compridas + traduções encolhem juntas em vez de vazar
                  if (ingles)
                    Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: _palavraDaFaixa(e, p, i)))
                  else
                    _palavraDaFaixa(e, p, i),
                ],
              ]),
              const SizedBox(height: 8),
              linha([
                // o carro freou sozinho e espera a palavra: o portal não passa sem ela
                if (e.segurando)
                  Text('⏸ esperando a palavra — digite para passar',
                      key: const Key('turismo-esperando'),
                      style: Mixart.ui(size: 11, weight: FontWeight.w700, color: Mixart.brand))
                else
                  Text('portal em ${(p.z - e.posicao).clamp(0, 9999).round()} m',
                      style: Mixart.ui(size: 11, color: Mixart.textFaint)),
                aSeguir(),
              ]),
            ])
          // combustível: a faixa já está marcada, agora é só acelerar
          : Column(children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                  child: Text(
                    atual == null
                        ? '🏁 RETA FINAL · ⛽ COMBUSTÍVEL'
                        : atual.digitado >= 0
                            ? '✓ ${_setas[atual.faixas[atual.digitado]]} marcada · ⛽ COMBUSTÍVEL'
                            // combustível pela metade antes da palavra do portal: nada
                            // marcado ainda (dart2js devolvia "undefined" no índice -1)
                            : '⛽ COMBUSTÍVEL · termine a palavra, depois vem a do portal',
                    style: Mixart.ui(size: 10, weight: FontWeight.w800, color: const Color(0xFF57C765))
                        .copyWith(letterSpacing: 2),
                  ),
                ),
                // inglês: a que você errou volta como combustível pra revisar
                if (gas != null && e.palavraGasRevisao) ...[
                  const SizedBox(width: 6),
                  const MarcaRevisao(rotulo: 'REVISÃO'),
                ],
              ]),
              const SizedBox(height: 6),
              if (gas != null) _palavraGas(e, gas),
              const SizedBox(height: 8),
              linha([
                Text(
                    atual == null
                        ? 'digite pra manter a velocidade até a bandeirada'
                        : 'portal em ${(atual.z - e.posicao).clamp(0, 9999).round()} m · digite pra não perder velocidade',
                    style: Mixart.ui(size: 11, color: Mixart.textFaint)),
                aSeguir(),
              ]),
            ]),
    );
  }

  /// ' (tradução)' de [palavra] no inglês; '' sem tradução (Dart, C#).
  String _entreParenteses(TurismoEngine e, String palavra) {
    final t = e.traducao(palavra);
    return t == null ? '' : ' ($t)';
  }

  Widget _palavraGas(TurismoEngine e, String gas) {
    final traducao = e.traducao(gas);
    final palavra = _palavraGasTexto(e, gas);
    if (traducao == null) return palavra;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      palavra,
      const SizedBox(height: 2),
      LegendaTraducao(traducao, tamanho: 13, maxLargura: 260),
    ]);
  }

  Widget _palavraGasTexto(TurismoEngine e, String gas) {
    final idx = e.gasDigitadas;
    return Semantics(
      label: 'digite: $gas',
      excludeSemantics: true,
      child: Text.rich(
        key: _chaveGas,
        TextSpan(children: [
          TextSpan(text: gas.substring(0, idx), style: TextStyle(color: Mixart.brand, fontWeight: FontWeight.w700)),
          if (idx < gas.length)
            TextSpan(text: gas[idx], style: TextStyle(color: Mixart.text, backgroundColor: Mixart.brandSub)),
          if (idx + 1 < gas.length)
            TextSpan(text: gas.substring(idx + 1), style: TextStyle(color: Mixart.textMuted)),
        ]),
        style: Mixart.mono(size: 28).copyWith(letterSpacing: 1.5, height: 1.1),
      ),
    );
  }

  Widget _palavraDaFaixa(TurismoEngine e, Portal p, int i) {
    final palavra = p.palavras[i];
    final travada = e.palavraTravada;
    final ativa = travada == null || travada == i;
    final idx = travada == i ? e.digitadas : 0;
    return Opacity(
      opacity: ativa ? 1 : .35,
      child: Column(children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_setas[p.faixas[i]],
              style: Mixart.ui(size: 10, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 2)),
          // inglês: voltou pra revisar (errou ou demorou na corrida anterior)
          if (p.ehRevisao(i)) ...[const SizedBox(width: 6), const MarcaRevisao()],
        ]),
        const SizedBox(height: 6),
        Semantics(
          label: 'digite: $palavra',
          excludeSemantics: true,
          child: Text.rich(
            key: i < _chavesPalavra.length ? _chavesPalavra[i] : null,
            TextSpan(children: [
              TextSpan(
                  text: palavra.substring(0, idx),
                  style: TextStyle(color: Mixart.brand, fontWeight: FontWeight.w700)),
              if (idx < palavra.length)
                TextSpan(
                  text: palavra[idx],
                  style: TextStyle(color: Mixart.text, backgroundColor: Mixart.brandSub),
                ),
              if (idx + 1 < palavra.length)
                TextSpan(text: palavra.substring(idx + 1), style: TextStyle(color: Mixart.textMuted)),
            ]),
            style: Mixart.mono(size: 28).copyWith(letterSpacing: 1.5, height: 1.1),
          ),
        ),
        if (e.traducao(palavra) != null) ...[
          const SizedBox(height: 2),
          LegendaTraducao(e.traducao(palavra), tamanho: 13, maxLargura: 220),
        ],
      ]),
    );
  }

  Widget _fimDaCorrida(TurismoEngine e, PistaGt pista) {
    final chegou = e.terminou;
    final m = e.medalha;
    final titulo = _campeao
        ? (BancoArcade.soDigitacao
            ? '🏆 CAMPEÃO ${BancoArcade.linguagem.toUpperCase()} TURISMO!'
            : '🏆 CAMPEÃO DART TURISMO!')
        : chegou
            ? (m == 0 ? '🏁 CHEGOU!' : '${emojisMedalha[m]} ${nomesMedalha[m].toUpperCase()}!')
            : '⏱ TEMPO ESGOTADO';
    final subtitulo = chegou
        ? 'Tempo ${_seg(e.tempoFinal!)} · ouro até ${_seg(pista.tempoOuro)} · prata até ${_seg(pista.tempoPrata)} · bronze até ${_seg(pista.tempoLimite)}'
        : 'Você percorreu ${e.posicao.round()} m de ${pista.distancia.round()} — '
            '${e.porSetas ? 'segure ↑ o tempo todo e desvie do tráfego pela faixa livre.' : 'digite sem parar: parar de escrever é ir parando.'}';
    final proxima = chegou && pista.numero < _pistas.length ? _pistas[pista.numero] : null;
    // 📖 inglês com história: o gancho do capítulo e o botão da chegada (na 30, o fim da história)
    final cap = chegou && _historiaAtiva ? _historia?.capitulo(pista.numero) : null;
    final ultimo = pista.numero == pistasGtIngles.length;
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Mixart.spring,
        builder: (_, t, child) => Opacity(opacity: t, child: child),
        child: Container(
          color: const Color(0xED010101),
          padding: const EdgeInsets.all(20),
          child: Stack(children: [
            if (chegou && (m >= 2 || _campeao)) const Confete(),
            Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_campeao ? '🏆' : (chegou ? emojisMedalha[m] : '⏱'), style: const TextStyle(fontSize: 52)),
                    const SizedBox(height: 8),
                    Text(titulo, textAlign: TextAlign.center, style: Mixart.display(size: 26, color: Mixart.brand)),
                    const SizedBox(height: 6),
                    Text(subtitulo,
                        textAlign: TextAlign.center,
                        style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.45)),
                    if (cap != null) ...[const SizedBox(height: 12), _chegadaNoFim(cap, ultimo: ultimo)],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                      decoration: BoxDecoration(
                        color: Mixart.surface,
                        border: Border.all(color: _novoRecorde ? Mixart.brand : Mixart.border),
                        borderRadius: BorderRadius.circular(Mixart.radiusMd),
                      ),
                      child: Column(children: [
                        Text('+${e.pontosFinais} pts', style: Mixart.display(size: 30, color: Mixart.brand)),
                        if (_novoRecorde)
                          Text('🏅 NOVO RECORDE PESSOAL!',
                              style: Mixart.ui(size: 11, weight: FontWeight.w700, color: Mixart.brand)
                                  .copyWith(letterSpacing: 1)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                      ChipPlacar('MOEDAS', '🪙 +$_moedasCorrida', cor: Mixart.brand),
                      ChipPlacar('FICHAS', '${e.fichasPegas}'),
                      if (e.porSetas)
                        ChipPlacar('PORTAIS LIMPOS', '${e.portaisLimpos}/${e.portais.length}')
                      else ...[
                        ChipPlacar('PALAVRAS', '${e.palavras}'),
                        ChipPlacar('PRECISÃO', '${e.precisao}%'),
                      ],
                      ChipPlacar('BATIDAS', '${e.colisoes}', cor: e.colisoes > 0 ? Mixart.danger : null),
                      ChipPlacar('MELHOR COMBO', '${e.melhorCombo}'),
                    ]),
                    if (_bateuFantasma || _trofeusNovos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                        if (_bateuFantasma)
                          ChipPlacar('👻 FANTASMA', 'batido!', cor: const Color(0xFF57C765)),
                        for (final t in _trofeusNovos) ChipPlacar('🏆 TROFÉU NOVO', '${t.emoji} ${t.nome}', cor: Mixart.brand),
                      ]),
                    ],
                    if (_sug != null) ...[const SizedBox(height: 14), _ofertaFim(_sug!, pista)],
                    const SizedBox(height: 14),
                    _radioDaEquipe(),
                    const SizedBox(height: 18),
                    Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                      if (proxima != null)
                        _botao('Próxima pista →', () => _correr(proxima), destaque: true),
                      _botao(chegou ? 'Correr de novo' : 'Tentar de novo', () => _correr(pista),
                          destaque: proxima == null),
                      _botao('Campeonato', _voltarAoCampeonato),
                    ]),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// 📖 No overlay de fim (inglês): "To be continued" com o gancho do capítulo (na 30, "THE END") e o
  /// botão da chegada — "Continue a história" ou, se já vista, "Rever final".
  Widget _chegadaNoFim(CapituloHistoria cap, {required bool ultimo}) {
    final gancho = cap.gancho;
    final vista = _vistos.contains(ProgressoHistoria.id(cap.pista, ParteDoCapitulo.fim));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.brandDim),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(children: [
        if (ultimo && gancho == null)
          Text('📖 THE END', textAlign: TextAlign.center, style: Mixart.display(size: 16, color: Mixart.brand))
        else if (gancho != null) ...[
          Text('📖 To be continued: ${gancho.en}',
              textAlign: TextAlign.center,
              style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.text).copyWith(height: 1.4)),
          const SizedBox(height: 2),
          Text(gancho.pt,
              textAlign: TextAlign.center,
              style: Mixart.ui(size: 11.5, color: Mixart.textMuted).copyWith(fontStyle: FontStyle.italic)),
        ] else
          Text('📖 Chapter ${cap.pista} · ${cap.titulo.en}',
              textAlign: TextAlign.center, style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.text)),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('turismo-continuar-historia'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Mixart.brand,
            side: BorderSide(color: Mixart.brand),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            textStyle: Mixart.ui(size: 13, weight: FontWeight.w700),
          ),
          onPressed: () => _verChegada(cap.pista),
          child: Text(vista ? '📖 Rever final' : '📖 Continue a história'),
        ),
      ]),
    );
  }

  /// 🎧 O rádio da equipe na tela de fim: a engenheira lê a telemetria.
  Widget _radioDaEquipe() {
    final texto = _radio;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🎧 RÁDIO DA EQUIPE · ENGENHEIRA DE PISTA',
            style: Mixart.ui(size: 10, weight: FontWeight.w800, color: Mixart.textMuted).copyWith(letterSpacing: 2)),
        const SizedBox(height: 6),
        if (texto == null)
          Row(children: [
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Mixart.brand)),
            const SizedBox(width: 8),
            Text('lendo a telemetria da sua corrida…', style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
          ])
        else
          Text(texto, style: Mixart.ui(size: 12.5, color: Mixart.text).copyWith(height: 1.5)),
      ]),
    );
  }

  Widget _botao(String texto, VoidCallback onTap, {bool destaque = false}) {
    if (destaque) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Mixart.brand,
          foregroundColor: Mixart.onBrand,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: Mixart.ui(size: 13, weight: FontWeight.w700),
        ),
        onPressed: onTap,
        child: Text(texto),
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Mixart.text,
        side: BorderSide(color: Mixart.border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: Mixart.ui(size: 13),
      ),
      onPressed: onTap,
      child: Text(texto),
    );
  }
}


/// 🎮 Controles na tela do modo setas: ◀ ▶ trocam de faixa no toque;
/// FREIO e GÁS valem enquanto o dedo (ou o mouse) segura.
class BotoesSetas extends StatelessWidget {
  final bool gas;
  final bool freio;
  final ValueChanged<int> onVirar;
  final ValueChanged<bool> onGas;
  final ValueChanged<bool> onFreio;
  const BotoesSetas({
    super.key,
    required this.gas,
    required this.freio,
    required this.onVirar,
    required this.onGas,
    required this.onFreio,
  });

  /// Os quatro botões lado a lado (64 + 8 + 64 + 96 + 8 + 96) e uma folga mínima entre os pares.
  static const _larguraCheia = 336.0 + 8;

  @override
  Widget build(BuildContext context) {
    // celular 360: sobram 320 px — os botões encolhem juntos em vez de vazar 16 px pela direita
    return LayoutBuilder(builder: (context, box) {
      final k = box.maxWidth.isFinite ? math.min(1.0, box.maxWidth / _larguraCheia) : 1.0;
      return Row(children: [
        _toque('◀', 'faixa da esquerda', () => onVirar(-1), k),
        const SizedBox(width: 8),
        _toque('▶', 'faixa da direita', () => onVirar(1), k),
        const Spacer(),
        _segura('▼ FREIO', 'freio', freio, onFreio, k, cor: Mixart.danger),
        const SizedBox(width: 8),
        _segura('▲ GÁS', 'acelerador', gas, onGas, k, cor: const Color(0xFF57C765)),
      ]);
    });
  }

  Widget _toque(String texto, String nome, VoidCallback onTap, double k) {
    return Semantics(
      button: true,
      label: nome,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onTap(),
        child: Container(
          width: 64 * k,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Text(texto, style: Mixart.display(size: 20)),
        ),
      ),
    );
  }

  Widget _segura(String texto, String nome, bool ativo, ValueChanged<bool> onMudou, double k,
      {required Color cor}) {
    return Semantics(
      button: true,
      label: nome,
      child: Listener(
        onPointerDown: (_) => onMudou(true),
        onPointerUp: (_) => onMudou(false),
        onPointerCancel: (_) => onMudou(false),
        child: Container(
          width: 96 * k,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ativo ? cor : Mixart.surface,
            border: Border.all(color: ativo ? cor : Mixart.border, width: ativo ? 1.8 : 1),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Text(texto,
              style: Mixart.ui(size: 12.5, weight: FontWeight.w800, color: ativo ? Colors.black : Mixart.text)),
        ),
      ),
    );
  }
}
