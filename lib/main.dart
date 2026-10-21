import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/linguagem/linguagem.dart';
import 'core/linguagem/linguagem_cubit.dart';
import 'core/theme/mixart.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/exclusao_de_conta.dart';
import 'features/auth/domain/app_user.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/curso/data/curriculo_loader.dart';
import 'features/curso/data/firestore_progresso_repository.dart';
import 'features/curso/data/progresso_repository.dart';
import 'features/curso/presentation/bloc/curso_bloc.dart';
import 'features/curso/presentation/bloc/typing_bloc.dart';
import 'features/curso/presentation/bloc/voz_cubit.dart';
import 'features/curso/presentation/pages/escolha_linguagem_page.dart';
import 'features/curso/presentation/pages/home_page.dart';
import 'features/habito/data/agendador_celular.dart';
import 'features/habito/data/agendador_lembrete.dart';
import 'features/habito/data/habito_repository.dart';
import 'features/habito/data/lembrete_repository.dart';
import 'features/habito/presentation/habito_cubit.dart';
import 'features/habito/presentation/lembrete_cubit.dart';
import 'features/ia/data/cache_explicacoes.dart';
import 'features/ia/data/cota_repository.dart';
import 'features/ia/presentation/ia_cubit.dart';
import 'features/ingles/data/audio_usuario.dart';
import 'features/ingles/data/audio_usuario_repository.dart';
import 'features/ingles/data/config_srs_repository.dart';
import 'features/ingles/data/palavras_repository.dart';
import 'features/ingles/data/preferencias_ouvir.dart';
import 'features/ingles/data/revisao_repository.dart';
import 'features/ingles/data/sessao_midia.dart';
import 'features/ingles/data/setlists_repository.dart';
import 'features/ingles/data/textos_repository.dart';
import 'features/ingles/data/tradutor.dart';
import 'features/ingles/domain/saida_audio.dart';
import 'features/ingles/presentation/ouvir/ouvir_acoes.dart';
import 'features/ingles/presentation/ouvir/ouvir_cubit.dart';
import 'features/ingles/presentation/ouvir/setlists_cubit.dart';
import 'features/ingles/presentation/palavras_cubit.dart';
import 'features/ingles/presentation/revisao_cubit.dart';
import 'features/ranking/data/ranking_repository.dart';
import 'features/ranking/presentation/ranking_cubit.dart';
import 'features/treino_dia/data/treino_dia_repository.dart';
import 'features/treino_dia/presentation/treino_dia_cubit.dart';
import 'features/tutor/data/tutor_firebase_ai.dart';
import 'features/tutor/data/tutor_service.dart';
import 'features/tutor/presentation/tutor_cubit.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    runApp(const PacDartApp());
  } catch (e) {
    // Se o Firebase não iniciar, mostra um aviso em vez de tela em branco.
    runApp(_ErroInicializacao(erro: e.toString()));
  }
}

class _ErroInicializacao extends StatelessWidget {
  final String erro;
  const _ErroInicializacao({required this.erro});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Mixart.bg,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.cloud_off, size: 44, color: Mixart.textMuted),
                const SizedBox(height: 16),
                Text('Não consegui conectar', style: Mixart.display(size: 20), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Verifique sua internet e recarregue a página (Ctrl/Cmd + Shift + R).',
                    style: Mixart.ui(size: 13, color: Mixart.textMuted), textAlign: TextAlign.center),
                const SizedBox(height: 14),
                Text(erro, style: Mixart.mono(size: 10, color: Mixart.textFaint), textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class PacDartApp extends StatelessWidget {
  /// Injetáveis para testes (evitam tocar no Firebase real).
  final AuthCubit? authCubitOverride;
  final ProgressoRepository Function(AppUser user)? progressoBuilder;
  final RankingRepository Function()? rankingBuilder;
  final TutorService Function()? tutorBuilder;

  /// Pula a tela de escolha já numa vertente (testes). null = lê a escolha
  /// salva; sem escolha salva, mostra a tela "Escolha sua trilha".
  final Linguagem? linguagemInicial;

  /// Carregador do currículo por vertente (testes usam um sem I/O de asset).
  final CurriculoLoader Function(Linguagem linguagem)? curriculoBuilder;

  /// Progresso por vertente (probe/testes locais: `LocalProgressoRepository(prefixo:)`).
  /// Tem prioridade sobre [progressoBuilder].
  final ProgressoRepository Function(AppUser user, Linguagem linguagem)? progressoPorLinguagem;

  /// Revisão espaçada do inglês (testes/probe: `LocalRevisaoRepository()`).
  final RevisaoRepository Function(AppUser user)? revisaoBuilder;

  /// Tradutor das lições feitas de texto colado (testes: um falso, sem rede).
  final Tradutor Function()? tradutorBuilder;

  /// Onde ficam os áudios que o aluno anexa às frases (testes/probe: `MemoriaAudioUsuarioRepository()`).
  final AudioUsuarioRepository Function(AppUser user)? audioBuilder;

  /// Os textos que o aluno cola ou escreve e viram lições (testes/probe: `LocalTextosRepository(uid)`). Sem isto vale a
  /// nuvem (`users/{uid}/textos`), que leva os textos da conta para qualquer aparelho; sem Firebase iniciado, o aparelho.
  final TextosRepository Function(AppUser user)? textosBuilder;

  /// O banco de palavras do aluno no inglês (testes/probe: `LocalPalavrasRepository(uid)` ou `MemoriaPalavrasRepository()`).
  /// Sem isto vale a nuvem (`users/{uid}/palavras/v1`, com cópia no aparelho); sem Firebase iniciado, o aparelho.
  final PalavrasRepository Function(AppUser user)? palavrasBuilder;

  /// As setlists do "🎧 Ouvir" no inglês (testes/probe: `MemoriaSetlistsRepository()` ou `LocalSetlistsRepository(uid)`).
  /// Sem isto vale a nuvem (`users/{uid}/setlists/v1`, com cópia no aparelho); sem Firebase iniciado, o aparelho.
  final SetlistsRepository Function(AppUser user)? setlistsBuilder;

  /// A saída de áudio do "🎧 Ouvir" (testes: uma falsa, sem som). Sem isto vale a voz do inglês ([saidaPadrao]).
  final SaidaDeAudio Function()? saidaOuvirBuilder;

  /// Hábito diário (sequência, meta, congelamentos) — testes/probe: `LocalHabitoRepository()`.
  final HabitoRepository Function(AppUser user)? habitoBuilder;

  /// Relógio do hábito (testes: para virar o dia sem esperar).
  final DateTime Function()? habitoAgora;

  /// Lembrete diário (Fase 1B): onde guarda a configuração e quem agenda no sistema
  /// (testes/probe: `LocalLembreteRepository()` e um agendador falso; sem isto vale o do celular).
  final LembreteRepository Function(AppUser user)? lembreteBuilder;
  final AgendadorDeLembrete Function()? agendadorBuilder;

  /// Cota de uso da IA (testes/probe: `LocalCotaRepository()`), seu cache e o relógio dela.
  final CotaRepository Function(AppUser user)? iaCotaBuilder;
  final CacheExplicacoes Function(AppUser user)? iaCacheBuilder;
  final DateTime Function()? iaAgora;

  /// O "⚡ Treino do dia" de cada curso (testes/probe: `LocalTreinoDiaRepository(uid:, curso:)`). Sem isto vale a
  /// nuvem (campo `{prefixo}treino_dia` em `users/{uid}`, com cópia no aparelho); sem Firebase iniciado, o aparelho.
  final TreinoDiaRepository Function(AppUser user, Linguagem linguagem)? treinoDiaBuilder;

  const PacDartApp({
    super.key,
    this.authCubitOverride,
    this.progressoBuilder,
    this.rankingBuilder,
    this.tutorBuilder,
    this.linguagemInicial,
    this.curriculoBuilder,
    this.progressoPorLinguagem,
    this.revisaoBuilder,
    this.tradutorBuilder,
    this.audioBuilder,
    this.textosBuilder,
    this.palavrasBuilder,
    this.setlistsBuilder,
    this.saidaOuvirBuilder,
    this.habitoBuilder,
    this.habitoAgora,
    this.lembreteBuilder,
    this.agendadorBuilder,
    this.iaCotaBuilder,
    this.iaCacheBuilder,
    this.iaAgora,
    this.treinoDiaBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Cada vertente guarda o progresso com o próprio prefixo no mesmo doc
    // (Dart sem prefixo, C# com "cs_", inglês com "en_").
    ProgressoRepository progressoDe(AppUser u, Linguagem l) =>
        progressoPorLinguagem?.call(u, l) ??
        progressoBuilder?.call(u) ??
        FirestoreProgressoRepository(u.uid, prefixo: l.prefixoProgresso);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider<AuthCubit>(
          create: (_) =>
              authCubitOverride ??
              AuthCubit(AuthRepository(FirebaseAuth.instance), exclusao: FirebaseExclusaoDeConta(FirebaseAuth.instance)),
        ),
      ],
      // O gate fica ACIMA do MaterialApp: assim os blocs do curso (no ramo
      // autenticado) envolvem o MaterialApp e ficam acessíveis a todas as
      // rotas empurradas (Mapa, Quiz, diálogos).
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, estado) => switch (estado.status) {
          AuthStatus.desconhecido => const _AppShell(home: _TelaCarregando()),
          AuthStatus.naoAutenticado => const _AppShell(home: LoginPage()),
          // o hábito vale para a conta (Dart + C# + Inglês somam): fica ACIMA da escolha de curso
          AuthStatus.autenticado => _comHabito(
              estado.user!,
              BlocProvider(
              key: ValueKey('lg:${estado.user!.uid}'),
              create: (_) => LinguagemCubit(uid: estado.user!.uid, inicial: linguagemInicial),
              child: BlocBuilder<LinguagemCubit, LinguagemState>(
                builder: (context, lg) {
                  if (!lg.carregado) return const _AppShell(home: _TelaCarregando());
                  final linguagem = lg.escolhida;
                  if (linguagem == null) {
                    return const _AppShell(home: EscolhaLinguagemPage());
                  }
                  return _cursoDe(estado.user!, linguagem, progressoDe(estado.user!, linguagem));
                },
              ),
            )),
        },
      ),
    );
  }

  /// O hábito diário da conta: sobrevive à troca de curso (só trocar de conta o recria).
  Widget _comHabito(AppUser user, Widget filho) => BlocProvider<HabitoCubit>(
        key: ValueKey('hb:${user.uid}'),
        create: (_) => HabitoCubit(
          repo: habitoBuilder?.call(user) ?? FirestoreHabitoRepository(user.uid),
          agora: habitoAgora,
        ),
        child: _comLembrete(user, _comIa(user, filho)),
      );

  /// O lembrete diário da conta neste aparelho: ao lado do hábito (só LÊ se a meta de hoje foi batida).
  Widget _comLembrete(AppUser user, Widget filho) => BlocProvider<LembreteCubit>(
        key: ValueKey('lb:${user.uid}'),
        // não é preguiçoso: precisa nascer na abertura do app para RENOVAR os 7 dias (senão só nasceria ao abrir a folha)
        lazy: false,
        create: (ctx) => LembreteCubit(
          repo: lembreteBuilder?.call(user) ?? LocalLembreteRepository(uid: user.uid),
          agendador: agendadorBuilder?.call() ?? AgendadorDoCelular(),
          habito: ctx.read<HabitoCubit>(),
        ),
        child: filho,
      );

  /// A cota e o cache da IA também são da conta (valem nos 3 cursos): ficam ao lado do hábito.
  /// O "toque na palavra" do inglês tem cota e cache próprios ([IaPalavrasCubit]).
  /// A janela de descanso do projeto (depois de um 429/503/401) é UMA só ([DescansoIa]), dividida pelos
  /// dois: depois de um 429 na conversa, o toque na palavra também espera em vez de bater de novo.
  Widget _comIa(AppUser user, Widget filho) {
    final descanso = DescansoIa();
    return MultiBlocProvider(
      key: ValueKey('ia:${user.uid}'),
      providers: [
        BlocProvider<IaCubit>(
          create: (_) => IaCubit(
            service: tutorBuilder != null
                ? tutorBuilder!()
                : (kIsWeb ? GeminiTutorService() : FirebaseAiTutorService()),
            cotaRepo: iaCotaBuilder?.call(user) ?? FirestoreCotaRepository(user.uid),
            cache: iaCacheBuilder?.call(user) ?? CacheExplicacoesLocal(uid: user.uid),
            agora: iaAgora,
            descanso: descanso,
            // 3 s entre falas da conversa só na produção (nos testes o tutor é falso e responde na hora)
            intervaloMinimo: tutorBuilder == null ? const Duration(seconds: 3) : Duration.zero,
          ),
        ),
        BlocProvider<IaPalavrasCubit>(
          create: (_) => IaPalavrasCubit(
            service: tutorBuilder != null
                ? tutorBuilder!()
                : (kIsWeb ? GeminiTutorService() : FirebaseAiTutorService()),
            uid: user.uid,
            agora: iaAgora,
            descanso: descanso,
          ),
        ),
      ],
      child: filho,
    );
  }

  /// Os blocs do curso de uma vertente. Trocar de conta OU de linguagem
  /// recria tudo (currículo, progresso, digitação).
  Widget _cursoDe(AppUser user, Linguagem linguagem, ProgressoRepository progresso) =>
      MultiBlocProvider(
        key: ValueKey('${user.uid}:${linguagem.id}'),
        providers: [
          BlocProvider(
            create: (_) => CursoBloc(
              loader: curriculoBuilder?.call(linguagem) ?? CurriculoLoader(linguagem: linguagem),
              progresso: progresso,
              // inglês: os textos que a pessoa colou e viraram lições
              textos: linguagem == Linguagem.ingles
                  ? (textosBuilder?.call(user) ??
                      (Firebase.apps.isNotEmpty ? FirestoreTextosRepository(user.uid) : LocalTextosRepository(user.uid)))
                  : null,
            )..add(const CursoIniciado()),
          ),
          BlocProvider(create: (_) => TypingBloc()),
          BlocProvider(create: (_) => VozCubit()),
          // Prof. Dash — o modelo só é criado na primeira pergunta
          BlocProvider(
            create: (_) => TutorCubit(
              service: tutorBuilder != null
                  ? tutorBuilder!()
                  : (kIsWeb ? GeminiTutorService() : FirebaseAiTutorService()),
            ),
          ),
          // placar público (lazy: só toca o Firestore quando usado)
          BlocProvider(
            create: (_) => RankingCubit(
              repo: rankingBuilder != null
                  ? rankingBuilder!()
                  : FirestoreRankingRepository(),
              uid: user.uid,
              apelido: user.apelido,
            ),
          ),
          // "⚡ Treino do dia": um plano por curso (cada vertente tem o seu), no mesmo relógio da sequência
          BlocProvider(
            create: (_) => TreinoDiaCubit(
              repo: treinoDiaBuilder?.call(user, linguagem) ??
                  (Firebase.apps.isNotEmpty
                      ? FirestoreTreinoDiaRepository(user.uid, linguagem: linguagem)
                      : LocalTreinoDiaRepository(uid: user.uid, curso: linguagem.id)),
              curso: linguagem.id,
              agora: habitoAgora,
            ),
          ),
          // inglês: os áudios do aluno (o registro carrega o índice uma vez). Sem nuvem
          // (Firebase não iniciado, como nos testes) e sem repositório injetado não há onde guardar:
          // o botão 🎧 simplesmente não existe.
          if (linguagem == Linguagem.ingles && (audioBuilder != null || Firebase.apps.isNotEmpty))
            RepositoryProvider<AudioUsuarioRepository>(
              // nada lê este repositório pelo contexto: sem `lazy: false` o registro nunca seria iniciado
              lazy: false,
              create: (_) {
                final repo = audioBuilder?.call(user) ?? FirestoreAudioUsuarioRepository(user.uid);
                AudioUsuario.iniciar(repo);
                return repo;
              },
            ),
          // inglês: o tradutor de "transforme um texto em lição"
          if (linguagem == Linguagem.ingles)
            RepositoryProvider<Tradutor>(create: (_) => tradutorBuilder?.call() ?? TradutorMyMemory()),
          // inglês: as frases aprendidas voltam na revisão espaçada
          if (linguagem == Linguagem.ingles)
            BlocProvider(
              create: (_) => RevisaoCubit(
                repo: revisaoBuilder?.call(user) ?? FirestoreRevisaoRepository(user.uid),
                // os ajustes seguem o mesmo lugar dos cartões: nuvem em produção, aparelho em teste/probe
                configRepo: revisaoBuilder != null ? LocalConfigSrsRepository() : FirestoreConfigSrsRepository(user.uid),
              ),
            ),
          // inglês: as palavras novas das lições, "Minhas palavras" e o vocabulário dos jogos
          if (linguagem == Linguagem.ingles)
            BlocProvider(
              create: (_) => PalavrasCubit(
                repo: palavrasBuilder?.call(user) ??
                    (Firebase.apps.isNotEmpty ? FirestorePalavrasRepository(user.uid) : LocalPalavrasRepository(user.uid)),
              ),
            ),
          // inglês: o "🎧 Ouvir" — o Navigator do app (o mini-player empurra o "Tocando agora" por ele; um por
          // curso, para trocar de conta/linguagem não reaproveitar a pilha antiga), as setlists e o player
          if (linguagem == Linguagem.ingles) RepositoryProvider(create: (_) => NavegadorOuvir()),
          if (linguagem == Linguagem.ingles)
            BlocProvider(
              create: (_) => SetlistsCubit(
                repo: setlistsBuilder?.call(user) ??
                    (Firebase.apps.isNotEmpty ? FirestoreSetlistsRepository(user.uid) : LocalSetlistsRepository(user.uid)),
              )..carregar(),
            ),
          if (linguagem == Linguagem.ingles)
            BlocProvider(
              create: (_) => OuvirCubit(
                saida: saidaOuvirBuilder?.call() ?? saidaPadrao(),
                prefs: PreferenciasOuvir(user.uid),
                midia: SessaoMidia.criar(),
              ),
            ),
        ],
        child: _AppShell(home: const HomePage(), linguagem: linguagem),
      );
}

class _AppShell extends StatelessWidget {
  final Widget home;
  final Linguagem? linguagem;
  const _AppShell({required this.home, this.linguagem});

  @override
  Widget build(BuildContext context) => BlocBuilder<ThemeCubit, Paleta>(
        // troca de tema reconstrói o MaterialApp inteiro → tudo recolore
        builder: (context, _) => MaterialApp(
          title: linguagem == null
              ? 'Paclingo — Treino de digitação: Dart, Flutter, C# e inglês'
              : '${linguagem!.nomeApp} — Treino de digitação',
          debugShowCheckedModeBanner: false,
          theme: Mixart.tema(),
          // inglês: o Navigator é o do curso, e o mini-player do "🎧 Ouvir" fica embaixo de todas as rotas
          // (no Dart/C# não há OuvirCubit: sem chave e o filho passa como veio)
          navigatorKey: NavegadorOuvir.de(context)?.chave,
          navigatorObservers: NavegadorOuvir.de(context)?.observadores ?? const <NavigatorObserver>[],
          builder: (c, child) => OuvirShell.envolver(c, child!),
          home: home,
        ),
      );
}

class _TelaCarregando extends StatelessWidget {
  const _TelaCarregando();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Mixart.bg,
        body: Center(child: CircularProgressIndicator(color: Mixart.brand)),
      );
}
