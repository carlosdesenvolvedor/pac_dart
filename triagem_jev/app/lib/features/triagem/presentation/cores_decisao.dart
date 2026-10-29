import 'package:flutter/material.dart';

import '../domain/estudo.dart';
import '../domain/resultado_estudo.dart';

/// Verde incluído, vermelho excluído, amarelo incerto (seção 4.3 do plano).
abstract final class CoresDecisao {
  static const incluir = Color(0xFF2E7D32);
  static const excluir = Color(0xFFC62828);
  static const incerto = Color(0xFFF9A825);

  static Color de(Decisao? d) => switch (d) {
    Decisao.incluir => incluir,
    Decisao.excluir => excluir,
    Decisao.incerto => incerto,
    null => Colors.grey,
  };

  static Color daFaixa(Faixa? f) => de(f?.comoDecisao);

  static String rotulo(Decisao? d) => switch (d) {
    Decisao.incluir => 'incluir',
    Decisao.excluir => 'excluir',
    Decisao.incerto => 'incerto',
    null => '—',
  };
}

/// Etiqueta colorida com a decisão.
class EtiquetaDecisao extends StatelessWidget {
  final Decisao? decisao;
  final String? texto;
  const EtiquetaDecisao(this.decisao, {super.key, this.texto});

  @override
  Widget build(BuildContext context) {
    final cor = CoresDecisao.de(decisao);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        border: Border.all(color: cor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto ?? CoresDecisao.rotulo(decisao),
        style: TextStyle(color: cor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
