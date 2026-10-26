import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/domain/mapa_regras.dart';
import 'package:pac_dart/features/curso/presentation/pages/mapa/no_3d.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/roteiro.dart';

/// 🪜 As partes (sub-lições) da lição (~10 digitações cada, como o Duolingo), a fila salva para continuar depois e
/// o anel das partes no nó do mapa.
void main() {
  setUpAll(() => EtapasDaLicao.ligadas = true);
  tearDownAll(() => EtapasDaLicao.ligadas = false);
  group('EtapasDaLicao', () {
    test('8 frases (40 digitações) = 4 partes de 10; 12 frases (60) = 6 de 10; lição curta = 1', () {
      final e40 = EtapasDaLicao.deFrases(8);
      expect(e40.total, 40);
      expect(e40.quantas, 4);
      expect([e40.fimDa(0), e40.fimDa(1), e40.fimDa(2)], [10, 20, 30]);
      final e60 = EtapasDaLicao.deFrases(12);
      expect(e60.quantas, 6);
      expect([for (var k = 0; k < 5; k++) e60.fimDa(k)], [10, 20, 30, 40, 50]);
      expect(EtapasDaLicao.deFrases(1).quantas, 1);
    });

    test('etapaDe, inicioDa e fechouEtapa (a última nunca "fecha": é o fim da lição)', () {
      final e = EtapasDaLicao.deFrases(8);
      expect([e.etapaDe(0), e.etapaDe(9), e.etapaDe(10), e.etapaDe(29), e.etapaDe(30), e.etapaDe(99)], [0, 0, 1, 2, 3, 3]);
      expect([e.inicioDa(0), e.inicioDa(1), e.inicioDa(3)], [0, 10, 30]);
      expect(e.fechouEtapa(10), isTrue);
      expect(e.fechouEtapa(30), isTrue);
      expect(e.fechouEtapa(11), isFalse);
      expect(e.fechouEtapa(40), isFalse);
      expect(e.fechouEtapa(0), isFalse);
    });

    test('toda parte fica com ~10 digitações (de 9 a 11) nas lições do curso (8 a 14 frases)', () {
      for (var frases = 8; frases <= 14; frases++) {
        final e = EtapasDaLicao.deFrases(frases);
        for (var k = 0; k < e.quantas; k++) {
          final tam = (k == e.quantas - 1 ? e.total : e.fimDa(k)) - e.inicioDa(k);
          expect(tam, inInclusiveRange(9, 11), reason: '$frases frases, parte $k: $tam');
        }
      }
    });
  });

  group('FilaLicao salva e retomada', () {
    /// Responde o passo: cópia sem nota; o resto acerta, menos as frases em [erra] na 1ª vez de memória.
    void responde(FilaLicao f, {Set<int> erra = const {}}) {
      final p = f.atual!;
      final r = p.modo == ModoFrase.ver
          ? null
          : (erra.contains(p.frase) && p.vez == 4 ? ResultadoRevisao.errou : ResultadoRevisao.acertou);
      f.registrar(r);
    }

    test('parar no fim da 1ª etapa e continuar dá exatamente a mesma lição (passos, nota, difíceis)', () {
      const erra = {2, 5};
      final inteira = FilaLicao(8, semente: 42);
      final parte = FilaLicao(8, semente: 42);
      final et = EtapasDaLicao.deFrases(8);
      final seq1 = <String>[], seq2 = <String>[];
      while (parte.feitos < et.fimDa(0)) {
        seq1.add('${inteira.atual}');
        seq2.add('${parte.atual}');
        responde(inteira, erra: erra);
        responde(parte, erra: erra);
      }
      final json = parte.toJson();
      final retomada = FilaLicao.fromJson(json, 8)!;
      expect(retomada.feitos, et.fimDa(0));
      while (!inteira.terminou) {
        seq1.add('${inteira.atual}');
        seq2.add('${retomada.atual}');
        responde(inteira, erra: erra);
        responde(retomada, erra: erra);
      }
      expect(retomada.terminou, isTrue);
      expect(seq2, seq1);
      expect(retomada.nota, inteira.nota);
      expect(retomada.primeiraProva, inteira.primeiraProva);
      expect(retomada.dificeis, inteira.dificeis);
    });

    test('salva de outra lição (outro tamanho) ou estragada: não retoma', () {
      final f = FilaLicao(8);
      expect(FilaLicao.fromJson(f.toJson(), 10), isNull);
      expect(FilaLicao.fromJson({'v': 1, 'n': 8}, 8), isNull);
      expect(FilaLicao.fromJson({'v': 9}, 8), isNull);
    });
  });

  testWidgets('o nó do mapa ganha o anel das partes (2+ partes, fora da feita e da trancada) e o leitor diz quantas', (tester) async {
    Mixart.usarGoogleFonts = false;
    Future<void> no(EstadoNo e, {int partes = 4, int feitas = 2}) => tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Center(
              child: No3D(emoji: '☕', estado: e, cor: Colors.green, onTap: () {}, rotulo: 'Café', partes: partes, partesFeitas: feitas),
            ),
          ),
        ));
    await no(EstadoNo.disponivel);
    expect(find.byKey(const Key('no-partes')), findsOneWidget);
    expect(tester.widget<No3D>(find.byType(No3D)).rotuloLido, contains('2 de 4 partes feitas'));
    await no(EstadoNo.feita);
    expect(find.byKey(const Key('no-partes')), findsNothing);
    await no(EstadoNo.trancada);
    expect(find.byKey(const Key('no-partes')), findsNothing);
    await no(EstadoNo.disponivel, partes: 1, feitas: 0);
    expect(find.byKey(const Key('no-partes')), findsNothing);
  });
}
