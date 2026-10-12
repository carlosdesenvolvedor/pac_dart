import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/config_srs_repository.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart';
import 'package:pac_dart/features/ingles/domain/config_srs.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/domain/texto_salvo.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RepoMemoria implements RevisaoRepository {
  Map<String, CartaoSrs> cartoes;
  final historico = <EntradaHistorico>[];
  RepoMemoria([Map<String, CartaoSrs>? iniciais]) : cartoes = {...?iniciais};
  @override
  Future<Map<String, CartaoSrs>> carregar() async => {...cartoes};
  @override
  Future<void> salvar(Map<String, CartaoSrs> novos) async => cartoes = {...cartoes, ...novos};
  @override
  Future<void> registrarHistorico(List<EntradaHistorico> e) async => historico.addAll(e);
  @override
  Future<List<EntradaHistorico>> carregarHistorico({int? desdeDia}) async =>
      [for (final e in historico) if (desdeDia == null || e.dia >= desdeDia) e];
}

class ConfigMemoria implements ConfigSrsRepository {
  ConfigSrs atual;
  int gravacoes = 0;
  ConfigMemoria([this.atual = ConfigSrs.padrao]);
  @override
  Future<ConfigSrs> carregar() async => atual;
  @override
  Future<void> salvar(ConfigSrs c) async {
    atual = c;
    gravacoes++;
  }
}

Future<void> assenta() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

const f1 = Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: '');
const f2 = Trecho(cod: 'How are you?', dica: 'Como vai?', out: '');
const f3 = Trecho(cod: 'I was tired.', dica: 'Eu estava cansado.', out: '');
const f4 = Trecho(cod: 'See you tomorrow.', dica: 'Até amanhã.', out: '');

List<Trilha> trilhasDeTeste() => [
      const Trilha(nivel: 'Primeiro contato', emoji: '👋', etapa: 'A1 · Fundação', licoes: [
        Licao(id: 'primeiro-contato.oi', nome: 'Oi', emoji: '1', trechos: [f1, f2]),
      ]),
      const Trilha(nivel: 'Dia a dia', emoji: '🌿', etapa: 'A2 · Dia a dia', licoes: [
        Licao(id: 'dia-a-dia.ontem', nome: 'Ontem', emoji: '2', trechos: [f3, f2]), // f2 repete
        Licao(id: 'dia-a-dia.amanha', nome: 'Amanhã', emoji: '3', trechos: [f4]),
      ]),
      TextoSalvo(
        id: 'abc',
        titulo: 'Minha viagem',
        criadoEm: DateTime(2026, 10, 1),
        frases: const [FraseDoTexto('I love Rome.', 'Eu amo Roma.')],
      ).comoTrilha(),
    ];

void main() {
  final fsrs = AgendadorFsrs(fuzz: false);
  final hoje = Revisao.dia(DateTime(2026, 10, 12));
  String k(Trecho f) => RevisaoCubit.chaveDe(f);

  group('chave do cartão invertido', () {
    test('é um cartão à parte, com sufixo, e dá para voltar à frase', () {
      final base = Revisao.chave('Nice to meet you.');
      final r = Revisao.chaveReversa(base);
      expect(r, '$base~r');
      expect(Revisao.ehReversa(r), isTrue);
      expect(Revisao.ehReversa(base), isFalse);
      expect(Revisao.baseDe(r), base);
      expect(Revisao.baseDe(base), base, reason: 'sem sufixo, devolve a mesma');
      expect(Revisao.chaveReversa(Revisao.baseDe(r)), r);
    });

    test('nenhuma chave de frase termina em "~r" (base 36 e ids do curso não têm "~")', () {
      for (var i = 0; i < 2000; i++) {
        expect(Revisao.ehReversa(Revisao.chave('frase $i')), isFalse);
      }
    });

    test('o bloco do cartão invertido é fixo e válido (mesmo resultado na VM e no Chrome)', () {
      const esperado = {
        'i1cy7sgips~r': 'b13',
        '7yuj1r19ji~r': 'b02',
        'zhqkf518me~r': 'b10',
      };
      esperado.forEach((chave, bloco) {
        expect(FirestoreRevisaoRepository.idDoBloco(chave), bloco, reason: chave);
      });
    });
  });

  group('CartaoSrs: suspender e enterrar', () {
    final base = fsrs.novo(100);

    test('o 8º campo só existe quando há estado; ida e volta; o formato sem ele continua valendo', () {
      expect(base.codificar().split('|').length, 7);
      final s = base.comSuspenso(true);
      expect(s.codificar(), endsWith('|s'));
      expect(CartaoSrs.decodificar(s.codificar()), s);
      final e = base.comEnterradoAte(105);
      expect(e.codificar(), endsWith('|e105'));
      expect(CartaoSrs.decodificar(e.codificar()), e);
      expect(CartaoSrs.decodificar('f|101|100|3.2602|4.8846|1|0'), base);
      expect(CartaoSrs.decodificar('f|101|100|3.2602|4.8846|1|0|e')!.enterradoAte, 0, reason: 'dia ilegível = não enterrado');
      expect(CartaoSrs.decodificar('f|101|100|3.2602|4.8846|1|0|zzz')!.suspenso, isFalse);
    });

    test('suspenso e enterrado não vencem; amanhã o enterrado volta; a agenda não muda', () {
      final vencido = fsrs.novo(hoje - 5); // vence ontem
      expect(vencido.devidaEm(hoje), isTrue);
      expect(vencido.comSuspenso(true).devidaEm(hoje), isFalse);
      expect(vencido.comSuspenso(true).devidaEm(hoje + 400), isFalse, reason: 'suspenso é até reativar');
      final enterrado = vencido.comEnterradoAte(hoje + 1);
      expect(enterrado.devidaEm(hoje), isFalse);
      expect(enterrado.devidaEm(hoje + 1), isTrue);
      expect(enterrado.proximoDia, vencido.proximoDia);
      expect(vencido.comSuspenso(true).comSuspenso(false), vencido);
    });

    test('revisar o cartão tira o suspenso e o enterrado', () {
      expect(fsrs.avaliar(base.comSuspenso(true), Rating.good, 101).suspenso, isFalse);
      expect(fsrs.avaliar(base.comEnterradoAte(500), Rating.good, 101).enterradoAte, 0);
    });

    test('devidas() ignora os escondidos', () {
      final cartoes = {
        'a': fsrs.novo(hoje - 5),
        'b': fsrs.novo(hoje - 5).comSuspenso(true),
        'c': fsrs.novo(hoje - 5).comEnterradoAte(hoje + 1),
      };
      expect(fsrs.devidas(cartoes, hoje), ['a']);
    });
  });

  group('AgendadorFsrs: cartão que a pessoa vê pela 1ª vez e previsão dos botões', () {
    test('sem a regra do "amanhã" a nota decide: errei/difícil → 1 dia, bom → dias, fácil → semanas', () {
      final dias = {for (final n in Rating.values) n: fsrs.novo(hoje, nota: n, voltaAmanha: false).proximoDia - hoje};
      expect(dias[Rating.again], 1);
      expect(dias[Rating.hard], 1);
      expect(dias[Rating.good]!, inInclusiveRange(2, 6));
      expect(dias[Rating.easy]!, greaterThan(10));
      expect(fsrs.novo(hoje, nota: Rating.easy).proximoDia, hoje + 1, reason: 'a regra do amanhã continua o padrão');
    });

    test('previsão de cartão novo: cresce com a nota e bate com o que de fato acontece', () {
      final p = fsrs.previsao(null, hoje);
      expect(p[Rating.again]!, lessThanOrEqualTo(p[Rating.hard]!));
      expect(p[Rating.hard]!, lessThanOrEqualTo(p[Rating.good]!));
      expect(p[Rating.good]!, lessThan(p[Rating.easy]!));
      for (final n in Rating.values) {
        expect(fsrs.novo(hoje, nota: n, voltaAmanha: false).proximoDia - hoje, p[n]);
      }
    });

    test('previsão de cartão existente: é exatamente o que a avaliação dá (sem fuzz)', () {
      var c = fsrs.novo(hoje - 10);
      c = fsrs.avaliar(c, Rating.good, hoje - 9);
      final p = fsrs.previsao(c, hoje);
      for (final n in Rating.values) {
        expect(fsrs.avaliar(c, n, hoje).proximoDia - hoje, p[n], reason: '$n');
      }
    });

    test('com fuzz ligado a previsão continua exata e estável (o número do botão não pula)', () {
      final com = AgendadorFsrs(); // fuzz ligado
      final c = com.avaliar(com.novo(hoje - 10), Rating.good, hoje - 9);
      final a = com.previsao(c, hoje), b = com.previsao(c, hoje);
      expect(a, b);
      expect(a, fsrs.previsao(c, hoje), reason: 'é a previsão SEM fuzz');
    });

    test('rotuloIntervalo: dias, semanas, meses e anos', () {
      expect({for (final d in [1, 2, 6, 13, 14, 21, 45, 59, 60, 90, 180, 364, 365, 800]) d: rotuloIntervalo(d)}, {
        1: '1 dia',
        2: '2 dias',
        6: '6 dias',
        13: '13 dias',
        14: '2 sem',
        21: '3 sem',
        45: '6 sem',
        59: '8 sem',
        60: '2 meses',
        90: '3 meses',
        180: '6 meses',
        364: '12 meses',
        365: '1 ano',
        800: '2 anos',
      });
      expect(rotuloIntervalo(0), '1 dia');
    });
  });

  group('ConfigSrs', () {
    test('padrão do Anki e ida e volta', () {
      const c = ConfigSrs();
      expect((c.limiteRevisoes, c.novosPorDia, c.retencao), (80, 10, 0.90));
      expect(c.reversos, isEmpty);
      final mexida = c.copyWith(limiteRevisoes: 150, novosPorDia: 5, retencao: .95, reversos: {'tr:a', 'txt:b'});
      expect(ConfigSrs.decodificar(mexida.codificar()), mexida);
    });

    test('lixo ou valores impossíveis nunca quebram: caem no padrão ou no limite', () {
      expect(ConfigSrs.decodificar(null), ConfigSrs.padrao);
      expect(ConfigSrs.decodificar('{{{'), ConfigSrs.padrao);
      expect(ConfigSrs.decodificar('[1,2]'), ConfigSrs.padrao);
      final c = ConfigSrs.decodificar('{"limite":-5,"novos":99999,"retencao":5,"reversos":["a",3,"",null,"b"]}');
      expect(c.limiteRevisoes, 1);
      expect(c.novosPorDia, 500);
      expect(c.retencao, 0.97, reason: 'acima de 97% a carga explode');
      expect(c.reversos, {'a', 'b'});
      expect(ConfigSrs.decodificar('{"retencao":0.1}').retencao, 0.7);
      expect(ConfigSrs.decodificar('{"retencao":"x"}').retencao, 0.90);
    });

    test('ligar e desligar o sentido invertido de vários baralhos', () {
      var c = ConfigSrs.padrao.comReversos(['tr:a', 'tr:b'], ligar: true);
      expect(c.reversoLigado('tr:a'), isTrue);
      expect(c.reversoLigado('tr:c'), isFalse);
      c = c.comReversos(['tr:a'], ligar: false);
      expect(c.reversos, {'tr:b'});
      expect(c.comReversos(['tr:b'], ligar: true).reversos, {'tr:b'}, reason: 'ligar de novo não duplica');
    });

    test('Local: guarda e devolve; sem nada, o padrão', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalConfigSrsRepository();
      expect(await repo.carregar(), ConfigSrs.padrao);
      final c = ConfigSrs.padrao.copyWith(novosPorDia: 20, reversos: {'tr:x'});
      await repo.salvar(c);
      expect(await LocalConfigSrsRepository().carregar(), c);
      SharedPreferences.setMockInitialValues({'en_srs_cfg': 'lixo'});
      expect(await LocalConfigSrsRepository().carregar(), ConfigSrs.padrao);
    });

    test('Firestore: um campo no users/{uid}, sem apagar o resto do documento', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('users').doc('u1').set({'concluidas': ['a']});
      final repo = FirestoreConfigSrsRepository('u1', db: db);
      expect(await repo.carregar(), ConfigSrs.padrao);
      final c = ConfigSrs.padrao.copyWith(limiteRevisoes: 20, reversos: {'tr:x', 'txt:y'});
      await repo.salvar(c);
      expect(await FirestoreConfigSrsRepository('u1', db: db).carregar(), c);
      expect((await db.collection('users').doc('u1').get()).data()!['concluidas'], ['a']);
      expect(await FirestoreConfigSrsRepository('outro', db: db).carregar(), ConfigSrs.padrao);
    });
  });

  group('IndiceBaralhos', () {
    final indice = IndiceBaralhos.de(trilhasDeTeste());

    test('uma trilha = um baralho; ids estáveis; "Meus textos" fica à parte', () {
      expect(indice.baralhos.map((b) => b.id), ['tr:primeiro-contato', 'tr:dia-a-dia', 'txt:abc']);
      expect(indice.grupos, ['A1 · Fundação', 'A2 · Dia a dia', 'Meus textos']);
      expect(indice.baralho('txt:abc')!.propria, isTrue);
      expect(indice.baralho('txt:abc')!.nome, 'Minha viagem');
      expect(indice.baralho('nao-existe'), isNull);
      expect(indice.doGrupo('A2 · Dia a dia').single.id, 'tr:dia-a-dia');
    });

    test('cada frase aparece uma vez por baralho; a repetida entre baralhos pertence aos dois', () {
      expect(indice.baralho('tr:dia-a-dia')!.frases.map((f) => f.cod), ['I was tired.', 'How are you?', 'See you tomorrow.']);
      expect(indice.baralhosDe[k(f2)], ['tr:primeiro-contato', 'tr:dia-a-dia']);
      expect(indice.pertence(k(f2), 'tr:dia-a-dia'), isTrue);
      expect(indice.pertence(Revisao.chaveReversa(k(f2)), 'tr:primeiro-contato'), isTrue, reason: 'o cartão invertido é da mesma frase');
      expect(indice.pertence(k(f1), 'tr:dia-a-dia'), isFalse);
      expect(indice.porChave[k(f1)], f1);
    });

    test('contar: aprendidas, a revisar, maduras e o sentido invertido', () {
      final madura = CartaoSrs(estabilidade: 40, dificuldade: 5, ultimoDia: hoje - 30, proximoDia: hoje + 10, revisoes: 5);
      final cartoes = {
        k(f1): fsrs.novo(hoje - 3), // vence
        k(f2): madura, // não vence, madura
        Revisao.chaveReversa(k(f1)): fsrs.novo(hoje - 3), // invertido vence
        Revisao.chaveReversa(k(f3)): madura, // invertido de outro baralho
      };
      final b1 = indice.baralho('tr:primeiro-contato')!;
      final c1 = indice.contar(b1, cartoes, hoje, ligados: {'tr:primeiro-contato'});
      expect((c1.total, c1.aprendidas, c1.devidas, c1.maduras), (2, 2, 1, 1));
      expect((c1.invertido, c1.invertidasTotal, c1.invertidasDevidas, c1.invertidasNovas), (true, 1, 1, 1));
      expect(c1.aRevisar, 2);

      final b2 = indice.baralho('tr:dia-a-dia')!;
      final c2 = indice.contar(b2, cartoes, hoje, ligados: const {});
      expect((c2.total, c2.aprendidas, c2.devidas, c2.maduras), (3, 1, 0, 2), reason: 'f2 e o invertido de f3 são maduros');
      expect((c2.invertido, c2.invertidasNovas), (false, 0), reason: 'desligado: nada novo');
    });

    test('frasesDosLigados: na ordem do curso, sem repetir', () {
      expect(indice.frasesDosLigados({'tr:dia-a-dia', 'tr:primeiro-contato'}).map((f) => f.cod),
          ['Nice to meet you.', 'How are you?', 'I was tired.', 'See you tomorrow.']);
      expect(indice.frasesDosLigados(const {}), isEmpty);
    });

    test('trilha vazia não vira baralho', () {
      expect(IndiceBaralhos.de([const Trilha(nivel: 'x', emoji: '', licoes: [])]).baralhos, isEmpty);
    });
  });

  group('estatísticas', () {
    test('previsão de carga: hoje inclui os atrasados; suspenso não conta; enterrado conta quando volta', () {
      final cartoes = {
        'atrasado': fsrs.novo(hoje - 9), // vence ontem
        'hoje': CartaoSrs(estabilidade: 3, dificuldade: 5, ultimoDia: hoje - 3, proximoDia: hoje),
        'amanha': CartaoSrs(estabilidade: 3, dificuldade: 5, ultimoDia: hoje - 2, proximoDia: hoje + 1),
        'daqui5': CartaoSrs(estabilidade: 9, dificuldade: 5, ultimoDia: hoje, proximoDia: hoje + 5),
        'longe': CartaoSrs(estabilidade: 90, dificuldade: 5, ultimoDia: hoje, proximoDia: hoje + 90),
        'suspenso': fsrs.novo(hoje - 9).comSuspenso(true),
        'enterrado': fsrs.novo(hoje - 9).comEnterradoAte(hoje + 2),
      };
      final c = previsaoDeCarga(cartoes, hoje, dias: 7);
      expect(c, [2, 1, 1, 0, 0, 1, 0]);
      expect(previsaoDeCarga({}, hoje), List.filled(14, 0));
    });

    test('retenção real: só revisões de cartões já aprendidos, na janela, e só com amostra mínima', () {
      final h = [
        const EntradaHistorico(100, 'a', 3),
        const EntradaHistorico(100, 'b', 1),
        const EntradaHistorico(101, 'c', 4),
        const EntradaHistorico(101, 'd', 2),
        const EntradaHistorico(101, 'e', 3),
        const EntradaHistorico(101, 'f', 1, primeira: true), // 1ª vez: fora
        const EntradaHistorico(10, 'g', 1), // antes da janela: fora
      ];
      expect(retencaoReal(h, desdeDia: 50), closeTo(4 / 5, 1e-9));
      expect(retencaoReal(h, desdeDia: 50, minimo: 6), isNull, reason: 'amostra pequena demais');
      expect(retencaoReal(const [], desdeDia: 0), isNull);
    });

    test('revisões por dia: os últimos N dias, o último é hoje', () {
      final h = [
        EntradaHistorico(hoje, 'a', 3),
        EntradaHistorico(hoje, 'b', 3),
        EntradaHistorico(hoje - 1, 'c', 3),
        EntradaHistorico(hoje - 6, 'd', 3),
        EntradaHistorico(hoje - 7, 'e', 3), // fora da janela de 7
        EntradaHistorico(hoje + 1, 'f', 3), // futuro: fora
      ];
      expect(revisoesPorDia(h, hoje, dias: 7), [1, 0, 0, 0, 0, 1, 2]);
    });

    test('descrever vencimento em português', () {
      CartaoSrs em(int d) => CartaoSrs(estabilidade: 5, dificuldade: 5, ultimoDia: hoje - 1, proximoDia: hoje + d);
      expect(descreverVencimento(em(-3), hoje), 'atrasado 3 dias');
      expect(descreverVencimento(em(-1), hoje), 'atrasado 1 dia');
      expect(descreverVencimento(em(0), hoje), 'vence hoje');
      expect(descreverVencimento(em(1), hoje), 'amanhã');
      expect(descreverVencimento(em(20), hoje), 'em 3 sem');
      expect(descreverVencimento(em(0).comSuspenso(true), hoje), 'suspenso');
      expect(descreverVencimento(em(-3).comEnterradoAte(hoje + 1), hoje), 'enterrado até amanhã');
    });
  });

  group('RevisaoCubit: cartão invertido, novos por dia, ajustes e escondidos', () {
    RevisaoCubit cubit(RepoMemoria repo, {ConfigMemoria? cfg, int dias = 0, bool fixo = true}) => RevisaoCubit(
          repo: repo,
          configRepo: cfg,
          agendador: fixo ? fsrs : null,
          agora: () => DateTime(2026, 10, 12).add(Duration(days: dias)),
        );

    test('registrarVirar: o cartão nasce com a nota decidindo o intervalo e vai ao histórico como 1ª vez', () async {
      final repo = RepoMemoria();
      final c = cubit(repo);
      await assenta();
      await c.registrarVirar(f1, Rating.easy);
      final chave = RevisaoCubit.chaveReversaDe(f1);
      expect(c.state.cartoes[chave], fsrs.novo(hoje, nota: Rating.easy, voltaAmanha: false));
      expect(c.state.cartoes[chave]!.proximoDia - hoje, greaterThan(10));
      expect(c.state.cartoes.containsKey(k(f1)), isFalse, reason: 'o cartão digitado não é criado por isso');
      expect(repo.historico.single, EntradaHistorico(hoje, chave, 4, primeira: true));
    });

    test('registrarVirar num cartão que já existe: avalia (não é 1ª vez)', () async {
      final chave = RevisaoCubit.chaveReversaDe(f1);
      final inicial = fsrs.novo(hoje - 9, voltaAmanha: false);
      final repo = RepoMemoria({chave: inicial});
      final c = cubit(repo);
      await assenta();
      await c.registrarVirar(f1, Rating.again);
      expect(c.state.cartoes[chave], fsrs.avaliar(inicial, Rating.again, hoje));
      expect(c.state.cartoes[chave]!.lapsos, 1);
      expect(repo.historico.single, EntradaHistorico(hoje, chave, 1));
    });

    test('os dois sentidos têm memória independente: errar um não mexe no outro', () async {
      final dir = fsrs.avaliar(fsrs.novo(hoje - 20), Rating.good, hoje - 19);
      final repo = RepoMemoria({k(f1): dir});
      final c = cubit(repo);
      await assenta();
      await c.registrarVirar(f1, Rating.again);
      expect(c.state.cartoes[k(f1)], dir);
    });

    test('novasReversas: só as sem cartão invertido, na ordem, sem repetir e dentro da cota do dia', () async {
      final repo = RepoMemoria({RevisaoCubit.chaveReversaDe(f2): fsrs.novo(hoje - 1)});
      final cfg = ConfigMemoria(const ConfigSrs(novosPorDia: 2));
      final c = cubit(repo, cfg: cfg);
      await assenta();
      expect(c.vagasDeNovos, 2);
      expect(c.novasReversas([f1, f2, f1, f3, f4]), [f1, f3], reason: 'f2 já é cartão, f1 repetida, cota de 2');
      await c.registrarVirar(f1, Rating.good); // entrou um novo hoje
      expect(c.introduzidasHoje, 1);
      expect(c.vagasDeNovos, 1);
      expect(c.novasReversas([f1, f3, f4]), [f3]);
      await c.registrarVirar(f3, Rating.good);
      expect(c.novasReversas([f4]), isEmpty, reason: 'cota do dia esgotada');
      // amanhã a cota volta
      final amanha = cubit(repo, cfg: cfg, dias: 1);
      await assenta();
      expect(amanha.introduzidasHoje, 0);
      expect(amanha.novasReversas([f4]), [f4]);
    });

    test('0 novos por dia = nenhum novo; rever um cartão antigo hoje não conta como novo do dia', () async {
      final antigo = fsrs.novo(hoje - 9, voltaAmanha: false);
      final repo = RepoMemoria({RevisaoCubit.chaveReversaDe(f1): antigo});
      final c = cubit(repo, cfg: ConfigMemoria(const ConfigSrs(novosPorDia: 0)));
      await assenta();
      expect(c.novasReversas([f2, f3]), isEmpty);
      final d = cubit(repo, cfg: ConfigMemoria(const ConfigSrs(novosPorDia: 1)));
      await assenta();
      await d.registrarVirar(f1, Rating.good);
      expect(d.introduzidasHoje, 0, reason: 'o cartão não era novo');
      expect(d.vagasDeNovos, 1);
    });

    test('devidas() mistura os dois sentidos e usa o limite dos ajustes', () async {
      final repo = RepoMemoria({
        k(f1): fsrs.novo(hoje - 5),
        RevisaoCubit.chaveReversaDe(f1): fsrs.novo(hoje - 5),
        k(f2): fsrs.novo(hoje - 5),
      });
      final c = cubit(repo, cfg: ConfigMemoria(const ConfigSrs(limiteRevisoes: 2)));
      await assenta();
      expect(c.state.quantasDevidas(hoje), 3);
      expect(c.devidas().length, 2, reason: 'o limite dos ajustes');
      expect(c.devidas(limite: 10).length, 3);
    });

    test('mudarConfig: aplica na hora, guarda uma vez e ignora o que não mudou', () async {
      final cfg = ConfigMemoria();
      final c = cubit(RepoMemoria(), cfg: cfg);
      await assenta();
      await c.mudarConfig(c.state.config.copyWith(novosPorDia: 3));
      expect(c.state.config.novosPorDia, 3);
      expect(cfg.atual.novosPorDia, 3);
      expect(cfg.gravacoes, 1);
      await c.mudarConfig(c.state.config);
      expect(cfg.gravacoes, 1, reason: 'igual: não grava de novo');
    });

    test('os ajustes salvos voltam no próximo acesso', () async {
      final cfg = ConfigMemoria(const ConfigSrs(limiteRevisoes: 20, reversos: {'tr:x'}));
      final c = cubit(RepoMemoria(), cfg: cfg);
      await assenta();
      expect(c.state.config.limiteRevisoes, 20);
      expect(c.state.config.reversoLigado('tr:x'), isTrue);
    });

    test('a retenção dos ajustes muda o agendador (retenção maior = revisa antes)', () async {
      final repo = RepoMemoria({k(f1): AgendadorFsrs(fuzz: false).novo(hoje - 1)});
      final c = cubit(repo, fixo: false);
      await assenta();
      final p90 = c.previsao(k(f1))[Rating.good]!;
      await c.mudarConfig(c.state.config.copyWith(retencao: .95));
      final p95 = c.previsao(k(f1))[Rating.good]!;
      await c.mudarConfig(c.state.config.copyWith(retencao: .85));
      final p85 = c.previsao(k(f1))[Rating.good]!;
      expect(p95, lessThan(p90));
      expect(p90, lessThan(p85));
    });

    test('previsao() de um cartão que ainda não existe parte de cartão novo', () async {
      final c = cubit(RepoMemoria());
      await assenta();
      expect(c.previsao(RevisaoCubit.chaveReversaDe(f1)), fsrs.previsao(null, hoje));
    });

    test('suspender e enterrar: somem das devidas, não vão ao histórico, e reativar volta', () async {
      final repo = RepoMemoria({k(f1): fsrs.novo(hoje - 5), k(f2): fsrs.novo(hoje - 5)});
      final c = cubit(repo);
      await assenta();
      await c.suspender(k(f1), suspenso: true);
      expect(c.devidas(), [k(f2)]);
      expect(repo.cartoes[k(f1)]!.suspenso, isTrue, reason: 'gravado');
      await c.enterrar(k(f2));
      expect(c.devidas(), isEmpty);
      expect(c.state.cartoes[k(f2)]!.proximoDia, repo.cartoes[k(f2)]!.proximoDia);
      expect(repo.historico, isEmpty);
      await c.suspender(k(f1), suspenso: false);
      expect(c.devidas(), [k(f1)]);
      // amanhã o enterrado volta
      final amanha = cubit(repo, dias: 1);
      await assenta();
      expect(amanha.devidas().toSet(), {k(f1), k(f2)});
      // cartão inexistente: nada acontece
      await c.suspender('nao-existe', suspenso: true);
      await c.enterrar('nao-existe');
      expect(c.state.cartoes.containsKey('nao-existe'), isFalse);
    });
  });
}
