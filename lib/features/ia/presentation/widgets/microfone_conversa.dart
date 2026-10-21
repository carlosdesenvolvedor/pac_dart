import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../../ingles/data/reconhecedor_fala.dart';
import '../../../ingles/presentation/widgets/painel_shadowing.dart' show PainelShadowingState;

/// O microfone de ditado livre da conversa (padrão do PainelShadowing, sem importar o privado dele): o
/// que a pessoa fala vai para o CAMPO, nunca é enviado sozinho. Sem suporte → nada.
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

  const MicrofoneConversa({
    super.key,
    required this.reconhecedor,
    required this.aoOuvir,
    this.aoParcial,
    this.aoRecado,
    this.antesDeOuvir,
    this.aoMudarOuvindo,
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
