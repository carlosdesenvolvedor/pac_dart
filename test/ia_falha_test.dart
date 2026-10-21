import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pac_dart/features/tutor/data/falha_ia.dart';

/// O erro tipado da IA: o status HTTP e as mensagens dos SDKs viram um motivo que a tela entende.
void main() {
  group('tipoDoStatus', () {
    const corpoDiario = '{"error":{"code":429,"status":"RESOURCE_EXHAUSTED","details":[{"violations":'
        '[{"quotaId": "GenerateRequestsPerDayPerProjectPerModel-FreeTier"}]}]}}';
    const corpoMinuto = '{"error":{"code":429,"details":[{"violations":'
        '[{"quotaId": "GenerateRequestsPerMinutePerProjectPerModel-FreeTier"}]}]}}';
    final casos = <(int, String, TipoFalhaIa)>[
      (429, '{"error":{"status":"RESOURCE_EXHAUSTED"}}', TipoFalhaIa.limite),
      (429, corpoDiario, TipoFalhaIa.limiteDiario),
      (429, corpoMinuto, TipoFalhaIa.limite),
      (500, '', TipoFalhaIa.ocupado),
      (502, '', TipoFalhaIa.ocupado),
      (503, '{"error":{"status":"UNAVAILABLE"}}', TipoFalhaIa.ocupado),
      (504, '', TipoFalhaIa.ocupado),
      (401, '', TipoFalhaIa.credencial),
      (403, '{"error":{"status":"PERMISSION_DENIED"}}', TipoFalhaIa.credencial),
      (400, '{"error":{"message":"API key not valid. Please pass a valid API key."}}', TipoFalhaIa.credencial),
      (400, '{"error":{"details":[{"reason":"API_KEY_INVALID"}]}}', TipoFalhaIa.credencial),
      (400, '{"error":{"message":"Invalid JSON payload received."}}', TipoFalhaIa.outro),
      (404, '{"error":{"message":"models/x is not found"}}', TipoFalhaIa.outro),
    ];
    for (final (status, corpo, esperado) in casos) {
      test('$status ${corpo.length > 40 ? '${corpo.substring(0, 40)}…' : corpo} → ${esperado.name}', () {
        expect(FalhaIa.tipoDoStatus(status, corpo), esperado);
      });
    }
  });

  test('ehLimiteDiario: PerDay / per day / per_day (sem caixa); PerMinute não', () {
    expect(FalhaIa.ehLimiteDiario('quotaId: GenerateRequestsPerDayPerProjectPerModel-FreeTier'), isTrue);
    expect(FalhaIa.ehLimiteDiario('Quota exceeded: requests PER DAY'), isTrue);
    expect(FalhaIa.ehLimiteDiario('limit per_day reached'), isTrue);
    expect(FalhaIa.ehLimiteDiario('quotaId: GenerateRequestsPerMinutePerProjectPerModel-FreeTier'), isFalse);
    expect(FalhaIa.ehLimiteDiario(''), isFalse);
  });

  group('FalhaIa.de', () {
    final casos = <(String, Object, TipoFalhaIa)>[
      ('SocketException', Exception('SocketException: Failed host lookup: generativelanguage.googleapis.com'),
          TipoFalhaIa.semRede),
      ('ClientException da web', http.ClientException('XMLHttpRequest error.'), TipoFalhaIa.semRede),
      ('Connection closed', Exception('Connection closed before full header was received'), TipoFalhaIa.semRede),
      ('TimeoutException', TimeoutException('demorou', const Duration(seconds: 25)), TipoFalhaIa.semRede),
      ('RESOURCE_EXHAUSTED', Exception('429 RESOURCE_EXHAUSTED'), TipoFalhaIa.limite),
      ('Quota exceeded', Exception('Quota exceeded for quota metric generate_content_requests'), TipoFalhaIa.limite),
      ('Quota exceeded por dia', Exception('Quota exceeded for metric ... limit: 250 per day, model: gemini-flash'),
          TipoFalhaIa.limiteDiario),
      ('model is overloaded', Exception('The model is overloaded. Please try again later.'), TipoFalhaIa.ocupado),
      ('503 UNAVAILABLE', Exception('Server error 503 UNAVAILABLE'), TipoFalhaIa.ocupado),
      ('Response was blocked', Exception('Response was blocked due to SAFETY'), TipoFalhaIa.recusada),
      ('PERMISSION_DENIED', Exception('PERMISSION_DENIED: requests from this referer are blocked?'), TipoFalhaIa.credencial),
      ('API key', Exception('API key not valid'), TipoFalhaIa.credencial),
      ('texto antigo do REST', Exception('Gemini 429: {"error":{"code":429}}'), TipoFalhaIa.limite),
      ('outra coisa', Exception('boom'), TipoFalhaIa.outro),
      ('qualquer objeto', 42, TipoFalhaIa.outro),
    ];
    for (final (nome, erro, esperado) in casos) {
      test('$nome → ${esperado.name}', () => expect(FalhaIa.de(erro).tipo, esperado));
    }

    test('uma FalhaIa passa como está', () {
      const f = FalhaIa(TipoFalhaIa.ocupado, status: 503, detalhe: 'x');
      expect(identical(FalhaIa.de(f), f), isTrue);
    });

    test('guarda a mensagem original no detalhe', () {
      expect(FalhaIa.de(Exception('boom')).detalhe, contains('boom'));
    });
  });

  group('toString (o TutorCubit procura "429"/"403" no texto)', () {
    test('com status: "Gemini <status>: <detalhe>"', () {
      const f = FalhaIa(TipoFalhaIa.limite, status: 429, detalhe: '{"error":"RESOURCE_EXHAUSTED"}');
      expect('$f', 'Gemini 429: {"error":"RESOURCE_EXHAUSTED"}');
      expect('${const FalhaIa(TipoFalhaIa.credencial, status: 403, detalhe: 'PERMISSION_DENIED')}', contains('403'));
    });

    test('sem status: o tipo e o detalhe', () {
      expect('${const FalhaIa(TipoFalhaIa.semRede, detalhe: 'offline')}', 'FalhaIa(semRede): offline');
    });
  });
}
