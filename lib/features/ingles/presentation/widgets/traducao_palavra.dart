import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../../ia/domain/explicacao.dart';
import '../../../ia/presentation/ia_cubit.dart';
import '../../../ia/presentation/widgets/botao_por_que.dart' show comNegrito;
import '../../data/dicionario_ingles.dart';

/// O que se sabe da palavra tocada: ela, a frase em que está e a tradução da frase.
class PalavraTocada {
  final String palavra, frase, traducao;

  /// Qual palavra da frase (0 = a 1ª).
  final int indice;

  /// O trecho que a lição ensina e a tradução dele, quando a palavra está dentro dele.
  final String alvo, alvoPt;

  const PalavraTocada({
    required this.palavra,
    required this.frase,
    this.traducao = '',
    this.indice = 0,
    this.alvo = '',
    this.alvoPt = '',
  });
}

/// Fala só a palavra tocada, na velocidade normal ou devagar (🐢).
typedef OuvirPalavra = void Function(String palavra, {required bool lenta});

/// "🎯 Treinar esta palavra" no balão: abre a escolha das palavras da lição com ela já marcada.
typedef TreinarPalavra = void Function(String palavra);

/// O balão do "toque na palavra": a pronúncia dela (🔊 normal e 🐢 devagar), o pé da letra (dicionário do app, na
/// hora e sem internet) e o sentido NO CONTEXTO (o trecho da lição, se a palavra está nele, e o Prof. Dash, com cache e cota própria).
///
/// Fica numa camada por cima da tela, presa à palavra, e NÃO toma o foco: dá para seguir digitando.
/// Fecha ao tocar fora, no ✕ ou quando o dono chamar [fechar] (Esc, próxima frase).
class BalaoPalavra {
  OverlayEntry? _entrada;

  bool get aberto => _entrada != null;

  /// Abre (ou troca) o balão sob [ancora] — o retângulo da palavra, em coordenadas globais.
  void abrir(
    BuildContext context, {
    required Rect ancora,
    required PalavraTocada palavra,
    OuvirPalavra? onOuvir,
    TreinarPalavra? onTreinar,
  }) {
    fechar();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final caixa = overlay.context.findRenderObject();
    final local = caixa is RenderBox
        ? Rect.fromPoints(caixa.globalToLocal(ancora.topLeft), caixa.globalToLocal(ancora.bottomRight))
        : ancora;
    // a camada fica no topo do app: o cubit vai junto (pode não haver provedor acima dela)
    final ia = IaPalavrasCubit.daArvore(context);
    late final OverlayEntry entrada;
    entrada = OverlayEntry(
      builder: (ctx) => _CamadaBalao(
        ancora: local,
        palavra: palavra,
        ia: ia,
        onOuvir: onOuvir,
        onTreinar: onTreinar == null
            ? null
            : (w) {
                if (identical(_entrada, entrada)) fechar();
                onTreinar(w);
              },
        onFechar: () {
          if (identical(_entrada, entrada)) fechar();
        },
      ),
    );
    _entrada = entrada;
    overlay.insert(entrada);
  }

  void fechar() {
    final e = _entrada;
    _entrada = null;
    e?.remove();
    e?.dispose();
  }
}

class _CamadaBalao extends StatelessWidget {
  final Rect ancora;
  final PalavraTocada palavra;
  final IaPalavrasCubit? ia;
  final OuvirPalavra? onOuvir;
  final TreinarPalavra? onTreinar;
  final VoidCallback onFechar;

  const _CamadaBalao({
    required this.ancora,
    required this.palavra,
    required this.ia,
    required this.onFechar,
    this.onOuvir,
    this.onTreinar,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return CustomSingleChildLayout(
      delegate: _PosicaoBalao(
        ancora: ancora,
        topo: mq.padding.top + 8,
        base: math.max(mq.viewInsets.bottom, mq.padding.bottom) + 8,
      ),
      child: TapRegion(
        onTapOutside: (_) => onFechar(),
        child: ConteudoBalaoPalavra(
          palavra: palavra,
          ia: ia,
          onOuvir: onOuvir,
          onTreinar: onTreinar,
          onFechar: onFechar,
        ),
      ),
    );
  }
}

/// Abaixo da palavra; sem espaço embaixo (teclado aberto, fim da tela), em cima.
class _PosicaoBalao extends SingleChildLayoutDelegate {
  final Rect ancora;
  final double topo, base;

  _PosicaoBalao({required this.ancora, required this.topo, required this.base});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints c) =>
      BoxConstraints(maxWidth: math.max(0.0, math.min(340.0, c.maxWidth - 32)), maxHeight: math.max(0.0, c.maxHeight * .6));

  @override
  Offset getPositionForChild(Size tela, Size balao) {
    final x = (ancora.center.dx - balao.width / 2).clamp(16.0, math.max(16.0, tela.width - balao.width - 16)).toDouble();
    final abaixo = ancora.bottom + 6;
    final y = abaixo + balao.height <= tela.height - base ? abaixo : math.max(topo, ancora.top - 6 - balao.height);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PosicaoBalao old) => old.ancora != ancora || old.topo != topo || old.base != base;
}

enum _Fase { semIa, carregando, ok, semCota, falhou }

/// O miolo do balão (público para os testes montarem sem a camada).
class ConteudoBalaoPalavra extends StatefulWidget {
  final PalavraTocada palavra;
  final IaPalavrasCubit? ia;
  final VoidCallback? onFechar;

  /// 🔊/🐢 ao lado da palavra (null = sem voz, sem os botões).
  final OuvirPalavra? onOuvir;

  /// "🎯 Treinar esta palavra" no pé do balão (null = sem o botão).
  final TreinarPalavra? onTreinar;

  const ConteudoBalaoPalavra({
    super.key,
    required this.palavra,
    this.ia,
    this.onFechar,
    this.onOuvir,
    this.onTreinar,
  });

  @override
  State<ConteudoBalaoPalavra> createState() => _ConteudoBalaoPalavraState();
}

class _ConteudoBalaoPalavraState extends State<ConteudoBalaoPalavra> {
  String? _literal;
  bool _dicionarioPronto = false;
  _Fase _fase = _Fase.semIa;
  String _sentido = '';

  @override
  void initState() {
    super.initState();
    final d = DicionarioIngles.pronto;
    if (d != null) {
      _literal = d.literal(widget.palavra.palavra);
      _dicionarioPronto = true;
      _perguntar();
    } else {
      DicionarioIngles.carregar().then((d) {
        if (!mounted) return;
        setState(() {
          _literal = d.literal(widget.palavra.palavra);
          _dicionarioPronto = true;
        });
        _perguntar();
      });
    }
  }

  Future<void> _perguntar() async {
    final ia = widget.ia;
    // dentro do trecho da lição, a tradução dele já é o contexto: nem gasta consulta
    if (ia == null || ia.isClosed || _noAlvo) return;
    final p = widget.palavra;
    setState(() => _fase = _Fase.carregando);
    final r = await ia.explicar(
      PedidoPalavra(
        palavra: p.palavra,
        frase: p.frase,
        traducao: p.traducao,
        indice: p.indice,
        literal: _literal ?? '',
      ),
    );
    if (!mounted) return;
    setState(() {
      _sentido = r.texto;
      _fase = switch (r.status) {
        StatusIa.ok => _Fase.ok,
        StatusIa.semCota => _Fase.semCota,
        StatusIa.falhou => _Fase.falhou,
      };
    });
  }

  /// A palavra está dentro do trecho que a lição ensina: a tradução dele já é o sentido no contexto.
  bool get _noAlvo {
    final p = widget.palavra;
    if (p.alvo.trim().isEmpty || p.alvoPt.trim().isEmpty) return false;
    final palavrasAlvo = p.alvo.toLowerCase().split(RegExp(r"[^a-z0-9'’-]+"));
    return palavrasAlvo.contains(p.palavra.toLowerCase());
  }

  Widget _rotulo(String t, {Key? key}) => Text(
    t,
    key: key,
    style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: .8),
  );

  @override
  Widget build(BuildContext context) {
    final p = widget.palavra;
    final corpo = Mixart.ui(size: 14, color: Mixart.text).copyWith(height: 1.45);
    return Material(
      key: const Key('balao-palavra'),
      color: Mixart.surfaceHi,
      elevation: 10,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Mixart.brandDim),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 6, 14),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.palavra,
                      style: Mixart.mono(size: 18, weight: FontWeight.w700, color: Mixart.brand),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onOuvir case final ouvir?) ...[
                    IconButton(
                      key: const Key('ouvir-palavra'),
                      tooltip: 'Ouvir a palavra',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.volume_up_rounded, size: 20, color: Mixart.brand),
                      onPressed: () => ouvir(p.palavra, lenta: false),
                    ),
                    IconButton(
                      key: const Key('ouvir-palavra-devagar'),
                      tooltip: 'Ouvir devagar',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.slow_motion_video_rounded, size: 20, color: Mixart.brand),
                      onPressed: () => ouvir(p.palavra, lenta: true),
                    ),
                  ],
                  IconButton(
                    key: const Key('fechar-balao-palavra'),
                    tooltip: 'Fechar',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded, size: 18, color: Mixart.textMuted),
                    onPressed: widget.onFechar,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _rotulo('AO PÉ DA LETRA'),
                    const SizedBox(height: 3),
                    if (!_dicionarioPronto)
                      Text('…', style: corpo)
                    else
                      Text(
                        _literal ?? 'não está no dicionário do app${widget.ia == null ? '' : ' (veja o contexto)'}',
                        key: const Key('literal-palavra'),
                        style: _literal == null
                            ? corpo.copyWith(color: Mixart.textMuted, fontStyle: FontStyle.italic)
                            : corpo,
                      ),
                    if (_noAlvo || _fase != _Fase.semIa) ...[
                      const SizedBox(height: 12),
                      _rotulo(_fase == _Fase.semIa ? 'NO CONTEXTO' : 'NO CONTEXTO · 🐦 PROF. DASH'),
                      const SizedBox(height: 3),
                    ],
                    if (_noAlvo)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text.rich(
                          key: const Key('alvo-palavra'),
                          TextSpan(
                            style: corpo,
                            children: [
                              TextSpan(
                                text: p.alvo,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const TextSpan(text: ' → '),
                              TextSpan(text: p.alvoPt),
                            ],
                          ),
                        ),
                      ),
                    switch (_fase) {
                      _Fase.semIa => const SizedBox.shrink(),
                      _Fase.carregando => Row(
                        children: [
                          SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Mixart.brand),
                          ),
                          const SizedBox(width: 8),
                          Text('pensando…', style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
                        ],
                      ),
                      _Fase.ok => SelectableText.rich(key: const Key('sentido-palavra'), comNegrito(_sentido, corpo)),
                      _Fase.semCota => Text(
                        'Por hoje acabaram as consultas ao Prof. Dash — o pé da letra continua.',
                        style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4),
                      ),
                      _Fase.falhou => Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Sem conexão com o Prof. Dash agora. ',
                            style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4),
                          ),
                          InkWell(
                            key: const Key('tentar-sentido-de-novo'),
                            onTap: _perguntar,
                            child: Text(
                              'Tentar de novo',
                              style: Mixart.ui(
                                size: 12.5,
                                weight: FontWeight.w700,
                                color: Mixart.brand,
                              ).copyWith(decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    },
                    if (widget.ia case final ia? when _fase == _Fase.ok || _fase == _Fase.carregando)
                      BlocBuilder<IaPalavrasCubit, IaState>(
                        bloc: ia,
                        builder: (_, st) => st.carregado && st.restantes <= 20
                            ? Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  st.restantes == 1 ? 'resta 1 consulta hoje' : 'restam ${st.restantes} consultas hoje',
                                  style: Mixart.ui(size: 10.5, color: Mixart.textFaint),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    if (widget.onTreinar case final treinar?) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const Key('treinar-palavra'),
                        onPressed: () => treinar(p.palavra),
                        icon: Icon(Icons.track_changes_rounded, size: 18, color: Mixart.brand),
                        label: Text(
                          'Treinar esta palavra',
                          style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.text),
                        ),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(color: Mixart.brandDim),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
