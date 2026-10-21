// O cubit das setlists do "🎧 Ouvir": o ➕ sem setlist cria "Minha setlist", vai para a última usada,
// "Trocar" move o item, e as gravações esperam a folga, vão em ordem e só o estado mais novo é gravado.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/data/setlists_repository.dart';
import 'package:pac_dart/features/ingles/domain/setlist.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/setlists_cubit.dart';

ItemSetlist _item(String id, String ref) => ItemSetlist(id: id, tipo: TipoItem.licao, ref: ref, rotulo: ref, criadoEm: 1);

/// Um repositório cuja gravação só termina quando o teste manda (para ver a fila de gravações).
class _RepoLento extends MemoriaSetlistsRepository {
  final gravados = <BancoSetlists>[];
  Completer<void>? porta;
  @override
  Future<void> salvar(BancoSetlists b) async {
    gravados.add(b);
    final p = porta;
    if (p != null) await p.future;
    await super.salvar(b);
  }
}

/// Um repositório que demora para ler.
class _RepoQueDemora extends MemoriaSetlistsRepository {
  final leitura = Completer<BancoSetlists>();
  _RepoQueDemora() : super();
  @override
  Future<BancoSetlists> carregar() => leitura.future;
}

/// Aparelho × nuvem: a cópia do aparelho chega na hora, a nuvem só quando o teste manda.
class _RepoNuvemLenta extends MemoriaSetlistsRepository {
  BancoSetlists aparelho;
  final nuvem = Completer<BancoSetlists>();
  final noAparelho = <BancoSetlists>[];
  _RepoNuvemLenta(this.aparelho);
  @override
  Future<BancoSetlists> carregarLocal() async => aparelho;
  @override
  Future<BancoSetlists> carregar() async => BancoSetlists.mesclar(aparelho, await nuvem.future);
  @override
  Future<void> salvarLocal(BancoSetlists b) async {
    noAparelho.add(b);
    aparelho = b;
  }
}

void main() {
  var relogio = 1000;
  SetlistsCubit cubit(SetlistsRepository repo, {Duration folga = Duration.zero}) =>
      SetlistsCubit(repo: repo, agora: () => relogio++, folga: folga);

  test('carregar é memoizado e mostra o banco gravado', () async {
    final (b, _) = const BancoSetlists().criar('Ônibus', agora: 1);
    final repo = MemoriaSetlistsRepository(b);
    final c = cubit(repo);
    expect(identical(c.carregar(), c.carregar()), isTrue);
    await c.carregar();
    expect(c.state, b);
    expect(c.carregado, isTrue);
    await c.close();
  });

  test('adicionar sem nenhuma setlist cria "Minha setlist" e põe lá; o próximo vai na última usada', () async {
    final repo = MemoriaSetlistsRepository();
    final c = cubit(repo);
    final (r, id) = await c.adicionar(_item('a', 'l.a'));
    expect(r, ResultadoAdicao.adicionado);
    expect(c.state.porId[id]!.nome, 'Minha setlist');
    expect(c.state.ultimaUsada, id);
    expect((await c.adicionar(_item('b', 'l.b'))).$2, id);
    expect((await c.adicionar(_item('c', 'l.a'))).$1, ResultadoAdicao.jaEstava);
    expect(c.state.porId[id]!.itens.map((i) => i.id), ['a', 'b']);
    await c.descarregar();
    expect(repo.banco, c.state, reason: 'gravou');
    await c.close();
  });

  test('adicionar numa setlist escolhida a torna a última usada; setlist sumida cai na última usada', () async {
    final c = cubit(MemoriaSetlistsRepository());
    final onibus = await c.criar('Ônibus', emoji: '🚌');
    final academia = await c.criar('Academia');
    expect(c.state.ultimaUsada, academia);
    expect((await c.adicionar(_item('a', 'l.a'), setlistId: onibus)).$2, onibus);
    expect(c.state.ultimaUsada, onibus);
    await c.apagar(onibus);
    expect(c.state.ultimaUsada, '');
    // a última usada foi apagada e não há "Minha setlist": cria uma
    final (_, nova) = await c.adicionar(_item('b', 'l.b'), setlistId: onibus);
    expect(nova, isNot(onibus));
    expect(nova, isNot(academia));
    expect(c.state.porId[nova]!.nome, 'Minha setlist');
    // apagada a última usada, o ➕ vai para a "Minha setlist" que já existe (não cria outra)
    final outra = await c.criar('Outra');
    expect(c.state.ultimaUsada, outra);
    await c.apagar(outra);
    expect((await c.adicionar(_item('c', 'l.c'))).$2, nova);
    expect(c.state.visiveis, hasLength(2));
    await c.close();
  });

  test('renomear, remover, restaurar e mover passam pelo banco', () async {
    final c = cubit(MemoriaSetlistsRepository());
    final id = await c.criar('X');
    for (final i in [_item('a', 'A'), _item('b', 'B'), _item('c', 'C')]) {
      await c.adicionar(i, setlistId: id);
    }
    List<String> ids() => [for (final i in c.state.porId[id]!.itens) i.id];
    await c.renomear(id, 'Academia', emoji: '🏋️');
    expect(c.state.porId[id]!.nome, 'Academia');
    final removido = c.state.porId[id]!.itens[1];
    await c.remover(id, 'b');
    expect(ids(), ['a', 'c']);
    await c.restaurar(id, removido, 1);
    expect(ids(), ['a', 'b', 'c']);
    await c.mover(id, 0, 2);
    expect(ids(), ['b', 'c', 'a']);
    await c.close();
  });

  test('moverItemPara ("Trocar"): sai de uma e entra no fim da outra, que vira a última usada', () async {
    final c = cubit(MemoriaSetlistsRepository());
    final a = await c.criar('A');
    final b = await c.criar('B');
    await c.adicionar(_item('x', 'X'), setlistId: b);
    await c.adicionar(_item('y', 'Y'), setlistId: a);
    await c.moverItemPara(a, 'y', b);
    expect(c.state.porId[a]!.itens, isEmpty);
    expect(c.state.porId[b]!.itens.map((i) => i.id), ['x', 'y']);
    expect(c.state.ultimaUsada, b);
    // já existe um igual no destino: só sai da origem
    await c.adicionar(_item('y2', 'Y'), setlistId: a);
    await c.moverItemPara(a, 'y2', b);
    expect(c.state.porId[a]!.itens, isEmpty);
    expect(c.state.porId[b]!.itens.map((i) => i.id), ['x', 'y']);
    // item ou setlist inexistente: nada muda
    final antes = c.state;
    await c.moverItemPara(a, 'nada', b);
    await c.moverItemPara(b, 'x', 'sumiu');
    expect(c.state, antes);
    await c.close();
  });

  test('gravações: esperam a folga, vão em ordem e só o mais novo vai depois', () async {
    final repo = _RepoLento();
    final c = cubit(repo, folga: const Duration(milliseconds: 30));
    final id = await c.criar('X');
    await c.adicionar(_item('a', 'A'), setlistId: id);
    await c.adicionar(_item('b', 'B'), setlistId: id);
    expect(repo.gravados, isEmpty, reason: 'ainda na folga');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(repo.gravados, hasLength(1), reason: 'as três mudanças viraram uma gravação');
    expect(repo.gravados.single.porId[id]!.itens, hasLength(2));

    // uma gravação presa: chegam três estados; depois dela, só o último vai
    repo.porta = Completer<void>();
    await c.adicionar(_item('c', 'C'), setlistId: id);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(repo.gravados, hasLength(2));
    await c.adicionar(_item('d', 'D'), setlistId: id);
    await c.adicionar(_item('e', 'E'), setlistId: id);
    await c.renomear(id, 'Final');
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(repo.gravados, hasLength(2), reason: 'em ordem: espera a que está gravando');
    repo.porta!.complete();
    repo.porta = null;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await c.descarregar();
    expect(repo.gravados, hasLength(3));
    expect(repo.gravados.last, c.state, reason: 'só o mais novo');
    expect(repo.banco.porId[id]!.nome, 'Final');
    await c.close();
  });

  test('fechar grava na hora o que esperava a folga', () async {
    final repo = MemoriaSetlistsRepository();
    final c = cubit(repo, folga: const Duration(seconds: 30));
    await c.criar('X');
    expect(repo.salvos, 0);
    await c.close();
    await Future<void>.delayed(Duration.zero);
    expect(repo.salvos, 1);
    expect(repo.banco.visiveis.single.nome, 'X');
  });

  test('ação antes de a leitura chegar: espera; se a leitura atrasa, junta as duas sem perder nada', () async {
    final repo = _RepoQueDemora();
    final c = cubit(repo);
    unawaited(c.carregar());
    // a leitura chega logo: a ação viu o banco gravado
    final (gravado, onibus) = const BancoSetlists().criar('Ônibus', agora: 1);
    final adicao = c.adicionar(_item('a', 'A'));
    repo.leitura.complete(gravado);
    final (r, id) = await adicao;
    expect(r, ResultadoAdicao.adicionado);
    expect(id, onibus, reason: 'foi para a última usada gravada, sem criar outra');
    await c.close();
  });

  test('leitura atrasada: a ação segue na memória sem gravar; quando a leitura chega, junta e grava', () async {
    final repo = _RepoQueDemora();
    final c = cubit(repo);
    unawaited(c.carregar());
    final nova = await c.criar('Nova'); // espera o limite (2 s) e segue
    expect(c.state.visiveis.single.nome, 'Nova');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repo.salvos, 0, reason: 'gravar antes de ler apagaria a cópia do aparelho');
    final (gravado, velha) = const BancoSetlists().criar('Velha', agora: 1);
    repo.leitura.complete(gravado);
    await c.carregar();
    expect(c.state.porId.keys.toSet(), {velha, nova});
    expect(c.state.ultimaUsada, nova, reason: 'a da memória (mais nova)');
    await c.descarregar();
    expect(repo.salvos, 1);
    expect(repo.banco, c.state);
    await c.close();
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('nuvem lenta: o aparelho entra na hora, o ➕ não espera nem cria outra "Minha setlist"', () async {
    final (b0, minha) = const BancoSetlists().criar(BancoSetlists.nomePadrao, agora: 1);
    final (comItem, _) = b0.adicionar(minha, _item('a', 'A'), agora: 2);
    final repo = _RepoNuvemLenta(comItem);
    final c = cubit(repo, folga: const Duration(seconds: 30));
    unawaited(c.carregar());
    final relogioAntes = DateTime.now();
    final (r, id) = await c.adicionar(_item('b', 'B'));
    expect(DateTime.now().difference(relogioAntes), lessThan(const Duration(seconds: 1)), reason: 'não esperou a nuvem');
    expect(r, ResultadoAdicao.adicionado);
    expect(id, minha);
    expect(c.state.visiveis, hasLength(1));
    // a nuvem chega depois (com outra setlist): junta, sem duplicar
    final (daNuvem, outra) = const BancoSetlists().criar('Do celular', agora: 3);
    repo.nuvem.complete(daNuvem);
    await c.carregar();
    expect(c.state.porId.keys.toSet(), {minha, outra});
    expect(c.state.porId[minha]!.itens.map((i) => i.id), ['a', 'b']);
    await c.close();
  });

  test('cada mudança vai já para o aparelho (sem folga); a gravação completa espera a folga', () async {
    final repo = _RepoNuvemLenta(const BancoSetlists());
    repo.nuvem.complete(const BancoSetlists());
    final c = cubit(repo, folga: const Duration(seconds: 30));
    await c.carregar();
    final id = await c.criar('X');
    await c.adicionar(_item('a', 'A'), setlistId: id);
    await Future<void>.delayed(Duration.zero);
    expect(repo.aparelho, c.state, reason: 'o aparelho já tem a última mudança');
    expect(repo.noAparelho, hasLength(2));
    expect(repo.salvos, 0, reason: 'a nuvem ainda espera a folga');
    await c.close();
    await Future<void>.delayed(Duration.zero);
    expect(repo.salvos, 1);
  });
}
