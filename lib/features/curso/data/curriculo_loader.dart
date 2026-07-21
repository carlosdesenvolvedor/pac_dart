import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/curriculo.dart';

/// Lê o currículo completo de assets/curriculo.json.
class CurriculoLoader {
  Future<List<Trilha>> carregar() async {
    final raw = await rootBundle.loadString('assets/curriculo.json');
    final lista = jsonDecode(raw) as List;
    return lista.map((e) => Trilha.fromJson(e as Map<String, dynamic>)).toList();
  }
}
