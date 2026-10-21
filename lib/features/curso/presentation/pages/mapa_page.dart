import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/util/abrir_url.dart';
import '../../../ingles/data/tradutor.dart';
import '../../../ingles/domain/fonte_frase.dart';
import '../../../ingles/domain/texto_salvo.dart';
import '../../../ingles/presentation/baralhos_page.dart';
import '../../../ingles/presentation/fixacao.dart';
import '../../../ingles/presentation/revisao_cubit.dart';
import '../../../ingles/presentation/texto_para_licao_page.dart';
import '../../../ingles/domain/palavras_novas.dart';
import '../../../ingles/presentation/minhas_palavras_page.dart';
import '../../../ingles/domain/setlist.dart';
import '../../../ingles/presentation/ouvir/ouvir_acoes.dart';
import '../../../ingles/presentation/ouvir/ouvir_cubit.dart';
import '../../../ingles/presentation/ouvir/ouvir_state.dart';
import '../../../ingles/presentation/palavras_cubit.dart';
import '../../../ingles/presentation/treino_palavras.dart';
import '../../../ingles/presentation/widgets/elenco_ingles.dart';
import '../../../ingles/domain/banco_palavras.dart';
import '../../../../core/ui/festa.dart';
import '../../domain/mapa_regras.dart';
import 'mapa/banner_unidade.dart';
import 'mapa/bau_trilha.dart';
import 'mapa/caminho_ingles.dart';
import 'mapa/guia_trilha.dart';
import 'mapa/no_3d.dart';

import '../../../../core/theme/mixart.dart';
import '../../../ia/presentation/cenarios_page.dart';
import '../../../ia/presentation/escrita_page.dart';
import '../../../ia/presentation/ia_cubit.dart';
import '../../../ingles/presentation/leituras_page.dart';
import '../../domain/curriculo.dart';
import '../bloc/curso_bloc.dart';
import '../fluxo_licao.dart';
import '../widgets/pacman.dart';
import 'desafios_page.dart';
import 'projeto_page.dart';
import 'quiz_page.dart';
import 'teoria_page.dart';

/// Mapa da Jornada: um caminho de nós por trilha (concluída ✓, atual com
/// Pac-Man, disponível apagada), com dashboard de progresso. Tocar num nó
/// abre a lição (praticar) ou o quiz. Progresso vem do estado local.
class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  /// Inglês: rolar sozinho até a lição atual ao abrir (testes podem desligar).
  static bool rolarAoAbrir = true;

  /// Esquece as lições já vistas (a comemoração da volta compara com elas). Só para testes.
  @visibleForTesting
  static void esquecerVistas() => _MapaPageState._ultimasVistas = Expando<Set<String>>('mapa-vistas');

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final _busca = TextEditingController();
  String _query = '';

  // ── inglês: achar a lição atual, comemorar a volta, índice de palavras ──
  final _chaveAtual = GlobalKey(debugLabel: 'mapa-no-atual');
  final _rolagem = ScrollController();
  bool _rolagemAgendada = false;
  /// O "📍 Onde parei" aparece? (um notifier: mostrar/esconder não reconstrói o mapa inteiro)
  final _ondeParei = ValueNotifier<bool>(false);
  List<Trilha>? _trilhasIndexadas;

  /// As lições concluídas da última vez que o mapa foi visto, POR CursoBloc (o bloc é recriado a cada
  /// conta e curso, então outra conta na mesma sessão não herda a lista): o que entrou desde então ganha
  /// a comemoração. A primeira abertura com um bloc não comemora.
  static var _ultimasVistas = Expando<Set<String>>('mapa-vistas');
  String? _celebrar;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<CursoBloc>();
    final st = bloc.state;
    if (st.status == CursoStatus.pronto && st.ehIngles) {
      final antes = _ultimasVistas[bloc];
      if (antes != null) {
        final novas = st.concluidas.difference(antes);
        // a mais adiantada na ordem do curso
        for (var t = st.trilhas.length - 1; t >= 0 && _celebrar == null; t--) {
          for (var l = st.trilhas[t].licoes.length - 1; l >= 0; l--) {
            if (novas.contains(st.chave(t, l))) {
              _celebrar = st.chave(t, l);
              break;
            }
          }
        }
      }
      _ultimasVistas[bloc] = st.concluidas;
    }
  }

  @override
  void dispose() {
    _busca.dispose();
    _rolagem.dispose();
    _ondeParei.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    _ativo = false;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _ativo = true;
  }

  bool _ativo = true;
  double _alturaTela = 0;

  /// O nó atual está fora da tela? (mostra o "📍 Onde parei")
  bool _atualForaDaTela() {
    final ro = _chaveAtual.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) return false;
    final topo = ro.localToGlobal(Offset.zero).dy;
    return topo + ro.size.height < 120 || topo > _alturaTela - 40;
  }

  void _atualizarOndeParei() {
    if (!mounted || !_ativo) return;
    final fora = _query.trim().isEmpty && _atualForaDaTela();
    _ondeParei.value = fora; // o notifier ignora valor igual
  }

  void _irParaAtual() {
    final ctx = _chaveAtual.currentContext;
    if (ctx == null || !_ativo) return;
    Scrollable.ensureVisible(ctx, alignment: .35, duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic)
        .then((_) => _atualizarOndeParei());
  }

  /// Uma vez por abertura: se a lição atual está bem abaixo da dobra, rola até ela.
  void _agendarRolagem(CursoState st) {
    if (_rolagemAgendada || !st.ehIngles) return;
    _rolagemAgendada = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_ativo) return;
      final ro = _chaveAtual.currentContext?.findRenderObject();
      final rolar = MapaPage.rolarAoAbrir &&
          st.concluidas.isNotEmpty &&
          _query.trim().isEmpty &&
          ro is RenderBox &&
          ro.attached &&
          ro.localToGlobal(Offset.zero).dy > _alturaTela * .9;
      if (rolar) {
        _irParaAtual();
      } else {
        _atualizarOndeParei();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palavras = PalavrasCubit.de(context);
    _alturaTela = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: BlocBuilder<CursoBloc, CursoState>(
        builder: (context, st) {
          if (st.status != CursoStatus.pronto) {
            return Center(child: CircularProgressIndicator(color: Mixart.brand));
          }
          if (st.ehIngles) {
            _ultimasVistas[context.read<CursoBloc>()] = st.concluidas;
            if (palavras != null && !identical(_trilhasIndexadas, st.trilhas)) {
              _trilhasIndexadas = st.trilhas;
              palavras.prepararIndice(st.trilhas);
            }
            _agendarRolagem(st);
          }
          if (palavras == null || !st.ehIngles) return _conteudo(context, st, null);
          // o caminho só usa o índice; o banco (treinos, foco…) não reconstrói o mapa — o cartão
          // "Minhas palavras" escuta o cubit sozinho
          return BlocBuilder<PalavrasCubit, PalavrasState>(
            bloc: palavras,
            buildWhen: (a, b) => !identical(a.indice, b.indice),
            builder: (context, ps) => _conteudo(context, st, ps),
          );
        },
      ),
    );
  }

  Widget _conteudo(BuildContext context, CursoState st, PalavrasState? ps) {
          final buscando = _query.trim().isNotEmpty;
          final ingles = st.ehIngles
              ? _MapaIngles(
                  inicios: iniciosDoSeno(st.trilhas),
                  alcance: alcanceDoMapa(st.trilhas, st.concluidas, (st.trilhaIdx, st.licaoIdx)),
                  palavras: ps,
                  celebrar: _celebrar,
                  chaveAtual: _chaveAtual,
                  bauBalanca: ps?.indice == null
                      ? null
                      : bauQueBalanca(_trilhasComBauPronto(st, ps!.indice!), st.trilhaIdx),
                )
              : null;
          return Stack(children: [
            const Positioned.fill(child: _FundoPontilhado()),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (ingles != null && n is ScrollEndNotification) {
                      // depois do próximo layout (a posição nova já valendo)
                      WidgetsBinding.instance.addPostFrameCallback((_) => _atualizarOndeParei());
                      WidgetsBinding.instance.scheduleFrame();
                    }
                    return false;
                  },
                  child: CustomScrollView(controller: _rolagem, slivers: [
                  _BarraTopo(
                    st: st,
                    controle: _busca,
                    onBusca: (v) => setState(() => _query = v),
                  ),
                  if (buscando)
                    _Resultados(st: st, query: _query)
                  else ...[
                    SliverToBoxAdapter(child: _HeroDashboard(st: st)),
                    // inglês: o texto que a pessoa cola vira trilha própria, no topo
                    if (st.ehIngles) ...[
                      const SliverToBoxAdapter(child: _CartaoNovoTexto()),
                      const SliverToBoxAdapter(child: _CartaoBaralhos()),
                      const SliverToBoxAdapter(child: _CartaoLer()),
                      const SliverToBoxAdapter(child: _CartaoOuvir()),
                      const SliverToBoxAdapter(child: _CartaoConversar()),
                      const SliverToBoxAdapter(child: _CartaoEscrever()),
                      if (ps != null) SliverToBoxAdapter(child: _CartaoMinhasPalavras(st: st)),
                      for (var t = 0; t < st.trilhas.length; t++)
                        if (st.trilhas[t].propria) ...[
                          if (t == st.trilhas.indexWhere((x) => x.propria))
                            SliverToBoxAdapter(child: _FaixaEtapa(st: st, t: t)),
                          SliverToBoxAdapter(child: _SecaoTrilha(st: st, t: t, ingles: ingles)),
                          const SliverToBoxAdapter(child: _Conector()),
                        ],
                    ],
                    for (var t = 0; t < st.trilhas.length; t++)
                      if (!st.trilhas[t].propria) ...[
                        // faixa da etapa (Iniciante → Sênior) quando ela muda
                        if (st.trilhas[t].etapa.isNotEmpty &&
                            (t == 0 || st.trilhas[t - 1].etapa != st.trilhas[t].etapa))
                          SliverToBoxAdapter(child: _FaixaEtapa(st: st, t: t)),
                        SliverToBoxAdapter(child: _SecaoTrilha(st: st, t: t, ingles: ingles)),
                        const SliverToBoxAdapter(child: _Conector()),
                      ],
                    if (st.masterApps.isNotEmpty)
                      SliverToBoxAdapter(child: _SecaoMaster(st: st)),
                    if (st.ehIngles) SliverToBoxAdapter(child: _CreditosIngles(st: st)),
                    const SliverToBoxAdapter(child: SizedBox(height: 56)),
                  ],
                ]),
                ),
              ),
            ),
            // inglês: a lição atual saiu da tela → um toque volta para ela
            if (ingles != null && !buscando)
              Positioned(
                left: 0,
                right: 0,
                bottom: 22,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _ondeParei,
                  builder: (context, mostrar, _) => !mostrar
                      ? const SizedBox.shrink()
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Botao3D(
                            key: const Key('mapa-onde-parei'),
                            rotulo: '📍 Onde parei',
                            expandir: false,
                            altura: 42,
                            tamanhoTexto: 13.5,
                            cor: st.trilhaIdx < st.trilhas.length ? corDaEtapa(st.trilha.etapa) : null,
                            onTap: _irParaAtual,
                          ),
                        ]),
                ),
              ),
          ]);
  }
}

/// O que o caminho do inglês precisa saber além do estado do curso (calculado uma vez por build).
class _MapaIngles {
  final List<int> inicios;
  final PosicaoMapa? alcance;
  final PalavrasState? palavras;
  final String? celebrar;
  final GlobalKey chaveAtual;

  /// A trilha cujo baú pronto balança (só uma no mapa); null = nenhuma.
  final int? bauBalanca;
  const _MapaIngles({
    required this.inicios,
    required this.alcance,
    required this.palavras,
    required this.celebrar,
    required this.chaveAtual,
    this.bauBalanca,
  });
}

/// As trilhas do curso com o baú pronto (completas, ainda não abertas, com palavras para o baú).
Iterable<int> _trilhasComBauPronto(CursoState st, IndicePalavras indice) sync* {
  for (var t = 0; t < st.trilhas.length; t++) {
    final trilha = st.trilhas[t];
    if (trilha.propria || bauAberto(st.projetosFeitos, trilha.baralhoId)) continue;
    var completa = true;
    for (var l = 0; l < trilha.licoes.length && completa; l++) {
      completa = st.licaoConcluida(t, l);
    }
    if (completa && temBau(trilha, indice.novasDaTrilha(trilha).length)) yield t;
  }
}

/// Pratica a lição [l] da trilha [t]: seleciona e fecha o mapa (o palco abre nela).
void _praticar(BuildContext context, int t, int l) {
  final cursoBloc = context.read<CursoBloc>();
  cursoBloc.add(TrilhaSelecionada(t));
  cursoBloc.add(LicaoSelecionada(l));
  Navigator.of(context).pop();
}

/// Rodapé da trilha no inglês: "já sei isso" → teste de nivelamento.
class _TesteDaTrilha extends StatelessWidget {
  final int t;
  const _TesteDaTrilha({required this.t});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: InkWell(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          onTap: () => abrirTesteTrilha(context, t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Mixart.bg,
              border: Border.all(color: Mixart.border),
              borderRadius: BorderRadius.circular(Mixart.radiusMd),
            ),
            child: Row(children: [
              const Text('⏭️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Já sei esta trilha', style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.text)),
                  Text('teste de $frasesDoTeste frases de memória — acertou 8, pula a trilha',
                      style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: Mixart.textMuted),
            ]),
          ),
        ),
      );
}

/// Créditos do curso de inglês: as frases que vieram do Tatoeba (a licença
/// CC BY 2.0 FR pede atribuição), com os autores, e de onde vem o áudio.
class _CreditosIngles extends StatelessWidget {
  final CursoState st;
  const _CreditosIngles({required this.st});

  @override
  Widget build(BuildContext context) {
    final autores = <String, int>{};
    // gravações de nativo: "CK · CC BY-NC-ND 3.0" → quantas frases
    final vozes = <String, int>{};
    var tatoeba = 0, total = 0;
    for (final t in st.trilhas) {
      for (final l in t.licoes) {
        for (final f in l.trechos) {
          total++;
          if (f.audioCredito.isNotEmpty) vozes[f.audioCredito] = (vozes[f.audioCredito] ?? 0) + 1;
          final fonte = FonteFrase.ler(f.fonte);
          if (fonte == null) continue;
          tatoeba++;
          autores[fonte.enAutor] = (autores[fonte.enAutor] ?? 0) + 1;
          if (fonte.ptAutor != null) autores[fonte.ptAutor!] = (autores[fonte.ptAutor!] ?? 0) + 1;
        }
      }
    }
    final lista = autores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final listaVozes = vozes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final gravadas = vozes.values.fold<int>(0, (s, n) => s + n);
    final link = Mixart.ui(size: 11.5, weight: FontWeight.w700, color: Mixart.brand);
    final estilo = Mixart.ui(size: 11.5, color: Mixart.textMuted).copyWith(height: 1.5);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Créditos e fontes', style: Mixart.display(size: 15)),
          const SizedBox(height: 8),
          if (tatoeba > 0) ...[
            Text(
                '$tatoeba das $total frases vêm do Tatoeba (tatoeba.org), um acervo colaborativo de frases '
                'e traduções, sob a licença Creative Commons Atribuição 2.0 França. Cada uma mostra o número '
                'e o autor originais; as marcadas como "adaptada" foram modificadas por nós. As demais foram '
                'escritas para o curso.',
                style: estilo),
            const SizedBox(height: 6),
            Wrap(spacing: 12, children: [
              InkWell(
                onTap: () => abrirUrl('https://tatoeba.org'),
                child: Text('tatoeba.org', style: Mixart.ui(size: 11.5, weight: FontWeight.w700, color: Mixart.brand)),
              ),
              InkWell(
                onTap: () => abrirUrl(FonteFrase.urlLicenca),
                child: Text('licença CC BY 2.0 FR',
                    style: Mixart.ui(size: 11.5, weight: FontWeight.w700, color: Mixart.brand)),
              ),
            ]),
            const SizedBox(height: 6),
            Text('Autores: ${lista.map((e) => '${e.key} (${e.value})').join(', ')}.', style: estilo),
          ] else
            Text('As frases foram escritas para o curso.', style: estilo),
          const SizedBox(height: 6),
          if (gravadas > 0) ...[
            Text(
                'Vozes nativas: $gravadas frases tocam a gravação de um falante nativo feita para o Tatoeba '
                '(tatoeba.org/audio), no lugar da voz sintética. Cada frase mostra quem gravou e a licença; '
                'os arquivos são usados sem nenhuma alteração e só para fins não comerciais — o curso é '
                'gratuito. Gravações: ${listaVozes.map((e) => '${e.key} (${e.value})').join(', ')}.',
                style: estilo),
            const SizedBox(height: 6),
            Wrap(spacing: 12, children: [
              InkWell(
                onTap: () => abrirUrl('https://tatoeba.org/pt-br/audio/index'),
                child: Text('gravações do Tatoeba', style: link),
              ),
              for (final lic in {for (final v in vozes.keys) v.split(' · ').last})
                if (_urlLicencaCc(lic) case final url?)
                  InkWell(onTap: () => abrirUrl(url), child: Text('licença $lic', style: link)),
              if (vozes.keys.any((v) => v.startsWith('CK ')))
                InkWell(
                  onTap: () => abrirUrl('https://www.manythings.org/tatoeba'),
                  child: Text('CK (manythings.org)', style: link),
                ),
            ]),
            const SizedBox(height: 6),
          ],
          Text(
              gravadas > 0
                  ? 'As demais frases usam a voz em inglês do seu navegador (Web Speech) — no Edge e no Chrome '
                      'ela soa mais natural.'
                  : 'O áudio é a voz em inglês do seu navegador (Web Speech) — no Edge e no Chrome ela soa mais natural.',
              style: estilo),
        ]),
      ),
    );
  }
}

/// "CC BY-NC-ND 3.0" → a página da licença; null = não é Creative Commons.
String? _urlLicencaCc(String licenca) {
  final m = RegExp(r'^CC\s*(0|[A-Z-]+)\s+(\d\.\d)$').firstMatch(licenca.trim());
  if (m == null) return null;
  if (m.group(1) == '0') return 'https://creativecommons.org/publicdomain/zero/${m.group(2)}/';
  return 'https://creativecommons.org/licenses/${m.group(1)!.toLowerCase()}/${m.group(2)}/';
}

/// Remove acentos e caixa para busca tolerante.
String _norm(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';
  var r = s.toLowerCase();
  for (var i = 0; i < de.length; i++) {
    r = r.replaceAll(de[i], para[i]);
  }
  return r;
}

// ───────────────────────── barra superior ─────────────────────────
class _BarraTopo extends StatelessWidget {
  final CursoState st;
  final TextEditingController controle;
  final ValueChanged<String> onBusca;
  const _BarraTopo({required this.st, required this.controle, required this.onBusca});

  @override
  Widget build(BuildContext context) {
    final (total, feitas) = st.progressoDoCurso;
    final pct = total == 0 ? 0 : (feitas * 100 / total).round();
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Mixart.bg.withValues(alpha: .92),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
      ),
      title: Row(children: [
        Flexible(child: Text('Mapa da Jornada', maxLines: 1, overflow: TextOverflow.ellipsis, style: Mixart.display(size: 17))),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: Mixart.brandSub,
            border: Border.all(color: Mixart.brandDim),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('$pct%', style: Mixart.mono(size: 11, weight: FontWeight.w700, color: Mixart.brand)),
        ),
      ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: controle,
            onChanged: onBusca,
            style: Mixart.ui(size: 14, color: Mixart.text),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar lição ou app por nome…',
              hintStyle: Mixart.ui(size: 13.5, color: Mixart.textFaint),
              prefixIcon: Icon(Icons.search, size: 19, color: Mixart.textMuted),
              suffixIcon: controle.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, size: 17, color: Mixart.textMuted),
                      onPressed: () {
                        controle.clear();
                        onBusca('');
                      },
                    ),
              filled: true,
              fillColor: Mixart.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
                borderSide: BorderSide(color: Mixart.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
                borderSide: BorderSide(color: Mixart.brand, width: 1.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lista de resultados da busca: lições, projetos e apps que casam com o nome.
class _Resultados extends StatelessWidget {
  final CursoState st;
  final String query;
  const _Resultados({required this.st, required this.query});

  @override
  Widget build(BuildContext context) {
    final q = _norm(query.trim());
    final itens = <Widget>[];

    for (var t = 0; t < st.trilhas.length; t++) {
      final tr = st.trilhas[t];
      for (var l = 0; l < tr.licoes.length; l++) {
        final lic = tr.licoes[l];
        if (_norm(lic.nome).contains(q)) {
          itens.add(_ItemResultado(
            emoji: lic.emoji,
            nome: lic.nome,
            contexto: '${tr.emoji} ${tr.nivel} · lição',
            feito: st.licaoConcluida(t, l),
            onTap: () => mostrarOpcoesLicao(context, st, t, l, st.quizNotas[st.chave(t, l)]),
          ));
        }
      }
      for (var i = 0; i < tr.projetos.length; i++) {
        final p = tr.projetos[i];
        if (_norm(p.nome).contains(q)) {
          itens.add(_ItemResultado(
            emoji: p.emoji,
            nome: p.nome,
            contexto: '${tr.emoji} ${tr.nivel} · mão na massa',
            feito: st.projetoFeito(CursoState.chaveProjeto(t, i)),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<bool>(
              builder: (_) => ProjetoPage(
                nivel: tr.nivel,
                fundo: tr.fundo,
                perfil: tr.perfil,
                projeto: p,
                chaveProgresso: CursoState.chaveProjeto(t, i),
              ),
            )),
          ));
        }
      }
    }
    for (var i = 0; i < st.masterApps.length; i++) {
      final p = st.masterApps[i];
      if (_norm(p.nome).contains(q)) {
        itens.add(_ItemResultado(
          emoji: p.emoji,
          nome: p.nome,
          contexto: '🏆 Teste Master · ${p.flutter ? 'app' : 'programa'}',
          feito: st.projetoFeito(CursoState.chaveMaster(i)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<bool>(
            builder: (_) => ProjetoPage(
              nivel: st.ehCSharp ? 'Teste Master' : 'Flutter',
              fundo: st.ehCSharp ? 'desafios' : '',
              projeto: p,
              chaveProgresso: CursoState.chaveMaster(i),
              master: true,
            ),
          )),
        ));
      }
    }

    if (itens.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(children: [
            Icon(Icons.search_off, size: 40, color: Mixart.textFaint),
            const SizedBox(height: 12),
            Text('Nada encontrado para "$query"',
                textAlign: TextAlign.center, style: Mixart.ui(size: 14, color: Mixart.textMuted)),
          ]),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 4),
                child: Text('${itens.length} resultado${itens.length == 1 ? '' : 's'}',
                    style: Mixart.ui(size: 11.5, weight: FontWeight.w600, color: Mixart.textMuted)),
              );
            }
            return itens[i - 1];
          },
          childCount: itens.length + 1,
        ),
      ),
    );
  }
}

class _ItemResultado extends StatelessWidget {
  final String emoji, nome, contexto;
  final bool feito;
  final VoidCallback onTap;
  const _ItemResultado(
      {required this.emoji, required this.nome, required this.contexto, this.feito = false, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Mixart.surface,
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                border: Border.all(color: Mixart.border),
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
              ),
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nome, style: Mixart.ui(size: 14, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(contexto, style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
                  ]),
                ),
                if (feito) Icon(Icons.check_circle, size: 17, color: Mixart.brand),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: Mixart.textFaint),
              ]),
            ),
          ),
        ),
      );
}

// ───────────────────────── dashboard ─────────────────────────
class _HeroDashboard extends StatelessWidget {
  final CursoState st;
  const _HeroDashboard({required this.st});

  @override
  Widget build(BuildContext context) {
    final (totalLicoes, feitas) = st.progressoDoCurso;
    final doCurso = [for (final t in st.trilhas) if (!t.propria) t];
    final totalEx = doCurso.fold<int>(0, (s, t) => s + t.licoes.fold<int>(0, (a, l) => a + l.trechos.length));
    final estrelas = st.quizNotas.entries
        .where((e) => !e.key.startsWith(TextoSalvo.prefixoLicao))
        .fold<int>(0, (s, e) => s + e.value);
    final trilhasIniciadas = [
      for (var t = 0; t < st.trilhas.length; t++)
        if (!st.trilhas[t].propria && List.generate(st.trilhas[t].licoes.length, (l) => st.licaoConcluida(t, l)).any((f) => f)) t
    ].length;
    final pct = totalLicoes == 0 ? 0.0 : feitas / totalLicoes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF161616), Mixart.surface],
          ),
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 18), spreadRadius: -24)],
        ),
        child: Column(children: [
          Row(children: [
            _AnelProgresso(pct: pct, tamanho: 76, texto: '${(pct * 100).round()}%', grosso: true),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Sua jornada ${st.linguagem.nomeCurso}', style: Mixart.display(size: 18)),
                const SizedBox(height: 4),
                Text(_frase(pct), style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.45)),
                if (st.ehIngles) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => abrirNivelamento(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('🧭 Nivelamento: pule os níveis que você já domina',
                          style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.brand)),
                    ),
                  ),
                ],
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            _StatTile(emoji: '🏁', valor: '$feitas/$totalLicoes', rotulo: 'lições'),
            const SizedBox(width: 10),
            _StatTile(emoji: '⭐', valor: '$estrelas', rotulo: 'estrelas'),
            const SizedBox(width: 10),
            _StatTile(emoji: '🧩', valor: '$trilhasIniciadas/${doCurso.length}', rotulo: 'trilhas'),
            const SizedBox(width: 10),
            _StatTile(emoji: '⌨️', valor: _compacto(totalEx), rotulo: st.ehIngles ? 'frases' : 'exercícios'),
          ]),
        ]),
      ),
    );
  }

  String _frase(double pct) {
    if (pct <= 0) {
      return st.ehIngles
          ? 'Comece pela primeira lição: ouça, copie e digite as frases de memória.'
          : 'Comece pela primeira lição e vá comendo o código com o Pac-Man.';
    }
    if (pct < .25) return 'Bom começo! Continue avançando pela trilha.';
    if (pct < .6) return 'Você está pegando o ritmo. Siga em frente!';
    if (pct < 1) return 'Reta final — falta pouco para dominar tudo.';
    return 'Currículo completo! Você é fera. 🏆';
  }

  static String _compacto(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _StatTile extends StatelessWidget {
  final String emoji, valor, rotulo;
  const _StatTile({required this.emoji, required this.valor, required this.rotulo});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: Mixart.bg,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 5),
            FittedBox(child: Text(valor, style: Mixart.display(size: 16))),
            const SizedBox(height: 2),
            Text(rotulo, style: Mixart.ui(size: 9.5, weight: FontWeight.w600, color: Mixart.textFaint).copyWith(letterSpacing: .5)),
          ]),
        ),
      );
}

// ───────────────────────── seção de trilha ─────────────────────────
class _SecaoTrilha extends StatelessWidget {
  final CursoState st;
  final int t;

  /// Inglês: o caminho estilo Duolingo (null = Dart/C#, o cartão de sempre).
  final _MapaIngles? ingles;
  const _SecaoTrilha({required this.st, required this.t, this.ingles});

  @override
  Widget build(BuildContext context) {
    if (ingles != null) return _SecaoTrilhaIngles(st: st, t: t, ingles: ingles!, apagar: () => _apagarTexto(context));
    final trilha = st.trilhas[t];
    final feitas = List.generate(trilha.licoes.length, (l) => st.licaoConcluida(t, l));
    final concluidas = feitas.where((f) => f).length;
    final ehAtual = t == st.trilhaIdx;
    final completa = concluidas == trilha.licoes.length;
    final pct = trilha.licoes.isEmpty ? 0.0 : concluidas / trilha.licoes.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: ehAtual ? Mixart.brandDim : Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          boxShadow: ehAtual
              ? const [BoxShadow(color: Color(0x22FFC73B), blurRadius: 34, spreadRadius: -12)]
              : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // cabeçalho da trilha
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: completa ? Mixart.brand : Mixart.surfaceHi,
                  shape: BoxShape.circle,
                  border: Border.all(color: completa ? Mixart.brand : Mixart.border),
                ),
                child: Text(trilha.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(trilha.nivel, style: Mixart.display(size: 18), overflow: TextOverflow.ellipsis)),
                    if (completa) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.verified, size: 16, color: Mixart.brand),
                    ] else if (ehAtual) ...[
                      const SizedBox(width: 8),
                      _EtiquetaAtual(),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(
                      '$concluidas de ${trilha.licoes.length} lições · ${_ex(trilha)} ${st.ehIngles ? 'frases' : 'exercícios'}'
                      '${trilha.etapa.isNotEmpty ? ' · ${trilha.etapa}' : ''}',
                      style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
                ]),
              ),
              const SizedBox(width: 10),
              if (trilha.propria)
                IconButton(
                  tooltip: 'Apagar este texto',
                  onPressed: () => _apagarTexto(context),
                  icon: Icon(Icons.delete_outline, size: 19, color: Mixart.textFaint),
                ),
              _AnelProgresso(pct: pct, tamanho: 40),
            ]),
          ),
          if (trilha.descricao.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
              child: Text(trilha.descricao,
                  style: Mixart.ui(size: 12, color: Mixart.textFaint).copyWith(height: 1.45)),
            ),
          // caminho de nós
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 20),
            child: LayoutBuilder(
              builder: (context, box) => _CaminhoLicoes(st: st, t: t, largura: box.maxWidth),
            ),
          ),
          if (st.ehIngles && !completa && !trilha.propria) _TesteDaTrilha(t: t),
          if (trilha.temProjetos) _MaoNaMassa(st: st, t: t),
          if (trilha.temDesafios) _DesafiosDaTrilha(st: st, t: t),
        ]),
      ),
    );
  }

  int _ex(Trilha t) => t.licoes.fold<int>(0, (a, l) => a + l.trechos.length);

  Future<void> _apagarTexto(BuildContext context) async {
    final bloc = context.read<CursoBloc>();
    final trilha = st.trilhas[t];
    final apagar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Mixart.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          side: BorderSide(color: Mixart.border),
        ),
        title: Text('Apagar "${trilha.nivel}"?', style: Mixart.display(size: 18)),
        content: Text(
          'As ${_ex(trilha)} frases e as lições deste texto saem do app. Não dá para desfazer.',
          style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: Mixart.ui(size: 13.5, weight: FontWeight.w600, color: Mixart.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Mixart.danger, foregroundColor: Colors.white),
            child: Text('Apagar', style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (apagar == true && !bloc.isClosed) bloc.add(TextoApagado(trilha.textoId));
  }
}

/// O personagem principal de cada trilha (quem mais fala), guardado por trilha ('' = ninguém).
final _personagens = Expando<String>('personagem');

String? _personagemDe(Trilha t) {
  final p = _personagens[t] ??= personagemDaTrilha(t) ?? '';
  return p.isEmpty ? null : p;
}

/// Inglês: a unidade estilo Duolingo — a faixa na cor da etapa com o personagem, o caminho em seno com
/// nós de apertar, o balão COMEÇAR, o baú no fim e o "Já sei esta trilha".
class _SecaoTrilhaIngles extends StatelessWidget {
  final CursoState st;
  final int t;
  final _MapaIngles ingles;
  final VoidCallback apagar;
  const _SecaoTrilhaIngles({required this.st, required this.t, required this.ingles, required this.apagar});

  @override
  Widget build(BuildContext context) {
    final trilha = st.trilhas[t];
    final feitas = List.generate(trilha.licoes.length, (l) => st.licaoConcluida(t, l));
    final concluidas = feitas.where((f) => f).length;
    final completa = concluidas == trilha.licoes.length;
    final ehAtual = t == st.trilhaIdx;
    final cor = corDaEtapa(trilha.propria ? '' : trilha.etapa);
    final indice = ingles.palavras?.indice;
    final palavras = indice == null ? const <PalavraNova>[] : indice.novasDaTrilha(trilha);
    final comBau = temBau(trilha, palavras.length);
    final numero = numeroDaUnidade(st.trilhas, t);
    final nivelCurto = trilha.etapa.trim().split(RegExp(r'[ ·—-]')).first.toUpperCase();
    final sobretitulo = trilha.propria
        ? 'MEU TEXTO'
        : 'UNIDADE $numero${nivelCurto.isNotEmpty ? ' · $nivelCurto' : ''}';
    final frases = trilha.licoes.fold<int>(0, (a, l) => a + l.trechos.length);
    final quem = _personagemDe(trilha);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        BannerUnidade(
          sobretitulo: sobretitulo,
          emoji: trilha.emoji,
          nome: trilha.nivel,
          detalhe: '$concluidas de ${trilha.licoes.length} lições · $frases frases',
          progresso: trilha.licoes.isEmpty ? 0 : concluidas / trilha.licoes.length,
          cor: cor,
          atual: ehAtual,
          completa: completa,
          rosto: quem == null ? null : ElencoIngles.de(quem),
          onGuia: () => abrirGuiaTrilha(
            context,
            trilha: trilha,
            sobretitulo: sobretitulo,
            cor: cor,
            feitas: feitas,
            palavras: palavras,
            onTreinar: palavras.length < 2
                ? null
                : () => abrirTreinoPalavras(context, _paraTreinar(context, palavras), titulo: trilha.nivel),
            // "🎧 Ouvir": a unidade inteira, na ordem, ou na setlist (só com o player na árvore)
            onOuvir: OuvirCubit.de(context) == null
                ? null
                : () => tocarItens(context, [ItemSetlist.daTrilha(trilha)], titulo: 'Unidade: ${trilha.nivel}'),
            onSetlist: OuvirCubit.de(context) == null ? null : () => porNaSetlist(context, ItemSetlist.daTrilha(trilha)),
          ),
          acao: trilha.propria
              ? Material(
                  color: Mixart.surface,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Apagar este texto',
                    visualDensity: VisualDensity.compact,
                    onPressed: apagar,
                    icon: Icon(Icons.delete_outline, size: 18, color: Mixart.textMuted),
                  ),
                )
              : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 18, 0, 12),
          child: LayoutBuilder(
            builder: (context, box) => CaminhoIngles(
              st: st,
              t: t,
              largura: box.maxWidth,
              inicioSeno: ingles.inicios[t],
              alcance: ingles.alcance,
              cor: cor,
              novasDe: indice == null ? null : (licao) => indice.novasPorLicao[licao.id]?.length ?? 0,
              bau: comBau
                  ? estadoDoBau(completa: completa, projetosFeitos: st.projetosFeitos, baralhoId: trilha.baralhoId)
                  : null,
              palavrasBau: palavras.length,
              bauBalanca: ingles.bauBalanca == t,
              celebrar: ingles.celebrar,
              chaveAtual: ehAtual ? ingles.chaveAtual : null,
              onAbrirLicao: (l) {
                final estado = estadoDoNo(
                  feita: feitas[l],
                  atual: ehAtual && l == st.licaoIdx,
                  pos: (t, l),
                  alcance: ingles.alcance,
                  propria: trilha.propria,
                );
                mostrarOpcoesLicao(context, st, t, l, st.quizNotas[st.chave(t, l)],
                    trancada: estado == EstadoNo.trancada);
              },
              onComecar: (l) => _praticar(context, t, l),
              onBau: () => _abrirBau(context, trilha, palavras, cor, completa, concluidas),
            ),
          ),
        ),
        if (!completa && !trilha.propria) _TesteDaTrilha(t: t),
      ]),
    );
  }

  /// Até 8 palavras para a sessão: primeiro as que ainda não estão firmes.
  static List<PalavraNova> _paraTreinar(BuildContext context, List<PalavraNova> palavras) {
    final cubit = PalavrasCubit.de(context);
    if (cubit == null) return palavras.take(8).toList();
    final fracas = [for (final p in palavras) if (cubit.forcaDe(p.en) != ForcaPalavra.firme) p];
    final firmes = [for (final p in palavras) if (cubit.forcaDe(p.en) == ForcaPalavra.firme) p];
    return [...fracas, ...firmes].take(8).toList();
  }

  Future<void> _abrirBau(
      BuildContext context, Trilha trilha, List<PalavraNova> palavras, Color cor, bool completa, int feitas) async {
    if (!completa) {
      final faltam = trilha.licoes.length - feitas;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(faltam == 1
              ? '🔒 Termine a última lição para abrir o baú.'
              : '🔒 Termine as $faltam lições que faltam para abrir o baú.'),
          duration: const Duration(seconds: 2),
        ));
      return;
    }
    final chave = chaveDoBau(trilha.baralhoId);
    final treinar = await abrirBauTrilha(
      context,
      unidade: trilha.nivel,
      palavras: palavras,
      cor: cor,
      jaAberto: st.projetoFeito(chave),
    );
    if (!treinar || !context.mounted) return;
    await abrirTreinoPalavras(context, _paraTreinar(context, palavras),
        titulo: 'Baú · ${trilha.nivel}', chaveConclusao: chave);
  }
}

/// Inglês: o banco de palavras do aluno — "N palavras · M para revisar hoje". Sem o cubit, some.
class _CartaoMinhasPalavras extends StatelessWidget {
  final CursoState st;
  const _CartaoMinhasPalavras({required this.st});

  @override
  Widget build(BuildContext context) {
    final cubit = PalavrasCubit.de(context);
    if (cubit == null) return const SizedBox.shrink();
    // escuta o cubit sozinho: o mapa não se reconstrói quando o banco muda
    return BlocBuilder<PalavrasCubit, PalavrasState>(
      bloc: cubit,
      builder: (context, _) => _cartao(context, cubit),
    );
  }

  Widget _cartao(BuildContext context, PalavrasCubit cubit) {
    final n = cubit.palavrasDoAluno(st).length;
    final m = cubit.quantasDevidas;
    final k = cubit.quantasTeimosas;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: InkWell(
        key: const Key('palavras'),
        onTap: () => abrirMinhasPalavras(context),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
          ),
          child: Row(children: [
            const Text('📚', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Minhas palavras', style: Mixart.display(size: 16)),
                const SizedBox(height: 3),
                Text(
                  n == 0
                      ? 'As palavras novas das lições, as suas e as da leitura — elas vão para os jogos do Arcade 🎮'
                      : '$n ${n == 1 ? 'palavra' : 'palavras'} · ${m == 0 ? 'nada para revisar hoje' : '$m para revisar hoje'}'
                          '${k > 0 ? ' · $k ${k == 1 ? 'teimosa' : 'teimosas'}' : ''}',
                  style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.4),
                ),
              ]),
            ),
            if (m > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Mixart.brand, borderRadius: BorderRadius.circular(99)),
                child: Text('$m', style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.onBrand)),
              ),
            Icon(Icons.chevron_right, color: Mixart.textMuted),
          ]),
        ),
      ),
    );
  }
}

/// Inglês: o Anki do app — baralhos, previsão, cartões de virar e ajustes.
class _CartaoBaralhos extends StatelessWidget {
  const _CartaoBaralhos();

  @override
  Widget build(BuildContext context) {
    final revisao = RevisaoCubit.de(context);
    if (revisao == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: InkWell(
        key: const Key('baralhos'),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BaralhosPage())),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
          ),
          child: Row(children: [
            const Text('🧠', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Baralhos e cartões', style: Mixart.display(size: 16)),
                const SizedBox(height: 3),
                BlocBuilder<RevisaoCubit, RevisaoState>(builder: (context, st) {
                  final n = st.quantasDevidas(revisao.hoje);
                  return Text(
                    n == 0
                        ? 'Previsão, retenção, cartões de inglês → português e ajustes.'
                        : '$n ${n == 1 ? 'cartão vence' : 'cartões vencem'} hoje · previsão, retenção e ajustes.',
                    style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.4),
                  );
                }),
              ]),
            ),
            Icon(Icons.chevron_right, color: Mixart.textMuted),
          ]),
        ),
      ),
    );
  }
}

/// Inglês: ler textos e guardar as palavras novas como cartões de lacuna.
class _CartaoLer extends StatelessWidget {
  const _CartaoLer();

  @override
  Widget build(BuildContext context) {
    if (RevisaoCubit.de(context) == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: InkWell(
        key: const Key('ler'),
        onTap: () {
          final curso = context.read<CursoBloc>(), revisao = RevisaoCubit.de(context);
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => MultiBlocProvider(
              providers: [BlocProvider.value(value: curso), if (revisao != null) BlocProvider.value(value: revisao)],
              child: const LeiturasPage(),
            ),
          ));
        },
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
          ),
          child: Row(children: [
            const Text('📖', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ler e guardar palavras', style: Mixart.display(size: 16)),
                const SizedBox(height: 3),
                Text('Textos curtos e os seus: toque numa palavra e ela vira um cartão de lacuna com a frase inteira.',
                    style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.4)),
              ]),
            ),
            Icon(Icons.chevron_right, color: Mixart.textMuted),
          ]),
        ),
      ),
    );
  }
}

/// Inglês: o "🎧 Ouvir" — escutar as lições na ordem ou as setlists, sem digitar. Sem o player na árvore, some.
class _CartaoOuvir extends StatelessWidget {
  const _CartaoOuvir();

  @override
  Widget build(BuildContext context) {
    final ouvir = OuvirCubit.de(context);
    if (ouvir == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: InkWell(
        key: const Key('ouvir-cartao-mapa'),
        onTap: () => abrirOuvir(context),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
          ),
          child: Row(children: [
            const Text('🎧', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ouvir', style: Mixart.display(size: 16)),
                const SizedBox(height: 3),
                // escuta o player sozinho: enquanto toca, o cartão diz o quê
                BlocBuilder<OuvirCubit, OuvirState>(
                  bloc: ouvir,
                  buildWhen: (a, b) => a.ativo != b.ativo || a.fonte != b.fonte,
                  builder: (context, ov) => Text(
                    ov.ativo && ov.fonte != null
                        ? 'Tocando: «${ov.fonte!.titulo}» · toque para ver o player ou montar suas setlists.'
                        : 'Escute as lições na ordem ou monte suas setlists, sem digitar.',
                    style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.4),
                  ),
                ),
              ]),
            ),
            Icon(Icons.chevron_right, color: Mixart.textMuted),
          ]),
        ),
      ),
    );
  }
}

/// Inglês: ensaiar conversas com o Prof. Dash (cenários guiados). Sem a IA na árvore, some.
class _CartaoConversar extends StatelessWidget {
  const _CartaoConversar();

  @override
  Widget build(BuildContext context) {
    if (RevisaoCubit.de(context) == null || IaCubit.de(context) == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: InkWell(
        key: const Key('conversar'),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CenariosPage())),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
          ),
          child: Row(children: [
            const Text('💬', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Conversar com o Prof. Dash', style: Mixart.display(size: 16)),
                const SizedBox(height: 3),
                Text('Ensaie um café, um check-in, uma entrevista… ele só corrige no fim e dá 3 frases para virar cartão.',
                    style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.4)),
              ]),
            ),
            Icon(Icons.chevron_right, color: Mixart.textMuted),
          ]),
        ),
      ),
    );
  }
}

/// Inglês: escrever 2–3 frases e ser corrigido pelo Prof. Dash (cada erro vira cartão). Sem a IA na árvore, some.
class _CartaoEscrever extends StatelessWidget {
  const _CartaoEscrever();

  @override
  Widget build(BuildContext context) {
    if (RevisaoCubit.de(context) == null || IaCubit.de(context) == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: InkWell(
        key: const Key('escrever'),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EscritaPage())),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
          ),
          child: Row(children: [
            const Text('📝', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Escrever e ser corrigido', style: Mixart.display(size: 16)),
                const SizedBox(height: 3),
                Text('Escreva 2–3 frases sobre o seu dia: o Prof. Dash corrige, explica e cada erro vira um cartão.',
                    style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.4)),
              ]),
            ),
            Icon(Icons.chevron_right, color: Mixart.textMuted),
          ]),
        ),
      ),
    );
  }
}

/// Inglês: "cole um texto e ele vira lição" — abre a tela de colar/traduzir/revisar.
class _CartaoNovoTexto extends StatelessWidget {
  const _CartaoNovoTexto();

  Future<void> _abrir(BuildContext context) async {
    final bloc = context.read<CursoBloc>();
    final tradutor = context.read<Tradutor>();
    final nav = Navigator.of(context);
    final texto = await nav.push<TextoSalvo>(
      MaterialPageRoute<TextoSalvo>(builder: (_) => TextoParaLicaoPage(tradutor: tradutor)),
    );
    if (texto == null || bloc.isClosed) return;
    bloc.add(TextoCriado(texto));
    // a lição nova já está selecionada: fecha o mapa e cai nela
    if (nav.mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      child: InkWell(
        key: const Key('novo-texto'),
        onTap: () => _abrir(context),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: Mixart.brandDim),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
          ),
          child: Row(children: [
            const Text('✍️', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Transforme um texto em lição', style: Mixart.display(size: 16)),
                const SizedBox(height: 3),
                Text('Cole um texto em inglês: eu traduzo e monto as frases para você digitar.',
                    style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.4)),
              ]),
            ),
            Icon(Icons.add_circle_outline, color: Mixart.brand),
          ]),
        ),
      ),
    );
  }
}

/// Faixa que abre uma etapa da carreira no mapa do C# (Iniciante,
/// Intermediário, Avançado, Sênior), com quantas trilhas e lições ela tem.
class _FaixaEtapa extends StatelessWidget {
  final CursoState st;
  final int t;
  const _FaixaEtapa({required this.st, required this.t});

  static const _emojis = {
    'Iniciante': '🌱',
    'Intermediário': '🚀',
    'Avançado': '⚙️',
    'Sênior': '🏛️',
    TextoSalvo.etapa: '📝',
  };
  static const _frases = {
    'Iniciante': 'Lógica e a base da linguagem: do primeiro programa às coleções.',
    'Intermediário': 'Orientação a objetos, LINQ, async e o C# moderno.',
    'Avançado': '.NET de verdade: testes, web, banco de dados, desempenho e jogos.',
    'Sênior': 'Arquitetura, padrões, sistemas distribuídos e decisões de projeto.',
    TextoSalvo.etapa: 'Textos que você colou: cada um virou uma trilha com tradução automática.',
  };

  /// Inglês: etapas pelo nível do Quadro Europeu ("A1", "B2 · …").
  static const _niveis = {
    'A1': ('🌱', 'O básico para se virar: apresentar-se, pedir e perguntar.'),
    'A2': ('🌿', 'Rotina, passado, planos e as situações do dia a dia.'),
    'B1': ('🚀', 'Conversar com independência: opinar, contar histórias, trabalhar.'),
    'B2': ('⚙️', 'Fluência para argumentar, negociar e trabalhar em inglês.'),
    'C1': ('🏛️', 'Precisão e naturalidade: nuance, registro e expressões.'),
    'C2': ('👑', 'Domínio pleno do idioma.'),
    'DEV': ('💻', 'Inglês de trabalho em tech: reuniões, code review, incidentes, entrevistas e liderança.'),
  };

  @override
  Widget build(BuildContext context) {
    final etapa = st.trilhas[t].etapa;
    final nivel = _niveis[etapa.split(RegExp(r'[ ·—-]')).first.toUpperCase()];
    var trilhas = 0, licoes = 0, feitas = 0;
    for (var k = 0; k < st.trilhas.length; k++) {
      if (st.trilhas[k].etapa != etapa) continue;
      trilhas++;
      licoes += st.trilhas[k].licoes.length;
      for (var l = 0; l < st.trilhas[k].licoes.length; l++) {
        if (st.licaoConcluida(k, l)) feitas++;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 4),
      child: Row(children: [
        // inglês: a cor da etapa numa faixinha à esquerda (o texto fica igual)
        if (st.ehIngles) ...[
          Container(
            width: 5,
            height: 44,
            decoration: BoxDecoration(
              color: corDaEtapa(st.trilhas[t].propria ? '' : etapa),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Text(nivel?.$1 ?? _emojis[etapa] ?? '⭐', style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(etapa.toUpperCase(),
                style: Mixart.display(size: 17, color: Mixart.brand).copyWith(letterSpacing: 2.2)),
            const SizedBox(height: 2),
            Text('${nivel?.$2 ?? _frases[etapa] ?? ''} $trilhas ${trilhas == 1 ? 'trilha' : 'trilhas'} · $feitas/$licoes lições.',
                style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}

/// Rodapé "Desafios de lógica" da trilha: quantos já foram acertados e o
/// botão que abre a bateria (prever saída, lacuna, ordenar, bug…).
class _DesafiosDaTrilha extends StatelessWidget {
  final CursoState st;
  final int t;
  const _DesafiosDaTrilha({required this.st, required this.t});

  @override
  Widget build(BuildContext context) {
    final trilha = st.trilhas[t];
    final total = trilha.desafios.length;
    final feitos = st.desafiosFeitos(t);
    final jogos = trilha.desafios.where((d) => d.ehJogo).length;
    final completos = feitos == total;
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<bool>(
        builder: (_) => DesafiosPage(trilhaIdx: t, trilha: trilha),
      )),
      borderRadius: BorderRadius.circular(Mixart.radiusMd),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Mixart.surfaceHi,
          border: Border.all(color: completos ? Mixart.brandDim : Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Row(children: [
          const Text('🧠', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('DESAFIOS DE LÓGICA',
                    style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 1.5)),
                if (completos) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.verified, size: 14, color: Mixart.brand),
                ],
              ]),
              const SizedBox(height: 3),
              Text(
                  feitos == 0
                      ? '$total desafios sem digitação${jogos > 0 ? ' · $jogos com tema de jogo' : ''}'
                      : '$feitos de $total resolvidos${jogos > 0 ? ' · $jogos com tema de jogo' : ''}',
                  style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(Icons.play_circle_fill, color: Mixart.brand, size: 28),
        ]),
      ),
    );
  }
}

/// Rodapé "Mão na Massa": os projetos completos ao fim do módulo, com quantos
/// já foram construídos.
class _MaoNaMassa extends StatelessWidget {
  final CursoState st;
  final int t;
  const _MaoNaMassa({required this.st, required this.t});

  @override
  Widget build(BuildContext context) {
    final trilha = st.trilhas[t];
    final projetos = trilha.projetos;
    final feitos = projetos.length - st.projetosPendentes(t).length;
    final completos = feitos == projetos.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Mixart.brandSub,
        border: Border.all(color: Mixart.brandDim),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(completos ? Icons.verified : Icons.construction, size: 16, color: Mixart.brand),
          const SizedBox(width: 8),
          Text('MÃO NA MASSA',
              style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 1.5)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              feitos == 0
                  ? '· construa ${projetos.length} ${projetos.any((p) => p.flutter) ? 'app' : 'programa'}${projetos.length == 1 ? '' : 's'}'
                  : '· $feitos de ${projetos.length} construídos',
              overflow: TextOverflow.ellipsis,
              style: Mixart.ui(
                  size: 11,
                  weight: feitos > 0 ? FontWeight.w600 : FontWeight.w400,
                  color: completos ? Mixart.brand : Mixart.textMuted),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        for (var i = 0; i < projetos.length; i++)
          _ChipProjeto(
            projeto: projetos[i],
            feito: st.projetoFeito(CursoState.chaveProjeto(t, i)),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<bool>(
              builder: (_) => ProjetoPage(
                nivel: trilha.nivel,
                fundo: trilha.fundo,
                perfil: trilha.perfil,
                projeto: projetos[i],
                chaveProgresso: CursoState.chaveProjeto(t, i),
              ),
            )),
          ),
      ]),
    );
  }
}

class _ChipProjeto extends StatelessWidget {
  final Projeto projeto;
  final VoidCallback onTap;
  final bool master;
  final bool feito;
  const _ChipProjeto(
      {required this.projeto, required this.onTap, this.master = false, this.feito = false});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: feito ? Mixart.brandDim : Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Row(children: [
            // feito vira medalhinha de check no lugar do emoji
            feito
                ? Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Mixart.brand, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, size: 17, color: Mixart.onBrand),
                  )
                : Text(projeto.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(projeto.nome,
                        overflow: TextOverflow.ellipsis,
                        style: Mixart.ui(size: 14, weight: FontWeight.w700)),
                  ),
                  if (feito) ...[
                    const SizedBox(width: 8),
                    Text('construído',
                        style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.brand)),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(projeto.descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Mixart.ui(size: 11.5, color: Mixart.textMuted).copyWith(height: 1.35)),
              ]),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Mixart.brandSub,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(projeto.flutter ? Icons.phone_iphone : Icons.terminal, size: 12, color: Mixart.brand),
                const SizedBox(width: 4),
                Text(projeto.flutter ? 'app' : 'programa',
                    style: Mixart.ui(size: 10, weight: FontWeight.w600, color: Mixart.brand)),
              ]),
            ),
          ]),
        ),
      );
}

/// Seção especial do Teste Master: os apps Flutter finais.
class _SecaoMaster extends StatelessWidget {
  final CursoState st;
  const _SecaoMaster({required this.st});

  @override
  Widget build(BuildContext context) {
    final projetos = st.masterApps;
    final feitos = List.generate(projetos.length, (i) => st.projetoFeito(CursoState.chaveMaster(i)))
        .where((f) => f)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Mixart.brand.withValues(alpha: .18), Mixart.surface],
          ),
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          boxShadow: const [BoxShadow(color: Color(0x22FFC73B), blurRadius: 40, spreadRadius: -14)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
            child: Row(children: [
              const Text('🏆', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Teste Master', style: Mixart.display(size: 20)),
                  Text(
                      feitos == 0
                          ? (st.ehCSharp
                              ? '${projetos.length} sistemas em C# para construir, do simples ao sênior'
                              : '${projetos.length} apps Flutter para construir, do simples ao avançado')
                          : '$feitos de ${projetos.length} ${st.ehCSharp ? 'sistemas' : 'apps'} construídos',
                      style: Mixart.ui(
                          size: 11.5,
                          weight: feitos > 0 ? FontWeight.w600 : FontWeight.w400,
                          color: feitos == projetos.length ? Mixart.brand : Mixart.textMuted)),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
            child: Text(
                st.ehCSharp
                    ? 'Programas completos que juntam tudo o que você estudou. Ao terminar, copie o código e rode com dotnet run.'
                    : 'Cada app se monta na telinha enquanto você digita. Ao terminar, copie o código e rode numa IDE de verdade.',
                style: Mixart.ui(size: 12, color: Mixart.textFaint).copyWith(height: 1.45)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              for (var i = 0; i < projetos.length; i++)
                _ChipProjeto(
                  projeto: projetos[i],
                  master: true,
                  feito: st.projetoFeito(CursoState.chaveMaster(i)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<bool>(
                    builder: (_) => ProjetoPage(
                      nivel: st.ehCSharp ? 'Teste Master' : 'Flutter',
                      fundo: st.ehCSharp ? 'desafios' : '',
                      projeto: projetos[i],
                      chaveProgresso: CursoState.chaveMaster(i),
                      master: true,
                    ),
                  )),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _EtiquetaAtual extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Mixart.brandSub,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text('ATUAL',
            style: Mixart.ui(size: 9, weight: FontWeight.w700, color: Mixart.brand).copyWith(letterSpacing: 1)),
      );
}

// ───────────────────────── caminho + nós ─────────────────────────
class _CaminhoLicoes extends StatelessWidget {
  final CursoState st;
  final int t;
  final double largura;
  const _CaminhoLicoes({required this.st, required this.t, required this.largura});

  static const _passoY = 84.0;
  static const _no = 54.0;
  static const _margem = 14.0;
  static const _rotuloMin = 92.0;

  /// Amplitude adaptativa: grande no desktop, menor no celular, sempre
  /// deixando espaço para o rótulo caber do lado de fora.
  double _amplitude() {
    final ideal = math.min(largura * 0.28, 104.0);
    final maxParaRotulo = largura / 2 - _no / 2 - _margem - _rotuloMin;
    return math.max(0, math.min(ideal, maxParaRotulo));
  }

  /// Zigue-zague equilibrado: alterna esquerda/direita do centro.
  Offset _pos(int i) {
    final centro = largura / 2;
    final dx = centro + (i.isEven ? -1 : 1) * _amplitude();
    return Offset(dx, i * _passoY + _no / 2 + 6);
  }

  @override
  Widget build(BuildContext context) {
    final licoes = st.trilhas[t].licoes;
    final altura = licoes.length * _passoY + 14;
    final pontos = List.generate(licoes.length, _pos);
    return SizedBox(
      height: altura,
      child: Stack(clipBehavior: Clip.none, children: [
        CustomPaint(
          size: Size(largura, altura),
          painter: _TrilhoPainter(
            pontos: pontos,
            feitas: List.generate(licoes.length, (l) => st.licaoConcluida(t, l)),
          ),
        ),
        for (var l = 0; l < licoes.length; l++) _montaNo(context, l, pontos[l]),
      ]),
    );
  }

  Widget _montaNo(BuildContext context, int l, Offset p) {
    final licao = st.trilhas[t].licoes[l];
    final feita = st.licaoConcluida(t, l);
    final atual = t == st.trilhaIdx && l == st.licaoIdx;
    final ladoDireito = l.isOdd; // lane do zigue-zague (robusto p/ amplitude pequena)
    final nota = st.quizNotas[st.chave(t, l)];

    final node = _NoLicao(
      emoji: licao.emoji,
      feita: feita,
      atual: atual,
      nota: nota,
      onTap: () => _abreOpcoes(context, l, nota),
    );

    // rótulo para fora do nó (também clicável); o texto encosta no nó
    final rotulo = _Rotulo(
      nome: licao.nome,
      feita: feita,
      atual: atual,
      nota: nota,
      alinhaDireita: !ladoDireito,
      onTap: () => _abreOpcoes(context, l, nota),
    );

    return Positioned(
      top: p.dy - _passoY / 2,
      left: 0,
      right: 0,
      height: _passoY,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        // rótulo para FORA do nó (lado com mais espaço), centrado na vertical
        Positioned(
          top: 0,
          bottom: 0,
          left: ladoDireito ? p.dx + _no / 2 + 12 : _margem,
          right: ladoDireito ? _margem : largura - (p.dx - _no / 2) + 12,
          child: Align(
            alignment: ladoDireito ? Alignment.centerLeft : Alignment.centerRight,
            child: rotulo,
          ),
        ),
        Positioned(left: p.dx - _no / 2, top: _passoY / 2 - _no / 2, child: node),
      ]),
    );
  }

  void _abreOpcoes(BuildContext context, int l, int? nota) =>
      mostrarOpcoesLicao(context, st, t, l, nota);
}

/// Abre a folha de opções de uma lição (Teoria / Praticar / Quiz). Reutilizada
/// pelos nós do mapa e pelos resultados da busca. [trancada] (inglês) = a lição
/// está depois de onde a pessoa chegou: a folha avisa e oferece o teste da unidade.
void mostrarOpcoesLicao(BuildContext context, CursoState st, int t, int l, int? nota, {bool trancada = false}) {
  final licao = st.trilhas[t].licoes[l];
  final cursoBloc = context.read<CursoBloc>();
  final feita = st.licaoConcluida(t, l);
  // inglês: as palavras novas da lição (vazio até o índice ficar pronto)
  final novas = st.ehIngles ? PalavrasCubit.de(context)?.novasDaLicao(st, licao) ?? const <PalavraNova>[] : const <PalavraNova>[];
  // inglês: o "🎧 Ouvir" (lição trancada também toca; ouvir não marca progresso)
  final ouvir = st.ehIngles && OuvirCubit.de(context) != null;
  final propria = st.trilhas[t].propria;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF141414),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusLg))),
    builder: (sheet) => _LicaoSheet(
      licao: licao,
      feita: feita,
      nota: nota,
      ingles: st.ehIngles,
      trancada: st.ehIngles && trancada && !feita,
      novas: novas,
      onPalavras: novas.length < 2
          ? null
          : () {
              Navigator.of(sheet).pop();
              abrirTreinoPalavras(context, novas.take(8).toList(), titulo: licao.nome);
            },
      onTesteUnidade: st.ehIngles && trancada && !st.trilhas[t].propria
          ? () {
              Navigator.of(sheet).pop();
              abrirTesteTrilha(context, t);
            }
          : null,
      // a folha fecha antes: o player e o snackbar aparecem no mapa, não atrás dela
      onOuvir: !ouvir
          ? null
          : () {
              Navigator.of(sheet).pop();
              tocarItens(context, [ItemSetlist.daLicao(licao)], titulo: licao.nome);
            },
      onOuvirDaqui: !ouvir || propria
          ? null
          : () {
              Navigator.of(sheet).pop();
              tocarCursoDesde(context, licao.id);
            },
      onPorNaSetlist: !ouvir
          ? null
          : () {
              Navigator.of(sheet).pop();
              porNaSetlist(context, ItemSetlist.daLicao(licao));
            },
      onEscolherFrases: !ouvir
          ? null
          : () {
              Navigator.of(sheet).pop();
              escolherFrasesDaLicao(context, licao);
            },
      onTeoria: () {
        Navigator.of(sheet).pop();
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => TeoriaPage(
            nivel: st.trilhas[t].nivel,
            fundo: st.trilhas[t].fundo,
            licao: licao,
            onPraticar: () {
              cursoBloc.add(TrilhaSelecionada(t));
              cursoBloc.add(LicaoSelecionada(l));
              Navigator.of(context).pop();
            },
          ),
        ));
      },
      onPraticar: () {
        Navigator.of(sheet).pop();
        cursoBloc.add(TrilhaSelecionada(t));
        cursoBloc.add(LicaoSelecionada(l));
        Navigator.of(context).pop();
      },
      onQuiz: () {
        Navigator.of(sheet).pop();
        if (st.ehIngles) {
          abrirFixacao(context, t, l);
          return;
        }
        Navigator.of(context).push(MaterialPageRoute<bool>(
          builder: (_) => QuizPage(
            trilhaIdx: t,
            licaoIdx: l,
            licao: licao,
            poolTrilha: poolDaTrilha(st.trilhas[t]),
          ),
        ));
      },
    ),
  );
}

class _Rotulo extends StatelessWidget {
  final String nome;
  final bool feita, atual;
  final int? nota;
  final bool alinhaDireita;
  final VoidCallback onTap;
  const _Rotulo(
      {required this.nome,
      required this.feita,
      required this.atual,
      this.nota,
      required this.alinhaDireita,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Column(
        crossAxisAlignment: alinhaDireita ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            nome,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alinhaDireita ? TextAlign.right : TextAlign.left,
            style: Mixart.ui(
              size: 12.5,
              weight: atual ? FontWeight.w700 : FontWeight.w600,
              color: atual
                  ? Mixart.brand
                  : feita
                      ? Mixart.text
                      : Mixart.textFaint,
            ),
          ),
          if (atual)
            Text('você está aqui', style: Mixart.ui(size: 10, weight: FontWeight.w600, color: Mixart.brand))
          else if (nota != null)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.star, size: 10, color: nota! >= 8 ? Mixart.brand : Mixart.textMuted),
              const SizedBox(width: 2),
              Text('$nota/10',
                  style: Mixart.ui(size: 10, weight: FontWeight.w600, color: nota! >= 8 ? Mixart.brand : Mixart.textMuted)),
            ]),
        ],
      ),
      ),
    );
  }
}

class _NoLicao extends StatefulWidget {
  final String emoji;
  final bool feita, atual;
  final int? nota;
  final VoidCallback onTap;
  const _NoLicao(
      {required this.emoji, required this.feita, required this.atual, this.nota, required this.onTap});

  @override
  State<_NoLicao> createState() => _NoLicaoState();
}

class _NoLicaoState extends State<_NoLicao> with SingleTickerProviderStateMixin {
  AnimationController? _pulso;

  @override
  void initState() {
    super.initState();
    if (widget.atual) {
      _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulso?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tam = _CaminhoLicoes._no;

    Widget miolo;
    BoxDecoration deco;
    List<BoxShadow> sombra = const [];

    if (widget.feita) {
      deco = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD766), Mixart.brand],
        ),
        shape: BoxShape.circle,
      );
      sombra = const [BoxShadow(color: Color(0x55FFC73B), blurRadius: 16, spreadRadius: -2)];
      miolo = Icon(Icons.check_rounded, size: 26, color: Mixart.onBrand);
    } else if (widget.atual) {
      deco = BoxDecoration(
        color: Mixart.brandSub,
        shape: BoxShape.circle,
        border: Border.all(color: Mixart.brand, width: 2.5),
      );
      miolo = const Padding(padding: EdgeInsets.all(9), child: Pacman(tamanho: 26));
    } else {
      deco = BoxDecoration(
        color: Mixart.surfaceHi,
        shape: BoxShape.circle,
        border: Border.all(color: Mixart.border),
      );
      miolo = Opacity(opacity: .55, child: Text(widget.emoji, style: const TextStyle(fontSize: 20)));
    }

    Widget circulo = Container(
      width: tam,
      height: tam,
      alignment: Alignment.center,
      decoration: deco.copyWith(boxShadow: sombra),
      child: miolo,
    );

    if (widget.atual && _pulso != null) {
      // anel de brilho pulsante atrás do Pac-Man
      circulo = Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        AnimatedBuilder(
          animation: _pulso!,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_pulso!.value);
            return Container(
              width: tam + 14 + t * 10,
              height: tam + 14 + t * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Mixart.brand.withValues(alpha: .35 - t * .25), width: 2),
              ),
            );
          },
        ),
        circulo,
      ]);
    }

    return InkWell(
      onTap: widget.onTap,
      customBorder: const CircleBorder(),
      child: Stack(clipBehavior: Clip.none, children: [
        circulo,
        // estrela = quiz já respondido (cheia quando foi bem)
        if (widget.nota != null)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Mixart.bg, shape: BoxShape.circle),
              child: Icon(widget.nota! >= 8 ? Icons.star : Icons.star_border,
                  size: 14, color: widget.nota! >= 8 ? Mixart.brand : Mixart.textMuted),
            ),
          ),
      ]),
    );
  }
}

/// Linha do caminho: trecho percorrido em amarelo com brilho, resto tracejado.
class _TrilhoPainter extends CustomPainter {
  final List<Offset> pontos;
  final List<bool> feitas;
  _TrilhoPainter({required this.pontos, required this.feitas});

  @override
  void paint(Canvas canvas, Size size) {
    if (pontos.length < 2) return;
    final glow = Paint()
      ..color = const Color(0x33FFC73B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final feito = Paint()
      ..color = Mixart.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final pendente = Paint()
      ..color = Mixart.surfaceHi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < pontos.length - 1; i++) {
      final a = pontos[i], b = pontos[i + 1];
      final meioY = (a.dy + b.dy) / 2;
      final caminho = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, meioY, b.dx, meioY, b.dx, b.dy);
      if (feitas[i]) {
        canvas.drawPath(caminho, glow);
        canvas.drawPath(caminho, feito);
      } else {
        _tracejado(canvas, caminho, pendente);
      }
    }
  }

  void _tracejado(Canvas canvas, Path caminho, Paint p) {
    for (final metric in caminho.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final fim = math.min(dist + 7, metric.length);
        canvas.drawPath(metric.extractPath(dist, fim), p);
        dist += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_TrilhoPainter old) => old.pontos != pontos || old.feitas != feitas;
}

// ───────────────────────── folha da lição ─────────────────────────
class _LicaoSheet extends StatelessWidget {
  final Licao licao;
  final bool feita;
  final int? nota;

  /// Curso de inglês: frases, "Entenda a lição" e Fixação no lugar do quiz.
  final bool ingles;
  final VoidCallback onTeoria, onPraticar, onQuiz;

  /// Inglês: a lição parece trancada (aviso + "Fazer o teste da unidade" em [onTesteUnidade]).
  final bool trancada;
  final VoidCallback? onTesteUnidade;

  /// Inglês: as palavras novas da lição e o treino delas (null = menos de 2).
  final List<PalavraNova> novas;
  final VoidCallback? onPalavras;

  /// Inglês: o "🎧 Ouvir" — tocar a lição, tocar daqui até o fim do curso (null em texto próprio),
  /// pôr na setlist e escolher frases (toque longo no ➕ também). null = sem player.
  final VoidCallback? onOuvir, onOuvirDaqui, onPorNaSetlist, onEscolherFrases;
  const _LicaoSheet(
      {required this.licao,
      required this.feita,
      this.nota,
      this.ingles = false,
      this.trancada = false,
      this.onTesteUnidade,
      this.novas = const [],
      this.onPalavras,
      this.onOuvir,
      this.onOuvirDaqui,
      this.onPorNaSetlist,
      this.onEscolherFrases,
      required this.onTeoria,
      required this.onPraticar,
      required this.onQuiz});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // rola em tela baixa (no inglês a folha ganhou as linhas do "🎧 Ouvir")
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Mixart.surfaceHi, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: feita ? Mixart.brand : Mixart.surfaceHi,
                shape: BoxShape.circle,
                border: Border.all(color: feita ? Mixart.brand : Mixart.border),
              ),
              child: feita
                  ? Icon(Icons.check_rounded, color: Mixart.onBrand, size: 24)
                  : Text(licao.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(licao.nome, style: Mixart.display(size: 19)),
                Text('${licao.trechos.length} ${ingles ? 'frases' : 'exercícios'}${feita ? ' · concluída' : ''}',
                    style: Mixart.ui(size: 12, color: feita ? Mixart.brand : Mixart.textMuted)),
              ]),
            ),
            if (ingles && nota != null) ...[
              EstrelasArco(estrelas: estrelasDaNota(nota), tamanho: 13),
              const SizedBox(width: 6),
            ],
            if (nota != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Mixart.brandSub,
                  border: Border.all(color: Mixart.brandDim),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star, size: 13, color: Mixart.brand),
                  const SizedBox(width: 4),
                  Text('$nota/10', style: Mixart.ui(size: 11.5, weight: FontWeight.w700, color: Mixart.brand)),
                ]),
              ),
          ]),
          if (trancada) ...[
            const SizedBox(height: 14),
            Container(
              key: const Key('sheet-trancada'),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Mixart.bg,
                border: Border.all(color: Mixart.border),
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🔒', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                        onTesteUnidade != null
                            ? 'Você ainda não chegou aqui — pode pular direto ou provar que já sabe:'
                            : 'Você ainda não chegou aqui — mas pode pular, se quiser.',
                        style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4)),
                    if (onTesteUnidade != null)
                      TextButton(
                        key: const Key('sheet-teste-unidade'),
                        onPressed: onTesteUnidade,
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.only(top: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: Text('Fazer o teste da unidade ›',
                            style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.brand)),
                      ),
                  ]),
                ),
              ]),
            ),
          ],
          if (licao.resumo.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Mixart.bg,
                border: Border.all(color: Mixart.border),
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.menu_book_outlined, size: 16, color: Mixart.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(licao.resumo,
                      style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5)),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          if (licao.temTeoria) ...[
            _OpcaoSheet(
              icone: Icons.menu_book_outlined,
              titulo: ingles ? 'Entenda a lição' : 'Teoria (Nivelamento)',
              subtitulo: ingles ? 'a explicação em português, com exemplos' : 'entenda o conceito antes de digitar',
              destaque: true,
              onTap: onTeoria,
            ),
            const SizedBox(height: 10),
          ],
          _OpcaoSheet(
            icone: Icons.keyboard_alt_outlined,
            titulo: feita ? 'Praticar de novo' : 'Praticar lição',
            subtitulo: ingles
                ? 'copie, complete e digite as frases de memória'
                : 'digite os exercícios com o Pac-Man',
            destaque: !licao.temTeoria,
            onTap: onPraticar,
          ),
          const SizedBox(height: 10),
          _OpcaoSheet(
            icone: Icons.quiz_outlined,
            titulo: ingles ? 'Treino de memória' : 'Quiz da lição',
            subtitulo: ingles
                ? '${nota != null ? 'prova da lição: $nota/10 · ' : ''}todas as frases de memória, fora de ordem'
                : nota != null
                    ? 'seu recorde: $nota/10 — tente superar'
                    : 'até 10 perguntas — escolha e digite o código certo',
            feito: nota != null,
            onTap: onQuiz,
          ),
          if (ingles && onPalavras != null) ...[
            const SizedBox(height: 10),
            KeyedSubtree(
              key: const Key('sheet-palavras'),
              child: _OpcaoSheet(
                icone: Icons.style_outlined,
                titulo: '🆕 Treinar as palavras novas (${novas.length})',
                subtitulo: novas.take(5).map((p) => p.en).join(' · ') + (novas.length > 5 ? ' …' : ''),
                onTap: onPalavras!,
              ),
            ),
          ],
          if (ingles && onOuvir != null) ...[
            const SizedBox(height: 16),
            Text('🎧 OUVIR — SEM DIGITAR',
                style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
            const SizedBox(height: 8),
            KeyedSubtree(
              key: const Key('ouvir-licao-tocar'),
              child: _OpcaoSheet(
                icone: Icons.play_arrow_rounded,
                titulo: '▶ Ouvir esta lição',
                subtitulo: trancada
                    ? 'Lição à frente — pode ouvir à vontade'
                    : '${licao.trechos.length} frases na ordem do diálogo',
                onTap: onOuvir!,
              ),
            ),
            if (onOuvirDaqui != null) ...[
              const SizedBox(height: 10),
              KeyedSubtree(
                key: const Key('ouvir-licao-daqui'),
                child: _OpcaoSheet(
                  icone: Icons.fast_forward_rounded,
                  titulo: '⏩ Ouvir daqui até o fim do curso',
                  subtitulo: 'esta lição e todas as seguintes, uma atrás da outra',
                  onTap: onOuvirDaqui!,
                ),
              ),
            ],
            if (onPorNaSetlist != null) ...[
              const SizedBox(height: 10),
              KeyedSubtree(
                key: const Key('ouvir-licao-add'),
                child: _OpcaoSheet(
                  icone: Icons.playlist_add_rounded,
                  titulo: '➕ Pôr na setlist',
                  subtitulo: 'a lição inteira · segure para escolher só algumas frases',
                  onTap: onPorNaSetlist!,
                  onLongPress: onEscolherFrases,
                ),
              ),
            ],
            if (onEscolherFrases != null) ...[
              const SizedBox(height: 10),
              KeyedSubtree(
                key: const Key('ouvir-licao-frases'),
                child: _OpcaoSheet(
                  icone: Icons.checklist_rounded,
                  titulo: 'Escolher frases…',
                  subtitulo: 'marque as frases que quer ouvir ou pôr na setlist',
                  onTap: onEscolherFrases!,
                ),
              ),
            ],
          ],
        ]),
      ),
    );
  }
}

class _OpcaoSheet extends StatelessWidget {
  final IconData icone;
  final String titulo, subtitulo;
  final bool destaque;
  final bool feito;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _OpcaoSheet(
      {required this.icone,
      required this.titulo,
      required this.subtitulo,
      this.destaque = false,
      this.feito = false,
      required this.onTap,
      this.onLongPress});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: destaque ? Mixart.brandSub : Mixart.surface,
            border: Border.all(color: destaque ? Mixart.brandDim : Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Mixart.brand, shape: BoxShape.circle),
              child: Icon(icone, size: 20, color: Mixart.onBrand),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(titulo,
                        overflow: TextOverflow.ellipsis,
                        style: Mixart.ui(size: 14.5, weight: FontWeight.w700)),
                  ),
                  if (feito) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, size: 15, color: Mixart.brand),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(subtitulo, style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
              ]),
            ),
            Icon(Icons.chevron_right, size: 18, color: Mixart.textFaint),
          ]),
        ),
      );
}

// ───────────────────────── conector entre trilhas ─────────────────────────
class _Conector extends StatelessWidget {
  const _Conector();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 30,
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 3,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(color: Mixart.surfaceHi, borderRadius: BorderRadius.circular(2)),
              ),
          ]),
        ),
      );
}

// ───────────────────────── auxiliares ─────────────────────────
class _AnelProgresso extends StatelessWidget {
  final double pct;
  final double tamanho;
  final String? texto;
  final bool grosso;
  const _AnelProgresso({required this.pct, required this.tamanho, this.texto, this.grosso = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: tamanho,
        height: tamanho,
        child: Stack(fit: StackFit.expand, children: [
          CircularProgressIndicator(
            value: pct,
            strokeWidth: grosso ? 6 : 4,
            backgroundColor: Mixart.surfaceHi,
            color: Mixart.brand,
            strokeCap: StrokeCap.round,
          ),
          if (texto != null)
            Center(child: Text(texto!, style: Mixart.display(size: tamanho * .26, color: Mixart.text))),
        ]),
      );
}

/// Fundo com pontos discretos + um brilho radial no topo, para dar profundidade.
class _FundoPontilhado extends StatelessWidget {
  const _FundoPontilhado();
  @override
  Widget build(BuildContext context) => const CustomPaint(painter: _PontosPainter());
}

class _PontosPainter extends CustomPainter {
  const _PontosPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final brilho = Paint()
      ..shader = const RadialGradient(colors: [Color(0x14FFC73B), Color(0x00FFC73B)]).createShader(
        Rect.fromCircle(center: Offset(size.width / 2, 40), radius: size.width * .7),
      );
    canvas.drawRect(Offset.zero & size, brilho);

    final ponto = Paint()..color = const Color(0x0DFFFFFF);
    const passo = 34.0;
    for (var y = 0.0; y < size.height; y += passo) {
      for (var x = 0.0; x < size.width; x += passo) {
        canvas.drawCircle(Offset(x, y), 1, ponto);
      }
    }
  }

  @override
  bool shouldRepaint(_PontosPainter old) => false;
}
