import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/config_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/assistir/memoria_assistir.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';

/// 📺 A memória do "Escutar assistindo" junto do `OuvirCubit` (D17): uma por cubit, assina o stream uma vez,
/// guarda por índice se houve tradução depois da última FalaEn, a faixa da última FalaEn e o `vez` dela, e
/// sobrevive ao "Tocando agora" sumir (minimizar).

/// Saída falsa: cada fala/silêncio fica pendente até o teste terminar ([terminar]); [parar] corta a pendente
/// com `cortada` (como a de verdade). No molde do fake de `ingles_ouvir_cubit_test.dart`.
class _Saida implements SaidaDeAudio {
  final chamadas = <String>[];
  final _pendentes = <Completer<FimDaFala>>[];

  Future<FimDaFala> _nova(String c) {
    chamadas.add(c);
    final x = Completer<FimDaFala>();
    _pendentes.add(x);
    return x.future;
  }

  @override
  Future<FimDaFala> en(String texto, {required double fator}) => _nova('en:$texto');

  @override
  Future<FimDaFala> pt(String texto, {required double fator}) => _nova('pt:$texto');

  @override
  Future<FimDaFala> silencio(Duration d) => _nova('sil:${d.inMilliseconds}');

  @override
  void parar() {
    for (final p in _pendentes) {
      if (!p.isCompleted) p.complete(FimDaFala.cortada);
    }
    _pendentes.clear();
  }

  @override
  void preaquecer(String texto) {}

  @override
  bool get somLiberado => true;

  @override
  double duracaoDe(String en) => 2;

  @override
  bool temGravacao(String en) => true;

  void terminar() => _pendentes.removeLast().complete(FimDaFala.acabou);
}

Faixa _fx(String chave, {bool primeira = false, String pt = ''}) => Faixa(
      chave: chave,
      en: '$chave.',
      pt: pt,
      quem: 'mike',
      licaoId: 'l1',
      licaoNome: 'Lição 1',
      primeiraDaLicao: primeira,
      segundos: 2,
    );

final _fila = [
  _fx('a1', primeira: true, pt: 'Um.'),
  _fx('a2', pt: 'Dois.'),
  _fx('a3'), // sem tradução: o modo vira "só inglês"
];

const _curso = FonteOuvir('curso', 'Curso na ordem');

void main() {
  late _Saida saida;
  late DateTime relogio;
  late OuvirCubit cubit;

  OuvirCubit novo() => OuvirCubit(
        saida: saida,
        agora: () => relogio,
        esperar: (_) => Completer<void>().future,
      );

  setUp(() {
    saida = _Saida();
    relogio = DateTime(2026, 10, 22, 8);
    cubit = novo();
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  /// Termina o passo pendente (uma fala "de verdade" leva tempo).
  Future<void> passo() async {
    relogio = relogio.add(const Duration(seconds: 1));
    saida.terminar();
    await pumpEventQueue();
  }

  test('uma memória por cubit (a mesma instância; outro cubit, outra)', () async {
    final m = MemoriaAssistir.de(cubit);
    expect(identical(MemoriaAssistir.de(cubit), m), isTrue);
    final outro = novo();
    expect(identical(MemoriaAssistir.de(outro), m), isFalse);
    await outro.close();
  });

  test('inglês → português: registra a tradução depois da última FalaEn e zera na troca de faixa', () async {
    cubit.configurar(const ConfigOuvir(modo: ModoOuvir.inglesPortugues, repeticoes: 2));
    final m = MemoriaAssistir.de(cubit);
    expect(m.ultimaFalaEnIndice, isNull);
    await cubit.tocar(_curso, _fila);
    await pumpEventQueue();
    // en(1)
    expect(cubit.state.fase, FaseOuvir.ouvindo);
    expect(m.ultimaFalaEnIndice, 0);
    expect(m.vezVista, 1);
    expect(m.viuTraducao(0), isFalse);
    await passo(); // → pausa
    await passo(); // → en(2)
    expect(m.vezVista, 2);
    expect(m.viuTraducao(0), isFalse);
    await passo(); // → 0,4 s (traducao)
    expect(cubit.state.fase, FaseOuvir.traducao);
    expect(m.viuTraducao(0), isTrue);
    await passo(); // → FalaPt
    await passo(); // → pausa final (respiro): o vão final
    expect(cubit.state.fase, FaseOuvir.respiro);
    expect(m.viuTraducao(0), isTrue);
    expect(m.viuTraducao(1), isFalse, reason: 'é por índice');
    expect(m.ultimaFalaEnIndice, 0);
    expect(m.vezVista, 2);
    await passo(); // → faixa 1, en(1)
    expect(cubit.state.indice, 1);
    expect(m.viuTraducao(0), isFalse, reason: 'zera quando o índice muda');
    expect(m.viuTraducao(1), isFalse);
    expect(m.ultimaFalaEnIndice, 1);
    expect(m.vezVista, 1);
  });

  test('português → inglês: a tradução vem antes, e o `vez` velho do irPara não conta como FalaEn', () async {
    cubit.configurar(const ConfigOuvir(modo: ModoOuvir.portuguesIngles, repeticoes: 2));
    final m = MemoriaAssistir.de(cubit);
    await cubit.tocar(_curso, _fila);
    await pumpEventQueue();
    expect(cubit.state.fase, FaseOuvir.traducao); // FalaPt
    expect(m.ultimaFalaEnIndice, isNull);
    await passo(); // pense
    expect(cubit.state.fase, FaseOuvir.pense);
    expect(m.ultimaFalaEnIndice, isNull);
    await passo(); // en(1)
    await passo(); // pausa
    await passo(); // en(2)
    expect(m.ultimaFalaEnIndice, 0);
    expect(m.vezVista, 2);
    // ⏭ para a faixa 1: o irPara emite `ouvindo` com o vez velho (2), depois a FalaPt
    cubit.irPara(1);
    await pumpEventQueue();
    expect(cubit.state.indice, 1);
    expect(cubit.state.fase, FaseOuvir.traducao);
    expect(cubit.state.vez, 2, reason: 'a armadilha do vez: o cubit não zera');
    expect(m.ultimaFalaEnIndice, isNot(1));
    expect(m.vezVista, isNot(2));
  });

  test('faixa sem pt: a FalaEn conta e não há tradução', () async {
    cubit.configurar(const ConfigOuvir(modo: ModoOuvir.inglesPortugues));
    final m = MemoriaAssistir.de(cubit);
    await cubit.tocar(_curso, _fila, inicio: 2);
    await pumpEventQueue();
    expect(m.ultimaFalaEnIndice, 2);
    await passo(); // pausa
    expect(cubit.state.fase, FaseOuvir.respiro);
    expect(m.viuTraducao(2), isFalse);
  });

  test('parado (antes de tocar) não conta como FalaEn; registrar é chamável direto', () {
    final m = MemoriaAssistir.de(cubit);
    expect(cubit.state.status, StatusOuvir.parado);
    expect(m.ultimaFalaEnIndice, isNull);
    final t = MemoriaAssistir.paraTeste();
    t.registrar(OuvirState(status: StatusOuvir.tocando, fila: _fila, indice: 1, vez: 3, de: 3));
    expect(t.ultimaFalaEnIndice, 1);
    expect(t.vezVista, 3);
    t.registrar(OuvirState(status: StatusOuvir.tocando, fila: _fila, indice: 1, fase: FaseOuvir.traducao, vez: 3, de: 3));
    expect(t.viuTraducao(1), isTrue);
    t.registrar(OuvirState(status: StatusOuvir.pausado, fila: _fila, indice: 1, fase: FaseOuvir.traducao, vez: 3, de: 3));
    expect(t.viuTraducao(1), isTrue, reason: 'pausar não apaga');
    t.registrar(OuvirState(status: StatusOuvir.tocando, fila: _fila, indice: 2, fase: FaseOuvir.respiro));
    expect(t.viuTraducao(1), isFalse);
    expect(t.viuTraducao(2), isFalse);
  });

  testWidgets('sobrevive a "minimizar": o widget some, a memória fica com o que viu', (tester) async {
    MemoriaAssistir? vista;
    Widget palco() => Builder(builder: (_) {
          vista = MemoriaAssistir.de(cubit);
          return const SizedBox();
        });
    await tester.pumpWidget(palco());
    final m = vista!;
    await tester.runAsync(() async {
      await cubit.tocar(_curso, _fila);
      await pumpEventQueue();
    });
    expect(m.ultimaFalaEnIndice, 0);
    // "minimiza": o palco some
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      cubit.irPara(1);
      await pumpEventQueue();
    });
    // "reabre": um palco novo pega a MESMA memória, que seguiu o cubit enquanto ninguém olhava
    await tester.pumpWidget(palco());
    expect(identical(vista, m), isTrue);
    expect(m.ultimaFalaEnIndice, 1);
    await tester.runAsync(cubit.close);
  });

  test('cancela a assinatura no close do cubit', () async {
    final m = MemoriaAssistir.de(cubit);
    expect(m.assinando, isTrue);
    await cubit.close();
    await pumpEventQueue();
    expect(m.assinando, isFalse);
    // um cubit já fechado: memória sem assinatura
    expect(MemoriaAssistir.de(cubit).assinando, isFalse);
  });
}
