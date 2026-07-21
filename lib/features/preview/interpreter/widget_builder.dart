import 'package:flutter/cupertino.dart' show CupertinoButton, CupertinoSwitch;
import 'package:flutter/material.dart';

import 'parser.dart';

/// Widgets que sabemos renderizar "ao vivo". A ordem não importa;
/// serve para achar o widget-raiz dentro do texto do exercício.
const widgetsVivos = {
  'MaterialApp', 'Scaffold', 'AppBar', 'Center', 'Container', 'Text', 'Icon',
  'Column', 'Row', 'Stack', 'Positioned', 'Align', 'Padding', 'SizedBox',
  'Expanded', 'Flexible', 'Spacer', 'Wrap', 'Card', 'ListTile', 'Divider',
  'CircleAvatar', 'Chip', 'ElevatedButton', 'TextButton', 'OutlinedButton',
  'IconButton', 'FloatingActionButton', 'Switch', 'Checkbox', 'Radio',
  'Slider', 'TextField', 'TextFormField', 'CircularProgressIndicator',
  'LinearProgressIndicator', 'ListView', 'GridView', 'SingleChildScrollView',
  'Opacity', 'ClipRRect', 'AspectRatio', 'FittedBox', 'FractionallySizedBox',
  'AnimatedContainer', 'AnimatedOpacity', 'GestureDetector', 'InkWell',
  'Tooltip', 'Badge', 'Hero', 'SafeArea', 'DropdownButton', 'AlertDialog',
  'SnackBar', 'Drawer', 'BottomNavigationBar', 'TabBar', 'Visibility',
  'RefreshIndicator', 'Scrollbar', 'CupertinoButton', 'CupertinoSwitch',
  'Dismissible', 'Draggable', 'AnimatedSwitcher', 'InputDecoration',
};

const _cores = <String, Color>{
  'red': Colors.red, 'blue': Colors.blue, 'green': Colors.green,
  'amber': Colors.amber, 'yellow': Colors.yellow, 'orange': Colors.orange,
  'purple': Colors.purple, 'pink': Colors.pink, 'teal': Colors.teal,
  'grey': Colors.grey, 'black': Colors.black, 'white': Colors.white,
  'indigo': Colors.indigo, 'cyan': Colors.cyan, 'brown': Colors.brown,
  'lime': Colors.lime, 'deepOrange': Colors.deepOrange,
  'lightBlue': Colors.lightBlue, 'blueGrey': Colors.blueGrey,
};

const _icones = <String, IconData>{
  'add': Icons.add, 'arrow_forward': Icons.arrow_forward, 'close': Icons.close,
  'favorite': Icons.favorite, 'home': Icons.home, 'info': Icons.info,
  'person': Icons.person, 'search': Icons.search, 'send': Icons.send,
  'star': Icons.star, 'image': Icons.image, 'settings': Icons.settings,
  'mail': Icons.mail, 'menu': Icons.menu, 'delete': Icons.delete,
  'edit': Icons.edit, 'check': Icons.check, 'share': Icons.share,
  'shopping_cart': Icons.shopping_cart, 'camera': Icons.camera_alt,
};

/// Constrói widgets Flutter de verdade a partir da árvore parseada.
class WidgetBuilderPreview {
  const WidgetBuilderPreview();

  Widget construir(Node node, [Map<String, Object?> ctx = const {}]) {
    switch (node.t) {
      case 'str':
        return Text(_interp(node.s, ctx));
      case 'list':
        return Column(
            mainAxisSize: MainAxisSize.min,
            children: node.pos.map((n) => construir(n, ctx)).toList());
      case 'call':
        return _widget(node, ctx);
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------- helpers de valores ----------
  String _interp(String s, Map<String, Object?> ctx) {
    var r = s.replaceAllMapped(RegExp(r'\$\{([^}]*)\}'), (m) {
      final e = m[1]!.trim();
      return (ctx[e] ?? e).toString();
    });
    r = r.replaceAllMapped(RegExp(r'\$(\w+)'), (m) => (ctx[m[1]] ?? m[1]!).toString());
    return r;
  }

  double? _num(Node? n) => n == null
      ? null
      : n.t == 'num'
          ? n.n
          : n.t == 'call' && n.name == 'Duration'
              ? null
              : null;

  String? _str(Node? n, Map<String, Object?> ctx) => n != null && n.t == 'str' ? _interp(n.s, ctx) : null;

  bool _bool(Node? n, {bool padrao = false}) => n != null && n.t == 'bool' ? n.b : padrao;

  Color? _cor(Node? n) {
    if (n == null) return null;
    if (n.t == 'ident' && n.name.startsWith('Colors.')) {
      return _cores[n.name.split('.')[1]];
    }
    if (n.t == 'call' && n.base == 'Color' && n.pos.isNotEmpty && n.pos.first.t == 'num') {
      return Color(n.pos.first.n.toInt());
    }
    if (n.t == 'call' && n.name.startsWith('Colors.')) {
      // Colors.red.withOpacity(...) etc — usa a cor base
      return _cores[n.name.split('.')[1]];
    }
    return null;
  }

  IconData? _icone(Node? n) =>
      n != null && n.t == 'ident' && n.name.startsWith('Icons.') ? _icones[n.name.split('.')[1]] ?? Icons.circle : null;

  EdgeInsets? _edge(Node? n) {
    if (n == null || n.t != 'call') return null;
    final v = n.pos.isNotEmpty && n.pos.first.t == 'num' ? n.pos.first.n : 8.0;
    return switch (n.name) {
      'EdgeInsets.all' => EdgeInsets.all(v),
      'EdgeInsets.symmetric' => EdgeInsets.symmetric(
          horizontal: _num(n.named['horizontal']) ?? 0, vertical: _num(n.named['vertical']) ?? 0),
      'EdgeInsets.only' => EdgeInsets.only(
          left: _num(n.named['left']) ?? 0,
          top: _num(n.named['top']) ?? 0,
          right: _num(n.named['right']) ?? 0,
          bottom: _num(n.named['bottom']) ?? 0),
      _ => EdgeInsets.all(v),
    };
  }

  Alignment? _align(Node? n) {
    if (n == null || n.t != 'ident' || !n.name.startsWith('Alignment.')) return null;
    return switch (n.name.split('.')[1]) {
      'topLeft' => Alignment.topLeft,
      'topCenter' => Alignment.topCenter,
      'topRight' => Alignment.topRight,
      'centerLeft' => Alignment.centerLeft,
      'center' => Alignment.center,
      'centerRight' => Alignment.centerRight,
      'bottomLeft' => Alignment.bottomLeft,
      'bottomCenter' => Alignment.bottomCenter,
      'bottomRight' => Alignment.bottomRight,
      _ => Alignment.center,
    };
  }

  MainAxisAlignment _main(Node? n) {
    if (n == null || n.t != 'ident') return MainAxisAlignment.start;
    return switch (n.name.split('.').last) {
      'center' => MainAxisAlignment.center,
      'end' => MainAxisAlignment.end,
      'spaceBetween' => MainAxisAlignment.spaceBetween,
      'spaceAround' => MainAxisAlignment.spaceAround,
      'spaceEvenly' => MainAxisAlignment.spaceEvenly,
      _ => MainAxisAlignment.start,
    };
  }

  CrossAxisAlignment _cross(Node? n) {
    if (n == null || n.t != 'ident') return CrossAxisAlignment.center;
    return switch (n.name.split('.').last) {
      'start' => CrossAxisAlignment.start,
      'end' => CrossAxisAlignment.end,
      'stretch' => CrossAxisAlignment.stretch,
      _ => CrossAxisAlignment.center,
    };
  }

  FontWeight? _peso(Node? n) {
    if (n == null || n.t != 'ident') return null;
    return switch (n.name.split('.').last) {
      'bold' => FontWeight.bold,
      'w900' => FontWeight.w900,
      'w700' => FontWeight.w700,
      'w600' => FontWeight.w600,
      'w500' => FontWeight.w500,
      'w300' => FontWeight.w300,
      'w100' => FontWeight.w100,
      _ => null,
    };
  }

  TextStyle? _estilo(Node? n) {
    if (n == null || n.t != 'call' || n.base != 'TextStyle') return null;
    return TextStyle(
      fontSize: _num(n.named['fontSize']),
      color: _cor(n.named['color']),
      fontWeight: _peso(n.named['fontWeight']),
      fontStyle: n.named['fontStyle']?.name.endsWith('italic') == true ? FontStyle.italic : null,
      letterSpacing: _num(n.named['letterSpacing']),
      decoration: n.named['decoration']?.name.endsWith('underline') == true ? TextDecoration.underline : null,
    );
  }

  BoxDecoration? _decor(Node? n) {
    if (n == null || n.t != 'call' || n.base != 'BoxDecoration') return null;
    final br = n.named['borderRadius'];
    return BoxDecoration(
      color: _cor(n.named['color']),
      shape: n.named['shape']?.name.endsWith('circle') == true ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: br != null && br.t == 'call' && br.pos.isNotEmpty && br.pos.first.t == 'num'
          ? BorderRadius.circular(br.pos.first.n)
          : null,
      boxShadow: n.named['boxShadow'] != null
          ? [const BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))]
          : null,
      border: n.named['border'] != null ? Border.all(color: Colors.black26, width: 2) : null,
    );
  }

  Widget? _filho(Node n, Map<String, Object?> ctx) =>
      n.named['child'] != null ? construir(n.named['child']!, ctx) : null;

  List<Widget> _filhos(Node n, Map<String, Object?> ctx) {
    final c = n.named['children'];
    if (c == null || c.t != 'list') return const [];
    return c.pos.map((x) => construir(x, ctx)).toList();
  }

  // ---------- o mapa de widgets ----------
  Widget _widget(Node n, Map<String, Object?> ctx) {
    switch (n.base) {
      case 'MaterialApp':
      case 'CupertinoApp':
        final home = n.named['home'];
        return home != null ? construir(home, ctx) : (_filho(n, ctx) ?? const SizedBox.shrink());
      case 'Scaffold':
        return Column(mainAxisSize: MainAxisSize.min, children: [
          if (n.named['appBar'] != null) construir(n.named['appBar']!, ctx),
          if (n.named['body'] != null)
            Padding(padding: const EdgeInsets.all(12), child: construir(n.named['body']!, ctx)),
          if (n.named['floatingActionButton'] != null)
            Align(
                alignment: Alignment.centerRight,
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: construir(n.named['floatingActionButton']!, ctx))),
          if (n.named['bottomNavigationBar'] != null) construir(n.named['bottomNavigationBar']!, ctx),
        ]);
      case 'AppBar':
        return _EntradaAnimada(
          desce: true,
          child: Container(
            width: double.infinity,
            color: _cor(n.named['backgroundColor']) ?? const Color(0xFF1565C0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              child: n.named['title'] != null ? construir(n.named['title']!, ctx) : const Text('App'),
            ),
          ),
        );
      case 'Center':
        return Center(child: _filho(n, ctx));
      case 'Container':
      case 'AnimatedContainer':
        final deco = _decor(n.named['decoration']);
        var cor = deco == null ? _cor(n.named['color']) : null;
        final temTamanho = n.named['width'] != null || n.named['height'] != null;
        // caixa sem cor ficaria invisível no fundo claro — dá uma cor de amostra
        if (cor == null && deco == null && temTamanho) cor = const Color(0xFF90CAF9);
        final base = Container(
          width: _num(n.named['width']),
          height: _num(n.named['height']),
          color: cor,
          decoration: deco,
          padding: _edge(n.named['padding']),
          margin: _edge(n.named['margin']),
          alignment: _align(n.named['alignment']),
          child: _filho(n, ctx),
        );
        return n.base == 'AnimatedContainer'
            ? _PulsoBox(
                cor: _cor(n.named['color']) ?? Colors.blue,
                w: _num(n.named['width']) ?? 90,
                h: _num(n.named['height']) ?? 90,
                child: _filho(n, ctx))
            : base;
      case 'AnimatedOpacity':
      case 'Opacity':
        final filho = _filho(n, ctx) ?? const Icon(Icons.star, size: 40);
        return n.base == 'AnimatedOpacity'
            ? _FadeLoop(child: filho)
            : Opacity(opacity: _num(n.named['opacity']) ?? .5, child: filho);
      case 'Text':
        return Text(_str(n.pos.isNotEmpty ? n.pos.first : null, ctx) ?? '', style: _estilo(n.named['style']));
      case 'Icon':
        return Icon(_icone(n.pos.isNotEmpty ? n.pos.first : null) ?? Icons.circle,
            size: _num(n.named['size']) ?? 24, color: _cor(n.named['color']));
      case 'Column':
        return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: _main(n.named['mainAxisAlignment']),
            crossAxisAlignment: _cross(n.named['crossAxisAlignment']),
            children: _filhos(n, ctx));
      case 'Row':
        return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: _main(n.named['mainAxisAlignment']),
            crossAxisAlignment: _cross(n.named['crossAxisAlignment']),
            children: _filhos(n, ctx));
      case 'Wrap':
        return Wrap(spacing: _num(n.named['spacing']) ?? 6, runSpacing: _num(n.named['runSpacing']) ?? 6, children: _filhos(n, ctx));
      case 'Stack':
        return SizedBox(
            width: 140,
            height: 110,
            child: Stack(alignment: Alignment.center, children: _filhos(n, ctx)));
      case 'Positioned':
        return Positioned(
            left: _num(n.named['left']),
            top: _num(n.named['top']),
            right: _num(n.named['right']),
            bottom: _num(n.named['bottom']),
            child: _filho(n, ctx) ?? const SizedBox.shrink());
      case 'Align':
        return SizedBox(
            width: 140,
            height: 90,
            child: Align(alignment: _align(n.named['alignment']) ?? Alignment.center, child: _filho(n, ctx)));
      case 'Padding':
        return Padding(padding: _edge(n.named['padding']) ?? const EdgeInsets.all(8), child: _filho(n, ctx));
      case 'SizedBox':
        final filhoSb = _filho(n, ctx);
        final wSb = _num(n.named['width']), hSb = _num(n.named['height']);
        // sem filho seria invisível: mostra o contorno do espaço ocupado
        if (filhoSb == null && (wSb != null || hSb != null)) {
          return Container(
            width: wSb ?? 12,
            height: hSb ?? 12,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }
        return SizedBox(width: wSb, height: hSb, child: filhoSb);
      case 'Expanded':
      case 'Flexible':
        // fora de um Row/Column real da prévia, só devolve o filho
        return _filho(n, ctx) ?? const SizedBox.shrink();
      case 'Spacer':
        return const SizedBox(width: 16, height: 16);
      case 'Card':
        return Card(
            color: _cor(n.named['color']),
            elevation: _num(n.named['elevation']) ?? 2,
            child: Padding(padding: const EdgeInsets.all(12), child: _filho(n, ctx) ?? const SizedBox(width: 60, height: 30)));
      case 'ListTile':
        return ListTile(
            dense: true,
            leading: n.named['leading'] != null ? construir(n.named['leading']!, ctx) : null,
            title: n.named['title'] != null ? construir(n.named['title']!, ctx) : null,
            subtitle: n.named['subtitle'] != null ? construir(n.named['subtitle']!, ctx) : null,
            trailing: n.named['trailing'] != null ? construir(n.named['trailing']!, ctx) : null);
      case 'Divider':
        return const Divider();
      case 'CircleAvatar':
        return CircleAvatar(
            radius: _num(n.named['radius']) ?? 20,
            backgroundColor: _cor(n.named['backgroundColor']) ?? const Color(0xFF1565C0),
            child: _filho(n, ctx) ?? const Icon(Icons.person, color: Colors.white, size: 20));
      case 'Chip':
        return Chip(label: n.named['label'] != null ? construir(n.named['label']!, ctx) : const Text('Chip'));
      case 'ElevatedButton':
      case 'TextButton':
      case 'OutlinedButton':
      case 'CupertinoButton':
        final rotulo = _filho(n, ctx) ?? const Text('Botão');
        return switch (n.base) {
          'TextButton' => TextButton(onPressed: () {}, child: rotulo),
          'OutlinedButton' => OutlinedButton(onPressed: () {}, child: rotulo),
          'CupertinoButton' => CupertinoButton(color: const Color(0xFF1565C0), onPressed: () {}, child: rotulo),
          _ => ElevatedButton(onPressed: () {}, child: rotulo),
        };
      case 'IconButton':
        return IconButton(onPressed: () {}, icon: n.named['icon'] != null ? construir(n.named['icon']!, ctx) : const Icon(Icons.star));
      case 'FloatingActionButton':
        return FloatingActionButton(
            mini: true, onPressed: () {}, child: _filho(n, ctx) ?? const Icon(Icons.add));
      case 'Switch':
      case 'CupertinoSwitch':
        return _Interativo(
            builder: (v, muda) => n.base == 'CupertinoSwitch'
                ? CupertinoSwitch(value: v, onChanged: muda)
                : Switch(value: v, onChanged: muda),
            inicial: _bool(n.named['value'], padrao: true));
      case 'Checkbox':
        return _Interativo(
            builder: (v, muda) => Checkbox(value: v, onChanged: (x) => muda(x ?? false)),
            inicial: _bool(n.named['value'], padrao: true));
      case 'Radio':
        return _Interativo(
            builder: (v, muda) => RadioGroup<bool>(
                groupValue: v,
                onChanged: (x) => muda(x ?? false),
                child: const Radio<bool>(value: true, toggleable: true)),
            inicial: true);
      case 'Slider':
        return _SliderDemo(inicial: _num(n.named['value']) ?? .4);
      case 'TextField':
      case 'TextFormField':
        final deco = n.named['decoration'];
        return SizedBox(
            width: 180,
            child: TextField(
                decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    labelText: deco != null ? _str(deco.named['labelText'], ctx) : null,
                    hintText: deco != null ? _str(deco.named['hintText'], ctx) : 'Digite…')));
      case 'CircularProgressIndicator':
        return const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3));
      case 'LinearProgressIndicator':
        return SizedBox(width: 150, child: LinearProgressIndicator(value: _num(n.named['value'])));
      case 'ListView':
        return _lista(n, ctx);
      case 'GridView':
        return SizedBox(
            width: 190,
            child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(
                    4,
                    (i) => Container(
                        width: 88,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                        child: Text('$i', style: const TextStyle(color: Color(0xFF1565C0)))))));
      case 'SingleChildScrollView':
      case 'SafeArea':
      case 'Hero':
      case 'GestureDetector':
      case 'InkWell':
      case 'RefreshIndicator':
      case 'Scrollbar':
      case 'Visibility':
      case 'ClipRRect':
      case 'FittedBox':
      case 'Dismissible':
      case 'Draggable':
      case 'AnimatedSwitcher':
        final filho = _filho(n, ctx);
        if (n.base == 'ClipRRect' && filho != null) {
          return ClipRRect(borderRadius: BorderRadius.circular(14), child: filho);
        }
        if ((n.base == 'GestureDetector' || n.base == 'InkWell') && filho != null) {
          return InkWell(borderRadius: BorderRadius.circular(8), onTap: () {}, child: Padding(padding: const EdgeInsets.all(4), child: filho));
        }
        return filho ?? const SizedBox.shrink();
      case 'AspectRatio':
        return SizedBox(
            width: 140,
            child: AspectRatio(
                aspectRatio: _num(n.named['aspectRatio']) ?? 1.5,
                child: Container(color: const Color(0xFFE3F2FD), child: _filho(n, ctx))));
      case 'FractionallySizedBox':
        return SizedBox(width: 160, height: 40, child: FractionallySizedBox(widthFactor: _num(n.named['widthFactor']) ?? .5, child: Container(color: const Color(0xFF1565C0))));
      case 'Tooltip':
        return Tooltip(
            message: _str(n.named['message'], ctx) ?? 'Dica',
            triggerMode: TooltipTriggerMode.tap,
            child: _filho(n, ctx) ?? const Icon(Icons.info));
      case 'Badge':
        return Badge(
            label: n.named['label'] != null ? construir(n.named['label']!, ctx) : const Text('1'),
            child: _filho(n, ctx) ?? const Icon(Icons.mail));
      case 'DropdownButton':
        return DropdownButton<String>(
            value: 'A',
            items: const [
              DropdownMenuItem(value: 'A', child: Text('Opção A')),
              DropdownMenuItem(value: 'B', child: Text('Opção B')),
            ],
            onChanged: (_) {});
      case 'AlertDialog':
        return _EntradaAnimada(
            child: Container(
                width: 200,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16)]),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  DefaultTextStyle(
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                      child: n.named['title'] != null ? construir(n.named['title']!, ctx) : const Text('Alerta')),
                  const SizedBox(height: 6),
                  DefaultTextStyle(
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                      child: n.named['content'] != null ? construir(n.named['content']!, ctx) : const SizedBox.shrink()),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('OK'))),
                ])));
      case 'SnackBar':
        return Container(
            width: 210,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF323232), borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Expanded(
                  child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white, fontSize: 12.5),
                      child: n.named['content'] != null ? construir(n.named['content']!, ctx) : const Text('Aviso'))),
              if (n.named['action'] != null)
                Text(_str(n.named['action']!.named['label'], ctx) ?? 'AÇÃO',
                    style: const TextStyle(color: Color(0xFFFFC73B), fontSize: 12, fontWeight: FontWeight.w700)),
            ]));
      case 'Drawer':
        return _EntradaAnimada(
            desliza: true,
            child: Container(
                width: 150,
                height: 170,
                color: Colors.white,
                child: Column(children: [
                  Container(height: 54, color: const Color(0xFF1565C0)),
                  const ListTile(dense: true, leading: Icon(Icons.home, size: 18), title: Text('Início', style: TextStyle(fontSize: 13))),
                  const ListTile(dense: true, leading: Icon(Icons.settings, size: 18), title: Text('Ajustes', style: TextStyle(fontSize: 13))),
                ])));
      case 'BottomNavigationBar':
        return Container(
            width: 230,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
            child: const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Icon(Icons.home, color: Color(0xFF1565C0)),
              Icon(Icons.search, color: Colors.grey),
              Icon(Icons.person, color: Colors.grey),
            ]));
      case 'TabBar':
        return Container(
            width: 230,
            color: const Color(0xFF1565C0),
            child: const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Padding(padding: EdgeInsets.all(10), child: Text('ABA 1', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
              Padding(padding: EdgeInsets.all(10), child: Text('ABA 2', style: TextStyle(color: Colors.white54, fontSize: 12))),
            ]));
      default:
        // desconhecido: tenta o filho / filhos
        final f = _filho(n, ctx);
        if (f != null) return f;
        final fs = _filhos(n, ctx);
        if (fs.isNotEmpty) return Column(mainAxisSize: MainAxisSize.min, children: fs);
        throw ParseException();
    }
  }

  Widget _lista(Node n, Map<String, Object?> ctx) {
    // ListView.builder: gera 3 itens de amostra com o índice no contexto.
    if (n.name == 'ListView.builder') {
      final lam = n.named['itemBuilder'];
      final itens = <Widget>[];
      for (var i = 0; i < 3; i++) {
        if (lam != null && lam.t == 'lambda' && lam.corpo != null) {
          final nomeIdx = lam.params.length > 1 ? lam.params[1] : 'index';
          itens.add(construir(lam.corpo!, {...ctx, nomeIdx: i}));
        }
      }
      if (itens.isEmpty) {
        itens.addAll(List.generate(3, (i) => ListTile(dense: true, title: Text('Item $i'))));
      }
      return _ListaAnimada(itens: itens);
    }
    return _ListaAnimada(itens: _filhos(n, ctx));
  }
}

// ---------- widgets de apoio da prévia ----------

/// Estado local simples para switch/checkbox/radio interativos.
class _Interativo extends StatefulWidget {
  final Widget Function(bool, ValueChanged<bool>) builder;
  final bool inicial;
  const _Interativo({required this.builder, required this.inicial});
  @override
  State<_Interativo> createState() => _InterativoState();
}

class _InterativoState extends State<_Interativo> {
  late bool v = widget.inicial;
  @override
  Widget build(BuildContext context) => widget.builder(v, (x) => setState(() => v = x));
}

class _SliderDemo extends StatefulWidget {
  final double inicial;
  const _SliderDemo({required this.inicial});
  @override
  State<_SliderDemo> createState() => _SliderDemoState();
}

class _SliderDemoState extends State<_SliderDemo> {
  late double v = widget.inicial.clamp(0, 1);
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 170, child: Slider(value: v, onChanged: (x) => setState(() => v = x)));
}

/// AnimatedContainer da prévia: pulsa em loop enquanto aberta.
class _PulsoBox extends StatefulWidget {
  final Color cor;
  final double w, h;
  final Widget? child;
  const _PulsoBox({required this.cor, required this.w, required this.h, this.child});
  @override
  State<_PulsoBox> createState() => _PulsoBoxState();
}

class _PulsoBoxState extends State<_PulsoBox> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = Curves.easeInOut.transform(_c.value);
          return Container(
            width: widget.w + widget.w * .7 * t,
            height: widget.h - widget.h * .38 * t,
            decoration: BoxDecoration(
              color: Color.lerp(widget.cor, Colors.teal, t),
              borderRadius: BorderRadius.circular(10),
            ),
            child: widget.child,
          );
        },
      );
}

class _FadeLoop extends StatefulWidget {
  final Widget child;
  const _FadeLoop({required this.child});
  @override
  State<_FadeLoop> createState() => _FadeLoopState();
}

class _FadeLoopState extends State<_FadeLoop> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: Tween(begin: 1.0, end: .18).animate(_c), child: widget.child);
}

/// Lista que entra item a item ao compilar.
class _ListaAnimada extends StatelessWidget {
  final List<Widget> itens;
  const _ListaAnimada({required this.itens});
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < itens.length; i++)
            _EntradaAnimada(atraso: Duration(milliseconds: 120 * i), child: itens[i]),
        ],
      );
}

/// Entrada única ao compilar (pop / desliza / desce).
class _EntradaAnimada extends StatefulWidget {
  final Widget child;
  final Duration atraso;
  final bool desliza; // da esquerda (drawer)
  final bool desce; // de cima (appbar)
  const _EntradaAnimada({required this.child, this.atraso = Duration.zero, this.desliza = false, this.desce = false});
  @override
  State<_EntradaAnimada> createState() => _EntradaAnimadaState();
}

class _EntradaAnimadaState extends State<_EntradaAnimada> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.atraso, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curva = CurvedAnimation(parent: _c, curve: const Cubic(.16, 1, .3, 1));
    final desloc = widget.desliza
        ? Tween(begin: const Offset(-.4, 0), end: Offset.zero)
        : widget.desce
            ? Tween(begin: const Offset(0, -.6), end: Offset.zero)
            : Tween(begin: const Offset(0, .12), end: Offset.zero);
    return FadeTransition(
      opacity: curva,
      child: SlideTransition(position: desloc.animate(curva), child: ScaleTransition(scale: Tween(begin: .92, end: 1.0).animate(curva), child: widget.child)),
    );
  }
}
