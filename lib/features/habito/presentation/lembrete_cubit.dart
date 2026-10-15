import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/agendador_lembrete.dart';
import '../data/lembrete_repository.dart';
import '../domain/lembrete.dart';
import 'habito_cubit.dart';

class LembreteState extends Equatable {
  final ConfigLembrete config;

  /// A configuração já foi lida (antes disso a folha não mostra o interruptor).
  final bool carregado;

  /// Este aparelho sabe agendar notificações (Android/iOS). Falso ⇒ a folha só explica.
  final bool disponivel;

  /// A pessoa tentou ligar e o sistema negou a permissão: a folha explica como liberar.
  final bool permissaoNegada;

  const LembreteState({this.config = ConfigLembrete.padrao, this.carregado = false, this.disponivel = false, this.permissaoNegada = false});

  LembreteState copyWith({ConfigLembrete? config, bool? carregado, bool? permissaoNegada}) => LembreteState(
        config: config ?? this.config,
        carregado: carregado ?? this.carregado,
        disponivel: disponivel,
        permissaoNegada: permissaoNegada ?? this.permissaoNegada,
      );

  @override
  List<Object?> get props => [config, carregado, disponivel, permissaoNegada];
}

/// O lembrete diário da conta neste aparelho. Só LÊ o hábito (se a meta de hoje já foi batida) para decidir
/// o que agendar; nunca mexe em sequência, ranking nem agenda. Vive ao lado do `HabitoCubit`, acima dos cursos.
///
/// Reagenda (cancela os 7 dias e agenda de novo) quando: a configuração é lida (cada abertura do app renova os
/// 7 dias), liga/desliga, muda o horário e **a meta de hoje é batida** (hoje sai da lista). Um exercício que
/// não bate a meta NÃO reagenda.
class LembreteCubit extends Cubit<LembreteState> {
  final LembreteRepository repo;
  final AgendadorDeLembrete agendador;
  final HabitoCubit? habito;

  /// Relógio injetável (testes); sem ele vale o do hábito.
  final DateTime Function()? _agora;

  /// Só o último cubit criado cancela ao fechar: na troca de conta o novo já assumiu e o antigo não apaga o que ele agendou.
  static int _geracao = 0;
  // (campo comum, NÃO `late`: tem de contar na hora em que o cubit nasce, não só na primeira vez que alguém o lê)
  final int _minha = ++_geracao;

  Future<void>? _carregando;
  Future<void> _fila = Future.value();
  StreamSubscription<HabitoState>? _sub;
  bool? _ultimoBateu;

  LembreteCubit({required this.repo, required this.agendador, this.habito, DateTime Function()? agora})
      : _agora = agora,
        super(LembreteState(disponivel: agendador.disponivel)) {
    _sub = habito?.stream.listen(_habitoMudou);
    carregar();
  }

  /// O cubit acima de [context], ou null (testes de tela antigos, sem lembrete).
  static LembreteCubit? de(BuildContext context) {
    try {
      return BlocProvider.of<LembreteCubit>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  DateTime get _hoje => (_agora ?? habito?.agora ?? DateTime.now)();

  bool get _metaBatidaHoje {
    final h = habito;
    return h != null && h.state.carregado && h.state.habito.bateuHoje(_hoje);
  }

  Future<void> carregar() => _carregando ??= _carregar();

  Future<void> _carregar() async {
    ConfigLembrete c;
    try {
      c = await repo.carregar();
    } catch (_) {
      c = ConfigLembrete.padrao;
    }
    // espera o hábito para saber se a meta de hoje já foi batida (senão agendaria o dia de hoje à toa)
    try {
      await habito?.carregar();
    } catch (_) {}
    if (isClosed) return;
    _ultimoBateu = _metaBatidaHoje;
    emit(state.copyWith(config: c, carregado: true));
    _reagendar();
  }

  /// O hábito mudou: só importa quando "bateu a meta hoje" vira verdadeiro (ou falso: virou o dia).
  void _habitoMudou(HabitoState s) {
    if (!s.carregado || !state.carregado) return;
    final b = _metaBatidaHoje;
    if (b == _ultimoBateu) return;
    _ultimoBateu = b;
    if (state.config.ligado) _reagendar();
  }

  /// Liga ou desliga. Ligar PEDE a permissão do sistema; negada, continua desligado e a tela explica.
  Future<void> ligar(bool ligar) async {
    if (isClosed || !state.disponivel) return;
    await carregar();
    if (isClosed) return;
    if (ligar == state.config.ligado && !state.permissaoNegada) return;
    if (ligar) {
      final ok = await agendador.pedirPermissao();
      if (isClosed) return;
      if (!ok) {
        emit(state.copyWith(permissaoNegada: true));
        return;
      }
    }
    final c = state.config.copyWith(ligado: ligar);
    emit(state.copyWith(config: c, permissaoNegada: false));
    await repo.salvar(c);
    _reagendar();
  }

  /// Muda o horário (hora 0–23, minuto 0–59; fora disso é ignorado).
  Future<void> mudarHorario(int hora, int minuto) async {
    if (isClosed || hora < 0 || hora > 23 || minuto < 0 || minuto > 59) return;
    await carregar();
    if (isClosed) return;
    final c = state.config.copyWith(hora: hora, minuto: minuto);
    if (c == state.config) return;
    emit(state.copyWith(config: c));
    await repo.salvar(c);
    if (c.ligado) _reagendar();
  }

  /// Uma de cada vez, na ordem: duas trocas seguidas nunca se misturam no sistema.
  void _reagendar() {
    if (!state.disponivel) return;
    _fila = _fila.then((_) async {
      if (isClosed) return;
      final lista = proximosLembretes(agora: _hoje, config: state.config, metaBatidaHoje: _metaBatidaHoje);
      try {
        await agendador.substituir(lista);
      } catch (_) {}
    });
  }

  @override
  Future<void> close() {
    unawaited(_sub?.cancel());
    // saiu da conta (nenhum cubit mais novo assumiu): não deixa lembrete para trás
    // (na mesma fila: um agendamento que estiver rodando termina antes do cancelamento)
    if (_geracao == _minha && state.disponivel) _fila = _fila.then((_) => agendador.cancelarTodos());
    return super.close();
  }
}
