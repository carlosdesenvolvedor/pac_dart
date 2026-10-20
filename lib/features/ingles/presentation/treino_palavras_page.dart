import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../../../core/ui/festa.dart';
import '../data/voz_ingles.dart';
import '../domain/banco_palavras.dart';
import '../domain/palavras_novas.dart';
import '../domain/roteiro_treino.dart';
import 'widgets/treino/barra_feedback.dart';
import 'widgets/treino/passo_conhecer.dart';
import 'widgets/treino/passo_digitar.dart';
import 'widgets/treino/passo_escolha.dart';
import 'widgets/treino/passo_pares.dart';
import 'widgets/treino/resumo_treino.dart';

/// A sessão de treino de palavras (estilo Duolingo): conhecer → escolher a tradução → pares → ouvir e
/// escolher → digitar de memória, com a barra de progresso (o Pac-Man andando nela), o combo 🔥 e o
/// resumo com o baú. Mais de 8 palavras viram lotes (12 → 6 + 6).
///
/// O que o banco respondeu ao registrar uma rodada da revanche das teimosas: as palavras DOMINADAS agora
/// (como se escrevem) e os acertos limpos seguidos de cada uma (chave → 0, 1, 2…; as ⭐ do resumo).
class RetornoRevanche {
  final List<String> dominadas;
  final Map<String, int> acertos;
  const RetornoRevanche({this.dominadas = const [], this.acertos = const {}});
}

/// A página NÃO grava nada: devolve um [ResultadoTreino] no `pop` (null = saiu antes de terminar o 1º
/// lote) e quem abriu ([abrirTreinoPalavras]) registra. Sem providers: fácil de testar. A exceção é a
/// revanche com [aoTerminarRodada]: quem abriu registra cada rodada quando ela termina.
class TreinoPalavrasPage extends StatefulWidget {
  final List<PalavraNova> palavras;

  /// Outras palavras (da mesma trilha) para as opções erradas.
  final List<PalavraNova> reserva;

  /// O nome da lição (ou da unidade), na barra de cima.
  final String? titulo;

  /// Voz e sorteio injetáveis (testes).
  final VozIngles? voz;
  final math.Random? rnd;

  /// A revanche das "🔥 teimosas" (relembrar → ouvir → digitar sem dica → digitar de novo).
  final bool revanche;

  /// Revanche: registra a rodada que acabou de terminar e devolve o que o banco respondeu (dominadas e
  /// acertos seguidos) para o resumo. Null = sem banco (o resumo mostra só as notas).
  final RetornoRevanche Function(ResultadoTreino rodada)? aoTerminarRodada;

  /// O "🎯 Conhecer antes" de uma lição: o resumo não oferece "🎮 Jogar" e o botão principal diz
  /// "COMEÇAR A LIÇÃO →" (a lição continua quando a página fecha).
  final bool antesDaLicao;

  const TreinoPalavrasPage({
    super.key,
    required this.palavras,
    this.reserva = const [],
    this.titulo,
    this.voz,
    this.rnd,
    this.revanche = false,
    this.aoTerminarRodada,
    this.antesDaLicao = false,
  });

  @override
  State<TreinoPalavrasPage> createState() => _TreinoPalavrasPageState();
}

/// O que a barra de baixo mostra depois de uma resposta.
class _Retorno {
  final TomFeedback tom;
  final String titulo;
  final String? detalhe;
  const _Retorno(this.tom, this.titulo, [this.detalhe]);
}

class _TreinoPalavrasPageState extends State<TreinoPalavrasPage> {
  late final VozIngles _voz = widget.voz ?? VozIngles();
  late final math.Random _rnd = widget.rnd ?? math.Random();
  final _foco = FocusNode(debugLabel: 'treino de palavras');
  GlobalKey<PassoDigitarState> _digitar = GlobalKey();
  GlobalKey<PassoParesState> _pares = GlobalKey();

  late final List<List<PalavraNova>> _lotes = lotesDeTreino(widget.palavras);
  int _lote = 0;
  late RoteiroTreino _r;

  /// Tudo o que já terminou (lotes e rodadas), e a rodada que acabou de terminar (no resumo).
  ResultadoTreino? _acumulado;
  ResultadoTreino? _rodada;
  bool _resumo = false;

  /// Revanche: o que o banco respondeu na última rodada.
  RetornoRevanche? _retornoRevanche;

  // o passo atual
  int? _escolhida;
  ResultadoRevisao? _notaDigitada;
  _Retorno? _retorno;

  /// Muda a cada passo: a chave do AnimatedSwitcher.
  int _versao = 0;

  static const _elogios = ['Mandou bem!', 'Isso aí!', 'Perfeito!', 'Boa!', 'Show!'];

  @override
  void initState() {
    super.initState();
    _iniciarLote();
  }

  @override
  void dispose() {
    _voz.parar();
    _foco.dispose();
    super.dispose();
  }

  List<PalavraNova> get _reserva => [
        ...widget.reserva,
        for (var i = 0; i < _lotes.length; i++)
          if (i != _lote) ..._lotes[i],
      ];

  void _iniciarLote() {
    _r = montarRoteiroTreino(_lotes.isEmpty ? const [] : _lotes[_lote],
        reserva: _reserva, rnd: _rnd, revanche: widget.revanche);
    _resumo = false;
    _rodada = null;
    _limparPasso();
    _versao++;
    _depoisDeMudar();
  }

  void _limparPasso() {
    _escolhida = null;
    _notaDigitada = null;
    _retorno = null;
    _digitar = GlobalKey();
    _pares = GlobalKey();
  }

  PassoTreino? get _passo => _resumo ? null : _r.atual;
  ItemTreino? get _item {
    final p = _passo;
    return p == null || p.item < 0 ? null : _r.itens[p.item];
  }

  /// Depois de trocar de passo: o 🎧 fala sozinho e o teclado volta para a página (no digitar, o
  /// campo pega o foco sozinho).
  void _depoisDeMudar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = _passo;
      if (p?.tipo == TipoPasso.ouvirEscolher) _falar(_item!.en);
      if (p?.tipo != TipoPasso.digitar) _foco.requestFocus();
    });
  }

  void _falar(String texto, {bool lenta = false}) => _voz.falar(texto, lenta: lenta);

  // ---------- respostas ----------

  void _somDaResposta(bool certo) {
    if (certo && const {3, 5, 8, 12}.contains(_r.combo)) {
      Sons.toca(Som.combo);
    } else {
      Sons.toca(certo ? Som.gol : Som.erro);
    }
  }

  String _elogio() => _elogios[_rnd.nextInt(_elogios.length)];

  String _resposta(ItemTreino it) => '${it.en} — ${it.pt}';

  void _escolher(int i) {
    final p = _passo;
    if (p == null || !p.deEscolha || _escolhida != null || i < 0 || i >= p.opcoes.length) return;
    final certo = i == p.correta;
    final it = _item!;
    _r.responder(certo ? ResultadoRevisao.acertou : ResultadoRevisao.errou);
    _somDaResposta(certo);
    setState(() {
      _escolhida = i;
      _retorno = certo
          ? _Retorno(TomFeedback.certo, _elogio(), _resposta(it))
          : _Retorno(TomFeedback.errado, 'Resposta: ${_resposta(it)}',
              p.vez < RoteiroTreino.maxVoltas ? 'Ela volta daqui a pouco.' : null);
    });
    if (p.tipo == TipoPasso.ouvirEscolher || !certo) _falar(it.en);
  }

  void _parAcerto(int item) {
    _r.acertouPar(item);
    Sons.toca(const {3, 5, 8, 12}.contains(_r.combo) ? Som.combo : Som.blip);
    setState(() {});
  }

  void _parErro(int item) {
    _r.errouPar(item);
    Sons.toca(Som.erro);
    setState(() {});
  }

  void _paresFim() {
    _r.terminouPares();
    Sons.toca(Som.gol);
    setState(() => _retorno = _Retorno(TomFeedback.certo, 'Todos os pares!', _elogio()));
  }

  void _enviarDigitado(String texto, {required bool dica}) {
    final it = _item;
    if (it == null || _notaDigitada != null) return;
    _registrarDigitado(it, notaDigitada(texto, it.en, dica: dica), dica: dica);
  }

  void _naoSei() {
    final it = _item;
    if (it == null || _notaDigitada != null) return;
    _registrarDigitado(it, ResultadoRevisao.errou, naoSei: true);
  }

  void _registrarDigitado(ItemTreino it, ResultadoRevisao nota, {bool dica = false, bool naoSei = false}) {
    final p = _passo!;
    _r.responder(nota);
    _somDaResposta(nota != ResultadoRevisao.errou);
    final volta = p.vez < RoteiroTreino.maxVoltas ? 'Ela volta daqui a pouco.' : null;
    setState(() {
      _notaDigitada = nota;
      _retorno = switch (nota) {
        ResultadoRevisao.acertou => _Retorno(TomFeedback.certo, _elogio(), _resposta(it)),
        ResultadoRevisao.hesitou =>
          _Retorno(TomFeedback.quase, 'Quase! Um errinho de digitação', 'Resposta: ${_resposta(it)}'),
        ResultadoRevisao.errou => _Retorno(
            TomFeedback.errado,
            'Resposta: ${_resposta(it)}',
            naoSei ? 'Sem problema: ${volta ?? 'ela entra na revisão.'}' : (dica ? 'Com dica conta como erro. ${volta ?? ''}'.trim() : volta),
          ),
      };
    });
    _falar(it.en);
  }

  // ---------- andar ----------

  /// Enter / CONTINUAR.
  void _continuar() {
    if (_resumo) {
      _concluir();
      return;
    }
    final p = _passo;
    if (p == null) return;
    if (!p.avaliado || _retorno != null) _proximo();
  }

  void _proximo() {
    _r.avancar();
    if (_r.terminou) {
      _fimDoLote();
      return;
    }
    setState(() {
      _limparPasso();
      _versao++;
    });
    _depoisDeMudar();
  }

  void _fimDoLote() {
    final res = _r.resultado();
    Sons.toca(Som.fase);
    final registrar = widget.aoTerminarRodada;
    _retornoRevanche = registrar == null ? null : registrar(res);
    setState(() {
      _acumulado = _acumulado == null ? res : _acumulado!.juntar(res);
      _rodada = res;
      _resumo = true;
      _limparPasso();
      _versao++;
    });
    _depoisDeMudar();
  }

  int get _proximas => _lote + 1 < _lotes.length ? _lotes[_lote + 1].length : 0;

  void _concluir({bool jogar = false, bool licao = false}) =>
      Navigator.of(context).pop(_acumulado?.comJogar(jogar).comLicao(licao));

  void _fechar() => Navigator.of(context).pop(_acumulado);

  /// O X e o voltar do sistema (botão/gesto do Android, swipe do iOS, voltar do navegador): sempre
  /// devolvem o que já terminou. No resumo, sair = continuar; no meio de um lote já começado, pergunta
  /// antes (um toque por engano no X perderia o lote).
  Future<void> _sair() async {
    if (_resumo) {
      _concluir();
      return;
    }
    final comecou = _lotes.isNotEmpty && (_r.indice > 0 || _retorno != null);
    if (comecou) {
      final sair = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('treino-confirmar-saida'),
          backgroundColor: Mixart.surface,
          title: Text('Sair do treino?', style: Mixart.ui(size: 18, weight: FontWeight.w800, color: Mixart.text)),
          content: Text('O que você fez neste lote não será salvo.',
              style: Mixart.ui(size: 14.5, color: Mixart.textMuted)),
          actions: [
            TextButton(
              key: const Key('treino-saida-continuar'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Continuar treinando',
                  style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: Mixart.brand)),
            ),
            TextButton(
              key: const Key('treino-saida-sair'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Sair', style: Mixart.ui(size: 13.5, color: Mixart.danger)),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (sair != true) {
        if (_passo?.tipo != TipoPasso.digitar) _foco.requestFocus();
        return;
      }
    }
    _fechar();
  }

  void _deNovo() => setState(_iniciarLote);

  void _proximoLote() {
    if (_proximas == 0) return;
    setState(() {
      _lote++;
      _iniciarLote();
    });
  }

  KeyEventResult _tecla(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      final p = _passo;
      if (_resumo || (p != null && !p.avaliado) || _retorno != null) {
        _continuar();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final p = _passo;
    if (p != null && p.deEscolha && _escolhida == null) {
      const teclas = [
        [LogicalKeyboardKey.digit1, LogicalKeyboardKey.numpad1],
        [LogicalKeyboardKey.digit2, LogicalKeyboardKey.numpad2],
        [LogicalKeyboardKey.digit3, LogicalKeyboardKey.numpad3],
        [LogicalKeyboardKey.digit4, LogicalKeyboardKey.numpad4],
      ];
      for (var i = 0; i < teclas.length; i++) {
        if (teclas[i].contains(k)) {
          _escolher(i);
          return KeyEventResult.handled;
        }
      }
    }
    // pares: 1–5 tocam a coluna do inglês, A–E a do português
    if (p != null && p.tipo == TipoPasso.pares && _retorno == null) {
      const esq = [
        [LogicalKeyboardKey.digit1, LogicalKeyboardKey.numpad1],
        [LogicalKeyboardKey.digit2, LogicalKeyboardKey.numpad2],
        [LogicalKeyboardKey.digit3, LogicalKeyboardKey.numpad3],
        [LogicalKeyboardKey.digit4, LogicalKeyboardKey.numpad4],
        [LogicalKeyboardKey.digit5, LogicalKeyboardKey.numpad5],
      ];
      const dir = [
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyB,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyE,
      ];
      for (var i = 0; i < esq.length; i++) {
        if (esq[i].contains(k)) {
          _pares.currentState?.tocarLinha(true, i);
          return KeyEventResult.handled;
        }
      }
      final j = dir.indexOf(k);
      if (j >= 0) {
        _pares.currentState?.tocarLinha(false, j);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // ---------- tela ----------

  Widget _conteudoDoPasso(bool estreito) {
    if (_resumo) {
      final ac = _acumulado!;
      return ResumoTreino(
        resultado: _rodada ?? ac,
        dicaTeclado: !estreito,
        proximas: _proximas,
        onProximas: _proximoLote,
        onContinuar: _concluir,
        onDeNovo: _deNovo,
        onJogar: !widget.antesDaLicao && ac.palavras.any((p) => p.deJogo) ? () => _concluir(jogar: true) : null,
        rotuloContinuar: widget.antesDaLicao ? 'COMEÇAR A LIÇÃO →' : 'CONTINUAR',
        revanche: widget.revanche,
        dominadas: _retornoRevanche?.dominadas ?? const [],
        acertos: _retornoRevanche?.acertos ?? const {},
        onLicao: widget.revanche ? () => _concluir(licao: true) : null,
      );
    }
    final p = _passo;
    if (p == null) return const SizedBox.shrink();
    final it = _item;
    return switch (p.tipo) {
      TipoPasso.conhecer => PassoConhecer(item: it!, onOuvir: ({required lenta}) => _falar(it.en, lenta: lenta)),
      TipoPasso.relembrar =>
        PassoConhecer(item: it!, compacto: true, onOuvir: ({required lenta}) => _falar(it.en, lenta: lenta)),
      TipoPasso.escolherPt || TipoPasso.ouvirEscolher => PassoEscolha(
          passo: p,
          item: it!,
          escolhida: _escolhida,
          onEscolher: _escolher,
          onOuvir: ({required lenta}) => _falar(it.en, lenta: lenta),
        ),
      TipoPasso.pares => PassoPares(
          key: _pares,
          passo: p,
          itens: _r.itens,
          onAcerto: _parAcerto,
          onErro: _parErro,
          onFim: _paresFim,
          onFalar: _falar,
        ),
      TipoPasso.digitar => PassoDigitar(
          key: _digitar,
          passo: p,
          item: it!,
          nota: _notaDigitada,
          onEnviar: _enviarDigitado,
          onNaoSei: _naoSei,
          onContinuar: _continuar,
          onOuvir: ({required lenta}) => _falar(it.en, lenta: lenta),
        ),
    };
  }

  Widget _barraDeBaixo(bool estreito) {
    if (_resumo) return const SizedBox.shrink();
    final r = _retorno;
    if (r != null) {
      return BarraFeedback(tom: r.tom, titulo: r.titulo, detalhe: r.detalhe, onContinuar: _continuar);
    }
    final p = _passo;
    if (p == null) return const SizedBox.shrink();
    final Widget conteudo;
    switch (p.tipo) {
      case TipoPasso.conhecer:
      case TipoPasso.relembrar:
        final botao = Botao3D(key: const Key('treino-continuar'), rotulo: 'CONTINUAR', onTap: _continuar);
        conteudo = estreito
            ? botao
            : Row(children: [
                Expanded(
                    child: Text('Enter = continuar', style: Mixart.ui(size: 12, color: Mixart.textFaint))),
                SizedBox(width: 220, child: botao),
              ]);
      case TipoPasso.digitar:
        conteudo = Row(children: [
          Botao3D(
            key: const Key('treino-nao-sei'),
            rotulo: 'NÃO SEI',
            contorno: true,
            expandir: false,
            altura: 46,
            tamanhoTexto: 13.5,
            onTap: () => _digitar.currentState?.naoSei(),
          ),
          const SizedBox(width: 8),
          Botao3D(
            key: const Key('treino-dica'),
            rotulo: 'DICA',
            icone: Icons.lightbulb_outline_rounded,
            contorno: true,
            expandir: false,
            altura: 46,
            tamanhoTexto: 13.5,
            onTap: () => _digitar.currentState?.dica(),
          ),
          SizedBox(width: estreito ? 8 : 16),
          if (!estreito) const Spacer(),
          estreito
              ? Expanded(child: _verificar())
              : SizedBox(width: 220, child: _verificar()),
        ]);
      case TipoPasso.escolherPt:
      case TipoPasso.ouvirEscolher:
      case TipoPasso.pares:
        conteudo = SizedBox(
          height: 46 + Botao3D.labio,
          child: Center(
            child: Text(
              p.tipo == TipoPasso.pares
                  ? (estreito ? 'Toque numa palavra e depois no par dela' : 'Toque nos pares ou tecle 1–5 e depois A–E')
                  : (estreito ? 'Toque na resposta' : 'Toque na resposta ou tecle 1 a 4'),
              style: Mixart.ui(size: 13, weight: FontWeight.w600, color: Mixart.textFaint),
            ),
          ),
        );
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Mixart.border, width: 2))),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 860), child: conteudo)),
    );
  }

  Widget _verificar() => Botao3D(
        key: const Key('treino-verificar'),
        rotulo: 'VERIFICAR',
        altura: 46,
        tamanhoTexto: 14,
        cor: escurecer(CoresFesta.verde, quanto: .1),
        onTap: () => _digitar.currentState?.verificar(),
      );

  @override
  Widget build(BuildContext context) {
    final semPalavras = _lotes.isEmpty;
    // o voltar do sistema não pode fazer pop(null): passa pelo _sair, que devolve o que já terminou
    return PopScope<ResultadoTreino>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _sair();
      },
      child: Scaffold(
        backgroundColor: Mixart.bg,
        body: SafeArea(
          child: Focus(
            focusNode: _foco,
            autofocus: true,
            onKeyEvent: _tecla,
            child: LayoutBuilder(builder: (context, c) {
              final estreito = c.maxWidth < 600;
              return Column(children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(estreito ? 6 : 12, 8, 16, 0),
                      child: _BarraDeCima(
                        progresso: _resumo || semPalavras ? 1 : _r.progresso,
                        combo: _resumo || semPalavras ? 0 : _r.combo,
                        titulo: widget.titulo,
                        lote: _lotes.length > 1 ? 'Lote ${_lote + 1} de ${_lotes.length}' : null,
                        onFechar: _sair,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: semPalavras
                      ? Center(
                          child: Text('Nenhuma palavra para treinar.',
                              style: Mixart.ui(size: 15, color: Mixart.textMuted)),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Mixart.spring,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (filho, anim) {
                            final entrando = filho.key == ValueKey(_versao);
                            final desliza = Tween<Offset>(
                              begin: Offset(entrando ? .18 : -.18, 0),
                              end: Offset.zero,
                            ).animate(anim);
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(position: desliza, child: filho),
                            );
                          },
                          layoutBuilder: (atual, anteriores) =>
                              Stack(alignment: Alignment.topCenter, children: [...anteriores, ?atual]),
                          child: KeyedSubtree(
                            key: ValueKey(_versao),
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(16, estreito ? 18 : 36, 16, 24),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: _resumo ? 600 : 640),
                                  child: _conteudoDoPasso(estreito),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                if (!semPalavras) _barraDeBaixo(estreito),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}

/// O X, a barra de progresso com o Pac-Man andando na ponta, o combo 🔥 e o nome da lição.
class _BarraDeCima extends StatelessWidget {
  final double progresso;
  final int combo;
  final String? titulo;
  final String? lote;
  final VoidCallback onFechar;
  const _BarraDeCima({required this.progresso, required this.combo, this.titulo, this.lote, required this.onFechar});

  @override
  Widget build(BuildContext context) {
    final legenda = [
      '🎯 Treino de palavras',
      if (titulo != null && titulo!.isNotEmpty) titulo!,
      ?lote,
    ].join(' · ');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(
          key: const Key('treino-fechar'),
          tooltip: 'Sair do treino',
          onPressed: onFechar,
          icon: Icon(Icons.close_rounded, color: Mixart.textMuted, size: 26),
        ),
        const SizedBox(width: 4),
        Expanded(child: TrilhaProgresso(valor: progresso)),
        SizedBox(
          width: 56,
          child: Align(
            alignment: Alignment.centerRight,
            // só na árvore a partir de 3: a ChamaCombo cria o controlador no 1º build com chama (se ela
            // sair da árvore sem nunca ter acendido, o dispose tentaria criá-lo já desmontada)
            child: combo >= 3
                ? FittedBox(fit: BoxFit.scaleDown, child: ChamaCombo(n: combo, tamanho: 24))
                : const SizedBox.shrink(),
          ),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Text(legenda,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.textFaint)),
      ),
    ]);
  }
}

/// A barra de progresso da sessão: o preenchimento verde com um brilho por cima, os pontinhos do
/// labirinto à frente e o Pac-Man na ponta, que mastiga (uma vez) a cada passo.
class TrilhaProgresso extends StatefulWidget {
  final double valor;
  const TrilhaProgresso({super.key, required this.valor});

  @override
  State<TrilhaProgresso> createState() => _TrilhaProgressoState();
}

class _TrilhaProgressoState extends State<TrilhaProgresso> with SingleTickerProviderStateMixin {
  late final _mastiga = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));

  @override
  void didUpdateWidget(covariant TrilhaProgresso old) {
    super.didUpdateWidget(old);
    if (widget.valor > old.valor) _mastiga.forward(from: 0);
  }

  @override
  void dispose() {
    _mastiga.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        // o valor de destino (não o animado), para o leitor de tela não anunciar cada quadro do tween
        container: true,
        label: 'Progresso do treino',
        value: '${(widget.valor.clamp(0.0, 1.0) * 100).round()}%',
        child: SizedBox(
          height: 28,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: widget.valor.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 480),
            curve: Mixart.spring,
            builder: (_, v, _) => AnimatedBuilder(
              animation: _mastiga,
              builder: (_, _) => CustomPaint(
                size: Size.infinite,
                painter: _TrilhaPainter(
                  valor: v,
                  boca: _mastiga.isAnimating ? .06 + .55 * (math.sin(_mastiga.value * math.pi * 4)).abs() : .42,
                  trilha: Mixart.surfaceHi,
                  cheio: escurecer(CoresFesta.verde, quanto: .15, soNoClaro: true),
                  pac: Mixart.brand,
                  ponto: Mixart.textFaint,
                ),
              ),
            ),
          ),
        ),
      );
}

class _TrilhaPainter extends CustomPainter {
  final double valor, boca;
  final Color trilha, cheio, pac, ponto;
  _TrilhaPainter({
    required this.valor,
    required this.boca,
    required this.trilha,
    required this.cheio,
    required this.pac,
    required this.ponto,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const alt = 14.0, rPac = 12.0;
    final cy = size.height / 2;
    final x0 = rPac, x1 = size.width - rPac;
    final largura = math.max(0.0, x1 - x0);
    final fundo = RRect.fromLTRBR(0, cy - alt / 2, size.width, cy + alt / 2, const Radius.circular(alt));
    canvas.drawRRect(fundo, Paint()..color = trilha);
    final px = x0 + largura * valor;
    // os pontinhos à frente
    final tinta = Paint()..color = ponto.withValues(alpha: .55);
    for (var x = px + rPac + 8; x < size.width - 6; x += 16) {
      canvas.drawCircle(Offset(x, cy), 2.2, tinta);
    }
    // o preenchimento (com o brilho de cima)
    if (valor > 0) {
      final cheioR = RRect.fromLTRBR(0, cy - alt / 2, px, cy + alt / 2, const Radius.circular(alt));
      canvas.drawRRect(cheioR, Paint()..color = cheio);
      if (px > 16) {
        canvas.drawRRect(
          RRect.fromLTRBR(8, cy - alt / 2 + 3, px - 8, cy - alt / 2 + 6.5, const Radius.circular(4)),
          Paint()..color = Colors.white.withValues(alpha: .28),
        );
      }
    }
    // o Pac-Man na ponta, olhando para a frente
    final centro = Offset(px, cy);
    canvas.drawCircle(centro.translate(0, 1.5), rPac, Paint()..color = Colors.black.withValues(alpha: .25));
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: rPac),
      boca,
      2 * math.pi - boca * 2,
      true,
      Paint()..color = pac,
    );
    canvas.drawCircle(centro.translate(1.5, -rPac * .5), 1.8, Paint()..color = const Color(0xFF111111));
  }

  @override
  bool shouldRepaint(covariant _TrilhaPainter old) =>
      old.valor != valor || old.boca != boca || old.trilha != trilha || old.cheio != cheio || old.pac != pac;
}
