import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/data/preferencias_ouvir.dart';
import 'package:pac_dart/features/ingles/data/sessao_midia.dart';
import 'package:pac_dart/features/ingles/domain/config_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';

/// Saída falsa: cada fala/silêncio fica pendente até o teste terminar ([fim]); [parar] corta a pendente
/// com `cortada` (como a de verdade).
class _Saida implements SaidaDeAudio {
  final chamadas = <String>[];
  final _pendentes = <Completer<FimDaFala>>[];
  final preaquecidas = <String>[];
  int paradas = 0;

  Future<FimDaFala> _nova(String c) {
    chamadas.add(c);
    final x = Completer<FimDaFala>();
    _pendentes.add(x);
    return x.future;
  }

  @override
  Future<FimDaFala> en(String texto, {required double fator}) => _nova('en:$texto@$fator');

  @override
  Future<FimDaFala> pt(String texto, {required double fator}) => _nova('pt:$texto');

  @override
  Future<FimDaFala> silencio(Duration d) => _nova('sil:${d.inMilliseconds}');

  @override
  void parar() {
    paradas++;
    for (final p in _pendentes) {
      if (!p.isCompleted) p.complete(FimDaFala.cortada);
    }
    _pendentes.clear();
  }

  @override
  void preaquecer(String texto) => preaquecidas.add(texto);

  @override
  bool get somLiberado => true;

  @override
  double duracaoDe(String en) => 2;

  @override
  bool temGravacao(String en) => true;

  bool get temPendente => _pendentes.any((p) => !p.isCompleted);

  void terminar(FimDaFala r) {
    final p = _pendentes.removeLast();
    p.complete(r);
  }

  String get ultima => chamadas.last;
}

class _Midia implements SessaoMidia, SessaoMidiaComRepetir {
  final metadados = <(String, String, String, bool)>[];
  VoidCallback? play, pause, proxima, anterior, parar, repetir;
  int limpezas = 0;

  @override
  void atualizar({required String titulo, required String artista, required String album, required bool tocando}) =>
      metadados.add((titulo, artista, album, tocando));

  @override
  void acoes({
    required VoidCallback play,
    required VoidCallback pause,
    required VoidCallback proxima,
    required VoidCallback anterior,
    required VoidCallback parar,
  }) {
    this.play = play;
    this.pause = pause;
    this.proxima = proxima;
    this.anterior = anterior;
    this.parar = parar;
  }

  @override
  void aoRepetir(VoidCallback repetir) => this.repetir = repetir;

  @override
  void limpar() => limpezas++;

  @override
  bool get oculta => false;
}

Faixa _fx(String chave, String licao, {bool primeira = false, String pt = ''}) => Faixa(
      chave: chave,
      en: '$chave.',
      pt: pt,
      quem: 'mike',
      licaoId: licao,
      licaoNome: 'Lição $licao',
      primeiraDaLicao: primeira,
      segundos: 2,
    );

/// Duas lições: l1 = a1 a2 a3, l2 = b1 b2.
final _fila = [
  _fx('a1', 'l1', primeira: true, pt: 'Um.'),
  _fx('a2', 'l1', pt: 'Dois.'),
  _fx('a3', 'l1', pt: 'Três.'),
  _fx('b1', 'l2', primeira: true, pt: 'Quatro.'),
  _fx('b2', 'l2', pt: 'Cinco.'),
];

const _curso = FonteOuvir('curso', 'Curso na ordem');

void main() {
  late _Saida saida;
  late _Midia midia;
  late PreferenciasOuvirMemoria prefs;
  late DateTime relogio;
  late List<Completer<void>> vigias;
  late List<Duration> limites;
  late OuvirCubit cubit;

  OuvirCubit novo({ConfigOuvir config = const ConfigOuvir()}) {
    prefs = PreferenciasOuvirMemoria(config: config);
    return OuvirCubit(
      saida: saida,
      prefs: prefs,
      midia: midia,
      agora: () => relogio,
      esperar: (d) {
        limites.add(d);
        final c = Completer<void>();
        vigias.add(c);
        return c.future;
      },
    );
  }

  setUp(() {
    saida = _Saida();
    midia = _Midia();
    relogio = DateTime(2026, 10, 20, 8);
    vigias = [];
    limites = [];
    cubit = novo();
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  /// Termina o passo pendente depois de [dt] (fala "de verdade" leva tempo; < 150 ms = instantânea).
  Future<void> passo([FimDaFala r = FimDaFala.acabou, Duration dt = const Duration(seconds: 1)]) async {
    relogio = relogio.add(dt);
    saida.terminar(r);
    await pumpEventQueue();
  }

  /// Toca a frase inteira no modo padrão (fala + pausa).
  Future<void> frase() async {
    await passo();
    await passo();
  }

  Future<void> comecar([int inicio = 0]) async {
    await cubit.tocar(_curso, _fila, inicio: inicio);
    await pumpEventQueue();
  }

  test('toca em ordem: fala, pausa, próxima frase; conta as ouvidas e pré-aquece as próximas', () async {
    await comecar();
    expect(cubit.state.status, StatusOuvir.tocando);
    expect(cubit.state.fase, FaseOuvir.ouvindo);
    expect(saida.ultima, 'en:a1.@1.0');
    expect(saida.preaquecidas, ['a2.', 'a3.']);
    await passo();
    expect(saida.ultima, 'sil:1000');
    expect(cubit.state.fase, FaseOuvir.respiro);
    await passo();
    expect(cubit.state.indice, 1);
    expect(cubit.state.ouvidas, 1);
    expect(saida.ultima, 'en:a2.@1.0');
    expect(limites.first, const Duration(seconds: 8), reason: 'vigia = 2 s × 2,5 + 3 s');
    await frase();
    await frase();
    expect(saida.chamadas.where((c) => c.startsWith('en:')).toList(), ['en:a1.@1.0', 'en:a2.@1.0', 'en:a3.@1.0', 'en:b1.@1.0']);
  });

  test('pausar e continuar recomeça a frase do início; o corte da própria pausa não vira "outra fala"', () async {
    await comecar();
    await frase();
    await passo(); // a2 falou; agora está na pausa
    expect(saida.ultima, 'sil:1000');
    cubit.pausar();
    await pumpEventQueue();
    expect(cubit.state.status, StatusOuvir.pausado);
    expect(cubit.state.motivo, MotivoPausa.usuario);
    expect(saida.paradas, greaterThan(0));
    expect(saida.temPendente, isFalse);
    expect(prefs.posicoes['curso'], (i: 1, chave: 'a2'), reason: 'salva na pausa');

    await cubit.continuar();
    await pumpEventQueue();
    expect(cubit.state.status, StatusOuvir.tocando);
    expect(cubit.state.motivo, isNull);
    expect(cubit.state.indice, 1);
    expect(saida.ultima, 'en:a2.@1.0');

    cubit.alternar();
    await pumpEventQueue();
    expect(cubit.state.status, StatusOuvir.pausado);
    cubit.alternar();
    await pumpEventQueue();
    expect(cubit.state.status, StatusOuvir.tocando);
  });

  test('próxima, anterior (regra de 1,5 s), próxima lição e lição anterior', () async {
    await comecar();
    cubit.proxima();
    await pumpEventQueue();
    expect(cubit.state.indice, 1);
    expect(saida.ultima, 'en:a2.@1.0');

    // logo no começo da frase: volta para a anterior
    relogio = relogio.add(const Duration(milliseconds: 500));
    cubit.anterior();
    await pumpEventQueue();
    expect(cubit.state.indice, 0);

    // depois de 1,5 s: recomeça a atual
    cubit.proxima();
    await pumpEventQueue();
    relogio = relogio.add(const Duration(seconds: 2));
    cubit.anterior();
    await pumpEventQueue();
    expect(cubit.state.indice, 1);
    expect(saida.ultima, 'en:a2.@1.0');

    cubit.proximaLicao();
    await pumpEventQueue();
    expect(cubit.state.indice, 3);
    cubit.proxima();
    await pumpEventQueue();
    relogio = relogio.add(const Duration(seconds: 3));
    cubit.licaoAnterior(); // no meio da l2: volta ao começo dela
    await pumpEventQueue();
    expect(cubit.state.indice, 3);
    cubit.licaoAnterior(); // logo na 1ª frase da l2: vai para a l1
    await pumpEventQueue();
    expect(cubit.state.indice, 0);

    cubit.repetirAtual();
    await pumpEventQueue();
    expect(cubit.state.indice, 0);
    cubit.irPara(4);
    await pumpEventQueue();
    expect(cubit.state.indice, 4);
    cubit.proximaLicao(); // não há outra: acabou
    await pumpEventQueue();
    expect(cubit.state.status, StatusOuvir.acabou);
  });

  test('pular enquanto pausado volta a tocar', () async {
    await comecar();
    cubit.pausar();
    cubit.proxima();
    await pumpEventQueue();
    expect(cubit.state.status, StatusOuvir.tocando);
    expect(cubit.state.indice, 1);
  });

  test('cortada (outra fala do app) = pausado/outraFala, não avança e não volta sozinho', () async {
    await comecar();
    await frase();
    await passo(FimDaFala.cortada);
    expect(cubit.state.status, StatusOuvir.pausado);
    expect(cubit.state.motivo, MotivoPausa.outraFala);
    expect(cubit.state.indice, 1);
    final n = saida.chamadas.length;
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(saida.chamadas.length, n, reason: 'nunca retoma sozinho');
    expect(midia.metadados.last.$4, isFalse);

    await cubit.continuar();
    await pumpEventQueue();
    expect(saida.ultima, 'en:a2.@1.0');
  });

  test('cortada no meio de uma pausa também pausa', () async {
    await comecar();
    await passo();
    await passo(FimDaFala.cortada); // a pausa (silêncio no <audio>) foi cortada
    expect(cubit.state.motivo, MotivoPausa.outraFala);
    expect(cubit.state.indice, 0);
  });

  test('3 falas instantâneas seguidas = semSom, de volta à frase onde começou', () async {
    await comecar();
    await frase(); // a1 normal
    await passo(FimDaFala.acabou, Duration.zero); // a2 instantânea
    await passo();
    await passo(FimDaFala.acabou, const Duration(milliseconds: 100)); // a3 instantânea
    await passo();
    expect(cubit.state.status, StatusOuvir.tocando);
    await passo(FimDaFala.acabou, Duration.zero); // b1 instantânea: a 3ª
    expect(cubit.state.status, StatusOuvir.pausado);
    expect(cubit.state.motivo, MotivoPausa.semSom);
    expect(cubit.state.indice, 1, reason: 'volta para a 1ª que não soou');
  });

  test('uma fala normal no meio zera a contagem de instantâneas', () async {
    await comecar();
    await passo(FimDaFala.acabou, Duration.zero);
    await passo();
    await passo(FimDaFala.acabou, Duration.zero);
    await passo();
    await frase(); // a3 normal
    await passo(FimDaFala.acabou, Duration.zero);
    expect(cubit.state.status, StatusOuvir.tocando);
  });

  test('o vigia pula a frase travada (e cala a saída)', () async {
    await comecar();
    final paradas = saida.paradas;
    vigias.last.complete();
    await pumpEventQueue();
    expect(saida.paradas, paradas + 1);
    expect(cubit.state.status, StatusOuvir.tocando);
    expect(cubit.state.indice, 1);
    expect(saida.ultima, 'en:a2.@1.0');
  });

  test('pt sem voz (semVoz) vira silêncio do tamanho estimado e segue', () async {
    await cubit.close();
    cubit = novo(config: const ConfigOuvir(modo: ModoOuvir.inglesPortugues));
    await pumpEventQueue();
    await comecar();
    await passo(); // en
    expect(saida.ultima, 'sil:400');
    expect(cubit.state.fase, FaseOuvir.traducao);
    await passo();
    expect(saida.ultima, 'pt:Um.');
    await passo(FimDaFala.semVoz);
    expect(saida.ultima, 'sil:1000', reason: '"Um." ≈ 1 s (mínimo)');
    expect(cubit.state.status, StatusOuvir.tocando);
    await passo(); // o silêncio no lugar da voz
    expect(saida.ultima, 'sil:1000'); // a pausa depois
    await passo();
    expect(cubit.state.indice, 1);
  });

  test('timer de N minutos para na virada de frase', () async {
    await comecar();
    cubit.desligarEm(DesligarEm.min15);
    expect(cubit.state.desligaAs, relogio.add(const Duration(minutes: 15)));
    await frase();
    expect(cubit.state.status, StatusOuvir.tocando);
    relogio = relogio.add(const Duration(minutes: 16));
    await passo(); // a2 fala
    expect(cubit.state.status, StatusOuvir.tocando, reason: 'só olha na virada');
    await passo(); // a2 pausa → virada
    expect(cubit.state.status, StatusOuvir.pausado);
    expect(cubit.state.motivo, MotivoPausa.timer);
    expect(cubit.state.indice, 2);
    expect(cubit.state.desligar, DesligarEm.nunca);
    expect(cubit.state.desligaAs, isNull);
  });

  test('timer "no fim da lição" para na 1ª frase da próxima', () async {
    await comecar();
    cubit.desligarEm(DesligarEm.fimDaLicao);
    await frase();
    await frase();
    expect(cubit.state.status, StatusOuvir.tocando);
    await frase(); // a3 → b1 vira a lição
    expect(cubit.state.status, StatusOuvir.pausado);
    expect(cubit.state.motivo, MotivoPausa.timer);
    expect(cubit.state.indice, 3);
  });

  test('fim da fila = acabou (com a pausa extra do fim da lição); "Repetir tudo" volta ao começo', () async {
    await comecar(4);
    await passo();
    expect(saida.ultima, 'sil:2500', reason: 'última da lição: +1,5 s');
    await passo();
    expect(cubit.state.status, StatusOuvir.acabou);
    expect(cubit.state.ouvidas, 1);
    await cubit.continuar(); // "Tocar de novo"
    await pumpEventQueue();
    expect(cubit.state.indice, 0);
    expect(cubit.state.status, StatusOuvir.tocando);

    cubit.configurar(const ConfigOuvir(repetirTudo: true));
    expect(prefs.config.repetirTudo, isTrue, reason: 'a config é salva');
    cubit.irPara(4);
    await pumpEventQueue();
    await frase();
    expect(cubit.state.status, StatusOuvir.tocando);
    expect(cubit.state.indice, 0);
    expect(saida.ultima, 'en:a1.@1.0');
  });

  test('configurar vale a partir da próxima frase', () async {
    await comecar();
    cubit.configurar(const ConfigOuvir(velocidade: .75, repeticoes: 2));
    await frase(); // a1 termina como começou
    expect(saida.ultima, 'en:a2.@0.75');
    expect(cubit.state.de, 2);
    await passo();
    await passo();
    expect(saida.ultima, 'en:a2.@0.75');
    expect(cubit.state.vez, 2);
  });

  test('posição: salva na virada de lição, a cada 5 frases e ao fechar; fechar limpa a sessão', () async {
    await comecar();
    await frase();
    await frase();
    expect(prefs.posicoes['curso'], isNull);
    await frase(); // a3 → b1: virada
    expect(prefs.posicoes['curso'], (i: 3, chave: 'b1'));
    expect(cubit.posicaoSalva('curso'), (i: 3, chave: 'b1'));
    await passo();
    cubit.fechar();
    expect(cubit.state.status, StatusOuvir.parado);
    expect(cubit.state.fila, isEmpty);
    expect(cubit.state.fonte, isNull);
    expect(cubit.posicaoSalva('curso'), (i: 3, chave: 'b1'));
    expect(midia.limpezas, 1);
    expect(saida.temPendente, isFalse);
    // depois de fechar, play da sessão de mídia não faz nada
    await cubit.continuar();
    expect(cubit.state.status, StatusOuvir.parado);

    // fila "avulso" não guarda posição
    await cubit.tocar(const FonteOuvir('avulso', 'Lição 1'), _fila);
    await pumpEventQueue();
    cubit.pausar();
    expect(cubit.posicaoSalva('avulso'), isNull);
  });

  test('salva a cada 5 frases dentro de uma lição longa', () async {
    final longa = [for (var i = 0; i < 8; i++) _fx('c$i', 'l9', primeira: i == 0)];
    await cubit.tocar(const FonteOuvir('setlist:s1', 'Ônibus'), longa);
    await pumpEventQueue();
    for (var i = 0; i < 4; i++) {
      await frase();
    }
    expect(prefs.posicoes['setlist:s1'], isNull);
    await frase();
    expect(prefs.posicoes['setlist:s1'], (i: 5, chave: 'c5'));
  });

  test('close() cala a saída e limpa a sessão de mídia', () async {
    await comecar();
    final paradas = saida.paradas;
    await cubit.close();
    expect(saida.paradas, greaterThan(paradas));
    expect(midia.limpezas, 1);
    expect(saida.temPendente, isFalse);
  });

  test('fechar/close pausado (outra fala começou) não cala a saída: a outra voz segue falando', () async {
    await comecar();
    await passo(FimDaFala.cortada);
    expect(cubit.state.motivo, MotivoPausa.outraFala);
    final paradas = saida.paradas;
    cubit.fechar();
    expect(saida.paradas, paradas, reason: 'o ✕ não corta o palco/arcade que pausou o player');
    expect(cubit.state.status, StatusOuvir.parado);

    await comecar();
    cubit.pausar();
    final p2 = saida.paradas;
    await cubit.close();
    expect(saida.paradas, p2);
  });

  test('sessão de mídia: metadados por frase e as teclas mandam no player', () async {
    await comecar();
    expect(midia.metadados.last, ('a1.', 'mike · Lição l1', 'Paclingo · Curso na ordem', true));
    midia.pause!();
    await pumpEventQueue();
    expect(cubit.state.status, StatusOuvir.pausado);
    expect(midia.metadados.last.$4, isFalse);
    midia.play!();
    await pumpEventQueue();
    expect(cubit.state.status, StatusOuvir.tocando);
    midia.proxima!();
    await pumpEventQueue();
    expect(cubit.state.indice, 1);
    expect(midia.metadados.last.$1, 'a2.');
    midia.repetir!();
    await pumpEventQueue();
    expect(cubit.state.indice, 1);
    midia.anterior!(); // logo no começo: anterior
    await pumpEventQueue();
    expect(cubit.state.indice, 0);
    midia.parar!();
    await pumpEventQueue();
    expect(cubit.state.status, StatusOuvir.parado);
  });

  test('nunca toca sozinho: um cubit novo começa parado (mesmo com posição salva) e carrega a config', () async {
    prefs = PreferenciasOuvirMemoria(config: const ConfigOuvir(velocidade: .9));
    await prefs.salvarPosicao('curso', 3, 'b1');
    final c = OuvirCubit(saida: saida, prefs: prefs);
    await pumpEventQueue();
    expect(c.state.status, StatusOuvir.parado);
    expect(c.state.config.velocidade, .9);
    expect(c.posicaoSalva('curso'), (i: 3, chave: 'b1'));
    expect(saida.chamadas, isEmpty);
    await c.close();
  });

  test('fila vazia não toca; tocar de novo troca a fila e o laço velho não emite mais', () async {
    await cubit.tocar(_curso, const []);
    expect(cubit.state.status, StatusOuvir.parado);
    await comecar();
    await cubit.tocar(const FonteOuvir('setlist:s1', 'Ônibus'), _fila.sublist(3));
    await pumpEventQueue();
    expect(cubit.state.fonte?.id, 'setlist:s1');
    expect(cubit.state.indice, 0);
    expect(saida.ultima, 'en:b1.@1.0');
    expect(cubit.state.status, StatusOuvir.tocando);
  });

  // testWidgets falha sozinho se sobrar Timer pendente no fim (o vigia de 8 s ficaria)
  testWidgets('vigia padrão (sem esperar injetado) não deixa timer pendurado', (tester) async {
    final s = _Saida();
    final c = OuvirCubit(saida: s);
    await c.tocar(_curso, _fila);
    await tester.pump();
    s.terminar(FimDaFala.acabou);
    await tester.pump();
    expect(s.ultima, 'sil:1000');
    c.pausar();
    await tester.pump();
    await c.close();
  });

  testWidgets('vigia padrão estoura de verdade e pula a frase', (tester) async {
    final s = _Saida();
    final c = OuvirCubit(saida: s);
    await c.tocar(_curso, _fila);
    await tester.pump(const Duration(seconds: 9));
    expect(c.state.indice, 1);
    expect(s.ultima, 'en:a2.@1.0');
    await c.close();
  });

  test('fechar (ou sair do curso) depois do fim não estraga o "Continuar": a posição fica no começo', () async {
    await comecar(4);
    cubit.proxima(); // passou da última: acabou
    await pumpEventQueue();
    expect(cubit.state.status, StatusOuvir.acabou);
    expect(prefs.posicoes['curso'], (i: 0, chave: 'a1'));
    cubit.fechar();
    expect(prefs.posicoes['curso'], (i: 0, chave: 'a1'), reason: 'o ✕ não salva a última frase por cima');
    await comecar(4);
    cubit.proximaLicao();
    await pumpEventQueue();
    expect(cubit.state.status, StatusOuvir.acabou);
    await cubit.close();
    expect(prefs.posicoes['curso'], (i: 0, chave: 'a1'), reason: 'nem o close');
  });

  test('frase com áudio do aluno: o vigia do inglês dá pelo menos 30 s (o clipe pode ser longo)', () async {
    await cubit.close();
    saida = _SaidaComAluno();
    cubit = novo();
    await comecar();
    expect(limites.last, OuvirCubit.vigiaAudioDoAluno);
    await passo();
    expect(limites.last, const Duration(milliseconds: 5500), reason: 'a pausa segue a conta normal');
    await passo();
    expect(saida.ultima, 'en:a2.@1.0');
    expect(limites.last, const Duration(seconds: 8), reason: 'sem áudio do aluno: 2 s × 2,5 + 3 s');
  });
}

/// A frase a1 tem áudio anexado pelo aluno.
class _SaidaComAluno extends _Saida implements SaidaComAudioDoAluno {
  @override
  bool temAudioDoAluno(String en) => en == 'a1.';
}
