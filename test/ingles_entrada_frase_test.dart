// A FraseView com os três jeitos de responder (Fase 7): ⌨️ Digitar · 🎤 Falar · 🧩 Montar.
// Digitar (o padrão) é o de sempre; Falar e Montar terminam a frase sem teclas e NÃO abrem o teclado do celular.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/curso/presentation/widgets/pacman.dart';
import 'package:pac_dart/features/ingles/data/reconhecedor_fala.dart';
import 'package:pac_dart/features/ingles/domain/entrada_resposta.dart';
import 'package:pac_dart/features/ingles/domain/roteiro.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/montagem_frase.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/seletor_entrada.dart';

const _frase = 'Good morning, Mike!';
const _apoio = ['Open the door now', 'The dog runs fast'];

class _Rec extends ReconhecedorFala {
  final bool _suportado;
  _Rec({bool suportado = true}) : _suportado = suportado;
  int iniciadas = 0, cancelarChamado = 0;
  void Function(List<String>)? final_;
  void Function()? fim;

  @override
  bool get suportado => _suportado;

  @override
  SessaoFala ouvir({
    String idioma = 'en-US',
    required void Function(String texto) aoParcial,
    required void Function(List<String> hipoteses) aoFinal,
    required void Function(ErroFala erro) aoErro,
    required void Function() aoFim,
  }) {
    iniciadas++;
    final_ = aoFinal;
    fim = aoFim;
    return _Sessao(this);
  }

  void terminar(List<String> hipoteses) {
    final_?.call(hipoteses);
    fim?.call();
  }
}

class _Sessao implements SessaoFala {
  final _Rec rec;
  _Sessao(this.rec);
  @override
  void parar() {}
  @override
  void cancelar() => rec.cancelarChamado++;
}

class _Tela {
  final TypingBloc bloc;
  final _Rec rec;
  final List<bool> mic;
  final List<EntradaResposta> mudou;
  final List<String> canal; // chamadas ao teclado virtual (TextInput.*)
  final FocusNode foco;
  _Tela(this.bloc, this.rec, this.mic, this.mudou, this.canal, this.foco);
  int get abriuTeclado => canal.where((c) => c == 'TextInput.show').length;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => FraseView.carencia = Duration.zero);
  tearDown(() => FraseView.carencia = const Duration(milliseconds: 350));

  void celular(String d, Future<void> Function(WidgetTester t) corpo) =>
      testWidgets(d, corpo, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  void computador(String d, Future<void> Function(WidgetTester t) corpo) =>
      testWidgets(d, corpo, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  /// Constrói a FraseView; [reconstruir] devolve a função que a refaz com outros parâmetros (troca de modo).
  Future<(_Tela, Future<void> Function({EntradaResposta? entrada, int? passo, bool? vitoria, String? frase}))> abrir(
    WidgetTester tester, {
    EntradaResposta entrada = EntradaResposta.digitar,
    ModoFrase modo = ModoFrase.memoria,
    bool seletor = true,
    bool vozSuportada = true,
    Size tamanho = const Size(400, 900),
    double fonte = 1,
    bool carregarAntes = true,
  }) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final canal = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (call) async {
      canal.add(call.method);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, null));
    final bloc = TypingBloc();
    if (carregarAntes) bloc.add(const TrechoCarregado(_frase, tolerante: true));
    addTearDown(() => tester.runAsync(bloc.close));
    final rec = _Rec(suportado: vozSuportada);
    final mic = <bool>[];
    final mudou = <EntradaResposta>[];
    final foco = FocusNode();
    addTearDown(foco.dispose);
    var atual = entrada;
    var passoAtual = 0;
    var vitoriaAtual = false;

    Future<void> monta() => tester.pumpWidget(MaterialApp(
          theme: Mixart.tema(),
          builder: (context, filho) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(fonte)), child: filho!),
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: SingleChildScrollView(
                child: FraseView(
                  modo: modo,
                  passo: passoAtual,
                  focusNode: foco,
                  reconhecedor: rec,
                  entrada: atual,
                  vitoria: vitoriaAtual,
                  onMudarEntrada: seletor ? mudou.add : null,
                  apoioMontagem: _apoio,
                  onAvancar: () {},
                  onMicrofone: mic.add,
                ),
              ),
            ),
          ),
        ));
    await monta();
    await tester.pump();
    Future<void> reconstruir({EntradaResposta? entrada, int? passo, bool? vitoria, String? frase}) async {
      if (entrada != null) atual = entrada;
      if (passo != null) passoAtual = passo;
      if (vitoria != null) vitoriaAtual = vitoria;
      if (frase != null) bloc.add(TrechoCarregado(frase, tolerante: true));
      await monta();
      await tester.pump();
      await tester.pump();
    }

    return (_Tela(bloc, rec, mic, mudou, canal, foco), reconstruir);
  }

  FraseViewState fv(WidgetTester t) => t.state<FraseViewState>(find.byType(FraseView));
  MontagemFraseState montagem(WidgetTester t) => t.state<MontagemFraseState>(find.byType(MontagemFrase));

  Future<void> tocarBloco(WidgetTester t, String texto) async {
    final id = montagem(t).blocos.firstWhere((b) => !b.distrator && b.texto == texto).id;
    final f = find.byKey(Key('bloco-$id'));
    await t.ensureVisible(f);
    await t.pump();
    await t.tap(f);
    await t.pump();
  }

  Future<void> montarFrase(WidgetTester t, [List<String> palavras = const ['Good', 'morning', 'Mike']]) async {
    for (final p in palavras) {
      await tocarBloco(t, p);
    }
  }

  final conferir = find.byKey(const Key('montagem-conferir'));
  final falar = find.text('Falar a frase');
  final teclado = find.byKey(const Key('abrir-teclado'));

  group('Digitar (o padrão): tudo como sempre', () {
    celular('sem a barra de modos (quem não passa onMudarEntrada nada vê de novo), mic como antes e o Teclado visível', (t) async {
      final (tela, _) = await abrir(t, seletor: false);
      expect(find.byType(SeletorEntrada), findsNothing);
      expect(find.byType(MontagemFrase), findsNothing);
      expect(falar, findsOneWidget);
      expect(teclado, findsOneWidget);
      expect(fv(t).entradaAtiva, EntradaResposta.digitar);
      expect(tela.bloc.state.idx, 0);
    });

    celular('o botão Teclado abre o teclado do celular (sem precisar adivinhar tocar na frase)', (t) async {
      final (tela, _) = await abrir(t);
      final antes = tela.abriuTeclado;
      await t.tap(teclado);
      await t.pump();
      expect(tela.foco.hasFocus, isTrue);
      expect(tela.abriuTeclado, greaterThan(antes));
    });

    computador('no computador não há botão Teclado nem painel de voz: nada mudou', (t) async {
      await abrir(t, seletor: false);
      expect(teclado, findsNothing);
      expect(falar, findsNothing);
      expect(find.byType(Pacman), findsOneWidget);
    });

    computador('digitar continua digitando (a letra certa avança o cursor)', (t) async {
      final (tela, _) = await abrir(t);
      await t.enterText(find.byType(TextField), 'G');
      await t.pump();
      expect(tela.bloc.state.idx, 1);
    });
  });

  group('a barra de modos', () {
    celular('aparece com as 3 pílulas', (t) async {
      await abrir(t);
      expect(find.byType(SeletorEntrada), findsOneWidget);
      for (final e in EntradaResposta.values) {
        expect(find.byKey(Key('entrada-${e.id}')), findsOneWidget);
      }
    });

    celular('sem reconhecimento de voz no aparelho o Falar some da barra', (t) async {
      await abrir(t, vozSuportada: false);
      expect(find.byKey(const Key('entrada-falar')), findsNothing);
      expect(find.byKey(const Key('entrada-digitar')), findsOneWidget);
      expect(find.byKey(const Key('entrada-montar')), findsOneWidget);
    });

    celular('tocar numa pílula avisa o modo escolhido', (t) async {
      final (tela, _) = await abrir(t);
      await t.tap(find.byKey(const Key('entrada-montar')));
      await t.tap(find.byKey(const Key('entrada-falar')));
      expect(tela.mudou, [EntradaResposta.montar, EntradaResposta.falar]);
    });

    celular('escolha de Falar num aparelho SEM voz vale Digitar (a barra mostra Digitar e o teclado segue possível)', (t) async {
      await abrir(t, entrada: EntradaResposta.falar, vozSuportada: false);
      expect(fv(t).entradaAtiva, EntradaResposta.digitar);
      expect(teclado, findsOneWidget);
      expect(find.byType(MontagemFrase), findsNothing);
    });

    celular('durante a vitória a barra some', (t) async {
      final (_, reconstruir) = await abrir(t);
      await reconstruir(vitoria: true);
      expect(find.byType(SeletorEntrada), findsNothing);
    });
  });

  group('🎤 Falar', () {
    celular('painel do microfone em destaque, sem botão Teclado, sem cursor, e tocar na moldura NÃO abre o teclado', (t) async {
      final (tela, _) = await abrir(t, entrada: EntradaResposta.falar);
      expect(falar, findsOneWidget);
      expect(teclado, findsNothing);
      expect(find.textContaining('Toque em “Falar a frase”'), findsOneWidget);
      expect(find.byType(Pacman), findsNothing);
      expect(tela.foco.hasFocus, isFalse, reason: 'Falar não pede o foco do campo (abriria o teclado)');
      await t.tapAt(t.getTopLeft(find.byType(FraseView)) + const Offset(60, 70));
      await t.pump();
      expect(tela.foco.hasFocus, isFalse);
      expect(tela.abriuTeclado, 0);
    });

    celular('falar a frase certa conclui como digitada e o cursor volta para comemorar', (t) async {
      final (tela, _) = await abrir(t, entrada: EntradaResposta.falar);
      await t.tap(falar);
      await t.pump();
      expect(tela.rec.iniciadas, 1);
      expect(tela.foco.hasFocus, isFalse, reason: 'abrir o microfone em Falar não pede o teclado');
      tela.rec.terminar(['good morning mike']);
      await t.pump();
      expect(tela.bloc.state.concluido, isTrue);
      expect(fv(t).errosDeFala, isEmpty);
      expect(find.byType(Pacman), findsOneWidget);
      expect(tela.abriuTeclado, 0);
    });

    celular('palavra errada na fala soma erro por posição (como sempre)', (t) async {
      final (tela, _) = await abrir(t, entrada: EntradaResposta.falar);
      await t.tap(falar);
      await t.pump();
      tela.rec.terminar(['good evening mike']);
      await t.pump();
      expect(tela.bloc.state.concluido, isFalse);
      expect(fv(t).errosDeFala, {5: 1}); // "morning" começa na posição 5
    });

    computador('no computador o painel do microfone também aparece em Falar', (t) async {
      await abrir(t, entrada: EntradaResposta.falar);
      expect(falar, findsOneWidget);
      expect(teclado, findsNothing);
    });

    celular('Falar não aceita letras digitadas (o teclado nem abre; texto que chegar é ignorado)', (t) async {
      final (tela, _) = await abrir(t, entrada: EntradaResposta.falar);
      await t.enterText(find.byType(TextField), 'Good');
      await t.pump();
      expect(tela.bloc.state.idx, 0);
    });
  });

  group('🧩 Montar', () {
    celular('mostra os blocos no lugar do teclado e do microfone, sem cursor, e não abre o teclado', (t) async {
      final (tela, _) = await abrir(t, entrada: EntradaResposta.montar);
      expect(find.byType(MontagemFrase), findsOneWidget);
      expect(falar, findsNothing);
      expect(teclado, findsNothing);
      expect(find.byType(Pacman), findsNothing);
      expect(tela.foco.hasFocus, isFalse);
      await tocarBloco(t, 'Good');
      await t.tapAt(t.getTopLeft(find.byType(FraseView)) + const Offset(60, 70));
      await t.pump();
      expect(tela.foco.hasFocus, isFalse);
      expect(tela.abriuTeclado, 0);
      expect(tela.canal.where((c) => c == 'TextInput.setClient'), isEmpty, reason: 'nenhuma conexão de teclado foi aberta');
    });

    celular('montar certo conclui como digitado: sem erro, sem dica, o cursor comemora', (t) async {
      final (tela, _) = await abrir(t, entrada: EntradaResposta.montar);
      await montarFrase(t);
      await t.ensureVisible(conferir);
      await t.pump();
      await t.tap(conferir);
      await t.pump();
      expect(tela.bloc.state.concluido, isTrue);
      expect(fv(t).errosDeFala, isEmpty);
      expect(fv(t).reveladas, isEmpty);
      expect(fv(t).desistiu, isFalse);
      expect(find.byType(Pacman), findsOneWidget);
      // os blocos ficam à mostra, verdes, até o próximo passo
      expect(find.byType(MontagemFrase), findsOneWidget);
      expect(conferir, findsNothing);
    });

    celular('montar errado soma 1 erro na posição da palavra a cada Conferir, sem revelar nada', (t) async {
      final (tela, _) = await abrir(t, entrada: EntradaResposta.montar);
      await montarFrase(t, ['Good', 'morning']); // faltou "Mike"
      for (var i = 0; i < 3; i++) {
        await t.ensureVisible(conferir);
        await t.pump();
        await t.tap(conferir);
        await t.pump();
      }
      expect(tela.bloc.state.concluido, isFalse);
      expect(fv(t).errosDeFala, {14: 3}); // "Mike" começa na posição 14
      expect(fv(t).reveladas, isEmpty);
    });

    celular('"não sei" (de memória) revela a frase, vira cópia e os blocos recomeçam; depois montar conclui', (t) async {
      final (tela, _) = await abrir(t, entrada: EntradaResposta.montar);
      await montarFrase(t, ['Good']);
      await t.ensureVisible(find.byKey(const Key('montagem-nao-sei')));
      await t.pump();
      await t.tap(find.byKey(const Key('montagem-nao-sei')));
      await t.pump();
      expect(fv(t).desistiu, isTrue);
      expect(fv(t).reveladas, isNotEmpty);
      expect(find.textContaining('Toque nos blocos abaixo'), findsOneWidget);
      await montarFrase(t);
      await t.ensureVisible(conferir);
      await t.pump();
      await t.tap(conferir);
      await t.pump();
      expect(tela.bloc.state.concluido, isTrue);
      expect(fv(t).desistiu, isTrue, reason: 'desistiu continua valendo: a nota será "errou"');
    });

    // montando, a frase fica coberta até na cópia: o "não sei" é o jeito de vê-la
    celular('na cópia a frase fica coberta e há "não sei"', (t) async {
      await abrir(t, entrada: EntradaResposta.montar, modo: ModoFrase.ver);
      expect(find.byKey(const Key('montagem-nao-sei')), findsOneWidget);
      expect(conferir, findsOneWidget);
    });

    computador('no computador: Enter confere, Esc é "não sei", Backspace e letras não digitam', (t) async {
      final (tela, _) = await abrir(t, entrada: EntradaResposta.montar);
      expect(tela.foco.hasFocus, isTrue, reason: 'no computador o foco segue valendo (teclas físicas)');
      await t.enterText(find.byType(TextField), 'Good');
      await t.pump();
      expect(tela.bloc.state.idx, 0, reason: 'montar não digita');
      await t.sendKeyEvent(LogicalKeyboardKey.backspace);
      await t.pump();
      expect(tela.bloc.state.idx, 0);
      await montarFrase(t);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(tela.bloc.state.concluido, isTrue);
    });

    computador('no computador: Esc revela a frase e recomeça os blocos', (t) async {
      await abrir(t, entrada: EntradaResposta.montar);
      await montarFrase(t, ['Good']);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      expect(fv(t).desistiu, isTrue);
      expect(find.textContaining('Toque nos blocos abaixo'), findsOneWidget);
    });

    celular('passo seguinte (frase nova): blocos novos e montagem zerada', (t) async {
      final (_, reconstruir) = await abrir(t, entrada: EntradaResposta.montar);
      await montarFrase(t, ['Good', 'morning']);
      await reconstruir(passo: 1, frase: 'We go home.');
      expect(find.textContaining('Toque nos blocos abaixo'), findsOneWidget);
      expect(montagem(t).blocos.where((b) => !b.distrator).map((b) => b.texto).toSet(), {'We', 'go', 'home'});
    });

    celular('a mesma frase repetida (cópia de correção) também recomeça limpa', (t) async {
      final (_, reconstruir) = await abrir(t, entrada: EntradaResposta.montar);
      await montarFrase(t, ['Good']);
      await reconstruir(passo: 1, frase: _frase);
      expect(find.textContaining('Toque nos blocos abaixo'), findsOneWidget);
    });
  });

  group('trocar de modo no meio do passo', () {
    celular('Digitar → Montar: o teclado fecha (foco sai) e os blocos aparecem', (t) async {
      final (tela, reconstruir) = await abrir(t);
      await t.tap(teclado);
      await t.pump();
      expect(tela.foco.hasFocus, isTrue);
      await reconstruir(entrada: EntradaResposta.montar);
      expect(tela.foco.hasFocus, isFalse);
      expect(find.byType(MontagemFrase), findsOneWidget);
      expect(teclado, findsNothing);
    });

    celular('a tela nasceu ANTES da frase carregar (como no palco): trocar para Montar mostra os blocos', (t) async {
      final (_, reconstruir) = await abrir(t, carregarAntes: false);
      await reconstruir(frase: _frase);
      await reconstruir(entrada: EntradaResposta.montar);
      expect(find.byType(MontagemFrase), findsOneWidget);
      expect(montagem(t).blocos.where((b) => !b.distrator).map((b) => b.texto).toSet(), {'Good', 'morning', 'Mike'});
      await reconstruir(entrada: EntradaResposta.falar);
      expect(find.byType(MontagemFrase), findsNothing);
      expect(falar, findsOneWidget);
      await reconstruir(entrada: EntradaResposta.digitar);
      expect(teclado, findsOneWidget);
      expect(falar, findsOneWidget);
    });

    celular('Montar → Digitar: o foco volta e o teclado abre', (t) async {
      final (tela, reconstruir) = await abrir(t, entrada: EntradaResposta.montar);
      expect(tela.abriuTeclado, 0);
      await reconstruir(entrada: EntradaResposta.digitar);
      expect(tela.foco.hasFocus, isTrue);
      expect(tela.abriuTeclado, greaterThan(0));
      expect(find.byType(MontagemFrase), findsNothing);
    });

    celular('Falar com o microfone aberto → Montar: o microfone é solto na hora', (t) async {
      final (tela, reconstruir) = await abrir(t, entrada: EntradaResposta.falar);
      await t.tap(falar);
      await t.pump();
      expect(fv(t).ouvindo, isTrue);
      await reconstruir(entrada: EntradaResposta.montar);
      expect(fv(t).ouvindo, isFalse);
      expect(tela.rec.cancelarChamado, 1);
      expect(tela.mic, [true, false]);
    });

    celular('o que já valeu fica: erros da montagem seguem depois de trocar para Falar', (t) async {
      final (_, reconstruir) = await abrir(t, entrada: EntradaResposta.montar);
      await montarFrase(t, ['Good', 'morning']);
      await t.ensureVisible(conferir);
      await t.pump();
      await t.tap(conferir);
      await t.pump();
      await reconstruir(entrada: EntradaResposta.falar);
      expect(fv(t).errosDeFala, {14: 1});
    });

    computador('no computador trocar de modo mantém o foco (teclas físicas)', (t) async {
      final (tela, reconstruir) = await abrir(t);
      await reconstruir(entrada: EntradaResposta.montar);
      expect(tela.foco.hasFocus, isTrue);
    });
  });

  group('sem estouro', () {
    for (final tamanho in const [Size(360, 740), Size(400, 900), Size(1027, 800)]) {
      for (final e in EntradaResposta.values) {
        testWidgets('${tamanho.width.toInt()} px · ${e.rotulo} · fonte grande · tema claro', (t) async {
          final antes = Mixart.atual;
          addTearDown(() => Mixart.atual = antes);
          Mixart.atual = Paleta.flutterClaro;
          await abrir(t, entrada: e, tamanho: tamanho, fonte: 1.4);
          expect(t.takeException(), isNull);
        }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
      }
    }
  });
}
