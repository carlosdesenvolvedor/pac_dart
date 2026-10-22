import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../../curso/domain/curriculo.dart';
import '../../../curso/presentation/bloc/curso_bloc.dart';
import '../../data/preferencia_assistir.dart';
import '../../data/voz_ingles.dart';
import '../../domain/assistir/historias_licoes.dart';
import '../../domain/config_ouvir.dart';
import '../../domain/fila_ouvir.dart';
import '../../domain/setlist.dart';
import 'assistir/palco_assistir.dart';
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
///
/// 📺 "Escutar assistindo" (`ouvir-assistir`, na linha da fase): troca a foto da cena pelo desenho animado
/// da lição ([PalcoAssistir]), que segue o player; ⛶ põe o desenho na tela inteira com uma barra compacta
/// (Esc sai da tela cheia; o 2º Esc minimiza). Começa desligado e é lembrado ([PreferenciaAssistir]).
class TocandoPage extends StatefulWidget {
  /// true = abre já no 📺; false = na foto; null = como a pref manda (lida de forma síncrona, sem piscar).
  final bool? assistir;

  const TocandoPage({super.key, this.assistir});

  @override
  State<TocandoPage> createState() => _TocandoPageState();
}

class _TocandoPageState extends State<TocandoPage> {
  OuvirCubit? _cubit;
  final _foco = FocusNode(debugLabel: 'tocando-agora');
  bool _aSeguirAberto = false;

  /// 📺 ligado (o palco no lugar da foto).
  late bool _assistir;

  /// ⛶ o desenho na tela inteira.
  bool _palcoGrande = false;

  /// O selo "novo" do botão 📺 (até o 1º uso).
  bool _novidade = false;
  bool _usouAssistir = false;

  /// O palco sobrevive à troca de layout de 900 px e ao ⛶ (D17).
  final _chavePalco = GlobalKey(debugLabel: 'palco-assistir');
  ({Widget palco, bool grande, List<Trilha> trilhas})? _palcoMemo;

  @override
  void initState() {
    super.initState();
    _cubit = OuvirCubit.de(context);
    _cubit?.telaCheia(true);
    _assistir = widget.assistir ?? PreferenciaAssistir.valor.value;
    PreferenciaAssistir.valor.addListener(_mudouPref);
    unawaited(_verNovidade());
    final f = _cubit?.state.atual;
    if (_assistir && f != null) unawaited(HistoriasLicoes.de(trilhasDoCurso(context)).preparar(f));
  }

  @override
  void dispose() {
    PreferenciaAssistir.valor.removeListener(_mudouPref);
    final c = _cubit;
    if (c != null && !c.isClosed) c.telaCheia(false);
    _foco.dispose();
    super.dispose();
  }

  Future<void> _verNovidade() async {
    final n = await PreferenciaAssistir.mostrarNovidade();
    if (!mounted || _usouAssistir || n == _novidade) return;
    setState(() => _novidade = n);
  }

  /// Um botão 📺 da playlist (ou outra tela) ligou a pref com este player já aberto: ele segue o pedido.
  void _mudouPref() {
    final v = PreferenciaAssistir.valor.value;
    if (!mounted || v == _assistir) return;
    setState(() {
      _assistir = v;
      if (!v) _palcoGrande = false;
    });
  }

  void _alternarAssistir() {
    final v = !_assistir;
    setState(() {
      _assistir = v;
      if (!v) _palcoGrande = false;
      _usouAssistir = true;
      _novidade = false;
    });
    unawaited(PreferenciaAssistir.salvar(v));
    unawaited(PreferenciaAssistir.marcarNovidadeVista());
    final f = _cubit?.state.atual;
    if (v && f != null) unawaited(HistoriasLicoes.de(trilhasDoCurso(context)).preparar(f));
  }

  void _alternarTelaCheia() {
    if (!mounted) return;
    setState(() => _palcoGrande = !_palcoGrande);
  }

  /// O ⛶ está na tela agora (com o player andando e o 📺 ligado).
  bool _emTelaCheia(OuvirState st) =>
      _palcoGrande && _assistir && st.fila.isNotEmpty && st.status != StatusOuvir.parado && st.atual != null;

  /// O [PalcoAssistir] com a [GlobalKey] do State. O mesmo widget volta enquanto nada muda, então os
  /// rebuilds do player (a cada emit) não reconstroem o palco.
  Widget _palco(OuvirCubit c, {required bool grande}) {
    final trilhas = trilhasDoCurso(context);
    final m = _palcoMemo;
    if (m != null && m.grande == grande && identical(m.trilhas, trilhas)) return m.palco;
    final palco = PalcoAssistir(
      key: _chavePalco,
      cubit: c,
      trilhas: trilhas,
      grande: grande,
      // no ⛶ a saída é o botão da barra compacta (um só "sair da tela cheia" na tela)
      onTelaCheia: grande ? null : _alternarTelaCheia,
    );
    _palcoMemo = (palco: palco, grande: grande, trilhas: trilhas);
    return palco;
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
      // no ⛶, o Esc só sai da tela cheia; o 2º minimiza
      if (_emTelaCheia(c.state)) {
        setState(() => _palcoGrande = false);
      } else {
        Navigator.of(context).maybePop();
      }
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
              if (_emTelaCheia(st)) {
                // o voltar do sistema também só sai da tela cheia
                return PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop && mounted) setState(() => _palcoGrande = false);
                  },
                  child: _palcoCheio(context, c, st),
                );
              }
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
    final escondeEn = escondeIngles(st);
    final mostraPt = mostraTraducao(f, cfg);
    final comImagem = cfg.mostrarImagens && f.temImagem;
    final aviso = textoDoAviso(st);
    final trilhas = trilhasDoCurso(context);
    final temLicao = f.licaoId.isNotEmpty && IndiceOuvir.de(trilhas).licao(f.licaoId) != null;
    final total = st.fila.length;
    // 📺: o palco entra no lugar da foto (com "Imagens" desligado e sem foto também); faixa sem lição do
    // curso mostra a foto de sempre com um aviso (D14)
    final podeAssistir = PalcoAssistir.podeAssistir(f, trilhas);
    final comPalco = _assistir && podeAssistir;
    final semDesenho = _assistir && !podeAssistir;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 8),
      if (!comPalco)
        Center(child: RostoDaFaixa(faixa: f, tamanho: comImagem ? (largo ? 96 : 72) : (largo ? 140 : 96))),
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
      if (comPalco) ...[
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, cons) {
          final w = math.min(cons.maxWidth, 720.0);
          // no celular em pé o palco é quase quadrado (.95): com .56 sobravam ~165 px de desenho e o balão de 2
          // linhas cobria todo mundo; com .78 o balão ainda tampava a cabeça de quem fala (a página rola, então
          // há espaço). O que ainda faltar, o palco resolve encolhendo os atores (`balaoSemCorte`).
          final h0 = largo ? (w * .56).clamp(260.0, 520.0) : (w * .95).clamp(240.0, 380.0);
          // tela baixa (celular deitado): o palco inteiro, com a faixa das bolinhas e o ⛶, na altura visível
          // (o que vem acima dele, barra + nome + trilha, ocupa ~140 px + o texto ampliado)
          final visivel = MediaQuery.sizeOf(context).height;
          final escalaTexto = MediaQuery.textScalerOf(context).scale(1);
          final h = math.min(h0, math.max(160.0, visivel - 140 - 40 * escalaTexto));
          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Mixart.radiusLg),
              child: SizedBox(width: w, height: h, child: _palco(c, grande: false)),
            ),
          );
        }),
      ] else if (comImagem) ...[
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, cons) {
          final w = cons.maxWidth.clamp(0.0, 520.0);
          return Center(
            child: ImagemDaFaixa(
              key: const Key('ouvir-imagem'),
              faixa: f,
              largura: w,
              altura: (w * (largo ? .5 : .56)).clamp(150.0, 260.0),
              raio: Mixart.radiusLg,
              comRosto: false,
            ),
          );
        }),
        if (f.foto.isNotEmpty && f.fotoCredito.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('foto: ${f.fotoCredito}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Mixart.ui(size: 10, color: Mixart.textFaint)),
        ],
      ],
      if (semDesenho) ...[
        const SizedBox(height: 10),
        const Center(child: _SemDesenho()),
      ],
      const SizedBox(height: 14),
      Text(
        escondeEn ? '…' : f.en,
        key: const Key('ouvir-en'),
        textAlign: TextAlign.center,
        semanticsLabel: escondeEn ? 'Pense: como se diz em inglês?' : null,
        // com o palco, o balão já mostra a frase: aqui ela fica menor (continua pela acessibilidade e pelo "…")
        style: Mixart.display(size: comPalco ? (largo ? 26 : 22) : (largo ? 32 : 26)).copyWith(height: 1.25),
      ),
      if (mostraPt) ...[
        const SizedBox(height: 8),
        Text(f.pt,
            key: const Key('ouvir-pt'),
            textAlign: TextAlign.center,
            style: Mixart.ui(size: largo ? 17 : 15, color: Mixart.textMuted).copyWith(height: 1.35)),
      ],
      const SizedBox(height: 14),
      // o 📺 fica sempre aqui (fora do bloco da foto): existe com "Imagens" desligado e sem foto (I8)
      Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            ChipFase(key: const Key('ouvir-fase'), fase: st.fase, vez: st.vez, de: st.de),
            if (podeAssistir || _assistir)
              _BotaoAssistir(ligado: _assistir, novidade: _novidade, onTap: _alternarAssistir),
          ],
        ),
      ),
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

  /// ⛶ O desenho na tela inteira + a barra compacta (⏮ ⏯ ⏭, ⏭⏭ próxima lição, sair, os chips do Ouvir).
  Widget _palcoCheio(BuildContext context, OuvirCubit c, OuvirState st) {
    final f = st.atual!;
    final pode = PalcoAssistir.podeAssistir(f, trilhasDoCurso(context));
    return Column(key: const Key('assistir-tela-cheia-layout'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
        child: LayoutBuilder(builder: (context, cons) {
          if (pode) {
            return SizedBox(width: cons.maxWidth, height: cons.maxHeight, child: _palco(c, grande: true));
          }
          return Stack(fit: StackFit.expand, children: [
            ImagemDaFaixa(faixa: f, largura: cons.maxWidth, altura: cons.maxHeight, raio: 0),
            const Positioned(left: 12, right: 12, bottom: 12, child: Center(child: _SemDesenho())),
          ]);
        }),
      ),
      _barraCompacta(c, st),
    ]);
  }

  Widget _barraCompacta(OuvirCubit c, OuvirState st) {
    final tocando = st.status == StatusOuvir.tocando;
    final p = posicaoNaFila(st.fila, st.indice);
    final aviso = textoDoAviso(st);
    final controles = <Widget>[
      _Controle(chave: 'assistir-anterior', rotulo: 'Frase anterior', icone: Icons.skip_previous_rounded, onTap: c.anterior),
      IconButton.filled(
        key: const Key('assistir-play'),
        tooltip: tocando ? 'Pausar' : 'Tocar',
        onPressed: () => _alternar(c),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        style: IconButton.styleFrom(backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
        icon: Icon(tocando ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28, color: Mixart.onBrand),
      ),
      _Controle(chave: 'assistir-proxima', rotulo: 'Próxima frase', icone: Icons.skip_next_rounded, onTap: c.proxima),
      _Controle(
          chave: 'assistir-proxima-licao', rotulo: 'Próxima lição', icone: Icons.double_arrow_rounded, onTap: c.proximaLicao),
      const SizedBox(width: 6),
    ];
    final posicao = Text(aviso ?? 'Lição ${p.licao} de ${p.licoes} · Frase ${p.frase} de ${p.frases}',
        key: const Key('assistir-barra-posicao'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Mixart.ui(size: 12.5, weight: aviso == null ? FontWeight.w600 : FontWeight.w800, color: aviso == null ? Mixart.textMuted : Mixart.text));
    final sair = _Controle(
      chave: 'assistir-sair-tela-cheia',
      rotulo: 'Sair da tela cheia (Esc)',
      icone: Icons.fullscreen_exit_rounded,
      onTap: () => setState(() => _palcoGrande = false),
    );
    final chips = SingleChildScrollView(
      key: const Key('assistir-barra-chips'),
      scrollDirection: Axis.horizontal,
      child: ChipsOuvir(
        config: st.config,
        desligar: st.desligar,
        onConfig: c.configurar,
        onDesligar: c.desligarEm,
      ),
    );
    // tela baixa (celular deitado): uma linha só, com os chips rolando ao lado, e sobram ~50 px de desenho
    final baixa = MediaQuery.sizeOf(context).height < 500;
    return Container(
      key: const Key('assistir-barra'),
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
      decoration: BoxDecoration(color: Mixart.surface, border: Border(top: BorderSide(color: Mixart.border))),
      child: baixa
          ? Row(children: [
              ...controles,
              Flexible(flex: 2, child: posicao),
              const SizedBox(width: 6),
              Expanded(flex: 3, child: chips),
              sair,
            ])
          : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [...controles, Expanded(child: posicao), sair]),
              chips,
            ]),
    );
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

/// 📺 Assistir / 🖼️ Foto: liga e desliga o desenho no lugar da foto (com o selo "novo" até o 1º uso).
class _BotaoAssistir extends StatelessWidget {
  final bool ligado, novidade;
  final VoidCallback onTap;
  const _BotaoAssistir({required this.ligado, required this.novidade, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ver as frases como desenho animado',
      child: Semantics(
        button: true,
        toggled: ligado,
        label: 'Assistir como desenho animado',
        child: ExcludeSemantics(
          child: InkWell(
            key: const Key('ouvir-assistir'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(Mixart.radiusChip),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: ligado ? Mixart.brandSub : Mixart.surfaceHi,
                  borderRadius: BorderRadius.circular(Mixart.radiusChip),
                  border: Border.all(color: ligado ? Mixart.brandDim : Mixart.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(
                    child: Text(ligado ? '🖼️ Foto' : '📺 Assistir',
                        style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.text)),
                  ),
                  if (novidade) ...[
                    const SizedBox(width: 6),
                    Container(
                      key: const Key('ouvir-assistir-novo'),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Mixart.brand, borderRadius: BorderRadius.circular(999)),
                      child: Text('novo', style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.onBrand)),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// D14: a faixa não é de uma lição do curso (frase própria, texto colado): fica a foto, com este aviso.
class _SemDesenho extends StatelessWidget {
  const _SemDesenho();

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('assistir-sem-desenho'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Mixart.surfaceHi,
          borderRadius: BorderRadius.circular(Mixart.radiusChip),
          border: Border.all(color: Mixart.border),
        ),
        child: Text('Sem desenho para esta frase (ela não é de uma lição do curso)',
            textAlign: TextAlign.center, style: Mixart.ui(size: 12, color: Mixart.textMuted)),
      );
}
