import 'package:flutter/material.dart';

import '../../../../core/syntax/tokenizer.dart';
import '../../../../core/theme/mixart.dart';
import '../../domain/curriculo.dart';
import '../widgets/fundo_fase.dart';

/// Tela de teoria ("Nivelamento") de uma lição: um mini-capítulo com texto,
/// exemplos de código e dicas, no clima da fase. Ao final, botão para praticar.
class TeoriaPage extends StatelessWidget {
  final String nivel; // trilha, para o fundo
  final Licao licao;
  final VoidCallback onPraticar;

  const TeoriaPage({super.key, required this.nivel, required this.licao, required this.onPraticar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: Stack(children: [
        FundoFase(nivel: nivel),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  _topo(context),
                  const SizedBox(height: 20),
                  ...licao.teoria.map((b) => _bloco(b)),
                  const SizedBox(height: 24),
                  _botaoPraticar(context),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _topo(BuildContext context) => Row(children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
          style: IconButton.styleFrom(
              backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('NIVELAMENTO',
                  style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.brand)
                      .copyWith(letterSpacing: 2)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              Text(licao.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Flexible(child: Text(licao.nome, style: Mixart.display(size: 22), overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),
      ]);

  Widget _bloco(BlocoTeoria b) {
    switch (b.tipo) {
      case 'h':
        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(b.conteudo, style: Mixart.display(size: 17, color: Mixart.text)),
        );
      case 'code':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _BlocoCodigo(cod: b.conteudo),
        );
      case 'tip':
        return _caixa(b.conteudo, Icons.lightbulb_outline, Mixart.brand);
      case 'warn':
        return _caixa(b.conteudo, Icons.warning_amber_rounded, Mixart.danger);
      default: // p
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: RichText(
            text: TextSpan(
              style: Mixart.ui(size: 14.5, color: Mixart.text).copyWith(height: 1.65),
              children: _spansInline(b.conteudo),
            ),
          ),
        );
    }
  }

  Widget _caixa(String texto, IconData icone, Color cor) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: .10),
          border: Border.all(color: cor.withValues(alpha: .35)),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Mixart.ui(size: 13.5, color: Mixart.text).copyWith(height: 1.55),
                children: _spansInline(texto),
              ),
            ),
          ),
        ]),
      );

  Widget _botaoPraticar(BuildContext context) => SizedBox(
        height: 52,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Mixart.brand,
            foregroundColor: Mixart.onBrand,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd)),
            textStyle: Mixart.ui(size: 15, weight: FontWeight.w700),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onPraticar();
          },
          icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
          label: const Text('Praticar esta lição →'),
        ),
      );

  /// Converte **negrito** e `código inline` em spans.
  List<TextSpan> _spansInline(String txt) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');
    var fim = 0;
    for (final m in re.allMatches(txt)) {
      if (m.start > fim) spans.add(TextSpan(text: txt.substring(fim, m.start)));
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else {
        spans.add(TextSpan(
          text: ' ${m.group(2)} ',
          style: Mixart.mono(size: 12.5, color: Mixart.brand).copyWith(
            backgroundColor: Mixart.surfaceHi,
          ),
        ));
      }
      fim = m.end;
    }
    if (fim < txt.length) spans.add(TextSpan(text: txt.substring(fim)));
    return spans;
  }
}

class _BlocoCodigo extends StatelessWidget {
  final String cod;
  const _BlocoCodigo({required this.cod});

  @override
  Widget build(BuildContext context) {
    final tipos = tokenizar(cod);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Mixart.bg,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Text.rich(
        TextSpan(children: [
          for (var k = 0; k < cod.length; k++)
            TextSpan(
              text: cod[k],
              style: TextStyle(
                color: switch (tipos[k]) {
                  TokenTipo.keyword => SyntaxColors.kw,
                  TokenTipo.ident => SyntaxColors.ident,
                  TokenTipo.literal => SyntaxColors.literal,
                  TokenTipo.punct => SyntaxColors.punct,
                  TokenTipo.comment => SyntaxColors.comment,
                },
                fontWeight: tipos[k] == TokenTipo.keyword ? FontWeight.w700 : FontWeight.w400,
                fontStyle: tipos[k] == TokenTipo.comment ? FontStyle.italic : null,
              ),
            ),
        ]),
        style: Mixart.mono(size: 13).copyWith(height: 1.6),
      ),
    );
  }
}
