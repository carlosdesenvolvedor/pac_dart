import 'package:flutter/material.dart';

/// A logo oficial do Paclingo (quadrado azul-marinho com o nome, o Pac de boné e a
/// moldura neon): o arquivo `assets/brand/paclingo-logo.png` (512 px, gerado de
/// `branding/paclingo-logo.png`) com cantos arredondados. Já traz o nome escrito,
/// então não se coloca texto "PACLINGO" ao lado — o HUD continua com o [LogoPacDart] pequeno.
class LogoPaclingo extends StatelessWidget {
  final double tamanho;
  const LogoPaclingo({super.key, this.tamanho = 140});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(tamanho * .22),
        child: Image.asset(
          'assets/brand/paclingo-logo.png',
          width: tamanho,
          height: tamanho,
          fit: BoxFit.cover,
          semanticLabel: 'Paclingo',
          filterQuality: FilterQuality.medium,
        ),
      );
}
