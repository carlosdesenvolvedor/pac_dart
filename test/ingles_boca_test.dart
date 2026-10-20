import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/data/bocas_ingles.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/boca.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/elenco_ingles.dart';

void main() {
  group('TrilhaBoca', () {
    test('lê o formato do bocas.json (centésimos + visema) e acha a boca de cada instante', () {
      final t = TrilhaBoca.compacta('0X 9B 15E 41C 104A 221X 225X');
      expect(t.duracao, 2.25);
      expect(t.em(-1), Visema.x);
      expect(t.em(0.05), Visema.x);
      expect(t.em(0.09), Visema.b);
      expect(t.em(0.3), Visema.e);
      expect(t.em(1.1), Visema.a);
      expect(t.em(2.22), Visema.x);
      expect(t.em(9), Visema.x);
      // lixo no meio não derruba
      expect(TrilhaBoca.compacta('0X ?? 10Q 20D 90X').em(.25), Visema.d);
    });

    test('pelo texto: M/B/P fecham, F/V mordem o lábio, O arredonda, e termina parada', () {
      final t = TrilhaBoca.doTexto('Mom loves food.', segPorPalavra: .4);
      final vistos = {for (var s = 0.0; s < t.duracao; s += .01) t.em(s)};
      expect(vistos, containsAll([Visema.a, Visema.g, Visema.e, Visema.f]));
      expect(t.em(t.duracao + .1), Visema.x);
      expect(t.duracao, closeTo(.15 + 3 * .4, .05));
    });

    test('registro: só monta a trilha de quem tem boca gerada', () {
      BocasIngles.limpar();
      BocasIngles.registrar({'assets/ingles/voz/a.mp3': '0X 10D 50X'});
      expect(BocasIngles.de('assets/ingles/voz/a.mp3')!.em(.2), Visema.d);
      expect(BocasIngles.de('assets/ingles/voz/b.mp3'), isNull);
      BocasIngles.limpar();
    });
  });

  group('elenco', () {
    test('cada `quem` tem rosto: o elenco fixo, o aluno e os papéis genéricos por gênero', () {
      for (final n in ElencoIngles.nomes) {
        expect(ElencoIngles.de(n), isNotNull, reason: n);
      }
      expect(ElencoIngles.de('voce'), ElencoIngles.voce);
      expect(ElencoIngles.de('recepcionista'), ElencoIngles.ela);
      expect(ElencoIngles.de('vendedor'), ElencoIngles.ele);
      expect(ElencoIngles.de(''), isNull);
    });

    PersonagemPainter pintor(WidgetTester t) =>
        t.widget<CustomPaint>(find.descendant(of: find.byType(RostoPersonagem), matching: find.byType(CustomPaint))).painter!
            as PersonagemPainter;

    testWidgets('mexe a boca com a fala DELA (e com uma palavra dela), e fecha quando a voz para', (t) async {
      await t.pumpWidget(const MaterialApp(
        home: Center(child: PersonagemFalante(quem: 'ana', frase: 'Mom loves food.', tamanho: 120)),
      ));
      expect(pintor(t).visema, Visema.x);

      // outra frase falando: a Ana não mexe a boca
      VozIngles.falando.value = FalaEmCurso(
        frase: 'Something else.',
        boca: TrilhaBoca.compacta('0D 500X'),
        inicio: DateTime.now(),
      );
      await t.pump(const Duration(milliseconds: 50));
      expect(pintor(t).visema, Visema.x);

      // a frase dela: a boca segue a trilha
      VozIngles.falando.value = FalaEmCurso(
        frase: 'Mom loves food.',
        boca: TrilhaBoca.compacta('0D 500X'),
        inicio: DateTime.now(),
      );
      await t.pump(const Duration(milliseconds: 16));
      await t.pump(const Duration(milliseconds: 16));
      expect(pintor(t).visema, Visema.d);

      // uma palavra dela (o toque na palavra) também
      VozIngles.falando.value = FalaEmCurso(
        frase: 'food',
        boca: TrilhaBoca.compacta('0F 500X'),
        inicio: DateTime.now(),
      );
      await t.pump(const Duration(milliseconds: 16));
      await t.pump(const Duration(milliseconds: 16));
      expect(pintor(t).visema, Visema.f);

      VozIngles.falando.value = null;
      await t.pump();
      expect(pintor(t).visema, Visema.x);
      expect(pintor(t).balanco, 0);
    });

    testWidgets('pisca sozinho de vez em quando', (t) async {
      await t.pumpWidget(const MaterialApp(home: Center(child: PersonagemFalante(quem: 'mike', tamanho: 100))));
      var piscou = false;
      for (var i = 0; i < 120 && !piscou; i++) {
        await t.pump(const Duration(milliseconds: 50));
        piscou = pintor(t).olhos == 0;
      }
      expect(piscou, isTrue);
      await t.pump(const Duration(milliseconds: 200));
      expect(pintor(t).olhos, 1);
    });
  });
}
