import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../ingles/domain/cartoes_texto.dart';
import '../../ingles/presentation/revisao_cubit.dart';
import '../domain/sessao_cenario.dart';
import 'widgets/botao_por_que.dart';

/// Salva [c] em "Meus cartões" pelo mesmo caminho do "Novo cartão" (a mesma frente só troca o
/// verso, nunca duplica) e, no 1º cartão, liga o inglês → português do baralho.
Future<void> salvarCartaoDoCenario(BuildContext context, CartaoEscrito c) async {
  final bloc = context.read<CursoBloc>();
  final revisao = RevisaoCubit.de(context);
  final primeiraVez = !bloc.state.trilhas.any((t) => t.textoId == idCartoesAvulsos);
  bloc.add(CartaoAdicionado(c));
  // espera o cartão aparecer no baralho (o bloc grava antes de atualizar)
  try {
    await bloc.stream
        .firstWhere((s) => s.trilhas.any((t) =>
            t.textoId == idCartoesAvulsos &&
            t.licoes.any((l) => l.trechos.any((x) => x.cod.toLowerCase() == c.en.toLowerCase() && x.dica == c.pt))))
        .timeout(const Duration(seconds: 5));
  } catch (_) {}
  if (primeiraVez && revisao != null) {
    await revisao.mudarConfig(revisao.state.config.comReversos(['txt:$idCartoesAvulsos'], ligar: true));
  }
}

/// O feedback de uma conversa: o que foi bem, até 3 correções explicadas e até 3 frases que
/// viram cartão com um toque. Com o JSON estragado mostra o texto como veio (sem cartões).
class FeedbackCenarioView extends StatefulWidget {
  final FeedbackCenario feedback;
  const FeedbackCenarioView({super.key, required this.feedback});

  @override
  State<FeedbackCenarioView> createState() => _FeedbackCenarioViewState();
}

class _FeedbackCenarioViewState extends State<FeedbackCenarioView> {
  final _salvos = <String>{};
  final _salvando = <String>{};

  Future<void> _salvar(CartaoEscrito c) async {
    if (_salvando.contains(c.en) || _salvos.contains(c.en)) return;
    setState(() => _salvando.add(c.en));
    await salvarCartaoDoCenario(context, c);
    if (!mounted) return;
    setState(() {
      _salvando.remove(c.en);
      _salvos.add(c.en);
    });
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(t, style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: .8)),
      );

  @override
  Widget build(BuildContext context) {
    final f = widget.feedback;
    final corpo = f.estruturado
        ? <Widget>[
            if (f.foiBem.isNotEmpty) ...[
              _titulo('O QUE FOI BEM'),
              for (final b in f.foiBem)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('✅ $b', style: Mixart.ui(size: 13.5, color: Mixart.text).copyWith(height: 1.45)),
                ),
            ],
            if (f.correcoes.isNotEmpty) ...[
              _titulo('PARA MELHORAR'),
              for (final c in f.correcoes)
                Container(
                  key: const Key('correcao-cenario'),
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Mixart.surfaceHi,
                    border: Border.all(color: Mixart.border),
                    borderRadius: BorderRadius.circular(Mixart.radiusMd),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.sua, style: Mixart.ui(size: 13, color: Mixart.danger).copyWith(decoration: TextDecoration.lineThrough, decorationColor: Mixart.danger)),
                    const SizedBox(height: 3),
                    Text(c.melhor, style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.brand)),
                    if (c.porque.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText.rich(comNegrito(c.porque, Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.45))),
                    ],
                  ]),
                ),
            ],
            if (f.frases.isNotEmpty) ...[
              _titulo('FRASES PARA LEVAR'),
              for (var i = 0; i < f.frases.length; i++) _frase(i, f.frases[i]),
            ],
          ]
        : <Widget>[
            const SizedBox(height: 8),
            Text('Não consegui organizar o feedback, mas aqui está o que o Prof. Dash disse:',
                key: const Key('feedback-cru'), style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
            const SizedBox(height: 8),
            SelectableText(f.textoCru ?? '', style: Mixart.ui(size: 13.5, color: Mixart.text).copyWith(height: 1.5)),
          ];
    return Container(
      key: const Key('feedback-cenario'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.brandDim),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🐦 Feedback do Prof. Dash', style: Mixart.display(size: 18)),
        ...corpo,
      ]),
    );
  }

  Widget _frase(int i, CartaoEscrito c) {
    final salvo = _salvos.contains(c.en), salvando = _salvando.contains(c.en);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Mixart.surfaceHi,
        border: Border.all(color: salvo ? Mixart.brand : Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.en, key: Key('frase-cenario-$i'), style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.text)),
            const SizedBox(height: 2),
            Text(c.pt, style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
          ]),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          key: Key('salvar-cartao-$i'),
          onPressed: salvo || salvando ? null : () => _salvar(c),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: salvo ? Mixart.brand : Mixart.brandDim),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: Text(salvo ? '✓ Salvo' : (salvando ? 'Salvando…' : 'Salvar como cartão'),
              style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.brand)),
        ),
      ]),
    );
  }
}
