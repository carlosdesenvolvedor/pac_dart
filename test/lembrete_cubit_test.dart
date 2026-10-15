import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/habito/data/agendador_lembrete.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/habito/data/lembrete_repository.dart';
import 'package:pac_dart/features/habito/domain/habito.dart';
import 'package:pac_dart/features/habito/domain/lembrete.dart';
import 'package:pac_dart/features/habito/presentation/habito_cubit.dart';
import 'package:pac_dart/features/habito/presentation/lembrete_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O sistema de mentira: guarda cada chamada em ordem, para o teste conferir o que foi (ou não foi) agendado.
class AgendadorFalso implements AgendadorDeLembrete {
  @override
  bool disponivel;
  bool concede;
  AgendadorFalso({this.disponivel = true, this.concede = true});

  int permissoes = 0;
  int cancelamentos = 0;
  final listas = <List<LembreteAgendado>>[];
  final eventos = <String>[];
  Completer<void>? segura;

  List<LembreteAgendado> get ultima => listas.last;

  @override
  Future<bool> pedirPermissao() async {
    permissoes++;
    eventos.add('permissao');
    return concede;
  }

  @override
  Future<void> substituir(List<LembreteAgendado> lembretes) async {
    eventos.add('substituir:${lembretes.length}');
    await segura?.future;
    listas.add(lembretes);
  }

  @override
  Future<void> cancelarTodos() async {
    eventos.add('cancelar');
    cancelamentos++;
  }
}

class RepoLembreteMemoria implements LembreteRepository {
  ConfigLembrete guardada;
  int salvamentos = 0;
  RepoLembreteMemoria([this.guardada = ConfigLembrete.padrao]);

  @override
  Future<ConfigLembrete> carregar() async => guardada;
  @override
  Future<void> salvar(ConfigLembrete config) async {
    salvamentos++;
    guardada = config;
  }
}

/// Um hábito que demora para carregar (o teste decide quando termina).
class RepoHabitoLento implements HabitoRepository {
  final Completer<Habito> espera = Completer<Habito>();
  @override
  Future<Habito> carregar() => espera.future;
  @override
  Future<void> salvar(Habito habito) async {}
}

class Relogio {
  DateTime t = DateTime(2026, 10, 13, 10, 0);
  DateTime call() => t;
  void dias(int n) => t = DateTime(t.year, t.month, t.day + n, 10);
}

Future<void> pump() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

String dia(DateTime d) => '${d.year}-${d.month}-${d.day}';

void main() {
  late Relogio relogio;
  late AgendadorFalso ag;
  late RepoLembreteMemoria repo;
  late HabitoCubit habito;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    relogio = Relogio();
    ag = AgendadorFalso();
    repo = RepoLembreteMemoria();
    habito = HabitoCubit(repo: LocalHabitoRepository(), agora: relogio.call);
  });

  Future<LembreteCubit> criar({bool comHabito = true}) async {
    final c = LembreteCubit(repo: repo, agendador: ag, habito: comHabito ? habito : null, agora: relogio.call);
    await c.carregar();
    await pump();
    return c;
  }

  tearDown(() async {
    await habito.close();
  });

  group('abrir o app', () {
    test('desligado de fábrica: carrega, não pede permissão e deixa o sistema sem lembretes do app', () async {
      final c = await criar();
      expect(c.state.carregado, isTrue);
      expect(c.state.disponivel, isTrue);
      expect(c.state.config, ConfigLembrete.padrao);
      expect(ag.permissoes, 0, reason: 'a permissão só é pedida quando a pessoa liga');
      expect(ag.ultima, isEmpty, reason: 'desligado ⇒ nada agendado (e os antigos saem)');
      await c.close();
    });

    test('ligado de antes: cada abertura RENOVA os 7 dias', () async {
      repo.guardada = const ConfigLembrete(ligado: true, hora: 20, minuto: 0);
      final c = await criar();
      expect(ag.ultima.length, 7);
      expect(dia(ag.ultima.first.quando), '2026-10-13');
      expect(ag.permissoes, 0, reason: 'já ligado: não pede de novo ao abrir');
      await c.close();
    });

    test('abrir já com a meta de hoje batida: hoje fica de fora', () async {
      habito.praticou(20);
      await pump();
      repo.guardada = const ConfigLembrete(ligado: true);
      final c = await criar();
      expect(ag.ultima.length, 6);
      expect(dia(ag.ultima.first.quando), '2026-10-14');
      await c.close();
    });

    test('a leitura espera o hábito carregar (não agenda hoje "à toa")', () async {
      habito.praticou(20); // enquanto o hábito ainda carrega
      repo.guardada = const ConfigLembrete(ligado: true);
      final c = LembreteCubit(repo: repo, agendador: ag, habito: habito, agora: relogio.call);
      await c.carregar();
      await pump();
      expect(ag.listas.length, 1, reason: 'um único agendamento, já com o hábito lido');
      expect(ag.ultima.length, 6);
      await c.close();
    });

    test('o hábito DEMORA a carregar: o lembrete espera e agenda uma vez só, já sem hoje (nada de agendar hoje "à toa")', () async {
      // meta de hoje já batida no que está guardado
      final batida = const Habito().registrar(20, relogio.call());
      final lento = RepoHabitoLento();
      final h2 = HabitoCubit(repo: lento, agora: relogio.call);
      repo.guardada = const ConfigLembrete(ligado: true);
      final c = LembreteCubit(repo: repo, agendador: ag, habito: h2, agora: relogio.call);
      await pump();
      expect(c.state.carregado, isFalse, reason: 'esperando o hábito');
      expect(ag.listas, isEmpty, reason: 'ainda não agendou nada');
      lento.espera.complete(batida);
      await pump();
      expect(c.state.carregado, isTrue);
      expect(ag.listas.length, 1, reason: 'um único agendamento, já com o hábito lido');
      expect(ag.ultima.length, 6);
      expect(dia(ag.ultima.first.quando), '2026-10-14');
      await c.close();
      await h2.close();
    });

    test('sem o cubit do hábito funciona (a meta é tratada como não batida)', () async {
      repo.guardada = const ConfigLembrete(ligado: true);
      final c = await criar(comHabito: false);
      expect(ag.ultima.length, 7);
      await c.close();
    });
  });

  group('ligar e desligar', () {
    test('ligar PEDE a permissão, guarda e agenda os próximos 7 dias', () async {
      final c = await criar();
      await c.ligar(true);
      await pump();
      expect(ag.permissoes, 1);
      expect(c.state.config.ligado, isTrue);
      expect(c.state.permissaoNegada, isFalse);
      expect(repo.guardada.ligado, isTrue);
      expect(ag.ultima.length, 7);
      expect(ag.eventos.indexOf('permissao'), lessThan(ag.eventos.lastIndexOf('substituir:7')), reason: 'primeiro a permissão, depois agenda');
      await c.close();
    });

    test('permissão NEGADA: continua desligado, não guarda, não agenda e avisa', () async {
      ag.concede = false;
      final c = await criar();
      final antes = ag.listas.length;
      await c.ligar(true);
      await pump();
      expect(c.state.config.ligado, isFalse);
      expect(c.state.permissaoNegada, isTrue);
      expect(repo.salvamentos, 0);
      expect(repo.guardada.ligado, isFalse);
      expect(ag.listas.length, antes, reason: 'nada novo foi agendado');
      // liberou nas configurações e tentou de novo
      ag.concede = true;
      await c.ligar(true);
      await pump();
      expect(c.state.permissaoNegada, isFalse);
      expect(c.state.config.ligado, isTrue);
      expect(ag.ultima.length, 7);
      await c.close();
    });

    test('desligar: guarda e cancela o que estava agendado', () async {
      final c = await criar();
      await c.ligar(true);
      await pump();
      await c.ligar(false);
      await pump();
      expect(c.state.config.ligado, isFalse);
      expect(repo.guardada.ligado, isFalse);
      expect(ag.ultima, isEmpty);
      expect(ag.permissoes, 1, reason: 'desligar não pede nada');
      await c.close();
    });

    test('ligar quando já está ligado não pede de novo nem reagenda', () async {
      final c = await criar();
      await c.ligar(true);
      await pump();
      final n = ag.listas.length;
      await c.ligar(true);
      await pump();
      expect(ag.permissoes, 1);
      expect(ag.listas.length, n);
      await c.close();
    });

    test('aparelho sem suporte (web/desktop): nada é pedido nem agendado, e ligar não faz nada', () async {
      ag = AgendadorFalso(disponivel: false);
      final c = await criar();
      await c.ligar(true);
      await pump();
      expect(c.state.disponivel, isFalse);
      expect(c.state.config.ligado, isFalse);
      expect(ag.permissoes, 0);
      expect(ag.listas, isEmpty);
      expect(ag.eventos, isEmpty);
      await c.close();
      expect(ag.cancelamentos, 0, reason: 'sem suporte nem cancela');
    });
  });

  group('horário', () {
    test('mudar o horário guarda e reagenda no novo horário', () async {
      final c = await criar();
      await c.ligar(true);
      await pump();
      await c.mudarHorario(7, 30);
      await pump();
      expect(c.state.config, const ConfigLembrete(ligado: true, hora: 7, minuto: 30));
      expect(repo.guardada.horario, '07:30');
      expect(ag.ultima.every((x) => x.quando.hour == 7 && x.quando.minute == 30), isTrue);
      expect(dia(ag.ultima.first.quando), '2026-10-14', reason: 'são 10:00: o 07:30 de hoje já passou');
      await c.close();
    });

    test('horário inválido é ignorado', () async {
      final c = await criar();
      await c.ligar(true);
      await pump();
      final n = ag.listas.length;
      for (final (h, m) in [(24, 0), (-1, 0), (8, 60), (8, -1)]) {
        await c.mudarHorario(h, m);
      }
      await pump();
      expect(c.state.config.horario, '20:00');
      expect(ag.listas.length, n);
      await c.close();
    });

    test('mesmo horário: não reagenda; desligado: guarda mas não agenda', () async {
      final c = await criar();
      final n0 = ag.listas.length;
      await c.mudarHorario(21, 0);
      await pump();
      expect(repo.guardada.horario, '21:00', reason: 'guarda o horário mesmo desligado');
      expect(ag.listas.length, n0, reason: 'desligado: nada a agendar');
      await c.ligar(true);
      await pump();
      final n1 = ag.listas.length;
      await c.mudarHorario(21, 0);
      await pump();
      expect(ag.listas.length, n1);
      await c.close();
    });

    test('duas mudanças seguidas: a ordem é respeitada (a última vence no sistema)', () async {
      final c = await criar();
      unawaited(c.ligar(true));
      unawaited(c.mudarHorario(6, 15));
      unawaited(c.mudarHorario(9, 45));
      await pump();
      expect(ag.ultima.every((x) => x.quando.hour == 9 && x.quando.minute == 45), isTrue);
      await c.close();
    });

    test('um agendamento lento não é atropelado pelo seguinte (um de cada vez)', () async {
      final c = await criar();
      await c.ligar(true);
      await pump();
      ag.segura = Completer<void>();
      final n = ag.eventos.length;
      unawaited(c.mudarHorario(6, 0));
      unawaited(c.mudarHorario(7, 0));
      await pump();
      expect(ag.eventos.skip(n).where((e) => e.startsWith('substituir')).length, 1, reason: 'o 2º espera o 1º terminar');
      ag.segura!.complete();
      await pump();
      expect(ag.eventos.skip(n).where((e) => e.startsWith('substituir')).length, 2);
      expect(ag.ultima.first.quando.hour, 7);
      await c.close();
    });
  });

  group('a meta do dia', () {
    test('bater a meta REAGENDA sem hoje; um exercício que não bate a meta NÃO reagenda', () async {
      final c = await criar();
      await c.mudarHorario(21, 0); // às 10:00, hoje ainda vale
      await c.ligar(true);
      await pump();
      expect(ag.ultima.length, 7);
      final n = ag.listas.length;
      habito.praticou(5);
      habito.praticou(5);
      await pump();
      expect(ag.listas.length, n, reason: '10 de 20: a meta ainda não foi batida');
      habito.praticou(10); // 20/20: bateu
      await pump();
      expect(ag.listas.length, n + 1);
      expect(ag.ultima.length, 6);
      expect(dia(ag.ultima.first.quando), '2026-10-14');
      // mais exercícios no mesmo dia não mudam nada
      habito.praticou(10);
      await pump();
      expect(ag.listas.length, n + 1);
      await c.close();
    });

    test('virou o dia: a meta de hoje volta a valer e o dia de hoje entra de novo', () async {
      final c = await criar();
      await c.mudarHorario(21, 0);
      await c.ligar(true);
      habito.praticou(20);
      await pump();
      expect(ag.ultima.length, 6);
      relogio.dias(1);
      habito.praticou(1); // 1/20 no dia novo
      await pump();
      expect(ag.ultima.length, 7);
      expect(dia(ag.ultima.first.quando), '2026-10-14');
      await c.close();
    });

    test('com o lembrete DESLIGADO bater a meta não agenda nada', () async {
      final c = await criar();
      final n = ag.listas.length;
      habito.praticou(20);
      await pump();
      expect(ag.listas.length, n);
      await c.close();
    });

    test('o lembrete só LÊ o hábito: não muda sequência nem exercícios', () async {
      final c = await criar();
      await c.ligar(true);
      habito.praticou(7);
      await pump();
      final antes = habito.state.habito;
      await c.mudarHorario(9, 0);
      await c.ligar(false);
      await pump();
      expect(habito.state.habito, antes);
      await c.close();
    });
  });

  group('fechar (sair da conta)', () {
    test('o último cubit cancela ao fechar', () async {
      final c = await criar();
      await c.ligar(true);
      await pump();
      await c.close();
      await pump();
      expect(ag.cancelamentos, 1);
      expect(ag.eventos.last, 'cancelar');
    });

    test('na troca de conta o cubit ANTIGO não apaga o que o novo agendou', () async {
      final velho = await criar();
      await velho.ligar(true);
      await pump();
      final repo2 = RepoLembreteMemoria(const ConfigLembrete(ligado: true, hora: 8, minuto: 0));
      final novo = LembreteCubit(repo: repo2, agendador: ag, habito: habito, agora: relogio.call);
      await novo.carregar();
      await pump();
      await velho.close();
      await pump();
      expect(ag.cancelamentos, 0, reason: 'o novo já assumiu');
      expect(ag.ultima.first.quando.hour, 8);
      await novo.close();
      await pump();
      expect(ag.cancelamentos, 1);
    });

    test('depois de fechado, nada mais é agendado (mudança do hábito é ignorada)', () async {
      final c = await criar();
      await c.mudarHorario(21, 0);
      await c.ligar(true);
      await pump();
      await c.close();
      await pump();
      final n = ag.listas.length;
      habito.praticou(20);
      await pump();
      expect(ag.listas.length, n);
    });
  });

  test('LembreteState: igualdade e copyWith', () {
    const a = LembreteState(disponivel: true);
    expect(a.copyWith(carregado: true), isNot(a));
    expect(a.copyWith(carregado: true).disponivel, isTrue);
    expect(a.copyWith(), a);
  });
}
