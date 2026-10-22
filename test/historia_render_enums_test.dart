// O palco do desenho (grupo C1) monta TODO valor dos enums da história sem exceção: cenário × hora,
// clima (combinações permitidas), efeito, prop, expressão, ação, movimento de objeto, fala remota e câmera.
// Cada caso é uma cena sintética "narrador → passo testado"; o roteiro anda na mão (tick) e o palco é
// montado em 0 / 300 / 1200 ms do passo, com e sem "reduzir animações".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/domain/simulacao_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/palco_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/roteiro_historia.dart';
import 'package:pac_dart/features/ingles/domain/expressao.dart';

const _abre = FalaHistoria(quem: narrador, en: 'Go.', pt: 'Vai.');

CapituloHistoria _cap(int pista) => CapituloHistoria(
      pista: pista,
      nivel: NivelIngles.b1,
      titulo: const TextoBilingue('Test', 'Teste'),
      resumo: 'Um capítulo de teste com uma cena sintética para o palco.',
      palavras: const [PalavraChave('car', 'carro'), PalavraChave('team', 'equipe'), PalavraChave('map', 'mapa')],
      intro: const [],
      fim: const [],
    );

CenaHistoria _cena(
  FalaHistoria f, {
  CenarioHistoria cenario = CenarioHistoria.campina,
  HoraHistoria hora = HoraHistoria.dia,
  List<ClimaHistoria> clima = const [],
  List<AtorEmCena>? elenco,
  List<ObjetoEmCena> objetos = const [],
}) =>
    CenaHistoria(
      cenario: cenario,
      hora: hora,
      clima: clima,
      elenco: elenco ??
          const [
            AtorEmCena(quem: 'voce', pos: PosicaoPalco.centroEsquerda),
            AtorEmCena(quem: 'mike', pos: PosicaoPalco.centroDireita),
          ],
      objetos: objetos,
      falas: [_abre, f],
    );

List<String> _erros(CenaHistoria c) {
  var e = EstadoCena.inicial(c);
  final erros = <String>[];
  for (final f in c.falas) {
    final (d, err) = SimulacaoCena.aplicar(e, f);
    erros.addAll(err);
    e = d;
  }
  return erros;
}

Future<void> _rodar(
  WidgetTester t,
  CenaHistoria cena, {
  bool reduzir = false,
  Size tamanho = const Size(800, 450),
  int pista = 1,
}) async {
  final r = RoteiroHistoria(
    cenas: [cena],
    nivel: NivelIngles.b1,
    voz: null,
    vozLigada: false,
    lenta: false,
    mostrarPt: true,
    reduzir: reduzir,
  );
  final cap = _cap(pista);
  r.tocar();
  r.tocarOuAvancar(); // completa a fala do narrador
  r.tocarOuAvancar(); // vai ao passo testado
  expect(r.passo, 1);
  var relogio = 0.0;
  for (final dt in [0.0, .3, .9]) {
    r.tick(dt);
    relogio += dt;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox.fromSize(
            size: tamanho,
            child: PalcoHistoria(roteiro: r, relogio: relogio, capitulo: cap, reduzir: reduzir),
          ),
        ),
      ),
    ));
    expect(t.takeException(), isNull);
  }
  r.dispose();
}

/// Uma cena válida em que o `voce` faz a ação [a] (com o contexto que ela exige).
CenaHistoria _cenaDaAcao(AcaoAtor a) {
  const fala = 'I can do it.', pt = 'Eu consigo.';
  switch (a) {
    case AcaoAtor.entra:
      return _cena(
        const FalaHistoria(quem: 'voce', en: fala, pt: pt, acao: AcaoAtor.entra, para: PosicaoPalco.esquerda),
        elenco: const [
          AtorEmCena(quem: 'voce', pos: PosicaoPalco.esquerda, visivel: false),
          AtorEmCena(quem: 'mike', pos: PosicaoPalco.centroDireita),
        ],
      );
    case AcaoAtor.anda || AcaoAtor.corre:
      return _cena(FalaHistoria(quem: 'voce', en: fala, pt: pt, acao: a, para: PosicaoPalco.centro));
    case AcaoAtor.abraca || AcaoAtor.arremessa || AcaoAtor.olha:
      return _cena(FalaHistoria(quem: 'voce', en: fala, pt: pt, acao: a, alvo: 'mike'),
          cenario: a == AcaoAtor.arremessa ? CenarioHistoria.neve : CenarioHistoria.campina);
    case AcaoAtor.mostra || AcaoAtor.escreve:
      return _cena(FalaHistoria(quem: 'voce', en: fala, pt: pt, acao: a, segura: PropHistoria.livro));
    case AcaoAtor.dirige:
      return _cena(
        const FalaHistoria(quem: 'voce', en: fala, pt: pt, acao: AcaoAtor.dirige),
        objetos: const [ObjetoEmCena(prop: PropHistoria.carro, pos: PosicaoPalco.centroEsquerda)],
      );
    case AcaoAtor.desce:
      return _cena(
        const FalaHistoria(quem: 'voce', en: fala, pt: pt, acao: AcaoAtor.desce),
        elenco: const [
          AtorEmCena(quem: 'voce', pos: PosicaoPalco.centroEsquerda, noCarro: true),
          AtorEmCena(quem: 'mike', pos: PosicaoPalco.centroDireita),
        ],
      );
    case AcaoAtor.rodopia:
      return _cena(
        const FalaHistoria(quem: 'voce', en: fala, pt: pt, acao: AcaoAtor.rodopia),
        elenco: const [
          AtorEmCena(quem: 'voce', pos: PosicaoPalco.centroEsquerda, noCarro: true),
          AtorEmCena(quem: 'mike', pos: PosicaoPalco.centroDireita),
        ],
      );
    case AcaoAtor.parado ||
          AcaoAtor.acena ||
          AcaoAtor.pula ||
          AcaoAtor.comemora ||
          AcaoAtor.aponta ||
          AcaoAtor.sai ||
          AcaoAtor.danca ||
          AcaoAtor.treme ||
          AcaoAtor.cai ||
          AcaoAtor.pensa ||
          AcaoAtor.palmas ||
          AcaoAtor.concorda ||
          AcaoAtor.nega ||
          AcaoAtor.senta ||
          AcaoAtor.dorme:
      return _cena(FalaHistoria(quem: 'voce', en: fala, pt: pt, acao: a));
  }
}

/// Uma cena válida com o movimento de objeto [a] (do chão, ou da mão de alguém quando [daMao]).
CenaHistoria _cenaDoObjeto(AcaoObjeto a, {bool daMao = false}) {
  const prop = PropHistoria.mapa;
  final noChao = !daMao && a != AcaoObjeto.aparece && a != AcaoObjeto.entra && a != AcaoObjeto.passa;
  final pos = a == AcaoObjeto.aparece || a == AcaoObjeto.entra ? PosicaoPalco.direita : null;
  return _cena(
    FalaHistoria(
      quem: 'voce',
      en: 'Look at the map.',
      pt: 'Olha o mapa.',
      objetos: [MovimentoObjeto(prop: prop, acao: a, pos: pos, de: daMao ? 'voce' : null)],
    ),
    elenco: [
      AtorEmCena(quem: 'voce', pos: PosicaoPalco.centroEsquerda, segura: daMao ? prop : null),
      const AtorEmCena(quem: 'mike', pos: PosicaoPalco.centroDireita),
    ],
    objetos: [if (noChao) const ObjetoEmCena(prop: prop, pos: PosicaoPalco.centro)],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  RoteiroHistoria.tocarSom = (_) {};

  testWidgets('CenarioHistoria × horasPermitidas', (t) async {
    for (final c in CenarioHistoria.values) {
      for (final h in horasPermitidas(c)) {
        await _rodar(t, _cena(const FalaHistoria(quem: 'voce', en: 'Hi!', pt: 'Oi!'), cenario: c, hora: h));
      }
    }
  });

  testWidgets('ClimaHistoria em todas as combinações permitidas (uma hora por cenário)', (t) async {
    for (final cl in ClimaHistoria.values) {
      var algum = false;
      for (final c in CenarioHistoria.values) {
        final h = horasPermitidas(c).where((h) => climaPermitido(cl, c, h)).firstOrNull;
        if (h == null) continue;
        algum = true;
        await _rodar(t, _cena(const FalaHistoria(quem: 'voce', en: 'Hi!', pt: 'Oi!'), cenario: c, hora: h, clima: [cl]));
      }
      expect(algum, isTrue, reason: '${cl.name} tem de valer em algum cenário');
    }
    // clima trocado no meio da cena, com reduzir
    await _rodar(
      t,
      _cena(const FalaHistoria(quem: 'voce', en: 'Rain!', pt: 'Chuva!', clima: [ClimaHistoria.chuva, ClimaHistoria.vento])),
      reduzir: true,
    );
  });

  testWidgets('troca de cenário e hora no meio da cena (fade)', (t) async {
    await _rodar(
      t,
      _cena(const FalaHistoria(
        quem: 'voce',
        en: 'Night now.',
        pt: 'Agora é noite.',
        cenario: CenarioHistoria.deserto,
        hora: HoraHistoria.noite,
        clima: [ClimaHistoria.estrelas],
      )),
    );
  });

  for (final reduzir in [false, true]) {
    final sufixo = reduzir ? ' (reduzir)' : '';

    testWidgets('EfeitoHistoria (falante, narrador e reação)$sufixo', (t) async {
      for (final e in EfeitoHistoria.values) {
        await _rodar(t, _cena(FalaHistoria(quem: 'voce', en: 'Wow!', pt: 'Uau!', efeito: e)), reduzir: reduzir);
        await _rodar(t, _cena(FalaHistoria(quem: narrador, en: 'Wow!', pt: 'Uau!', efeito: e)), reduzir: reduzir);
        await _rodar(
          t,
          _cena(FalaHistoria(quem: 'voce', en: 'Wow!', pt: 'Uau!', reacoes: [ReacaoHistoria(quem: 'mike', efeito: e)])),
          reduzir: reduzir,
        );
      }
    });

    testWidgets('PropHistoria na mão, no chão e com o capítulo de cada pintura$sufixo', (t) async {
      for (final p in PropHistoria.values) {
        await _rodar(t, _cena(FalaHistoria(quem: 'voce', en: 'Look!', pt: 'Olha!', segura: p)), reduzir: reduzir);
        if (p == PropHistoria.nada) continue;
        for (final pista in [1, 7, 22, 29, 30]) {
          await _rodar(
            t,
            _cena(
              const FalaHistoria(quem: 'voce', en: 'Look!', pt: 'Olha!'),
              objetos: [ObjetoEmCena(prop: p, pos: PosicaoPalco.centro)],
            ),
            reduzir: reduzir,
            pista: pista,
          );
        }
      }
    });

    testWidgets('Expressao no falante e numa reação$sufixo', (t) async {
      for (final e in Expressao.values) {
        await _rodar(
          t,
          _cena(FalaHistoria(quem: 'voce', en: 'Hi!', pt: 'Oi!', emocao: e, reacoes: [ReacaoHistoria(quem: 'mike', emocao: e)])),
          reduzir: reduzir,
        );
      }
    });

    testWidgets('AcaoAtor (cenas válidas) no falante e em reações$sufixo', (t) async {
      for (final a in AcaoAtor.values) {
        final cena = _cenaDaAcao(a);
        expect(_erros(cena), isEmpty, reason: a.name);
        await _rodar(t, cena, reduzir: reduzir);
        await _rodar(t, cena, reduzir: reduzir, tamanho: const Size(360, 560));
        if (acoesDeReacao.contains(a) && a != AcaoAtor.mostra && a != AcaoAtor.escreve) {
          final r = _cena(FalaHistoria(quem: 'voce', en: 'Hi!', pt: 'Oi!', reacoes: [ReacaoHistoria(quem: 'mike', acao: a)]));
          expect(_erros(r), isEmpty, reason: 'reação ${a.name}');
          await _rodar(t, r, reduzir: reduzir);
        }
      }
      // passo mudo com ação
      final mudo = _cena(const FalaHistoria(quem: 'voce', mudo: true, acao: AcaoAtor.cai, efeito: EfeitoHistoria.estalo));
      expect(_erros(mudo), isEmpty);
      await _rodar(t, mudo, reduzir: reduzir);
    });

    testWidgets('AcaoObjeto (do chão e da mão)$sufixo', (t) async {
      for (final a in AcaoObjeto.values) {
        final cena = _cenaDoObjeto(a);
        expect(_erros(cena), isEmpty, reason: a.name);
        await _rodar(t, cena, reduzir: reduzir);
        if (a != AcaoObjeto.passa && a != AcaoObjeto.aparece && a != AcaoObjeto.entra) {
          final mao = _cenaDoObjeto(a, daMao: true);
          expect(_erros(mao), isEmpty, reason: '${a.name} da mão');
          await _rodar(t, mao, reduzir: reduzir);
        }
      }
      // carro que entra dirigindo
      await _rodar(
        t,
        _cena(const FalaHistoria(
          quem: narrador,
          en: 'A car!',
          pt: 'Um carro!',
          objetos: [MovimentoObjeto(prop: PropHistoria.carroRival, acao: AcaoObjeto.entra, pos: PosicaoPalco.direita)],
        )),
        reduzir: reduzir,
      );
    });

    testWidgets('ViaRemota: rádio (na mão e no carro) e celular$sufixo', (t) async {
      for (final via in ViaRemota.values) {
        final cena = _cena(
          const FalaHistoria(quem: 'sarah', en: 'Can you hear me?', pt: 'Você me ouve?'),
          elenco: [
            AtorEmCena(
              quem: 'voce',
              pos: PosicaoPalco.centro,
              segura: via == ViaRemota.radio ? PropHistoria.radio : PropHistoria.celular,
            ),
            AtorEmCena(quem: 'sarah', remoto: via),
            const AtorEmCena(quem: 'julia', remoto: ViaRemota.celular),
          ],
        );
        expect(_erros(cena).where((e) => e.contains('sarah')), isEmpty, reason: via.name);
        await _rodar(t, cena, reduzir: reduzir);
        await _rodar(t, cena, reduzir: reduzir, tamanho: const Size(360, 560));
      }
      final noCarro = _cena(
        const FalaHistoria(quem: 'mike', en: 'Turn left.', pt: 'Vire à esquerda.'),
        cenario: CenarioHistoria.vale,
        hora: HoraHistoria.amanhecer,
        clima: const [ClimaHistoria.neblina],
        elenco: const [
          AtorEmCena(quem: 'voce', pos: PosicaoPalco.centro, noCarro: true),
          AtorEmCena(quem: 'mike', remoto: ViaRemota.radio),
        ],
      );
      expect(_erros(noCarro), isEmpty);
      await _rodar(t, noCarro, reduzir: reduzir);
    });

    testWidgets('CameraHistoria (no falante, no narrador e na tela estreita)$sufixo', (t) async {
      for (final c in CameraHistoria.values) {
        final alvo = c == CameraHistoria.dupla ? 'mike' : null;
        await _rodar(t, _cena(FalaHistoria(quem: 'voce', en: 'Hi!', pt: 'Oi!', camera: c, alvo: alvo)), reduzir: reduzir);
        await _rodar(
          t,
          _cena(FalaHistoria(quem: 'voce', en: 'Hi!', pt: 'Oi!', camera: c, alvo: alvo)),
          reduzir: reduzir,
          tamanho: const Size(360, 560),
        );
        if (c != CameraHistoria.dupla) {
          await _rodar(t, _cena(FalaHistoria(quem: narrador, en: 'Hi!', pt: 'Oi!', camera: c)), reduzir: reduzir);
        }
      }
    });
  }

  testWidgets('cinco atores na tela de 360 px e no 2560×1080', (t) async {
    final cena = _cena(
      const FalaHistoria(quem: 'ana', en: 'We are a team!', pt: 'Nós somos uma equipe!', acao: AcaoAtor.comemora),
      elenco: const [
        AtorEmCena(quem: 'ana', pos: PosicaoPalco.esquerda),
        AtorEmCena(quem: 'sarah', pos: PosicaoPalco.centroEsquerda),
        AtorEmCena(quem: 'voce', pos: PosicaoPalco.centro),
        AtorEmCena(quem: 'mike', pos: PosicaoPalco.centroDireita),
        AtorEmCena(quem: 'ben', pos: PosicaoPalco.direita),
      ],
    );
    expect(_erros(cena), isEmpty);
    await _rodar(t, cena, tamanho: const Size(360, 560));
    await _rodar(t, cena, tamanho: const Size(2560, 1000));
    // a fórmula de tamanho encolhe para caber entre os vizinhos
    final h = PalcoHistoria.alturaDosAtores(const Size(360, 560), [for (final x in PalcoHistoria.xsEstreito) x * 360]);
    expect(h * .62, lessThanOrEqualTo(.92 * (.18 * 360) + .001));
    expect(h, greaterThanOrEqualTo(84));
    expect(PalcoHistoria.alturaDosAtores(const Size(2560, 1000), const []), 420);
  });
}
