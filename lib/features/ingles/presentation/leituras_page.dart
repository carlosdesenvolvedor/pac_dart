import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../data/tradutor.dart';
import '../data/voz_ingles.dart';
import '../domain/leitura.dart';
import 'leitura_page.dart';
import 'revisao_cubit.dart';

/// Lê `assets/ingles/leituras.json` (lista vazia se faltar ou estiver estragado).
Future<List<Leitura>> carregarLeituras() async {
  try {
    return leiturasDeJson(jsonDecode(await rootBundle.loadString('assets/ingles/leituras.json')));
  } catch (_) {
    return const [];
  }
}

/// A lista de textos para ler: os graduados (por etapa) e os "Meus textos" que a pessoa já colou.
class LeiturasPage extends StatefulWidget {
  /// Injetáveis (testes): a lista dos graduados (o relógio falso do testWidgets não espera I/O de asset),
  /// o tradutor e a voz.
  final Future<List<Leitura>> Function()? carregador;
  final Tradutor? tradutor;
  final VozIngles? voz;

  const LeiturasPage({super.key, this.carregador, this.tradutor, this.voz});

  @override
  State<LeiturasPage> createState() => _LeiturasPageState();
}

class _LeiturasPageState extends State<LeiturasPage> {
  late final Future<List<Leitura>> _futuro = (widget.carregador ?? carregarLeituras)();

  void _abrir(Leitura l) {
    final curso = context.read<CursoBloc>();
    final revisao = RevisaoCubit.de(context);
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => MultiBlocProvider(
        providers: [BlocProvider.value(value: curso), if (revisao != null) BlocProvider.value(value: revisao)],
        child: LeituraPage(leitura: l, tradutor: widget.tradutor, voz: widget.voz),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final trilhas = context.select((CursoBloc b) => b.state.trilhas);
    final dela = [for (final t in trilhas) ?Leitura.deTrilha(t)];
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
                const Text('📖', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(child: Text('Ler', style: Mixart.display(size: 22))),
              ]),
              const SizedBox(height: 10),
              Text('Leia textos curtos em inglês e toque numa palavra que você não conhece: ela vira um cartão de lacuna, '
                  'com a frase inteira como contexto.',
                  style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.5)),
              const SizedBox(height: 10),
              FutureBuilder<List<Leitura>>(
                future: _futuro,
                builder: (context, snap) {
                  if (!snap.hasData) return Padding(padding: const EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: Mixart.brand)));
                  final graduadas = snap.data!;
                  final etapas = <String>{for (final l in graduadas) l.etapa}.toList()..sort();
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (dela.isNotEmpty) ...[
                      _Rotulo('SEUS TEXTOS'),
                      for (final l in dela) _CartaoLeitura(leitura: l, onTap: () => _abrir(l)),
                    ],
                    for (final e in etapas) ...[
                      _Rotulo(e),
                      for (final l in graduadas.where((l) => l.etapa == e)) _CartaoLeitura(leitura: l, onTap: () => _abrir(l)),
                    ],
                    if (graduadas.isEmpty && dela.isEmpty)
                      Text('Não encontrei textos agora. Tente de novo mais tarde.', style: Mixart.ui(size: 13, color: Mixart.textMuted)),
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

class _Rotulo extends StatelessWidget {
  final String texto;
  const _Rotulo(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 0, 6),
        child: Text(texto, style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 1.2)),
      );
}

class _CartaoLeitura extends StatelessWidget {
  final Leitura leitura;
  final VoidCallback onTap;
  const _CartaoLeitura({required this.leitura, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          key: Key('leitura-${leitura.id}'),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Mixart.surface,
              border: Border.all(color: Mixart.border),
              borderRadius: BorderRadius.circular(Mixart.radiusLg),
            ),
            child: Row(children: [
              Text(leitura.propria ? '📝' : '📖', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(leitura.titulo, style: Mixart.display(size: 16)),
                  const SizedBox(height: 3),
                  Text('${leitura.frases.length} ${leitura.frases.length == 1 ? 'frase' : 'frases'}',
                      style: Mixart.ui(size: 12, color: Mixart.textMuted)),
                ]),
              ),
              Icon(Icons.chevron_right, color: Mixart.textMuted),
            ]),
          ),
        ),
      );
}
