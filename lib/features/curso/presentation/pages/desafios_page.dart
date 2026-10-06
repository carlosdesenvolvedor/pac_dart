import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/som/sons.dart';
import '../../../../core/syntax/codigo_colorido.dart';
import '../../../../core/theme/mixart.dart';
import '../../../ranking/presentation/ranking_cubit.dart';
import '../../domain/conferir_desafio.dart';
import '../../domain/curriculo.dart';
import '../bloc/curso_bloc.dart';
import '../widgets/botao_pular.dart';
import '../widgets/fundo_fase.dart';

/// Desafios de lógica de uma trilha — não são de digitação: prever a saída,
/// dizer o valor final, completar a lacuna, pôr linhas em ordem, achar o bug
/// e perguntas de conceito, só com o que a trilha (e as anteriores) ensinou.
///
/// Começa pelos que ainda não foram acertados (do mais fácil ao mais
/// difícil); com tudo resolvido, vira treino livre com todos. Cada acerto
/// NOVO marca a conquista no progresso e vale pontos no ranking.
class DesafiosPage extends StatefulWidget {
  final int trilhaIdx;
  final Trilha trilha;

  /// Veio emendado depois das lições/projetos: ganha "pular" e devolve true.
  final bool emSequencia;

  /// Semente do embaralhamento (testes determinísticos).
  final int? semente;

  const DesafiosPage({
    super.key,
    required this.trilhaIdx,
    required this.trilha,
    this.emSequencia = false,
    this.semente,
  });

  @override
  State<DesafiosPage> createState() => _DesafiosPageState();
}

class _DesafiosPageState extends State<DesafiosPage> {
  late final Random _rnd = Random(widget.semente ?? widget.trilhaIdx * 7919 + DateTime.now().millisecond);
  late List<int> _fila;
  var _pos = 0;
  var _acertos = 0;
  var _novos = 0;
  bool? _acertou; // null = ainda respondendo
  int? _escolhida;
  final _resposta = TextEditingController();
  final _focoResposta = FocusNode();
  final _foco = FocusNode();

  // ordenar
  List<int> _cartoes = [];
  List<int> _montados = [];

  bool _fim = false;

  /// Capturado no initState: no dispose o context já não acha o cubit.
  RankingCubit? _ranking;

  List<DesafioLogica> get _desafios => widget.trilha.desafios;
  int get _atualIdx => _fila[_pos];
  DesafioLogica get _d => _desafios[_atualIdx];

  @override
  void initState() {
    super.initState();
    _ranking = RankingCubit.de(context);
    _montarFila();
    _prepararAtual();
  }

  @override
  void dispose() {
    _resposta.dispose();
    _focoResposta.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _montarFila() {
    final st = context.read<CursoBloc>().state;
    bool feito(int i) => st.projetoFeito(CursoState.chaveDesafio(widget.trilhaIdx, i));
    var fila = [for (var i = 0; i < _desafios.length; i++) if (!feito(i)) i];
    if (fila.isEmpty) fila = List.generate(_desafios.length, (i) => i);
    fila.shuffle(_rnd);
    fila.sort((a, b) => _desafios[a].nivel.compareTo(_desafios[b].nivel)); // estável: embaralha dentro do nível
    _fila = fila;
  }

  void _prepararAtual() {
    _acertou = null;
    _escolhida = null;
    _resposta.clear();
    if (_fila.isEmpty) return;
    if (_d.tipo == TipoDesafioLogica.ordenar) {
      _cartoes = List.generate(_d.linhas.length, (i) => i)..shuffle(_rnd);
      // nunca começa já na ordem certa
      var tentativas = 0;
      while (tentativas++ < 5 && List.generate(_cartoes.length, (i) => i).every((i) => _cartoes[i] == i)) {
        _cartoes.shuffle(_rnd);
      }
      _montados = [];
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_d.tipo == TipoDesafioLogica.valor) {
        _focoResposta.requestFocus();
      } else {
        _foco.requestFocus();
      }
    });
  }

  void _registrar(bool certo) {
    final chave = CursoState.chaveDesafio(widget.trilhaIdx, _atualIdx);
    final bloc = context.read<CursoBloc>();
    final novo = certo && !bloc.state.projetoFeito(chave);
    setState(() {
      _acertou = certo;
      if (certo) _acertos++;
      if (novo) _novos++;
    });
    if (certo) bloc.add(ProjetoConcluido(chave));
    // cada acerto NOVO pontua na hora (sair no meio não perde nada)
    if (novo) _ranking?.desafiosResolvidos(1);
    Sons.toca(certo ? Som.blip : Som.erro);
    // o campo de resposta fica desabilitado: o Enter volta para a página
    // (Enter = próximo desafio)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _foco.requestFocus();
    });
  }

  void _escolher(int i) {
    if (_acertou != null) return;
    _escolhida = i;
    _registrar(i == _d.certa);
  }

  /// Desafio "ache o bug": tocou numa linha.
  void _escolherLinha(int i) {
    if (_acertou != null) return;
    _escolhida = i;
    _registrar(i == _d.linhaBug);
  }

  void _responderValor() {
    if (_acertou != null) return;
    if (_resposta.text.trim().isEmpty) {
      _focoResposta.requestFocus();
      return;
    }
    _registrar(confereValor(_resposta.text, _d));
  }

  void _conferirOrdem() {
    if (_acertou != null || _montados.length != _d.linhas.length) return;
    _registrar(confereOrdem([for (final i in _montados) _d.linhas[i]], _d));
  }

  void _proximo() {
    if (_acertou == null) return;
    if (_pos + 1 >= _fila.length) {
      setState(() => _fim = true);
      return;
    }
    setState(() {
      _pos++;
      _prepararAtual();
    });
  }

  void _reiniciar() {
    setState(() {
      _pos = 0;
      _acertos = 0;
      _novos = 0;
      _fim = false;
      _montarFila();
      _prepararAtual();
    });
  }

  KeyEventResult _tecla(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      if (_fim) {
        Navigator.of(context).pop(true);
        return KeyEventResult.handled;
      }
      if (_acertou != null) {
        _proximo();
        return KeyEventResult.handled;
      }
      if (_d.tipo == TipoDesafioLogica.ordenar) {
        _conferirOrdem();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (_fim || _acertou != null) return KeyEventResult.ignored;
    final opcoes = switch (_d.tipo) {
      TipoDesafioLogica.saida || TipoDesafioLogica.lacuna || TipoDesafioLogica.escolha => _d.opcoes.length,
      _ => 0,
    };
    const numeros = [LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4];
    const letras = [LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyB, LogicalKeyboardKey.keyC, LogicalKeyboardKey.keyD];
    for (var i = 0; i < opcoes && i < 4; i++) {
      if (k == numeros[i] || k == letras[i]) {
        _escolher(i);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: Focus(
        focusNode: _foco,
        autofocus: true,
        onKeyEvent: _tecla,
        child: Stack(children: [
          FundoFase(nivel: widget.trilha.nivel, fundo: widget.trilha.fundo),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  children: [
                    _topo(context),
                    const SizedBox(height: 16),
                    if (_fila.isEmpty)
                      _vazio()
                    else if (_fim)
                      _placar(context)
                    else ...[
                      _cartao(),
                      if (_acertou != null) ...[
                        const SizedBox(height: 14),
                        _feedback(),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _topo(BuildContext context) {
    final total = _fila.length;
    final progresso = total == 0 ? 0.0 : (_pos + (_acertou != null || _fim ? 1 : 0)) / total;
    final estreito = MediaQuery.sizeOf(context).width < 480;
    final acoes = Row(mainAxisSize: MainAxisSize.min, children: [
      if (widget.emSequencia && !_fim)
        BotaoPular(rotulo: 'pular desafios', onTap: () => Navigator.of(context).pop(true)),
      const SizedBox(width: 10),
      _Placa(rotulo: 'ACERTOS', valor: '$_acertos'),
    ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
          style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DESAFIOS DE LÓGICA',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.brand).copyWith(letterSpacing: 2)),
            const SizedBox(height: 2),
            Text('${widget.trilha.emoji} ${widget.trilha.nivel}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: Mixart.display(size: 20)),
          ]),
        ),
        if (!estreito) acoes,
      ]),
      // no celular, pular + placar descem para a linha de baixo
      if (estreito) Padding(padding: const EdgeInsets.only(top: 10), child: Align(alignment: Alignment.centerRight, child: acoes)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 7,
              backgroundColor: Mixart.surfaceHi,
              color: Mixart.brand,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(total == 0 ? '' : '${min(_pos + 1, total)} / $total',
            style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.textMuted)),
      ]),
    ]);
  }

  Widget _vazio() => _Caixa(
        child: Text('Esta trilha ainda não tem desafios de lógica.',
            style: Mixart.ui(size: 14, color: Mixart.textMuted)),
      );

  Widget _cartao() {
    final d = _d;
    return _Caixa(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          _Chip(texto: rotuloTipo(d.tipo), forte: true),
          _Estrelas(nivel: d.nivel),
          if (d.ehJogo) const _Chip(texto: '🎮 jogo'),
        ]),
        const SizedBox(height: 12),
        Text(d.titulo, style: Mixart.display(size: 19)),
        const SizedBox(height: 6),
        Text(d.enunciado, style: Mixart.ui(size: 14, color: Mixart.text).copyWith(height: 1.5)),
        const SizedBox(height: 14),
        ..._corpo(d),
      ]),
    );
  }

  List<Widget> _corpo(DesafioLogica d) {
    switch (d.tipo) {
      case TipoDesafioLogica.saida:
        return [
          _BlocoCodigo(d.cod),
          const SizedBox(height: 14),
          _rotulo('Qual destas é a saída?'),
          ..._opcoes(d, mono: true),
        ];
      case TipoDesafioLogica.valor:
        return [
          _BlocoCodigo(d.cod),
          const SizedBox(height: 14),
          _campoValor(d),
        ];
      case TipoDesafioLogica.lacuna:
        return [
          _BlocoCodigo(d.cod, lacuna: '___'),
          if (d.esperado.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SaidaEsperada(d.esperado),
          ],
          const SizedBox(height: 14),
          _rotulo('O que vai no lugar de ???'),
          ..._opcoes(d, mono: true),
        ];
      case TipoDesafioLogica.escolha:
        return [
          if (d.cod.isNotEmpty) ...[_BlocoCodigo(d.cod), const SizedBox(height: 14)],
          ..._opcoes(d, mono: false),
        ];
      case TipoDesafioLogica.ordenar:
        return _ordenar(d);
      case TipoDesafioLogica.bug:
        return _bug(d);
    }
  }

  Widget _rotulo(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t.toUpperCase(),
            style: Mixart.ui(size: 10.5, weight: FontWeight.w700, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
      );

  List<Widget> _opcoes(DesafioLogica d, {required bool mono}) => [
        for (var i = 0; i < d.opcoes.length; i++)
          _Opcao(
            letra: String.fromCharCode(65 + i),
            texto: d.opcoes[i],
            mono: mono,
            estado: _acertou == null
                ? _EstadoOpcao.livre
                : i == d.certa
                    ? _EstadoOpcao.certa
                    : i == _escolhida
                        ? _EstadoOpcao.errada
                        : _EstadoOpcao.apagada,
            onTap: () => _escolher(i),
          ),
      ];

  Widget _campoValor(DesafioLogica d) => Row(children: [
        Expanded(
          child: TextField(
            controller: _resposta,
            focusNode: _focoResposta,
            enabled: _acertou == null,
            autocorrect: false,
            enableSuggestions: false,
            style: Mixart.mono(size: 16),
            // sem isto o Enter tira o foco do campo e o teclado para de responder
            onEditingComplete: () {},
            onSubmitted: (_) => _acertou == null ? _responderValor() : _proximo(),
            decoration: InputDecoration(
              hintText: 'Digite o valor (ex.: 42, 7,5, True, Ana)',
              hintStyle: Mixart.ui(size: 13, color: Mixart.textFaint),
              filled: true,
              fillColor: Mixart.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Mixart.brand,
            foregroundColor: Mixart.onBrand,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          onPressed: _acertou == null ? _responderValor : null,
          child: const Text('Responder'),
        ),
      ]);

  List<Widget> _ordenar(DesafioLogica d) {
    final respondido = _acertou != null;
    return [
      if (d.esperado.isNotEmpty) ...[_SaidaEsperada(d.esperado), const SizedBox(height: 14)],
      _rotulo('Sua ordem (toque para devolver)'),
      Container(
        constraints: const BoxConstraints(minHeight: 60),
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Mixart.bg,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_montados.isEmpty)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text('Toque nos cartões abaixo na ordem em que o código deve ficar.',
                  style: Mixart.ui(size: 12.5, color: Mixart.textFaint)),
            ),
          for (final (n, i) in _montados.indexed)
            _CartaoLinha(
              numero: n + 1,
              texto: d.linhas[i],
              onTap: respondido ? null : () => setState(() => _montados.removeAt(n)),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      if (!respondido) ...[
        _rotulo('Cartões'),
        for (final i in _cartoes.where((i) => !_montados.contains(i)))
          _CartaoLinha(texto: d.linhas[i], onTap: () => setState(() => _montados.add(i))),
        const SizedBox(height: 10),
        Row(children: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
            onPressed: _montados.length == d.linhas.length ? _conferirOrdem : null,
            child: const Text('Conferir (Enter)'),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _montados.isEmpty ? null : () => setState(() => _montados = []),
            child: Text('Limpar', style: Mixart.ui(size: 13, color: Mixart.textMuted)),
          ),
        ]),
      ],
    ];
  }

  List<Widget> _bug(DesafioLogica d) {
    final respondido = _acertou != null;
    return [
      if (d.esperado.isNotEmpty) ...[_SaidaEsperada(d.esperado), const SizedBox(height: 14)],
      _rotulo('Toque na linha que tem o bug'),
      Container(
        decoration: BoxDecoration(
          color: Mixart.bg,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < d.linhas.length; i++)
            InkWell(
              onTap: respondido ? null : () => _escolherLinha(i),
              child: Container(
                color: !respondido
                    ? null
                    : i == d.linhaBug
                        ? _verde.withValues(alpha: .16)
                        : (_escolhida == i ? Mixart.danger.withValues(alpha: .16) : null),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 26,
                    child: Text('${i + 1}', style: Mixart.mono(size: 12, color: Mixart.textFaint).copyWith(height: 1.6)),
                  ),
                  Expanded(
                    child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: CodigoColorido(d.linhas[i])),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    ];
  }

  Widget _feedback() {
    final d = _d;
    final certo = _acertou == true;
    return _Caixa(
      borda: certo ? _verde : Mixart.danger,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(certo ? Icons.check_circle : Icons.cancel, color: certo ? _verde : Mixart.danger, size: 22),
          const SizedBox(width: 10),
          Text(certo ? 'Acertou!' : 'Não foi dessa vez', style: Mixart.display(size: 18)),
        ]),
        const SizedBox(height: 10),
        if (!certo) ..._gabarito(d),
        Text(d.explicacao, style: Mixart.ui(size: 13.5, color: Mixart.text).copyWith(height: 1.55)),
        const SizedBox(height: 14),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
          onPressed: _proximo,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: Text(_pos + 1 >= _fila.length ? 'Ver resultado (Enter)' : 'Próximo (Enter)'),
        ),
      ]),
    );
  }

  List<Widget> _gabarito(DesafioLogica d) {
    Widget bloco(String titulo, Widget w) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_rotulo(titulo), w]),
        );
    switch (d.tipo) {
      case TipoDesafioLogica.valor:
        return [bloco('Resposta certa', Text(d.resposta, style: Mixart.mono(size: 15, color: Mixart.brand)))];
      case TipoDesafioLogica.ordenar:
        return [bloco('Ordem certa', _BlocoCodigo(d.linhas.join('\n')))];
      case TipoDesafioLogica.bug:
        return [
          bloco('Linha ${d.linhaBug + 1} corrigida', _BlocoCodigo(d.correcao)),
        ];
      default:
        return const [];
    }
  }

  Widget _placar(BuildContext context) {
    final total = _fila.length;
    final pct = total == 0 ? 0.0 : _acertos / total;
    final estrelas = pct >= .9 ? 3 : (pct >= .6 ? 2 : (pct > 0 ? 1 : 0));
    return _Caixa(
      child: Column(children: [
        const SizedBox(height: 6),
        Text(['😅', '🙂', '😎', '🏆'][estrelas], style: const TextStyle(fontSize: 44)),
        const SizedBox(height: 8),
        Text('Você acertou $_acertos de $total', style: Mixart.display(size: 22), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('${'★' * estrelas}${'☆' * (3 - estrelas)}', style: Mixart.display(size: 22, color: Mixart.brand)),
        if (_novos > 0) ...[
          const SizedBox(height: 6),
          Text('+${_novos * 15} pontos no ranking ($_novos desafio${_novos == 1 ? '' : 's'} novo${_novos == 1 ? '' : 's'})',
              style: Mixart.ui(size: 13, weight: FontWeight.w600, color: Mixart.brand)),
        ],
        const SizedBox(height: 18),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
          OutlinedButton.icon(
            onPressed: _reiniciar,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Jogar de novo'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(widget.emSequencia ? 'Seguir (Enter)' : 'Voltar (Enter)'),
          ),
        ]),
      ]),
    );
  }
}

// ───────────────────────── peças ─────────────────────────

/// Verde do "acertou" (as paletas só têm o vermelho de erro).
const _verde = Color(0xFF3FB950);

class _Caixa extends StatelessWidget {
  final Widget child;
  final Color? borda;
  const _Caixa({required this.child, this.borda});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: borda ?? Mixart.border, width: borda == null ? 1 : 1.5),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 18), spreadRadius: -26)],
        ),
        child: child,
      );
}

class _Chip extends StatelessWidget {
  final String texto;
  final bool forte;
  const _Chip({required this.texto, this.forte = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: forte ? Mixart.brandSub : Mixart.surfaceHi,
          border: Border.all(color: forte ? Mixart.brandDim : Mixart.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(texto,
            style: Mixart.ui(size: 11, weight: FontWeight.w700, color: forte ? Mixart.brand : Mixart.textMuted)),
      );
}

/// Dificuldade do desafio: 1 a 3 estrelas cheias (ícones — os caracteres
/// ★/☆ ficam parecidos demais na fonte da interface).
class _Estrelas extends StatelessWidget {
  final int nivel;
  const _Estrelas({required this.nivel});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: const ['fácil', 'médio', 'difícil'][(nivel - 1).clamp(0, 2)],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Mixart.surfaceHi,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 1; i <= 3; i++)
              Icon(i <= nivel ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 14, color: i <= nivel ? Mixart.brand : Mixart.textFaint),
          ]),
        ),
      );
}

class _Placa extends StatelessWidget {
  final String rotulo, valor;
  const _Placa({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Mixart.surfaceHi,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(children: [
          Text(rotulo, style: Mixart.ui(size: 9, weight: FontWeight.w700, color: Mixart.textMuted).copyWith(letterSpacing: 1)),
          Text(valor, style: Mixart.display(size: 17, color: Mixart.brand)),
        ]),
      );
}

class _BlocoCodigo extends StatelessWidget {
  final String cod;
  final String? lacuna;
  const _BlocoCodigo(this.cod, {this.lacuna});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Mixart.bg,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CodigoColorido(cod, tamanho: 13.5, lacuna: lacuna),
        ),
      );
}

class _SaidaEsperada extends StatelessWidget {
  final String texto;
  const _SaidaEsperada(this.texto);

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B0B),
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SAÍDA ESPERADA',
              style: Mixart.ui(size: 9.5, weight: FontWeight.w700, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(texto, style: Mixart.mono(size: 13, color: const Color(0xFF7CE38B)).copyWith(height: 1.5)),
          ),
        ]),
      );
}

enum _EstadoOpcao { livre, certa, errada, apagada }

class _Opcao extends StatelessWidget {
  final String letra, texto;
  final bool mono;
  final _EstadoOpcao estado;
  final VoidCallback onTap;
  const _Opcao({required this.letra, required this.texto, required this.mono, required this.estado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cor = switch (estado) {
      _EstadoOpcao.certa => _verde,
      _EstadoOpcao.errada => Mixart.danger,
      _ => Mixart.border,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: estado == _EstadoOpcao.apagada ? .55 : 1,
        child: InkWell(
          onTap: estado == _EstadoOpcao.livre ? onTap : null,
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: estado == _EstadoOpcao.certa
                  ? _verde.withValues(alpha: .12)
                  : estado == _EstadoOpcao.errada
                      ? Mixart.danger.withValues(alpha: .12)
                      : Mixart.bg,
              border: Border.all(color: cor, width: estado == _EstadoOpcao.livre ? 1 : 1.5),
              borderRadius: BorderRadius.circular(Mixart.radiusMd),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Mixart.surfaceHi, shape: BoxShape.circle, border: Border.all(color: Mixart.border)),
                child: Text(letra, style: Mixart.ui(size: 11.5, weight: FontWeight.w700, color: Mixart.textMuted)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: mono
                    // saída/código não quebra sozinho: uma quebra falsa pareceria um WriteLine a mais
                    ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: CodigoColorido(texto, tamanho: 13))
                    : Text(texto, style: Mixart.ui(size: 13.5, color: Mixart.text).copyWith(height: 1.45)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CartaoLinha extends StatelessWidget {
  final int? numero;
  final String texto;
  final VoidCallback? onTap;
  const _CartaoLinha({this.numero, required this.texto, this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Mixart.surfaceHi,
              border: Border.all(color: Mixart.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (numero != null)
                SizedBox(
                  width: 24,
                  child: Text('$numero', style: Mixart.mono(size: 12, color: Mixart.brand).copyWith(height: 1.6)),
                ),
              Expanded(
                child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: CodigoColorido(texto, tamanho: 13)),
              ),
            ]),
          ),
        ),
      );
}
