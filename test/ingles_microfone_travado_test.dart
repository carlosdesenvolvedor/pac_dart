// O microfone NUNCA pode ficar preso em "Ouvindo…" (relato do dono no Chrome do iPhone: toca em "Parar" e o navegador
// nunca avisa que terminou, a tela não sai mais e não dá para digitar). O reconhecedor falso aqui faz exatamente isso:
// aceita `parar()`/`cancelar()` e NUNCA dispara o fim.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/ingles/data/reconhecedor_fala.dart';
import 'package:pac_dart/features/ingles/domain/roteiro.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';

/// Um navegador teimoso: ouve, mas ignora o "parar" (nunca manda o fim).
class _RecTeimoso extends ReconhecedorFala {
  int iniciadas = 0, pararChamado = 0, cancelarChamado = 0;
  void Function(List<String>)? final_;
  void Function()? fim;

  @override
  bool get suportado => true;

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
}

class _Sessao implements SessaoFala {
  final _RecTeimoso rec;
  _Sessao(this.rec);
  @override
  void parar() => rec.pararChamado++;
  @override
  void cancelar() => rec.cancelarChamado++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => FraseView.carencia = Duration.zero);
  tearDown(() => FraseView.carencia = const Duration(milliseconds: 350));

  void celular(String descricao, Future<void> Function(WidgetTester tester) corpo) =>
      testWidgets(descricao, corpo, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  Future<({_RecTeimoso rec, List<bool> mic, TypingBloc bloc})> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bloc = TypingBloc()..add(const TrechoCarregado('Good morning, Mike!', tolerante: true));
    addTearDown(bloc.close);
    final rec = _RecTeimoso();
    final mic = <bool>[];
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: Scaffold(
        body: BlocProvider.value(
          value: bloc,
          child: SingleChildScrollView(
            child: FraseView(modo: ModoFrase.memoria, reconhecedor: rec, onAvancar: () {}, onMicrofone: mic.add),
          ),
        ),
      ),
    ));
    await tester.pump();
    return (rec: rec, mic: mic, bloc: bloc);
  }

  final falar = find.text('Falar a frase');
  final parar = find.text('Parar');
  final ouvindo = find.text('Ouvindo… diga a frase em inglês');
  final aviso = find.textContaining('O microfone não respondeu');

  celular('toca em Falar: aparece "Ouvindo…" e o botão vira "Parar"', (tester) async {
    final m = await montar(tester);
    await tester.tap(falar);
    await tester.pump();
    expect(m.rec.iniciadas, 1);
    expect(ouvindo, findsOneWidget);
    expect(parar, findsOneWidget);
    expect(m.mic, [true]);
  });

  celular('"Parar" e o navegador NÃO avisa o fim: depois de 2 s o microfone é solto à força e a tela avisa', (tester) async {
    final m = await montar(tester);
    await tester.tap(falar);
    await tester.pump();
    await tester.tap(parar);
    await tester.pump();
    expect(m.rec.pararChamado, 1);
    expect(ouvindo, findsOneWidget, reason: 'espera um pouco o navegador responder');
    await tester.pump(const Duration(milliseconds: 1900));
    expect(ouvindo, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(ouvindo, findsNothing, reason: 'passou a espera: solta o microfone');
    expect(falar, findsOneWidget);
    expect(parar, findsNothing);
    expect(m.rec.cancelarChamado, 1);
    expect(m.mic, [true, false]);
    expect(aviso, findsOneWidget);
  });

  celular('2º toque em "Parar": solta na hora, sem esperar os 2 s', (tester) async {
    final m = await montar(tester);
    await tester.tap(falar);
    await tester.pump();
    await tester.tap(parar);
    await tester.pump();
    await tester.tap(parar);
    await tester.pump();
    expect(ouvindo, findsNothing);
    expect(falar, findsOneWidget);
    expect(m.rec.cancelarChamado, 1);
    expect(aviso, findsOneWidget);
    // e passado o tempo nada acontece de novo (o temporizador foi cancelado)
    await tester.pump(const Duration(seconds: 5));
    expect(m.rec.cancelarChamado, 1);
    expect(m.mic, [true, false]);
  });

  celular('depois de solto dá para tentar de novo (Falar abre outra escuta)', (tester) async {
    final m = await montar(tester);
    await tester.tap(falar);
    await tester.pump();
    await tester.tap(parar);
    await tester.pump();
    await tester.tap(parar);
    await tester.pump();
    await tester.tap(falar);
    await tester.pump();
    expect(m.rec.iniciadas, 2);
    expect(ouvindo, findsOneWidget);
    expect(aviso, findsNothing, reason: 'o recado antigo sai quando começa outra escuta');
  });

  celular('navegador que responde ao "parar" a tempo: entrega o que ouviu e NÃO solta à força nem avisa', (tester) async {
    final m = await montar(tester);
    await tester.tap(falar);
    await tester.pump();
    await tester.tap(parar);
    await tester.pump(const Duration(milliseconds: 500));
    m.rec.final_!(['Good morning Mike']);
    m.rec.fim!();
    await tester.pump();
    expect(m.bloc.state.concluido, isTrue, reason: 'frase certa falada vale como digitada');
    expect(ouvindo, findsNothing);
    expect(m.rec.cancelarChamado, 0);
    await tester.pump(const Duration(seconds: 5)); // o temporizador de 2 s não pode mais disparar
    expect(m.rec.cancelarChamado, 0);
    expect(aviso, findsNothing);
    expect(m.mic, [true, false]);
  });

  celular('tocar na frase ("quero digitar") fecha o microfone na hora', (tester) async {
    final m = await montar(tester);
    await tester.tap(falar);
    await tester.pump();
    expect(ouvindo, findsOneWidget);
    // um toque no canto da frase (longe do botão do microfone)
    await tester.tapAt(tester.getTopLeft(find.byType(FraseView)) + const Offset(40, 20));
    await tester.pump();
    expect(ouvindo, findsNothing);
    expect(falar, findsOneWidget);
    expect(m.rec.cancelarChamado, 1);
    expect(m.mic, [true, false]);
  });

  celular('sair da tela com o microfone aberto e preso não deixa temporizador pendurado', (tester) async {
    final m = await montar(tester);
    await tester.tap(falar);
    await tester.pump();
    await tester.tap(parar);
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 5));
    expect(m.rec.cancelarChamado, 1);
    expect(tester.takeException(), isNull);
  });
}
