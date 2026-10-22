import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/mixart.dart';
import '../../../ingles/data/voz_ingles.dart';
import '../../../ingles/domain/saida_audio.dart';
import '../../domain/historia_turismo.dart';
import '../../domain/progresso_historia.dart';
import '../../domain/progresso_turismo.dart';
import 'creditos_historia.dart';
import 'palco_historia.dart';
import 'roteiro_historia.dart';

/// Como o player fechou.
enum FimDoPlayer { assistido, pulado }

/// Abre a cena (abertura ou chegada) do [capitulo] numa rota de tela cheia opaca e espera fechar.
/// null = rota fechada pelo Voltar do sistema/navegador (tratado como pulado; marca visto).
Future<FimDoPlayer?> abrirCenaDaHistoria(BuildContext context,
    {required CapituloHistoria capitulo, required ParteDoCapitulo parte, VozIngles? voz, bool creditos = false}) {
  final reduzir = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  final dur = reduzir ? Duration.zero : const Duration(milliseconds: 260);
  return Navigator.of(context).push<FimDoPlayer>(PageRouteBuilder<FimDoPlayer>(
    opaque: true,
    transitionDuration: dur,
    reverseTransitionDuration: dur,
    pageBuilder: (context, _, _) => PlayerHistoria(
      capitulo: capitulo,
      parte: parte,
      voz: voz,
      creditos: creditos,
      onFim: (fim) => Navigator.of(context).maybePop(fim),
    ),
    transitionsBuilder: (context, anim, _, child) => FadeTransition(opacity: anim, child: child),
  ));
}

/// 📖 O player do desenho animado da história.
///
/// Monta o [PalcoHistoria] com um [RoteiroHistoria] e UM relógio (um `Ticker` que só roda enquanto o
/// roteiro anda: para em pausa, nos cartões finais e com a página oculta; com "reduzir animações" vira um
/// passo de 100 ms sem quadros de animação). Barra: ⏸ · PT · 🔊 · 🐢 · ⏪ · progresso · Pular ⏭. Teclado:
/// Espaço/Enter avança, Esc pula, T/V/L/P/R. Cartões finais: "🔑 Words from the story" + "🏁 Race!" na
/// abertura; "To be continued…" com o gancho na chegada; créditos no fim da história.
class PlayerHistoria extends StatefulWidget {
  const PlayerHistoria({
    super.key,
    required this.capitulo,
    required this.parte,
    this.voz,
    this.creditos = false,
    this.onFim,
  });

  final CapituloHistoria capitulo;
  final ParteDoCapitulo parte;
  final VozIngles? voz;
  final bool creditos;
  final void Function(FimDoPlayer)? onFim;

  @override
  State<PlayerHistoria> createState() => _PlayerHistoriaState();
}

class _PlayerHistoriaState extends State<PlayerHistoria> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final VozIngles _voz = widget.voz ?? VozIngles();
  final _foco = FocusNode(debugLabel: 'historia');
  /// Criado já no initState: criar o Ticker preguiçoso dentro do dispose (Voltar no gate do "▶ Assistir")
  /// procura o TickerMode num elemento já desativado.
  late final Ticker _ticker;
  Timer? _passoReduzido;
  Duration _ultimoTique = Duration.zero;

  RoteiroHistoria? _roteiro;
  bool _reduzirSistema = false, _tremor = true;
  bool _fechou = false, _assistiu = false, _pausadoPorOculto = false, _oculto = false;

  /// Relógio do palco (s) e o mesmo em degraus de 1/30 s (o idle repinta a 30 fps).
  double _relogio = 0, _relogioQuadro = 0;

  bool get _reduzir => _reduzirSistema || !_tremor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_aoTique);
    _carregar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduzirSistema = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  Future<void> _carregar() async {
    final pt = await ProgressoHistoria.traducao();
    final voz = await ProgressoHistoria.voz();
    final velocidade = await ProgressoHistoria.velocidade();
    final tremor = await ProgressoTurismo.tremorLigado();
    if (!mounted) return;
    _tremor = tremor;
    final r = RoteiroHistoria(
      cenas: widget.capitulo.parte(widget.parte),
      nivel: widget.capitulo.nivel,
      voz: _voz,
      vozLigada: voz,
      lenta: velocidade < 1,
      velocidade: velocidade,
      mostrarPt: pt,
      reduzir: _reduzir,
    )..addListener(_aoMudar);
    setState(() => _roteiro = r);
    if (_voz.somLiberado) r.tocar();
    _foco.requestFocus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passoReduzido?.cancel();
    _ticker.dispose();
    _roteiro?.removeListener(_aoMudar);
    _roteiro?.dispose();
    _foco.dispose();
    // reserva: o normal é o PopScope já ter feito isto no instante do pop
    _fecharPeloVoltar();
    super.dispose();
  }

  /// Voltar do sistema/navegador: conta como visto. Roda no pop (antes de quem abriu a cena continuar e
  /// reler o que foi visto), para a voz e o relógio na hora — não só no dispose, que vem depois da
  /// transição de saída.
  void _fecharPeloVoltar() {
    if (_fechou) return;
    _fechou = true;
    if (_ticker.isActive) _ticker.stop();
    _passoReduzido?.cancel();
    _passoReduzido = null;
    _voz.parar();
    ProgressoHistoria.marcarVisto(widget.capitulo.pista, widget.parte, assistido: _assistiu);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final r = _roteiro;
    final oculto = state == AppLifecycleState.hidden || state == AppLifecycleState.paused;
    _oculto = oculto;
    if (r == null) return;
    if (oculto && r.estado != EstadoRoteiro.pausado) {
      final antes = r.estado;
      r.pausar();
      _pausadoPorOculto = r.estado == EstadoRoteiro.pausado && antes != EstadoRoteiro.pausado;
    } else if (state == AppLifecycleState.resumed && _pausadoPorOculto) {
      _pausadoPorOculto = false;
      r.continuar();
    }
    _sincronizarRelogio();
  }

  // ───────────────────────── relógio

  void _aoMudar() {
    final r = _roteiro;
    if (r == null || !mounted) return;
    if (r.estado == EstadoRoteiro.cartaoFinal && !_assistiu) {
      _assistiu = true;
      ProgressoHistoria.marcarVisto(widget.capitulo.pista, widget.parte, assistido: true);
    }
    if (r.estado == EstadoRoteiro.terminado && !_fechou) {
      _fechar(_assistiu ? FimDoPlayer.assistido : FimDoPlayer.pulado);
      return;
    }
    _sincronizarRelogio();
    setState(() {});
  }

  bool get _andando {
    final r = _roteiro;
    if (r == null || _oculto) return false;
    return r.estado == EstadoRoteiro.entrando || r.estado == EstadoRoteiro.falando || r.estado == EstadoRoteiro.lendo;
  }

  void _sincronizarRelogio() {
    if (!mounted) return;
    final andar = _andando;
    if (_reduzir) {
      if (_ticker.isActive) _ticker.stop();
      if (andar && _passoReduzido == null) {
        _passoReduzido = Timer.periodic(const Duration(milliseconds: 100), (_) {
          if (!mounted) return;
          _roteiro?.tick(.1);
          if (mounted) setState(() {});
        });
      } else if (!andar) {
        _passoReduzido?.cancel();
        _passoReduzido = null;
      }
      return;
    }
    _passoReduzido?.cancel();
    _passoReduzido = null;
    if (andar && !_ticker.isActive) {
      _ultimoTique = Duration.zero;
      _ticker.start();
    } else if (!andar && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _aoTique(Duration decorrido) {
    final dt = ((decorrido - _ultimoTique).inMicroseconds / 1e6).clamp(0.0, .1);
    _ultimoTique = decorrido;
    if (dt <= 0) return;
    _relogio += dt;
    _roteiro?.tick(dt);
    final q = (_relogio * 30).floor() / 30;
    if (q != _relogioQuadro && mounted) setState(() => _relogioQuadro = q);
  }

  // ───────────────────────── comandos

  void _fechar(FimDoPlayer fim) {
    if (_fechou) return;
    _fechou = true;
    _ticker.stop();
    _passoReduzido?.cancel();
    _passoReduzido = null;
    _voz.parar();
    if (fim == FimDoPlayer.pulado) ProgressoHistoria.marcarVisto(widget.capitulo.pista, widget.parte);
    widget.onFim?.call(fim);
  }

  void _pular() {
    if (_fechou) return;
    if (_assistiu) {
      _fechar(FimDoPlayer.assistido);
      return;
    }
    _fechar(FimDoPlayer.pulado);
    _roteiro?.pular();
  }

  void _concluir() => _fechar(FimDoPlayer.assistido);

  void _avancar() {
    final r = _roteiro;
    if (r == null || _fechou) return;
    if (r.estado == EstadoRoteiro.cartaoFinal) {
      _concluir();
    } else {
      r.tocarOuAvancar();
    }
  }

  void _alternarPausa() {
    final r = _roteiro;
    if (r == null) return;
    _pausadoPorOculto = false;
    if (r.estado == EstadoRoteiro.pausado) {
      r.continuar();
    } else {
      r.pausar();
    }
  }

  void _alternarPt() {
    final r = _roteiro;
    if (r == null) return;
    r.alternarPt();
    ProgressoHistoria.salvarTraducao(r.mostrarPt);
  }

  void _alternarVoz() {
    final r = _roteiro;
    if (r == null) return;
    r.alternarVoz();
    ProgressoHistoria.salvarVoz(r.vozLigada);
  }

  void _alternarLenta() {
    final r = _roteiro;
    if (r == null) return;
    r.alternarLenta();
    ProgressoHistoria.salvarVelocidade(r.velocidade);
  }

  void _ouvir(String en) {
    final r = _roteiro;
    try {
      _voz.falarNoPlayer(en, fator: r?.velocidade ?? 1.0).catchError((_) => FimDaFala.semVoz);
    } catch (_) {}
  }

  KeyEventResult _tecla(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _avancar();
    } else if (k == LogicalKeyboardKey.escape) {
      _pular();
    } else if (k == LogicalKeyboardKey.keyT) {
      _alternarPt();
    } else if (k == LogicalKeyboardKey.keyV) {
      _alternarVoz();
    } else if (k == LogicalKeyboardKey.keyL) {
      _alternarLenta();
    } else if (k == LogicalKeyboardKey.keyP) {
      _alternarPausa();
    } else if (k == LogicalKeyboardKey.keyR) {
      _roteiro?.repetir();
    } else if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyB) {
      _roteiro?.voltar();
    } else if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyN) {
      _roteiro?.proximaFala();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ───────────────────────── UI

  bool get _mostraCreditos =>
      widget.creditos &&
      widget.parte == ParteDoCapitulo.fim &&
      (_roteiro?.estado == EstadoRoteiro.cartaoFinal || _roteiro?.estado == EstadoRoteiro.terminado);

  @override
  Widget build(BuildContext context) {
    final r = _roteiro;
    return PopScope<Object?>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _fecharPeloVoltar();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E14),
        body: SafeArea(
          child: Focus(
            focusNode: _foco,
            autofocus: true,
            onKeyEvent: _tecla,
            child: r == null
                ? const SizedBox.expand()
                : _mostraCreditos
                    ? CreditosHistoria(onFim: _concluir, reduzir: _reduzir)
                    : Column(
                        children: [
                          Expanded(child: _palco(r)),
                          _Barra(
                            roteiro: r,
                            onPausa: _alternarPausa,
                            onPt: _alternarPt,
                            onVoz: _alternarVoz,
                            onLenta: _alternarLenta,
                            onRepetir: r.repetir,
                            onVoltar: r.voltar,
                            onProxima: r.proximaFala,
                            onIrPara: r.irParaFala,
                            onPular: _pular,
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _palco(RoteiroHistoria r) {
    final cartao = r.estado == EstadoRoteiro.cartaoFinal || r.estado == EstadoRoteiro.terminado;
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            button: true,
            label: 'Avançar (Espaço ou Enter)',
            child: GestureDetector(
              key: const Key('historia-avancar'),
              behavior: HitTestBehavior.opaque,
              onTap: _avancar,
              child: ValueListenableBuilder<FalaEmCurso?>(
                valueListenable: VozIngles.falando,
                builder: (context, _, _) => PalcoHistoria(
                  roteiro: r,
                  relogio: _reduzir ? 0 : _relogioQuadro,
                  capitulo: widget.capitulo,
                  reduzir: _reduzir,
                ),
              ),
            ),
          ),
        ),
        if (r.estado == EstadoRoteiro.aguardandoGesto) Positioned.fill(child: _gate(r)),
        if (r.estado == EstadoRoteiro.pausado)
          Positioned(
            top: 10,
            right: 10,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(Mixart.radiusChip),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text('⏸ Pausado', style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
        if (cartao) Positioned.fill(child: _cartaoFinal(r)),
      ],
    );
  }

  Widget _gate(RoteiroHistoria r) {
    final c = widget.capitulo;
    return ColoredBox(
      color: Colors.black.withValues(alpha: .55),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CHAPTER ${c.pista}',
                  style: Mixart.display(size: 14, color: Mixart.brand).copyWith(letterSpacing: 3)),
              const SizedBox(height: 6),
              Text(c.titulo.en,
                  textAlign: TextAlign.center,
                  style: Mixart.display(size: 28, weight: FontWeight.w800, color: Colors.white)),
              Text(c.titulo.pt,
                  textAlign: TextAlign.center,
                  style: Mixart.ui(size: 14, color: Colors.white70).copyWith(fontStyle: FontStyle.italic)),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('historia-assistir'),
                style: FilledButton.styleFrom(
                  backgroundColor: Mixart.brand,
                  foregroundColor: Mixart.onBrand,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
                ),
                onPressed: r.tocar,
                child: Text('▶ Assistir', style: Mixart.ui(size: 18, weight: FontWeight.w800, color: Mixart.onBrand)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartaoFinal(RoteiroHistoria r) {
    final c = widget.capitulo;
    final intro = widget.parte == ParteDoCapitulo.intro;
    final gancho = c.gancho;
    final filhos = <Widget>[];
    if (intro) {
      filhos.addAll([
        Text('🔑 Words from the story', style: Mixart.display(size: 20, color: Mixart.text)),
        const SizedBox(height: 4),
        Text('Toque numa palavra para ouvir', style: Mixart.ui(size: 12, color: Mixart.textMuted)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final p in c.palavras)
              Semantics(
                button: true,
                label: '${p.en}: ${p.pt}',
                child: InkWell(
                  key: Key('historia-palavra-${p.en}'),
                  borderRadius: BorderRadius.circular(Mixart.radiusChip),
                  onTap: () => _ouvir(p.en),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Mixart.surfaceHi,
                      borderRadius: BorderRadius.circular(Mixart.radiusChip),
                      border: Border.all(color: Mixart.brandDim),
                    ),
                    child: ExcludeSemantics(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🔊 ${p.en}', style: Mixart.ui(size: 15, weight: FontWeight.w800, color: Mixart.text)),
                          Text(p.pt, style: Mixart.ui(size: 12, color: Mixart.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton(
          key: const Key('historia-correr'),
          style: FilledButton.styleFrom(
            backgroundColor: Mixart.brand,
            foregroundColor: Mixart.onBrand,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
          ),
          onPressed: _concluir,
          child: Text('🏁 Race!', style: Mixart.ui(size: 18, weight: FontWeight.w800, color: Mixart.onBrand)),
        ),
        const SizedBox(height: 4),
        Text('Enter', style: Mixart.ui(size: 11, color: Mixart.textFaint)),
      ]);
    } else if (gancho != null) {
      filhos.addAll([
        Text('To be continued…', style: Mixart.display(size: 22, color: Mixart.brand)),
        Text('Continua…', style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(fontStyle: FontStyle.italic)),
        const SizedBox(height: 14),
        Text('📖 ${gancho.en}',
            key: const Key('historia-gancho'),
            textAlign: TextAlign.center,
            style: Mixart.ui(size: 18, weight: FontWeight.w700, color: Mixart.text)),
        if (r.mostrarPt)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(gancho.pt,
                textAlign: TextAlign.center,
                style: Mixart.ui(size: 14, color: Mixart.textMuted).copyWith(fontStyle: FontStyle.italic)),
          ),
        const SizedBox(height: 14),
        Text('Próximo capítulo na pista ${c.pista + 1}', style: Mixart.ui(size: 13, color: Mixart.textMuted)),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('historia-continuar'),
          style: FilledButton.styleFrom(
            backgroundColor: Mixart.brand,
            foregroundColor: Mixart.onBrand,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
          ),
          onPressed: _concluir,
          child: Text('Continuar ▶', style: Mixart.ui(size: 16, weight: FontWeight.w800, color: Mixart.onBrand)),
        ),
      ]);
    } else {
      filhos.addAll([
        Text('THE END', style: Mixart.display(size: 30, weight: FontWeight.w800, color: Mixart.brand)),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('historia-continuar'),
          onPressed: _concluir,
          child: Text('Fechar ✓', style: Mixart.ui(size: 16, weight: FontWeight.w800, color: Mixart.onBrand)),
        ),
      ]);
    }
    final cartao = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DecoratedBox(
            key: const Key('historia-cartao-final'),
            decoration: BoxDecoration(
              color: Mixart.surface,
              borderRadius: BorderRadius.circular(Mixart.radiusLg),
              border: Border.all(color: Mixart.border),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8))],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(mainAxisSize: MainAxisSize.min, children: filhos),
            ),
          ),
        ),
      ),
    );
    return ColoredBox(
      color: Colors.black.withValues(alpha: .5),
      child: _reduzir
          ? cartao
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: .92, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Mixart.spring,
              builder: (context, s, child) => Transform.scale(scale: s, child: child),
              child: cartao,
            ),
    );
  }
}

/// A barra de controles: as bolinhas de progresso (uma por fala; toque para ir até ela) em cima e
/// ⏸/▶ · PT · 🔊 · 🐢 velocidade · ⏮ fala anterior · 🔁 repetir · ⏭ próxima fala · Pular embaixo.
class _Barra extends StatelessWidget {
  const _Barra({
    required this.roteiro,
    required this.onPausa,
    required this.onPt,
    required this.onVoz,
    required this.onLenta,
    required this.onRepetir,
    required this.onVoltar,
    required this.onProxima,
    required this.onIrPara,
    required this.onPular,
  });

  final RoteiroHistoria roteiro;
  final VoidCallback onPausa, onPt, onVoz, onLenta, onRepetir, onVoltar, onProxima, onPular;
  final ValueChanged<int> onIrPara;

  static String _vel(double v) => v == 1 ? '1×' : '${v.toString().replaceFirst(RegExp(r'^0'), '')}×';

  @override
  Widget build(BuildContext context) {
    final r = roteiro;
    final pausado = r.estado == EstadoRoteiro.pausado;
    return Material(
      color: Mixart.surface,
      child: LayoutBuilder(
        builder: (context, c) {
          final estreita = c.maxWidth < 420;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Fala ${r.falasPassadas} de ${r.totalFalas}. Toque numa bolinha para ir até a fala.',
                child: GestureDetector(
                  key: const Key('historia-bolinhas'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    final w = c.maxWidth - 16;
                    if (r.totalFalas <= 0 || w <= 0) return;
                    onIrPara(((d.localPosition.dx - 8) / w * r.totalFalas).floor().clamp(0, r.totalFalas - 1));
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                    child: CustomPaint(
                      size: const Size(double.infinity, 12),
                      painter: _BolinhasPainter(
                        total: r.totalFalas,
                        feitas: r.falasPassadas,
                        cor: Mixart.brand,
                        apagada: Mixart.textHint,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      _BotaoBarra(
                        chave: 'historia-pausa',
                        rotulo: pausado ? '▶' : '⏸',
                        dica: pausado ? 'Continuar (P)' : 'Pausar (P)',
                        onTap: onPausa,
                      ),
                      _BotaoBarra(
                        chave: 'historia-pt',
                        rotulo: 'PT',
                        dica: r.mostrarPt ? 'Esconder a tradução (T)' : 'Mostrar a tradução (T)',
                        ligado: r.mostrarPt,
                        onTap: onPt,
                      ),
                      _BotaoBarra(
                        chave: 'historia-voz',
                        rotulo: r.vozLigada ? '🔊' : '🔇',
                        dica: r.vozLigada ? 'Desligar a voz (V)' : 'Ligar a voz (V)',
                        ligado: r.vozLigada,
                        onTap: onVoz,
                      ),
                      _BotaoBarra(
                        chave: 'historia-lenta',
                        rotulo: '🐢${_vel(r.velocidade)}',
                        largura: 64,
                        dica: 'Velocidade da voz: ${_vel(r.velocidade)} — toque para mudar (L)',
                        onTap: onLenta,
                      ),
                      _BotaoBarra(
                        chave: 'historia-voltar',
                        rotulo: '⏮',
                        dica: 'Fala anterior (←)',
                        onTap: onVoltar,
                      ),
                      _BotaoBarra(chave: 'historia-repetir', rotulo: '🔁', dica: 'Repetir a fala (R)', onTap: onRepetir),
                      if (!estreita)
                        _BotaoBarra(
                          chave: 'historia-proxima',
                          rotulo: '⏭',
                          dica: 'Próxima fala (→)',
                          onTap: onProxima,
                        ),
                      const Spacer(),
                      Tooltip(
                        message: 'Pular o capítulo (Esc)',
                        child: TextButton(
                          key: const Key('historia-pular'),
                          onPressed: onPular,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(44, 44),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: estreita ? 64 : 96),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Pular ⏩',
                                  style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.brand)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BotaoBarra extends StatelessWidget {
  const _BotaoBarra({
    required this.chave,
    required this.rotulo,
    required this.dica,
    required this.onTap,
    this.ligado,
    this.largura = 40,
  });

  final String chave, rotulo, dica;
  final VoidCallback onTap;
  final double largura;

  /// Liga/desliga (PT, voz, 🐢); null = botão comum (pausa, repetir), sem estado de alternância.
  final bool? ligado;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: dica,
        // o rótulo do Semantics já leva a dica com o atalho: sem ler duas vezes
        excludeFromSemantics: true,
        child: Semantics(
          button: true,
          toggled: ligado,
          label: dica,
          child: InkResponse(
            key: Key(chave),
            onTap: onTap,
            radius: 22,
            child: SizedBox(
              width: largura,
              height: 44,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ExcludeSemantics(
                    child: Opacity(
                      opacity: ligado ?? true ? 1 : .45,
                      child: Text(
                        rotulo,
                        style: Mixart.ui(size: 17, weight: FontWeight.w800, color: Mixart.text).copyWith(
                          decoration: ligado ?? true ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// As bolinhas de progresso (uma por fala com texto); encolhem para caber na largura.
class _BolinhasPainter extends CustomPainter {
  _BolinhasPainter({required this.total, required this.feitas, required this.cor, required this.apagada});

  final int total, feitas;
  final Color cor, apagada;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0 || size.width <= 0) return;
    final passo = size.width / total;
    final r = math.min(4.0, passo * .32);
    final cy = size.height / 2;
    for (var i = 0; i < total; i++) {
      canvas.drawCircle(
        Offset(passo * (i + .5), cy),
        r,
        Paint()..color = i < feitas ? cor : apagada,
      );
    }
  }

  @override
  bool shouldRepaint(_BolinhasPainter old) =>
      old.total != total || old.feitas != feitas || old.cor != cor || old.apagada != apagada;
}
