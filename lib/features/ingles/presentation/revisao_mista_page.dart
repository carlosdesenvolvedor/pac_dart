import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../../curso/presentation/bloc/typing_bloc.dart';
import '../data/reconhecedor_fala.dart';
import '../data/voz_ingles.dart';
import '../domain/alternativas.dart';
import '../domain/avaliacao.dart';
import '../domain/entrada_resposta.dart' show EntradaResposta;
import '../domain/erros_palavra.dart' show EvidenciaPalavra, FonteErro, evidenciasDaFrase;
import '../domain/revisao.dart';
import '../domain/revisao_mista.dart';
import '../domain/roteiro.dart';
import 'palavras_cubit.dart';
import 'sessao_memoria_page.dart' show semCreditoDeAcerto;
import 'widgets/frase_view.dart';
import 'widgets/traducao_card.dart';
import 'zona_visivel.dart';

/// A 1ª tentativa de um exercício da revisão.
class ResultadoMisto {
  final ExercicioMisto exercicio;
  final ResultadoRevisao resultado;
  const ResultadoMisto(this.exercicio, this.resultado);
}

/// Como a pessoa saiu da revisão.
enum SaidaRevisaoMista { voltou, terminou, maisUma }

/// 🔁 "Revisão até aqui": poucos exercícios (10) com frases de lições já feitas, cada um de um jeito —
/// ✍️ escrever, 🧩 montar com blocos, 👂 escutar e escrever, 🎤 falar ([TipoExercicio]). Escutar e falar têm
/// "não posso escutar / falar agora" (como no Duolingo): o exercício vira outro e o tipo sai do resto da
/// sessão. Só a 1ª tentativa vale nota; a frase errada volta UMA vez no fim, de outro jeito, sem nota.
class RevisaoMistaPage extends StatefulWidget {
  final List<ExercicioMisto> exercicios;

  /// Escutar / falar desligados ao abrir (a pausa de uma hora ainda vale).
  final bool semAudio, semFala;

  /// Cada exercício na 1ª tentativa (a volta do fim não chama).
  final void Function(ResultadoMisto r)? onResultado;

  /// Fim da sessão (todos os exercícios, inclusive as voltas).
  final void Function(List<ResultadoMisto> resultados)? onFim;

  /// "Não posso escutar / falar agora" (quem abriu guarda a pausa).
  final void Function(TipoExercicio tipo)? onDesligar;

  /// Frases em inglês para os blocos de enfeite do 🧩 (além das da própria sessão).
  final List<String> extraMontagem;

  final VozIngles? voz;
  final ReconhecedorFala? reconhecedor;

  /// 🎓 Modo PROVA (a prova final do certificado), com este título no resumo: sem "foi erro de digitação", a
  /// frase errada não volta no fim e não há "mais uma rodada" (a nota é de quem abriu, pelo [onFim]).
  final String? prova;

  const RevisaoMistaPage({
    super.key,
    required this.exercicios,
    this.semAudio = false,
    this.semFala = false,
    this.onResultado,
    this.onFim,
    this.onDesligar,
    this.extraMontagem = const [],
    this.voz,
    this.reconhecedor,
    this.prova,
  });

  @override
  State<RevisaoMistaPage> createState() => _RevisaoMistaPageState();
}

class _RevisaoMistaPageState extends State<RevisaoMistaPage> with WidgetsBindingObserver, VigiaDoTeclado {
  final _typing = TypingBloc();
  final _foco = FocusNode();
  final _frase = GlobalKey<FraseViewState>();
  final _zona = GlobalKey();
  late final VozIngles _voz = widget.voz ?? VozIngles();

  late List<ExercicioMisto> _fila = [...widget.exercicios];
  late bool _semAudio = widget.semAudio, _semFala = widget.semFala;
  final List<ResultadoMisto> _resultados = [];
  int _i = 0;

  /// Muda a cada exercício carregado (inclusive o mesmo trocado de tipo): o FraseView recomeça.
  int _versao = 0;
  ResultadoRevisao? _ultimo;
  Set<int> _erradas = const {};
  bool _aguardando = false;
  bool _fim = false;
  int _ouviuAntes = 0;
  bool _contestou = false;

  // 🔥 palavras teimosas: as evidências de cada frase (gravadas uma vez, no fim ou ao sair)
  PalavrasCubit? _palavras;
  List<EvidenciaPalavra>? _evPasso;
  final _evSessao = <EvidenciaPalavra>[];
  bool _gravou = false;

  ExercicioMisto get _ex => _fila[_i];

  EntradaResposta get _entrada => switch (_ex.tipo) {
        TipoExercicio.blocos => EntradaResposta.montar,
        TipoExercicio.falar => EntradaResposta.falar,
        _ => EntradaResposta.digitar,
      };

  List<String> get _apoio => [for (final e in _fila) if (e.trecho.cod != _ex.trecho.cod) e.trecho.cod];

  @override
  void initState() {
    super.initState();
    _palavras = PalavrasCubit.de(context);
    if (_semAudio) _fila = semOTipo(_fila, TipoExercicio.escutar);
    if (_semFala) _fila = semOTipo(_fila, TipoExercicio.falar);
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
    _gravarTeimosas();
    _voz.parar();
    _typing.close();
    _foco.dispose();
    super.dispose();
  }

  void _gravarTeimosas() {
    final cubit = _palavras;
    if (cubit == null || _gravou) return;
    _gravou = true;
    if (_evSessao.isNotEmpty) cubit.registrarErros(List.of(_evSessao));
  }

  void _carregar() {
    final f = _ex.trecho;
    _typing.add(TrechoCarregado(f.cod,
        tolerante: true, alternativas: alternativasDe(f.cod, declaradas: f.alternativas)));
    _versao++;
    _ouviuAntes = 0;
    _ultimo = null;
    _erradas = const {};
    _aguardando = false;
    _contestou = false;
    _evPasso = null;
    // 👂 escutar: a frase já toca ao aparecer (o toque que abriu a revisão liberou o som)
    if (_ex.tipo == TipoExercicio.escutar && !_semAudio) {
      final versao = _versao;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && versao == _versao) _voz.falar(f.cod);
      });
    }
  }

  void _concluiu(TypingState st) {
    final ex = _ex;
    if (!_semAudio) _voz.falar(ex.trecho.cod); // depois de responder, ouvir confirma
    final fv = _frase.currentState;
    final d = avaliarDigitacao(
      st.chars.join(),
      errosPorPosicao: somarErros(st.errosPorPosicao, fv?.errosDeFala),
      reveladas: fv?.reveladas ?? const {},
      desistiu: fv?.desistiu ?? false,
      // no 👂 ouvir É o exercício; nos outros, ouvir antes de responder conta como dica
      dicasExtras: ex.tipo == TipoExercicio.escutar ? 0 : _ouviuAntes,
    );
    if (d.resultado == ResultadoRevisao.acertou) Sons.toca(Som.gol);
    final cubit = _palavras;
    if (cubit != null && cubit.state.indice != null && !ex.repeticao) {
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
      // blocos e escutar mostram (ou dizem) a frase: as palavras limpas não ganham crédito de acerto
      final ajuda = _ouviuAntes > 0 || ex.tipo == TipoExercicio.blocos || ex.tipo == TipoExercicio.escutar;
      _evPasso = evs.isEmpty ? null : (ajuda ? semCreditoDeAcerto(evs) : evs);
    }
    setState(() {
      _ultimo = d.resultado;
      _erradas = d.palavrasErradas;
      _aguardando = true;
    });
  }

  void _registrar() {
    final ex = _ex, r = _ultimo;
    if (r == null) return;
    final evs = _evPasso;
    _evPasso = null;
    if (evs != null) _evSessao.addAll(evs);
    final res = ResultadoMisto(ex, r);
    _resultados.add(res);
    if (ex.repeticao) return;
    widget.onResultado?.call(res);
    // errou: a frase volta no fim, de outro jeito (uma vez só, sem nota) — na prova, não
    if (r == ResultadoRevisao.errou && widget.prova == null) {
      final tipo = tipoDaVolta(ex);
      _fila.add(ExercicioMisto(ex.trecho, ex.licao, tipo, repeticao: true));
    }
  }

  void _contestar() {
    if (_contestou || _ultimo == null || _ultimo == ResultadoRevisao.acertou) return;
    setState(() {
      _contestou = true;
      _evPasso = null; // foi erro de digitação: não conta para as teimosas
      _ultimo = contestar(_ultimo!);
    });
    _foco.requestFocus();
  }

  void _avancar() {
    if (!mounted || _fim || !_aguardando) return;
    _registrar();
    if (_i < _fila.length - 1) {
      _voz.parar();
      setState(() {
        _i++;
        _carregar();
      });
      _foco.requestFocus();
      manterZonaVisivel(_zona, aindaVale: () => mounted && !_fim);
      return;
    }
    _gravarTeimosas();
    setState(() => _fim = true);
    widget.onFim?.call(List.unmodifiable(_resultados));
  }

  /// "Não posso escutar / falar agora": este e os próximos exercícios desse tipo viram escrever/blocos.
  void _naoPosso(TipoExercicio tipo) {
    if (_aguardando) return;
    widget.onDesligar?.call(tipo);
    _voz.calarTudo();
    setState(() {
      if (tipo == TipoExercicio.escutar) _semAudio = true;
      if (tipo == TipoExercicio.falar) _semFala = true;
      _fila = semOTipo(_fila, tipo, desde: _i);
      _carregar();
    });
    _foco.requestFocus();
  }

  void _ouvir({required bool lenta}) {
    if (_fim) return;
    if (!_aguardando && _ex.tipo != TipoExercicio.escutar) _ouviuAntes++;
    _voz.falar(_ex.trecho.cod, lenta: lenta);
  }

  void _sair(SaidaRevisaoMista s) => Navigator.of(context).pop(s);

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
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 40), children: [
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

  Widget _topo() {
    final feitos = _fim ? _fila.length : _i + (_aguardando ? 1 : 0);
    return Row(children: [
      IconButton(
        key: const Key('revisao-mista-sair'),
        tooltip: 'Sair da revisão',
        onPressed: () => _sair(SaidaRevisaoMista.voltou),
        icon: Icon(Icons.close, color: Mixart.text, size: 20),
        style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: _fila.isEmpty ? 1 : feitos / _fila.length,
            minHeight: 10,
            backgroundColor: Mixart.surfaceHi,
            color: Mixart.brand,
          ),
        ),
      ),
      const SizedBox(width: 12),
      if (!_fim)
        Text('${_i + 1} / ${_fila.length}', style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textMuted)),
    ]);
  }

  Widget _sessao() {
    final ex = _ex;
    final escutar = ex.tipo == TipoExercicio.escutar;
    final titulo = ex.repeticao ? '🔁 Essa voltou · ${ex.tipo.titulo.toLowerCase()}' : '${ex.tipo.emoji} ${ex.tipo.titulo}';
    return BlocListener<TypingBloc, TypingState>(
      listenWhen: (a, b) => !a.concluido && b.concluido,
      listener: (_, st) => _concluiu(st),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, key: const Key('revisao-mista-titulo'), style: Mixart.display(size: 20)),
        const SizedBox(height: 4),
        Text('🔁 da lição “${ex.licao.nome}”',
            overflow: TextOverflow.ellipsis, style: Mixart.ui(size: 12, color: Mixart.textMuted)),
        const SizedBox(height: 12),
        Column(key: _zona, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (escutar && !_aguardando)
            CartaoEscutar(onOuvir: () => _ouvir(lenta: false), onDevagar: () => _ouvir(lenta: true))
          else
            TraducaoCard(
              key: ValueKey('trad-$_versao'),
              trecho: ex.trecho,
              modo: ModoFrase.memoria,
              mostrarNota: _aguardando,
              onOuvir: () => _ouvir(lenta: false),
              onOuvirDevagar: () => _ouvir(lenta: true),
              onDica: ex.tipo == TipoExercicio.escrever || escutar ? () => _frase.currentState?.revelarPalavra() : null,
              onNaoSei: () => _frase.currentState?.naoSei(),
              compacto: tecladoAberto,
            ),
          const SizedBox(height: 14),
          FraseView(
            key: _frase,
            focusNode: _foco,
            modo: ModoFrase.memoria,
            passo: _versao,
            alvo: ex.trecho.alvo,
            alvoPt: ex.trecho.alvoPt,
            traducao: ex.trecho.dicaPlana,
            palavrasErradas: _erradas,
            onAvancar: _avancar,
            onOuvir: _ouvir,
            onOuvirPalavra: (palavra, {required lenta}) => _voz.falar(palavra, lenta: lenta),
            alternativas: alternativasDe(ex.trecho.cod, declaradas: ex.trecho.alternativas),
            entrada: _entrada,
            apoioMontagem: _apoio,
            extraMontagem: widget.extraMontagem,
            reconhecedor: widget.reconhecedor,
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
                    onContestar: widget.prova != null ||
                            _contestou ||
                            _ultimo == null ||
                            _ultimo == ResultadoRevisao.acertou ||
                            _entrada != EntradaResposta.digitar
                        ? null
                        : _contestar)
                : null,
          ),
          // 👂/🎤 como no Duolingo: dá para seguir a revisão sem som ou sem falar
          if (!_aguardando && (escutar || ex.tipo == TipoExercicio.falar)) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                key: Key('revisao-mista-nao-posso-${ex.tipo.id}'),
                onPressed: () => _naoPosso(ex.tipo),
                child: Text(escutar ? '🔇 Não posso escutar agora' : '🙊 Não posso falar agora',
                    style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.textMuted)),
              ),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _resumo() {
    final validos = [for (final r in _resultados) if (!r.exercicio.repeticao) r];
    final de1 = validos.where((r) => r.resultado == ResultadoRevisao.acertou).length;
    final tropeco = validos.where((r) => r.resultado == ResultadoRevisao.hesitou).length;
    final errou = validos.where((r) => r.resultado == ResultadoRevisao.errou).length;
    final pct = validos.isEmpty ? 0 : ((de1 + tropeco * .5) * 100 / validos.length).round();
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent &&
            (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter)) {
          _sair(SaidaRevisaoMista.terminou);
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
          Text(validos.isEmpty ? 'Nada para revisar ainda' : (widget.prova != null ? '${widget.prova}: concluída' : 'Revisão feita! 🎉'),
              textAlign: TextAlign.center, style: Mixart.display(size: 26, color: Mixart.brand)),
          if (validos.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('$pct% de acerto em ${validos.length} exercícios',
                style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.textMuted)),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
              _Placar('✅ DE PRIMEIRA', '$de1'),
              _Placar('🟡 COM TROPEÇO', '$tropeco'),
              _Placar('🔁 PARA REVER', '$errou'),
            ]),
          ] else ...[
            const SizedBox(height: 10),
            Text('Termine uma lição e a revisão aparece aqui.',
                textAlign: TextAlign.center, style: Mixart.ui(size: 13.5, color: Mixart.textMuted)),
          ],
          const SizedBox(height: 20),
          Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
            if (validos.isNotEmpty && widget.prova == null)
              OutlinedButton(
                key: const Key('revisao-mista-mais-uma'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: BorderSide(color: Mixart.brandDim),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: () => _sair(SaidaRevisaoMista.maisUma),
                child: Text('🔀 Mais uma rodada', style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.brand)),
              ),
            FilledButton(
              key: const Key('revisao-mista-continuar'),
              style: FilledButton.styleFrom(
                backgroundColor: Mixart.brand,
                foregroundColor: Mixart.onBrand,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: () => _sair(SaidaRevisaoMista.terminou),
              child: Text('Continuar →', style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.onBrand)),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// 👂 O cartão do escutar: nada escrito (nem o português) — só o 🔊 grande e o 🐢.
class CartaoEscutar extends StatelessWidget {
  final VoidCallback onOuvir, onDevagar;
  const CartaoEscutar({super.key, required this.onOuvir, required this.onDevagar});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            Material(
              color: Mixart.brand,
              shape: const CircleBorder(),
              child: InkWell(
                key: const Key('revisao-mista-ouvir'),
                customBorder: const CircleBorder(),
                onTap: onOuvir,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Icon(Icons.volume_up_rounded, size: 40, color: Mixart.onBrand),
                ),
              ),
            ),
            Material(
              color: Mixart.surfaceHi,
              shape: CircleBorder(side: BorderSide(color: Mixart.border)),
              child: InkWell(
                key: const Key('revisao-mista-devagar'),
                customBorder: const CircleBorder(),
                onTap: onDevagar,
                child: const Padding(padding: EdgeInsets.all(14), child: Text('🐢', style: TextStyle(fontSize: 24))),
              ),
            ),
            Text('Toque para ouvir de novo e escreva\no que ouviu, em inglês',
                textAlign: TextAlign.center, style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4)),
          ],
        ),
      );
}

class _Selo extends StatelessWidget {
  final ResultadoRevisao? r;
  final VoidCallback onSeguir;
  final VoidCallback? onContestar;
  const _Selo(this.r, {required this.onSeguir, this.onContestar});

  @override
  Widget build(BuildContext context) {
    final (texto, cor) = switch (r) {
      null => ('✓', Mixart.textMuted),
      ResultadoRevisao.acertou => ('✅ Isso aí!', Mixart.brand),
      ResultadoRevisao.hesitou => ('🟡 Quase — veja as palavras em vermelho', Mixart.textMuted),
      ResultadoRevisao.errou => ('🔁 Essa volta no fim', Mixart.danger),
    };
    return Center(
      child: Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, children: [
        Text(texto, key: const Key('revisao-mista-selo'), style: Mixart.ui(size: 13, weight: FontWeight.w800, color: cor)),
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
