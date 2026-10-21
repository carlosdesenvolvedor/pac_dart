import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/habito/domain/habito.dart' show diaDe;
import 'package:pac_dart/features/ia/domain/cota_ia.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/tutor/data/falha_ia.dart';
import 'package:pac_dart/features/tutor/data/tutor_service.dart';

import 'helpers/tutor_falso.dart';
import 'ia_cubit_test.dart' show CacheMemoria, CotaMemoria, Relogio, TutorFalso, pedido;

const _esquema = <String, Object?>{
  'type': 'OBJECT',
  'properties': {
    'fala': {'type': 'STRING'},
  },
  'required': ['fala'],
};
const _formato = 'Devolva SOMENTE um JSON válido.';

/// A conversa com IA no IaCubit: o caminho JSON, o "só gasta o que serve" ([aceitar]) e a janela de
/// descanso do projeto depois de 429/503/401 (compartilhada entre cubits pelo mesmo [DescansoIa]).
void main() {
  late TutorConversaFalso tutor;
  late CotaMemoria cotaRepo;
  late Relogio relogio;

  setUp(() {
    tutor = TutorConversaFalso();
    cotaRepo = CotaMemoria();
    relogio = Relogio();
  });

  Future<IaCubit> criar({
    TutorService? service,
    DescansoIa? descanso,
    int limite = 30,
    Duration intervaloMinimo = Duration.zero,
    Future<void> Function(Duration)? esperar,
  }) async {
    final c = IaCubit(
      service: service ?? tutor,
      cotaRepo: cotaRepo,
      cache: CacheMemoria(),
      agora: relogio.call,
      limite: limite,
      descanso: descanso ?? DescansoIa(),
      intervaloMinimo: intervaloMinimo,
      esperar: esperar,
    );
    await c.carregar();
    return c;
  }

  Future<ResultadoIa> turno(IaCubit c, {bool Function(String)? aceitar, int maxTokens = 600}) => c.consultarJson(
        persona: 'PERSONA',
        contexto: 'MODO CONVERSA COM IA: café',
        historico: 'Aluno: hi',
        pergunta: '<<<ALUNO>>>\nI want a coffee\n<<<FIM>>>',
        esquema: _esquema,
        formatoTexto: _formato,
        maxTokens: maxTokens,
        aceitar: aceitar,
      );

  void avanca(Duration d) => relogio.t = relogio.t.add(d);

  group('roteamento', () {
    test('TutorJson → perguntarJson com esquema, persona e maxTokens; gasta 1', () async {
      final c = await criar();
      final r = await turno(c, maxTokens: 420);
      expect(r.status, StatusIa.ok);
      expect(r.texto, respostaJson());
      expect(tutor.viaJson, 1);
      expect(tutor.viaComo + tutor.viaPerguntar, 0);
      expect(tutor.esquemas.single, _esquema);
      expect(tutor.maxTokens.single, 420);
      expect(tutor.personas.single, 'PERSONA');
      expect(tutor.historicos.single, 'Aluno: hi');
      expect(tutor.perguntas.single, isNot(contains(_formato)), reason: 'com schema o formato em texto não vai');
      expect(c.state.restantes, 29);
      await pumpEventQueue();
      expect(cotaRepo.guardada.usos, 1);
      await c.close();
    });

    test('só TutorComPersona → perguntarComo com o formato no fim da pergunta', () async {
      final como = TutorComPersonaFalso()..turno = '{"fala":"Hi"}';
      final c = await criar(service: como);
      final r = await turno(c);
      expect(r, const ResultadoIa(StatusIa.ok, '{"fala":"Hi"}'));
      expect(como.personas.single, 'PERSONA');
      expect(como.viaPerguntar, 0);
      expect(como.perguntas.single, '<<<ALUNO>>>\nI want a coffee\n<<<FIM>>>\n\n$_formato');
      expect(c.state.restantes, 29);
      await c.close();
    });

    test('serviço simples → perguntar com a persona no contexto e o formato na pergunta', () async {
      final simples = TutorCenarioFalso()..turno = '{"fala":"Hi"}';
      final c = await criar(service: simples);
      expect((await turno(c)).status, StatusIa.ok);
      expect(simples.contextos.single, 'PERSONA\n\nMODO CONVERSA COM IA: café');
      expect(simples.perguntas.single, endsWith('\n\n$_formato'));
      await c.close();
    });

    test('agora() devolve o relógio injetado', () async {
      final c = await criar();
      expect(c.agora(), relogio.t);
      avanca(const Duration(minutes: 3));
      expect(c.agora(), relogio.t);
      await c.close();
    });
  });

  group('aceitar: só gasta a resposta que serve', () {
    test('recusada pelo aceitar → falhou, motivo outro, cota intacta, nada gravado, sem janela', () async {
      final c = await criar();
      String? visto;
      final r = await turno(c, aceitar: (t) {
        visto = t;
        return false;
      });
      expect(r, const ResultadoIa(StatusIa.falhou, '', TipoFalhaIa.outro));
      expect(visto, respostaJson(), reason: 'o aceitar recebe o texto da IA');
      expect(tutor.chamadas, 1);
      expect(c.state.restantes, 30);
      expect(c.state.esperaAte, isNull);
      expect(c.descanso.ate, isNull);
      await pumpEventQueue();
      expect(cotaRepo.gravacoes, isEmpty);
      await c.close();
    });

    test('aceita → gasta 1', () async {
      final c = await criar();
      final r = await turno(c, aceitar: (t) => t.contains('"fala"'));
      expect(r.status, StatusIa.ok);
      expect(c.state.restantes, 29);
      await c.close();
    });

    test('aceitar que lança conta como "não serve" (nunca lança para fora)', () async {
      final c = await criar();
      final r = await turno(c, aceitar: (_) => throw StateError('x'));
      expect(r.motivo, TipoFalhaIa.outro);
      expect(c.state.restantes, 30);
      await c.close();
    });

    test('texto vazio → falhou/outro sem gastar (nem chega ao aceitar)', () async {
      tutor.respostas.add('   ');
      final c = await criar();
      var chamou = false;
      final r = await turno(c, aceitar: (_) => chamou = true);
      expect(r, const ResultadoIa(StatusIa.falhou, '', TipoFalhaIa.outro));
      expect(chamou, isFalse);
      expect(c.state.restantes, 30);
      await c.close();
    });
  });

  group('429 → janela de descanso', () {
    test('motivo limite, nada gasto, esperaAte = agora + 20 s; dentro da janela nem chama; depois chama', () async {
      tutor.respostas.add(const FalhaIa(TipoFalhaIa.limite, status: 429));
      final c = await criar();
      final t0 = relogio.t;
      final r = await turno(c);
      expect(r, const ResultadoIa(StatusIa.falhou, '', TipoFalhaIa.limite));
      expect(c.state.restantes, 30);
      expect(c.state.esperaAte, t0.add(IaCubit.descansoInicial));
      await pumpEventQueue();
      expect(cotaRepo.gravacoes, isEmpty);

      avanca(const Duration(seconds: 19));
      final r2 = await turno(c);
      expect(r2.motivo, TipoFalhaIa.limite);
      expect(tutor.chamadas, 1, reason: 'durante a janela a IA não é chamada');

      avanca(const Duration(seconds: 2));
      expect((await turno(c)).status, StatusIa.ok);
      expect(tutor.chamadas, 2);
      expect(c.state.esperaAte, isNull, reason: 'o sucesso limpa a janela');
      expect(c.descanso.passo, isNull);
      expect(c.state.restantes, 29);
      await c.close();
    });

    test('o 2º 429 seguido dobra (40 s), e o passo para em 5 min', () async {
      final c = await criar();
      final esperados = [20, 40, 80, 160, 300, 300];
      for (final s in esperados) {
        tutor.respostas.add(const FalhaIa(TipoFalhaIa.limite, status: 429));
        final t = relogio.t;
        expect((await turno(c)).motivo, TipoFalhaIa.limite);
        expect(c.state.esperaAte, t.add(Duration(seconds: s)));
        avanca(Duration(seconds: s + 1));
      }
      expect(tutor.chamadas, esperados.length);
      await c.close();
    });

    test('a mensagem antiga "429 RESOURCE_EXHAUSTED" (Exception comum) também abre a janela', () async {
      tutor.respostas.add(Exception('429 RESOURCE_EXHAUSTED'));
      final c = await criar();
      expect((await turno(c)).motivo, TipoFalhaIa.limite);
      expect(c.state.esperaAte, relogio.t.add(IaCubit.descansoInicial));
      await c.close();
    });
  });

  group('429 por dia → até as próximas 08:00 UTC (no máximo 12 h)', () {
    Future<DateTime?> janelaDiaria(DateTime agora) async {
      relogio.t = agora;
      tutor.respostas.add(const FalhaIa(TipoFalhaIa.limiteDiario, status: 429));
      final c = await criar();
      final r = await turno(c);
      expect(r.motivo, TipoFalhaIa.limiteDiario);
      final ate = c.state.esperaAte;
      await c.close();
      return ate;
    }

    test('antes das 08:00 UTC → 08:00 do mesmo dia', () async {
      final ate = await janelaDiaria(DateTime.utc(2026, 10, 13, 3));
      expect(ate!.isAtSameMomentAs(DateTime.utc(2026, 10, 13, 8)), isTrue, reason: '$ate');
    });

    test('depois das 08:00 UTC → 08:00 do dia seguinte', () async {
      final ate = await janelaDiaria(DateTime.utc(2026, 10, 13, 21));
      expect(ate!.isAtSameMomentAs(DateTime.utc(2026, 10, 14, 8)), isTrue, reason: '$ate');
    });

    test('mais de 12 h até a virada → no máximo 12 h', () async {
      final ate = await janelaDiaria(DateTime.utc(2026, 10, 13, 9));
      expect(ate!.isAtSameMomentAs(DateTime.utc(2026, 10, 13, 21)), isTrue, reason: '$ate');
    });

    test('às 08:00 UTC em ponto → o dia seguinte (limitado a 12 h)', () async {
      final ate = await janelaDiaria(DateTime.utc(2026, 10, 13, 8));
      expect(ate!.isAtSameMomentAs(DateTime.utc(2026, 10, 13, 20)), isTrue, reason: '$ate');
    });

    test('proximaViradaDiaria mantém o fuso de agora', () {
      final local = DateTime(2026, 10, 13, 10);
      expect(DescansoIa.proximaViradaDiaria(local).isUtc, isFalse);
      expect(DescansoIa.proximaViradaDiaria(DateTime.utc(2026, 10, 13, 3)).isUtc, isTrue);
    });
  });

  test('janela COMPARTILHADA: 429 na conversa ⇒ o toque na palavra nem chama e mostra esperaAte', () async {
    final descanso = DescansoIa();
    tutor.respostas.add(const FalhaIa(TipoFalhaIa.limite, status: 429));
    final conversa = await criar(descanso: descanso);
    final palavrasTutor = TutorFalso();
    final palavras = IaPalavrasCubit(
      service: palavrasTutor,
      cotaRepo: CotaMemoria(),
      cache: CacheMemoria(),
      agora: relogio.call,
      descanso: descanso,
    );
    await palavras.carregar();
    expect(palavras.state.esperaAte, isNull);

    await turno(conversa);
    final r = await palavras.explicar(pedido());
    expect(r, const ResultadoIa(StatusIa.falhou, '', TipoFalhaIa.limite));
    expect(palavrasTutor.chamadas, 0);
    expect(palavras.state.esperaAte, descanso.ate);
    expect(palavras.state.esperaAte, relogio.t.add(IaCubit.descansoInicial));
    expect(palavras.state.restantes, IaPalavrasCubit.limitePalavras);

    avanca(const Duration(seconds: 21));
    expect((await palavras.explicar(pedido())).status, StatusIa.ok);
    expect(palavrasTutor.chamadas, 1);
    await conversa.close();
    await palavras.close();
  });

  test('cada cubit sem descanso próprio ganha o seu (não vaza entre instâncias)', () async {
    tutor.respostas.add(const FalhaIa(TipoFalhaIa.limite, status: 429));
    final a = await criar();
    final b = await criar();
    await turno(a);
    expect(a.state.esperaAte, isNotNull);
    expect((await turno(b)).status, StatusIa.ok);
    await a.close();
    await b.close();
  });

  group('outros motivos', () {
    final casos = <(String, Object, TipoFalhaIa, Duration?)>[
      ('503', const FalhaIa(TipoFalhaIa.ocupado, status: 503), TipoFalhaIa.ocupado, IaCubit.descansoOcupado),
      ('401', const FalhaIa(TipoFalhaIa.credencial, status: 401), TipoFalhaIa.credencial, IaCubit.descansoCredencial),
      ('403', const FalhaIa(TipoFalhaIa.credencial, status: 403), TipoFalhaIa.credencial, IaCubit.descansoCredencial),
      ('semRede', const FalhaIa(TipoFalhaIa.semRede), TipoFalhaIa.semRede, null),
      ('recusada', const FalhaIa(TipoFalhaIa.recusada), TipoFalhaIa.recusada, null),
      ('Exception genérica (os fakes antigos)', Exception('boom'), TipoFalhaIa.outro, null),
    ];
    for (final (nome, erro, motivo, janela) in casos) {
      test('$nome → motivo ${motivo.name}, ${janela == null ? 'sem janela' : 'janela de ${janela.inSeconds} s'}', () async {
        tutor.respostas.add(erro);
        final c = await criar();
        final r = await turno(c);
        expect(r, ResultadoIa(StatusIa.falhou, '', motivo));
        expect(c.state.restantes, 30);
        expect(c.state.esperaAte, janela == null ? isNull : relogio.t.add(janela));
        if (janela == null) {
          // sem janela: a próxima já chama
          expect((await turno(c)).status, StatusIa.ok);
          expect(tutor.chamadas, 2);
        } else {
          expect((await turno(c)).motivo, motivo);
          expect(tutor.chamadas, 1);
        }
        await c.close();
      });
    }
  });

  test('semCota continua: sem saldo nem chama', () async {
    cotaRepo.guardada = CotaIa(dia: diaDe(relogio.t), usos: 30);
    final c = await criar();
    expect((await turno(c)).status, StatusIa.semCota);
    expect(tutor.chamadas, 0);
    await c.close();
  });

  group('intervaloMinimo', () {
    test('espera o resto do intervalo antes da próxima chamada', () async {
      final esperas = <Duration>[];
      final c = await criar(intervaloMinimo: const Duration(seconds: 3), esperar: (d) async => esperas.add(d));
      await turno(c);
      expect(esperas, isEmpty, reason: 'a 1ª não espera');
      avanca(const Duration(seconds: 1));
      await turno(c);
      expect(esperas, [const Duration(seconds: 2)]);
      avanca(const Duration(seconds: 5));
      await turno(c);
      expect(esperas, hasLength(1), reason: 'passou do intervalo: não espera');
      expect(tutor.chamadas, 3);
      await c.close();
    });

    test('só vale para o consultarJson (explicar/consultar não esperam)', () async {
      final esperas = <Duration>[];
      final c = await criar(intervaloMinimo: const Duration(seconds: 3), esperar: (d) async => esperas.add(d));
      await turno(c);
      await c.consultar(contexto: 'c', pergunta: 'q');
      await c.explicar(pedido());
      expect(esperas, isEmpty);
      await c.close();
    });
  });

  group('explicar/consultar também têm motivo e respeitam a janela', () {
    test('explicar: 503 → motivo ocupado e janela; durante ela, consultar nem chama', () async {
      final velho = TutorFalso()..erro = const FalhaIa(TipoFalhaIa.ocupado, status: 503);
      final c = await criar(service: velho);
      final r = await c.explicar(pedido());
      expect(r, const ResultadoIa(StatusIa.falhou, '', TipoFalhaIa.ocupado));
      expect(c.state.esperaAte, relogio.t.add(IaCubit.descansoOcupado));
      velho.erro = null;
      final r2 = await c.consultar(contexto: 'c', pergunta: 'q', persona: 'p');
      expect(r2.motivo, TipoFalhaIa.ocupado);
      expect(velho.chamadas, 1);
      avanca(IaCubit.descansoOcupado);
      expect((await c.consultar(contexto: 'c', pergunta: 'q')).status, StatusIa.ok);
      expect(c.state.esperaAte, isNull);
      await c.close();
    });

    test('consultar com Exception genérica → motivo outro, sem janela', () async {
      final velho = TutorFalso()..erro = Exception('boom');
      final c = await criar(service: velho);
      expect((await c.consultar(contexto: 'c', pergunta: 'q')).motivo, TipoFalhaIa.outro);
      expect(c.state.esperaAte, isNull);
      await c.close();
    });
  });
}
