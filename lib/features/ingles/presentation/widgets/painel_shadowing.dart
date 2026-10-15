import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../data/reconhecedor_fala.dart';
import '../../domain/avaliacao_fala.dart';
import '../../domain/shadowing.dart';

/// O microfone do shadowing: 🎤 Falar → mostra o que está sendo ouvido → confere por palavra e
/// avisa a tela do cartão ([onTentativa]). A frase NÃO aparece aqui (só ao virar o cartão): entre uma
/// tentativa e outra mostra o que foi ouvido (as palavras que casaram em verde, as outras em
/// vermelho) e quantas palavras da frase faltaram, sem dizer quais.
///
/// Só importa a API pública do reconhecedor (`ReconhecedorFala`, `SessaoFala`, `ErroFala`) e a conferência
/// por palavra ([avaliarFala]): nada do reconhecedor é editado ou copiado. O microfone SÓ abre por um
/// toque ou tecla (regra do navegador).
class PainelShadowing extends StatefulWidget {
  final ReconhecedorFala reconhecedor;

  /// A frase a repetir (só vai ao conferidor; nunca é mostrada) e as formas que o autor aceita.
  final String frase;
  final List<String> alternativas;

  /// As tentativas já feitas neste cartão (a última aparece para a pessoa).
  final SessaoShadowing sessao;

  /// Uma fala conferida (o reconhecedor entendeu alguma palavra).
  final void Function(AvaliacaoFala avaliacao) onTentativa;

  /// O microfone abriu (true) ou fechou (false): a tela cala a voz do app enquanto a pessoa fala.
  final void Function(bool ouvindo)? onMicrofone;

  /// "Mostrar a frase": desiste e vira o cartão.
  final VoidCallback onMostrarFrase;

  /// Este aparelho/navegador não consegue ouvir (sem permissão, sem microfone, sem suporte): a tela troca o
  /// cartão por ditado e a revisão segue.
  final VoidCallback onSemVoz;

  const PainelShadowing({
    super.key,
    required this.reconhecedor,
    required this.frase,
    this.alternativas = const [],
    required this.sessao,
    required this.onTentativa,
    this.onMicrofone,
    required this.onMostrarFrase,
    required this.onSemVoz,
  });

  @override
  State<PainelShadowing> createState() => PainelShadowingState();
}

class PainelShadowingState extends State<PainelShadowing> {
  SessaoFala? _escuta;

  /// Cada escuta tem uma "vez": o aviso de uma escuta velha (cartão que mudou, toque duplo) é ignorado.
  int _vez = 0;
  bool _ouvindo = false;

  /// Já tocou em "Parar" e o navegador ainda não avisou o fim (no Chrome/Safari do iPhone ele pode nunca avisar): um
  /// 2º toque, ou [_esperaParar], solta o microfone à força — a tela nunca fica presa em "Ouvindo…".
  bool _pediuParar = false;
  Timer? _forcaFim;
  static const _esperaParar = Duration(seconds: 2);
  String _parcial = '';
  String _recado = '';

  /// A última fala conferida nesta tela (para mostrar o que foi ouvido).
  AvaliacaoFala? _ultima;

  static String textoDoErro(ErroFala e) => switch (e) {
        ErroFala.semPermissao =>
          'O microfone está bloqueado para este site. Libere nas permissões do navegador (o cadeado na barra de endereço).',
        ErroFala.semMicrofone => 'Não achei um microfone neste aparelho.',
        ErroFala.semRede => 'O reconhecimento de voz precisa de internet. Tente de novo quando conectar.',
        ErroFala.naoOuviu => 'Não ouvi nada. Toque no microfone e fale a frase em inglês.',
        ErroFala.naoSuportado => 'Este aparelho não reconhece voz.',
        ErroFala.outro => 'Não consegui ouvir agora. Tente de novo.',
      };

  /// Erros em que insistir não adianta: o cartão vira ditado.
  static bool semSaida(ErroFala e) => e == ErroFala.semPermissao || e == ErroFala.semMicrofone || e == ErroFala.naoSuportado;

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
    if (estavaOuvindo) widget.onMicrofone?.call(false);
    super.dispose();
  }

  /// 🎤 / Espaço: começa a ouvir; se já está ouvindo, entrega o que ouviu.
  void alternar() {
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
    if (widget.sessao.encerrou) return;
    if (!widget.reconhecedor.suportado) {
      widget.onSemVoz();
      return;
    }
    widget.onMicrofone?.call(true);
    final vez = ++_vez;
    _pediuParar = false;
    _forcaFim?.cancel();
    setState(() {
      _ouvindo = true;
      _parcial = '';
      _recado = '';
    });
    _escuta = widget.reconhecedor.ouvir(
      aoParcial: (t) {
        if (mounted && vez == _vez) setState(() => _parcial = t);
      },
      aoFinal: (hipoteses) {
        if (mounted && vez == _vez) _conferir(hipoteses);
      },
      aoErro: (e) {
        if (!mounted || vez != _vez) return;
        if (semSaida(e)) {
          widget.onSemVoz();
        } else {
          setState(() => _recado = textoDoErro(e));
        }
      },
      aoFim: () {
        if (vez != _vez) return;
        _escuta = null;
        _pediuParar = false;
        _forcaFim?.cancel();
        widget.onMicrofone?.call(false);
        if (mounted) setState(() => _ouvindo = false);
      },
    );
  }

  /// O navegador não respondeu ao "parar": fecha o microfone à força (nada é entregue) e deixa tentar de novo.
  void _soltar() {
    _forcaFim?.cancel();
    _forcaFim = null;
    if (!mounted || !_ouvindo) return;
    _vez++; // o que o navegador mandar depois não vale
    final e = _escuta;
    _escuta = null;
    _pediuParar = false;
    e?.cancelar();
    widget.onMicrofone?.call(false);
    setState(() {
      _ouvindo = false;
      _parcial = '';
      _recado = 'O microfone não respondeu. Toque em Tentar de novo, ou use "Mostrar a frase".';
    });
  }

  void _conferir(List<String> hipoteses) {
    final av = avaliarFala(widget.frase, hipoteses, alternativas: widget.alternativas);
    if (av.nada) {
      // nenhuma palavra entendida: não é tentativa (nada de castigo), só pede de novo
      setState(() {
        _recado = 'Não entendi nenhuma palavra. Fale perto do microfone e tente de novo.';
        _ultima = null;
      });
      return;
    }
    setState(() {
      _ultima = av;
      _recado = '';
    });
    widget.onTentativa(av);
  }

  @override
  Widget build(BuildContext context) {
    final feitas = widget.sessao.tentativas.length;
    final resta = maxTentativasShadowing - feitas;
    final u = _ultima;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        key: const Key('painel-shadowing'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Mixart.surfaceHi, border: Border.all(color: Mixart.border), borderRadius: BorderRadius.circular(Mixart.radiusMd)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_ouvindo)
            Text(_parcial.isEmpty ? '🎤 Ouvindo… fale a frase em inglês.' : '🎤 $_parcial…',
                key: const Key('shadowing-ouvindo'), style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.brand).copyWith(height: 1.4))
          else if (u != null && feitas > 0) ...[
            Text('O QUE EU OUVI', style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
            const SizedBox(height: 4),
            _ouvido(u),
            const SizedBox(height: 6),
            Text(
                u.perfeita
                    ? 'Saiu a frase inteira! ✅'
                    : 'Faltaram ${u.palavras - u.acertos} de ${u.palavras} palavras'
                        '${u.aMais.isNotEmpty ? ' · ${u.aMais.length == 1 ? 'sobrou 1 palavra' : 'sobraram ${u.aMais.length} palavras'}' : ''}.',
                key: const Key('shadowing-resultado'),
                style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.textMuted)),
          ] else
            Text('Ouça com atenção e repita a frase em voz alta. Toque em 🎤 Falar quando estiver pronto.',
                key: const Key('shadowing-convite'), style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.45)),
          if (_recado.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_recado, key: const Key('shadowing-recado'), style: Mixart.ui(size: 12.5, color: Mixart.danger).copyWith(height: 1.4)),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
        _Botao(
          key: const Key('shadowing-falar'),
          rotulo: _ouvindo ? '⏹ Parar' : (feitas == 0 ? '🎤 Falar' : '🎤 Tentar de novo'),
          dica: _ouvindo ? 'Parar de ouvir (Espaço)' : 'Falar a frase (Espaço)',
          principal: true,
          onTap: alternar,
        ),
        _Botao(
          key: const Key('shadowing-mostrar'),
          rotulo: 'Mostrar a frase',
          dica: 'Desistir de repetir e ver a frase',
          onTap: _ouvindo ? null : widget.onMostrarFrase,
        ),
      ]),
      const SizedBox(height: 8),
      Text(
          feitas == 0
              ? 'Você tem $maxTentativasShadowing tentativas. O app confere se as PALAVRAS saíram, não o sotaque.'
              : (resta == 1 ? 'Resta 1 tentativa.' : 'Restam $resta tentativas.'),
          key: const Key('shadowing-tentativas'),
          textAlign: TextAlign.center,
          style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
      const SizedBox(height: 2),
      Text('O reconhecimento é feito pelo navegador ou pelo sistema (no Chrome, num servidor: precisa de internet). O app não grava sua voz.',
          key: const Key('shadowing-privacidade'), textAlign: TextAlign.center, style: Mixart.ui(size: 10.5, color: Mixart.textFaint).copyWith(height: 1.4)),
    ]);
  }

  /// O que foi ouvido, palavra por palavra: as que casaram com a frase em verde, as outras em vermelho.
  Widget _ouvido(AvaliacaoFala a) {
    final base = Mixart.display(size: 19, weight: FontWeight.w600, color: Mixart.text).copyWith(height: 1.35);
    return Text.rich(
      key: const Key('shadowing-ouvido'),
      TextSpan(children: [
        for (var i = 0; i < a.ouvidas.length; i++) ...[
          if (i > 0) TextSpan(text: ' ', style: base),
          TextSpan(text: a.ouvidas[i], style: base.copyWith(color: a.ouvidaCasou[i] ? const Color(0xFF4CD08A) : Mixart.danger)),
        ],
      ]),
    );
  }
}

class _Botao extends StatelessWidget {
  final String rotulo, dica;
  final bool principal;
  final VoidCallback? onTap;
  const _Botao({super.key, required this.rotulo, required this.dica, this.principal = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ligado = onTap != null;
    // canRequestFocus: false — o foco fica na tela do cartão (Espaço/R continuam funcionando)
    return Tooltip(
      message: dica,
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: BoxConstraints(minWidth: principal ? 170 : 140, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: principal && ligado ? Mixart.brand : Colors.transparent,
            border: Border.all(color: principal ? Mixart.brand : Mixart.border),
            borderRadius: BorderRadius.circular(999),
          ),
          // Center com widthFactor: o botão tem o tamanho do texto (um Container com `alignment` esticaria até a borda)
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(rotulo,
                style: Mixart.ui(
                    size: 14,
                    weight: FontWeight.w800,
                    color: !ligado ? Mixart.textFaint : (principal ? Mixart.onBrand : Mixart.textMuted))),
          ),
        ),
      ),
    );
  }
}
