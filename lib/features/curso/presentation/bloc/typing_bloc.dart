import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ---------- Eventos ----------
sealed class TypingEvent extends Equatable {
  const TypingEvent();
  @override
  List<Object?> get props => const [];
}

class TrechoCarregado extends TypingEvent {
  final String cod;

  /// Correção tolerante (frases de inglês digitadas de memória): a
  /// pontuação de fim de palavra (`, . ! ? ; : "`) é preenchida sozinha e a
  /// maiúscula da 1ª letra da frase fica livre. Apóstrofo, hífen e as
  /// outras maiúsculas (I, nomes, dias, meses) continuam exigidos.
  final bool tolerante;

  /// Outras formas aceitas (contrações, `alt` do autor): na primeira tecla
  /// que diverge do texto mas segue uma delas, o alvo passa a ser ela.
  final List<String> alternativas;

  const TrechoCarregado(this.cod, {this.tolerante = false, this.alternativas = const []});
  @override
  List<Object?> get props => [cod, tolerante, alternativas];
}

class TeclaDigitada extends TypingEvent {
  final String tecla; // um caractere (ou '\n')
  const TeclaDigitada(this.tecla);
  @override
  List<Object?> get props => [tecla];
}

class BackspaceApertado extends TypingEvent {
  const BackspaceApertado();
}

class TrechoReiniciado extends TypingEvent {
  const TrechoReiniciado();
}

class SessaoZerada extends TypingEvent {
  const SessaoZerada();
}

// ---------- Estado ----------
class TypingState extends Equatable {
  final List<String> chars;
  final int idx;

  /// Erros no trecho atual (para pontuar) e na sessão inteira (HUD).
  final int errosTrecho;
  final int errosSessao;
  final int acertosSessao;
  final int score;
  final bool concluido;
  final bool ultimoErrou; // para animar o caractere atual em vermelho
  final DateTime? inicioSessao;

  /// Teclas erradas por POSIÇÃO no trecho atual — para avaliar a memória
  /// palavra a palavra (dez teclas erradas no mesmo lugar são um lugar só).
  /// Não inclui os erros só de maiúscula/minúscula ([errosDeCaixa]).
  final Map<int, int> errosPorPosicao;

  /// Letra certa com a caixa errada ("monday"): conta no placar, mas não
  /// derruba a palavra na nota (é quase motor; o app avisa da regra).
  final Map<int, int> errosDeCaixa;

  const TypingState({
    this.chars = const [],
    this.idx = 0,
    this.errosTrecho = 0,
    this.errosSessao = 0,
    this.acertosSessao = 0,
    this.score = 0,
    this.concluido = false,
    this.ultimoErrou = false,
    this.inicioSessao,
    this.errosPorPosicao = const {},
    this.errosDeCaixa = const {},
  });

  double get progresso => chars.isEmpty ? 0 : (idx / chars.length).clamp(0, 1).toDouble();

  int get precisao {
    final total = acertosSessao + errosSessao;
    return total == 0 ? 100 : (acertosSessao * 100 / total).round();
  }

  /// PPM: 5 toques corretos = 1 palavra.
  int ppm(DateTime agora) {
    final ini = inicioSessao;
    if (ini == null) return 0;
    final min = agora.difference(ini).inMilliseconds / 60000.0;
    if (min <= 0) return 0;
    return (acertosSessao / 5 / min).round();
  }

  TypingState copyWith({
    List<String>? chars,
    int? idx,
    int? errosTrecho,
    int? errosSessao,
    int? acertosSessao,
    int? score,
    bool? concluido,
    bool? ultimoErrou,
    DateTime? inicioSessao,
    bool zerarInicio = false,
    Map<int, int>? errosPorPosicao,
    Map<int, int>? errosDeCaixa,
  }) =>
      TypingState(
        chars: chars ?? this.chars,
        idx: idx ?? this.idx,
        errosTrecho: errosTrecho ?? this.errosTrecho,
        errosSessao: errosSessao ?? this.errosSessao,
        acertosSessao: acertosSessao ?? this.acertosSessao,
        score: score ?? this.score,
        concluido: concluido ?? this.concluido,
        ultimoErrou: ultimoErrou ?? this.ultimoErrou,
        inicioSessao: zerarInicio ? null : (inicioSessao ?? this.inicioSessao),
        errosPorPosicao: errosPorPosicao ?? this.errosPorPosicao,
        errosDeCaixa: errosDeCaixa ?? this.errosDeCaixa,
      );

  @override
  List<Object?> get props => [
        chars,
        idx,
        errosTrecho,
        errosSessao,
        acertosSessao,
        score,
        concluido,
        ultimoErrou,
        inicioSessao,
        errosPorPosicao,
        errosDeCaixa,
      ];
}

// ---------- Bloc ----------
/// Motor de digitação: compara tecla a tecla com o código-alvo.
/// Regras críticas (ver PAC-DART.md §5):
///  - após um \n correto, pula TODOS os espaços de indentação;
///  - Backspace volta toda a indentação auto-consumida até o \n.
class TypingBloc extends Bloc<TypingEvent, TypingState> {
  String _cod = '';
  bool _tolerante = false;
  List<String> _alternativas = const [];

  /// Posições preenchidas sozinhas (pontuação no modo tolerante): se a
  /// pessoa digitar o sinal mesmo assim, não duplica nem conta erro.
  final Set<int> _automaticas = {};

  /// A última tecla crua foi um sinal que pode ser tecla morta (o espaço
  /// que vem atrás só "soltou" o sinal).
  bool _sinalMorto = false;

  TypingBloc() : super(const TypingState()) {
    on<TrechoCarregado>(_carregar);
    on<TeclaDigitada>(_digitar);
    on<BackspaceApertado>(_apagar);
    on<TrechoReiniciado>((e, emit) {
      _automaticas.clear();
      _sinalMorto = false;
      emit(state.copyWith(
          chars: _cod.split(''),
          idx: 0,
          errosTrecho: 0,
          concluido: false,
          ultimoErrou: false,
          errosPorPosicao: const {},
          errosDeCaixa: const {}));
      _pularAutomaticas(emit);
    });
    on<SessaoZerada>((e, emit) => emit(TypingState(chars: state.chars)));
  }

  void _carregar(TrechoCarregado e, Emitter<TypingState> emit) {
    _cod = normalizarTexto(e.cod);
    _tolerante = e.tolerante;
    _alternativas = [for (final a in e.alternativas) normalizarTexto(a)];
    _automaticas.clear();
    _sinalMorto = false;
    emit(state.copyWith(
        chars: _cod.split(''),
        idx: 0,
        errosTrecho: 0,
        concluido: false,
        ultimoErrou: false,
        errosPorPosicao: const {},
        errosDeCaixa: const {}));
    _pularAutomaticas(emit);
  }

  /// Acentos do teclado ABNT são TECLA MORTA: `~ ^ ´ \`` só saem depois da
  /// próxima tecla, e quem "solta" o acento sozinho é o ESPAÇO. Esse espaço
  /// chega aqui como uma tecla a mais — e não é erro de ninguém.
  /// (Sem isso, todo `~/` do Dart custava um erro. Ver PAC-DART.md.)
  static const acentosMortos = {'~', '^', '´', '`'};

  /// Variantes que alguns teclados soltam no lugar do ASCII esperado.
  /// No Mac, `~` + espaço produz U+02DC (˜) — que NÃO é o `~` do Dart — e
  /// teclados móveis trocam aspas retas por curvas e hífen por travessão.
  static const equivalenciasTeclado = {
    '˜': '~', // U+02DC small tilde (Mac, tecla morta + espaço)
    '∼': '~', // U+223C tilde operator
    'ˆ': '^', // U+02C6 modifier circumflex (Mac)
    '‘': "'", '’': "'", // aspas simples curvas
    '“': '"', '”': '"', // aspas duplas curvas
    '–': '-', '—': '-', // en/em dash de autocorreção
    ' ': ' ', ' ': ' ', ' ': ' ', ' ': ' ', '　': ' ', // espaços "especiais" (Option+Espaço)
  };

  /// Variantes aceitas SÓ quando o esperado é o caractere-chave — no
  /// ABNT2 é comum digitar o acento ´ no lugar do apóstrofo ("don´t").
  static const variantesContextuais = {
    "'": {'´', '`', '‛', 'ʼ', '′', '＇'},
    '"': {'„', '‟', '″', '＂'},
    '-': {'‐', '‑', '‒', '−'},
  };

  /// Caracteres invisíveis que alguns sistemas inserem: ignorados.
  static const invisiveis = {'​', '‌', '‍', '⁠', '﻿', '­'};

  /// Normaliza o texto-alvo com a mesma tabela (rede de segurança: um ’
  /// que escape no conteúdo não vira uma letra impossível de digitar).
  static String normalizarTexto(String s) {
    final b = StringBuffer();
    for (final ch in s.split('')) {
      if (invisiveis.contains(ch)) continue;
      b.write(equivalenciasTeclado[ch] ?? (ch == '…' ? '...' : ch));
    }
    return b.toString();
  }

  /// Layout US-International (muito usado no Brasil): `'`, `"`, `` ` ``, `~`
  /// e `^` são teclas mortas e se FUNDEM com a letra seguinte — `'` + `c`
  /// sai `ç`, `'` + `a` sai `á`, `"` + `u` sai `ü`. Quando o esperado é o
  /// sinal e a letra fundida bate com o próximo caractere (o'clock, 'a'),
  /// a tecla vale pelos dois.
  static const composicoesUsIntl = {
    "'": {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ý': 'y', 'ç': 'c',
      'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ý': 'Y', 'Ç': 'C'},
    '"': {'ä': 'a', 'ë': 'e', 'ï': 'i', 'ö': 'o', 'ü': 'u', 'ÿ': 'y',
      'Ä': 'A', 'Ë': 'E', 'Ï': 'I', 'Ö': 'O', 'Ü': 'U'},
    '`': {'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u', 'À': 'A', 'È': 'E', 'Ì': 'I', 'Ò': 'O', 'Ù': 'U'},
    '~': {'ã': 'a', 'õ': 'o', 'ñ': 'n', 'Ã': 'A', 'Õ': 'O', 'Ñ': 'N'},
    '^': {'â': 'a', 'ê': 'e', 'î': 'i', 'ô': 'o', 'û': 'u', 'Â': 'A', 'Ê': 'E', 'Î': 'I', 'Ô': 'O', 'Û': 'U'},
  };

  /// Pontuação que o modo tolerante preenche sozinho.
  static const pontuacaoAutomatica = {',', '.', '!', '?', ';', ':', '"'};

  /// A letra fundida [tecla] desdobrada em sinal + letra, se é isso que o
  /// texto espera a partir da posição atual; senão null.
  String? _desdobraComposicao(String tecla, String esperado) {
    final letra = composicoesUsIntl[esperado]?[tecla];
    if (letra == null || state.idx + 1 >= state.chars.length) return null;
    return state.chars[state.idx + 1] == letra ? letra : null;
  }

  bool _espacoQueSoltaAcento(String tecla, String esperado) {
    if (tecla != ' ' || esperado == ' ') return false;
    final anterior = state.idx > 0 ? state.chars[state.idx - 1] : '';
    // ou o acento acabou de entrar, ou é ele que estamos esperando
    if (acentosMortos.contains(anterior) || acentosMortos.contains(esperado)) return true;
    // ' e " mortos (US-Intl) também se soltam com espaço; e espaço repetido
    // nunca é erro de memória (ninguém exige dois espaços)
    return _sinalMorto || anterior == ' ';
  }

  void _digitar(TeclaDigitada e, Emitter<TypingState> emit) {
    if (state.concluido || state.idx >= state.chars.length) return;
    if (invisiveis.contains(e.tecla)) return;
    final esperado = state.chars[state.idx];
    var tecla = equivalenciasTeclado[e.tecla] ?? e.tecla;
    if (tecla != esperado && (variantesContextuais[esperado]?.contains(tecla) ?? false)) tecla = esperado;
    final engole = _espacoQueSoltaAcento(tecla, esperado);
    _sinalMorto = tecla == "'" || tecla == '"' || acentosMortos.contains(e.tecla);
    if (engole) return; // engole, sem erro
    // o sinal que o modo tolerante já preencheu: digitar de novo não conta
    if (state.idx > 0 && _automaticas.contains(state.idx - 1) && state.chars[state.idx - 1] == tecla) return;
    if (tecla == '…' && _seguem(esperado, '...')) {
      for (var k = 0; k < 3; k++) {
        _uma('.', emit);
      }
      return;
    }
    final letra = tecla == esperado ? null : _desdobraComposicao(tecla, esperado);
    if (letra != null) {
      _uma(esperado, emit);
      _uma(letra, emit);
      return;
    }
    _uma(tecla, emit);
  }

  bool _seguem(String esperado, String texto) {
    final i = state.idx;
    return i + texto.length <= state.chars.length && state.chars.sublist(i, i + texto.length).join() == texto;
  }

  /// 1ª letra (de verdade) da frase — a que o modo tolerante deixa livre.
  bool _primeiraLetra(int i) {
    for (var k = 0; k < i; k++) {
      if (RegExp(r'[A-Za-z0-9]').hasMatch(state.chars[k])) return false;
    }
    return true;
  }

  /// Uma forma aceita que segue o que já foi digitado e continua com
  /// [tecla] — o alvo troca para ela (ex.: "I am" no lugar de "I'm").
  String? _alternativaPara(String tecla) {
    if (_alternativas.isEmpty) return null;
    final prefixo = '${state.chars.sublist(0, state.idx).join()}$tecla';
    final atual = state.chars.join();
    for (final a in _alternativas) {
      if (a != atual && a.startsWith(prefixo)) return a;
    }
    return null;
  }

  /// Confere UMA tecla já normalizada contra o caractere esperado.
  void _uma(String tecla, Emitter<TypingState> emit) {
    if (state.concluido || state.idx >= state.chars.length) return;
    var esperado = state.chars[state.idx];
    if (tecla != esperado) {
      final alt = _alternativaPara(tecla);
      if (alt != null) {
        emit(state.copyWith(chars: alt.split('')));
        esperado = tecla;
      }
    }
    var ok = tecla == esperado;
    final soCaixa = !ok && tecla.toLowerCase() == esperado.toLowerCase();
    if (soCaixa && _tolerante && _primeiraLetra(state.idx)) ok = true;
    final inicio = state.inicioSessao ?? DateTime.now();

    if (!ok) {
      final pos = Map<int, int>.of(soCaixa ? state.errosDeCaixa : state.errosPorPosicao);
      pos[state.idx] = (pos[state.idx] ?? 0) + 1;
      emit(state.copyWith(
        errosTrecho: state.errosTrecho + 1,
        errosSessao: state.errosSessao + 1,
        ultimoErrou: true,
        inicioSessao: inicio,
        errosPorPosicao: soCaixa ? null : pos,
        errosDeCaixa: soCaixa ? pos : null,
      ));
      return;
    }

    var idx = state.idx + 1;
    if (tecla == '\n') {
      // Auto-indentação: pula TODOS os espaços do começo da linha.
      while (idx < state.chars.length && state.chars[idx] == ' ') {
        idx++;
      }
    }
    emit(state.copyWith(
      idx: idx,
      acertosSessao: state.acertosSessao + 1,
      score: state.score + 1,
      ultimoErrou: false,
      inicioSessao: inicio,
    ));
    _pularAutomaticas(emit);
    _verificaFim(emit);
  }

  /// Modo tolerante: avança sozinho pela pontuação de fim de palavra (a
  /// que vem antes de espaço, de outra pontuação ou do fim da frase —
  /// "7:30" e "U.S" no meio da palavra continuam sendo digitados).
  void _pularAutomaticas(Emitter<TypingState> emit) {
    if (!_tolerante) return;
    var idx = state.idx;
    while (idx < state.chars.length && pontuacaoAutomatica.contains(state.chars[idx])) {
      final depois = idx + 1 < state.chars.length ? state.chars[idx + 1] : ' ';
      final fimDePalavra = depois == ' ' || pontuacaoAutomatica.contains(depois);
      final abreAspas = state.chars[idx] == '"' && (idx == 0 || state.chars[idx - 1] == ' ');
      if (!fimDePalavra && !abreAspas) break;
      _automaticas.add(idx);
      idx++;
    }
    if (idx != state.idx) emit(state.copyWith(idx: idx));
  }

  void _verificaFim(Emitter<TypingState> emit) {
    if (state.concluido || state.idx < state.chars.length) return;
    // Bônus de conclusão, descontando erros do trecho.
    emit(state.copyWith(
      score: state.score + (25 - state.errosTrecho * 2).clamp(5, 25),
      concluido: true,
    ));
  }

  void _apagar(BackspaceApertado e, Emitter<TypingState> emit) {
    if (state.concluido || state.idx <= 0) return;
    var idx = state.idx - 1;
    // Volta por TODA a indentação auto-consumida até o \n.
    while (idx > 0 &&
        state.chars[idx] == ' ' &&
        (state.chars[idx - 1] == ' ' || state.chars[idx - 1] == '\n')) {
      idx--;
    }
    // ...e pela pontuação que o modo tolerante preencheu sozinho
    while (idx > 0 && _automaticas.contains(idx)) {
      _automaticas.remove(idx);
      idx--;
    }
    emit(state.copyWith(idx: idx, ultimoErrou: false));
  }
}
