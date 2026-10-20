import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../../core/ui/festa.dart';
import '../../arcade/presentation/arcade_page.dart';
import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../data/tradutor.dart';
import '../data/voz_ingles.dart';
import '../domain/banco_palavras.dart';
import '../domain/cartoes_texto.dart';
import '../domain/palavras_novas.dart';
import '../domain/teimosas.dart';
import 'acoes_teimosas.dart';
import 'palavras_cubit.dart';
import 'treino_palavras.dart';
import 'widgets/adicionar_palavra_sheet.dart';

/// Abre "📚 Minhas palavras" (o banco de palavras do aluno). Fora do inglês (sem o [PalavrasCubit]) não
/// faz nada.
Future<void> abrirMinhasPalavras(BuildContext context) async {
  if (PalavrasCubit.de(context) == null) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MinhasPalavrasPage()));
}

/// Os filtros da lista.
enum FiltroPalavras {
  todas('Todas'),
  revisar('Para revisar'),
  licoes('Das lições'),
  minhas('Minhas'),
  leitura('Da leitura'),
  foraDosJogos('Fora dos jogos'),

  /// As "🔥 teimosas" (o chip só aparece quando há alguma, ou com o filtro ligado).
  teimosas('Teimosas');

  final String rotulo;
  const FiltroPalavras(this.rotulo);
}

/// Uma linha da lista: a palavra, se já mora no banco (as das lições e da leitura só entram quando a
/// pessoa mexe nelas ou treina) e o nome da lição de onde veio.
class LinhaDePalavra {
  final PalavraDoBanco p;
  final bool noBanco;
  final String? licao;
  const LinhaDePalavra(this.p, {required this.noBanco, this.licao});

  /// Só letras A–Z (3 a 14) entram nos jogos.
  bool get podeJogar => p.comoPalavraNova.deJogo;
  bool get nosJogos => podeJogar && p.noJogo;
}

/// "📚 Minhas palavras": tudo o que o aluno já viu (as das lições concluídas, as que ele escreveu, as
/// guardadas na leitura), com a força de cada uma, o 🔊, o "nos jogos" e as ações de revisar, jogar e
/// adicionar.
class MinhasPalavrasPage extends StatefulWidget {
  /// Injetáveis (testes): a voz, o tradutor da folha de adicionar e o que "Jogar com elas" abre.
  final VozIngles? voz;
  final Tradutor? tradutor;
  final VoidCallback? aoJogar;

  const MinhasPalavrasPage({super.key, this.voz, this.tradutor, this.aoJogar});

  @override
  State<MinhasPalavrasPage> createState() => _MinhasPalavrasPageState();
}

class _MinhasPalavrasPageState extends State<MinhasPalavrasPage> {
  late final VozIngles _voz = widget.voz ?? VozIngles();
  final _busca = TextEditingController();
  FiltroPalavras _filtro = FiltroPalavras.todas;
  int _festa = 0;

  // memória das contas (refeitas só quando o curso/banco/índice mudam)
  List<Trilha>? _trilhasNomes;
  Map<String, String> _nomes = const {};
  Object? _chaveLinhas;
  List<LinhaDePalavra> _linhas = const [];

  @override
  void initState() {
    super.initState();
    final cubit = PalavrasCubit.de(context);
    if (cubit != null) {
      unawaited(cubit.carregar());
      unawaited(cubit.prepararIndice(context.read<CursoBloc>().state.trilhas));
    }
  }

  @override
  void dispose() {
    _busca.dispose();
    unawaited(_voz.parar());
    super.dispose();
  }

  Map<String, String> _nomesDasLicoes(List<Trilha> trilhas) {
    if (!identical(trilhas, _trilhasNomes)) {
      _trilhasNomes = trilhas;
      _nomes = {
        for (final t in trilhas)
          for (final l in t.licoes)
            if (l.id.isNotEmpty) l.id: t.textoId == idCartoesAvulsos ? tituloCartoesAvulsos : l.nome,
      };
    }
    return _nomes;
  }

  /// Banco + lições concluídas (do cubit) + as palavras soltas guardadas em "Meus cartões".
  List<LinhaDePalavra> _montar(CursoState st, PalavrasState ps, PalavrasCubit cubit) {
    final chave = (st.trilhas, st.concluidas, ps.banco, ps.indice);
    final anterior = _chaveLinhas;
    if (anterior is (List<Trilha>, Set<String>, BancoPalavras, IndicePalavras?) &&
        identical(anterior.$1, chave.$1) &&
        identical(anterior.$2, chave.$2) &&
        identical(anterior.$3, chave.$3) &&
        identical(anterior.$4, chave.$4)) {
      return _linhas;
    }
    final nomes = _nomesDasLicoes(st.trilhas);
    final banco = ps.banco;
    final r = <LinhaDePalavra>[];
    final vistas = <String>{...banco.palavras.keys};
    for (final p in cubit.palavrasDoAluno(st)) {
      vistas.add(p.chave);
      r.add(LinhaDePalavra(p, noBanco: banco[p.en] != null, licao: p.licaoId == null ? null : nomes[p.licaoId]));
    }
    for (final t in st.trilhas) {
      if (t.textoId != idCartoesAvulsos) continue;
      for (final l in t.licoes) {
        for (final tr in l.trechos) {
          final alvo = tr.alvo.trim().replaceAll(RegExp(r"^[^A-Za-z]+|[^A-Za-z]+$"), '');
          if (!RegExp(r"^[A-Za-z][A-Za-z'\-]{1,23}$").hasMatch(alvo)) continue;
          if (!vistas.add(alvo.toLowerCase())) continue;
          r.add(LinhaDePalavra(
            PalavraDoBanco(
              en: alvo,
              pt: tr.alvoPt.isNotEmpty ? tr.alvoPt : traducaoCurta(ps.indice?.dic.literal(alvo), max: 30),
              origem: OrigemPalavra.leitura,
              licaoId: l.id,
              exemplo: tr.cod,
            ),
            noBanco: false,
            licao: tituloCartoesAvulsos,
          ));
        }
      }
    }
    _chaveLinhas = chave;
    return _linhas = r;
  }

  static String _semAcento(String s) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = de.indexOf(ch);
      b.write(i >= 0 ? para[i] : ch);
    }
    return b.toString();
  }

  List<LinhaDePalavra> _filtradas(List<LinhaDePalavra> todas, Set<String> devidas, [Set<String> teimosas = const {}]) {
    final q = _semAcento(_busca.text.trim());
    return [
      for (final l in todas)
        if (switch (_filtro) {
              FiltroPalavras.todas => true,
              FiltroPalavras.revisar => devidas.contains(l.p.chave),
              FiltroPalavras.licoes => l.p.origem == OrigemPalavra.licao,
              FiltroPalavras.minhas => l.p.origem == OrigemPalavra.minha,
              FiltroPalavras.leitura => l.p.origem == OrigemPalavra.leitura,
              FiltroPalavras.foraDosJogos => !l.nosJogos,
              FiltroPalavras.teimosas => teimosas.contains(l.p.chave),
            } &&
            (q.isEmpty || l.p.chave.contains(q) || _semAcento(l.p.pt).contains(q)))
          l,
    ];
  }

  // ---------- ações ----------

  Future<void> _revisar(PalavrasCubit cubit, List<LinhaDePalavra> todas) async {
    final devidas = cubit.devidasHoje;
    final List<PalavraNova> sessao;
    final String titulo;
    if (devidas.isNotEmpty) {
      sessao = [for (final p in devidas.take(8)) p.comoPalavraNova];
      titulo = 'Revisão das palavras';
    } else {
      // nada vencendo: as fracas primeiro, depois as que nunca foram treinadas (das mais recentes)
      final hoje = cubit.state.hoje;
      final escolha = <String, PalavraNova>{};
      for (final p in cubit.state.banco.fracas(hoje)) {
        if (escolha.length >= 8) break;
        if (p.pt.isNotEmpty) escolha[p.chave] = p.comoPalavraNova;
      }
      for (final l in todas) {
        if (escolha.length >= 8) break;
        if (l.p.cartao == null && l.p.pt.isNotEmpty) escolha.putIfAbsent(l.p.chave, () => l.p.comoPalavraNova);
      }
      sessao = escolha.values.toList();
      titulo = 'Treino de palavras';
    }
    if (sessao.isEmpty) return;
    await abrirTreinoPalavras(context, sessao, titulo: titulo);
  }

  void _jogar(PalavrasCubit cubit, List<LinhaDePalavra> visiveis, Set<String> devidas) {
    final foco = <String>[
      for (final l in visiveis)
        if (l.nosJogos && devidas.contains(l.p.chave)) l.p.en,
      for (final l in visiveis)
        if (l.nosJogos && !devidas.contains(l.p.chave)) l.p.en,
    ].take(BancoPalavras.maxEmTreino).toList();
    cubit.focar(foco);
    final abrir = widget.aoJogar;
    if (abrir != null) {
      abrir();
      return;
    }
    unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ArcadePage())));
  }

  Future<void> _adicionar() async {
    final entraram = await mostrarAdicionarPalavra(context, tradutor: widget.tradutor);
    if (!mounted || entraram.isEmpty) return;
    setState(() => _festa++);
  }

  /// A palavra da leitura que ainda não mora no banco entra (como da leitura) para poder mudar.
  bool _garantirNoBanco(PalavrasCubit cubit, LinhaDePalavra l, {String? pt}) {
    if (l.noBanco || l.p.origem != OrigemPalavra.leitura) return true;
    return cubit.adicionar(l.p.en, pt ?? l.p.pt, exemplo: l.p.exemplo, origem: OrigemPalavra.leitura) == null;
  }

  void _alternarJogo(PalavrasCubit cubit, LinhaDePalavra l) {
    final novo = !l.p.noJogo;
    if (!_garantirNoBanco(cubit, l)) return;
    cubit.alternarJogo(l.p.en, novo);
  }

  Future<void> _editar(PalavrasCubit cubit, LinhaDePalavra l) async {
    final novo = await showDialog<String>(context: context, builder: (_) => _EditarTraducao(palavra: l.p));
    if (novo == null || novo.trim().isEmpty || !mounted) return;
    if (!l.noBanco && l.p.origem == OrigemPalavra.leitura) {
      _garantirNoBanco(cubit, l, pt: novo);
    } else {
      cubit.editar(l.p.en, pt: novo);
    }
  }

  void _remover(PalavrasCubit cubit, LinhaDePalavra l) {
    cubit.remover(l.p.en);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: Mixart.surfaceHi,
        content: Text('"${l.p.en}" saiu das suas palavras', style: Mixart.ui(size: 13, color: Mixart.text)),
      ));
  }

  // ---------- tela ----------

  @override
  Widget build(BuildContext context) {
    final cubit = PalavrasCubit.de(context);
    final curso = context.watch<CursoBloc>().state;
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Stack(children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: cubit == null
                  ? _semCurso()
                  : BlocBuilder<PalavrasCubit, PalavrasState>(
                      bloc: cubit,
                      builder: (context, ps) => _corpo(context, cubit, curso, ps),
                    ),
            ),
          ),
          if (_festa > 0)
            Positioned.fill(
              child: Confete(key: ValueKey('festa-palavra-$_festa'), quantidade: 28, origem: const Alignment(0, -.5)),
            ),
        ]),
      ),
    );
  }

  Widget _semCurso() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [_topo(), const SizedBox(height: 20), Text('Disponível no curso de inglês.', style: Mixart.ui(color: Mixart.textMuted))]),
      );

  Widget _topo() => Row(children: [
        IconButton(
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
          style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
        ),
        const SizedBox(width: 12),
        const Text('📚', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(child: Text('Minhas palavras', style: Mixart.display(size: 22), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]);

  Widget _corpo(BuildContext context, PalavrasCubit cubit, CursoState curso, PalavrasState ps) {
    final todas = _montar(curso, ps, cubit);
    final devidasLista = cubit.devidasHoje;
    final devidas = {for (final p in devidasLista) p.chave};
    final hoje = cubit.state.hoje;
    final teimosasLista = cubit.teimosas(max: 1 << 30);
    final teimosas = {for (final p in teimosasLista) p.chave};
    final dominadas = cubit.dominadas;
    final visiveis = _filtradas(todas, devidas, teimosas);
    final nosJogos = todas.where((l) => l.nosJogos).length;
    final m = devidasLista.length;
    final carregando = ps.indice == null && todas.isEmpty;
    final larg = MediaQuery.sizeOf(context).width;
    final lado = larg < 480 ? 14.0 : 20.0;

    return CustomScrollView(slivers: [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(lado, 12, lado, 0),
        sliver: SliverToBoxAdapter(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _topo(),
            const SizedBox(height: 8),
            Text(
              '${todas.length} ${todas.length == 1 ? 'palavra' : 'palavras'} · $m para revisar hoje · $nosJogos nos jogos',
              key: const Key('palavras-contagem'),
              style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.textMuted),
            ),
            const SizedBox(height: 14),
            _acoes(cubit, todas, visiveis, devidas, m),
            if (teimosasLista.isNotEmpty || dominadas.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SecaoTeimosas(
                teimosas: teimosasLista,
                dominadas: dominadas,
                onTreinar: () => treinarTeimosas(context, [for (final p in teimosasLista.take(8)) p.chave], origem: 'minhasPalavras'),
              ),
            ],
            const SizedBox(height: 16),
            _campoBusca(),
            const SizedBox(height: 10),
            _chips(todas, devidas, teimosas),
            const SizedBox(height: 12),
          ]),
        ),
      ),
      if (carregando)
        SliverToBoxAdapter(child: _aviso('Carregando as palavras das suas lições…', chave: const Key('palavras-carregando')))
      else if (todas.isEmpty)
        SliverToBoxAdapter(
          child: _aviso('Ainda não há palavras aqui. Conclua uma lição ou toque em "➕ Adicionar" para pôr as suas.',
              chave: const Key('palavras-vazio')),
        )
      else if (visiveis.isEmpty && _filtro == FiltroPalavras.teimosas)
        SliverToBoxAdapter(
          child: _aviso('Nenhuma teimosa por aqui 🎉 — erre à vontade, eu anoto.', chave: const Key('teimosas-vazio')),
        )
      else if (visiveis.isEmpty)
        SliverToBoxAdapter(child: _aviso('Nenhuma palavra neste filtro.', chave: const Key('palavras-filtro-vazio')))
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(lado, 0, lado, 48),
          sliver: SliverList.builder(
            itemCount: visiveis.length,
            itemBuilder: (context, i) {
              final l = visiveis[i];
              return _LinhaPalavraView(
                key: ValueKey('palavra-${l.p.chave}'),
                linha: l,
                forca: l.noBanco ? cubit.forcaDe(l.p.en) : ForcaPalavra.nova,
                devida: devidas.contains(l.p.chave),
                compacta: larg < 480,
                onOuvir: () => unawaited(_voz.falar(l.p.en)),
                onJogo: () => _alternarJogo(cubit, l),
                onEditar: () => _editar(cubit, l),
                onRemover: l.p.origem == OrigemPalavra.minha && l.noBanco ? () => _remover(cubit, l) : null,
                onTreinar: l.p.pt.isEmpty ? null : () => abrirTreinoPalavras(context, [l.p.comoPalavraNova], titulo: l.p.en),
                chamas: teimosas.contains(l.p.chave) ? chamasDe(l.p, hoje) : 0,
                erros: _badgeErros(l.p, hoje),
                onJaSei: teimosas.contains(l.p.chave) ? () => _jaSei(cubit, l) : null,
              );
            },
          ),
        ),
    ]);
  }

  /// "errou 5x · há 2 dias" (só para quem já errou de vez numa lição, revisão, cartão ou treino).
  static String? _badgeErros(PalavraDoBanco p, int hoje) {
    if (p.errosTotal <= 0 || p.ultimoErroDia <= 0) return null;
    final d = hoje - p.ultimoErroDia;
    final quando = d <= 0 ? 'hoje' : (d == 1 ? 'ontem' : 'há $d dias');
    return 'errou ${p.errosTotal}x · $quando';
  }

  void _jaSei(PalavrasCubit cubit, LinhaDePalavra l) {
    cubit.jaSei(l.p.en);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: Mixart.surfaceHi,
        content: Text('Combinado! "${l.p.en}" sai das teimosas por 2 semanas', style: Mixart.ui(size: 13, color: Mixart.text)),
      ));
  }

  Widget _aviso(String texto, {Key? chave}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          key: chave,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
          ),
          child: Text(texto, style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.45)),
        ),
      );

  Widget _acoes(PalavrasCubit cubit, List<LinhaDePalavra> todas, List<LinhaDePalavra> visiveis, Set<String> devidas, int m) {
    final temTreino = m > 0 ||
        todas.any((l) => l.p.pt.isNotEmpty && l.p.cartao == null) ||
        cubit.state.banco.fracas(cubit.state.hoje).any((p) => p.pt.isNotEmpty);
    final revisar = Botao3D(
      key: const Key('revisar-palavras'),
      rotulo: m > 0 ? '🎯 Revisar agora ($m)' : '🎯 Treinar palavras',
      cor: m > 0 ? CoresFesta.ambar : null,
      corTexto: m > 0 ? corSobre(CoresFesta.ambar) : null,
      altura: 46,
      tamanhoTexto: 14,
      onTap: temTreino ? () => _revisar(cubit, todas) : null,
    );
    final jogar = Botao3D(
      key: const Key('jogar-com-palavras'),
      rotulo: '🎮 Jogar com elas',
      contorno: true,
      altura: 46,
      tamanhoTexto: 13.5,
      onTap: visiveis.any((l) => l.nosJogos) ? () => _jogar(cubit, visiveis, devidas) : null,
    );
    final adicionar = Botao3D(
      key: const Key('adicionar-palavra'),
      rotulo: '➕ Adicionar',
      contorno: true,
      altura: 46,
      tamanhoTexto: 13.5,
      onTap: _adicionar,
    );
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 620) {
        return Row(children: [
          Expanded(flex: 5, child: revisar),
          const SizedBox(width: 10),
          Expanded(flex: 4, child: jogar),
          const SizedBox(width: 10),
          Expanded(flex: 4, child: adicionar),
        ]);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        revisar,
        const SizedBox(height: 10),
        Row(children: [Expanded(child: jogar), const SizedBox(width: 10), Expanded(child: adicionar)]),
      ]);
    });
  }

  Widget _campoBusca() => TextField(
        key: const Key('busca-palavras'),
        controller: _busca,
        onChanged: (_) => setState(() {}),
        style: Mixart.ui(size: 14, color: Mixart.text),
        decoration: InputDecoration(
          hintText: 'Buscar em inglês ou português',
          hintStyle: Mixart.ui(size: 13.5, color: Mixart.textFaint),
          prefixIcon: Icon(Icons.search_rounded, color: Mixart.textMuted, size: 20),
          suffixIcon: _busca.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',
                  icon: Icon(Icons.close_rounded, color: Mixart.textMuted, size: 18),
                  onPressed: () => setState(_busca.clear),
                ),
          isDense: true,
          filled: true,
          fillColor: Mixart.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.brand, width: 1.4)),
        ),
      );

  Widget _chips(List<LinhaDePalavra> todas, Set<String> devidas, [Set<String> teimosas = const {}]) {
    int conta(FiltroPalavras f) => switch (f) {
          FiltroPalavras.todas => todas.length,
          FiltroPalavras.revisar => todas.where((l) => devidas.contains(l.p.chave)).length,
          FiltroPalavras.licoes => todas.where((l) => l.p.origem == OrigemPalavra.licao).length,
          FiltroPalavras.minhas => todas.where((l) => l.p.origem == OrigemPalavra.minha).length,
          FiltroPalavras.leitura => todas.where((l) => l.p.origem == OrigemPalavra.leitura).length,
          FiltroPalavras.foraDosJogos => todas.where((l) => !l.nosJogos).length,
          FiltroPalavras.teimosas => todas.where((l) => teimosas.contains(l.p.chave)).length,
        };
    final chips = [
      for (final f in FiltroPalavras.values)
        if (f != FiltroPalavras.teimosas || teimosas.isNotEmpty || _filtro == f)
        ChoiceChip(
            key: Key('filtro-${f.name}'),
            label: Text(f == FiltroPalavras.teimosas ? '${f.rotulo} (${conta(f)})' : '${f.rotulo} · ${conta(f)}'),
            selected: _filtro == f,
            onSelected: (_) => setState(() => _filtro = f),
            showCheckmark: false,
            labelStyle: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: _filtro == f ? Mixart.onBrand : Mixart.textMuted),
            backgroundColor: Mixart.surface,
            selectedColor: Mixart.brand,
            side: BorderSide(color: _filtro == f ? Mixart.brand : Mixart.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
            visualDensity: VisualDensity.compact,
          ),
    ];
    // largo: os chips quebram linha; estreito: uma fileira que rola de lado
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth >= 600
          ? Wrap(spacing: 8, runSpacing: 8, children: chips)
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final ch in chips) ...[ch, const SizedBox(width: 8)],
              ]),
            ),
    );
  }
}

/// Uma palavra da lista.
class _LinhaPalavraView extends StatelessWidget {
  final LinhaDePalavra linha;
  final ForcaPalavra forca;
  final bool devida;
  final bool compacta;
  final VoidCallback onOuvir;
  final VoidCallback onJogo;
  final VoidCallback onEditar;
  final VoidCallback? onRemover;
  final VoidCallback? onTreinar;

  /// Teimosas: o medidor 🔥 (0 = não é teimosa), o "errou Nx · há D dias" e o "Já sei essa".
  final int chamas;
  final String? erros;
  final VoidCallback? onJaSei;

  const _LinhaPalavraView({
    super.key,
    required this.linha,
    required this.forca,
    required this.devida,
    required this.compacta,
    required this.onOuvir,
    required this.onJogo,
    required this.onEditar,
    this.onRemover,
    this.onTreinar,
    this.chamas = 0,
    this.erros,
    this.onJaSei,
  });

  @override
  Widget build(BuildContext context) {
    final p = linha.p;
    final coral = escurecer(CoresFesta.coral, quanto: .25, soNoClaro: true);
    final chave = p.chave;
    final origem = switch (p.origem) {
      OrigemPalavra.licao => linha.licao == null ? 'Lição' : 'Lição: ${linha.licao}',
      OrigemPalavra.minha => 'Minha',
      OrigemPalavra.leitura => 'Leitura',
    };
    final corOrigem = switch (p.origem) {
      OrigemPalavra.licao => CoresFesta.azul,
      OrigemPalavra.minha => CoresFesta.violeta,
      OrigemPalavra.leitura => CoresFesta.verde,
    };
    final jogo = linha.podeJogar
        ? Tooltip(
            message: linha.nosJogos ? 'Nos jogos — toque para tirar' : 'Fora dos jogos — toque para pôr',
            child: InkResponse(
              key: Key('jogo-$chave'),
              onTap: onJogo,
              radius: 22,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Opacity(
                    opacity: linha.nosJogos ? 1 : .3,
                    child: const Text('🎮', style: TextStyle(fontSize: 19)),
                  ),
                ),
              ),
            ),
          )
        : Tooltip(
            message: 'Só letras A–Z entram nos jogos',
            child: SizedBox(
              key: Key('jogo-$chave'),
              width: 40,
              height: 40,
              child: const Center(child: Opacity(opacity: .18, child: Text('🎮', style: TextStyle(fontSize: 19)))),
            ),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.fromLTRB(compacta ? 12 : 16, 10, 4, 10),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: devida ? CoresFesta.ambar.withValues(alpha: .55) : Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(p.en,
                    key: Key('palavra-en-$chave'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Mixart.mono(size: compacta ? 16 : 17, weight: FontWeight.w700, color: Mixart.text)),
              ),
              const SizedBox(width: 2),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  tooltip: 'Ouvir',
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onPressed: onOuvir,
                  icon: Icon(Icons.volume_up_rounded, color: Mixart.brand),
                ),
              ),
            ]),
            Text(p.pt.isEmpty ? '—' : p.pt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.3)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compacta ? 150 : 260),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: corOrigem.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(Mixart.radiusChip),
                  ),
                  child: Text(origem,
                      key: Key('origem-$chave'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mixart.ui(size: 11, weight: FontWeight.w700, color: escurecer(corOrigem, quanto: .35, soNoClaro: true))),
                ),
              ),
              _MedidorForca(forca: forca),
              if (chamas > 0)
                Tooltip(
                  message: 'Teimosa: você erra bastante esta',
                  child: Text('🔥' * chamas, key: Key('chamas-$chave'), style: const TextStyle(fontSize: 12)),
                ),
              if (erros != null)
                Text(erros!,
                    key: Key('erros-$chave'),
                    style: Mixart.ui(size: 11, weight: FontWeight.w700, color: chamas > 0 ? coral : Mixart.textFaint)),
              if (devida)
                Text('⏰ hoje', style: Mixart.ui(size: 11, weight: FontWeight.w800, color: escurecer(CoresFesta.ambar, soNoClaro: true))),
            ]),
          ]),
        ),
        jogo,
        PopupMenuButton<String>(
          key: Key('menu-$chave'),
          tooltip: 'Opções da palavra',
          icon: Icon(Icons.more_vert_rounded, color: Mixart.textMuted, size: 20),
          color: Mixart.surfaceHi,
          onSelected: (v) {
            switch (v) {
              case 'editar':
                onEditar();
              case 'treinar':
                onTreinar?.call();
              case 'remover':
                onRemover?.call();
              case 'jaSei':
                onJaSei?.call();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              key: const Key('editar-palavra'),
              value: 'editar',
              child: Text('✏️ Editar tradução', style: Mixart.ui(size: 13.5, color: Mixart.text)),
            ),
            if (onTreinar != null)
              PopupMenuItem(
                key: const Key('treinar-palavra'),
                value: 'treinar',
                child: Text('🎯 Treinar esta palavra', style: Mixart.ui(size: 13.5, color: Mixart.text)),
              ),
            if (onJaSei != null)
              PopupMenuItem(
                key: const Key('ja-sei-palavra'),
                value: 'jaSei',
                child: Text('✅ Já sei essa', style: Mixart.ui(size: 13.5, color: Mixart.text)),
              ),
            if (onRemover != null)
              PopupMenuItem(
                key: const Key('remover-palavra'),
                value: 'remover',
                child: Tooltip(
                  message: 'Remover palavra',
                  child: Text('🗑️ Remover palavra', style: Mixart.ui(size: 13.5, color: Mixart.danger)),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}

/// "🔥 As que você mais erra": as teimosas (as 6 primeiras em chips, com o "Nx"), o "🎯 Treinar as
/// teimosas (N)" e a prateleira "🏆 Dominadas: N".
class _SecaoTeimosas extends StatelessWidget {
  final List<PalavraDoBanco> teimosas;
  final List<PalavraDoBanco> dominadas;
  final VoidCallback onTreinar;
  const _SecaoTeimosas({required this.teimosas, required this.dominadas, required this.onTreinar});

  @override
  Widget build(BuildContext context) {
    final coral = escurecer(CoresFesta.coral, quanto: .2, soNoClaro: true);
    final ouro = escurecer(CoresFesta.ouro, quanto: .3, soNoClaro: true);
    final n = teimosas.length;
    return Container(
      key: const Key('secao-teimosas'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(coral.withValues(alpha: .06), Mixart.surface),
        border: Border.all(color: coral.withValues(alpha: .45)),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (n > 0) ...[
          Text('🔥 As que você mais erra', style: Mixart.display(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final p in teimosas.take(6))
              Container(
                padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
                decoration: BoxDecoration(
                  color: Mixart.surface,
                  border: Border.all(color: Mixart.border),
                  borderRadius: BorderRadius.circular(Mixart.radiusChip),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(p.en, style: Mixart.mono(size: 13.5, weight: FontWeight.w800, color: Mixart.text)),
                  // o "Nx" só de 2 vezes para cima ("1x" não combina com "as que você mais erra")
                  if (vezesDe(p) >= 2) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: coral.withValues(alpha: .16), borderRadius: BorderRadius.circular(999)),
                      child: Text('${vezesDe(p)}x', style: Mixart.ui(size: 11, weight: FontWeight.w900, color: coral)),
                    ),
                  ] else
                    const SizedBox(width: 4),
                ]),
              ),
            if (n > 6)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text('+${n - 6}', style: Mixart.ui(size: 12.5, weight: FontWeight.w800, color: Mixart.textMuted)),
              ),
          ]),
          const SizedBox(height: 10),
          Botao3D(
            key: const Key('treinar-teimosas-banco'),
            rotulo: '🎯 Treinar as teimosas (${n > 8 ? 8 : n})',
            cor: coral,
            corTexto: corSobre(coral),
            altura: 44,
            tamanhoTexto: 14,
            onTap: onTreinar,
          ),
        ],
        if (dominadas.isNotEmpty) ...[
          if (n > 0) const SizedBox(height: 12),
          Text.rich(
            key: const Key('prateleira-dominadas'),
            TextSpan(children: [
              TextSpan(
                  text: '🏆 Dominadas: ${dominadas.length}  ',
                  style: Mixart.ui(size: 13, weight: FontWeight.w800, color: ouro)),
              TextSpan(
                  text: dominadas.take(10).map((p) => p.en).join(' · ') + (dominadas.length > 10 ? ' …' : ''),
                  style: Mixart.mono(size: 12.5, weight: FontWeight.w700, color: Mixart.textMuted)),
            ]),
          ),
        ],
      ]),
    );
  }
}

/// Os 4 pontinhos da força (nova → firme).
class _MedidorForca extends StatelessWidget {
  final ForcaPalavra forca;
  const _MedidorForca({required this.forca});

  @override
  Widget build(BuildContext context) {
    final (cheios, cor, nome) = switch (forca) {
      ForcaPalavra.nova => (0, Mixart.textFaint, 'nova'),
      ForcaPalavra.fraca => (1, CoresFesta.coral, 'fraca'),
      ForcaPalavra.boa => (3, CoresFesta.ambar, 'boa'),
      ForcaPalavra.firme => (4, CoresFesta.verde, 'firme'),
    };
    final c = escurecer(cor, quanto: .15, soNoClaro: true);
    return Tooltip(
      message: 'Força: $nome',
      child: Semantics(
        label: 'Força: $nome',
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < cheios ? c : Colors.transparent,
                border: Border.all(color: i < cheios ? c : Mixart.textFaint, width: 1.2),
              ),
            ),
          const SizedBox(width: 3),
          Text(nome, style: Mixart.ui(size: 11, weight: FontWeight.w700, color: forca == ForcaPalavra.nova ? Mixart.textFaint : c)),
        ]),
      ),
    );
  }
}

/// O diálogo de trocar a tradução.
class _EditarTraducao extends StatefulWidget {
  final PalavraDoBanco palavra;
  const _EditarTraducao({required this.palavra});

  @override
  State<_EditarTraducao> createState() => _EditarTraducaoState();
}

class _EditarTraducaoState extends State<_EditarTraducao> {
  late final _pt = TextEditingController(text: widget.palavra.pt);

  @override
  void dispose() {
    _pt.dispose();
    super.dispose();
  }

  void _ok() {
    final t = _pt.text.trim();
    if (t.isEmpty) return;
    Navigator.of(context).pop(t);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: Mixart.surface,
        title: Text(widget.palavra.en, style: Mixart.mono(size: 18, weight: FontWeight.w700, color: Mixart.text)),
        content: TextField(
          key: const Key('editar-pt'),
          controller: _pt,
          autofocus: true,
          style: Mixart.ui(size: 15, color: Mixart.text),
          decoration: InputDecoration(labelText: 'Tradução', labelStyle: Mixart.ui(size: 13, color: Mixart.textMuted)),
          onSubmitted: (_) => _ok(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: Mixart.ui(size: 13.5, color: Mixart.textMuted)),
          ),
          TextButton(
            key: const Key('editar-salvar'),
            onPressed: _ok,
            child: Text('Salvar', style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: Mixart.brand)),
          ),
        ],
      );
}
