import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/habito/domain/habito.dart';
import 'package:pac_dart/features/habito/presentation/habito_cubit.dart';

/// Repositório em memória que anota o que foi gravado; pode atrasar a leitura e falhar ao gravar.
class RepoFalso implements HabitoRepository {
  Habito guardado;
  final gravacoes = <Habito>[];
  bool falhaAoGravar = false;
  Completer<void>? seguraLeitura;
  Completer<void>? seguraGravacao;

  RepoFalso([this.guardado = Habito.vazio]);

  @override
  Future<Habito> carregar() async {
    await seguraLeitura?.future;
    return guardado;
  }

  @override
  Future<void> salvar(Habito habito) async {
    await seguraGravacao?.future;
    if (falhaAoGravar) throw Exception('sem rede');
    gravacoes.add(habito);
    guardado = habito;
  }
}

/// O relógio do teste: anda quando o teste manda.
class Relogio {
  DateTime t;
  Relogio([DateTime? t]) : t = t ?? DateTime(2026, 10, 12, 10);
  DateTime call() => t;
  void dias(int n, {int h = 10, int min = 0}) => t = DateTime(t.year, t.month, t.day + n, h, min);
}

void main() {
  late Relogio relogio;
  late RepoFalso repo;
  setUp(() {
    relogio = Relogio();
    repo = RepoFalso();
  });

  Future<HabitoCubit> criar([RepoFalso? r]) async {
    final c = HabitoCubit(repo: r ?? repo, agora: relogio.call);
    await c.carregar();
    return c;
  }

  test('carrega o hábito do repositório', () async {
    repo.guardado = Habito.vazio.registrar(20, DateTime(2026, 10, 11));
    final c = await criar();
    expect(c.state.carregado, isTrue);
    expect(c.state.habito.sequencia, 1);
    await c.close();
  });

  test('antes de carregar o estado é neutro; erro ao ler vira hábito vazio', () async {
    final c = HabitoCubit(repo: _RepoQueFalhaNaLeitura(), agora: relogio.call);
    expect(c.state.carregado, isFalse);
    await c.carregar();
    expect(c.state.carregado, isTrue);
    expect(c.state.habito, Habito.vazio);
    await c.close();
  });

  test('praticou emite NA HORA (antes de gravar) e grava depois', () async {
    final c = await criar();
    repo.seguraGravacao = Completer<void>();
    c.praticou();
    expect(c.state.habito.unidadesHoje, 1, reason: 'a tela não espera a gravação');
    expect(repo.gravacoes, isEmpty);
    repo.seguraGravacao!.complete();
    await pumpEventQueue();
    expect(repo.gravacoes.last.unidadesHoje, 1);
    await c.close();
  });

  test('2 chamadas seguidas (2 telas quase juntas) não perdem unidade, nem na gravação', () async {
    final c = await criar();
    repo.seguraGravacao = Completer<void>();
    c.praticou();
    c.praticou();
    c.praticou(3);
    expect(c.state.habito.unidadesHoje, 5);
    repo.seguraGravacao!.complete();
    await pumpEventQueue();
    expect(repo.guardado.unidadesHoje, 5, reason: 'a última gravação tem tudo');
    await c.close();
  });

  test('bater a meta: sobe a sequência e conta UMA transição de aviso', () async {
    final c = await criar();
    for (var i = 0; i < 19; i++) {
      c.praticou();
    }
    expect(c.state.metasBatidas, 0);
    expect(c.state.habito.sequencia, 0);
    c.praticou();
    expect(c.state.habito.sequencia, 1);
    expect(c.state.metasBatidas, 1);
    c.praticou(10);
    c.praticou();
    expect(c.state.metasBatidas, 1, reason: 'depois de bater, o mesmo dia não avisa de novo');
    await c.close();
  });

  test('virada do dia: zera o contador, avisa de novo no dia seguinte e a sequência sobe', () async {
    final c = await criar();
    c.praticou(20);
    relogio.dias(1);
    c.praticou(5);
    expect(c.state.habito.unidadesHoje, 5);
    expect(c.state.metasBatidas, 1);
    c.praticou(15);
    expect(c.state.habito.sequencia, 2);
    expect(c.state.metasBatidas, 2);
    await c.close();
  });

  test('um dia perdido sem congelamento recomeça em 1; com congelamento mantém', () async {
    final c = await criar();
    c.praticou(20);
    relogio.dias(2);
    c.praticou(20);
    expect(c.state.habito.sequencia, 1);

    relogio.t = DateTime(2026, 10, 12, 10);
    final c2 = await criar(RepoFalso(Habito(
      dia: diaDe(DateTime(2026, 10, 10)),
      sequencia: 6,
      melhor: 6,
      ultimoDiaMeta: diaDe(DateTime(2026, 10, 10)),
      congelamentos: 1,
    )));
    c2.praticou(20);
    expect(c2.state.habito.sequencia, 7);
    expect(c2.state.habito.congelamentos, 1, reason: 'gastou 1 e ganhou 1 ao chegar a 7');
    await c.close();
    await c2.close();
  });

  test('erro ao gravar: engolido, a tela segue certa e o próximo salvar tenta de novo', () async {
    final c = await criar();
    repo.falhaAoGravar = true;
    c.praticou(3);
    await pumpEventQueue();
    expect(c.state.habito.unidadesHoje, 3);
    expect(repo.gravacoes, isEmpty);
    repo.falhaAoGravar = false;
    c.praticou(2);
    await pumpEventQueue();
    expect(repo.guardado.unidadesHoje, 5, reason: 'o estado inteiro vai, não só o evento novo');
    await c.close();
  });

  test('gravações em ordem e sem empilhar: durante uma gravação lenta só a mais nova segue', () async {
    final c = await criar();
    repo.seguraGravacao = Completer<void>();
    for (var i = 0; i < 5; i++) {
      c.praticou();
    }
    repo.seguraGravacao!.complete();
    await pumpEventQueue();
    // 1ª gravação (com 1) já estava em curso; depois só a última (com 5)
    expect(repo.gravacoes.length, 2);
    expect(repo.gravacoes.last.unidadesHoje, 5);
    await c.close();
  });

  test('o que foi feito ENQUANTO carregava entra por cima do que veio', () async {
    repo.guardado = Habito.vazio.registrar(18, DateTime(2026, 10, 12, 8));
    repo.seguraLeitura = Completer<void>();
    final c = HabitoCubit(repo: repo, agora: relogio.call);
    c.praticou();
    c.praticou();
    expect(c.state.carregado, isFalse);
    repo.seguraLeitura!.complete();
    await c.carregar();
    expect(c.state.habito.unidadesHoje, 20);
    expect(c.state.habito.sequencia, 1, reason: 'as 2 unidades pendentes bateram a meta');
    expect(c.state.metasBatidas, 1);
    await pumpEventQueue();
    expect(repo.guardado.sequencia, 1, reason: 'e foi gravado');
    await c.close();
  });

  test('mudar a meta para menos depois de já ter feito os exercícios bate a meta (e avisa)', () async {
    final c = await criar();
    c.praticou(12);
    c.mudarMeta(10);
    expect(c.state.habito.meta, 10);
    expect(c.state.habito.sequencia, 1);
    expect(c.state.metasBatidas, 1);
    await pumpEventQueue();
    expect(repo.guardado.meta, 10);
    await c.close();
  });

  test('meta inválida e unidades inválidas são ignoradas', () async {
    final c = await criar();
    c.mudarMeta(15);
    c.praticou(0);
    c.praticou(-2);
    expect(c.state.habito, Habito.vazio);
    expect(repo.gravacoes, isEmpty);
    await c.close();
  });

  test('praticou depois de fechado não lança', () async {
    final c = await criar();
    await c.close();
    c.praticou();
    c.mudarMeta(10);
  });
}

class _RepoQueFalhaNaLeitura implements HabitoRepository {
  @override
  Future<Habito> carregar() async => throw Exception('sem rede');
  @override
  Future<void> salvar(Habito habito) async {}
}
