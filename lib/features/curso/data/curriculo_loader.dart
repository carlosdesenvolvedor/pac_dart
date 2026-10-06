import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/linguagem/linguagem.dart';
import '../../dartpad/mapa_rodavel.dart';
import '../domain/curriculo.dart';

/// Lê o currículo da [linguagem] (assets/curriculo.json no Dart,
/// assets/csharp/curriculo.json no C#), os apps/programas do Teste Master
/// e o mapa do que roda no DartPad (só Dart: assets/roda.json).
class CurriculoLoader {
  final Linguagem linguagem;

  CurriculoLoader({this.linguagem = Linguagem.dart});

  Future<List<Trilha>> carregar() async {
    final raw = await rootBundle.loadString(linguagem.curriculo);
    final lista = jsonDecode(raw) as List;
    return lista.map((e) => Trilha.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Sem o asset (ou com ele quebrado) ninguém roda — o botão só some.
  Future<MapaRodavel> carregarRodaveis() async {
    final arq = linguagem.rodaveis;
    if (arq == null) return MapaRodavel.vazio;
    try {
      final raw = await rootBundle.loadString(arq);
      return MapaRodavel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return MapaRodavel.vazio;
    }
  }

  Future<List<Projeto>> carregarMaster() async {
    try {
      final raw = await rootBundle.loadString(linguagem.master);
      final lista = jsonDecode(raw) as List;
      return lista.map((e) => Projeto.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }
}
