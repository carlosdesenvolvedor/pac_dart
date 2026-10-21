import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../../curso/domain/curriculo.dart';
import '../../../curso/presentation/bloc/curso_bloc.dart';
import '../../data/saida_voz_ingles.dart';
import '../../domain/config_ouvir.dart';
import '../../domain/fila_ouvir.dart';
import '../../domain/saida_audio.dart';
import '../../domain/setlist.dart';
import 'escolher_frases_sheet.dart';
import 'escolher_setlist_sheet.dart';
import 'mini_player.dart';
import 'ouvir_cubit.dart';
import 'ouvir_page.dart';
import 'ouvir_state.dart';
import 'setlist_page.dart';
import 'setlists_cubit.dart';
import 'tocando_page.dart';

// As portas de entrada do "🎧 Ouvir" para o resto do app. Todas voltam na hora quando não há
// [OuvirCubit]/[SetlistsCubit] (fora do curso de inglês).

bool _semOuvir(BuildContext c) => OuvirCubit.de(c) == null || SetlistsCubit.de(c) == null;

/// O título da fonte "curso" (e do item `curso`).
const tituloCursoInteiro = 'Curso inteiro';

Future<void> abrirOuvir(BuildContext c) async {
  if (_semOuvir(c)) return;
  await Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const OuvirPage()));
}

/// Abre o "Tocando agora". Funciona também de cima do Navigator (o mini-player), pela chave do
/// [NavegadorOuvir]. Não abre de novo se já está aberto.
Future<void> abrirTocando(BuildContext c) async {
  if (_semOuvir(c)) return;
  final cubit = OuvirCubit.de(c)!;
  if (cubit.state.telaCheia) return;
  // com folha/diálogo aberto, o player não abre por cima dele (a barra fica fora da barreira do modal)
  if (NavegadorOuvir.de(c)?.observador.topo.value.modal ?? false) return;
  final nav = NavegadorOuvir.de(c)?.chave.currentState ?? Navigator.maybeOf(c);
  if (nav == null) return;
  await nav.push(MaterialPageRoute<void>(builder: (_) => const TocandoPage()));
}

/// Abre a página de uma setlist.
Future<void> abrirSetlist(BuildContext c, String setlistId) async {
  if (_semOuvir(c)) return;
  await Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => SetlistPage(setlistId: setlistId)));
}

/// Fonte 'avulso'.
Future<void> tocarItens(BuildContext c, List<ItemSetlist> itens, {required String titulo}) async {
  if (_semOuvir(c)) return;
  _tocar(c, FonteOuvir('avulso', titulo), filaDosItens(c, itens).faixas, 0);
}

/// "Ouvir daqui até o fim do curso". Uma lição fora do curso (texto do aluno) toca só ela.
Future<void> tocarCursoDesde(BuildContext c, String licaoId) async {
  if (_semOuvir(c)) return;
  final fila = filaDoCurso(c);
  final i = fila.faixas.indexWhere((f) => f.licaoId == licaoId);
  if (i >= 0) {
    _tocar(c, const FonteOuvir('curso', tituloCursoInteiro), fila.faixas, i);
    return;
  }
  final trilhas = trilhasDoCurso(c);
  final pos = IndiceOuvir.de(trilhas).licao(licaoId);
  if (pos == null) {
    _avisar(ScaffoldMessenger.maybeOf(c), 'Nada para tocar aqui.');
    return;
  }
  final l = trilhas[pos.t].licoes[pos.l];
  await tocarItens(c, [ItemSetlist.daLicao(l)], titulo: l.nome);
}

/// O curso inteiro na ordem, a partir da faixa [inicio].
Future<void> tocarCurso(BuildContext c, {int inicio = 0}) async {
  if (_semOuvir(c)) return;
  _tocar(c, const FonteOuvir('curso', tituloCursoInteiro), filaDoCurso(c).faixas, inicio);
}

/// Toca a setlist [s] a partir do item [item] (índice em `s.itens`).
Future<void> tocarSetlist(BuildContext c, Setlist s, {int item = 0}) async {
  if (_semOuvir(c)) return;
  final fila = filaDosItens(c, s.itens);
  final inicio = item > 0 && item < fila.inicioDoItem.length ? fila.inicioDoItem[item] : 0;
  _tocar(c, FonteOuvir('setlist:${s.id}', s.nome), fila.faixas, inicio);
}

void _tocar(BuildContext c, FonteOuvir fonte, List<Faixa> faixas, int inicio) {
  if (faixas.isEmpty) {
    _avisar(ScaffoldMessenger.maybeOf(c), 'Nada para tocar aqui.');
    return;
  }
  // não espera: o motor segue tocando a fila depois daqui
  unawaited(OuvirCubit.de(c)!.tocar(fonte, faixas, inicio: inicio.clamp(0, faixas.length - 1)));
}

/// Põe na última setlist usada + snackbar (Desfazer / Trocar).
Future<void> porNaSetlist(BuildContext c, ItemSetlist item) async {
  if (_semOuvir(c)) return;
  final setlists = SetlistsCubit.de(c)!;
  final messenger = ScaffoldMessenger.maybeOf(c);
  final (r, id) = await setlists.adicionar(item);
  _avisarAdicao(messenger, setlists, r, id, item, trocar: () {
    if (!c.mounted) return;
    unawaited(_trocarSetlist(c, setlists, id, item));
  });
}

/// A folha "Pôr em qual setlist?".
Future<void> escolherSetlist(BuildContext c, ItemSetlist item) async {
  if (_semOuvir(c)) return;
  final setlists = SetlistsCubit.de(c)!;
  final ouvir = OuvirCubit.de(c)!;
  final messenger = ScaffoldMessenger.maybeOf(c);
  final escolha = await mostrarEscolherSetlist(c, setlists: setlists, tocarAgora: ouvir.state.ativo);
  if (escolha == null || !c.mounted) return;
  if (escolha == EscolhaSetlist.tocarAgora) {
    await tocarItens(c, [item], titulo: item.rotulo);
    return;
  }
  final (r, id) = await setlists.adicionar(item, setlistId: escolha);
  _avisarAdicao(messenger, setlists, r, id, item);
}

/// A folha com as frases da lição para marcar.
Future<void> escolherFrasesDaLicao(BuildContext c, Licao l) async {
  if (_semOuvir(c)) return;
  final ouvir = OuvirCubit.de(c)!;
  final r = await mostrarEscolherFrases(c, l, ouvir: (en) => unawaited(ouvir.saida.en(en, fator: 1)));
  if (r == null || r.escolhidas.isEmpty || !c.mounted) return;
  final item = ItemSetlist.doTrecho(l, r.escolhidas);
  if (r.tocar) {
    await tocarItens(c, [item], titulo: l.nome);
  } else {
    await porNaSetlist(c, item);
  }
}

/// O "Trocar" do snackbar: escolhe outra setlist e muda o item para lá.
Future<void> _trocarSetlist(BuildContext c, SetlistsCubit setlists, String deSetlist, ItemSetlist item) async {
  final messenger = ScaffoldMessenger.maybeOf(c);
  final para = await mostrarEscolherSetlist(c, setlists: setlists, tocarAgora: false, atual: deSetlist);
  if (para == null || para == EscolhaSetlist.tocarAgora || para == deSetlist) return;
  await setlists.moverItemPara(deSetlist, item.id, para);
  _avisar(messenger, 'Movido para «${_nomeDa(setlists.state, para)}».');
}

String _nomeDa(BancoSetlists b, String id) => b.porId[id]?.nome ?? 'Minha setlist';

void _avisarAdicao(
  ScaffoldMessengerState? messenger,
  SetlistsCubit setlists,
  ResultadoAdicao r,
  String setlistId,
  ItemSetlist item, {
  VoidCallback? trocar,
}) {
  final nome = _nomeDa(setlists.state, setlistId);
  switch (r) {
    case ResultadoAdicao.adicionado:
      _avisar(messenger, 'Adicionado a «$nome».', acoes: [
        ('Desfazer', () => unawaited(setlists.remover(setlistId, item.id))),
        if (trocar != null) ('Trocar', trocar),
      ]);
    case ResultadoAdicao.jaEstava:
      _avisar(messenger, 'Já está em «$nome».');
    case ResultadoAdicao.cheia:
      _avisar(messenger, '«$nome» está cheia (${BancoSetlists.maxItens} itens).');
  }
}

/// Um aviso no rodapé, com até duas ações (o SnackBar só tem uma, então elas vão no conteúdo).
void _avisar(ScaffoldMessengerState? messenger, String texto, {List<(String, VoidCallback)> acoes = const []}) {
  if (messenger == null || !messenger.mounted) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: Mixart.surfaceHi,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: acoes.isEmpty ? 3 : 5),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusMd), side: BorderSide(color: Mixart.border)),
      content: Row(children: [
        Expanded(child: Text(texto, style: Mixart.ui(size: 13.5, weight: FontWeight.w600, color: Mixart.text))),
        for (final (rotulo, acao) in acoes)
          TextButton(
            key: Key('aviso-${rotulo.toLowerCase()}'),
            onPressed: () {
              messenger.hideCurrentSnackBar();
              acao();
            },
            child: Text(rotulo, style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: Mixart.brand)),
          ),
      ]),
    ));
}

/// Mostra "Removido." com Desfazer (a página da setlist usa).
void avisarRemovido(BuildContext c, VoidCallback desfazer) =>
    _avisar(ScaffoldMessenger.maybeOf(c), 'Removido.', acoes: [('Desfazer', desfazer)]);

// ---------------------------------------------------------------------------------------------------------
// Fila: resolve os itens contra as trilhas do curso (memoizado por lista de itens e por trilhas).

/// As trilhas carregadas no [CursoBloc] (vazio sem ele).
List<Trilha> trilhasDoCurso(BuildContext c) {
  try {
    return BlocProvider.of<CursoBloc>(c, listen: false).state.trilhas;
  } catch (_) {
    return const [];
  }
}

final _memoItens = Expando<(List<Trilha>, FilaOuvir)>('filaDosItens');
final _memoCurso = Expando<FilaOuvir>('filaDoCurso');

/// A fila de [itens] (vazia fora do inglês). A mesma lista com as mesmas trilhas não é resolvida de novo.
FilaOuvir filaDosItens(BuildContext c, List<ItemSetlist> itens) {
  final ouvir = OuvirCubit.de(c);
  if (ouvir == null) return const FilaOuvir();
  final trilhas = trilhasDoCurso(c);
  final m = _memoItens[itens];
  if (m != null && identical(m.$1, trilhas)) return m.$2;
  final f = _resolver(ouvir.saida, trilhas, itens);
  _memoItens[itens] = (trilhas, f);
  return f;
}

/// O curso inteiro, na ordem (sem as trilhas próprias).
FilaOuvir filaDoCurso(BuildContext c) {
  final ouvir = OuvirCubit.de(c);
  if (ouvir == null) return const FilaOuvir();
  final trilhas = trilhasDoCurso(c);
  return _memoCurso[trilhas] ??= _resolver(ouvir.saida, trilhas, [ItemSetlist.doCurso()]);
}

FilaOuvir _resolver(SaidaDeAudio saida, List<Trilha> trilhas, List<ItemSetlist> itens) =>
    resolverFila(IndiceOuvir.de(trilhas), itens, duracaoDe: saida.duracaoDe, temGravacao: saida.temGravacao);

/// O item "esta frase" de uma faixa: a frase do curso quando ainda existe, senão o retrato do texto.
ItemSetlist itemDaFaixa(BuildContext c, Faixa f) {
  final trilhas = trilhasDoCurso(c);
  final pos = IndiceOuvir.de(trilhas).frase(f.chave);
  if (pos != null) {
    final l = trilhas[pos.t].licoes[pos.l];
    return ItemSetlist.daFrase(l.trechos[pos.f], licao: l);
  }
  return ItemSetlist.daTexto(en: f.en, pt: f.pt);
}

/// "5.308".
String milhar(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

String plural(int n, String um, String varios) => '${milhar(n)} ${n == 1 ? um : varios}';

// ---------------------------------------------------------------------------------------------------------

/// ➕ "Pôr na setlist": toque = põe na última usada; toque longo = escolhe a setlist.
class BotaoPorNaSetlist extends StatelessWidget {
  const BotaoPorNaSetlist({super.key, required this.item, this.redondo = true});

  final ItemSetlist Function() item;
  final bool redondo;

  @override
  Widget build(BuildContext context) {
    if (_semOuvir(context)) return const SizedBox.shrink();
    void tocar() => unawaited(porNaSetlist(context, item()));
    void segurar() => unawaited(escolherSetlist(context, item()));
    const dica = 'Pôr na setlist (segure para escolher qual)';
    // o toque longo é a ação "escolher": o Tooltip não pode roubá-lo (só aparece no hover)
    if (redondo) {
      return Tooltip(
        message: dica,
        triggerMode: TooltipTriggerMode.manual,
        child: Semantics(
          button: true,
          label: 'Pôr na setlist',
          onLongPressHint: 'escolher a setlist',
          child: Material(
            color: Mixart.surfaceHi,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(color: Mixart.border),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: tocar,
              onLongPress: segurar,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.playlist_add_rounded, size: 18, color: Mixart.brand),
              ),
            ),
          ),
        ),
      );
    }
    return Tooltip(
      message: dica,
      triggerMode: TooltipTriggerMode.manual,
      child: Semantics(
        button: true,
        label: 'Pôr na setlist',
        onLongPressHint: 'escolher a setlist',
        child: InkResponse(
          onTap: tocar,
          onLongPress: segurar,
          radius: 24,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.playlist_add_rounded, size: 22, color: Mixart.brand),
          ),
        ),
      ),
    );
  }
}

/// O Navigator do app (o mini-player fica acima dele e empurra o "Tocando agora" por esta chave). Um por
/// curso (`uid:linguagem`): trocar de conta/linguagem cria outra chave, sem reaproveitar a pilha antiga.
class NavegadorOuvir {
  final chave = GlobalKey<NavigatorState>();

  /// Vigia o topo da pilha (o `MaterialApp.navigatorObservers` do inglês usa [observadores]).
  final observador = ObservadorOuvir();
  late final List<NavigatorObserver> observadores = [observador];

  static NavegadorOuvir? de(BuildContext c) {
    try {
      return RepositoryProvider.of<NavegadorOuvir>(c, listen: false);
    } catch (_) {
      return null;
    }
  }
}

/// O nome da rota do Arcade: com ela na pilha o mini-player some (os jogos usam a janela inteira) e o
/// player pausa. Quem abre o Arcade passa `RouteSettings(name: rotaArcade)`.
const rotaArcade = 'arcade';

/// O que está no topo do Navigator, para o [OuvirShell]: [modal] = folha/diálogo/menu aberto (a barra fica
/// escurecida e não responde — ela mora fora da barreira do modal); [semBarra] = o Arcade está na pilha.
typedef TopoOuvir = ({bool modal, bool semBarra});

/// Acompanha a pilha do Navigator do app e publica o [TopoOuvir]. Mudanças no meio do build (a rota
/// inicial, por exemplo) só são publicadas depois do frame.
class ObservadorOuvir extends NavigatorObserver {
  final topo = ValueNotifier<TopoOuvir>((modal: false, semBarra: false));
  final _pilha = <Route<dynamic>>[];
  bool _agendado = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pilha.add(route);
    _mudou();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pilha.remove(route);
    _mudou();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pilha.remove(route);
    _mudou();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _pilha.indexOf(oldRoute);
    if (newRoute == null) {
      if (i >= 0) _pilha.removeAt(i);
    } else if (i >= 0) {
      _pilha[i] = newRoute;
    } else {
      _pilha.add(newRoute);
    }
    _mudou();
  }

  void _mudou() {
    final fase = SchedulerBinding.instance.schedulerPhase;
    if (fase != SchedulerPhase.persistentCallbacks) return _publicar();
    if (_agendado) return;
    _agendado = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _agendado = false;
      _publicar();
    });
  }

  void _publicar() {
    topo.value = (
      modal: _pilha.isNotEmpty && _pilha.last is PopupRoute,
      semBarra: _pilha.any((r) => r.settings.name == rotaArcade),
    );
  }
}

/// A moldura do app com o mini-player embaixo (no `MaterialApp.builder`, acima do Navigator). O conteúdo
/// encolhe para a barra caber (não fica coberto). Aqui não há Overlay: nada de Tooltip na barra. Some no
/// Arcade; com folha/diálogo aberto fica escurecida e sem toque, como o resto atrás do modal.
class OuvirShell extends StatefulWidget {
  const OuvirShell({super.key, required this.child});

  final Widget child;

  /// A partir desta largura a barra vira um cartão centralizado de até [larguraMaxCartao] px.
  static const larguraCartao = 900.0;
  static const larguraMaxCartao = 860.0;

  /// Sem [OuvirCubit] (curso de Dart), devolve [child] como veio.
  static Widget envolver(BuildContext c, Widget child) => OuvirCubit.de(c) == null ? child : OuvirShell(child: child);

  /// A barra cresce para caber a imagem e a tradução; com as duas desligadas fica mais baixa.
  static bool barraRica(ConfigOuvir c) =>
      c.mostrarImagens || c.mostrarTraducao || c.modo == ModoOuvir.portuguesIngles;

  /// A linha de cima da barra (imagem + frase + tradução).
  static double alturaConteudo(ConfigOuvir c, {required bool cartao}) =>
      barraRica(c) ? (cartao ? 116 : 88) : (cartao ? 76 : 60);

  /// Altura da barra (sem a área segura de baixo): progresso + linha de cima + linha dos botões.
  static double alturaBarra(ConfigOuvir c, {required bool cartao}) =>
      3 + alturaConteudo(c, cartao: cartao) + (cartao ? 52 : 48);

  /// Quanto a barra ocupa embaixo, com a área segura e a margem do cartão no computador.
  static double alturaTotal(MediaQueryData mq, ConfigOuvir c) {
    final cartao = mq.size.width >= larguraCartao;
    return alturaBarra(c, cartao: cartao) + (cartao ? 12 : 0) + mq.padding.bottom;
  }

  @override
  State<OuvirShell> createState() => _OuvirShellState();
}

class _OuvirShellState extends State<OuvirShell> {
  ValueNotifier<TopoOuvir>? _topo;
  bool _semBarra = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final t = NavegadorOuvir.de(context)?.observador.topo;
    if (identical(t, _topo)) return;
    _topo?.removeListener(_mudouTopo);
    _topo = t?..addListener(_mudouTopo);
    _semBarra = t?.value.semBarra ?? false;
  }

  @override
  void dispose() {
    _topo?.removeListener(_mudouTopo);
    super.dispose();
  }

  void _mudouTopo() {
    if (!mounted) return;
    final semBarra = _topo?.value.semBarra ?? false;
    // entrou no Arcade: os jogos falam e a barra some — o player pausa (sem ficar tocando escondido)
    if (semBarra && !_semBarra) OuvirCubit.de(context)?.pausar();
    _semBarra = semBarra;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final cubit = OuvirCubit.de(context);
    if (cubit == null) return child;
    final topo = _topo?.value ?? (modal: false, semBarra: false);
    return BlocBuilder<OuvirCubit, OuvirState>(
      bloc: cubit,
      buildWhen: (a, b) =>
          a.status != b.status ||
          a.telaCheia != b.telaCheia ||
          OuvirShell.barraRica(a.config) != OuvirShell.barraRica(b.config),
      builder: (context, st) {
        final mq = MediaQuery.of(context);
        // some com o player parado, com o "Tocando agora" aberto, com o teclado aberto (o palco) e no Arcade
        final mostrar =
            st.status != StatusOuvir.parado && !st.telaCheia && mq.viewInsets.bottom <= 0 && !topo.semBarra;
        final altura = mostrar ? OuvirShell.alturaTotal(mq, st.config) : 0.0;
        // a estrutura não muda ao mostrar/esconder: o Navigator (child) nunca é remontado
        return Material(
          color: Mixart.bg,
          child: Column(children: [
            Expanded(
              child: MediaQuery(
                data: mostrar
                    ? mq.copyWith(
                        size: Size(mq.size.width, math.max(0, mq.size.height - altura)),
                        padding: mq.padding.copyWith(bottom: 0),
                        viewPadding: mq.viewPadding.copyWith(bottom: 0),
                      )
                    : mq,
                child: child,
              ),
            ),
            if (mostrar)
              // a barreira do modal não chega aqui: a barra escurece e ignora toque/leitor de tela com ele aberto
              IgnorePointer(
                ignoring: topo.modal,
                child: ExcludeSemantics(
                  excluding: topo.modal,
                  child: Stack(children: [
                    MiniPlayer(cubit: cubit, altura: altura),
                    if (topo.modal)
                      const Positioned.fill(child: ColoredBox(key: Key('mini-player-escurecido'), color: Colors.black54)),
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }
}

/// A saída de áudio do app (o `main` usa quando o teste não injeta outra).
SaidaDeAudio saidaPadrao() => SaidaVozIngles();
