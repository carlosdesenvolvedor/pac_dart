import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/ingles/data/textos_repository.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart';
import 'package:pac_dart/features/ingles/domain/cartoes_texto.dart';
import 'package:pac_dart/features/ingles/domain/exportar_anki.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/domain/texto_para_frases.dart';
import 'package:pac_dart/features/ingles/domain/texto_salvo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Loader extends CurriculoLoader {
  final List<Trilha> trilhas;
  _Loader(this.trilhas) : super(linguagem: Linguagem.ingles);
  @override
  Future<List<Trilha>> carregar() async => trilhas;
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

void main() {
  group('prepararCartao (frente em inglês, verso em português)', () {
    test('serve: espaços arrumados, o verso fica como está', () {
      final r = prepararCartao('  I   would like\na coffee, please. ', '  Eu gostaria  de um café, por favor. ');
      expect(r.cartao, const CartaoEscrito('I would like a coffee, please.', 'Eu gostaria de um café, por favor.'));
      expect(r.erro, isNull);
      expect(r.simplificou, isFalse);
    });

    test('a frente vira letras que se digitam (aspas curvas, acento, travessão) e avisa; o verso mantém os acentos', () {
      final r = prepararCartao('She said “it’s a café — really”', 'Ela disse que é um café…');
      expect(r.cartao!.en, 'She said "it\'s a cafe - really"');
      expect(r.cartao!.pt, 'Ela disse que é um café…');
      expect(r.simplificou, isTrue);
    });

    test('rejeita frente sem letra, verso vazio e frente enorme — com o motivo em português', () {
      expect(prepararCartao('', 'x').erro, contains('frente em inglês'));
      expect(prepararCartao('123 !!!', 'x').erro, contains('frente em inglês'));
      expect(prepararCartao('Hello', '   ').erro, contains('verso'));
      expect(prepararCartao('Hello', '').cartao, isNull);
      expect(prepararCartao('a' * 301, 'x').erro, contains('longa demais'));
      expect(prepararCartao('a' * 300, 'x').cartao, isNotNull);
      expect(prepararCartao('日本語', 'x').erro, isNotNull, reason: 'tudo some na simplificação: não sobra letra');
    });
  });

  group('lerListaDeCartoes', () {
    List<CartaoEscrito> le(String t) => lerListaDeCartoes(t).cartoes;

    test('TAB (o arquivo do Anki), ponto e vírgula e barra vertical', () {
      expect(le('I am hungry\tEstou com fome\nWhere is it?\tOnde fica?'), const [
        CartaoEscrito('I am hungry', 'Estou com fome'),
        CartaoEscrito('Where is it?', 'Onde fica?'),
      ]);
      expect(le('I am hungry ; Estou com fome'), const [CartaoEscrito('I am hungry', 'Estou com fome')]);
      expect(le('I am hungry | Estou com fome'), const [CartaoEscrito('I am hungry', 'Estou com fome')]);
    });

    test('vale o PRIMEIRO separador da linha; o resto do verso fica inteiro', () {
      expect(le('Hello ; Olá | oi ; e tchau'), const [CartaoEscrito('Hello', 'Olá | oi ; e tchau')]);
      expect(le('Hello | Olá ; oi'), const [CartaoEscrito('Hello', 'Olá ; oi')]);
      expect(le('Well, it depends; it is hard.\tDepende, é difícil.'), const [CartaoEscrito('Well, it depends; it is hard.', 'Depende, é difícil.')],
          reason: 'com TAB na linha, só o TAB separa');
    });

    test('exportação do Anki: ignora as linhas #…, a coluna de tags, o HTML e as aspas dos campos', () {
      const anki = '#separator:tab\n#html:true\n#tags column:3\n'
          'Nice to meet you.<br>\tPrazer em te conhecer.&nbsp;\tPaclingo::A1\n'
          '"She said ""hi"""\t"Ela disse ""oi"""\ttag\n'
          '<b>Bold</b> &amp; clear\t<i>Negrito</i> &lt;e&gt; claro\n';
      expect(le(anki), const [
        CartaoEscrito('Nice to meet you.', 'Prazer em te conhecer.'),
        CartaoEscrito('She said "hi"', 'Ela disse "oi"'),
        CartaoEscrito('Bold & clear', 'Negrito <e> claro'),
      ]);
    });

    test('linhas ruins são contadas, não derrubam: sem separador, sem verso, sem letra, repetidas, separador no começo', () {
      final r = lerListaDeCartoes('só uma coisa\nOk ; \n123 ; 456\nHi ; Oi\nhi ; Olá\n ; sem frente\n\n   \n# comentário\n');
      expect(r.cartoes, const [CartaoEscrito('Hi', 'Oi')]);
      expect(r.ignoradas, 5, reason: 'sem separador, sem verso, sem letra, repetida e sem frente');
      expect(r.simplificou, isFalse);
      expect(r.cortado, isFalse);
    });

    test('CRLF, acento no inglês (vira simples e avisa) e lista vazia', () {
      final r = lerListaDeCartoes('Café ; Coffee\r\nNaïve ; Ingênuo\r\n');
      expect(r.cartoes.map((c) => c.en), ['Cafe', 'Naive']);
      expect(r.simplificou, isTrue);
      expect(lerListaDeCartoes('').cartoes, isEmpty);
      expect(lerListaDeCartoes('\n\n').ignoradas, 0);
    });

    test('passou do máximo: corta e avisa, mas ainda conta o resto como cortado (não como ignorado)', () {
      final lista = [for (var i = 0; i < 12; i++) 'Sentence ${String.fromCharCode(97 + i)} here ; Frase $i'].join('\n');
      final r = lerListaDeCartoes(lista, max: 5);
      expect(r.cartoes.length, 5);
      expect(r.cortado, isTrue);
      expect(r.ignoradas, 0);
    });

    test('vira um baralho (TextoSalvo) com o título e as frases', () {
      final t = textoDeCartoes(le('A ; um\nB ; dois'), titulo: 'Minha lista', id: 'xyz', criadoEm: DateTime(2026, 10, 12));
      expect(t.id, 'xyz');
      expect(t.titulo, 'Minha lista');
      expect(t.frases, const [FraseDoTexto('A', 'um'), FraseDoTexto('B', 'dois')]);
      expect(t.sequencial, isFalse);
      expect(textoDeCartoes(const [], titulo: 't').id, isNotEmpty);
    });
  });

  group('TextoSalvo sequencial (o baralho que cresce uma frase por vez)', () {
    TextoSalvo com(int n, {bool seq = true}) => TextoSalvo(
          id: 'c',
          titulo: 'Meus cartões',
          criadoEm: DateTime(2026, 10, 12),
          frases: [for (var i = 1; i <= n; i++) FraseDoTexto('Sentence $i.', 'Frase $i.')],
          sequencial: seq,
        );

    test('lições de 8 em sequência: 8, 8, 1', () {
      expect(repartirEmSequencia(List.generate(17, (i) => i)).map((l) => l.length), [8, 8, 1]);
      expect(repartirEmSequencia(const <int>[]), isEmpty);
      expect(com(17).comoTrilha().licoes.map((l) => l.trechos.length), [8, 8, 1]);
    });

    test('acrescentar frases NUNCA muda o que já está nas lições anteriores (o progresso é por id)', () {
      final antes = com(9).comoTrilha().licoes;
      final depois = com(17).comoTrilha().licoes;
      expect(depois[0], antes[0]);
      expect(depois[0].id, 'txt-c-1');
      expect(depois[1].trechos.first.cod, 'Sentence 9.');
      // o equilibrado (padrão) muda: 9 → 5+4, 17 → 6+6+5
      expect(com(9, seq: false).comoTrilha().licoes.map((l) => l.trechos.length), [5, 4]);
      expect(com(17, seq: false).comoTrilha().licoes.map((l) => l.trechos.length), [6, 6, 5]);
    });

    test('ida e volta em JSON guarda a marca; sem ela (textos antigos) é falso; comFrases mantém o resto', () {
      expect(TextoSalvo.fromJson(com(3).toJson())!.sequencial, isTrue);
      expect(com(3).toJson()['seq'], isTrue);
      expect(com(3, seq: false).toJson().containsKey('seq'), isFalse);
      expect(TextoSalvo.fromJson(com(3, seq: false).toJson())!.sequencial, isFalse);
      final c = com(3).comFrases(const [FraseDoTexto('X', 'Y')]);
      expect((c.id, c.titulo, c.sequencial, c.frases.length), ('c', 'Meus cartões', true, 1));
    });
  });

  group('exportar para o Anki', () {
    final trilhas = [
      const Trilha(nivel: 'Primeiro contato', emoji: '👋', etapa: 'A1 · Fundação', licoes: [
        Licao(id: 'primeiro-contato.oi', nome: 'Oi', emoji: '1', trechos: [
          Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: ''),
          Trecho(cod: 'How are you?', dica: 'Como vai?', out: ''),
        ]),
      ]),
      const Trilha(nivel: 'Dia a dia', emoji: '🌿', etapa: 'A2 · Dia a dia', licoes: [
        Licao(id: 'dia-a-dia.ontem', nome: 'Ontem', emoji: '2', trechos: [
          Trecho(cod: 'I was tired.', dica: 'Eu estava <b>cansado</b>.', out: ''),
          Trecho(cod: 'how are you?', dica: 'Como vai?', out: ''), // repetida (outra caixa)
        ]),
      ]),
      TextoSalvo(id: 'abc', titulo: 'Minha viagem', criadoEm: DateTime(2026, 10, 1), frases: const [FraseDoTexto('I love Rome.', 'Eu amo\tRoma.')]).comoTrilha(),
    ];
    final indice = IndiceBaralhos.de(trilhas);

    test('tags do Anki: sem espaço, hierárquicas, sem símbolos', () {
      expect(tagDoAnki(['Paclingo', 'A1 · Fundação', 'Primeiro contato']), 'Paclingo::A1_Fundação::Primeiro_contato');
      expect(tagDoAnki(['Paclingo', '', '  ']), 'Paclingo');
      expect(tagDoAnki(["Eu e você: I'm, you're"]), 'Eu_e_você_Im_youre');
    });

    test('cabeçalho do Anki, TAB entre os campos, tags no 3º, HTML do verso tirado', () {
      final t = exportarParaAnki(indice.baralhos);
      final linhas = t.trim().split('\n');
      expect(linhas.take(3), ['#separator:tab', '#html:false', '#tags column:3']);
      expect(linhas[3], 'Nice to meet you.\tPrazer em te conhecer.\tPaclingo::A1_Fundação::Primeiro_contato');
      expect(linhas.any((l) => l.startsWith('I was tired.\tEu estava <b>cansado</b>.')), isFalse, reason: 'o <b> sai? não: o dicaPlana tira');
    });

    test('o verso sai sem marcação, a frase repetida entre baralhos sai UMA vez com as tags dos dois', () {
      final linhas = exportarParaAnki(indice.baralhos).trim().split('\n').skip(3).toList();
      expect(linhas.length, 4, reason: 'Nice, How (uma vez), I was tired, I love Rome');
      expect(linhas.firstWhere((l) => l.startsWith('I was tired.')), 'I was tired.\tEu estava cansado.\tPaclingo::A2_Dia_a_dia::Dia_a_dia');
      expect(linhas.firstWhere((l) => l.toLowerCase().startsWith('how are you')),
          'How are you?\tComo vai?\tPaclingo::A1_Fundação::Primeiro_contato Paclingo::A2_Dia_a_dia::Dia_a_dia');
    });

    test('tabulação dentro de um campo vira espaço (não quebra as colunas)', () {
      final l = exportarParaAnki(indice.baralhos).trim().split('\n').firstWhere((x) => x.startsWith('I love Rome.'));
      expect(l.split('\t'), ['I love Rome.', 'Eu amo Roma.', 'Paclingo::Meus_textos::Minha_viagem']);
    });

    test('português na frente; escolher só alguns baralhos; nada → só o cabeçalho', () {
      final t = exportarParaAnki(indice.baralhos.where((b) => b.propria), invertido: true).trim().split('\n');
      expect(t.skip(3), ['Eu amo Roma.\tI love Rome.\tPaclingo::Meus_textos::Minha_viagem']);
      expect(exportarParaAnki(const []).trim().split('\n'), ['#separator:tab', '#html:false', '#tags column:3']);
    });

    test('ida e volta: o que a gente exporta, a importação entende (frente e verso)', () {
      final exportado = exportarParaAnki(indice.baralhos);
      final lido = lerListaDeCartoes(exportado).cartoes;
      expect(lido.length, 4);
      expect(lido.first, const CartaoEscrito('Nice to meet you.', 'Prazer em te conhecer.'));
    });

    test('histórico em CSV: por data, com o sentido, a frase (aspas se tiver vírgula), a nota e a 1ª vez', () {
      final h = [
        const EntradaHistorico(20738, 'k2~r', 4, primeira: true),
        const EntradaHistorico(20737, 'k1', 3),
        const EntradaHistorico(20737, 'k3', 1),
      ];
      final csv = exportarHistorico(h, frases: (k) => switch (k) { 'k1' => 'Nice, to meet you.', 'k2' => 'How "are" you?', _ => k }).trim().split('\n');
      expect(csv, [
        'data,sentido,frase,nota,primeira_vez',
        '2026-10-11,portugues-ingles,"Nice, to meet you.",3,0',
        '2026-10-11,portugues-ingles,k3,1,0',
        '2026-10-12,ingles-portugues,"How ""are"" you?",4,1',
      ]);
      expect(exportarHistorico(const []).trim(), 'data,sentido,frase,nota,primeira_vez');
    });
  });

  group('CursoBloc: cartão escrito à mão e baralho sem abrir', () {
    final curso = [
      const Trilha(nivel: 'Primeiros', emoji: '👋', etapa: 'A1 · Fundação', licoes: [
        Licao(id: 'primeiros.um', nome: 'Um', emoji: '1', trechos: [Trecho(cod: 'Hi.', dica: 'Oi.', out: '')]),
        Licao(id: 'primeiros.dois', nome: 'Dois', emoji: '2', trechos: [Trecho(cod: 'Bye.', dica: 'Tchau.', out: '')]),
      ]),
    ];

    Future<(CursoBloc, LocalTextosRepository)> abrir() async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalTextosRepository('u');
      final bloc = CursoBloc(loader: _Loader(curso), progresso: LocalProgressoRepository(prefixo: 'en_'), textos: repo)
        ..add(const CursoIniciado());
      await bloc.stream.firstWhere((s) => s.status == CursoStatus.pronto);
      return (bloc, repo);
    }

    TextoSalvo texto(String id, int n, [DateTime? quando]) => TextoSalvo(
          id: id,
          titulo: 'T $id',
          criadoEm: quando ?? DateTime(2026, 10, 1),
          frases: [for (var i = 1; i <= n; i++) FraseDoTexto('Line $i of $id.', 'Linha $i de $id.')],
        );

    test('o 1º cartão cria "Meus cartões" (sequencial) SEM mudar a lição aberta; os seguintes acrescentam', () async {
      final (bloc, repo) = await abrir();
      bloc.add(const LicaoSelecionada(1));
      await bloc.stream.firstWhere((s) => s.licaoIdx == 1);
      bloc.add(const CartaoAdicionado(CartaoEscrito('I am hungry.', 'Estou com fome.')));
      var st = await bloc.stream.firstWhere((s) => s.trilhas.length == 2);
      expect(st.trilhas.last.nivel, tituloCartoesAvulsos);
      expect(st.trilhas.last.textoId, idCartoesAvulsos);
      expect((st.trilhaIdx, st.licaoIdx), (0, 1), reason: 'continua na lição que estava');
      expect(st.trilhas.last.licoes.single.trechos.single.cod, 'I am hungry.');

      bloc.add(const CartaoAdicionado(CartaoEscrito('I am tired.', 'Estou cansado.')));
      st = await bloc.stream.firstWhere((s) => s.trilhas.last.licoes.single.trechos.length == 2);
      expect(st.trilhas.length, 2, reason: 'a mesma trilha cresce, não nasce outra');
      final salvo = (await repo.carregar()).single;
      expect(salvo.sequencial, isTrue);
      expect(salvo.frases.map((f) => f.en), ['I am hungry.', 'I am tired.']);
      await bloc.close();
    });

    test('a mesma frente de novo só troca o verso (sem duplicar), sem diferença de caixa', () async {
      final (bloc, repo) = await abrir();
      bloc.add(const CartaoAdicionado(CartaoEscrito('I am hungry.', 'Estou com fome.')));
      await bloc.stream.firstWhere((s) => s.trilhas.length == 2);
      bloc.add(const CartaoAdicionado(CartaoEscrito('i am HUNGRY.', 'Tenho fome.')));
      await bloc.stream.firstWhere((s) => s.trilhas.last.licoes.single.trechos.single.dica == 'Tenho fome.');
      final salvo = (await repo.carregar()).single;
      expect(salvo.frases, const [FraseDoTexto('I am hungry.', 'Tenho fome.')]);
      await bloc.close();
    });

    test('lições do baralho crescem em sequência: a 9ª frase abre a 2ª lição e a 1ª fica igual', () async {
      final (bloc, _) = await abrir();
      for (var i = 1; i <= 9; i++) {
        bloc.add(CartaoAdicionado(CartaoEscrito('Card number $i.', 'Cartão $i.')));
      }
      final st = await bloc.stream.firstWhere((s) => s.trilhas.length == 2 && s.trilhas.last.licoes.length == 2);
      expect(st.trilhas.last.licoes.map((l) => l.trechos.length), [8, 1]);
      expect(st.trilhas.last.licoes.first.id, 'txt-cartoes-1');
      await bloc.close();
    });

    test('quem estava num texto do aluno continua nele quando "Meus cartões" entra antes (o índice acompanha)', () async {
      final (bloc, _) = await abrir();
      bloc.add(TextoCriado(texto('a', 3, DateTime(2026, 10, 2))));
      await bloc.stream.firstWhere((s) => s.trilha.textoId == 'a');
      expect(bloc.state.trilhaIdx, 1);
      bloc.add(const CartaoAdicionado(CartaoEscrito('Hello.', 'Olá.')));
      final st = await bloc.stream.firstWhere((s) => s.trilhas.length == 3);
      expect(st.trilhas.map((t) => t.textoId), ['', idCartoesAvulsos, 'a']);
      expect(st.trilha.textoId, 'a', reason: 'a seleção seguiu o texto, não o número');
      await bloc.close();
    });

    test('importar SEM abrir: o baralho entra, a seleção fica; e importar DE NOVO o mesmo troca no lugar', () async {
      final (bloc, repo) = await abrir();
      bloc.add(TextoCriado(texto('a', 3), abrir: false));
      var st = await bloc.stream.firstWhere((s) => s.trilhas.length == 2);
      expect(st.trilha.nivel, 'Primeiros');
      expect(st.trilhas.last.textoId, 'a');
      bloc.add(TextoCriado(texto('a', 5), abrir: false));
      st = await bloc.stream.firstWhere((s) => s.trilhas.last.licoes.expand((l) => l.trechos).length == 5);
      expect(st.trilhas.length, 2, reason: 'trocou no lugar');
      expect((await repo.carregar()).single.frases.length, 5);
      await bloc.close();
    });

    test('abrir: true segue como antes (cai na 1ª lição do texto)', () async {
      final (bloc, _) = await abrir();
      bloc.add(TextoCriado(texto('a', 3)));
      final st = await bloc.stream.firstWhere((s) => s.trilha.propria);
      expect((st.trilhaIdx, st.licaoIdx), (1, 0));
      await bloc.close();
    });

    test('sem onde guardar os textos ou antes de carregar: o cartão é ignorado, sem quebrar', () async {
      final semRepo = CursoBloc(loader: _Loader(curso), progresso: LocalProgressoRepository(prefixo: 'en_'))..add(const CursoIniciado());
      await semRepo.stream.firstWhere((s) => s.status == CursoStatus.pronto);
      semRepo.add(const CartaoAdicionado(CartaoEscrito('Hello.', 'Olá.')));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(semRepo.state.trilhas.length, 1);
      await semRepo.close();

      SharedPreferences.setMockInitialValues({});
      final cedo = CursoBloc(loader: _Loader(curso), progresso: LocalProgressoRepository(prefixo: 'en_'), textos: LocalTextosRepository('u'));
      cedo.add(const CartaoAdicionado(CartaoEscrito('Hello.', 'Olá.')));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(cedo.state.trilhas, isEmpty);
      await cedo.close();
    });
  });
}
