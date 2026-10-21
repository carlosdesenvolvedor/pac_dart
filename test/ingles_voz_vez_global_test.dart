import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/data/audio_nativo.dart';
import 'package:pac_dart/features/ingles/data/audio_usuario.dart';
import 'package:pac_dart/features/ingles/data/audio_usuario_repository.dart';
import 'package:pac_dart/features/ingles/data/bocas_ingles.dart';
import 'package:pac_dart/features/ingles/data/escolha_voz.dart';
import 'package:pac_dart/features/ingles/data/saida_voz_ingles.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/boca.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';

/// Um WAV mínimo (o áudio do aluno entra pelo `tocarClipe` injetado — o resto da plataforma é o stub mudo).
Uint8List _wav() {
  final b = Uint8List(64);
  b.setRange(0, 4, 'RIFF'.codeUnits);
  b.setRange(8, 12, 'WAVE'.codeUnits);
  return b;
}

/// Um "player do aluno" que só termina quando o teste manda.
class _Clipe {
  final tocadas = <(String, double)>[];
  final _fins = <Completer<bool>>[];
  int _n = 0;

  Future<bool> tocar(Uint8List bytes, String mime, double v) {
    tocadas.add(('clipe${_n++}', v));
    final c = Completer<bool>();
    _fins.add(c);
    return c.future;
  }

  void acabar([int i = 0]) => _fins[i].complete(true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AudioUsuario.limpar();
    AudioNativo.limpar();
    BocasIngles.limpar();
    VozIngles.falando.value = null;
    await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
    await AudioUsuario.adicionar('Hello.', _wav());
    await AudioUsuario.adicionar('Other.', _wav());
  });

  tearDown(() {
    AudioUsuario.limpar();
    AudioNativo.limpar();
    BocasIngles.limpar();
    VozIngles.lentaPorPadrao = true;
    VozIngles.falando.value = null;
  });

  group('VozIngles.vezGlobal', () {
    test('sobe na hora (antes de qualquer await) em falar, parar com fala em curso, falarNoPlayer, falarPt e silencio',
        () {
      final a = VozIngles(), b = VozIngles();
      final g0 = VozIngles.vezGlobal;
      unawaited(a.falar('Sem áudio.'));
      expect(VozIngles.vezGlobal, g0 + 1);
      unawaited(b.parar());
      expect(VozIngles.vezGlobal, g0 + 1, reason: 'b não falava nada: o parar dele não corta ninguém');
      unawaited(a.parar());
      expect(VozIngles.vezGlobal, g0 + 2, reason: 'a ainda falava: o parar dele corta de verdade');
      unawaited(a.falarNoPlayer('Sem áudio.', fator: 1));
      unawaited(a.falarPt('Olá.'));
      unawaited(a.silencio(Duration.zero));
      expect(VozIngles.vezGlobal, g0 + 5);
      unawaited(b.calarTudo());
      expect(VozIngles.vezGlobal, g0 + 6, reason: 'calarTudo corta mesmo sem fala própria (o microfone)');
    });

    test('o parar() de uma página que não falou nada (dispose) NÃO corta o player', () async {
      final clipe = _Clipe();
      final player = VozIngles(tocarClipe: clipe.tocar);
      final pagina = VozIngles();

      final f = player.falarNoPlayer('Hello.', fator: 1);
      await pumpEventQueue();
      await pagina.parar(); // o baralho / a leitura fechando sem ter falado
      expect(VozIngles.falando.value?.frase, 'Hello.', reason: 'a boca do player segue mexendo');
      clipe.acabar();
      expect(await f, FimDaFala.acabou);

      final s = player.silencio(const Duration(milliseconds: 30));
      await pagina.parar();
      expect(await s, FimDaFala.acabou);

      // a página que já acabou de falar também não corta mais nada
      await pagina.falar('Sem áudio.');
      final s2 = player.silencio(const Duration(milliseconds: 30));
      await pagina.parar();
      expect(await s2, FimDaFala.acabou);
    });

    test('o parar() de quem ainda fala corta o player; calarTudo corta mesmo sem fala própria', () async {
      final clipe = _Clipe(), clipePalco = _Clipe();
      final player = VozIngles(tocarClipe: clipe.tocar);
      final palco = VozIngles(tocarClipe: clipePalco.tocar);

      final f = player.falarNoPlayer('Hello.', fator: 1);
      await pumpEventQueue();
      final q = palco.falar('Other.'); // já corta o player ao começar
      await pumpEventQueue();
      await palco.parar();
      expect(VozIngles.falando.value, isNull);
      clipe.acabar(0);
      clipePalco.acabar(0);
      await q;
      expect(await f, FimDaFala.cortada);

      final s = player.silencio(const Duration(milliseconds: 30));
      await VozIngles().calarTudo();
      expect(await s, FimDaFala.cortada);
    });

    test('falarNoPlayer: ninguém no meio = acabou; outra VozIngles falou no meio = cortada', () async {
      final clipe = _Clipe();
      final player = VozIngles(tocarClipe: clipe.tocar);

      final sozinho = player.falarNoPlayer('Hello.', fator: 1);
      await pumpEventQueue();
      clipe.acabar(0);
      expect(await sozinho, FimDaFala.acabou);

      final cortado = player.falarNoPlayer('Hello.', fator: 1);
      await pumpEventQueue();
      await VozIngles().falar('Sem áudio.'); // o palco / o 🔊 de um cartão
      clipe.acabar(1);
      expect(await cortado, FimDaFala.cortada);
    });

    test('parar() da própria instância (o player pausando) também devolve cortada', () async {
      final clipe = _Clipe();
      final player = VozIngles(tocarClipe: clipe.tocar);
      final f = player.falarNoPlayer('Hello.', fator: 1);
      await pumpEventQueue();
      await player.parar();
      clipe.acabar();
      expect(await f, FimDaFala.cortada);
    });

    test('a velocidade do player ignora lentaPorPadrao (a lenta continua valendo para o resto)', () async {
      VozIngles.lentaPorPadrao = true;
      final rates = <double>[];
      final voz = VozIngles(tocarClipe: (_, _, v) async {
        rates.add(v);
        return true;
      });
      await voz.falarNoPlayer('Hello.', fator: 1.15);
      await voz.falarNoPlayer('Hello.', fator: .75);
      await voz.falar('Hello.');
      expect(rates, [1.15, .75, VozIngles.velocidadeGravadaLenta]);
    });

    test('o player cortado NÃO fecha a boca de quem o cortou', () async {
      final clipePlayer = _Clipe(), clipePalco = _Clipe();
      final player = VozIngles(tocarClipe: clipePlayer.tocar);
      final palco = VozIngles(tocarClipe: clipePalco.tocar);

      final p = player.falarNoPlayer('Hello.', fator: 1);
      await pumpEventQueue();
      expect(VozIngles.falando.value?.frase, 'Hello.');

      final q = palco.falar('Other.');
      await pumpEventQueue();
      expect(VozIngles.falando.value?.frase, 'Other.');

      clipePlayer.acabar(); // o player "termina" depois de cortado
      expect(await p, FimDaFala.cortada);
      expect(VozIngles.falando.value?.frase, 'Other.', reason: 'a boca do palco segue mexendo');

      clipePalco.acabar();
      await q;
      expect(VozIngles.falando.value, isNull, reason: 'quem falou por último fecha a própria boca');
    });

    test('fala que continuou depois do parar() de OUTRA instância ainda fecha a própria boca no fim', () async {
      final clipe = _Clipe();
      final a = VozIngles(tocarClipe: clipe.tocar);
      final f = a.falar('Hello.');
      // o parar de outra instância chega enquanto o áudio do aluno ainda baixava
      unawaited(VozIngles().parar());
      await pumpEventQueue();
      expect(VozIngles.falando.value?.frase, 'Hello.');
      clipe.acabar();
      await f;
      expect(VozIngles.falando.value, isNull, reason: 'nada de boca "pendurada" (o ticker do rosto não para)');
    });

    test('falarPt sem voz pt-BR (stub) = semVoz e não anuncia boca; silencio acaba ou é cortado', () async {
      final voz = VozIngles();
      expect(await voz.falarPt('Prazer em conhecer.'), FimDaFala.semVoz);
      expect(VozIngles.falando.value, isNull);

      expect(await voz.silencio(const Duration(milliseconds: 5)), FimDaFala.acabou);
      expect(VozIngles.falando.value, isNull);

      final s = voz.silencio(const Duration(milliseconds: 30));
      await VozIngles().falar('Sem áudio.');
      expect(await s, FimDaFala.cortada);
    });
  });

  group('duração e pré-aquecimento', () {
    test('duracaoDe: a última marca da boca do mp3; sem mp3, palavras × segPorPalavra', () {
      AudioNativo.registrarGeradas({'Nice to meet you.': 'assets/ingles/voz/abc.mp3'});
      BocasIngles.registrar({'assets/ingles/voz/abc.mp3': '0X 20C 27B 150F 222X'});
      expect(VozIngles.duracaoDe('Nice to meet you.'), closeTo(2.22, 1e-9));
      expect(VozIngles.duracaoDe('one two  three'), closeTo(3 * VozIngles.segPorPalavra, 1e-9));
      expect(VozIngles.duracaoDe(''), 0);
      // pré-aquecer fora do navegador não faz nada e não lança
      VozIngles.preaquecer('Nice to meet you.');
      VozIngles.preaquecer('sem mp3');
    });

    test('BocasIngles.duracaoDe lê só o fim da string (igual à trilha montada) e tolera lixo', () {
      BocasIngles.registrar({
        'a.mp3': '0X 9B 15E 41C 104A 221X 225X ',
        'b.mp3': '0X 10D ??',
        'c.mp3': '',
      });
      expect(BocasIngles.duracaoDe('a.mp3'), TrilhaBoca.compacta('0X 9B 15E 41C 104A 221X 225X').duracao);
      expect(BocasIngles.duracaoDe('b.mp3'), isNull);
      expect(BocasIngles.duracaoDe('c.mp3'), isNull);
      expect(BocasIngles.duracaoDe('nao-existe.mp3'), isNull);
      expect(BocasIngles.duracaoDe(null), isNull);
      // já montada: a mesma resposta
      BocasIngles.de('a.mp3');
      expect(BocasIngles.duracaoDe('a.mp3'), 2.25);
    });

    test('SaidaVozIngles entrega duração e gravação do VozIngles / AudioNativo / áudio do aluno', () async {
      AudioNativo.registrarGeradas({'Nice to meet you.': 'assets/ingles/voz/abc.mp3'});
      BocasIngles.registrar({'assets/ingles/voz/abc.mp3': '0X 222X'});
      final s = SaidaVozIngles(voz: VozIngles(tocarClipe: (_, _, _) async => true));
      expect(s.duracaoDe('Nice to meet you.'), closeTo(2.22, 1e-9));
      expect(s.temGravacao('Nice to meet you.'), isTrue);
      expect(s.temGravacao('Hello.'), isTrue, reason: 'o áudio do aluno conta');
      expect(s.temGravacao('Só a voz do sistema.'), isFalse);
      expect(await s.en('Hello.', fator: 1), FimDaFala.acabou);
      expect(await s.pt('Olá.', fator: 1), FimDaFala.semVoz);
      expect(await s.silencio(Duration.zero), FimDaFala.acabou);
      s.parar();
      s.preaquecer('Nice to meet you.');
    });
  });

  group('notaDaVoz', () {
    test('inglês continua igual; pt-BR pontua Francisca/Antonio > Google > Luciana > pt-PT', () {
      expect(notaDaVoz('Google US English', 'en-US'), 90);
      expect(notaDaVoz('Microsoft Ava Online (Natural) - English (United States)', 'en-US'), 110);
      expect(notaDaVoz('Luciana', 'pt-BR'), -1, reason: 'o padrão é inglês');

      final francisca = notaDaVoz('Microsoft Francisca Online (Natural) - Portuguese (Brazil)', 'pt-BR', idioma: 'pt');
      final antonio = notaDaVoz('Microsoft Antonio Online (Natural) - Portuguese (Brazil)', 'pt_BR', idioma: 'pt');
      final google = notaDaVoz('Google português do Brasil', 'pt-BR', idioma: 'pt');
      final luciana = notaDaVoz('Luciana', 'pt-BR', idioma: 'pt');
      final joana = notaDaVoz('Joana', 'pt-PT', idioma: 'pt');
      expect(francisca, 110);
      expect(antonio, 110);
      expect(francisca > google && google > luciana && luciana > joana, isTrue);
      expect(notaDaVoz('Google US English', 'en-US', idioma: 'pt'), -1);
      expect(notaDaVoz('Luciana', 'pt-BR', local: true, idioma: 'pt'), luciana + 5);
    });
  });
}
