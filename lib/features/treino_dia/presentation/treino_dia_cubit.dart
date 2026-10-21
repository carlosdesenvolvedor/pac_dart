import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../habito/domain/habito.dart' show diaDe;
import '../data/treino_dia_repository.dart';
import '../domain/plano_treino.dart';

class TreinoDiaState extends Equatable {
  /// O plano já foi lido do aparelho/nuvem? Até lá ninguém monta plano novo.
  final bool carregado;

  /// O último plano (pode ser de outro dia — ver [TreinoDiaCubit.planoDeHoje]).
  final PlanoTreino? plano;

  const TreinoDiaState({this.carregado = false, this.plano});

  TreinoDiaState copyWith({bool? carregado, PlanoTreino? plano}) =>
      TreinoDiaState(carregado: carregado ?? this.carregado, plano: plano ?? this.plano);

  @override
  List<Object?> get props => [carregado, plano];
}

/// O "⚡ Treino do dia" de UM curso (vive em `_cursoDe`, chave `uid:linguagem`).
///
/// Offline-first como o [HabitoCubit]: cada mudança aparece na hora e é gravada em seguida, em ordem,
/// "a mais nova vence"; erro de gravação é engolido. Virada da meia-noite: [marcar], `anotar*` e
/// [tomarBonus] agem sempre em `state.plano` (a sessão aberta termina no próprio plano); só [iniciar]
/// troca de dia.
class TreinoDiaCubit extends Cubit<TreinoDiaState> {
  final TreinoDiaRepository repo;

  /// `Linguagem.id`.
  final String curso;

  /// Relógio injetável (o mesmo do hábito: `habitoAgora`).
  final DateTime Function() agora;

  Future<void>? _carregando;

  /// Mudanças pedidas antes de o plano carregar (não esperado: a tela espera [carregar]). Entram
  /// por cima do plano lido só se ele for do dia em que foram pedidas; senão são descartadas.
  final List<(int, PlanoTreino Function(PlanoTreino, int))> _pendentes = [];

  PlanoTreino? _aGravar;
  Completer<void>? _gravando;

  TreinoDiaCubit({required this.repo, required this.curso, DateTime Function()? agora})
      : agora = agora ?? DateTime.now,
        super(const TreinoDiaState()) {
    carregar();
  }

  /// O cubit acima de [c], ou null (testes de tela sem treino).
  static TreinoDiaCubit? de(BuildContext c) {
    try {
      return BlocProvider.of<TreinoDiaCubit>(c, listen: false);
    } catch (_) {
      return null;
    }
  }

  int get hoje => diaDe(agora());

  /// Lê o plano salvo (o repositório já mescla aparelho × nuvem). Chamar de novo reaproveita a leitura.
  Future<void> carregar() => _carregando ??= _carregar();

  Future<void> _carregar() async {
    PlanoTreino? lido;
    try {
      lido = await repo.carregar();
    } catch (_) {
      lido = null;
    }
    if (isClosed) return;
    // um plano criado antes da leitura (só com assert desligado) é mesclado, nunca perdido
    var p = PlanoTreino.mesclar(lido, state.plano);
    for (final (dia, f) in _pendentes) {
      if (p != null && p.dia == dia) p = f(p, _ms());
    }
    _pendentes.clear();
    emit(TreinoDiaState(carregado: true, plano: p));
    if (p != null && p != lido) _salvar(p);
  }

  int _ms() => agora().millisecondsSinceEpoch;

  /// `state.plano` se for de hoje; senão null.
  PlanoTreino? get planoDeHoje {
    final p = state.plano;
    return p != null && p.dia == hoje ? p : null;
  }

  /// Barato (o HUD chama a cada segundo).
  SituacaoTreino get situacao => planoDeHoje?.situacao ?? SituacaoTreino.pendente;

  /// O plano de hoje; sem ele (ou com o de outro dia), cria com [montar] e grava. O ÚNICO método que
  /// troca o dia do plano. `assert(state.carregado)`: chamar antes de [carregar] terminar é bug.
  PlanoTreino iniciar(PlanoTreino Function() montar) {
    assert(state.carregado, 'TreinoDiaCubit.iniciar antes de carregar() terminar');
    final atual = planoDeHoje;
    if (atual != null) return atual;
    final novo = montar();
    if (!isClosed) {
      emit(state.copyWith(plano: novo));
      _salvar(novo);
    }
    return novo;
  }

  /// Troca o plano de hoje por um melhorado (`completarPlano`). Nada se não for o plano de hoje.
  void completar(PlanoTreino Function(PlanoTreino atual) upgrade) {
    final atual = planoDeHoje;
    if (atual == null || isClosed) return;
    _trocar(upgrade(atual));
  }

  void marcar(String id, EstadoBloco e, {int? resultado, int? total, bool vazio = false}) =>
      _mudar((p, ms) => p.marcar(id, e, resultado: resultado, total: total, vazio: vazio, agoraMs: ms));

  void anotarOuvir(Iterable<String> chaves) {
    final l = List<String>.of(chaves);
    _mudar((p, ms) => p.anotarOuvir(l, agoraMs: ms));
  }

  void anotarFoco(Iterable<String> ens) {
    final l = List<String>.of(ens);
    _mudar((p, ms) => p.anotarFoco(l, agoraMs: ms));
  }

  /// Concluído e [PlanoTreino.merecebonus]: marca `bonus = true`, grava e devolve true. Quem chamou
  /// chama em seguida `HabitoCubit.ganharBonusTreino(bonusTreino)` (a trava de 1× por conta por dia).
  /// Antes de carregar, ou de novo depois de tomado, devolve false.
  bool tomarBonus() {
    final p = state.plano;
    if (isClosed || p == null || !p.merecebonus) return false;
    _trocar(p.comBonus(agoraMs: _ms()));
    return true;
  }

  /// Completa quando a fila de gravação esvazia.
  @visibleForTesting
  Future<void> get gravacoes => _gravando?.future ?? Future<void>.value();

  /// Aplica [f] em `state.plano` (de qualquer dia: a sessão aberta termina no próprio plano). Antes
  /// de carregar, guarda para aplicar por cima do que vier (ver [_pendentes]).
  void _mudar(PlanoTreino Function(PlanoTreino p, int agoraMs) f) {
    if (isClosed) return;
    final p = state.plano;
    if (p == null) {
      if (!state.carregado) _pendentes.add((hoje, f));
      return;
    }
    _trocar(f(p, _ms()));
  }

  void _trocar(PlanoTreino novo) {
    if (novo == state.plano) return;
    emit(state.copyWith(plano: novo));
    _salvar(novo);
  }

  /// Grava em ordem e sem empilhar: durante uma gravação só o plano mais novo segue depois. Erro (sem
  /// rede) é engolido: o aparelho já guardou e a próxima mudança tenta de novo.
  Future<void> _salvar(PlanoTreino p) async {
    _aGravar = p;
    if (_gravando != null) return;
    final fim = _gravando = Completer<void>();
    try {
      while (_aGravar != null) {
        final vez = _aGravar!;
        _aGravar = null;
        try {
          await repo.salvar(vez);
        } catch (_) {}
      }
    } finally {
      _gravando = null;
      fim.complete();
    }
  }
}
