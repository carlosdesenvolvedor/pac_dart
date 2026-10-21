// Teste de APP da "💬 Conversa com IA": o PacDartApp inteiro (Inglês) → Mapa → "Conversa com IA" → café →
// 3 falas (uma corrigida, uma certa, a 3ª fecha a cena) → o resumo local aparece sozinho (0 usos) →
// "Salvar como cartão" (o cartão está em "Meus cartões", sem duplicar) → a palavra nova vai para Minhas palavras.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/auth/data/auth_repository.dart';
import 'package:pac_dart/features/auth/domain/app_user.dart';
import 'package:pac_dart/features/auth/presentation/auth_cubit.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/pages/home_page.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/habito/presentation/habito_cubit.dart';
import 'package:pac_dart/features/ia/data/cota_repository.dart';
import 'package:pac_dart/features/ia/domain/prompt_conversa.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/domain/cartoes_texto.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/elenco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/features/tutor/data/falha_ia.dart';
import 'package:pac_dart/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/tutor_falso.dart';

class _AuthFake implements AuthRepository {
  static const _user = AppUser(uid: 'teste-uid', email: 'teste@pac.dart');
  @override
  Stream<AppUser?> get mudancas => Stream.value(_user);
  @override
  AppUser? get atual => _user;
  @override
  Future<void> entrar(String email, String senha) async {}
  @override
  Future<void> cadastrar(String email, String senha) async {}
  @override
  Future<void> redefinirSenha(String email) async {}
  @override
  Future<void> sair() async {}
}

class _Ranking implements RankingRepository {
  int somas = 0;
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async => somas++;
  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async => true;
  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

final _trilhaEn = Trilha(
  nivel: 'Primeiros Passos',
  emoji: '👋',
  etapa: 'A1 · Fundação',
  licoes: const [
    Licao(nome: 'Olá!', emoji: '🙋', trechos: [Trecho(cod: "Hi, I'm Ana.", dica: 'Oi, eu sou a Ana.', out: '')]),
  ],
);

class _LoaderEn extends CurriculoLoader {
  _LoaderEn() : super(linguagem: Linguagem.ingles);
  @override
  Future<List<Trilha>> carregar() async => [_trilhaEn];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

Future<void> _anda(WidgetTester tester, [int vezes = 6]) async {
  for (var i = 0; i < vezes; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

Future<void> _esperar(WidgetTester tester, Finder alvo) async {
  for (var i = 0; i < 25 && alvo.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }
}

Future<void> _abrirApp(WidgetTester tester, TutorConversaFalso tutor, _Ranking ranking) async {
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false});
  tester.view.physicalSize = const Size(1400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoPorLinguagem: (_, l) => LocalProgressoRepository(prefixo: l.prefixoProgresso),
      revisaoBuilder: (_) => LocalRevisaoRepository(),
      rankingBuilder: () => ranking,
      habitoBuilder: (u) => LocalHabitoRepository(uid: u.uid),
      tutorBuilder: () => tutor,
      iaCotaBuilder: (u) => LocalCotaRepository(uid: u.uid),
      palavrasBuilder: (_) => MemoriaPalavrasRepository(),
      curriculoBuilder: (l) => _LoaderEn(),
      linguagemInicial: Linguagem.ingles,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  });
  await _esperar(tester, find.byType(PalcoIngles));
  await _anda(tester, 3);
  await tester.runAsync(() => tester.element(find.byType(HomePage)).read<IaCubit>().carregar());
}

void testWidgetsDesktop(String d, WidgetTesterCallback c) =>
    testWidgets(d, c, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => FraseView.carencia = Duration.zero);
  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgetsDesktop('Mapa → Conversa com IA → café: 3 falas corrigidas na hora, resumo local (0 usos), cartão sem duplicar e palavra nova',
      (tester) async {
    // a 1ª fala é "errada" (correção do Prof. Dash), a 2ª está certa, a 3ª fecha a cena (fim: true)
    final tutor = TutorConversaFalso()
      ..respostas.addAll([
        respostaJson(),
        respostaJson(precisa: false, fala: 'Great. Would you like anything to eat with that?'),
        respostaJson(precisa: false, fim: true, fala: "Perfect. That's four dollars. Have a nice day!"),
      ]);
    final ranking = _Ranking();
    await _abrirApp(tester, tutor, ranking);
    final home = tester.element(find.byType(HomePage));
    final curso = home.read<CursoBloc>();
    final revisao = home.read<RevisaoCubit>();
    final ia = home.read<IaCubit>();
    final habito = home.read<HabitoCubit>();
    final palavras = home.read<PalavrasCubit>();
    final praticasAntes = habito.state.habito.unidadesHoje;

    await tester.tap(find.text('Mapa'));
    await _anda(tester, 8);
    expect(find.byKey(const Key('conversar')), findsOneWidget);
    expect(find.text('Conversa com IA'), findsOneWidget, reason: 'o cartão do mapa tem o nome novo');
    await tester.ensureVisible(find.byKey(const Key('conversar')));
    await tester.tap(find.byKey(const Key('conversar')));
    await _anda(tester, 4);
    await _esperar(tester, find.byKey(const Key('cenario-cafe'))); // lê assets/ingles/cenarios.json (I/O real)
    await _anda(tester, 3);
    expect(find.byKey(const Key('cenarios-restantes')), findsOneWidget);
    expect(find.text('Restam 30 usos hoje · cada fala usa 1'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('cenario-cafe')));
    await tester.tap(find.byKey(const Key('cenario-cafe')));
    await _anda(tester, 8);
    // a abertura com o rosto da Emma (sem gastar nada)
    expect(find.text('Hi! Welcome to Sunny Beans. What can I get for you?'), findsWidgets);
    expect(find.byKey(const Key('avatar-conversa')), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const Key('avatar-conversa')), matching: find.byType(PersonagemFalante)),
      findsOneWidget,
    );
    expect(ia.state.restantes, 30);
    expect(tutor.chamadas, 0);

    for (final f in ['I want a coffee.', 'A small one.', 'Thank you.']) {
      await tester.enterText(find.byKey(const Key('campo-conversa')), f);
      await tester.tap(find.byKey(const Key('enviar-conversa')));
      await _anda(tester, 6);
      expect(find.text(f), findsWidgets);
    }
    expect(tutor.chamadas, 3, reason: 'uma chamada por fala; o resumo não chama a IA');
    expect(tutor.viaJson, 3, reason: 'o tutor com TutorJson recebe o esquema');
    expect(tutor.contextos.every((c) => c.contains(marcadorConversa)), isTrue);
    expect(tutor.personas.first, contains('Emma'));
    expect(tutor.perguntas.first, contains('<<<ALUNO>>>'));

    // a correção da 1ª fala apareceu na hora; a 2ª ficou "✅ Certinho!"
    expect(find.byKey(const Key('correcao-1')), findsOneWidget);
    expect(find.byKey(const Key('fala-certa-3')), findsOneWidget);

    // a cena fechou na 3ª fala: o resumo aparece sozinho e NÃO gasta nada
    await _esperar(tester, find.byKey(const Key('resumo-conversa')));
    expect(find.byKey(const Key('resumo-conversa')), findsOneWidget);
    expect(find.byKey(const Key('campo-conversa')), findsNothing, reason: 'acabou: o rodapé some');
    expect(ia.state.restantes, 27);
    await _anda(tester, 4);
    expect(ia.state.restantes, 27, reason: 'o resumo é local');
    expect(tutor.chamadas, 3);

    // salva a correção como cartão → "Meus cartões"
    expect(curso.state.trilhas.any((t) => t.textoId == idCartoesAvulsos), isFalse);
    await tester.ensureVisible(find.byKey(const Key('resumo-cartao-0')));
    await tester.tap(find.byKey(const Key('resumo-cartao-0')));
    await _anda(tester, 10);
    expect(find.text('✓ Salvo'), findsOneWidget);
    final meus = curso.state.trilhas.firstWhere((t) => t.textoId == idCartoesAvulsos);
    final frases = [for (final l in meus.licoes) ...l.trechos];
    expect(frases.map((t) => t.cod), ['Can I have a coffee, please?']);
    expect(frases.single.dica, 'Posso pedir um café, por favor?');
    expect(revisao.state.config.reversoLigado('txt:$idCartoesAvulsos'), isTrue, reason: 'o 1º cartão liga o inglês → português');

    // a mesma frase de novo (pelo cartão da correção, lá em cima na conversa) NÃO duplica
    await tester.ensureVisible(find.byKey(const Key('salvar-correcao-1')));
    await tester.tap(find.byKey(const Key('salvar-correcao-1')));
    await _anda(tester, 10);
    // a frente repetida não muda o baralho: o salvarCartaoDoCenario espera os 5 s dele e segue
    await tester.pump(const Duration(seconds: 6));
    await _anda(tester, 4);
    expect(find.byKey(const Key('salvar-correcao-1')), findsOneWidget);
    curso.add(CartaoAdicionado(const CartaoEscrito('Can I have a coffee, please?', 'Posso pedir um café, por favor?')));
    await _anda(tester, 8);
    final depois = curso.state.trilhas.firstWhere((t) => t.textoId == idCartoesAvulsos);
    expect([for (final l in depois.licoes) ...l.trechos].map((t) => t.cod), ['Can I have a coffee, please?']);

    // a palavra nova ("size") vai para Minhas palavras
    await _esperar(tester, find.byKey(const Key('palavra-size')));
    expect(find.byKey(const Key('palavra-size')), findsOneWidget);
    expect(palavras.state.banco['size'], isNull);
    await tester.ensureVisible(find.byKey(const Key('adicionar-palavras')));
    await tester.tap(find.byKey(const Key('adicionar-palavras')));
    await _anda(tester, 6);
    expect(palavras.state.banco['size'], isNotNull);
    expect(palavras.state.banco['size']!.removida, isFalse);
    expect(find.text('já está nas suas palavras'), findsOneWidget);

    // cada fala corrigida conta 1 prática do hábito; a conversa não toca no ranking
    expect(habito.state.habito.unidadesHoje, praticasAntes + 3);
    expect(ranking.somas, 0);
    expect(ia.state.restantes, 27);
  });

  testWidgetsDesktop('o app divide UMA janela de descanso entre a conversa e o toque na palavra (e sem intervalo mínimo nos testes)',
      (tester) async {
    final tutor = TutorConversaFalso()..respostas.add(const FalhaIa(TipoFalhaIa.limite, status: 429, detalhe: 'RESOURCE_EXHAUSTED'));
    await _abrirApp(tester, tutor, _Ranking());
    final home = tester.element(find.byType(HomePage));
    final ia = home.read<IaCubit>();
    final palavras = home.read<IaPalavrasCubit>();
    expect(identical(ia.descanso, palavras.descanso), isTrue, reason: 'um 429 na conversa também segura o toque na palavra');
    expect(ia.intervaloMinimo, Duration.zero, reason: 'com tutor falso o app não espera 3 s entre falas');

    // um 429 na conversa abre a janela para os dois
    late ResultadoIa r;
    await tester.runAsync(() async {
      r = await ia.consultarJson(
        persona: 'p',
        contexto: marcadorConversa,
        pergunta: '<<<ALUNO>>>\nhi\n<<<FIM>>>',
        esquema: const {'type': 'OBJECT'},
        formatoTexto: '',
      );
    });
    expect(r.status, StatusIa.falhou);
    expect(r.motivo, TipoFalhaIa.limite);
    expect(palavras.descanso.ativo(palavras.agora()), isTrue);
    expect(ia.state.restantes, 30, reason: 'falha não gasta');
  });
}
