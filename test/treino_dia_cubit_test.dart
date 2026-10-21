import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/habito/domain/habito.dart' show diaDe;
import 'package:pac_dart/features/treino_dia/data/treino_dia_repository.dart';
import 'package:pac_dart/features/treino_dia/domain/montar_plano.dart';
import 'package:pac_dart/features/treino_dia/domain/plano_treino.dart';
import 'package:pac_dart/features/treino_dia/presentation/treino_dia_cubit.dart';

/// O relógio do teste: anda quando o teste manda.
class Relogio {
  DateTime t;
  Relogio([DateTime? t]) : t = t ?? DateTime(2026, 10, 21, 10);
  DateTime call() => t;
}

/// Repositório em memória que pode segurar a leitura e a gravação, e falhar ao gravar.
class RepoFalso extends MemoriaTreinoDiaRepository {
  Completer<void>? seguraLeitura;
  Completer<void>? seguraGravacao;
  bool falhaAoGravar = false;
  final salvos = <PlanoTreino>[];

  RepoFalso([super.inicial]);

  @override
  Future<PlanoTreino?> carregar() async {
    await seguraLeitura?.future;
    return super.carregar();
  }

  @override
  Future<void> salvar(PlanoTreino p) async {
    await seguraGravacao?.future;
    if (falhaAoGravar) throw Exception('sem rede');
    salvos.add(p);
    await super.salvar(p);
  }
}

const _fontesIngles = FontesTreino(
  ingles: true,
  frasesDevidas: 5,
  cartoes: 2,
  teimosas: 3,
  temOuvir: true,
);

void main() {
  late Relogio relogio;
  late RepoFalso repo;
  setUp(() {
    relogio = Relogio();
    repo = RepoFalso();
  });

  TreinoDiaCubit novo([RepoFalso? r]) => TreinoDiaCubit(repo: r ?? repo, curso: 'ingles', agora: relogio.call);

  Future<TreinoDiaCubit> criar([RepoFalso? r]) async {
    final c = novo(r);
    await c.carregar();
    return c;
  }

  PlanoTreino montar(TreinoDiaCubit c, [FontesTreino f = _fontesIngles]) =>
      montarPlano(f, dia: c.hoje, curso: 'ingles', agoraMs: relogio.t.millisecondsSinceEpoch);

  test('carrega: sem plano salvo, carregado e situação pendente', () async {
    final c = novo();
    expect(c.state.carregado, isFalse);
    await c.carregar();
    expect(c.state.carregado, isTrue);
    expect(c.state.plano, isNull);
    expect(c.planoDeHoje, isNull);
    expect(c.situacao, SituacaoTreino.pendente);
    expect(c.hoje, diaDe(relogio.t));
    await c.close();
  });

  test('erro ao ler: plano nulo, sem lançar', () async {
    final c = TreinoDiaCubit(repo: _RepoQueFalha(), curso: 'dart', agora: relogio.call);
    await c.carregar();
    expect((c.state.carregado, c.state.plano), (true, null));
    await c.close();
  });

  test('iniciar cria UMA vez por dia e devolve o mesmo plano na 2ª chamada', () async {
    final c = await criar();
    var montagens = 0;
    final p = c.iniciar(() {
      montagens++;
      return montar(c);
    });
    expect(c.planoDeHoje, p);
    expect(c.situacao, SituacaoTreino.pendente);
    final de = c.iniciar(() {
      montagens++;
      return montar(c, const FontesTreino(ingles: true));
    });
    expect(de, same(p));
    expect(montagens, 1);
    await c.gravacoes;
    expect(repo.plano, p, reason: 'foi gravado');
    await c.close();
  });

  test('iniciar antes de carregar terminar → assert', () async {
    repo.seguraLeitura = Completer<void>();
    final c = novo();
    expect(() => c.iniciar(() => montar(c)), throwsA(isA<AssertionError>()));
    repo.seguraLeitura!.complete();
    await c.close();
  });

  test('o plano de hoje que já estava salvo é retomado (iniciar não monta outro)', () async {
    final salvo = montarPlano(_fontesIngles, dia: diaDe(relogio.t), curso: 'ingles', agoraMs: 1)
        .marcar('revisao', EstadoBloco.feito, resultado: 4, agoraMs: 2);
    final c = await criar(RepoFalso(salvo));
    expect(c.situacao, SituacaoTreino.emAndamento);
    expect(c.iniciar(() => fail('não devia montar')), salvo);
    await c.close();
  });

  test('leitura lenta com o plano de hoje em 2/4: nada aparece antes, e depois retoma em 2/4', () async {
    final salvo = montarPlano(_fontesIngles, dia: diaDe(relogio.t), curso: 'ingles', agoraMs: 1)
        .marcar('revisao', EstadoBloco.feito, resultado: 4, agoraMs: 2)
        .marcar('palavras', EstadoBloco.pulado, agoraMs: 3);
    final r = RepoFalso(salvo)..seguraLeitura = Completer<void>();
    final c = novo(r);
    await pumpEventQueue();
    expect(c.state.carregado, isFalse);
    expect(c.state.plano, isNull);
    expect(c.planoDeHoje, isNull);
    final esperando = c.carregar();
    r.seguraLeitura!.complete();
    await esperando;
    expect(c.planoDeHoje!.resolvidos, 2);
    expect(c.situacao, SituacaoTreino.emAndamento);
    expect(r.gravacoes, 0, reason: 'só leu; nada a regravar');
    await c.close();
  });

  test('marcar ANTES de carregar (não esperado) entra por cima do plano do mesmo dia; de outro dia, cai fora', () async {
    final salvo = montarPlano(_fontesIngles, dia: diaDe(relogio.t), curso: 'ingles', agoraMs: 1);
    final r = RepoFalso(salvo)..seguraLeitura = Completer<void>();
    final c = novo(r);
    c.marcar('revisao', EstadoBloco.feito, resultado: 3);
    c.anotarOuvir(['f1']);
    r.seguraLeitura!.complete();
    await c.carregar();
    expect(c.planoDeHoje!.blocos.first.estado, EstadoBloco.feito);
    expect(c.planoDeHoje!.ouvirChaves, ['f1']);
    await c.gravacoes;
    expect(r.plano, c.state.plano, reason: 'e foi gravado');
    await c.close();

    final ontem = montarPlano(_fontesIngles, dia: diaDe(relogio.t) - 1, curso: 'ingles', agoraMs: 1);
    final r2 = RepoFalso(ontem)..seguraLeitura = Completer<void>();
    final c2 = novo(r2);
    c2.marcar('revisao', EstadoBloco.feito, resultado: 3);
    expect(c2.tomarBonus(), isFalse, reason: 'antes de carregar não há plano para o bônus');
    r2.seguraLeitura!.complete();
    await c2.carregar();
    expect(c2.state.plano, ontem, reason: 'o plano de outro dia fica como estava');
    expect(r2.gravacoes, 0);
    await c2.close();
  });

  test('marcar emite na hora e grava depois (gravacoes)', () async {
    final c = await criar();
    c.iniciar(() => montar(c));
    await c.gravacoes;
    repo.seguraGravacao = Completer<void>();
    c.marcar('revisao', EstadoBloco.feito, resultado: 5);
    expect(c.planoDeHoje!.blocos.first.resultado, 5, reason: 'a tela não espera a gravação');
    expect(repo.plano!.blocos.first.estado, EstadoBloco.pendente);
    var gravou = false;
    unawaited(c.gravacoes.then((_) => gravou = true));
    await pumpEventQueue();
    expect(gravou, isFalse);
    repo.seguraGravacao!.complete();
    await c.gravacoes;
    expect(repo.plano!.blocos.first.resultado, 5);
    await c.close();
  });

  test('gravações em ordem e sem empilhar: só a mais nova segue', () async {
    final c = await criar();
    repo.seguraGravacao = Completer<void>();
    c.iniciar(() => montar(c));
    c.marcar('revisao', EstadoBloco.feito, resultado: 5);
    c.marcar('palavras', EstadoBloco.feito, resultado: 3);
    c.anotarFoco(['cat', 'dog']);
    repo.seguraGravacao!.complete();
    await c.gravacoes;
    expect(repo.salvos, hasLength(2), reason: 'a 1ª já estava em curso; depois só a última');
    expect(repo.plano, c.state.plano);
    await c.close();
  });

  test('erro ao gravar é engolido; a próxima mudança grava tudo', () async {
    final c = await criar();
    repo.falhaAoGravar = true;
    c.iniciar(() => montar(c));
    c.marcar('revisao', EstadoBloco.feito, resultado: 5);
    await c.gravacoes;
    expect(repo.plano, isNull);
    repo.falhaAoGravar = false;
    c.marcar('palavras', EstadoBloco.pulado);
    await c.gravacoes;
    expect(repo.plano!.resolvidos, 2);
    await c.close();
  });

  test('marcar sem mudança não grava; anotarOuvir/anotarFoco gravam', () async {
    final c = await criar();
    c.iniciar(() => montar(c));
    await c.gravacoes;
    final antes = repo.gravacoes;
    c.marcar('nada', EstadoBloco.feito);
    c.marcar('rali', EstadoBloco.pendente);
    await c.gravacoes;
    expect(repo.gravacoes, antes);
    c.anotarOuvir(['a', 'b']);
    c.anotarFoco(['cat']);
    await c.gravacoes;
    expect(repo.plano!.ouvirChaves, ['a', 'b']);
    expect(repo.plano!.palavrasFoco, ['cat']);
    await c.close();
  });

  test('meia-noite: planoDeHoje vira null, o plano de ontem ainda aceita marcar, e iniciar faz o de hoje', () async {
    relogio.t = DateTime(2026, 10, 21, 23, 58);
    final c = await criar();
    final ontem = c.iniciar(() => montar(c));
    c.marcar('revisao', EstadoBloco.feito, resultado: 2);
    expect(c.situacao, SituacaoTreino.emAndamento);

    relogio.t = DateTime(2026, 10, 22, 0, 1);
    expect(c.planoDeHoje, isNull);
    expect(c.situacao, SituacaoTreino.pendente);

    // a sessão aberta termina no próprio plano (sem regra de "ignora outro dia")
    c.marcar('palavras', EstadoBloco.feito, resultado: 3);
    expect(c.state.plano!.dia, ontem.dia);
    expect(c.state.plano!.blocos[1].estado, EstadoBloco.feito);

    final hoje = c.iniciar(() => montar(c));
    expect(hoje.dia, ontem.dia + 1);
    expect(c.planoDeHoje, hoje);
    expect(hoje.resolvidos, 0);
    await c.gravacoes;
    expect(repo.plano, hoje);
    await c.close();
  });

  test('completar troca o plano de hoje e grava; sem plano de hoje não faz nada', () async {
    final c = await criar();
    c.completar((p) => fail('sem plano de hoje não chama'));
    final p = c.iniciar(() => montar(c, const FontesTreino(ingles: true, temOuvir: true, incompleta: true)));
    expect(p.incompleto, isTrue);
    c.completar((atual) => completarPlano(atual, const FontesTreino(ingles: true, temOuvir: true, frasesDevidas: 3),
        agoraMs: relogio.t.millisecondsSinceEpoch));
    expect(c.planoDeHoje!.blocos.first.id, 'revisao');
    expect(c.planoDeHoje!.incompleto, isFalse);
    await c.gravacoes;
    expect(repo.plano, c.planoDeHoje);

    relogio.t = relogio.t.add(const Duration(days: 1));
    final antes = c.state.plano;
    c.completar((atual) => fail('o plano é de ontem'));
    expect(c.state.plano, antes);
    await c.close();
  });

  test('tomarBonus: true uma vez, depois false; recarregado com bonus continua false', () async {
    final c = await criar();
    c.iniciar(() => montar(c));
    expect(c.tomarBonus(), isFalse, reason: 'ainda não concluído');
    c.marcar('revisao', EstadoBloco.feito, resultado: 5);
    c.marcar('palavras', EstadoBloco.feito, resultado: 3);
    c.marcar('ouvir', EstadoBloco.pulado);
    c.marcar('rali', EstadoBloco.pulado);
    expect(c.situacao, SituacaoTreino.concluido);
    expect(c.tomarBonus(), isTrue);
    expect(c.state.plano!.bonus, isTrue);
    expect(c.tomarBonus(), isFalse);
    await c.gravacoes;
    expect(repo.plano!.bonus, isTrue);
    await c.close();

    final c2 = await criar(RepoFalso(repo.plano));
    expect(c2.state.plano!.bonus, isTrue);
    expect(c2.tomarBonus(), isFalse);
    await c2.close();
  });

  test('plano sem direito ao bônus (curto) → tomarBonus false e o plano não muda', () async {
    final c = await criar();
    c.iniciar(() => montar(c, const FontesTreino(ingles: true)));
    c.marcar('rali', EstadoBloco.feito, resultado: 99);
    expect(c.state.plano!.concluido, isTrue);
    expect(c.tomarBonus(), isFalse);
    expect(c.state.plano!.bonus, isFalse);
    await c.close();
  });

  test('depois de fechado nada lança', () async {
    final c = await criar();
    c.iniciar(() => montar(c));
    await c.close();
    c.marcar('revisao', EstadoBloco.feito);
    c.anotarOuvir(['a']);
    c.anotarFoco(['b']);
    c.completar((p) => p);
    expect(c.tomarBonus(), isFalse);
  });
}

class _RepoQueFalha implements TreinoDiaRepository {
  @override
  Future<PlanoTreino?> carregar() async => throw Exception('sem rede');
  @override
  Future<void> salvar(PlanoTreino p) async => throw Exception('sem rede');
}
