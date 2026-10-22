// 📺❓ O gerador da pergunta de compreensão do fim da historinha da lição: tipos, opções, semente pelo id.
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/assistir/pergunta_compreensao.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/tocando_page.dart' show nomeDeQuem;

Faixa _f(String en, {String pt = '', String quem = ''}) => Faixa(chave: en, en: en, pt: pt, quem: quem);

PerguntaCompreensao? _p(String id, List<Faixa> fs) => perguntaDaLicao(id, fs, nomeDe: nomeDeQuem);

final _cha = [
  _f('Tea with milk, please.', pt: 'Chá com leite, por favor.', quem: 'mike'),
  _f('Here you are.', pt: 'Aqui está.', quem: 'ana'),
  _f('Thank you so much.', pt: 'Muito obrigado.', quem: 'mike'),
];

void main() {
  test('mesma lição → mesma pergunta (determinística); 3 opções distintas e a certa no meio delas', () {
    final a = _p('mesa.cha', _cha)!;
    final b = _p('mesa.cha', _cha)!;
    expect(a.tipo, b.tipo);
    expect(a.enunciado, b.enunciado);
    expect(a.opcoes, b.opcoes);
    expect(a.certa, b.certa);
    expect(a.opcoes, hasLength(3));
    expect(a.opcoes.toSet(), hasLength(3));
    expect(a.certa, inInclusiveRange(0, 2));
  });

  test('ids diferentes variam o tipo e a frase (os dois tipos aparecem)', () {
    final tipos = <TipoPergunta>{};
    final frases = <String>{};
    for (var i = 0; i < 40; i++) {
      final p = _p('licao.$i', _cha)!;
      tipos.add(p.tipo);
      frases.add(p.frase);
    }
    expect(tipos, TipoPergunta.values.toSet());
    expect(frases.length, greaterThan(1));
  });

  test('"Quem disse": a certa é quem fala a frase; com 2 falantes, completa com um canônico de fora', () {
    for (var i = 0; i < 40; i++) {
      final p = _p('quem.$i', _cha)!;
      if (p.tipo != TipoPergunta.quemDisse) continue;
      final dono = _cha.firstWhere((f) => f.en == p.frase).quem;
      expect(p.enunciado, 'Quem disse «${p.frase}»?');
      expect(p.opcoes[p.certa], nomeDeQuem(dono));
      expect(p.opcoes, containsAll(['Mike', 'Ana']));
      final extra = p.opcoes.where((o) => o != 'Mike' && o != 'Ana').single;
      expect(falantesCanonicos.map(nomeDeQuem), contains(extra));
    }
  });

  test('"O que significa": a certa é a tradução da frase; as outras são de outras frases da lição', () {
    var viu = false;
    for (var i = 0; i < 40; i++) {
      final p = _p('sig.$i', _cha)!;
      if (p.tipo != TipoPergunta.significado) continue;
      viu = true;
      final alvo = _cha.firstWhere((f) => f.en == p.frase);
      expect(p.enunciado, 'O que significa «${p.frase}»?');
      expect(p.opcoes[p.certa], alvo.pt);
      expect(p.opcoes.toSet(), _cha.map((f) => f.pt).toSet());
    }
    expect(viu, isTrue);
  });

  test('menos de 3 frases: sem pergunta', () {
    expect(_p('x', _cha.take(2).toList()), isNull);
    expect(_p('x', [..._cha.take(2), _f('  ')]), isNull, reason: 'frase vazia não conta');
  });

  test('um falante só: só "O que significa"', () {
    final fs = [for (final f in _cha) _f(f.en, pt: f.pt, quem: 'voce')];
    for (var i = 0; i < 20; i++) {
      expect(_p('um.$i', fs)!.tipo, TipoPergunta.significado);
    }
  });

  test('narrador sem tradução: sem pergunta; traduções repetidas não servem de opção', () {
    expect(_p('n', [for (final f in _cha) _f(f.en)]), isNull);
    final repetidas = [
      _f('Hi.', pt: 'Oi.'),
      _f('Hello.', pt: 'Oi.'),
      _f('Hey.', pt: 'oi. '),
    ];
    expect(_p('r', repetidas), isNull, reason: 'só 1 tradução distinta');
  });

  test('"Quem disse" não usa frase dita por dois falantes (resposta ambígua)', () {
    final fs = [
      _f('Hi.', quem: 'mike'),
      _f('Hi.', quem: 'ana'),
      _f('Bye.', quem: 'ana'),
    ];
    for (var i = 0; i < 20; i++) {
      final p = _p('amb.$i', fs)!;
      expect(p.tipo, TipoPergunta.quemDisse);
      expect(p.frase, 'Bye.');
      expect(p.opcoes[p.certa], 'Ana');
    }
  });

  test('3+ falantes: as opções saem só dos falantes da lição', () {
    final fs = [
      _f('One.', quem: 'mike'),
      _f('Two.', quem: 'ana'),
      _f('Three.', quem: 'dra-lee'),
      _f('Four.', quem: 'ben'),
    ];
    for (var i = 0; i < 20; i++) {
      final p = _p('tres.$i', fs)!;
      expect(p.tipo, TipoPergunta.quemDisse);
      expect(['Mike', 'Ana', 'Dra. Lee', 'Ben'], containsAll(p.opcoes));
    }
  });
}
