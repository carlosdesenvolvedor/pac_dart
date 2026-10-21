import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/habito/domain/habito.dart' show diaDe;
import 'package:pac_dart/features/ia/data/cache_explicacoes.dart';
import 'package:pac_dart/features/ia/data/cota_repository.dart';
import 'package:pac_dart/features/ia/domain/cota_ia.dart';
import 'package:pac_dart/features/ia/domain/explicacao.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/tutor/data/tutor_service.dart';

/// Tutor de mentira: conta chamadas, guarda o que recebeu e pode falhar, vir vazio ou demorar.
class TutorFalso implements TutorService {
  int chamadas = 0;
  final contextos = <String>[];
  final perguntas = <String>[];
  List<String> pedacos = ['Porque ', '**I\'m** é a contração. '];
  Object? erro;
  Completer<void>? segura;

  @override
  Stream<String> perguntar({required String contexto, required String historico, required String pergunta}) async* {
    chamadas++;
    contextos.add(contexto);
    perguntas.add(pergunta);
    await segura?.future;
    if (erro != null) throw erro!;
    for (final p in pedacos) {
      yield p;
    }
  }
}

class CotaMemoria implements CotaRepository {
  CotaIa guardada;
  final gravacoes = <CotaIa>[];
  bool falhaAoGravar = false;
  CotaMemoria([this.guardada = CotaIa.vazia]);
  @override
  Future<CotaIa> carregar() async => guardada;
  @override
  Future<void> salvar(CotaIa cota) async {
    if (falhaAoGravar) throw Exception('sem rede');
    gravacoes.add(cota);
    guardada = cota;
  }
}

class CacheMemoria implements CacheExplicacoes {
  final mapa = <String, String>{};
  @override
  Future<String?> ler(String chave) async => mapa[chave];
  @override
  Future<void> gravar(String chave, String texto) async => mapa[chave] = texto;
}

class Relogio {
  DateTime t = DateTime(2026, 10, 13, 10);
  DateTime call() => t;
  void dias(int n) => t = DateTime(t.year, t.month, t.day + n, 10);
}

PedidoExplicacao pedido([String resposta = 'hi am ana']) => PedidoExplicacao(
      frase: "Hi, I'm Ana.",
      traducao: 'Oi, eu sou a Ana.',
      resposta: resposta,
      palavrasErradas: const ["I'm"],
      exercicio: 'cartão PT → EN (Avançado)',
    );

void main() {
  late TutorFalso tutor;
  late CotaMemoria cotaRepo;
  late CacheMemoria cache;
  late Relogio relogio;

  setUp(() {
    tutor = TutorFalso();
    cotaRepo = CotaMemoria();
    cache = CacheMemoria();
    relogio = Relogio();
  });

  Future<IaCubit> criar({int limite = 30}) async {
    final c = IaCubit(service: tutor, cotaRepo: cotaRepo, cache: cache, agora: relogio.call, limite: limite);
    await c.carregar();
    return c;
  }

  test('carrega a cota e mostra os usos que restam', () async {
    cotaRepo.guardada = CotaIa(dia: diaDe(relogio.t), usos: 12);
    final c = await criar();
    expect(c.state.carregado, isTrue);
    expect(c.state.restantes, 18);
    await c.close();
  });

  test('sucesso: devolve o texto juntando os pedaços, gasta 1, guarda no cache e grava a cota', () async {
    final c = await criar();
    final r = await c.explicar(pedido());
    expect(r.status, StatusIa.ok);
    expect(r.texto, "Porque **I'm** é a contração.");
    expect(tutor.chamadas, 1);
    expect(c.state.restantes, 29);
    expect(cache.mapa[pedido().chave], r.texto);
    await pumpEventQueue();
    expect(cotaRepo.guardada.usos, 1);
    await c.close();
  });

  test('o serviço recebe o pedido montado (contexto do erro + pergunta em português)', () async {
    final c = await criar();
    await c.explicar(pedido());
    expect(tutor.contextos.single, startsWith('PEDIDO: explicar um erro'));
    expect(tutor.contextos.single, contains('"hi am ana"'));
    expect(tutor.perguntas.single, contains('em português'));
    await c.close();
  });

  test('CACHE: o mesmo erro de novo NÃO chama a IA e NÃO gasta cota', () async {
    final c = await criar();
    await c.explicar(pedido());
    final r = await c.explicar(pedido());
    expect(r.status, StatusIa.ok);
    expect(tutor.chamadas, 1);
    expect(c.state.restantes, 29);
    // outra resposta errada = outro erro = chama (e gasta) de novo
    await c.explicar(pedido('hi are ana'));
    expect(tutor.chamadas, 2);
    expect(c.state.restantes, 28);
    await c.close();
  });

  test('cache cheio de outra sessão também vale (depois de reiniciar o app)', () async {
    cache.mapa[pedido().chave] = 'já explicado antes';
    final c = await criar();
    final r = await c.explicar(pedido());
    expect(r.texto, 'já explicado antes');
    expect(tutor.chamadas, 0);
    expect(c.state.restantes, 30);
    await c.close();
  });

  test('FALHA não gasta cota e não vai para o cache (exceção, vazio, só espaços)', () async {
    final c = await criar();
    tutor.erro = Exception('429 RESOURCE_EXHAUSTED');
    expect((await c.explicar(pedido())).status, StatusIa.falhou);
    // o 429 abre a janela de descanso do projeto (20 s): passa dela para os próximos casos chegarem ao serviço
    relogio.t = relogio.t.add(IaCubit.descansoInicial + const Duration(seconds: 1));
    tutor
      ..erro = null
      ..pedacos = [];
    expect((await c.explicar(pedido())).status, StatusIa.falhou);
    tutor.pedacos = ['   ', '\n'];
    expect((await c.explicar(pedido())).status, StatusIa.falhou);
    expect(c.state.restantes, 30);
    expect(cache.mapa, isEmpty);
    await pumpEventQueue();
    expect(cotaRepo.gravacoes, isEmpty);
    // e depois que o serviço volta, funciona e gasta 1
    tutor.pedacos = ['ok'];
    expect((await c.explicar(pedido())).status, StatusIa.ok);
    expect(c.state.restantes, 29);
    await c.close();
  });

  test('COTA: no limite a IA nem é chamada; o cache ainda responde', () async {
    cotaRepo.guardada = CotaIa(dia: diaDe(relogio.t), usos: 30);
    cache.mapa[pedido('no cache').chave] = 'resposta guardada';
    final c = await criar();
    final r = await c.explicar(pedido());
    expect(r.status, StatusIa.semCota);
    expect(tutor.chamadas, 0);
    expect((await c.explicar(pedido('no cache'))).texto, 'resposta guardada');
    expect(c.state.restantes, 0);
    await c.close();
  });

  test('limite parametrizado: o 3º pedido de um limite 2 é negado', () async {
    final c = await criar(limite: 2);
    expect((await c.explicar(pedido('a'))).status, StatusIa.ok);
    expect((await c.explicar(pedido('b'))).status, StatusIa.ok);
    expect((await c.explicar(pedido('c'))).status, StatusIa.semCota);
    expect(tutor.chamadas, 2);
    await c.close();
  });

  test('VIRADA DO DIA devolve a cota; relógio que volta não devolve', () async {
    cotaRepo.guardada = CotaIa(dia: diaDe(relogio.t), usos: 30);
    final c = await criar();
    expect((await c.explicar(pedido())).status, StatusIa.semCota);
    relogio.dias(-2);
    expect((await c.explicar(pedido())).status, StatusIa.semCota, reason: 'relógio voltou: nada de saldo de graça');
    relogio.dias(3);
    expect((await c.explicar(pedido())).status, StatusIa.ok);
    expect(c.state.restantes, 29);
    await pumpEventQueue();
    expect(cotaRepo.guardada, CotaIa(dia: diaDe(relogio.t), usos: 1));
    await c.close();
  });

  test('DUAS chamadas iguais ao mesmo tempo: 1 pedido ao serviço e 1 uso', () async {
    final c = await criar();
    tutor.segura = Completer<void>();
    final a = c.explicar(pedido());
    final b = c.explicar(pedido());
    await pumpEventQueue();
    tutor.segura!.complete();
    final r = await Future.wait([a, b]);
    expect(r.map((e) => e.status), [StatusIa.ok, StatusIa.ok]);
    expect(tutor.chamadas, 1);
    expect(c.state.restantes, 29);
    await c.close();
  });

  test('pedidos DIFERENTES ao mesmo tempo respeitam o limite (reserva o uso antes de chamar)', () async {
    final c = await criar(limite: 1);
    tutor.segura = Completer<void>();
    final a = c.explicar(pedido('a'));
    final b = c.explicar(pedido('b'));
    await pumpEventQueue();
    tutor.segura!.complete();
    final r = await Future.wait([a, b]);
    expect(r.map((e) => e.status).toSet(), {StatusIa.ok, StatusIa.semCota});
    expect(tutor.chamadas, 1);
    await c.close();
  });

  test('erro ao gravar a cota é engolido: a tela segue certa e o próximo salvar leva o estado inteiro', () async {
    final c = await criar();
    cotaRepo.falhaAoGravar = true;
    expect((await c.explicar(pedido('a'))).status, StatusIa.ok);
    await pumpEventQueue();
    expect(c.state.restantes, 29);
    cotaRepo.falhaAoGravar = false;
    await c.explicar(pedido('b'));
    await pumpEventQueue();
    expect(cotaRepo.guardada.usos, 2);
    await c.close();
  });

  test('pedido sem nada a explicar não chama a IA nem gasta', () async {
    final c = await criar();
    final r = await c.explicar(const PedidoExplicacao(frase: 'a', traducao: 'b'));
    expect(r.status, StatusIa.falhou);
    expect(tutor.chamadas, 0);
    expect(c.state.restantes, 30);
    await c.close();
  });

  test('explicar durante o carregamento espera a cota (não gasta em cima de uma cota ainda não lida)', () async {
    cotaRepo.guardada = CotaIa(dia: diaDe(relogio.t), usos: 30);
    final c = IaCubit(service: tutor, cotaRepo: cotaRepo, cache: cache, agora: relogio.call);
    final r = await c.explicar(pedido()); // sem esperar o carregar()
    expect(r.status, StatusIa.semCota);
    expect(tutor.chamadas, 0);
    await c.close();
  });

  test('erro ao LER a cota: começa cheia (perdoa) e funciona', () async {
    final c = IaCubit(service: tutor, cotaRepo: _CotaQueFalhaNaLeitura(), cache: cache, agora: relogio.call);
    expect((await c.explicar(pedido())).status, StatusIa.ok);
    await c.close();
  });
}

class _CotaQueFalhaNaLeitura implements CotaRepository {
  @override
  Future<CotaIa> carregar() async => throw Exception('x');
  @override
  Future<void> salvar(CotaIa cota) async {}
}
