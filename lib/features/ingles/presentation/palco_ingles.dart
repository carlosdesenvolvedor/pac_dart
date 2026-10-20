import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/mixart.dart';
import '../../../core/ui/festa.dart' show CoresFesta;
import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../curso/presentation/bloc/typing_bloc.dart';
import '../../curso/presentation/fluxo_licao.dart';
import '../../curso/presentation/pages/teoria_page.dart';
import '../../curso/presentation/widgets/victory_overlay.dart';
import '../../habito/presentation/habito_cubit.dart';
import '../../ia/domain/explicacao.dart';
import '../../ia/presentation/widgets/botao_por_que.dart';
import '../data/voz_ingles.dart';
import '../domain/alternativas.dart';
import '../domain/avaliacao.dart';
import '../domain/entrada_resposta.dart';
import '../domain/revisao.dart';
import '../domain/roteiro.dart';
import 'fixacao.dart';
import 'zona_visivel.dart';
import 'revisao_cubit.dart';
import '../../../core/som/sons.dart';
import 'widgets/audio_da_frase.dart';
import 'widgets/cena_visual.dart';
import 'widgets/ensaio_mental.dart';
import 'widgets/frase_view.dart';
import 'widgets/traducao_card.dart';
import 'widgets/elenco_ingles.dart';
import '../domain/palavras_novas.dart';
import '../domain/erros_palavra.dart' show EvidenciaPalavra, FonteErro, evidenciasDaFrase;
import '../domain/teimosas.dart' show LocalSugestao, SugestaoTeimosas, somaDaSessao;
import 'acoes_teimosas.dart';
import 'palavras_cubit.dart';
import 'sessao_memoria_page.dart' show semCreditoDeAcerto;
import 'treino_palavras.dart';
import 'widgets/cartao_palavras_novas.dart';
import 'widgets/cartao_teimosas.dart';

/// O palco do PAC·ENGLISH: a tradução em cima, a frase em inglês embaixo
/// e a fila da lição — cada frase sobe a escada (copiar → iniciais →
/// esqueleto → de memória → prova), sempre intercalada com as outras.
class PalcoIngles extends StatefulWidget {
  final CursoState curso;

  /// Voz injetável (testes).
  final VozIngles? voz;

  const PalcoIngles({super.key, required this.curso, this.voz});

  /// Pref: quantas vezes SEGUIDAS o cartão "🆕 palavras novas" do começo foi pulado (Começar direto ou a 1ª
  /// tecla); "Conhecer antes" zera.
  static const prefPulosAntes = 'en_antes_pulos';

  @override
  State<PalcoIngles> createState() => _PalcoInglesState();
}

class _PalcoInglesState extends State<PalcoIngles> with WidgetsBindingObserver, VigiaDoTeclado {
  final _foco = FocusNode();
  final _frase = GlobalKey<FraseViewState>();

  /// A frase, o aviso e a barra da fila: a zona que o celular mantém à vista
  /// quando o teclado sobe.
  final _zonaDigitacao = GlobalKey();
  late final VozIngles _voz = widget.voz ?? VozIngles();

  /// Pref: tocar o áudio sozinho (antes da cópia e ao terminar a frase).
  static const prefAudio = 'en_audio_auto';

  /// Pref: o 👁 ligado — o inglês à vista em todas as frases.
  static const prefVerFrases = 'en_ver_frases';

  late FilaLicao _fila;
  bool _audioAuto = true;
  bool _vozLenta = VozIngles.lentaPorPadrao;
  bool _verFrases = false;
  bool _emSequencia = false;

  /// O 👁 esteve ligado em algum momento desta digitação de memória.
  bool _viuNestePasso = false;

  /// Como a pessoa responde os passos (⌨️ digitar, 🎤 falar, 🧩 montar). Fica salvo neste aparelho.
  EntradaResposta _entrada = EntradaResposta.padrao;

  /// O jeito como o passo que acabou foi respondido (a nota e o selo dependem dele, mesmo que a pessoa troque depois).
  EntradaResposta _entradaDoPasso = EntradaResposta.padrao;

  /// A nota deste passo caiu para meio ponto só porque foi montado na prova (não há palavra errada para mostrar).
  bool _reduzidaPorMontagem = false;

  /// Resultado da digitação de memória que acabou (registrado ao avançar).
  ResultadoRevisao? _pendente;
  bool _pendenteSemCorrecao = false;
  bool _aguardando = false;
  Set<int> _erradas = const {};

  /// Ouviu o áudio antes de terminar uma digitação de memória (conta dica).
  int _ouviuAntes = 0;

  /// "Foi erro de digitação" já usado nesta lição (vale uma vez).
  bool _contestou = false;

  /// 🎬 Ensaio mental antes da lição, em tela cheia por cima de tudo (um
  /// OverlayPortal: continua sendo deste palco e sobrevive ao redimensionar).
  final _portal = OverlayPortalController();
  final _focoEnsaio = FocusNode(debugLabel: 'ensaio mental');

  /// A vitória: sem frase na tela, é ela que recebe o Enter/Esc (próxima lição).
  final _focoVitoria = FocusNode(debugLabel: 'vitória');

  /// A rota do palco está no topo (sem mapa/revisão por cima).
  bool _noTopo = true;

  /// Pref "ensaio antes da lição" (null = ainda lendo).
  bool? _ensaioLigado;

  /// O ensaio está na tela.
  bool _ensaioAberto = false;

  /// O palco abriu no começo de uma lição: o ensaio é decidido quando a pref
  /// chegar (até lá a frase não recebe tecla nem fala).
  bool _ensaioEsperando = false;

  /// Cada abertura recomeça o roteiro do ensaio.
  int _ensaioVez = 0;

  /// A fala da 1ª frase (estreia) ficou para depois do ensaio.
  bool _vozSegurada = false;

  /// O ensaio desta lição chegou ao sino (passo 1 feito): só então a vitória
  /// repete o som e o gesto — para quem não fez o ensaio, a âncora não é nada.
  bool _ancoraNestaLicao = false;

  /// A lição está sendo repetida (as frases já não são novas).
  bool _repetindo = false;

  /// O texto que VALEU na digitação de memória que acabou (pode ser a alternativa "I am" no lugar de "I'm").
  String _textoAceito = '';

  // ---- 🔥 palavras teimosas (só com o PalavrasCubit: o inglês) ----

  /// As evidências do passo que acabou (gravadas ao avançar; "foi erro de digitação" as descarta).
  List<EvidenciaPalavra>? _evPasso;

  /// O passo teve ajuda (o áudio antes de responder, ou as iniciais / o esqueleto): as palavras limpas dele
  /// contam como vistas, sem o crédito de "acertou limpo".
  bool _evPassoSemCredito = false;

  /// As evidências da lição (uma chamada ao cubit no fim) e a soma das falhas por palavra.
  final _evLicao = <EvidenciaPalavra>[];
  final _somaLicao = <String, double>{};

  /// As palavras já anotadas nesta lição (no máximo 2 avisos) e a do aviso deste passo.
  final _anotadas = <String>[];
  String? _chipAnotada;

  /// As frases onde houve erro (o "📝 Virar lição" procura frases NOVAS para as palavras).
  final _frasesComErro = <String>{};
  List<String> _dominadasDaLicao = const [];
  SugestaoTeimosas? _sug;

  /// O cartão "🆕 Esta lição tem N palavras novas" do começo já saiu (Começar direto, a 1ª tecla ou o
  /// treino): uma vez por visita à lição.
  bool _antesDispensado = false;

  /// Pulado ([PalcoIngles.prefPulosAntes]) tantas vezes seguidas, o cartão do começo vira uma linha só.
  static const _pulosParaCompacto = 3;
  int _pulosAntes = 0;

  /// As palavras do cartão do começo, se ele está na tela neste frame (o ⌘/Ctrl+Enter o abre).
  List<PalavraNova>? _antesNaTela;

  /// O cubit das palavras, guardado no initState (o dispose grava sem o context).
  PalavrasCubit? _cubitPalavras;

  /// As evidências desta visita à lição já foram gravadas (no fim): trocar de lição ou sair não grava de novo.
  bool _gravouLicao = false;

  /// A altura medida do conteúdo da vitória com os cartões (null = ainda não medida: vale a estimativa).
  double? _alturaConteudoVitoria;

  /// Com o ensaio na frente, nenhuma tecla chega à frase e ela não fala.
  bool get _segurandoFrase => _ensaioAberto || _ensaioEsperando;

  CursoState get curso => widget.curso;
  PassoFila? get _atual => _fila.atual;
  Trecho get _trecho => curso.licao.trechos[_atual!.frase];

  @override
  void initState() {
    super.initState();
    _montarFila();
    _ensaioEsperando = !curso.vitoria;
    _portal.show();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarPasso());
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        _audioAuto = p.getBool(prefAudio) ?? true;
        _verFrases = p.getBool(prefVerFrases) ?? false;
        _entrada = PrefsEntrada.ler(p);
        _pulosAntes = p.getInt(PalcoIngles.prefPulosAntes) ?? 0;
        final passo = _atual;
        if (_verFrases && passo != null && passo.modo.deMemoria && !_aguardando) _viuNestePasso = true;
      });
      _decidirEnsaio(p.getBool(EnsaioMental.prefLigado) ?? true);
    }).catchError((_) {
      if (mounted) _decidirEnsaio(true);
    });
    VozIngles.carregarPreferencia().then((lenta) {
      if (mounted) setState(() => _vozLenta = lenta);
    });
    // as palavras novas da lição (o cartão "🎯 Treinar" na vitória): o índice é montado uma vez
    // (e o banco lido: o cartão do começo só aparece se as palavras ainda não foram treinadas)
    final palavras = _cubitPalavras = PalavrasCubit.de(context);
    if (palavras != null) {
      Future.wait([palavras.prepararIndice(curso.trilhas), palavras.carregar()]).then((_) {
        if (mounted) setState(() {});
      }, onError: (_) {});
    }
    // ⌘/Ctrl+Enter abre o "🎯 Conhecer antes": visto ANTES da frase (que fica com o Enter)
    FocusManager.instance.addEarlyKeyEventHandler(_atalhoAntes);
  }

  /// A rota do palco voltou ao topo (fechou o mapa, a revisão…) com o
  /// ensaio aberto: o teclado volta para ele, não para a frase.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final noTopo = ModalRoute.of(context)?.isCurrent ?? true;
    if (noTopo && !_noTopo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _ensaioAberto) _focoEnsaio.requestFocus();
      });
    }
    _noTopo = noTopo;
  }

  @override
  void didUpdateWidget(covariant PalcoIngles oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trocouLicao =
        oldWidget.curso.trilhaIdx != curso.trilhaIdx || oldWidget.curso.licaoIdx != curso.licaoIdx;
    final repetiu = oldWidget.curso.vitoria && !curso.vitoria;
    if (trocouLicao) {
      _ancoraNestaLicao = false;
      _repetindo = false;
    } else if (repetiu) {
      _repetindo = true;
    }
    if (trocouLicao || repetiu) {
      _montarFila();
      // lição nova começa com o ensaio; ao repetir ele pula (o link fica no palco)
      if (trocouLicao && _ensaioLigado == true && !curso.vitoria) _abrirEnsaio(rebuild: false);
      _carregarPasso();
    }
    // a âncora de novo, no pico: o mesmo sino do ensaio (e o gesto, na linha
    // logo abaixo do título da vitória) — só se o ensaio desta lição a armou
    if (!oldWidget.curso.vitoria && curso.vitoria && _ancoraNestaLicao) Sons.toca(Som.ancora);
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_atalhoAntes);
    // saiu no meio da lição: o que já foi respondido conta
    _gravarLicaoInterrompida();
    _voz.parar();
    _foco.dispose();
    _focoEnsaio.dispose();
    _focoVitoria.dispose();
    super.dispose();
  }

  /// 🔥 A lição foi largada no meio (outra lição pelo mapa, ou o palco saiu): as palavras que já tropeçaram
  /// contam — sem oferta. O fim da lição já gravou: não grava de novo. O passo ainda não avançado fica de
  /// fora (podia ser contestado como erro de digitação).
  void _gravarLicaoInterrompida() {
    final cubit = _cubitPalavras;
    if (cubit != null && !cubit.isClosed && !_gravouLicao && _evLicao.isNotEmpty) {
      cubit.registrarErros(List.of(_evLicao));
    }
    _gravouLicao = true;
  }

  void _montarFila() {
    _gravarLicaoInterrompida();
    _gravouLicao = false;
    _alturaConteudoVitoria = null;
    // a semente varia por lição: a rodada final não sai sempre na mesma ordem
    _fila = FilaLicao(curso.licao.trechos.length, semente: curso.trilhaIdx * 1000 + curso.licaoIdx + 7);
    _pendente = null;
    _aguardando = false;
    _erradas = const {};
    _contestou = false;
    _reduzidaPorMontagem = false;
    _evPasso = null;
    _evLicao.clear();
    _somaLicao.clear();
    _anotadas.clear();
    _chipAnotada = null;
    _frasesComErro.clear();
    _dominadasDaLicao = const [];
    _sug = null;
    _antesDispensado = false;
  }

  void _carregarPasso() {
    final p = _atual;
    if (!mounted || p == null) return;
    context.read<TypingBloc>().add(TrechoCarregado(
          _trecho.cod,
          tolerante: p.modo.deMemoria,
          // de memória (N3) vale a forma equivalente: I am ↔ I'm, alt do autor
          alternativas: p.modo == ModoFrase.memoria
              ? alternativasDe(_trecho.cod, declaradas: _trecho.alternativas)
              : const [],
        ));
    final bloc = context.read<CursoBloc>();
    if (bloc.state.trechoIdx != p.frase) bloc.add(TrechoMostrado(p.frase));
    setState(() {
      _pendente = null;
      _aguardando = false;
      _erradas = const {};
      _reduzidaPorMontagem = false;
      _evPasso = null;
      _chipAnotada = null;
      _ouviuAntes = 0;
      _viuNestePasso = _verFrases && p.modo.deMemoria;
    });
    if (_segurandoFrase) {
      // o ensaio está na frente: a fala e o foco esperam ele fechar
      _vozSegurada = _audioAuto && p.estreia;
      return;
    }
    // ouvir ANTES só na estreia (copiar); de memória o áudio entregaria a resposta
    if (_audioAuto && p.estreia) _voz.falar(_trecho.cod);
    _pedirFoco();
    _manterAFraseVisivel();
  }

  /// Pede o foco da frase (o teclado do celular junto) — só quando o jeito de responder usa o teclado: Falar e
  /// Montar no celular não o abrem. No computador o foco segue valendo (Enter, Esc e Tab).
  void _pedirFoco() {
    final e = _frase.currentState?.entradaAtiva ?? _entrada;
    if (abreTeclado(e, celular: ehCelular)) _foco.requestFocus();
  }

  /// A pessoa escolheu outro jeito de responder: vale já neste passo e fica salvo.
  void _mudarEntrada(EntradaResposta e) {
    if (e == _entrada) return;
    setState(() => _entrada = e);
    PrefsEntrada.salvar(e);
    // celular: os blocos (ou o microfone) aparecem embaixo da frase — rola para a zona inteira ficar à vista
    _manterAFraseVisivel();
  }

  /// As outras frases (em inglês) desta lição: dão os blocos de enfeite do Montar.
  List<String> _apoioDoMontar() => [
        for (final t in curso.licao.trechos)
          if (_atual == null || t.cod != _trecho.cod) t.cod,
      ];

  /// Celular: a zona de digitação fica à vista com o teclado aberto.
  @override
  void aoSubirOTeclado() => _manterAFraseVisivel();

  void _manterAFraseVisivel() => manterZonaVisivel(_zonaDigitacao, aindaVale: () => mounted && !_segurandoFrase);

  /// A pref chegou: no começo da lição abre o ensaio (ou libera a frase).
  void _decidirEnsaio(bool ligado) {
    final abre = ligado && _ensaioEsperando && _fila.feitos == 0 && !curso.vitoria;
    setState(() {
      _ensaioLigado = ligado;
      _ensaioEsperando = false;
    });
    if (abre) {
      _abrirEnsaio();
    } else {
      _liberarFrase();
    }
  }

  void _abrirEnsaio({bool rebuild = true}) {
    void abre() {
      _ensaioAberto = true;
      _ensaioVez++;
    }

    rebuild ? setState(abre) : abre();
  }

  /// Enter / Esc / botões do ensaio: a lição começa, com o foco na frase.
  void _fecharEnsaio() {
    if (!_ensaioAberto) return;
    setState(() => _ensaioAberto = false);
    _voz.parar();
    _liberarFrase();
  }

  /// Devolve teclado e voz à frase — depois do frame que tira o ExcludeFocus.
  void _liberarFrase() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _segurandoFrase) return;
      _pedirFoco();
      if (_vozSegurada && _atual != null && !_aguardando) _voz.falar(_trecho.cod);
      _vozSegurada = false;
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// "Não mostrar mais" no próprio ensaio (desmarcar religa).
  void _naoMostrarEnsaio(bool naoMostrar) {
    setState(() => _ensaioLigado = !naoMostrar);
    EnsaioMental.salvarPreferencia(!naoMostrar);
  }

  Widget _ensaio(BuildContext context) => _ensaioAberto
      ? EnsaioMental(
          key: ValueKey('ensaio-${curso.trilhaIdx}:${curso.licaoIdx}-$_ensaioVez'),
          licao: curso.licao,
          voz: _voz,
          onComecar: _fecharEnsaio,
          onPular: _fecharEnsaio,
          naoMostrarMais: _ensaioLigado == false,
          onNaoMostrarMais: _naoMostrarEnsaio,
          focusNode: _focoEnsaio,
          // "áudio automático" desligado: o ensaio também não fala sozinho
          audioAuto: _audioAuto,
          onAncora: () => _ancoraNestaLicao = true,
        )
      : const SizedBox.shrink();

  /// A frase do passo foi digitada até o fim: a voz repete a frase e ela
  /// fica na tela até o Enter (dá para ouvir o que digitou).
  void _concluiu(TypingState st) {
    final p = _atual;
    if (p == null) return;
    if (p.modo.deMemoria && !_viuNestePasso) {
      final fv = _frase.currentState;
      final d = avaliarDigitacao(
        st.chars.join(),
        errosPorPosicao: somarErros(st.errosPorPosicao, fv?.errosDeFala),
        reveladas: fv?.reveladas ?? const {},
        desistiu: fv?.desistiu ?? false,
        dicasExtras: _ouviuAntes,
      );
      // montar é reconhecer: na prova final um montar certo vale meio ponto (digitar e falar valem inteiro)
      final entrada = fv?.entradaAtiva ?? _entrada;
      final nota = notaDaEntrada(d.resultado, entrada: entrada, degrau: p.degrau);
      final aceito = st.chars.join();
      final ev = _evidenciasDoPasso(aceito, st, fv, entrada);
      setState(() {
        _textoAceito = aceito;
        _evPasso = ev;
        // com ajuda (ouviu antes, ou as iniciais / o esqueleto à vista) a palavra limpa não é acerto de memória
        _evPassoSemCredito = _ouviuAntes > 0 || p.modo != ModoFrase.memoria;
        _chipAnotada = _anotacaoDe(ev);
        _entradaDoPasso = entrada;
        _reduzidaPorMontagem = nota != d.resultado;
        _pendente = nota;
        // "não sei" já virou a cópia: não precisa de outra
        _pendenteSemCorrecao = d.desistiu;
        _erradas = d.palavrasErradas;
        _aguardando = true;
      });
      // âncora de acerto: o mesmo som e o mesmo brilho toda vez que a frase
      // sai de memória, limpa
      if (nota == ResultadoRevisao.acertou) Sons.toca(Som.gol);
    } else {
      // cópia (ou de memória com o 👁 ligado): não gera nota
      setState(() {
        _entradaDoPasso = _frase.currentState?.entradaAtiva ?? _entrada;
        _reduzidaPorMontagem = false;
        _aguardando = true;
      });
    }
    if (_audioAuto) _voz.falar(_trecho.cod);
  }

  /// 🔥 As evidências desta digitação de memória (null sem o cubit ou sem o índice: nada é capturado).
  List<EvidenciaPalavra>? _evidenciasDoPasso(String aceito, TypingState st, FraseViewState? fv, EntradaResposta entrada) {
    final cubit = PalavrasCubit.de(context);
    if (cubit == null || cubit.state.indice == null) return null;
    final evs = evidenciasDaFrase(
      aceito,
      teclas: st.errosPorPosicao,
      extras: fv?.errosDeFala ?? const {},
      entrada: entrada,
      reveladas: fv?.reveladas ?? const {},
      desistiu: fv?.desistiu ?? false,
      fonte: FonteErro.licao,
      chaveDe: cubit.chaveDeTreino,
    );
    return evs.isEmpty ? null : evs;
  }

  /// A palavra que passa AGORA (com este passo) de 1,5 de falha na lição: o aviso "📝 anotei" (no
  /// máximo 2 por lição, um por passo). A soma é peso × falha (falar e montar pesam menos).
  String? _anotacaoDe(List<EvidenciaPalavra>? evs) {
    if (evs == null || _anotadas.length >= 2) return null;
    for (final e in evs) {
      if (e.falha <= 0 || _anotadas.contains(e.chave)) continue;
      final antes = _somaLicao[e.chave] ?? 0;
      if (antes < somaDaSessao && antes + e.peso * e.falha >= somaDaSessao) return e.chave;
    }
    return null;
  }

  /// Grava as evidências do passo na lição (ao avançar: a contestação já teve a chance de descartá-las).
  void _gravarPasso() {
    final evs = _evPasso;
    _evPasso = null;
    if (evs == null) return;
    _evLicao.addAll(_evPassoSemCredito ? semCreditoDeAcerto(evs) : evs);
    for (final e in evs) {
      if (e.falha <= 0) continue;
      _somaLicao[e.chave] = (_somaLicao[e.chave] ?? 0) + e.peso * e.falha;
      _frasesComErro.add(_trecho.cod);
    }
    final anotada = _chipAnotada;
    if (anotada != null && !_anotadas.contains(anotada)) _anotadas.add(anotada);
  }

  /// Como [chave] se escreve (o aviso e a linha do "DOMINADA").
  String _formaDe(String chave) => PalavrasCubit.de(context)?.state.indice?.formaDe(chave) ?? chave;

  void _avancar() {
    if (!mounted || curso.vitoria || _atual == null || !_aguardando) return;
    // cada frase digitada conta 1 exercício do dia; a cópia de correção depois de um
    // erro é repetição do erro, não exercício novo
    if (!_atual!.correcao) HabitoCubit.de(context)?.praticou();
    _gravarPasso();
    _fila.registrar(_pendente, semCorrecao: _pendenteSemCorrecao, vista: _viuNestePasso);
    if (!_fila.terminou) {
      _carregarPasso();
      return;
    }
    // fim da lição: as frases entram na revisão espaçada (1ª revisão amanhã)
    // e a prova vira a nota da lição no mapa
    final trechos = curso.licao.trechos;
    RevisaoCubit.de(context)?.aprender(trechos, notas: {
      for (final e in _fila.primeiraProva.entries) RevisaoCubit.chaveDe(trechos[e.key]): e.value,
    });
    // 🔥 as palavras que deram trabalho: UMA gravação por lição e, se der, a oferta "treinar só elas"
    final palavras = PalavrasCubit.de(context);
    _gravouLicao = true;
    if (palavras != null) {
      _dominadasDaLicao = palavras.registrarErros(List.of(_evLicao));
      _sug = palavras.sugestao(LocalSugestao.fimDeLicao, daSessao: Map.of(_somaLicao));
      if (_sug != null) palavras.marcarMostrada();
    }
    final bloc = context.read<CursoBloc>();
    bloc.add(QuizFinalizado(curso.trilhaIdx, curso.licaoIdx, _fila.nota));
    bloc.add(const LicaoFinalizada());
  }

  Future<void> _seguir() async {
    if (!mounted || _emSequencia) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _emSequencia = true;
    await seguirDepoisDaLicao(context, comQuiz: false);
    _emSequencia = false;
    if (mounted) _pedirFoco();
  }

  void _repetir() => context.read<CursoBloc>().add(const LicaoRepetida());

  /// "🎯 Treinar agora" no cartão das palavras novas: a sessão abre por cima; na volta o cartão vira
  /// "✅ Treinadas" e o teclado volta para a vitória (Enter segue).
  Future<void> _treinarPalavras(List<PalavraNova> novas) async {
    await abrirTreinoPalavras(context, novas, titulo: curso.licao.nome, voz: widget.voz);
    if (!mounted) return;
    setState(() {});
    if (curso.vitoria) _focoVitoria.requestFocus();
  }

  /// As palavras já foram treinadas (têm o cartão FSRS no banco ou estão "em treino")?
  static bool _jaTreinadas(PalavrasCubit c, List<PalavraNova> novas) {
    final b = c.state.banco;
    return novas.every((p) => b[p.chave]?.cartao != null || b.emTreino.contains(p.chave));
  }

  /// "🎯 Conhecer antes" (o cartão do começo da lição): o treino das palavras novas abre por cima; na volta
  /// a lição começa normalmente, com o teclado na frase.
  Future<void> _conhecerAntes(List<PalavraNova> novas) async {
    setState(() => _antesDispensado = true);
    _salvarPulos(0);
    _voz.parar();
    await abrirTreinoPalavras(context, novas, titulo: curso.licao.nome, voz: widget.voz, antesDaLicao: true);
    if (!mounted) return;
    setState(() {});
    _pedirFoco();
  }

  /// "Começar direto": o cartão do começo sai e a frase segue com o teclado.
  void _comecarDireto() {
    if (!_antesDispensado) _pularAntes();
    _pedirFoco();
  }

  /// O cartão do começo sai sem treino (Começar direto ou a 1ª tecla): conta um pulo seguido.
  void _pularAntes() {
    if (_antesNaTela != null) _salvarPulos(_pulosAntes + 1);
    setState(() => _antesDispensado = true);
  }

  Future<void> _salvarPulos(int n) async {
    _pulosAntes = n;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(PalcoIngles.prefPulosAntes, n);
    } catch (_) {}
  }

  /// ⌘/Ctrl+Enter com o cartão do começo na tela: "🎯 Conhecer antes" pelo teclado (o cartão fica fora do
  /// foco para a frase receber as teclas; o Enter sozinho continua sendo dela).
  KeyEventResult _atalhoAntes(KeyEvent e) {
    final novas = _antesNaTela;
    if (novas == null || !mounted || _antesDispensado || _segurandoFrase || e is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (e.logicalKey != LogicalKeyboardKey.enter && e.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    final hk = HardwareKeyboard.instance;
    if (!hk.isControlPressed && !hk.isMetaPressed) return KeyEventResult.ignored;
    if (ModalRoute.of(context)?.isCurrent == false) return KeyEventResult.ignored;
    _conhecerAntes(novas);
    return KeyEventResult.handled;
  }

  /// "🎯 Treinar só elas" (a oferta das teimosas na vitória): a revanche abre por cima; na volta a oferta
  /// sai (já foi aceita) e o teclado volta para a vitória.
  Future<void> _treinarTeimosas(SugestaoTeimosas s) async {
    await treinarTeimosas(context, s.palavras, origem: 'fimDeLicao', voz: widget.voz);
    if (!mounted) return;
    setState(() => _sug = null);
    if (curso.vitoria) _focoVitoria.requestFocus();
  }

  /// A altura da vitória (ela cobre o palco). A estimativa vale no 1º frame; depois, com os cartões, vale o
  /// conteúdo MEDIDO (o título e o placar quebram no celular, o "ver" abre o cartão, o "Agora não" o tira):
  /// o placar e os botões cabem sem rolar.
  double _alturaVitoria({required bool comCartao, required bool teimosas, required bool dominadas}) {
    var h = 380.0;
    if (comCartao) h += teimosas ? 44 : 120;
    // a oferta das teimosas; no celular os chips e os botões quebram em mais linhas
    if (teimosas) h += MediaQuery.sizeOf(context).width < 600 ? 360 : 210;
    if (dominadas) h += 34;
    if (_ancoraNestaLicao && (comCartao || teimosas || dominadas)) h += 56;
    final medida = _alturaConteudoVitoria;
    // + o respiro da vitória (20 em cima e embaixo) e uma folga
    if (medida != null && medida + 44 > h) h = medida + 44;
    return h;
  }

  /// Os cartões da vitória mudaram de tamanho (ou acabaram de aparecer): mede o conteúdo inteiro dela (o
  /// filho da rolagem) e ajusta a altura.
  void _mediuExtraDaVitoria(RenderBox extra) {
    if (!mounted || !curso.vitoria) return;
    RenderObject? o = extra;
    while (o != null && o.parent is! RenderAbstractViewport) {
      o = o.parent;
    }
    if (o is! RenderBox || !o.hasSize) return;
    final h = o.size.height;
    final antes = _alturaConteudoVitoria;
    if (antes != null && (h - antes).abs() < 1) return;
    setState(() => _alturaConteudoVitoria = h);
  }

  /// Quem falou [fala] nesta lição (para o "Ana: …" do contexto).
  String _quemDisse(String fala) {
    if (fala.isEmpty) return '';
    for (final t in curso.licao.trechos) {
      if (t.cod == fala) return t.quem;
    }
    return '';
  }

  /// "Foi erro de digitação": a nota sobe um nível (uma vez por lição) e,
  /// se saiu do "errou", não precisa da cópia de correção.
  void _contestar() {
    final p = _pendente;
    if (p == null || _contestou) return;
    setState(() {
      _contestou = true;
      // foi erro de digitação: as palavras desta frase não contam como teimosas
      _evPasso = null;
      _chipAnotada = null;
      _pendente = contestar(p);
      if (_pendente != ResultadoRevisao.errou) _pendenteSemCorrecao = true;
    });
    _pedirFoco();
  }

  /// Ouvir a frase (Enter / 🔊). Numa digitação de memória ainda em curso,
  /// ouvir entrega a resposta: conta como dica.
  void _ouvir({required bool lenta}) {
    final p = _atual;
    if (p != null && p.modo.deMemoria && !_aguardando) setState(() => _ouviuAntes++);
    _voz.falar(_trecho.cod, lenta: lenta);
  }

  Future<void> _alternarAudio() async {
    setState(() => _audioAuto = !_audioAuto);
    if (!_audioAuto) _voz.parar();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(prefAudio, _audioAuto);
    } catch (_) {}
  }

  /// O que a pessoa errou neste passo, em dados (as palavras que tropeçaram e se desistiu).
  PedidoExplicacao _pedidoPorQue(PassoFila passo) {
    // as posições de _erradas são do texto que VALEU (pode ser a alternativa "I am" no lugar de "I'm")
    final texto = _textoAceito.isEmpty ? _trecho.cod : _textoAceito;
    final palavras = palavrasDe(texto);
    return PedidoExplicacao(
      frase: _trecho.cod,
      traducao: _trecho.dicaPlana,
      palavrasErradas: [
        for (final i in _erradas.toList()..sort())
          if (i >= 0 && i < palavras.length) texto.substring(palavras[i].ini, palavras[i].fim),
      ],
      exercicio: 'digitar a frase de memória (${passo.modo.name})',
      desistiu: _frase.currentState?.desistiu ?? false,
    );
  }

  Future<void> _alternarVozLenta() async {
    setState(() => _vozLenta = !_vozLenta);
    await VozIngles.salvarPreferencia(_vozLenta);
    _pedirFoco();
  }

  /// 👁: liga/desliga o inglês à vista em todas as frases (fica salvo).
  Future<void> _alternarVerFrases() async {
    final p = _atual;
    setState(() {
      _verFrases = !_verFrases;
      // viu a frase desta digitação de memória: ela já não vale como memória
      if (_verFrases && p != null && p.modo.deMemoria && !_aguardando) _viuNestePasso = true;
    });
    _pedirFoco();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefVerFrases, _verFrases);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final passo = _atual;
    final revisao = RevisaoCubit.de(context);
    // fim de lição nova (não repetida) com 2+ palavras novas: o cartão "🎯 Treinar" na vitória
    final palavras = curso.vitoria && !_repetindo ? PalavrasCubit.de(context) : null;
    final novas = palavras?.novasDaLicao(curso, curso.licao) ?? const <PalavraNova>[];
    final comCartao = novas.length >= 2;
    // treinadas nesta visita ou antes (o cartão FSRS no banco, ou "em treino"): o cartão vira "✅ já treinou"
    final treinadas = comCartao && _jaTreinadas(palavras!, novas);
    // 🔥 a oferta das teimosas e as palavras dominadas nesta lição (só na vitória)
    final sug = curso.vitoria ? _sug : null;
    final dominadas = curso.vitoria ? _dominadasDaLicao : const <String>[];
    // começo de lição nova (não repetida) com 2+ palavras novas ainda não treinadas: "🎯 Conhecer antes"
    final pc = !_antesDispensado && !curso.vitoria && !_repetindo && passo != null && _fila.feitos == 0
        ? PalavrasCubit.de(context)
        : null;
    final novasAntes =
        pc != null && pc.state.carregado ? pc.novasDaLicao(curso, curso.licao) : const <PalavraNova>[];
    final comAntes = novasAntes.length >= 2 && !_jaTreinadas(pc!, novasAntes);
    _antesNaTela = comAntes ? novasAntes : null;
    // uma linha só: pulado 3+ vezes seguidas, ou na 1ª lição no celular (o nivelamento já está em cima)
    final antesCompacto = _pulosAntes >= _pulosParaCompacto ||
        (curso.concluidas.isEmpty && MediaQuery.sizeOf(context).width < 600);
    return BlocListener<TypingBloc, TypingState>(
      listenWhen: (a, b) => !a.concluido && b.concluido,
      listener: (_, st) => _concluiu(st),
      child: BlocListener<TypingBloc, TypingState>(
        // a 1ª tecla da lição dispensa o cartão do começo (o Enter e o resto seguem como sempre)
        listenWhen: (a, b) => !_antesDispensado && (b.idx > 0 || b.errosPorPosicao.isNotEmpty),
        listener: (_, _) => _pularAntes(),
        child: OverlayPortal(controller: _portal, overlayChildBuilder: _ensaio, child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 60, offset: Offset(0, 24), spreadRadius: -30)],
        ),
        // ensaio aberto: o palco inteiro fica fora do foco (nenhuma tecla chega à frase)
        child: ExcludeFocus(excluding: _segurandoFrase, child: Stack(children: [
          if (passo == null)
            // a vitória cobre o palco: alto o bastante para o placar e os
            // botões caberem sem rolar
            // sem a frase (que tinha o Enter), a vitória pega o teclado: Enter/Esc = próxima lição
            Focus(
              focusNode: _focoVitoria,
              autofocus: curso.vitoria,
              onKeyEvent: (_, e) {
                if (!curso.vitoria || e is! KeyDownEvent) return KeyEventResult.ignored;
                final k = e.logicalKey;
                if (k != LogicalKeyboardKey.enter && k != LogicalKeyboardKey.numpadEnter && k != LogicalKeyboardKey.escape) {
                  return KeyEventResult.ignored;
                }
                _seguir();
                return KeyEventResult.handled;
              },
              child: SizedBox(
                  height: curso.vitoria
                      ? _alturaVitoria(comCartao: comCartao, teimosas: sug != null, dominadas: dominadas.isNotEmpty)
                      : 200),
            )
          else
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_fila.feitos == 0) ...[
                if (curso.concluidas.isEmpty) const _AvisoNivelamento(),
                if (revisao != null)
                  BlocBuilder<RevisaoCubit, RevisaoState>(
                    bloc: revisao,
                    builder: (context, rv) {
                      final n = rv.quantasDevidas(revisao.hoje);
                      return n == 0 ? const SizedBox.shrink() : _AvisoRevisao(quantas: n);
                    },
                  ),
                if (curso.licao.resumo.isNotEmpty || curso.licao.cena.isNotEmpty || curso.licao.temTeoria) ...[
                  _IntroLicaoIngles(curso: curso),
                  const SizedBox(height: 14),
                ],
                if (CenaVisual(licao: curso.licao).temAlgo) ...[
                  CenaVisual(licao: curso.licao),
                  const SizedBox(height: 8),
                ],
                _LinkEnsaio(ligado: _ensaioLigado != false, onAbrir: _abrirEnsaio),
                const SizedBox(height: 12),
                // entra de uma vez (dá para tocar já; zero não pode: o AnimatedSize terminaria dentro do layout) e
                // sai recolhendo: a frase sobe devagar, não pula no meio da tecla
                AnimatedSize(
                  duration: Duration(milliseconds: _antesDispensado ? 200 : 1),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: comAntes
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CartaoAntesDaLicao(
                            key: const Key('antes-palavras'),
                            palavras: novasAntes,
                            onConhecer: () => _conhecerAntes(novasAntes),
                            onComecar: _comecarDireto,
                            compacto: antesCompacto,
                            atalho: ehCelular ? null : _rotuloAtalhoAntes,
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
              _CabecalhoPasso(
                  passo: passo,
                  frase: _trecho.cod,
                  frases: curso.licao.trechos.length,
                  vista: _verFrases && passo.modo.deMemoria),
              const SizedBox(height: 12),
              Column(key: _zonaDigitacao, crossAxisAlignment: CrossAxisAlignment.start, children: [
                TraducaoCard(
                  acaoAudio: BotaoAudioDaFrase(frase: _trecho.cod, voz: _voz, redondo: true),
                  rosto: _trecho.quem.isEmpty
                      ? null
                      : (tamanho) => PersonagemFalante(
                          key: ValueKey('rosto-${_trecho.quem}'),
                          quem: _trecho.quem,
                          frase: _trecho.cod,
                          tamanho: tamanho,
                        ),
                  trecho: _trecho,
                  modo: passo.modo,
                  mostrarNota: passo.estreia || passo.correcao,
                  audioAuto: _audioAuto,
                  onOuvir: () => _ouvir(lenta: false),
                  onOuvirDevagar: () => _ouvir(lenta: true),
                  onDica: passo.modo.deMemoria ? () => _frase.currentState?.revelarPalavra() : null,
                  onNaoSei: passo.modo.deMemoria ? () => _frase.currentState?.naoSei() : null,
                  onAlternarAudio: _alternarAudio,
                  vozLenta: _vozLenta,
                  onAlternarVozLenta: _alternarVozLenta,
                  verFrases: _verFrases,
                  onAlternarVerFrases: _alternarVerFrases,
                  compacto: tecladoAberto,
                  quemDoContexto: _trecho.contextoDe >= 0 && _trecho.contextoDe < curso.licao.trechos.length
                      ? curso.licao.trechos[_trecho.contextoDe].quem
                      : _quemDisse(_trecho.contexto),
                  // a fala anterior em PT até ela ser concluída (o inglês dela ainda está sendo decorado)
                  contextoEmPt: _trecho.contextoDe >= 0 && !_fila.concluida(_trecho.contextoDe),
                ),
                const SizedBox(height: 14),
                FraseView(
                  key: _frase,
                  focusNode: _foco,
                  modo: passo.modo,
                  passo: _fila.feitos,
                  alvo: _trecho.alvo,
                  alvoPt: _trecho.alvoPt,
                  traducao: _trecho.dicaPlana,
                  palavrasErradas: _erradas,
                  onAvancar: _avancar,
                  onOuvir: _ouvir,
                  onOuvirPalavra: (palavra, {required lenta}) => _voz.falar(palavra, lenta: lenta),
                  falarPalavraAoTocar: _audioAuto,
                  vitoria: curso.vitoria,
                  onProximaLicao: _seguir,
                  onPularQuiz: _seguir,
                  mostrarTudo: _verFrases,
                  entrada: _entrada,
                  onMudarEntrada: _mudarEntrada,
                  apoioMontagem: _apoioDoMontar(),
                  alternativas: passo.modo == ModoFrase.memoria
                      ? alternativasDe(_trecho.cod, declaradas: _trecho.alternativas)
                      : const [],
                  // a voz do app cala enquanto a pessoa fala (senão o microfone a ouve)
                  onMicrofone: (ouvindo) {
                    if (ouvindo) _voz.parar();
                  },
                ),
                const SizedBox(height: 10),
                // altura mínima (nada pula ao aparecer), mas cresce: no celular o selo
                // quebra em duas linhas e não pode atropelar a barra da lição
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 26),
                  child: _aguardando
                      ? _Selo(
                          resultado: _pendente,
                          modo: passo.modo,
                          entrada: _entradaDoPasso,
                          porMontagem: _reduzidaPorMontagem,
                          onSeguir: _avancar,
                          // meio ponto por montar na prova não é "erro de digitação": não há o que contestar
                          onContestar: _contestou || _reduzidaPorMontagem || _pendente == null || _pendente == ResultadoRevisao.acertou
                              ? null
                              : _contestar,
                        )
                      : null,
                ),
                // errou ou tropeçou (a cópia não gera nota): o Prof. Dash explica o porquê
                if (_aguardando &&
                    !_reduzidaPorMontagem &&
                    (_pendente == ResultadoRevisao.errou || _pendente == ResultadoRevisao.hesitou)) ...[
                  const SizedBox(height: 6),
                  BotaoPorQue(key: ValueKey('por-que-${_fila.feitos}'), pedido: _pedidoPorQue(passo)),
                ],
                // 🔥 uma palavra que já deu trabalho nesta lição: anotada para o treino (sem botão)
                if (_aguardando && _chipAnotada != null) ...[
                  const SizedBox(height: 6),
                  Center(child: ChipAnotada(_formaDe(_chipAnotada!))),
                  const SizedBox(height: 4),
                ],
                _BarraFila(feitos: _fila.feitos, restantes: _fila.restantes),
              ]),
            ]),
          if (curso.vitoria)
            VictoryOverlay(
              esperaAuto: null,
              projetosDepois: 0,
              onQuiz: _seguir,
              onPularQuiz: _seguir,
              onRepetir: _repetir,
              // no fluxo do placar (nada por cima do título)
              extra: _ancoraNestaLicao || comCartao || sug != null || dominadas.isNotEmpty
                  ? _AoMudarTamanho(aoMudar: _mediuExtraDaVitoria, child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (_ancoraNestaLicao) _LinhaAncora(frases: curso.licao.trechos.length, novas: !_repetindo),
                      if (dominadas.isNotEmpty) ...[
                        if (_ancoraNestaLicao) const SizedBox(height: 10),
                        _LinhaDominadas(palavras: dominadas),
                      ],
                      if (sug != null) ...[
                        if (_ancoraNestaLicao || dominadas.isNotEmpty) const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: CartaoTeimosas(
                            key: const Key('vitoria-teimosas'),
                            palavras: sug.itens,
                            daSessao: sug.daSessao,
                            onTreinar: () => _treinarTeimosas(sug),
                            onJogar: () => jogarComTeimosas(context, sug.palavras),
                            onLicao: () => virarLicao(context, sug.palavras, evitar: Set.of(_frasesComErro)),
                            // a oferta sai: a vitória encolhe e o cartão das palavras novas volta inteiro
                            onAgoraNao: () {
                              PalavrasCubit.de(context)?.adiar();
                              setState(() => _sug = null);
                            },
                          ),
                        ),
                      ],
                      if ((_ancoraNestaLicao || dominadas.isNotEmpty || sug != null) && comCartao)
                        const SizedBox(height: 12),
                      if (comCartao)
                        CartaoPalavrasNovas(
                          key: const Key('vitoria-palavras'),
                          palavras: novas,
                          treinadas: treinadas,
                          compacto: sug != null,
                          onTreinar: () => _treinarPalavras(novas),
                        ),
                    ]))
                  : null,
            ),
        ])),
      ))),
    );
  }
}

/// O atalho do "🎯 Conhecer antes", como o teclado deste computador o escreve.
String get _rotuloAtalhoAntes =>
    defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS ? '⌘ Enter' : 'Ctrl+Enter';

/// Avisa (depois do frame) quando o tamanho do filho muda — e no 1º layout: a vitória acompanha o cartão que
/// abre ("ver") ou sai ("Agora não") sem precisar se reconstruir.
class _AoMudarTamanho extends SingleChildRenderObjectWidget {
  final ValueChanged<RenderBox> aoMudar;
  const _AoMudarTamanho({required this.aoMudar, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderAoMudarTamanho(aoMudar);

  @override
  void updateRenderObject(BuildContext context, _RenderAoMudarTamanho renderObject) => renderObject.aoMudar = aoMudar;
}

class _RenderAoMudarTamanho extends RenderProxyBox {
  _RenderAoMudarTamanho(this.aoMudar);
  ValueChanged<RenderBox> aoMudar;
  Size? _antes;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _antes) return;
    _antes = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) aoMudar(this);
    });
  }
}

/// "🏆 "through" DOMINADA! Saiu da lista de teimosas" — na vitória, para cada palavra que a lição fechou.
class _LinhaDominadas extends StatelessWidget {
  final List<String> palavras;
  const _LinhaDominadas({required this.palavras});

  @override
  Widget build(BuildContext context) {
    final aspas = [for (final p in palavras) '"$p"'];
    final texto = palavras.length == 1
        ? '🏆 ${aspas.first} DOMINADA! Saiu da lista de teimosas'
        : '🏆 ${aspas.sublist(0, aspas.length - 1).join(', ')} e ${aspas.last} DOMINADAS! Saíram da lista de teimosas';
    return Center(
      child: Container(
        key: const Key('vitoria-dominadas'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: CoresFesta.ouro.withValues(alpha: .16),
          border: Border.all(color: CoresFesta.ouro.withValues(alpha: .7)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(texto,
            textAlign: TextAlign.center,
            style: Mixart.ui(size: 12.5, weight: FontWeight.w800, color: Mixart.text).copyWith(height: 1.35)),
      ),
    );
  }
}

/// No começo da lição: rever o ensaio mental sob demanda (e religá-lo, se
/// foi desligado no "não mostrar mais").
class _LinkEnsaio extends StatelessWidget {
  final bool ligado;
  final VoidCallback onAbrir;
  const _LinkEnsaio({required this.ligado, required this.onAbrir});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onAbrir,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: ligado ? '🎬 rever o ensaio mental' : '🎬 ensaio mental',
                style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.brand)),
            TextSpan(
                text: ligado ? ' · 20 s de cena e frases antes de digitar' : ' · desligado — toque para ver (e religar)',
                style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
          ])),
        ),
      );
}

/// A âncora de volta na vitória: o mesmo gesto do ensaio, ligado ao que a
/// pessoa acabou de conseguir.
class _LinhaAncora extends StatelessWidget {
  final int frases;

  /// false = lição repetida: as frases já não são novas.
  final bool novas;
  const _LinhaAncora({required this.frases, this.novas = true});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Mixart.spring,
          builder: (_, v, filho) => Opacity(opacity: v, child: filho),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Mixart.brandSub,
                border: Border.all(color: Mixart.brandDim),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '👌 Junte o polegar e o indicador: você acabou de usar '
                '$frases ${frases == 1 ? 'frase' : 'frases'}${novas ? (frases == 1 ? ' nova' : ' novas') : ''} em inglês.',
                textAlign: TextAlign.center,
                style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.text).copyWith(height: 1.4),
              ),
            ),
          ),
        ),
      );
}

/// "🧠 De memória · 6 palavras" + o que fazer neste degrau.
class _CabecalhoPasso extends StatelessWidget {
  final PassoFila passo;
  final String frase;
  final int frases;

  /// 👁 ligado num degrau de memória: a frase está à vista.
  final bool vista;
  const _CabecalhoPasso({required this.passo, required this.frase, required this.frases, this.vista = false});

  @override
  Widget build(BuildContext context) {
    final explicacao = passo.correcao
        ? 'Corrija copiando a frase certa'
        : vista
            ? '👁 Frase à vista — desligue o olho para treinar de memória'
            : switch (passo.degrau) {
            Degrau.conhecer => 'Ouça e copie com atenção',
            Degrau.iniciais => 'Complete a partir das iniciais',
            Degrau.esqueleto => 'Só o tamanho das palavras',
            Degrau.memoria => 'Só com a tradução',
            Degrau.prova => 'Prova da lição: de memória',
          };
    final palavras = palavrasDe(frase).length;
    final rotulo = passo.correcao
        ? '🔁 Correção'
        : '${passo.modo.emoji} ${passo.degrau == Degrau.prova ? 'Prova' : passo.modo.rotulo}'
            '${passo.modo == ModoFrase.memoria ? ' · $palavras palavras' : ''}';
    final forte = passo.modo == ModoFrase.memoria && !passo.correcao;
    return Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: forte ? Mixart.brand : Mixart.brandSub,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(rotulo,
            style: Mixart.ui(size: 12, weight: FontWeight.w800, color: forte ? Mixart.onBrand : Mixart.brand)),
      ),
      Text(explicacao, style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
      Text('frase ${passo.frase + 1} de $frases · ${passo.vez}ª vez',
          style: Mixart.ui(size: 11.5, weight: FontWeight.w600, color: Mixart.textFaint)),
    ]);
  }
}

/// Como saiu a digitação que acabou de terminar.
class _Selo extends StatelessWidget {
  final ResultadoRevisao? resultado;
  final ModoFrase modo;
  final EntradaResposta entrada;

  /// O resultado é meio ponto só porque foi montado na prova (nenhuma palavra errada).
  final bool porMontagem;
  final VoidCallback onSeguir;
  final VoidCallback? onContestar;
  const _Selo({
    required this.resultado,
    required this.modo,
    required this.onSeguir,
    this.entrada = EntradaResposta.digitar,
    this.porMontagem = false,
    this.onContestar,
  });

  @override
  Widget build(BuildContext context) {
    final (texto, cor) = switch (resultado) {
      null => ('✓ Feita — ela volta daqui a pouco com menos ajuda', Mixart.textMuted),
      ResultadoRevisao.acertou when entrada == EntradaResposta.montar => ('✅ Montou certinho, sem erro!', Mixart.brand),
      ResultadoRevisao.acertou when entrada == EntradaResposta.falar => ('✅ Falou certinho, sem erro!', Mixart.brand),
      ResultadoRevisao.acertou => ('✅ De memória, sem erro!', Mixart.brand),
      ResultadoRevisao.hesitou when porMontagem =>
        ('🧩 Montou certo! Na prova, montar vale meio ponto — digite ou fale para valer inteiro', Mixart.textMuted),
      ResultadoRevisao.hesitou => ('🟡 Quase — as palavras em vermelho tropeçaram', Mixart.textMuted),
      ResultadoRevisao.errou => ('🔁 Vamos corrigir: copie a frase certa', Mixart.danger),
    };
    return Center(
      child: Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, children: [
        Text(texto, style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: cor), textAlign: TextAlign.center),
        // não avança sozinho: dá para ouvir a frase que acabou de digitar
        BotaoSeguir(onTap: onSeguir, tamanho: 12.5),
        if (onContestar != null)
          InkWell(
            onTap: onContestar,
            borderRadius: BorderRadius.circular(6),
            child: Text('foi erro de digitação',
                style: Mixart.ui(size: 11.5, weight: FontWeight.w600, color: Mixart.textMuted)
                    .copyWith(decoration: TextDecoration.underline)),
          ),
      ]),
    );
  }
}

class _BarraFila extends StatelessWidget {
  final int feitos, restantes;
  const _BarraFila({required this.feitos, required this.restantes});

  @override
  Widget build(BuildContext context) {
    final total = feitos + restantes;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Lição', style: Mixart.ui(size: 11, color: Mixart.textMuted)),
        Text('$feitos / $total digitações', style: Mixart.ui(size: 11, color: Mixart.textMuted)),
      ]),
      const SizedBox(height: 6),
      BlocBuilder<TypingBloc, TypingState>(
        buildWhen: (a, b) => a.progresso != b.progresso,
        builder: (context, typing) => ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : ((feitos + typing.progresso) / total).clamp(0, 1),
            minHeight: 8,
            backgroundColor: Mixart.surfaceHi,
            color: Mixart.brand,
          ),
        ),
      ),
    ]);
  }
}

/// Começo do curso: quem já sabe inglês não precisa começar do zero.
class _AvisoNivelamento extends StatelessWidget {
  const _AvisoNivelamento();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Mixart.bg,
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
            onTap: () => abrirNivelamento(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                border: Border.all(color: Mixart.border),
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
              ),
              child: Row(children: [
                const Text('🧭', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Já sabe algum inglês? Faça o nivelamento: 15 frases de memória por nível, '
                    'e você pula o que já domina. Começando do zero? É só seguir aqui embaixo.',
                    style: Mixart.ui(size: 12.5, weight: FontWeight.w600, color: Mixart.text).copyWith(height: 1.4),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Nivelar →', style: Mixart.ui(size: 12.5, weight: FontWeight.w800, color: Mixart.brand)),
              ]),
            ),
          ),
        ),
      );
}

/// Lembrete: revisar as frases que vencem hoje ANTES da lição nova.
class _AvisoRevisao extends StatelessWidget {
  final int quantas;
  const _AvisoRevisao({required this.quantas});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Mixart.brandSub,
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
            onTap: () => abrirRevisao(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                border: Border.all(color: Mixart.brandDim),
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
              ),
              child: Row(children: [
                const Text('🔁', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$quantas frase${quantas == 1 ? '' : 's'} para revisar hoje — revise primeiro: '
                    'lembrar o que já viu antes de aprender mais é o que fixa.',
                    style: Mixart.ui(size: 12.5, weight: FontWeight.w600, color: Mixart.text).copyWith(height: 1.4),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Revisar →', style: Mixart.ui(size: 12.5, weight: FontWeight.w800, color: Mixart.brand)),
              ]),
            ),
          ),
        ),
      );
}

/// Resumo da lição + acesso à explicação (antes da 1ª digitação).
class _IntroLicaoIngles extends StatelessWidget {
  final CursoState curso;
  const _IntroLicaoIngles({required this.curso});

  @override
  Widget build(BuildContext context) {
    final licao = curso.licao;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Mixart.bg,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(licao.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(licao.nome, style: Mixart.display(size: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Mixart.surfaceHi, borderRadius: BorderRadius.circular(999)),
                child: Text('${licao.trechos.length} frases · cada uma 5×',
                    style: Mixart.ui(size: 10, weight: FontWeight.w600, color: Mixart.textMuted)),
              ),
            ]),
            if (licao.cena.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text('📍 ${licao.cena}', style: Mixart.ui(size: 12.5, color: Mixart.text).copyWith(height: 1.5)),
            ],
            if (licao.resumo.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(licao.resumo, style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5)),
            ],
            if (licao.temTeoria) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => TeoriaPage(
                      nivel: curso.trilha.nivel, fundo: curso.trilha.fundo, licao: licao, onPraticar: () {}),
                )),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.menu_book_outlined, size: 14, color: Mixart.brand),
                    const SizedBox(width: 6),
                    // Flexible: em tela estreita (celular) o texto quebra de linha em vez de vazar do card
                    Flexible(
                      child: Text('Entenda a lição (explicação em português)',
                          style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.brand)),
                    ),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
