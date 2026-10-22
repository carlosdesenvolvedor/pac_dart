// 📺 O RoteiroSeguidor contra sequências REAIS de estados do Ouvir (geradas com `passosDa` + `copyWith`): letras
// da vez 1 (pela voz e pelo nível), PT forçado na tradução, "…" no pense, o vão final com os mudos (estado final =
// `linhaDoTempo`), irPara, pausa, timer, eco, troca de lição (com esmaecer) e só em corte de verdade (D18),
// partida a frio (D17), reancorar pela voz (I4), a autoral que chega no meio da lição, faixa órfã e reduzir.
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/simulacao_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/roteiro_historia.dart' show EstadoRoteiro;
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historia_licao.dart';
import 'package:pac_dart/features/ingles/domain/boca.dart';
import 'package:pac_dart/features/ingles/domain/config_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/assistir/memoria_assistir.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/assistir/roteiro_seguidor.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';

import 'assistir_compasso_test.dart';

/// Um seguidor com a fixture (lição A autoral, lição B) e um relógio controlável.
class _Montagem {
  _Montagem({HistoriaLicao? Function(Faixa f)? historiaDe, bool reduzir = false}) {
    seguidor = RoteiroSeguidor(
      historiaDe: historiaDe ?? (f) => f.licaoId == licaoA.id ? a : (f.licaoId == licaoB.id ? b : null),
      memoria: memoria,
      reduzir: reduzir,
      agora: () => agora,
    );
  }

  final a = historiaA();
  final b = historiaB();
  final memoria = MemoriaAssistir.paraTeste();
  late final RoteiroSeguidor seguidor;
  DateTime agora = DateTime(2026, 10, 22, 9);

  void emitir(OuvirState st) => seguidor.aoEstado(st);

  /// Anda [s] segundos em tiques de 1/60 s.
  void andar(double s) {
    var t = 0.0;
    while (t < s - 1e-9) {
      final dt = (s - t).clamp(0.0, 1 / 60);
      seguidor.tick(dt);
      agora = agora.add(Duration(microseconds: (dt * 1e6).round()));
      t += dt;
    }
  }
}

/// O que importa de um estado da cena (para comparar com a `linhaDoTempo`).
Map<String, Object?> _resumo(EstadoCena e) => {
      'cenario': e.cenario,
      'hora': e.hora,
      for (final a in e.atores.values)
        a.quem: (a.pos, a.visivel, a.emocao, a.segura, a.remoto),
    };

FalaEmCurso _fc(String frase, DateTime inicio) =>
    FalaEmCurso(frase: frase, boca: TrilhaBoca.compacta('0D 500X'), inicio: inicio);

void main() {
  group('a fala (âncora)', () {
    test('vez 1: espera a voz .6 s e depois digita pelo nível; vez 2 já vem completa', () {
      final m = _Montagem();
      final s = m.seguidor;
      final estados = estadosDaFaixa(tocandoEm(config: const ConfigOuvir(repeticoes: 2)), 0);
      m.emitir(estados[0]); // ouvindo, vez 1 de 2
      expect((s.cena, s.passo), (0, 0));
      expect(s.falaAtual!.en, 'Good morning, Mike!');
      expect(s.estadoVisivel, EstadoRoteiro.falando);
      expect(s.letrasVisiveis, 0);
      m.andar(.5);
      expect(s.letrasVisiveis, 0, reason: 'esperando a voz');
      m.andar(.3); // .2 s depois da espera: 22 × .2
      expect(s.letrasVisiveis, inInclusiveRange(3, 5));
      m.andar(2);
      expect(s.letrasVisiveis, 'Good morning, Mike!'.length);
      expect(s.estadoVisivel, EstadoRoteiro.lendo);
      m.emitir(estados[1]); // respiro, vez 1 de 2: não é o final
      expect(s.noVao, isFalse);
      m.emitir(estados[2]); // ouvindo, vez 2 de 2
      expect(s.letrasVisiveis, 'Good morning, Mike!'.length);
      expect(s.estadoVisivel, EstadoRoteiro.lendo);
      expect(s.tPasso, 0, reason: 'a ação recomeça');
    });

    test('letras pela voz (I3): proporcionais à posição da FalaEmCurso', () {
      final m = _Montagem();
      final s = m.seguidor;
      m.emitir(tocandoEm());
      const en = 'Good morning, Mike!';
      s.aoFalar(_fc(en, m.agora));
      m.andar(.5); // a faixa dura 2 s: 25%
      expect(s.letrasVisiveis, inInclusiveRange((en.length * .2).floor(), (en.length * .3).ceil()));
      m.andar(.5); // 50%
      expect(s.letrasVisiveis, inInclusiveRange((en.length * .45).floor(), (en.length * .55).ceil()));
      // a voz acabou (falando = null): o texto completa
      s.aoFalar(null);
      expect(s.letrasVisiveis, en.length);
    });

    test('reancorar pela voz (I4): a mesma frase anunciada de novo, sem emit, recomeça as letras', () {
      final m = _Montagem();
      final s = m.seguidor;
      m.emitir(tocandoEm());
      const en = 'Good morning, Mike!';
      s.aoFalar(_fc(en, m.agora));
      m.andar(1.5);
      expect(s.letrasVisiveis, greaterThan(10));
      expect(s.tPasso, greaterThan(1));
      s.aoFalar(_fc(en, m.agora)); // o "R" na vez 1 de 1: o cubit não emite (estado igual)
      expect(s.letrasVisiveis, 0);
      expect(s.tPasso, 0);
      expect(s.escurecimento, 0, reason: 'a mesma âncora não escurece');
      m.andar(.5);
      expect(s.letrasVisiveis, inInclusiveRange(3, 7));
    });

    test('inglês→português: a tradução força o PT (com o chip "Tradução" desligado)', () {
      final m = _Montagem();
      final s = m.seguidor;
      const cfg = ConfigOuvir(modo: ModoOuvir.inglesPortugues, mostrarTraducao: false);
      final estados = estadosDaFaixa(tocandoEm(config: cfg), 0);
      m.emitir(estados[0]);
      expect(s.mostrarPt, isFalse);
      m.emitir(estados[1]); // traducao (o .4 s antes da FalaPt)
      expect(s.mostrarPt, isTrue);
      expect(s.letrasVisiveis, 'Good morning, Mike!'.length);
      expect(s.esconderEn, isFalse);
      expect((s.cena, s.passo), (0, 0));
    });

    test('português→inglês: o "…" na tradução e no pense (🤔), o inglês volta no ouvindo', () {
      final m = _Montagem();
      final s = m.seguidor;
      const cfg = ConfigOuvir(modo: ModoOuvir.portuguesIngles, mostrarTraducao: false);
      final estados = estadosDaFaixa(tocandoEm(config: cfg), 0);
      m.emitir(estados[0]); // traducao (FalaPt)
      expect(s.esconderEn, isTrue);
      expect(s.mostrarPt, isTrue);
      m.emitir(estados[1]); // pense
      expect(s.esconderEn, isTrue);
      expect(s.iconeDaFala, '🤔');
      m.emitir(estados[2]); // ouvindo
      expect(s.esconderEn, isFalse);
      expect(s.iconeDaFala, '☀️👋');
    });
  });

  group('o vão', () {
    test('vão final toca os mudos e termina no estado da linhaDoTempo', () {
      final m = _Montagem();
      final s = m.seguidor;
      final estados = estadosDaFaixa(tocandoEm(config: const ConfigOuvir(pausa: PausaOuvir.longa)), 0);
      m.emitir(estados[0]);
      m.andar(1);
      m.emitir(estados[1]); // respiro final (2 s)
      expect(s.noVao, isTrue);
      expect(s.falaAtual!.mudo, isFalse, reason: 'o balão fica .25 s');
      m.andar(.4);
      expect((s.cena, s.passo), (0, 1));
      expect(s.falaAtual!.mudo, isTrue);
      expect(s.estadoVisivel, EstadoRoteiro.entrando);
      expect(s.letrasVisiveis, 0);
      m.andar(1.6);
      expect((s.cena, s.passo), (0, 1));
      final linha = SimulacaoCena.linhaDoTempo(m.a.cenas[0]);
      expect(_resumo(s.depois), _resumo(linha[2]));
      expect(s.escurecimento, 0);
      // a próxima faixa (mesma cena): a âncora a1, sem esmaecer
      m.emitir(estadosDaFaixa(tocandoEm(config: const ConfigOuvir(pausa: PausaOuvir.longa)), 1).first);
      expect((s.cena, s.passo), (0, 2));
      expect(s.escurecimento, 0);
      expect(_resumo(s.antes), _resumo(linha[2]));
    });

    test('troca de cena no vão: o rabo, o corte (esmaecer) e a Ana entrando antes da âncora dela', () {
      final m = _Montagem();
      final s = m.seguidor;
      const cfg = ConfigOuvir(pausa: PausaOuvir.longa);
      final estados = estadosDaFaixa(tocandoEm(config: cfg, indice: 2), 2);
      m.emitir(estados[0]); // a2 (0,3)
      m.emitir(estados[1]); // vão final de 2 s
      m.andar(.25 + .5);
      expect((s.cena, s.passo), (0, 4), reason: 'o rabo: concorda');
      m.andar(.35);
      expect((s.cena, s.passo), (1, 0), reason: 'a abertura da cena 1: a Ana entra');
      expect(s.historiaNaTela, same(m.a));
      expect(s.escurecimento, greaterThan(0));
      m.andar(1);
      expect(s.escurecimento, 0);
      final linha1 = SimulacaoCena.linhaDoTempo(m.a.cenas[1]);
      expect(_resumo(s.depois), _resumo(linha1[1]));
      expect(s.depois.atores['ana']!.visivel, isTrue);
      // a FalaEn da a3: já está na cena 1 (aberta no vão), sem 2º esmaecer
      m.emitir(estadosDaFaixa(tocandoEm(config: cfg, indice: 3), 3).first);
      expect((s.cena, s.passo), (1, 1));
      expect(s.escurecimento, 0);
    });

    test('vão curto demais: salta direto para o estado final, coerente', () {
      final m = _Montagem();
      final s = m.seguidor;
      const cfg = ConfigOuvir(pausa: PausaOuvir.curta);
      final estados = estadosDaFaixa(tocandoEm(config: cfg, indice: 2), 2);
      m.emitir(estados[0]);
      m.emitir(estados[1]); // .5 s: .25 de balão e .25 para 2 mudos → salta
      m.andar(.3);
      expect(s.estatico, isTrue);
      expect(s.falaAtual, isNull);
      expect(s.cena, 1);
      final linha1 = SimulacaoCena.linhaDoTempo(m.a.cenas[1]);
      expect(_resumo(s.depois), _resumo(linha1[1]));
      expect(_resumo(s.antes), _resumo(linha1[1]));
    });

    test('nada para animar: o balão fica até a próxima faixa', () {
      final m = _Montagem();
      final s = m.seguidor;
      final estados = estadosDaFaixa(tocandoEm(indice: 1), 1); // a1 (0,2) → a2 (0,3): sem mudo entre
      m.emitir(estados[0]);
      m.emitir(estados[1]);
      expect(s.noVao, isFalse);
      m.andar(2);
      expect((s.cena, s.passo), (0, 2));
      expect(s.falaAtual!.en, "Hi! How's it going?");
      expect(s.letrasVisiveis, "Hi! How's it going?".length);
    });

    test('eco (I2): no "Sua vez" o balão fica nos primeiros 70% do vão; os mudos só no fim', () {
      final m = _Montagem();
      final s = m.seguidor;
      const cfg = ConfigOuvir(pausa: PausaOuvir.eco);
      final estados = estadosDaFaixa(tocandoEm(config: cfg), 0);
      m.emitir(estados[0]);
      m.emitir(estados[1]); // suaVez final: 3,2 s → o balão até 2,24 s
      expect(estados[1].fase, FaseOuvir.suaVez);
      m.andar(2.1);
      expect((s.cena, s.passo), (0, 0));
      expect(s.falaAtual!.mudo, isFalse);
      expect(s.letrasVisiveis, 'Good morning, Mike!'.length);
      m.andar(.3);
      expect((s.cena, s.passo), (0, 1));
      expect(s.falaAtual!.mudo, isTrue);
    });
  });

  group('pulos, pausa, timer, fim', () {
    test('irPara arbitrário: o estado da âncora (com o efeito dos mudos de antes)', () {
      final m = _Montagem();
      final s = m.seguidor;
      m.emitir(tocandoEm());
      m.emitir(tocandoEm(indice: 3)); // irPara(3): a3 (1,1) na cena 1
      expect((s.cena, s.passo), (1, 1));
      final linha1 = SimulacaoCena.linhaDoTempo(m.a.cenas[1]);
      expect(_resumo(s.antes), _resumo(linha1[1]));
      expect(s.antes.atores['ana']!.visivel, isTrue, reason: 'quem "entrou" no mudo já está lá');
      expect(s.escurecimento, 1, reason: 'troca de cena = corte');
      m.andar(.2);
      expect(s.escurecimento, closeTo(1 - .2 / .45, .05));
      // para trás, na mesma cena da âncora de antes
      m.emitir(tocandoEm(indice: 0));
      expect((s.cena, s.passo), (0, 0));
    });

    test('pausa congela: o tick não muda nada e o relógio para', () {
      final m = _Montagem();
      final s = m.seguidor;
      final estados = estadosDaFaixa(tocandoEm(config: const ConfigOuvir(pausa: PausaOuvir.longa)), 0);
      m.emitir(estados[0]);
      m.emitir(estados[1]);
      m.andar(.5);
      final antes = (s.cena, s.passo, s.tPasso, s.letrasVisiveis);
      m.emitir(estados[1].copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.usuario));
      expect(s.precisaDeRelogio, isFalse);
      m.andar(2);
      expect((s.cena, s.passo, s.tPasso, s.letrasVisiveis), antes);
      // continuar recomeça a frase: de volta à âncora
      m.emitir(estados[1].copyWith(fase: FaseOuvir.ouvindo));
      expect((s.cena, s.passo), (0, 0));
      expect(s.precisaDeRelogio, isTrue);
    });

    test('sem timer, o vão do fim da lição já abre a próxima (o estado antes da 1ª fala, sem balão)', () {
      final m = _Montagem();
      final s = m.seguidor;
      final estados = estadosDaFaixa(tocandoEm(indice: 4, config: const ConfigOuvir(pausa: PausaOuvir.longa)), 4);
      for (final e in estados) {
        m.emitir(e);
      }
      m.andar(.5);
      expect(s.historiaNaTela, same(m.b));
      expect(s.falaAtual?.mudo ?? true, isTrue, reason: 'a Sarah entra; nenhum balão da lição B');
      expect(s.historia, same(m.a), reason: 'a faixa ainda é da lição A');
    });

    test('timer (P8): o índice anda e o Ouvir pausa — fica o estado final da lição anterior', () {
      final m = _Montagem();
      final s = m.seguidor;
      final base = tocandoEm(indice: 4, config: const ConfigOuvir(pausa: PausaOuvir.longa))
          .copyWith(desligar: DesligarEm.fimDaLicao);
      final estados = estadosDaFaixa(base, 4); // a4 (1,2), a última da lição A
      for (final e in estados) {
        m.emitir(e);
      }
      m.andar(.5);
      // a virada natural (índice novo com a fase velha) e a pausa do timer
      final virada = estados.last.copyWith(indice: 5);
      m.emitir(virada);
      expect(s.historiaNaTela, same(m.a));
      final pausa = virada.copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.timer);
      m.emitir(pausa);
      expect(s.historiaNaTela, same(m.a), reason: 'não abre a lição B');
      expect(s.falaAtual?.en, isNot('See you tomorrow.'));
      m.andar(1);
      expect(s.historiaNaTela, same(m.a));
      // continuar: a FalaEn da b0
      m.emitir(pausa.copyWith(status: StatusOuvir.tocando, semMotivo: true, fase: FaseOuvir.ouvindo));
      expect(s.historia, same(m.b));
      expect(s.falaAtual!.en, 'See you tomorrow.');
    });

    test('fim da fila: congela no estado final', () {
      final m = _Montagem();
      final s = m.seguidor;
      final base = tocandoEm(indice: 6, config: const ConfigOuvir(pausa: PausaOuvir.longa));
      final estados = estadosDaFaixa(base, 6);
      for (final e in estados) {
        m.emitir(e);
      }
      m.andar(.3);
      m.emitir(estados.last.copyWith(status: StatusOuvir.acabou));
      expect(s.estatico, isTrue);
      final linha = SimulacaoCena.linhaDoTempo(m.b.cenas[0]);
      expect(_resumo(s.depois), _resumo(linha.last));
      expect(s.precisaDeRelogio, isFalse);
    });
  });

  group('cortes (D18)', () {
    test('repetir a âncora (0,0) e a 1ª da cena 1 três vezes: nenhum véu', () {
      for (final indice in [0, 3]) {
        final m = _Montagem();
        final s = m.seguidor;
        const cfg = ConfigOuvir(repeticoes: 3);
        final estados = estadosDaFaixa(tocandoEm(config: cfg, indice: indice), indice);
        for (final e in estados) {
          m.emitir(e);
          expect(s.escurecimento, 0, reason: '$indice ${e.fase} ${e.vez}');
          m.andar(.2);
          expect(s.escurecimento, 0);
        }
        // irPara para o mesmo índice (o `vez` velho) e o "R" pela voz
        m.emitir(estados.last.copyWith(fase: FaseOuvir.ouvindo));
        expect(s.escurecimento, 0);
        s.aoFalar(_fc(s.falaAtual!.en!, m.agora));
        s.aoFalar(_fc(s.falaAtual!.en!, m.agora));
        expect(s.escurecimento, 0);
      }
    });

    test('outra lição troca a história, com esmaecer', () {
      final m = _Montagem();
      final s = m.seguidor;
      m.emitir(tocandoEm(indice: 4));
      expect(s.historia, same(m.a));
      m.emitir(tocandoEm(indice: 5)); // irPara na lição B
      expect(s.historia, same(m.b));
      expect((s.cena, s.passo), (0, 1));
      expect(s.escurecimento, 1);
      m.andar(.5);
      expect(s.escurecimento, 0);
    });
  });

  group('partida a frio e memória (D17)', () {
    test('nascendo no meio de respiro (vez 2 de 3): âncora, balão completo, nenhum mudo', () {
      final m = _Montagem();
      final s = m.seguidor;
      const cfg = ConfigOuvir(repeticoes: 3);
      final estados = estadosDaFaixa(tocandoEm(config: cfg), 0);
      m.emitir(estados[3]); // respiro, vez 2 de 3
      expect((s.cena, s.passo), (0, 0));
      expect(s.letrasVisiveis, 'Good morning, Mike!'.length);
      expect(s.frio, isTrue);
      expect(s.escurecimento, 0);
      // até o vão final (vez 3 de 3) sem FalaEn vista: sem mudos
      m.emitir(estados[5].copyWith(fase: FaseOuvir.respiro));
      expect(s.noVao, isFalse);
      m.andar(1);
      expect((s.cena, s.passo), (0, 0));
      // a próxima FalaEn tira o frio
      m.emitir(estados[4]);
      expect(s.frio, isFalse);
    });

    test('nascendo na tradução (inglês→português): âncora, PT forçado, sem "…"', () {
      final m = _Montagem();
      final s = m.seguidor;
      const cfg = ConfigOuvir(modo: ModoOuvir.inglesPortugues, mostrarTraducao: false);
      final estados = estadosDaFaixa(tocandoEm(config: cfg, indice: 1), 1);
      m.emitir(estados[1]); // traducao
      expect((s.cena, s.passo), (0, 2));
      expect(s.mostrarPt, isTrue);
      expect(s.esconderEn, isFalse);
      expect(s.noVao, isFalse);
      m.emitir(estados.last); // o respiro final, sem a FalaEn vista
      expect(s.noVao, isFalse);
    });

    test('nascendo no pense (português→inglês): âncora e o "…"', () {
      final m = _Montagem();
      final s = m.seguidor;
      const cfg = ConfigOuvir(modo: ModoOuvir.portuguesIngles);
      final estados = estadosDaFaixa(tocandoEm(config: cfg, indice: 3), 3);
      m.emitir(estados[1]); // pense
      expect((s.cena, s.passo), (1, 1));
      expect(s.esconderEn, isTrue);
      expect(s.noVao, isFalse);
    });

    test('minimizar e reabrir no meio de um vão: o seguidor novo continua do mesmo passo', () {
      final m = _Montagem();
      final s = m.seguidor;
      const cfg = ConfigOuvir(pausa: PausaOuvir.longa);
      final estados = estadosDaFaixa(tocandoEm(config: cfg, indice: 2), 2);
      m.emitir(estados[0]);
      m.emitir(estados[1]);
      m.andar(.6);
      final passo = (s.cena, s.passo);
      expect(passo, (0, 4));
      s.dispose();
      final novo = RoteiroSeguidor(historiaDe: (f) => f.licaoId == licaoA.id ? m.a : m.b, memoria: m.memoria);
      novo.aoEstado(estados[1]);
      expect((novo.cena, novo.passo), passo);
      expect(novo.noVao, isTrue);
      novo.tick(1.2);
      expect(novo.cena, 1, reason: 'o plano continua');
      novo.dispose();
    });
  });

  group('história', () {
    test('a autoral que chega no meio da lição só entra na faixa seguinte (com esmaecer)', () {
      final auto = historiaAutoA();
      final autoral = historiaA();
      var temAutoral = false;
      final m = _Montagem(historiaDe: (f) => temAutoral ? autoral : auto);
      final s = m.seguidor;
      const cfg = ConfigOuvir(repeticoes: 2);
      final estados = estadosDaFaixa(tocandoEm(config: cfg), 0);
      m.emitir(estados[0]);
      expect(s.historia, same(auto));
      temAutoral = true;
      m.emitir(estados[1]);
      m.emitir(estados[2]);
      expect(s.historia, same(auto), reason: 'nunca troca no meio da faixa');
      m.emitir(estados[3]); // o vão final
      expect(s.historia, same(auto));
      m.andar(.4);
      m.emitir(estadosDaFaixa(tocandoEm(config: cfg, indice: 1), 1).first);
      expect(s.historia, same(autoral));
      expect((s.cena, s.passo), (0, 2));
    });

    test('faixa órfã: historia == null (D14); a próxima com lição volta a desenhar', () {
      final m = _Montagem();
      final s = m.seguidor;
      final fila = [faixaOrfa, ...filaAB()];
      m.emitir(tocandoEm(fila: fila));
      expect(s.historia, isNull);
      expect(s.precisaDeRelogio, isFalse);
      m.emitir(tocandoEm(fila: fila, indice: 1));
      expect(s.historia, same(m.a));
      expect(s.escurecimento, 0, reason: 'nada estava desenhado antes');
    });

    test('reduzir: sem esmaecer, texto completo e o vão salta para o estado final (sem andar)', () {
      final m = _Montagem(reduzir: true);
      final s = m.seguidor;
      const cfg = ConfigOuvir(pausa: PausaOuvir.longa);
      final estados = estadosDaFaixa(tocandoEm(config: cfg, indice: 2), 2);
      m.emitir(estados[0]);
      expect(s.letrasVisiveis, 'Pretty good, thanks.'.length);
      m.emitir(estados[1]);
      m.andar(.3);
      expect(s.estatico, isTrue, reason: 'sem a Ana andando: o estado final direto');
      expect(s.cena, 1);
      expect(s.depois.atores['ana']!.visivel, isTrue);
      expect(s.escurecimento, 0);
      m.emitir(tocandoEm(indice: 5));
      expect(s.escurecimento, 0);
    });
  });
}
