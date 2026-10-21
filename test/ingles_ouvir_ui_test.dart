// "🎧 Ouvir" (FASE-8): o hub (Curso na ordem com "Continuar", Minhas setlists, Explorar o curso), criar
// setlist, o estado vazio, a folha "Pôr em qual setlist?", a folha das frases (vira um `trecho`), e a
// página da setlist (reordenar, deslizar para remover + Desfazer, item indisponível) — a 360, 390 e 1400 px,
// no tema escuro e no claro, sem nada estourando.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/preferencias_ouvir.dart';
import 'package:pac_dart/features/ingles/data/setlists_repository.dart';
import 'package:pac_dart/features/ingles/domain/config_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:pac_dart/features/ingles/domain/setlist.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_acoes.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_page.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/setlist_page.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/setlists_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ingles_cartoes_ui_test.dart' show LoaderTeste;

/// Saída de áudio muda: toda fala "acaba" na hora; cada frase dura 2 s.
class SaidaFake implements SaidaDeAudio {
  final falas = <String>[];
  @override
  Future<FimDaFala> en(String texto, {required double fator}) async {
    falas.add(texto);
    return FimDaFala.acabou;
  }

  @override
  Future<FimDaFala> pt(String texto, {required double fator}) async => FimDaFala.acabou;
  @override
  Future<FimDaFala> silencio(Duration d) async => FimDaFala.acabou;
  @override
  void parar() {}
  @override
  void preaquecer(String texto) {}
  @override
  bool get somLiberado => true;
  @override
  double duracaoDe(String en) => 2;
  @override
  bool temGravacao(String en) => false;
}

/// O player sem motor: anota as chamadas e muda o estado como o de verdade mudaria (o suficiente para a UI).
class OuvirFake extends OuvirCubit {
  OuvirFake({PreferenciasOuvir? prefs}) : super(saida: SaidaFake(), prefs: prefs ?? PreferenciasOuvirMemoria());

  final chamadas = <String>[];
  ({FonteOuvir fonte, List<Faixa> fila, int inicio})? tocou;

  void emitir(OuvirState s) => emit(s);

  @override
  Future<void> tocar(FonteOuvir fonte, List<Faixa> fila, {int inicio = 0}) async {
    chamadas.add('tocar');
    tocou = (fonte: fonte, fila: fila, inicio: inicio);
    emit(state.copyWith(status: StatusOuvir.tocando, semMotivo: true, fonte: fonte, fila: fila, indice: inicio));
  }

  @override
  void pausar() {
    chamadas.add('pausar');
    emit(state.copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.usuario));
  }

  @override
  Future<void> continuar() async => chamadas.add('continuar');
  @override
  void alternar() => chamadas.add('alternar');
  @override
  void proxima() => chamadas.add('proxima');
  @override
  void anterior() => chamadas.add('anterior');
  @override
  void repetirAtual() => chamadas.add('repetirAtual');
  @override
  void irPara(int i) => chamadas.add('irPara:$i');
  @override
  void proximaLicao() => chamadas.add('proximaLicao');
  @override
  void licaoAnterior() => chamadas.add('licaoAnterior');
  @override
  void configurar(ConfigOuvir c) {
    chamadas.add('configurar');
    emit(state.copyWith(config: c));
  }

  @override
  void desligarEm(DesligarEm d) {
    chamadas.add('desligarEm:${d.name}');
    emit(state.copyWith(desligar: d));
  }

  @override
  void fechar() {
    chamadas.add('fechar');
    emit(OuvirState(config: state.config, telaCheia: state.telaCheia));
  }
}

/// Um curso pequeno: duas etapas, três lições (7 frases) e "Meus cartões" (texto do aluno).
List<Trilha> trilhasOuvir() => const [
      Trilha(nivel: 'Primeiro contato', emoji: '👋', etapa: 'A1 · Fundação', licoes: [
        Licao(nome: 'Oi, tudo bem?', emoji: '🙂', id: 'pc.oi', trechos: [
          Trecho(cod: 'Hi! How are you?', dica: 'Oi! Tudo bem?', out: '', id: 'f-1', quem: 'mike'),
          Trecho(cod: "I'm fine, thanks.", dica: 'Tudo bem, obrigado.', out: '', id: 'f-2', quem: 'voce'),
          Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: '', id: 'f-3', quem: 'mike'),
        ]),
        Licao(nome: 'No café', emoji: '☕', id: 'pc.cafe', trechos: [
          Trecho(cod: 'A coffee, please.', dica: 'Um café, por favor.', out: '', id: 'f-4', quem: 'voce'),
          Trecho(cod: 'Here you go.', dica: 'Aqui está.', out: '', id: 'f-5', quem: 'atendente'),
        ]),
      ]),
      Trilha(nivel: 'Viagem', emoji: '✈️', etapa: 'A2 · Base', licoes: [
        Licao(nome: 'No aeroporto', emoji: '🛫', id: 'vg.aeroporto', trechos: [
          Trecho(cod: 'Where is gate twelve?', dica: 'Onde fica o portão doze?', out: '', id: 'f-6', quem: 'voce'),
          Trecho(cod: 'It is on the left.', dica: 'Fica à esquerda.', out: '', id: 'f-7', quem: 'sarah'),
        ]),
      ]),
      Trilha(nivel: 'Meus cartões', emoji: '📝', etapa: 'Meus textos', textoId: 'cartoes', licoes: [
        Licao(nome: 'Parte 1', emoji: '📝', id: 'txt-cartoes-1', trechos: [
          Trecho(cod: 'The garden is lovely.', dica: 'O jardim é lindo.', out: ''),
        ]),
      ]),
    ];

/// Tudo que as telas do Ouvir precisam, montado num app de teste.
class MontagemOuvir {
  final CursoBloc curso;
  final OuvirFake ouvir;
  final SetlistsCubit setlists;
  final MemoriaSetlistsRepository repo;
  final NavegadorOuvir nav;
  MontagemOuvir(this.curso, this.ouvir, this.setlists, this.repo, this.nav);
}

/// Monta o app com o [OuvirShell] no `builder` e um botão `abrir` que chama [aoAbrir].
Future<MontagemOuvir> montarOuvir(
  WidgetTester tester, {
  Size tamanho = const Size(1000, 1600),
  BancoSetlists banco = const BancoSetlists(),
  PreferenciasOuvir? prefs,
  bool claro = false,
  Future<void> Function(BuildContext c)? aoAbrir,
}) async {
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false});
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Mixart.atual = claro ? Paleta.flutterClaro : Paleta.mixart;
  addTearDown(() => Mixart.atual = Paleta.mixart);
  final curso = CursoBloc(loader: LoaderTeste(trilhasOuvir()), progresso: LocalProgressoRepository(prefixo: 'en_'))
    ..add(const CursoIniciado());
  addTearDown(curso.close);
  await tester.runAsync(() => curso.stream.firstWhere((s) => s.status == CursoStatus.pronto));
  final ouvir = OuvirFake(prefs: prefs);
  addTearDown(ouvir.close);
  final repo = MemoriaSetlistsRepository(banco);
  final setlists = SetlistsCubit(repo: repo, agora: () => 1760000000000, folga: Duration.zero);
  addTearDown(setlists.close);
  await tester.runAsync(setlists.carregar);
  final nav = NavegadorOuvir();
  await tester.pumpWidget(RepositoryProvider<NavegadorOuvir>.value(
    value: nav,
    child: MultiBlocProvider(
      providers: [
        BlocProvider<CursoBloc>.value(value: curso),
        BlocProvider<OuvirCubit>.value(value: ouvir),
        BlocProvider<SetlistsCubit>.value(value: setlists),
      ],
      child: MaterialApp(
        theme: Mixart.tema(),
        navigatorKey: nav.chave,
        navigatorObservers: nav.observadores,
        builder: (c, child) => OuvirShell.envolver(c, child!),
        home: Builder(
          builder: (context) => Scaffold(
            backgroundColor: Mixart.bg,
            body: Center(
              child: TextButton(
                key: const Key('abrir'),
                onPressed: () => (aoAbrir ?? abrirOuvir)(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  ));
  return MontagemOuvir(curso, ouvir, setlists, repo, nav);
}

Future<void> abrir(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('abrir')));
  await tester.pumpAndSettle();
}

/// Rola a lista até [chave] aparecer.
Future<void> rolarAte(WidgetTester tester, String chave, {String lista = 'ouvir-lista'}) async {
  await tester.scrollUntilVisible(find.byKey(Key(chave)), 200, scrollable: find.descendant(
    of: find.byKey(Key(lista)),
    matching: find.byType(Scrollable),
  ).first);
  await tester.pumpAndSettle();
}

ItemSetlist _item(String id, TipoItem tipo, String ref, String rotulo) =>
    ItemSetlist(id: id, tipo: tipo, ref: ref, rotulo: rotulo, criadoEm: 1);

/// Uma setlist "Ônibus" com a lição pc.oi, a frase f-6 e uma lição que saiu do curso.
BancoSetlists bancoComSetlist() => BancoSetlists(porId: {
      's1': Setlist(id: 's1', nome: 'Ônibus', emoji: '🚌', criadoEm: 1, editadoEm: 2, itens: [
        _item('i1', TipoItem.licao, 'pc.oi', 'Oi, tudo bem?'),
        ItemSetlist(
            id: 'i2', tipo: TipoItem.frase, ref: 'f-6', licaoId: 'vg.aeroporto', rotulo: '“Where is gate twelve?”',
            en: 'Where is gate twelve?', pt: 'Onde fica o portão doze?', criadoEm: 1),
        _item('i3', TipoItem.licao, 'sumiu.daqui', 'Lição antiga'),
      ]),
    }, ultimaUsada: 's1');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  group('o hub', () {
    testWidgets('mostra as três seções, o total do curso e o estado vazio das setlists', (tester) async {
      await montarOuvir(tester);
      await abrir(tester);
      expect(find.byType(OuvirPage), findsOneWidget);
      expect(find.text('🎧 Ouvir'), findsOneWidget);
      expect(find.text('Curso na ordem'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('ouvir-curso-total'))).data, '7 frases · ~14 s');
      expect(find.text('MINHAS SETLISTS'), findsOneWidget);
      expect(find.byKey(const Key('ouvir-setlists-vazio')), findsOneWidget);
      expect(find.text('EXPLORAR O CURSO'), findsOneWidget);
      expect(find.byKey(const Key('ouvir-curso-continuar')), findsNothing, reason: 'nada ouvido ainda');
      expect(find.byKey(const Key('ouvir-curso-atual')), findsOneWidget);
      expect(find.byKey(const Key('ouvir-curso-inicio')), findsOneWidget);
      // a árvore: as duas etapas e "Meus textos" (com a etiqueta da voz do sistema)
      expect(find.byKey(const Key('arvore-etapa-A1')), findsOneWidget);
      expect(find.byKey(const Key('arvore-etapa-A2')), findsOneWidget);
      await rolarAte(tester, 'arvore-etapa-meus');
      expect(find.text('voz do sistema'), findsOneWidget);
    });

    testWidgets('"Continuar" mostra onde parou e toca o curso dali', (tester) async {
      final prefs = PreferenciasOuvirMemoria()..posicoes['curso'] = (i: 3, chave: 'f-4');
      final m = await montarOuvir(tester, prefs: prefs);
      await abrir(tester);
      expect(tester.widget<Text>(find.byKey(const Key('ouvir-curso-continuar-sub'))).data,
          'Parou em: ☕ No café (A1)');
      await tester.tap(find.byKey(const Key('ouvir-curso-continuar')));
      await tester.pumpAndSettle();
      expect(m.ouvir.tocou!.fonte.id, 'curso');
      expect(m.ouvir.tocou!.inicio, 3);
      expect(m.ouvir.tocou!.fila.length, 7, reason: 'o curso sem os textos do aluno');
      // e o mini-player aparece embaixo do hub
      expect(find.byKey(const Key('mini-player')), findsOneWidget);
    });

    testWidgets('"Do começo" e "Da minha lição atual" tocam o curso', (tester) async {
      final m = await montarOuvir(tester);
      m.curso
        ..add(const TrilhaSelecionada(0))
        ..add(const LicaoSelecionada(1));
      await tester.pump();
      await abrir(tester);
      await tester.tap(find.byKey(const Key('ouvir-curso-atual')));
      await tester.pumpAndSettle();
      expect(m.ouvir.tocou!.inicio, 3, reason: 'a lição 2 começa na 4ª frase');
      await tester.tap(find.byKey(const Key('ouvir-curso-inicio')));
      await tester.pumpAndSettle();
      expect(m.ouvir.tocou!.inicio, 0);
      expect(m.ouvir.tocou!.fonte.titulo, 'Curso inteiro');
    });

    testWidgets('"＋ Nova setlist" cria a setlist e o cartão aparece com o resumo', (tester) async {
      final m = await montarOuvir(tester);
      await abrir(tester);
      await tester.tap(find.byKey(const Key('ouvir-nova-setlist')));
      await tester.pumpAndSettle();
      expect(find.text('Nome da setlist'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('nova-setlist-nome')), 'Inglês no ônibus');
      await tester.tap(find.byKey(const Key('nova-setlist-emoji-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('nova-setlist-criar')));
      await tester.pumpAndSettle();
      final s = m.setlists.state.visiveis.single;
      expect(s.nome, 'Inglês no ônibus');
      expect(s.emoji, '🚌');
      expect(find.byKey(Key('setlist-${s.id}')), findsOneWidget);
      expect(find.text('0 itens · 0 frases'), findsOneWidget);
      expect(find.byKey(const Key('ouvir-setlists-vazio')), findsNothing);
    });

    testWidgets('⋯ Renomear e Apagar (com confirmação)', (tester) async {
      final m = await montarOuvir(tester, banco: bancoComSetlist());
      await abrir(tester);
      expect(find.text('Ônibus'), findsOneWidget);
      expect(find.text('3 itens · 4 frases · ~8 s'), findsOneWidget);
      await tester.tap(find.byKey(const Key('setlist-menu-s1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Renomear'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('nova-setlist-nome')), 'Academia');
      await tester.tap(find.byKey(const Key('nova-setlist-criar')));
      await tester.pumpAndSettle();
      expect(m.setlists.state.porId['s1']!.nome, 'Academia');
      await tester.tap(find.byKey(const Key('setlist-menu-s1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar'));
      await tester.pumpAndSettle();
      expect(find.text('Apagar «Academia»?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('setlist-apagar-confirmar')));
      await tester.pumpAndSettle();
      expect(m.setlists.state.visiveis, isEmpty);
      expect(find.byKey(const Key('ouvir-setlists-vazio')), findsOneWidget);
    });

    testWidgets('▶ numa setlist toca a setlist (fonte setlist:<id>)', (tester) async {
      final m = await montarOuvir(tester, banco: bancoComSetlist());
      await abrir(tester);
      await tester.tap(find.byKey(const Key('setlist-tocar-s1')));
      await tester.pumpAndSettle();
      expect(m.ouvir.tocou!.fonte, const FonteOuvir('setlist:s1', 'Ônibus'));
      expect(m.ouvir.tocou!.fila.map((f) => f.chave), ['f-1', 'f-2', 'f-3', 'f-6']);
    });
  });

  group('a árvore e o ➕', () {
    Future<void> abrirLicoes(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('arvore-etapa-A1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('arvore-unidade-tr:pc')));
      await tester.pumpAndSettle();
    }

    testWidgets('lição trancada mostra 🔒 e toca do mesmo jeito', (tester) async {
      final m = await montarOuvir(tester);
      await abrir(tester);
      await abrirLicoes(tester);
      expect(find.byKey(const Key('arvore-licao-pc.oi')), findsOneWidget);
      // a atual (pc.oi) não é trancada; a seguinte é
      expect(find.text('🔒 à frente'), findsOneWidget);
      await rolarAte(tester, 'arvore-tocar-licao-pc.cafe');
      await tester.tap(find.byKey(const Key('arvore-tocar-licao-pc.cafe')));
      await tester.pumpAndSettle();
      expect(m.ouvir.tocou!.fonte, const FonteOuvir('avulso', 'No café'));
      expect(m.ouvir.tocou!.fila.map((f) => f.chave), ['f-4', 'f-5']);
    });

    testWidgets('➕ sem setlist cria "Minha setlist"; Desfazer tira o item', (tester) async {
      final m = await montarOuvir(tester);
      await abrir(tester);
      await abrirLicoes(tester);
      await tester.tap(find.byKey(const Key('arvore-add-licao-pc.oi')));
      await tester.pumpAndSettle();
      final s = m.setlists.state.visiveis.single;
      expect(s.nome, 'Minha setlist');
      expect(s.itens.single.tipo, TipoItem.licao);
      expect(find.text('Adicionado a «Minha setlist».'), findsOneWidget);
      // de novo: já está
      await tester.tap(find.byKey(const Key('arvore-add-licao-pc.oi')));
      await tester.pumpAndSettle();
      expect(find.text('Já está em «Minha setlist».'), findsOneWidget);
      await tester.tap(find.byKey(const Key('arvore-add-unidade-tr:pc')));
      await tester.pumpAndSettle();
      expect(m.setlists.state.visiveis.single.itens.length, 2);
      await tester.tap(find.byKey(const Key('aviso-desfazer')));
      await tester.pumpAndSettle();
      expect(m.setlists.state.visiveis.single.itens.map((i) => i.tipo), [TipoItem.licao]);
    });

    testWidgets('toque longo no ➕ abre "Pôr em qual setlist?" (a última usada marcada) e cria outra', (tester) async {
      final m = await montarOuvir(tester, banco: bancoComSetlist());
      await abrir(tester);
      await tester.longPress(find.byKey(const Key('arvore-add-etapa-A2')));
      await tester.pumpAndSettle();
      expect(find.text('Pôr em qual setlist?'), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('escolher-setlist-s1')), matching: find.byIcon(Icons.radio_button_checked_rounded)),
          findsOneWidget,
          reason: 'a última usada vem marcada');
      expect(find.byKey(const Key('escolher-tocar-agora')), findsNothing, reason: 'só com o player ativo');
      await tester.tap(find.byKey(const Key('escolher-nova-setlist')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('nova-setlist-nome')), 'Viagem');
      await tester.pump();
      await tester.tap(find.byKey(const Key('nova-setlist-criar')));
      await tester.pumpAndSettle();
      final nova = m.setlists.state.visiveis.firstWhere((s) => s.nome == 'Viagem');
      expect(nova.itens.single.tipo, TipoItem.etapa);
      expect(nova.itens.single.ref, 'A2');
      expect(find.text('Adicionado a «Viagem».'), findsOneWidget);
    });

    testWidgets('escolher uma setlist da folha põe o item nela', (tester) async {
      final m = await montarOuvir(tester, banco: bancoComSetlist());
      await abrir(tester);
      await tester.longPress(find.byKey(const Key('arvore-add-etapa-A1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('escolher-setlist-s1')));
      await tester.pumpAndSettle();
      expect(m.setlists.state.porId['s1']!.itens.last.ref, 'A1');
      expect(find.text('Adicionado a «Ônibus».'), findsOneWidget);
    });

    testWidgets('leitor de tela: etapa/unidade dizem se estão abertas; a caixinha da frase diz qual frase é',
        (tester) async {
      final sem = tester.ensureSemantics();
      await montarOuvir(tester);
      await abrir(tester);
      expect(tester.getSemantics(find.byKey(const Key('arvore-etapa-A1'))),
          isSemantics(hasExpandedState: true, isExpanded: false, hasTapAction: true));
      await abrirLicoes(tester);
      expect(tester.getSemantics(find.byKey(const Key('arvore-etapa-A1'))),
          isSemantics(hasExpandedState: true, isExpanded: true));
      expect(tester.getSemantics(find.byKey(const Key('arvore-licao-pc.oi'))),
          isSemantics(hasExpandedState: false, onTapHint: 'ouvir esta lição'));

      await tester.tap(find.byKey(const Key('arvore-frases-pc.oi')));
      await tester.pumpAndSettle();
      final linha = tester.getSemantics(find.byKey(const Key('frase-f-1')));
      expect(linha, isSemantics(hasCheckedState: true, isChecked: false, hasTapAction: true));
      expect(linha.label, contains('Hi! How are you?'));
      expect(linha.label, contains('Oi! Tudo bem?'));
      await tester.tap(find.byKey(const Key('frase-f-1')));
      await tester.pump();
      expect(tester.getSemantics(find.byKey(const Key('frase-f-1'))), isSemantics(isChecked: true));
      // o 🔊 continua um botão à parte
      final ouvir = tester.getSemantics(find.byTooltip('Ouvir').first);
      expect(ouvir, isSemantics(hasTapAction: true, hasCheckedState: false));
      expect(ouvir.id, isNot(linha.id));
      sem.dispose();
    });

    testWidgets('"Escolher frases…" marca duas frases e vira um trecho na setlist', (tester) async {
      final m = await montarOuvir(tester);
      await abrir(tester);
      await abrirLicoes(tester);
      await tester.tap(find.byKey(const Key('arvore-frases-pc.oi')));
      await tester.pumpAndSettle();
      expect(find.text('Hi! How are you?'), findsOneWidget);
      expect(find.text('Oi! Tudo bem?'), findsOneWidget);
      final add = find.byKey(const Key('frases-add'));
      expect(tester.widget<ButtonStyleButton>(add).onPressed, isNull, reason: 'nada marcado');
      await tester.tap(find.byKey(const Key('frase-f-1')));
      await tester.tap(find.byKey(const Key('frase-f-3')));
      await tester.pump();
      expect(find.text('Pôr 2 frases na setlist'), findsOneWidget);
      await tester.tap(add);
      await tester.pumpAndSettle();
      final item = m.setlists.state.visiveis.single.itens.single;
      expect(item.tipo, TipoItem.trecho);
      expect(item.ref, 'pc.oi');
      expect(item.chaves, ['f-1', 'f-3']);
    });

    testWidgets('"Ouvir só estas" toca só as frases marcadas', (tester) async {
      final m = await montarOuvir(tester);
      await abrir(tester);
      await abrirLicoes(tester);
      await tester.tap(find.byKey(const Key('arvore-frases-pc.oi')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('frase-f-2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('frases-tocar')));
      await tester.pumpAndSettle();
      expect(m.ouvir.tocou!.fila.map((f) => f.chave), ['f-2']);
      expect(m.setlists.state.visiveis, isEmpty);
    });
  });

  group('a página da setlist', () {
    Future<MontagemOuvir> abrirSetlistS1(WidgetTester tester, {Size tamanho = const Size(1000, 1600), bool claro = false}) async {
      final m = await montarOuvir(tester, banco: bancoComSetlist(), tamanho: tamanho, claro: claro);
      await abrir(tester);
      await tester.tap(find.byKey(const Key('setlist-s1')));
      await tester.pumpAndSettle();
      expect(find.byType(SetlistPage), findsOneWidget);
      return m;
    }

    testWidgets('mostra o resumo, os itens e o indisponível (apagado, com Remover)', (tester) async {
      final m = await abrirSetlistS1(tester);
      expect(tester.widget<Text>(find.byKey(const Key('setlist-resumo'))).data, '3 itens · 4 frases · ~8 s');
      expect(find.text('Item indisponível (saiu do curso)'), findsOneWidget);
      expect(find.text('3 frases · ~6 s'), findsOneWidget);
      await tester.tap(find.byKey(const Key('setlist-remover-i3')));
      await tester.pumpAndSettle();
      expect(m.setlists.state.porId['s1']!.itens.map((i) => i.id), ['i1', 'i2']);
      expect(find.text('Removido.'), findsOneWidget);
    });

    testWidgets('tocar num item toca a setlist dali; ▶ Tocar toca do começo', (tester) async {
      final m = await abrirSetlistS1(tester);
      await tester.tap(find.byKey(const Key('setlist-item-i2')));
      await tester.pumpAndSettle();
      expect(m.ouvir.tocou!.inicio, 3);
      await tester.tap(find.byKey(const Key('setlist-tocar')));
      await tester.pumpAndSettle();
      expect(m.ouvir.tocou!.inicio, 0);
      expect(m.ouvir.tocou!.fonte.id, 'setlist:s1');
    });

    testWidgets('arrastar pela alça reordena; ⋯ Mover para baixo também', (tester) async {
      final m = await abrirSetlistS1(tester);
      final alca = find.descendant(
          of: find.byKey(const Key('setlist-item-i1')), matching: find.byIcon(Icons.drag_indicator_rounded));
      final gesto = await tester.startGesture(tester.getCenter(alca));
      await tester.pump(const Duration(milliseconds: 50));
      await gesto.moveBy(const Offset(0, 90));
      await tester.pump();
      await gesto.moveBy(const Offset(0, 90));
      await tester.pump();
      await gesto.up();
      await tester.pumpAndSettle();
      expect(m.setlists.state.porId['s1']!.itens.first.id, isNot('i1'));
      // volta ao começo pelo menu (alternativa acessível ao arrastar)
      final ids = m.setlists.state.porId['s1']!.itens.map((i) => i.id).toList();
      await tester.tap(find.byKey(Key('setlist-item-menu-${ids.first}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mover para baixo'));
      await tester.pumpAndSettle();
      expect(m.setlists.state.porId['s1']!.itens.map((i) => i.id).toList(), [ids[1], ids[0], ids[2]]);
    });

    testWidgets('deslizar remove e "Desfazer" devolve na mesma posição', (tester) async {
      final m = await abrirSetlistS1(tester);
      await tester.drag(find.byKey(const Key('setlist-item-i1')), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(m.setlists.state.porId['s1']!.itens.map((i) => i.id), ['i2', 'i3']);
      expect(find.byKey(const Key('setlist-item-i1')), findsNothing);
      await tester.tap(find.byKey(const Key('aviso-desfazer')));
      await tester.pumpAndSettle();
      expect(m.setlists.state.porId['s1']!.itens.map((i) => i.id), ['i1', 'i2', 'i3']);
      expect(find.byKey(const Key('setlist-item-i1')), findsOneWidget);
    });

    testWidgets('editar o nome na própria página renomeia', (tester) async {
      final m = await abrirSetlistS1(tester);
      await tester.enterText(find.byKey(const Key('setlist-nome')), 'Corrida');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(m.setlists.state.porId['s1']!.nome, 'Corrida');
    });

    testWidgets('setlist vazia mostra o convite', (tester) async {
      await montarOuvir(tester,
          banco: const BancoSetlists(porId: {'v': Setlist(id: 'v', nome: 'Vazia', criadoEm: 1, editadoEm: 1)}));
      await abrir(tester);
      await tester.tap(find.byKey(const Key('setlist-v')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('setlist-vazia')), findsOneWidget);
      expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('setlist-tocar'))).onPressed, isNull);
    });
  });

  group('nada estoura', () {
    for (final largura in [360.0, 390.0, 1400.0]) {
      for (final claro in [false, true]) {
        final nome = '${largura.toInt()} px ${claro ? 'claro' : 'escuro'}';
        testWidgets('hub com a árvore aberta, folhas e página da setlist — $nome', (tester) async {
          final m = await montarOuvir(tester, banco: bancoComSetlist(), tamanho: Size(largura, 900), claro: claro);
          await abrir(tester);
          // tocando: o mini-player embaixo
          await tester.tap(find.byKey(const Key('ouvir-curso-inicio')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('mini-player')), findsOneWidget);
          await rolarAte(tester, 'arvore-etapa-A1');
          await tester.tap(find.byKey(const Key('arvore-etapa-A1')));
          await tester.pumpAndSettle();
          await rolarAte(tester, 'arvore-unidade-tr:pc');
          await tester.tap(find.byKey(const Key('arvore-unidade-tr:pc')));
          await tester.pumpAndSettle();
          await rolarAte(tester, 'arvore-frases-pc.cafe');
          expect(tester.takeException(), isNull);
          // a folha das frases
          await tester.tap(find.byKey(const Key('arvore-frases-pc.cafe')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('frases-todas')));
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();
          // a folha das setlists (com "Tocar agora", o player está ativo) e o formulário aberto
          await tester.longPress(find.byKey(const Key('arvore-add-licao-pc.cafe')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('escolher-tocar-agora')), findsOneWidget);
          await tester.tap(find.byKey(const Key('escolher-nova-setlist')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();
          // a página da setlist
          await tester.scrollUntilVisible(find.byKey(const Key('setlist-s1')), -200,
              scrollable: find.descendant(of: find.byKey(const Key('ouvir-lista')), matching: find.byType(Scrollable)).first);
          await tester.tap(find.byKey(const Key('setlist-s1')));
          await tester.pumpAndSettle();
          expect(find.byType(SetlistPage), findsOneWidget);
          expect(tester.takeException(), isNull);
          expect(m.ouvir.state.ativo, isTrue);
        });
      }
    }
  });
}
