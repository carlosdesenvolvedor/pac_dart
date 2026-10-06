import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../curso/domain/curriculo.dart';
import '../data/revisao_repository.dart';
import '../domain/revisao.dart';

class RevisaoState extends Equatable {
  final bool carregado;

  /// Chave da frase (hash do inglês) → cartão de Leitner.
  final Map<String, CartaoRevisao> cartoes;

  const RevisaoState({this.carregado = false, this.cartoes = const {}});

  List<String> devidas(int hoje, {int limite = Revisao.limiteDiario}) =>
      Revisao.devidas(cartoes, hoje, limite: limite);

  int quantasDevidas(int hoje) => cartoes.values.where((c) => c.devidaEm(hoje)).length;
  int get dominadas => cartoes.values.where((c) => c.dominada).length;

  @override
  List<Object?> get props => [carregado, cartoes];
}

/// A revisão espaçada das frases do inglês: frase digitada numa lição entra
/// na caixa 1; a revisão do dia mostra só a tradução e a pessoa digita de
/// memória — acertou sobe de caixa, errou volta para a 1.
class RevisaoCubit extends Cubit<RevisaoState> {
  final RevisaoRepository repo;

  /// Relógio injetável (testes).
  final DateTime Function() agora;

  RevisaoCubit({required this.repo, DateTime Function()? agora})
      : agora = agora ?? DateTime.now,
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

  /// A chave da frase na revisão (o id do conteúdo; sem id, o texto).
  static String chaveDe(Trecho f) => Revisao.chaveDe(id: f.id, cod: f.cod);

  Future<void> _carregar() async {
    Map<String, CartaoRevisao> cartoes;
    try {
      cartoes = await repo.carregar();
    } catch (_) {
      cartoes = {};
    }
    if (isClosed) return;
    // o que entrou enquanto carregava (lição terminada offline) prevalece
    emit(RevisaoState(carregado: true, cartoes: {...cartoes, ...state.cartoes}));
  }

  /// As frases de uma lição terminada entram na revisão (as que já estavam
  /// seguem no ritmo delas).
  Future<void> aprender(Iterable<Trecho> frases) async {
    final novos = <String, CartaoRevisao>{};
    for (final f in frases) {
      final k = chaveDe(f);
      if (!state.cartoes.containsKey(k)) novos[k] = Revisao.novo(hoje);
    }
    if (novos.isEmpty) return;
    emit(RevisaoState(carregado: state.carregado, cartoes: {...state.cartoes, ...novos}));
    try {
      await repo.salvar(novos);
    } catch (_) {}
  }

  /// Frases de uma trilha testada no nivelamento: entram numa caixa alta
  /// (a 1ª revisão, daqui a uma semana, confirma ou derruba — nada é
  /// descartado sem prova).
  Future<void> testadas(Iterable<Trecho> frases) async {
    final novos = <String, CartaoRevisao>{};
    for (final f in frases) {
      final k = chaveDe(f);
      if (!state.cartoes.containsKey(k)) novos[k] = Revisao.testada(hoje);
    }
    if (novos.isEmpty) return;
    emit(RevisaoState(carregado: state.carregado, cartoes: {...state.cartoes, ...novos}));
    try {
      await repo.salvar(novos);
    } catch (_) {}
  }

  /// Resultado de revisar a frase [frase] hoje.
  Future<void> registrar(Trecho frase, ResultadoRevisao r) async {
    final k = chaveDe(frase);
    final atual = state.cartoes[k] ?? Revisao.novo(hoje);
    final novo = Revisao.avaliar(atual, r, hoje);
    emit(RevisaoState(carregado: state.carregado, cartoes: {...state.cartoes, k: novo}));
    try {
      await repo.salvar({k: novo});
    } catch (_) {}
  }
}
