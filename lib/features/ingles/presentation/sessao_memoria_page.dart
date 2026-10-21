import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/typing_bloc.dart';
import '../../ia/domain/explicacao.dart';
import '../../ia/presentation/widgets/botao_por_que.dart';
import '../data/voz_ingles.dart';
import '../domain/alternativas.dart';
import '../domain/avaliacao.dart';
import '../domain/revisao.dart';
import '../domain/roteiro.dart';
import '../domain/entrada_resposta.dart' show EntradaResposta;
import '../domain/erros_palavra.dart' show EvidenciaPalavra, FonteErro, evidenciasDaFrase;
import '../domain/teimosas.dart' show LocalSugestao, SugestaoTeimosas;
import '../../../core/som/sons.dart';
import 'acoes_teimosas.dart';
import 'palavras_cubit.dart';
import 'widgets/cartao_teimosas.dart';
import 'widgets/audio_da_frase.dart';
import 'widgets/cena_visual.dart';
import 'widgets/frase_view.dart';
import 'widgets/traducao_card.dart';
import 'widgets/elenco_ingles.dart';
import 'zona_visivel.dart';

/// 🔥 Uma resposta com ajuda (o áudio ouvido antes, ou as iniciais / o esqueleto à vista): as palavras que
/// saíram limpas continuam contando como vistas, mas sem o crédito de "acertou limpo" — uma teimosa não vira
/// DOMINADA com a resposta audível ou meio à mostra. (Uma falha mínima: a carga quase não muda.)
List<EvidenciaPalavra> semCreditoDeAcerto(List<EvidenciaPalavra> evs) => [
      for (final e in evs)
        e.limpa
            ? EvidenciaPalavra(chave: e.chave, peso: e.peso, falha: 0.01, fonte: e.fonte, vistas: e.vistas)
            : e,
    ];

/// Uma frase digitada de memória e como saiu (só a 1ª tentativa conta).
class ResultadoFrase {
  final Trecho trecho;
  final ResultadoRevisao resultado;
  const ResultadoFrase(this.trecho, this.resultado);
}

/// Sessão em que as frases são digitadas DE MEMÓRIA — só a tradução em
/// cima: a Revisão do dia (repetição espaçada) e o Treino de memória da
/// lição. Só a 1ª tentativa de cada frase vale nota; a que sai errada
/// recebe a cópia corrigida na hora e volta na mesma sessão — primeiro no
/// esqueleto, depois de memória — até sair (reaprendizagem sucessiva).
class SessaoMemoriaPage extends StatefulWidget {
  final String titulo, subtitulo, emoji;
  final List<Trecho> itens;

  /// Veio emendada em outra sequência: sair devolve false, terminar true.
  final bool emSequencia;

  /// Cada frase na 1ª tentativa.
  final void Function(ResultadoFrase r)? onResultado;

  /// Fim da sessão com os resultados (1ª tentativa de cada frase).
  final void Function(List<ResultadoFrase> resultados)? onFim;

  /// Frase errada volta na sessão (desligado no teste de nivelamento).
  final bool reaprender;

  /// A lição de onde veio cada frase (a cena volta junto: reencontrar o
  /// contexto ajuda a lembrar). null = sem faixa de cena.
  final Licao? Function(Trecho trecho)? cenaDe;

  /// Mensagem extra no resumo final (ex.: passou ou não no teste).
  final String Function(List<ResultadoFrase> resultados)? resumoExtra;

  final VozIngles? voz;

  const SessaoMemoriaPage({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.emoji = '🧠',
    required this.itens,
    this.emSequencia = false,
    this.onResultado,
    this.onFim,
    this.reaprender = true,
    this.cenaDe,
    this.resumoExtra,
    this.voz,
  });

  @override
  State<SessaoMemoriaPage> createState() => _SessaoMemoriaPageState();
}

/// Um item da fila: a frase, o modo e se é a tentativa que vale nota.
class _Item {
  final Trecho trecho;
  final ModoFrase modo;
  final bool vale;
  final bool correcao;
  const _Item(this.trecho, this.modo, {this.vale = false, this.correcao = false});
}

class _SessaoMemoriaPageState extends State<SessaoMemoriaPage> with WidgetsBindingObserver, VigiaDoTeclado {
  /// Quantas voltas de reaprendizagem uma frase pode ter na sessão.
  static const _maxVoltas = 2;

  final _typing = TypingBloc();
  final _foco = FocusNode();
  final _frase = GlobalKey<FraseViewState>();
  final _zona = GlobalKey();
  late final VozIngles _voz = widget.voz ?? VozIngles();

  late final List<_Item> _fila = [for (final t in widget.itens) _Item(t, ModoFrase.memoria, vale: true)];
  final List<ResultadoFrase> _resultados = [];
  final Map<String, int> _voltas = {};
  int _i = 0;
  ResultadoRevisao? _ultimo;
  Set<int> _erradas = const {};
  bool _aguardando = false;
  bool _fim = false;
  int _ouviuAntes = 0;

  /// Resultado da 1ª tentativa ainda não registrado (vai no avançar, para
  /// o "foi erro de digitação" poder corrigir) e se já foi contestado.
  ResultadoFrase? _aRegistrar;
  bool _desistiuAgora = false;
  bool _contestou = false;

  // ---- 🔥 palavras teimosas (só com o PalavrasCubit: o inglês; nunca no nivelamento) ----
  PalavrasCubit? _palavras;

  /// As evidências da frase que acabou (gravadas ao avançar; "foi erro de digitação" as descarta), as da
  /// sessão (uma chamada ao cubit no fim) e a soma das falhas por palavra.
  List<EvidenciaPalavra>? _evPasso;

  /// A frase que acabou teve ajuda (ouviu antes, ou o esqueleto da reaprendizagem): sem crédito de acerto.
  bool _evPassoSemCredito = false;
  final _evSessao = <EvidenciaPalavra>[];
  final _somaSessao = <String, double>{};
  bool _gravouTeimosas = false;
  SugestaoTeimosas? _sug;

  _Item get _item => _fila[_i];

  @override
  void initState() {
    super.initState();
    _palavras = widget.reaprender ? PalavrasCubit.de(context) : null;
    if (_fila.isEmpty) {
      _fim = true;
    } else {
      _carregar();
    }
  }

  @override
  void aoSubirOTeclado() => manterZonaVisivel(_zona, aindaVale: () => mounted && !_fim);

  @override
  void dispose() {
    // saiu no meio: o que já foi respondido conta
    _gravarTeimosas();
    _voz.parar();
    _typing.close();
    _foco.dispose();
    super.dispose();
  }

  void _carregar() {
    _typing.add(TrechoCarregado(
      _item.trecho.cod,
      tolerante: _item.modo.deMemoria,
      alternativas: _item.modo == ModoFrase.memoria
          ? alternativasDe(_item.trecho.cod, declaradas: _item.trecho.alternativas)
          : const [],
    ));
    _ouviuAntes = 0;
    _ultimo = null;
    _erradas = const {};
    _aguardando = false;
    _evPasso = null;
  }

  /// 🔥 As evidências desta frase de memória (null sem o cubit, sem o índice ou no nivelamento).
  List<EvidenciaPalavra>? _evidenciasDe(TypingState st, FraseViewState? fv) {
    final cubit = _palavras;
    if (cubit == null || cubit.state.indice == null) return null;
    final evs = evidenciasDaFrase(
      st.chars.join(),
      teclas: st.errosPorPosicao,
      extras: fv?.errosDeFala ?? const {},
      entrada: fv?.entradaAtiva ?? EntradaResposta.digitar,
      reveladas: fv?.reveladas ?? const {},
      desistiu: fv?.desistiu ?? false,
      fonte: FonteErro.revisao,
      chaveDe: cubit.chaveDeTreino,
    );
    return evs.isEmpty ? null : evs;
  }

  /// Grava as evidências da sessão (UMA vez: no fim, ou ao sair no meio) e, no fim, monta a oferta.
  void _gravarTeimosas({bool fim = false}) {
    final cubit = _palavras;
    if (cubit == null || _gravouTeimosas) return;
    _gravouTeimosas = true;
    cubit.registrarErros(List.of(_evSessao));
    if (!fim) return;
    _sug = cubit.sugestao(LocalSugestao.fimDeRevisao, daSessao: Map.of(_somaSessao));
    if (_sug != null) cubit.marcarMostrada();
  }

  /// As palavras que tropeçaram nesta sessão (como se escrevem; da que mais deu trabalho para a menos).
  List<String> get _tropecos {
    final ind = _palavras?.state.indice;
    final lista = [for (final e in _somaSessao.entries) if (e.value >= 1) e]
      ..sort((a, b) {
        final s = b.value.compareTo(a.value);
        return s != 0 ? s : a.key.compareTo(b.key);
      });
    return [for (final e in lista.take(8)) ind?.formaDe(e.key) ?? e.key];
  }

  /// Terminou a frase: a voz repete e ela fica na tela até o Enter.
  void _concluiu(TypingState st) {
    final item = _item;
    _voz.falar(item.trecho.cod); // depois de tentar, ouvir confirma
    if (item.modo.deMemoria) {
      final fv = _frase.currentState;
      final d = avaliarDigitacao(
        st.chars.join(),
        errosPorPosicao: somarErros(st.errosPorPosicao, fv?.errosDeFala),
        reveladas: fv?.reveladas ?? const {},
        desistiu: fv?.desistiu ?? false,
        dicasExtras: _ouviuAntes,
      );
      if (item.vale) _aRegistrar = ResultadoFrase(item.trecho, d.resultado);
      if (d.resultado == ResultadoRevisao.acertou) Sons.toca(Som.gol); // âncora de acerto
      _desistiuAgora = d.desistiu;
      _evPasso = _evidenciasDe(st, fv);
      _evPassoSemCredito = _ouviuAntes > 0 || item.modo != ModoFrase.memoria;
      setState(() {
        _ultimo = d.resultado;
        _erradas = d.palavrasErradas;
        _aguardando = true;
      });
    } else {
      setState(() => _aguardando = true);
    }
  }

  /// Errou de memória: cópia corrigida agora (se não foi "não sei", que já
  /// virou cópia), o esqueleto daqui a pouco e de memória no fim.
  void _reaprender(_Item item, {required bool desistiu}) {
    final k = item.trecho.cod;
    final voltas = _voltas[k] ?? 0;
    if (voltas >= _maxVoltas) return;
    _voltas[k] = voltas + 1;
    var pos = _i + 1;
    if (!desistiu) _fila.insert(pos++, _Item(item.trecho, ModoFrase.ver, correcao: true));
    final esqueleto = (pos + 4).clamp(pos, _fila.length);
    _fila.insert(esqueleto, _Item(item.trecho, ModoFrase.esqueleto));
    _fila.add(_Item(item.trecho, ModoFrase.memoria));
  }

  /// Registra a 1ª tentativa (com a contestação, se houve) e agenda a
  /// reaprendizagem da frase errada.
  void _registrarPendente() {
    final res = _aRegistrar;
    _aRegistrar = null;
    final item = _item;
    final r = res?.resultado ?? _ultimo;
    if (res != null) {
      _resultados.add(res);
      widget.onResultado?.call(res);
    }
    // 🔥 as palavras desta frase entram na conta da sessão
    final evs = _evPasso;
    _evPasso = null;
    if (evs != null) {
      _evSessao.addAll(_evPassoSemCredito ? semCreditoDeAcerto(evs) : evs);
      for (final e in evs) {
        if (e.falha > 0) _somaSessao[e.chave] = (_somaSessao[e.chave] ?? 0) + e.peso * e.falha;
      }
    }
    if (item.modo.deMemoria && r == ResultadoRevisao.errou && widget.reaprender) {
      _reaprender(item, desistiu: _desistiuAgora);
    }
  }

  void _contestar() {
    if (_contestou || _ultimo == null || _ultimo == ResultadoRevisao.acertou) return;
    setState(() {
      _contestou = true;
      _evPasso = null; // foi erro de digitação: não conta para as teimosas
      _ultimo = contestar(_ultimo!);
      final res = _aRegistrar;
      if (res != null) _aRegistrar = ResultadoFrase(res.trecho, _ultimo!);
    });
    _foco.requestFocus();
  }

  void _avancar() {
    if (!mounted || _fim || !_aguardando) return;
    _registrarPendente();
    if (_i < _fila.length - 1) {
      setState(() {
        _i++;
        _carregar();
      });
      _foco.requestFocus();
      manterZonaVisivel(_zona, aindaVale: () => mounted && !_fim);
      return;
    }
    _gravarTeimosas(fim: true);
    setState(() => _fim = true);
    widget.onFim?.call(List.unmodifiable(_resultados));
  }

  void _sair({required bool seguir}) => Navigator.of(context).pop(seguir);

  /// Ouvir antes de terminar uma digitação de memória conta como dica.
  void _ouvir({required bool lenta}) {
    if (_fim) return;
    if (_item.modo.deMemoria && !_aguardando) _ouviuAntes++;
    _voz.falar(_item.trecho.cod, lenta: lenta);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _typing,
      child: Scaffold(
        backgroundColor: Mixart.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
                _topo(),
                const SizedBox(height: 16),
                if (_fim) _resumo() else _sessao(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topo() => Row(children: [
        IconButton(
          tooltip: widget.emSequencia ? 'Sair da sequência' : 'Voltar',
          onPressed: () => _sair(seguir: false),
          icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
          style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
        ),
        const SizedBox(width: 12),
        Text(widget.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.titulo, style: Mixart.display(size: 20), overflow: TextOverflow.ellipsis),
            Text(widget.subtitulo, style: Mixart.ui(size: 12, color: Mixart.textMuted), overflow: TextOverflow.ellipsis),
          ]),
        ),
        if (!_fim)
          Text('${_i + 1} / ${_fila.length}', style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textMuted)),
      ]);

  Widget _sessao() {
    final item = _item;
    final palavras = palavrasDe(item.trecho.cod).length;
    final aviso = item.correcao
        ? '🔁 Corrija copiando a frase certa'
        : switch (item.modo) {
            ModoFrase.esqueleto => '▁ Essa voltou: só o tamanho das palavras',
            ModoFrase.memoria when !item.vale => '🧠 …e agora de memória de novo · $palavras palavras',
            _ => '🧠 Digite em inglês, de memória · $palavras palavras',
          };
    return BlocListener<TypingBloc, TypingState>(
      listenWhen: (a, b) => !a.concluido && b.concluido,
      listener: (_, st) => _concluiu(st),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: _i / _fila.length,
            minHeight: 6,
            backgroundColor: Mixart.surfaceHi,
            color: Mixart.brand,
          ),
        ),
        const SizedBox(height: 14),
        Text(aviso, style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.brand)),
        const SizedBox(height: 10),
        if (widget.cenaDe?.call(item.trecho) case final licao? when CenaVisual(licao: licao).temAlgo) ...[
          CenaVisual(licao: licao, compacta: true),
          const SizedBox(height: 10),
        ],
        Column(key: _zona, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TraducaoCard(
            acaoAudio: BotaoAudioDaFrase(frase: item.trecho.cod, voz: _voz, redondo: true),
            rosto: item.trecho.quem.isEmpty
                ? null
                : (tamanho) => PersonagemFalante(
                    key: ValueKey('rosto-${item.trecho.quem}'),
                    quem: item.trecho.quem,
                    frase: item.trecho.cod,
                    tamanho: tamanho,
                  ),
            trecho: item.trecho,
            modo: item.modo,
            mostrarNota: item.correcao,
            onOuvir: () => _ouvir(lenta: false),
            onOuvirDevagar: () => _ouvir(lenta: true),
            onDica: item.modo.deMemoria ? () => _frase.currentState?.revelarPalavra() : null,
            onNaoSei: item.modo.deMemoria ? () => _frase.currentState?.naoSei() : null,
            compacto: tecladoAberto,
          ),
          const SizedBox(height: 14),
          FraseView(
            key: _frase,
            focusNode: _foco,
            modo: item.modo,
            passo: _i,
            alvo: item.trecho.alvo,
            alvoPt: item.trecho.alvoPt,
            traducao: item.trecho.dicaPlana,
            palavrasErradas: _erradas,
            onAvancar: _avancar,
            onOuvir: _ouvir,
            onOuvirPalavra: (palavra, {required lenta}) => _voz.falar(palavra, lenta: lenta),
            alternativas: item.modo == ModoFrase.memoria
                ? alternativasDe(item.trecho.cod, declaradas: item.trecho.alternativas)
                : const [],
            onMicrofone: (ouvindo) {
              if (ouvindo) _voz.calarTudo();
            },
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 28),
            child: _aguardando
                ? _Selo(_ultimo,
                    onSeguir: _avancar,
                    onContestar:
                        _contestou || _ultimo == null || _ultimo == ResultadoRevisao.acertou ? null : _contestar)
                : null,
          ),
          // errou ou tropeçou de memória: o Prof. Dash explica o porquê
          if (_aguardando && _item.modo.deMemoria && (_ultimo == ResultadoRevisao.errou || _ultimo == ResultadoRevisao.hesitou)) ...[
            const SizedBox(height: 6),
            BotaoPorQue(key: ValueKey('por-que-$_i-${_fila.length}'), pedido: _pedidoPorQue(_item)),
          ],
        ]),
        Text(
            ehCelular
                ? '🔊 ouve (conta dica) · 💡 dá a dica · 🎤 fale a frase em inglês · “não sei” mostra a frase'
                : 'Tab = uma letra · Tab Tab = a palavra · Esc = não sei · Enter ouve (conta dica); no fim, Enter segue',
            textAlign: TextAlign.center,
            style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
      ]),
    );
  }

  /// O que a pessoa errou nesta frase, em dados (as palavras que tropeçaram e se desistiu).
  PedidoExplicacao _pedidoPorQue(_Item item) {
    final cod = item.trecho.cod;
    final palavras = palavrasDe(cod);
    return PedidoExplicacao(
      frase: cod,
      traducao: item.trecho.dicaPlana,
      palavrasErradas: [
        for (final i in _erradas.toList()..sort())
          if (i >= 0 && i < palavras.length) cod.substring(palavras[i].ini, palavras[i].fim),
      ],
      exercicio: 'digitar a frase de memória (revisão)',
      desistiu: _desistiuAgora,
    );
  }

  Widget _resumo() {
    final de1 = _resultados.where((r) => r.resultado == ResultadoRevisao.acertou).length;
    final tropeco = _resultados.where((r) => r.resultado == ResultadoRevisao.hesitou).length;
    final voltam = _resultados.where((r) => r.resultado == ResultadoRevisao.errou).length;
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent &&
            (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter)) {
          _sair(seguir: true);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
        ),
        child: Column(children: [
          Text(_resultados.isEmpty ? 'Nada para revisar agora 🎉' : 'Pronto!',
              style: Mixart.display(size: 26, color: Mixart.brand)),
          const SizedBox(height: 14),
          if (_resultados.isNotEmpty)
            Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
              _Placar('✅ DE PRIMEIRA', '$de1'),
              _Placar('🟡 COM TROPEÇO', '$tropeco'),
              _Placar('🔁 VOLTAM LOGO', '$voltam'),
            ]),
          if (widget.resumoExtra != null && _resultados.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(widget.resumoExtra!(_resultados),
                textAlign: TextAlign.center,
                style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.text).copyWith(height: 1.5)),
          ],
          // 🔥 as palavras em que tropeçou (os botões só quando a oferta pode aparecer agora)
          if (_tropecos case final tropecos when tropecos.isNotEmpty) ...[
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListaTeimosas(
                palavras: tropecos,
                onTreinar: _sug == null
                    ? null
                    : () => treinarTeimosas(context, _sug!.palavras, origem: 'revisao', voz: widget.voz),
                onJogar: _sug == null ? null : () => jogarComTeimosas(context, _sug!.palavras),
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Mixart.brand,
              foregroundColor: Mixart.onBrand,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => _sair(seguir: true),
            child: Text('Continuar →', style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.onBrand)),
          ),
        ]),
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  /// null = cópia (de correção): não gera nota.
  final ResultadoRevisao? r;
  final VoidCallback onSeguir;
  final VoidCallback? onContestar;
  const _Selo(this.r, {required this.onSeguir, this.onContestar});

  @override
  Widget build(BuildContext context) {
    final (texto, cor) = switch (r) {
      null => ('✓ Copiada', Mixart.textMuted),
      ResultadoRevisao.acertou => ('✅ De memória, sem erro!', Mixart.brand),
      ResultadoRevisao.hesitou => ('🟡 Quase — as palavras em vermelho tropeçaram', Mixart.textMuted),
      ResultadoRevisao.errou => ('🔁 Essa volta daqui a pouco', Mixart.danger),
    };
    return Center(
      child: Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, children: [
        Text(texto, style: Mixart.ui(size: 13, weight: FontWeight.w800, color: cor)),
        // não avança sozinho: dá para ouvir a frase que acabou de digitar
        BotaoSeguir(onTap: onSeguir, tamanho: 13),
        if (onContestar != null)
          InkWell(
            onTap: onContestar,
            child: Text('foi erro de digitação',
                style: Mixart.ui(size: 11.5, weight: FontWeight.w600, color: Mixart.textMuted)
                    .copyWith(decoration: TextDecoration.underline)),
          ),
      ]),
    );
  }
}

class _Placar extends StatelessWidget {
  final String k, v;
  const _Placar(this.k, this.v);
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 110),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Mixart.bg,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(children: [
          Text(k, style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.textMuted).copyWith(letterSpacing: .8)),
          const SizedBox(height: 6),
          Text(v, style: Mixart.display(size: 20)),
        ]),
      );
}
