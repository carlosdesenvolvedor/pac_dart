import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/ingles/data/audio_nativo.dart';
import 'package:pac_dart/features/ingles/domain/avaliacao.dart';
import 'package:pac_dart/features/ingles/domain/fonte_frase.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';

/// Auditoria do currículo de inglês integrado (assets/ingles/curriculo.json).
void main() {
  final trilhas = (jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
      .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
      .toList();
  final frases = [
    for (final t in trilhas)
      for (final l in t.licoes)
        for (final f in l.trechos) (t: t, l: l, f: f),
  ];

  test('curso completo: do A1 ao C1 + dev, milhares de frases', () {
    expect(trilhas.length, greaterThanOrEqualTo(100));
    expect(frases.length, greaterThanOrEqualTo(4000));
    final etapas = trilhas.map((t) => t.etapa.split(' ').first).toSet();
    expect(etapas, containsAll(['A1', 'A2', 'B1', 'B2', 'C1']));
  });

  test('toda lição tem resumo e de 5 a 14 frases; a teoria (quando há) é bem formada', () {
    for (final t in trilhas) {
      expect(t.licoes, isNotEmpty, reason: t.nivel);
      for (final l in t.licoes) {
        final onde = '${t.nivel} › ${l.nome}';
        expect(l.resumo, isNotEmpty, reason: onde);
        expect(l.imagem, isNotEmpty, reason: '$onde (sem imagem da cena)');
        expect(l.visualizacao, isNotEmpty, reason: '$onde (sem visualização)');
        expect(l.trechos.length, inInclusiveRange(5, 14), reason: onde);
        for (final b in l.teoria) {
          expect(['h', 'p', 'ex', 'tip', 'warn'], contains(b.tipo), reason: onde);
          if (b.tipo == 'ex') expect(b.conteudo.contains('\n'), isTrue, reason: '$onde: ${b.conteudo}');
        }
      }
    }
  });

  test('toda frase é inglês digitável: ASCII, pontuação final, sem espaço duplo; tradução e alvo certos', () {
    final ascii = RegExp(r'^[\x20-\x7E]+$');
    for (final x in frases) {
      final en = x.f.cod;
      final onde = '${x.t.nivel} › ${x.l.nome}: "$en"';
      expect(ascii.hasMatch(en), isTrue, reason: onde);
      expect(RegExp(r'[.?!]"?$').hasMatch(en), isTrue, reason: onde);
      expect(en.contains('  '), isFalse, reason: onde);
      expect(en, en.trim(), reason: onde);
      expect(x.f.dica.trim(), isNotEmpty, reason: onde);
      if (x.f.alvo.isNotEmpty) expect(en.contains(x.f.alvo), isTrue, reason: '$onde (alvo "${x.f.alvo}")');
      if (x.f.fonte.isNotEmpty) expect(FonteFrase.ler(x.f.fonte), isNotNull, reason: '$onde (fonte ${x.f.fonte})');
      expect(palavrasDe(en), isNotEmpty, reason: onde);
      // âncora visual (IMAGENS.md): toda frase tem a imagem do sentido, sem letras
      expect(x.f.imagem.trim(), isNotEmpty, reason: '$onde (sem img)');
      expect(RegExp(r'[A-Za-z0-9]').hasMatch(x.f.imagem), isFalse, reason: '$onde (img "${x.f.imagem}")');
    }
  });

  test('o motor digita toda frase sem erro, copiando e no modo tolerante (de memória)', () async {
    final bloc = TypingBloc();
    addTearDown(bloc.close);
    for (final x in frases) {
      for (final tolerante in [false, true]) {
        bloc.add(TrechoCarregado(x.f.cod, tolerante: tolerante));
        await Future<void>.delayed(Duration.zero);
        for (final ch in x.f.cod.split('')) {
          if (bloc.state.concluido) break;
          bloc.add(TeclaDigitada(ch));
        }
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.concluido, isTrue, reason: '"${x.f.cod}" (tolerante: $tolerante)');
        expect(bloc.state.errosTrecho, 0, reason: '"${x.f.cod}" (tolerante: $tolerante)');
      }
    }
  }, timeout: const Timeout(Duration(minutes: 3))); // 7 mil frases: passa de 30 s com a máquina ocupada

  // As gravações de nativo do Tatoeba (CC BY-NC-ND / CC BY-NC) não permitem uso comercial e o Paclingo é pago:
  // saíram do app em 26/out/2026. Toda frase toca a voz do personagem.
  test('nenhuma gravação do Tatoeba (licença não comercial) no app: sem "au", sem a pasta, fora do pubspec', () {
    expect(frases.where((x) => x.f.audio.isNotEmpty || x.f.audioCredito.isNotEmpty), isEmpty);
    expect(Directory('assets/ingles/audio').existsSync(), isFalse);
    expect(File('pubspec.yaml').readAsStringSync(), isNot(contains('- assets/ingles/audio/')));
  });

  // Mudou no lote "trocar as vozes" (22/out/2026, decisão do dono): toda frase — inclusive as que têm gravação
  // do Tatoeba ("au") — e todo exemplo da teoria passam a ter a voz do PERSONAGEM; antes a frase com "au" podia
  // ficar sem voz gerada (o Tatoeba tocava no lugar).
  test('voz gerada por personagem: toda frase e todo exemplo da teoria têm a voz do personagem', () {
    final indice = jsonDecode(File(AudioNativo.indiceGeradas).readAsStringSync()) as Map<String, dynamic>;
    final usados = <String>{};
    for (final e in indice.entries) {
      final arq = File(e.value as String);
      expect(arq.existsSync(), isTrue, reason: '"${e.key}" (falta ${e.value})');
      expect(arq.lengthSync(), greaterThan(1000), reason: '"${e.key}" (${e.value} vazio)');
      usados.add(arq.path.split('/').last);
    }
    // Exceção (vozes_google.universo_curso): frase do Tatoeba dita por mais de um personagem (vozes diferentes) fica
    // fora do índice por texto e segue no Tatoeba para todos — senão o Ben falaria com a voz da Ana.
    final falantes = <String, Set<String>>{};
    for (final x in frases) {
      falantes.putIfAbsent(x.f.cod, () => {}).add(x.f.quem);
    }
    final noTatoeba = <String>{};
    for (final x in frases) {
      if (!indice.containsKey(x.f.cod) && x.f.audio.isNotEmpty && falantes[x.f.cod]!.length > 1) {
        noTatoeba.add(x.f.cod);
        continue;
      }
      expect(indice.containsKey(x.f.cod), isTrue, reason: '${x.t.nivel} › ${x.l.nome}: "${x.f.cod}" sem voz do personagem');
    }
    expect(noTatoeba.length, lessThanOrEqualTo(5), reason: '$noTatoeba');
    for (final t in trilhas) {
      for (final l in t.licoes) {
        for (final b in l.teoria.where((b) => b.tipo == 'ex')) {
          final en = b.conteudo.split('\n').first.trim();
          if (noTatoeba.contains(en)) continue;
          expect(indice.containsKey(en), isTrue, reason: '${l.nome}: exemplo "$en" sem voz');
        }
      }
    }
    // toda voz gerada tem a boca do Rhubarb (lip sync)
    final bocas = jsonDecode(File('assets/ingles/bocas.json').readAsStringSync()) as Map<String, dynamic>;
    for (final e in indice.entries) {
      expect(bocas.containsKey(e.value), isTrue, reason: '"${e.key}" (${e.value}) sem boca');
    }
    // nenhum mp3 sobrando e a pasta registrada no pubspec
    final naPasta =
        Directory('assets/ingles/voz').listSync().map((e) => e.path.split('/').last).where((n) => n.endsWith('.mp3'));
    expect(naPasta.toSet().difference(usados), isEmpty);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/ingles/voz/'));
    expect(pubspec, contains('- ${AudioNativo.indiceGeradas}'));
  });

  // Mudou no lote "trocar as vozes" (22/out/2026, decisão do dono: "faça um lote separado para trocar essas
  // vozes"): a prioridade era Tatoeba > personagem; agora a voz do personagem vence e o Tatoeba é só reserva.
  test('o que tocar: voz gerada do personagem > voz sintética', () {
    AudioNativo.limpar();
    addTearDown(AudioNativo.limpar);
    final uma = frases.first.f, outra = frases.last.f;
    AudioNativo.registrarGeradas({uma.cod: 'assets/ingles/voz/x.mp3'});
    expect(AudioNativo.paraTocar(uma.cod), 'assets/ingles/voz/x.mp3');
    expect(AudioNativo.paraTocar(outra.cod), isNull, reason: 'sem voz gerada: a voz sintética do navegador');
    expect(AudioNativo.paraTocar('Not in the course at all.'), isNull);
  });

  test('índice da história: "quem|texto" → mp3; a chave tem quem fala; limpar() esvazia', () {
    AudioNativo.limpar();
    addTearDown(AudioNativo.limpar);
    expect(AudioNativo.daHistoria('max', 'Copy that!'), isNull);
    AudioNativo.registrarHistoria({
      'max|Copy that!': 'assets/ingles/voz_historia/a.mp3',
      'voce|Copy that!': 'assets/ingles/voz_historia/b.mp3',
      'ruim|x': 3,
    });
    expect(AudioNativo.daHistoria('max', 'Copy that!'), 'assets/ingles/voz_historia/a.mp3');
    expect(AudioNativo.daHistoria('voce', 'Copy that!'), 'assets/ingles/voz_historia/b.mp3');
    expect(AudioNativo.daHistoria('max', ' Copy that! '), 'assets/ingles/voz_historia/a.mp3');
    expect(AudioNativo.daHistoria('kim', 'Copy that!'), isNull);
    expect(AudioNativo.totalHistoria, 2);
    expect(AudioNativo.paraTocar('Copy that!'), isNull, reason: 'a história não entra no índice do curso');
    AudioNativo.limpar();
    expect(AudioNativo.totalHistoria, 0);
  });

  test('nenhuma frase repetida dentro de uma trilha; chaves de revisão sem colisão', () {
    for (final t in trilhas) {
      final vistas = <String>{};
      for (final l in t.licoes) {
        for (final f in l.trechos) {
          expect(vistas.add(f.cod.toLowerCase()), isTrue, reason: '${t.nivel}: "${f.cod}" repetida');
        }
      }
    }
    final porChave = <String, String>{};
    for (final x in frases) {
      final k = Revisao.chave(x.f.cod);
      final outra = porChave[k];
      expect(outra == null || outra == x.f.cod, isTrue, reason: 'colisão: "$outra" × "${x.f.cod}"');
      porChave[k] = x.f.cod;
    }
  });
}
