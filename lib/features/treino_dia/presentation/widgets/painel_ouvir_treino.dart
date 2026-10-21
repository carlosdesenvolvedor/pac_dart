import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../../ingles/presentation/ouvir/mini_player.dart' show RostoDaFaixa;
import '../../../ingles/presentation/ouvir/ouvir_cubit.dart';
import '../../../ingles/presentation/ouvir/ouvir_state.dart';
import '../../../ingles/presentation/ouvir/tocando_page.dart' show nomeDeQuem;
import '../../domain/plano_treino.dart';

/// A etapa 🎧 Ouvir do treino, dentro da própria página (sem rota nova): a frase da vez (EN grande,
/// PT embaixo), "Frase {indice+1} de {fila.length}", ⏯ e "Pular".
///
/// - `initState`: `ouvir.telaCheia(true)` (esconde o mini-player); `dispose`: `telaCheia(false)`.
///   Nunca chama `fechar` (só a página, ao terminar ou pular).
/// - O alvo é `ouvir.state.fila.length` da sessão do treino (lido depois de `tocarItens` ou da sessão
///   que já estava tocando).
/// - [aoTerminar]: a fila acabou (ou `ouvidas >= fila.length`), uma vez só.
/// - [aoParar]: alguém fechou a sessão por fora — recebe as `ouvidas` do estado ANTERIOR (o `fechar()`
///   zera tudo no mesmo emit).
class PainelOuvirTreino extends StatefulWidget {
  final OuvirCubit ouvir;
  final void Function(int ouvidas) aoTerminar;
  final void Function(int ouvidas) aoParar;
  final VoidCallback aoPular;

  const PainelOuvirTreino({
    super.key,
    required this.ouvir,
    required this.aoTerminar,
    required this.aoParar,
    required this.aoPular,
  });

  @override
  State<PainelOuvirTreino> createState() => _PainelOuvirTreinoState();
}

/// A sessão do Ouvir é a do treino?
bool ehDoTreino(OuvirState s) => s.fonte?.titulo == tituloOuvirTreino;

class _PainelOuvirTreinoState extends State<PainelOuvirTreino> {
  /// Já avisou o fim (ou a parada): nada mais é avisado por este painel.
  bool _avisou = false;

  /// As últimas `ouvidas` vistas com a fonte do treino (reserva caso o estado anterior já venha zerado).
  int _ultimasOuvidas = 0;

  /// As `ouvidas` do estado de antes da parada (o [BlocListener] só entrega o estado novo).
  int _ouvidasAntes = 0;

  @override
  void initState() {
    super.initState();
    _ultimasOuvidas = ehDoTreino(widget.ouvir.state) ? widget.ouvir.state.ouvidas : 0;
    // o mini-player some enquanto o painel está aberto (sem controles em dobro)
    widget.ouvir.telaCheia(true);
  }

  @override
  void dispose() {
    widget.ouvir.telaCheia(false);
    super.dispose();
  }

  void _terminar(int ouvidas) {
    if (_avisou) return;
    _avisou = true;
    widget.aoTerminar(ouvidas);
  }

  void _parar(int ouvidas) {
    if (_avisou) return;
    _avisou = true;
    widget.aoParar(ouvidas);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // as ouvidas de reserva
        BlocListener<OuvirCubit, OuvirState>(
          bloc: widget.ouvir,
          listenWhen: (a, b) => ehDoTreino(b) && b.ouvidas != a.ouvidas,
          listener: (_, s) => _ultimasOuvidas = math.max(_ultimasOuvidas, s.ouvidas),
        ),
        // 1. o fim: a fila acabou, ou já ouviu tudo (vale também com o "repetir tudo" ligado)
        BlocListener<OuvirCubit, OuvirState>(
          bloc: widget.ouvir,
          listenWhen: (a, b) =>
              ehDoTreino(b) && (b.status == StatusOuvir.acabou || (b.fila.isNotEmpty && b.ouvidas >= b.fila.length)),
          listener: (_, s) => _terminar(s.ouvidas),
        ),
        // 2. fechado por fora (o ✕ de um player em outro lugar): o fechar() zera `ouvidas` e `fonte` no
        //    mesmo emit, então quem vale é o estado ANTERIOR (guardado no listenWhen, que o recebe)
        BlocListener<OuvirCubit, OuvirState>(
          bloc: widget.ouvir,
          listenWhen: (a, b) {
            final parou = ehDoTreino(a) && b.status == StatusOuvir.parado;
            if (parou) _ouvidasAntes = a.ouvidas;
            return parou;
          },
          listener: (_, _) => _parar(math.max(_ouvidasAntes, _ultimasOuvidas)),
        ),
      ],
      child: BlocBuilder<OuvirCubit, OuvirState>(
        bloc: widget.ouvir,
        builder: (context, st) => _corpo(context, st),
      ),
    );
  }

  Widget _corpo(BuildContext context, OuvirState st) {
    final f = ehDoTreino(st) ? st.atual : null;
    final total = st.fila.length;
    final largo = MediaQuery.sizeOf(context).width >= 600;
    final tocando = st.status == StatusOuvir.tocando;
    final aviso = !ehDoTreino(st) || st.status != StatusOuvir.pausado
        ? null
        : switch (st.motivo) {
            MotivoPausa.outraFala => 'Pausado — outra fala começou. ▶ para continuar.',
            MotivoPausa.semSom => 'Não consegui tocar o som. Toque ▶ ou pule esta etapa.',
            _ => null,
          };
    final nome = f == null ? null : nomeDeQuem(f.quem);
    return Container(
      key: const Key('treino-dia-ouvir'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.brand, width: 1.6),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('🎧 Ouvir', style: Mixart.display(size: 16))),
          if (f != null)
            Text('Frase ${st.indice + 1} de $total',
                key: const Key('treino-dia-ouvir-contador'),
                style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.textMuted)),
        ]),
        const SizedBox(height: 14),
        Center(child: RostoDaFaixa(faixa: f, tamanho: largo ? 110 : 84)),
        if (nome != null) ...[
          const SizedBox(height: 6),
          Text(nome,
              textAlign: TextAlign.center,
              style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.textMuted)),
        ],
        const SizedBox(height: 12),
        Text(
          f?.en ?? 'Preparando as frases…',
          key: const Key('treino-dia-ouvir-en'),
          textAlign: TextAlign.center,
          style: f == null
              ? Mixart.ui(size: 14, color: Mixart.textMuted)
              : Mixart.display(size: largo ? 26 : 22).copyWith(height: 1.25),
        ),
        if (f != null && f.pt.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(f.pt,
              key: const Key('treino-dia-ouvir-pt'),
              textAlign: TextAlign.center,
              style: Mixart.ui(size: largo ? 16 : 14.5, color: Mixart.textMuted).copyWith(height: 1.35)),
        ],
        const SizedBox(height: 14),
        Semantics(
          label: total == 0 ? null : 'Frase ${st.indice + 1} de $total',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : ((st.indice + 1) / total).clamp(0.0, 1.0),
              minHeight: 5,
              color: Mixart.brand,
              backgroundColor: Mixart.surfaceHi,
            ),
          ),
        ),
        if (aviso != null) ...[
          const SizedBox(height: 12),
          Container(
            key: const Key('treino-dia-ouvir-aviso'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Mixart.brandSub,
              border: Border.all(color: Mixart.brandDim),
              borderRadius: BorderRadius.circular(12),
            ),
            // o som parou sozinho: o leitor de tela anuncia o porquê (como a `_Faixa` do hub)
            child: Semantics(
              liveRegion: true,
              child: Text(aviso, style: Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.35)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton.filled(
            key: const Key('treino-dia-ouvir-play'),
            tooltip: tocando ? 'Pausar' : 'Tocar',
            onPressed: f == null
                ? null
                : () {
                    if (tocando) {
                      widget.ouvir.pausar();
                    } else {
                      widget.ouvir.continuar();
                    }
                  },
            style: IconButton.styleFrom(
              backgroundColor: Mixart.brand,
              foregroundColor: Mixart.onBrand,
              minimumSize: const Size(56, 56),
            ),
            icon: Icon(tocando ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
          ),
          const SizedBox(width: 16),
          TextButton(
            key: const Key('treino-dia-ouvir-pular'),
            onPressed: widget.aoPular,
            style: TextButton.styleFrom(
              foregroundColor: Mixart.textMuted,
              minimumSize: const Size(48, 48),
              textStyle: Mixart.ui(size: 13.5, weight: FontWeight.w600),
            ),
            child: const Text('Pular'),
          ),
        ]),
      ]),
    );
  }
}
