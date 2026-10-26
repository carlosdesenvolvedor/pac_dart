import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/som/sons.dart';
import '../../../../core/theme/mixart.dart';
import '../../../curso/presentation/bloc/typing_bloc.dart';
import '../../../curso/presentation/widgets/pacman.dart';
import '../../data/reconhecedor_fala.dart';
import '../../data/voz_ingles.dart';
import '../../domain/avaliacao.dart';
import '../../domain/avaliacao_fala.dart';
import '../../domain/entrada_resposta.dart';
import '../../domain/roteiro.dart';
import '../zona_visivel.dart';
import 'leitor_teclado.dart';
import 'montagem_frase.dart';
import 'seletor_entrada.dart';
import 'traducao_palavra.dart';

/// A frase em inglês sendo digitada, com o Pac-Man comendo letra a letra.
///
/// O que aparece antes de digitar depende do degrau ([ModoFrase]): a frase
/// toda, só as iniciais, só os tracinhos ou nada. No escuro, errar duas
/// vezes a mesma letra a revela; Tab revela a próxima letra (Tab duas vezes
/// seguidas, a palavra) e Esc ("não sei") mostra a frase inteira. Terminada
/// uma digitação de memória, a frase aparece completa com as palavras
/// erradas sublinhadas. O teclado entra por um TextField invisível, como no
/// CodeView (acentos/IME e as teclas mortas do US-International).
///
/// No celular há também o MICROFONE: a pessoa fala a frase em inglês (ou dita
/// pelo 🎤 do teclado) e ela é conferida palavra por palavra
/// ([avaliarFala]) — acertou tudo, a frase vale como digitada.
///
/// [entrada] diz COMO a pessoa responde este passo: ⌨️ digitando (o padrão, tudo
/// como descrito acima), 🎤 falando (o painel do microfone em destaque) ou 🧩
/// montando a frase com blocos de palavras ([MontagemFrase]). Falar e Montar
/// terminam a frase sem teclas ([TrechoFalado]) e NÃO abrem o teclado do celular. Neles a frase em inglês
/// fica COBERTA (tracinhos) até ser respondida — senão bastava ler e montar/falar o que está escrito; o "não
/// sei" a revela. O 👁 ([mostrarTudo]) continua mostrando tudo.
///
/// Tocar numa palavra À VISTA (já digitada ou mostrada) abre o balão com a tradução dela: o pé da letra
/// (dicionário do app) e o sentido no contexto ([BalaoPalavra]). Palavra coberta não abre (seria cola).
class FraseView extends StatefulWidget {
  final ModoFrase modo;

  /// Número do passo: mudou, as revelações recomeçam (a frase pode voltar
  /// logo em seguida, na cópia de correção).
  final int passo;

  /// Trecho da frase que a lição ensina — vem destacado.
  final String alvo;

  /// A tradução da frase e a do [alvo]: o contexto do balão da palavra tocada.
  final String traducao, alvoPt;

  /// Palavras (índices) a sublinhar em vermelho depois de terminar.
  final Set<int> palavrasErradas;

  /// Enter com a frase completa.
  final VoidCallback onAvancar;

  /// Enter ANTES de terminar = ouvir na velocidade padrão (a lenta, se o
  /// aluno não mudou); Shift+Enter = na outra velocidade.
  final void Function({required bool lenta})? onOuvir;

  /// Só a palavra tocada (o 🔊/🐢 do balão dela); null = o balão sem voz.
  final OuvirPalavra? onOuvirPalavra;

  /// "🎯 Treinar esta palavra" no balão da palavra tocada (null = sem o botão).
  final TreinarPalavra? onTreinarPalavra;

  /// A palavra tocada já soa ao abrir o balão (na velocidade padrão do aluno) — segue o "áudio automático".
  final bool falarPalavraAoTocar;

  /// 👁 ligado: a frase inteira à vista em qualquer degrau (vale para
  /// todas as frases até desligar).
  final bool mostrarTudo;

  /// Pediu dica (Tab / 💡) ou desistiu (Esc): algo foi revelado.
  final VoidCallback? onRevelou;

  final FocusNode? focusNode;

  /// Overlay de vitória na tela: Enter segue, Esc pula a etapa seguinte.
  final bool vitoria;
  final VoidCallback? onProximaLicao;
  final VoidCallback? onPularQuiz;

  /// Formas da frase aceitas além dela (contrações, `alt` do autor): valem
  /// também quando a resposta é falada.
  final List<String> alternativas;

  /// O microfone abriu (true) ou fechou (false): o palco cala a voz do app
  /// enquanto a pessoa fala (senão o reconhecedor ouve o próprio app).
  final void Function(bool ouvindo)? onMicrofone;

  /// O reconhecedor de voz (testes injetam o deles; null = o do navegador).
  final ReconhecedorFala? reconhecedor;

  /// Como a pessoa responde este passo. O padrão (digitar) deixa tudo como sempre foi.
  final EntradaResposta entrada;

  /// Quando existe, a barra ⌨️ Digitar · 🎤 Falar · 🧩 Montar aparece acima da frase e avisa a escolha.
  final ValueChanged<EntradaResposta>? onMudarEntrada;

  /// De onde saem os blocos de enfeite do Montar: frases em inglês da lição (e, se faltar, do curso).
  final List<String> apoioMontagem, extraMontagem;

  /// Quem cria o reconhecedor quando [reconhecedor] é null — os testes de tela
  /// cheia (onde o FraseView nasce dentro do palco) trocam por um falso.
  static ReconhecedorFala Function() fabricaReconhecedor = ReconhecedorFala.navegador;

  /// Janela logo após montar em que o texto que chega é descartado (a
  /// tecla que escolheu o curso). Testes zeram.
  static Duration carencia = const Duration(milliseconds: 350);

  const FraseView({
    super.key,
    required this.modo,
    this.passo = 0,
    required this.onAvancar,
    this.onOuvir,
    this.onOuvirPalavra,
    this.onTreinarPalavra,
    this.falarPalavraAoTocar = true,
    this.alvo = '',
    this.traducao = '',
    this.alvoPt = '',
    this.palavrasErradas = const {},
    this.onRevelou,
    this.focusNode,
    this.vitoria = false,
    this.onProximaLicao,
    this.onPularQuiz,
    this.mostrarTudo = false,
    this.alternativas = const [],
    this.onMicrofone,
    this.reconhecedor,
    this.entrada = EntradaResposta.digitar,
    this.onMudarEntrada,
    this.apoioMontagem = const [],
    this.extraMontagem = const [],
  });

  @override
  State<FraseView> createState() => FraseViewState();
}

class FraseViewState extends State<FraseView> {
  late final FocusNode _foco = widget.focusNode ?? FocusNode();
  final _ctrl = TextEditingController();

  /// Posições reveladas no escuro (dica, letra errada duas vezes, "não sei").
  final Set<int> _reveladas = {};
  bool _desistiu = false;
  bool _ultimaFoiTab = false;

  /// A tecla que ESCOLHEU o curso (o "3" da tela de escolha) chega aqui
  /// logo depois da montagem como texto digitado — descarta esse resto.
  final _montadoEm = DateTime.now();

  /// O que foi revelado nesta digitação (para a nota).
  Set<int> get reveladas => Set.unmodifiable(_reveladas);
  bool get desistiu => _desistiu;

  // Celular/tablet: teclado virtual (que compõe a palavra enquanto se
  // digita), microfone e toque no lugar de Enter/Tab/Esc. No computador
  // nada disso muda.
  late final LeitorTeclado _leitor = LeitorTeclado(aoDigitar: _digitou, aoDitar: ehCelular ? _ditou : null);

  // ── resposta falada ──
  late final ReconhecedorFala _rec = widget.reconhecedor ?? FraseView.fabricaReconhecedor();
  SessaoFala? _escuta;
  int _vezEscuta = 0;
  bool _ouvindo = false;
  String _parcial = '';
  String _recado = '';
  AvaliacaoFala? _ultimaFala;

  /// Já tocou em "Parar" e o navegador ainda não avisou que terminou (no Chrome/Safari do iPhone ele pode nunca
  /// avisar): um 2º toque, ou [_esperaParar], solta o microfone à força — a tela nunca fica presa em "Ouvindo…".
  bool _pediuParar = false;
  Timer? _forcaFim;
  static const _esperaParar = Duration(seconds: 2);

  /// Erros da fala por posição da 1ª letra da palavra errada: entram na nota
  /// como as teclas erradas (e a palavra errada duas vezes é revelada).
  final Map<int, int> _errosFala = {};
  Map<int, int> get errosDeFala => Map.unmodifiable(_errosFala);

  /// O microfone está aberto agora.
  bool get ouvindo => _ouvindo;

  /// O modo que vale agora: Falar sem reconhecimento de voz neste aparelho vira Digitar (a escolha guardada fica).
  EntradaResposta get entradaAtiva =>
      widget.entrada == EntradaResposta.falar && !_rec.suportado ? EntradaResposta.digitar : widget.entrada;
  bool get _digitando => entradaAtiva == EntradaResposta.digitar;

  /// Falar e Montar: a frase fica coberta até ser respondida (o 👁 mostra mesmo assim).
  bool get _cobreResposta => !widget.mostrarTudo && !_digitando;

  /// "não sei" vale de memória e, coberta, também na cópia (é o único jeito de ver a frase).
  bool get _podeNaoSei => widget.modo.deMemoria || _cobreResposta;

  // ── toque na palavra ──
  final _balao = BalaoPalavra();
  final _chaveFrase = GlobalKey();

  /// As palavras à vista no último desenho da frase: o índice e onde estão (coordenadas da frase).
  List<({int indice, int ini, int fim, Rect caixa})> _palavrasAVista = const [];

  /// Este modo pede o foco do campo escondido (e, no celular, o teclado)? Só o Digitar; no computador sempre.
  /// Pede o foco (e o teclado) — só com a frase na tela do topo: com o Início (ou outra tela) por cima, o teclado
  /// não sobe por cima dela.
  bool get _pedeFoco =>
      abreTeclado(entradaAtiva, celular: ehCelular) && (ModalRoute.of(context)?.isCurrent ?? true);

  final _montagem = GlobalKey<MontagemFraseState>();

  // o Enter do teclado virtual chega como ação do campo E, às vezes, como
  // tecla: o que vier segundo, dentro desta janela, é o mesmo toque
  DateTime _enterTeclaEm = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _enterAcaoEm = DateTime.fromMillisecondsSinceEpoch(0);
  static const _mesmoToque = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _foco.onKeyEvent = _teclaControle;
    _ctrl.addListener(_processaTexto);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pedeFoco) _foco.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant FraseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modo != widget.modo || oldWidget.passo != widget.passo) _recomecar();
    if (widget.vitoria && !oldWidget.vitoria) _pararEscuta(cancelar: true);
    if (oldWidget.entrada != widget.entrada) _trocouEntrada();
  }

  /// A pessoa trocou o jeito de responder: o que ficou do modo antigo (microfone aberto, recado, tecla em
  /// composição) sai; o que já valeu (erros, dicas, "não sei") fica. Digitar abre o teclado no celular;
  /// Falar e Montar fecham o teclado — SEM mexer no campo escondido (nada de `readOnly`/`enabled`), só no foco.
  void _trocouEntrada() {
    _pararEscuta(cancelar: true);
    _ultimaFala = null;
    _recado = '';
    _leitor.esquecer(_ctrl.text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pedeFoco) {
        _foco.requestFocus();
        if (ehCelular && _digitando) _mostrarTeclado();
      } else if (ehCelular) {
        _foco.unfocus();
      }
    });
  }

  void _recomecar() {
    _balao.fechar();
    _reveladas.clear();
    _desistiu = false;
    _ultimaFoiTab = false;
    _pararEscuta(cancelar: true);
    _errosFala.clear();
    _ultimaFala = null;
    _recado = '';
    // o teclado pode seguir com a palavra que a pessoa não terminou (ela
    // ainda está em composição): o que já está no campo não vale na frase nova
    _leitor.esquecer(_ctrl.text);
  }

  @override
  void dispose() {
    _balao.fechar();
    _pararEscuta(cancelar: true, avisar: false);
    if (widget.focusNode == null) _foco.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _digitou(String ch) {
    if (!_digitando) return; // Falar e Montar não digitam (o computador ainda recebe as teclas)
    _ultimaFoiTab = false;
    context.read<TypingBloc>().add(TeclaDigitada(ch));
  }

  /// Uma frase inteira chegou de uma vez pelo teclado do celular (o 🎤 do
  /// Gboard/iOS): vale como resposta falada, não como cem teclas.
  void _ditou(String frase) => responderPorVoz([frase]);

  void _processaTexto() {
    final v = _ctrl.value;
    if (v.text.isEmpty) {
      _leitor.zerar();
      return;
    }
    if (DateTime.now().difference(_montadoEm) < FraseView.carencia) {
      if (v.composing.isCollapsed) _ctrl.clear();
      return;
    }
    // false = ainda em composição (tecla morta ou ditado em andamento): não mexe
    if (_leitor.ler(v)) _ctrl.clear();
  }

  /// Toque na frase: foco e, no celular, o teclado de volta (com o campo
  /// já focado e o teclado fechado pelo "voltar", só o foco não o reabre).
  void _tocou() {
    if (!_digitando) {
      // Falar e Montar: tocar na moldura não abre o teclado nem fecha o microfone
      if (!ehCelular) _foco.requestFocus();
      return;
    }
    // tocar na frase é "quero digitar": se o microfone estava aberto, fecha
    if (_ouvindo) {
      _pararEscuta(cancelar: true);
      setState(() {});
    }
    _foco.requestFocus();
    if (ehCelular) _mostrarTeclado();
  }

  /// O campo escondido (para achar o editor dele e reabrir o teclado).
  final _campo = GlobalKey();

  /// Abre o teclado do celular. Com o campo já focado e o teclado fechado pela pessoa ("OK", tocar fora), a
  /// conexão com o teclado foi encerrada: só pedir o foco (ou o `TextInput.show`) não a reabre e o teclado não
  /// volta. O `requestKeyboard` do editor reabre a conexão e mostra o teclado — chamado DENTRO do toque, que é
  /// quando o iPhone deixa o teclado subir.
  void _mostrarTeclado() {
    EditableTextState? editor;
    void procura(Element e) {
      if (editor != null) return;
      if (e is StatefulElement && e.state is EditableTextState) {
        editor = e.state as EditableTextState;
        return;
      }
      e.visitChildren(procura);
    }

    _campo.currentContext?.visitChildElements(procura);
    try {
      if (editor != null) {
        editor!.requestKeyboard();
      } else {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show').catchError((_) {});
      }
    } catch (_) {}
  }

  /// Enter do teclado virtual ("ok"/"ir"): faz o que o Enter faz no teclado
  /// físico — e NÃO tira o foco do campo (o padrão do Flutter fecha o teclado).
  void _aoEnviar() {
    final agora = DateTime.now();
    if (agora.difference(_enterTeclaEm) < _mesmoToque) return;
    _enterAcaoEm = agora;
    _enter(repeticao: false, shift: false);
  }

  void _enter({required bool repeticao, required bool shift}) {
    final bloc = context.read<TypingBloc>();
    if (widget.vitoria) {
      widget.onProximaLicao?.call();
    } else if (bloc.state.concluido) {
      widget.onAvancar();
    } else if (entradaAtiva == EntradaResposta.montar) {
      if (!repeticao) _montagem.currentState?.conferir(); // Enter confere a frase montada
    } else if (!repeticao) {
      widget.onOuvir?.call(lenta: shift ? !VozIngles.lentaPorPadrao : VozIngles.lentaPorPadrao);
    }
  }

  /// setState de algo que aparece embaixo da frase (o que foi ouvido, um recado):
  /// no celular, com o teclado aberto, rola para o botão não ficar escondido.
  void _mudou(VoidCallback fn) {
    setState(fn);
    manterContextoVisivel(context);
  }

  // ── microfone ──

  static const _semSuporte =
      'Este navegador não reconhece voz. Toque no 🎤 do seu teclado e fale a frase: '
      'eu confiro do mesmo jeito.';

  static String _textoDoErro(ErroFala e) => switch (e) {
    ErroFala.semPermissao =>
      'O microfone está bloqueado para este site. Libere nas permissões do navegador (o cadeado na barra de endereço) '
          'ou use o 🎤 do teclado.',
    ErroFala.semMicrofone => 'Não achei um microfone neste aparelho.',
    ErroFala.semRede => 'O reconhecimento de voz precisa de internet. Tente de novo quando conectar.',
    ErroFala.naoOuviu => 'Não ouvi nada. Toque no microfone e fale a frase em inglês.',
    ErroFala.naoSuportado => _semSuporte,
    ErroFala.outro => 'Não consegui ouvir agora. Tente de novo.',
  };

  /// 🎤: começa a ouvir (ou, se já está ouvindo, entrega o que ouviu).
  void alternarMicrofone() {
    if (_ouvindo) {
      // 2º toque no "Parar": o navegador não respondeu ao primeiro — solta o microfone na marra
      if (_pediuParar) {
        _soltarMicrofone();
        return;
      }
      _pediuParar = true;
      _escuta?.parar();
      _forcaFim?.cancel();
      _forcaFim = Timer(_esperaParar, _soltarMicrofone);
      return;
    }
    final st = context.read<TypingBloc>().state;
    if (st.concluido || widget.vitoria) return;
    if (_pedeFoco) _foco.requestFocus();
    if (!_rec.suportado) {
      _mudou(() {
        _recado = _semSuporte;
        _ultimaFala = null;
      });
      _mostrarTeclado();
      return;
    }
    widget.onMicrofone?.call(true);
    final vez = ++_vezEscuta;
    _pediuParar = false;
    _forcaFim?.cancel();
    _mudou(() {
      _ouvindo = true;
      _parcial = '';
      _recado = '';
      _ultimaFala = null;
    });
    _escuta = _rec.ouvir(
      aoParcial: (t) {
        if (mounted && vez == _vezEscuta) setState(() => _parcial = t);
      },
      aoFinal: (hipoteses) {
        if (mounted && vez == _vezEscuta) responderPorVoz(hipoteses);
      },
      aoErro: (e) {
        if (mounted && vez == _vezEscuta) _mudou(() => _recado = _textoDoErro(e));
      },
      aoFim: () {
        if (vez != _vezEscuta) return;
        _escuta = null;
        _pediuParar = false;
        _forcaFim?.cancel();
        widget.onMicrofone?.call(false);
        if (mounted) setState(() => _ouvindo = false);
      },
    );
  }

  /// O navegador não respondeu ao "parar" (acontece no Chrome/Safari do iPhone): fecha o microfone à força para a
  /// tela não ficar presa em "Ouvindo…" — a pessoa volta a digitar (ou toca no 🎤 de novo).
  void _soltarMicrofone() {
    _forcaFim?.cancel();
    _forcaFim = null;
    if (!mounted || !_ouvindo) return;
    _pararEscuta(cancelar: true);
    _mudou(() => _recado = 'O microfone não respondeu. Toque no 🎤 para tentar de novo ou digite a frase.');
  }

  void _pararEscuta({bool cancelar = false, bool avisar = true}) {
    _pediuParar = false;
    _forcaFim?.cancel();
    _forcaFim = null;
    if (_escuta == null && !_ouvindo) return;
    _vezEscuta++; // os avisos da escuta velha já não valem
    final e = _escuta;
    _escuta = null;
    if (cancelar) {
      e?.cancelar();
    } else {
      e?.parar();
    }
    if (_ouvindo) {
      _ouvindo = false;
      _parcial = '';
      if (avisar) widget.onMicrofone?.call(false);
    }
  }

  /// A resposta falada (as hipóteses do reconhecedor, ou a frase ditada pelo
  /// teclado) conferida com a frase da vez. Tudo certo = a frase vale como
  /// digitada; senão aparece o que foi ouvido e as palavras erradas contam
  /// como tecla errada (a palavra errada duas vezes é revelada).
  void responderPorVoz(List<String> hipoteses) {
    if (!mounted || widget.vitoria) return;
    final bloc = context.read<TypingBloc>();
    final st = bloc.state;
    if (st.concluido || st.chars.isEmpty) return;
    final frase = st.chars.join();
    final av = avaliarFala(frase, hipoteses, alternativas: widget.alternativas);
    if (av.nada) {
      _mudou(() {
        _recado = 'Não entendi nenhuma palavra. Fale perto do microfone e tente de novo.';
        _ultimaFala = null;
      });
      return;
    }
    if (av.perfeita) {
      setState(() {
        _ultimaFala = null;
        _recado = '';
      });
      bloc.add(const TrechoFalado());
      return;
    }
    final ps = palavrasDe(frase);
    final aRevelar = <int>[];
    for (final w in av.erradas) {
      if (w >= ps.length) continue;
      final n = (_errosFala[ps[w].ini] = (_errosFala[ps[w].ini] ?? 0) + 1);
      if (n >= 2 && widget.modo.deMemoria) aRevelar.addAll([for (var i = ps[w].ini; i < ps[w].fim; i++) i]);
    }
    _mudou(() {
      _ultimaFala = av;
      _recado = '';
    });
    Sons.toca(Som.erro);
    if (aRevelar.isNotEmpty) _revelar(aRevelar);
  }

  /// Conferiu a frase montada e errou: cada palavra fora do lugar conta como tecla errada (a chave é a 1ª letra
  /// da palavra, a mesma da fala e do `avaliarDigitacao`). Montar não revela letras: as pastilhas vermelhas já guiam.
  void _montagemErrou(Map<int, int> erros) {
    if (!mounted || widget.vitoria) return;
    final st = context.read<TypingBloc>().state;
    if (st.concluido || st.chars.isEmpty) return;
    erros.forEach((ini, n) => _errosFala[ini] = (_errosFala[ini] ?? 0) + n);
    Sons.toca(Som.erro);
  }

  /// A frase montada está certa: vale como digitada (o mesmo caminho da fala perfeita).
  void _montagemCerta() {
    if (!mounted || widget.vitoria) return;
    final bloc = context.read<TypingBloc>();
    if (bloc.state.concluido || bloc.state.chars.isEmpty) return;
    bloc.add(const TrechoFalado());
  }

  KeyEventResult _teclaControle(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final bloc = context.read<TypingBloc>();
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.backspace) {
      if (_digitando) bloc.add(const BackspaceApertado());
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      final agora = DateTime.now();
      // a ação do campo (teclado virtual) já cuidou deste Enter
      if (agora.difference(_enterAcaoEm) < _mesmoToque) return KeyEventResult.handled;
      _enterTeclaEm = agora;
      _enter(repeticao: e is! KeyDownEvent, shift: HardwareKeyboard.instance.isShiftPressed);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      if (_balao.aberto) {
        _balao.fechar(); // Esc fecha o balão da palavra (não é "não sei")
      } else if (widget.vitoria) {
        widget.onPularQuiz?.call();
      } else if (e is KeyDownEvent) {
        naoSei();
      }
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.tab) {
      if (e is KeyDownEvent) {
        if (_ultimaFoiTab) {
          revelarPalavra();
        } else {
          revelarLetra();
        }
        _ultimaFoiTab = true;
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static bool _ehLetra(String c) => RegExp(r'[A-Za-z0-9]').hasMatch(c);

  /// Próxima letra a partir do cursor (pula espaço e pontuação).
  int? _proximaLetra(TypingState st) {
    for (var i = st.idx; i < st.chars.length; i++) {
      if (_ehLetra(st.chars[i])) return i;
    }
    return null;
  }

  void _revelar(Iterable<int> posicoes) {
    var revelou = false;
    for (final i in posicoes) {
      revelou |= _reveladas.add(i);
    }
    if (revelou) {
      setState(() {});
      widget.onRevelou?.call();
    }
  }

  /// Tab: revela a próxima letra.
  void revelarLetra() {
    if (!widget.modo.deMemoria) return;
    final st = context.read<TypingBloc>().state;
    if (st.concluido) return;
    final i = _proximaLetra(st);
    if (i != null) _revelar([i]);
  }

  /// Tab duas vezes (ou o 💡): revela o resto da palavra atual.
  void revelarPalavra() {
    if (!widget.modo.deMemoria) return;
    final st = context.read<TypingBloc>().state;
    if (st.concluido) return;
    final ini = _proximaLetra(st);
    if (ini == null) return;
    final ps = <int>[];
    for (var i = ini; i < st.chars.length; i++) {
      final c = st.chars[i];
      if (!_ehLetra(c) && c != "'" && c != '-') break;
      ps.add(i);
    }
    _revelar(ps);
  }

  /// Esc: "não sei" — a frase inteira aparece e vira cópia (nota: errou).
  void naoSei() {
    if (!_podeNaoSei) return;
    final st = context.read<TypingBloc>().state;
    if (st.concluido) return;
    _desistiu = true;
    _revelar([for (var i = st.idx; i < st.chars.length; i++) i]);
    // montando: a frase foi revelada, os blocos recomeçam para ela ser copiada
    _montagem.currentState?.limpar();
  }

  // baseline do placar para tocar o som certo (o listener só vê o estado novo)
  int _somAcertos = 0, _somErros = 0;
  bool _somConcluido = false;

  void _trilhaSonora(TypingState st) {
    if (st.acertosSessao > _somAcertos) {
      Sons.toca(Som.waka);
    } else if (st.errosSessao > _somErros) {
      Sons.toca(Som.erro);
    }
    if (st.concluido && !_somConcluido) Sons.toca(Som.blip);
    _somAcertos = st.acertosSessao;
    _somErros = st.errosSessao;
    _somConcluido = st.concluido;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TypingBloc, TypingState>(
      listenWhen: (a, b) =>
          a.acertosSessao != b.acertosSessao || a.errosSessao != b.errosSessao || a.concluido != b.concluido,
      listener: (_, st) {
        _trilhaSonora(st);
        // no escuro, errar DUAS vezes a mesma letra a revela (conta como dica)
        if (st.ultimoErrou && widget.modo.deMemoria && st.idx < st.chars.length) {
          if ((st.errosPorPosicao[st.idx] ?? 0) >= 2) _revelar([st.idx]);
        }
      },
      child: GestureDetector(
        onTap: _tocou,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Mixart.bg,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Stack(
            children: [
              Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 2, color: Mixart.brandDim)),
              Padding(
                padding: EdgeInsets.fromLTRB(28, 26, 24, ehCelular ? 14 : 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ⌨️ Digitar · 🎤 Falar · 🧩 Montar: o jeito de responder este passo
                    if (widget.onMudarEntrada != null && !widget.vitoria)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: SeletorEntrada(
                          entrada: entradaAtiva,
                          falarDisponivel: _rec.suportado,
                          onMudar: widget.onMudarEntrada!,
                        ),
                      ),
                    BlocBuilder<TypingBloc, TypingState>(
                      builder: (context, st) => LayoutBuilder(builder: (context, box) => _frase(st, box.maxWidth)),
                    ),
                    // no celular digitando: o aviso de caixa e o microfone ficam no fluxo, embaixo da frase
                    // (cada BlocBuilder condicional tem chave: sem ela, ao trocar de modo o Flutter reaproveitava o
                    // estado do vizinho — com a frase vazia de quando a tela nasceu — e os blocos nunca apareciam)
                    if (ehCelular && _digitando)
                      BlocBuilder<TypingBloc, TypingState>(
                        key: const ValueKey('aviso-de-caixa'),
                        buildWhen: (a, b) =>
                            a.idx != b.idx || a.errosDeCaixa != b.errosDeCaixa || a.ultimoErrou != b.ultimoErrou,
                        builder: (context, st) => _avisoDeCaixa(st) ?? const SizedBox.shrink(),
                      ),
                    // o painel do microfone: no celular digitando (ao lado do teclado) e, em Falar, em qualquer aparelho
                    if ((ehCelular && _digitando) || entradaAtiva == EntradaResposta.falar)
                      BlocBuilder<TypingBloc, TypingState>(
                        key: const ValueKey('barra-de-voz'),
                        buildWhen: (a, b) => a.concluido != b.concluido,
                        builder: (context, st) =>
                            st.concluido || widget.vitoria ? const SizedBox.shrink() : _barraDeVoz(),
                      ),
                    // Montar: os blocos de palavras no lugar do teclado (ficam, verdes, até o próximo passo)
                    if (entradaAtiva == EntradaResposta.montar && !widget.vitoria)
                      BlocBuilder<TypingBloc, TypingState>(
                        key: const ValueKey('montagem-de-blocos'),
                        buildWhen: (a, b) => a.chars.join() != b.chars.join(),
                        builder: (context, st) {
                          if (st.chars.isEmpty) return const SizedBox.shrink();
                          final frase = st.chars.join();
                          return MontagemFrase(
                            key: _montagem,
                            frase: frase,
                            apoio: widget.apoioMontagem,
                            extra: widget.extraMontagem,
                            semente: Object.hash(widget.passo, frase) & 0x3fffffff,
                            podeNaoSei: _podeNaoSei,
                            onErrou: _montagemErrou,
                            onCerta: _montagemCerta,
                            onNaoSei: naoSei,
                          );
                        },
                      ),
                  ],
                ),
              ),
              // letra certa com a caixa errada: avisa a regra (é conteúdo)
              if (!ehCelular)
                Positioned(
                  left: 28,
                  right: 24,
                  bottom: 6,
                  child: BlocBuilder<TypingBloc, TypingState>(
                    buildWhen: (a, b) =>
                        a.idx != b.idx || a.errosDeCaixa != b.errosDeCaixa || a.ultimoErrou != b.ultimoErrou,
                    builder: (context, st) => _avisoDeCaixa(st) ?? const SizedBox.shrink(),
                  ),
                ),
              Positioned(
                left: 0,
                top: 0,
                width: 1,
                height: 1,
                child: Opacity(
                  key: _campo,
                  opacity: 0,
                  // invisível, mas no leitor de tela: com a acessibilidade ligada o Flutter
                  // web só digita em campo que está na árvore semântica
                  alwaysIncludeSemantics: true,
                  child: TextField(
                    focusNode: _foco,
                    controller: _ctrl,
                    autofocus: _pedeFoco,
                    maxLines: 1,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.text,
                    // o Enter do teclado virtual não pode fechar o teclado
                    onEditingComplete: _aoEnviar,
                    onTapOutside: (_) {
                      if (_pedeFoco) _foco.requestFocus();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _avisoDeCaixa(TypingState st) {
    if (!st.ultimoErrou || !st.errosDeCaixa.containsKey(st.idx)) return null;
    final c = st.idx < st.chars.length ? st.chars[st.idx] : '';
    final maiuscula = c == c.toUpperCase();
    return Text(
      maiuscula
          ? 'Maiúscula aqui: em inglês I, nomes, dias, meses, idiomas e nacionalidades começam com maiúscula.'
          : 'Minúscula aqui.',
      style: Mixart.ui(size: 11, weight: FontWeight.w600, color: Mixart.brand),
    );
  }

  /// "não sei" (no celular não há Esc) e o microfone, com o que foi ouvido.
  Widget _barraDeVoz() {
    final c = _ultimaFala;
    final Widget? status;
    if (_ouvindo) {
      status = Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: Mixart.danger, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _parcial.isEmpty ? 'Ouvindo… diga a frase em inglês' : '“$_parcial”',
              style: Mixart.ui(
                size: 12.5,
                weight: FontWeight.w600,
                color: Mixart.text,
              ).copyWith(fontStyle: _parcial.isEmpty ? FontStyle.normal : FontStyle.italic, height: 1.35),
            ),
          ),
        ],
      );
    } else if (c != null) {
      final faltaram = c.palavras - c.acertos;
      status = Text.rich(
        TextSpan(
          style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4),
          children: [
            const TextSpan(text: 'Ouvi: '),
            for (var i = 0; i < c.ouvidas.length; i++)
              TextSpan(
                text: '${c.ouvidas[i]} ',
                style: TextStyle(
                  color: c.ouvidaCasou[i] ? Mixart.text : Mixart.danger,
                  fontWeight: FontWeight.w700,
                  decoration: c.ouvidaCasou[i] ? null : TextDecoration.lineThrough,
                ),
              ),
            TextSpan(
              text:
                  '· ${faltaram == 1 ? 'faltou 1 palavra' : 'faltaram $faltaram palavras'} — toque no 🎤 e tente de novo',
              style: TextStyle(color: Mixart.brand, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    } else if (_recado.isNotEmpty) {
      status = Text(_recado, style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4));
    } else if (entradaAtiva == EntradaResposta.falar) {
      status = Text(
        'Toque em “Falar a frase” e diga a frase em inglês.',
        style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4),
      );
    } else {
      status = null;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != null) ...[status, const SizedBox(height: 10)],
          Row(
            children: [
              if (_podeNaoSei)
                InkWell(
                  onTap: () {
                    naoSei();
                    _tocou();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    child: Text(
                      'não sei',
                      style: Mixart.ui(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: Mixart.textMuted,
                      ).copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              // o botão fica à direita; se a tela (ou a fonte) for estreita demais, ele encolhe em vez de estourar
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // celular digitando: um botão que ABRE o teclado (antes só se descobria tocando na frase)
                        if (ehCelular && _digitando) ...[_BotaoTeclado(onTap: _tocou), const SizedBox(width: 8)],
                        _BotaoMicrofone(ouvindo: _ouvindo, onTap: alternarMicrofone),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _frase(TypingState st, double maxWidth) {
    if (st.chars.isEmpty) return const SizedBox(height: 60);
    final frase = st.chars.join();
    final mascara = mascaraDaFrase(frase, widget.mostrarTudo ? ModoFrase.ver : widget.modo);
    // Falar/Montar: o que estaria à vista vira tracinho (a pontuação fica, como no esqueleto)
    if (_cobreResposta) {
      for (var i = 0; i < mascara.length; i++) {
        if (mascara[i] == Mostra.letra && _ehLetra(frase[i])) mascara[i] = Mostra.tracinho;
      }
    }
    final ini = widget.alvo.isEmpty ? -1 : frase.indexOf(widget.alvo);
    final fim = ini < 0 ? -1 : ini + widget.alvo.length;
    final erradas = <int>{};
    if (st.concluido && widget.palavrasErradas.isNotEmpty) {
      final ps = palavrasDe(frase);
      for (final w in widget.palavrasErradas) {
        if (w < ps.length) erradas.addAll([for (var i = ps[w].ini; i < ps[w].fim; i++) i]);
      }
    }

    // letra grande; encolhe só se a palavra mais longa não couber na linha
    final base = maxWidth < 560 ? 22.0 : 30.0;
    final maiorPalavra = frase.split(' ').fold<int>(0, (m, p) => math.max(m, p.length));
    final cabe = maiorPalavra == 0 ? base : (maxWidth - 8) / (maiorPalavra * 0.64);
    final fontSize = math.max(16.0, math.min(base, cabe));
    final estilo = Mixart.mono(size: fontSize).copyWith(height: 1.9, letterSpacing: .4);

    final spans = <InlineSpan>[];
    for (var i = 0; i < st.chars.length; i++) {
      final ch = st.chars[i];
      final feito = i < st.idx;
      final atual = i == st.idx;
      final noAlvo = i >= ini && i < fim;
      final mostra = _reveladas.contains(i) ? Mostra.letra : mascara[i];
      var texto = ch;
      Color cor;
      Color? fundo;
      var peso = FontWeight.w500;
      TextDecoration? deco;
      Color? corDeco;
      if (feito) {
        cor = noAlvo ? Mixart.brand : Mixart.text;
        peso = FontWeight.w600;
        if (erradas.contains(i)) {
          cor = Mixart.danger;
          deco = TextDecoration.underline;
          corDeco = Mixart.danger;
        }
      } else if (mostra == Mostra.nada) {
        cor = Colors.transparent; // ocupa o lugar, mas não entrega nada
      } else if (mostra == Mostra.tracinho) {
        texto = '_';
        cor = Mixart.textHint;
      } else {
        final revelada = _reveladas.contains(i) && widget.modo.deMemoria;
        cor = revelada
            ? Mixart.brand.withValues(alpha: .55)
            : (noAlvo ? Mixart.brand.withValues(alpha: .85) : Mixart.textMuted);
      }
      if (noAlvo && widget.modo == ModoFrase.ver && !feito && mostra == Mostra.letra) {
        deco = TextDecoration.underline;
        corDeco = Mixart.brandDim;
      }
      if (atual && !st.concluido) {
        fundo = st.ultimoErrou ? Mixart.danger : Mixart.brandSub;
        if (st.ultimoErrou) {
          // a posição fica vermelha; a letra só aparece se estiver à vista
          texto = mostra == Mostra.letra ? (ch == ' ' ? '␣' : ch) : (ch == ' ' ? ' ' : '?');
          cor = Colors.white;
        }
      }
      spans.add(
        TextSpan(
          text: texto,
          style: estilo.copyWith(
            color: cor,
            fontWeight: peso,
            backgroundColor: fundo,
            decoration: deco,
            decorationColor: corDeco,
          ),
        ),
      );
    }

    final painter = TextPainter(
      text: TextSpan(children: spans, style: estilo),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final caret = painter.getOffsetForCaret(TextPosition(offset: st.idx.clamp(0, st.chars.length)), Rect.zero);
    // as palavras que dá para tocar: inteiras à vista (digitadas ou mostradas) — coberta não entrega nada
    final aVista = <({int indice, int ini, int fim, Rect caixa})>[];
    final ps = palavrasDe(frase);
    for (var w = 0; w < ps.length; w++) {
      final p = ps[w];
      var visivel = true;
      for (var i = p.ini; i < p.fim && visivel; i++) {
        visivel = i < st.idx || st.concluido || _reveladas.contains(i) || mascara[i] == Mostra.letra;
      }
      if (!visivel) continue;
      for (final b in painter.getBoxesForSelection(TextSelection(baseOffset: p.ini, extentOffset: p.fim))) {
        aVista.add((indice: w, ini: p.ini, fim: p.fim, caixa: b.toRect()));
      }
    }
    _palavrasAVista = aVista;
    final alturaLinha = fontSize * 1.9;
    final pacTam = fontSize * .9;
    final altura = painter.height;
    painter.dispose();

    return GestureDetector(
      key: _chaveFrase,
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) => _tocouNaFrase(d.localPosition),
      child: SizedBox(
        height: altura,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Text.rich(TextSpan(children: spans), style: estilo),
            // Falar e Montar não digitam: o cursor só volta para comemorar a frase concluída
            if (_digitando || st.concluido)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 90),
                left: caret.dx - pacTam - 1,
                top: caret.dy + (alturaLinha - pacTam) / 2,
                child: IgnorePointer(
                  child: Pacman(tamanho: pacTam, venceu: st.concluido),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Onde está a [indice]ª palavra da frase na tela (null = não está à vista para tocar). Para os testes.
  @visibleForTesting
  Rect? caixaDaPalavra(int indice) {
    final caixa = _chaveFrase.currentContext?.findRenderObject();
    final p = _palavrasAVista.where((p) => p.indice == indice).firstOrNull;
    if (caixa is! RenderBox || p == null) return null;
    return Rect.fromPoints(caixa.localToGlobal(p.caixa.topLeft), caixa.localToGlobal(p.caixa.bottomRight));
  }

  /// Toque na frase: numa palavra à vista abre o balão da tradução (sem abrir o teclado); fora delas, é o
  /// toque de sempre ([_tocou]).
  void _tocouNaFrase(Offset pos) {
    final achada = widget.vitoria ? null : _palavrasAVista.where((p) => p.caixa.inflate(3).contains(pos)).firstOrNull;
    if (achada == null) {
      _balao.fechar();
      _tocou();
      return;
    }
    final caixa = _chaveFrase.currentContext?.findRenderObject();
    if (caixa is! RenderBox) return;
    final frase = context.read<TypingBloc>().state.chars.join();
    // a palavra inteira (pode ter quebrado de linha): a união das caixas dela
    var r = achada.caixa;
    for (final p in _palavrasAVista) {
      if (p.indice == achada.indice) r = r.expandToInclude(p.caixa);
    }
    final ancora = Rect.fromPoints(caixa.localToGlobal(r.topLeft), caixa.localToGlobal(r.bottomRight));
    final palavra = frase.substring(achada.ini, achada.fim);
    _balao.abrir(
      context,
      ancora: ancora,
      onOuvir: widget.onOuvirPalavra,
      onTreinar: widget.onTreinarPalavra,
      palavra: PalavraTocada(
        palavra: palavra,
        frase: frase,
        traducao: widget.traducao,
        indice: achada.indice,
        alvo: widget.alvo,
        alvoPt: widget.alvoPt,
      ),
    );
    if (widget.falarPalavraAoTocar) widget.onOuvirPalavra?.call(palavra, lenta: VozIngles.lentaPorPadrao);
    // o foco segue no campo escondido (no computador, dá para continuar digitando)
    if (_pedeFoco && !ehCelular) _foco.requestFocus();
  }
}

/// ⌨️ "Teclado" — abre o teclado do celular para digitar a frase (o mesmo que tocar na frase).
class _BotaoTeclado extends StatelessWidget {
  final VoidCallback onTap;
  const _BotaoTeclado({required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Abrir o teclado para digitar a frase',
    child: Material(
      key: const Key('abrir-teclado'),
      color: Mixart.surfaceHi,
      shape: StadiumBorder(side: BorderSide(color: Mixart.border, width: 1.2)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.keyboard_rounded, size: 20, color: Mixart.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Teclado',
                  style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 🎤 "Falar" — o botão de "mandar áudio": pílula de 48 px (cabe o dedo) que
/// fica vermelha enquanto ouve.
class _BotaoMicrofone extends StatelessWidget {
  final bool ouvindo;
  final VoidCallback onTap;
  const _BotaoMicrofone({required this.ouvindo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cor = ouvindo ? Mixart.danger : Mixart.brand;
    return Semantics(
      button: true,
      label: ouvindo ? 'Parar de ouvir' : 'Falar a frase em inglês',
      child: Material(
        color: cor,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ouvindo ? Icons.stop_rounded : Icons.mic_rounded, size: 20, color: Mixart.onBrand),
                  const SizedBox(width: 8),
                  Text(
                    ouvindo ? 'Parar' : 'Falar a frase',
                    style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.onBrand),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
