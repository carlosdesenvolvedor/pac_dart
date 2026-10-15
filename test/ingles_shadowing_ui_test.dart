import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/ingles/data/reconhecedor_fala.dart';
import 'package:pac_dart/features/ingles/domain/avaliacao_fala.dart';
import 'package:pac_dart/features/ingles/domain/shadowing.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/painel_shadowing.dart';

/// Uma escuta que o teste conduz à mão: `falou([...])` entrega as hipóteses e fecha, como o reconhecedor de verdade.
class EscutaFalsa implements SessaoFala {
  final void Function(String texto) aoParcial;
  final void Function(List<String> hipoteses) aoFinal;
  final void Function(ErroFala erro) aoErro;
  final void Function() aoFim;
  bool parada = false, cancelada = false;
  EscutaFalsa(this.aoParcial, this.aoFinal, this.aoErro, this.aoFim);

  @override
  void parar() => parada = true;
  @override
  void cancelar() => cancelada = true;

  void parcial(String t) => aoParcial(t);
  void falou(List<String> hipoteses) {
    aoFinal(hipoteses);
    aoFim();
  }

  void deuErro(ErroFala e) {
    aoErro(e);
    aoFim();
  }
}

class ReconhecedorFalso extends ReconhecedorFala {
  bool ok;
  ReconhecedorFalso({this.ok = true});
  final escutas = <EscutaFalsa>[];

  @override
  bool get suportado => ok;

  @override
  SessaoFala ouvir({
    String idioma = 'en-US',
    required void Function(String texto) aoParcial,
    required void Function(List<String> hipoteses) aoFinal,
    required void Function(ErroFala erro) aoErro,
    required void Function() aoFim,
  }) {
    final e = EscutaFalsa(aoParcial, aoFinal, aoErro, aoFim);
    escutas.add(e);
    return e;
  }
}

const frase = 'Nice to meet you, Mike.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  late ReconhecedorFalso rec;
  late List<AvaliacaoFala> tentativas;
  late List<bool> microfone;
  late int mostrou, semVoz;

  /// A tela do cartão guarda as tentativas e devolve a sessão ao painel: aqui um anfitrião faz o mesmo.
  Future<void> montar(WidgetTester tester, {Size tamanho = const Size(900, 900), bool mostrarPainel = true}) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tentativas = [];
    microfone = [];
    mostrou = 0;
    semVoz = 0;
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: mostrarPainel
                ? PainelShadowing(
                    key: const ValueKey('p'),
                    reconhecedor: rec,
                    frase: frase,
                    sessao: SessaoShadowing(tentativas),
                    onTentativa: (a) => setState(() => tentativas = [...tentativas, a]),
                    onMicrofone: microfone.add,
                    onMostrarFrase: () => mostrou++,
                    onSemVoz: () => semVoz++,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ));
  }

  Future<void> toca(WidgetTester tester, String chave) async {
    await tester.tap(find.byKey(Key(chave)));
    await tester.pump();
  }

  setUp(() => rec = ReconhecedorFalso());

  testWidgets('abre com o convite, as 3 tentativas e o aviso de privacidade; a frase NÃO aparece', (tester) async {
    await montar(tester);
    expect(find.byKey(const Key('shadowing-convite')), findsOneWidget);
    expect(find.text('🎤 Falar'), findsOneWidget);
    expect(find.textContaining('3 tentativas'), findsOneWidget);
    expect(find.textContaining('não o sotaque'), findsOneWidget);
    expect(find.byKey(const Key('shadowing-privacidade')), findsOneWidget);
    expect(find.textContaining('não grava sua voz'), findsOneWidget);
    expect(find.textContaining('Nice'), findsNothing);
    expect(rec.escutas, isEmpty, reason: 'o microfone só abre por um toque');
  });

  testWidgets('tocar em Falar abre o microfone, avisa a tela e mostra o que está sendo ouvido', (tester) async {
    await montar(tester);
    await toca(tester, 'shadowing-falar');
    expect(rec.escutas.length, 1);
    expect(microfone, [true]);
    expect(find.byKey(const Key('shadowing-ouvindo')), findsOneWidget);
    expect(find.text('⏹ Parar'), findsOneWidget);
    rec.escutas.single.parcial('nice to');
    await tester.pump();
    expect(find.text('🎤 nice to…'), findsOneWidget);
  });

  testWidgets('o botão "Mostrar a frase" fica desligado enquanto o microfone está aberto', (tester) async {
    await montar(tester);
    await toca(tester, 'shadowing-falar');
    await tester.tap(find.byKey(const Key('shadowing-mostrar')));
    await tester.pump();
    expect(mostrou, 0);
    rec.escutas.single.falou(['nice to meet you']);
    await tester.pump();
    await toca(tester, 'shadowing-mostrar');
    expect(mostrou, 1);
  });

  testWidgets('falou com palavra faltando: mostra o que ouviu (sem a frase), quantas faltaram e as tentativas que restam', (tester) async {
    await montar(tester);
    await toca(tester, 'shadowing-falar');
    rec.escutas.single.falou(['nice to meet you']);
    await tester.pump();
    expect(tentativas.length, 1);
    expect(microfone, [true, false]);
    expect(find.text('O QUE EU OUVI'), findsOneWidget);
    expect(find.byKey(const Key('shadowing-ouvido')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('shadowing-resultado'))).data, 'Faltaram 1 de 5 palavras.');
    expect(find.text('🎤 Tentar de novo'), findsOneWidget);
    expect(find.text('Restam 2 tentativas.'), findsOneWidget);
    expect(find.textContaining('Mike'), findsNothing, reason: 'a palavra que faltou não pode ser revelada antes de virar');
  });

  testWidgets('palavra a mais aparece no resumo; a trocada fica em vermelho e as certas em verde', (tester) async {
    await montar(tester);
    await toca(tester, 'shadowing-falar');
    rec.escutas.single.falou(['well nice to meet you mark']);
    await tester.pump();
    final texto = tester.widget<Text>(find.byKey(const Key('shadowing-ouvido'))).textSpan! as TextSpan;
    final cores = {for (final s in texto.children!.cast<TextSpan>().where((s) => s.text!.trim().isNotEmpty)) s.text!: s.style!.color};
    expect(cores['nice'], const Color(0xFF4CD08A));
    expect(cores['well'], Mixart.danger);
    expect(cores['mark'], Mixart.danger);
    expect(tester.widget<Text>(find.byKey(const Key('shadowing-resultado'))).data, contains('sobraram 2 palavras'));
  });

  testWidgets('frase perfeita: "Saiu a frase inteira!"', (tester) async {
    await montar(tester);
    await toca(tester, 'shadowing-falar');
    rec.escutas.single.falou(['nice to meet you mike']);
    await tester.pump();
    expect(find.text('Saiu a frase inteira! ✅'), findsOneWidget);
    expect(tentativas.single.perfeita, isTrue);
  });

  testWidgets('"não entendi nenhuma palavra" NÃO é tentativa: só pede de novo', (tester) async {
    await montar(tester);
    await toca(tester, 'shadowing-falar');
    rec.escutas.single.falou(['']);
    await tester.pump();
    expect(tentativas, isEmpty);
    expect(find.byKey(const Key('shadowing-recado')), findsOneWidget);
    expect(find.textContaining('Não entendi nenhuma palavra'), findsOneWidget);
    expect(find.text('🎤 Falar'), findsOneWidget, reason: 'continua na 1ª tentativa');
    expect(find.textContaining('3 tentativas'), findsOneWidget);
  });

  testWidgets('erro que dá para repetir (não ouviu, sem rede, outro): recado e o painel segue', (tester) async {
    for (final e in [ErroFala.naoOuviu, ErroFala.semRede, ErroFala.outro]) {
      rec = ReconhecedorFalso();
      await montar(tester);
      await toca(tester, 'shadowing-falar');
      rec.escutas.single.deuErro(e);
      await tester.pump();
      expect(find.text(PainelShadowingState.textoDoErro(e)), findsOneWidget, reason: '$e');
      expect(semVoz, 0, reason: '$e');
      expect(find.text('🎤 Falar'), findsOneWidget);
    }
  });

  testWidgets('erro sem saída (permissão, sem microfone, sem suporte): avisa a tela para virar ditado', (tester) async {
    for (final e in [ErroFala.semPermissao, ErroFala.semMicrofone, ErroFala.naoSuportado]) {
      rec = ReconhecedorFalso();
      await montar(tester);
      await toca(tester, 'shadowing-falar');
      rec.escutas.single.deuErro(e);
      await tester.pump();
      expect(semVoz, 1, reason: '$e');
    }
    expect(PainelShadowingState.semSaida(ErroFala.semRede), isFalse);
    expect(PainelShadowingState.semSaida(ErroFala.naoOuviu), isFalse);
  });

  testWidgets('reconhecedor sem suporte: tocar em Falar avisa a tela (e não abre microfone)', (tester) async {
    rec = ReconhecedorFalso(ok: false);
    await montar(tester);
    await toca(tester, 'shadowing-falar');
    expect(semVoz, 1);
    expect(rec.escutas, isEmpty);
    expect(microfone, isEmpty);
  });

  testWidgets('tocar de novo enquanto ouve PARA a escuta (não abre outra)', (tester) async {
    await montar(tester);
    await toca(tester, 'shadowing-falar');
    await toca(tester, 'shadowing-falar');
    expect(rec.escutas.length, 1);
    expect(rec.escutas.single.parada, isTrue);
    expect(rec.escutas.single.cancelada, isFalse);
  });

  testWidgets('"Parar" e o navegador NÃO avisa o fim (Chrome do iPhone): em 2 s o microfone é solto à força e dá para tentar de novo', (tester) async {
    await montar(tester);
    await toca(tester, 'shadowing-falar');
    expect(find.text('⏹ Parar'), findsOneWidget);
    await toca(tester, 'shadowing-falar'); // Parar: o falso ignora e nunca manda o fim
    expect(rec.escutas.single.parada, isTrue);
    expect(find.byKey(const Key('shadowing-ouvindo')), findsOneWidget, reason: 'espera um pouco o navegador responder');
    await tester.pump(const Duration(milliseconds: 2100));
    expect(find.byKey(const Key('shadowing-ouvindo')), findsNothing);
    expect(rec.escutas.single.cancelada, isTrue);
    expect(microfone, [true, false]);
    expect(find.textContaining('O microfone não respondeu'), findsOneWidget);
    expect(find.text('🎤 Falar'), findsOneWidget);
    expect(tentativas, isEmpty, reason: 'solto à força não vira tentativa');
    // tenta de novo
    await toca(tester, 'shadowing-falar');
    expect(rec.escutas.length, 2);
    expect(find.textContaining('O microfone não respondeu'), findsNothing);
  });

  testWidgets('2º toque em "Parar" solta na hora (sem esperar os 2 s) e o temporizador não dispara depois', (tester) async {
    await montar(tester);
    await toca(tester, 'shadowing-falar');
    await toca(tester, 'shadowing-falar');
    await toca(tester, 'shadowing-falar');
    expect(find.byKey(const Key('shadowing-ouvindo')), findsNothing);
    expect(rec.escutas.single.cancelada, isTrue);
    await tester.pump(const Duration(seconds: 5));
    expect(microfone, [true, false]);
  });

  testWidgets('navegador que responde ao "parar" a tempo: confere normalmente e não solta à força', (tester) async {
    await montar(tester);
    await toca(tester, 'shadowing-falar');
    await toca(tester, 'shadowing-falar');
    await tester.pump(const Duration(milliseconds: 400));
    rec.escutas.single.falou(['nice to meet you mike']);
    await tester.pump();
    expect(tentativas.length, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(rec.escutas.single.cancelada, isFalse);
    expect(find.textContaining('O microfone não respondeu'), findsNothing);
  });

  testWidgets('o aviso de uma escuta VELHA (depois de outra começar) é ignorado', (tester) async {
    await montar(tester);
    await toca(tester, 'shadowing-falar');
    final velha = rec.escutas.single;
    velha.aoFim();
    await tester.pump();
    await toca(tester, 'shadowing-falar');
    expect(rec.escutas.length, 2);
    velha.aoFinal(['nice to meet you mike']); // chegou tarde: não vale
    velha.aoParcial('blá');
    velha.aoFim(); // nem fecha o microfone da escuta nova
    await tester.pump();
    expect(tentativas, isEmpty);
    expect(find.byKey(const Key('shadowing-ouvindo')), findsOneWidget);
    expect(microfone, [true, false, true]);
  });

  testWidgets('sair da tela com o microfone aberto: cancela e avisa que fechou', (tester) async {
    await montar(tester);
    await toca(tester, 'shadowing-falar');
    expect(microfone, [true]);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(rec.escutas.single.cancelada, isTrue);
    expect(microfone, [true, false]);
  });

  testWidgets('depois de encerrar (3 tentativas) o Falar não abre mais o microfone', (tester) async {
    await montar(tester);
    for (var i = 0; i < 3; i++) {
      await toca(tester, 'shadowing-falar');
      rec.escutas.last.falou(['nice to meet']);
      await tester.pump();
    }
    expect(tentativas.length, 3);
    final antes = rec.escutas.length;
    (tester.state(find.byKey(const ValueKey('p'))) as PainelShadowingState).alternar();
    expect(rec.escutas.length, antes);
  });

  testWidgets('"Espaço" (alternar) abre e para o microfone pelo estado', (tester) async {
    await montar(tester);
    final estado = tester.state(find.byKey(const ValueKey('p'))) as PainelShadowingState;
    estado.alternar();
    await tester.pump();
    expect(rec.escutas.length, 1);
    estado.alternar();
    expect(rec.escutas.single.parada, isTrue);
  });

  for (final tamanho in const [Size(360, 740), Size(390, 844), Size(1027, 800)]) {
    testWidgets('sem estouro em ${tamanho.width.toInt()} px (resultado na tela, tema claro)', (tester) async {
      final antes = Mixart.atual;
      addTearDown(() => Mixart.atual = antes);
      Mixart.atual = Paleta.flutterClaro;
      await montar(tester, tamanho: tamanho);
      await toca(tester, 'shadowing-falar');
      rec.escutas.single.falou(['well nice to meet you mark and more words']);
      await tester.pump();
      expect(find.byKey(const Key('shadowing-resultado')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
