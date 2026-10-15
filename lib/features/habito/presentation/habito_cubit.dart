import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/habito_repository.dart';
import '../domain/habito.dart';

class HabitoState extends Equatable {
  final Habito habito;

  /// O hábito já foi lido do aparelho/nuvem? Até lá o chip fica neutro.
  final bool carregado;

  /// Quantas vezes a meta do dia foi batida NESTA execução do app. Quem avisa a
  /// pessoa ("Meta de hoje batida!") escuta a mudança deste número: aviso 1× por dia,
  /// sem depender de a tela estar aberta na hora nem de reabrir o app repetir.
  final int metasBatidas;

  const HabitoState({this.habito = Habito.vazio, this.carregado = false, this.metasBatidas = 0});

  HabitoState copyWith({Habito? habito, bool? carregado, int? metasBatidas}) => HabitoState(
        habito: habito ?? this.habito,
        carregado: carregado ?? this.carregado,
        metasBatidas: metasBatidas ?? this.metasBatidas,
      );

  @override
  List<Object?> get props => [habito, carregado, metasBatidas];
}

/// A sequência de dias, a meta do dia e os congelamentos — uma só para a conta
/// inteira (Dart, C# e Inglês somam juntos), por isso vive ACIMA dos blocs de cada curso.
///
/// Offline-first: cada exercício atualiza a tela na hora e só depois é gravado
/// (no aparelho e, se der, na nuvem); falha de rede nunca atrapalha o estudo.
class HabitoCubit extends Cubit<HabitoState> {
  final HabitoRepository repo;

  /// Relógio injetável (testes).
  final DateTime Function() agora;

  /// Exercícios feitos enquanto o hábito ainda carregava: entram por cima do que veio.
  final List<(int, DateTime)> _pendentes = [];
  Future<void>? _carregando;

  Habito? _aGravar;
  bool _gravando = false;

  HabitoCubit({required this.repo, DateTime Function()? agora})
      : agora = agora ?? DateTime.now,
        super(const HabitoState()) {
    carregar();
  }

  /// O cubit acima de [context], ou null (testes de tela antigos, sem hábito).
  static HabitoCubit? de(BuildContext context) {
    try {
      return BlocProvider.of<HabitoCubit>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  /// Lê o hábito (o repositório já mescla aparelho × nuvem). Chamar de novo reaproveita a leitura.
  Future<void> carregar() => _carregando ??= _carregar();

  Future<void> _carregar() async {
    Habito lido;
    try {
      lido = await repo.carregar();
    } catch (_) {
      lido = Habito.vazio;
    }
    if (isClosed) return;
    // o que foi feito durante a leitura entra por cima, na hora em que aconteceu
    var h = lido;
    var bateu = 0;
    for (final (n, quando) in _pendentes) {
      final novo = h.registrar(n, quando);
      if (novo.ultimoDiaMeta != h.ultimoDiaMeta) bateu++;
      h = novo;
    }
    final tinha = _pendentes.isNotEmpty;
    _pendentes.clear();
    emit(state.copyWith(habito: h, carregado: true, metasBatidas: state.metasBatidas + bateu));
    if (tinha) _salvar(h);
  }

  /// A pessoa concluiu [n] exercício(s). Atualiza a tela já e grava sem esperar.
  void praticou([int n = 1]) {
    if (n < 1 || isClosed) return;
    final quando = agora();
    if (!state.carregado) {
      _pendentes.add((n, quando));
      return;
    }
    _mudar((h) => h.registrar(n, quando));
  }

  /// Troca a meta do dia (10/20/40).
  void mudarMeta(int meta) {
    if (isClosed) return;
    final quando = agora();
    if (!state.carregado) {
      // ainda carregando: espera, para não ser sobrescrita pelo que vier gravado
      carregar().then((_) => mudarMeta(meta));
      return;
    }
    _mudar((h) => h.mudarMeta(meta, quando));
  }

  void _mudar(Habito Function(Habito) f) {
    final antes = state.habito;
    final depois = f(antes);
    if (depois == antes) return;
    final bateu = depois.ultimoDiaMeta != antes.ultimoDiaMeta;
    emit(state.copyWith(habito: depois, metasBatidas: state.metasBatidas + (bateu ? 1 : 0)));
    _salvar(depois);
  }

  /// Grava em ordem e sem empilhar: se chegar outro estado enquanto grava, só o
  /// mais novo vai em seguida (o hábito é um estado, não uma lista de eventos).
  /// Erro (sem rede) é engolido: o aparelho já guardou e o próximo salvar tenta de novo.
  Future<void> _salvar(Habito h) async {
    _aGravar = h;
    if (_gravando) return;
    _gravando = true;
    try {
      while (_aGravar != null) {
        final vez = _aGravar!;
        _aGravar = null;
        try {
          await repo.salvar(vez);
        } catch (_) {}
      }
    } finally {
      _gravando = false;
    }
  }
}
