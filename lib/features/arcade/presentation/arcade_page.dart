import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../../core/ui/festa.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../ingles/domain/banco_palavras.dart';
import '../../ingles/domain/palavras_novas.dart';
import '../../ingles/domain/teimosas.dart';
import '../../ingles/presentation/acoes_teimosas.dart';
import '../../ingles/presentation/minhas_palavras_page.dart';
import '../../ingles/presentation/palavras_cubit.dart';
import '../../ingles/presentation/treino_palavras.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/personagem.dart';
import 'widgets/avatares.dart';
import 'banco_arcade.dart';
import 'caca_bug_page.dart';
import 'chuva_page.dart';
import 'corrida_page.dart';
import 'escolher_licoes_page.dart';
import 'futebol_page.dart';
import 'missoes_page.dart';
import 'rali_page.dart';
import 'turismo_page.dart';
import 'widgets/arcade_ui.dart';

/// Nada vencendo: as fracas do banco e depois as nunca treinadas (banco + lições concluídas), como o
/// "Revisar" de Minhas palavras — nunca as de função (the, and, you…) nem os nomes das personagens, que
/// o vocabulário dos jogos usa de enchimento. As que a pessoa escreveu passam sempre. Até 8.
List<PalavraNova> treinoSemDevidas(PalavrasCubit cubit, CursoState st) {
  final nomes = cubit.state.indice?.nomes ?? const <String>{};
  bool treinavel(PalavraDoBanco p) {
    if (p.pt.trim().isEmpty) return false;
    if (p.origem == OrigemPalavra.minha) return true;
    final k = p.chave;
    return k.length >= 3 && !stopwordsEn.contains(k) && !nomes.contains(k);
  }

  final escolha = <String, PalavraNova>{};
  for (final p in cubit.state.banco.fracas(cubit.state.hoje)) {
    if (escolha.length >= 8) break;
    if (treinavel(p)) escolha[p.chave] = p.comoPalavraNova;
  }
  for (final p in cubit.palavrasDoAluno(st)) {
    if (escolha.length >= 8) break;
    if (p.cartao == null && treinavel(p)) escolha.putIfAbsent(p.chave, () => p.comoPalavraNova);
  }
  return escolha.values.toList();
}

/// 🎮 Hub do Arcade: os joguinhos de Dart, com o recorde pessoal de cada um.
class ArcadePage extends StatefulWidget {
  const ArcadePage({super.key});

  @override
  State<ArcadePage> createState() => _ArcadePageState();
}

class _ArcadePageState extends State<ArcadePage> {
  RankingCubit? _ranking;

  /// Inglês: o banco de palavras do aluno (null no Dart/C# ou sem o provider).
  PalavrasCubit? _palavras;

  @override
  void initState() {
    super.initState();
    _ranking = RankingCubit.de(context);
    _ranking?.carregarTop(); // atualiza os recordes dos cartões
    PersonagemStore.carregar().then((_) {
      if (mounted) setState(() {});
    });
    _palavras = BancoArcade.palavras(context);
    // o índice das palavras do curso (os jogos usam as das lições assim que ele fica pronto)
    final st = _cursoIngles();
    if (st != null) _palavras?.prepararIndice(st.trilhas);
  }

  /// O estado do curso de inglês (null sem o CursoBloc ou fora do inglês).
  CursoState? _cursoIngles() {
    try {
      final st = BlocProvider.of<CursoBloc>(context, listen: false).state;
      return st.ehIngles ? st : null;
    } catch (_) {
      return null;
    }
  }

  /// 📚 Cartão das palavras do aluno no lugar da Lógica Animada (só no inglês): com quantas palavras
  /// os jogos estão jogando, as do momento (EN em cima, PT embaixo), Gerenciar e Revisar.
  Widget _cartaoMinhasPalavras(PalavrasCubit cubit) {
    return BlocBuilder<PalavrasCubit, PalavrasState>(
      bloc: cubit,
      builder: (context, ps) {
        final st = _cursoIngles();
        final v = st == null ? null : cubit.vocabularioJogo(st);
        final ind = ps.indice;
        final banco = ps.banco;
        final todas = v == null ? const <String>[] : {...v.todas}.toList();
        // as lições escolhidas para os jogos (null = automático) — só as que existem no curso
        final escolha = banco.licoesJogo;
        final idsEscolhidos = escolha == null || st == null
            ? const <String>{}
            : {
                for (final t in st.trilhas)
                  for (final l in t.licoes)
                    if (l.id.isNotEmpty && escolha.contains(l.id)) l.id,
              };
        final daEscolha = escolha == null || st == null
            ? const <String>{}
            : {for (final (w, _) in cubit.palavrasDasLicoes(st, idsEscolhidos)) w.toLowerCase()};
        bool daLicao(String w) {
          if (escolha != null) return daEscolha.contains(w.toLowerCase());
          final l = ind?.primeiraLicao[w.toLowerCase()];
          return l != null && st != null && st.concluidas.contains(l);
        }

        bool suaDela(String w) {
          final p = banco[w];
          return p != null && !p.removida && p.origem != OrigemPalavra.licao;
        }

        final k = todas.where(suaDela).length;
        final n = todas.where((w) => !suaDela(w) && daLicao(w)).length;
        final destaque = <String>[
          ...todas.where((w) => v!.emFoco(w)),
          ...todas.where((w) => !v!.emFoco(w) && (suaDela(w) || daLicao(w))),
          ...todas.where((w) => !v!.emFoco(w) && !suaDela(w) && !daLicao(w)),
        ].where((w) => v!.traducao(w) != null).take(6).toList();
        final devidas = cubit.devidasHoje;
        final m = devidas.length;
        final nl = idsEscolhidos.length;
        final poucas = v == null || escolha == null ? null : avisoPoucasPalavras(v);
        final suas = k > 0 ? ' + $k ${k == 1 ? 'palavra sua' : 'palavras suas'}' : '';
        final linha = v == null
            ? 'Preparando as palavras das suas lições…'
            : escolha != null
                ? 'Jogando com $n palavra${n == 1 ? '' : 's'} de $nl ${nl == 1 ? 'lição escolhida' : 'lições escolhidas'}'
                    '$suas${poucas == null ? '' : ' — ${poucas.alerta ? 'poucas palavras' : 'poucas longas (9+ letras)'}: '
                        'completei com ${poucas.quantas} das mais usadas'}'
                : n + k == 0
                    ? 'Jogando com as palavras mais usadas do inglês — cada lição concluída põe as palavras dela aqui 🎮'
                    : 'Jogando com $n palavra${n == 1 ? '' : 's'} das suas lições$suas';
        final rotuloLicoes = escolha == null ? '📚 Palavras: Automático' : '📚 Palavras: $nl ${nl == 1 ? 'lição' : 'lições'}';
        final List<PalavraNova> paraTreinar = m > 0
            ? [for (final p in devidas.take(8)) p.comoPalavraNova]
            : st == null
                ? const []
                : treinoSemDevidas(cubit, st);
        final teimosas = cubit.teimosas();
        return Container(
          key: const Key('arcade-minhas-palavras'),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: Mixart.brandDim, width: 1.4),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
            gradient: LinearGradient(colors: [Mixart.brandSub, Mixart.surface]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('📚', style: TextStyle(fontSize: 34)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Minhas palavras', style: Mixart.display(size: 19)),
                  const SizedBox(height: 4),
                  Text(linha, style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.45)),
                ]),
              ),
            ]),
            if (destaque.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final w in destaque) _chipPalavra(w, v!.traducao(w)!, foco: v.emFoco(w)),
              ]),
            ],
            if (teimosas.isNotEmpty) ...[
              const SizedBox(height: 12),
              _linhaTeimosas(teimosas, cubit.quantasTeimosas),
            ],
            const SizedBox(height: 14),
            // IntrinsicWidth: o Botao3D sem expandir ainda ocupa a largura toda dentro de um Wrap
            Wrap(spacing: 10, runSpacing: 10, children: [
              IntrinsicWidth(
                child: Tooltip(
                  message: 'Escolher de quais lições vêm as palavras dos jogos',
                  child: Botao3D(
                    key: const Key('arcade-escolher-licoes'),
                    rotulo: rotuloLicoes,
                    contorno: true,
                    // expandir dentro do IntrinsicWidth: a largura do rótulo, mas encolhe (com "…") no
                    // celular estreito em vez de estourar
                    expandir: true,
                    altura: 40,
                    tamanhoTexto: 13,
                    onTap: st == null
                        ? null
                        : () => abrirEscolherLicoes(context).then((_) {
                              if (mounted) setState(() {});
                            }),
                  ),
                ),
              ),
              IntrinsicWidth(
                child: Botao3D(
                  key: const Key('arcade-gerenciar-palavras'),
                  rotulo: 'Gerenciar',
                  icone: Icons.tune_rounded,
                  contorno: true,
                  expandir: false,
                  altura: 40,
                  tamanhoTexto: 13,
                  onTap: () => abrirMinhasPalavras(context).then((_) {
                    if (mounted) setState(() {});
                  }),
                ),
              ),
              IntrinsicWidth(
                child: Botao3D(
                  key: const Key('arcade-revisar-palavras'),
                  rotulo: m > 0 ? '🎯 Revisar ($m)' : '🎯 Treinar',
                  expandir: false,
                  altura: 40,
                  tamanhoTexto: 13,
                  onTap: paraTreinar.isEmpty
                      ? null
                      : () => abrirTreinoPalavras(context, paraTreinar,
                              titulo: m > 0 ? 'Revisão do dia' : 'Treino de palavras')
                          .then((_) {
                            if (mounted) setState(() {});
                          }),
                ),
              ),
            ]),
          ]),
        );
      },
    );
  }

  /// '🔥 N teimosas · a mais teimosa: through (6x)' (com 1: '🔥 1 teimosa: through (6x)') e o
  /// "🔥 Revanche" (o treino só com elas — não confundir com o "🎯 Treinar" do banco logo abaixo).
  Widget _linhaTeimosas(List<PalavraDoBanco> teimosas, int n) {
    final top = teimosas.first;
    final cor = escurecer(CoresFesta.coral, quanto: .2, soNoClaro: true);
    return Container(
      key: const Key('arcade-teimosas'),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(cor.withValues(alpha: .08), Mixart.surface),
        border: Border.all(color: cor.withValues(alpha: .5)),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Row(children: [
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: n == 1 ? '🔥 1 teimosa: ' : '🔥 $n teimosas · a mais teimosa: '),
              TextSpan(
                  text: top.en, style: Mixart.mono(size: 12.5, weight: FontWeight.w800, color: Mixart.text)),
              TextSpan(text: ' (${vezesDe(top)}x)'),
            ]),
            style: Mixart.ui(size: 12.5, weight: FontWeight.w600, color: Mixart.textMuted).copyWith(height: 1.4),
          ),
        ),
        const SizedBox(width: 8),
        Botao3D(
          key: const Key('arcade-treinar-teimosas'),
          rotulo: '🔥 Revanche',
          cor: cor,
          corTexto: corSobre(cor),
          expandir: false,
          altura: 36,
          tamanhoTexto: 12.5,
          onTap: () => treinarTeimosas(context, [for (final p in teimosas) p.chave], origem: 'arcade').then((_) {
            if (mounted) setState(() {});
          }),
        ),
      ]),
    );
  }

  Widget _chipPalavra(String en, String pt, {bool foco = false}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Mixart.surfaceHi,
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        border: Border.all(color: foco ? Mixart.brand : Mixart.border),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(en,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Mixart.mono(size: 13, weight: FontWeight.w700, color: Mixart.text)),
        Text(pt,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Mixart.ui(size: 10.5, weight: FontWeight.w600, color: Mixart.textMuted)),
      ]),
    );
  }

  static final _jogos = [
    (
      id: 'turismo',
      emoji: '🏎️',
      nome: 'Dart Turismo',
      tag: 'DIGITAÇÃO',
      descricao: 'Campeonato de 10 pistas em 3D: digite a palavra da faixa livre pra '
          'fazer a curva. Cada tecla acelera — parar de digitar é ir parando. '
          'Ouro, prata ou bronze no relógio.',
      abre: (BuildContext c) => const TurismoPage(),
    ),
    (
      id: 'chuva',
      emoji: '☄️',
      nome: 'Chuva de Código',
      tag: 'DIGITAÇÃO',
      descricao: 'Palavras do Dart despencam do céu e o Pac atira pela boca: '
          'cada letra digitada é um tiro. Sem errar, o COMBO multiplica os pontos!',
      abre: (BuildContext c) => const ChuvaPage(),
    ),
    (
      id: 'rali',
      emoji: '🏁',
      nome: 'Rali de Digitação',
      tag: 'DIGITAÇÃO',
      descricao: 'Cada palavra digitada acelera seu personagem — palavra perfeita '
          'dá TURBO. O medidor mostra quando a CPU vai andar: fique na frente!',
      abre: (BuildContext c) => const RaliPage(),
    ),
    (
      id: 'corrida',
      emoji: '🚗',
      nome: 'Corrida do Código',
      tag: 'LÓGICA',
      descricao: 'Preveja o que o código imprime para acelerar. Responda com a '
          'barra do TURBO cheia pra dobrar o passo — as fases sobem de nível.',
      abre: (BuildContext c) => const CorridaPage(),
    ),
    (
      id: 'futebol',
      emoji: '⚽',
      nome: 'Gol de Dart',
      tag: 'SINTAXE',
      descricao: 'Cinco pênaltis: complete a peça que falta no código e '
          'escolha o canto. Errou a sintaxe? O goleiro agradece.',
      abre: (BuildContext c) => const FutebolPage(),
    ),
    (
      id: 'cacaBug',
      emoji: '🐞',
      nome: 'Caça-Bug',
      tag: 'ATENÇÃO',
      descricao: 'Uma linha do trecho está estragada. Ache e esmague o bug '
          'antes de o relógio zerar — segundos sobrando viram bônus.',
      abre: (BuildContext c) => const CacaBugPage(),
    ),
  ];

  /// "Gol de Dart" vira "Gol de C#" na vertente C# (e o resto dos textos).
  static String _naVertente(String texto) {
    if (BancoArcade.linguagem == 'Dart') return texto;
    if (BancoArcade.soDigitacao) {
      texto = texto
          .replaceAll('Chuva de Código', 'Chuva de Palavras')
          .replaceAll('Palavras do Dart', 'Palavras em inglês');
    }
    return texto.replaceAll('Dart', BancoArcade.linguagem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
              children: [
                CabecalhoJogo(
                    rotulo: 'PACLINGO · ${BancoArcade.linguagem.toUpperCase()}',
                    titulo: '🎮 Arcade ${BancoArcade.linguagem}'),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Mixart.brandSub,
                    border: Border.all(color: Mixart.brandDim),
                    borderRadius: BorderRadius.circular(Mixart.radiusMd),
                  ),
                  child: Text(
                    BancoArcade.soDigitacao
                        ? 'Jogue com as palavras das SUAS lições (e as que você guardou), com a tradução '
                            'embaixo de cada uma: cada palavra digitada acelera, atira ou faz a curva. '
                            'Vença as fases e acumule pontos no seu ranking 🏆 — o recorde de cada jogo '
                            'fica guardado. Esc pausa qualquer jogo.'
                        : 'Treine a lógica e a sintaxe do ${BancoArcade.linguagem} jogando. Vença as fases, '
                    'viaje pelos cenários e acumule pontos no seu ranking 🏆 — o '
                    'recorde pessoal de cada jogo fica guardado. Esc pausa qualquer '
                    'jogo (e sair da aba pausa sozinho).',
                    style: Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.55),
                  ),
                ),
                const SizedBox(height: 18),
                _seletorPersonagem(),
                const SizedBox(height: 18),
                if (!BancoArcade.soDigitacao) ...[
                  _cartaoMissoes(),
                  const SizedBox(height: 12),
                ] else if (_palavras != null) ...[
                  _cartaoMinhasPalavras(_palavras!),
                  const SizedBox(height: 12),
                ],
                _cartoes(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cartão de destaque do modo missões (Lógica Animada).
  Widget _cartaoMissoes() {
    return Material(
      color: Mixart.surface,
      borderRadius: BorderRadius.circular(Mixart.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const MissoesPage()))
            .then((_) => _ranking?.carregarTop()),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: Mixart.brandDim, width: 1.4),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
            gradient: LinearGradient(colors: [Mixart.brandSub, Mixart.surface]),
          ),
          child: Row(children: [
            const Text('🗺️', style: TextStyle(fontSize: 38)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text('Lógica Animada', style: Mixart.display(size: 19))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Mixart.brand, borderRadius: BorderRadius.circular(999)),
                    child: Text('NOVO',
                        style:
                            Mixart.ui(size: 9, weight: FontWeight.w800, color: Mixart.onBrand)
                                .copyWith(letterSpacing: 1)),
                  ),
                ]),
                const SizedBox(height: 5),
                Text(
                  'Missões sem fim, trilha a trilha: preveja a lógica, digite o '
                  'código pra destravar a cena e assista ele rodar animado — com '
                  '🔮 Ajuda Misteriosa pra quando bater dúvida.',
                  style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            Icon(Icons.play_circle_fill, size: 34, color: Mixart.brand),
          ]),
        ),
      ),
    );
  }

  Widget _seletorPersonagem() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SEU PERSONAGEM',
          style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.textMuted)
              .copyWith(letterSpacing: 2)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final p in Personagem.values) _cartaoPersonagem(p),
      ]),
    ]);
  }

  /// O personagem com o mouse em cima (só ele mastiga): parado, o hub não pede frame nenhum.
  Personagem? _sobre;

  Widget _cartaoPersonagem(Personagem p) {
    final escolhido = PersonagemStore.atual == p;
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = p),
      onExit: (_) {
        if (_sobre == p) setState(() => _sobre = null);
      },
      child: Material(
      color: Mixart.surface,
      borderRadius: BorderRadius.circular(Mixart.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        onTap: () {
          PersonagemStore.trocar(p);
          setState(() {});
        },
        child: Container(
          width: 250,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
                color: escolhido ? Mixart.brand : Mixart.border, width: escolhido ? 1.8 : 1),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Row(children: [
            RepaintBoundary(child: AvatarPersonagem(tamanho: 40, personagem: p, animado: _sobre == p)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.rotulo, style: Mixart.display(size: 15)),
                const SizedBox(height: 2),
                Text(p.descricao, style: Mixart.ui(size: 11, color: Mixart.textMuted)),
              ]),
            ),
            if (escolhido) Icon(Icons.check_circle, size: 18, color: Mixart.brand),
          ]),
        ),
      ),
      ),
    );
  }

  Widget _cartoes() {
    final cubit = _ranking;
    return LayoutBuilder(builder: (context, box) {
      final colunas = box.maxWidth >= 900
          ? 3
          : box.maxWidth >= 600
              ? 2
              : 1;
      final largura = (box.maxWidth - (colunas - 1) * 12) / colunas;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        for (final j in _jogos)
          if (!BancoArcade.soDigitacao || j.tag == 'DIGITAÇÃO') SizedBox(width: largura, child: _cartao(j, cubit)),
      ]);
    });
  }

  Widget _cartao(
      ({
        String id,
        String emoji,
        String nome,
        String tag,
        String descricao,
        Widget Function(BuildContext) abre,
      }) jogo,
      RankingCubit? cubit) {
    return CartaoInclinavel(
      raio: BorderRadius.circular(Mixart.radiusLg),
      child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Mixart.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: jogo.abre))
            .then((_) => _ranking?.carregarTop()),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Mixart.surfaceHi, Mixart.surface],
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(jogo.emoji,
                  style: const TextStyle(fontSize: 34, shadows: [
                    Shadow(color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 5)),
                  ])),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Mixart.surfaceHi,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Mixart.border),
                ),
                child: Text(jogo.tag,
                    style: Mixart.ui(size: 9.5, weight: FontWeight.w700, color: Mixart.brand)
                        .copyWith(letterSpacing: 1.4)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(_naVertente(jogo.nome), style: Mixart.display(size: 18)),
            const SizedBox(height: 6),
            Text(_naVertente(jogo.descricao),
                style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: cubit == null
                    ? const SizedBox.shrink()
                    : BlocBuilder<RankingCubit, RankingState>(
                        bloc: cubit,
                        builder: (context, st) {
                          final recorde = st.meu(cubit.uid)?.recordeDoJogo(jogo.id) ?? 0;
                          return Row(children: [
                            Icon(Icons.workspace_premium_outlined,
                                size: 14, color: Mixart.textMuted),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                  recorde > 0 ? 'recorde: $recorde pts' : 'sem recorde ainda',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
                            ),
                          ]);
                        },
                      ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: Mixart.brand,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.play_arrow_rounded, size: 16, color: Mixart.onBrand),
                  const SizedBox(width: 4),
                  Text('Jogar',
                      style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.onBrand)),
                ]),
              ),
            ]),
          ]),
        ),
      ),
      ),
    );
  }
}
