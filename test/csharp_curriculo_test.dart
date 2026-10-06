import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/util/programa_csharp.dart';
import 'package:pac_dart/features/arcade/domain/banco_curriculo.dart';
import 'package:pac_dart/features/arcade/domain/desafio.dart';
import 'package:pac_dart/features/arcade/domain/palavras_csharp.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/domain/quiz.dart';

/// O currículo do PAC·C# (assets/csharp/curriculo.json). Cada lição dele foi
/// compilada e executada pelo laboratório Roslyn (ver ESTADO-DO-PROJETO.md,
/// seção PAC·C#); aqui o app confere que o asset chegou inteiro e coerente.
void main() {
  final bruto = jsonDecode(File('assets/csharp/curriculo.json').readAsStringSync()) as List;
  final trilhas = bruto.map((e) => Trilha.fromJson(e as Map<String, dynamic>)).toList();

  final digitaveis = <String>{
    for (var c = 0x20; c < 0x7F; c++) String.fromCharCode(c),
    '\n',
    ...'áàâãéêíóôõúüçÁÀÂÃÉÊÍÓÔÕÚÜÇ'.split(''),
  };

  const nomesDart = {
    'Fundamentos', 'Lógica', 'Coleções', 'Objetos', 'Avançado', 'Flutter', 'Desafios', 'Pacotes',
    'Dart Moderno', 'Assíncrono', 'Testes', 'Navegação', 'Animações', 'Layout Pro', 'Rede e APIs',
    'Persistência', 'Arquitetura', 'Pacotes II', 'Dart Idiomático', 'Coleções Pro',
    'Formulários e Gestos', 'Estado Avançado', 'UI e Material 3', 'Cupertino iOS', 'Firebase',
    'Erros e Exceções', 'Datas e Texto', 'Ciclo de Vida', 'Widgets Avançados', 'Debug e Performance',
    'Plataforma Nativa', 'i18n e Acessibilidade',
  };

  test('pelo menos o DOBRO dos exercícios do Dart (2.354 → 4.708)', () {
    final ex = trilhas.fold<int>(0, (s, t) => s + t.licoes.fold<int>(0, (a, l) => a + l.trechos.length));
    expect(ex, greaterThanOrEqualTo(4708));
  });

  test('etapas em ordem (Iniciante → Sênior), nomes únicos e diferentes dos do Dart', () {
    const etapas = ['Iniciante', 'Intermediário', 'Avançado', 'Sênior'];
    var anterior = 0;
    final nomes = <String>{};
    for (final t in trilhas) {
      final i = etapas.indexOf(t.etapa);
      expect(i, greaterThanOrEqualTo(anterior), reason: '${t.nivel} (${t.etapa}) fora de ordem');
      anterior = i;
      expect(nomes.add(t.nivel), isTrue, reason: 'trilha repetida: ${t.nivel}');
      expect(nomesDart.contains(t.nivel), isFalse, reason: '${t.nivel} colide com a vertente Dart');
      expect(const ['console', 'web', 'testes', 'biblioteca', 'unity', 'godot', 'monogame'], contains(t.perfil));
    }
    expect(etapas.every((e) => trilhas.any((t) => t.etapa == e)), isTrue);
  });

  test('toda lição tem resumo, teoria com código e exercícios; o quiz consegue perguntas', () {
    for (final (ti, t) in trilhas.indexed) {
      expect(t.licoes, isNotEmpty, reason: t.nivel);
      final pool = t.licoes.expand((l) => l.trechos.map((e) => e.cod)).toList();
      for (final (li, l) in t.licoes.indexed) {
        final onde = '${t.nivel} › ${l.nome}';
        expect(l.resumo, isNotEmpty, reason: onde);
        expect(l.teoria.any((b) => b.tipo == 'code'), isTrue, reason: '$onde sem bloco de código');
        expect(l.trechos.length, greaterThanOrEqualTo(6), reason: onde);
        expect(gerarQuiz(l, pool, seed: ti * 1000 + li), isNotEmpty, reason: '$onde sem quiz');
        for (final tr in l.trechos) {
          expect(tr.dica, isNotEmpty, reason: onde);
          expect(tr.out, isNotEmpty, reason: '$onde: trecho sem saída/descrição');
        }
      }
    }
  });

  test('todo código é digitável num teclado ABNT (sem emoji, °, →, tab…)', () {
    final problemas = <String>[];
    void checa(String cod, String onde) {
      for (final ch in cod.split('').toSet()) {
        if (!digitaveis.contains(ch)) problemas.add('U+${ch.codeUnitAt(0).toRadixString(16)} "$ch" em $onde');
      }
    }

    for (final t in trilhas) {
      for (final l in t.licoes) {
        for (final (k, tr) in l.trechos.indexed) {
          checa(tr.cod, '${t.nivel} › ${l.nome} › $k');
        }
      }
      for (final p in t.projetos) {
        checa(p.cod, '${t.nivel} › projeto ${p.nome}');
      }
    }
    expect(problemas, isEmpty, reason: problemas.take(20).join('\n'));
  });

  test('o botão "copiar" monta um programa para cada trecho de cada lição', () {
    for (final t in trilhas) {
      for (final l in t.licoes) {
        final cods = <String>[];
        for (final tr in l.trechos) {
          if (!tr.ehCodigoDoCurso) continue;
          cods.add(tr.cod);
          final p = programaCSharp(cods);
          expect(p.contains(tr.cod.split('\n').first.trim()), isTrue, reason: '${t.nivel} › ${l.nome}');
        }
      }
    }
  });

  test('desafios de lógica bem formados, com jogos e dos 6 tipos', () {
    var total = 0, jogos = 0;
    final tipos = <TipoDesafioLogica>{};
    for (final t in trilhas) {
      for (final d in t.desafios) {
        total++;
        if (d.ehJogo) jogos++;
        tipos.add(d.tipo);
        final onde = '${t.nivel} › ${d.titulo}';
        expect(d.enunciado, isNotEmpty, reason: onde);
        expect(d.explicacao, isNotEmpty, reason: onde);
        expect(d.nivel, inInclusiveRange(1, 3), reason: onde);
        switch (d.tipo) {
          case TipoDesafioLogica.saida:
          case TipoDesafioLogica.lacuna:
            expect(d.opcoes.length, 4, reason: onde);
            expect(d.certa, inInclusiveRange(0, 3), reason: onde);
            if (d.tipo == TipoDesafioLogica.lacuna) expect(d.cod, contains('___'), reason: onde);
          case TipoDesafioLogica.escolha:
            expect(d.opcoes.length, inInclusiveRange(2, 4), reason: onde);
            expect(d.certa, lessThan(d.opcoes.length), reason: onde);
          case TipoDesafioLogica.valor:
            expect(d.resposta, isNotEmpty, reason: onde);
          case TipoDesafioLogica.ordenar:
            expect(d.linhas.length, inInclusiveRange(4, 10), reason: onde);
            expect(d.esperado, isNotEmpty, reason: onde);
          case TipoDesafioLogica.bug:
            expect(d.linhaBug, inInclusiveRange(0, d.linhas.length - 1), reason: onde);
            expect(d.correcao, isNotEmpty, reason: onde);
        }
      }
    }
    expect(total, greaterThanOrEqualTo(trilhas.length * 12));
    expect(jogos, greaterThanOrEqualTo(total ~/ 4));
    expect(tipos, TipoDesafioLogica.values.toSet());
  });

  test('o Arcade no modo C# tem desafios de lógica, de sintaxe e bugs do currículo', () {
    final banco = desafiosDoCurriculo(trilhas);
    expect(banco.where((d) => d.tipo == TipoDesafio.logica).length, greaterThan(50));
    expect(banco.where((d) => d.tipo == TipoDesafio.sintaxe).length, greaterThan(30));
    expect(banco.every((d) => d.opcoes.length == 3 && d.certa == 0), isTrue);
    for (final n in [1, 2, 3]) {
      expect(banco.any((d) => d.nivel == n), isTrue, reason: 'sem desafio de nível $n');
    }
    expect(bugsDoCurriculo(trilhas).length, greaterThan(30));
  });

  test('vocabulário C# dos jogos de digitação: só letras, sem repetição', () {
    final v = vocabularioDe(Linguagem.csharp);
    final todas = [...v.curtas, ...v.medias, ...v.longas];
    expect(todas.toSet().length, todas.length);
    for (final p in todas) {
      expect(RegExp(r'^[A-Za-z]{3,}$').hasMatch(p), isTrue, reason: p);
    }
  });
}
