import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/mixart.dart';
import '../../../../curso/domain/curriculo.dart';
import '../../../domain/assistir/historias_licoes.dart';
import '../../../domain/assistir/pergunta_compreensao.dart';
import '../../../domain/config_ouvir.dart';
import '../../../domain/fila_ouvir.dart';
import '../../../domain/setlist.dart';
import '../ouvir_acoes.dart';
import '../ouvir_cubit.dart';
import '../ouvir_state.dart';
import '../tocando_page.dart' show nomeDeQuem;
import 'palco_assistir.dart';
import 'pergunta_assistir.dart';

/// A fila da historinha da lição [l] (vazia fora do inglês ou numa lição sem desenho: texto próprio).
List<Faixa> faixasParaAssistir(BuildContext c, Licao l) {
  final faixas = filaDosItens(c, [ItemSetlist.daLicao(l)]).faixas;
  if (faixas.isEmpty || !PalcoAssistir.podeAssistir(faixas.first, trilhasDoCurso(c))) return const [];
  return faixas;
}

/// A lição [l] tem historinha para assistir (o 📺 aparece)?
bool podeAssistirLicao(BuildContext c, Licao l) => faixasParaAssistir(c, l).isNotEmpty;

/// 📺 "Assistir a historinha" da lição [l], de dentro da lição ou da folha do mapa. Abre por cima com um
/// player PRÓPRIO (um [OuvirCubit] só desta tela, na mesma saída de áudio): a fila do 🎧 Ouvir não muda, só
/// pausa se estava tocando. Não grava progresso nem posição. Volta quando a tela fecha.
Future<void> assistirLicao(BuildContext c, Licao l) async {
  final global = OuvirCubit.de(c);
  final faixas = faixasParaAssistir(c, l);
  if (global == null || faixas.isEmpty) return;
  if (global.state.status == StatusOuvir.tocando) global.pausar();
  final trilhas = trilhasDoCurso(c);
  final historias = HistoriasLicoes.de(trilhas);
  unawaited(historias.preparar(faixas.first));
  // a velocidade que a pessoa escolheu no Ouvir; o resto no padrão (uma passada, sem repetir tudo)
  final cubit = OuvirCubit(saida: global.saida)
    ..configurar(ConfigOuvir(velocidade: global.state.config.velocidade));
  // toca DENTRO do gesto (autoplay da web)
  unawaited(cubit.tocar(FonteOuvir('avulso', l.nome), faixas));
  await Navigator.of(c).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => AssistirLicaoPage(cubit: cubit, trilhas: trilhas, titulo: l.nome, historias: historias),
  ));
  await cubit.close();
}

/// A tela do 📺 da lição: o [PalcoAssistir] em tela cheia e uma barra (⏮ ⏯ ⏭). Espaço toca/pausa, ←/→
/// frase anterior/próxima, Esc volta para a lição. Quem fecha o [cubit] é quem abriu ([assistirLicao]).
///
/// No fim da historinha, por cima do palco, uma pergunta OPCIONAL de compreensão ([PerguntaAssistir], de
/// [perguntaDaLicao]): 1/2/3 escolhem, Esc pula. Não grava progresso. Lição sem pergunta possível: só o véu.
///
/// Keys: `assistir-licao-page`, `assistir-licao-fechar`, `assistir-licao-play`, `assistir-licao-anterior`,
/// `assistir-licao-proxima`, `assistir-licao-posicao`.
class AssistirLicaoPage extends StatefulWidget {
  const AssistirLicaoPage({
    super.key,
    required this.cubit,
    required this.trilhas,
    required this.titulo,
    this.historias,
  });

  final OuvirCubit cubit;
  final List<Trilha> trilhas;
  final String titulo;

  /// Injeção nos testes; padrão HistoriasLicoes.de(trilhas).
  final HistoriasLicoes? historias;

  @override
  State<AssistirLicaoPage> createState() => _AssistirLicaoPageState();
}

class _AssistirLicaoPageState extends State<AssistirLicaoPage> {
  final _foco = FocusNode(debugLabel: 'assistir-licao');

  /// A pergunta do fim (calculada uma vez, na 1ª vez que a historinha acaba; null = a lição não tem).
  PerguntaCompreensao? _pergunta;
  var _perguntaFeita = false;

  /// A pergunta está por cima do palco; [_escolha] = a opção respondida (null = ainda não).
  var _aberta = false;
  int? _escolha;

  /// O palco é criado uma vez: os rebuilds da barra (a cada emit) não o reconstroem.
  late final Widget _palco = PalcoAssistir(
    cubit: widget.cubit,
    trilhas: widget.trilhas,
    historias: widget.historias,
    grande: true,
  );

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  void _alternar() {
    final c = widget.cubit;
    final st = c.state;
    final fonte = st.fonte;
    if (st.status == StatusOuvir.acabou && fonte != null) {
      unawaited(c.tocar(fonte, st.fila));
    } else if (st.status != StatusOuvir.parado) {
      c.alternar();
    }
  }

  /// A historinha acabou (abre a pergunta, se a lição tiver) ou voltou a tocar (fecha).
  void _aoStatus(OuvirState st) {
    if (st.status == StatusOuvir.acabou) {
      if (!_perguntaFeita) {
        _perguntaFeita = true;
        final id = st.fila.isEmpty || st.fila.first.licaoId.isEmpty ? widget.titulo : st.fila.first.licaoId;
        _pergunta = perguntaDaLicao(id, st.fila, nomeDe: nomeDeQuem);
      }
      if (_pergunta != null) {
        setState(() {
          _aberta = true;
          _escolha = null;
        });
      }
    } else if (_aberta) {
      setState(() => _aberta = false);
    }
  }

  void _responder(int i) {
    if (_escolha != null) return;
    setState(() => _escolha = i);
  }

  /// "Pular" (ou Esc): fecha a pergunta e fica o véu "▶ de novo" do palco.
  void _fecharPergunta() {
    setState(() => _aberta = false);
    _foco.requestFocus();
  }

  void _verDeNovo() {
    _fecharPergunta();
    _alternar();
  }

  /// 1/2/3 (em cima ou no teclado numérico) → a opção.
  static final _teclasDaOpcao = {
    LogicalKeyboardKey.digit1: 0,
    LogicalKeyboardKey.digit2: 1,
    LogicalKeyboardKey.digit3: 2,
    LogicalKeyboardKey.numpad1: 0,
    LogicalKeyboardKey.numpad2: 1,
    LogicalKeyboardKey.numpad3: 2,
  };

  KeyEventResult _tecla(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    // com a pergunta aberta: 1/2/3 escolhem e Esc pula (mesmo com o foco num botão dela)
    if (_aberta && _pergunta != null) {
      final i = _teclasDaOpcao[k];
      if (i != null && i < _pergunta!.opcoes.length) {
        _responder(i);
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.escape) {
        _fecharPergunta();
        return KeyEventResult.handled;
      }
    }
    if (!_foco.hasPrimaryFocus && k != LogicalKeyboardKey.escape) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.space) {
      _alternar();
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      widget.cubit.anterior();
    } else if (k == LogicalKeyboardKey.arrowRight) {
      widget.cubit.proxima();
    } else if (k == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('assistir-licao-page'),
      backgroundColor: const Color(0xFF0E0E14),
      body: SafeArea(
        child: Focus(
          focusNode: _foco,
          autofocus: true,
          onKeyEvent: _tecla,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _topo(context),
            Expanded(
              child: BlocListener<OuvirCubit, OuvirState>(
                bloc: widget.cubit,
                listenWhen: (a, b) => a.status != b.status,
                listener: (_, st) => _aoStatus(st),
                child: Stack(fit: StackFit.expand, children: [
                  _palco,
                  if (_aberta && _pergunta != null)
                    PerguntaAssistir(
                      pergunta: _pergunta!,
                      escolha: _escolha,
                      onEscolher: _responder,
                      // a mesma saída do player da tela, a 1× (a historinha já acabou: nada a cortar)
                      onOuvir: () => unawaited(widget.cubit.saida.en(_pergunta!.frase, fator: 1)),
                      onPular: _fecharPergunta,
                      onDeNovo: _verDeNovo,
                      onVoltar: () => Navigator.of(context).maybePop(),
                    ),
                ]),
              ),
            ),
            BlocBuilder<OuvirCubit, OuvirState>(
              bloc: widget.cubit,
              builder: (context, st) => _barra(st),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _topo(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        child: Row(children: [
          IconButton(
            key: const Key('assistir-licao-fechar'),
            tooltip: 'Voltar para a lição',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text('📺 ${widget.titulo}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Mixart.ui(size: 15, weight: FontWeight.w800, color: Colors.white)),
          ),
        ]),
      );

  Widget _barra(OuvirState st) {
    final c = widget.cubit;
    final tocando = st.status == StatusOuvir.tocando;
    final n = st.fila.length;
    final texto = st.status == StatusOuvir.acabou
        ? '🏁 Fim da historinha'
        : n == 0
            ? ''
            : 'Frase ${(st.indice + 1).clamp(1, n)} de $n';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(children: [
        Expanded(
          child: Text(texto,
              key: const Key('assistir-licao-posicao'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Mixart.ui(size: 12.5, color: Colors.white70)),
        ),
        IconButton(
          key: const Key('assistir-licao-anterior'),
          tooltip: 'Frase anterior',
          onPressed: c.anterior,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.skip_previous_rounded, size: 28, color: Colors.white),
        ),
        IconButton.filled(
          key: const Key('assistir-licao-play'),
          tooltip: tocando ? 'Pausar' : 'Tocar',
          onPressed: _alternar,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          style: IconButton.styleFrom(backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
          icon: Icon(tocando ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28, color: Mixart.onBrand),
        ),
        IconButton(
          key: const Key('assistir-licao-proxima'),
          tooltip: 'Próxima frase',
          onPressed: c.proxima,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.skip_next_rounded, size: 28, color: Colors.white),
        ),
        const Spacer(),
      ]),
    );
  }
}
