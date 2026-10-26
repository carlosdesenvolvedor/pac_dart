// 🏠 A tela Início (26/out/2026): o app abre nela, por cima da lição; "Continuar" volta para a frase onde parou;
// o menu tem os atalhos e as ferramentas; a lição fica com o cabeçalho limpo ("☰ Início") e o mapa sem as
// ferramentas.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/auth/data/auth_repository.dart';
import 'package:pac_dart/features/auth/domain/app_user.dart';
import 'package:pac_dart/features/auth/presentation/auth_cubit.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/pages/inicio_page.dart';
import 'package:pac_dart/features/curso/presentation/pages/mapa_page.dart';
import 'package:pac_dart/features/curso/presentation/widgets/hud.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/data/setlists_repository.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
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
              Trecho(id: 'f-000001', quem: 'mike', cod: 'Tea with milk, please.', dica: 'Chá com leite, por favor.', out: ''),
              Trecho(id: 'f-000002', quem: 'ana', cod: 'Here you are.', dica: 'Aqui está.', out: ''),
              Trecho(id: 'f-000003', quem: 'mike', cod: 'Thank you so much.', dica: 'Muito obrigado.', out: ''),
            ]),
            Licao(nome: 'De novo', emoji: '🔁', id: 'mesa.de-novo', trechos: [
              Trecho(id: 'f-000004', quem: 'ana', cod: 'How are you?', dica: 'Como vai você?', out: ''),
              Trecho(id: 'f-000005', quem: 'mike', cod: 'Fine, thanks.', dica: 'Bem, obrigado.', out: ''),
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

/// Deixa terminar as animações de uma vez (rotas, folhas, snackbar).
Future<void> _passa(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
  await _anda(tester, 2);
}

Future<void> _esperar(WidgetTester tester, Finder alvo) async {
  for (var i = 0; i < 25 && alvo.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }
}

Future<void> _abrirApp(WidgetTester tester, {required Linguagem linguagem, _SaidaFake? saida, Size? tela}) async {
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false});
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
  await _esperar(tester, find.byKey(const Key('inicio')));
  await _anda(tester, 4);
}

Finder _k(String chave) => find.byKey(Key(chave));

Future<void> _tocar(WidgetTester tester, String chave) async {
  final alvo = _k(chave);
  expect(alvo, findsOneWidget, reason: chave);
  await tester.ensureVisible(alvo);
  await _passa(tester);
  await tester.tap(alvo);
  await _passa(tester);
}


void main() {
  Mixart.usarGoogleFonts = false;
  setUp(() => Inicio.ligado = true);
  tearDown(() => Inicio.ligado = false);

  testWidgets('abre no Início, por cima da lição; "Continuar" volta para a frase; "☰ Início" abre de novo',
      (tester) async {
    await _abrirApp(tester, linguagem: Linguagem.ingles);
    await _esperar(tester, _k('inicio'));
    expect(_k('inicio'), findsOneWidget);
    // o cartão Continuar mostra onde parou
    expect(find.text('Chá da tarde'), findsWidgets);
    expect(find.textContaining('Na mesa · lição 1 de 2'), findsOneWidget);
    // o menu: os atalhos e as ferramentas do inglês
    expect(find.byType(AtalhosHud), findsOneWidget);
    expect(find.byType(CartaoOuvir), findsOneWidget);
    expect(find.byType(CartaoConversar), findsOneWidget);
    expect(find.byType(CartaoBaralhos), findsOneWidget);
    // a lição está embaixo (viva), sem o cabeçalho cheio
    expect(find.byType(PalcoIngles, skipOffstage: false), findsOneWidget);
    await _tocar(tester, 'inicio-continuar');
    expect(_k('inicio'), findsNothing);
    expect(find.byType(PalcoIngles), findsOneWidget);
    expect(_k('abrir-inicio'), findsOneWidget);
    expect(find.byType(Hud), findsNothing, reason: 'a lição fica limpa');
    expect(find.text('SCORE'), findsNothing);
    await _tocar(tester, 'abrir-inicio');
    expect(_k('inicio'), findsOneWidget);
  });

  testWidgets('o mapa fica só com o caminho (as ferramentas moram no Início)', (tester) async {
    await _abrirApp(tester, linguagem: Linguagem.ingles);
    await _esperar(tester, _k('inicio'));
    await tester.tap(find.text('Mapa'));
    await _passa(tester);
    expect(find.byType(MapaPage), findsOneWidget);
    expect(find.descendant(of: find.byType(MapaPage), matching: find.byType(CartaoOuvir)), findsNothing);
    expect(find.descendant(of: find.byType(MapaPage), matching: find.byType(HeroDashboard)), findsNothing);
  });

  testWidgets('no curso de Dart também abre no Início (sem as ferramentas do inglês)', (tester) async {
    await _abrirApp(tester, linguagem: Linguagem.dart);
    await _esperar(tester, _k('inicio'));
    expect(_k('inicio-continuar'), findsOneWidget);
    expect(find.byType(CartaoOuvir), findsNothing);
    await _tocar(tester, 'inicio-continuar');
    expect(_k('abrir-inicio'), findsOneWidget);
  });
}
