import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind, kPrimaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/mixart.dart';
import '../../../ingles/data/reconhecedor_fala.dart';
import '../../../ingles/presentation/widgets/painel_shadowing.dart' show PainelShadowingState;
import '../maos_livres.dart';

/// O microfone de ditado livre da conversa (padrão do PainelShadowing, sem importar o privado dele): o
/// que a pessoa fala vai para o CAMPO, nunca é enviado sozinho. Sem suporte → nada.
///
/// Com [maosLivres] (o modo ligado) ele vira o botão de SEGURAR: apertou, ouve; soltou, envia sozinho; um
/// toque abre a vez (o [ControladorMaosLivres] decide tudo; os callbacks do ditado não são usados).
class MicrofoneConversa extends StatefulWidget {
  final ReconhecedorFala reconhecedor;

  /// hipoteses.first.trim() (não vazio).
  final ValueChanged<String> aoOuvir;

  /// '' quando acaba.
  final ValueChanged<String>? aoParcial;

  /// PainelShadowingState.textoDoErro(e), ou 'Confira o texto e toque em Enviar.'.
  final ValueChanged<String>? aoRecado;

  /// voz.calarTudo().
  final Future<void> Function()? antesDeOuvir;

  /// true quando começa a ouvir; false no aoFim / erro / fim forçado / dispose.
  final ValueChanged<bool>? aoMudarOuvindo;

  /// O mãos-livres ligado (null = o ditado de sempre).
  final ControladorMaosLivres? maosLivres;

  /// Mãos-livres: por que o 🎤 não abre agora (ex.: "Espere a resposta"); null = abre. Com ele o botão fica
  /// apagado e esse é o rótulo dele.
  final String? esperaMaosLivres;

  const MicrofoneConversa({
    super.key,
    required this.reconhecedor,
    required this.aoOuvir,
    this.aoParcial,
    this.aoRecado,
    this.antesDeOuvir,
    this.aoMudarOuvindo,
    this.maosLivres,
    this.esperaMaosLivres,
  });

  /// O recado depois de um ditado que deu certo.
  static const recadoConfira = 'Confira o texto e toque em Enviar.';

  @override
  State<MicrofoneConversa> createState() => _MicrofoneConversaState();
}

class _MicrofoneConversaState extends State<MicrofoneConversa> {
  SessaoFala? _escuta;

  /// Cada escuta tem uma "vez": o que chega de uma escuta velha é ignorado.
  int _vez = 0;
  bool _ouvindo = false;

  /// Já tocou em "Parar" e o navegador ainda não avisou o fim: um 2º toque, ou [_esperaParar], solta à força.
  bool _pediuParar = false;
  Timer? _forcaFim;
  static const _esperaParar = Duration(seconds: 2);

  void _alternar() {
    if (_ouvindo) {
      if (_pediuParar) {
        _soltar();
        return;
      }
      _pediuParar = true;
      _escuta?.parar();
      _forcaFim?.cancel();
      _forcaFim = Timer(_esperaParar, _soltar);
      return;
    }
    final vez = ++_vez;
    _pediuParar = false;
    _forcaFim?.cancel();
    setState(() => _ouvindo = true);
    widget.aoMudarOuvindo?.call(true);
    widget.aoRecado?.call('');
    widget.aoParcial?.call('');
    // cala o app (a voz do personagem, o player do 🎧) ANTES de abrir o microfone — senão ele ouve o próprio
    // app. Sem await: o microfone abre no mesmo toque (regra do navegador); a parte que cala é síncrona.
    unawaited(widget.antesDeOuvir?.call());
    _escuta = widget.reconhecedor.ouvir(
      idioma: 'en-US',
      aoParcial: (t) {
        if (mounted && vez == _vez) widget.aoParcial?.call(t);
      },
      aoFinal: (hipoteses) {
        if (!mounted || vez != _vez) return;
        final t = hipoteses.isEmpty ? '' : hipoteses.first.trim();
        if (t.isEmpty) {
          widget.aoRecado?.call(PainelShadowingState.textoDoErro(ErroFala.naoOuviu));
          return;
        }
        widget.aoOuvir(t);
        widget.aoRecado?.call(MicrofoneConversa.recadoConfira);
      },
      aoErro: (e) {
        if (mounted && vez == _vez) widget.aoRecado?.call(PainelShadowingState.textoDoErro(e));
      },
      aoFim: () {
        if (vez != _vez) return;
        _escuta = null;
        _pediuParar = false;
        _forcaFim?.cancel();
        if (!mounted) return;
        widget.aoParcial?.call('');
        widget.aoMudarOuvindo?.call(false);
        setState(() => _ouvindo = false);
      },
    );
  }

  /// O navegador não respondeu ao "parar": fecha o microfone à força (nada é entregue).
  void _soltar() {
    _forcaFim?.cancel();
    _forcaFim = null;
    if (!mounted || !_ouvindo) return;
    _vez++; // o que o navegador mandar depois não vale
    final e = _escuta;
    _escuta = null;
    _pediuParar = false;
    e?.cancelar();
    widget.aoParcial?.call('');
    widget.aoMudarOuvindo?.call(false);
    setState(() => _ouvindo = false);
  }

  @override
  void didUpdateWidget(MicrofoneConversa antigo) {
    super.didUpdateWidget(antigo);
    // ligou o mãos-livres com o ditado aberto: o ditado desiste já (nada vai para o campo); os avisos à tela
    // ("fechou") ficam para depois do quadro — aqui é o meio do build
    if (antigo.maosLivres == null && widget.maosLivres != null && _ouvindo) {
      _vez++;
      final e = _escuta;
      _escuta = null;
      e?.cancelar();
      WidgetsBinding.instance.addPostFrameCallback((_) => _soltar());
    }
  }

  @override
  void dispose() {
    _forcaFim?.cancel();
    // sair da tela com o microfone aberto: desiste (nada é entregue) e avisa que fechou
    final e = _escuta;
    final estavaOuvindo = _ouvindo;
    _vez++;
    _escuta = null;
    _ouvindo = false;
    e?.cancelar();
    if (estavaOuvindo) widget.aoMudarOuvindo?.call(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.reconhecedor.suportado) return const SizedBox.shrink();
    final maos = widget.maosLivres;
    if (maos != null) return _BotaoSegurar(controlador: maos, espera: widget.esperaMaosLivres);
    final rotulo = _ouvindo ? 'Parar de ouvir' : 'Falar em inglês';
    return Tooltip(
      message: rotulo,
      child: Semantics(
        button: true,
        label: rotulo,
        excludeSemantics: true,
        child: Material(
          key: const Key('microfone-conversa'),
          color: _ouvindo ? Mixart.danger : Mixart.brand,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _alternar,
            child: SizedBox.square(
              dimension: 44,
              child: Icon(_ouvindo ? Icons.stop_rounded : Icons.mic_rounded, size: 22, color: _ouvindo ? Colors.white : Mixart.onBrand),
            ),
          ),
        ),
      ),
    );
  }
}

/// O 🎤 do mãos-livres: segurar grava, soltar envia (Listener, não gesto: o microfone abre já no "apertar",
/// sem esperar a arena de gestos). Sem Tooltip: no celular ele apareceria a cada "segurar". No teclado (Tab
/// chega nele) Espaço/Enter seguram como o dedo: apertou, ouve; soltou a tecla, envia.
class _BotaoSegurar extends StatefulWidget {
  final ControladorMaosLivres controlador;

  /// Por que não dá para falar agora (null = dá).
  final String? espera;
  const _BotaoSegurar({required this.controlador, this.espera});

  @override
  State<_BotaoSegurar> createState() => _BotaoSegurarState();
}

class _BotaoSegurarState extends State<_BotaoSegurar> {
  bool _focado = false;

  /// O ponteiro que segura o 🎤: só o "soltar" dele envia.
  int? _ponteiro;

  /// Espaço/Enter apertado (a tecla segura o 🎤).
  bool _tecla = false;

  void _apertou(PointerDownEvent e) {
    // só o botão principal do mouse: o direito abre o menu do navegador, que engole o "soltar"
    if (e.kind == PointerDeviceKind.mouse && e.buttons != kPrimaryButton) return;
    if (_ponteiro != null || widget.espera != null) return;
    _ponteiro = e.pointer;
    widget.controlador.segurar();
  }

  void _soltouPonteiro(PointerEvent e) {
    if (e.pointer != _ponteiro) return;
    _ponteiro = null;
    widget.controlador.soltar();
  }

  void _soltarTecla() {
    if (!_tecla) return;
    _tecla = false;
    widget.controlador.soltar();
  }

  KeyEventResult _teclou(FocusNode _, KeyEvent e) {
    final k = e.logicalKey;
    if (k != LogicalKeyboardKey.space && k != LogicalKeyboardKey.enter && k != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (e is KeyDownEvent) {
      if (!_tecla && _ponteiro == null && widget.espera == null) {
        _tecla = true;
        widget.controlador.segurar();
      }
    } else if (e is KeyUpEvent) {
      _soltarTecla();
    }
    // a repetição da tecla segurada não faz nada (nem vira o "ativar" padrão)
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controlador,
        builder: (context, _) {
          final c = widget.controlador;
          final ouvindo = c.estado == EstadoMaosLivres.ouvindo;
          final apagado = !ouvindo && widget.espera != null;
          final rotulo = apagado
              ? widget.espera!
              : !ouvindo
                  ? 'Segure para falar em inglês'
                  : (c.segurando ? 'Solte para enviar' : 'Ouvindo — fale em inglês');
          return Focus(
            onKeyEvent: _teclou,
            onFocusChange: (f) {
              // perdeu o foco com a tecla apertada: conta como soltar
              if (!f) _soltarTecla();
              setState(() => _focado = f);
            },
            child: Semantics(
              button: true,
              enabled: !apagado,
              label: rotulo,
              excludeSemantics: true,
              // leitor de tela: um toque abre a vez (envia sozinho no silêncio)
              onTap: apagado
                  ? null
                  : () {
                      c.segurar();
                      c.soltar();
                    },
              child: Listener(
                onPointerDown: _apertou,
                onPointerUp: _soltouPonteiro,
                onPointerCancel: _soltouPonteiro,
                child: AnimatedContainer(
                  key: const Key('microfone-conversa'),
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ouvindo ? Mixart.danger : (apagado ? Mixart.surfaceHi : Mixart.brand),
                    shape: BoxShape.circle,
                    border: apagado ? Border.all(color: Mixart.border) : null,
                    // segurando: um anel em volta (o dedo cobre o ícone); com o foco do teclado, o anel do foco
                    boxShadow: c.segurando
                        ? [BoxShadow(color: Mixart.danger.withValues(alpha: .35), spreadRadius: 5)]
                        : (_focado ? [BoxShadow(color: Mixart.text.withValues(alpha: .55), spreadRadius: 3)] : null),
                  ),
                  child: Icon(ouvindo ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                      size: 22, color: ouvindo ? Colors.white : (apagado ? Mixart.textFaint : Mixart.onBrand)),
                ),
              ),
            ),
          );
        },
      );
}
