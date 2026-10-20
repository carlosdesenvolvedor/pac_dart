// "📖 Guia" de uma unidade do PAC·ENGLISH: a descrição da trilha, o resumo de cada lição e as palavras
// novas da unidade, com o botão de treinar.
import 'package:flutter/material.dart';

import '../../../../../core/theme/mixart.dart';
import '../../../../../core/ui/festa.dart';
import '../../../../ingles/domain/palavras_novas.dart';
import '../../../domain/curriculo.dart';

/// Abre o guia da [trilha]. [feitas][l] marca as lições concluídas; [onTreinar] (null = sem palavras
/// prontas) treina as [palavras].
Future<void> abrirGuiaTrilha(
  BuildContext context, {
  required Trilha trilha,
  required String sobretitulo,
  required Color cor,
  required List<bool> feitas,
  List<PalavraNova> palavras = const [],
  VoidCallback? onTreinar,
}) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Mixart.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusLg))),
      builder: (sheet) => _GuiaTrilha(
        trilha: trilha,
        sobretitulo: sobretitulo,
        cor: cor,
        feitas: feitas,
        palavras: palavras,
        onTreinar: onTreinar == null
            ? null
            : () {
                Navigator.of(sheet).pop();
                onTreinar();
              },
      ),
    );

class _GuiaTrilha extends StatelessWidget {
  final Trilha trilha;
  final String sobretitulo;
  final Color cor;
  final List<bool> feitas;
  final List<PalavraNova> palavras;
  final VoidCallback? onTreinar;

  const _GuiaTrilha({
    required this.trilha,
    required this.sobretitulo,
    required this.cor,
    required this.feitas,
    required this.palavras,
    this.onTreinar,
  });

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.sizeOf(context).height;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: altura * .86),
      child: SafeArea(
        child: SingleChildScrollView(
          key: const Key('guia-trilha'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: Mixart.surfaceHi, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            Text('📖 GUIA · $sobretitulo',
                style: Mixart.ui(size: 11, weight: FontWeight.w900, color: cor).copyWith(letterSpacing: 1.4)),
            const SizedBox(height: 4),
            Text('${trilha.emoji} ${trilha.nivel}', style: Mixart.display(size: 21)),
            if (trilha.descricao.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(trilha.descricao, style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.5)),
            ],
            if (palavras.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text('PALAVRAS DA UNIDADE',
                  style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
              const SizedBox(height: 8),
              Wrap(spacing: 7, runSpacing: 7, children: [
                for (final p in palavras)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Mixart.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Mixart.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(p.en, style: Mixart.mono(size: 13, weight: FontWeight.w700, color: Mixart.text)),
                      if (p.pt.isNotEmpty) Text(p.pt, style: Mixart.ui(size: 10.5, color: Mixart.textMuted)),
                    ]),
                  ),
              ]),
              if (onTreinar != null) ...[
                const SizedBox(height: 12),
                Botao3D(key: const Key('guia-treinar'), rotulo: '🎯 Treinar', cor: cor, onTap: onTreinar),
              ],
            ],
            const SizedBox(height: 18),
            Text('LIÇÕES',
                style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
            const SizedBox(height: 6),
            for (var l = 0; l < trilha.licoes.length; l++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: l < feitas.length && feitas[l] ? CoresFesta.ouro : Mixart.surfaceHi,
                    ),
                    child: l < feitas.length && feitas[l]
                        ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                        : Text(trilha.licoes[l].emoji, style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(trilha.licoes[l].nome, style: Mixart.ui(size: 14, weight: FontWeight.w700)),
                      if (trilha.licoes[l].resumo.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(trilha.licoes[l].resumo,
                              style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.45)),
                        ),
                    ]),
                  ),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}
