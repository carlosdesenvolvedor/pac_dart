import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/curriculo_loader.dart';
import '../../data/progresso_repository.dart';
import '../../domain/curriculo.dart';

// ---------- Eventos ----------
sealed class CursoEvent extends Equatable {
  const CursoEvent();
  @override
  List<Object?> get props => const [];
}

class CursoIniciado extends CursoEvent {
  const CursoIniciado();
}

class TrilhaSelecionada extends CursoEvent {
  final int indice;
  const TrilhaSelecionada(this.indice);
  @override
  List<Object?> get props => [indice];
}

class LicaoSelecionada extends CursoEvent {
  final int indice;
  const LicaoSelecionada(this.indice);
  @override
  List<Object?> get props => [indice];
}

/// Enter após concluir um trecho.
class TrechoAvancado extends CursoEvent {
  const TrechoAvancado();
}

class ProximaLicaoPedida extends CursoEvent {
  const ProximaLicaoPedida();
}

class LicaoRepetida extends CursoEvent {
  const LicaoRepetida();
}

/// Quiz da lição terminou com [acertos] de [total].
class QuizFinalizado extends CursoEvent {
  final int trilha, licao, acertos;
  const QuizFinalizado(this.trilha, this.licao, this.acertos);
  @override
  List<Object?> get props => [trilha, licao, acertos];
}

// ---------- Estado ----------
enum CursoStatus { carregando, pronto, erro }

class CursoState extends Equatable {
  final CursoStatus status;
  final List<Trilha> trilhas;
  final int trilhaIdx;
  final int licaoIdx;
  final int trechoIdx;
  final Set<String> concluidas; // chaves "trilha:licao"
  final Map<String, int> quizNotas; // "trilha:licao" → melhores acertos
  final List<Projeto> masterApps; // apps do Teste Master
  final bool vitoria;

  const CursoState({
    this.status = CursoStatus.carregando,
    this.trilhas = const [],
    this.trilhaIdx = 0,
    this.licaoIdx = 0,
    this.trechoIdx = 0,
    this.concluidas = const {},
    this.quizNotas = const {},
    this.masterApps = const [],
    this.vitoria = false,
  });

  Trilha get trilha => trilhas[trilhaIdx];
  Licao get licao => trilha.licoes[licaoIdx];
  Trecho get trecho => licao.trechos[trechoIdx];
  bool get ehFlutter => trilha.nivel == 'Flutter';

  String chave(int t, int l) => '$t:$l';
  bool licaoConcluida(int t, int l) => concluidas.contains(chave(t, l));

  CursoState copyWith({
    CursoStatus? status,
    List<Trilha>? trilhas,
    int? trilhaIdx,
    int? licaoIdx,
    int? trechoIdx,
    Set<String>? concluidas,
    Map<String, int>? quizNotas,
    List<Projeto>? masterApps,
    bool? vitoria,
  }) =>
      CursoState(
        status: status ?? this.status,
        trilhas: trilhas ?? this.trilhas,
        trilhaIdx: trilhaIdx ?? this.trilhaIdx,
        licaoIdx: licaoIdx ?? this.licaoIdx,
        trechoIdx: trechoIdx ?? this.trechoIdx,
        concluidas: concluidas ?? this.concluidas,
        quizNotas: quizNotas ?? this.quizNotas,
        masterApps: masterApps ?? this.masterApps,
        vitoria: vitoria ?? this.vitoria,
      );

  @override
  List<Object?> get props =>
      [status, trilhas, trilhaIdx, licaoIdx, trechoIdx, concluidas, quizNotas, masterApps, vitoria];
}

// ---------- Bloc ----------
class CursoBloc extends Bloc<CursoEvent, CursoState> {
  final CurriculoLoader loader;
  final ProgressoRepository progresso;

  CursoBloc({required this.loader, required this.progresso}) : super(const CursoState()) {
    on<CursoIniciado>(_iniciar);
    on<TrilhaSelecionada>(_selecionarTrilha);
    on<LicaoSelecionada>(_selecionarLicao);
    on<TrechoAvancado>(_avancarTrecho);
    on<ProximaLicaoPedida>(_proximaLicao);
    on<LicaoRepetida>((e, emit) => emit(state.copyWith(trechoIdx: 0, vitoria: false)));
    on<QuizFinalizado>(_quizFinalizado);
  }

  void _quizFinalizado(QuizFinalizado e, Emitter<CursoState> emit) {
    final chave = state.chave(e.trilha, e.licao);
    final melhor = state.quizNotas[chave] ?? -1;
    if (e.acertos > melhor) {
      emit(state.copyWith(quizNotas: {...state.quizNotas, chave: e.acertos}));
    }
    progresso.salvarQuizNota(chave, e.acertos);
  }

  Future<void> _iniciar(CursoIniciado e, Emitter<CursoState> emit) async {
    try {
      final trilhas = await loader.carregar();
      final master = await loader.carregarMaster();
      final feitas = await progresso.concluidas();
      final notas = await progresso.quizNotas();
      final (t, l) = await progresso.posicao();
      final ti = t.clamp(0, trilhas.length - 1);
      final li = l.clamp(0, trilhas[ti].licoes.length - 1);
      emit(state.copyWith(
        status: CursoStatus.pronto,
        trilhas: trilhas,
        masterApps: master,
        trilhaIdx: ti,
        licaoIdx: li,
        trechoIdx: 0,
        concluidas: feitas,
        quizNotas: notas,
      ));
    } catch (_) {
      emit(state.copyWith(status: CursoStatus.erro));
    }
  }

  void _selecionarTrilha(TrilhaSelecionada e, Emitter<CursoState> emit) {
    emit(state.copyWith(trilhaIdx: e.indice, licaoIdx: 0, trechoIdx: 0, vitoria: false));
    progresso.salvarPosicao(e.indice, 0);
  }

  void _selecionarLicao(LicaoSelecionada e, Emitter<CursoState> emit) {
    emit(state.copyWith(licaoIdx: e.indice, trechoIdx: 0, vitoria: false));
    progresso.salvarPosicao(state.trilhaIdx, e.indice);
  }

  void _avancarTrecho(TrechoAvancado e, Emitter<CursoState> emit) {
    if (state.trechoIdx < state.licao.trechos.length - 1) {
      emit(state.copyWith(trechoIdx: state.trechoIdx + 1));
      return;
    }
    // Fim da lição: marca concluída e mostra a vitória.
    final chave = state.chave(state.trilhaIdx, state.licaoIdx);
    progresso.marcarConcluida(chave);
    emit(state.copyWith(concluidas: {...state.concluidas, chave}, vitoria: true));
  }

  void _proximaLicao(ProximaLicaoPedida e, Emitter<CursoState> emit) {
    var t = state.trilhaIdx, l = state.licaoIdx + 1;
    if (l >= state.trilha.licoes.length) {
      t = (t + 1) % state.trilhas.length;
      l = 0;
    }
    emit(state.copyWith(trilhaIdx: t, licaoIdx: l, trechoIdx: 0, vitoria: false));
    progresso.salvarPosicao(t, l);
  }
}
