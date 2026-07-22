import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/curriculo.dart';

/// Lê o currículo (assets/curriculo.json) e os apps do Teste Master
/// (assets/master.json).
class CurriculoLoader {
  Future<List<Trilha>> carregar() async {
    final raw = await rootBundle.loadString('assets/curriculo.json');
    final lista = jsonDecode(raw) as List;
    return lista.map((e) => Trilha.fromJson(e as Map<String, dynamic>)).toList();
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
