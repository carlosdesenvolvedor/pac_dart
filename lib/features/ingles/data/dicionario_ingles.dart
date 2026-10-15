import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/dicionario.dart';

/// O dicionário embutido (assets/ingles/dicionario.json: as ~3 mil palavras do curso → o pé da letra em
/// português). Carregado uma vez, no primeiro toque numa palavra; sem o arquivo, fica vazio (o balão
/// mostra só o sentido da IA).
abstract final class DicionarioIngles {
  static const arquivo = 'assets/ingles/dicionario.json';

  static Dicionario? _pronto;
  static Future<Dicionario>? _carregando;

  /// Já carregado (o balão abre com o pé da letra sem esperar um frame).
  static Dicionario? get pronto => _pronto;

  static Future<Dicionario> carregar({AssetBundle? bundle}) => _carregando ??= _carregar(bundle ?? rootBundle);

  static Future<Dicionario> _carregar(AssetBundle bundle) async {
    try {
      return _pronto = Dicionario.fromJson(jsonDecode(await bundle.loadString(arquivo)));
    } catch (_) {
      return _pronto = Dicionario.vazio;
    }
  }

  /// Testes: troca o dicionário (null = volta a ler o arquivo).
  static void usarParaTestes(Dicionario? d) {
    _pronto = d;
    _carregando = d == null ? null : Future.value(d);
  }
}
