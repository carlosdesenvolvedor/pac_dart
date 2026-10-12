import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/mixart.dart';
import '../domain/cartoes_texto.dart';
import '../domain/texto_salvo.dart';

/// Escolhe um arquivo de texto e devolve o conteúdo (null = cancelou).
typedef SeletorTexto = Future<String?> Function();

Future<String?> seletorDeTextoDoSistema() async {
  final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['txt', 'tsv', 'csv']);
  if (f == null) return null;
  return const Utf8Decoder(allowMalformed: true).convert(await f.readAsBytes());
}

/// "Importar lista": cola (ou carrega de um arquivo) cartões no formato do Anki — inglês e
/// português separados por TAB, `;` ou `|`, uma linha por cartão — e devolve um [TextoSalvo] (um
/// baralho novo). Quem chama põe o baralho na lista.
class ImportarCartoesPage extends StatefulWidget {
  final String textoInicial;
  final SeletorTexto? seletor;
  const ImportarCartoesPage({super.key, this.textoInicial = '', this.seletor});

  @override
  State<ImportarCartoesPage> createState() => _ImportarCartoesPageState();
}

class _ImportarCartoesPageState extends State<ImportarCartoesPage> {
  final _titulo = TextEditingController();
  late final _texto = TextEditingController(text: widget.textoInicial);
  late ResultadoImportacao _lido = lerListaDeCartoes(widget.textoInicial);
  String? _erro;

  @override
  void dispose() {
    _titulo.dispose();
    _texto.dispose();
    super.dispose();
  }

  Future<void> _arquivo() async {
    try {
      final t = await (widget.seletor ?? seletorDeTextoDoSistema)();
      if (t == null || !mounted) return;
      setState(() {
        _texto.text = t;
        _lido = lerListaDeCartoes(t);
        _erro = null;
      });
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não consegui abrir o arquivo. Tente outro, ou cole o texto aqui.');
    }
  }

  void _importar() {
    if (_lido.cartoes.isEmpty) return;
    final titulo = _titulo.text.trim();
    Navigator.of(context).pop(textoDeCartoes(_lido.cartoes, titulo: titulo.isEmpty ? 'Cartões importados' : titulo));
  }

  InputDecoration _campo(String dica) => InputDecoration(
        hintText: dica,
        hintStyle: Mixart.ui(size: 13.5, color: Mixart.textFaint),
        filled: true,
        fillColor: Mixart.surface,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.brand, width: 1.4)),
      );

  @override
  Widget build(BuildContext context) {
    final n = _lido.cartoes.length;
    return Scaffold(
      backgroundColor: Mixart.bg,
      appBar: AppBar(
        backgroundColor: Mixart.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20)),
        title: Text('Importar lista de cartões', style: Mixart.display(size: 17)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 40), children: [
              Text(
                'Um cartão por linha: o inglês, um separador e o português. Serve o arquivo de texto que o Anki exporta '
                '(campos separados por TAB) ou linhas como "I am hungry ; Estou com fome" e "I am hungry | Estou com fome".',
                style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.55),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('titulo-importar'),
                controller: _titulo,
                maxLength: 40,
                style: Mixart.ui(size: 14, color: Mixart.text),
                decoration: _campo('Nome do baralho (se deixar em branco: "Cartões importados")'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('texto-importar'),
                controller: _texto,
                minLines: 9,
                maxLines: 16,
                keyboardType: TextInputType.multiline,
                onChanged: (v) => setState(() {
                  _lido = lerListaDeCartoes(v);
                  _erro = null;
                }),
                style: Mixart.mono(size: 13, color: Mixart.text).copyWith(height: 1.5),
                decoration: _campo('I am hungry ; Estou com fome\nWhere is the station? ; Onde fica a estação?'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('arquivo-importar'),
                  onPressed: _arquivo,
                  icon: Icon(Icons.upload_file_rounded, size: 18, color: Mixart.textMuted),
                  label: Text('Ou carregar de um arquivo (.txt, .tsv, .csv)', style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.textMuted)),
                ),
              ),
              const SizedBox(height: 6),
              if (n > 0) ...[
                Text('$n ${n == 1 ? 'cartão pronto' : 'cartões prontos'}${_lido.ignoradas > 0 ? ' · ${_lido.ignoradas} ${_lido.ignoradas == 1 ? 'linha ignorada' : 'linhas ignoradas'}' : ''}',
                    key: const Key('contagem-importar'), style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.brand)),
                const SizedBox(height: 8),
                for (final c in _lido.cartoes.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${c.en}  →  ${c.pt}', style: Mixart.ui(size: 12.5, color: Mixart.textMuted), overflow: TextOverflow.ellipsis),
                  ),
                if (n > 3) Text('… e mais ${n - 3}', style: Mixart.ui(size: 12, color: Mixart.textFaint)),
              ] else if (_texto.text.trim().isNotEmpty)
                Text('Não achei nenhum cartão: confira se cada linha tem o inglês, um separador (TAB, ; ou |) e o português.',
                    key: const Key('vazio-importar'), style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
              if (_lido.simplificou) _aviso('Troquei letras acentuadas e aspas curvas do inglês por sinais simples, para dar para digitar.'),
              if (_lido.cortado) _aviso('A lista passou de $maxCartoesPorImportacao cartões; usei os primeiros. Importe o resto em outro baralho.'),
              if (_erro != null) _aviso(_erro!),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  key: const Key('botao-importar'),
                  onPressed: n == 0 ? null : _importar,
                  style: FilledButton.styleFrom(
                    backgroundColor: Mixart.brand,
                    foregroundColor: Mixart.onBrand,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                  ),
                  child: Text(n == 0 ? 'Importar' : 'Importar $n ${n == 1 ? 'cartão' : 'cartões'}',
                      style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.onBrand)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _aviso(String t) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('ℹ️ $t', style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.45)),
      );
}
