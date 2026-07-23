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
  const TrechoCarregado(this.cod);
  @override
  List<Object?> get props => [cod];
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
      );

  @override
  List<Object?> get props =>
      [chars, idx, errosTrecho, errosSessao, acertosSessao, score, concluido, ultimoErrou, inicioSessao];
}

// ---------- Bloc ----------
/// Motor de digitação: compara tecla a tecla com o código-alvo.
/// Regras críticas (ver PAC-DART.md §5):
///  - após um \n correto, pula TODOS os espaços de indentação;
///  - Backspace volta toda a indentação auto-consumida até o \n.
class TypingBloc extends Bloc<TypingEvent, TypingState> {
  String _cod = '';

  TypingBloc() : super(const TypingState()) {
    on<TrechoCarregado>(_carregar);
    on<TeclaDigitada>(_digitar);
    on<BackspaceApertado>(_apagar);
    on<TrechoReiniciado>((e, emit) => emit(state.copyWith(
        chars: _cod.split(''), idx: 0, errosTrecho: 0, concluido: false, ultimoErrou: false)));
    on<SessaoZerada>((e, emit) => emit(TypingState(chars: state.chars)));
  }

  void _carregar(TrechoCarregado e, Emitter<TypingState> emit) {
    _cod = e.cod;
    emit(state.copyWith(
        chars: e.cod.split(''), idx: 0, errosTrecho: 0, concluido: false, ultimoErrou: false));
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
  };

  bool _espacoQueSoltaAcento(String tecla, String esperado) {
    if (tecla != ' ' || esperado == ' ') return false;
    final anterior = state.idx > 0 ? state.chars[state.idx - 1] : '';
    // ou o acento acabou de entrar, ou é ele que estamos esperando
    return acentosMortos.contains(anterior) || acentosMortos.contains(esperado);
  }

  void _digitar(TeclaDigitada e, Emitter<TypingState> emit) {
    if (state.concluido || state.idx >= state.chars.length) return;
    final esperado = state.chars[state.idx];
    final tecla = equivalenciasTeclado[e.tecla] ?? e.tecla;
    if (_espacoQueSoltaAcento(tecla, esperado)) return; // engole, sem erro
    final ok = tecla == esperado;
    final inicio = state.inicioSessao ?? DateTime.now();

    if (!ok) {
      emit(state.copyWith(
        errosTrecho: state.errosTrecho + 1,
        errosSessao: state.errosSessao + 1,
        ultimoErrou: true,
        inicioSessao: inicio,
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
    final terminou = idx >= state.chars.length;
    var score = state.score + 1;
    if (terminou) {
      // Bônus de conclusão, descontando erros do trecho.
      score += (25 - state.errosTrecho * 2).clamp(5, 25);
    }
    emit(state.copyWith(
      idx: idx,
      acertosSessao: state.acertosSessao + 1,
      score: score,
      concluido: terminou,
      ultimoErrou: false,
      inicioSessao: inicio,
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
    emit(state.copyWith(idx: idx, ultimoErrou: false));
  }
}
