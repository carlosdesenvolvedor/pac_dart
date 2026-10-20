import 'package:flutter/material.dart';

import '../../../domain/roteiro_treino.dart';
import '../pastilha.dart';
import 'passo_conhecer.dart';
import 'passo_escolha.dart';

/// Passo 3: o tabuleiro de pares — inglês à esquerda, português à direita. Toca um, depois o par
/// dele: certo, os dois ficam verdes e viram buraco; errado, os dois tremem em vermelho. O 1º toque é
/// a "pergunta": no erro, quem leva a culpa é a palavra tocada primeiro ([onErro]).
class PassoPares extends StatefulWidget {
  final PassoTreino passo;
  final List<ItemTreino> itens;
  final ValueChanged<int> onAcerto;
  final ValueChanged<int> onErro;
  final VoidCallback onFim;

  /// Tocar num inglês fala a palavra.
  final ValueChanged<String>? onFalar;

  const PassoPares({
    super.key,
    required this.passo,
    required this.itens,
    required this.onAcerto,
    required this.onErro,
    required this.onFim,
    this.onFalar,
  });

  @override
  State<PassoPares> createState() => PassoParesState();
}

/// Pública para a página repassar o teclado ([tocarLinha]: 1–5 no inglês, A–E no português).
class PassoParesState extends State<PassoPares> {
  /// O 1º toque: (coluna do inglês?, item).
  (bool, int)? _sel;
  final Set<int> _feitos = {};

  /// Os que acabaram de acertar (verdes por um instante antes de virar buraco).
  final Set<int> _verdes = {};

  /// O último erro (os dois ladrilhos tremem em vermelho até o próximo toque).
  (int, int)? _erro;
  int _tremor = 0;
  int _pulo = 0;

  void _tocar(bool ingles, int item) {
    if (_feitos.contains(item)) return;
    if (ingles) widget.onFalar?.call(widget.itens[item].en);
    final sel = _sel;
    setState(() {
      _erro = null;
      _verdes.clear();
      if (sel == null || sel.$1 == ingles) {
        // 1º toque (ou trocou de ideia na mesma coluna)
        _sel = sel != null && sel.$2 == item ? null : (ingles, item);
        return;
      }
      _sel = null;
      if (sel.$2 == item) {
        _feitos.add(item);
        _verdes.add(item);
        _pulo++;
        widget.onAcerto(item);
      } else {
        _erro = ingles ? (item, sel.$2) : (sel.$2, item);
        _tremor++;
        widget.onErro(sel.$2);
      }
    });
    if (_feitos.length == widget.passo.esquerda.length) widget.onFim();
  }

  /// Toca o ladrilho da [linha] (0 = o de cima) na coluna do inglês ou do português — o teclado.
  void tocarLinha(bool ingles, int linha) {
    final coluna = ingles ? widget.passo.esquerda : widget.passo.direita;
    if (linha < 0 || linha >= coluna.length) return;
    _tocar(ingles, coluna[linha]);
  }

  static const _letras = 'ABCDE';

  Widget _ladrilho(bool ingles, int item, int linha, bool teclas) {
    final feito = _feitos.contains(item);
    final verde = _verdes.contains(item);
    final errado = _erro != null && (ingles ? _erro!.$1 == item : _erro!.$2 == item);
    final selecionado = _sel != null && _sel!.$1 == ingles && _sel!.$2 == item;
    final texto = ingles ? widget.itens[item].en : widget.itens[item].pt;
    return Ladrilho3D(
      key: Key('treino-par-${ingles ? 'en' : 'pt'}-$item'),
      texto: texto,
      tecla: teclas && ingles ? linha + 1 : null,
      letra: teclas && !ingles && linha < _letras.length ? _letras[linha] : null,
      mono: ingles,
      altura: 54,
      tamanhoTexto: 15.5,
      vazio: feito && !verde,
      selecionado: selecionado,
      marca: verde ? MarcaPastilha.certa : (errado ? MarcaPastilha.errada : MarcaPastilha.nenhuma),
      tremer: errado ? _tremor : 0,
      pular: verde ? _pulo : 0,
      onTap: feito ? null : () => _tocar(ingles, item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esq = widget.passo.esquerda, dir = widget.passo.direita;
    // o número/letra da tecla só no computador (no celular, o espaço é da palavra)
    return LayoutBuilder(builder: (context, c) {
      final teclas = c.maxWidth >= 520;
      return Column(
        key: const Key('passo-pares'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TituloPasso('Toque nos pares'),
          const SizedBox(height: 22),
          for (var i = 0; i < esq.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _ladrilho(true, esq[i], i, teclas)),
              const SizedBox(width: 12),
              Expanded(child: _ladrilho(false, dir[i], i, teclas)),
            ]),
          ],
        ],
      );
    });
  }
}
