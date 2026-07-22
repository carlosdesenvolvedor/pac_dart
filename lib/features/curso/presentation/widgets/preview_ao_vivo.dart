import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../../preview/interpreter/parser.dart';
import '../../../preview/interpreter/widget_builder.dart';
import '../bloc/typing_bloc.dart';

/// Prévia AO VIVO: conforme a pessoa digita, o app vai sendo montado.
/// Não compila nada — pega o código digitado até o cursor, fecha os
/// parênteses/colchetes/aspas que faltam e renderiza com o interpretador.
/// Assim o que aparece condiz com onde a pessoa está no código.
class PreviewAoVivo extends StatefulWidget {
  final String cod;
  final double largura;
  final double altura;

  const PreviewAoVivo({super.key, required this.cod, this.largura = 230, this.altura = 320});

  @override
  State<PreviewAoVivo> createState() => _PreviewAoVivoState();
}

class _PreviewAoVivoState extends State<PreviewAoVivo> {
  static const _builder = WidgetBuilderPreview();
  late final int _raiz = _acharRaiz(widget.cod);
  Widget _ultimoBom = const SizedBox.shrink();

  int _acharRaiz(String cod) {
    for (final m in RegExp(r'\b([A-Z][A-Za-z]+)(?:\.\w+)?\s*\(').allMatches(cod)) {
      if (widgetsVivos.contains(m.group(1))) return m.start;
    }
    return 0;
  }

  /// Fecha strings e brackets abertos para tornar o prefixo parseável.
  String _balancear(String s) {
    final pilha = <String>[];
    String? aspas;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      buf.write(c);
      if (aspas != null) {
        if (c == r'\' && i + 1 < s.length) {
          buf.write(s[++i]);
          continue;
        }
        if (c == aspas) aspas = null;
      } else {
        if (c == "'" || c == '"') {
          aspas = c;
        } else if (c == '(') {
          pilha.add(')');
        } else if (c == '[') {
          pilha.add(']');
        } else if (c == '{') {
          pilha.add('}');
        } else if (c == ')' || c == ']' || c == '}') {
          if (pilha.isNotEmpty) pilha.removeLast();
        }
      }
    }
    if (aspas != null) buf.write(aspas);
    for (var k = pilha.length - 1; k >= 0; k--) {
      buf.write(pilha[k]);
    }
    return buf.toString();
  }

  Widget _render(String parcial) {
    var s = parcial.trimRight();
    if (s.isEmpty) return _ultimoBom;
    // tenta o prefixo inteiro; se não parsear, apara o trecho incompleto do
    // fim (até o último separador) e tenta de novo — renderiza o maior pedaço
    // válido, sem nunca ficar em branco.
    for (var t = 0; t < 8 && s.isNotEmpty; t++) {
      try {
        final w = _builder.construir(parseWidget(_balancear(s), 0));
        _ultimoBom = w;
        return w;
      } catch (_) {
        final cortado = s
            .replaceFirst(RegExp(r'[^,\(\[\{]*$'), '') // tira o token incompleto
            .replaceFirst(RegExp(r'[,\s]+$'), ''); // e a vírgula/espaço final
        if (cortado.length >= s.length) break;
        s = cortado;
      }
    }
    return _ultimoBom;
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF3FB950), shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text('PRÉVIA AO VIVO',
            style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.textMuted).copyWith(letterSpacing: 1.4)),
      ]),
      const SizedBox(height: 8),
      Container(
        width: widget.largura,
        height: widget.altura,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1B1B1B), width: 6),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 14), spreadRadius: -10)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Theme(
            data: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
              useMaterial3: true,
            ),
            child: Material(
              color: const Color(0xFFFAFAFA),
              child: BlocBuilder<TypingBloc, TypingState>(
                buildWhen: (a, b) => a.idx != b.idx || a.chars != b.chars,
                builder: (context, st) {
                  final ate = st.idx.clamp(0, widget.cod.length);
                  final parcial = ate > _raiz ? widget.cod.substring(_raiz, ate) : '';
                  final w = parcial.trim().isEmpty ? _placeholder() : _render(parcial);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: DefaultTextStyle(
                        style: const TextStyle(color: Color(0xFF212121), fontSize: 13),
                        child: w,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _placeholder() => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.play_circle_outline, size: 30, color: Color(0xFFBBBBBB)),
          const SizedBox(height: 8),
          Text('O app aparece aqui\nconforme você digita',
              textAlign: TextAlign.center,
              style: Mixart.ui(size: 11.5, color: const Color(0xFF9AA0A6))),
        ]),
      );
}
