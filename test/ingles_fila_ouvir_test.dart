// A fila do "🎧 Ouvir": cada tipo de item vira frases na ordem do diálogo, contra as trilhas do curso
// (refs que quebram caem no retrato ou viram "indisponível"), e a navegação por lição na fila.
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/setlist.dart';

Trecho _t(String id, String cod, {String quem = 'mike'}) => Trecho(cod: cod, dica: 'PT <b>$cod</b>', out: '', id: id, quem: quem);

final _l1 = Licao(nome: 'Oi', emoji: '👋', id: 'contato.oi', trechos: [_t('f-1', 'Hi.'), _t('f-2', 'Hello!'), _t('f-3', 'Bye.')]);
final _l2 = Licao(nome: 'Nomes', emoji: '🪪', id: 'contato.nomes', trechos: [_t('f-4', "I'm Ana."), _t('f-5', 'Nice!')]);
final _l3 = Licao(nome: 'Café', emoji: '☕', id: 'cafe.pedir', trechos: [_t('f-6', 'A coffee, please.'), _t('f-7', 'Sure.')]);
final _l4 = Licao(nome: 'Bugs', emoji: '🐛', id: 'dev.bugs', trechos: [_t('f-8', 'It works on my machine.')]);
final _texto = Licao(
  nome: 'Parte 1',
  emoji: '📝',
  id: 'txt-k1-1',
  trechos: const [Trecho(cod: 'My own line.', dica: 'Minha frase.', out: ''), Trecho(cod: '  ', dica: '', out: '')],
);

final _trilhas = [
  Trilha(nivel: 'Contato', emoji: '🤝', etapa: 'A1 · Fundação', licoes: [_l1, _l2]),
  Trilha(nivel: 'Café', emoji: '☕', etapa: 'A1 · Fundação', licoes: [_l3]),
  Trilha(nivel: 'Dev', emoji: '💻', etapa: 'DEV · Inglês para devs', licoes: [_l4]),
  Trilha(nivel: 'Meu texto', emoji: '📝', etapa: 'Meus textos', textoId: 'k1', licoes: [_texto]),
];

ItemSetlist _i(TipoItem tipo, String ref, {List<String> chaves = const [], String licaoId = '', String en = '', String pt = '', String id = ''}) =>
    ItemSetlist(id: id.isEmpty ? 'i-${tipo.name}-$ref' : id, tipo: tipo, ref: ref, chaves: chaves, licaoId: licaoId, rotulo: ref, en: en, pt: pt, criadoEm: 1);

/// Cada frase dura (a 1×) o número de letras / 10; "gravação" = tem id de curso (cod com ponto final).
FilaOuvir _fila(List<ItemSetlist> itens) => resolverFila(IndiceOuvir.de(_trilhas), itens,
    duracaoDe: (en) => en.length / 10, temGravacao: (en) => en.endsWith('.'));

List<String> _chaves(FilaOuvir f) => [for (final x in f.faixas) x.chave];

void main() {
  test('IndiceOuvir: memoizado pela lista; acha frase, lição, trilha; etapas do curso na ordem', () {
    final ix = IndiceOuvir.de(_trilhas);
    expect(identical(IndiceOuvir.de(_trilhas), ix), isTrue);
    expect(identical(IndiceOuvir.de([..._trilhas]), ix), isFalse);
    final ix2 = IndiceOuvir.de(_trilhas);
    expect(ix2.frase('f-5'), (t: 0, l: 1, f: 1));
    expect(ix2.frase(Revisao.chave('My own line.')), (t: 3, l: 0, f: 0));
    expect(ix2.frase('nada'), isNull);
    expect(ix2.licao('cafe.pedir'), (t: 1, l: 0));
    expect(ix2.licao('txt-k1-1'), (t: 3, l: 0));
    expect(ix2.trilha('tr:contato'), 0);
    expect(ix2.trilha('txt:k1'), 3);
    expect(ix2.etapas, ['A1 · Fundação', 'DEV · Inglês para devs']);
    expect(ix2.trilhas, same(_trilhas));
  });

  test('frase: os dados da faixa vêm da lição (PT sem tags, duração, gravação)', () {
    final f = _fila([_i(TipoItem.frase, 'f-6', licaoId: 'cafe.pedir')]);
    expect(f.faixas, hasLength(1));
    final x = f.faixas.single;
    expect((x.chave, x.en, x.pt, x.quem), ('f-6', 'A coffee, please.', 'PT A coffee, please.', 'mike'));
    expect((x.licaoId, x.licaoNome, x.licaoEmoji, x.trilhaNome, x.etapa), ('cafe.pedir', 'Café', '☕', 'Café', 'A1 · Fundação'));
    expect((x.itemIdx, x.primeiraDaLicao, x.temGravacao), (0, true, true));
    expect(x.segundos, closeTo(1.7, 1e-9));
    expect(f.indisponiveis, isEmpty);
  });

  test('frase: licaoId errada cai no índice global; texto do aluno pelo hash', () {
    expect(_chaves(_fila([_i(TipoItem.frase, 'f-4', licaoId: 'cafe.pedir')])), ['f-4']);
    final h = Revisao.chave('My own line.');
    final f = _fila([_i(TipoItem.frase, h)]);
    expect(f.faixas.single.en, 'My own line.');
    expect(f.faixas.single.licaoId, 'txt-k1-1');
  });

  test('frase órfã: o retrato toca (sem lição); sem retrato vai para indisponíveis', () {
    final f = _fila([
      _i(TipoItem.frase, 'f-sumiu', en: 'Gone phrase.', pt: 'Frase que sumiu.', id: 'orfa'),
      _i(TipoItem.frase, 'f-sumiu2', id: 'vazia'),
    ]);
    expect(f.faixas, hasLength(1));
    final x = f.faixas.single;
    expect((x.chave, x.en, x.pt, x.licaoId), ('f-sumiu', 'Gone phrase.', 'Frase que sumiu.', ''));
    expect(x.primeiraDaLicao, isTrue);
    expect(f.indisponiveis, ['vazia']);
    expect(f.inicioDoItem, [0, 1]);
  });

  test('trecho: as escolhidas na ordem da lição; chave sumida fica de fora; todas sumidas → a lição', () {
    expect(_chaves(_fila([_i(TipoItem.trecho, 'contato.oi', chaves: ['f-3', 'f-1', 'f-x'])])), ['f-1', 'f-3']);
    expect(_chaves(_fila([_i(TipoItem.trecho, 'contato.oi', chaves: ['f-x', 'f-y'])])), ['f-1', 'f-2', 'f-3']);
    expect(_fila([_i(TipoItem.trecho, 'sumiu', chaves: ['f-1'], id: 't')]).indisponiveis, ['t']);
  });

  test('lição, trilha (inclui texto do aluno, pulando frase vazia), etapa e curso sem os textos próprios', () {
    expect(_chaves(_fila([_i(TipoItem.licao, 'contato.nomes')])), ['f-4', 'f-5']);
    expect(_chaves(_fila([_i(TipoItem.trilha, 'tr:contato')])), ['f-1', 'f-2', 'f-3', 'f-4', 'f-5']);
    expect(_chaves(_fila([_i(TipoItem.trilha, 'txt:k1')])), [Revisao.chave('My own line.')]);
    expect(_chaves(_fila([_i(TipoItem.licao, 'txt-k1-1')])), hasLength(1));
    expect(_chaves(_fila([_i(TipoItem.etapa, 'A1')])), ['f-1', 'f-2', 'f-3', 'f-4', 'f-5', 'f-6', 'f-7']);
    expect(_chaves(_fila([_i(TipoItem.etapa, 'DEV')])), ['f-8']);
    expect(_chaves(_fila([_i(TipoItem.curso, '')])), ['f-1', 'f-2', 'f-3', 'f-4', 'f-5', 'f-6', 'f-7', 'f-8']);
    final ruins = _fila([_i(TipoItem.licao, 'x', id: 'a'), _i(TipoItem.trilha, 'tr:x', id: 'b'), _i(TipoItem.etapa, 'C2', id: 'c')]);
    expect(ruins.faixas, isEmpty);
    expect(ruins.indisponiveis, ['a', 'b', 'c']);
  });

  test('vários itens: inicioDoItem, itemIdx e primeiraDaLicao', () {
    final f = _fila([
      _i(TipoItem.frase, 'f-2', licaoId: 'contato.oi'), // 0
      _i(TipoItem.frase, 'f-3', licaoId: 'contato.oi'), // 1: mesma lição, não recomeça
      _i(TipoItem.licao, 'sumiu', id: 'x'), // indisponível
      _i(TipoItem.licao, 'contato.oi'), // 2..4: recomeça a lição do começo
      _i(TipoItem.licao, 'cafe.pedir'), // 5..6
    ]);
    expect(_chaves(f), ['f-2', 'f-3', 'f-1', 'f-2', 'f-3', 'f-6', 'f-7']);
    expect(f.inicioDoItem, [0, 1, 2, 2, 5]);
    expect(f.indisponiveis, ['x']);
    expect([for (final x in f.faixas) x.itemIdx], [0, 1, 3, 3, 3, 4, 4]);
    expect([for (final x in f.faixas) x.primeiraDaLicao], [true, false, true, false, false, true, false]);
  });

  test('somas: total, segundosDe (limitado) e fila vazia', () {
    final f = _fila([_i(TipoItem.licao, 'contato.oi')]); // 0.3 + 0.6 + 0.4
    expect(f.segundosTotal, closeTo(1.3, 1e-9));
    expect(f.segundosDe(1), closeTo(1.0, 1e-9));
    expect(f.segundosDe(3), 0);
    expect(f.segundosDe(-5), closeTo(1.3, 1e-9));
    expect(f.segundosDe(99), 0);
    expect(const FilaOuvir().segundosTotal, 0);
  });

  test('indiceDaChave: a dica primeiro, depois a mais perto, senão 0', () {
    final f = _fila([_i(TipoItem.licao, 'contato.oi'), _i(TipoItem.licao, 'contato.nomes'), _i(TipoItem.frase, 'f-1', id: 'r')]);
    // f-1 aparece em 0 e em 5
    expect(f.indiceDaChave('f-1', dica: 5), 5);
    expect(f.indiceDaChave('f-1', dica: 4), 5);
    expect(f.indiceDaChave('f-1', dica: 1), 0);
    expect(f.indiceDaChave('f-5'), 4);
    expect(f.indiceDaChave('nada', dica: 3), 0);
    expect(f.indiceDaChave('f-5', dica: 99), 4);
    expect(const FilaOuvir().indiceDaChave('x'), 0);
  });

  test('navegação por lição: início, próxima (fim = length) e anterior', () {
    final f = _fila([_i(TipoItem.trilha, 'tr:contato'), _i(TipoItem.licao, 'cafe.pedir')]);
    // [f-1 f-2 f-3 | f-4 f-5 | f-6 f-7]
    expect(f.inicioDaLicao(2), 0);
    expect(f.inicioDaLicao(4), 3);
    expect(f.inicioDaLicao(3), 3);
    expect(f.proximaLicao(0), 3);
    expect(f.proximaLicao(3), 5);
    expect(f.proximaLicao(6), 7, reason: 'sem próxima: o fim da fila');
    expect(f.licaoAnterior(4), 0);
    expect(f.licaoAnterior(6), 3);
    expect(f.licaoAnterior(1), 0);
    expect(const FilaOuvir().proximaLicao(0), 0);
    expect(const FilaOuvir().inicioDaLicao(3), 0);
  });

  test('contarFrases bate com a fila', () {
    final ix = IndiceOuvir.de(_trilhas);
    for (final item in [
      _i(TipoItem.frase, 'f-1'),
      _i(TipoItem.frase, 'sumiu', en: 'x'),
      _i(TipoItem.frase, 'sumiu'),
      _i(TipoItem.trecho, 'contato.oi', chaves: ['f-1', 'f-3']),
      _i(TipoItem.trecho, 'contato.oi', chaves: ['f-x']),
      _i(TipoItem.licao, 'txt-k1-1'),
      _i(TipoItem.trilha, 'tr:contato'),
      _i(TipoItem.etapa, 'A1'),
      _i(TipoItem.curso, ''),
    ]) {
      expect(contarFrases(ix, item), _fila([item]).faixas.length, reason: item.assinatura);
    }
  });

  test('formatarDuracao', () {
    expect(formatarDuracao(0), '0 s');
    expect(formatarDuracao(-3), '0 s');
    expect(formatarDuracao(double.nan), '0 s');
    expect(formatarDuracao(38.2), '38 s');
    expect(formatarDuracao(59.4), '59 s');
    expect(formatarDuracao(59.6), '1 min');
    expect(formatarDuracao(240), '4 min');
    expect(formatarDuracao(3600), '1 h');
    expect(formatarDuracao(14280), '3 h 58 min');
  });
}
