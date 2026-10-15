import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../domain/cenario.dart';
import 'conversa_page.dart';
import 'ia_cubit.dart';

/// Lê `assets/ingles/cenarios.json` (a lista vazia se faltar ou estiver estragado).
Future<List<Cenario>> carregarCenarios() async {
  try {
    return cenariosDeJson(jsonDecode(await rootBundle.loadString('assets/ingles/cenarios.json')));
  } catch (_) {
    return const [];
  }
}

/// A lista de cenários, por etapa. Cada um abre uma conversa com o Prof. Dash.
class CenariosPage extends StatefulWidget {
  /// Testes dão a lista pronta (o relógio falso do testWidgets não espera I/O de asset).
  final Future<List<Cenario>> Function()? carregador;
  const CenariosPage({super.key, this.carregador});

  @override
  State<CenariosPage> createState() => _CenariosPageState();
}

class _CenariosPageState extends State<CenariosPage> {
  late final Future<List<Cenario>> _futuro = (widget.carregador ?? carregarCenarios)();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 48), children: [
              Row(children: [
                IconButton(
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
                  style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
                ),
                const SizedBox(width: 12),
                const Text('💬', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(child: Text('Conversar', style: Mixart.display(size: 22))),
              ]),
              const SizedBox(height: 10),
              Text(
                  'Ensaie situações reais em inglês: o Prof. Dash faz o outro papel e você escreve. '
                  'Ele só corrige no fim, com o que foi bem, as correções e 3 frases para virar cartão.',
                  style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.5)),
              const SizedBox(height: 6),
              BlocBuilder<IaCubit, IaState>(
                builder: (_, ia) => Text(ia.carregado ? (ia.restantes == 1 ? 'Resta 1 uso hoje' : 'Restam ${ia.restantes} usos hoje') : '',
                    key: const Key('cenarios-restantes'), style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textFaint)),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<Cenario>>(
                future: _futuro,
                builder: (context, snap) {
                  if (!snap.hasData) return Padding(padding: const EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: Mixart.brand)));
                  final lista = snap.data!;
                  if (lista.isEmpty) {
                    return Text('Não encontrei os cenários agora. Tente de novo mais tarde.', style: Mixart.ui(size: 13, color: Mixart.textMuted));
                  }
                  final etapas = <String>[for (final c in lista) c.etapa]..sort();
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final e in etapas.toSet()) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 12, 0, 6),
                        child: Text(e, style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 1.2)),
                      ),
                      for (final c in lista.where((c) => c.etapa == e)) _CartaoCenario(cenario: c),
                    ],
                  ]);
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CartaoCenario extends StatelessWidget {
  final Cenario cenario;
  const _CartaoCenario({required this.cenario});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          key: Key('cenario-${cenario.id}'),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ConversaPage(cenario: cenario))),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Mixart.surface,
              border: Border.all(color: Mixart.border),
              borderRadius: BorderRadius.circular(Mixart.radiusLg),
            ),
            child: Row(children: [
              Text(cenario.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cenario.titulo, style: Mixart.display(size: 16)),
                  const SizedBox(height: 3),
                  Text(cenario.objetivo, style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.4)),
                ]),
              ),
              Icon(Icons.chevron_right, color: Mixart.textMuted),
            ]),
          ),
        ),
      );
}
