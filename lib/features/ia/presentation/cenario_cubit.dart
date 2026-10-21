import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../tutor/data/falha_ia.dart';
import '../domain/cenario.dart';
import '../domain/conversa_resposta.dart';
import '../domain/nivel_conversa.dart';
import '../domain/prompt_conversa.dart';
import '../domain/seguranca_texto.dart';
import '../domain/sessao_cenario.dart';
import 'ia_cubit.dart';

/// O que deu errado na última tentativa (a tela mostra a mensagem certa).
enum ErroCenario { nenhum, semCota, limite, limiteDia, ocupado, semRede, indisponivel, recusada, falhou }

class CenarioState extends Equatable {
  final SessaoCenario sessao;

  /// Esperando a resposta do personagem (e a correção do Prof. Dash).
  final bool aguardando;

  final ErroCenario erro;

  /// A fala que não foi (falha ou sem cota): volta para o campo, sem a pessoa digitar de novo.
  final String? falaPendente;

  /// Até quando a IA descansa (429/503/401): o Enviar fica desligado e o Enter não manda nada.
  final DateTime? esperaAte;

  /// O resumo local do fim da conversa (0 usos).
  final ResumoConversa? resumo;

  const CenarioState({
    required this.sessao,
    this.aguardando = false,
    this.erro = ErroCenario.nenhum,
    this.falaPendente,
    this.esperaAte,
    this.resumo,
  });

  bool get terminou => resumo != null;

  CenarioState copyWith({
    SessaoCenario? sessao,
    bool? aguardando,
    ErroCenario? erro,
    String? falaPendente,
    bool limparFala = false,
    DateTime? esperaAte,
    bool limparEspera = false,
    ResumoConversa? resumo,
  }) =>
      CenarioState(
        sessao: sessao ?? this.sessao,
        aguardando: aguardando ?? this.aguardando,
        erro: erro ?? this.erro,
        falaPendente: limparFala ? null : (falaPendente ?? this.falaPendente),
        esperaAte: limparEspera ? null : (esperaAte ?? this.esperaAte),
        resumo: resumo ?? this.resumo,
      );

  @override
  List<Object?> get props => [sessao, aguardando, erro, falaPendente, esperaAte, resumo];
}

/// Uma Conversa com IA: cada fala da pessoa é UMA chamada (JSON com a resposta do personagem e a
/// correção do Prof. Dash) e gasta 1 uso pelo [IaCubit] — só quando a resposta serve. O resumo do
/// fim é local (0 usos). Nada é salvo se a pessoa sair no meio.
class CenarioCubit extends Cubit<CenarioState> {
  final IaCubit ia;

  /// O nível da conversa ('A1'…'C1'): vai ao prompt.
  final String nivel;

  /// Palavras que o aluno já estudou (só vão ao prompt em A1/A2).
  final List<String> vocabulario;

  /// Cada fala respondida conta 1 prática do hábito do dia.
  final void Function()? aoPraticar;

  CenarioCubit({
    required this.ia,
    required Cenario cenario,
    required this.nivel,
    this.vocabulario = const [],
    this.aoPraticar,
  }) : super(CenarioState(sessao: SessaoCenario.nova(cenario)));

  Cenario get cenario => state.sessao.cenario;

  /// = ia.agora(): o ÚNICO relógio da contagem e da trava do Enter.
  DateTime agora() => ia.agora();

  /// A IA está na janela de descanso.
  bool get emEspera => state.esperaAte != null && agora().isBefore(state.esperaAte!);

  /// A pessoa fala; o personagem responde e o Prof. Dash corrige (1 uso). Sem saldo, com falha ou na
  /// janela de descanso, a fala volta para o campo e nada é gasto.
  Future<void> enviar(String texto) async {
    final s = state;
    if (s.aguardando || s.terminou || !s.sessao.podeFalar || emEspera) return;
    final depois = s.sessao.aluno(texto);
    if (depois.turnosDoAluno == s.sessao.turnosDoAluno) return; // vazia
    final fala = depois.turnos.last.texto;
    emit(s.copyWith(sessao: depois, aguardando: true, erro: ErroCenario.nenhum, limparFala: true, limparEspera: true));

    // a máscara uma vez só: o que vai ao modelo é o que o interpretar compara
    final m = mascarar(semMarcadores(fala));
    final r = await ia.consultarJson(
      persona: personaConversa(cenario, nivel: nivel),
      contexto: contextoConversa(depois, nivel: nivel, vocabulario: nivelIniciante(nivel) ? vocabulario : const []),
      historico: depois.historicoParaResposta(),
      pergunta: perguntaDoTurno(m),
      esquema: esquemaTurno,
      formatoTexto: formatoTurnoTexto,
      aceitar: (t) => RespostaTurno.interpretar(t, falaEnviada: m.texto, trechos: m.trechos) != null,
    );
    if (isClosed) return;
    final resp = r.status == StatusIa.ok ? RespostaTurno.interpretar(r.texto, falaEnviada: m.texto, trechos: m.trechos) : null;
    if (resp != null) {
      final nova = state.sessao.responder(resp);
      aoPraticar?.call();
      emit(state.copyWith(
        sessao: nova,
        aguardando: false,
        limparEspera: true,
        resumo: nova.encerrada ? ResumoConversa.de(nova) : null,
      ));
      return;
    }
    final erro = r.status == StatusIa.semCota ? ErroCenario.semCota : erroDoMotivo(r.motivo);
    final janela = ia.descanso.ativo(agora()) ? ia.descanso.ate : ia.state.esperaAte;
    emit(CenarioState(
      sessao: state.sessao.semUltimaFala(),
      erro: erro,
      falaPendente: fala,
      esperaAte: janela,
    ));
  }

  /// Termina a conversa: o resumo é local e síncrono (nenhuma IA). Sem fala respondida não há resumo.
  void terminar() {
    final s = state;
    if (s.aguardando || s.terminou) return;
    // uma fala sem resposta (falhou) não entra no resumo
    final sessao = s.sessao.esperandoDash ? s.sessao.semUltimaFala() : s.sessao;
    if (sessao.turnosDoAluno == 0) return;
    emit(s.copyWith(sessao: sessao, erro: ErroCenario.nenhum, limparFala: true, resumo: ResumoConversa.de(sessao)));
  }

  /// O motivo da falha (do [IaCubit]) → o aviso da tela.
  static ErroCenario erroDoMotivo(TipoFalhaIa? m) => switch (m) {
        TipoFalhaIa.limite => ErroCenario.limite,
        TipoFalhaIa.limiteDiario => ErroCenario.limiteDia,
        TipoFalhaIa.ocupado => ErroCenario.ocupado,
        TipoFalhaIa.semRede => ErroCenario.semRede,
        TipoFalhaIa.credencial => ErroCenario.indisponivel,
        TipoFalhaIa.recusada => ErroCenario.recusada,
        TipoFalhaIa.outro || null => ErroCenario.falhou,
      };
}
