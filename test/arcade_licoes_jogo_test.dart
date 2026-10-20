// As lições das palavras dos jogos: a escolha gravada no banco (codec, mescla, compatibilidade com o
// que já estava gravado), as palavras de cada lição e o vocabulário montado com a escolha.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/arcade/domain/vocabulario_jogo.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/palavras_novas.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/domain/vocabulario_aluno.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final dic = Dicionario.fromJson(jsonDecode(File('assets/ingles/dicionario.json').readAsStringSync()));
  final curso = (jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
      .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
      .toList();
  final ind = IndicePalavras.de(curso, dic);
  final licoes = [for (final t in curso) for (final l in t.licoes) l];
  final ids = [for (final l in licoes) l.id];
  const hoje = 20400;
  final reserva = {...palavrasCurtasEn, ...palavrasMediasEn, ...palavrasLongasEn};

  group('BancoPalavras: a escolha das lições dos jogos', () {
    test('sem a escolha, o JSON antigo volta byte a byte igual', () {
      const antigos = [
        '{"p":[{"e":"apple","p":"maçã","c":5,"u":7,"v":3,"r":1}],"t":["apple"],"te":9}',
        '{"p":[]}',
        '{"p":[{"e":"Monday","p":"segunda","o":"m","j":0}]}',
      ];
      for (final j in antigos) {
        final b = BancoPalavras.decodificar(j);
        expect(b.licoesJogo, isNull);
        expect(b.minhasNoJogo, isTrue);
        expect(b.licoesJogoEm, 0);
        expect(b.codificar(), j);
      }
    });

    test('codec: lições, "minhas palavras" desligado e a hora da mudança', () {
      final b = const BancoPalavras()
          .com(const PalavraDoBanco(en: 'apple', pt: 'maçã'))
          .comLicoesJogo(['a.1', 'b.2', 'a.1', ''], minhas: false, agora: 1234);
      expect(b.licoesJogo, ['a.1', 'b.2']);
      final j = b.toJson();
      expect(j['lj'], ['a.1', 'b.2']);
      expect(j['lm'], 0);
      expect(j['le'], 1234);
      final volta = BancoPalavras.decodificar(b.codificar());
      expect(volta, b);
      expect(volta.codificar(), b.codificar());

      // automático escolhido depois de uma escolha: sem 'lj', mas com a hora (para ganhar a mescla)
      final auto = volta.comLicoesJogo(null, minhas: true, agora: 2000);
      expect(auto.toJson().containsKey('lj'), isFalse);
      expect(auto.toJson().containsKey('lm'), isFalse);
      expect(auto.toJson()['le'], 2000);
      expect(BancoPalavras.decodificar(auto.codificar()), auto);

      // escolha vazia é diferente do automático
      final vazia = BancoPalavras.decodificar(const BancoPalavras().comLicoesJogo(const [], agora: 5).codificar());
      expect(vazia.licoesJogo, isEmpty);
    });

    test('lixo no campo não quebra a leitura', () {
      final b = BancoPalavras.decodificar('{"p":[],"lj":"x","le":"y","lm":"z"}');
      expect(b.licoesJogo, isNull);
      expect(b.licoesJogoEm, 0);
      expect(b.minhasNoJogo, isTrue);
      final c = BancoPalavras.decodificar('{"p":[],"lj":[1,"a.1",null,""],"le":12.0}');
      expect(c.licoesJogo, ['a.1']);
      expect(c.licoesJogoEm, 12);
    });

    test('mescla: vale a escolha inteira do lado que mudou por último (inclusive a volta ao automático)', () {
      final base = const BancoPalavras().com(const PalavraDoBanco(en: 'apple', pt: 'maçã'));
      final a = base.comLicoesJogo(['a.1'], minhas: false, agora: 100);
      final b = base.comLicoesJogo(['b.1', 'b.2'], minhas: true, agora: 200);
      for (final m in [BancoPalavras.mesclar(a, b), BancoPalavras.mesclar(b, a)]) {
        expect(m.licoesJogo, ['b.1', 'b.2']);
        expect(m.minhasNoJogo, isTrue);
        expect(m.licoesJogoEm, 200);
      }
      final auto = base.comLicoesJogo(null, agora: 300);
      for (final m in [BancoPalavras.mesclar(a, auto), BancoPalavras.mesclar(auto, a)]) {
        expect(m.licoesJogo, isNull);
        expect(m.licoesJogoEm, 300);
      }
      // um lado sem nunca ter escolhido não apaga a escolha do outro
      expect(BancoPalavras.mesclar(base, a).licoesJogo, ['a.1']);
      expect(BancoPalavras.mesclar(a, base).licoesJogo, ['a.1']);
    });

    test('as outras mudanças do banco guardam a escolha', () {
      final b = const BancoPalavras().comLicoesJogo(['a.1'], minhas: false, agora: 7);
      final c = b
          .com(const PalavraDoBanco(en: 'apple', pt: 'maçã'))
          .comEmTreino(['apple'], 9)
          .podado(hoje);
      expect(c.licoesJogo, ['a.1']);
      expect(c.minhasNoJogo, isFalse);
      expect(c.licoesJogoEm, 7);
    });
  });

  group('IndicePalavras.palavrasDeJogo', () {
    test('as novas da lição primeiro; depois as outras palavras de conteúdo com tradução', () {
      for (final l in licoes.take(40)) {
        final ps = ind.palavrasDeJogo(l);
        final novas = [for (final p in ind.novasDe(l.id)) if (p.deJogo) p.en];
        expect([for (final p in ps.take(novas.length)) p.$1], novas, reason: l.id);
        for (final (en, pt) in ps) {
          expect(RegExp(r'^[A-Za-z]{3,14}$').hasMatch(en), isTrue, reason: en);
          expect(stopwordsEn.contains(en.toLowerCase()), isFalse, reason: en);
          expect(ind.nomes.contains(en.toLowerCase()), isFalse, reason: en);
          expect(pt, isNotEmpty, reason: en);
        }
        expect(ps.map((p) => p.$1.toLowerCase()).toSet().length, ps.length, reason: 'sem repetir: ${l.id}');
        expect(identical(ind.palavrasDeJogo(l), ps), isTrue, reason: 'memorizado');
      }
    });

    test('lição com poucas novas ainda contribui com as palavras das frases', () {
      final poucas = licoes.firstWhere((l) => ind.novasDe(l.id).length <= 2 && ind.palavrasDeJogo(l).length >= 4,
          orElse: () => licoes.first);
      expect(ind.palavrasDeJogo(poucas).length, greaterThan(ind.novasDe(poucas.id).length));
    });

    test('cartões de uma palavra (Meus cartões) entram com a tradução do cartão', () {
      const l = Licao(nome: 'Parte 1', emoji: '📝', id: 'txt-cartoes-1', trechos: [
        Trecho(cod: 'serendipity', dica: 'acaso feliz', out: ''),
        Trecho(cod: 'I saw a kangaroo.', dica: 'Vi um canguru.', out: '', alvo: 'kangaroo', alvoPt: 'canguru'),
        Trecho(cod: 'two words', dica: 'duas palavras', out: ''),
      ]);
      final ps = {for (final (en, pt) in ind.palavrasDeJogo(l)) en: pt};
      expect(ps['serendipity'], 'acaso feliz');
      expect(ps['kangaroo'], isNotNull);
      expect(ps.containsKey('two words'), isFalse);
    });
  });

  group('montarVocabularioIngles com lições escolhidas', () {
    final escolhidas = [ids[3], ids[8]];
    final daEscolha = {
      for (final id in escolhidas)
        for (final p in ind.palavrasDeJogo(licoes[ids.indexOf(id)])) p.$1.toLowerCase(),
    };

    BancoPalavras bancoDeTeste() => const BancoPalavras()
        .com(const PalavraDoBanco(en: 'umbrella', pt: 'guarda-chuva', origem: OrigemPalavra.minha, criadaEm: 1))
        .com(const PalavraDoBanco(
            en: 'grandmother',
            pt: 'avó',
            cartao: CartaoSrs(estabilidade: 1, dificuldade: 5, ultimoDia: hoje - 3, proximoDia: hoje - 1)))
        .comEmTreino(['afternoon'], 5);

    test('só as palavras das lições escolhidas (+ foco, + as minhas, + enchimento)', () {
      final v = montarVocabularioIngles(
        trilhas: curso,
        concluidas: ids.take(60).toSet(),
        indice: ind,
        banco: bancoDeTeste(),
        hoje: hoje,
        licaoAtualId: ids[60],
        licoesEscolhidas: escolhidas,
      );
      expect(v.foco, {'afternoon'});
      expect(v.longas.first, 'afternoon', reason: 'o foco continua na frente');
      expect(v.todas, contains('umbrella'), reason: 'minhas palavras ligado (padrão)');
      expect(v.todas, isNot(contains('grandmother')), reason: 'as que vencem saem com a escolha');
      for (final w in v.todas) {
        final k = w.toLowerCase();
        expect(daEscolha.contains(k) || reserva.contains(w) || k == 'afternoon' || k == 'umbrella', isTrue,
            reason: 'veio de fora da escolha: $w');
      }
      expect(v.todas.where((w) => daEscolha.contains(w.toLowerCase())).length, greaterThan(5));
      for (final w in v.todas) {
        expect(v.traducao(w), isNotNull, reason: w);
      }
    });

    test('"incluir minhas palavras" desligado: as da pessoa saem, o foco fica', () {
      final banco = bancoDeTeste().com(const PalavraDoBanco(en: 'afternoon', pt: 'tarde', origem: OrigemPalavra.minha));
      final v = montarVocabularioIngles(
        trilhas: curso,
        concluidas: const {},
        indice: ind,
        banco: banco,
        hoje: hoje,
        licoesEscolhidas: escolhidas,
        incluirMinhas: false,
      );
      expect(v.todas, isNot(contains('umbrella')));
      expect(v.foco, {'afternoon'});
      expect(v.todas, contains('afternoon'));
    });

    test('poucas palavras: o enchimento completa até 12 por faixa e é contado', () {
      final pequena = licoes.firstWhere((l) => ind.palavrasDeJogo(l).length <= 6);
      final v = montarVocabularioIngles(
          trilhas: curso, concluidas: const {}, indice: ind, hoje: hoje, licoesEscolhidas: [pequena.id]);
      expect(v.curtas.length, greaterThanOrEqualTo(12));
      expect(v.medias.length, greaterThanOrEqualTo(12));
      expect(v.longas.length, greaterThanOrEqualTo(12));
      expect(v.enchimento, greaterThan(20));
      // sem escolha e sem progresso também enche — mas a contagem só é aviso com escolha
      final muitas = montarVocabularioIngles(
          trilhas: curso, concluidas: const {}, indice: ind, hoje: hoje, licoesEscolhidas: ids.take(80));
      expect(muitas.enchimento, lessThan(v.enchimento));
    });

    test('muitas lições: teto de 40 por faixa, e cada lição contribui (revezando)', () {
      final muitas = ids.take(120).toList();
      final v = montarVocabularioIngles(
          trilhas: curso, concluidas: const {}, indice: ind, hoje: hoje, licoesEscolhidas: muitas);
      expect(v.curtas.length, 40);
      expect(v.medias.length, 40);
      // a última lição escolhida tem palavra no jogo (não só as primeiras lições do curso)
      final ultimas = {
        for (final id in muitas.skip(100))
          for (final p in ind.palavrasDeJogo(licoes[ids.indexOf(id)])) p.$1.toLowerCase(),
      };
      expect(v.todas.where((w) => ultimas.contains(w.toLowerCase())), isNotEmpty);
    });

    test('todas as lições: entram palavras do curso inteiro e o conjunto muda de um dia para o outro', () {
      final todasIds = ids.where((id) => id.isNotEmpty).toList();
      final terco = {
        for (final id in todasIds.skip(todasIds.length * 2 ~/ 3))
          for (final p in ind.palavrasDeJogo(licoes[ids.indexOf(id)])) p.$1.toLowerCase(),
      };
      final primeiro = {
        for (final id in todasIds.take(todasIds.length ~/ 3))
          for (final p in ind.palavrasDeJogo(licoes[ids.indexOf(id)])) p.$1.toLowerCase(),
      };
      VocabularioJogo dia(int h) => montarVocabularioIngles(
          trilhas: curso, concluidas: const {}, indice: ind, hoje: h, licoesEscolhidas: todasIds);
      final a = dia(hoje), b = dia(hoje + 1);
      for (final v in [a, b]) {
        expect([v.curtas.length, v.medias.length, v.longas.length], [40, 40, 40]);
        expect(v.enchimento, 0);
        final soDoFim = v.todas.where((w) => terco.contains(w.toLowerCase()) && !primeiro.contains(w.toLowerCase()));
        expect(soDoFim.length, greaterThan(10), reason: 'o último terço do curso também entra: ${soDoFim.length}');
      }
      final comuns = a.todas.toSet().intersection(b.todas.toSet()).length;
      expect(comuns, lessThan(90), reason: 'mudou pouco de um dia para o outro: $comuns de 120 iguais');
    });

    test('com muitas lições, as palavras da pessoa ainda entram (cota antes das lições)', () {
      var banco = const BancoPalavras();
      for (final (en, pt) in [('zebra', 'zebra'), ('quokka', 'quoca'), ('pangolin', 'pangolim'), ('narwhal', 'narval')]) {
        banco = banco.com(PalavraDoBanco(en: en, pt: pt, origem: OrigemPalavra.minha, criadaEm: 1));
      }
      final muitas = ids.skip(300).take(30).toList();
      final v = montarVocabularioIngles(
          trilhas: curso, concluidas: const {}, indice: ind, banco: banco, hoje: hoje, licoesEscolhidas: muitas);
      expect([v.curtas.length, v.medias.length], [40, 40], reason: 'as lições enchem as faixas');
      expect(v.todas, containsAll(['zebra', 'quokka', 'pangolin', 'narwhal']));
      expect(v.minhas, 4);
      final sem = montarVocabularioIngles(
          trilhas: curso,
          concluidas: const {},
          indice: ind,
          banco: banco,
          hoje: hoje,
          licoesEscolhidas: muitas,
          incluirMinhas: false);
      expect(sem.todas, isNot(contains('zebra')));
      expect(sem.minhas, 0);
    });

    test('faltar só palavras longas não é "poucas palavras" (curtas/médias cheias)', () {
      final v = montarVocabularioIngles(
          trilhas: curso, concluidas: const {}, indice: ind, hoje: hoje, licoesEscolhidas: ids.take(40));
      expect([v.curtas.length, v.medias.length], [40, 40]);
      expect(v.enchimentoCurtasMedias, 0);
      expect(v.enchimentoLongas, v.enchimento);
      final pequena = licoes.firstWhere((l) => ind.palavrasDeJogo(l).length <= 6);
      final p = montarVocabularioIngles(
          trilhas: curso, concluidas: const {}, indice: ind, hoje: hoje, licoesEscolhidas: [pequena.id]);
      expect(p.enchimentoCurtasMedias, greaterThan(0));
    });

    test('a escolha vazia joga só com o foco, as minhas e o enchimento', () {
      final v = montarVocabularioIngles(
          trilhas: curso, concluidas: ids.take(30).toSet(), indice: ind, hoje: hoje, licoesEscolhidas: const []);
      expect(v.todas.every(reserva.contains), isTrue);
    });

    test('palavrasDasLicoesEscolhidas: o total sem repetir e sem as tiradas dos jogos', () {
      final todas = palavrasDasLicoesEscolhidas(trilhas: curso, escolhidas: escolhidas, indice: ind);
      expect(todas.map((p) => p.$1.toLowerCase()).toSet(), daEscolha);
      final tirada = todas.first.$1;
      final banco = const BancoPalavras().com(PalavraDoBanco(en: tirada, pt: 'x', noJogo: false));
      final sem = palavrasDasLicoesEscolhidas(trilhas: curso, escolhidas: escolhidas, indice: ind, banco: banco);
      expect(sem.length, todas.length - 1);
    });
  });

  group('PalavrasCubit', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('escolherLicoesDoJogo grava, o vocabulário segue a escolha e o automático volta ao normal', () async {
      final repo = MemoriaPalavrasRepository();
      final c = PalavrasCubit(
        repo: repo,
        carregarDicionario: () async => dic,
        agora: () => DateTime(2025, 11, 10, 12),
      );
      await c.carregar();
      await c.prepararIndice(curso);
      final st = _CursoFake(CursoState(
        status: CursoStatus.pronto,
        trilhas: curso,
        linguagem: Linguagem.ingles,
        concluidas: ids.take(30).toSet(),
      ));
      expect(c.licoesDoJogo, isNull);
      expect(c.minhasNoJogo, isTrue);
      final auto = c.vocabularioJogo(st.state)!;

      c.escolherLicoesDoJogo([ids[3], ids[8]], incluirMinhas: false);
      expect(c.licoesDoJogo, {ids[3], ids[8]});
      expect(c.minhasNoJogo, isFalse);
      await c.gravacoes;
      expect(repo.banco.licoesJogo, [ids[3], ids[8]]);
      expect(repo.banco.minhasNoJogo, isFalse);
      final salvos = repo.salvos;

      // a mesma escolha de novo não grava outra vez
      c.escolherLicoesDoJogo([ids[8], ids[3]]);
      await c.gravacoes;
      expect(repo.salvos, salvos);

      final v = c.vocabularioJogo(st.state)!;
      final daEscolha = {for (final p in c.palavrasDasLicoes(st.state, [ids[3], ids[8]])) p.$1.toLowerCase()};
      expect(v.todas.where((w) => !reserva.contains(w)).every((w) => daEscolha.contains(w.toLowerCase())), isTrue);
      expect(v.todas, isNot(auto.todas));

      // a prévia com outra escolha não muda o que está gravado
      final previa = c.vocabularioJogo(st.state, escolha: (licoes: null, minhas: true))!;
      expect(previa.todas, auto.todas);
      expect(c.licoesDoJogo, {ids[3], ids[8]});

      c.escolherLicoesDoJogo(null);
      expect(c.licoesDoJogo, isNull);
      expect(c.vocabularioJogo(st.state)!.todas, auto.todas);
      await c.gravacoes;
      expect(repo.banco.licoesJogo, isNull);
      expect(repo.banco.licoesJogoEm, greaterThan(0));
      await c.close();
      await st.close();
    });
  });
}

class _CursoFake extends CursoBloc {
  _CursoFake(CursoState s) : super(loader: CurriculoLoader(), progresso: LocalProgressoRepository()) {
    emit(s);
  }
}
