import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/som/sintetizador.dart';
import 'package:pac_dart/core/som/sons.dart';

/// As amostras (int16) de um WAV gerado pelo sintetizador.
List<int> amostras(Uint8List wav) {
  final d = ByteData.sublistView(wav);
  return [for (var i = 44; i + 1 < wav.length; i += 2) d.getInt16(i, Endian.little)];
}

String texto(Uint8List wav, int ini, int n) => String.fromCharCodes(wav.sublist(ini, ini + n));

void main() {
  group('efeitos sonoros fora do navegador (WAV sintetizado)', () {
    test('todo efeito é um WAV mono de 16 bits bem formado, com som e sem estourar', () {
      for (final som in Som.values) {
        final wav = sintetizarWav(som);
        final d = ByteData.sublistView(wav);
        expect(texto(wav, 0, 4), 'RIFF', reason: '$som');
        expect(texto(wav, 8, 4), 'WAVE', reason: '$som');
        expect(texto(wav, 36, 4), 'data', reason: '$som');
        expect(d.getUint16(22, Endian.little), 1, reason: '$som mono');
        expect(d.getUint32(24, Endian.little), taxaDeAmostragem, reason: '$som taxa');
        expect(d.getUint16(34, Endian.little), 16, reason: '$som bits');
        // o tamanho declarado bate com o arquivo
        expect(d.getUint32(40, Endian.little), wav.length - 44, reason: '$som data');
        expect(d.getUint32(4, Endian.little), wav.length - 8, reason: '$som riff');
        final a = amostras(wav);
        final pico = a.map((v) => v.abs()).reduce(math.max);
        expect(pico, greaterThan(1500), reason: '$som não pode sair mudo');
        expect(pico, lessThanOrEqualTo(32767), reason: '$som');
      }
    });

    test('a duração segue a partitura (fanfarra ≈ 0,7 s; tique é curtinho; âncora é longa)', () {
      double seg(Som s) => amostras(sintetizarWav(s)).length / taxaDeAmostragem;
      expect(seg(Som.fanfarra), inInclusiveRange(.6, .8));
      expect(seg(Som.tique), lessThan(.2));
      expect(seg(Som.ancora), greaterThan(1.8));
    });

    test('o waka alterna: subindo numa tecla, descendo na outra', () {
      expect(sintetizarWav(Som.waka, alterna: true), isNot(equals(sintetizarWav(Som.waka, alterna: false))));
      expect(sintetizarWav(Som.waka, alterna: true), equals(sintetizarWav(Som.waka, alterna: true)),
          reason: 'determinístico');
    });

    test('o sino da âncora decai: o fim é bem mais fraco que o começo', () {
      final a = amostras(sintetizarWav(Som.ancora));
      double rms(int ini, int fim) =>
          math.sqrt(a.sublist(ini, fim).fold<double>(0, (s, v) => s + v * v) / (fim - ini));
      final t = taxaDeAmostragem;
      expect(rms((1.4 * t).round(), (1.9 * t).round()), lessThan(rms(0, (.5 * t).round()) * .5));
    });

    test('o ronco do motor dura 1 s, tem som e emenda sem estalo no laço', () {
      final a = amostras(sintetizarMotor());
      expect(a.length, taxaDeAmostragem);
      final pico = a.map((v) => v.abs()).reduce(math.max);
      expect(pico, inInclusiveRange(20000, 32767));
      var maiorSalto = 0;
      for (var i = 1; i < a.length; i++) {
        maiorSalto = math.max(maiorSalto, (a[i] - a[i - 1]).abs());
      }
      final emenda = (a.first - a.last).abs();
      expect(emenda, lessThanOrEqualTo(maiorSalto + 1), reason: 'o salto do fim para o começo é igual aos de dentro do laço');
    });
  });
}
