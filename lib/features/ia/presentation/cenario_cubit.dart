import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/cenario.dart';
import '../domain/sessao_cenario.dart';
import 'ia_cubit.dart';

/// O que deu errado na última tentativa (a tela mostra a mensagem certa).
enum ErroCenario { nenhum, semCota, falhou }

class CenarioState extends Equatable {
  final SessaoCenario sessao;

  /// Esperando o Prof. Dash (resposta de um turno ou o feedback).
  final bool aguardando;

  /// Gerando o feedback.
  final bool gerandoFeedback;

  final ErroCenario erro;

  /// A fala que não foi (falha ou sem cota): volta para o campo, sem a pessoa digitar de novo.
  final String? falaPendente;

  final FeedbackCenario? feedback;

  /// O feedback não pôde ser pedido por falta de cota: a tela mostra um resumo local e gentil.
  final bool feedbackLocal;

  const CenarioState({
    required this.sessao,
    this.aguardando = false,
    this.gerandoFeedback = false,
    this.erro = ErroCenario.nenhum,
    this.falaPendente,
    this.feedback,
    this.feedbackLocal = false,
  });

  bool get terminou => feedback != null || feedbackLocal;

  CenarioState copyWith({
    SessaoCenario? sessao,
    bool? aguardando,
    bool? gerandoFeedback,
    ErroCenario? erro,
    String? falaPendente,
    bool limparFala = false,
    FeedbackCenario? feedback,
    bool? feedbackLocal,
  }) =>
      CenarioState(
        sessao: sessao ?? this.sessao,
        aguardando: aguardando ?? this.aguardando,
        gerandoFeedback: gerandoFeedback ?? this.gerandoFeedback,
        erro: erro ?? this.erro,
        falaPendente: limparFala ? null : (falaPendente ?? this.falaPendente),
        feedback: feedback ?? this.feedback,
        feedbackLocal: feedbackLocal ?? this.feedbackLocal,
      );

  @override
  List<Object?> get props => [sessao, aguardando, gerandoFeedback, erro, falaPendente, feedback, feedbackLocal];
}

/// Uma conversa de cenário: cada fala da pessoa (resposta do Dash) e o feedback gastam 1 uso da
/// cota pelo [IaCubit]. Nada é salvo se a pessoa sair no meio (só o feedback pode virar cartão).
class CenarioCubit extends Cubit<CenarioState> {
  final IaCubit ia;

  CenarioCubit({required this.ia, required Cenario cenario}) : super(CenarioState(sessao: SessaoCenario.nova(cenario)));

  Cenario get cenario => state.sessao.cenario;

  /// A pessoa fala. O Dash responde (1 uso). Sem saldo ou com falha, a fala volta para o campo.
  Future<void> enviar(String texto) async {
    final s = state;
    if (s.aguardando || s.terminou || !s.sessao.podeFalar) return;
    final depois = s.sessao.aluno(texto);
    if (identical(depois, s.sessao) || depois == s.sessao) return; // vazia
    final fala = depois.turnos.last.texto;
    emit(s.copyWith(sessao: depois, aguardando: true, erro: ErroCenario.nenhum, limparFala: true));

    final r = await ia.consultar(
      contexto: contextoDoTurno(depois, comPersona: true),
      historico: depois.historicoParaResposta(),
      pergunta: fala,
      persona: personaCenario(cenario),
    );
    if (isClosed) return;
    switch (r.status) {
      case StatusIa.ok:
        emit(state.copyWith(sessao: state.sessao.dash(r.texto), aguardando: false));
      case StatusIa.semCota:
        emit(state.copyWith(sessao: state.sessao.semUltimaFala(), aguardando: false, erro: ErroCenario.semCota, falaPendente: fala));
      case StatusIa.falhou:
        emit(state.copyWith(sessao: state.sessao.semUltimaFala(), aguardando: false, erro: ErroCenario.falhou, falaPendente: fala));
    }
  }

  /// Termina e pede o feedback (1 uso). Sem fala nenhuma não há o que avaliar; sem saldo, um resumo local.
  Future<void> terminar() async {
    final s = state;
    if (s.aguardando || s.terminou || s.sessao.turnosDoAluno == 0) return;
    // a última fala ficou sem resposta (falhou): o feedback avalia só o que foi respondido
    final sessao = s.sessao.esperandoDash ? s.sessao.semUltimaFala() : s.sessao;
    if (sessao.turnosDoAluno == 0) return;
    emit(s.copyWith(sessao: sessao, aguardando: true, gerandoFeedback: true, erro: ErroCenario.nenhum, limparFala: true));
    final p = pedidoDeFeedback(sessao);
    final r = await ia.consultar(contexto: p.contexto, pergunta: p.pergunta);
    if (isClosed) return;
    switch (r.status) {
      case StatusIa.ok:
        emit(state.copyWith(aguardando: false, gerandoFeedback: false, feedback: FeedbackCenario.interpretar(r.texto)));
      case StatusIa.semCota:
        emit(state.copyWith(aguardando: false, gerandoFeedback: false, feedbackLocal: true, erro: ErroCenario.semCota));
      case StatusIa.falhou:
        emit(state.copyWith(aguardando: false, gerandoFeedback: false, erro: ErroCenario.falhou));
    }
  }
}
