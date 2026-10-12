import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/mixart.dart';
import '../../../core/util/salvar_texto.dart';
import '../domain/baralhos.dart';
import '../domain/exportar_anki.dart';
import '../domain/srs.dart';

/// Exportar para o Anki de verdade: o arquivo de texto (TAB) que o "Importar" do Anki lê,
/// com a frente em inglês e o verso em português (ou ao contrário), tags por baralho. Também
/// o histórico de revisões em CSV. Copia ou, no navegador, baixa o arquivo.
Future<void> mostrarExportarAnki(
  BuildContext context, {
  required IndiceBaralhos indice,
  required List<EntradaHistorico> historico,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _Dialogo(indice: indice, historico: historico),
    );

enum _Escopo { tudo, meus }

class _Dialogo extends StatefulWidget {
  final IndiceBaralhos indice;
  final List<EntradaHistorico> historico;
  const _Dialogo({required this.indice, required this.historico});

  @override
  State<_Dialogo> createState() => _DialogoState();
}

class _DialogoState extends State<_Dialogo> {
  _Escopo _escopo = _Escopo.tudo;
  bool _invertido = false;
  String? _recado;

  List<Baralho> get _baralhos => [for (final b in widget.indice.baralhos) if (_escopo == _Escopo.tudo || b.propria) b];

  String get _texto => exportarParaAnki(_baralhos, invertido: _invertido);

  int get _quantos => '\n'.allMatches(_texto).length - 3;

  Future<void> _copiar(String conteudo, String oQue) async {
    await Clipboard.setData(ClipboardData(text: conteudo));
    if (mounted) setState(() => _recado = '$oQue copiado: agora é só colar num arquivo de texto.');
  }

  void _baixar(String nome, String conteudo, String oQue) {
    final ok = salvarTexto(nome, conteudo);
    setState(() => _recado = ok ? '$oQue baixado ($nome).' : 'Não consegui baixar o arquivo; use "Copiar".');
  }

  @override
  Widget build(BuildContext context) {
    final texto = _texto;
    final n = _quantos < 0 ? 0 : _quantos;
    final previa = texto.split('\n').take(9).join('\n');
    return AlertDialog(
      backgroundColor: Mixart.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusLg), side: BorderSide(color: Mixart.border)),
      title: Text('Exportar para o Anki', style: Mixart.display(size: 19)),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'No Anki: Arquivo → Importar → escolha o arquivo. Frente = inglês, verso = português, uma tag por baralho. '
              'Só o texto vai: o áudio e os intervalos não — no Anki os cartões começam do zero.',
              style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                key: const Key('escopo-tudo'),
                label: const Text('Todos os baralhos'),
                selected: _escopo == _Escopo.tudo,
                onSelected: (_) => setState(() => _escopo = _Escopo.tudo),
              ),
              ChoiceChip(
                key: const Key('escopo-meus'),
                label: const Text('Só os meus (textos e cartões)'),
                selected: _escopo == _Escopo.meus,
                onSelected: (_) => setState(() => _escopo = _Escopo.meus),
              ),
            ]),
            SwitchListTile(
              key: const Key('inverter-exportar'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('Português na frente', style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.text)),
              value: _invertido,
              onChanged: (v) => setState(() => _invertido = v),
            ),
            Text('$n ${n == 1 ? 'cartão' : 'cartões'}', key: const Key('quantos-exportar'), style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.brand)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Mixart.bg, border: Border.all(color: Mixart.border), borderRadius: BorderRadius.circular(Mixart.radiusMd)),
              child: SelectableText(previa, key: const Key('previa-exportar'), style: Mixart.mono(size: 11, color: Mixart.textMuted)),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 6, children: [
              FilledButton(
                key: const Key('copiar-exportar'),
                onPressed: n == 0 ? null : () => _copiar(texto, 'Texto'),
                style: FilledButton.styleFrom(backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
                child: const Text('Copiar'),
              ),
              if (podeSalvarArquivo)
                OutlinedButton(
                  key: const Key('baixar-exportar'),
                  onPressed: n == 0 ? null : () => _baixar('paclingo-cartoes.txt', texto, 'Arquivo'),
                  child: const Text('Baixar .txt'),
                ),
            ]),
            const Divider(height: 28),
            Text('Histórico de revisões (CSV)', style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.text)),
            const SizedBox(height: 2),
            Text('${widget.historico.length} revisões. Para guardar ou analisar fora do app.',
                style: Mixart.ui(size: 12, color: Mixart.textMuted)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: [
              OutlinedButton(
                key: const Key('copiar-historico'),
                onPressed: widget.historico.isEmpty ? null : () => _copiar(_csv(), 'CSV'),
                child: const Text('Copiar CSV'),
              ),
              if (podeSalvarArquivo)
                OutlinedButton(
                  key: const Key('baixar-historico'),
                  onPressed: widget.historico.isEmpty ? null : () => _baixar('paclingo-historico.csv', _csv(), 'CSV'),
                  child: const Text('Baixar .csv'),
                ),
            ]),
            if (_recado != null) ...[
              const SizedBox(height: 12),
              Text(_recado!, key: const Key('recado-exportar'), style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.brand)),
            ],
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar'))],
    );
  }

  /// O histórico com a frase em inglês no lugar da chave (as que o curso carregado conhece).
  String _csv() => exportarHistorico(
        widget.historico,
        frases: (chave) => widget.indice.porChave[chave]?.cod ?? chave,
      );
}
