import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/habito.dart';
import '../habito_cubit.dart';
import '../lembrete_cubit.dart';
import 'chip_sequencia.dart';

/// Abre a folha "Sua sequência" (toque no chip do cabeçalho).
Future<void> mostrarSequencia(BuildContext context) {
  final cubit = HabitoCubit.de(context);
  if (cubit == null) return Future.value();
  final lembrete = LembreteCubit.de(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Mixart.surface,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusLg))),
    // o lembrete (Fase 1B) é opcional: sem ele na árvore a folha é a de sempre
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: lembrete == null
          ? const SequenciaSheet()
          : BlocProvider.value(value: lembrete, child: const SequenciaSheet()),
    ),
  );
}

const _gelo = Color(0xFF7CC4FF);

/// Chama grande, dias seguidos, melhor sequência, progresso de hoje, congelamentos,
/// os últimos 14 dias e o seletor da meta. Tom acolhedor: sequência que acabou é
/// "recomece hoje", nunca "você perdeu".
class SequenciaSheet extends StatelessWidget {
  const SequenciaSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = HabitoCubit.de(context)!;
    return BlocBuilder<HabitoCubit, HabitoState>(
      builder: (context, st) {
        final agora = cubit.agora();
        final h = st.habito;
        final dias = h.sequenciaVisivel(agora);
        final viva = dias > 0;
        final bateu = h.bateuHoje(agora);
        final feitas = h.feitasHoje(agora);
        final faltam = (h.meta - feitas).clamp(0, h.meta);
        final String titulo;
        final String frase;
        if (viva) {
          titulo = dias == 1 ? '1 dia seguido' : '$dias dias seguidos';
          frase = bateu
              ? 'Meta de hoje batida. Volte amanhã e some mais um dia.'
              : '${_inicial(_faltam(faltam))} hoje para manter a chama acesa.';
        } else {
          titulo = 'Comece hoje';
          frase = h.ultimoDiaMeta == null
              ? 'Faça ${h.meta} exercícios hoje e acenda sua primeira chama.'
              : 'Recomece hoje: ${h.meta} exercícios e a chama volta a acender.';
        }
        return SingleChildScrollView(
          key: const Key('sequencia-sheet'),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Chama(tamanho: 64, acesa: viva)),
            const SizedBox(height: 6),
            Text(titulo, textAlign: TextAlign.center, style: Mixart.display(size: 28, color: viva ? Mixart.brand : Mixart.text)),
            const SizedBox(height: 4),
            Text(frase, textAlign: TextAlign.center, style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.5)),
            const SizedBox(height: 18),
            _ProgressoDeHoje(feitas: feitas, meta: h.meta, bateu: bateu),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Numero(chave: 'melhor', rotulo: 'Melhor sequência', valor: h.melhor == 1 ? '1 dia' : '${h.melhor} dias')),
              const SizedBox(width: 10),
              Expanded(
                child: _Numero(
                  chave: 'congelamentos',
                  rotulo: 'Congelamentos',
                  valor: '❄️ ${h.congelamentos}/${RegrasHabito.maxCongelamentos}',
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              'A cada ${RegrasHabito.diasPorCongelamento} dias seguidos você ganha um ❄️ (guarda até ${RegrasHabito.maxCongelamentos}). '
              'Ele cobre um dia sem estudo sozinho, sem você fazer nada.',
              style: Mixart.ui(size: 11.5, color: Mixart.textFaint).copyWith(height: 1.5),
            ),
            const SizedBox(height: 18),
            Text('Últimos 14 dias', style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textMuted)),
            const SizedBox(height: 8),
            _Ultimos14(habito: h, hoje: h.hoje(agora)),
            const SizedBox(height: 18),
            Text('Meta do dia', style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textMuted)),
            const SizedBox(height: 8),
            Row(children: [
              for (final m in RegrasHabito.metas) ...[
                if (m != RegrasHabito.metas.first) const SizedBox(width: 8),
                Expanded(child: _OpcaoMeta(meta: m, escolhida: h.meta == m, onTap: () => cubit.mudarMeta(m))),
              ],
            ]),
            const SizedBox(height: 18),
            const _SecaoLembrete(),
          ]),
        );
      },
    );
  }

  static String _faltam(int n) => n == 1 ? 'falta 1 exercício' : 'faltam $n exercícios';
  static String _inicial(String s) => s[0].toUpperCase() + s.substring(1);
}

class _ProgressoDeHoje extends StatelessWidget {
  final int feitas, meta;
  final bool bateu;
  const _ProgressoDeHoje({required this.feitas, required this.meta, required this.bateu});

  @override
  Widget build(BuildContext context) {
    final p = (feitas / meta).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Mixart.surfaceHi,
        border: Border.all(color: bateu ? Mixart.brand : Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('Hoje', style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.textMuted)),
          const Spacer(),
          Text(bateu && feitas >= meta ? '$feitas/$meta ✓' : '$feitas/$meta',
              key: const Key('progresso-hoje'), style: Mixart.display(size: 16, color: bateu ? Mixart.brand : Mixart.text)),
          Text(' hoje', style: Mixart.ui(size: 12, color: Mixart.textMuted)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: bateu ? 1 : p,
            minHeight: 8,
            backgroundColor: Mixart.border,
            valueColor: AlwaysStoppedAnimation(Mixart.brand),
          ),
        ),
      ]),
    );
  }
}

class _Numero extends StatelessWidget {
  final String chave, rotulo, valor;
  const _Numero({required this.chave, required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) => Container(
        key: Key('numero-$chave'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Mixart.surfaceHi,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(rotulo, style: Mixart.ui(size: 11, weight: FontWeight.w600, color: Mixart.textMuted)),
          const SizedBox(height: 3),
          Text(valor, style: Mixart.display(size: 17)),
        ]),
      );
}

/// Duas semanas em duas linhas de 7 (cabe em 360 px): feito, congelado ou perdido.
class _Ultimos14 extends StatelessWidget {
  final Habito habito;
  final int hoje;
  const _Ultimos14({required this.habito, required this.hoje});

  @override
  Widget build(BuildContext context) {
    // antes do 1º dia de estudo não houve "dia perdido": só um ponto apagado
    final primeiro = [...habito.historico, ...habito.congelados].fold<int?>(null, (m, d) => m == null || d < m ? d : m);
    final dias = [for (var i = 13; i >= 0; i--) hoje - i];
    Widget linha(List<int> ds) => Row(children: [for (final d in ds) Expanded(child: _Dia(dia: d, hoje: hoje, habito: habito, primeiro: primeiro))]);
    return Column(children: [linha(dias.sublist(0, 7)), const SizedBox(height: 8), linha(dias.sublist(7))]);
  }
}

class _Dia extends StatelessWidget {
  final int dia, hoje;
  final int? primeiro;
  final Habito habito;
  const _Dia({required this.dia, required this.hoje, required this.habito, required this.primeiro});

  static const _semana = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final estado = habito.estadoDe(dia);
    final ehHoje = dia == hoje;
    final antes = primeiro == null || dia < primeiro!;
    final letra = _semana[DateTime.utc(1970, 1, 1 + dia).weekday - 1];
    final String nome;
    final Widget marca;
    if (estado == EstadoDoDia.feito) {
      nome = 'feito';
      marca = _Bolinha(preenchida: Mixart.brand, filho: Icon(Icons.check_rounded, size: 16, color: Mixart.onBrand));
    } else if (estado == EstadoDoDia.congelado) {
      nome = 'congelado';
      marca = const _Bolinha(preenchida: _gelo, filho: Icon(Icons.ac_unit_rounded, size: 15, color: Color(0xFF0B2A44)));
    } else if (ehHoje) {
      nome = 'hoje';
      marca = _Bolinha(borda: Mixart.brand);
    } else if (antes) {
      nome = 'antes';
      marca = Container(width: 6, height: 6, decoration: BoxDecoration(color: Mixart.textHint.withValues(alpha: .5), shape: BoxShape.circle));
    } else {
      nome = 'perdido';
      marca = _Bolinha(borda: Mixart.textHint);
    }
    return Semantics(
      label: 'dia $dia: $nome',
      child: Column(key: Key('dia-$nome'), mainAxisSize: MainAxisSize.min, children: [
        Text(letra, style: Mixart.ui(size: 10, weight: FontWeight.w600, color: ehHoje ? Mixart.brand : Mixart.textFaint)),
        const SizedBox(height: 4),
        SizedBox(height: 24, child: Center(child: marca)),
      ]),
    );
  }
}

class _Bolinha extends StatelessWidget {
  final Color? preenchida, borda;
  final Widget? filho;
  const _Bolinha({this.preenchida, this.borda, this.filho});

  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: preenchida,
          shape: BoxShape.circle,
          border: borda == null ? null : Border.all(color: borda!, width: 1.6),
        ),
        child: filho == null ? null : Center(child: filho),
      );
}

class _OpcaoMeta extends StatelessWidget {
  final int meta;
  final bool escolhida;
  final VoidCallback onTap;
  const _OpcaoMeta({required this.meta, required this.escolhida, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        key: Key('meta-$meta'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: escolhida ? Mixart.brand : Mixart.surfaceHi,
            border: Border.all(color: escolhida ? Mixart.brand : Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(RegrasHabito.nomeDaMeta(meta),
                style: Mixart.ui(size: 13, weight: FontWeight.w700, color: escolhida ? Mixart.onBrand : Mixart.text)),
            const SizedBox(height: 2),
            Text('$meta por dia', style: Mixart.ui(size: 11, color: escolhida ? Mixart.onBrand : Mixart.textMuted)),
          ]),
        ),
      );
}

/// Como a pessoa escolhe o horário do lembrete (os testes trocam por um que responde na hora).
Future<TimeOfDay?> Function(BuildContext context, TimeOfDay inicial) seletorDeHorarioDoLembrete = (context, inicial) => showTimePicker(
      context: context,
      initialTime: inicial,
      helpText: 'Horário do lembrete',
      builder: (c, filho) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: filho!),
    );

/// 🔔 Lembrete diário (Fase 1B): interruptor + horário. Só Android/iOS; no navegador e no desktop uma linha explica.
/// Sem o cubit do lembrete na árvore (testes antigos) não aparece nada.
class _SecaoLembrete extends StatelessWidget {
  const _SecaoLembrete();

  @override
  Widget build(BuildContext context) {
    final cubit = LembreteCubit.de(context);
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<LembreteCubit, LembreteState>(
      builder: (context, st) {
        if (!st.carregado) return const SizedBox.shrink();
        final titulo = Text('🔔 Lembrete diário', style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textMuted));
        if (!st.disponivel) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            titulo,
            const SizedBox(height: 6),
            Text('O lembrete diário funciona no app do celular (Android e iOS).',
                key: const Key('lembrete-indisponivel'), style: Mixart.ui(size: 12, color: Mixart.textFaint).copyWith(height: 1.5)),
          ]);
        }
        final c = st.config;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          titulo,
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 10),
            decoration: BoxDecoration(
              color: Mixart.surfaceHi,
              border: Border.all(color: c.ligado ? Mixart.brand : Mixart.border),
              borderRadius: BorderRadius.circular(Mixart.radiusMd),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Lembrar de estudar', style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.text)),
                    const SizedBox(height: 2),
                    Text(
                      c.ligado
                          ? 'Todo dia às ${c.horario} — só se a meta do dia ainda não foi batida.'
                          : 'Uma notificação por dia, no horário que você escolher. Sem pressão.',
                      key: const Key('lembrete-explicacao'),
                      style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.45),
                    ),
                  ]),
                ),
                Switch(key: const Key('lembrete-switch'), value: c.ligado, onChanged: cubit.ligar),
              ]),
              if (c.ligado)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 6),
                  child: OutlinedButton.icon(
                    key: const Key('lembrete-horario'),
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text('Horário: ${c.horario}', style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Mixart.brandDim), foregroundColor: Mixart.brand),
                    onPressed: () async {
                      final t = await seletorDeHorarioDoLembrete(context, TimeOfDay(hour: c.hora, minute: c.minuto));
                      if (t != null) unawaited(cubit.mudarHorario(t.hour, t.minute));
                    },
                  ),
                ),
              if (st.permissaoNegada)
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 6),
                  child: Text(
                    'Sem permissão para notificar. Libere as notificações do Paclingo nas configurações do aparelho e tente de novo.',
                    key: const Key('lembrete-aviso'),
                    style: Mixart.ui(size: 12, color: Mixart.danger).copyWith(height: 1.45),
                  ),
                ),
            ]),
          ),
        ]);
      },
    );
  }
}
