// Conteúdo de verdade da história do English Turismo ("The Golden Wheel"): os 3 JSON de `assets/ingles/`
// lidos por dart:io em parse ESTRITO, `validar()` vazio, 30 capítulos, níveis por faixa (plano 5.2),
// V-mundo nos 30 (tabela 5.4) e os capítulos 1 e 30 tocados de ponta a ponta no PlayerHistoria.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/som/sons.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/data/historia_turismo_repo.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/domain/progresso_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/elenco_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/player_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/roteiro_historia.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voz de teste: guarda o que o player mandou falar (com o perfil) e termina na hora.
class _VozFake extends VozIngles {
  final falas = <(String, PerfilVoz?)>[];

  @override
  Future<FimDaFala> falarNoPlayer(String frase, {required double fator, PerfilVoz? perfil}) {
    falas.add((frase, perfil));
    return Future.value(FimDaFala.acabou);
  }

  @override
  Future<void> falar(String frase, {bool? lenta}) {
    falas.add((frase, null));
    return Future.value();
  }

  @override
  Future<void> parar() async {}

  @override
  bool get somLiberado => true;
}

List<Map<String, dynamic>> _lerPartes() => [
      for (final a in HistoriaTurismoRepo.arquivos) jsonDecode(File(a).readAsStringSync()) as Map<String, dynamic>,
    ];

/// Tabela 5.2: nível por faixa de capítulos.
String _nivelEsperado(int n) => n <= 8
    ? 'A1'
    : n <= 16
        ? 'A2'
        : n <= 24
            ? 'B1'
            : 'B2';

/// Tabela 5.4 (coluna "mundo"), escrita de novo aqui para conferir também a const `cenarioDaPista`.
const _mundo = [
  'campina', 'deserto', 'cidade', 'neve', 'vulcao', 'espaco', 'campina', 'deserto', 'cidade', 'espaco', //
  'campina', 'vale', 'floresta', 'campina', 'praia', 'ponte', 'canion', 'deserto', 'oasis', 'cidade', //
  'cidade', 'cidade', 'neve', 'lago', 'neve', 'vulcao', 'lua', 'marte', 'estacao', 'autodromo', //
];

/// O cenário efetivo da 1ª e da última fala da abertura (contando trocas de `cenario` dentro da cena).
(CenarioHistoria, CenarioHistoria) _cenariosDasPontas(CapituloHistoria c) {
  final primeira = c.intro.first.falas.first.cenario ?? c.intro.first.cenario;
  final ultimaCena = c.intro.last;
  var efetivo = ultimaCena.cenario;
  for (final f in ultimaCena.falas) {
    efetivo = f.cenario ?? efetivo;
  }
  return (primeira, efetivo);
}

Future<void> _avancar(WidgetTester t, double segundos, {int passoMs = 100}) async {
  final n = (segundos * 1000 / passoMs).ceil();
  for (var i = 0; i < n; i++) {
    await t.pump(Duration(milliseconds: passoMs));
    expect(t.takeException(), isNull);
  }
}

/// Bomba até [achou] (ou [limite] s de relógio), sem nenhuma exceção (overflow incluído) no caminho.
Future<bool> _ate(WidgetTester t, bool Function() achou, {double limite = 240, int passoMs = 100}) async {
  final n = (limite * 1000 / passoMs).ceil();
  for (var i = 0; i < n; i++) {
    if (achou()) return true;
    await t.pump(Duration(milliseconds: passoMs));
    expect(t.takeException(), isNull);
  }
  return achou();
}

bool _temCartaoFinal() => find.byKey(const Key('historia-cartao-final')).evaluate().isNotEmpty;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  final partes = _lerPartes();
  final historia = HistoriaTurismo.dasPartes(partes); // estrito: qualquer erro de esquema estoura aqui

  group('conteúdo (parse estrito dos 3 JSON)', () {
    test('os 3 arquivos são as partes a, b e c, versão 2, com o mesmo título', () {
      expect(partes.map((p) => p['parte']).toList(), ['a', 'b', 'c']);
      for (final p in partes) {
        expect(p['versao'], 2);
        expect(p['titulo'], {'en': 'The Golden Wheel', 'pt': 'A Roda de Ouro'});
      }
      expect(historia.titulo.en, 'The Golden Wheel');
    });

    test('validar() não acha nenhum erro', () {
      expect(historia.validar(), isEmpty);
    });

    test('30 capítulos, 1..30 uma vez cada, em ordem; gancho em 1–29 e nunca no 30', () {
      expect(historia.capitulos.map((c) => c.pista).toList(), [for (var n = 1; n <= 30; n++) n]);
      for (final c in historia.capitulos) {
        expect(c.gancho != null, c.pista < 30, reason: 'cap ${c.pista}');
      }
    });

    test('níveis por faixa (plano 5.2) e falas dentro dos limites do nível', () {
      for (final c in historia.capitulos) {
        expect(c.nivel.json, _nivelEsperado(c.pista), reason: 'cap ${c.pista}');
        int comTexto(List<CenaHistoria> cenas) => cenas.expand((s) => s.falas).where((f) => !f.mudo).length;
        final intro = comTexto(c.intro), fim = comTexto(c.fim);
        final fi = c.nivel.faixaIntro, ff = c.pista == 30 ? faixaFimFinal : c.nivel.faixaFim;
        expect(intro, inInclusiveRange(fi.$1, fi.$2), reason: 'cap ${c.pista} intro');
        expect(fim, inInclusiveRange(ff.$1, ff.$2), reason: 'cap ${c.pista} fim');
        for (final f in c.todasAsFalas) {
          expect(f.palavras, lessThanOrEqualTo(c.nivel.maxPalavras), reason: 'cap ${c.pista}: ${f.en}');
        }
      }
    });

    test('V-mundo: a 1ª ou a última fala da abertura acontece no mundo da pista (os 30)', () {
      for (var n = 1; n <= 30; n++) {
        expect(cenarioDaPista[n]!.name, _mundo[n - 1], reason: 'cenarioDaPista[$n]');
        final c = historia.capitulo(n)!;
        final (primeira, ultima) = _cenariosDasPontas(c);
        expect(primeira.name == _mundo[n - 1] || ultima.name == _mundo[n - 1], isTrue,
            reason: 'cap $n: ${primeira.name} … ${ultima.name} (esperava ${_mundo[n - 1]})');
      }
    });

    test('o parse tolerante (o do app) lê os mesmos 30 capítulos sem aviso', () {
      final avisos = <String>[];
      final h = HistoriaTurismo.dasPartes(_lerPartes(), estrito: false, aviso: avisos.add);
      expect(avisos, isEmpty);
      expect(h.capitulos.length, 30);
    });
  });

  group('capítulos de verdade tocados de ponta a ponta', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      RoteiroHistoria.tocarSom = (_) {};
      VozIngles.falando.value = null;
    });
    tearDown(() {
      RoteiroHistoria.tocarSom = Sons.toca;
      VozIngles.falando.value = null;
    });

    Future<FimDoPlayer?> tocar(WidgetTester t, CapituloHistoria cap, ParteDoCapitulo parte, _VozFake voz,
        {bool creditos = false}) async {
      t.view.physicalSize = const Size(1280, 720);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      FimDoPlayer? fim;
      var fechou = false;
      await t.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  fim = await abrirCenaDaHistoria(context, capitulo: cap, parte: parte, voz: voz, creditos: creditos);
                  fechou = true;
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ));
      await t.tap(find.text('abrir'));
      await t.pump();
      await _avancar(t, .4);
      bool terminou() => creditos ? find.text('THE END').evaluate().isNotEmpty : _temCartaoFinal();
      expect(await _ate(t, terminou), isTrue, reason: 'cap ${cap.pista} ${parte.name}: chegou ao cartão final');

      // a voz recebeu cada fala com texto, na ordem, com o perfil de quem fala
      final esperadas = [
        for (final s in cap.parte(parte))
          for (final f in s.falas)
            if (!f.mudo) f,
      ];
      expect(voz.falas.map((f) => f.$1).toList(), esperadas.map((f) => f.en).toList());
      for (var i = 0; i < esperadas.length; i++) {
        expect(voz.falas[i].$2, ElencoTurismo.perfilDeVoz(esperadas[i].quem), reason: esperadas[i].quem);
      }

      if (creditos) {
        expect(find.text('THE END'), findsWidgets);
        await _avancar(t, 19); // a rolagem dos créditos acaba
        await t.tap(find.byKey(const Key('historia-concluir')));
      } else {
        await t.tap(find.byKey(Key(parte == ParteDoCapitulo.intro ? 'historia-correr' : 'historia-continuar')));
      }
      await _avancar(t, .6);
      expect(fechou, isTrue);
      await t.pumpWidget(Container());
      return fim;
    }

    testWidgets('capítulo 1: abertura e chegada inteiras', (t) async {
      final cap = historia.capitulo(1)!;
      expect(await tocar(t, cap, ParteDoCapitulo.intro, _VozFake()), FimDoPlayer.assistido);
      expect(await tocar(t, cap, ParteDoCapitulo.fim, _VozFake()), FimDoPlayer.assistido);
      expect(await ProgressoHistoria.vistos(), containsAll(['i1', 'f1', 'c1']));
    });

    testWidgets('capítulo 30: abertura e o final com créditos', (t) async {
      final cap = historia.capitulo(30)!;
      expect(await tocar(t, cap, ParteDoCapitulo.intro, _VozFake()), FimDoPlayer.assistido);
      expect(await tocar(t, cap, ParteDoCapitulo.fim, _VozFake(), creditos: true), FimDoPlayer.assistido);
      expect(await ProgressoHistoria.vistos(), containsAll(['i30', 'f30', 'c30']));
    });
  });
}
