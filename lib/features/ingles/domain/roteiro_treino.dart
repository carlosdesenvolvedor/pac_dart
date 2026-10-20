// O roteiro de uma sessão de treino de palavras do PAC·ENGLISH (estilo
// Duolingo): conhecer cada palavra → escolher a tradução → parear → ouvir e
// escolher (metade delas) → digitar de memória. Errou? O passo volta 3 passos
// depois (no máximo 2 vezes). A nota de cada palavra é a PIOR 1ª tentativa
// entre os passos dela. Dart puro (sem Flutter): a tela só mostra e responde.
import 'dart:math' as math;

import '../../arcade/domain/palavras_ingles.dart';
import 'banco_palavras.dart';
import 'comparar_resposta.dart';
import 'palavras_novas.dart';

/// Os tipos de passo, na ordem em que a sessão os apresenta.
enum TipoPasso {
  /// A palavra nova: inglês, áudio, tradução e a frase da lição (sem nota).
  conhecer,

  /// O inglês na tela → 4 traduções.
  escolherPt,

  /// Um tabuleiro de até 5 inglês × 5 português.
  pares,

  /// Só o áudio → 4 palavras em inglês.
  ouvirEscolher,

  /// A tradução (e o 🔊) → digitar o inglês.
  digitar,

  /// Revanche das teimosas: um cartão rápido (sem nota) para relembrar a palavra — inglês, tradução, 🔊
  /// e o exemplo com ela em destaque.
  relembrar,
}

/// Uma palavra da sessão, com a tradução já cortada para caber num botão.
class ItemTreino {
  final PalavraNova palavra;

  /// A tradução dos botões (até 24 letras).
  final String pt;

  const ItemTreino(this.palavra, this.pt);

  String get en => palavra.en;
  String get chave => palavra.chave;

  factory ItemTreino.de(PalavraNova p) {
    final curta = p.ptCompleta.isNotEmpty ? traducaoCurta(p.ptCompleta, max: 24) : '';
    return ItemTreino(p, curta.isNotEmpty ? curta : p.pt);
  }
}

/// Um passo da sessão.
class PassoTreino {
  final TipoPasso tipo;

  /// A palavra do passo (índice em [RoteiroTreino.itens]); -1 nos pares.
  final int item;

  /// As 4 opções (escolher: traduções; ouvir: palavras em inglês) e qual é a certa.
  final List<String> opcoes;
  final int correta;

  /// Pares: as palavras do tabuleiro na coluna do inglês e na do português (índices de itens).
  final List<int> esquerda;
  final List<int> direita;

  /// 0 = 1ª vez; 1–2 = voltou depois de um erro.
  final int vez;

  /// Digitar sem a inicial apagadinha no 1º quadradinho (revanche: é para lembrar de verdade).
  final bool semDica;

  const PassoTreino({
    required this.tipo,
    this.item = -1,
    this.opcoes = const [],
    this.correta = -1,
    this.esquerda = const [],
    this.direita = const [],
    this.vez = 0,
    this.semDica = false,
  });

  /// Passo que vale nota (todos menos o "conhecer" e o "relembrar").
  bool get avaliado => tipo != TipoPasso.conhecer && tipo != TipoPasso.relembrar;

  /// Passo de uma palavra só com 4 opções.
  bool get deEscolha => tipo == TipoPasso.escolherPt || tipo == TipoPasso.ouvirEscolher;

  @override
  String toString() => '${tipo.name}($item${vez > 0 ? ' vez $vez' : ''})';
}

/// A nota de uma digitação: certinho = acertou; um errinho de digitação numa palavra de 5+ letras
/// ([palavrasIguais]) = hesitou; dica, "não sei" ou palavra errada = errou.
ResultadoRevisao notaDigitada(String digitado, String alvo, {bool dica = false, bool naoSei = false}) {
  if (naoSei || dica) return ResultadoRevisao.errou;
  final a = digitado.trim().toLowerCase(), b = alvo.trim().toLowerCase();
  if (a.isEmpty) return ResultadoRevisao.errou;
  if (a == b) return ResultadoRevisao.acertou;
  return palavrasIguais(a, b) ? ResultadoRevisao.hesitou : ResultadoRevisao.errou;
}

/// O que a sessão devolve: a nota de cada palavra (pela chave), quantos passos com nota foram
/// respondidos, a % de acerto de primeira e se a pessoa quer jogar com as palavras.
class ResultadoTreino {
  final List<PalavraNova> palavras;
  final Map<String, ResultadoRevisao> notas;
  final int passos;
  final int pct;
  final int melhorCombo;
  final bool jogar;

  /// A pessoa pediu "📝 Virar lição" (revanche das teimosas).
  final bool licao;

  const ResultadoTreino({
    required this.palavras,
    required this.notas,
    required this.passos,
    required this.pct,
    this.melhorCombo = 0,
    this.jogar = false,
    this.licao = false,
  });

  /// Palavras que saíram certinhas de primeira (digitadas sem erro e sem errar a escolha).
  int get dePrimeira => notas.values.where((n) => n == ResultadoRevisao.acertou).length;

  /// O formato de [PalavrasCubit.registrarTreino].
  Map<String, (ResultadoRevisao, PalavraNova)> get paraRegistrar => {
        for (final p in palavras)
          if (notas[p.chave] != null) p.chave: (notas[p.chave]!, p),
      };

  ResultadoTreino comJogar(bool jogar) => ResultadoTreino(
      palavras: palavras, notas: notas, passos: passos, pct: pct, melhorCombo: melhorCombo, jogar: jogar, licao: licao);

  ResultadoTreino comLicao(bool licao) => ResultadoTreino(
      palavras: palavras, notas: notas, passos: passos, pct: pct, melhorCombo: melhorCombo, jogar: jogar, licao: licao);

  /// Junta duas rodadas (lotes da mesma sessão ou "treinar de novo"): a nota que vale é a pior.
  ResultadoTreino juntar(ResultadoTreino outro) {
    final notas = {...this.notas};
    for (final e in outro.notas.entries) {
      final ja = notas[e.key];
      notas[e.key] = ja == null || e.value.index < ja.index ? e.value : ja;
    }
    final vistas = {for (final p in palavras) p.chave};
    final total = passos + outro.passos;
    return ResultadoTreino(
      palavras: [...palavras, for (final p in outro.palavras) if (vistas.add(p.chave)) p],
      notas: notas,
      passos: total,
      pct: total == 0 ? 0 : ((pct * passos + outro.pct * outro.passos) / total).round(),
      melhorCombo: math.max(melhorCombo, outro.melhorCombo),
      jogar: jogar || outro.jogar,
      licao: licao || outro.licao,
    );
  }
}

/// Uma palavra candidata a "opção errada".
class _Candidata {
  final String en, pt;
  const _Candidata(this.en, this.pt);
}

String _norm(String s) => s.trim().toLowerCase();

/// A sessão em andamento: a fila de passos (que cresce quando um passo volta), o passo atual, as
/// 1ªs tentativas de cada palavra e o combo.
class RoteiroTreino {
  /// No máximo quantas palavras numa sessão.
  static const maxPalavras = 8;

  /// No máximo quantas palavras no tabuleiro de pares.
  static const maxPares = 5;

  /// Quantas vezes um passo errado pode voltar.
  static const maxVoltas = 2;

  /// Quantos passos depois o passo errado volta.
  static const distanciaVolta = 3;

  final List<ItemTreino> itens;
  final List<PassoTreino> _passos;
  final math.Random _rnd;
  final List<_Candidata> _reserva;

  int _atual = 0;
  final Map<int, List<ResultadoRevisao>> _primeiras = {};
  final Set<int> _recordou = {};
  final Set<int> _errouNoPar = {};
  int _respondidos = 0;
  int _certasDePrimeira = 0;
  int _avaliadasDePrimeira = 0;
  int combo = 0;
  int melhorCombo = 0;

  RoteiroTreino._(this.itens, this._reserva, this._rnd) : _passos = [];

  /// Os passos (os que voltaram depois de um erro inclusive).
  List<PassoTreino> get passos => List.unmodifiable(_passos);

  int get indice => _atual;
  PassoTreino? get atual => _atual < _passos.length ? _passos[_atual] : null;
  bool get terminou => _atual >= _passos.length;

  /// Progresso da barra (0–1): só os passos originais contam — um passo que volta não faz a barra
  /// andar para trás.
  double get progresso {
    final originais = _passos.where((p) => p.vez == 0).length;
    if (originais == 0) return 1;
    var feitos = 0;
    for (var i = 0; i < _atual && i < _passos.length; i++) {
      if (_passos[i].vez == 0) feitos++;
    }
    return feitos / originais;
  }

  /// Passos com nota já respondidos (cada um conta 1 exercício do dia).
  int get respondidos => _respondidos;

  /// Responde o passo atual de UMA palavra (escolher, ouvir, digitar). A 1ª vez entra na nota da
  /// palavra; errou → o passo volta [distanciaVolta] passos depois (até [maxVoltas] vezes).
  void responder(ResultadoRevisao r) {
    final p = atual;
    if (p == null || !p.avaliado || p.tipo == TipoPasso.pares) return;
    _respondidos++;
    final certo = r != ResultadoRevisao.errou;
    _contaCombo(certo);
    if (p.vez == 0) {
      (_primeiras[p.item] ??= []).add(r);
      if (p.tipo == TipoPasso.digitar) _recordou.add(p.item);
      _avaliadasDePrimeira++;
      if (certo) _certasDePrimeira++;
    }
    if (!certo && p.vez < maxVoltas) _devolver(p);
  }

  /// Pares: [item] foi pareado certo.
  void acertouPar(int item) {
    _contaCombo(true);
    if (atual?.vez == 0 && !_errouNoPar.contains(item)) {
      (_primeiras[item] ??= []).add(ResultadoRevisao.acertou);
      _avaliadasDePrimeira++;
      _certasDePrimeira++;
    }
  }

  /// Pares: a pessoa tocou primeiro em [item] e escolheu o par errado (vale a 1ª vez de cada palavra).
  void errouPar(int item) {
    _contaCombo(false);
    if (atual?.vez == 0 && _errouNoPar.add(item)) {
      (_primeiras[item] ??= []).add(ResultadoRevisao.errou);
      _avaliadasDePrimeira++;
    }
  }

  /// O tabuleiro de pares terminou (conta como 1 exercício).
  void terminouPares() {
    if (atual?.tipo == TipoPasso.pares) _respondidos++;
  }

  /// Vai para o próximo passo.
  void avancar() {
    if (_atual < _passos.length) _atual++;
  }

  void _contaCombo(bool certo) {
    combo = certo ? combo + 1 : 0;
    if (combo > melhorCombo) melhorCombo = combo;
  }

  void _devolver(PassoTreino p) {
    final opcoes = [...p.opcoes];
    var correta = p.correta;
    if (p.deEscolha && opcoes.isNotEmpty) {
      final certa = opcoes[correta];
      opcoes.shuffle(_rnd);
      correta = opcoes.indexOf(certa);
    }
    final volta =
        PassoTreino(tipo: p.tipo, item: p.item, opcoes: opcoes, correta: correta, vez: p.vez + 1, semDica: p.semDica);
    final onde = math.min(_atual + 1 + distanciaVolta, _passos.length);
    _passos.insert(onde, volta);
  }

  /// A nota de cada palavra que teve ao menos uma tentativa (a pior 1ª tentativa; sem digitar, no
  /// máximo "hesitou").
  Map<String, ResultadoRevisao> get notas => {
        for (final e in _primeiras.entries)
          itens[e.key].chave: notaDoTreino(e.value, recordou: _recordou.contains(e.key)),
      };

  ResultadoTreino resultado({bool jogar = false}) => ResultadoTreino(
        palavras: [for (final i in itens) i.palavra],
        notas: notas,
        passos: _respondidos,
        pct: _avaliadasDePrimeira == 0 ? 0 : (100 * _certasDePrimeira / _avaliadasDePrimeira).round(),
        melhorCombo: melhorCombo,
        jogar: jogar,
      );

  // ---------- montagem ----------

  /// 3 opções erradas + a certa, embaralhadas. [emPt]: opções em português (escolher a tradução);
  /// senão em inglês (ouvir e escolher). Ordem de procura: as palavras da sessão, a [_reserva] (a
  /// trilha), e por fim a lista fixa do Arcade; primeiro com tamanho parecido (±40%), depois qualquer.
  (List<String>, int) _opcoes(int i, {required bool emPt}) {
    final item = itens[i];
    final alvo = emPt ? item.pt : item.en;
    final ptAlvo = _norm(item.pt), enAlvo = _norm(item.en);
    final usados = {_norm(alvo)};
    final escolhidas = <String>[];
    final sessao = [for (var j = 0; j < itens.length; j++) if (j != i) _Candidata(itens[j].en, itens[j].pt)];
    final fixa = [for (final e in traducoesEn.entries) _Candidata(e.key, e.value)];
    bool tamanhoOk(String s) {
      final folga = math.max(2.0, alvo.length * .4);
      return (s.length - alvo.length).abs() <= folga;
    }

    void procurar(List<_Candidata> lista, {required bool estrito}) {
      if (escolhidas.length >= 3) return;
      final embaralhada = [...lista]..shuffle(_rnd);
      for (final c in embaralhada) {
        if (escolhidas.length >= 3) return;
        final texto = (emPt ? c.pt : c.en).trim();
        if (texto.isEmpty) continue;
        final n = _norm(texto);
        // nunca duas opções iguais, nem uma errada que também seria certa (home/house = casa)
        if (usados.contains(n) || _norm(c.pt) == ptAlvo || _norm(c.en) == enAlvo) continue;
        if (estrito && !tamanhoOk(texto)) continue;
        usados.add(n);
        escolhidas.add(texto);
      }
    }

    procurar(sessao, estrito: true);
    procurar(_reserva, estrito: true);
    procurar(sessao, estrito: false);
    procurar(_reserva, estrito: false);
    procurar(fixa, estrito: true);
    procurar(fixa, estrito: false);
    final opcoes = [alvo, ...escolhidas]..shuffle(_rnd);
    return (opcoes, opcoes.indexOf(alvo));
  }

  /// Revanche das teimosas: sem "conhecer" (ela já conhece) — um "relembrar" rápido por palavra, ouvir e
  /// escolher TODAS, digitar todas sem a inicial e, no fim da fila (espaçado), digitar todas de novo.
  void _montarRevanche() {
    final n = itens.length;
    final ordem = [for (var i = 0; i < n; i++) i];
    for (final i in ordem) {
      _passos.add(PassoTreino(tipo: TipoPasso.relembrar, item: i));
    }
    for (final i in [...ordem]..shuffle(_rnd)) {
      final (opcoes, correta) = _opcoes(i, emPt: false);
      _passos.add(PassoTreino(tipo: TipoPasso.ouvirEscolher, item: i, opcoes: opcoes, correta: correta));
    }
    for (final i in [...ordem]..shuffle(_rnd)) {
      _passos.add(PassoTreino(tipo: TipoPasso.digitar, item: i, semDica: true));
    }
    for (final i in [...ordem]..shuffle(_rnd)) {
      _passos.add(PassoTreino(tipo: TipoPasso.digitar, item: i, semDica: true));
    }
  }

  void _montar() {
    final n = itens.length;
    final ordem = [for (var i = 0; i < n; i++) i];
    // 1. conhecer, na ordem da lição
    for (final i in ordem) {
      _passos.add(PassoTreino(tipo: TipoPasso.conhecer, item: i));
    }
    // 2. escolher a tradução
    for (final i in [...ordem]..shuffle(_rnd)) {
      final (opcoes, correta) = _opcoes(i, emPt: true);
      _passos.add(PassoTreino(tipo: TipoPasso.escolherPt, item: i, opcoes: opcoes, correta: correta));
    }
    // 3. um tabuleiro de pares (com 3+ palavras: com 2 não tem graça)
    if (n >= 3) {
      final noTabuleiro = ([...ordem]..shuffle(_rnd)).take(maxPares).toList();
      _passos.add(PassoTreino(
        tipo: TipoPasso.pares,
        esquerda: [...noTabuleiro]..shuffle(_rnd),
        direita: [...noTabuleiro]..shuffle(_rnd),
      ));
    }
    // 4. ouvir e escolher: metade das palavras (arredondando para cima)
    final ouvir = ([...ordem]..shuffle(_rnd)).take((n + 1) ~/ 2).toList();
    for (final i in ouvir) {
      final (opcoes, correta) = _opcoes(i, emPt: false);
      _passos.add(PassoTreino(tipo: TipoPasso.ouvirEscolher, item: i, opcoes: opcoes, correta: correta));
    }
    // 5. digitar cada uma de memória
    for (final i in [...ordem]..shuffle(_rnd)) {
      _passos.add(PassoTreino(tipo: TipoPasso.digitar, item: i));
    }
  }
}

/// Monta a sessão para [palavras] (sem repetir; no máximo [RoteiroTreino.maxPalavras]). [reserva]:
/// outras palavras (da mesma trilha) para as opções erradas quando a sessão tem poucas. [revanche]: a
/// sessão das teimosas (relembrar → ouvir e escolher → digitar sem dica → digitar de novo no fim).
RoteiroTreino montarRoteiroTreino(
  List<PalavraNova> palavras, {
  List<PalavraNova> reserva = const [],
  math.Random? rnd,
  bool revanche = false,
}) {
  final vistas = <String>{};
  final itens = <ItemTreino>[];
  for (final p in palavras) {
    if (p.en.trim().isEmpty || !vistas.add(p.chave)) continue;
    itens.add(ItemTreino.de(p));
    if (itens.length >= RoteiroTreino.maxPalavras) break;
  }
  final res = <_Candidata>[];
  for (final p in reserva) {
    if (vistas.contains(p.chave)) continue;
    final it = ItemTreino.de(p);
    res.add(_Candidata(it.en, it.pt));
  }
  final r = RoteiroTreino._(itens, res, rnd ?? math.Random());
  return revanche ? (r.._montarRevanche()) : (r.._montar());
}

/// Divide [palavras] em sessões de no máximo [RoteiroTreino.maxPalavras], do mesmo tamanho (12 → 6 + 6).
List<List<PalavraNova>> lotesDeTreino(List<PalavraNova> palavras) {
  final vistas = <String>{};
  final unicas = [for (final p in palavras) if (p.en.trim().isNotEmpty && vistas.add(p.chave)) p];
  if (unicas.isEmpty) return const [];
  final lotes = (unicas.length / RoteiroTreino.maxPalavras).ceil();
  final tamanho = (unicas.length / lotes).ceil();
  return [
    for (var i = 0; i < unicas.length; i += tamanho)
      unicas.sublist(i, math.min(i + tamanho, unicas.length)),
  ];
}
