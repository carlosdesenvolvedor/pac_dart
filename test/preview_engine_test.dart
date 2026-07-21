import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/preview/preview_engine.dart';

void main() {
  group('PreviewEngine — ao vivo × conceito', () {
    test('Text simples renderiza ao vivo', () {
      final r = PreviewEngine.gerar("Text('Olá, Flutter!')", 'dica');
      expect(r.aoVivo, isTrue);
    });

    test('Container com cor e filho renderiza ao vivo', () {
      final r = PreviewEngine.gerar(
          "Container(\n  width: 120,\n  height: 60,\n  color: Colors.amber,\n  child: Text('caixa'),\n)",
          'dica');
      expect(r.aoVivo, isTrue);
    });

    test('Column com children renderiza ao vivo', () {
      final r = PreviewEngine.gerar(
          "Column(\n  mainAxisAlignment: MainAxisAlignment.center,\n  children: [\n    Text('a'),\n    Icon(Icons.star),\n  ],\n)",
          'dica');
      expect(r.aoVivo, isTrue);
    });

    test('ListView.builder gera itens de amostra', () {
      final r = PreviewEngine.gerar(
          "ListView.builder(\n  itemCount: 3,\n  itemBuilder: (context, i) {\n    return Text('Item \$i');\n  },\n)",
          'dica');
      expect(r.aoVivo, isTrue);
    });

    test('declaração de classe StatefulWidget vira demo real', () {
      final r = PreviewEngine.gerar(
          'class Tela extends StatefulWidget {\n  @override\n  State<Tela> createState() => _TelaState();\n}',
          'dica');
      expect(r.modo, PreviewModo.demo);
    });

    test('setState vira demo real de contador', () {
      final r = PreviewEngine.gerar('setState(() {\n  contador++;\n});', 'dica');
      expect(r.modo, PreviewModo.demo);
    });

    test('TextStyle solto vira demo com o estilo aplicado', () {
      final r = PreviewEngine.gerar('const estilo = TextStyle(\n  fontSize: 20,\n);', 'dica');
      expect(r.modo, PreviewModo.demo);
    });

    test('Navigator.push vira demo de navegação real', () {
      final r = PreviewEngine.gerar(
          'Navigator.push(context, MaterialPageRoute(builder: (c) => Tela2()));', 'dica');
      expect(r.modo, PreviewModo.demo);
    });

    test('código sem padrão conhecido ainda vira conceito', () {
      final r = PreviewEngine.gerar('var contexto = XYZDesconhecido;', 'dica');
      expect(r.modo, PreviewModo.conceito);
    });

    test('ElevatedButton com lambda no onPressed renderiza', () {
      final r = PreviewEngine.gerar(
          "ElevatedButton(\n  onPressed: () {\n    print('clique');\n  },\n  child: Text('Enviar'),\n)",
          'dica');
      expect(r.aoVivo, isTrue);
    });

    test('Scaffold com AppBar e body renderiza', () {
      final r = PreviewEngine.gerar(
          "Scaffold(\n  appBar: AppBar(\n    title: Text('Meu app'),\n  ),\n  body: Center(\n    child: Text('corpo'),\n  ),\n)",
          'dica');
      expect(r.aoVivo, isTrue);
    });
  });
}
