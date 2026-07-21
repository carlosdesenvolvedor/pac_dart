import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens Mixart (Brandguide V1.0 · CADMO 2026).
abstract final class Mixart {
  static const bg = Color(0xFF010101);
  static const surface = Color(0xFF0F0F0F);
  static const surfaceHi = Color(0xFF1F1F1F);
  static const text = Color(0xFFF4F1EA);
  static const textMuted = Color(0xFF9CA3AF);
  static const textFaint = Color(0xFF6B7280);
  static const textHint = Color(0xFF4B5563);
  static const brand = Color(0xFFFFC73B);
  static const onBrand = Color(0xFF010101);
  static const brandSub = Color(0x14FFC73B); // amarelo 8%
  static const brandDim = Color(0x73FFC73B); // amarelo 45%
  static const border = Color(0xFF1F1F1F);
  static const danger = Color(0xFFF2555A);

  static const radiusLg = 18.0;
  static const radiusMd = 16.0;
  static const radiusChip = 24.0;

  static const spring = Cubic(.16, 1, .3, 1);
  static const slide = Cubic(.4, 0, .2, 1);

  /// Desligado nos testes (sem rede para baixar fontes).
  static bool usarGoogleFonts = true;

  static TextStyle display({double size = 24, FontWeight weight = FontWeight.w700, Color color = text}) =>
      usarGoogleFonts
          ? GoogleFonts.funnelDisplay(fontSize: size, fontWeight: weight, color: color, letterSpacing: -.5)
          : TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: -.5);

  static TextStyle ui({double size = 13, FontWeight weight = FontWeight.w500, Color color = text}) =>
      usarGoogleFonts
          ? GoogleFonts.archivo(fontSize: size, fontWeight: weight, color: color)
          : TextStyle(fontSize: size, fontWeight: weight, color: color);

  static TextStyle mono({double size = 13, FontWeight weight = FontWeight.w400, Color color = text}) =>
      usarGoogleFonts
          ? GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color)
          : TextStyle(fontSize: size, fontWeight: weight, color: color, fontFamily: 'monospace');

  static ThemeData tema() => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: brand,
          onPrimary: onBrand,
          surface: surface,
          onSurface: text,
          error: danger,
        ),
        textTheme: usarGoogleFonts
            ? GoogleFonts.archivoTextTheme(ThemeData.dark().textTheme)
            : ThemeData.dark().textTheme,
        splashFactory: InkSparkle.splashFactory,
      );
}

/// Cores do destaque de sintaxe (monocromático + amarelo).
abstract final class SyntaxColors {
  static const kw = Mixart.brand;
  static const ident = Mixart.text;
  static const literal = Color(0xFFB9BFC9); // strings e números
  static const punct = Color(0xFFAEB4BE); // pontuação legível, mais clara
  static const comment = Mixart.textFaint;
}
