// 🪜 As partes da lição no app inteiro: a lição de 5 frases (25 digitações) tem 3 partes; no fim da 1ª, "Parte
// concluída!" com Continuar e Parar; a fila fica salva e, reabrindo o app, a lição continua da parte 2.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/data/setlists_repository.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/features/ingles/domain/roteiro.dart';
import 'package:pac_dart/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async {}
  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async => true;
  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

/// A saída de áudio falsa: cada fala/silêncio fica PENDENTE até o teste decidir (o player fica "tocando"
/// parado na frase, sem som e sem relógio de verdade). `parar()` corta tudo o que está pendente.
/// A duração longa deixa o vigia de cada passo (segundos × 2,5 + 3 s) bem longe dos pumps do teste.
class _SaidaFake implements SaidaDeAudio {
  final pendentes = <({String tipo, String texto, Completer<FimDaFala> fim})>[];
  final faladas = <String>[];
  var paradas = 0;

  Future<FimDaFala> _pendente(String tipo, String texto) {
    final c = Completer<FimDaFala>();
    pendentes.add((tipo: tipo, texto: texto, fim: c));
    return c.future;
  }

  @override
  Future<FimDaFala> en(String texto, {required double fator}) {
    faladas.add(texto);
    return _pendente('en', texto);
  }

  @override
  Future<FimDaFala> pt(String texto, {required double fator}) => _pendente('pt', texto);

  @override
  Future<FimDaFala> silencio(Duration d) => _pendente('silencio', '');

  @override
  void parar() {
    paradas++;
    for (final p in pendentes) {
      if (!p.fim.isCompleted) p.fim.complete(FimDaFala.cortada);
    }
    pendentes.clear();
  }

  /// Outra fala do app cortou a frase do player (sem o player ter pedido).
  void cortarDeFora() {
    final vivas = [for (final p in pendentes) if (!p.fim.isCompleted) p];
    expect(vivas, isNotEmpty, reason: 'o player está esperando uma fala');
    vivas.last.fim.complete(FimDaFala.cortada);
    pendentes.remove(vivas.last);
  }

  @override
  void preaquecer(String texto) {}

  @override
  bool get somLiberado => true;

  @override
  double duracaoDe(String en) => 600;

  @override
  bool temGravacao(String en) => true;
}

/// Um currículo pequeno: 1 unidade, 2 lições, 5 frases.
class _LoaderEn extends CurriculoLoader {
  _LoaderEn() : super(linguagem: Linguagem.ingles);
  @override
  Future<List<Trilha>> carregar() async => const [
        Trilha(
          nivel: 'Na mesa',
          emoji: '🫖',
          etapa: 'A1 · Fundação',
          licoes: [
            Licao(nome: 'Chá da tarde', emoji: '🍵', id: 'mesa.cha', trechos: [
              Trecho(id: 'f-000001', quem: 'mike', cod: 'Tea, please.', dica: 'Chá, por favor.', out: ''),
              Trecho(id: 'f-000002', quem: 'ana', cod: 'Here you are.', dica: 'Aqui está.', out: ''),
              Trecho(id: 'f-000003', quem: 'mike', cod: 'Thank you.', dica: 'Obrigado.', out: ''),
              Trecho(id: 'f-000004', quem: 'ana', cod: 'Some milk?', dica: 'Um pouco de leite?', out: ''),
              Trecho(id: 'f-000005', quem: 'mike', cod: 'Yes, please.', dica: 'Sim, por favor.', out: ''),
            ]),
          ],
        ),
      ];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

class _LoaderDart extends CurriculoLoader {
  _LoaderDart() : super(linguagem: Linguagem.dart);
  @override
  Future<List<Trilha>> carregar() async => const [
        Trilha(
          nivel: 'Fundamentos',
          emoji: '🎯',
          licoes: [
            Licao(nome: 'Variáveis', emoji: '📦', trechos: [
              Trecho(cod: "var nome = 'Ana';", dica: 'Declare uma variável.', out: ''),
            ]),
          ],
        ),
      ];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

/// O relógio do HUD redesenha todo segundo (pumpAndSettle nunca assenta) e o app nasce dentro de
/// `runAsync`: os blocs só andam com tempo real entre os pumps.
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

Future<void> _abrirApp(WidgetTester tester, {required Linguagem linguagem, _SaidaFake? saida, Size? tela, bool limpar = true}) async {
  if (limpar) SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false});
  tester.view.physicalSize = tela ?? const Size(1400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoPorLinguagem: (_, l) => LocalProgressoRepository(prefixo: l.prefixoProgresso),
      revisaoBuilder: (_) => LocalRevisaoRepository(),
      palavrasBuilder: (_) => MemoriaPalavrasRepository(),
      setlistsBuilder: (_) => MemoriaSetlistsRepository(),
      saidaOuvirBuilder: () => saida ?? _SaidaFake(),
      rankingBuilder: () => _Ranking(),
      habitoBuilder: (u) => LocalHabitoRepository(uid: u.uid),
      curriculoBuilder: (l) => l == Linguagem.ingles ? _LoaderEn() : _LoaderDart(),
      linguagemInicial: linguagem,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  });
  await _esperar(tester, find.byType(PalcoIngles));
  await _anda(tester, 4);
}

Finder _k(String chave) => find.byKey(Key(chave));




/// A frase da vez (o palco avisa o curso a cada passo).
String _fraseDaVez(WidgetTester tester) =>
    tester.element(find.byType(PalcoIngles)).read<CursoBloc>().state.trecho.cod;

/// Digita a frase da vez e segue (Enter).
Future<void> _passo(WidgetTester tester) async {
  await tester.enterText(find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last, _fraseDaVez(tester));
  await _anda(tester, 3);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await _anda(tester, 3);
}

void main() {
  setUpAll(() => EtapasDaLicao.ligadas = true);
  tearDownAll(() => EtapasDaLicao.ligadas = false);
  Mixart.usarGoogleFonts = false;
  setUp(() => FraseView.carencia = Duration.zero);

  testWidgets('5 frases (25 digitações) = 3 partes: no fim da 1ª, "Parte concluída!"; continuar; reabrir o app continua da parte 2',
      (tester) async {
    await _abrirApp(tester, linguagem: Linguagem.ingles);
    expect(_k('etapa-atual'), findsOneWidget);
    expect(find.text('Parte 1 de 3'), findsOneWidget);
    for (var i = 0; i < 20 && _k('etapa-concluida').evaluate().isEmpty; i++) {
      await _passo(tester);
    }
    expect(_k('etapa-concluida'), findsOneWidget);
    expect(find.text('Parte 1 de 3 concluída!'), findsOneWidget);
    final p = await SharedPreferences.getInstance();
    expect(p.getString('en_etapa_mesa.cha'), isNotNull, reason: 'a fila fica salva no fim da etapa');
    await tester.tap(_k('etapa-continuar'));
    await _anda(tester, 4);
    expect(_k('etapa-concluida'), findsNothing);
    expect(find.text('Parte 2 de 3'), findsOneWidget);
    // reabre o app (as prefs ficam): a lição continua da etapa 2
    await tester.pumpWidget(const SizedBox());
    await _anda(tester, 2);
    await _abrirApp(tester, linguagem: Linguagem.ingles, limpar: false);
    await _anda(tester, 4);
    expect(_k('etapa-retomada'), findsOneWidget);
    expect(find.text('Parte 2 de 3'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
