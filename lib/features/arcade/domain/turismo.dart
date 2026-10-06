import 'dart:math';

import 'palavras_csharp.dart';

/// 🏎️ Dart Turismo — campeonato de digitação em 10 pistas.
///
/// Uma pista (fase) do campeonato. As grandezas derivadas mantêm o jogo
/// justo em qualquer fase: a velocidade máxima é a que ainda deixa ~2,8 s
/// entre um portal e o próximo, e o tempo limite (bronze) exige a média
/// [velAlvo]. Prata e ouro são frações desse limite.
class PistaGt {
  final int numero;
  final String nome;
  final String dificuldade;

  /// Mundo do cenário (1–6, ver `cenario.dart`).
  final int tema;

  /// Comprimento da pista em metros.
  final double distancia;

  /// Velocidade MÉDIA mínima pra fechar no tempo (km/h) — o bronze.
  final double velAlvo;

  /// Segundos entre portais no ritmo alvo (menor = mais apertado).
  final double tempoPorPortal;

  /// Intensidade máxima das curvas (0 reta … 6 grampo).
  final double curvaMax;

  /// 1 = palavras curtas · 2 = curtas e médias · 3 = médias e longas.
  final int nivelPalavras;

  /// Portais com DUAS faixas livres (o jogador escolhe qual palavra digitar).
  final bool duasSaidas;

  /// 🎸 Trilha da fase (arquivo em web/assets3d/som/musica; rock instrumental de
  /// Kevin MacLeod, incompetech.com, CC BY 4.0) e o título dela.
  final String musica;
  final String tituloMusica;

  const PistaGt({
    required this.numero,
    required this.nome,
    required this.dificuldade,
    required this.tema,
    required this.distancia,
    required this.velAlvo,
    required this.tempoPorPortal,
    required this.curvaMax,
    required this.nivelPalavras,
    this.duasSaidas = false,
    this.musica = '',
    this.tituloMusica = '',
  });

  double get velAlvoMs => velAlvo / 3.6;

  /// Tempo limite em segundos (bronze).
  double get tempoLimite => distancia / velAlvoMs;
  double get tempoPrata => tempoLimite * .86;
  double get tempoOuro => tempoLimite * .72;

  /// Metros entre portais.
  double get intervaloPortais => velAlvoMs * tempoPorPortal;

  /// Velocidade máxima do carro (m/s): a que ainda dá 2,8 s por portal.
  double get velMax => intervaloPortais / 2.8;
  double get velMaxKmh => velMax * 3.6;

  List<String> get vocabulario {
    final v = vocabularioDe();
    return switch (nivelPalavras) {
      1 => v.curtas,
      2 => [...v.curtas, ...v.medias],
      _ => [...v.medias, ...v.longas],
    };
  }

  /// Medalha pra um tempo de chegada: 3 ouro · 2 prata · 1 bronze · 0 nada.
  int medalha(double tempo) {
    if (tempo <= tempoOuro) return 3;
    if (tempo <= tempoPrata) return 2;
    if (tempo <= tempoLimite) return 1;
    return 0;
  }
}

/// O campeonato: 10 pistas, do autódromo de iniciante à final lendária.
const List<PistaGt> pistasGt = [
  PistaGt(numero: 1, nome: 'Autódromo da Campina', dificuldade: 'Iniciante', tema: 1, distancia: 4000, velAlvo: 60, tempoPorPortal: 5.0, curvaMax: 1.5, nivelPalavras: 1, musica: '01_cool_rock.mp3', tituloMusica: 'Cool Rock'),
  PistaGt(numero: 2, nome: 'Circuito do Deserto', dificuldade: 'Iniciante', tema: 2, distancia: 4800, velAlvo: 70, tempoPorPortal: 4.9, curvaMax: 2.0, nivelPalavras: 1, musica: '02_hotrock.mp3', tituloMusica: 'Hotrock'),
  PistaGt(numero: 3, nome: 'Noturno da Cidade', dificuldade: 'Amador', tema: 3, distancia: 5600, velAlvo: 80, tempoPorPortal: 4.8, curvaMax: 2.5, nivelPalavras: 1, musica: '03_big_rock.mp3', tituloMusica: 'Big Rock'),
  PistaGt(numero: 4, nome: 'Serra Nevada', dificuldade: 'Amador', tema: 4, distancia: 6400, velAlvo: 90, tempoPorPortal: 4.8, curvaMax: 3.0, nivelPalavras: 2, musica: '04_delay_rock.mp3', tituloMusica: 'Delay Rock'),
  PistaGt(numero: 5, nome: 'Rota do Vulcão', dificuldade: 'Semi-pro', tema: 5, distancia: 7200, velAlvo: 100, tempoPorPortal: 4.7, curvaMax: 3.5, nivelPalavras: 2, musica: '05_neolith.mp3', tituloMusica: 'Neolith'),
  PistaGt(numero: 6, nome: 'Anel Sideral', dificuldade: 'Semi-pro', tema: 6, distancia: 8000, velAlvo: 110, tempoPorPortal: 4.7, curvaMax: 4.0, nivelPalavras: 2, musica: '06_exhilarate.mp3', tituloMusica: 'Exhilarate'),
  PistaGt(numero: 7, nome: 'Campina GP', dificuldade: 'Profissional', tema: 1, distancia: 9200, velAlvo: 120, tempoPorPortal: 4.6, curvaMax: 4.5, nivelPalavras: 3, duasSaidas: true, musica: '07_riptide.mp3', tituloMusica: 'Riptide'),
  PistaGt(numero: 8, nome: 'Deserto Endurance', dificuldade: 'Profissional', tema: 2, distancia: 10400, velAlvo: 130, tempoPorPortal: 4.6, curvaMax: 5.0, nivelPalavras: 3, duasSaidas: true, musica: '08_ready_aim_fire.mp3', tituloMusica: 'Ready Aim Fire'),
  PistaGt(numero: 9, nome: 'Cidade 24 Horas', dificuldade: 'Lendário', tema: 3, distancia: 11200, velAlvo: 140, tempoPorPortal: 4.5, curvaMax: 5.5, nivelPalavras: 3, duasSaidas: true, musica: '09_metalmania.mp3', tituloMusica: 'Metalmania'),
  PistaGt(numero: 10, nome: 'Grande Final Sideral', dificuldade: 'Lendário', tema: 6, distancia: 12000, velAlvo: 150, tempoPorPortal: 4.5, curvaMax: 6.0, nivelPalavras: 3, duasSaidas: true, musica: '10_summon_the_rawk.mp3', tituloMusica: 'Summon the Rawk'),
];

const nomesMedalha = ['—', 'Bronze', 'Prata', 'Ouro'];
const emojisMedalha = ['·', '🥉', '🥈', '🥇'];

/// Um pedaço de estrada de [TurismoEngine.comprimentoSegmento] metros; a
/// curva acumula ao longo dos segmentos e dobra a pista na tela.
class Segmento {
  final int indice;
  final double curva;
  const Segmento(this.indice, this.curva);
}

/// Carro de TRÁFEGO numa faixa bloqueada do portal: espera parado no pórtico
/// e arranca quando o jogador se aproxima, sempre na sua faixa. Encostar
/// nele é batida.
class CarroTrafego {
  final int faixa;
  double z;

  /// Velocidade atual (m/s): arranca do zero quando o jogador chega perto.
  double vel = 0;
  bool ativo = false;
  bool batido = false;
  CarroTrafego({required this.faixa, required this.z});
}

/// Ficha de programação na pista (`=>`, `{}`, `async`…): passar por cima,
/// na faixa dela, rende MOEDAS — a moeda do campeonato compra carros.
class Ficha {
  final double z;
  final int faixa;
  final String texto;
  bool pega = false;
  Ficha({required this.z, required this.faixa, required this.texto});
}

/// Portal (pórtico) sobre a pista: faixas livres com uma palavra cada; as
/// outras têm carros de tráfego. Digite a palavra da faixa livre pra entrar
/// nela antes de chegar.
class Portal {
  final int indice;

  /// Posição do portal em metros.
  final double z;

  /// Faixas livres (0 esquerda · 1 meio · 2 direita) e a palavra de cada uma.
  final List<int> faixas;
  final List<String> palavras;

  /// Um carro por faixa bloqueada.
  final List<CarroTrafego> carros;

  /// Fichas antes do pórtico, na faixa livre (marcam o caminho certo).
  final List<Ficha> fichas;

  bool passado = false;

  /// Índice (em [palavras]) da palavra digitada — -1 = nenhuma.
  int digitado = -1;

  Portal({
    required this.indice,
    required this.z,
    required this.faixas,
    required this.palavras,
    this.carros = const [],
    this.fichas = const [],
  });

  bool get livre => digitado >= 0;

  /// Algum carro deste portal já foi atingido.
  bool get batido => carros.any((c) => c.batido);
}

/// Símbolos e palavras-chave que viram fichas na pista.
const fichasDart = ['=>', '{ }', ';', '??', '...', 'async', 'await', 'final', '[ ]', '?.', 'const', 'void'];

enum TeclaGt { avancou, completou, errou, nada }

/// Como o jogador controla o carro: digitando as palavras dos portais (o
/// modo de aprender) ou pelas SETAS (acelera, freia e troca de faixa).
enum ModoControle { digitacao, setas }

/// 👻 Uma volta gravada: posição (m) e x lateral (m) do carro a cada [passo]
/// segundos. A melhor de cada pista vira o carro-fantasma da próxima.
class VoltaFantasma {
  static const passo = 0.25;
  final double tempo;

  /// posicao0, x0, posicao1, x1, … (as posições nunca diminuem).
  final List<double> amostras;
  const VoltaFantasma(this.tempo, this.amostras);

  int get n => amostras.length ~/ 2;

  double _lerp(int par, double t) {
    if (n == 0) return 0;
    final i = t / passo;
    final a = i.floor().clamp(0, n - 1);
    final b = (a + 1).clamp(0, n - 1);
    final f = (i - a).clamp(0.0, 1.0);
    return amostras[a * 2 + par] + (amostras[b * 2 + par] - amostras[a * 2 + par]) * f;
  }

  /// Onde o fantasma estava aos [t] segundos.
  double posicaoEm(double t) => _lerp(0, t);
  double xEm(double t) => _lerp(1, t);

  /// Em que segundo o fantasma passou por [posicao] (busca binária).
  double tempoEm(double posicao) {
    if (n == 0) return 0;
    var lo = 0, hi = n - 1;
    while (lo < hi) {
      final m = (lo + hi) ~/ 2;
      if (amostras[m * 2] < posicao) {
        lo = m + 1;
      } else {
        hi = m;
      }
    }
    if (lo == 0) return 0;
    final p0 = amostras[(lo - 1) * 2], p1 = amostras[lo * 2];
    final f = p1 > p0 ? ((posicao - p0) / (p1 - p0)).clamp(0.0, 1.0) : 0.0;
    return (lo - 1 + f) * passo;
  }

  String serializar() =>
      '${tempo.toStringAsFixed(2)}|${amostras.map((v) => v.toStringAsFixed(1)).join(',')}';

  static VoltaFantasma? desserializar(String? s) {
    if (s == null || !s.contains('|')) return null;
    try {
      final partes = s.split('|');
      final tempo = double.parse(partes[0]);
      final amostras = partes[1].split(',').map(double.parse).toList();
      if (amostras.length < 4 || amostras.length.isOdd) return null;
      return VoltaFantasma(tempo, amostras);
    } catch (_) {
      return null;
    }
  }
}

/// O motor da corrida. Tudo em metros, segundos e m/s.
///
/// - Cada tecla certa dá um impulso; o arrasto (quadrático) freia sempre —
///   parar de digitar é ir parando até ficar imóvel.
/// - Tecla errada derrapa (−10%); completar a palavra dá um boost e move o
///   carro pra faixa da palavra.
/// - Cruzar um portal numa faixa bloqueada é BATIDA: velocidade cai a 30%.
/// - COMBO de palavras seguidas sem erro nem batida: x2 aos 5, x3 aos 10.
///   Pontos por palavra = (3 + letras)·combo — uma corrida rende centenas de
///   pontos, na escala dos outros jogos do ranking.
/// - Digitada a palavra do próximo portal, vêm palavras de COMBUSTÍVEL (só
///   aceleram) até o portal passar — sempre há o que digitar, e quem para
///   de digitar vai parando.
class TurismoEngine {
  final PistaGt pista;
  final Random rnd;
  final ModoControle modo;

  static const comprimentoSegmento = 8.0;
  static const larguraFaixa = 3.7;
  static const faixaInicial = 1;

  /// O tráfego arranca (do zero, em ~1,5 s) quando o jogador chega a esta
  /// distância DO CARRO; cruza no máximo esta fração da velocidade máxima.
  /// Arrancar tarde e devagar garante duas coisas: quem vem na faixa errada
  /// bate logo depois do pórtico, e quem passou deixa o tráfego pra trás —
  /// ele nunca reaparece na faixa do portal seguinte.
  static const distanciaArranque = 25.0;
  static const fracaoTrafego = .32;
  static const segundosArranque = 1.5;
  static const fracaoDoJogador = .45;

  /// Alcance da batida (m) e da coleta de ficha (m).
  static const alcanceBatida = 4.2;
  static const alcanceFicha = 3.0;
  static const alcanceLateralFicha = 2.3;
  static const moedasPorFicha = 3;

  /// Metros depois de um pórtico em que a troca de faixa do PRÓXIMO portal
  /// passa a valer: quem digita a palavra logo ao cruzar não entra em cima
  /// do tráfego que acabou de deixar pra trás.
  static const folgaTroca = 14.0;

  late final List<Segmento> segmentos;
  late final List<Portal> portais;

  double posicao = 0;
  double velocidade = 0;
  double tempo = 0;

  /// Faixa alvo (0/1/2) e posição lateral real do carro em metros
  /// (anima até a faixa; a diferença vira a inclinação nas curvas de faixa).
  int faixa = faixaInicial;
  double xAtual = 0;

  /// Troca de faixa esperando a folga depois do último pórtico.
  int? faixaPendente;
  double _zLiberaTroca = double.negativeInfinity;

  int palavras = 0;
  int erros = 0;
  int teclasCertas = 0;
  int colisoes = 0;
  int combo = 0;
  int melhorCombo = 0;
  int pontos = 0;

  /// Moedas ganhas nesta corrida (fichas coletadas).
  int moedas = 0;
  int fichasPegas = 0;

  /// Efeitos visuais decaindo (1 → 0): batida e boost.
  double impacto = 0;
  double boost = 0;

  bool terminou = false;
  bool tempoEsgotado = false;
  double? tempoFinal;

  /// Digitação do portal: qual palavra (se há duas) e quantas letras.
  int? palavraTravada;
  int digitadas = 0;

  /// Palavra de COMBUSTÍVEL na vez (só acelera, não troca de faixa) e o
  /// progresso nela. Existe enquanto o próximo portal já estiver digitado
  /// (ou não houver mais portais).
  String? palavraGas;
  int gasDigitadas = 0;
  final List<String> _usadasGas = [];

  TurismoEngine({required this.pista, required this.rnd, this.modo = ModoControle.digitacao}) {
    segmentos = _gerarPista();
    portais = _gerarPortais();
  }

  bool get porSetas => modo == ModoControle.setas;

  /// Portais atravessados numa faixa livre (modo setas).
  int portaisLimpos = 0;

  /// 👻 A volta sendo gravada (posição, x a cada 0,25 s) — vira fantasma se
  /// for a melhor da pista.
  final gravacao = <double>[];
  double _proximaAmostra = 0;

  /// Aceleração e freio do modo setas (frações da máxima por segundo).
  static const aceleracaoSetas = .55;
  static const freioSetas = 1.4;

  /// Modo setas: troca de faixa pra esquerda (−1) ou direita (+1).
  void virar(int delta) {
    if (!correndo || !porSetas) return;
    faixa = (faixa + delta).clamp(0, 2);
    faixaPendente = null;
  }

  /// Modo setas: chame a cada frame com o estado do acelerador e do freio.
  void pedais(double dt, {bool gas = false, bool freio = false}) {
    if (!correndo || !porSetas) return;
    if (gas) velocidade = (velocidade + velMax * aceleracaoSetas * dt).clamp(0, velMax);
    if (freio) velocidade = (velocidade - velMax * freioSetas * dt).clamp(0, velMax);
  }

  double get xAlvo => (faixa - 1) * larguraFaixa;

  /// A faixa onde o carro ESTÁ de verdade (posição visual), não a alvo:
  /// é ela que decide batida e coleta — trocar em cima da hora não salva.
  int get faixaVisual => ((xAtual / larguraFaixa).round() + 1).clamp(0, 2);
  double get velMax => pista.velMax;
  double get velTrafego => velMax * fracaoTrafego;

  /// Carros de tráfego já em movimento (pra tela).
  Iterable<CarroTrafego> get trafegoAtivo sync* {
    for (final p in portais) {
      for (final c in p.carros) {
        if (c.ativo && !c.batido) yield c;
      }
    }
  }
  double get fracaoVel => (velocidade / velMax).clamp(0, 1);
  double get progresso => (posicao / pista.distancia).clamp(0, 1);
  double get tempoRestante => (pista.tempoLimite - tempo).clamp(0, double.infinity);
  bool get correndo => !terminou && !tempoEsgotado;
  int get multiplicador => combo >= 10 ? 3 : (combo >= 5 ? 2 : 1);
  int get precisao =>
      teclasCertas + erros == 0 ? 100 : (teclasCertas * 100 / (teclasCertas + erros)).round();

  /// Curva do segmento sob o carro (pra inclinar o cenário).
  double get curvaAtual => segmentoEm(posicao).curva;

  Segmento segmentoEm(double z) =>
      segmentos[(z / comprimentoSegmento).floor().clamp(0, segmentos.length - 1)];

  /// Posição (na lista) do próximo portal não cruzado; `portais.length` se
  /// já passou por todos. ⚠️ Não confundir com `Portal.indice`, que é o
  /// índice do SEGMENTO da pista onde o pórtico está.
  int get ordinalDoPortalAtual {
    for (var i = 0; i < portais.length; i++) {
      if (!portais[i].passado) return i;
    }
    return portais.length;
  }

  /// Os portais em volta do carro (do 2º anterior ao 5º à frente) com a
  /// posição de cada um na lista — é o que a vista 3D precisa animar por
  /// frame; mandar os 48–64 portais inteiros virava lixo pro GC.
  List<(int, Portal)> janelaDePortais({int antes = 2, int depois = 6}) {
    final atual = ordinalDoPortalAtual;
    final de = (atual - antes).clamp(0, portais.length);
    final ate = (atual + depois).clamp(0, portais.length);
    return [for (var i = de; i < ate; i++) (i, portais[i])];
  }

  /// O próximo portal ainda não cruzado.
  Portal? get portalAtual {
    for (final p in portais) {
      if (!p.passado) return p;
    }
    return null;
  }

  /// O portal cuja palavra está na vez: o próximo, se ainda não foi
  /// digitado e nenhuma palavra de combustível está pela metade.
  /// (No modo setas ninguém digita: sempre null.)
  Portal? get portalParaDigitar {
    if (porSetas) return null;
    final p = portalAtual;
    if (p == null || p.livre) return null;
    if (palavraGas != null && gasDigitadas > 0) return null;
    return p;
  }

  /// O portal depois do próximo (pra "a seguir").
  Portal? get proximoPortal {
    var achou = false;
    for (final p in portais) {
      if (p.passado) continue;
      if (achou) return p;
      achou = true;
    }
    return null;
  }

  /// Decide o que está na vez: a palavra do portal tem prioridade; sem
  /// portal pra digitar, entra (ou continua) uma palavra de combustível.
  void _atualizaAlvo() {
    if (porSetas) return;
    final p = portalAtual;
    if (p == null || p.livre) {
      palavraGas ??= _sorteiaPalavra(_usadasGas);
    } else if (palavraGas != null && gasDigitadas == 0) {
      palavraGas = null;
    }
  }

  int get medalha => tempoFinal == null ? 0 : pista.medalha(tempoFinal!);

  /// Pontos da corrida com o bônus da medalha (só quem chega ganha bônus).
  int get pontosFinais => pontos + const [0, 60, 120, 200][medalha];

  // ---------- geração ----------

  List<Segmento> _gerarPista() {
    final total = (pista.distancia / comprimentoSegmento).ceil() + 40;
    final curvas = List<double>.filled(total, 0);
    var i = 10; // largada reta
    var sentido = rnd.nextBool() ? 1.0 : -1.0;
    while (i < total) {
      // poucas retas; curvas cheias (50–100% da máxima) alternando o lado —
      // sequência de S que faz a pista parecer um circuito de verdade
      final reta = rnd.nextDouble() < .12;
      final alvo = reta ? 0.0 : sentido * pista.curvaMax * (.5 + .5 * rnd.nextDouble());
      if (!reta && rnd.nextDouble() < .8) sentido = -sentido;
      final entrada = 4 + rnd.nextInt(5);
      final manter = 5 + rnd.nextInt(9);
      final saida = 4 + rnd.nextInt(5);
      for (var k = 0; k < entrada && i < total; k++, i++) {
        curvas[i] = alvo * _suave(k / entrada);
      }
      for (var k = 0; k < manter && i < total; k++, i++) {
        curvas[i] = alvo;
      }
      for (var k = 0; k < saida && i < total; k++, i++) {
        curvas[i] = alvo * (1 - _suave(k / saida));
      }
    }
    return [for (var n = 0; n < total; n++) Segmento(n, curvas[n])];
  }

  static double _suave(double t) => t * t * (3 - 2 * t);

  List<Portal> _gerarPortais() {
    final lista = <Portal>[];
    final usadas = <String>[];
    var faixaAnterior = faixaInicial;
    final intervalo = pista.intervaloPortais;
    for (var z = intervalo; z < pista.distancia - 40; z += intervalo) {
      // a faixa livre nunca é a que o carro já ocupa: todo portal exige digitar
      final candidatas = [0, 1, 2]..remove(faixaAnterior);
      candidatas.shuffle(rnd);
      final faixas = pista.duasSaidas ? [candidatas[0], candidatas[1]] : [candidatas[0]];
      final palavras = [for (final _ in faixas) _sorteiaPalavra(usadas)];
      lista.add(Portal(
        indice: (z / comprimentoSegmento).floor(),
        z: z,
        faixas: faixas,
        palavras: palavras,
        carros: [
          for (var f = 0; f < 3; f++)
            if (!faixas.contains(f)) CarroTrafego(faixa: f, z: z + 2.6),
        ],
        // três fichas na faixa livre ANTES do pórtico: marcam o caminho certo
        fichas: [
          for (var k = 0; k < 3; k++)
            Ficha(z: z - 34 + k * 10, faixa: faixas.first, texto: fichasDart[rnd.nextInt(fichasDart.length)]),
        ],
      ));
      faixaAnterior = faixas.first;
    }
    return lista;
  }

  String _sorteiaPalavra(List<String> usadas) {
    final pool = pista.vocabulario;
    for (var t = 0; t < 40; t++) {
      final p = pool[rnd.nextInt(pool.length)];
      if (!usadas.contains(p)) {
        usadas.add(p);
        if (usadas.length > 8) usadas.removeAt(0);
        return p;
      }
    }
    return pool[rnd.nextInt(pool.length)];
  }

  // ---------- simulação ----------

  /// Avança a corrida em [dt] segundos.
  void tick(double dt) {
    if (!correndo) return;
    if (tempo >= _proximaAmostra) {
      gravacao.add(posicao);
      gravacao.add(xAtual);
      _proximaAmostra += VoltaFantasma.passo;
    }
    tempo += dt;
    // arrasto quadrático: parou de digitar, vai parando
    final r = velocidade / velMax;
    velocidade -= velMax * (0.02 + 0.13 * r * r) * dt;
    if (velocidade < 0) velocidade = 0;
    posicao += velocidade * dt;
    if (faixaPendente != null && posicao >= _zLiberaTroca) {
      faixa = faixaPendente!;
      faixaPendente = null;
    }
    // o carro desliza até a faixa alvo
    xAtual += (xAlvo - xAtual) * (dt * 8).clamp(0, 1);
    impacto = (impacto - dt * 1.6).clamp(0, 1);
    boost = (boost - dt * 2.2).clamp(0, 1);

    final visual = faixaVisual;
    for (final p in portais) {
      // o tráfego arranca quando o jogador chega perto e segue na faixa dele
      for (final c in p.carros) {
        if (c.batido) continue;
        if (!c.ativo && posicao > c.z - distanciaArranque) c.ativo = true;
        if (c.ativo) {
          // nunca mais rápido que 45% do jogador: quem vem na faixa errada
          // SEMPRE alcança o carro (e quem para, vê o tráfego parar junto)
          final teto = min(velTrafego, velocidade * fracaoDoJogador);
          c.vel = teto < c.vel ? teto : (c.vel + velTrafego / segundosArranque * dt).clamp(0.0, teto);
          c.z += c.vel * dt;
        }
        // encostou no carro à frente, na MESMA faixa (visual): batida
        if (c.faixa == visual && c.z >= posicao - 1 && (c.z - posicao).abs() < alcanceBatida) {
          c.batido = true;
          colisoes++;
          combo = 0;
          velocidade *= .3;
          impacto = 1;
        }
      }
      // fichas: passou por cima — a 2,3 m do centro dela já pega (o carro tem
      // 1,8 m de largura; enquanto desliza entre faixas também conta)
      for (final f in p.fichas) {
        if (f.pega || (f.z - posicao).abs() > alcanceFicha) continue;
        if ((xAtual - (f.faixa - 1) * larguraFaixa).abs() > alcanceLateralFicha) continue;
        f.pega = true;
        fichasPegas++;
        moedas += moedasPorFicha;
        pontos += 5;
      }
      if (p.passado || posicao < p.z) continue;
      p.passado = true;
      _zLiberaTroca = p.z + folgaTroca;
      if (porSetas && p.faixas.contains(visual)) {
        // passou limpo pela faixa livre: vale como uma palavra acertada
        portaisLimpos++;
        combo++;
        if (combo > melhorCombo) melhorCombo = combo;
        pontos += 10 * multiplicador;
        boost = 1;
      }
      if (!p.livre) {
        // o portal passou sem palavra: a digitação pela metade se perde
        palavraTravada = null;
        digitadas = 0;
      }
      _atualizaAlvo();
    }

    if (posicao >= pista.distancia) {
      terminou = true;
      tempoFinal = tempo;
      velocidade = velocidade.clamp(0, velMax);
      gravacao.add(posicao);
      gravacao.add(xAtual);
    } else if (tempo >= pista.tempoLimite) {
      tempoEsgotado = true;
    }
  }

  /// Uma tecla do jogador.
  TeclaGt teclar(String ch) {
    if (!correndo || porSetas) return TeclaGt.nada;
    _atualizaAlvo();
    final p = portalParaDigitar;
    if (p == null) return _teclarGas(ch);
    var idx = palavraTravada;
    if (idx == null) {
      idx = p.palavras.indexWhere((w) => w.startsWith(ch));
      if (idx < 0) return _errou();
      palavraTravada = idx;
      digitadas = 1;
    } else {
      final w = p.palavras[idx];
      if (digitadas < w.length && w[digitadas] == ch) {
        digitadas++;
      } else {
        return _errou();
      }
    }
    teclasCertas++;
    velocidade = (velocidade + velMax * .075).clamp(0, velMax);
    final w = p.palavras[idx];
    if (digitadas >= w.length) {
      p.digitado = idx;
      if (posicao >= _zLiberaTroca) {
        faixa = p.faixas[idx];
      } else {
        faixaPendente = p.faixas[idx]; // vale assim que passar a folga
      }
      _completou(w.length, boostExtra: .12, forca: 1);
      palavraTravada = null;
      digitadas = 0;
      _atualizaAlvo();
      return TeclaGt.completou;
    }
    return TeclaGt.avancou;
  }

  /// Palavra de combustível: cada letra acelera; completa, dá um boost menor.
  TeclaGt _teclarGas(String ch) {
    final gas = palavraGas;
    if (gas == null) return TeclaGt.nada;
    if (gasDigitadas < gas.length && gas[gasDigitadas] == ch) {
      gasDigitadas++;
    } else {
      return _errou();
    }
    teclasCertas++;
    velocidade = (velocidade + velMax * .075).clamp(0, velMax);
    if (gasDigitadas >= gas.length) {
      _completou(gas.length, boostExtra: .06, forca: .6);
      palavraGas = null;
      gasDigitadas = 0;
      _atualizaAlvo();
      return TeclaGt.completou;
    }
    return TeclaGt.avancou;
  }

  void _completou(int letras, {required double boostExtra, required double forca}) {
    palavras++;
    combo++;
    if (combo > melhorCombo) melhorCombo = combo;
    pontos += (3 + letras) * multiplicador;
    velocidade = (velocidade + velMax * boostExtra).clamp(0, velMax);
    boost = forca;
  }

  TeclaGt _errou() {
    erros++;
    combo = 0;
    velocidade *= .9;
    return TeclaGt.errou;
  }
}
