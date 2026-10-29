import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/arquivos_triagem.dart';
import '../domain/config_triagem.dart';
import '../domain/decisoes.dart';
import '../domain/estudo.dart';
import '../domain/orquestrador_triagem.dart';
import '../domain/portas.dart';

enum StatusTriagem { vazio, pronto, rodando, concluido }

/// Monta os clientes da rodada. [real] = chamar os modelos de verdade pelo Worker; senão, simulados.
typedef FabricaClientes = (IDecisionModelClient, ILlmClient) Function(ConfigTriagem config, {required bool real});

class TriagemState extends Equatable {
  final StatusTriagem status;
  final ProjetoTriagem? projeto;
  final ConfigTriagem config;
  final RodadaTriagem? rodada;

  /// "Etapa 1 — 3/24" enquanto roda.
  final String etapa;

  /// Chamar os modelos reais (precisa do Worker) ou usar os simulados.
  final bool modoReal;

  /// Há um Worker configurado (--dart-define=WORKER_URL=…)? Sem ele, só o modo simulado.
  final bool realDisponivel;
  final String? erro;

  const TriagemState({
    this.status = StatusTriagem.vazio,
    this.projeto,
    this.config = const ConfigTriagem(),
    this.rodada,
    this.etapa = '',
    this.modoReal = false,
    this.realDisponivel = false,
    this.erro,
  });

  TriagemState copyWith({
    StatusTriagem? status,
    ProjetoTriagem? projeto,
    ConfigTriagem? config,
    RodadaTriagem? rodada,
    bool limparRodada = false,
    String? etapa,
    bool? modoReal,
    String? erro,
    bool limparErro = false,
  }) => TriagemState(
    status: status ?? this.status,
    projeto: projeto ?? this.projeto,
    config: config ?? this.config,
    rodada: limparRodada ? null : rodada ?? this.rodada,
    etapa: etapa ?? this.etapa,
    modoReal: modoReal ?? this.modoReal,
    realDisponivel: realDisponivel,
    erro: limparErro ? null : erro ?? this.erro,
  );

  @override
  List<Object?> get props => [status, projeto, config, rodada, etapa, modoReal, realDisponivel, erro];
}

class TriagemCubit extends Cubit<TriagemState> {
  final ArquivosTriagem arquivos;
  final FabricaClientes fabrica;

  TriagemCubit({
    required this.arquivos,
    required this.fabrica,
    ConfigTriagem config = const ConfigTriagem(),
    bool realDisponivel = false,
  }) : super(TriagemState(config: config, realDisponivel: realDisponivel));

  /// Lê a tabela de preços (assets/precos.json). Chamado uma vez ao abrir.
  Future<void> iniciar() async {
    try {
      final precos = await arquivos.precos();
      emit(state.copyWith(config: state.config.copyWith(precos: precos)));
    } catch (e) {
      emit(state.copyWith(erro: 'Não consegui ler a tabela de preços: $e'));
    }
  }

  Future<void> carregarExemplo() async {
    try {
      _carregado(await arquivos.exemplo());
    } catch (e) {
      emit(state.copyWith(erro: 'Exemplo inválido: $e'));
    }
  }

  void carregarArquivo(String conteudo) {
    try {
      _carregado(ArquivosTriagem.lerProjeto(conteudo));
    } catch (e) {
      emit(state.copyWith(erro: 'Arquivo inválido: $e'));
    }
  }

  void _carregado(ProjetoTriagem p) =>
      emit(state.copyWith(status: StatusTriagem.pronto, projeto: p, limparRodada: true, etapa: '', limparErro: true));

  void alternarModoReal(bool real) {
    if (real && !state.realDisponivel) return;
    emit(state.copyWith(modoReal: real));
  }

  void alternarEstabilidade(bool ligado) =>
      emit(state.copyWith(config: state.config.copyWith(testeEstabilidade: ligado)));

  void ajustarLimites({double? incluir, double? excluir}) {
    final i = incluir ?? state.config.limiteIncluir;
    final x = excluir ?? state.config.limiteExcluir;
    if (x > i) return;
    emit(
      state.copyWith(
        config: state.config.copyWith(limiteIncluir: i, limiteExcluir: x),
      ),
    );
  }

  Future<void> rodar() async {
    final projeto = state.projeto;
    if (projeto == null || state.status == StatusTriagem.rodando) return;
    final config = state.config;
    final (decisor, llm) = fabrica(config, real: state.modoReal);
    final configRodada = config.copyWith(modeloDecisao: decisor.modelo, modeloLlm: llm.modelo);
    emit(state.copyWith(status: StatusTriagem.rodando, limparRodada: true, etapa: 'Começando…', limparErro: true));
    try {
      final rodada = await OrquestradorTriagem(decisor: decisor, llm: llm, config: configRodada).rodar(
        projeto,
        aoProgredir: (parcial, etapa) => emit(state.copyWith(rodada: parcial, etapa: etapa)),
      );
      emit(state.copyWith(status: StatusTriagem.concluido, rodada: rodada, etapa: 'Concluída'));
    } catch (e) {
      emit(state.copyWith(status: StatusTriagem.pronto, erro: 'A triagem parou: $e'));
    }
  }

  /// Etapa 3: o pesquisador confirma ou muda. [decisao] null desfaz a decisão humana.
  void decidirHumano(String estudoId, Decisao? decisao, {String observacao = ''}) {
    final rodada = state.rodada;
    if (rodada == null) return;
    final resultados = [
      for (final r in rodada.resultados)
        if (r.estudo.id != estudoId)
          r
        else if (decisao == null)
          r.copyWith(limparHumana: true)
        else
          r.copyWith(humana: DecisaoHumana(decisao, observacao)),
    ];
    emit(state.copyWith(rodada: rodada.copyWith(resultados: resultados)));
  }

  /// Aceita a sugestão do sistema em todos os estudos que o pesquisador ainda não decidiu.
  void aceitarSugestoes() {
    final rodada = state.rodada;
    if (rodada == null) return;
    final resultados = [
      for (final r in rodada.resultados)
        r.humana == null && r.decisaoSistema != null ? r.copyWith(humana: DecisaoHumana(r.decisaoSistema!)) : r,
    ];
    emit(state.copyWith(rodada: rodada.copyWith(resultados: resultados)));
  }

  void limparErro() => emit(state.copyWith(limparErro: true));
}
