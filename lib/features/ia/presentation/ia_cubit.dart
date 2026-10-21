import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../habito/domain/habito.dart' show diaDe;
import '../../tutor/data/falha_ia.dart';
import '../../tutor/data/tutor_service.dart';
import '../data/cache_explicacoes.dart';
import '../data/cota_repository.dart';
import '../domain/cota_ia.dart';
import '../domain/explicacao.dart';

enum StatusIa { ok, semCota, falhou }

class ResultadoIa extends Equatable {
  final StatusIa status;
  final String texto;

  /// Por que falhou (só quando [status] == falhou; null = motivo desconhecido).
  final TipoFalhaIa? motivo;
  const ResultadoIa(this.status, [this.texto = '', this.motivo]);

  @override
  List<Object?> get props => [status, texto, motivo];
}

class IaState extends Equatable {
  /// Quantos usos ainda restam hoje.
  final int restantes;

  /// A cota já foi lida (antes disso o botão não mostra o saldo).
  final bool carregado;

  /// A janela de descanso do projeto depois de um 429/503/401 (null = livre).
  final DateTime? esperaAte;

  const IaState({this.restantes = CotaIa.limitePadrao, this.carregado = false, this.esperaAte});

  @override
  List<Object?> get props => [restantes, carregado, esperaAte];
}

/// A janela de descanso que TODOS os [IaCubit] que falam com o mesmo projeto dividem: o `main.dart`
/// cria UMA e passa ao [IaCubit] e ao [IaPalavrasCubit]. Sem argumento cada cubit ganha a sua (os
/// testes não vazam estado por um campo estático).
class DescansoIa {
  DateTime? ate;
  TipoFalhaIa? motivo;
  Duration? passo;

  bool ativo(DateTime agora) => ate != null && agora.isBefore(ate!);

  /// limite: passo 20 s → dobra até 5 min; limiteDiario: até as próximas 08:00 UTC (no máximo 12 h);
  /// ocupado: 8 s; credencial: 60 s; semRede/recusada/outro/limitePessoal: sem janela.
  void registrar(TipoFalhaIa tipo, DateTime agora) {
    switch (tipo) {
      case TipoFalhaIa.limite:
        final p = passo == null ? IaCubit.descansoInicial : passo! * 2;
        passo = p > IaCubit.descansoMaximo ? IaCubit.descansoMaximo : p;
        ate = agora.add(passo!);
      case TipoFalhaIa.limiteDiario:
        ate = proximaViradaDiaria(agora);
      case TipoFalhaIa.ocupado:
        ate = agora.add(IaCubit.descansoOcupado);
      case TipoFalhaIa.credencial:
        ate = agora.add(IaCubit.descansoCredencial);
      case TipoFalhaIa.semRede || TipoFalhaIa.recusada || TipoFalhaIa.outro:
        return; // falha "local": não é o projeto pedindo descanso
      case TipoFalhaIa.limitePessoal:
        return; // só a Conversa (Claude) desta pessoa: o roteador segura até o Retry-After; o Gemini segue livre
    }
    motivo = tipo;
  }

  /// As próximas 08:00 UTC depois de [agora] (meia-noite do Pacífico no horário padrão, quando o
  /// limite diário grátis do Gemini zera; no horário de verão sai 1 h atrasado, sem problema), no
  /// máximo [IaCubit.descansoDiarioMaximo] à frente. No mesmo fuso de [agora].
  static DateTime proximaViradaDiaria(DateTime agora) {
    final u = agora.toUtc();
    var alvo = DateTime.utc(u.year, u.month, u.day, 8);
    if (!alvo.isAfter(u)) alvo = DateTime.utc(u.year, u.month, u.day + 1, 8);
    final teto = agora.add(IaCubit.descansoDiarioMaximo);
    final ate = alvo.isBefore(teto) ? alvo : teto;
    return agora.isUtc ? ate.toUtc() : ate.toLocal();
  }

  void limpar() {
    ate = null;
    motivo = null;
    passo = null;
  }
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
  final DateTime Function() _agora;

  /// A janela de descanso (compartilhada no app; própria nos testes).
  final DescansoIa descanso;

  /// O intervalo mínimo entre chamadas do [consultarJson] (produção: 3 s, no `main.dart`).
  final Duration intervaloMinimo;

  /// Espera o resto do [intervaloMinimo] (injetável nos testes).
  final Future<void> Function(Duration) esperar;

  static const descansoInicial = Duration(seconds: 20);
  static const descansoMaximo = Duration(minutes: 5);
  static const descansoOcupado = Duration(seconds: 8);
  static const descansoCredencial = Duration(seconds: 60);
  static const descansoDiarioMaximo = Duration(hours: 12);

  CotaIa _cota = CotaIa.vazia;
  Future<void>? _carregando;

  /// Pedidos em andamento por chave (duas telas pedindo o mesmo gastam 1) e usos já reservados.
  final Map<String, Future<ResultadoIa>> _emVoo = {};
  int _reservados = 0;

  CotaIa? _aGravar;
  bool _gravando = false;

  /// Quando saiu a última chamada do [consultarJson] (o [intervaloMinimo] conta daqui).
  DateTime? _ultimaJson;

  IaCubit({
    required this.service,
    required this.cotaRepo,
    CacheExplicacoes? cache,
    this.limite = CotaIa.limitePadrao,
    DateTime Function()? agora,
    DescansoIa? descanso,
    this.intervaloMinimo = Duration.zero,
    Future<void> Function(Duration)? esperar,
  })  : cache = cache ?? CacheExplicacoesLocal(),
        _agora = agora ?? DateTime.now,
        descanso = descanso ?? DescansoIa(),
        esperar = esperar ?? Future<void>.delayed,
        super(const IaState()) {
    carregar();
  }

  /// O relógio do cubit (o `agora` injetado, ou DateTime.now). A contagem na tela usa SÓ este.
  DateTime agora() => _agora();

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
    _emitir(carregado: true);
  }

  /// A janela de descanso, se ainda vale agora (null = livre).
  DateTime? get _esperaAte => descanso.ativo(agora()) ? descanso.ate : null;

  void _emitir({bool? carregado}) {
    if (isClosed) return;
    emit(IaState(
      restantes: _cota.restantes(_hoje, limite: limite) - _reservados,
      carregado: carregado ?? state.carregado,
      esperaAte: _esperaAte,
    ));
  }

  /// Junta o streaming numa resposta só.
  static Future<String> _juntar(Stream<String> fluxo) async {
    final b = StringBuffer();
    await for (final pedaco in fluxo) {
      b.write(pedaco);
    }
    return b.toString();
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
    final r = await _chamar(() => _juntar(service.perguntar(contexto: p.contexto, historico: '', pergunta: p.pergunta)));
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
    final svc = service;
    return _chamar(() => _juntar(persona != null && svc is TutorComPersona
        ? (svc as TutorComPersona).perguntarComo(persona: persona, contexto: contexto, historico: historico, pergunta: pergunta)
        : svc.perguntar(
            contexto: persona == null ? contexto : '$persona\n\n$contexto', historico: historico, pergunta: pergunta)));
  }

  /// Um turno de conversa com resposta em JSON (1 uso, sem cache). [TutorJson] → `perguntarJson`
  /// (esquema, maxTokens); [TutorComPersona] → `perguntarComo(pergunta: '$pergunta\n\n$formatoTexto')`;
  /// senão `perguntar(contexto: '$persona\n\n$contexto', pergunta: '$pergunta\n\n$formatoTexto')`. Nunca lança.
  /// [aceitar] roda no texto ANTES de gastar: false → `ResultadoIa(falhou, '', TipoFalhaIa.outro)`, nada
  /// gasto, sem janela de descanso.
  Future<ResultadoIa> consultarJson({
    required String persona,
    required String contexto,
    String historico = '',
    required String pergunta,
    required Map<String, Object?> esquema,
    required String formatoTexto,
    int maxTokens = 600,
    bool Function(String texto)? aceitar,
  }) async {
    await carregar();
    // durante a janela de descanso nem espera o intervalo: o _chamar já recusa na hora
    if (!descanso.ativo(agora())) await _respeitarIntervalo();
    final svc = service;
    final comFormato = formatoTexto.isEmpty ? pergunta : '$pergunta\n\n$formatoTexto';
    return _chamar(
      () {
        if (svc is TutorJson) {
          return (svc as TutorJson).perguntarJson(
              persona: persona,
              contexto: contexto,
              historico: historico,
              pergunta: pergunta,
              esquema: esquema,
              maxTokens: maxTokens);
        }
        return _juntar(svc is TutorComPersona
            ? (svc as TutorComPersona)
                .perguntarComo(persona: persona, contexto: contexto, historico: historico, pergunta: comFormato)
            : svc.perguntar(contexto: '$persona\n\n$contexto', historico: historico, pergunta: comFormato));
      },
      aceitar: aceitar,
    );
  }

  /// Espera o resto do [intervaloMinimo] desde a última chamada da conversa (espera em vez de recusar).
  Future<void> _respeitarIntervalo() async {
    final ultima = _ultimaJson;
    if (ultima != null && intervaloMinimo > Duration.zero) {
      final resto = intervaloMinimo - agora().difference(ultima);
      if (resto > Duration.zero) await esperar(resto);
    }
    _ultimaJson = agora();
  }

  /// A janela de descanso, a cota (com reserva do uso ANTES de chamar: pedidos simultâneos não
  /// passam do limite), a chamada e o gasto. Só gasta quando o texto veio e [aceitar] o aprovou:
  /// erro, vazio, resposta inútil ou "sem saldo" nunca gastam.
  Future<ResultadoIa> _chamar(Future<String> Function() chamada, {bool Function(String)? aceitar}) async {
    // 1) o projeto está descansando (429/503/401 recente, deste cubit ou de outro): nem chama nem reserva
    if (descanso.ativo(agora())) {
      _emitir();
      return ResultadoIa(StatusIa.falhou, '', descanso.motivo);
    }
    // 2) a cota da pessoa
    if (_cota.restantes(_hoje, limite: limite) - _reservados <= 0) return const ResultadoIa(StatusIa.semCota);
    _reservados++;
    String texto;
    try {
      texto = (await chamada()).trim();
    } catch (e) {
      // 3) falhou: o tipo decide a janela de descanso (semRede/recusada/outro não abrem janela)
      _reservados--;
      final f = FalhaIa.de(e);
      descanso.registrar(f.tipo, agora());
      _emitir();
      return ResultadoIa(StatusIa.falhou, '', f.tipo);
    }
    _reservados--;
    var util = texto.isNotEmpty;
    if (util && aceitar != null) {
      try {
        util = aceitar(texto);
      } catch (_) {
        util = false;
      }
    }
    if (!util) return const ResultadoIa(StatusIa.falhou, '', TipoFalhaIa.outro); // não gasta
    // 4) deu certo: o projeto respondeu, a janela some
    descanso.limpar();
    _cota = _cota.gastar(_hoje);
    _emitir(carregado: true);
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
    super.descanso,
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
