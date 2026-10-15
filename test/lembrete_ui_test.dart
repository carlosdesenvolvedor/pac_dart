import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/habito/domain/habito.dart';
import 'package:pac_dart/features/habito/domain/lembrete.dart';
import 'package:pac_dart/features/habito/presentation/habito_cubit.dart';
import 'package:pac_dart/features/habito/presentation/lembrete_cubit.dart';
import 'package:pac_dart/features/habito/presentation/widgets/sequencia_sheet.dart';

import 'lembrete_cubit_test.dart' show AgendadorFalso, RepoLembreteMemoria, Relogio;

class _RepoHabito implements HabitoRepository {
  Habito guardado = Habito.vazio;
  @override
  Future<Habito> carregar() async => guardado;
  @override
  Future<void> salvar(Habito habito) async => guardado = habito;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  late AgendadorFalso ag;
  late RepoLembreteMemoria repo;
  late HabitoCubit habito;
  late LembreteCubit? lembrete;
  late Relogio relogio;

  Future<void> anda(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  /// Monta um botão que abre a folha "Sua sequência" (como o chip do cabeçalho faz).
  Future<void> abrir(WidgetTester tester,
      {bool comLembrete = true, bool disponivel = true, Size tamanho = const Size(900, 1400), ConfigLembrete inicial = ConfigLembrete.padrao}) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    relogio = Relogio();
    ag = AgendadorFalso(disponivel: disponivel);
    repo = RepoLembreteMemoria(inicial);
    habito = HabitoCubit(repo: _RepoHabito(), agora: relogio.call);
    lembrete = comLembrete ? LembreteCubit(repo: repo, agendador: ag, habito: habito, agora: relogio.call) : null;
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: habito),
          if (lembrete != null) BlocProvider.value(value: lembrete!),
        ],
        child: Builder(builder: (context) => TextButton(onPressed: () => mostrarSequencia(context), child: const Text('abrir'))),
      ),
    ));
    await anda(tester);
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await anda(tester);
  }

  tearDown(() async {
    seletorDeHorarioDoLembrete = (context, inicial) => showTimePicker(context: context, initialTime: inicial);
  });

  Future<void> rolarAte(WidgetTester tester, Key k) async {
    await tester.ensureVisible(find.byKey(k));
    await tester.pump();
  }

  testWidgets('sem o cubit do lembrete na árvore (testes antigos): a folha é a de sempre, sem seção nova', (tester) async {
    await abrir(tester, comLembrete: false);
    expect(find.byKey(const Key('sequencia-sheet')), findsOneWidget);
    expect(find.text('🔔 Lembrete diário'), findsNothing);
    expect(find.byKey(const Key('lembrete-switch')), findsNothing);
    expect(find.byKey(const Key('lembrete-indisponivel')), findsNothing);
  });

  testWidgets('web/desktop (sem suporte): uma linha explica e não há interruptor', (tester) async {
    await abrir(tester, disponivel: false);
    await rolarAte(tester, const Key('lembrete-indisponivel'));
    expect(find.text('🔔 Lembrete diário'), findsOneWidget);
    expect(find.text('O lembrete diário funciona no app do celular (Android e iOS).'), findsOneWidget);
    expect(find.byKey(const Key('lembrete-switch')), findsNothing);
    expect(find.byKey(const Key('lembrete-horario')), findsNothing);
    expect(ag.listas, isEmpty);
  });

  testWidgets('celular, desligado de fábrica: interruptor desligado, explicação sem pressão e sem botão de horário', (tester) async {
    await abrir(tester);
    await rolarAte(tester, const Key('lembrete-switch'));
    expect(tester.widget<Switch>(find.byKey(const Key('lembrete-switch'))).value, isFalse);
    expect(find.text('Lembrar de estudar'), findsOneWidget);
    expect(find.textContaining('Uma notificação por dia'), findsOneWidget);
    expect(find.byKey(const Key('lembrete-horario')), findsNothing);
    expect(find.byKey(const Key('lembrete-aviso')), findsNothing);
    expect(ag.permissoes, 0, reason: 'abrir a folha não pede permissão');
  });

  testWidgets('ligar: pede a permissão, o interruptor liga, a regra aparece e o horário padrão é 20:00', (tester) async {
    await abrir(tester);
    await rolarAte(tester, const Key('lembrete-switch'));
    await tester.tap(find.byKey(const Key('lembrete-switch')));
    await anda(tester);
    expect(ag.permissoes, 1);
    expect(tester.widget<Switch>(find.byKey(const Key('lembrete-switch'))).value, isTrue);
    expect(find.text('Todo dia às 20:00 — só se a meta do dia ainda não foi batida.'), findsOneWidget);
    expect(find.text('Horário: 20:00'), findsOneWidget);
    expect(repo.guardada.ligado, isTrue);
    expect(ag.ultima.length, 7);
  });

  testWidgets('permissão negada: continua desligado e o aviso diz como liberar', (tester) async {
    await abrir(tester);
    ag.concede = false;
    await rolarAte(tester, const Key('lembrete-switch'));
    await tester.tap(find.byKey(const Key('lembrete-switch')));
    await anda(tester);
    expect(tester.widget<Switch>(find.byKey(const Key('lembrete-switch'))).value, isFalse);
    expect(find.byKey(const Key('lembrete-aviso')), findsOneWidget);
    expect(find.textContaining('configurações do aparelho'), findsOneWidget);
    expect(find.byKey(const Key('lembrete-horario')), findsNothing);
    // liberou e tentou de novo: o aviso some
    ag.concede = true;
    await tester.tap(find.byKey(const Key('lembrete-switch')));
    await anda(tester);
    expect(find.byKey(const Key('lembrete-aviso')), findsNothing);
    expect(tester.widget<Switch>(find.byKey(const Key('lembrete-switch'))).value, isTrue);
  });

  testWidgets('escolher o horário: o botão mostra o novo horário e o sistema é reagendado', (tester) async {
    await abrir(tester, inicial: const ConfigLembrete(ligado: true));
    seletorDeHorarioDoLembrete = (context, inicial) async {
      expect((inicial.hour, inicial.minute), (20, 0), reason: 'o seletor abre no horário atual');
      return const TimeOfDay(hour: 7, minute: 30);
    };
    await rolarAte(tester, const Key('lembrete-horario'));
    await tester.tap(find.byKey(const Key('lembrete-horario')));
    await anda(tester);
    expect(find.text('Horário: 07:30'), findsOneWidget);
    expect(find.text('Todo dia às 07:30 — só se a meta do dia ainda não foi batida.'), findsOneWidget);
    expect(repo.guardada.horario, '07:30');
    expect(ag.ultima.every((x) => x.quando.hour == 7 && x.quando.minute == 30), isTrue);
  });

  testWidgets('cancelar o seletor de horário não muda nada', (tester) async {
    await abrir(tester, inicial: const ConfigLembrete(ligado: true));
    seletorDeHorarioDoLembrete = (context, inicial) async => null;
    final n = ag.listas.length;
    await rolarAte(tester, const Key('lembrete-horario'));
    await tester.tap(find.byKey(const Key('lembrete-horario')));
    await anda(tester);
    expect(find.text('Horário: 20:00'), findsOneWidget);
    expect(ag.listas.length, n);
  });

  testWidgets('desligar: some o botão de horário e o sistema fica sem lembretes', (tester) async {
    await abrir(tester, inicial: const ConfigLembrete(ligado: true));
    await rolarAte(tester, const Key('lembrete-switch'));
    expect(find.byKey(const Key('lembrete-horario')), findsOneWidget);
    await tester.tap(find.byKey(const Key('lembrete-switch')));
    await anda(tester);
    expect(tester.widget<Switch>(find.byKey(const Key('lembrete-switch'))).value, isFalse);
    expect(find.byKey(const Key('lembrete-horario')), findsNothing);
    expect(ag.ultima, isEmpty);
    expect(repo.guardada.ligado, isFalse);
  });

  testWidgets('a meta, os congelamentos e os últimos 14 dias continuam na folha (nada foi tirado)', (tester) async {
    await abrir(tester);
    expect(find.text('Meta do dia'), findsOneWidget);
    expect(find.byKey(const Key('meta-20')), findsOneWidget);
    expect(find.byKey(const Key('numero-congelamentos')), findsOneWidget);
    expect(find.text('Últimos 14 dias'), findsOneWidget);
  });

  for (final tamanho in const [Size(360, 740), Size(390, 844), Size(1027, 800)]) {
    testWidgets('sem estouro em ${tamanho.width.toInt()} px (ligado, com aviso, tema claro)', (tester) async {
      final antes = Mixart.atual;
      addTearDown(() => Mixart.atual = antes);
      Mixart.atual = Paleta.flutterClaro;
      await abrir(tester, tamanho: tamanho, inicial: const ConfigLembrete(ligado: true));
      await rolarAte(tester, const Key('lembrete-horario'));
      expect(find.byKey(const Key('lembrete-horario')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
