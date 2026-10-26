import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/roteiro.dart';

/// 🪜 As etapas da lição (~12 digitações cada, como o Duolingo) e a fila salva para continuar depois.
void main() {
  group('EtapasDaLicao', () {
    test('8 frases (40 digitações) = 3 etapas de ~13; 12 frases (60) = 5 de 12; lição curta = 1', () {
      final e40 = EtapasDaLicao.deFrases(8);
      expect(e40.total, 40);
      expect(e40.quantas, 3);
      expect([e40.fimDa(0), e40.fimDa(1)], [13, 27]);
      final e60 = EtapasDaLicao.deFrases(12);
      expect(e60.quantas, 5);
      expect([for (var k = 0; k < 4; k++) e60.fimDa(k)], [12, 24, 36, 48]);
      expect(EtapasDaLicao.deFrases(2).quantas, 1);
    });

    test('etapaDe, inicioDa e fechouEtapa (a última nunca "fecha": é o fim da lição)', () {
      final e = EtapasDaLicao.deFrases(8);
      expect([e.etapaDe(0), e.etapaDe(12), e.etapaDe(13), e.etapaDe(26), e.etapaDe(27), e.etapaDe(99)], [0, 0, 1, 1, 2, 2]);
      expect([e.inicioDa(0), e.inicioDa(1), e.inicioDa(2)], [0, 13, 27]);
      expect(e.fechouEtapa(13), isTrue);
      expect(e.fechouEtapa(27), isTrue);
      expect(e.fechouEtapa(14), isFalse);
      expect(e.fechouEtapa(40), isFalse);
      expect(e.fechouEtapa(0), isFalse);
    });

    test('toda etapa fica entre 10 e 15 digitações nas lições do curso (8 a 14 frases)', () {
      for (var frases = 8; frases <= 14; frases++) {
        final e = EtapasDaLicao.deFrases(frases);
        for (var k = 0; k < e.quantas; k++) {
          final tam = (k == e.quantas - 1 ? e.total : e.fimDa(k)) - e.inicioDa(k);
          expect(tam, inInclusiveRange(10, 15), reason: '$frases frases, etapa $k: $tam');
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
}
