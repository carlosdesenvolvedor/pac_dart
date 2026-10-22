// Entrypoint de PROVA VISUAL do Arcade (sem Firebase): abre o hub do Arcade
// de verdade — os jogos funcionam sem login (RankingCubit vira no-op) — e
// uma galeria com pista/personagens/cenários crus.
//   flutter build web -t lib/main_arcade_probe.dart --output=build/probe
// Rotas do English Turismo (prova visual do plano 8.3): /turismo-en, /turismo-en11 … /turismo-en30,
// /historia-en (galeria), /historia-en1 (abertura 1) e /historia-en30 (final 30, créditos).
// 📺 Escutar assistindo (plano das historinhas §11.3): /?licao=<Licao.id>&modo=so|ep|pe[&setlist=1]#/assistir-en
// — o "▶ Assistir" é o gesto que libera o áudio na web; com setlist=1 toca uma setlist "Probe" de 2 lições.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/linguagem/linguagem.dart';
import 'core/theme/mixart.dart';
import 'features/curso/data/curriculo_loader.dart';
import 'features/curso/data/progresso_repository.dart';
import 'features/curso/presentation/bloc/curso_bloc.dart';
import 'features/arcade/data/historia_turismo_repo.dart';
import 'features/arcade/domain/gerador_missoes.dart';
import 'features/arcade/domain/historia_turismo.dart';
import 'features/arcade/domain/personagem.dart';
import 'features/arcade/domain/turismo.dart';
import 'features/arcade/presentation/arcade_page.dart';
import 'features/arcade/presentation/historia/galeria_historia.dart';
import 'features/arcade/presentation/historia/player_historia.dart';
import 'features/arcade/presentation/turismo_page.dart';
import 'features/arcade/presentation/widgets/arcade_ui.dart';
import 'features/arcade/presentation/widgets/avatares.dart';
import 'features/arcade/presentation/widgets/cenario.dart';
import 'features/arcade/presentation/widgets/cenas.dart';
import 'features/ingles/data/preferencia_assistir.dart';
import 'features/ingles/data/setlists_repository.dart';
import 'features/ingles/domain/config_ouvir.dart';
import 'features/ingles/domain/fila_ouvir.dart';
import 'features/ingles/domain/setlist.dart';
import 'features/ingles/presentation/ouvir/ouvir_acoes.dart';
import 'features/ingles/presentation/ouvir/ouvir_cubit.dart';
import 'features/ingles/presentation/ouvir/setlists_cubit.dart';

void main() => runApp(const _ProbeApp());

class _ProbeApp extends StatelessWidget {
  const _ProbeApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Mixart.tema(),
      routes: {
        '/galeria': (_) => const _Galeria(),
        // atalhos de prova visual: pista 1 com semente fixa e a pista noturna
        '/turismo': (_) => const TurismoPage(semente: 3, pistaInicial: 1),
        '/turismo3': (_) => const TurismoPage(semente: 3, pistaInicial: 3),
        '/turismo10': (_) => const TurismoPage(semente: 3, pistaInicial: 10),
        // 📖 English Turismo (o curso vira inglês DENTRO do builder): campeonato com a história, as 20
        // pistas novas direto na corrida (sem história), a galeria e as cenas 1 (abertura) e 30 (final)
        '/turismo-en': (_) => _ingles(const TurismoPage(carregarHistoria: true)),
        for (var n = pistasClassicas + 1; n <= pistasGtIngles.length; n++)
          '/turismo-en$n': (_) => _ingles(TurismoPage(semente: 3, pistaInicial: n)),
        '/historia-en': (_) => _ingles(const _HistoriaProbe()),
        '/historia-en1': (_) => _ingles(const _HistoriaProbe(pista: 1, parte: ParteDoCapitulo.intro)),
        '/historia-en30': (_) => _ingles(const _HistoriaProbe(pista: 30, parte: ParteDoCapitulo.fim)),
        '/assistir-en': (_) => _ingles(const _AssistirProbe()),
      },
      home: const ArcadePage(),
    );
  }
}

/// Liga o curso de inglês antes de montar [pagina] (as rotas `-en` da prova visual).
Widget _ingles(Widget pagina) {
  Linguagem.atual = Linguagem.ingles;
  return pagina;
}

/// 📖 Prova visual da história: com [pista], a cena ([parte]) desse capítulo; sem, a galeria inteira
/// liberada (pistaMax 30 e todas as chegadas).
class _HistoriaProbe extends StatelessWidget {
  const _HistoriaProbe({this.pista, this.parte = ParteDoCapitulo.intro});

  final int? pista;
  final ParteDoCapitulo parte;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HistoriaTurismo?>(
      future: HistoriaTurismoRepo.carregar(),
      builder: (context, snap) {
        final h = snap.data;
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(backgroundColor: Mixart.bg, body: const Center(child: CircularProgressIndicator()));
        }
        final cap = pista == null ? null : h?.capitulo(pista!);
        if (h == null || (pista != null && cap == null)) {
          return Scaffold(
            backgroundColor: Mixart.bg,
            body: Center(child: Text('📖 história indisponível', style: Mixart.ui(size: 14))),
          );
        }
        if (cap == null) {
          return GaleriaHistoriaPage(
            historia: h,
            pistaMax: pistasGtIngles.length,
            chegadas: {for (final c in h.capitulos) c.pista},
          );
        }
        return PlayerHistoria(
          capitulo: cap,
          parte: parte,
          creditos: parte == ParteDoCapitulo.fim && cap.pista == pistasGtIngles.length,
          onFim: (_) => Navigator.of(context).maybePop(),
        );
      },
    );
  }
}

/// 📺 Prova visual do "Escutar assistindo": os providers do 🎧 Ouvir (sem o `SetlistsCubit`, as portas do
/// Ouvir voltam sem fazer nada) e, EMBAIXO deles, um Navigator próprio com a chave do [NavegadorOuvir] —
/// o `abrirTocando` empurra o "Tocando agora" nele, então o player enxerga o `OuvirCubit`. Sem mini-player
/// (ele mora no `OuvirShell` do app).
class _AssistirProbe extends StatefulWidget {
  const _AssistirProbe();

  @override
  State<_AssistirProbe> createState() => _AssistirProbeState();
}

class _AssistirProbeState extends State<_AssistirProbe> {
  final _nav = NavegadorOuvir();
  late final _setlists = SetlistsCubit(repo: LocalSetlistsRepository('probe'))..carregar();
  late final _curso = CursoBloc(
    loader: CurriculoLoader(linguagem: Linguagem.ingles),
    progresso: LocalProgressoRepository(prefixo: 'en_'),
  )..add(const CursoIniciado());
  late final _ouvir = OuvirCubit(saida: saidaPadrao());

  @override
  void dispose() {
    unawaited(_ouvir.close());
    unawaited(_curso.close());
    unawaited(_setlists.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<NavegadorOuvir>.value(
      value: _nav,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CursoBloc>.value(value: _curso),
          BlocProvider<SetlistsCubit>.value(value: _setlists),
          BlocProvider<OuvirCubit>.value(value: _ouvir),
        ],
        child: Navigator(
          key: _nav.chave,
          observers: _nav.observadores,
          onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const _AssistirInicio()),
        ),
      ),
    );
  }
}

/// A tela de entrada da prova: espera o curso e mostra o "▶ Assistir" (o clique é o gesto do áudio).
class _AssistirInicio extends StatelessWidget {
  const _AssistirInicio();

  static String get _licao => Uri.base.queryParameters['licao'] ?? 'primeiro-contato.oi-tudo-bem';

  static ModoOuvir get _modo => switch (Uri.base.queryParameters['modo']) {
        'ep' => ModoOuvir.inglesPortugues,
        'pe' => ModoOuvir.portuguesIngles,
        _ => ModoOuvir.soIngles,
      };

  static bool get _comSetlist => Uri.base.queryParameters['setlist'] == '1';

  /// A setlist "Probe": a lição pedida e a seguinte da mesma trilha (só na memória, para o clique não
  /// esperar nada antes do `tocar`).
  static Setlist? _setlistProbe(BuildContext context) {
    final trilhas = trilhasDoCurso(context);
    final pos = IndiceOuvir.de(trilhas).licao(_licao);
    if (pos == null) return null;
    final licoes = trilhas[pos.t].licoes;
    return Setlist(
      id: 'probe',
      nome: 'Probe',
      emoji: '📺',
      itens: [
        for (var i = pos.l; i < licoes.length && i < pos.l + 2; i++) ItemSetlist.daLicao(licoes[i]),
      ],
      criadoEm: 0,
      editadoEm: 0,
    );
  }

  void _assistir(BuildContext context) {
    final ouvir = OuvirCubit.de(context)!;
    ouvir.configurar(ouvir.state.config.copyWith(modo: _modo));
    if (_comSetlist) {
      final s = _setlistProbe(context);
      if (s != null) {
        unawaited(assistirSetlist(context, s));
        return;
      }
    }
    unawaited(PreferenciaAssistir.salvar(true));
    unawaited(tocarCursoDesde(context, _licao));
    unawaited(abrirTocando(context, assistir: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: BlocBuilder<CursoBloc, CursoState>(
        builder: (context, curso) {
          if (curso.status != CursoStatus.pronto) {
            return Center(
              child: curso.status == CursoStatus.erro
                  ? Text('currículo indisponível', style: Mixart.ui(size: 14))
                  : const CircularProgressIndicator(),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('📺 $_licao · ${_modo.name}${_comSetlist ? ' · setlist' : ''}',
                    key: const Key('probe-assistir-rotulo'),
                    textAlign: TextAlign.center,
                    style: Mixart.ui(size: 14, color: Mixart.textMuted)),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('probe-assistir'),
                  onPressed: () => _assistir(context),
                  style: FilledButton.styleFrom(minimumSize: const Size(240, 72), backgroundColor: Mixart.brand),
                  child: Text('▶ Assistir', style: Mixart.display(size: 26, color: Mixart.onBrand)),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _Galeria extends StatelessWidget {
  const _Galeria();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PistaPro — fases 1, 3 e 5', style: Mixart.display(size: 16)),
              const SizedBox(height: 8),
              const PistaPro(posJogador: 5, posCpu: 3, pista: 12, fase: 1),
              const SizedBox(height: 12),
              const PistaPro(posJogador: 9, posCpu: 7, pista: 12, fase: 3),
              const SizedBox(height: 12),
              const PistaPro(posJogador: 2, posCpu: 4, pista: 12, fase: 5),
              const SizedBox(height: 16),
              Text('Personagens', style: Mixart.display(size: 16)),
              const SizedBox(height: 8),
              const Row(children: [
                AvatarPersonagem(tamanho: 64, personagem: Personagem.pac),
                SizedBox(width: 24),
                AvatarPersonagem(tamanho: 64, personagem: Personagem.dash),
              ]),
              const SizedBox(height: 16),
              Text('Cenas do Lógica Animada', style: Mixart.display(size: 16)),
              const SizedBox(height: 8),
              CenaMissao(
                missao: missaoPara(0, 2),
                estado: {...missaoPara(0, 2).dados, 'avanco': 3},
                trilha: 0,
              ),
              const SizedBox(height: 10),
              CenaMissao(
                missao: missaoPara(1, 0),
                estado: {...missaoPara(1, 0).dados, 'atual': 1, 'v0': true, 'v1': false},
                trilha: 1,
              ),
              const SizedBox(height: 10),
              CenaMissao(
                missao: missaoPara(1, 3),
                estado: {...missaoPara(1, 3).dados, 'contagem': 2},
                trilha: 4,
              ),
              const SizedBox(height: 16),
              Text('Cenários crus — fases 2, 4 e 6', style: Mixart.display(size: 16)),
              const SizedBox(height: 8),
              Row(children: [
                for (final f in [2, 4, 6]) ...[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(height: 120, child: CenarioFase(fase: f)),
                    ),
                  ),
                  if (f != 6) const SizedBox(width: 10),
                ],
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
