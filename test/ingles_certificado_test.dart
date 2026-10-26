import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/auth/data/exclusao_de_conta.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/certificado_pdf.dart';
import 'package:pac_dart/features/ingles/data/certificados_repository.dart';
import 'package:pac_dart/features/ingles/domain/certificado.dart';
import 'package:pac_dart/features/ingles/presentation/certificado_page.dart';

/// 🎓 O certificado de conclusão por nível: as regras (Dart puro), o Firestore, o PDF, a página pública de
/// verificação e o cartão do mapa.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final trilhas = [
    for (final t in jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
      Trilha.fromJson(t as Map<String, dynamic>),
  ];
  final c = Certificado(
    codigo: 'PCL-B2-7KQ4-M9XZ',
    uid: 'u1',
    nome: 'Maria José da Conceição',
    nivel: 'B2',
    nomeDoNivel: 'B2 · Desenvoltura',
    emitidoEm: DateTime.utc(2026, 10, 26, 12),
    nota: 85,
    horas: 61,
    licoes: 243,
  );

  group('regras', () {
    test('os 6 níveis do curso têm certificado, cada um fechado pela trilha de revisão', () {
      final n = niveisDoCurso(trilhas);
      expect([for (final x in n) x.codigo], ['A1', 'A2', 'B1', 'B2', 'C1', 'DEV']);
      expect(n[3].trilhaDeRevisao, 'revisao-b2');
      expect(n[3].titulo, 'Desenvoltura');
      expect(n.last.trilhaDeRevisao, 'pro-dia-de-trabalho');
    });

    test('a prova só libera com a revisão do nível feita e 80% das lições', () {
      final b2 = niveisDoCurso(trilhas)[3];
      expect(situacaoDoNivel(trilhas, b2, (_, _) => false).liberaProva, isFalse);
      final tudo = situacaoDoNivel(trilhas, b2, (_, _) => true);
      expect(tudo.liberaProva, isTrue);
      expect(tudo.licoes, greaterThan(200), reason: 'o B2 tem as trilhas de vocabulário');
      // tudo menos a trilha de revisão: não libera
      final semRevisao = situacaoDoNivel(trilhas, b2, (t, _) => slugDaTrilha(trilhas[t]) != 'revisao-b2');
      expect(semRevisao.revisaoFeita, isFalse);
      expect(semRevisao.liberaProva, isFalse);
      // só a revisão: falta o mínimo de lições
      final soRevisao = situacaoDoNivel(trilhas, b2, (t, _) => slugDaTrilha(trilhas[t]) == 'revisao-b2');
      expect(soRevisao.revisaoFeita, isTrue);
      expect(soRevisao.liberaProva, isFalse);
    });

    test('código: formato, letras sem ambiguidade, normalização do que a pessoa digita', () {
      final r = Random(7);
      for (var i = 0; i < 200; i++) {
        final cod = gerarCodigo('B2', r);
        expect(normalizarCodigo(cod), cod);
        expect(cod.substring(7).contains(RegExp('[01OIL]')), isFalse, reason: cod);
      }
      expect(normalizarCodigo(' pcl-b2-7kq4-m9xz '), 'PCL-B2-7KQ4-M9XZ');
      expect(normalizarCodigo('PCL-B3-7KQ4-M9XZ'), isNull);
      expect(normalizarCodigo('PCL-B2-7KQ4-M9X0'), isNull, reason: '0 não existe no alfabeto');
      expect(urlDeVerificacao('https://pac-dart.web.app/', 'PCL-B2-7KQ4-M9XZ'),
          'https://pac-dart.web.app/?certificado=PCL-B2-7KQ4-M9XZ');
    });

    test('nome: nome e sobrenome, só letras; espaços normalizados', () {
      expect(nomeParaCertificado('  Maria   José da Conceição '), 'Maria José da Conceição');
      expect(nomeParaCertificado("Ana D'Ávila"), "Ana D'Ávila");
      expect(nomeParaCertificado('Maria'), isNull);
      expect(nomeParaCertificado('Maria 123'), isNull);
    });

    test('nota: de primeira = 1, com tropeço = ½', () {
      expect(notaDaProva(dePrimeira: 16, comTropeco: 0, total: 20), 80);
      expect(notaDaProva(dePrimeira: 15, comTropeco: 1, total: 20), 78);
      expect(notaDaProva(dePrimeira: 0, comTropeco: 0, total: 0), 0);
    });

    test('carga horária do conteúdo: aulas + 1 min por frase, em horas', () {
      final semAula = horasDoNivel(trilhas, 'B2', (_) => 0);
      final comAula = horasDoNivel(trilhas, 'B2', (_) => 8 * 60);
      expect(semAula, greaterThan(20));
      expect(comAula, greaterThan(semAula + 20));
    });

    test('json ida e volta; o texto não promete proficiência oficial', () {
      final d = Certificado.fromJson(c.codigo, jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>)!;
      expect([d.nome, d.nivel, d.nota, d.horas, d.licoes, d.uid], [c.nome, c.nivel, 85, 61, 243, 'u1']);
      expect(d.emitidoEm, c.emitidoEm);
      expect(textoDeConteudo, isNot(contains('MEC')));
      expect(textoDeConteudo, contains('não é certificado de proficiência'));
      expect(dataPorExtenso(DateTime(2026, 10, 26)), '26 de outubro de 2026');
    });
  });

  group('Firestore', () {
    test('emitir, buscar pelo código e listar os da conta', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreCertificadosRepository(db: db);
      await repo.emitir(c);
      await repo.emitir(Certificado(
          codigo: 'PCL-A1-AAAA-BBBB', uid: 'u2', nome: 'Outra Pessoa', nivel: 'A1', nomeDoNivel: 'A1 · Fundação',
          emitidoEm: DateTime.utc(2026), nota: 90, horas: 30, licoes: 156));
      expect((await repo.buscar('PCL-B2-7KQ4-M9XZ'))!.nome, 'Maria José da Conceição');
      expect(await repo.buscar('PCL-B2-AAAA-AAAA'), isNull);
      expect([for (final x in await repo.daConta('u1')) x.codigo], ['PCL-B2-7KQ4-M9XZ']);
    });

    test('excluir a conta leva os certificados dela (e só os dela)', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('certificados').doc('PCL-B2-7KQ4-M9XZ').set(c.toJson());
      await db.collection('certificados').doc('PCL-A1-AAAA-BBBB').set({...c.toJson(), 'uid': 'u2'});
      await apagarDadosDoUsuario(db, 'u1');
      final sobrou = await db.collection('certificados').get();
      expect([for (final d in sobrou.docs) d.id], ['PCL-A1-AAAA-BBBB']);
    });

    test('as regras: leitura pública por código, criação só do dono, ninguém altera', () {
      final r = File('firestore.rules').readAsStringSync();
      final bloco = r.substring(r.indexOf('match /certificados/{codigo}'));
      expect(bloco, contains('allow get: if true;'));
      expect(bloco, contains('allow update: if false;'));
      expect(bloco, contains('request.resource.data.uid == request.auth.uid'));
      expect(bloco, contains('request.resource.data.nota >= 80'));
    });
  });

  test('o PDF: A4 deitado, com as fontes do app e o QR', () async {
    final bytes = await pdfDoCertificado(c, await FontesDoCertificado.carregar());
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(10000));
    expect(nomeDoArquivo(c), 'certificado-paclingo-b2-PCL-B2-7KQ4-M9XZ.pdf');
  });

  group('página pública de verificação', () {
    testWidgets('código válido: mostra o certificado', (tester) async {
      final repo = MemoriaCertificadosRepository()..docs[c.codigo] = c;
      await tester.pumpWidget(MaterialApp(home: VerificarCertificadoPage('pcl-b2-7kq4-m9xz', repo: repo)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('certificado-valido')), findsOneWidget);
      expect(find.text('Maria José da Conceição'), findsOneWidget);
      expect(find.textContaining('B2 · Desenvoltura'), findsOneWidget);
    });

    testWidgets('código que não existe ou fora do formato: "não encontrado"', (tester) async {
      final repo = MemoriaCertificadosRepository();
      await tester.pumpWidget(MaterialApp(home: VerificarCertificadoPage('PCL-B2-7KQ4-M9XZ', repo: repo)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('certificado-nao-encontrado')), findsOneWidget);
      await tester.pumpWidget(MaterialApp(home: VerificarCertificadoPage('abc', repo: repo, key: UniqueKey())));
      await tester.pumpAndSettle();
      expect(find.textContaining('não tem o formato'), findsOneWidget);
    });
  });

  testWidgets('o cartão do mapa: sem a revisão do nível, diz o que falta (sem botão de prova)', (tester) async {
    Certificados.paraTestes = MemoriaCertificadosRepository();
    addTearDown(() => Certificados.paraTestes = null);
    final st = CursoState(status: CursoStatus.pronto, trilhas: trilhas, linguagem: Linguagem.ingles);
    final b2 = niveisDoCurso(trilhas)[3];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CartaoCertificado(st: st, nivel: b2))));
    await tester.pumpAndSettle();
    expect(find.textContaining('a trilha de revisão do nível'), findsOneWidget);
    expect(find.byKey(const Key('certificado-prova-B2')), findsNothing);
  });
}
