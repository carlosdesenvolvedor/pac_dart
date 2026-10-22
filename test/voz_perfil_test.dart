import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/data/audio_nativo.dart';
import 'package:pac_dart/features/ingles/data/audio_usuario.dart';
import 'package:pac_dart/features/ingles/data/audio_usuario_repository.dart';
import 'package:pac_dart/features/ingles/data/bocas_ingles.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/boca.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';

/// 🎭 Grupo V: a voz por personagem da história do English Turismo (`falarNoPlayer(perfil:)`).

/// Um WAV mínimo para o áudio do aluno (que entra pelo `tocarClipe` injetado).
Uint8List _wav() {
  final b = Uint8List(64);
  b.setRange(0, 4, 'RIFF'.codeUnits);
  b.setRange(8, 12, 'WAVE'.codeUnits);
  return b;
}

/// A voz sintética "do personagem" que só termina quando o teste manda.
class _Sintetica {
  final falas = <(String, double, PerfilVoz)>[];
  final _fins = <Completer<void>>[];

  Future<void> falar(String frase, double v, PerfilVoz p) {
    falas.add((frase, v, p));
    final c = Completer<void>();
    _fins.add(c);
    return c.future;
  }

  void acabar([int i = 0]) => _fins[i].complete();
}

/// Tudo que foi anunciado em [VozIngles.falando] (a boca dos personagens).
List<FalaEmCurso> _ouvirAnuncios(void Function(void Function()) aoFim) {
  final anuncios = <FalaEmCurso>[];
  void ouvinte() {
    final f = VozIngles.falando.value;
    if (f != null) anuncios.add(f);
  }

  VozIngles.falando.addListener(ouvinte);
  aoFim(() => VozIngles.falando.removeListener(ouvinte));
  return anuncios;
}

const _mp3 = 'assets/ingles/voz/hello.mp3';
const _bocaMp3 = '0X 20C 27B 150F 222X';
const _sarah = PerfilVoz(tom: 1.10, variante: 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AudioUsuario.limpar();
    AudioNativo.limpar();
    BocasIngles.limpar();
    VozIngles.falando.value = null;
    await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
    await AudioUsuario.adicionar('Hello.', _wav()); // o aluno anexou áudio a esta frase
    AudioNativo.registrarGeradas({'Hello.': _mp3, 'Nice to meet you.': _mp3}); // e há mp3 de personagem
    BocasIngles.registrar({_mp3: _bocaMp3});
  });

  tearDown(() {
    AudioUsuario.limpar();
    AudioNativo.limpar();
    BocasIngles.limpar();
    VozIngles.lentaPorPadrao = true;
    VozIngles.falando.value = null;
  });

  group('PerfilVoz', () {
    test('padrão = tom 1, variante 0; igualdade por valor', () {
      expect(PerfilVoz.padrao.tom, 1);
      expect(PerfilVoz.padrao.variante, 0);
      expect(const PerfilVoz(), PerfilVoz.padrao);
      expect(const PerfilVoz(tom: 1.1, variante: 1), _sarah);
      expect(const PerfilVoz(tom: 1.1, variante: 1).hashCode, _sarah.hashCode);
      expect(const PerfilVoz(tom: 1.1), isNot(_sarah));
    });
  });

  group('falarNoPlayer com perfil', () {
    test('só voz sintética: não toca o áudio do aluno nem o mp3; a boca vem do texto', () async {
      final clipes = <double>[];
      final sint = _Sintetica();
      final voz = VozIngles(
        tocarClipe: (_, _, v) async {
          clipes.add(v);
          return true;
        },
        falarComPerfil: sint.falar,
      );
      final anuncios = _ouvirAnuncios(addTearDown);

      final f = voz.falarNoPlayer('Hello.', fator: 1, perfil: _sarah);
      await pumpEventQueue();
      expect(clipes, isEmpty, reason: 'o áudio que o aluno anexou é de outra cena, não do personagem');
      expect(sint.falas, [('Hello.', VozIngles.velocidadeNormal, _sarah)]);
      expect(anuncios, hasLength(1), reason: 'nenhum anúncio da boca do mp3 antes da sintética');
      final a = anuncios.single;
      expect(a.frase, 'Hello.');
      expect(a.gravacao, isFalse);
      expect(a.velocidade, 1);
      final pelaFrase = TrilhaBoca.doTexto('Hello.', segPorPalavra: VozIngles.segPorPalavra);
      expect(a.boca.tempos, pelaFrase.tempos);
      expect(a.boca.visemas, pelaFrase.visemas);
      expect(a.boca.duracao, isNot(TrilhaBoca.compacta(_bocaMp3).duracao));
      expect(VozIngles.falando.value?.frase, 'Hello.', reason: 'a boca mexe enquanto a sintética fala');

      sint.acabar();
      expect(await f, FimDaFala.acabou);
      expect(VozIngles.falando.value, isNull, reason: 'acabou: a boca fecha');
    });

    test('a velocidade segue o fator (clamp .6–1.2), ignora a lenta global; a boca acompanha', () async {
      VozIngles.lentaPorPadrao = true;
      final velocidades = <double>[];
      final voz = VozIngles(falarComPerfil: (_, v, _) async => velocidades.add(v));
      final anuncios = _ouvirAnuncios(addTearDown);

      await voz.falarNoPlayer('Nice to meet you.', fator: .8, perfil: _sarah);
      await voz.falarNoPlayer('Nice to meet you.', fator: 1, perfil: PerfilVoz.padrao);
      await voz.falarNoPlayer('Nice to meet you.', fator: 2, perfil: _sarah);
      await voz.falarNoPlayer('Nice to meet you.', fator: .1, perfil: _sarah);
      await voz.falarNoPlayer('Nice to meet you.', fator: 0, perfil: _sarah);
      expect(velocidades, [
        closeTo(.76, 1e-9),
        closeTo(.95, 1e-9),
        1.2,
        .6,
        closeTo(.95, 1e-9),
      ]);
      expect(
        anuncios.first.boca.duracao,
        closeTo(TrilhaBoca.doTexto('Nice to meet you.', segPorPalavra: VozIngles.segPorPalavra / .8).duracao, 1e-9),
        reason: 'a 🐢 da história estica a boca junto',
      );
      expect(anuncios.every((a) => !a.gravacao), isTrue);
    });

    test('PerfilVoz.padrao também é "com perfil": sempre sintética', () async {
      var clipes = 0;
      final perfis = <PerfilVoz>[];
      final voz = VozIngles(
        tocarClipe: (_, _, _) async {
          clipes++;
          return true;
        },
        falarComPerfil: (_, _, p) async => perfis.add(p),
      );
      expect(await voz.falarNoPlayer('Hello.', fator: 1, perfil: PerfilVoz.padrao), FimDaFala.acabou);
      expect(clipes, 0);
      expect(perfis, [PerfilVoz.padrao]);
    });

    test('vezGlobal sobe na hora (antes de qualquer await)', () {
      final voz = VozIngles(falarComPerfil: (_, _, _) async {});
      final g0 = VozIngles.vezGlobal;
      unawaited(voz.falarNoPlayer('Hello.', fator: 1, perfil: _sarah));
      expect(VozIngles.vezGlobal, g0 + 1);
    });

    test('outra VozIngles falou no meio = cortada, e a boca de quem cortou continua', () async {
      final sint = _Sintetica();
      final historia = VozIngles(falarComPerfil: sint.falar);

      final f = historia.falarNoPlayer('Nice to meet you.', fator: 1, perfil: _sarah);
      await pumpEventQueue();
      expect(VozIngles.falando.value?.frase, 'Nice to meet you.');

      // o palco fala "Hello." (o áudio do aluno, que só termina mais tarde)
      final fimPalco = Completer<bool>();
      final palcoLento = VozIngles(tocarClipe: (_, _, _) => fimPalco.future);
      final q = palcoLento.falar('Hello.');
      await pumpEventQueue();
      expect(VozIngles.falando.value?.frase, 'Hello.');

      sint.acabar(); // a sintética "termina" depois de cortada
      expect(await f, FimDaFala.cortada);
      expect(VozIngles.falando.value?.frase, 'Hello.', reason: 'a fala da história não fecha a boca do palco');

      fimPalco.complete(true);
      await q;
      expect(VozIngles.falando.value, isNull);
    });

    test('parar() da própria instância (pular a cena) = cortada; a fala seguinte acaba normal', () async {
      final sint = _Sintetica();
      final voz = VozIngles(falarComPerfil: sint.falar);

      final f = voz.falarNoPlayer('Hello.', fator: 1, perfil: _sarah);
      await pumpEventQueue();
      await voz.parar();
      expect(VozIngles.falando.value, isNull);
      sint.acabar(0);
      expect(await f, FimDaFala.cortada);

      final g = voz.falarNoPlayer('Hello.', fator: 1, perfil: const PerfilVoz(tom: .76));
      await pumpEventQueue();
      sint.acabar(1);
      expect(await g, FimDaFala.acabou);
      expect(sint.falas.map((e) => e.$3), [_sarah, const PerfilVoz(tom: .76)]);
    });

    test('a próxima fala da mesma instância corta a anterior (o roteiro avançando)', () async {
      final sint = _Sintetica();
      final voz = VozIngles(falarComPerfil: sint.falar);

      final a = voz.falarNoPlayer('Hello.', fator: 1, perfil: _sarah);
      await pumpEventQueue();
      final b = voz.falarNoPlayer('Nice to meet you.', fator: 1, perfil: const PerfilVoz(tom: .88));
      await pumpEventQueue();
      sint.acabar(0);
      expect(await a, FimDaFala.cortada);
      expect(VozIngles.falando.value?.frase, 'Nice to meet you.', reason: 'a 1ª não fecha a boca da 2ª');
      sint.acabar(1);
      expect(await b, FimDaFala.acabou);
      expect(VozIngles.falando.value, isNull);
    });

    test('a voz sintética que lança não derruba o player (acabou, boca fechada)', () async {
      final voz = VozIngles(falarComPerfil: (_, _, _) async => throw StateError('sem TTS'));
      expect(await voz.falarNoPlayer('Hello.', fator: 1, perfil: _sarah), FimDaFala.acabou);
      expect(VozIngles.falando.value, isNull);
    });

    test('sem injeção (plataforma de teste, voz muda): completa e nunca toca o áudio do aluno', () async {
      var clipes = 0;
      final voz = VozIngles(tocarClipe: (_, _, _) async {
        clipes++;
        return true;
      });
      final anuncios = _ouvirAnuncios(addTearDown);
      expect(await voz.falarNoPlayer('Hello.', fator: 1, perfil: _sarah), FimDaFala.acabou);
      expect(clipes, 0);
      expect(anuncios.map((a) => a.gravacao), [false]);
      expect(VozIngles.falando.value, isNull);
    });
  });

  group('falarNoPlayer sem perfil (o caminho de hoje)', () {
    test('o áudio do aluno vem na frente, na velocidade do fator; a sintética do perfil nunca é chamada', () async {
      final clipes = <double>[];
      var sinteticas = 0;
      final voz = VozIngles(
        tocarClipe: (_, _, v) async {
          clipes.add(v);
          return true;
        },
        falarComPerfil: (_, _, _) async => sinteticas++,
      );
      final anuncios = _ouvirAnuncios(addTearDown);
      expect(await voz.falarNoPlayer('Hello.', fator: 1.15), FimDaFala.acabou);
      expect(clipes, [1.15]);
      expect(sinteticas, 0);
      expect(anuncios, hasLength(1));
      expect(
        anuncios.single.boca.duracao,
        closeTo(TrilhaBoca.doTexto('Hello.', segPorPalavra: VozIngles.segPorPalavra / 1.15 * .8).duracao, 1e-9),
      );
    });

    test('frase com mp3: anuncia a boca do mp3 (gravação) antes da sintética de reserva', () async {
      var sinteticas = 0;
      final voz = VozIngles(falarComPerfil: (_, _, _) async => sinteticas++);
      final anuncios = _ouvirAnuncios(addTearDown);
      expect(await voz.falarNoPlayer('Nice to meet you.', fator: 1), FimDaFala.acabou);
      expect(sinteticas, 0);
      // na VM o mp3 não toca (sem player): a sintética comum assume, como sempre
      expect(anuncios.map((a) => a.gravacao), [true, false]);
      expect(anuncios.first.boca.duracao, TrilhaBoca.compacta(_bocaMp3).duracao);
    });

    test('cortada por outra VozIngles continua cortada', () async {
      final fim = Completer<bool>();
      final player = VozIngles(tocarClipe: (_, _, _) => fim.future);
      final f = player.falarNoPlayer('Hello.', fator: 1);
      await pumpEventQueue();
      await VozIngles().falar('Sem áudio.');
      fim.complete(true);
      expect(await f, FimDaFala.cortada);
    });
  });

  group('ordemVozesEnUs (a variante do perfil)', () {
    test('só en-US que servem, da melhor para a pior; empate = a ordem da lista', () {
      final vozes = [
        ('Samantha', 'en-US', true), // 0: 50+10+5 = 65
        ('Google UK English Female', 'en-GB', false), // 1: fora (não é en-US)
        ('Microsoft Ava Online (Natural) - English (United States)', 'en-US', false), // 2: 110
        ('Zarvox', 'en-US', true), // 3: voz de efeito (nota 0): fora
        ('Luciana', 'pt-BR', true), // 4: fora
        ('Google US English', 'en_US', false), // 5: 90
        ('Microsoft Andrew Online (Natural) - English (United States)', 'en-US', false), // 6: 110 (empata com 2)
        ('Alex', 'EN-us', true), // 7: 70+10+5 = 85
      ];
      expect(ordemVozesEnUs(vozes), [2, 6, 5, 7, 0]);
    });

    test('lista vazia ou sem en-US: nenhuma variante (cai na melhor)', () {
      expect(ordemVozesEnUs(const []), isEmpty);
      expect(ordemVozesEnUs(const [('Daniel', 'en-GB', true), ('Luciana', 'pt-BR', true)]), isEmpty);
    });
  });
}
