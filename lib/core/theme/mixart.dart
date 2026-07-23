import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Uma paleta completa do app. Os tokens são os mesmos; só os valores mudam.
class Paleta {
  final String nome;
  final String emoji;
  final Brightness brilho;

  final Color bg, surface, surfaceHi;
  final Color text, textMuted, textFaint, textHint;
  final Color brand, onBrand, brandSub, brandDim;
  final Color border, danger;

  // destaque de sintaxe (adapta ao fundo claro/escuro)
  final Color synKw, synIdent, synLiteral, synPunct, synComment;

  const Paleta({
    required this.nome,
    required this.emoji,
    required this.brilho,
    required this.bg,
    required this.surface,
    required this.surfaceHi,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.textHint,
    required this.brand,
    required this.onBrand,
    required this.brandSub,
    required this.brandDim,
    required this.border,
    required this.danger,
    required this.synKw,
    required this.synIdent,
    required this.synLiteral,
    required this.synPunct,
    required this.synComment,
  });

  bool get ehClaro => brilho == Brightness.light;

  /// Paleta Mixart — escura, monocromática com acento amarelo (Brandguide CADMO).
  static const mixart = Paleta(
    nome: 'Mixart',
    emoji: '🟡',
    brilho: Brightness.dark,
    bg: Color(0xFF010101),
    surface: Color(0xFF0F0F0F),
    surfaceHi: Color(0xFF1F1F1F),
    text: Color(0xFFF4F1EA),
    textMuted: Color(0xFF9CA3AF),
    textFaint: Color(0xFF6B7280),
    textHint: Color(0xFF4B5563),
    brand: Color(0xFFFFC73B),
    onBrand: Color(0xFF010101),
    brandSub: Color(0x14FFC73B),
    brandDim: Color(0x73FFC73B),
    border: Color(0xFF1F1F1F),
    danger: Color(0xFFF2555A),
    synKw: Color(0xFFFFC73B),
    synIdent: Color(0xFFF4F1EA),
    synLiteral: Color(0xFFB9BFC9),
    synPunct: Color(0xFFAEB4BE),
    synComment: Color(0xFF6B7280),
  );

  /// Paleta Flutter — clara (cores oficiais de docs.flutter.dev).
  static const flutterClaro = Paleta(
    nome: 'Flutter claro',
    emoji: '🔵',
    brilho: Brightness.light,
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF6F7F8),
    surfaceHi: Color(0xFFE9ECEF),
    text: Color(0xFF212121),
    textMuted: Color(0xFF5F6368),
    textFaint: Color(0xFF80868B),
    textHint: Color(0xFFA0A4A8),
    brand: Color(0xFF0468D7),
    onBrand: Color(0xFFFFFFFF),
    brandSub: Color(0x140468D7),
    brandDim: Color(0x520468D7),
    border: Color(0xFFE3E5EA),
    danger: Color(0xFFCD3434),
    synKw: Color(0xFF0468D7),
    synIdent: Color(0xFF212121),
    synLiteral: Color(0xFF5F6368),
    synPunct: Color(0xFF80868B),
    synComment: Color(0xFFA0A4A8),
  );

  /// Paleta Flutter — escura (cores oficiais de docs.flutter.dev).
  static const flutterEscuro = Paleta(
    nome: 'Flutter escuro',
    emoji: '🌙',
    brilho: Brightness.dark,
    bg: Color(0xFF121317),
    surface: Color(0xFF1C1E27),
    surfaceHi: Color(0xFF202731),
    text: Color(0xFFDCDCDC),
    textMuted: Color(0xFFA8ACAD),
    textFaint: Color(0xFF8A8F91),
    textHint: Color(0xFF6A6F71),
    brand: Color(0xFF4AA3F0),
    onBrand: Color(0xFF08111C),
    brandSub: Color(0x1F4AA3F0),
    brandDim: Color(0x664AA3F0),
    border: Color(0xFF2A2D3A),
    danger: Color(0xFFFF5D5D),
    synKw: Color(0xFF4AA3F0),
    synIdent: Color(0xFFDCDCDC),
    synLiteral: Color(0xFFAFB4BC),
    synPunct: Color(0xFF9297A0),
    synComment: Color(0xFF6A6F71),
  );

  static const todas = [mixart, flutterClaro, flutterEscuro];
}

/// Fachada dos tokens de estilo. As cores delegam para [Mixart.atual], que
/// muda em runtime (troca de tema). Por serem getters, não podem ser usadas
/// em contextos `const`.
abstract final class Mixart {
  /// Paleta ativa. Trocada pelo ThemeCubit; a UI é reconstruída em seguida.
  static Paleta atual = Paleta.mixart;

  static Color get bg => atual.bg;
  static Color get surface => atual.surface;
  static Color get surfaceHi => atual.surfaceHi;
  static Color get text => atual.text;
  static Color get textMuted => atual.textMuted;
  static Color get textFaint => atual.textFaint;
  static Color get textHint => atual.textHint;
  static Color get brand => atual.brand;
  static Color get onBrand => atual.onBrand;
  static Color get brandSub => atual.brandSub;
  static Color get brandDim => atual.brandDim;
  static Color get border => atual.border;
  static Color get danger => atual.danger;

  static const radiusLg = 18.0;
  static const radiusMd = 16.0;
  static const radiusChip = 24.0;

  static const spring = Cubic(.16, 1, .3, 1);
  static const slide = Cubic(.4, 0, .2, 1);

  /// Desligado nos testes (sem rede para baixar fontes).
  static bool usarGoogleFonts = true;

  static TextStyle display({double size = 24, FontWeight weight = FontWeight.w700, Color? color}) {
    final c = color ?? atual.text;
    return usarGoogleFonts
        ? GoogleFonts.funnelDisplay(fontSize: size, fontWeight: weight, color: c, letterSpacing: -.5)
        : TextStyle(fontSize: size, fontWeight: weight, color: c, letterSpacing: -.5);
  }

  static TextStyle ui({double size = 13, FontWeight weight = FontWeight.w500, Color? color}) {
    final c = color ?? atual.text;
    return usarGoogleFonts
        ? GoogleFonts.archivo(fontSize: size, fontWeight: weight, color: c)
        : TextStyle(fontSize: size, fontWeight: weight, color: c);
  }

  /// SEM ligaduras tipográficas: num treinador de digitação, "->" precisa
  /// PARECER '-' e '>' (a JetBrains Mono fundia em → e != virava ≠,
  /// escondendo do jogador o que teclar).
  static const _semLigaduras = [
    FontFeature.disable('liga'),
    FontFeature.disable('calt'),
    FontFeature.disable('clig'),
    FontFeature.disable('dlig'),
  ];

  static TextStyle mono({double size = 13, FontWeight weight = FontWeight.w400, Color? color}) {
    final c = color ?? atual.text;
    return usarGoogleFonts
        ? GoogleFonts.jetBrainsMono(
            fontSize: size, fontWeight: weight, color: c, fontFeatures: _semLigaduras)
        : TextStyle(
            fontSize: size,
            fontWeight: weight,
            color: c,
            fontFamily: 'monospace',
            fontFeatures: _semLigaduras);
  }

  static ThemeData tema() {
    final base = ThemeData(brightness: atual.brilho);
    return ThemeData(
      brightness: atual.brilho,
      scaffoldBackgroundColor: atual.bg,
      colorScheme: ColorScheme(
        brightness: atual.brilho,
        primary: atual.brand,
        onPrimary: atual.onBrand,
        secondary: atual.brand,
        onSecondary: atual.onBrand,
        surface: atual.surface,
        onSurface: atual.text,
        error: atual.danger,
        onError: atual.onBrand,
      ),
      textTheme: usarGoogleFonts ? GoogleFonts.archivoTextTheme(base.textTheme) : base.textTheme,
      splashFactory: InkSparkle.splashFactory,
    );
  }
}

/// Cores do destaque de sintaxe — delegam para a paleta ativa.
abstract final class SyntaxColors {
  static Color get kw => Mixart.atual.synKw;
  static Color get ident => Mixart.atual.synIdent;
  static Color get literal => Mixart.atual.synLiteral;
  static Color get punct => Mixart.atual.synPunct;
  static Color get comment => Mixart.atual.synComment;
}
