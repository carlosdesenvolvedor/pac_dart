import 'dart:convert';
import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pac_dart/core/gemini/chave_gemini.dart';
import 'package:pac_dart/features/arcade/data/engenheiro_gt.dart';
import 'package:pac_dart/features/arcade/domain/turismo.dart';

TelemetriaGt _telemetria({bool chegou = true, int medalha = 3, int colisoes = 0, bool setas = false}) =>
    TelemetriaGt(
      pista: 'Autódromo da Campina',
      dificuldade: 'Iniciante',
      carro: 'Porsche 911 (930) Turbo',
      porSetas: setas,
      chegou: chegou,
      medalha: medalha,
      tempo: 200,
      tempoOuro: 220,
      tempoLimite: 240,
      distancia: 4000,
      percorrido: chegou ? 4000 : 3100,
      precisao: 96,
      colisoes: colisoes,
      melhorCombo: 12,
      palavras: 40,
      portaisLimpos: 30,
      totalPortais: 48,
      fichas: const ['=>', 'async'],
    );

Future<void> _comChave() async {
  final db = FakeFirebaseFirestore();
  await db.collection('config').doc('tutor').set({'chaveGemini': 'chave-de-teste'});
  ChaveGemini.dbParaTestes = db;
}

void main() {
  setUp(() {
    ChaveGemini.limparCache();
    ChaveGemini.dbParaTestes = FakeFirebaseFirestore();
  });

  test('a engenheira lê a resposta do Gemini e a telemetria vai no prompt', () async {
    await _comChave();
    String? corpo;
    final cliente = MockClient((req) async {
      corpo = req.body;
      expect(req.url.toString(), contains('gemini-flash-latest:generateContent'));
      return http.Response(
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Ouro limpo, 20 s abaixo da marca! '},
                  {'text': 'Segura esse ritmo.'}
                ]
              }
            }
          ]
        }),
        200,
      );
    });
    final texto = await EngenheiroGt(client: cliente).debrief(_telemetria());
    expect(texto, 'Ouro limpo, 20 s abaixo da marca! Segura esse ritmo.');
    expect(corpo, contains('ouro'));
    expect(corpo, contains('=>'));
    expect(corpo, contains('digitação'));
  });

  test('sem chave no Firestore, responde a engenheira de bolso na hora', () async {
    final cliente = MockClient((_) async => throw StateError('não devia chamar a rede'));
    final texto = await EngenheiroGt(client: cliente).debrief(_telemetria(medalha: 2, colisoes: 2));
    expect(texto, contains('faltaram'));
    expect(texto, contains('2 batidas'));
    expect(texto, contains('=>')); // curiosidade da ficha
  });

  test('erro da API (429) ou corpo estranho caem no texto local', () async {
    await _comChave();
    final t429 = await EngenheiroGt(client: MockClient((_) async => http.Response('{}', 429)))
        .debrief(_telemetria(chegou: false, setas: true));
    expect(t429, contains('bandeirada'));
    expect(t429, contains('↑'));
    ChaveGemini.limparCache();
    await _comChave();
    final vazio = await EngenheiroGt(client: MockClient((_) async => http.Response('{"candidates":[]}', 200)))
        .debrief(_telemetria());
    expect(vazio, contains('Ouro'));
    expect(EngenheiroGt.extrairTexto('não é json'), isNull);
  });

  test('TelemetriaGt.de lê o motor de verdade (fichas pegas, modo, portais)', () {
    final e = TurismoEngine(pista: pistasGt[0], rnd: Random(4), modo: ModoControle.setas);
    final t = TelemetriaGt.de(e, carro: 'Miata');
    expect(t.porSetas, isTrue);
    expect(t.totalPortais, e.portais.length);
    expect(t.distancia, pistasGt[0].distancia);
    expect(t.resumo, contains('setas'));
    expect(t.resumo, contains('Miata'));
  });
}
