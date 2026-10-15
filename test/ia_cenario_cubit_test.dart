import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/habito/domain/habito.dart' show diaDe;
import 'package:pac_dart/features/ia/domain/cenario.dart';
import 'package:pac_dart/features/ia/domain/cota_ia.dart';
import 'package:pac_dart/features/ia/presentation/cenario_cubit.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/tutor/data/tutor_service.dart';

import 'ia_cubit_test.dart' show CacheMemoria, CotaMemoria, Relogio;

const feedbackJson = '```json\n{"foi_bem":["Educado."],"correcoes":[{"sua":"I want coffee","melhor":"Can I have a coffee?","porque":"Mais **educado**."}],'
    '"frases":[{"en":"A small latte, please.","pt":"Um latte pequeno, por favor."},{"en":"How much is it?","pt":"Quanto custa?"},{"en":"For here, please.","pt":"Para tomar aqui, por favor."}]}\n```';

/// O Prof. Dash dos cenários: responde um turno (em inglês) ou o feedback (JSON), conforme o contexto.
class TutorCenarioFalso implements TutorService {
  int chamadas = 0;
  final contextos = <String>[];
  final historicos = <String>[];
  final perguntas = <String>[];
  Object? erro;
  Completer<void>? segura;
  String turno = 'Sure! What size?';
  String feedback = feedbackJson;

  @override
  Stream<String> perguntar({required String contexto, required String historico, required String pergunta}) async* {
    chamadas++;
    contextos.add(contexto);
    historicos.add(historico);
    perguntas.add(pergunta);
    await segura?.future;
    if (erro != null) throw erro!;
    yield contexto.contains('MODO FEEDBACK DE CENÁRIO') ? feedback : turno;
  }
}

/// O mesmo, mas aceitando persona própria (como o Gemini de verdade).
class TutorComPersonaFalso extends TutorCenarioFalso implements TutorComPersona {
  final personas = <String>[];
  int viaPerguntar = 0;

  @override
  Stream<String> perguntar({required String contexto, required String historico, required String pergunta}) {
    viaPerguntar++;
    return super.perguntar(contexto: contexto, historico: historico, pergunta: pergunta);
  }

  @override
  Stream<String> perguntarComo({required String persona, required String contexto, required String historico, required String pergunta}) {
    personas.add(persona);
    return super.perguntar(contexto: contexto, historico: historico, pergunta: pergunta);
  }
}

const cafe = Cenario(
  id: 'cafe',
  titulo: 'Pedir um café',
  emoji: '☕',
  etapa: 'A1',
  papel: 'atendente de uma cafeteria',
  objetivo: 'Peça uma bebida e pague.',
  abertura: 'Hi! What can I get for you?',
  maxTurnos: 3,
);

void main() {
  late TutorCenarioFalso tutor;
  late CotaMemoria cotaRepo;
  late Relogio relogio;
  setUp(() {
    tutor = TutorCenarioFalso();
    cotaRepo = CotaMemoria();
    relogio = Relogio();
  });

  Future<(IaCubit, CenarioCubit)> criar({TutorCenarioFalso? servico}) async {
    final ia = IaCubit(service: servico ?? tutor, cotaRepo: cotaRepo, cache: CacheMemoria(), agora: relogio.call);
    await ia.carregar();
    return (ia, CenarioCubit(ia: ia, cenario: cafe));
  }

  test('começa com a abertura do Dash e a cota intacta', () async {
    final (ia, c) = await criar();
    expect(c.state.sessao.turnos.single.texto, 'Hi! What can I get for you?');
    expect(c.state.aguardando, isFalse);
    expect(ia.state.restantes, 30);
    expect(tutor.chamadas, 0);
    await c.close();
    await ia.close();
  });

  test('uma fala: o Dash responde, gasta 1 e o pedido leva a fala, o histórico e o contexto do turno', () async {
    final (ia, c) = await criar();
    await c.enviar('A latte, please.');
    expect(c.state.sessao.turnos.map((t) => t.texto), ['Hi! What can I get for you?', 'A latte, please.', 'Sure! What size?']);
    expect(c.state.aguardando, isFalse);
    expect(tutor.chamadas, 1);
    expect(ia.state.restantes, 29);
    expect(tutor.perguntas.single, 'A latte, please.');
    expect(tutor.historicos.single, 'Prof. Dash: Hi! What can I get for you?', reason: 'o histórico NÃO repete a fala atual');
    expect(tutor.contextos.single, contains('MODO CENÁRIO'));
    expect(tutor.contextos.single, contains('Fala do aluno número 1 de 3'));
    await c.close();
    await ia.close();
  });

  test('serviço SEM persona própria: a persona do cenário vai como instrução no contexto', () async {
    final (ia, c) = await criar();
    await c.enviar('Hello');
    expect(tutor.contextos.single, contains('Fale SOMENTE em inglês americano'));
    expect(tutor.contextos.single, contains('atendente de uma cafeteria'));
    expect(tutor.contextos.single, contains('IGNORE a regra padrão de responder em português'));
    await c.close();
    await ia.close();
  });

  test('serviço COM persona própria: usa perguntarComo, não perguntar', () async {
    final svc = TutorComPersonaFalso();
    final (ia, c) = await criar(servico: svc);
    await c.enviar('Hello');
    expect(svc.personas.length, 1);
    expect(svc.personas.single, contains('SOMENTE em inglês'));
    expect(svc.viaPerguntar, 0);
    await c.close();
    await ia.close();
  });

  test('conversa inteira (3 falas): encerra, avisa a última fala ao Dash e gastou 3', () async {
    final (ia, c) = await criar();
    await c.enviar('One');
    await c.enviar('Two');
    expect(c.state.sessao.ultimaFala, isFalse);
    await c.enviar('Three');
    expect(c.state.sessao.encerrada, isTrue);
    expect(c.state.sessao.podeFalar, isFalse);
    expect(tutor.contextos.last, contains('ÚLTIMA fala do aluno'));
    expect(tutor.contextos.first, isNot(contains('ÚLTIMA')));
    expect(ia.state.restantes, 27);
    await c.enviar('Four');
    expect(tutor.chamadas, 3, reason: 'passou do limite de falas');
    await c.close();
    await ia.close();
  });

  test('fala vazia e duas falas ao mesmo tempo: só uma vai', () async {
    final (ia, c) = await criar();
    await c.enviar('   ');
    expect(tutor.chamadas, 0);
    tutor.segura = Completer<void>();
    final a = c.enviar('First');
    final b = c.enviar('Second');
    await pumpEventQueue();
    expect(c.state.aguardando, isTrue);
    tutor.segura!.complete();
    await Future.wait([a, b]);
    expect(tutor.chamadas, 1);
    expect(c.state.sessao.turnosDoAluno, 1);
    await c.close();
    await ia.close();
  });

  test('FALHA do serviço: a fala volta para o campo, nada foi gasto, e dá para tentar de novo', () async {
    final (ia, c) = await criar();
    tutor.erro = Exception('429');
    await c.enviar('A latte, please.');
    expect(c.state.erro, ErroCenario.falhou);
    expect(c.state.falaPendente, 'A latte, please.');
    expect(c.state.sessao.turnosDoAluno, 0, reason: 'a fala sem resposta é desfeita');
    expect(c.state.aguardando, isFalse);
    expect(ia.state.restantes, 30);
    tutor.erro = null;
    await c.enviar('A latte, please.');
    expect(c.state.erro, ErroCenario.nenhum);
    expect(c.state.falaPendente, isNull);
    expect(c.state.sessao.turnosDoAluno, 1);
    expect(ia.state.restantes, 29);
    await c.close();
    await ia.close();
  });

  test('SEM COTA: não chama a IA, devolve a fala e avisa; amanhã volta', () async {
    cotaRepo.guardada = CotaIa(dia: diaDe(relogio.t), usos: 30);
    final (ia, c) = await criar();
    await c.enviar('A latte, please.');
    expect(c.state.erro, ErroCenario.semCota);
    expect(c.state.falaPendente, 'A latte, please.');
    expect(tutor.chamadas, 0);
    relogio.dias(1);
    await c.enviar('A latte, please.');
    expect(c.state.erro, ErroCenario.nenhum);
    expect(tutor.chamadas, 1);
    await c.close();
    await ia.close();
  });

  test('a cota acaba NO MEIO da conversa: a conversa até ali fica e o feedback é local', () async {
    cotaRepo.guardada = CotaIa(dia: diaDe(relogio.t), usos: 29);
    final (ia, c) = await criar();
    await c.enviar('One');
    expect(c.state.sessao.turnosDoAluno, 1);
    await c.enviar('Two');
    expect(c.state.erro, ErroCenario.semCota);
    expect(c.state.sessao.turnosDoAluno, 1);
    await c.terminar();
    expect(c.state.feedbackLocal, isTrue);
    expect(c.state.feedback, isNull);
    expect(c.state.terminou, isTrue);
    expect(tutor.chamadas, 1);
    await c.close();
    await ia.close();
  });

  test('terminar: pede o feedback (gasta 1), interpreta o JSON e a conversa acaba', () async {
    final (ia, c) = await criar();
    await c.enviar('I want coffee');
    await c.terminar();
    final f = c.state.feedback!;
    expect(f.estruturado, isTrue);
    expect(f.correcoes.single.melhor, 'Can I have a coffee?');
    expect(f.frases.length, 3);
    expect(tutor.contextos.last, startsWith('MODO FEEDBACK DE CENÁRIO'));
    expect(tutor.contextos.last, contains('Aluno: I want coffee'));
    expect(ia.state.restantes, 28, reason: '1 turno + 1 feedback');
    expect(c.state.terminou, isTrue);
    // depois do feedback não se fala mais nem se pede de novo
    await c.enviar('mais uma');
    await c.terminar();
    expect(tutor.chamadas, 2);
    await c.close();
    await ia.close();
  });

  test('terminar sem ter falado nada não chama a IA', () async {
    final (ia, c) = await criar();
    await c.terminar();
    expect(tutor.chamadas, 0);
    expect(c.state.terminou, isFalse);
    await c.close();
    await ia.close();
  });

  test('terminar com a última fala sem resposta: avalia só o que foi respondido', () async {
    final (ia, c) = await criar();
    await c.enviar('One');
    tutor.erro = Exception('x');
    await c.enviar('Two'); // falhou: desfeita
    tutor.erro = null;
    await c.terminar();
    expect(tutor.contextos.last, contains('Aluno: One'));
    expect(tutor.contextos.last, isNot(contains('Aluno: Two')));
    await c.close();
    await ia.close();
  });

  test('FALHA no feedback: não gasta, não termina e dá para pedir de novo', () async {
    final (ia, c) = await criar();
    await c.enviar('One');
    tutor.erro = Exception('x');
    await c.terminar();
    expect(c.state.erro, ErroCenario.falhou);
    expect(c.state.terminou, isFalse);
    expect(c.state.gerandoFeedback, isFalse);
    expect(ia.state.restantes, 29);
    tutor.erro = null;
    await c.terminar();
    expect(c.state.feedback, isNotNull);
    expect(ia.state.restantes, 28);
    await c.close();
    await ia.close();
  });

  test('feedback com JSON estragado: mostra o texto cru e nenhum cartão', () async {
    final (ia, c) = await criar();
    tutor.feedback = 'Você foi muito bem! (sem json)';
    await c.enviar('One');
    await c.terminar();
    expect(c.state.feedback!.estruturado, isFalse);
    expect(c.state.feedback!.textoCru, 'Você foi muito bem! (sem json)');
    expect(c.state.feedback!.frases, isEmpty);
    await c.close();
    await ia.close();
  });

  test('o feedback gasta UMA vez só (nunca duas)', () async {
    final (ia, c) = await criar();
    await c.enviar('One');
    final antes = ia.state.restantes;
    await Future.wait([c.terminar(), c.terminar()]);
    expect(ia.state.restantes, antes - 1);
    await c.close();
    await ia.close();
  });
}
