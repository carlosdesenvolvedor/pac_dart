import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/syntax/tokenizer.dart';
import 'package:pac_dart/core/util/programa_csharp.dart';
import 'package:pac_dart/core/util/sharplab.dart';
import 'package:pac_dart/features/curso/data/firestore_progresso_repository.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/conferir_desafio.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Infra da vertente C# (PAC·C#): destaque de sintaxe, o programa que o
/// botão "copiar" monta, a correção dos desafios de lógica e o progresso
/// separado por linguagem.
void main() {
  group('rodar no SharpLab', () {
    test('lzCompressToBase64 é idêntico ao lz-string do JavaScript', () {
      const vetores = [
      // (entrada, saída do lz-string 1.5.0 no Node)
      ("t:run|Console.WriteLine(\"Olá, mundo!\");", "C4LgTgrgdgPgwgeygZwQGwKYDoDqYCWwGAMvlBgBQBEA8mgIcA0ABALbQAmCAhFQJQBuIA=="),
      ("abc", "IYIwxkA="),
      ("", "Q==="),
      ("ááá ç 🎮 teste", "IcgEHPUHg3Dr90BcCmBnJQ=="),
      ("t:run|var x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\nvar x = 1;\n", "C4LgTgrgdgPgbgQzAAgB7ILzIIwG4BQiK6WehSamOBRlpNFJ15xVZtT7jbDr9LdZhx4DOvQVz5Du/YbJnSpkieLGiRcxSvXylqjQuVrNRg3p1bjh/bu0mbls9qA="),
      ("ababababababababababab ababab 12345 !@#", "IYI17SOkAIdgRgEwGYAsBWWBCAAgMRA="),
      ("t:run|decimal preco = 12.5m;\nConsole.WriteLine(\$\"Total: {preco:F2}\");", "C4LgTgrgdgPgJgUwMYEsC2BDANgAgA5jID2OAvDgIwBMAdAKxoDcAUAMJFQDORWCNA6mBTAEAGRRQEACgAkAIgAqRYNhA4A3gWIgAYlQC+cgJSMgA==="),
      ];
      for (final (entrada, saida) in vetores) {
        expect(lzCompressToBase64(entrada), saida, reason: entrada);
      }
    });

    test('URL no modo Run com @ escapado', () {
      final url = urlSharpLab('var p = @"C:\\x";');
      expect(url, startsWith('https://sharplab.io/#v2:'));
      expect(url, 'https://sharplab.io/#v2:${lzCompressToBase64('t:run|var p = @@"C:\\x";')}');
    });

    test('programa para o SharpLab: usings implícitos no topo e cultura pt-BR antes dos comandos', () {
      final p = programaCSharp(['using System.Text;\nvar sb = new StringBuilder("oi");', 'Console.WriteLine(sb);', 'record R(int X);'],
          paraSharpLab: true);
      final linhas = p.split('\n');
      expect(linhas.first, 'using System;');
      expect(linhas.where((l) => l == 'using System.Text;').length, 1);
      final cultura = linhas.indexWhere((l) => l.contains('CultureInfo.CurrentCulture = new("pt-BR")'));
      expect(cultura, greaterThan(linhas.indexOf('using System.Text;')));
      expect(cultura, lessThan(linhas.indexOf('var sb = new StringBuilder("oi");')));
      expect(linhas.indexOf('record R(int X);'), greaterThan(cultura));
      // lição só de tipos: nada para rodar, sem linha de cultura
      expect(programaCSharp(['class A\n{\n}'], paraSharpLab: true), isNot(contains('CultureInfo')));
      expect(temComandosCSharp(['class A\n{\n}']), isFalse);
      expect(temComandosCSharp(['// só comentário', 'int x = 1;']), isTrue);
    });

    test('trechoRodaNoSharpLab junta o contexto da lição', () {
      expect(trechoRodaNoSharpLab(['int x = 1;', 'Console.WriteLine(x);'], 'console'), isTrue);
      expect(trechoRodaNoSharpLab(['class A\n{\n}'], 'console'), isFalse);
      expect(trechoRodaNoSharpLab(['using Dapper;', 'Console.WriteLine(1);'], 'console'), isFalse);
      expect(trechoRodaNoSharpLab(['var app = WebApplication.Create();'], 'web'), isFalse);
    });

    test('só programas de console sem bibliotecas de fora e sem teclado rodam', () {
      expect(rodaNoSharpLab('Console.WriteLine(1);', 'console'), isTrue);
      expect(rodaNoSharpLab('using Microsoft.EntityFrameworkCore;\nConsole.WriteLine(1);', 'console'), isFalse);
      expect(rodaNoSharpLab('var n = Console.ReadLine();', 'console'), isFalse);
      expect(rodaNoSharpLab('Console.WriteLine(1);', 'unity'), isFalse);
      expect(rodaNoSharpLab('using System.Text;\nConsole.WriteLine(1);', 'console'), isTrue);
    });
  });

  group('destaque de sintaxe C#', () {
    List<TokenTipo> cs(String s) => tokenizar(s, linguagem: Linguagem.csharp);

    test('palavras-chave do C# (e não as do Dart)', () {
      const cod = 'foreach (var item in lista) { }';
      final t = cs(cod);
      expect(t[cod.indexOf('foreach')], TokenTipo.keyword);
      expect(t[cod.indexOf('var')], TokenTipo.keyword);
      expect(t[cod.indexOf(' in ') + 1], TokenTipo.keyword);
      expect(t[cod.indexOf('item')], TokenTipo.ident);
      // "final" é palavra do Dart, no C# é só um nome
      expect(cs('final')[0], TokenTipo.ident);
      expect(tokenizar('final', linguagem: Linguagem.dart)[0], TokenTipo.keyword);
    });

    test('string interpolada com aspas dentro do buraco é um literal só', () {
      const cod = r'var s = $"Oi {(ok ? "sim" : "não")}!"; x';
      final t = cs(cod);
      final ini = cod.indexOf(r'$"');
      final fim = cod.lastIndexOf('"');
      for (var i = ini; i <= fim; i++) {
        expect(t[i], TokenTipo.literal, reason: 'posição $i (${cod[i]})');
      }
      expect(t[cod.length - 1], TokenTipo.ident);
    });

    test('verbatim, raw string, char e sufixo de número', () {
      const cod = 'var p = @"C:\\pasta"; var r = """a "b" c"""; char c = \'x\'; decimal d = 9.99m;';
      final t = cs(cod);
      expect(t[cod.indexOf('@"')], TokenTipo.literal);
      expect(t[cod.indexOf('"""') + 5], TokenTipo.literal);
      expect(t[cod.indexOf("'x'") + 1], TokenTipo.literal);
      expect(t[cod.indexOf('9.99m') + 4], TokenTipo.literal);
    });

    test('diretiva de pré-processador pinta como comentário', () {
      final t = cs('#nullable enable\nint x = 1;');
      expect(t[0], TokenTipo.comment);
      expect(t['#nullable enable\n'.length], TokenTipo.keyword); // int
    });

    test('trecho em bash não usa as palavras do C#', () {
      const cod = 'dotnet new console -n Loja # cria';
      final t = tokenizar(cod, linguagem: Linguagem.csharp, variante: 'bash');
      expect(t[0], TokenTipo.ident);
      expect(t[cod.indexOf('#')], TokenTipo.comment);
    });
  });

  group('programa do botão "copiar" (mesma regra do laboratório)', () {
    test('comandos primeiro, tipos no fim, using no topo sem repetir', () {
      final p = programaCSharp([
        'using System.Text;\nvar p = new Ponto(1, 2);',
        'record Ponto(int X, int Y);',
        'using System.Text;\nvar sb = new StringBuilder();\nsb.Append(p);',
        'Console.WriteLine(sb);',
      ]);
      expect(
          p,
          'using System.Text;\n\n'
          'var p = new Ponto(1, 2);\n'
          'var sb = new StringBuilder();\n'
          'sb.Append(p);\n'
          'Console.WriteLine(sb);\n\n'
          'record Ponto(int X, int Y);\n');
    });

    test('if/else partido em linhas continua um comando só; classe com atributo vai pro fim', () {
      final p = programaCSharp([
        'if (x > 1)\n{\n    Console.WriteLine("a");\n}\nelse\n{\n    Console.WriteLine("b");\n}',
        '[Flags]\nenum Cor\n{\n    Azul = 1,\n    Verde = 2\n}',
        'int x = 3;',
      ]);
      final linhas = p.trim().split('\n');
      expect(linhas.first, 'if (x > 1)');
      expect(linhas.indexOf('else'), 4);
      expect(linhas.indexOf('int x = 3;'), lessThan(linhas.indexOf('[Flags]')));
      expect(linhas.last, '}');
    });

    test('namespace de arquivo vira bloco em volta dos tipos do trecho', () {
      final p = programaCSharp(['namespace Loja.Dominio;\n\npublic class Produto\n{\n}']);
      expect(p, 'namespace Loja.Dominio\n{\n\npublic class Produto\n{\n}\n}\n');
    });

    test('função local com static e using var ficam como comando', () {
      final p = programaCSharp([
        'static int Dobro(int n) => n * 2;',
        'using var leitor = new StringReader("oi");',
        'static class Util\n{\n}',
      ]);
      final linhas = p.trim().split('\n');
      expect(linhas[0], 'static int Dobro(int n) => n * 2;');
      expect(linhas[1], 'using var leitor = new StringReader("oi");');
      expect(linhas.last, '}');
      expect(linhas.contains('static class Util'), isTrue);
    });

    test('string com chave e verbatim multilinha não confundem a contagem', () {
      final p = programaCSharp([
        'var json = "{ \\"a\\": 1 }";\nvar txt = @"linha 1\nlinha {2}";',
        'class A\n{\n}',
      ]);
      expect(p.indexOf('var txt'), lessThan(p.indexOf('class A')));
      expect(p.indexOf('linha {2}";'), lessThan(p.indexOf('class A')));
    });

    test('texto de onde colar muda pelo perfil da trilha', () {
      expect(comoRodarCSharp('console'), contains('dotnet new console'));
      expect(comoRodarCSharp('web'), contains('dotnet new web'));
      expect(comoRodarCSharp('unity'), contains('Unity'));
    });
  });

  group('correção dos desafios de lógica', () {
    const valor = DesafioLogica(
      tipo: TipoDesafioLogica.valor,
      titulo: 't',
      enunciado: 'e',
      resposta: '7,5',
    );

    test('número aceita vírgula ou ponto', () {
      expect(confereValor('7,5', valor), isTrue);
      expect(confereValor(' 7.5 ', valor), isTrue);
      expect(confereValor('7', valor), isFalse);
      expect(confereValor('', valor), isFalse);
    });

    test('bool aceita True/true; texto aceita aspas mas é sensível a maiúsculas', () {
      const b = DesafioLogica(tipo: TipoDesafioLogica.valor, titulo: 't', enunciado: 'e', resposta: 'True');
      expect(confereValor('true', b), isTrue);
      expect(confereValor('False', b), isFalse);
      const s = DesafioLogica(tipo: TipoDesafioLogica.valor, titulo: 't', enunciado: 'e', resposta: 'Ana');
      expect(confereValor('"Ana"', s), isTrue);
      expect(confereValor('ana', s), isFalse);
    });

    test('respostas aceitas extras', () {
      const d = DesafioLogica(
          tipo: TipoDesafioLogica.valor, titulo: 't', enunciado: 'e', resposta: '10', aceitas: ['dez']);
      expect(confereValor('dez', d), isTrue);
    });

    test('ordem compara o texto dos cartões (chaves iguais podem trocar)', () {
      const d = DesafioLogica(
        tipo: TipoDesafioLogica.ordenar,
        titulo: 't',
        enunciado: 'e',
        linhas: ['for (int i = 0; i < 2; i++)\n{', '    if (i > 0)\n    {', '        x++;', '    }', '}'],
      );
      expect(confereOrdem(List.of(d.linhas), d), isTrue);
      // as duas chaves de fechamento só diferem na indentação: dá o mesmo programa
      final chaves = List.of(d.linhas);
      final a = chaves[3];
      chaves[3] = chaves[4];
      chaves[4] = a;
      expect(confereOrdem(chaves, d), isTrue);
      // já trocar comandos diferentes muda o programa
      final errada = [d.linhas[0], d.linhas[2], d.linhas[1], d.linhas[3], d.linhas[4]];
      expect(confereOrdem(errada, d), isFalse);
      expect(confereOrdem(d.linhas.take(4).toList(), d), isFalse);
    });

    test('lê o desafio do JSON do currículo', () {
      final d = DesafioLogica.fromJson({
        'tipo': 'bug',
        'titulo': 'Média',
        'enunciado': 'Deveria imprimir 7,5',
        'linhas': ['int a = 7;', 'int b = 8;', 'double m = (a + b) / 2;', 'Console.WriteLine(m);'],
        'linhaBug': 2,
        'correcao': 'double m = (a + b) / 2.0;',
        'esperado': '7,5',
        'explicacao': 'divisão inteira',
        'nivel': 2,
        'tema': 'jogo',
      });
      expect(d.tipo, TipoDesafioLogica.bug);
      expect(d.linhaBug, 2);
      expect(d.ehJogo, isTrue);
      expect(rotuloTipo(d.tipo), 'Ache o bug');
    });
  });

  group('progresso separado por linguagem', () {
    test('Firestore: C# grava com prefixo cs_ no mesmo documento, sem mexer no Dart', () async {
      final db = FakeFirebaseFirestore();
      final dart = FirestoreProgressoRepository('u1', db: db);
      final cs = FirestoreProgressoRepository('u1', db: db, prefixo: Linguagem.csharp.prefixoProgresso);
      await dart.marcarConcluida('0:0');
      await cs.marcarConcluida('0:1');
      await cs.salvarPosicao(3, 4);
      await cs.salvarQuizNota('0:1', 8);
      await cs.marcarProjetoFeito('desafio:0:2');

      expect(await dart.concluidas(), {'0:0'});
      expect(await cs.concluidas(), {'0:1'});
      expect(await dart.posicao(), (0, 0));
      expect(await cs.posicao(), (3, 4));
      expect(await dart.quizNotas(), isEmpty);
      expect(await cs.quizNotas(), {'0:1': 8});
      expect(await cs.projetosFeitos(), {'desafio:0:2'});

      final doc = (await db.collection('users').doc('u1').get()).data()!;
      expect(doc.keys, containsAll(['concluidas', 'cs_concluidas', 'cs_trilha', 'cs_licao', 'cs_quizNotas', 'cs_projetos']));
    });

    test('local: chaves com prefixo', () async {
      SharedPreferences.setMockInitialValues({});
      final dart = LocalProgressoRepository();
      final cs = LocalProgressoRepository(prefixo: 'cs_');
      await dart.marcarConcluida('1:1');
      await cs.marcarConcluida('2:2');
      expect(await dart.concluidas(), {'1:1'});
      expect(await cs.concluidas(), {'2:2'});
    });

    test('a vertente Dart continua sem prefixo (progresso antigo intacto)', () {
      expect(Linguagem.dart.prefixoProgresso, '');
      expect(Linguagem.csharp.prefixoProgresso, 'cs_');
      expect(Linguagem.csharp.curriculo, 'assets/csharp/curriculo.json');
      expect(Linguagem.csharp.rodaveis, isNull);
      expect(Linguagem.porId('csharp'), Linguagem.csharp);
      expect(Linguagem.porId('cobol'), isNull);
    });
  });
}
