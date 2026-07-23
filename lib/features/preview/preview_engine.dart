import 'package:flutter/material.dart';

import 'demos/demos.dart';
import 'interpreter/parser.dart';
import 'interpreter/visibilidade.dart';
import 'interpreter/widget_builder.dart';

enum PreviewModo {
  vivo, // o próprio código digitado virou widget
  demo, // demo pré-construída, Flutter real acontecendo
  conceito, // cartão explicativo
}

class PreviewResultado {
  final PreviewModo modo;
  final Widget widget;
  const PreviewResultado({required this.modo, required this.widget});

  bool get aoVivo => modo != PreviewModo.conceito;
}

/// Lê o texto do exercício e devolve uma prévia: widget real (ao vivo)
/// ou um cartão de conceito quando o trecho não tem saída visual.
class PreviewEngine {
  static const _builder = WidgetBuilderPreview();

  static PreviewResultado gerar(String cod, String dicaPlana) {
    // tenta cada construtor conhecido que aparece no código, na ordem
    // (aceita construtores nomeados: ListView.builder, GridView.count…)
    for (final m in RegExp(r'\b([A-Z][A-Za-z]+)(?:\.\w+)?\s*\(').allMatches(cod)) {
      final nome = m.group(1)!;
      if (!widgetsVivos.contains(nome)) continue;
      if (nome == 'InputDecoration') continue; // só faz sentido dentro de TextField
      // esses só existem DENTRO de Row/Column/Stack — como raiz, quebram;
      // pulamos e o laço acha o widget de dentro (Container, etc.)
      if (const {'Expanded', 'Flexible', 'Positioned', 'Spacer'}.contains(nome)) {
        continue;
      }
      try {
        final node = parseWidget(cod, m.start);
        // parseou mas não pintaria NADA (ex.: children: variavel)?
        // melhor uma demo/conceito bonita que uma tela em branco.
        if (!temFolhaVisivel(node)) continue;
        final w = _builder.construir(node);
        // toda prévia ao vivo "acontece": entrada com pop + flutuação contínua
        return PreviewResultado(modo: PreviewModo.vivo, widget: VidaPreview(child: w));
      } catch (_) {
        // tenta o próximo candidato
      }
    }
    // sem widget renderizável: procura uma demo real pré-construída
    final demo = demoPara(cod);
    if (demo != null) return PreviewResultado(modo: PreviewModo.demo, widget: demo);
    return PreviewResultado(modo: PreviewModo.conceito, widget: _cartaoConceito(cod, dicaPlana));
  }

  static Widget _cartaoConceito(String cod, String dica) {
    final titulo = _titulo(cod);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [for (final passo in _fluxo(cod)) ...[_no(passo), if (passo != _fluxo(cod).last) const Text('→', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.w700))]],
      ),
      const SizedBox(height: 10),
      Text(titulo, style: const TextStyle(color: Color(0xFF1565C0), fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(dica,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF607D8B), fontSize: 12.5, height: 1.45)),
    ]);
  }

  static Widget _no(String rotulo) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xFFECEFF1),
            border: Border.all(color: const Color(0xFFCFD8DC)),
            borderRadius: BorderRadius.circular(8)),
        child: Text(rotulo,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF37474F))),
      );

  static String _titulo(String cod) {
    final classe = RegExp(r'class\s+(\w+)').firstMatch(cod);
    if (cod.contains('StatefulWidget')) return 'StatefulWidget';
    if (cod.contains('StatelessWidget')) return 'StatelessWidget';
    if (cod.contains('setState')) return 'setState';
    if (cod.contains('Navigator')) return 'Navigator';
    if (cod.contains('initState') || cod.contains('dispose')) return 'Ciclo de vida';
    if (classe != null) return classe.group(1)!;
    final chamada = RegExp(r'\b([A-Z][A-Za-z]+)').firstMatch(cod);
    return chamada?.group(1) ?? 'Conceito';
  }

  static List<String> _fluxo(String cod) {
    if (cod.contains('StatefulWidget')) return const ['StatefulWidget', 'State', 'build()'];
    if (cod.contains('StatelessWidget')) return const ['StatelessWidget', 'build()'];
    if (cod.contains('setState')) return const ['evento', 'setState()', 'build()'];
    if (cod.contains('Navigator.push')) return const ['Tela 1', 'push', 'Tela 2'];
    if (cod.contains('Navigator.pop')) return const ['Tela 2', 'pop', 'Tela 1'];
    if (cod.contains('initState')) return const ['initState', 'build', 'dispose'];
    if (cod.contains('await') || cod.contains('Future')) return const ['chama', 'aguarda', 'resultado'];
    if (cod.contains('Stream')) return const ['emite', 'escuta', 'reage'];
    return const ['código', 'compila', 'roda'];
  }
}

/// Dá vida a qualquer prévia: entra com "pop" (fade + escala com mola)
/// e depois flutua suavemente em loop — nada fica parado na tela.
class VidaPreview extends StatefulWidget {
  final Widget child;
  const VidaPreview({super.key, required this.child});

  @override
  State<VidaPreview> createState() => _VidaPreviewState();
}

class _VidaPreviewState extends State<VidaPreview> with TickerProviderStateMixin {
  late final _entrada = AnimationController(vsync: this, duration: const Duration(milliseconds: 550))
    ..forward();
  late final _flutua = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _entrada.dispose();
    _flutua.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mola = CurvedAnimation(parent: _entrada, curve: const Cubic(.16, 1, .3, 1));
    return AnimatedBuilder(
      animation: _flutua,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_flutua.value);
        return Transform.translate(offset: Offset(0, 3 - 6 * t), child: child);
      },
      child: FadeTransition(
        opacity: mola,
        child: ScaleTransition(
          scale: Tween(begin: .8, end: 1.0).animate(mola),
          child: widget.child,
        ),
      ),
    );
  }
}
