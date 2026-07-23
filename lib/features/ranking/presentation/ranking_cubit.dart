import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../curso/presentation/bloc/typing_bloc.dart';
import '../data/ranking_repository.dart';
import '../domain/jogador_ranking.dart';

enum RankingStatus { inicial, carregando, pronto, erro }

class RankingState extends Equatable {
  final RankingStatus status;
  final List<JogadorRanking> jogadores;

  const RankingState({this.status = RankingStatus.inicial, this.jogadores = const []});

  RankingState copyWith({RankingStatus? status, List<JogadorRanking>? jogadores}) =>
      RankingState(status: status ?? this.status, jogadores: jogadores ?? this.jogadores);

  /// A linha do próprio jogador (se já publicou algo).
  JogadorRanking? meu(String uid) {
    for (final j in jogadores) {
      if (j.uid == uid) return j;
    }
    return null;
  }

  @override
  List<Object?> get props => [status, jogadores];
}

/// Publica as conquistas do jogador no placar público e carrega o top.
///
/// A digitação é publicada por DELTA: o TypingBloc global acumula
/// score/acertos/erros pela sessão inteira, então o cubit guarda uma régua
/// do último envio e manda só a diferença. Toda escrita é best-effort —
/// sem internet o jogo segue e a diferença entra no próximo envio.
class RankingCubit extends Cubit<RankingState> {
  final RankingRepository repo;
  final String uid;
  final String apelido;

  int _basePontos = 0, _baseTeclas = 0, _baseErros = 0;

  /// Deltas que não subiram (sem rede) — fundem no próximo envio.
  final Map<String, int> _pendente = {};

  RankingCubit({required this.repo, required this.uid, required this.apelido})
      : super(const RankingState());

  /// O cubit vive no ramo autenticado do app; em árvores sem ele
  /// (testes de tela antigos), tudo vira um no-op silencioso.
  static RankingCubit? de(BuildContext context) {
    try {
      return context.read<RankingCubit>();
    } catch (_) {
      return null;
    }
  }

  Map<String, int> _deltaDigitacao(TypingState st) {
    if (st.score < _basePontos || st.acertosSessao < _baseTeclas || st.errosSessao < _baseErros) {
      // a sessão foi zerada: recomeça a régua sem mandar delta negativo
      _basePontos = 0;
      _baseTeclas = 0;
      _baseErros = 0;
    }
    final delta = {
      'pontos': st.score - _basePontos,
      'teclas': st.acertosSessao - _baseTeclas,
      'erros': st.errosSessao - _baseErros,
    };
    _basePontos = st.score;
    _baseTeclas = st.acertosSessao;
    _baseErros = st.errosSessao;
    return delta;
  }

  /// Lição digitada até o fim (o [st] é do TypingBloc GLOBAL).
  Future<void> licaoConcluida(TypingState st) =>
      _soma({..._deltaDigitacao(st), 'licoes': 1});

  /// Projeto/app digitado até o fim ([st] é do TypingBloc LOCAL da tela,
  /// criado zerado ao abrir o projeto — vai inteiro, sem régua).
  Future<void> projetoConcluido(TypingState st) => _soma({
        'pontos': st.score,
        'teclas': st.acertosSessao,
        'erros': st.errosSessao,
        'projetos': 1,
      });

  /// Quiz respondido: cada acerto vale 10 pontos no placar geral.
  Future<void> quizRespondido(int acertos, int total) =>
      _soma({'pontos': acertos * 10, 'quizAcertos': acertos});

  /// Missão do Lógica Animada cumprida.
  Future<void> missaoConcluida(int pontos) =>
      _soma({'pontos': pontos, 'missoes': 1});

  /// Partida de arcade encerrada. Devolve se a pontuação virou recorde
  /// pessoal do joguinho.
  Future<bool> arcadeJogado(String jogo, int pontos) async {
    await _soma({'pontos': pontos, 'arcadePontos': pontos});
    try {
      return await repo.salvarRecordeArcade(uid, apelido, jogo, pontos);
    } catch (_) {
      return false;
    }
  }

  Future<void> _soma(Map<String, int> deltas) async {
    final tudo = {..._pendente};
    deltas.forEach((k, v) => tudo[k] = (tudo[k] ?? 0) + v);
    try {
      await repo.somar(uid, apelido, tudo);
      _pendente.clear();
    } catch (_) {
      // sem rede: guarda tudo para a próxima conquista reenviar
      _pendente
        ..clear()
        ..addAll(tudo);
    }
  }

  Future<void> carregarTop() async {
    emit(state.copyWith(status: RankingStatus.carregando));
    try {
      emit(state.copyWith(status: RankingStatus.pronto, jogadores: await repo.top()));
    } catch (_) {
      emit(state.copyWith(status: RankingStatus.erro));
    }
  }
}
