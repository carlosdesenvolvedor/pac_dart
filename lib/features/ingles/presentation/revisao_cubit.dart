import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../curso/domain/curriculo.dart';
import '../data/config_srs_repository.dart';
import '../data/revisao_repository.dart';
import '../domain/config_srs.dart';
import '../domain/revisao.dart';
import '../domain/srs.dart';

class RevisaoState extends Equatable {
  final bool carregado;

  /// Chave da frase (hash do inglês) → cartão (a memória dela, medida pelo FSRS).
  /// O cartão do sentido invertido (inglês → português) tem a chave com `~r`.
  final Map<String, CartaoSrs> cartoes;

  /// Os ajustes (limite do dia, novos por dia, retenção, baralhos invertidos).
  final ConfigSrs config;

  const RevisaoState({this.carregado = false, this.cartoes = const {}, this.config = ConfigSrs.padrao});

  int quantasDevidas(int hoje) => cartoes.values.where((c) => c.devidaEm(hoje)).length;

  /// Frases com memória de 3 semanas ou mais ("maduras", como no Anki).
  int get maduras => cartoes.values.where((c) => c.madura).length;

  RevisaoState copyWith({bool? carregado, Map<String, CartaoSrs>? cartoes, ConfigSrs? config}) => RevisaoState(
        carregado: carregado ?? this.carregado,
        cartoes: cartoes ?? this.cartoes,
        config: config ?? this.config,
      );

  @override
  List<Object?> get props => [carregado, cartoes, config];
}

/// A revisão espaçada das frases do inglês, no jeito do Anki: a frase terminada
/// numa lição vira um cartão (volta amanhã); a revisão do dia mostra só a
/// tradução e a pessoa digita de memória — a nota (errei / difícil / bom) vai
/// para o FSRS, que decide quando a frase volta. Nos baralhos com o sentido
/// invertido há também o cartão de virar-e-avaliar (inglês na frente,
/// tradução no verso, 4 botões). Cada revisão entra no histórico.
class RevisaoCubit extends Cubit<RevisaoState> {
  final RevisaoRepository repo;
  final ConfigSrsRepository? configRepo;

  /// Relógio injetável (testes).
  final DateTime Function() agora;

  final AgendadorFsrs? _fixo;
  AgendadorFsrs? _doConfig;
  double? _retencaoDoConfig;

  /// [agendador] fixo só nos testes; no app o agendador acompanha a retenção
  /// escolhida nos ajustes.
  RevisaoCubit({required this.repo, this.configRepo, AgendadorFsrs? agendador, DateTime Function()? agora})
      : _fixo = agendador,
        agora = agora ?? DateTime.now,
        super(const RevisaoState()) {
    _carregar();
  }

  /// O cubit acima de [context], ou null (fora do curso de inglês).
  static RevisaoCubit? de(BuildContext context) {
    try {
      return BlocProvider.of<RevisaoCubit>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  int get hoje => Revisao.dia(agora());

  AgendadorFsrs get agendador {
    final fixo = _fixo;
    if (fixo != null) return fixo;
    final r = state.config.retencao;
    if (_doConfig == null || _retencaoDoConfig != r) {
      _doConfig = AgendadorFsrs(retencao: r);
      _retencaoDoConfig = r;
    }
    return _doConfig!;
  }

  /// A chave da frase na revisão (o id do conteúdo; sem id, o texto).
  static String chaveDe(Trecho f) => Revisao.chaveDe(id: f.id, cod: f.cod);

  /// A chave do cartão inglês → português da frase.
  static String chaveReversaDe(Trecho f) => Revisao.chaveReversa(chaveDe(f));

  /// As frases que vencem hoje (as que a pessoa tem menos chance de lembrar
  /// primeiro) nos DOIS sentidos, no máximo [limite] (padrão: o dos ajustes).
  List<String> devidas({int? limite}) =>
      agendador.devidas(state.cartoes, hoje, limite: limite ?? state.config.limiteRevisoes);

  /// Em quantos dias o cartão [chave] volta com cada nota (nulo = ainda não é
  /// cartão: a 1ª vez de um de virar-e-avaliar) — o texto dos 4 botões.
  Map<Rating, int> previsao(String chave) => agendador.previsao(state.cartoes[chave], hoje);

  Future<void> _carregar() async {
    Map<String, CartaoSrs> cartoes;
    try {
      cartoes = await repo.carregar();
    } catch (_) {
      cartoes = {};
    }
    ConfigSrs config = ConfigSrs.padrao;
    try {
      config = await configRepo?.carregar() ?? ConfigSrs.padrao;
    } catch (_) {}
    if (isClosed) return;
    // o que entrou enquanto carregava (lição terminada offline) prevalece
    emit(RevisaoState(carregado: true, cartoes: {...cartoes, ...state.cartoes}, config: config));
  }

  /// Grava [novos] e a revisão de cada um no histórico (nunca derruba a tela).
  /// [primeiras] são as chaves cuja revisão é a 1ª vez da frase.
  Future<void> _gravar(Map<String, CartaoSrs> novos, Map<String, int> notas, {Set<String> primeiras = const {}}) async {
    emit(state.copyWith(cartoes: {...state.cartoes, ...novos}));
    final dia = hoje;
    try {
      await repo.salvar(novos);
    } catch (_) {}
    if (notas.isEmpty) return;
    try {
      await repo.registrarHistorico([
        for (final e in notas.entries) EntradaHistorico(dia, e.key, e.value, primeira: primeiras.contains(e.key)),
      ]);
    } catch (_) {}
  }

  /// Muda os ajustes (limites, retenção, baralhos invertidos) e guarda.
  Future<void> mudarConfig(ConfigSrs nova) async {
    if (nova == state.config) return;
    emit(state.copyWith(config: nova));
    try {
      await configRepo?.salvar(nova);
    } catch (_) {}
  }

  /// As frases de uma lição terminada viram cartões que voltam AMANHÃ (as que
  /// já eram cartões seguem no ritmo delas). [notas] é como cada frase saiu na
  /// prova da lição (chave → resultado); sem ela, vale "bom".
  Future<void> aprender(Iterable<Trecho> frases, {Map<String, ResultadoRevisao> notas = const {}}) async {
    final novos = <String, CartaoSrs>{};
    final dadas = <String, int>{};
    for (final f in frases) {
      final k = chaveDe(f);
      if (state.cartoes.containsKey(k) || novos.containsKey(k)) continue;
      final nota = notaDoResultado(notas[k] ?? ResultadoRevisao.acertou);
      novos[k] = agendador.novo(hoje, nota: nota);
      dadas[k] = nota.value;
    }
    if (novos.isEmpty) return;
    await _gravar(novos, dadas, primeiras: dadas.keys.toSet());
  }

  /// Frases de uma trilha testada no nivelamento: entram como "fáceis" e a 1ª
  /// revisão, daqui a uma semana, confirma ou derruba — nada é descartado sem
  /// prova.
  Future<void> testadas(Iterable<Trecho> frases) async {
    final novos = <String, CartaoSrs>{};
    final dadas = <String, int>{};
    for (final f in frases) {
      final k = chaveDe(f);
      if (state.cartoes.containsKey(k) || novos.containsKey(k)) continue;
      novos[k] = agendador.testada(hoje);
      dadas[k] = Rating.easy.value;
    }
    if (novos.isEmpty) return;
    await _gravar(novos, dadas, primeiras: dadas.keys.toSet());
  }

  /// Resultado de revisar a frase [frase] hoje (digitada de memória).
  Future<void> registrar(Trecho frase, ResultadoRevisao r) async {
    final k = chaveDe(frase);
    final nota = notaDoResultado(r);
    final atual = state.cartoes[k];
    final novo = atual == null ? agendador.novo(hoje, nota: nota) : agendador.avaliar(atual, nota, hoje);
    await _gravar({k: novo}, {k: nota.value}, primeiras: atual == null ? {k} : const {});
  }

  /// A nota dos 4 botões do cartão inglês → português. Cartão que ainda não
  /// existia nasce aqui e a nota já decide o intervalo (como no Anki).
  Future<void> registrarVirar(Trecho frase, Rating nota) async {
    final k = chaveReversaDe(frase);
    final atual = state.cartoes[k];
    final novo = atual == null
        ? agendador.novo(hoje, nota: nota, voltaAmanha: false)
        : agendador.avaliar(atual, nota, hoje);
    await _gravar({k: novo}, {k: nota.value}, primeiras: atual == null ? {k} : const {});
  }

  /// Quantos cartões inglês → português entraram HOJE (a 1ª vez de cada um).
  int get introduzidasHoje {
    final h = hoje;
    return state.cartoes.entries
        .where((e) => Revisao.ehReversa(e.key) && e.value.revisoes == 1 && e.value.ultimoDia == h)
        .length;
  }

  /// Quantos cartões inglês → português ainda podem entrar hoje.
  int get vagasDeNovos => (state.config.novosPorDia - introduzidasHoje).clamp(0, 1 << 30);

  /// Dentre [candidatas] (na ordem do curso), as que ainda NÃO têm cartão inglês →
  /// português e cabem na cota de novos do dia.
  List<Trecho> novasReversas(Iterable<Trecho> candidatas) {
    final vistas = <String>{};
    final r = <Trecho>[];
    var vagas = vagasDeNovos;
    for (final f in candidatas) {
      if (vagas <= 0) break;
      final k = chaveReversaDe(f);
      if (state.cartoes.containsKey(k) || !vistas.add(k)) continue;
      r.add(f);
      vagas--;
    }
    return r;
  }

  /// Suspende (some das revisões até reativar) ou reativa o cartão [chave].
  Future<void> suspender(String chave, {required bool suspenso}) async {
    final c = state.cartoes[chave];
    if (c == null || c.suspenso == suspenso) return;
    await _gravar({chave: c.comSuspenso(suspenso)}, const {});
  }

  /// Enterra o cartão [chave] até amanhã (some das revisões de hoje; a agenda não muda).
  Future<void> enterrar(String chave) async {
    final c = state.cartoes[chave];
    if (c == null) return;
    await _gravar({chave: c.comEnterradoAte(hoje + 1)}, const {});
  }
}
