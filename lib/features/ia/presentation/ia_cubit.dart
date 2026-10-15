import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../habito/domain/habito.dart' show diaDe;
import '../../tutor/data/tutor_service.dart';
import '../data/cache_explicacoes.dart';
import '../data/cota_repository.dart';
import '../domain/cota_ia.dart';
import '../domain/explicacao.dart';

enum StatusIa { ok, semCota, falhou }

class ResultadoIa extends Equatable {
  final StatusIa status;
  final String texto;
  const ResultadoIa(this.status, [this.texto = '']);

  @override
  List<Object?> get props => [status, texto];
}

class IaState extends Equatable {
  /// Quantos usos ainda restam hoje.
  final int restantes;

  /// A cota já foi lida (antes disso o botão não mostra o saldo).
  final bool carregado;

  const IaState({this.restantes = CotaIa.limitePadrao, this.carregado = false});

  @override
  List<Object?> get props => [restantes, carregado];
}

/// Quem decide se a pessoa pode usar a IA agora e guarda o que já foi explicado:
/// cache → cota → serviço, nessa ordem. Vive ACIMA dos cursos (a cota é da conta).
///
/// A IA só EXPLICA: nunca mexe em nota, agenda nem ranking.
class IaCubit extends Cubit<IaState> {
  final TutorService service;
  final CotaRepository cotaRepo;
  final CacheExplicacoes cache;
  final int limite;

  /// Relógio injetável (testes).
  final DateTime Function() agora;

  CotaIa _cota = CotaIa.vazia;
  Future<void>? _carregando;

  /// Pedidos em andamento por chave (duas telas pedindo o mesmo gastam 1) e usos já reservados.
  final Map<String, Future<ResultadoIa>> _emVoo = {};
  int _reservados = 0;

  CotaIa? _aGravar;
  bool _gravando = false;

  IaCubit({
    required this.service,
    required this.cotaRepo,
    CacheExplicacoes? cache,
    this.limite = CotaIa.limitePadrao,
    DateTime Function()? agora,
  })  : cache = cache ?? CacheExplicacoesLocal(),
        agora = agora ?? DateTime.now,
        super(const IaState()) {
    carregar();
  }

  /// O cubit acima de [context], ou null (testes antigos, sem IA).
  static IaCubit? de(BuildContext context) {
    try {
      return BlocProvider.of<IaCubit>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  int get _hoje => diaDe(agora());

  Future<void> carregar() => _carregando ??= _carregar();

  Future<void> _carregar() async {
    try {
      _cota = await cotaRepo.carregar();
    } catch (_) {
      _cota = CotaIa.vazia;
    }
    if (isClosed) return;
    emit(IaState(restantes: _cota.restantes(_hoje, limite: limite) - _reservados, carregado: true));
  }

  /// Explica o erro de [pedido]. Nunca lança.
  Future<ResultadoIa> explicar(PedidoIa pedido) {
    if (!pedido.temErro) return Future.value(const ResultadoIa(StatusIa.falhou));
    final chave = pedido.chave;
    final emVoo = _emVoo[chave];
    if (emVoo != null) return emVoo;
    final f = _explicar(pedido, chave).whenComplete(() {
      // (chaves, não o Future devolvido por remove(): o whenComplete esperaria por ele mesmo)
      _emVoo.remove(chave);
    });
    _emVoo[chave] = f;
    return f;
  }

  Future<ResultadoIa> _explicar(PedidoIa pedido, String chave) async {
    await carregar();
    final guardada = await cache.ler(chave);
    if (guardada != null && guardada.isNotEmpty) return ResultadoIa(StatusIa.ok, guardada);
    final p = pedido.montar();
    final r = await _chamar(contexto: p.contexto, historico: '', pergunta: p.pergunta);
    if (r.status == StatusIa.ok) unawaited(cache.gravar(chave, r.texto));
    return r;
  }

  /// Uma chamada à IA que gasta 1 uso (sem cache): os turnos e o feedback dos cenários guiados.
  /// Com [persona], o Dash faz esse papel (serviço que aceita persona própria) ou recebe a
  /// persona como instrução no contexto (os outros). Nunca lança.
  Future<ResultadoIa> consultar({
    required String contexto,
    String historico = '',
    required String pergunta,
    String? persona,
  }) async {
    await carregar();
    return _chamar(contexto: contexto, historico: historico, pergunta: pergunta, persona: persona);
  }

  /// A cota (com reserva do uso ANTES de chamar: pedidos simultâneos não passam do limite), a
  /// chamada e o gasto: erro, vazio ou "sem saldo" nunca gastam.
  Future<ResultadoIa> _chamar({
    required String contexto,
    required String historico,
    required String pergunta,
    String? persona,
  }) async {
    if (_cota.restantes(_hoje, limite: limite) - _reservados <= 0) return const ResultadoIa(StatusIa.semCota);
    _reservados++;
    String texto;
    try {
      final svc = service;
      final Stream<String> fluxo = persona != null && svc is TutorComPersona
          ? (svc as TutorComPersona).perguntarComo(persona: persona, contexto: contexto, historico: historico, pergunta: pergunta)
          : svc.perguntar(
              contexto: persona == null ? contexto : '$persona\n\n$contexto', historico: historico, pergunta: pergunta);
      final b = StringBuffer();
      await for (final pedaco in fluxo) {
        b.write(pedaco);
      }
      texto = b.toString().trim();
    } catch (_) {
      _reservados--;
      return const ResultadoIa(StatusIa.falhou);
    }
    _reservados--;
    if (texto.isEmpty) return const ResultadoIa(StatusIa.falhou); // não gasta
    _cota = _cota.gastar(_hoje);
    if (!isClosed) emit(IaState(restantes: _cota.restantes(_hoje, limite: limite) - _reservados, carregado: true));
    _salvar(_cota);
    return ResultadoIa(StatusIa.ok, texto);
  }

  /// Grava em ordem e sem empilhar (o estado mais novo vence); erro de rede é engolido.
  Future<void> _salvar(CotaIa c) async {
    _aGravar = c;
    if (_gravando) return;
    _gravando = true;
    try {
      while (_aGravar != null) {
        final vez = _aGravar!;
        _aGravar = null;
        try {
          await cotaRepo.salvar(vez);
        } catch (_) {}
      }
    } finally {
      _gravando = false;
    }
  }
}

/// A IA do "toque na palavra" (o sentido de uma palavra NA frase): o mesmo caminho cache → cota →
/// serviço do [IaCubit], mas com cota e cache PRÓPRIOS — tocar em palavras não gasta os usos do
/// "Por quê?" nem expulsa as explicações guardadas. A cota é maior (cada resposta é uma linha) e
/// fica só no aparelho.
class IaPalavrasCubit extends IaCubit {
  static const limitePalavras = 150;

  IaPalavrasCubit({
    required super.service,
    String? uid,
    CotaRepository? cotaRepo,
    CacheExplicacoes? cache,
    super.limite = limitePalavras,
    super.agora,
  }) : super(
          cotaRepo: cotaRepo ?? LocalCotaRepository(uid: uid, base: 'ia_cota_palavras_v1'),
          cache: cache ?? CacheExplicacoesLocal(uid: uid, base: 'ia_palavras_v1', limite: 800),
        );

  /// O cubit acima de [context], ou null (sem IA: o balão mostra só o pé da letra).
  static IaPalavrasCubit? daArvore(BuildContext context) {
    try {
      return BlocProvider.of<IaPalavrasCubit>(context, listen: false);
    } catch (_) {
      return null;
    }
  }
}
