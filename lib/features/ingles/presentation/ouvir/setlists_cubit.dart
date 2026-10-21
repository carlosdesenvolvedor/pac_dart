import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/setlists_repository.dart';
import '../../domain/setlist.dart';

/// As setlists do "🎧 Ouvir" (só no inglês). Offline-first: cada ação muda a tela e a cópia do aparelho
/// na hora; a gravação completa (com a nuvem) vem depois (em ordem, 600 ms de folga, só o mais novo vai
/// depois).
///
/// A leitura vem em dois tempos: a cópia do aparelho ([SetlistsRepository.carregarLocal], rápida) e depois
/// a nuvem ([SetlistsRepository.carregar]), que se junta por cima ([BancoSetlists.mesclar]: a edição mais
/// nova ganha). As ações esperam só a do aparelho (até [esperaLeitura]); se ela demorar mais, a ação vale
/// sobre o que há na memória e se junta quando a leitura chegar. Antes de ler o aparelho, nada é gravado —
/// gravar um banco parcial apagaria a cópia dele.
class SetlistsCubit extends Cubit<BancoSetlists> {
  final SetlistsRepository repo;

  /// Relógio injetável (testes), em ms desde 1970.
  final int Function() agora;

  /// A folga antes de gravar: mudanças seguidas (arrastar, desfazer…) viram uma gravação só.
  final Duration folga;

  /// Quanto uma ação espera a primeira leitura antes de seguir com o que tem.
  static const esperaLeitura = Duration(seconds: 2);

  Future<void>? _carregando;
  bool _carregado = false;
  BancoSetlists? _aGravar;
  bool _gravando = false;
  Future<void>? _gravacao;
  Timer? _relogio;

  SetlistsCubit({required this.repo, int Function()? agora, this.folga = const Duration(milliseconds: 600)})
      : agora = agora ?? (() => DateTime.now().millisecondsSinceEpoch),
        super(const BancoSetlists());

  static SetlistsCubit? de(BuildContext c) {
    try {
      return BlocProvider.of<SetlistsCubit>(c, listen: false);
    } catch (_) {
      return null;
    }
  }

  /// Já leu o banco do repositório?
  bool get carregado => _carregado;

  /// Memoizado; termina quando a nuvem também chegou (ou falhou).
  Future<void> carregar() => _carregando ??= _carregar();

  /// A cópia do aparelho já entrou (as ações não esperam mais).
  final _aparelhoLido = Completer<void>();

  Future<void> _carregar() async {
    // 1. o aparelho, na hora
    BancoSetlists local;
    try {
      local = await repo.carregarLocal();
    } catch (_) {
      local = const BancoSetlists();
    }
    if (isClosed) return;
    _carregado = true;
    // o que foi feito antes de a leitura chegar entra por cima (é mais novo)
    final junto = BancoSetlists.mesclar(state, local);
    emit(junto);
    if (!_aparelhoLido.isCompleted) _aparelhoLido.complete();
    if (junto != local) _gravarAparelho(junto);
    // 2. a nuvem, quando chegar (o repositório já limita a espera)
    BancoSetlists lido;
    try {
      lido = await repo.carregar();
    } catch (_) {
      lido = const BancoSetlists();
    }
    if (isClosed) return;
    final tudo = BancoSetlists.mesclar(state, lido);
    if (tudo != state) emit(tudo);
    if (tudo != lido) {
      _gravarAparelho(tudo);
      _salvar(tudo);
    }
  }

  Future<void> _esperarLeitura() async {
    if (_carregado) return;
    unawaited(carregar());
    try {
      await _aparelhoLido.future.timeout(esperaLeitura);
    } catch (_) {}
  }

  /// Aplica [f] ao banco (depois da leitura), mostra, grava já no aparelho e agenda a gravação completa
  /// se algo mudou.
  Future<T> _mudar<T>((BancoSetlists, T) Function(BancoSetlists b) f) async {
    await _esperarLeitura();
    final (depois, r) = f(state);
    if (!isClosed && !identical(depois, state)) {
      emit(depois);
      if (_carregado) {
        _gravarAparelho(depois);
        _salvar(depois);
      }
    }
    return r;
  }

  /// A cópia do aparelho, sem folga e fora da fila da nuvem (uma gravação lenta na nuvem não a atrasa).
  /// As chamadas seguidas chegam ao aparelho na ordem em que foram feitas.
  void _gravarAparelho(BancoSetlists b) {
    unawaited(repo.salvarLocal(b).catchError((Object _) {}));
  }

  Future<void> _so(BancoSetlists Function(BancoSetlists b) f) => _mudar((b) => (f(b), null));

  /// Devolve o id da nova setlist ('' no limite de [BancoSetlists.maxSetlists]).
  Future<String> criar(String nome, {String emoji = '🎧'}) =>
      _mudar((b) => b.criar(nome, emoji: emoji, agora: agora()));

  Future<void> renomear(String id, String nome, {String? emoji}) =>
      _so((b) => b.renomear(id, nome, emoji: emoji, agora: agora()));

  Future<void> apagar(String id) => _so((b) => b.apagar(id, agora: agora()));

  /// [setlistId] null (ou de uma setlist que não existe mais) → a última usada; sem ela, uma
  /// "Minha setlist" que já exista, ou uma nova com esse nome. No limite de setlists: `(cheia, '')`.
  Future<(ResultadoAdicao, String setlistId)> adicionar(ItemSetlist item, {String? setlistId}) => _mudar((b) {
        var banco = b;
        var id = _destino(banco, setlistId);
        if (id == null) {
          final (criado, novo) = banco.criar(BancoSetlists.nomePadrao, agora: agora());
          if (novo.isEmpty) return (b, (ResultadoAdicao.cheia, ''));
          banco = criado;
          id = novo;
        }
        final (depois, r) = banco.adicionar(id, item, agora: agora());
        return (depois, (r, id));
      });

  /// Para onde vai um ➕: [pedida] se viva; senão a última usada; senão uma "Minha setlist" visível.
  static String? _destino(BancoSetlists b, String? pedida) {
    if (pedida != null && b.viva(pedida) != null) return pedida;
    if (b.viva(b.ultimaUsada) != null) return b.ultimaUsada;
    for (final s in b.visiveis) {
      if (s.nome == BancoSetlists.nomePadrao) return s.id;
    }
    return null;
  }

  Future<void> remover(String setlistId, String itemId) =>
      _so((b) => b.remover(setlistId, itemId, agora: agora()));

  Future<void> restaurar(String setlistId, ItemSetlist item, int indice) =>
      _so((b) => b.restaurar(setlistId, item, indice, agora: agora()));

  /// [para] é a posição FINAL do item (ver [BancoSetlists.mover]).
  Future<void> mover(String setlistId, int de, int para) =>
      _so((b) => b.mover(setlistId, de, para, agora: agora()));

  /// O "Trocar" do snackbar: tira o item de [deSetlist] e põe no fim de [paraSetlist] (que vira a
  /// última usada). Se [paraSetlist] já tem um igual, só sai da primeira; se está cheia, nada muda.
  Future<void> moverItemPara(String deSetlist, String itemId, String paraSetlist) => _so((b) {
        if (deSetlist == paraSetlist) return b;
        final item = b.viva(deSetlist)?.itens.where((i) => i.id == itemId).firstOrNull;
        if (item == null || b.viva(paraSetlist) == null) return b;
        final t = agora();
        final (comNovo, r) = b.adicionar(paraSetlist, item, agora: t);
        if (r == ResultadoAdicao.cheia) return b;
        return comNovo.remover(deSetlist, itemId, agora: t);
      });

  /// Grava em ordem e sem empilhar, depois da [folga]: chegando outro estado durante a gravação, só o
  /// mais novo vai depois. Erro (sem rede) é engolido: o aparelho já guardou e o próximo salvar tenta de novo.
  void _salvar(BancoSetlists b) {
    _aGravar = b;
    _relogio?.cancel();
    _relogio = Timer(folga, _disparar);
  }

  void _disparar() {
    _relogio = null;
    if (_gravando || _aGravar == null) return;
    _gravando = true;
    _gravacao = _laco();
  }

  Future<void> _laco() async {
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

  /// Grava já o que estiver esperando a folga e termina quando a gravação acabar (testes).
  @visibleForTesting
  Future<void> descarregar() async {
    _relogio?.cancel();
    _disparar();
    await (_gravacao ?? Future<void>.value());
  }

  /// Fecha sem perder a última mudança: o que esperava a folga vai agora (sem esperar a rede).
  @override
  Future<void> close() {
    _relogio?.cancel();
    _disparar();
    return super.close();
  }
}
