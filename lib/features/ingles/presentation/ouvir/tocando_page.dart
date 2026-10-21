import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../../curso/presentation/bloc/curso_bloc.dart';
import '../../data/voz_ingles.dart';
import '../../domain/config_ouvir.dart';
import '../../domain/fila_ouvir.dart';
import '../../domain/setlist.dart';
import 'mini_player.dart';
import 'ouvir_acoes.dart';
import 'ouvir_cubit.dart';
import 'ouvir_state.dart';
import 'widgets/chips_ouvir.dart';

/// Onde a faixa [i] está: lição [licao] de [licoes] e frase [frase] de [frases] dentro dela. Uma lição
/// começa onde a faixa diz `primeiraDaLicao` ou onde muda o `licaoId`.
({int licao, int licoes, int frase, int frases}) posicaoNaFila(List<Faixa> fila, int i) {
  if (fila.isEmpty) return (licao: 0, licoes: 0, frase: 0, frases: 0);
  final inicios = _inicios(fila);
  final idx = i.clamp(0, fila.length - 1);
  // a última lição que começa em ou antes de idx (busca binária)
  var lo = 0, hi = inicios.length - 1;
  while (lo < hi) {
    final meio = (lo + hi + 1) >> 1;
    if (inicios[meio] <= idx) {
      lo = meio;
    } else {
      hi = meio - 1;
    }
  }
  final comeco = inicios[lo];
  final fim = lo + 1 < inicios.length ? inicios[lo + 1] : fila.length;
  return (licao: lo + 1, licoes: inicios.length, frase: idx - comeco + 1, frases: fim - comeco);
}

final _memoInicios = Expando<List<int>>('iniciosDasLicoes');

List<int> _inicios(List<Faixa> fila) => _memoInicios[fila] ??= [
      for (var i = 0; i < fila.length; i++)
        if (i == 0 || fila[i].primeiraDaLicao || fila[i].licaoId != fila[i - 1].licaoId) i,
    ];

/// "Mike", "Você", "Dra. Lee"; null = narrador.
String? nomeDeQuem(String quem) {
  if (quem.isEmpty) return null;
  if (quem == 'voce') return 'Você';
  if (quem == 'dra-lee') return 'Dra. Lee';
  final limpo = quem.replaceAll('-', ' ');
  return limpo[0].toUpperCase() + limpo.substring(1);
}

/// O aviso da tela para o estado [st] (pausa por outra fala, sem som, timer, fim), ou null.
String? textoDoAviso(OuvirState st) {
  if (st.status == StatusOuvir.acabou) {
    final n = st.ouvidas;
    return 'Fim de «${st.fonte?.titulo ?? ''}» 🎉 Você ouviu ${n == 1 ? '1 frase' : '${milhar(n)} frases'}.';
  }
  if (st.status != StatusOuvir.pausado) return null;
  return switch (st.motivo) {
    MotivoPausa.outraFala => 'Pausado: outra fala começou. ▶ para continuar.',
    MotivoPausa.semSom => 'Não consegui tocar o som. Toque ▶ para tentar de novo.',
    MotivoPausa.timer => 'Timer acabou — até amanhã! 🌙',
    _ => null,
  };
}

/// "Tocando agora": o rosto de quem fala, a frase grande, a tradução, a fase, o progresso, os controles
/// (⏮ ⏪ ⏯ ⏩ ⏭ ↺), os ajustes e "A seguir". Teclado (só com a tela no topo): espaço toca/pausa, ←/→ frase
/// anterior/próxima, R repete, Esc minimiza. A partir de 900 px, duas colunas.
class TocandoPage extends StatefulWidget {
  const TocandoPage({super.key});

  @override
  State<TocandoPage> createState() => _TocandoPageState();
}

class _TocandoPageState extends State<TocandoPage> {
  OuvirCubit? _cubit;
  final _foco = FocusNode(debugLabel: 'tocando-agora');
  bool _aSeguirAberto = false;

  @override
  void initState() {
    super.initState();
    _cubit = OuvirCubit.de(context);
    _cubit?.telaCheia(true);
  }

  @override
  void dispose() {
    final c = _cubit;
    if (c != null && !c.isClosed) c.telaCheia(false);
    _foco.dispose();
    super.dispose();
  }

  void _alternar(OuvirCubit c) {
    final st = c.state;
    final fonte = st.fonte;
    if (st.status == StatusOuvir.acabou && fonte != null) {
      unawaited(c.tocar(fonte, st.fila));
    } else if (st.status != StatusOuvir.parado) {
      c.alternar();
    }
  }

  KeyEventResult _tecla(FocusNode _, KeyEvent e) {
    final c = _cubit;
    if (c == null || e is! KeyDownEvent) return KeyEventResult.ignored;
    if (!(ModalRoute.isCurrentOf(context) ?? false)) return KeyEventResult.ignored;
    final k = e.logicalKey;
    // com o foco num chip/botão/linha (Tab), espaço ativa ELE e ←/→ andam o foco: os atalhos só valem com o
    // foco na própria tela. Esc minimiza de qualquer lugar.
    if (!_foco.hasPrimaryFocus && k != LogicalKeyboardKey.escape) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.space) {
      _alternar(c);
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      c.anterior();
    } else if (k == LogicalKeyboardKey.arrowRight) {
      c.proxima();
    } else if (k == LogicalKeyboardKey.keyR) {
      c.repetirAtual();
    } else if (k == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _praticar(OuvirCubit c, Faixa f) {
    final trilhas = trilhasDoCurso(context);
    final pos = IndiceOuvir.de(trilhas).licao(f.licaoId);
    if (pos == null) return;
    if (c.state.status == StatusOuvir.tocando) c.pausar();
    final curso = context.read<CursoBloc>();
    curso.add(TrilhaSelecionada(pos.t));
    curso.add(LicaoSelecionada(pos.l));
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final c = _cubit;
    if (c == null) return Scaffold(backgroundColor: Mixart.bg);
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Focus(
          focusNode: _foco,
          autofocus: true,
          onKeyEvent: _tecla,
          child: BlocConsumer<OuvirCubit, OuvirState>(
            bloc: c,
            listenWhen: (a, b) => textoDoAviso(a) != textoDoAviso(b),
            listener: (context, st) {
              final t = textoDoAviso(st);
              if (t != null) {
                unawaited(SemanticsService.sendAnnouncement(View.of(context), t, TextDirection.ltr));
              }
            },
            builder: (context, st) => LayoutBuilder(builder: (context, cons) {
              final largo = cons.maxWidth >= 900;
              if (st.fila.isEmpty || st.status == StatusOuvir.parado) return _nadaTocando(context);
              if (largo) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Column(children: [
                    _topo(context, st),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(key: const Key('ouvir-duas-colunas'), crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 24, right: 12),
                            child: _player(context, c, st, largo: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Mixart.surface,
                              borderRadius: BorderRadius.circular(Mixart.radiusLg),
                              border: Border.all(color: Mixart.border),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                                child: Text('A seguir', style: Mixart.display(size: 16)),
                              ),
                              Expanded(child: _listaASeguir(c, st, rolavel: true)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _topo(context, st),
                      const SizedBox(height: 8),
                      _player(context, c, st, largo: false),
                      const SizedBox(height: 14),
                      _aSeguirRecolhivel(c, st),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _nadaTocando(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _botaoMinimizar(context),
          const SizedBox(height: 24),
          Text('Nada tocando agora.', style: Mixart.ui(size: 14, color: Mixart.textMuted)),
        ]),
      );

  Widget _botaoMinimizar(BuildContext context) => IconButton(
        key: const Key('ouvir-minimizar'),
        tooltip: 'Minimizar',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Mixart.text, size: 26),
        style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
      );

  Widget _topo(BuildContext context, OuvirState st) {
    final p = posicaoNaFila(st.fila, st.indice);
    return Row(children: [
      _botaoMinimizar(context),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(st.fonte?.titulo ?? '',
              key: const Key('ouvir-fonte'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Mixart.display(size: 17)),
          const SizedBox(height: 2),
          Text('Lição ${p.licao} de ${p.licoes} · Frase ${p.frase} de ${p.frases}',
              key: const Key('ouvir-posicao'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
        ]),
      ),
    ]);
  }

  Widget _player(BuildContext context, OuvirCubit c, OuvirState st, {required bool largo}) {
    final f = st.atual!;
    final cfg = st.config;
    final nome = nomeDeQuem(f.quem);
    final trilha = [f.etapa.isEmpty ? '' : ItemSetlist.codigoEtapa(f.etapa), f.trilhaNome, f.licaoNome]
        .where((s) => s.isNotEmpty)
        .join(' › ');
    // Português → inglês: o inglês fica escondido enquanto a pessoa pensa
    final escondeEn = cfg.modo == ModoOuvir.portuguesIngles &&
        st.status == StatusOuvir.tocando &&
        (st.fase == FaseOuvir.traducao || st.fase == FaseOuvir.pense);
    final mostraPt = f.pt.isNotEmpty && (cfg.mostrarTraducao || cfg.modo == ModoOuvir.portuguesIngles);
    final aviso = textoDoAviso(st);
    final temLicao = f.licaoId.isNotEmpty && IndiceOuvir.de(trilhasDoCurso(context)).licao(f.licaoId) != null;
    final total = st.fila.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 8),
      Center(child: RostoDaFaixa(faixa: f, tamanho: largo ? 140 : 96)),
      if (nome != null) ...[
        const SizedBox(height: 6),
        Text(nome, textAlign: TextAlign.center, style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.textMuted)),
      ],
      if (trilha.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(trilha,
            key: const Key('ouvir-trilha'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Mixart.ui(size: 12, color: Mixart.textFaint)),
      ],
      const SizedBox(height: 14),
      Text(
        escondeEn ? '…' : f.en,
        key: const Key('ouvir-en'),
        textAlign: TextAlign.center,
        semanticsLabel: escondeEn ? 'Pense: como se diz em inglês?' : null,
        style: Mixart.display(size: largo ? 32 : 26).copyWith(height: 1.25),
      ),
      if (mostraPt) ...[
        const SizedBox(height: 8),
        Text(f.pt,
            key: const Key('ouvir-pt'),
            textAlign: TextAlign.center,
            style: Mixart.ui(size: largo ? 17 : 15, color: Mixart.textMuted).copyWith(height: 1.35)),
      ],
      const SizedBox(height: 14),
      Center(child: ChipFase(key: const Key('ouvir-fase'), fase: st.fase, vez: st.vez, de: st.de)),
      const SizedBox(height: 16),
      Text('Frase ${milhar(st.indice + 1)} de ${milhar(total)} · faltam ~${formatarDuracao(st.restanteSeg)}',
          key: const Key('ouvir-progresso'),
          textAlign: TextAlign.center,
          style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : ((st.indice + 1) / total).clamp(0.0, 1.0),
          minHeight: 5,
          color: Mixart.brand,
          backgroundColor: Mixart.surfaceHi,
        ),
      ),
      const SizedBox(height: 12),
      _controles(c, st),
      if (aviso != null) ...[
        const SizedBox(height: 10),
        _Aviso(
          chave: switch ((st.status, st.motivo)) {
            (StatusOuvir.acabou, _) => 'ouvir-banner-fim',
            (_, MotivoPausa.outraFala) => 'ouvir-banner-outra-fala',
            (_, MotivoPausa.semSom) => 'ouvir-banner-sem-som',
            _ => 'ouvir-banner-timer',
          },
          texto: aviso,
          acao: st.status == StatusOuvir.acabou && st.fonte != null
              ? ('Tocar de novo', () => unawaited(c.tocar(st.fonte!, st.fila)))
              : null,
        ),
      ],
      const SizedBox(height: 16),
      ChipsOuvir(
        config: cfg,
        desligar: st.desligar,
        onConfig: c.configurar,
        onDesligar: c.desligarEm,
      ),
      if (cfg.modo != ModoOuvir.soIngles) ...[
        const SizedBox(height: 6),
        FutureBuilder<bool>(
          future: VozIngles.temVozPt(),
          builder: (_, snap) => Text(
            snap.data == false
                ? 'Seu navegador não tem voz em português — a tradução aparece só na tela.'
                : 'Com a tela apagada, o português pode não tocar. Use «Só inglês».',
            key: Key(snap.data == false ? 'ouvir-aviso-sem-pt' : 'ouvir-aviso-tela-apagada'),
            style: Mixart.ui(size: 11.5, color: Mixart.textFaint),
          ),
        ),
      ],
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _BotaoAcao(
          chave: 'ouvir-por-frase',
          icone: Icons.playlist_add_rounded,
          rotulo: 'Pôr esta frase na setlist',
          onTap: () => unawaited(porNaSetlist(context, itemDaFaixa(context, f))),
        ),
        if (temLicao)
          _BotaoAcao(
            chave: 'ouvir-praticar',
            icone: Icons.keyboard_rounded,
            rotulo: 'Praticar esta lição',
            onTap: () => _praticar(c, f),
          ),
      ]),
    ]);
  }

  Widget _controles(OuvirCubit c, OuvirState st) {
    final tocando = st.status == StatusOuvir.tocando;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _Controle(chave: 'ouvir-licao-anterior', rotulo: 'Lição anterior', icone: Icons.skip_previous_rounded, onTap: c.licaoAnterior),
          _Controle(chave: 'ouvir-anterior', rotulo: 'Frase anterior', icone: Icons.fast_rewind_rounded, onTap: c.anterior),
          SizedBox(
            width: 64,
            height: 64,
            child: IconButton.filled(
              key: const Key('ouvir-play'),
              tooltip: tocando ? 'Pausar' : 'Tocar',
              onPressed: () => _alternar(c),
              style: IconButton.styleFrom(backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
              icon: Icon(tocando ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 36, color: Mixart.onBrand),
            ),
          ),
          _Controle(chave: 'ouvir-proxima', rotulo: 'Próxima frase', icone: Icons.fast_forward_rounded, onTap: c.proxima),
          _Controle(chave: 'ouvir-proxima-licao', rotulo: 'Próxima lição', icone: Icons.skip_next_rounded, onTap: c.proximaLicao),
          _Controle(chave: 'ouvir-repetir', rotulo: 'Repetir frase', icone: Icons.replay_rounded, onTap: c.repetirAtual),
        ]),
      ),
    );
  }

  Widget _aSeguirRecolhivel(OuvirCubit c, OuvirState st) {
    final restam = st.fila.length - st.indice - 1;
    if (restam <= 0) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Mixart.surface,
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        border: Border.all(color: Mixart.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InkWell(
            key: const Key('ouvir-a-seguir'),
            onTap: () => setState(() => _aSeguirAberto = !_aSeguirAberto),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Expanded(child: Text('A seguir', style: Mixart.display(size: 16))),
                  Icon(_aSeguirAberto ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Mixart.textMuted),
                ]),
              ),
            ),
          ),
          if (_aSeguirAberto) _listaASeguir(c, st, rolavel: false),
        ]),
      ),
    );
  }

  /// As próximas 20 frases; tocar numa pula para ela.
  Widget _listaASeguir(OuvirCubit c, OuvirState st, {required bool rolavel}) {
    final inicio = st.indice + 1;
    final n = (st.fila.length - inicio).clamp(0, 20);
    if (n == 0) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('É a última frase.', style: Mixart.ui(size: 13, color: Mixart.textMuted)),
      );
    }
    return ListView.builder(
      key: const Key('ouvir-a-seguir-lista'),
      shrinkWrap: !rolavel,
      physics: rolavel ? null : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: n,
      itemBuilder: (context, k) {
        final i = inicio + k;
        final f = st.fila[i];
        return InkWell(
          key: Key('a-seguir-$i'),
          onTap: () => c.irPara(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              SizedBox(
                width: 36,
                child: Text('${i + 1}', style: Mixart.ui(size: 11.5, weight: FontWeight.w700, color: Mixart.textFaint)),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (f.primeiraDaLicao && f.licaoNome.isNotEmpty)
                    Text('${f.licaoEmoji.isEmpty ? '' : '${f.licaoEmoji} '}${f.licaoNome}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.brand)),
                  Text(f.en,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mixart.ui(size: 13.5, weight: FontWeight.w600, color: Mixart.text)),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _Controle extends StatelessWidget {
  final String chave, rotulo;
  final IconData icone;
  final VoidCallback onTap;
  const _Controle({required this.chave, required this.rotulo, required this.icone, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        key: Key(chave),
        tooltip: rotulo,
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: Icon(icone, size: 28, color: Mixart.text),
      );
}

class _BotaoAcao extends StatelessWidget {
  final String chave, rotulo;
  final IconData icone;
  final VoidCallback onTap;
  const _BotaoAcao({required this.chave, required this.rotulo, required this.icone, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        key: Key(chave),
        onPressed: onTap,
        icon: Icon(icone, size: 19, color: Mixart.brand),
        label: Text(rotulo, style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.text)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: BorderSide(color: Mixart.border),
          backgroundColor: Mixart.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
        ),
      );
}

class _Aviso extends StatelessWidget {
  final String chave, texto;
  final (String, VoidCallback)? acao;
  const _Aviso({required this.chave, required this.texto, this.acao});

  @override
  Widget build(BuildContext context) => Container(
        key: Key(chave),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: Mixart.brandSub,
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          border: Border.all(color: Mixart.brandDim),
        ),
        child: Row(children: [
          Expanded(
            child: Text(texto, style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.text).copyWith(height: 1.35)),
          ),
          if (acao case (final rotulo, final onTap))
            TextButton(
              key: const Key('ouvir-tocar-de-novo'),
              onPressed: onTap,
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              child: Text(rotulo, style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: Mixart.brand)),
            ),
        ]),
      );
}
