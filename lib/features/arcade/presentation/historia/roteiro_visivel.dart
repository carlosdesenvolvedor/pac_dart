import 'package:flutter/foundation.dart';

import '../../domain/historia_turismo.dart';
import '../../domain/simulacao_historia.dart';
import 'roteiro_historia.dart' show EstadoRoteiro;

/// O que o [PalcoHistoria] lê de um roteiro, a cada quadro. O Turismo usa o [RoteiroHistoria] (que anda
/// sozinho e fala); o 📺 Assistir usa o `RoteiroSeguidor` (segue o Ouvir, sem voz própria).
abstract interface class RoteiroVisivel implements Listenable {
  EstadoRoteiro get estadoVisivel;
  FalaHistoria? get falaAtual;
  FalaHistoria? get falaAnterior;
  EstadoCena get antes;
  EstadoCena get depois;
  int get cena;
  int get passo;
  double get tPasso;
  double? get tFala;
  double? get tSaida;
  int get letrasVisiveis;
  bool get mostrarPt;
  bool get noTitulo;
  double get duracaoTituloAtual;

  /// A boca segue só a voz do app (fora de `falando`, fecha). Turismo: `vozLigada && voz != null`.
  bool get falaComVoz;

  /// "Português → inglês": o EN do balão vira "…" (Turismo: false).
  bool get esconderEn;

  /// Emoji da frase no chip do balão (Turismo: null).
  String? get iconeDaFala;

  /// Véu preto 0..1 por cima do palco. Turismo: a fórmula de hoje do `_escurecimento()` do palco,
  /// movida sem mudança (cena 0 passo 0: .55 durante o título e depois some em .45 s; passo 0 das
  /// cenas seguintes: 1 − t/.45). Seguidor: só depois de um corte de verdade (troca de lição, de cena
  /// ou abertura no vão); 0 numa reancoragem da mesma âncora. O seguidor tem noTitulo = false e
  /// duracaoTituloAtual = 0.
  double get escurecimento;
}

/// O cabeçalho do palco (cartão de título e Semantics). Turismo: [CabecalhoPalco.doCapitulo].
class CabecalhoPalco {
  /// 'CHAPTER 7' | '🎬 A1 · Primeiro contato'.
  final String sobretitulo;
  final TextoBilingue titulo;

  /// Turismo: 'Desenho animado: Chapter 7, titulo.en' (idêntico ao de hoje).
  final String rotuloSemantico;

  /// `PropPainter(capitulo:)`; 0 = pintura padrão.
  final int pinturaCarro;

  const CabecalhoPalco({
    required this.sobretitulo,
    required this.titulo,
    required this.rotuloSemantico,
    this.pinturaCarro = 0,
  });

  factory CabecalhoPalco.doCapitulo(CapituloHistoria c) => CabecalhoPalco(
        sobretitulo: 'CHAPTER ${c.pista}',
        titulo: c.titulo,
        rotuloSemantico: 'Desenho animado: Chapter ${c.pista}, ${c.titulo.en}',
        pinturaCarro: c.pista,
      );
}
