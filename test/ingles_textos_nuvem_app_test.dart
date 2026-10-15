// Teste de APP dos textos na nuvem: o PacDartApp inteiro (Inglês) recebe o repositório de textos pelo
// `textosBuilder` (a mesma ligação que a produção usa com o Firestore) e o Mapa mostra o texto que só existia na
// nuvem, vindo de outro aparelho; um texto criado aqui vai para a nuvem da conta certa.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
import 'package:pac_dart/features/ia/data/cota_repository.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/data/textos_repository.dart';
import 'package:pac_dart/features/ingles/domain/texto_salvo.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ia_cenario_cubit_test.dart' show TutorCenarioFalso;

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

Future<FirestoreTextosRepository> _abrirApp(WidgetTester tester, FakeFirebaseFirestore nuvem) async {
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false});
  tester.view.physicalSize = const Size(1400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late FirestoreTextosRepository repo;
  await tester.runAsync(() async {
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoPorLinguagem: (_, l) => LocalProgressoRepository(prefixo: l.prefixoProgresso),
      revisaoBuilder: (_) => LocalRevisaoRepository(),
      rankingBuilder: () => _Ranking(),
      habitoBuilder: (u) => LocalHabitoRepository(uid: u.uid),
      tutorBuilder: () => TutorCenarioFalso(),
      iaCotaBuilder: (u) => LocalCotaRepository(uid: u.uid),
      curriculoBuilder: (l) => _LoaderEn(),
      textosBuilder: (u) => repo = FirestoreTextosRepository(u.uid, db: nuvem),
      linguagemInicial: Linguagem.ingles,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  });
  await _esperar(tester, find.byType(PalcoIngles));
  await _anda(tester, 3);
  return repo;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => FraseView.carencia = Duration.zero);
  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgets('o app em inglês mostra o texto que veio da nuvem e manda para ela o que for criado', (tester) async {
    final nuvem = FakeFirebaseFirestore();
    await nuvem.doc('users/teste-uid/textos/de-outro-aparelho').set(TextoSalvo(
          id: 'de-outro-aparelho',
          titulo: 'Escrito no computador',
          criadoEm: DateTime.fromMillisecondsSinceEpoch(5000),
          frases: const [FraseDoTexto('I wrote this on my computer.', 'Escrevi isto no computador.')],
        ).toJson());
    // texto de OUTRA conta: não pode aparecer
    await nuvem.doc('users/outra-conta/textos/alheio').set(TextoSalvo(
          id: 'alheio',
          titulo: 'De outra pessoa',
          criadoEm: DateTime.fromMillisecondsSinceEpoch(6000),
          frases: const [FraseDoTexto('Not mine.', 'Não é meu.')],
        ).toJson());

    final repo = await _abrirApp(tester, nuvem);
    final curso = tester.element(find.byType(HomePage)).read<CursoBloc>();

    expect(curso.state.trilhas.map((t) => t.textoId), ['', 'de-outro-aparelho']);
    expect(curso.state.trilhas.last.nivel, 'Escrito no computador');

    await tester.runAsync(() async {
      curso.add(TextoCriado(TextoSalvo(
        id: 'criado-aqui',
        titulo: 'Criado no celular',
        criadoEm: DateTime.fromMillisecondsSinceEpoch(9000),
        frases: const [FraseDoTexto('I wrote this on my phone.', 'Escrevi isto no celular.')],
      )));
      await curso.stream.firstWhere((s) => s.trilhas.length == 3);
      await repo.enviado;
    });
    final doc = await nuvem.doc('users/teste-uid/textos/criado-aqui').get();
    expect(doc.exists, isTrue, reason: 'o texto criado na tela foi para a nuvem da conta');
    expect((await nuvem.doc('users/outra-conta/textos/criado-aqui').get()).exists, isFalse);
  });
}
