import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/som/sons.dart';
import '../../../../core/theme/mixart.dart';
import '../../../curso/domain/curriculo.dart';
import '../../data/voz_ingles.dart';
import 'cena_visual.dart';

/// 🎬 Ensaio mental antes da lição (~20–40 s, em tela cheia, nunca
/// obrigatório). Três passos que andam sozinhos e um que espera o Enter:
///
/// 1. **Estado (âncora):** um ciclo de respiração (inspira 4 s, solta 4 s)
///    lembrando uma conversa que deu certo, com o polegar e o indicador
///    juntos — no pico toca [Som.ancora]. A vitória da lição repete o MESMO
///    som e o mesmo gesto: é isso que faz deles uma âncora.
/// 2. **Cena:** a foto em tela cheia com zoom lento e a visualização guiada
///    (lembrar no mesmo contexto em que aprendeu ajuda a lembrar).
/// 3. **Ensaio do futuro:** as frases-chave da lição — primeiro a tradução,
///    depois o inglês aparece e a voz fala ("daqui a pouco você vai dizer").
///    Cada frase fica o tempo de ser dita INTEIRA ([segDaFrase]) e, se a voz
///    ainda estiver falando, o relógio espera ela acabar: uma frase nunca
///    corta a outra.
/// 4. **Pronto:** fica parado até o Enter ("Começar a lição").
///
/// Enter começa e Esc pula a qualquer momento; Tab não sai daqui. Se a
/// página ainda não teve nenhum gesto (app recém-aberto direto na lição), o
/// navegador deixaria tudo mudo: o roteiro espera parado num "▶ Começar o
/// ensaio" — o Enter ou o toque ali é o gesto que libera o som.
class EnsaioMental extends StatefulWidget {
  final Licao licao;
  final VozIngles voz;

  /// Enter / "Começar a lição".
  final VoidCallback onComecar;

  /// Esc / "Pular".
  final VoidCallback onPular;

  /// A caixinha "não mostrar mais" (true = desligar antes das próximas).
  final bool naoMostrarMais;
  final ValueChanged<bool> onNaoMostrarMais;

  /// Foco do ensaio (o palco o devolve quando a rota dele volta ao topo).
  final FocusNode? focusNode;

  /// A pref "áudio automático" do palco: desligada, a voz das frases só sai
  /// no 🔊 (o sino da âncora segue o liga/desliga geral dos [Sons]).
  final bool audioAuto;

  /// O passo 1 chegou ao pico (o sino da âncora): a vitória desta lição pode
  /// repetir o som e o gesto.
  final VoidCallback? onAncora;

  const EnsaioMental({
    super.key,
    required this.licao,
    required this.voz,
    required this.onComecar,
    required this.onPular,
    required this.naoMostrarMais,
    required this.onNaoMostrarMais,
    this.focusNode,
    this.audioAuto = true,
    this.onAncora,
  });

  /// Pref: mostrar o ensaio quando uma lição começa (padrão ligado).
  static const prefLigado = 'en_ensaio';

  static Future<bool> carregarPreferencia() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(prefLigado) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> salvarPreferencia(bool ligado) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(prefLigado, ligado);
    } catch (_) {}
  }

  /// As frases-chave: as que têm alvo (o trecho que a lição ensina), até 3
  /// e na ordem da lição; lição sem alvo marcado usa as 3 primeiras.
  static List<Trecho> frasesChave(Licao licao) {
    final comAlvo = licao.trechos.where((t) => t.alvo.isNotEmpty).take(3).toList();
    return comAlvo.isNotEmpty ? comAlvo : licao.trechos.take(3).toList();
  }

  /// Duração de cada passo (segundos) — o roteiro inteiro dá ~20–40 s.
  static const segEstado = 8.0;
  static const segCena = 6.0;

  /// O mínimo de cada frase do ensaio do futuro (frase curta).
  static const segFrase = 3.4;

  /// Dentro de cada frase: quando o inglês aparece (antes, só a tradução).
  static const segRevelaIngles = 1.2;

  /// A fala: o atraso até a voz começar, o tempo por palavra (a devagar, que
  /// é o padrão, sai ~2 palavras/s: TTS a 0,72 e gravação a 0,8; a normal,
  /// ~3/s) e uma pausa depois, antes da próxima frase entrar.
  static const segLatencia = .4;
  static const segPorPalavraLenta = .46;
  static const segPorPalavra = .34;
  static const segRespiro = .6;

  /// Quanto [frase] fica no ensaio do futuro: a tradução sozinha, e então
  /// tempo para a voz dizer a frase inteira antes da próxima entrar.
  static double segDaFrase(String frase, {required bool lenta}) {
    final palavras = RegExp(r"[A-Za-z0-9']+").allMatches(frase).length;
    final fala = segLatencia + palavras * (lenta ? segPorPalavraLenta : segPorPalavra);
    return math.max(segFrase, segRevelaIngles + fala + segRespiro);
  }

  /// Teto da espera por uma fala que nunca avisa o fim (evento perdido).
  static const limiteFala = Duration(seconds: 15);

  @override
  State<EnsaioMental> createState() => _EnsaioMentalState();
}

enum _Passo { estado, cena, futuro, pronto }

class _EnsaioMentalState extends State<EnsaioMental> with SingleTickerProviderStateMixin {
  late final FocusNode _foco = widget.focusNode ?? FocusNode(debugLabel: 'ensaio mental');
  late final List<Trecho> _frases = EnsaioMental.frasesChave(widget.licao);
  late final bool _temCena =
      widget.licao.foto.isNotEmpty ||
      widget.licao.imagem.isNotEmpty ||
      widget.licao.visualizacao.isNotEmpty ||
      widget.licao.cena.isNotEmpty;
  late final double _segCena = _temCena ? EnsaioMental.segCena : 0;

  /// O tempo de cada frase-chave, na velocidade padrão do aluno.
  late final List<double> _segFrases = [
    for (final f in _frases) EnsaioMental.segDaFrase(f.cod, lenta: VozIngles.lentaPorPadrao),
  ];
  late final double _total = EnsaioMental.segEstado + _segCena + _segFrases.fold(0.0, (a, b) => a + b);
  late final AnimationController _relogio = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_total * 1000).round()),
  );
  late bool _naoMostrar = widget.naoMostrarMais;

  bool _tocouAncora = false;
  int _falou = -1;

  /// A fala em curso (automática ou do 🔊): enquanto ela soa, a próxima
  /// frase não entra — o relógio para e espera.
  Future<void>? _falando;

  /// Página sem nenhum gesto ainda: o roteiro espera o "▶ Começar o ensaio"
  /// (com o navegador bloqueando, o sino e as vozes sairiam mudos).
  late bool _esperandoGesto = !widget.voz.somLiberado && (Sons.ligado || widget.audioAuto);

  double get _t => _relogio.value * _total;
  double get _iniFuturo => EnsaioMental.segEstado + _segCena;

  _Passo _passoEm(double t) {
    if (_relogio.isCompleted) return _Passo.pronto;
    if (t < EnsaioMental.segEstado) return _Passo.estado;
    if (t < _iniFuturo) return _Passo.cena;
    return _frases.isEmpty ? _Passo.pronto : _Passo.futuro;
  }

  /// Frase do ensaio do futuro em [t] e há quanto tempo ela entrou.
  (int, double) _fraseEm(double t) {
    var dt = math.max(0.0, t - _iniFuturo);
    for (var i = 0; i < _frases.length - 1; i++) {
      if (dt < _segFrases[i]) return (i, dt);
      dt -= _segFrases[i];
    }
    return (_frases.length - 1, dt);
  }

  @override
  void initState() {
    super.initState();
    _relogio.addListener(_marcos);
    _relogio.addStatusListener((_) => setState(() {}));
    if (!_esperandoGesto) _relogio.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // aberto por baixo de outra tela (a lição mudou com o mapa ou a
      // revisão por cima): não rouba o teclado dela
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) _foco.requestFocus();
    });
  }

  /// "▶ Começar o ensaio" (Enter/toque): o gesto que libera o som.
  void _comecarRoteiro() {
    if (!_esperandoGesto) return;
    setState(() => _esperandoGesto = false);
    _relogio.forward();
    _foco.requestFocus();
  }

  /// Os momentos do roteiro: o sino no pico da respiração e a voz de cada
  /// frase quando o inglês aparece (pulou o tempo? fala só a da vez).
  void _marcos() {
    final t = _t;
    if (!_tocouAncora && t >= EnsaioMental.segEstado / 2) {
      _tocouAncora = true;
      Sons.toca(Som.ancora);
      widget.onAncora?.call();
    }
    if (_frases.isEmpty || t < _iniFuturo) return;
    final (i, local) = _fraseEm(t);
    if (i <= _falou) return;
    // a frase anterior ainda está sendo dita (voz mais lenta que a conta):
    // a próxima espera, em vez de cortá-la no meio
    if (_falando != null && !_relogio.isCompleted) {
      _relogio.stop();
      return;
    }
    if (local >= EnsaioMental.segRevelaIngles || _relogio.isCompleted) {
      _falou = i;
      if (widget.audioAuto) _falar(_frases[i]); // velocidade padrão do aluno
    }
  }

  /// Fala [f] e guarda a fala em curso até ela acabar (com teto: evento de
  /// fim perdido não trava o roteiro).
  void _falar(Trecho f) {
    late final Future<void> fala;
    fala = widget.voz
        .falar(f.cod)
        .timeout(EnsaioMental.limiteFala, onTimeout: () {})
        .catchError((Object _) {})
        .whenComplete(() {
          if (!identical(_falando, fala)) return;
          _falando = null;
          // o relógio parou esperando esta fala: segue
          if (mounted && !_esperandoGesto && !_relogio.isAnimating && !_relogio.isCompleted) _relogio.forward();
        });
    _falando = fala;
  }

  @override
  void dispose() {
    _falando = null;
    _relogio.dispose();
    if (widget.focusNode == null) _foco.dispose();
    super.dispose();
  }

  KeyEventResult _tecla(FocusNode _, KeyEvent e) {
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      // parado no convite, o Enter começa o ensaio (e libera o som)
      if (e is KeyDownEvent) _esperandoGesto ? _comecarRoteiro() : widget.onComecar();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      if (e is KeyDownEvent) widget.onPular();
      return KeyEventResult.handled;
    }
    // o foco não sai do ensaio para o palco de trás
    if (k == LogicalKeyboardKey.tab) return KeyEventResult.handled;
    return KeyEventResult.ignored;
  }

  /// 🔊 de uma frase (o foco volta para o ensaio: Enter/Esc seguem valendo).
  void _ouvir(Trecho f) {
    _falar(f);
    _foco.requestFocus();
  }

  void _alternarNaoMostrar() {
    setState(() => _naoMostrar = !_naoMostrar);
    widget.onNaoMostrarMais(_naoMostrar);
    _foco.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Mixart.bg,
      child: Focus(
        focusNode: _foco,
        onKeyEvent: _tecla,
        // largura pela MediaQuery, não por LayoutBuilder: o ensaio vive num
        // OverlayPortal que muda de lugar quando a janela cruza a largura do
        // painel do tutor (ver FotoCena)
        child: Builder(
          builder: (context) {
            final estreito = MediaQuery.sizeOf(context).width < 560;
            return AnimatedBuilder(
              animation: _relogio,
              builder: (context, _) {
                final t = _t;
                final passo = _passoEm(t);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // a cena em tela cheia, só no passo dela
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 700),
                      child: passo == _Passo.cena
                          ? _FundoCena(key: const ValueKey('cena'), licao: widget.licao)
                          : const SizedBox.expand(key: ValueKey('liso')),
                    ),
                    SafeArea(
                      child: Column(
                        children: [
                          _topo(passo, estreito),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.symmetric(horizontal: estreito ? 16 : 32, vertical: 20),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 760),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 450),
                                    child: _esperandoGesto
                                        ? KeyedSubtree(key: const ValueKey('convite'), child: _convite(estreito))
                                        : KeyedSubtree(key: ValueKey(passo), child: _conteudo(passo, t, estreito)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _rodape(passo, estreito),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _topo(_Passo passo, bool estreito) {
    const nomes = ['Estado', 'Cena', 'Ensaio', 'Começar'];
    final atual = passo.index;
    // lição sem cena: são 3 passos
    final visiveis = [
      for (var i = 0; i < nomes.length; i++)
        if (i != 1 || _temCena) i,
    ];
    final posicao = visiveis.indexOf(atual) + 1;
    return Container(
      color: Mixart.bg.withValues(alpha: .9),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(estreito ? 16 : 24, 10, estreito ? 8 : 16, 8),
            child: Row(
              children: [
                Text(
                  '🎬 ENSAIO MENTAL',
                  style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 1.6),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: estreito
                      ? Text(
                          '$posicao/${visiveis.length} · ${nomes[atual]}',
                          style: Mixart.ui(size: 11.5, weight: FontWeight.w600, color: Mixart.textMuted),
                        )
                      : Wrap(
                          spacing: 12,
                          children: [
                            for (final i in visiveis)
                              Text(
                                nomes[i],
                                style: Mixart.ui(
                                  size: 11.5,
                                  weight: i == atual ? FontWeight.w800 : FontWeight.w500,
                                  color: i == atual ? Mixart.text : (i < atual ? Mixart.textMuted : Mixart.textFaint),
                                ),
                              ),
                          ],
                        ),
                ),
                TextButton(
                  onPressed: widget.onPular,
                  style: TextButton.styleFrom(foregroundColor: Mixart.textMuted),
                  child: Text(
                    estreito ? 'Pular' : 'Pular · Esc',
                    style: Mixart.ui(size: 12.5, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: _relogio.value,
            minHeight: 3,
            backgroundColor: Mixart.surfaceHi,
            color: Mixart.brand,
          ),
        ],
      ),
    );
  }

  Widget _rodape(_Passo passo, bool estreito) {
    final caixa = InkWell(
      onTap: _alternarNaoMostrar,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _naoMostrar ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 18,
              color: _naoMostrar ? Mixart.brand : Mixart.textMuted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'não mostrar mais antes das lições',
                style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
    // parado no convite o botão grande é o do ensaio; aqui fica o atalho
    final botao = _esperandoGesto
        ? OutlinedButton(
            onPressed: widget.onComecar,
            style: OutlinedButton.styleFrom(
              foregroundColor: Mixart.text,
              side: BorderSide(color: Mixart.border),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: Mixart.ui(size: 14, weight: FontWeight.w700),
            ),
            child: const Text('Ir direto para a lição'),
          )
        : FilledButton(
            onPressed: widget.onComecar,
            style: FilledButton.styleFrom(
              backgroundColor: Mixart.brand,
              foregroundColor: Mixart.onBrand,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: Mixart.ui(size: 14, weight: FontWeight.w800),
            ),
            child: Text(passo == _Passo.pronto ? 'Começar a lição  ↵' : 'Começar já  ↵'),
          );
    return Container(
      color: Mixart.bg.withValues(alpha: .9),
      padding: EdgeInsets.fromLTRB(estreito ? 16 : 24, 10, estreito ? 16 : 24, 14),
      child: estreito
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                botao,
                const SizedBox(height: 4),
                Center(child: caixa),
              ],
            )
          // alinhado com a coluna do conteúdo (o botão fica sob os cartões)
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(alignment: Alignment.centerLeft, child: caixa),
                    ),
                    const SizedBox(width: 12),
                    botao,
                  ],
                ),
              ),
            ),
    );
  }

  /// Parado antes do roteiro, esperando o gesto que libera o som.
  Widget _convite(bool estreito) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Um ensaio de 20 segundos, com som',
          textAlign: TextAlign.center,
          style: Mixart.display(size: estreito ? 21 : 28),
        ),
        const SizedBox(height: 10),
        Text(
          'Respiração, a cena da lição e as frases que você vai digitar, em voz alta.',
          textAlign: TextAlign.center,
          style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _comecarRoteiro,
          style: FilledButton.styleFrom(
            backgroundColor: Mixart.brand,
            foregroundColor: Mixart.onBrand,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            textStyle: Mixart.ui(size: 15, weight: FontWeight.w800),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          label: const Text('Começar o ensaio  ↵'),
        ),
        const SizedBox(height: 12),
        Text(
          'Esc pula direto para a lição',
          textAlign: TextAlign.center,
          style: Mixart.ui(size: 12, color: Mixart.textFaint),
        ),
      ],
    );
  }

  Widget _conteudo(_Passo passo, double t, bool estreito) => switch (passo) {
    _Passo.estado => _estado(t, estreito),
    _Passo.cena => _cena(estreito),
    _Passo.futuro => _futuro(t, estreito),
    _Passo.pronto => _pronto(estreito),
  };

  Widget _estado(double t, bool estreito) {
    final meia = EnsaioMental.segEstado / 2;
    final inspirando = t < meia;
    final fase = inspirando ? t / meia : (t - meia) / meia;
    final curva = Curves.easeInOut.transform(fase.clamp(0.0, 1.0));
    final escala = inspirando ? .55 + .45 * curva : 1 - .45 * curva;
    final diametro = estreito ? 150.0 : 190.0;
    final faltam = (meia - (t % meia)).ceil().clamp(1, meia.round());
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: diametro,
          height: diametro,
          child: Center(
            child: Container(
              width: diametro * escala,
              height: diametro * escala,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Mixart.brand.withValues(alpha: .55), Mixart.brandSub]),
                border: Border.all(color: Mixart.brand.withValues(alpha: _tocouAncora ? .9 : .35), width: 2),
                // o brilho do sino: o pico da respiração é o momento da âncora
                boxShadow: _tocouAncora
                    ? [BoxShadow(color: Mixart.brand.withValues(alpha: .35 * (1 - curva * .6)), blurRadius: 40)]
                    : null,
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        inspirando ? 'inspira' : 'solta',
                        style: Mixart.ui(size: 15, weight: FontWeight.w800, color: Mixart.text),
                      ),
                      Text('$faltam', style: Mixart.display(size: 22, color: Mixart.text)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: estreito ? 22 : 30),
        Text(
          'Lembre de uma conversa em que você se saiu bem.',
          textAlign: TextAlign.center,
          style: Mixart.display(size: estreito ? 20 : 27).copyWith(height: 1.3),
        ),
        const SizedBox(height: 12),
        Text(
          '👌  Junte o polegar e o indicador.',
          textAlign: TextAlign.center,
          style: Mixart.ui(size: estreito ? 15 : 17, weight: FontWeight.w700, color: Mixart.brand),
        ),
        const SizedBox(height: 10),
        Text(
          'Sinta de novo como foi. Esse som e esse gesto vão voltar quando você terminar a lição.',
          textAlign: TextAlign.center,
          style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5),
        ),
      ],
    );
  }

  Widget _cena(bool estreito) {
    final l = widget.licao;
    const branco = Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'VISUALIZE A CENA',
          style: Mixart.ui(
            size: 11,
            weight: FontWeight.w800,
            color: branco.withValues(alpha: .75),
          ).copyWith(letterSpacing: 1.6),
        ),
        if (l.cena.isNotEmpty && l.visualizacao.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '📍 ${l.cena}',
            style: Mixart.ui(size: 13, weight: FontWeight.w600, color: branco.withValues(alpha: .8)),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          l.visualizacao.isNotEmpty ? l.visualizacao : (l.cena.isNotEmpty ? l.cena : l.nome),
          style: Mixart.ui(size: estreito ? 20 : 28, weight: FontWeight.w600, color: branco).copyWith(
            height: 1.45,
            fontStyle: FontStyle.italic,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 12)],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Veja o lugar, quem está com você, os sons. Você está lá.',
          style: Mixart.ui(size: 13, color: branco.withValues(alpha: .75)).copyWith(height: 1.5),
        ),
        if (l.fotoCredito.isNotEmpty && l.foto.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('foto: ${l.fotoCredito}', style: Mixart.ui(size: 9.5, color: branco.withValues(alpha: .45))),
        ],
      ],
    );
  }

  Widget _futuro(double t, bool estreito) {
    final (atual, local) = _fraseEm(t);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Daqui a pouco, nessa cena, você vai dizer:',
          style: Mixart.ui(size: estreito ? 14 : 16, weight: FontWeight.w600, color: Mixart.textMuted),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i <= atual; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CartaoFrase(
              trecho: _frases[i],
              destaque: i == atual,
              ingles: i < atual || local >= EnsaioMental.segRevelaIngles,
              estreito: estreito,
              onOuvir: () => _ouvir(_frases[i]),
            ),
          ),
      ],
    );
  }

  Widget _pronto(bool estreito) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Você já se viu dizendo isso.',
          textAlign: TextAlign.center,
          style: Mixart.display(size: estreito ? 21 : 28),
        ),
        const SizedBox(height: 8),
        Text(
          'Agora é digitar: cada frase 5 vezes, com menos ajuda a cada vez.',
          textAlign: TextAlign.center,
          style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.5),
        ),
        const SizedBox(height: 18),
        for (final f in _frases)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CartaoFrase(
              trecho: f,
              destaque: false,
              ingles: true,
              compacto: true,
              estreito: estreito,
              onOuvir: () => _ouvir(f),
            ),
          ),
        // no celular o botão logo abaixo já diz tudo
        if (!estreito) ...[
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: Mixart.brandDim),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '↵ Enter começa',
                style: Mixart.mono(size: 17, weight: FontWeight.w700, color: Mixart.brand),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A foto da cena em tela cheia, aproximando devagar, com um véu escuro
/// para o texto branco ler bem em qualquer tema.
class _FundoCena extends StatelessWidget {
  final Licao licao;
  const _FundoCena({super.key, required this.licao});

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      FotoCena(
        licao: licao,
        altura: MediaQuery.sizeOf(context).height,
        zoom: const Duration(seconds: 9),
        escala: 1.12,
        emojiFator: .22,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x99000000), Color(0x66000000), Color(0xE6000000)],
          ),
        ),
      ),
    ],
  );
}

/// Uma frase do ensaio do futuro: a tradução grande e, embaixo, o inglês
/// que aparece em seguida (o trecho que a lição ensina, destacado).
class _CartaoFrase extends StatelessWidget {
  final Trecho trecho;
  final bool destaque, ingles, estreito, compacto;
  final VoidCallback onOuvir;

  const _CartaoFrase({
    required this.trecho,
    required this.destaque,
    required this.ingles,
    required this.estreito,
    required this.onOuvir,
    this.compacto = false,
  });

  /// [texto] com o pedaço [alvo] em destaque.
  static TextSpan _realce(String texto, String alvo, TextStyle base, TextStyle forte) {
    final i = alvo.isEmpty ? -1 : texto.indexOf(alvo);
    if (i < 0) return TextSpan(text: texto, style: base);
    return TextSpan(
      style: base,
      children: [
        TextSpan(text: texto.substring(0, i)),
        TextSpan(text: alvo, style: forte),
        TextSpan(text: texto.substring(i + alvo.length)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tamPt = compacto ? (estreito ? 15.0 : 17.0) : (estreito ? 20.0 : 27.0);
    final tamEn = compacto ? (estreito ? 15.0 : 17.0) : (estreito ? 18.0 : 24.0);
    final pt = Mixart.display(
      size: tamPt,
      color: destaque || compacto ? Mixart.text : Mixart.textMuted,
    ).copyWith(height: 1.3);
    final en = Mixart.mono(size: tamEn, weight: FontWeight.w600, color: Mixart.text).copyWith(height: 1.45);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: destaque || compacto ? 1 : .55,
      child: Container(
        padding: EdgeInsets.all(compacto ? 12 : (estreito ? 14 : 20)),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: destaque ? Mixart.brandDim : Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(_realce(trecho.dica, trecho.alvoPt, pt, pt.copyWith(color: Mixart.brand))),
            SizedBox(height: compacto ? 4 : 10),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: ingles ? 1 : 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Text.rich(_realce(trecho.cod, trecho.alvo, en, en.copyWith(color: Mixart.brand)))),
                  IconButton(
                    onPressed: ingles ? onOuvir : null,
                    tooltip: 'ouvir',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.volume_up_rounded, size: 20, color: Mixart.brand),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
