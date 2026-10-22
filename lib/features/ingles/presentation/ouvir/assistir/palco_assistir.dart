import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/mixart.dart';
import '../../../../arcade/domain/historia_turismo.dart';
import '../../../../arcade/presentation/historia/palco_historia.dart';
import '../../../../arcade/presentation/historia/roteiro_visivel.dart';
import '../../../../curso/domain/curriculo.dart';
import '../../../data/voz_ingles.dart';
import '../../../domain/assistir/compasso_assistir.dart';
import '../../../domain/assistir/historia_licao.dart';
import '../../../domain/assistir/historias_licoes.dart';
import '../../../domain/config_ouvir.dart';
import '../../../domain/fila_ouvir.dart';
import '../mini_player.dart' show ImagemDaFaixa;
import '../ouvir_cubit.dart';
import '../ouvir_state.dart';
import 'memoria_assistir.dart';
import 'roteiro_seguidor.dart';

/// 📺 O palco do "Escutar assistindo" dentro do "Tocando agora": o desenho animado da lição que segue o
/// 🎧 Ouvir (o `RoteiroSeguidor` + o `PalcoHistoria` do Turismo), com bolinhas, véus e o ⛶.
///
/// Keys: `assistir-palco` (raiz), `assistir-bolinhas`, `assistir-tela-cheia`, `assistir-titulo`,
/// `assistir-especial`, `assistir-pausado`, `assistir-timer`, `assistir-fim`, `assistir-sem-desenho`,
/// `assistir-carregando`. Quem monta (o `TocandoPage`) passa uma `GlobalKey` guardada no State, para o palco
/// sobreviver à troca de layout de 900 px e ao ⛶.
///
/// Sem voz e sem `Timer`: o seguidor recebe cada emit do cubit (o 1º no initState), cada `VozIngles.falando` e
/// o relógio de UM `Ticker` (do `TickerProviderStateMixin`: o `TickerMode` do Navigator o cala só quando a rota
/// fica coberta por uma rota opaca). O Ticker só anda tocando, com o app visível e com o palco dentro da área
/// visível da página que rola (rolado para fora, ele para; ver [_PalcoAssistirState._conferirVisivel]); "reduzir animações" = passos
/// de 100 ms, sem andar nem esmaecer. Tocar no palco = ⏯ (no fim, ▶ de novo). O palco não pega o foco
/// (`ExcludeFocus`); o ⛶ e as bolinhas entram no Tab.
class PalcoAssistir extends StatefulWidget {
  const PalcoAssistir({
    super.key,
    required this.cubit,
    required this.trilhas,
    this.grande = false,
    this.onTelaCheia,
    this.historias,
  });

  final OuvirCubit cubit;
  final List<Trilha> trilhas;

  /// Layout da ⛶ tela cheia (barra compacta própria).
  final bool grande;

  /// null = sem botão ⛶.
  final VoidCallback? onTelaCheia;

  /// Injeção nos testes; padrão HistoriasLicoes.de(trilhas).
  final HistoriasLicoes? historias;

  /// Quanto o palco espera pela história autoral da trilha que está chegando (I6), mostrando a foto.
  static const esperaDaAutoral = .4;

  /// A faixa tem desenho (lição do curso, não própria)?
  static bool podeAssistir(Faixa f, List<Trilha> trilhas) {
    if (f.licaoId.isEmpty) return false;
    final onde = IndiceOuvir.de(trilhas).licao(f.licaoId);
    return onde != null && !trilhas[onde.t].propria;
  }

  @override
  State<PalcoAssistir> createState() => _PalcoAssistirState();
}

class _PalcoAssistirState extends State<PalcoAssistir> with TickerProviderStateMixin, WidgetsBindingObserver {
  late HistoriasLicoes _historias = widget.historias ?? HistoriasLicoes.de(widget.trilhas);
  late final MemoriaAssistir _memoria = MemoriaAssistir.de(widget.cubit);
  late final RoteiroSeguidor _seguidor;
  late final Ticker _ticker;
  Duration _ultimoTique = Duration.zero;

  bool _reduzir = false, _oculto = false;

  /// O palco rolado para fora da área visível da página (o `Scrollable` em volta): o relógio para.
  bool _foraDaTela = false;
  ScrollPosition? _rolagem;
  bool _conferenciaAgendada = false;

  /// Esperando a autoral (até [PalcoAssistir.esperaDaAutoral]); o seguidor só nasce depois.
  bool _esperando = false;
  double _espera = 0;

  /// Relógio do palco (s) e o acumulado do "reduzir".
  double _relogio = 0, _acumulado = 0;

  /// O relógio em degraus de 1/30 s (no "reduzir", um degrau a cada passo de 100 ms): o idle e a boca repintam
  /// só quando ele vira; o resto (ação, letras, corte) vem das notificações do seguidor.
  final _quadro = ValueNotifier<double>(0);
  late final Listenable _redesenho = Listenable.merge([_seguidor, _quadro]);

  /// O que a moldura de fora mostra (sem desenho, título): muda pouco, rebuild só quando muda.
  HistoriaLicao? _historiaVista;
  bool _semDesenhoVisto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_aoTique);
    _seguidor = RoteiroSeguidor(
      historiaDe: (f) => _historias.para(f),
      memoria: _memoria,
      configDaFaixa: (i) {
        final c = widget.cubit.configDaFaixa;
        return c != null && c.indice == i ? c.config : null;
      },
    )..addListener(_aoMudar);
    final f = widget.cubit.state.atual;
    _esperando = f != null && f.licaoId.isNotEmpty && _historias.carregando(f.licaoId);
    if (!_esperando) _nascer();
    VozIngles.falando.addListener(_aoFalar);
    _sincronizar();
  }

  /// O 1º estado (o BlocListener não entrega o estado inicial, P10) e a voz em curso.
  void _nascer() {
    _esperando = false;
    _seguidor.aoEstado(widget.cubit.state);
    _seguidor.aoFalar(VozIngles.falando.value);
    _historiaVista = _seguidor.historia;
    _semDesenhoVisto = _semDesenho;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (r != _reduzir) {
      _reduzir = r;
      _seguidor.reduzir = r;
    }
    // a página que rola em volta (no ⛶ não há): a cada rolagem, confere se o palco ainda aparece
    final rolagem = Scrollable.maybeOf(context)?.position;
    if (!identical(rolagem, _rolagem)) {
      _rolagem?.removeListener(_agendarConferencia);
      _rolagem = rolagem?..addListener(_agendarConferencia);
      _agendarConferencia();
    }
  }

  @override
  void didUpdateWidget(PalcoAssistir old) {
    super.didUpdateWidget(old);
    if (!identical(old.historias, widget.historias) || !identical(old.trilhas, widget.trilhas)) {
      _historias = widget.historias ?? HistoriasLicoes.de(widget.trilhas);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rolagem?.removeListener(_agendarConferencia);
    VozIngles.falando.removeListener(_aoFalar);
    _ticker.dispose();
    _quadro.dispose();
    _seguidor
      ..removeListener(_aoMudar)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _oculto = state == AppLifecycleState.hidden || state == AppLifecycleState.paused;
    _sincronizar();
  }

  /// Confere a visibilidade depois do quadro (o layout já com a rolagem nova); várias rolagens no mesmo quadro
  /// viram uma conferência só.
  void _agendarConferencia() {
    if (_conferenciaAgendada) return;
    _conferenciaAgendada = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _conferenciaAgendada = false;
      _conferirVisivel();
    });
    // parado (sem Ticker), a rolagem já agenda o quadro; garante um quadro mesmo assim
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// O palco está fora da área visível do `Scrollable` em volta? (sem `Scrollable`, ou sem layout ainda: visível)
  void _conferirVisivel() {
    if (!mounted) return;
    var fora = false;
    final eu = context.findRenderObject();
    final vp = _rolagem == null ? null : Scrollable.maybeOf(context)?.context.findRenderObject();
    if (eu is RenderBox && vp is RenderBox && eu.attached && vp.attached && eu.hasSize && vp.hasSize) {
      final r = MatrixUtils.transformRect(eu.getTransformTo(vp), Offset.zero & eu.size);
      fora = !r.overlaps(Offset.zero & vp.size);
    }
    if (fora != _foraDaTela) {
      _foraDaTela = fora;
      _sincronizar();
    }
  }

  // ───────────────────────── entradas

  void _aoEstado(OuvirState st) {
    if (_esperando) return; // o seguidor nasce com o estado de quando a espera acabar
    _seguidor.aoEstado(st);
    _sincronizar();
  }

  void _aoFalar() {
    if (!_esperando) _seguidor.aoFalar(VozIngles.falando.value);
  }

  bool get _semDesenho {
    final f = widget.cubit.state.atual;
    return f != null && (!PalcoAssistir.podeAssistir(f, widget.trilhas) || _seguidor.historia == null);
  }

  /// A moldura de fora (sem desenho / título) só reconstrói quando a história muda.
  void _aoMudar() {
    if (!mounted) return;
    final h = _seguidor.historia;
    final sem = _semDesenho;
    if (!identical(h, _historiaVista) || sem != _semDesenhoVisto) {
      _historiaVista = h;
      _semDesenhoVisto = sem;
      setState(() {});
    }
  }

  // ───────────────────────── relógio

  void _sincronizar() {
    if (!mounted) return;
    final andar = !_oculto && !_foraDaTela && (_esperando || _seguidor.precisaDeRelogio);
    if (andar && !_ticker.isActive) {
      _ultimoTique = Duration.zero;
      _ticker.start();
    } else if (!andar && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _aoTique(Duration decorrido) {
    final real = (decorrido - _ultimoTique).inMicroseconds / 1e6;
    final dt = real.clamp(0.0, .1);
    _ultimoTique = decorrido;
    if (dt <= 0 || !mounted) return;
    if (_esperando) {
      _espera += real; // a espera conta o relógio de verdade (um quadro longo não a estica)
      final f = widget.cubit.state.atual;
      if (f == null || !_historias.carregando(f.licaoId) || _espera >= PalcoAssistir.esperaDaAutoral) {
        setState(_nascer);
      }
      _sincronizar();
      return;
    }
    if (_reduzir) {
      // 10 passos por segundo, sem animação entre eles
      _acumulado += dt;
      while (_acumulado >= .1) {
        _acumulado -= .1;
        _seguidor.tick(.1);
        _quadro.value += .1; // a boca da voz em degraus de 100 ms (o palco recebe relógio 0)
      }
    } else {
      _relogio += dt;
      _seguidor.tick(dt);
      _quadro.value = (_relogio * 30).floor() / 30;
    }
    _sincronizar();
  }

  // ───────────────────────── comandos

  void _tocarNoPalco() {
    final c = widget.cubit;
    final st = c.state;
    final fonte = st.fonte;
    if (st.status == StatusOuvir.acabou && fonte != null) {
      unawaited(c.tocar(fonte, st.fila));
    } else if (st.status != StatusOuvir.parado) {
      c.alternar();
    }
  }

  // ───────────────────────── UI

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('assistir-palco'),
      child: BlocListener<OuvirCubit, OuvirState>(
        bloc: widget.cubit,
        listener: (_, st) => _aoEstado(st),
        child: BlocBuilder<OuvirCubit, OuvirState>(
          bloc: widget.cubit,
          buildWhen: (a, b) =>
              a.status != b.status ||
              a.motivo != b.motivo ||
              a.indice != b.indice ||
              !identical(a.fila, b.fila) ||
              a.fase != b.fase ||
              a.fonte != b.fonte,
          builder: (context, st) => LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth.isFinite ? c.maxWidth : 640.0;
            final h = c.maxHeight.isFinite ? c.maxHeight : w * .56;
            return SizedBox(width: w, height: h, child: _conteudo(st, w, h));
          }),
        ),
      ),
    );
  }

  Widget _conteudo(OuvirState st, double w, double h) {
    final f = st.atual;
    if (f == null) return const SizedBox.shrink();
    if (_esperando) {
      return KeyedSubtree(
        key: const Key('assistir-carregando'),
        child: ImagemDaFaixa(faixa: f, largura: w, altura: h, comRosto: false),
      );
    }
    if (_semDesenho) return _semDesenhoDe(f, w, h);
    // a faixa de baixo tem altura de alvo de toque (bolinhas e ⛶ com ≥ 24×40)
    final barra = (40.0 * MediaQuery.textScalerOf(context).scale(1)).clamp(40.0, 48.0);
    return ColoredBox(
      color: const Color(0xFF0E0E14),
      child: Column(
        children: [
          Expanded(child: _palco(st)),
          SizedBox(height: barra, child: _barra(st, f)),
        ],
      ),
    );
  }

  Widget _semDesenhoDe(Faixa f, double w, double h) {
    return KeyedSubtree(
      key: const Key('assistir-sem-desenho'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImagemDaFaixa(faixa: f, largura: w, altura: h, comRosto: false),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Center(
              child: _Selo(
                texto: 'Sem desenho para esta frase (ela não é de uma lição do curso)',
                fundo: Colors.black.withValues(alpha: .62),
              ),
            ),
          ),
        ],
      ),
    );
  }

  CabecalhoPalco _cabecalho(Faixa f, HistoriaLicao? h) {
    final nome = f.licaoNome;
    final etapa = _etapaCurta(f.etapa);
    return CabecalhoPalco(
      sobretitulo: ['🎬', if (etapa.isNotEmpty) '$etapa ·', f.trilhaNome].join(' '),
      titulo: h?.titulo ?? TextoBilingue(nome, nome),
      rotuloSemantico: 'Desenho animado: ${[f.licaoEmoji, nome].where((s) => s.isNotEmpty).join(' ')}',
    );
  }

  static String _etapaCurta(String etapa) {
    final e = etapa.trim();
    final i = e.indexOf(' ');
    return i > 0 ? e.substring(0, i) : e;
  }

  Widget _palco(OuvirState st) {
    final f = st.atual!;
    final cab = _cabecalho(f, _seguidor.historia);
    final pausado = st.status == StatusOuvir.pausado;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tocarNoPalco,
            // o ⏯ rotulado é o do player; o toque no desenho é atalho (sem um "botão" sem nome no leitor de tela)
            excludeFromSemantics: true,
            child: RepaintBoundary(
              child: ListenableBuilder(
                listenable: _redesenho,
                builder: (context, _) => PalcoHistoria(
                  roteiro: _seguidor,
                  relogio: _reduzir ? 0 : _quadro.value,
                  cabecalho: cab,
                  reduzir: _reduzir,
                  balaoSemCorte: true,
                  // fora do ⛶ o "Tocando agora" mostra o PT logo abaixo do palco
                  ptNaPagina: !widget.grande,
                ),
              ),
            ),
          ),
        ),
        if (pausado && st.motivo == MotivoPausa.timer)
          _Veu(chave: 'assistir-timer', texto: '🌙 Timer acabou', onTap: _tocarNoPalco)
        else if (pausado)
          _Veu(chave: 'assistir-pausado', texto: '⏸ Pausado: toque para continuar', onTap: _tocarNoPalco)
        else if (st.status == StatusOuvir.acabou)
          _Veu(chave: 'assistir-fim', texto: '🏁 Fim: ▶ de novo', onTap: _tocarNoPalco),
        if (widget.grande && st.status == StatusOuvir.tocando && st.fase == FaseOuvir.suaVez)
          Positioned(
            top: 10,
            right: 10,
            child: IgnorePointer(
              child: _Selo(
                key: const Key('assistir-sua-vez'),
                texto: '🗣️ Sua vez',
                fundo: Mixart.brand,
                cor: Mixart.onBrand,
              ),
            ),
          ),
      ],
    );
  }

  Widget _barra(OuvirState st, Faixa f) {
    final h = _seguidor.historia;
    final autoral = h?.autoral ?? false;
    final etapa = _etapaCurta(f.etapa);
    final titulo = autoral ? (h!.titulo?.pt ?? f.licaoNome) : f.licaoNome;
    // o 🎬 (claquete escura) some na faixa quase preta e parece um glifo quebrado: só entra sem o emoji da lição
    final texto = [f.licaoEmoji.isNotEmpty ? f.licaoEmoji : '🎬', titulo].join(' ') + (etapa.isEmpty ? '' : ' · $etapa');
    final (:inicio, :fim) = CompassoAssistir.licaoDaFaixa(st.fila, st.indice);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(builder: (context, cons) => Row(
        children: [
          Flexible(
            flex: 5,
            child: Semantics(
              label: autoral ? 'História especial: $titulo' : null,
              child: Row(
                key: const Key('assistir-titulo'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (autoral)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _Selo(
                          key: const Key('assistir-especial'),
                          // celular em pé: só o ✨ (o nome da lição cabe; a Semantics diz "História especial")
                          texto: cons.maxWidth < 480 ? '✨' : '✨ história especial',
                          fundo: Mixart.brand,
                          cor: Mixart.onBrand,
                          pequeno: true,
                        ),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      texto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: _Bolinhas(
              inicio: inicio,
              fim: fim,
              indice: st.indice,
              onIrPara: widget.cubit.irPara,
            ),
          ),
          if (widget.onTelaCheia != null)
            IconButton(
              key: const Key('assistir-tela-cheia'),
              tooltip: widget.grande ? 'Sair da tela cheia do desenho' : 'Desenho em tela cheia',
              onPressed: widget.onTelaCheia,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 40),
              iconSize: 22,
              color: Colors.white,
              icon: Icon(widget.grande ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
            ),
        ],
      )),
    );
  }
}

/// As bolinhas das frases da lição atual na fila: tocar = ir para a frase.
class _Bolinhas extends StatelessWidget {
  const _Bolinhas({required this.inicio, required this.fim, required this.indice, required this.onIrPara});

  final int inicio, fim, indice;
  final void Function(int) onIrPara;

  /// A caixa de toque de cada bolinha (a da frase atual é mais larga); o desenho fica no meio.
  static const larguraToque = 24.0, larguraToqueAtual = 32.0;

  @override
  Widget build(BuildContext context) {
    final n = fim - inicio;
    if (n <= 0) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, cons) {
      final precisa = (n - 1) * larguraToque + larguraToqueAtual;
      // não cabem com alvo de toque decente: "k/N" com ◀ ▶ (em vez de encolher as bolinhas)
      if (cons.maxWidth.isFinite && precisa > cons.maxWidth) return _compacto(n);
      return _bolinhas(n);
    });
  }

  Widget _compacto(int n) {
    final k = (indice - inicio).clamp(0, n - 1);
    Widget seta(String chave, String rotulo, IconData icone, int? alvo) => IconButton(
          key: Key(chave),
          tooltip: rotulo,
          onPressed: alvo == null ? null : () => onIrPara(alvo),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 40),
          iconSize: 20,
          color: Colors.white,
          disabledColor: Colors.white.withValues(alpha: .3),
          icon: Icon(icone),
        );
    // só num palco minúsculo nem isto cabe: aí encolhe (o último recurso)
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        key: const Key('assistir-bolinhas-compacto'),
        mainAxisSize: MainAxisSize.min,
        children: [
          seta('assistir-bolinha-antes', 'Frase anterior da lição', Icons.chevron_left_rounded,
              indice > inicio ? indice - 1 : null),
          Semantics(
            label: 'Frase ${k + 1} de $n',
            excludeSemantics: true,
            child: Text('${k + 1}/$n',
                maxLines: 1, style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Colors.white)),
          ),
          seta('assistir-bolinha-depois', 'Próxima frase da lição', Icons.chevron_right_rounded,
              indice < fim - 1 ? indice + 1 : null),
        ],
      ),
    );
  }

  Widget _bolinhas(int n) {
    return Row(
      key: const Key('assistir-bolinhas'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var j = inicio; j < fim; j++)
          Semantics(
            button: true,
            selected: j == indice,
            label: 'Frase ${j - inicio + 1} de $n',
            child: InkResponse(
              key: Key('assistir-bolinha-$j'),
              onTap: () => onIrPara(j),
              radius: 16,
              child: SizedBox(
                width: j == indice ? larguraToqueAtual : larguraToque,
                height: 40,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: j == indice ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: j == indice
                          ? Mixart.brand
                          : (j < indice ? Colors.white.withValues(alpha: .7) : Colors.white.withValues(alpha: .28)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// O véu de pausa / timer / fim por cima do palco (tocar = ⏯ ou ▶ de novo).
class _Veu extends StatelessWidget {
  const _Veu({required this.chave, required this.texto, required this.onTap});

  final String chave, texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ExcludeFocus(
        child: GestureDetector(
          key: Key(chave),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: .38)),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _Selo(texto: texto, fundo: Colors.black.withValues(alpha: .7), grande: true),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Um selo arredondado com texto (avisos, "✨ história especial", "🗣️ Sua vez").
class _Selo extends StatelessWidget {
  const _Selo({super.key, required this.texto, required this.fundo, this.cor = Colors.white, this.grande = false, this.pequeno = false});

  final String texto;
  final Color fundo, cor;
  final bool grande, pequeno;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(Mixart.radiusChip)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: pequeno ? 8 : 12, vertical: pequeno ? 2 : 6),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          maxLines: pequeno ? 1 : 3,
          overflow: TextOverflow.ellipsis,
          style: Mixart.ui(size: grande ? 15 : (pequeno ? 11 : 13), weight: FontWeight.w800, color: cor),
        ),
      ),
    );
  }
}
