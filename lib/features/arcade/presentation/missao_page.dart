import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../../curso/presentation/bloc/typing_bloc.dart';
import '../../curso/presentation/widgets/code_view.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/gerador_missoes.dart';
import '../domain/missao.dart';
import '../domain/personagem.dart';
import '../domain/progresso_missoes.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/cenas.dart';

/// 🗺️ Uma missão do Lógica Animada, em quatro atos:
/// PREVER (o teste de lógica) → DIGITAR o código que destrava →
/// ASSISTIR a execução animada passo a passo → VITÓRIA (pontos + porquê).
/// Na dúvida, a 🔮 Ajuda Misteriosa revela pistas (custa 5 pontos cada).
class MissaoPage extends StatefulWidget {
  final int trilhaIdx;
  final String trilhaNome;
  final String trilhaEmoji;

  /// Índice inicial (fixo nos testes); null = continua de onde parou.
  final int? indiceInicial;

  const MissaoPage({
    super.key,
    required this.trilhaIdx,
    required this.trilhaNome,
    required this.trilhaEmoji,
    this.indiceInicial,
  });

  @override
  State<MissaoPage> createState() => _MissaoPageState();
}

enum _Etapa { carregando, previsao, digitando, animando, vitoria }

class _MissaoPageState extends State<MissaoPage> {
  RankingCubit? _ranking;

  var _etapa = _Etapa.carregando;
  int _indice = 0;
  late Missao _missao;
  late Map<String, Object> _estadoCena;

  int? _escolhida;
  bool _previuCerto = false;
  int _ajudas = 0;

  TypingBloc? _typing;
  final _foco = FocusNode();

  Timer? _anim;
  String _legenda = '';
  int _pontosGanhos = 0;

  @override
  void initState() {
    super.initState();
    _ranking = RankingCubit.de(context);
    PersonagemStore.carregar().then((_) {
      if (mounted) setState(() {});
    });
    _carregarInicio();
  }

  Future<void> _carregarInicio() async {
    final i = widget.indiceInicial ?? await ProgressoMissoes.proxima(widget.trilhaIdx);
    if (mounted) _abrirMissao(i);
  }

  @override
  void dispose() {
    _anim?.cancel();
    _typing?.close();
    _foco.dispose();
    super.dispose();
  }

  void _abrirMissao(int i) {
    _anim?.cancel();
    _typing?.close();
    setState(() {
      _indice = i;
      _missao = missaoPara(widget.trilhaIdx, i);
      _estadoCena = {..._missao.dados};
      _etapa = _Etapa.previsao;
      _escolhida = null;
      _previuCerto = false;
      _ajudas = 0;
      _legenda = '';
      _typing = TypingBloc()..add(TrechoCarregado(_missao.codigo));
    });
  }

  void _responderPrevisao(int i) {
    if (_escolhida != null) return;
    setState(() {
      _escolhida = i;
      _previuCerto = i == _missao.certa;
    });
    Sons.toca(_previuCerto ? Som.blip : Som.erro);
  }

  void _irDigitar() {
    setState(() => _etapa = _Etapa.digitando);
    WidgetsBinding.instance.addPostFrameCallback((_) => _foco.requestFocus());
  }

  void _iniciarAnimacao() {
    if (_etapa != _Etapa.digitando) return;
    setState(() {
      _etapa = _Etapa.animando;
      _legenda = '🔓 Código aceito — executando…';
    });
    var passo = -1;
    _anim = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      passo++;
      if (passo >= _missao.passos.length) {
        _vitoria();
        return;
      }
      final p = _missao.passos[passo];
      Sons.toca(Som.tique);
      setState(() {
        _estadoCena = {..._estadoCena, ...p.muda};
        _legenda = p.legenda;
      });
    });
  }

  void _vitoria() {
    Sons.toca(Som.fanfarra);
    _anim?.cancel();
    final pontos = (_missao.pontos + (_previuCerto ? 15 : 0) - _ajudas * 5).clamp(10, 99);
    setState(() {
      _pontosGanhos = pontos;
      _etapa = _Etapa.vitoria;
    });
    _ranking?.missaoConcluida(pontos);
    ProgressoMissoes.concluiu(widget.trilhaIdx, _indice);
  }

  void _ajudaMisteriosa() {
    if (_ajudas >= _missao.dicas.length) return;
    final dica = _missao.dicas[_ajudas];
    Sons.toca(Som.misterio);
    setState(() => _ajudas++);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Mixart.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          side: BorderSide(color: Mixart.brandDim),
        ),
        title: Text('🔮 Ajuda Misteriosa', style: Mixart.display(size: 18)),
        content: Text(dica, style: Mixart.ui(size: 13.5).copyWith(height: 1.5)),
        actions: [
          Text('-5 pts · ajuda $_ajudas de ${_missao.dicas.length}',
              style: Mixart.ui(size: 11, color: Mixart.textFaint)),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted && _etapa == _Etapa.digitando) _foco.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _etapa == _Etapa.carregando
                ? Center(child: CircularProgressIndicator(color: Mixart.brand))
                : Stack(children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      children: [
                        CabecalhoJogo(
                          rotulo:
                              'LÓGICA ANIMADA · ${widget.trilhaEmoji} ${widget.trilhaNome.toUpperCase()}',
                          titulo: _missao.titulo,
                          chips: [
                            ChipPlacar('MISSÃO', '${_indice + 1}'),
                            ChipPlacar('AJUDAS', '$_ajudas/${_missao.dicas.length}'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _historia(),
                        const SizedBox(height: 12),
                        CenaMissao(
                            missao: _missao, estado: _estadoCena, trilha: widget.trilhaIdx),
                        const SizedBox(height: 12),
                        ...switch (_etapa) {
                          _Etapa.previsao => _previsao(),
                          _Etapa.digitando => _digitacao(),
                          _Etapa.animando => _animacao(),
                          _ => const <Widget>[],
                        },
                      ],
                    ),
                    if (_etapa == _Etapa.vitoria) _vitoriaOverlay(),
                  ]),
          ),
        ),
      ),
    );
  }

  Widget _historia() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Mixart.brandSub,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Text(_missao.historia,
            style: Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.5)),
      );

  Widget _botaoAjuda() => OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: _ajudas >= _missao.dicas.length ? Mixart.textFaint : Mixart.brand,
          side: BorderSide(color: Mixart.brandDim),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: Mixart.ui(size: 12.5, weight: FontWeight.w700),
        ),
        onPressed: _ajudas >= _missao.dicas.length ? null : _ajudaMisteriosa,
        icon: const Text('🔮', style: TextStyle(fontSize: 14)),
        label: Text(_ajudas >= _missao.dicas.length
            ? 'Ajudas esgotadas'
            : 'Ajuda misteriosa (-5 pts)'),
      );

  // ---------- ato 1: prever ----------

  List<Widget> _previsao() {
    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ATO 1 · PREVEJA',
              style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.brand)
                  .copyWith(letterSpacing: 2)),
          const SizedBox(height: 6),
          Text(_missao.pergunta,
              style: Mixart.ui(size: 14.5, weight: FontWeight.w600).copyWith(height: 1.4)),
        ]),
      ),
      const SizedBox(height: 10),
      CartaoCodigo(_missao.codigo),
      const SizedBox(height: 10),
      for (var i = 0; i < _missao.opcoes.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BotaoOpcao(
            indice: i,
            codigo: _missao.opcoes[i],
            revelado: _escolhida != null,
            ehCerta: i == _missao.certa,
            ehEscolhida: i == _escolhida,
            onTap: () => _responderPrevisao(i),
          ),
        ),
      const SizedBox(height: 4),
      if (_escolhida == null)
        _botaoAjuda()
      else
        Row(children: [
          Expanded(
            child: Text(
              _previuCerto
                  ? '🎯 Previsão certeira! +15 pts te esperam na vitória.'
                  : '🤏 Quase! Veja a certa acima — a animação vai provar.',
              style: Mixart.ui(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: _previuCerto ? Mixart.brand : Mixart.danger),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Mixart.brand,
              foregroundColor: Mixart.onBrand,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: Mixart.ui(size: 13, weight: FontWeight.w700),
            ),
            onPressed: _irDigitar,
            child: const Text('Digitar pra destravar →'),
          ),
        ]),
    ];
  }

  // ---------- ato 2: digitar ----------

  List<Widget> _digitacao() {
    return [
      Row(children: [
        Expanded(
          child: Text('ATO 2 · DIGITE O CÓDIGO — cada tecla destrava a cena 🔓',
              style: Mixart.ui(size: 11.5, weight: FontWeight.w700, color: Mixart.textMuted)),
        ),
        _botaoAjuda(),
      ]),
      const SizedBox(height: 10),
      BlocProvider<TypingBloc>.value(
        value: _typing!,
        child: BlocListener<TypingBloc, TypingState>(
          listenWhen: (a, b) => !a.concluido && b.concluido,
          listener: (_, _) => _iniciarAnimacao(),
          child: CodeView(
            focusNode: _foco,
            ehFlutter: false,
            titulo: _missao.titulo,
            podeRodar: false,
            onAvancar: _iniciarAnimacao,
          ),
        ),
      ),
    ];
  }

  // ---------- ato 3: assistir ----------

  List<Widget> _animacao() {
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Row(children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: Mixart.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_legenda,
                style: Mixart.mono(size: 12.5, color: Mixart.text).copyWith(height: 1.4)),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      Text('ATO 3 · O código que você digitou está rodando na cena 🎬',
          style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
    ];
  }

  // ---------- ato 4: vitória ----------

  Widget _vitoriaOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xED010101),
        padding: const EdgeInsets.all(20),
        child: Stack(children: [
          const Confete(),
          Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🏆', style: TextStyle(fontSize: 46)),
                const SizedBox(height: 8),
                Text('MISSÃO CUMPRIDA!',
                    style: Mixart.display(size: 26, color: Mixart.brand)),
                const SizedBox(height: 4),
                Text('${_missao.titulo} · missão ${_indice + 1} de ${widget.trilhaNome}',
                    textAlign: TextAlign.center,
                    style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
                const SizedBox(height: 16),
                Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                  ChipPlacar('PONTOS', '+$_pontosGanhos', cor: Mixart.brand),
                  ChipPlacar('PREVISÃO', _previuCerto ? '🎯 +15' : '✘'),
                  ChipPlacar('AJUDAS', _ajudas == 0 ? 'nenhuma' : '-${_ajudas * 5}'),
                ]),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Mixart.brandSub,
                    border: Border.all(color: Mixart.brandDim),
                    borderRadius: BorderRadius.circular(Mixart.radiusMd),
                  ),
                  child: Text('💡 ${_missao.explica}',
                      style: Mixart.ui(size: 12.5, color: Mixart.text).copyWith(height: 1.5)),
                ),
                const SizedBox(height: 8),
                Text('Os pontos já somaram no seu ranking 🏆',
                    style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
                const SizedBox(height: 16),
                Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Mixart.brand,
                      foregroundColor: Mixart.onBrand,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      textStyle: Mixart.ui(size: 13, weight: FontWeight.w700),
                    ),
                    onPressed: () => _abrirMissao(_indice + 1),
                    child: const Text('Próxima missão →'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Mixart.text,
                      side: BorderSide(color: Mixart.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      textStyle: Mixart.ui(size: 13),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Voltar às trilhas'),
                  ),
                ]),
              ]),
            ),
          ),
          ),
        ]),
      ),
    );
  }
}
