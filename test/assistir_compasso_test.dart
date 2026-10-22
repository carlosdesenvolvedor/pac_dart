// 📺 O compasso do "Escutar assistindo" (puro): vão final nos 3 modos × repetições × com e sem tradução
// (com o `vez` velho do português→inglês), a duração do vão, o plano dos mudos, o fator de tempo, as letras e
// as faixas da lição na fila. Também guarda a fixture das historinhas usada pelo seguidor e pelo palco.
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/domain/assistir/compasso_assistir.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historia_licao.dart';
import 'package:pac_dart/features/ingles/domain/config_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/expressao.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/assistir/memoria_assistir.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';

// ───────────────────────── fixture (2 lições da mesma trilha)

const etapaFixture = 'A1 · Fundação';

const licaoA = Licao(id: 'trilha-a.licao-1', nome: 'Primeira chamada', emoji: '👋', trechos: [
  Trecho(id: 'f-a0', quem: 'voce', cod: 'Good morning, Mike!', dica: 'Bom dia, Mike!', out: '', imagem: '☀️👋'),
  Trecho(id: 'f-a1', quem: 'mike', cod: "Hi! How's it going?", dica: 'Oi! Tudo bem?', out: '', imagem: '🙂❓'),
  Trecho(id: 'f-a2', quem: 'voce', cod: 'Pretty good, thanks.', dica: 'Tudo certo, obrigado.', out: '', imagem: '👍'),
  Trecho(id: 'f-a3', quem: 'ana', cod: 'Hello, everyone!', dica: 'Olá, pessoal!', out: '', imagem: '👋'),
  Trecho(id: 'f-a4', quem: 'voce', cod: 'Hi, Ana!', dica: 'Oi, Ana!', out: '', imagem: '🙂'),
]);

const licaoB = Licao(id: 'trilha-a.licao-2', nome: 'Até amanhã', emoji: '🌙', trechos: [
  Trecho(id: 'f-b0', quem: 'voce', cod: 'See you tomorrow.', dica: 'Até amanhã.', out: '', imagem: '👋'),
  Trecho(id: 'f-b1', quem: 'sarah', cod: 'Bye, see you!', dica: 'Tchau, até!', out: '', imagem: '😊'),
]);

const trilhaFixture = Trilha(nivel: 'Trilha A', emoji: '🧪', etapa: etapaFixture, licoes: [licaoA, licaoB]);

FalaHistoria _ancora(Licao l, int k, {AcaoAtor acao = AcaoAtor.parado, Expressao? emocao}) {
  final t = l.trechos[k];
  return FalaHistoria(quem: quemNoPalco(t.quem), en: t.cod, pt: t.dicaPlana, acao: acao, emocao: emocao);
}

/// A lição A, autoral: cena 0 (passos: âncora a0 · mudo · âncora a1 · âncora a2 · mudo) e cena 1 (mudo: a Ana
/// entra · âncora a3 · âncora a4). Âncoras: a0 (0,0), a1 (0,2), a2 (0,3), a3 (1,1), a4 (1,2).
HistoriaLicao historiaA() => HistoriaLicao.daLicao(
      licaoA,
      [
        CenaHistoria(
          cenario: CenarioHistoria.escritorio,
          hora: HoraHistoria.dia,
          elenco: const [
            AtorEmCena(quem: 'voce', pos: PosicaoPalco.centroEsquerda),
            AtorEmCena(quem: 'mike', pos: PosicaoPalco.centroDireita),
          ],
          falas: [
            _ancora(licaoA, 0, acao: AcaoAtor.acena, emocao: Expressao.feliz),
            const FalaHistoria(quem: 'mike', mudo: true, acao: AcaoAtor.acena),
            _ancora(licaoA, 1),
            _ancora(licaoA, 2, acao: AcaoAtor.concorda),
            const FalaHistoria(quem: 'voce', mudo: true, acao: AcaoAtor.concorda, emocao: Expressao.radiante),
          ],
        ),
        CenaHistoria(
          cenario: CenarioHistoria.casa,
          hora: HoraHistoria.tarde,
          elenco: const [
            AtorEmCena(quem: 'voce', pos: PosicaoPalco.centroEsquerda),
            AtorEmCena(quem: 'ana', pos: PosicaoPalco.centroDireita, visivel: false),
          ],
          falas: [
            const FalaHistoria(quem: 'ana', mudo: true, acao: AcaoAtor.entra, emocao: Expressao.feliz),
            _ancora(licaoA, 3, acao: AcaoAtor.acena),
            _ancora(licaoA, 4),
          ],
        ),
      ],
      nivel: NivelIngles.a1,
      titulo: const TextoBilingue('The first call', 'A primeira chamada'),
      autoral: true,
    );

/// A lição A "automática": uma cena só, uma âncora parada por frase, sem mudos.
HistoriaLicao historiaAutoA() => HistoriaLicao.daLicao(
      licaoA,
      [
        CenaHistoria(
          cenario: CenarioHistoria.casa,
          hora: HoraHistoria.dia,
          elenco: const [
            AtorEmCena(quem: 'voce', pos: PosicaoPalco.esquerda),
            AtorEmCena(quem: 'mike', pos: PosicaoPalco.centro),
            AtorEmCena(quem: 'ana', pos: PosicaoPalco.direita),
          ],
          falas: [for (var k = 0; k < licaoA.trechos.length; k++) _ancora(licaoA, k)],
        ),
      ],
      nivel: NivelIngles.a1,
      autoral: false,
    );

/// A lição B: a Sarah entra (mudo) · âncora b0 (0,1) · âncora b1 (0,2) · todos acenam (mudo).
HistoriaLicao historiaB() => HistoriaLicao.daLicao(
      licaoB,
      [
        CenaHistoria(
          cenario: CenarioHistoria.casa,
          hora: HoraHistoria.noite,
          elenco: const [
            AtorEmCena(quem: 'voce', pos: PosicaoPalco.centroEsquerda),
            AtorEmCena(quem: 'sarah', pos: PosicaoPalco.centroDireita, visivel: false),
          ],
          falas: [
            const FalaHistoria(quem: 'sarah', mudo: true, acao: AcaoAtor.entra),
            _ancora(licaoB, 0, acao: AcaoAtor.acena),
            _ancora(licaoB, 1, acao: AcaoAtor.acena),
            const FalaHistoria(quem: 'voce', mudo: true, acao: AcaoAtor.acena, emocao: Expressao.feliz),
          ],
        ),
      ],
      nivel: NivelIngles.a1,
      titulo: const TextoBilingue('Good night', 'Boa noite'),
      autoral: true,
    );

/// Uma faixa do Ouvir para a frase [k] da lição [l] (2 s a 1×).
Faixa faixaDe(Licao l, int k, {bool? primeira, double segundos = 2}) {
  final t = l.trechos[k];
  return Faixa(
    chave: t.id,
    en: t.cod,
    pt: t.dicaPlana,
    quem: t.quem,
    licaoId: l.id,
    licaoNome: l.nome,
    licaoEmoji: l.emoji,
    trilhaNome: trilhaFixture.nivel,
    etapa: etapaFixture,
    primeiraDaLicao: primeira ?? k == 0,
    segundos: segundos,
    imagem: t.imagem,
  );
}

/// A fila do curso de teste: as 5 frases da lição A e as 2 da B.
List<Faixa> filaAB() => [
      for (var k = 0; k < licaoA.trechos.length; k++) faixaDe(licaoA, k),
      for (var k = 0; k < licaoB.trechos.length; k++) faixaDe(licaoB, k),
    ];

/// Uma frase órfã (sem lição do curso).
const faixaOrfa = Faixa(chave: 'orfa-1', en: 'Free text.', pt: 'Texto livre.', primeiraDaLicao: true, segundos: 2);

/// Os estados que o Ouvir emite tocando a faixa [i] (pela ordem de `passosDa`), a partir de [base].
List<OuvirState> estadosDaFaixa(OuvirState base, int i) {
  final fila = base.fila;
  final f = fila[i];
  final fim = i + 1 >= fila.length || fila[i + 1].primeiraDaLicao;
  var st = base.copyWith(status: StatusOuvir.tocando, indice: i);
  final r = <OuvirState>[];
  for (final p in passosDa(f, base.config, fimDeLicao: fim)) {
    switch (p) {
      case FalaEn():
        st = st.copyWith(fase: FaseOuvir.ouvindo, vez: p.vez, de: p.de);
      case FalaPt():
        st = st.copyWith(fase: FaseOuvir.traducao);
      case Silencio():
        st = st.copyWith(fase: p.fase);
    }
    r.add(st);
  }
  return r;
}

/// O estado base tocando a fila [fila] (padrão: a [filaAB]).
OuvirState tocandoEm({int indice = 0, ConfigOuvir config = const ConfigOuvir(), List<Faixa>? fila}) => OuvirState(
      status: StatusOuvir.tocando,
      fonte: const FonteOuvir('curso', 'Curso'),
      fila: fila ?? filaAB(),
      indice: indice,
      config: config,
    );

// ───────────────────────── testes

/// O vão final como o seguidor decide: só logo depois de uma FalaEn desta faixa (memória) + `ehVaoFinal`.
bool _finalNoSeguidor(MemoriaAssistir m, OuvirState st) {
  final f = st.atual!;
  return m.ultimaFalaEnIndice == st.indice &&
      CompassoAssistir.ehVaoFinal(
        fase: st.fase,
        vez: st.vez,
        de: st.de,
        modo: st.config.modo,
        viuTraducao: m.viuTraducao(st.indice),
        temPt: f.pt.trim().isNotEmpty,
      );
}

void main() {
  group('ehVaoFinal', () {
    for (final modo in ModoOuvir.values) {
      for (var rep = 1; rep <= 3; rep++) {
        for (final comPt in [true, false]) {
          for (final eco in [false, true]) {
            test('${modo.name} × $rep repetição(ões) × ${comPt ? 'com' : 'sem'} pt${eco ? ' × eco' : ''}: só o último silêncio',
                () {
              final cfg = ConfigOuvir(modo: modo, repeticoes: rep, pausa: eco ? PausaOuvir.eco : PausaOuvir.media);
              final fila = [
                for (final f in filaAB())
                  comPt
                      ? f
                      : Faixa(
                          chave: f.chave,
                          en: f.en,
                          quem: f.quem,
                          licaoId: f.licaoId,
                          primeiraDaLicao: f.primeiraDaLicao,
                          segundos: f.segundos,
                        ),
              ];
              final estados = estadosDaFaixa(tocandoEm(config: cfg, fila: fila), 1);
              final m = MemoriaAssistir.paraTeste();
              final finais = <int>[];
              for (var k = 0; k < estados.length; k++) {
                final st = estados[k];
                m.registrar(st);
                if ((st.fase == FaseOuvir.respiro || st.fase == FaseOuvir.suaVez) && _finalNoSeguidor(m, st)) {
                  finais.add(k);
                }
              }
              expect(finais, [estados.length - 1], reason: 'exatamente um vão final, o último passo');
              final ultimo = estados.last;
              expect(ultimo.fase, eco ? FaseOuvir.suaVez : FaseOuvir.respiro);
            });
          }
        }
      }
    }

    test('sem pt o modo efetivo é "só inglês": a faixa tem vão final mesmo no inglês→português (P1)', () {
      expect(
        CompassoAssistir.ehVaoFinal(
            fase: FaseOuvir.respiro, vez: 1, de: 1, modo: ModoOuvir.inglesPortugues, viuTraducao: false, temPt: false),
        isTrue,
      );
      expect(
        CompassoAssistir.ehVaoFinal(
            fase: FaseOuvir.respiro, vez: 1, de: 1, modo: ModoOuvir.inglesPortugues, viuTraducao: false, temPt: true),
        isFalse,
        reason: 'com pt, o vão final é o depois da tradução',
      );
    });

    test('fora de respiro/suaVez ou com vez < de, nunca', () {
      for (final fase in [FaseOuvir.ouvindo, FaseOuvir.traducao, FaseOuvir.pense]) {
        expect(
          CompassoAssistir.ehVaoFinal(fase: fase, vez: 1, de: 1, modo: ModoOuvir.soIngles, viuTraducao: true, temPt: true),
          isFalse,
        );
      }
      expect(
        CompassoAssistir.ehVaoFinal(
            fase: FaseOuvir.respiro, vez: 1, de: 2, modo: ModoOuvir.soIngles, viuTraducao: true, temPt: true),
        isFalse,
      );
    });

    test('o vez velho do português→inglês (virada de faixa e irPara) não vira vão final', () {
      const cfg = ConfigOuvir(modo: ModoOuvir.portuguesIngles, repeticoes: 2);
      final base = tocandoEm(config: cfg);
      final m = MemoriaAssistir.paraTeste();
      final faixa0 = estadosDaFaixa(base, 0);
      for (final st in faixa0) {
        m.registrar(st);
      }
      expect(_finalNoSeguidor(m, faixa0.last), isTrue);
      // a virada natural: índice novo com a fase do silêncio anterior e o vez 2 de 2 velho
      final virada = faixa0.last.copyWith(indice: 1);
      m.registrar(virada);
      expect(
        CompassoAssistir.ehVaoFinal(
            fase: virada.fase, vez: virada.vez, de: virada.de, modo: cfg.modo, viuTraducao: false, temPt: true),
        isTrue,
        reason: 'só pelos números pareceria final…',
      );
      expect(_finalNoSeguidor(m, virada), isFalse, reason: '…mas a FalaEn desta faixa ainda não veio');
      // o irPara emite `ouvindo` com o vez velho; a FalaPt do português→inglês vem antes do inglês
      final irPara = virada.copyWith(fase: FaseOuvir.ouvindo);
      m.registrar(irPara);
      final pt = irPara.copyWith(fase: FaseOuvir.traducao);
      m.registrar(pt);
      final pense = pt.copyWith(fase: FaseOuvir.pense);
      m.registrar(pense);
      expect(m.ultimaFalaEnIndice, isNot(1));
      // um respiro aqui (não acontece no cubit, mas o vez é velho) também não é final
      expect(_finalNoSeguidor(m, pense.copyWith(fase: FaseOuvir.respiro)), isFalse);
      final en1 = pense.copyWith(fase: FaseOuvir.ouvindo, vez: 1, de: 2);
      m.registrar(en1);
      final r1 = en1.copyWith(fase: FaseOuvir.respiro);
      m.registrar(r1);
      expect(_finalNoSeguidor(m, r1), isFalse, reason: 'vez 1 de 2');
      final en2 = r1.copyWith(fase: FaseOuvir.ouvindo, vez: 2);
      m.registrar(en2);
      final r2 = en2.copyWith(fase: FaseOuvir.respiro);
      m.registrar(r2);
      expect(_finalNoSeguidor(m, r2), isTrue);
    });
  });

  group('momento', () {
    test('cada fase do Ouvir', () {
      final st = tocandoEm();
      expect(CompassoAssistir.momento(st, viuTraducao: false), MomentoAssistir.fala);
      expect(CompassoAssistir.momento(st.copyWith(fase: FaseOuvir.traducao), viuTraducao: false), MomentoAssistir.traducao);
      expect(CompassoAssistir.momento(st.copyWith(fase: FaseOuvir.pense), viuTraducao: false), MomentoAssistir.pense);
      expect(CompassoAssistir.momento(st.copyWith(fase: FaseOuvir.respiro), viuTraducao: false), MomentoAssistir.vaoFinal);
      expect(CompassoAssistir.momento(st.copyWith(fase: FaseOuvir.respiro, de: 2), viuTraducao: false), MomentoAssistir.vao);
      expect(CompassoAssistir.momento(st.copyWith(status: StatusOuvir.pausado), viuTraducao: false), MomentoAssistir.parado);
    });
  });

  group('vaoFinal', () {
    test('é o último Silencio de passosDa; +1,5 s no fim da lição', () {
      final f = faixaDe(licaoA, 1);
      for (final pausa in PausaOuvir.values) {
        for (final modo in ModoOuvir.values) {
          final cfg = ConfigOuvir(pausa: pausa, modo: modo, repeticoes: 2, velocidade: .9);
          for (final fim in [false, true]) {
            final ultimo = passosDa(f, cfg, fimDeLicao: fim).last as Silencio;
            expect(CompassoAssistir.vaoFinal(f, cfg, fimDeLicao: fim), ultimo.d.inMilliseconds / 1000);
          }
          expect(
            CompassoAssistir.vaoFinal(f, cfg, fimDeLicao: true) - CompassoAssistir.vaoFinal(f, cfg, fimDeLicao: false),
            closeTo(1.5, 1e-9),
          );
        }
      }
      expect(CompassoAssistir.vaoFinal(f, const ConfigOuvir(pausa: PausaOuvir.curta), fimDeLicao: false), .5);
      expect(CompassoAssistir.vaoFinal(f, const ConfigOuvir(), fimDeLicao: false), 1.0);
      // eco: clamp(2 × 1,2 / 1 + 0,8, 1,5, 9) = 3,2
      expect(CompassoAssistir.vaoFinal(f, const ConfigOuvir(pausa: PausaOuvir.eco), fimDeLicao: false), closeTo(3.2, 1e-9));
    });
  });

  group('planoDoVao', () {
    final a = historiaA();
    final b = historiaB();

    test('as âncoras da fixture', () {
      expect(a.ancoras, {'f-a0': (0, 0), 'f-a1': (0, 2), 'f-a2': (0, 3), 'f-a3': (1, 1), 'f-a4': (1, 2)});
      expect(b.ancoras, {'f-b0': (0, 1), 'f-b1': (0, 2)});
    });

    test('mesma história e mesma cena: os mudos entre as duas âncoras', () {
      final p = CompassoAssistir.planoDoVao(atual: a, ancoraAtual: (0, 0), proxima: a, ancoraProxima: (0, 2), vao: 1);
      expect(p, hasLength(1));
      expect(p.single.passos, [(0, 1)]);
      expect(p.single.abreCena, isFalse);
      expect(identical(p.single.historia, a), isTrue);
    });

    test('mesma cena sem mudo entre as âncoras: nada', () {
      expect(CompassoAssistir.planoDoVao(atual: a, ancoraAtual: (0, 2), proxima: a, ancoraProxima: (0, 3)), isEmpty);
    });

    test('troca de cena: o rabo da cena atual + a abertura da nova com os mudos do começo', () {
      final p = CompassoAssistir.planoDoVao(atual: a, ancoraAtual: (0, 3), proxima: a, ancoraProxima: (1, 1), vao: .5);
      expect(p, hasLength(2));
      expect(p[0].passos, [(0, 4)]);
      expect(p[0].abreCena, isFalse);
      expect(p[1].passos, [(1, 0)]);
      expect(p[1].abreCena, isTrue);
      expect(p[1].destino, (1, 1));
    });

    test('outra lição com tempo para abrir: o rabo + a abertura da próxima (o estado antes da âncora + mudos)', () {
      final p = CompassoAssistir.planoDoVao(atual: a, ancoraAtual: (0, 3), proxima: b, ancoraProxima: (0, 1), vao: 3);
      expect(p, hasLength(2));
      expect(p[0].passos, [(0, 4)]);
      expect(identical(p[1].historia, b), isTrue);
      expect(p[1].abreCena, isTrue);
      expect(p[1].passos, [(0, 0)], reason: 'a Sarah entra antes da 1ª fala');
      expect(p[1].destino, (0, 1));
    });

    test('outra lição sem tempo para abrir: só o rabo', () {
      // o rabo (concorda) dura .9 s; com 1,5 s de vão sobram 1,35 − .9 = .45 < .6
      final p = CompassoAssistir.planoDoVao(atual: a, ancoraAtual: (0, 3), proxima: b, ancoraProxima: (0, 1), vao: 1.5);
      expect(p, hasLength(1));
      expect(p.single.passos, [(0, 4)]);
      // sem rabo e com pouco vão: nada
      expect(CompassoAssistir.planoDoVao(atual: a, ancoraAtual: (1, 2), proxima: b, ancoraProxima: (0, 1), vao: .6),
          isEmpty);
      // sem rabo e com vão: só a abertura
      final so = CompassoAssistir.planoDoVao(atual: a, ancoraAtual: (1, 2), proxima: b, ancoraProxima: (0, 1), vao: 1);
      expect(so.single.abreCena, isTrue);
    });

    test('pulo para trás na mesma história: o rabo + a abertura da âncora de trás (sem mudos: só o estado)', () {
      final p = CompassoAssistir.planoDoVao(atual: a, ancoraAtual: (0, 3), proxima: a, ancoraProxima: (0, 0), vao: 4);
      expect(p, hasLength(2));
      expect(p[0].passos, [(0, 4)]);
      expect(p[1].abreCena, isTrue);
      expect(p[1].passos, isEmpty);
      expect(p[1].destino, (0, 0));
    });

    test('sem próxima (fim da fila / faixa sem desenho): só o rabo', () {
      final p = CompassoAssistir.planoDoVao(atual: b, ancoraAtual: (0, 2));
      expect(p.single.passos, [(0, 3)]);
      expect(CompassoAssistir.planoDoVao(atual: a, ancoraAtual: (0, 2)), isEmpty);
    });
  });

  group('fatorDeTempo', () {
    test('≤ 1 em tempo real; > 1 acelera; infinity salta para o fim', () {
      expect(CompassoAssistir.fatorDeTempo(const [], 1), 1);
      expect(CompassoAssistir.fatorDeTempo(const [1.2], 2), closeTo(1.2 / 1.8, 1e-9));
      expect(CompassoAssistir.fatorDeTempo(const [1.2], 2), lessThanOrEqualTo(1));
      expect(CompassoAssistir.fatorDeTempo(const [1.2, 1.2], 2), closeTo(2.4 / 1.8, 1e-9));
      expect(CompassoAssistir.fatorDeTempo(const [1.2, 1.2], 2), greaterThan(1));
      // .9 s de vão para 3 passos: .81 / 3 = .27 s por passo < .35
      expect(CompassoAssistir.fatorDeTempo(const [1, 1, 1], .9), double.infinity);
      expect(CompassoAssistir.fatorDeTempo(const [1], 0), double.infinity);
    });

    test('duracaoMuda: a conta do Turismo (mínimo .8; efeitos 1,2; objetos)', () {
      expect(CompassoAssistir.duracaoMuda(const FalaHistoria(quem: 'ana', mudo: true, acao: AcaoAtor.entra)), .9);
      expect(CompassoAssistir.duracaoMuda(const FalaHistoria(quem: 'ana', mudo: true, acao: AcaoAtor.pula)), .8);
      expect(CompassoAssistir.duracaoMuda(const FalaHistoria(quem: 'ana', mudo: true, emocao: Expressao.feliz)), 1.2);
      expect(
        CompassoAssistir.duracaoMuda(const FalaHistoria(quem: 'ana', mudo: true, acao: AcaoAtor.pula, efeito: EfeitoHistoria.confete)),
        1.2,
      );
      expect(
        CompassoAssistir.duracaoMuda(const FalaHistoria(
          quem: 'ana',
          mudo: true,
          acao: AcaoAtor.pula,
          objetos: [MovimentoObjeto(prop: PropHistoria.presente, acao: AcaoObjeto.passa)],
        )),
        1.6,
      );
    });
  });

  group('letras', () {
    test('por segundo: A1 22 · A2 26 · B1/B2 30, × fator', () {
      expect(CompassoAssistir.letrasPorSegundo(NivelIngles.a1, 1), 22);
      expect(CompassoAssistir.letrasPorSegundo(NivelIngles.a2, 1), 26);
      expect(CompassoAssistir.letrasPorSegundo(NivelIngles.b1, 1), 30);
      expect(CompassoAssistir.letrasPorSegundo(NivelIngles.b2, .75), 22.5);
    });

    test('pela voz: proporcional à posição; null sem dado', () {
      expect(CompassoAssistir.letrasPelaVoz(total: 20, segundoDaVoz: 1, segundosDaFaixa: 2, fator: 1), 10);
      expect(CompassoAssistir.letrasPelaVoz(total: 20, segundoDaVoz: 1, segundosDaFaixa: 2, fator: .5), 5);
      expect(CompassoAssistir.letrasPelaVoz(total: 20, segundoDaVoz: 9, segundosDaFaixa: 2, fator: 1), 20);
      expect(CompassoAssistir.letrasPelaVoz(total: 20, segundoDaVoz: -1, segundosDaFaixa: 2, fator: 1), 0);
      expect(CompassoAssistir.letrasPelaVoz(total: 20, segundoDaVoz: null, segundosDaFaixa: 2, fator: 1), isNull);
      expect(CompassoAssistir.letrasPelaVoz(total: 20, segundoDaVoz: 1, segundosDaFaixa: null, fator: 1), isNull);
      expect(CompassoAssistir.letrasPelaVoz(total: 20, segundoDaVoz: 1, segundosDaFaixa: 0, fator: 1), isNull);
    });
  });

  group('licaoDaFaixa', () {
    test('o começo e o fim da lição da faixa na fila', () {
      final fila = filaAB();
      expect(CompassoAssistir.licaoDaFaixa(fila, 0), (inicio: 0, fim: 5));
      expect(CompassoAssistir.licaoDaFaixa(fila, 3), (inicio: 0, fim: 5));
      expect(CompassoAssistir.licaoDaFaixa(fila, 5), (inicio: 5, fim: 7));
      expect(CompassoAssistir.licaoDaFaixa(fila, 6), (inicio: 5, fim: 7));
      expect(CompassoAssistir.licaoDaFaixa(fila, 99), (inicio: 5, fim: 7));
      expect(CompassoAssistir.licaoDaFaixa(const [], 0), (inicio: 0, fim: 0));
      expect(CompassoAssistir.licaoDaFaixa([faixaOrfa, ...fila], 0), (inicio: 0, fim: 1));
    });
  });
}
