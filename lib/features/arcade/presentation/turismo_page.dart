import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/personagem.dart';
import '../domain/progresso_turismo.dart';
import '../domain/turismo.dart';
import '../data/engenheiro_gt.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/campanha.dart';
import 'widgets/campo_teclas.dart';
import 'widgets/cenario.dart';
import 'widgets/minimapa.dart';
import 'widgets/tutorial_turismo.dart';
import 'widgets/vista_3d.dart';

/// 🏎️ Dart Turismo — campeonato de digitação em 10 pistas pseudo-3D.
/// Cada portal marca a faixa livre com uma PALAVRA: digite-a pra entrar na
/// faixa. Toda tecla certa acelera; parar de digitar é ir parando; cruzar o
/// portal numa faixa bloqueada é batida. Feche a pista dentro do tempo pra
/// liberar a próxima — ouro, prata ou bronze pelo relógio.
class TurismoPage extends StatefulWidget {
  /// Semente da pista (fixa nos testes; null = aleatória).
  final int? semente;

  /// Abre direto correndo esta pista (1–10); null = tela do campeonato.
  final int? pistaInicial;

  /// A engenheira de pista (IA) — injetável nos testes.
  final EngenheiroGt? engenheiro;
  const TurismoPage({super.key, this.semente, this.pistaInicial, this.engenheiro});

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

  /// 👻 O fantasma da pista atual, 📊 as estatísticas e 🏆 os troféus novos.
  VoltaFantasma? _fantasma;
  bool _bateuFantasma = false;
  EstatisticasGt _estatisticas = EstatisticasGt.vazio;
  List<TrofeuGt> _trofeusNovos = const [];

  _Tela _tela = _Tela.campeonato;
  PistaGt? _pista;
  TurismoEngine? _engine;
  late final Ticker _ticker = createTicker(_tick);
  Duration _ultimo = Duration.zero;
  double _relogio = 0;
  double _ultimoRonco = -1;

  bool _contagem = false;
  bool _acabou = false;
  bool _pontuado = false;
  bool _novoRecorde = false;
  bool _campeao = false;

  static const _setas = ['⬅ ESQUERDA', '⬆ MEIO', '➡ DIREITA'];

  @override
  bool get podePausar => _tela == _Tela.corrida && _engine != null && !_contagem && !_acabou && !_tutorial;

  @override
  void initState() {
    super.initState();
    _ranking = RankingCubit.de(context);
    PersonagemStore.carregar().then((_) {
      if (mounted) setState(() {});
    });
    _ticker.start();
    // o modo (⌨️/🎮), o carro e a câmera salvos entram ANTES da corrida direta
    _carregarCampeonato().then((_) {
      final inicial = widget.pistaInicial;
      if (inicial != null && mounted) _correr(pistasGt[(inicial - 1).clamp(0, pistasGt.length - 1)]);
    });
  }

  Future<void> _carregarCampeonato() async {
    final c = await ProgressoTurismo.carregar(totalPistas: pistasGt.length);
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
    _ticker.dispose();
    _foco.dispose();
    Sons.motorParar();
    _publicarParcial();
    super.dispose();
  }

  /// Saiu no meio: as palavras digitadas valem ponto mesmo assim.
  void _publicarParcial() {
    final e = _engine;
    if (e == null || _pontuado || e.pontos <= 0) return;
    _pontuado = true;
    _ranking?.arcadeJogado('turismo', e.pontos);
  }

  @override
  void aoPausar() => Sons.motorParar();

  // ---------- corrida ----------

  Future<void> _correr(PistaGt p) async {
    Sons.motorParar();
    final tutorial = !await ProgressoTurismo.tutorialVisto(setas: _modoSetas);
    final fantasma = await ProgressoTurismo.fantasma(p.numero);
    if (!mounted) return;
    setState(() {
      _pista = p;
      _engine = TurismoEngine(
        pista: p,
        rnd: math.Random(widget.semente),
        modo: _modoSetas ? ModoControle.setas : ModoControle.digitacao,
      );
      _tracado = tracadoDaPista([for (final s in _engine!.segmentos) s.curva],
          comprimento: TurismoEngine.comprimentoSegmento);
      _tutorial = tutorial;
      _fantasma = fantasma;
      _bateuFantasma = false;
      _trofeusNovos = const [];
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
    });
  }

  void _largada() {
    if (!mounted || _engine == null) return;
    setState(() => _contagem = false);
    pausarSeEscondido();
    if (_modoSetas) _foco.requestFocus();
  }

  void _voltarAoCampeonato() {
    _publicarParcial();
    Sons.motorParar();
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
    _ultimo = elapsed;
    final e = _engine;
    if (e == null || _tela != _Tela.corrida || _contagem || pausado || _acabou || !mounted) return;
    if (dt > .1) dt = .1;
    final colisoesAntes = e.colisoes;
    final fichasAntes = e.fichasPegas;
    final limposAntes = e.portaisLimpos;
    if (e.porSetas) {
      // sem campo de texto, o foco do teclado tem que ficar na página
      if (!_foco.hasFocus) _foco.requestFocus();
      e.pedais(dt, gas: _gas, freio: _freio);
    }
    setState(() {
      e.tick(dt);
      _relogio += dt;
    });
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

  void _tecla(String ch) {
    final e = _engine;
    if (e == null || _contagem || pausado || _acabou || ch.trim().isEmpty) return;
    final multAntes = e.multiplicador;
    final r = e.teclar(ch);
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

  Future<void> _fim() async {
    final e = _engine;
    final pista = _pista;
    if (e == null || pista == null || _acabou) return;
    Sons.motorParar();
    setState(() {
      _acabou = true;
      pausado = false;
      _campeao = e.terminou && pista.numero == pistasGt.length && e.medalha > 0;
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
        totalPistas: pistasGt.length,
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
      final recorde = await _ranking?.arcadeJogado('turismo', e.pontosFinais);
      if (mounted && recorde == true) setState(() => _novoRecorde = true);
    }
    await _carregarCampeonato();
    if (!mounted) return;
    setState(() {
      _estatisticas = statsDepois;
      _trofeusNovos = [
        for (final t in trofeusGt)
          if (!t.ganhou(statsAntes, campAntes) && t.ganhou(statsDepois, _campeonato)) t,
      ];
    });
    if (_trofeusNovos.isNotEmpty) Sons.toca(Som.fanfarra);
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
              constraints: const BoxConstraints(maxWidth: 920),
              child: Stack(children: [
                if (_tela == _Tela.campeonato || e == null) _telaCampeonato() else _telaCorrida(e),
                if (_tutorial && _pista != null)
                  TutorialTurismo(porSetas: _modoSetas, onLargar: _fecharTutorial)
                else if (_contagem && _pista != null)
                  ContagemRegressiva(
                    onFim: _largada,
                    legenda: '${emojiDaFase(_pista!.tema)} ${_pista!.nome} — '
                        '${_modoSetas ? 'segure ↑ pra acelerar' : 'digite pra acelerar'}',
                  ),
                if (pausado) PausaOverlay(onContinuar: retomar, onSair: _voltarAoCampeonato),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
      children: [
        CabecalhoJogo(
          rotulo: 'ARCADE · DIGITAÇÃO',
          titulo: '🏎️ Dart Turismo',
          chips: [
            ChipPlacar('MOEDAS', '🪙 ${_campeonato.moedas}', cor: Mixart.brand),
            ChipPlacar('MEDALHAS', '${_campeonato.totalMedalhas}/${pistasGt.length}'),
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
            'Campeonato de ${pistasGt.length} pistas em 3D. Cada portal marca a faixa LIVRE '
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
          return Wrap(spacing: 12, runSpacing: 12, children: [
            for (final p in pistasGt) SizedBox(width: largura, child: _cartaoPista(p)),
          ]);
        }),
        const SizedBox(height: 18),
        Text(
          'Créditos 3D · Carros: Porsche 911 (930) Turbo 1975, Nissan Skyline R34 GT-R, Honda NSX 1990, '
          'Mazda Miata MX-5 NA e Toyota Corolla AE86 Trueno, por Lexyc16 (sketchfab.com/Lexyc16), '
          'licença CC BY 4.0 · Céus HDRI, texturas e postes: Poly Haven (CC0) · Som do motor: "Car Engine Loop" '
          'por qubodup (OpenGameArt), CC BY 3.0 · Som da batida: qubodup (CC0) · Músicas: "Rock Music Pack" '
          'por Ragnar Random (OpenGameArt, CC0) · Fachadas dos prédios: ambientCG (CC0) · Rochas, arbustos e '
          'árvores: Poly Haven (CC0) · Pneu cantando: audible-edge (OpenGameArt, CC BY 3.0) · '
          'Engenheira de pista: Gemini · Motor 3D: three.js (MIT).',
          style: Mixart.ui(size: 10.5, color: Mixart.textFaint).copyWith(height: 1.5),
        ),
      ],
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
    final ganhos = trofeusGt.where((t) => t.ganhou(s, _campeonato)).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TROFÉUS · $ganhos/${trofeusGt.length}',
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
        for (final t in trofeusGt) _cartaoTrofeu(t, t.ganhou(s, _campeonato)),
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
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.nome, style: Mixart.display(size: 13)),
                Text(
                  meu ? c.apelido : '${c.apelido} · 🪙 ${c.preco} moedas${daPra ? ' — toque pra comprar' : ''}',
                  style: Mixart.ui(size: 10.5, color: daPra && !meu ? Mixart.brand : Mixart.textMuted),
                ),
              ]),
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
    return Opacity(
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
                  '${emojiDaFase(p.tema)} ${nomeDaFase(p.tema)} · ${p.dificuldade} · '
                  '${(p.distancia / 1000).toStringAsFixed(1)} km · limite ${p.tempoLimite.round()}s',
                  style: Mixart.ui(size: 11, color: Mixart.textMuted),
                ),
                if (p.tituloMusica.isNotEmpty)
                  Text('🎸 ${p.tituloMusica}', style: Mixart.ui(size: 10.5, color: Mixart.textFaint)),
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
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
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
            )
          else
            Text('🔒 vença a pista ${p.numero - 1} pra liberar',
                style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
        ]),
      ),
    );
  }

  Widget _telaCorrida(TurismoEngine e) {
    final pista = _pista!;
    final urgente = e.tempoRestante <= 10;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: CabecalhoJogo(
          rotulo: 'PISTA ${pista.numero}/${pistasGt.length} · ${pista.dificuldade.toUpperCase()}',
          titulo: '🏎️ ${pista.nome}',
          chips: [
            ChipPlacar('TEMPO', _seg(e.tempoRestante), cor: urgente ? Mixart.danger : null),
            ChipPlacar('MOEDAS', '🪙 ${e.moedas}', cor: Mixart.brand),
            ChipPlacar('PALAVRAS', '${e.palavras}'),
            ChipPlacar('COMBO', e.multiplicador > 1 ? 'x${e.multiplicador}' : '${e.combo}/5',
                cor: e.multiplicador > 1 ? Mixart.brand : null),
            if (e.porSetas) ChipPlacar('PORTAIS', '${e.portaisLimpos}') else ChipPlacar('ERROS', '${e.erros}'),
            if (_fantasma != null) _chipFantasma(e),
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
              ),
            ),
            Positioned(left: 12, top: 12, right: 136, child: _barraProgresso(e)),
            Positioned(
              right: 12,
              top: 12,
              child: Minimapa(
                tracado: _tracado,
                posicao: e.posicao,
                comprimentoSegmento: TurismoEngine.comprimentoSegmento,
              ),
            ),
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
        CampoTeclas(onChar: _tecla),
    ]);
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
              final x = e.progresso * (box.maxWidth - 10);
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
              : '${p.palavras.first}  ·  portal em ${(p.z - e.posicao).clamp(0, 9999).round()} m'
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
            Text('${_setas[proximo.faixas.first].substring(0, 1)} ${proximo.palavras.first}',
                style: Mixart.mono(size: 12, color: Mixart.textMuted)),
          ]);
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
                  _palavraDaFaixa(e, p, i),
                ],
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('portal em ${(p.z - e.posicao).clamp(0, 9999).round()} m',
                    style: Mixart.ui(size: 11, color: Mixart.textFaint)),
                aSeguir(),
              ]),
            ])
          // combustível: a faixa já está marcada, agora é só acelerar
          : Column(children: [
              Text(
                atual == null
                    ? '🏁 RETA FINAL · ⛽ COMBUSTÍVEL'
                    : '✓ ${_setas[atual.faixas[atual.digitado]]} marcada · ⛽ COMBUSTÍVEL',
                style: Mixart.ui(size: 10, weight: FontWeight.w800, color: const Color(0xFF57C765))
                    .copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 6),
              if (gas != null) _palavraGas(e, gas),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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

  Widget _palavraGas(TurismoEngine e, String gas) {
    final idx = e.gasDigitadas;
    return Semantics(
      label: 'digite: $gas',
      excludeSemantics: true,
      child: Text.rich(
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
        Text(_setas[p.faixas[i]],
            style: Mixart.ui(size: 10, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 2)),
        const SizedBox(height: 6),
        Semantics(
          label: 'digite: $palavra',
          excludeSemantics: true,
          child: Text.rich(
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
      ]),
    );
  }

  Widget _fimDaCorrida(TurismoEngine e, PistaGt pista) {
    final chegou = e.terminou;
    final m = e.medalha;
    final titulo = _campeao
        ? '🏆 CAMPEÃO DART TURISMO!'
        : chegou
            ? '${emojisMedalha[m]} ${nomesMedalha[m].toUpperCase()}!'
            : '⏱ TEMPO ESGOTADO';
    final subtitulo = chegou
        ? 'Tempo ${_seg(e.tempoFinal!)} · ouro até ${_seg(pista.tempoOuro)} · prata até ${_seg(pista.tempoPrata)} · bronze até ${_seg(pista.tempoLimite)}'
        : 'Você percorreu ${e.posicao.round()} m de ${pista.distancia.round()} — '
            '${e.porSetas ? 'segure ↑ o tempo todo e desvie do tráfego pela faixa livre.' : 'digite sem parar: parar de escrever é ir parando.'}';
    final proxima = chegou && pista.numero < pistasGt.length ? pistasGt[pista.numero] : null;
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

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _toque('◀', 'faixa da esquerda', () => onVirar(-1)),
      const SizedBox(width: 8),
      _toque('▶', 'faixa da direita', () => onVirar(1)),
      const Spacer(),
      _segura('▼ FREIO', 'freio', freio, onFreio, cor: Mixart.danger),
      const SizedBox(width: 8),
      _segura('▲ GÁS', 'acelerador', gas, onGas, cor: const Color(0xFF57C765)),
    ]);
  }

  Widget _toque(String texto, String nome, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: nome,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onTap(),
        child: Container(
          width: 64,
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

  Widget _segura(String texto, String nome, bool ativo, ValueChanged<bool> onMudou, {required Color cor}) {
    return Semantics(
      button: true,
      label: nome,
      child: Listener(
        onPointerDown: (_) => onMudou(true),
        onPointerUp: (_) => onMudou(false),
        onPointerCancel: (_) => onMudou(false),
        child: Container(
          width: 96,
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
