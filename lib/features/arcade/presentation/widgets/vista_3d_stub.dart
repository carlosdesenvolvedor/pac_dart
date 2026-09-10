import 'package:flutter/material.dart';

import '../../domain/turismo.dart';
import 'pista_gt.dart';
import 'vista_3d_controlador.dart';

/// Fora da web não há WebGL/Three.js: a vista em Canvas assume.
class Vista3D extends StatelessWidget {
  final TurismoEngine engine;
  final double relogio;
  final String carro;
  final List<String> trafego;
  final bool som;
  final bool pausado;
  final String camera;
  final bool musica;
  final String qualidade;
  final bool tremor;
  final VoltaFantasma? fantasma;
  final VoidCallback? onPronto;
  final Vista3DControlador? controlador;
  const Vista3D({
    super.key,
    required this.engine,
    required this.relogio,
    this.carro = 'porsche_930',
    this.trafego = const [],
    this.som = true,
    this.pausado = false,
    this.camera = 'perseguicao',
    this.musica = true,
    this.qualidade = 'auto',
    this.tremor = true,
    this.fantasma,
    this.onPronto,
    this.controlador,
  });

  static bool get disponivel => false;

  @override
  Widget build(BuildContext context) => VistaCorrida(engine: engine, relogio: relogio);
}
