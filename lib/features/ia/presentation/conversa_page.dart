import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../domain/cenario.dart';
import '../domain/sessao_cenario.dart';
import 'cenario_cubit.dart';
import 'feedback_cenario.dart';
import 'ia_cubit.dart';

/// A conversa de um cenário: o Prof. Dash faz o outro papel, a pessoa escreve em inglês, e o
/// feedback vem no fim (nunca no meio). Sem [IaCubit] na árvore não abre.
class ConversaPage extends StatelessWidget {
  final Cenario cenario;
  const ConversaPage({super.key, required this.cenario});

  @override
  Widget build(BuildContext context) {
    final ia = IaCubit.de(context);
    if (ia == null) return const Scaffold(body: SizedBox.shrink());
    return BlocProvider(
      create: (_) => CenarioCubit(ia: ia, cenario: cenario),
      child: const _Conversa(),
    );
  }
}

class _Conversa extends StatefulWidget {
  const _Conversa();

  @override
  State<_Conversa> createState() => _ConversaState();
}

class _ConversaState extends State<_Conversa> {
  final _campo = TextEditingController();
  final _foco = FocusNode(debugLabel: 'fala do cenário');
  final _rolagem = ScrollController();
  bool _dicas = false;

  @override
  void dispose() {
    _campo.dispose();
    _foco.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  void _enviar() {
    final t = _campo.text;
    // esperando o Dash (ou sem falas): o texto fica no campo, nada é enviado nem apagado
    if (t.trim().isEmpty || context.read<CenarioCubit>().state.aguardando) return;
    _campo.clear();
    context.read<CenarioCubit>().enviar(t);
  }

  void _rolarParaOFim() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_rolagem.hasClients) _rolagem.animateTo(_rolagem.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CenarioCubit, CenarioState>(
      listener: (context, st) {
        // a fala que não foi volta para o campo (ninguém digita de novo)
        final volta = st.falaPendente;
        if (volta != null && _campo.text.isEmpty) {
          _campo.text = volta;
          _campo.selection = TextSelection.collapsed(offset: volta.length);
        }
        _rolarParaOFim();
      },
      builder: (context, st) {
        final c = st.sessao.cenario;
        return Scaffold(
          backgroundColor: Mixart.bg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(children: [
                  Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: _topo(c)),
                  Expanded(
                    child: ListView(
                      key: const Key('lista-conversa'),
                      controller: _rolagem,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      children: [
                        _objetivo(c),
                        const SizedBox(height: 10),
                        for (var i = 0; i < st.sessao.turnos.length; i++) _Bolha(turno: st.sessao.turnos[i], traducao: i == 0 ? c.aberturaPt : ''),
                        if (st.aguardando && !st.gerandoFeedback) const _Digitando(),
                        if (st.gerandoFeedback) const _Digitando(rotulo: 'O Prof. Dash está preparando o feedback…'),
                        if (st.erro == ErroCenario.falhou) _aviso(const Key('cenario-falhou'), 'Não consegui falar com o Prof. Dash agora (isso não gastou seu limite do dia). Confere a internet e tenta de novo.'),
                        if (st.erro == ErroCenario.semCota && !st.feedbackLocal)
                          _aviso(const Key('cenario-sem-cota'), 'Por hoje o Prof. Dash descansou — amanhã tem mais 🐦 Sua fala ficou guardada no campo.'),
                        if (st.feedback != null) ...[
                          const SizedBox(height: 14),
                          FeedbackCenarioView(feedback: st.feedback!),
                        ],
                        if (st.feedbackLocal) ...[
                          const SizedBox(height: 14),
                          _feedbackLocal(st),
                        ],
                        if (st.sessao.encerrada && !st.terminou && !st.aguardando)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text('A conversa terminou — toque em "Terminar e ver feedback".',
                                key: const Key('conversa-encerrada'), textAlign: TextAlign.center, style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
                          ),
                      ],
                    ),
                  ),
                  if (!st.terminou) _rodape(st),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topo(Cenario c) => Row(children: [
        IconButton(
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
          style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
        ),
        const SizedBox(width: 12),
        Text(c.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.titulo, style: Mixart.display(size: 20), overflow: TextOverflow.ellipsis),
            BlocBuilder<IaCubit, IaState>(
              builder: (_, ia) => Text(
                  ia.carregado ? '${c.etapa} · ${ia.restantes == 1 ? 'resta 1 uso' : 'restam ${ia.restantes} usos'} hoje' : c.etapa,
                  key: const Key('conversa-restantes'),
                  style: Mixart.ui(size: 12, color: Mixart.textMuted)),
            ),
          ]),
        ),
      ]);

  Widget _objetivo(Cenario c) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Mixart.brandSub,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🎯 ${c.objetivo}', key: const Key('objetivo-cenario'), style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.text).copyWith(height: 1.4)),
          const SizedBox(height: 4),
          Text('O Prof. Dash faz o papel de ${c.papel}. Ele só corrige no fim — converse sem medo de errar.',
              style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.4)),
          if (c.dicas.isNotEmpty) ...[
            const SizedBox(height: 6),
            InkWell(
              key: const Key('dicas-cenario'),
              onTap: () => setState(() => _dicas = !_dicas),
              child: Text(_dicas ? '▾ esconder frases úteis' : '▸ frases úteis, se travar',
                  style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.brand)),
            ),
            if (_dicas)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final d in c.dicas)
                    ActionChip(
                      label: Text(d, style: Mixart.ui(size: 12, color: Mixart.text)),
                      backgroundColor: Mixart.surfaceHi,
                      side: BorderSide(color: Mixart.border),
                      onPressed: () {
                        _campo.text = d;
                        _campo.selection = TextSelection.collapsed(offset: d.length);
                        _foco.requestFocus();
                      },
                    ),
                ]),
              ),
          ],
        ]),
      );

  Widget _aviso(Key k, String t) => Container(
        key: k,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Mixart.surfaceHi, border: Border.all(color: Mixart.border), borderRadius: BorderRadius.circular(Mixart.radiusMd)),
        child: Text(t, style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.45)),
      );

  Widget _feedbackLocal(CenarioState st) => Container(
        key: const Key('feedback-local'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Mixart.surface, border: Border.all(color: Mixart.brandDim), borderRadius: BorderRadius.circular(Mixart.radiusLg)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🐦 Boa conversa!', style: Mixart.display(size: 18)),
          const SizedBox(height: 6),
          Text(
              'Você falou ${st.sessao.turnosDoAluno} ${st.sessao.turnosDoAluno == 1 ? 'vez' : 'vezes'} em inglês neste cenário. '
              'Por hoje o Prof. Dash descansou, então o feedback com correções e frases para levar fica para amanhã — '
              'volte e refaça este cenário para ver. 🐦',
              style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.5)),
        ]),
      );

  Widget _rodape(CenarioState st) {
    final s = st.sessao;
    final livre = s.podeFalar && !st.aguardando;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(color: Mixart.surface, border: Border(top: BorderSide(color: Mixart.border))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (s.podeFalar || st.aguardando)
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              // uma linha só: o Enter envia pelo próprio campo (onSubmitted)
              child: TextField(
                  key: const Key('campo-conversa'),
                  controller: _campo,
                  focusNode: _foco,
                  // sem autofocus: na web, focar o campo durante a transição da tela dá erro no motor de texto (a pessoa toca no campo)
                  // O campo NUNCA é desligado nem perde o foco enquanto o Dash responde (readOnly/enabled/requestFocus no meio
                  // do Enter derrubam a conexão do teclado na web com um erro do motor); só o envio é ignorado até a resposta chegar.
                  maxLines: 1,
                  maxLength: SessaoCenario.maxFala,
                  textInputAction: TextInputAction.done,
                  // onEditingComplete vazio: o padrão do "done" seria tirar o foco do campo a cada Enter (e dar erro na web)
                  onEditingComplete: () {},
                  onSubmitted: (_) => _enviar(),
                  style: Mixart.ui(size: 14, color: Mixart.text),
                  decoration: InputDecoration(
                    hintText: 'Escreva em inglês… (fala ${(s.turnosDoAluno + (s.podeFalar ? 1 : 0)).clamp(1, s.cenario.maxTurnos)} de ${s.cenario.maxTurnos})',
                    hintStyle: Mixart.ui(size: 13.5, color: Mixart.textFaint),
                    counterText: '',
                    filled: true,
                    fillColor: Mixart.surfaceHi,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.brand)),
                  ),
                ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('enviar-conversa'),
              tooltip: 'Enviar',
              onPressed: livre ? _enviar : null,
              style: IconButton.styleFrom(backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
              icon: const Icon(Icons.send_rounded, size: 18),
            ),
          ]),
        if (s.turnosDoAluno > 0)
          Padding(
            padding: EdgeInsets.only(top: s.podeFalar || st.aguardando ? 8 : 0),
            child: TextButton(
              key: const Key('terminar-conversa'),
              onPressed: st.aguardando ? null : () => context.read<CenarioCubit>().terminar(),
              child: Text('Terminar e ver feedback', style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)),
            ),
          ),
      ]),
    );
  }
}

class _Bolha extends StatelessWidget {
  final Turno turno;
  final String traducao;
  const _Bolha({required this.turno, this.traducao = ''});

  @override
  Widget build(BuildContext context) {
    final aluno = turno.doAluno;
    return Align(
      alignment: aluno ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: Key(aluno ? 'bolha-aluno' : 'bolha-dash'),
        margin: const EdgeInsets.only(top: 8),
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: aluno ? Mixart.brandSub : Mixart.surface,
          border: Border.all(color: aluno ? Mixart.brandDim : Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          if (!aluno) Text('🐦 Prof. Dash', style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.brand)),
          SelectableText(turno.texto, style: Mixart.ui(size: 14.5, color: Mixart.text).copyWith(height: 1.45)),
          if (traducao.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(traducao, style: Mixart.ui(size: 12, color: Mixart.textFaint).copyWith(height: 1.4)),
          ],
        ]),
      ),
    );
  }
}

class _Digitando extends StatelessWidget {
  final String rotulo;
  const _Digitando({this.rotulo = 'O Prof. Dash está escrevendo…'});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Mixart.brand)),
          const SizedBox(width: 8),
          Flexible(child: Text(rotulo, key: const Key('dash-digitando'), style: Mixart.ui(size: 12.5, color: Mixart.textMuted))),
        ]),
      );
}
