import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../curso/presentation/bloc/typing_bloc.dart';
import '../../curso/presentation/fluxo_licao.dart';
import '../../curso/presentation/pages/teoria_page.dart';
import '../../curso/presentation/widgets/victory_overlay.dart';
import '../data/voz_ingles.dart';
import '../domain/alternativas.dart';
import '../domain/avaliacao.dart';
import '../domain/revisao.dart';
import '../domain/roteiro.dart';
import 'fixacao.dart';
import 'revisao_cubit.dart';
import '../../../core/som/sons.dart';
import 'widgets/cena_visual.dart';
import 'widgets/frase_view.dart';
import 'widgets/traducao_card.dart';

/// O palco do PAC·ENGLISH: a tradução em cima, a frase em inglês embaixo
/// e a fila da lição — cada frase sobe a escada (copiar → iniciais →
/// esqueleto → de memória → prova), sempre intercalada com as outras.
class PalcoIngles extends StatefulWidget {
  final CursoState curso;

  /// Voz injetável (testes).
  final VozIngles? voz;

  /// Quanto o feedback de uma digitação de memória fica na tela.
  static Duration esperaFeedback = const Duration(milliseconds: 2500);
  static Duration esperaCopia = const Duration(milliseconds: 700);

  const PalcoIngles({super.key, required this.curso, this.voz});

  @override
  State<PalcoIngles> createState() => _PalcoInglesState();
}

class _PalcoInglesState extends State<PalcoIngles> {
  final _foco = FocusNode();
  final _frase = GlobalKey<FraseViewState>();
  late final VozIngles _voz = widget.voz ?? VozIngles();

  /// Pref: tocar o áudio sozinho (antes da cópia, depois da memória).
  static const prefAudio = 'en_audio_auto';

  late FilaLicao _fila;
  bool _audioAuto = true;
  Timer? _proximo;
  bool _emSequencia = false;

  /// Resultado da digitação de memória que acabou (registrado ao avançar).
  ResultadoRevisao? _pendente;
  bool _pendenteSemCorrecao = false;
  bool _aguardando = false;
  Set<int> _erradas = const {};

  /// Ouviu o áudio antes de terminar uma digitação de memória (conta dica).
  int _ouviuAntes = 0;

  /// "Foi erro de digitação" já usado nesta lição (vale uma vez).
  bool _contestou = false;

  CursoState get curso => widget.curso;
  PassoFila? get _atual => _fila.atual;
  Trecho get _trecho => curso.licao.trechos[_atual!.frase];

  @override
  void initState() {
    super.initState();
    _montarFila();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarPasso());
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _audioAuto = p.getBool(prefAudio) ?? true);
    }).catchError((_) {});
  }

  @override
  void didUpdateWidget(covariant PalcoIngles oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trocouLicao =
        oldWidget.curso.trilhaIdx != curso.trilhaIdx || oldWidget.curso.licaoIdx != curso.licaoIdx;
    final repetiu = oldWidget.curso.vitoria && !curso.vitoria;
    if (trocouLicao || repetiu) {
      _proximo?.cancel();
      _montarFila();
      _carregarPasso();
    }
  }

  @override
  void dispose() {
    _proximo?.cancel();
    _voz.parar();
    _foco.dispose();
    super.dispose();
  }

  void _montarFila() {
    // a semente varia por lição: a rodada final não sai sempre na mesma ordem
    _fila = FilaLicao(curso.licao.trechos.length, semente: curso.trilhaIdx * 1000 + curso.licaoIdx + 7);
    _pendente = null;
    _aguardando = false;
    _erradas = const {};
    _contestou = false;
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
      _ouviuAntes = 0;
    });
    // ouvir ANTES só na estreia (copiar); de memória o áudio entregaria a resposta
    if (_audioAuto && p.estreia) _voz.falar(_trecho.cod);
    _foco.requestFocus();
  }

  /// A frase do passo foi digitada até o fim.
  void _concluiu(TypingState st) {
    final p = _atual;
    if (p == null) return;
    _proximo?.cancel();
    if (p.modo.deMemoria) {
      final fv = _frase.currentState;
      final d = avaliarDigitacao(
        st.chars.join(),
        errosPorPosicao: st.errosPorPosicao,
        reveladas: fv?.reveladas ?? const {},
        desistiu: fv?.desistiu ?? false,
        dicasExtras: _ouviuAntes,
      );
      setState(() {
        _pendente = d.resultado;
        // "não sei" já virou a cópia: não precisa de outra
        _pendenteSemCorrecao = d.desistiu;
        _erradas = d.palavrasErradas;
        _aguardando = true;
      });
      if (_audioAuto) _voz.falar(_trecho.cod);
      // âncora de acerto: o mesmo som e o mesmo brilho toda vez que a frase
      // sai de memória, limpa
      if (d.resultado == ResultadoRevisao.acertou) Sons.toca(Som.gol);
      _proximo = Timer(PalcoIngles.esperaFeedback, _avancar);
    } else {
      setState(() => _aguardando = true);
      if (_audioAuto && p.estreia) _voz.falar(_trecho.cod);
      _proximo = Timer(PalcoIngles.esperaCopia, _avancar);
    }
  }

  void _avancar() {
    _proximo?.cancel();
    if (!mounted || curso.vitoria || _atual == null || !_aguardando) return;
    _fila.registrar(_pendente, semCorrecao: _pendenteSemCorrecao);
    if (!_fila.terminou) {
      _carregarPasso();
      return;
    }
    // fim da lição: as frases entram na revisão espaçada (1ª revisão amanhã)
    // e a prova vira a nota da lição no mapa
    RevisaoCubit.de(context)?.aprender(curso.licao.trechos);
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
    if (mounted) _foco.requestFocus();
  }

  void _repetir() => context.read<CursoBloc>().add(const LicaoRepetida());

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
    _proximo?.cancel();
    setState(() {
      _contestou = true;
      _pendente = contestar(p);
      if (_pendente != ResultadoRevisao.errou) _pendenteSemCorrecao = true;
    });
    _proximo = Timer(PalcoIngles.esperaCopia, _avancar);
    _foco.requestFocus();
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

  @override
  Widget build(BuildContext context) {
    final passo = _atual;
    final revisao = RevisaoCubit.de(context);
    return BlocListener<TypingBloc, TypingState>(
      listenWhen: (a, b) => !a.concluido && b.concluido,
      listener: (_, st) => _concluiu(st),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 60, offset: Offset(0, 24), spreadRadius: -30)],
        ),
        child: Stack(children: [
          if (passo == null)
            const SizedBox(height: 200)
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
                  const SizedBox(height: 16),
                ],
              ],
              _CabecalhoPasso(passo: passo, frase: _trecho.cod, frases: curso.licao.trechos.length),
              const SizedBox(height: 12),
              TraducaoCard(
                trecho: _trecho,
                modo: passo.modo,
                mostrarNota: passo.estreia || passo.correcao,
                audioAuto: _audioAuto,
                onOuvir: () => _ouvir(lenta: false),
                onOuvirDevagar: () => _ouvir(lenta: true),
                onDica: passo.modo.deMemoria ? () => _frase.currentState?.revelarPalavra() : null,
                onNaoSei: passo.modo.deMemoria ? () => _frase.currentState?.naoSei() : null,
                onAlternarAudio: _alternarAudio,
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
                palavrasErradas: _erradas,
                onAvancar: _avancar,
                onOuvir: _ouvir,
                vitoria: curso.vitoria,
                onProximaLicao: _seguir,
                onPularQuiz: _seguir,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 26,
                child: _aguardando
                    ? _Selo(
                        resultado: _pendente,
                        modo: passo.modo,
                        onContestar: _contestou || _pendente == null || _pendente == ResultadoRevisao.acertou
                            ? null
                            : _contestar,
                      )
                    : null,
              ),
              _BarraFila(feitos: _fila.feitos, restantes: _fila.restantes),
            ]),
          if (curso.vitoria)
            VictoryOverlay(
              esperaAuto: null,
              projetosDepois: 0,
              onQuiz: _seguir,
              onPularQuiz: _seguir,
              onRepetir: _repetir,
            ),
        ]),
      ),
    );
  }
}

/// "🧠 De memória · 6 palavras" + o que fazer neste degrau.
class _CabecalhoPasso extends StatelessWidget {
  final PassoFila passo;
  final String frase;
  final int frases;
  const _CabecalhoPasso({required this.passo, required this.frase, required this.frases});

  @override
  Widget build(BuildContext context) {
    final explicacao = passo.correcao
        ? 'Corrija copiando a frase certa'
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
  final VoidCallback? onContestar;
  const _Selo({required this.resultado, required this.modo, this.onContestar});

  @override
  Widget build(BuildContext context) {
    final (texto, cor) = switch (resultado) {
      null => ('✓ Copiada — ela volta daqui a pouco com menos ajuda', Mixart.textMuted),
      ResultadoRevisao.acertou => ('✅ De memória, sem erro!', Mixart.brand),
      ResultadoRevisao.hesitou => ('🟡 Quase — as palavras em vermelho tropeçaram', Mixart.textMuted),
      ResultadoRevisao.errou => ('🔁 Vamos corrigir: copie a frase certa', Mixart.danger),
    };
    return Center(
      child: Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, children: [
        Text('$texto   ·   Enter segue',
            style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: cor), textAlign: TextAlign.center),
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
                    Text('Entenda a lição (explicação em português)',
                        style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.brand)),
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
