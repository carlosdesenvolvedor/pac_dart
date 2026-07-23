import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../dartpad/mapa_rodavel.dart';
import '../domain/curriculo.dart';

/// Lê o currículo (assets/curriculo.json), os apps do Teste Master
/// (assets/master.json) e o mapa do que roda no DartPad (assets/roda.json).
class CurriculoLoader {
  Future<List<Trilha>> carregar() async {
    final raw = await rootBundle.loadString('assets/curriculo.json');
    final lista = jsonDecode(raw) as List;
    return lista.map((e) => Trilha.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Sem o asset (ou com ele quebrado) ninguém roda — o botão só some.
  Future<MapaRodavel> carregarRodaveis() async {
    try {
      final raw = await rootBundle.loadString('assets/roda.json');
      return MapaRodavel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return MapaRodavel.vazio;
    }
  }

  Future<List<Projeto>> carregarMaster() async {
    try {
      final raw = await rootBundle.loadString('assets/master.json');
      final lista = jsonDecode(raw) as List;
      return lista.map((e) => Projeto.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }
}
