import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';

/// Como a pastilha foi conferida: sem marca (ainda não conferiu), certa (verde) ou errada (vermelha).
enum MarcaPastilha { nenhuma, certa, errada }

/// Um bloco de palavra para montar a frase (nível Fácil dos cartões e modo Montar das lições).
/// [vazia] = já está na frase: sobra só o buraco no banco.
class Pastilha extends StatelessWidget {
  static const _verde = Color(0xFF4CD08A);

  final String texto;
  final VoidCallback? onTap;
  final bool vazia;
  final MarcaPastilha marca;
  const Pastilha({super.key, required this.texto, this.onTap, this.vazia = false, this.marca = MarcaPastilha.nenhuma});

  @override
  Widget build(BuildContext context) {
    final cor = switch (marca) {
      MarcaPastilha.certa => _verde,
      MarcaPastilha.errada => Mixart.danger,
      MarcaPastilha.nenhuma => null,
    };
    return Material(
      color: cor != null ? cor.withValues(alpha: .14) : (vazia ? Mixart.surface : Mixart.surfaceHi),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cor ?? (vazia ? Mixart.border.withValues(alpha: .5) : Mixart.border), width: 1.4),
      ),
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(texto, style: Mixart.ui(size: 17, weight: FontWeight.w700, color: vazia ? Colors.transparent : Mixart.text)),
        ),
      ),
    );
  }
}
