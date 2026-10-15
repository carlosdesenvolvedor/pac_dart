import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../habito_cubit.dart';
import 'sequencia_sheet.dart';

/// 🔥 + dias seguidos + um anel com o progresso da meta de hoje, no cabeçalho.
/// Toque abre a folha "Sua sequência". Sem [HabitoCubit] na árvore (testes antigos)
/// não existe. Também é quem avisa, uma vez por dia, que a meta foi batida.
class ChipSequencia extends StatelessWidget {
  const ChipSequencia({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = HabitoCubit.de(context);
    if (cubit == null) return const SizedBox.shrink();
    return BlocConsumer<HabitoCubit, HabitoState>(
      // o contador só sobe quando a meta de um dia é batida: aviso 1× por dia
      listenWhen: (a, b) => a.metasBatidas != b.metasBatidas,
      listener: (context, st) => _avisarMetaBatida(context, st.habito.sequenciaVisivel(cubit.agora())),
      builder: (context, st) {
        final agora = cubit.agora();
        final h = st.habito;
        final dias = h.sequenciaVisivel(agora);
        final bateu = h.bateuHoje(agora);
        final viva = dias > 0;
        final risco = h.emRisco(agora);
        final feitas = h.feitasHoje(agora);
        final faltam = (h.meta - feitas).clamp(0, h.meta);
        final String rotulo;
        final String dica;
        if (!st.carregado) {
          rotulo = '';
          dica = 'Sua sequência de estudo';
        } else if (viva) {
          rotulo = '$dias';
          dica = bateu
              ? 'Meta de hoje batida · ${_dias(dias)} seguidos'
              : 'Faltam $faltam exercícios hoje para manter sua sequência de ${_dias(dias)}';
        } else {
          // sem sequência não mostramos "0 dias": é um convite
          rotulo = feitas > 0 ? '$feitas/${h.meta}' : 'Comece hoje';
          dica = 'Faça ${h.meta} exercícios hoje para acender sua primeira chama';
        }
        final destaque = viva && (bateu || risco);
        return Tooltip(
          message: dica,
          child: InkWell(
            key: const Key('chip-sequencia'),
            onTap: () => mostrarSequencia(context),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 40,
              padding: EdgeInsets.only(left: 7, right: rotulo.isEmpty ? 7 : 13),
              decoration: BoxDecoration(
                color: destaque ? Mixart.brandSub : Mixart.surfaceHi,
                border: Border.all(color: destaque ? Mixart.brand : Mixart.border, width: risco ? 1.6 : 1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnelDaMeta(
                  progresso: !st.carregado
                      ? 0
                      : bateu
                          ? 1
                          : h.progressoHoje(agora),
                  acesa: viva,
                  tamanho: 28,
                ),
                if (rotulo.isNotEmpty) ...[
                  const SizedBox(width: 7),
                  Text(rotulo,
                      key: const Key('chip-sequencia-rotulo'),
                      style: viva
                          ? Mixart.display(size: 17, color: bateu ? Mixart.brand : Mixart.text)
                          : Mixart.ui(size: 13, weight: FontWeight.w500, color: Mixart.textMuted)),
                ],
              ]),
            ),
          ),
        );
      },
    );
  }

  /// A mensagem curta de meta batida: sem som, sem bloquear nada.
  static void _avisarMetaBatida(BuildContext context, int dias) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final estreito = MediaQuery.sizeOf(context).width < 460;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        key: const Key('aviso-meta-batida'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Mixart.surfaceHi,
        duration: const Duration(seconds: 4),
        // largura fixa no computador, margem no celular (os dois juntos não podem)
        width: estreito ? null : 380,
        margin: estreito ? const EdgeInsets.fromLTRB(16, 0, 16, 16) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          side: BorderSide(color: Mixart.brand),
        ),
        content: Text('Meta de hoje batida! 🔥 ${_dias(dias)}', style: Mixart.ui(size: 14, weight: FontWeight.w600, color: Mixart.text)),
      ));
  }
}

String _dias(int n) => n == 1 ? '1 dia' : '$n dias';

/// A chama dentro de um anel que enche conforme a meta do dia. Apagada (cinza)
/// quando não há sequência.
class AnelDaMeta extends StatelessWidget {
  final double progresso;
  final bool acesa;
  final double tamanho;
  const AnelDaMeta({super.key, required this.progresso, required this.acesa, required this.tamanho});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: tamanho,
        height: tamanho,
        child: CustomPaint(
          painter: _AnelPainter(progresso.clamp(0.0, 1.0), Mixart.brand, Mixart.textHint.withValues(alpha: .45)),
          child: Center(child: Chama(tamanho: tamanho * .52, acesa: acesa)),
        ),
      );
}

/// 🔥, em tons de cinza quando [acesa] é falso.
class Chama extends StatelessWidget {
  final double tamanho;
  final bool acesa;
  const Chama({super.key, required this.tamanho, required this.acesa});

  static const _cinza = ColorFilter.matrix(<double>[
    .2126, .7152, .0722, 0, 0, //
    .2126, .7152, .0722, 0, 0,
    .2126, .7152, .0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final emoji = Text('🔥', style: TextStyle(fontSize: tamanho, height: 1));
    return acesa ? emoji : Opacity(opacity: .55, child: ColorFiltered(colorFilter: _cinza, child: emoji));
  }
}

class _AnelPainter extends CustomPainter {
  final double progresso;
  final Color cor, fundo;
  _AnelPainter(this.progresso, this.cor, this.fundo);

  @override
  void paint(Canvas canvas, Size size) {
    const largura = 3.0;
    final r = Rect.fromLTWH(largura / 2, largura / 2, size.width - largura, size.height - largura);
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = largura
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, pincel..color = fundo);
    if (progresso > 0) {
      canvas.drawArc(r, -math.pi / 2, math.pi * 2 * progresso, false, pincel..color = cor);
    }
  }

  @override
  bool shouldRepaint(_AnelPainter o) => o.progresso != progresso || o.cor != cor || o.fundo != fundo;
}
