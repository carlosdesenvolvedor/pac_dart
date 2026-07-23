import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/mixart.dart';
import '../../core/util/codigo_executavel.dart';
import 'dartpad_embed.dart';

/// Tela cheia com o DartPad de verdade, já carregado com o código do
/// exercício/projeto — ele compila e roda no servidor do Dart.
///
/// Fora do navegador (celular/desktop) não dá para embutir: aí a tela vira
/// o plano B, com o código pronto para copiar.
class DartPadPage extends StatelessWidget {
  /// Nome do exercício/projeto, só para o cabeçalho.
  final String titulo;

  /// Código como está no exercício (vira programa rodável aqui dentro).
  final String cod;
  final bool ehFlutter;

  /// Trechos anteriores da lição (o programa gerado precisa deles para fechar).
  final List<String> contexto;

  const DartPadPage({
    super.key,
    required this.titulo,
    required this.cod,
    required this.ehFlutter,
    this.contexto = const [],
  });

  String get _codigoRodavel => codigoExecutavel(cod, ehFlutter, contexto: contexto);

  Future<void> _copiar(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _codigoRodavel));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Mixart.surfaceHi,
      duration: const Duration(seconds: 3),
      content: Text('Código copiado! Cole no dartpad.dev ou na sua IDE.',
          style: Mixart.ui(size: 13, color: Mixart.text)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Column(children: [
          _cabecalho(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
                child: dartPadEmbutivel
                    ? dartPadEmbutido(
                        codigo: _codigoRodavel,
                        escuro: !Mixart.atual.ehClaro,
                      )
                    : _ForaDoNavegador(codigo: _codigoRodavel),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _cabecalho(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(children: [
          IconButton(
            tooltip: 'Voltar',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
            style: IconButton.styleFrom(
                backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('RODAR NO DARTPAD',
                  style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.brand)
                      .copyWith(letterSpacing: 2)),
              const SizedBox(height: 2),
              Text(titulo,
                  overflow: TextOverflow.ellipsis, style: Mixart.display(size: 19)),
            ]),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Mixart.textMuted,
              side: BorderSide(color: Mixart.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: Mixart.ui(size: 12, weight: FontWeight.w600),
            ),
            onPressed: () => _copiar(context),
            icon: const Icon(Icons.copy_all_outlined, size: 15),
            label: const Text('copiar'),
          ),
        ]),
      );
}

/// Plano B quando não é web: o DartPad não embute, mas o código sai pronto.
class _ForaDoNavegador extends StatelessWidget {
  final String codigo;
  const _ForaDoNavegador({required this.codigo});

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.public_off, size: 40, color: Mixart.textFaint),
              const SizedBox(height: 14),
              Text('O DartPad só abre aqui dentro no navegador',
                  textAlign: TextAlign.center, style: Mixart.display(size: 17)),
              const SizedBox(height: 8),
              Text(
                'Nesta versão do app o código não roda embutido. Copie no botão '
                'acima e cole em dartpad.dev — ele já vem como programa completo.',
                textAlign: TextAlign.center,
                style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Mixart.surface,
                  border: Border.all(color: Mixart.border),
                  borderRadius: BorderRadius.circular(Mixart.radiusMd),
                ),
                child: Text(codigo, style: Mixart.mono(size: 12).copyWith(height: 1.5)),
              ),
            ]),
          ),
        ),
      );
}
