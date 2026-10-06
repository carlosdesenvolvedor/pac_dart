import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
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
