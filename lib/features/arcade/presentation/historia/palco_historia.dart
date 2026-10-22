import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../../ingles/data/voz_ingles.dart';
import '../../../ingles/domain/boca.dart';
import '../../../ingles/domain/expressao.dart';
import '../../../ingles/presentation/widgets/elenco_ingles.dart';
import '../../domain/historia_turismo.dart';
import '../../domain/simulacao_historia.dart';
import 'ator_historia.dart';
import 'balao_fala.dart';
import 'clima_historia.dart';
import 'efeitos_historia.dart';
import 'elenco_turismo.dart';
import 'fundo_historia.dart';
import 'moldura_webcam.dart';
import 'props_historia.dart';
import 'roteiro_historia.dart';
import 'roteiro_visivel.dart';

/// 🎭 O palco do desenho: fundo, clima, objetos, atores, efeitos, balão e legenda, com a câmera.
///
/// Sem estado: cada quadro é calculado do [roteiro] (passo, tempo do passo, estado antes/depois da
/// [SimulacaoCena]) e do [relogio] (idle, clima). Camadas (trás → frente): céu · distante (paralaxe) ·
/// clima traseiro · chão · objetos · atores · clima frontal · efeitos e projéteis — todas sob a câmera — e,
/// por cima, sem câmera: fade da cena, cartão de título, balão e legenda do narrador.
class PalcoHistoria extends StatelessWidget {
  const PalcoHistoria({
    super.key,
    required this.roteiro,
    required this.relogio,
    this.capitulo,
    this.cabecalho,
    this.reduzir = false,
    this.balaoSemCorte = false,
  }) : assert(capitulo != null || cabecalho != null);

  /// O Turismo passa o [RoteiroHistoria]; o 📺 Assistir, o `RoteiroSeguidor`.
  final RoteiroVisivel roteiro;

  /// Segundos do relógio do player (idle, clima, efeitos).
  final double relogio;

  /// O capítulo do Turismo (o cabeçalho sai dele quando não vem [cabecalho]).
  final CapituloHistoria? capitulo;

  /// O cartão de título e a Semantics; null = [CabecalhoPalco.doCapitulo] do [capitulo].
  final CabecalhoPalco? cabecalho;
  final bool reduzir;

  /// 📺 Palco baixo (a faixa do "Tocando agora" no celular): o balão que não cabe na faixa de cima cresce por
  /// cima dos atores em vez de cortar o texto. O Turismo (palco alto) usa o padrão `false`, sem mudança.
  final bool balaoSemCorte;

  /// As 5 posições do palco (fração da largura); na tela estreita (< 560 px), um pouco mais juntas.
  static const xsLargo = [.12, .31, .50, .69, .88];
  static const xsEstreito = [.14, .32, .50, .68, .86];

  /// No retrato (celular em pé): as posições pares (esquerda, centro, direita) são a fila da frente e as
  /// ímpares (centroEsquerda/centroDireita) ficam numa 2ª fila, um pouco atrás e mais alto ([recuoFila]); assim
  /// os atores podem ser bem maiores sem um tampar o rosto do outro.
  static const xsRetrato = [.16, .33, .50, .67, .84];

  /// Quanto a 2ª fila do retrato sobe, em alturas de ator (limitado a 60% do chão visível, ver [_Quadro]).
  static const recuoFila = .35;

  /// Largura abaixo da qual o balão vira faixa no topo e as posições se juntam.
  static const larguraEstreita = 560.0;

  /// Retrato = mais alto que largo: palco em 2 filas e atores maiores ([alturaDosAtores]).
  static bool retrato(Size palco) => palco.height > palco.width;

  /// As 5 posições (fração da largura) para o tamanho do [palco].
  static List<double> xsDo(Size palco) =>
      retrato(palco) ? xsRetrato : (palco.width < larguraEstreita ? xsEstreito : xsLargo);

  /// A altura dos atores para o palco [palco] com as posições [xsOcupados] (px) ocupadas: `clamp(min(.46 alt,
  /// .30 larg), 84, 420)`, encolhida para caber entre os vizinhos (`w = .62 H ≤ .92 × menor distância`).
  /// No [retrato]: `clamp(min(.30 alt, .48 larg), 84, 420)`; vizinhos da mesma fila seguem a regra acima e os de
  /// filas diferentes só precisam de meia largura (`w/2 ≤ .92 × distância`), pois o de trás fica mais alto.
  static double alturaDosAtores(Size palco, List<double> xsOcupados) {
    if (retrato(palco)) return _alturaNoRetrato(palco, xsOcupados);
    var h = math.min(palco.height * .46, palco.width * .30).clamp(84.0, 420.0);
    final xs = xsOcupados.toSet().toList()..sort();
    var menor = double.infinity;
    for (var i = 1; i < xs.length; i++) {
      menor = math.min(menor, xs[i] - xs[i - 1]);
    }
    final w = math.min(AtorHistoria.largura(h), .92 * menor);
    if (w < AtorHistoria.largura(h)) h = math.max(84.0, w / .62);
    return h;
  }

  /// A fila (0 = frente, 1 = trás) da posição mais perto de [x] no retrato.
  static int filaNoRetrato(Size palco, double x) {
    var melhor = 0;
    for (var i = 1; i < xsRetrato.length; i++) {
      if ((xsRetrato[i] * palco.width - x).abs() < (xsRetrato[melhor] * palco.width - x).abs()) melhor = i;
    }
    return melhor.isOdd ? 1 : 0;
  }

  /// 📺 Na `videochamada` cada ator fica na sua moldura de webcam, recortado na cintura (spike, opção b): uma fila
  /// só (sem [recuoFila]; no retrato com 4+ pessoas, 2 filas sem sobrepor) e atores do tamanho que faz as
  /// molduras caberem lado a lado (`largura da moldura ≤ .92 × menor distância`) com a margem de
  /// [margemDaMoldura] acima da cabeça.
  static bool ehChamada(CenarioHistoria c) => c == CenarioHistoria.videochamada;

  /// A folga da moldura acima da cabeça (em alturas de ator): a mão do `acena`/`aponta` não é cortada.
  static const margemDaMoldura = .15;

  /// A largura da moldura / a largura do corpo (o `MolduraWebcamPainter.molduraDe` de um corpo padrão).
  static double _proporcaoDaMoldura() {
    const corpo = Rect.fromLTWH(0, 0, 62, 100);
    return MolduraWebcamPainter.molduraDe(corpo).width / corpo.width;
  }

  /// A moldura de um ator de altura 1 em pé no chão 0: (quanto sobe acima dos pés, a altura dela).
  static (double topo, double altura) _molduraUnitaria() {
    final m = molduraNaChamada(const Rect.fromLTWH(-31, -100, 62, 100), double.infinity);
    return (-m.top / 100, m.height / 100);
  }

  /// No retrato com 4 ou mais lugares, a chamada usa 2 filas: a de trás sobe até a moldura dela ficar inteira
  /// acima das da frente (spike, regra 3); com menos gente, uma fila só.
  static bool duasFilasNaChamada(Size palco, int lugares) => retrato(palco) && lugares >= 4;

  /// Quanto a fila de trás da chamada sobe (px): a altura da moldura + 8 px de vão.
  static double recuoNaChamada(double alturaAtor) => _molduraUnitaria().$2 * alturaAtor + 8;

  /// A altura dos atores na `videochamada`: a regra do palco, encolhida até as molduras vizinhas (da mesma
  /// fila, [menorDistancia] em px) não se encostarem e a moldura mais alta (com a margem de cima e, com
  /// [duasFilas], a fila de trás) caber acima do [chao]. Com [reservaTopo] (px, 📺 numa fila só) a moldura fica
  /// abaixo dessa faixa do topo, onde o balão cabe sem cobrir a cabeça de quem fala.
  static double alturaNaChamada(Size palco, double menorDistancia, double chao,
      {bool duasFilas = false, double reservaTopo = 0}) {
    var h = math.min(palco.height * .46, palco.width * .30).clamp(56.0, 420.0);
    if (retrato(palco)) h = math.min(palco.height * .30, palco.width * .48).clamp(56.0, 420.0);
    final k = _proporcaoDaMoldura();
    if (menorDistancia.isFinite && AtorHistoria.largura(h) * k > .92 * menorDistancia) {
      h = .92 * menorDistancia / k / .62;
    }
    final (topo, altura) = _molduraUnitaria();
    // a moldura inteira dentro do palco, com um respiro de 4 px (com 2 filas, a de trás: + a moldura + 8 px)
    final teto = duasFilas ? (chao - 12) / (topo + altura) : (chao - math.max(4.0, reservaTopo)) / topo;
    h = math.min(h, math.max(24.0, teto));
    return math.max(24.0, h);
  }

  /// A moldura de webcam de um ator cujo corpo ocupa [corpo] (palco), com as regras do 📺: no máximo [maxLargura]
  /// de largura (centrada no ator) e pelo menos [margemDaMoldura] de folga acima da cabeça.
  static Rect molduraNaChamada(Rect corpo, double maxLargura) {
    final m = MolduraWebcamPainter.molduraDe(corpo);
    final w = math.min(m.width, maxLargura);
    final topo = math.min(m.top, corpo.top - corpo.height * margemDaMoldura);
    return Rect.fromLTRB(corpo.center.dx - w / 2, topo, corpo.center.dx + w / 2, math.max(m.bottom, topo + 8));
  }

  static double _alturaNoRetrato(Size palco, List<double> xsOcupados) {
    var h = math.min(palco.height * .30, palco.width * .48).clamp(84.0, 420.0);
    final xs = xsOcupados.toSet().toList()..sort();
    var maxLargura = double.infinity;
    for (var i = 0; i < xs.length; i++) {
      for (var j = i + 1; j < xs.length; j++) {
        final d = xs[j] - xs[i];
        final mesmaFila = filaNoRetrato(palco, xs[i]) == filaNoRetrato(palco, xs[j]);
        maxLargura = math.min(maxLargura, (mesmaFila ? .92 : 1.84) * d);
      }
    }
    if (AtorHistoria.largura(h) > maxLargura) h = math.max(84.0, maxLargura / .62);
    return h;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(
        c.maxWidth.isFinite ? c.maxWidth : 800,
        c.maxHeight.isFinite ? c.maxHeight : 450,
      );
      final cab = cabecalho ?? CabecalhoPalco.doCapitulo(capitulo!);
      final q = _Quadro(
        roteiro: roteiro,
        cabecalho: cab,
        size: size,
        relogio: relogio,
        reduzir: reduzir,
        agora: DateTime.now(),
        fala: VozIngles.falando.value,
        balaoSemCorte: balaoSemCorte,
      );
      return Semantics(
        container: true,
        label: cab.rotuloSemantico,
        child: ClipRect(
          child: SizedBox.fromSize(
            size: size,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(child: Transform(transform: q.matrizCamera, child: q.mundo())),
                ...q.sobreposicoes(context),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Um ator calculado para o quadro.
class _AtorQuadro {
  final String quem;
  final Aparencia aparencia;
  final double x, alpha;
  final PoseAtor pose;
  final bool espelhado;
  final Visema visema;
  final double olhos;
  final Expressao expressao;
  final Offset olhar;
  final PropHistoria? segura, carro;
  final bool falante;

  const _AtorQuadro({
    required this.quem,
    required this.aparencia,
    required this.x,
    required this.alpha,
    required this.pose,
    required this.espelhado,
    required this.visema,
    required this.olhos,
    required this.expressao,
    required this.olhar,
    required this.segura,
    required this.carro,
    required this.falante,
  });
}

/// Um objeto calculado para o quadro (no chão ou em movimento).
class _ObjetoQuadro {
  final PropHistoria prop;
  final Offset centro; // centro da base (pés do objeto), em coordenadas do palco
  final double escala, alpha, giro;

  const _ObjetoQuadro(this.prop, this.centro, {this.escala = 1, this.alpha = 1, this.giro = 0});
}

/// O enquadramento da câmera: [s] = zoom, [foco] = ponto do palco que fica no centro da tela.
class _Enquadro {
  final double s;
  final Offset foco;
  const _Enquadro(this.s, this.foco);

  static _Enquadro lerp(_Enquadro a, _Enquadro b, double k) =>
      _Enquadro(a.s + (b.s - a.s) * k, Offset.lerp(a.foco, b.foco, k)!);
}

/// Tudo o que um quadro do palco precisa, calculado uma vez por build.
class _Quadro {
  _Quadro({
    required this.roteiro,
    required this.cabecalho,
    required this.size,
    required this.relogio,
    required this.reduzir,
    required this.agora,
    required this.fala,
    this.balaoSemCorte = false,
  }) {
    _calcular();
  }

  final bool balaoSemCorte;

  final RoteiroVisivel roteiro;
  final CabecalhoPalco cabecalho;
  final Size size;
  final double relogio;
  final bool reduzir;
  final DateTime agora;

  /// A fala que a voz do app está tocando agora (lip-sync).
  final FalaEmCurso? fala;

  late final EstadoRoteiro estado = roteiro.estadoVisivel;
  late final bool parado = estado == EstadoRoteiro.aguardandoGesto;
  late final bool acabou = estado == EstadoRoteiro.cartaoFinal || estado == EstadoRoteiro.terminado;

  /// O passo em curso (null no gate do "▶ Assistir").
  late final FalaHistoria? passo = parado ? null : roteiro.falaAtual;

  /// Segundos do passo (no fim, "infinito": toda transição já acabou).
  late final double t = parado ? 0 : (acabou ? 99 : roteiro.tPasso);

  late final EstadoCena antes = roteiro.antes;
  late final EstadoCena depois = parado ? roteiro.antes : roteiro.depois;

  late final bool estreito = size.width < PalcoHistoria.larguraEstreita;
  late final double chao = size.height * FundoHistoriaPainter.linhaDoChao(depois.cenario);

  late double alturaAtor;
  late double larguraAtor;

  /// No retrato, quanto a 2ª fila sobe (px); 0 fora do retrato (na `videochamada`, só com 2 filas).
  double recuo = 0;

  /// 📺 A `videochamada`: cada ator na sua moldura de webcam, recortado na cintura.
  late final bool chamada = PalcoHistoria.ehChamada(depois.cenario);

  /// A largura máxima de uma moldura (`.92 ×` a menor distância entre as posições ocupadas).
  double maxMoldura = double.infinity;

  /// 📺 A faixa do topo (px de tela) guardada para o balão na chamada de uma fila só; 0 = nenhuma.
  double reservaBalao = 0;

  /// As molduras da `videochamada`: quem, onde e o quanto está acesa (0 = ainda fora da chamada).
  final molduras = <(String quem, Rect caixa, double acesa)>[];
  final atores = <_AtorQuadro>[];
  final objetos = <_ObjetoQuadro>[];
  final efeitos = <EfeitoAtivo>[];
  final projeteis = <ProjetilAtivo>[];
  final celulares = <(String quem, Rect caixa, Visema visema)>[];
  late _Enquadro camera;
  Offset tremor = Offset.zero;
  double paralaxe = 0;

  /// Onde o balão aponta (palco): a boca do falante ou o rádio/celular; null = narrador/sem âncora.
  Offset? ancoraBalao;

  /// O topo da cabeça do falante (palco), para pôr o balão acima.
  double? topoFalante;
  ViaRemota? via;

  late final List<double> _xs = PalcoHistoria.xsDo(size);

  /// 📺 Na `videochamada` de uma fila só, os lugares do elenco espalhados por igual na largura (sem o vão do
  /// lugar vazio no meio, as molduras crescem); null fora dela. Quem não está no mapa usa [_xs].
  Map<PosicaoPalco, double>? _xsChamada;

  double xDe(PosicaoPalco p) => _xsChamada?[p] ?? size.width * _xs[p.index];

  /// 0 = fila da frente, 1 = fila de trás (retrato), suave entre as posições (quem anda muda de fila aos poucos).
  double profundidade(double x) {
    if (recuo == 0) return 0;
    final w = size.width;
    if (x <= _xs.first * w || x >= _xs.last * w) return 0;
    var i = 0;
    while (i < _xs.length - 2 && x > _xs[i + 1] * w) {
      i++;
    }
    final u = i + (x - _xs[i] * w) / ((_xs[i + 1] - _xs[i]) * w);
    return (1 - math.cos(math.pi * u)) / 2;
  }

  /// Onde pisam os pés de quem está em [x]: a [chao], ou mais alto na 2ª fila do retrato.
  double pe(double x) => chao - recuo * profundidade(x);

  static double _ease(double v) => Curves.easeInOut.transform(v.clamp(0.0, 1.0));

  bool _ehFalante(String quem) => passo != null && passo!.quem == quem;

  /// [quem] fala este passo com `sai`: fica parado no lugar enquanto fala e lê, e sai depois
  /// ([RoteiroHistoria.tSaida]).
  bool _saiDepoisDeFalar(String quem) {
    final f = passo;
    return f != null && f.quem == quem && RoteiroHistoria.saiDepoisDeFalar(f);
  }

  AcaoAtor _acaoDe(String quem) {
    final f = passo;
    if (f == null) return AcaoAtor.parado;
    if (f.quem == quem) return f.acao;
    for (final r in f.reacoes) {
      if (r.quem == quem && r.acao != null) return r.acao!;
    }
    return AcaoAtor.parado;
  }

  // ───────────────────────── cálculo

  void _calcular() {
    final ocupados = <double>[
      for (final e in [antes, depois])
        for (final a in e.atores.values)
          if (a.noPalco && a.pos != null) xDe(a.pos!),
    ];
    if (chamada) {
      // todos os lugares do elenco (também quem ainda não entrou: a moldura apagada já está lá)
      final posicoes = <PosicaoPalco>{
        for (final e in [antes, depois])
          for (final a in e.atores.values)
            if (a.pos != null && (a.noPalco || !a.ehRemoto)) a.pos!,
      };
      final duas = PalcoHistoria.duasFilasNaChamada(size, posicoes.length);
      if (!duas && posicoes.isNotEmpty) {
        // uma fila: as molduras dividem a largura por igual, na ordem dos lugares
        final ordem = posicoes.toList()..sort((a, b) => a.index.compareTo(b.index));
        _xsChamada = {for (var i = 0; i < ordem.length; i++) ordem[i]: size.width * (i + .5) / ordem.length};
      }
      final lugares = <double>{for (final p in posicoes) xDe(p)}.toList()..sort();
      var menor = double.infinity;
      for (var i = 0; i < lugares.length; i++) {
        for (var j = i + 1; j < lugares.length; j++) {
          final mesmaFila = !duas ||
              PalcoHistoria.filaNoRetrato(size, lugares[i]) == PalcoHistoria.filaNoRetrato(size, lugares[j]);
          if (mesmaFila) menor = math.min(menor, (lugares[j] - lugares[i]).abs());
        }
      }
      // as molduras das pontas também não encostam na borda do palco (4 px)
      if (lugares.isNotEmpty) {
        final borda = math.min(lugares.first, size.width - lugares.last) - 4;
        if (borda > 0) menor = math.min(menor, 2 * borda / .92);
      }
      maxMoldura = menor.isFinite ? .92 * menor : size.width * .9;
      // 📺 numa fila só: uma faixa no topo para o balão (o palco baixo do celular deitado não cobre a cabeça)
      final reserva = balaoSemCorte && !duas
          ? math.min(size.height * .36, 112 * (size.width / 1280).clamp(1.0, 1.4))
          : 0.0;
      reservaBalao = reserva;
      alturaAtor = PalcoHistoria.alturaNaChamada(size, menor, chao, duasFilas: duas, reservaTopo: reserva);
      larguraAtor = AtorHistoria.largura(alturaAtor);
      if (duas) recuo = PalcoHistoria.recuoNaChamada(alturaAtor);
      _calcularAtores();
      _calcularMolduras();
      _calcularObjetos();
      _calcularRemotos();
      _calcularEfeitos();
      _calcularCamera();
      return;
    }
    alturaAtor = PalcoHistoria.alturaDosAtores(size, ocupados);
    larguraAtor = AtorHistoria.largura(alturaAtor);
    if (PalcoHistoria.retrato(size)) {
      final cen = depois.cenario;
      final chaoVisivel = size.height * (FundoHistoriaPainter.linhaDoChao(cen) - FundoHistoriaPainter.horizonte(cen));
      recuo = math.max(0.0, math.min(alturaAtor * PalcoHistoria.recuoFila, chaoVisivel * .6));
    }
    _calcularAtores();
    _calcularObjetos();
    _calcularRemotos();
    _calcularEfeitos();
    _calcularCamera();
  }

  /// Posição x do ator [quem] agora (interpolada) e se está visível.
  (double x, double alpha, bool andando, bool paraEsquerda)? _xDoAtor(String quem) {
    final a = antes.atores[quem], d = depois.atores[quem];
    if (a == null || d == null || d.ehRemoto) return null;
    final acao = _acaoDe(quem);
    final xa = a.pos == null ? null : xDe(a.pos!);
    final xd = d.pos == null ? null : xDe(d.pos!);
    final margem = larguraAtor * .8;
    if (chamada) {
      // na chamada ninguém anda pelo palco: entrar e sair acendem e apagam a câmera, no lugar
      final dur = SimulacaoCena.duracaoDe(acao) ?? .9;
      final p = reduzir ? 1.0 : (t / dur).clamp(0.0, 1.0);
      if (!a.noPalco && d.noPalco && xd != null) {
        return (xd, acao == AcaoAtor.entra ? p : 1, false, false);
      }
      if (a.noPalco && !d.noPalco) {
        if (xa == null || acabou || (acao == AcaoAtor.sai && p >= 1) || acao != AcaoAtor.sai) return null;
        return (xa, 1 - p, false, false);
      }
      if (!d.noPalco) return null;
      final x1 = xd ?? xa;
      return x1 == null ? null : (x1, 1, false, false);
    }
    if (!a.noPalco && d.noPalco && acao == AcaoAtor.entra && xd != null) {
      final borda = xd < size.width / 2 ? -margem : size.width + margem;
      final p = reduzir ? 1.0 : (t / (SimulacaoCena.duracaoDe(acao) ?? .9)).clamp(0.0, 1.0);
      return (borda + (xd - borda) * _ease(p), 1, p < 1, borda > xd);
    }
    if (a.noPalco && !d.noPalco) {
      if (acao != AcaoAtor.sai || xa == null || acabou) return null;
      var tSai = t;
      if (_saiDepoisDeFalar(quem)) {
        // fala primeiro, no lugar (com reduzir, fica até o passo acabar)
        final ts = roteiro.tSaida;
        if (ts == null || reduzir) return (xa, 1, false, a.olhaParaEsquerda);
        tSai = ts;
      } else if (reduzir) {
        return null;
      }
      final borda = xa < size.width / 2 ? -margem : size.width + margem;
      final p = (tSai / (SimulacaoCena.duracaoDe(acao) ?? .9)).clamp(0.0, 1.0);
      if (p >= 1) return null;
      return (xa + (borda - xa) * _ease(p), 1, true, borda < xa);
    }
    if (!d.noPalco) return null;
    final x1 = xd ?? xa;
    if (x1 == null) return null;
    if ((acao == AcaoAtor.anda || acao == AcaoAtor.corre) && xa != null && xa != x1) {
      final p = reduzir ? 1.0 : (t / (SimulacaoCena.duracaoDe(acao) ?? .9)).clamp(0.0, 1.0);
      return (xa + (x1 - xa) * _ease(p), 1, p < 1, x1 < xa);
    }
    if (acao == AcaoAtor.abraca && !reduzir) {
      final alvo = passo?.alvo;
      final xAlvo = alvo == null ? null : _posAlvo(alvo)?.dx;
      if (xAlvo != null) {
        final p = (t / (SimulacaoCena.duracaoDe(acao) ?? 1)).clamp(0.0, 1.0);
        return (x1 + math.sin(math.pi * p) * .35 * (xAlvo - x1), 1, false, false);
      }
    }
    return (x1, 1, false, false);
  }

  /// Onde está o alvo (ator ou objeto) — no estado depois.
  Offset? _posAlvo(String alvo) {
    final a = depois.atores[alvo];
    if (a != null) {
      if (!a.noPalco || a.pos == null) return null;
      final x = xDe(a.pos!);
      return Offset(x, pe(x) - alturaAtor * .55);
    }
    for (final o in depois.objetos) {
      if (o.visivel && o.prop.name == alvo && o.pos != null) {
        final tam = PropPainter.tamanho(o.prop, alturaAtor);
        final x = xDe(o.pos!);
        return Offset(x, pe(x) - tam.height * .5);
      }
    }
    return null;
  }

  static int _hash(String s) => s.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0x7fffffff);

  double _olhosPiscando(String quem) {
    if (reduzir) return 1;
    final h = _hash(quem);
    final periodo = 2.6 + (h % 29) / 10; // 2.6–5.4 s
    final fase = (relogio + (h % 97) / 13) % periodo;
    return fase < .14 ? .08 : 1;
  }

  static final _trilhas = <String, TrilhaBoca>{};

  /// A boca pelo texto (sem voz): a trilha da fala no segundo [tFala].
  static Visema _bocaDoTexto(String en, double tFala) {
    final trilha = _trilhas[en] ??= TrilhaBoca.doTexto(en, segPorPalavra: VozIngles.segPorPalavra);
    if (_trilhas.length > 24) _trilhas.remove(_trilhas.keys.first);
    return trilha.em(tFala);
  }

  /// O visema de quem fala o passo atual (ator no palco ou rostinho no celular).
  Visema _visemaDoFalante() {
    final f = passo;
    final en = f?.en;
    if (f == null || en == null || acabou) return Visema.x;
    if (estado != EstadoRoteiro.falando && estado != EstadoRoteiro.lendo) return Visema.x;
    final fc = fala;
    if (fc != null && fc.frase == en) return fc.visema(agora);
    final tf = roteiro.tFala;
    if (tf == null) return Visema.x;
    if (roteiro.falaComVoz && estado != EstadoRoteiro.falando) return Visema.x;
    return _bocaDoTexto(en, tf);
  }

  void _calcularAtores() {
    final visemaFalante = _visemaDoFalante();
    final xFalante = () {
      final f = passo;
      if (f == null) return null;
      final r = _xDoAtor(f.quem);
      return r?.$1;
    }();
    final lista = <_AtorQuadro>[];
    for (final id in depois.atores.keys) {
      final d = depois.atores[id]!;
      final a = antes.atores[id] ?? d;
      if (d.ehRemoto) continue;
      final ap = ElencoTurismo.de(id);
      if (ap == null) continue;
      final px = _xDoAtor(id);
      if (px == null) continue;
      final (x, alpha, andando, paraEsquerda) = px;
      final acaoDoPasso = _acaoDe(id);
      var acao = acaoDoPasso;
      // quem fala e depois sai: parado enquanto fala; a andança conta do começo da saída
      final saiDepois = _saiDepoisDeFalar(id);
      final tAcao = saiDepois ? (roteiro.tSaida ?? 0) : t;
      if (saiDepois && (roteiro.tSaida == null || reduzir)) acao = AcaoAtor.parado;
      final dur = SimulacaoCena.duracaoDe(acao);
      var prog = dur == null ? (tAcao / .6).clamp(0.0, 1.0) : (tAcao / dur).clamp(0.0, 1.0);
      if (reduzir) {
        // sem pulo/queda/rodopio: a pose final por 400 ms
        prog = 1;
        if (dur != null && t >= .4) acao = AcaoAtor.parado;
      } else if (dur != null && tAcao >= dur && acao != AcaoAtor.senta && acao != AcaoAtor.dirige) {
        acao = AcaoAtor.parado;
      }
      if (acabou) acao = AcaoAtor.parado;
      final falante = _ehFalante(id);
      final falandoAgora = falante &&
          (estado == EstadoRoteiro.falando || (estado == EstadoRoteiro.lendo && visemaFalante != Visema.x));
      final noCarro = acaoDoPasso == AcaoAtor.sai ? a.noCarro : d.noCarro;
      PropHistoria? carro;
      if (noCarro) {
        carro = depois.objetos.where((o) => o.absorvidoPor == id).firstOrNull?.prop ??
            antes.objetos.where((o) => o.absorvidoPor == id).firstOrNull?.prop ??
            ElencoTurismo.carroDe(id);
      }
      final espelhado = andando ? paraEsquerda : (acaoDoPasso == AcaoAtor.sai ? a : d).olhaParaEsquerda;
      var olhar = Offset.zero;
      if (!falante && xFalante != null && (xFalante - x).abs() > 4) {
        olhar = Offset((xFalante > x ? .5 : -.5) * (espelhado ? -1 : 1), 0);
      }
      lista.add(_AtorQuadro(
        quem: id,
        aparencia: ap,
        x: x,
        alpha: alpha,
        pose: PoseAtor(
          acao: andando && acao == AcaoAtor.parado ? AcaoAtor.anda : acao,
          progresso: prog,
          tempo: reduzir ? 0 : relogio + (_hash(id) % 11) / 7,
          sentado: d.sentado,
          dormindo: d.dormindo,
          noCarro: noCarro,
          falando: falandoAgora,
        ),
        espelhado: espelhado,
        visema: falante ? visemaFalante : Visema.x,
        olhos: d.dormindo ? .05 : _olhosPiscando(id),
        expressao: d.emocao,
        olhar: olhar,
        segura: noCarro ? null : d.segura,
        carro: carro,
        falante: falante,
      ));
    }
    // a fila de trás primeiro (retrato), depois por posição (esquerda → direita); quem fala vem na frente
    lista.sort((p, q) {
      if (p.falante != q.falante) return p.falante ? 1 : -1;
      final fila = profundidade(q.x).compareTo(profundidade(p.x));
      if (fila != 0) return fila;
      return p.x.compareTo(q.x);
    });
    atores.addAll(lista);

    // âncora do balão de quem fala no palco
    final f = passo;
    if (f != null && !f.ehNarrador) {
      final at = lista.where((x) => x.quem == f.quem).firstOrNull;
      if (at != null) {
        final topo = pe(at.x) - alturaAtor * (at.pose.noCarro ? .78 : (at.pose.sentado ? .82 : 1.0));
        final boca = AtorHistoria.boca(alturaAtor);
        final bx = at.espelhado ? larguraAtor - boca.dx : boca.dx;
        ancoraBalao = Offset(at.x - larguraAtor / 2 + bx, topo + boca.dy * (at.pose.noCarro ? .78 : 1));
        topoFalante = topo;
      }
    }
  }

  /// 📺 As molduras de webcam da `videochamada`: uma por lugar do elenco (não remoto), atrás do ator; acesa com
  /// quem está na chamada (o `entra` acende junto com o esmaecer do ator).
  void _calcularMolduras() {
    final vistos = <String>{};
    for (final e in [depois, antes]) {
      for (final a in e.atores.values) {
        if (a.ehRemoto || a.pos == null || !vistos.add(a.quem)) continue;
        final x = xDe(depois.atores[a.quem]?.pos ?? a.pos!);
        final corpo = Rect.fromLTWH(x - larguraAtor / 2, pe(x) - alturaAtor, larguraAtor, alturaAtor);
        final at = atores.where((q) => q.quem == a.quem).firstOrNull;
        molduras.add((a.quem, PalcoHistoria.molduraNaChamada(corpo, maxMoldura), at?.alpha ?? 0));
      }
    }
  }

  /// Os objetos no chão e os que estão se mexendo neste passo.
  void _calcularObjetos() {
    final f = passo;
    final movs = List<MovimentoObjeto?>.of(f?.objetos ?? const []);
    final h = alturaAtor;
    Offset base(PosicaoPalco p) => Offset(xDe(p), pe(xDe(p)) + h * .03);
    double bordaMaisPerto(double x, Size tam) => x < size.width / 2 ? -tam.width : size.width + tam.width;

    MovimentoObjeto? pegaMov(PropHistoria prop, bool Function(MovimentoObjeto) ok) {
      for (var i = 0; i < movs.length; i++) {
        final m = movs[i];
        if (m != null && m.prop == prop && ok(m)) {
          movs[i] = null;
          return m;
        }
      }
      return null;
    }

    for (var i = 0; i < depois.objetos.length; i++) {
      final d = depois.objetos[i];
      final a = i < antes.objetos.length ? antes.objetos[i] : null;
      final tam = PropPainter.tamanho(d.prop, h);
      final visA = a != null && a.visivel, visD = d.visivel;
      final posD = d.pos ?? a?.pos;
      if (posD == null) continue;
      final alvoBase = base(posD);
      if (!visA && visD) {
        // apareceu: movimento aparece/entra/roda/treme (de uma mão) ou desce do carro
        final m = pegaMov(d.prop, (m) => true);
        final dur = m == null ? .6 : RoteiroHistoria.duracaoObjeto(m.acao);
        final p = reduzir ? 1.0 : (t / dur).clamp(0.0, 1.0);
        final de = m?.de == null ? null : _maoDe(m!.de!, antes);
        if (m != null && m.acao == AcaoObjeto.entra && de == null) {
          final bx = bordaMaisPerto(alvoBase.dx, tam);
          objetos.add(_ObjetoQuadro(d.prop, Offset(bx + (alvoBase.dx - bx) * _ease(p), alvoBase.dy)));
        } else if (de != null) {
          final arco = math.sin(math.pi * p) * h * .3;
          final pt = Offset.lerp(de, alvoBase, _ease(p))! - Offset(0, arco);
          objetos.add(_ObjetoQuadro(d.prop, pt, giro: m!.acao == AcaoObjeto.roda ? p * 2 * math.pi : 0));
        } else if (m != null && m.acao == AcaoObjeto.aparece) {
          objetos.add(_ObjetoQuadro(d.prop, alvoBase, escala: Curves.elasticOut.transform(p).clamp(0.0, 1.3)));
        } else {
          objetos.add(_ObjetoQuadro(d.prop, alvoBase, alpha: p));
        }
        continue;
      }
      if (visA && !visD) {
        // sumiu: some/sai/voa, ou entrou no carro (dirige)
        final posA = a.pos ?? posD;
        final b = base(posA);
        final m = pegaMov(d.prop, (m) => m.de == null);
        if (reduzir || acabou) continue;
        if (m == null) {
          final p = (t / .5).clamp(0.0, 1.0);
          if (p < 1) objetos.add(_ObjetoQuadro(d.prop, b, alpha: 1 - p));
          continue;
        }
        final p = (t / RoteiroHistoria.duracaoObjeto(m.acao)).clamp(0.0, 1.0);
        if (p >= 1) continue;
        switch (m.acao) {
          case AcaoObjeto.sai:
            final bx = bordaMaisPerto(b.dx, tam);
            objetos.add(_ObjetoQuadro(d.prop, Offset(b.dx + (bx - b.dx) * _ease(p), b.dy)));
          case AcaoObjeto.voa:
            objetos.add(_voando(d.prop, b, p, tam));
          default:
            objetos.add(_ObjetoQuadro(d.prop, b, alpha: 1 - p));
        }
        continue;
      }
      if (!visD) continue;
      // parado no chão (talvez rodando ou tremendo)
      final m = pegaMov(d.prop, (m) => m.de == null && (m.acao == AcaoObjeto.roda || m.acao == AcaoObjeto.treme));
      var c = alvoBase;
      var giro = 0.0;
      if (m != null && !reduzir && !acabou) {
        final p = (t / RoteiroHistoria.duracaoObjeto(m.acao)).clamp(0.0, 1.0);
        if (m.acao == AcaoObjeto.roda) giro = _ease(p) * 2 * math.pi;
        if (m.acao == AcaoObjeto.treme && p < 1) c += Offset(math.sin(t * 60) * h * .02, 0);
      }
      if (a != null && a.pos != null && a.pos != d.pos && !reduzir) {
        final p = (t / .6).clamp(0.0, 1.0);
        c = Offset.lerp(base(a.pos!), alvoBase, _ease(p))!;
      }
      objetos.add(_ObjetoQuadro(d.prop, c, giro: giro));
    }

    // os de passagem: `passa` e o que sai voando/saindo da mão de alguém
    if (reduzir || acabou || f == null) return;
    for (final m in movs) {
      if (m == null) continue;
      final tam = PropPainter.tamanho(m.prop, h);
      final p = (t / RoteiroHistoria.duracaoObjeto(m.acao)).clamp(0.0, 1.0);
      if (p >= 1) continue;
      if (m.acao == AcaoObjeto.passa) {
        final x0 = -tam.width, x1 = size.width + tam.width;
        objetos.add(_ObjetoQuadro(m.prop, Offset(x0 + (x1 - x0) * p, chao + h * .05)));
        continue;
      }
      final de = m.de == null ? null : _maoDe(m.de!, antes);
      if (de == null) continue;
      switch (m.acao) {
        case AcaoObjeto.voa:
          objetos.add(_voando(m.prop, de, p, tam));
        case AcaoObjeto.sai:
          final bx = bordaMaisPerto(de.dx, tam);
          objetos.add(_ObjetoQuadro(m.prop, Offset(de.dx + (bx - de.dx) * _ease(p), de.dy)));
        default:
          objetos.add(_ObjetoQuadro(m.prop, de, alpha: 1 - p));
      }
    }
  }

  _ObjetoQuadro _voando(PropHistoria prop, Offset de, double p, Size tam) {
    final dir = de.dx < size.width / 2 ? 1.0 : -1.0;
    final x = de.dx + dir * p * size.width * .45;
    final y = de.dy - p * (de.dy + tam.height * 1.5) + math.sin(p * math.pi * 3) * tam.height * .2;
    return _ObjetoQuadro(prop, Offset(x, y), giro: p * 3 * math.pi);
  }

  /// A mão (palco) de um ator no estado [e], para objetos que partem dela.
  Offset? _maoDe(String quem, EstadoCena e) {
    final a = e.atores[quem];
    if (a == null || !a.noPalco || a.pos == null) return null;
    final x = xDe(a.pos!);
    final mao = AtorHistoria.mao(alturaAtor);
    final mx = a.olhaParaEsquerda ? larguraAtor - mao.dx : mao.dx;
    return Offset(x - larguraAtor / 2 + mx, pe(x) - alturaAtor + mao.dy);
  }

  /// Rostinhos no celular (remotos `celular`) e a âncora das falas remotas.
  void _calcularRemotos() {
    final f = passo;
    final remotos = depois.atores.values.where((a) => a.ehRemoto).toList();
    if (remotos.isEmpty) return;
    _AtorQuadro? ancoraDe(ViaRemota v) {
      for (final at in atores) {
        final e = depois.atores[at.quem];
        if (e == null) continue;
        if (v == ViaRemota.celular && e.segura == PropHistoria.celular) return at;
        if (v == ViaRemota.radio && (e.segura == PropHistoria.radio || e.noCarro)) return at;
      }
      return null;
    }

    final cel = ancoraDe(ViaRemota.celular);
    final faces = remotos.where((r) => r.remoto == ViaRemota.celular).toList();
    if (cel != null && faces.isNotEmpty) {
      final tamTela = Size(alturaAtor * .3, alturaAtor * .5);
      for (var i = 0; i < faces.length; i++) {
        final lado = cel.x > size.width * .6 ? -1.0 : 1.0;
        var left = cel.x + lado * (larguraAtor * .45 + i * (tamTela.width + 6)) - (lado < 0 ? tamTela.width : 0);
        left = left.clamp(4.0, math.max(4.0, size.width - tamTela.width - 4));
        final top = (pe(cel.x) - alturaAtor * 1.02).clamp(4.0, size.height);
        final fala = f != null && f.quem == faces[i].quem;
        celulares.add((faces[i].quem, Rect.fromLTWH(left, top, tamTela.width, tamTela.height),
            fala ? _visemaDoFalante() : Visema.x));
      }
    }

    if (f == null) return;
    final rem = depois.atores[f.quem];
    if (rem == null || !rem.ehRemoto) return;
    via = rem.remoto;
    if (via == ViaRemota.celular) {
      final c = celulares.where((c) => c.$1 == f.quem).firstOrNull;
      if (c != null) {
        ancoraBalao = c.$2.topCenter;
        topoFalante = c.$2.top;
        return;
      }
    }
    final at = ancoraDe(via!);
    if (at != null) {
      final mao = AtorHistoria.mao(alturaAtor);
      final mx = at.espelhado ? larguraAtor - mao.dx : mao.dx;
      final chaoAt = pe(at.x);
      final topo = chaoAt - alturaAtor * (at.pose.noCarro ? .78 : 1.0);
      ancoraBalao = at.pose.noCarro
          ? Offset(at.x, chaoAt - alturaAtor * .45)
          : Offset(at.x - larguraAtor / 2 + mx, chaoAt - alturaAtor + mao.dy);
      topoFalante = topo;
    }
  }

  void _calcularEfeitos() {
    final f = passo;
    if (f == null || acabou || t > 2.6) return;
    Offset? cabeca(String quem) {
      final at = atores.where((a) => a.quem == quem).firstOrNull;
      if (at == null) return null;
      return Offset(at.x, pe(at.x) - alturaAtor * (at.pose.noCarro ? .85 : 1.06));
    }

    final centro = Offset(size.width / 2, size.height * .28);
    Offset origem(EfeitoHistoria e, String quem) {
      switch (e) {
        case EfeitoHistoria.confete || EfeitoHistoria.fogos || EfeitoHistoria.estrelaCadente || EfeitoHistoria.relampago:
          return centro;
        case EfeitoHistoria.fumaca:
          final at = atores.where((a) => a.quem == quem).firstOrNull;
          final x0 = at?.x ?? size.width / 2;
          _ObjetoQuadro? perto;
          for (final o in objetos) {
            if (perto == null || (o.centro.dx - x0).abs() < (perto.centro.dx - x0).abs()) perto = o;
          }
          if (at != null && at.pose.noCarro) return Offset(at.x, pe(at.x) - alturaAtor * .2);
          if (perto != null) return perto.centro - Offset(0, alturaAtor * .15);
          return at == null ? Offset(size.width / 2, chao - alturaAtor * .3) : Offset(at.x, pe(at.x) - alturaAtor * .3);
        case EfeitoHistoria.estalo:
          final at = atores.where((a) => a.quem == quem).firstOrNull;
          return at == null ? centro : Offset(at.x, pe(at.x) - alturaAtor * .5);
        default:
          return cabeca(quem) ?? centro;
      }
    }

    if (f.efeito != null) efeitos.add(EfeitoAtivo(f.efeito!, origem(f.efeito!, f.quem), 0));
    for (final r in f.reacoes) {
      if (r.efeito != null) efeitos.add(EfeitoAtivo(r.efeito!, origem(r.efeito!, r.quem), 0));
    }
    if (f.acao == AcaoAtor.arremessa && f.alvo != null) {
      final de = _maoDe(f.quem, depois);
      final para = _posAlvo(f.alvo!);
      if (de != null && para != null) {
        final neve = depois.cenario == CenarioHistoria.neve || depois.cenario == CenarioHistoria.lago;
        // o projétil já desenha o respingo e o estalo no alvo ao pousar (sem um 2º estalo aqui)
        projeteis.add(ProjetilAtivo(de, para, .25, neve: neve));
      }
    }
  }

  /// Onde está o falante agora (para a câmera).
  Offset? _focoDoFalante(FalaHistoria? f, {double altura = .6}) {
    if (f == null || f.ehNarrador) return null;
    final at = atores.where((a) => a.quem == f.quem).firstOrNull;
    if (at != null) return Offset(at.x, pe(at.x) - alturaAtor * altura);
    if (ancoraBalao != null && f == passo) return ancoraBalao;
    return null;
  }

  _Enquadro _enquadrar(CameraHistoria cam, FalaHistoria? f, double tf) {
    final w = size.width, h = size.height;
    final centro = Offset(w / 2, h / 2);
    switch (cam) {
      case CameraHistoria.geral || CameraHistoria.tremida:
        return _Enquadro(1, centro);
      case CameraHistoria.medio:
        final p = _focoDoFalante(f, altura: .62);
        return p == null ? _Enquadro(1, centro) : _Enquadro(1.25, p);
      case CameraHistoria.close:
        final p = _focoDoFalante(f, altura: .8);
        return p == null ? _Enquadro(1.15, centro) : _Enquadro(1.6, p);
      case CameraHistoria.dupla:
        final p = _focoDoFalante(f, altura: .6);
        final alvo = f?.alvo == null ? null : _posAlvo(f!.alvo!);
        if (p == null || alvo == null) return _Enquadro(1, centro);
        final dx = (p.dx - alvo.dx).abs() + larguraAtor * 1.4;
        final s = (w * .9 / dx).clamp(1.0, 1.4);
        return _Enquadro(s, Offset((p.dx + alvo.dx) / 2, (pe(p.dx) + pe(alvo.dx)) / 2 - alturaAtor * .6));
      case CameraHistoria.panoramica:
        if (reduzir) return _Enquadro(1, centro);
        final k = (tf / 7).clamp(0.0, 1.0);
        return _Enquadro(1.1, Offset(w * (.44 + .12 * k), h / 2));
      case CameraHistoria.aproxima:
        final p = _focoDoFalante(f, altura: .7) ?? centro;
        final k = reduzir ? 1.0 : Curves.easeInOut.transform((tf / 3.5).clamp(0.0, 1.0));
        return _Enquadro(1 + .3 * k, Offset.lerp(centro, p, k)!);
    }
  }

  _Enquadro _limitar(_Enquadro e) {
    final w = size.width, h = size.height;
    var s = math.max(1.0, e.s);
    var fx = e.foco.dx;
    if (chamada && s > 1 && molduras.isNotEmpty) {
      // 📺 o zoom na chamada nunca corta uma moldura de webcam na borda (o app de chamada não dá zoom):
      // a câmera só se aproxima até caber todas as molduras na largura, e fica centrada nelas.
      final esq = molduras.map((m) => m.$2.left).reduce(math.min) - 6;
      final dir = molduras.map((m) => m.$2.right).reduce(math.max) + 6;
      s = math.min(s, math.max(1.0, w / (dir - esq)));
      final meia = w / (2 * s);
      fx = dir - esq >= 2 * meia ? (esq + dir) / 2 : fx.clamp(dir - meia, esq + meia);
    }
    final mx = w / (2 * s), my = h / (2 * s);
    var fy = e.foco.dy;
    if (reservaBalao > 0 && s > 1 && molduras.isNotEmpty) {
      // 📺 o zoom na chamada não sobe as molduras para dentro da faixa do balão
      final topo = molduras.map((m) => m.$2.top).reduce(math.min);
      fy = math.min(fy, topo - (reservaBalao - h / 2) / s);
    }
    return _Enquadro(s, Offset(fx.clamp(mx, w - mx), fy.clamp(my, h - my)));
  }

  void _calcularCamera() {
    final f = passo;
    final atual = parado ? CameraHistoria.geral : depois.camera;
    final cur = _limitar(_enquadrar(atual, f, t));
    if (parado || acabou || reduzir) {
      camera = cur;
    } else {
      final anterior = roteiro.passo == 0 ? CameraHistoria.geral : antes.camera;
      final prev = _limitar(_enquadrar(anterior, roteiro.falaAnterior, 99));
      final k = Mixart.spring.transform((t / .6).clamp(0.0, 1.0));
      camera = _limitar(_Enquadro.lerp(prev, cur, k));
    }
    if (atual == CameraHistoria.panoramica && !reduzir && !parado) paralaxe = (t / 7).clamp(0.0, 1.0);
    if (atual == CameraHistoria.tremida && !reduzir && !parado && !acabou && t < .4) {
      final amp = (1 - t / .4) * math.max(3.0, size.shortestSide * .012);
      tremor = Offset(math.sin(t * 73) * amp, math.cos(t * 59) * amp * .7);
    }
    // a tremida do relâmpago (zero com reduzir)
    tremor += EfeitoHistoriaLayer.tremor(efeitos, t, reduzir: reduzir);
  }

  Matrix4 get matrizCamera {
    final c = Offset(size.width / 2, size.height / 2) + tremor;
    return Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(camera.s, camera.s, 1, 1)
      ..translateByDouble(-camera.foco.dx, -camera.foco.dy, 0, 1);
  }

  /// Ponto do palco → tela (depois da câmera).
  Offset naTela(Offset p) =>
      (p - camera.foco) * camera.s + Offset(size.width / 2, size.height / 2) + tremor;

  // ───────────────────────── widgets

  Widget _fundo(CenarioHistoria cenario, HoraHistoria hora, {required bool comClimaTraseiro}) {
    CustomPaint camada(CamadaFundo c, {double paralaxe = 0}) => CustomPaint(
          size: size,
          painter: FundoHistoriaPainter(cenario: cenario, hora: hora, camada: c, t: reduzir ? 0 : relogio, paralaxe: paralaxe),
        );
    return Stack(children: [
      Positioned.fill(child: RepaintBoundary(child: camada(CamadaFundo.ceu))),
      Positioned.fill(child: RepaintBoundary(child: camada(CamadaFundo.distante, paralaxe: paralaxe))),
      if (comClimaTraseiro)
        Positioned.fill(
          child: CustomPaint(
            painter: ClimaHistoriaPainter(
              clima: depois.clima,
              frente: false,
              t: relogio,
              hora: hora,
              cenario: cenario,
              estatico: reduzir,
            ),
          ),
        ),
      Positioned.fill(child: RepaintBoundary(child: camada(CamadaFundo.chao))),
    ]);
  }

  /// As camadas 1–8 (sob a câmera).
  Widget mundo() {
    final mudouFundo = antes.cenario != depois.cenario || antes.hora != depois.hora;
    final fade = !parado && !acabou && !reduzir && mudouFundo && t < .4;
    final h = alturaAtor;
    return SizedBox.fromSize(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _fundo(depois.cenario, depois.hora, comClimaTraseiro: true)),
          if (fade)
            Positioned.fill(
              child: Opacity(
                opacity: 1 - t / .4,
                child: _fundo(antes.cenario, antes.hora, comClimaTraseiro: false),
              ),
            ),
          // sombras + objetos, depois os atores; no retrato, a fila de trás (objetos e atores) vem antes da da frente
          for (final m in molduras) ..._moldura(m),
          for (final o in objetos)
            if (_objetoAtras(o)) _objeto(o),
          for (final a in atores)
            if (_atorAtras(a)) ..._ator(a, h),
          for (final o in objetos)
            if (!_objetoAtras(o)) _objeto(o),
          for (final a in atores)
            if (!_atorAtras(a)) ..._ator(a, h),
          // rostinhos no celular
          for (final c in celulares) _celular(c),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ClimaHistoriaPainter(
                  clima: depois.clima,
                  frente: true,
                  t: relogio,
                  hora: depois.hora,
                  cenario: depois.cenario,
                  estatico: reduzir,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: EfeitoHistoriaLayer(efeitos: efeitos, projeteis: projeteis, t: t, reduzir: reduzir),
            ),
          ),
        ],
      ),
    );
  }

  /// Na fila de trás do retrato (o que passa pelo chão da frente, não).
  bool _objetoAtras(_ObjetoQuadro o) => recuo > 0 && o.centro.dy < chao && profundidade(o.centro.dx) >= .5;

  /// Na fila de trás do retrato; quem fala fica sempre na frente.
  bool _atorAtras(_AtorQuadro a) => recuo > 0 && !a.falante && profundidade(a.x) >= .5;

  Widget _objeto(_ObjetoQuadro o) {
    final tam = PropPainter.tamanho(o.prop, alturaAtor);
    if (tam.isEmpty) return const SizedBox.shrink();
    Widget w = CustomPaint(
      size: tam,
      painter: PropPainter(prop: o.prop, t: reduzir ? 0 : relogio, capitulo: cabecalho.pinturaCarro),
    );
    if (o.giro != 0) w = Transform.rotate(angle: o.giro, child: w);
    if (o.escala != 1) w = Transform.scale(scale: o.escala, alignment: Alignment.bottomCenter, child: w);
    if (o.alpha < 1) w = Opacity(opacity: o.alpha.clamp(0.0, 1.0), child: w);
    return Positioned(
      left: o.centro.dx - tam.width / 2,
      top: o.centro.dy - tam.height,
      width: tam.width,
      height: tam.height,
      child: IgnorePointer(child: w),
    );
  }

  List<Widget> _ator(_AtorQuadro a, double h) {
    if (chamada) return _atorNaChamada(a, h);
    final w = larguraAtor;
    final sombraW = a.pose.noCarro ? w * 1.5 : w * .8;
    final chao = pe(a.x);
    return [
      Positioned(
        left: a.x - sombraW / 2,
        top: chao - h * .035,
        width: sombraW,
        height: h * .07,
        child: const IgnorePointer(child: _Sombra()),
      ),
      Positioned(
        left: a.x - w / 2,
        top: chao - h,
        width: w,
        height: h,
        child: IgnorePointer(
          child: Opacity(
            opacity: a.alpha.clamp(0.0, 1.0),
            child: RepaintBoundary(
              child: AtorHistoria(
                key: ValueKey('historia-ator-${a.quem}'),
                aparencia: a.aparencia,
                altura: h,
                pose: a.pose,
                visema: a.visema,
                olhos: a.olhos,
                expressao: a.expressao,
                olhar: a.olhar,
                espelhado: a.espelhado,
                segura: a.segura,
                carro: a.carro,
                capitulo: cabecalho.pinturaCarro,
                reduzir: reduzir,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  /// A moldura de webcam (apagada embaixo; a acesa por cima, com o quanto a pessoa já entrou) e as iniciais de
  /// quem ainda não entrou.
  List<Widget> _moldura((String, Rect, double) m) {
    final (quem, r, acesa) = m;
    final indice = _hash(quem) % 4;
    final nome = ElencoTurismo.nomeDe(quem);
    final iniciais = nome.isEmpty ? '?' : nome.characters.first.toUpperCase();
    // a borda verde de "quem está falando", como nos apps de chamada: acesa o passo inteiro da fala (com o
    // balão na tela, também no vão e na "sua vez"), não só enquanto a boca mexe
    final f = passo;
    final falando = (atores.where((q) => q.quem == quem).firstOrNull?.pose.falando ?? false) ||
        (f != null &&
            f.quem == quem &&
            !f.mudo &&
            f.en != null &&
            !acabou &&
            (estado == EstadoRoteiro.falando || estado == EstadoRoteiro.lendo));
    return [
      Positioned.fromRect(
        rect: r,
        child: IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (acesa < 1)
                CustomPaint(
                  key: ValueKey('historia-moldura-$quem'),
                  painter: MolduraWebcamPainter(indice: indice, acesa: false, hora: depois.hora, iniciais: iniciais),
                ),
              if (acesa > 0)
                Opacity(
                  opacity: acesa.clamp(0.0, 1.0),
                  child: CustomPaint(
                    key: acesa >= 1 ? ValueKey('historia-moldura-$quem') : null,
                    painter: MolduraWebcamPainter(
                        indice: indice, acesa: true, hora: depois.hora, falando: falando && acesa >= 1),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  /// O ator dentro da moldura dele, recortado nela (a cintura para baixo some, D8 + spike b).
  List<Widget> _atorNaChamada(_AtorQuadro a, double h) {
    final w = larguraAtor;
    final chao = pe(a.x);
    final corpo = Rect.fromLTWH(a.x - w / 2, chao - h, w, h);
    final m = molduras.where((x) => x.$1 == a.quem).firstOrNull?.$2 ??
        PalcoHistoria.molduraNaChamada(corpo, maxMoldura);
    return [
      Positioned.fromRect(
        rect: m,
        child: IgnorePointer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MolduraWebcamPainter.raioDe(m.size)),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: corpo.left - m.left,
                  top: corpo.top - m.top,
                  width: w,
                  height: h,
                  child: Opacity(
                    opacity: a.alpha.clamp(0.0, 1.0),
                    child: RepaintBoundary(
                      child: AtorHistoria(
                        key: ValueKey('historia-ator-${a.quem}'),
                        aparencia: a.aparencia,
                        altura: h,
                        pose: a.pose,
                        visema: a.visema,
                        olhos: a.olhos,
                        expressao: a.expressao,
                        olhar: a.olhar,
                        espelhado: a.espelhado,
                        segura: a.segura,
                        carro: a.carro,
                        capitulo: cabecalho.pinturaCarro,
                        reduzir: reduzir,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _celular((String, Rect, Visema) c) {
    final (quem, r, visema) = c;
    return Positioned.fromRect(
      rect: r,
      child: IgnorePointer(
        child: CustomPaint(
          key: ValueKey('historia-celular-$quem'),
          size: r.size,
          painter: PropPainter(
            prop: PropHistoria.celular,
            t: reduzir ? 0 : relogio,
            rosto: ElencoTurismo.de(quem),
            visema: visema,
            capitulo: cabecalho.pinturaCarro,
          ),
        ),
      ),
    );
  }

  /// O que fica por cima da câmera: fade da cena, título, balão/legenda.
  List<Widget> sobreposicoes(BuildContext context) {
    final r = <Widget>[];
    final escuro = parado || acabou ? 0.0 : roteiro.escurecimento;
    if (escuro > 0) {
      r.add(Positioned.fill(
        child: IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: escuro.clamp(0.0, 1.0)))),
      ));
    }
    if (roteiro.noTitulo) r.add(_titulo());
    final f = passo;
    final mostraTexto = f != null &&
        !f.mudo &&
        f.en != null &&
        roteiro.tSaida == null && // falou, leu e agora sai: o balão já fechou
        (estado == EstadoRoteiro.falando || estado == EstadoRoteiro.lendo);
    if (mostraTexto) {
      final pt = f.pt ?? '';
      if (f.ehNarrador) {
        r.add(Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: LegendaNarrador(
            key: const Key('historia-legenda'),
            en: f.en!,
            pt: pt,
            letras: roteiro.letrasVisiveis,
            mostrarPt: roteiro.mostrarPt,
            esconderEn: roteiro.esconderEn,
            icone: roteiro.iconeDaFala,
          ),
        ));
      } else {
        r.add(_balao(context, f));
      }
    }
    return r;
  }

  Widget _titulo() {
    final tit = roteiro.duracaoTituloAtual;
    final a = reduzir ? 1.0 : math.min((t / .3).clamp(0.0, 1.0), ((tit - t) / .35).clamp(0.0, 1.0));
    final escala = (size.width / 1280).clamp(1.0, 1.4);
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: a,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cabecalho.sobretitulo,
                      style: Mixart.display(size: 14 * escala, color: const Color(0xFFFFC73B))
                          .copyWith(letterSpacing: 3)),
                  const SizedBox(height: 6),
                  Text(cabecalho.titulo.en,
                      textAlign: TextAlign.center,
                      style: Mixart.display(size: 30 * escala, color: Colors.white, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(cabecalho.titulo.pt,
                      textAlign: TextAlign.center,
                      style: Mixart.ui(size: 15 * escala, color: Colors.white70).copyWith(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _balao(BuildContext context, FalaHistoria f) {
    final w = size.width;
    final escala = (w / 1280).clamp(1.0, 1.4);
    final ancora = ancoraBalao == null ? null : naTela(ancoraBalao!);
    final topo = topoFalante == null ? null : naTela(Offset(0, topoFalante!)).dy;
    // a largura MÁXIMA; o balão tem a largura do texto (medida) e fica centrado em quem fala
    final largura = estreito ? w - 16 : math.min(w * .86, 560 * escala);
    final nome = ElencoTurismo.nomeDe(f.quem);
    final mq = MediaQuery.of(context);
    var scaler = mq.textScaler;
    Size medir() => BalaoFala.medir(
          context,
          nome: nome,
          en: f.en!,
          pt: f.pt ?? '',
          mostrarPt: roteiro.mostrarPt,
          via: via,
          esconderEn: roteiro.esconderEn,
          icone: roteiro.iconeDaFala,
          comRabicho: ancora != null,
          escala: escala,
          maxLargura: largura,
          textScaler: scaler,
        );
    var tam = medir();
    // em cima da cabeça só se o balão inteiro couber ali; senão a faixa do topo, que pode descer até perto
    // da cabeça (cobre a cabeça só quando nem isso basta)
    final cabeEmCima = !estreito && topo != null && topo - 16 > 96 * escala && tam.height <= topo - 10;
    var alturaMax = cabeEmCima
        ? math.max(0.0, topo - 10)
        : math.max(size.height * (estreito ? .42 : .38), (topo ?? 0) - 16)
            .clamp(80.0, math.max(80.0, size.height - 16))
            .toDouble();
    // texto grande que não cabe: encolhe só dentro do balão (até o tamanho normal) antes de precisar rolar
    var fator = scaler.scale(100) / 100;
    while (tam.height > alturaMax && fator > 1.0) {
      fator = math.max(1.0, fator * .88);
      scaler = TextScaler.linear(fator);
      tam = medir();
    }
    // 📺 palco baixo: melhor cobrir as cabeças do que cortar a frase
    if (balaoSemCorte && !cabeEmCima && tam.height > alturaMax) {
      alturaMax = math.min(tam.height, math.max(alturaMax, size.height - 16));
    }
    final bw = math.min(largura, tam.width.ceilToDouble() + 1);
    final left = ancora == null
        ? (w - bw) / 2
        : (ancora.dx - bw / 2).clamp(8.0, math.max(8.0, w - bw - 8)).toDouble();
    // 📺 na chamada, o balão que não cabe em cima da cabeça desce até logo acima da moldura de quem fala (com
    // 2 filas, a da frente ficava longe do balão do topo), se ali não cobrir a moldura de ninguém
    var topoBalao = 8.0;
    if (chamada && !cabeEmCima) {
      final m = molduras.where((x) => x.$1 == f.quem).firstOrNull?.$2;
      if (m != null) {
        final dy = naTela(m.topLeft).dy - tam.height - 6;
        final caixa = Rect.fromLTWH(left, dy, bw, tam.height);
        final livre = molduras.every((o) =>
            o.$1 == f.quem || !Rect.fromPoints(naTela(o.$2.topLeft), naTela(o.$2.bottomRight)).overlaps(caixa));
        if (dy > 8 && livre) {
          topoBalao = dy;
          alturaMax = tam.height;
        }
      }
    }
    final alvo = ancora == null ? null : Offset(ancora.dx - left, math.max(0, (topo ?? ancora.dy) - 8));
    Widget balao = BalaoFala(
      nome: nome,
      cor: ElencoTurismo.corDe(f.quem),
      en: f.en!,
      pt: f.pt ?? '',
      letras: roteiro.letrasVisiveis,
      mostrarPt: roteiro.mostrarPt,
      via: via,
      esconderEn: roteiro.esconderEn,
      icone: roteiro.iconeDaFala,
      alvoRabicho: alvo,
      escala: escala,
    );
    if (scaler != mq.textScaler) balao = MediaQuery(data: mq.copyWith(textScaler: scaler), child: balao);
    if (cabeEmCima) {
      return Positioned(
        left: left,
        width: bw,
        top: 8,
        height: alturaMax,
        child: Align(alignment: Alignment.bottomCenter, child: balao),
      );
    }
    return Positioned(
      left: left,
      width: bw,
      top: topoBalao,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: alturaMax),
        child: Align(alignment: Alignment.topCenter, child: balao),
      ),
    );
  }
}

/// A sombra elíptica sob cada ator.
class _Sombra extends StatelessWidget {
  const _Sombra();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: ShapeDecoration(shape: OvalBorder(), color: Color(0x33000000)),
      );
}
