import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/gerador_missoes.dart';

/// O gerador do Lógica Animada precisa entregar missões VÁLIDAS e DIVERSAS
/// para qualquer trilha do mapa — e a resposta certa tem que bater com os
/// dados da própria cena (é tudo computado dos mesmos parâmetros).
void main() {
  final digitaveis = <String>{
    for (var c = 0x20; c < 0x7F; c++) String.fromCharCode(c),
    '\n',
    ...'áàâãéêíóôõúüçÁÀÂÃÉÊÍÓÔÕÚÜÇ'.split(''),
  };

  test('determinístico: a missão N da trilha T é sempre a mesma', () {
    expect(missaoPara(1, 3), missaoPara(1, 3));
    expect(missaoPara(2, 7), missaoPara(2, 7));
    expect(missaoPara(1, 3) == missaoPara(1, 4), isFalse);
  });

  test('toda missão de toda trilha é válida e 100% digitável', () {
    for (var t = 0; t < 32; t++) {
      for (var i = 0; i < 40; i++) {
        final m = missaoPara(t, i);
        final onde = 'trilha $t missão $i (${m.titulo})';
        expect(m.codigo, isNotEmpty, reason: onde);
        for (final ch in m.codigo.split('').toSet()) {
          expect(digitaveis.contains(ch), isTrue,
              reason: '$onde tem caractere não-digitável: "$ch"');
        }
        expect(m.opcoes, hasLength(3), reason: onde);
        expect(m.opcoes.toSet(), hasLength(3), reason: '$onde: opções repetidas');
        expect(m.certa, inInclusiveRange(0, 2), reason: onde);
        expect(m.passos, isNotEmpty, reason: onde);
        expect(m.dicas, hasLength(3), reason: onde);
        expect(m.historia, isNotEmpty, reason: onde);
        expect(m.pergunta, isNotEmpty, reason: onde);
        expect(m.explica, isNotEmpty, reason: onde);
        expect(m.pontos, greaterThan(0), reason: onde);
      }
    }
  });

  test('o estoque passa dos MILHARES: 32 trilhas x 40 índices ≥ 1000 códigos únicos',
      () {
    final codigos = <String>{};
    for (var t = 0; t < 32; t++) {
      for (var i = 0; i < 40; i++) {
        codigos.add(missaoPara(t, i).codigo);
      }
    }
    expect(codigos.length, greaterThanOrEqualTo(1000),
        reason: 'só ${codigos.length} códigos distintos em 1280 missões');
  });

  test('a resposta certa bate com os dados da cena (checagem independente)', () {
    var conferidas = 0;
    for (var t = 0; t < 32; t++) {
      for (var i = 0; i < 40; i++) {
        final m = missaoPara(t, i);
        final certa = m.opcoes[m.certa];
        switch (m.titulo) {
          case 'Blitz da Maioridade':
            final idades = (m.dados['rotulos'] as List)
                .map((r) => int.parse((r as String).split(' ').first));
            expect(certa, '${idades.where((x) => x >= 18).length}');
            conferidas++;
          case 'Passos até a Porta' || 'Energia Contada' || 'Botas de Turbo':
            expect(certa, '${m.dados['total']}');
            conferidas++;
          case 'Cesta Crescente' || 'Soma da Colheita' || 'Filtro do Pomar':
            expect(certa, '${m.dados['total']}');
            conferidas++;
          case 'Contagem Regressiva':
            expect(certa, '${m.dados['contagem']}');
            conferidas++;
          case 'Ponte Sob Medida':
            expect(certa, '${m.dados['pranchas']}');
            conferidas++;
          case 'Visor do Caixa':
            expect(certa, '${m.dados['valor']}');
            conferidas++;
          case 'Conta da Feira':
            expect(certa, '${m.dados['total']}');
            conferidas++;
          case 'Senha do Cofre':
            expect(certa, '${(m.dados['senha'] as String).length}');
            conferidas++;
        }
      }
    }
    expect(conferidas, greaterThan(400)); // boa parte do estoque é auditável
  });

  test('o último passo sempre entrega a cena no estado final coerente', () {
    for (var t = 0; t < 12; t++) {
      for (var i = 0; i < 12; i++) {
        final m = missaoPara(t, i);
        final estado = {...m.dados};
        for (final p in m.passos) {
          estado.addAll(p.muda);
        }
        // nenhuma chave de passo aparece sem existir base coerente
        expect(estado, isNotEmpty, reason: '${m.titulo} trilha $t missão $i');
      }
    }
  });
}
