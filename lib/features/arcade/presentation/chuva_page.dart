import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../../ingles/domain/erros_palavra.dart';
import '../../ingles/domain/teimosas.dart';
import '../../ingles/presentation/acoes_teimosas.dart';
import '../../ingles/presentation/palavras_cubit.dart';
import 'banco_arcade.dart';
import 'voz_jogo.dart';
import '../domain/personagem.dart';
import '../domain/tiro_engine.dart';
import '../domain/tropecos.dart';
import '../domain/vocabulario_jogo.dart';
import 'widgets/legenda_traducao.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/avatares.dart';
import 'widgets/campanha.dart';
import 'widgets/campo_teclas.dart';
import 'widgets/cenario.dart';
import 'widgets/painel_tropecos.dart';
import 'widgets/perspectiva.dart';

/// ☄️ Chuva de Código — palavras do Dart caem do céu; digite a primeira
/// letra pra travar a mira e cada letra certa sai como TIRO da boca do Pac.
/// Palavra que toca o chão custa uma vida (são 3). Douradas valem 4x.
/// COMBO de palavras sem erro multiplica os pontos (x2 aos 5, x3 aos 10).
/// Largada 3-2-1, palavra explode em estilhaços, chão treme ao perder vida,
/// mira desenhada até o alvo, Esc pausa.
class ChuvaPage extends StatefulWidget {
  /// Semente do sorteio (fixa nos testes; null = aleatório de verdade).
  final int? semente;
  const ChuvaPage({super.key, this.semente});

  @override
  State<ChuvaPage> createState() => _ChuvaPageState();
}

/// Tiro voando do Pac até a palavra (coordenadas em fração da arena).
class _Tiro {
  final double x1, y1;
  double t = 0;
  _Tiro(this.x1, this.y1);
}

/// Aviso de pontos que sobe quando a palavra explode.
class _Premio {
  final double x, y;
  final String texto;
  final bool ouro;
  double t = 0;
  _Premio(this.x, this.y, this.texto, this.ouro);
}

/// Estilhaços da palavra destruída (vivem ~0,6s).
class _Explosao {
  final double x, y;
  final bool ouro;
  final int semente;
  double t = 0;
  _Explosao(this.x, this.y, this.ouro, this.semente);
}

class _ChuvaPageState extends State<ChuvaPage>
    with WidgetsBindingObserver, PausaDeJogo<ChuvaPage>, SingleTickerProviderStateMixin {
  RankingCubit? _ranking;
  late TiroEngine _engine = _novoEngine();
  late final Ticker _ticker; // criado no initState, ligado só na partida

  /// Motor com as palavras da vertente em uso (Dart, C# ou as das lições de inglês).
  TiroEngine _novoEngine() {
    final v = _vocab = BancoArcade.vocabulario(context);
    return TiroEngine(rnd: math.Random(widget.semente), curtas: v.curtas, medias: v.medias, longas: v.longas);
  }

  /// O vocabulário da partida (a tradução embaixo da palavra no inglês).
  VocabularioJogo? _vocab;

  /// Inglês: o banco de palavras do aluno e o que aconteceu com cada palavra nesta partida.
  PalavrasCubit? _palavrasCubit;
  final _placar = PlacarPalavras();
  Duration _ultimo = Duration.zero;

  /// O Ticker só roda com a chuva caindo (da largada até a pausa/o fim): parado, não pede frame (no
  /// navegador cada frame redesenha a tela inteira). Ao religar, o 1º passo conta a partir do último
  /// frame desenhado ([_religadoEm]) — como se ele nunca tivesse parado; na volta da pausa, no máximo
  /// do tamanho do último passo jogado ([_ultimoDt]), sem o salto do tempo parado.
  Duration? _religadoEm;
  bool _retomando = false;
  double _ultimoDt = 1 / 60;

  /// O campo invisível é sempre o mesmo widget: o setState de cada frame não o reconstrói.
  late final _campo = CampoTeclas(onChar: _tecla);

  /// Inglês (teimosas): os tropeços da partida, as teclas erradas em cada palavra travada (por id) e a
  /// oferta "treinar só elas" do fim de jogo. Null/vazio no Dart e no C#.
  TropecosDoJogo? _tropecos;
  final Map<int, int> _errosNoAlvo = {};
  SugestaoTeimosas? _sug;

  final List<_Tiro> _tiros = [];
  final List<_Premio> _premios = [];
  final List<_Explosao> _explosoes = [];
  int _flashErro = 0; // frames restantes do aviso de tecla errada
  double _chaoFlash = 0; // segundos restantes do chão vermelho (palavra caiu)
  int _tremor = 0; // sacode a arena a cada vida perdida

  /// Aviso no topo da arena ("NÍVEL 2 — Deserto…", "COMBO x2"), some sozinho.
  String _aviso = '';
  double _avisoTempo = 0;

  /// Largada 3-2-1 (nada cai ainda).
  bool _contagem = true;
  bool _acabou = false;
  bool _novoRecorde = false;
  bool _pontuado = false;

  /// 🔊 Inglês: a palavra falada quando a pessoa trava a mira nela (não a cada uma que cai).
  final _voz = VozDoJogo();

  void _alternarVoz() {
    _voz.alternar();
    setState(() {});
  }

  @override
  bool get podePausar => !_contagem && !_acabou;

  @override
  void initState() {
    super.initState();
    _ranking = RankingCubit.de(context);
    _palavrasCubit = BancoArcade.palavras(context);
    if (_palavrasCubit != null) _tropecos = TropecosDoJogo();
    _ticker = createTicker(_tick);
    PersonagemStore.carregar().then((_) {
      if (mounted) setState(() {});
    });
    if (BancoArcade.soDigitacao) {
      VozDoJogo.carregarPreferencia().then((_) {
        if (mounted) setState(() {});
      });
    }
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

  @override
  void aoPausar() {
    _desligarTicker();
    _voz.calar();
  }

  @override
  void aoRetomar() {
    if (!_acabou && !_contagem) _ligarTicker(retomando: true);
  }

  @override
  void dispose() {
    _voz.encerrar();
    _ticker.dispose();
    // fechou no meio: o que já foi destruído vale ponto mesmo assim
    if (!_pontuado && _engine.pontos > 0) _ranking?.arcadeJogado('chuva', _engine.pontos);
    _placar.enviar(_palavrasCubit, fonte: FonteErro.chuva, tropecos: _tropecos);
    super.dispose();
  }

  void _reiniciar() {
    _desligarTicker(); // volta para a largada 3-2-1
    _voz.calar();
    setState(() {
      _engine = _novoEngine();
      _tiros.clear();
      _premios.clear();
      _explosoes.clear();
      _flashErro = 0;
      _chaoFlash = 0;
      _aviso = '';
      _avisoTempo = 0;
      _contagem = true;
      _acabou = false;
      _novoRecorde = false;
      _pontuado = false;
      pausado = false;
      _errosNoAlvo.clear();
      _sug = null;
      if (_tropecos != null) _tropecos = TropecosDoJogo();
    });
  }

  void _largada() {
    if (!mounted || _acabou) return;
    setState(() => _contagem = false);
    _ligarTicker();
    pausarSeEscondido();
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
    if (_acabou || !mounted || _contagem || pausado) return;
    if (dt > 0.1) dt = 0.1; // aba dormiu: não deixa tudo despencar de uma vez
    if (dt > 0) _ultimoDt = dt;
    final nivelAntes = _engine.nivel;
    final vidasAntes = _engine.vidas;
    final noArAntes = _palavrasCubit == null ? null : [..._engine.ativas];
    setState(() {
      _engine.tick(dt);
      // inglês: a palavra que chegou ao chão conta como erro nela
      if (noArAntes != null) {
        for (final p in noArAntes) {
          if (!_engine.ativas.contains(p)) {
            _placar.errou(p.texto);
            _tropecou(p, 1); // caiu: errou de vez
          }
        }
      }
      if (_engine.vidas < vidasAntes) {
        Sons.toca(Som.defesa);
        _tremor++;
        _chaoFlash = .7;
      }
      if (_engine.nivel != nivelAntes) {
        Sons.toca(Som.fase);
        // passou de nível: cenário novo lá atrás + aviso na tela
        _mostraAviso(
            '${emojiDaFase(_engine.nivel)} NÍVEL ${_engine.nivel} — ${nomeDaFase(_engine.nivel)}!',
            2.8);
      }
      if (_avisoTempo > 0) _avisoTempo -= dt;
      if (_chaoFlash > 0) _chaoFlash -= dt;
      for (final t in _tiros) {
        t.t += dt * 6;
      }
      _tiros.removeWhere((t) => t.t >= 1);
      for (final p in _premios) {
        p.t += dt * 1.4;
      }
      _premios.removeWhere((p) => p.t >= 1);
      for (final x in _explosoes) {
        x.t += dt / .7;
      }
      _explosoes.removeWhere((x) => x.t >= 1);
      if (_flashErro > 0) _flashErro--;
    });
    if (_engine.fim) _fim();
  }

  void _mostraAviso(String texto, double segundos) {
    _aviso = texto;
    _avisoTempo = segundos;
  }

  /// Inglês: uma ocorrência de [p] terminou com falha [f] (caiu = 1; destruída com n teclas erradas =
  /// n·0,34). Na 2ª escapada, o aviso leve no topo. Chame dentro de um setState.
  void _tropecou(PalavraCaindo p, double f) {
    final t = _tropecos;
    final erradas = _errosNoAlvo.remove(p.id) ?? 0;
    if (t == null) return;
    final falha = f >= 1 ? 1.0 : math.min(1.0, erradas * .34);
    if (falha <= 0) return;
    t.falha(p.texto, falha);
    final w = t.aviso(p.texto, pode: !_contagem && !pausado);
    if (w != null) _mostraAviso(BancoArcade.textoAviso(w, t.vezes(w)), 3.2);
  }

  /// "⚡ Revanche no jogo": as palavras da oferta em foco e outra partida.
  void _revanche() {
    final s = _sug;
    if (s != null) jogarComTeimosas(context, s.palavras, dentroDoJogo: true);
    _reiniciar();
  }

  void _tecla(String ch) {
    if (_acabou || _contagem || pausado || ch.trim().isEmpty) return;
    final multAntes = _engine.multiplicador;
    final semAlvo = _engine.alvoId == null;
    final (resultado, palavra) = _engine.teclar(ch);
    // travou a mira agora: a palavra falada (o tiro e a voz saem juntos)
    if (semAlvo && palavra != null && resultado != TiroResultado.errou && resultado != TiroResultado.nada) {
      _voz.falar(palavra.texto, pausado: pausado, acabou: _acabou);
    }
    setState(() {
      switch (resultado) {
        case TiroResultado.avancou:
          _tiros.add(_Tiro(palavra!.x, palavra.y));
          Sons.toca(Som.tiro);
        case TiroResultado.destruiu:
          if (_palavrasCubit != null) _placar.viu(palavra!.texto);
          if (_tropecos != null) {
            _tropecos!.vista(palavra!.texto);
            _tropecou(palavra, 0);
          }
          _tiros.add(_Tiro(palavra!.x, palavra.y));
          _premios.add(_Premio(palavra.x, palavra.y, '+${_engine.ultimoGanho}', palavra.ouro));
          _explosoes.add(_Explosao(palavra.x, palavra.y, palavra.ouro, palavra.id));
          Sons.toca(Som.explosao);
          if (_engine.multiplicador > multAntes) {
            Sons.toca(Som.combo);
            _mostraAviso('🔥 COMBO x${_engine.multiplicador} — pontos multiplicados!', 2.2);
          }
        case TiroResultado.errou:
          // inglês: tecla errada na palavra travada conta para ela (sem alvo, não é de palavra nenhuma)
          if (_tropecos != null && palavra != null) _errosNoAlvo[palavra.id] = (_errosNoAlvo[palavra.id] ?? 0) + 1;
          _flashErro = 10;
          Sons.toca(Som.erro);
          if (multAntes > 1) _mostraAviso('💔 Combo perdido', 1.4);
        case TiroResultado.nada:
          break;
      }
    });
  }

  Future<void> _fim() async {
    if (_pontuado) return;
    _pontuado = true;
    _desligarTicker();
    _voz.calar();
    setState(() {
      _acabou = true;
      _tiros.clear();
      pausado = false;
    });
    Sons.toca(Som.defesa);
    _placar.enviar(_palavrasCubit, fonte: FonteErro.chuva, tropecos: _tropecos);
    _oferecerTeimosas();
    final recorde = await _ranking?.arcadeJogado('chuva', _engine.pontos);
    if (mounted && recorde == true) setState(() => _novoRecorde = true);
  }

  /// Inglês: a oferta "treinar só elas" do fim de jogo (uma por partida), se a política deixar.
  void _oferecerTeimosas() {
    final cubit = _palavrasCubit, t = _tropecos;
    if (cubit == null || t == null || t.somas.isEmpty) return;
    final sug = cubit.sugestao(LocalSugestao.fimDeJogo, daSessao: BancoArcade.daSessao(cubit, t));
    if (sug == null) return;
    cubit.marcarMostrada();
    setState(() => _sug = sug);
  }

  Widget? _ofertaFim() {
    final s = _sug;
    if (s == null) return null;
    return OfertaTeimosasFim(
      sugestao: s,
      onTreinar: () => treinarTeimosas(context, s.palavras, origem: 'chuva').then((_) {
        if (mounted) setState(() => _sug = null);
      }),
      onRevanche: _revanche,
      onAgoraNao: _palavrasCubit?.adiar,
    );
  }

  /// Inglês: a linha das palavras anotadas na pausa (null sem nada).
  Widget? _anotadas() {
    final t = BancoArcade.linhaAnotadas(_tropecos);
    return t == null ? null : LinhaAnotadas(t);
  }

  String get _comboTexto {
    final e = _engine;
    return switch (e.multiplicador) {
      3 => 'x3 🔥',
      2 => 'x2 · ${e.combo}',
      _ => '${e.combo}/5',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: Focus(
        onKeyEvent: (_, ev) => teclaDePausa(ev) ? KeyEventResult.handled : KeyEventResult.ignored,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Stack(children: [
                Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    // camadas próprias: a arena que mexe a cada frame não arrasta o cabeçalho
                    child: RepaintBoundary(
                    child: CabecalhoJogo(
                      rotulo: 'ARCADE · DIGITAÇÃO',
                      titulo: BancoArcade.soDigitacao ? '☄️ Chuva de Palavras' : '☄️ Chuva de Código',
                      chips: [
                        ChipPlacar('VIDAS', '❤️' * _engine.vidas + '·' * (3 - _engine.vidas)),
                        ChipPlacar('NÍVEL', '${_engine.nivel}'),
                        ChipPlacar('COMBO', _comboTexto,
                            cor: _engine.multiplicador > 1 ? Mixart.brand : null),
                        ChipPlacar('PONTOS', '${_engine.pontos}', cor: Mixart.brand),
                        ChipPlacar('ERROS', '${_engine.erros}',
                            cor: _flashErro > 0 ? Mixart.danger : null),
                      ],
                      acao: BancoArcade.soDigitacao
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              BotaoVozJogo(key: const Key('arcade-voz'), onTap: _alternarVoz),
                              const SizedBox(width: 8),
                              BotaoPausa(onTap: podePausar ? pausar : null),
                            ])
                          : BotaoPausa(onTap: podePausar ? pausar : null),
                    ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      // atrás da pausa a arena congela (o Pac para de mastigar); a pausa fica fora
                      child: TickerMode(
                        enabled: !pausado,
                        child: RepaintBoundary(child: Tremor(gatilho: _tremor, child: _arena())),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      '⌨️ digite a 1ª letra pra travar a mira — cada letra certa é um tiro. '
                      'Douradas valem 4x · 5 palavras sem erro = COMBO x2 · Esc pausa',
                      textAlign: TextAlign.center,
                      style: Mixart.ui(size: 11.5, color: Mixart.textFaint),
                    ),
                  ),
                  _campo,
                ]),
                if (_contagem)
                  ContagemRegressiva(
                    onFim: _largada,
                    grito: 'VAI!',
                    legenda: 'digite a 1ª letra pra travar a mira',
                  ),
                if (pausado)
                  PausaOverlay(
                      onContinuar: retomar, onSair: () => Navigator.of(context).pop(), extra: _anotadas()),
                if (_acabou)
                  FimDeJogo(
                    emoji: _engine.destruidas >= 24 ? '🏆' : '☄️',
                    titulo: _engine.destruidas >= 24 ? 'CHUVA DOMINADA!' : 'FIM DE JOGO',
                    subtitulo:
                        'Você destruiu ${_engine.destruidas} palavras e chegou ao nível ${_engine.nivel}.',
                    pontos: _engine.pontos,
                    novoRecorde: _novoRecorde,
                    celebrar: _novoRecorde,
                    noRanking: _ranking != null,
                    stats: [
                      ('PALAVRAS', '${_engine.destruidas}'),
                      ('NÍVEL', '${_engine.nivel}'),
                      ('MELHOR COMBO', '${_engine.melhorCombo}'),
                      ('ERROS', '${_engine.erros}'),
                    ],
                    onDeNovo: _reiniciar,
                    onSair: () => Navigator.of(context).pop(),
                    extra: _ofertaFim(),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _arena() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: _flashErro > 0 ? Mixart.danger : Mixart.border,
            width: _flashErro > 0 ? 1.6 : 1),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        // 200 = folga pro chip mais largo (GestureDetector dourado) não vazar
        double px(double x) => x * (w - 200);
        // no inglês a tradução embaixo do chip pede mais 16 px de folga no chão
        final folgaChao = BancoArcade.soDigitacao ? 132.0 : 116.0;
        double py(double y) => y * (h - folgaChao);
        final pacX = w / 2;
        final pacY = h - 62;
        final alvo = _engine.alvo;
        final chaoQuente = (_chaoFlash / .7).clamp(0.0, 1.0);

        return Stack(children: [
          // palco 3D da fase (muda a cada nível): céu + chão em perspectiva
          Positioned.fill(child: PalcoFase(fase: _engine.nivel, horizonte: .58)),
          Positioned.fill(child: Container(color: const Color(0x3806070B))),
          // linha do chão (esquenta quando uma palavra cai)
          Positioned(
            left: 12,
            right: 12,
            bottom: 40,
            child: Container(
              height: 1.4 + chaoQuente * 1.6,
              decoration: BoxDecoration(
                color: Color.lerp(Mixart.brandDim, Mixart.danger, chaoQuente),
                boxShadow: chaoQuente > 0
                    ? [BoxShadow(color: Mixart.danger.withValues(alpha: chaoQuente * .6), blurRadius: 10)]
                    : const [],
              ),
            ),
          ),
          // a mira: linha fina do Pac até o alvo travado
          if (alvo != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _MiraPainter(
                    de: Offset(pacX, pacY - 14),
                    ate: Offset(px(alvo.x) + 44, py(alvo.y) + 30),
                    cor: alvo.ouro ? Mixart.brand : Mixart.brandDim,
                  ),
                ),
              ),
            ),
          // tiros (da boca do Pac até a palavra), com rastro luminoso
          if (_tiros.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TirosPainter(
                    tiros: [
                      for (final t in _tiros)
                        (
                          Offset(pacX, pacY - 14),
                          Offset(px(t.x1) + 44, py(t.y1) + 14),
                          t.t,
                        ),
                    ],
                    cor: Mixart.brand,
                  ),
                ),
              ),
            ),
          // palavras caindo
          for (final p in _engine.ativas)
            Positioned(left: px(p.x), top: py(p.y), child: _palavra(p)),
          // estilhaços das destruídas
          for (final x in _explosoes)
            Positioned(
              left: px(x.x) + 44 - 44,
              top: py(x.y) + 16 - 44,
              child: Estilhacos(
                cor: x.ouro ? Mixart.brand : Mixart.text,
                pedacos: x.ouro ? 16 : 11,
                semente: x.semente,
              ),
            ),
          // prêmios subindo
          for (final pr in _premios)
            Positioned(
              left: px(pr.x) + 20,
              top: py(pr.y) - pr.t * 34,
              // o alfa vai na cor (sem camada por prêmio); o ✨ colorido do ouro fica no Opacity
              child: pr.ouro
                  ? Opacity(
                      opacity: (1 - pr.t).clamp(0, 1),
                      child: Text('${pr.texto} ✨', style: Mixart.display(size: 16, color: Mixart.brand)),
                    )
                  // o estilo-base fica no cache do Mixart; só a cor (com o alfa do quadro) muda
                  : Text(pr.texto,
                      style: Mixart.display(size: 16, color: Mixart.brand)
                          .copyWith(color: Mixart.brand.withValues(alpha: (1 - pr.t).clamp(0.0, 1.0)))),
            ),
          // o atirador: seu personagem de boca (ou bico) pra cima, com sombra
          Positioned(
            left: pacX - 30,
            top: pacY + 14,
            child: const Sombra(largura: 60, altura: 16, opacidade: .45),
          ),
          Positioned(
            left: pacX - 23,
            top: pacY - 23,
            child: Transform.rotate(
              angle: -math.pi / 2,
              // no fim (atrás do placar final) o Pac para de mastigar; o tremor da última vida segue
              child: IgnorePointer(child: AvatarPersonagem(tamanho: 46, animado: !_acabou)),
            ),
          ),
          // aviso (nível novo, combo)
          if (_avisoTempo > 0)
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xE010131A),
                    border: Border.all(color: Mixart.brandDim),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(_aviso, style: Mixart.display(size: 14, color: Mixart.brand)),
                ),
              ),
            ),
        ]);
      }),
    );
  }

  Widget _palavra(PalavraCaindo p) {
    final ehAlvo = _engine.alvoId == p.id;
    final perigo = !ehAlvo && p.y > .78;
    final corFundo = p.ouro ? Mixart.brand : Mixart.surfaceHi;
    final corTexto = p.ouro ? Mixart.onBrand : Mixart.text;
    final corFeita = p.ouro ? Mixart.onBrand.withValues(alpha: .45) : Mixart.brand;
    final n = p.digitadas;
    final len = p.texto.length;
    final feitas = p.texto.substring(0, n);
    final prox = n < len ? p.texto[n] : '';
    final resto = n + 1 < len ? p.texto.substring(n + 1) : '';

    final traducao = BancoArcade.soDigitacao ? _vocab?.traducao(p.texto) : null;
    final chip = _chipPalavra(p, ehAlvo, perigo, corFundo, corTexto, corFeita, feitas, prox, resto);
    if (traducao == null) return chip;
    // inglês: a tradução embaixo (o chip fica em cima — a mira e os tiros continuam batendo nele)
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      chip,
      Padding(
        padding: const EdgeInsets.only(left: 8, top: 3),
        child: LegendaTraducao(
          traducao,
          tamanho: 12,
          maxLargura: 170,
          textAlign: TextAlign.left,
          cor: p.ouro ? Mixart.brand : const Color(0xFFE8ECF0),
          fundo: const Color(0xB310131A),
        ),
      ),
    ]);
  }

  Widget _chipPalavra(PalavraCaindo p, bool ehAlvo, bool perigo, Color corFundo, Color corTexto, Color corFeita,
      String feitas, String prox, String resto) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ehAlvo
              ? (p.ouro ? Mixart.text : Mixart.brand)
              : perigo
                  ? Mixart.danger
                  : Mixart.border,
          width: ehAlvo ? 2 : 1,
        ),
        boxShadow: [
          // flutua sobre o palco
          const BoxShadow(color: Color(0x80000000), blurRadius: 10, offset: Offset(0, 5)),
          if (ehAlvo) BoxShadow(color: Mixart.brandDim, blurRadius: 12),
          if (perigo) BoxShadow(color: Mixart.danger.withValues(alpha: .35), blurRadius: 10),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (p.ouro)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text('4X',
                style: Mixart.ui(size: 9, weight: FontWeight.w800, color: Mixart.onBrand)
                    .copyWith(letterSpacing: 1)),
          ),
        Text.rich(
          TextSpan(children: [
            // já atingidas: preenchem de amarelo (nada de riscar — atrapalha ler)
            TextSpan(
                text: feitas,
                style: TextStyle(color: corFeita, fontWeight: FontWeight.w800)),
            // a próxima letra do alvo ganha um cursor
            TextSpan(
              text: prox,
              style: ehAlvo
                  ? TextStyle(
                      color: p.ouro ? Mixart.brand : Mixart.onBrand,
                      backgroundColor: p.ouro ? Mixart.onBrand : Mixart.brand,
                      fontWeight: FontWeight.w800,
                    )
                  : TextStyle(color: corTexto),
            ),
            TextSpan(text: resto, style: TextStyle(color: corTexto)),
          ]),
          style: Mixart.mono(size: 15.5, weight: FontWeight.w600),
        ),
      ]),
    );
  }
}

/// Tiros com rastro: cabeça brilhante e cauda que esmaece.
class _TirosPainter extends CustomPainter {
  final List<(Offset, Offset, double)> tiros;
  final Color cor;
  _TirosPainter({required this.tiros, required this.cor});

  @override
  void paint(Canvas c, Size s) {
    for (final (de, ate, t) in tiros) {
      final pos = Offset.lerp(de, ate, t)!;
      final cauda = Offset.lerp(de, ate, (t - .14).clamp(0, 1))!;
      c.drawLine(
        cauda,
        pos,
        Paint()
          ..shader = ui.Gradient.linear(cauda, pos, [cor.withValues(alpha: 0), cor.withValues(alpha: .9)])
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      c.drawCircle(pos, 7, Paint()..color = cor.withValues(alpha: .35)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5));
      c.drawCircle(pos, 4.2, Paint()..color = cor);
      c.drawCircle(pos - const Offset(1.2, 1.2), 1.6, Paint()..color = Colors.white.withValues(alpha: .9));
    }
  }

  @override
  bool shouldRepaint(_TirosPainter old) => true;
}

/// Linha tracejada e discreta do atirador até a palavra travada.
class _MiraPainter extends CustomPainter {
  final Offset de, ate;
  final Color cor;
  _MiraPainter({required this.de, required this.ate, required this.cor});

  @override
  void paint(Canvas c, Size s) {
    final tinta = Paint()
      ..color = cor.withValues(alpha: .55)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final total = (ate - de).distance;
    if (total < 1) return;
    final dir = (ate - de) / total;
    const traco = 7.0, vao = 6.0;
    for (double d = 0; d < total; d += traco + vao) {
      final fim = math.min(d + traco, total);
      c.drawLine(de + dir * d, de + dir * fim, tinta);
    }
  }

  @override
  bool shouldRepaint(_MiraPainter old) => old.de != de || old.ate != ate || old.cor != cor;
}
