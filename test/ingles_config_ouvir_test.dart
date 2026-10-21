import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/data/preferencias_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/config_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _f = Faixa(chave: 'f-1', en: 'Nice to meet you.', pt: 'Prazer em conhecer.', segundos: 2);
const _semPt = Faixa(chave: 'f-2', en: 'Hi.', segundos: 1);

Duration _ms(int ms) => Duration(milliseconds: ms);

void main() {
  group('pausaPara / pausaPense', () {
    test('curta, média e longa são fixas; eco = seg × 1,2 / v + 0,8 entre 1,5 e 9 s', () {
      expect(pausaPara(PausaOuvir.curta, 2, 1), _ms(500));
      expect(pausaPara(PausaOuvir.media, 2, 1), _ms(1000));
      expect(pausaPara(PausaOuvir.longa, 2, .75), _ms(2000));
      expect(pausaPara(PausaOuvir.eco, 2, 1), _ms(3200));
      expect(pausaPara(PausaOuvir.eco, 2, .75), _ms(4000)); // 2 × 1,2 / 0,75 + 0,8
      expect(pausaPara(PausaOuvir.eco, .2, 1), _ms(1500), reason: 'mínimo');
      expect(pausaPara(PausaOuvir.eco, 30, 1), _ms(9000), reason: 'máximo');
    });

    test('pense = seg × 1,5 / v + 1 entre 2 e 10 s', () {
      expect(pausaPense(2, 1), _ms(4000));
      expect(pausaPense(0, 1), _ms(2000));
      expect(pausaPense(20, 1.15), _ms(10000));
    });
  });

  group('passosDa', () {
    test('Só inglês: [fala, pausa] × repetições', () {
      expect(passosDa(_f, const ConfigOuvir(), fimDeLicao: false), [
        const FalaEn(fator: 1),
        Silencio(d: _ms(1000), fase: FaseOuvir.respiro),
      ]);
      expect(passosDa(_f, const ConfigOuvir(repeticoes: 3, velocidade: .9, pausa: PausaOuvir.curta), fimDeLicao: false), [
        const FalaEn(fator: .9, vez: 1, de: 3),
        Silencio(d: _ms(500), fase: FaseOuvir.respiro),
        const FalaEn(fator: .9, vez: 2, de: 3),
        Silencio(d: _ms(500), fase: FaseOuvir.respiro),
        const FalaEn(fator: .9, vez: 3, de: 3),
        Silencio(d: _ms(500), fase: FaseOuvir.respiro),
      ]);
    });

    test('"2ª vez devagar": da 2ª passada em diante a 0,8 × velocidade; eco mostra "Sua vez"', () {
      final p = passosDa(
        _f,
        const ConfigOuvir(repeticoes: 2, segundaDevagar: true, pausa: PausaOuvir.eco),
        fimDeLicao: false,
      );
      expect(p, [
        const FalaEn(fator: 1, vez: 1, de: 2),
        Silencio(d: _ms(3200), fase: FaseOuvir.suaVez),
        const FalaEn(fator: .8, vez: 2, de: 2),
        Silencio(d: _ms(3200), fase: FaseOuvir.suaVez),
      ]);
    });

    test('Inglês → português: fala, 0,4 s, tradução, pausa', () {
      expect(passosDa(_f, const ConfigOuvir(modo: ModoOuvir.inglesPortugues), fimDeLicao: false), [
        const FalaEn(fator: 1),
        Silencio(d: _ms(400), fase: FaseOuvir.traducao),
        const FalaPt(),
        Silencio(d: _ms(1000), fase: FaseOuvir.respiro),
      ]);
      // com repetições, o inglês repete antes da tradução
      expect(passosDa(_f, const ConfigOuvir(modo: ModoOuvir.inglesPortugues, repeticoes: 2), fimDeLicao: false), [
        const FalaEn(fator: 1, vez: 1, de: 2),
        Silencio(d: _ms(1000), fase: FaseOuvir.respiro),
        const FalaEn(fator: 1, vez: 2, de: 2),
        Silencio(d: _ms(400), fase: FaseOuvir.traducao),
        const FalaPt(),
        Silencio(d: _ms(1000), fase: FaseOuvir.respiro),
      ]);
    });

    test('Português → inglês: tradução, pense, fala, pausa', () {
      expect(passosDa(_f, const ConfigOuvir(modo: ModoOuvir.portuguesIngles), fimDeLicao: false), [
        const FalaPt(),
        Silencio(d: _ms(4000), fase: FaseOuvir.pense),
        const FalaEn(fator: 1),
        Silencio(d: _ms(1000), fase: FaseOuvir.respiro),
      ]);
    });

    test('fim de lição soma 1,5 s à última pausa', () {
      expect(passosDa(_f, const ConfigOuvir(), fimDeLicao: true).last, Silencio(d: _ms(2500), fase: FaseOuvir.respiro));
      expect(
        passosDa(_f, const ConfigOuvir(modo: ModoOuvir.inglesPortugues, pausa: PausaOuvir.longa), fimDeLicao: true).last,
        Silencio(d: _ms(3500), fase: FaseOuvir.respiro),
      );
    });

    test('frase sem tradução: os modos com português viram "Só inglês"', () {
      for (final m in ModoOuvir.values) {
        expect(passosDa(_semPt, ConfigOuvir(modo: m), fimDeLicao: false), [
          const FalaEn(fator: 1),
          Silencio(d: _ms(1000), fase: FaseOuvir.respiro),
        ]);
      }
    });
  });

  group('ConfigOuvir JSON', () {
    test('ida e volta', () {
      const c = ConfigOuvir(
        modo: ModoOuvir.portuguesIngles,
        velocidade: 1.15,
        repeticoes: 3,
        segundaDevagar: true,
        pausa: PausaOuvir.eco,
        mostrarTraducao: false,
        repetirTudo: true,
      );
      expect(ConfigOuvir.fromJson(jsonDecode(jsonEncode(c.toJson())) as Map), c);
      expect(ConfigOuvir.fromJson(const ConfigOuvir().toJson()), const ConfigOuvir());
    });

    test('tolerante: nulo, tipos errados, enum desconhecido e números fora da faixa', () {
      expect(ConfigOuvir.fromJson(null), const ConfigOuvir());
      expect(ConfigOuvir.fromJson({}), const ConfigOuvir());
      expect(
        ConfigOuvir.fromJson({'mo': 'karaoke', 'v': 'rápido', 'r': true, 'd': 'sim', 'pa': 7, 't': null, 'rt': 1}),
        const ConfigOuvir(),
      );
      final c = ConfigOuvir.fromJson({'v': 0.8, 'r': 9, 'mo': 'inglesPortugues'});
      expect(c.velocidade, .75, reason: 'a velocidade mais perto dos chips');
      expect(c.repeticoes, 3);
      expect(c.modo, ModoOuvir.inglesPortugues);
      expect(ConfigOuvir.fromJson({'r': 0}).repeticoes, 1);
      expect(ConfigOuvir.fromJson({'v': double.nan}).velocidade, 1.0);
    });
  });

  group('PreferenciasOuvir', () {
    test('salva e lê a config e as posições; pref estragada = padrão, sem lançar', () async {
      SharedPreferences.setMockInitialValues({});
      final p = PreferenciasOuvir('u1');
      await p.carregar();
      expect(p.config, const ConfigOuvir());
      expect(p.posicao('curso'), isNull);

      await p.salvarConfig(const ConfigOuvir(velocidade: .9, repeticoes: 2));
      await p.salvarPosicao('curso', 34, 'f-abc');
      await p.salvarPosicao('setlist:s1', 2, 'f-xyz');

      final outra = PreferenciasOuvir('u1');
      await outra.carregar();
      expect(outra.config, const ConfigOuvir(velocidade: .9, repeticoes: 2));
      expect(outra.posicao('curso'), (i: 34, chave: 'f-abc'));
      expect(outra.posicao('setlist:s1'), (i: 2, chave: 'f-xyz'));

      // a posição é por conta; a config é do aparelho
      final u2 = PreferenciasOuvir('u2');
      await u2.carregar();
      expect(u2.posicao('curso'), isNull);
      expect(u2.config.velocidade, .9);

      SharedPreferences.setMockInitialValues({
        PreferenciasOuvir.prefConfig: '{não é json',
        'en_ouvir_pos_u1': jsonEncode({'curso': {'i': 'x'}, 'ok': {'i': 3, 'k': 'f-1', 'm': 5}, 'neg': {'i': -1, 'k': 'a'}}),
      });
      final estragada = PreferenciasOuvir('u1');
      await estragada.carregar();
      expect(estragada.config, const ConfigOuvir());
      expect(estragada.posicao('curso'), isNull);
      expect(estragada.posicao('neg'), isNull);
      expect(estragada.posicao('ok'), (i: 3, chave: 'f-1'));
    });

    test('guarda no máximo maxPosicoes fontes (as mais antigas saem)', () async {
      SharedPreferences.setMockInitialValues({});
      final p = PreferenciasOuvir('u1');
      await p.carregar();
      for (var i = 0; i < PreferenciasOuvir.maxPosicoes + 5; i++) {
        await p.salvarPosicao('setlist:$i', i, 'f-$i');
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      final j = jsonDecode((await SharedPreferences.getInstance()).getString(p.prefPosicoes)!) as Map;
      expect(j.length, PreferenciasOuvir.maxPosicoes);
      expect(p.posicao('setlist:0'), isNull);
      expect(p.posicao('setlist:${PreferenciasOuvir.maxPosicoes + 4}'), isNotNull);
    });
  });
}
