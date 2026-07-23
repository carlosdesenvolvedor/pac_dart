import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../domain/jogador_ranking.dart';
import 'ranking_cubit.dart';

/// 🏆 Ranking dos jogadores: pódio com troféus + lista completa, nos
/// critérios Geral (pontos), Precisão, Digitação (toques) e Arcade.
class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  CriterioRanking _criterio = CriterioRanking.pontos;

  @override
  void initState() {
    super.initState();
    context.read<RankingCubit>().carregarTop();
  }

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  String _valor(JogadorRanking j) => _criterio == CriterioRanking.precisao
      ? '${j.precisao}%'
      : _fmt(_criterio.valor(j));

  @override
  Widget build(BuildContext context) {
    final uid = context.read<RankingCubit>().uid;
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: BlocBuilder<RankingCubit, RankingState>(
              builder: (context, st) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                children: [
                  _cabecalho(context, st),
                  const SizedBox(height: 16),
                  _criterios(),
                  const SizedBox(height: 18),
                  ..._corpo(st, uid),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho(BuildContext context, RankingState st) {
    return Row(children: [
      IconButton(
        tooltip: 'Voltar',
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
        style: IconButton.styleFrom(
            backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PAC·DART',
              style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.brand)
                  .copyWith(letterSpacing: 2)),
          const SizedBox(height: 2),
          Text('🏆 Ranking dos Jogadores', style: Mixart.display(size: 21)),
        ]),
      ),
      IconButton(
        tooltip: 'Atualizar',
        onPressed: st.status == RankingStatus.carregando
            ? null
            : () => context.read<RankingCubit>().carregarTop(),
        icon: Icon(Icons.refresh, color: Mixart.textMuted, size: 20),
        style: IconButton.styleFrom(
            backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
      ),
    ]);
  }

  Widget _criterios() {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final c in CriterioRanking.values)
        InkWell(
          onTap: () => setState(() => _criterio = c),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: c == _criterio ? Mixart.brand : Mixart.surfaceHi,
              border: Border.all(color: c == _criterio ? Mixart.brand : Mixart.border),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('${c.emoji} ${c.rotulo}',
                style: Mixart.ui(
                    size: 12.5,
                    weight: c == _criterio ? FontWeight.w700 : FontWeight.w500,
                    color: c == _criterio ? Mixart.onBrand : Mixart.textMuted)),
          ),
        ),
    ]);
  }

  List<Widget> _corpo(RankingState st, String uid) {
    switch (st.status) {
      case RankingStatus.inicial:
      case RankingStatus.carregando:
        return [
          const SizedBox(height: 80),
          Center(child: CircularProgressIndicator(color: Mixart.brand)),
        ];
      case RankingStatus.erro:
        return [
          const SizedBox(height: 40),
          Icon(Icons.cloud_off, size: 40, color: Mixart.textMuted),
          const SizedBox(height: 12),
          Center(
            child: Text('Não consegui buscar o ranking — verifique a internet.',
                style: Mixart.ui(size: 13, color: Mixart.textMuted)),
          ),
          const SizedBox(height: 14),
          Center(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Mixart.text,
                side: BorderSide(color: Mixart.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: () => context.read<RankingCubit>().carregarTop(),
              child: const Text('Tentar de novo'),
            ),
          ),
        ];
      case RankingStatus.pronto:
        if (st.jogadores.isEmpty) {
          return [
            const SizedBox(height: 40),
            const Center(child: Text('🏆', style: TextStyle(fontSize: 44))),
            const SizedBox(height: 12),
            Center(
              child: Text('O pódio está vazio!',
                  style: Mixart.display(size: 18)),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('Conclua uma lição ou jogue no Arcade para inaugurar o ranking.',
                  textAlign: TextAlign.center,
                  style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
            ),
          ];
        }
        final ordenados = ordenarRanking(st.jogadores, _criterio);
        return [
          _podio(ordenados, uid),
          const SizedBox(height: 22),
          for (var i = 0; i < ordenados.length; i++) _linha(i, ordenados[i], uid),
          if (_criterio == CriterioRanking.precisao) ...[
            const SizedBox(height: 10),
            Text(
              '🎯 Na Precisão, entra na disputa quem já digitou $volumeMinimoPrecisao+ toques '
              '(quem ainda está aquecendo aparece no fim).',
              style: Mixart.ui(size: 11.5, color: Mixart.textFaint),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Pontos vêm da digitação (código real!), dos quizzes e do Arcade. '
            'Convide amigos para disputar o troféu 🏆',
            style: Mixart.ui(size: 11.5, color: Mixart.textFaint),
          ),
        ];
    }
  }

  // ---------- pódio ----------

  Widget _podio(List<JogadorRanking> ordenados, String uid) {
    JogadorRanking? em(int i) => i < ordenados.length ? ordenados[i] : null;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: _lugar(2, em(1), uid, altura: 92)),
      const SizedBox(width: 10),
      Expanded(child: _lugar(1, em(0), uid, altura: 124)),
      const SizedBox(width: 10),
      Expanded(child: _lugar(3, em(2), uid, altura: 72)),
    ]);
  }

  Widget _lugar(int posicao, JogadorRanking? j, String uid, {required double altura}) {
    const medalhas = {1: '🥇', 2: '🥈', 3: '🥉'};
    final souEu = j != null && j.uid == uid;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (posicao == 1)
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text('🏆', style: TextStyle(fontSize: 26)),
        ),
      Text(medalhas[posicao]!, style: TextStyle(fontSize: posicao == 1 ? 30 : 24)),
      const SizedBox(height: 6),
      Container(
        width: posicao == 1 ? 52 : 44,
        height: posicao == 1 ? 52 : 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Mixart.surfaceHi,
          shape: BoxShape.circle,
          border: Border.all(color: souEu ? Mixart.brand : Mixart.border, width: souEu ? 2 : 1),
        ),
        child: Text(
          j == null ? '?' : j.apelido[0].toUpperCase(),
          style: Mixart.display(size: posicao == 1 ? 20 : 16,
              color: j == null ? Mixart.textFaint : Mixart.brand),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        j?.apelido ?? 'vaga livre',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Mixart.ui(
            size: 12,
            weight: FontWeight.w700,
            color: j == null ? Mixart.textFaint : Mixart.text),
      ),
      Text(
        j == null ? 'convide alguém!' : '${_valor(j)} ${_criterio == CriterioRanking.precisao ? '' : _criterio.unidade}'.trim(),
        style: Mixart.ui(size: 11, color: j == null ? Mixart.textHint : Mixart.textMuted),
      ),
      const SizedBox(height: 8),
      Container(
        height: altura,
        decoration: BoxDecoration(
          color: j == null ? Mixart.surface : Mixart.surfaceHi,
          border: Border.all(color: souEu ? Mixart.brandDim : Mixart.border),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        alignment: Alignment.center,
        child: Text('$posicaoº',
            style: Mixart.display(size: 22, color: j == null ? Mixart.textHint : Mixart.brand)),
      ),
    ]);
  }

  // ---------- lista ----------

  Widget _linha(int i, JogadorRanking j, String uid) {
    const medalhas = ['🥇', '🥈', '🥉'];
    final souEu = j.uid == uid;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: souEu ? Mixart.brandSub : Mixart.surface,
        border: Border.all(color: souEu ? Mixart.brandDim : Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Row(children: [
        SizedBox(
          width: 34,
          child: Text(
            i < 3 ? medalhas[i] : '${i + 1}º',
            style: i < 3 ? const TextStyle(fontSize: 18) : Mixart.mono(size: 13, color: Mixart.textMuted),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Mixart.surfaceHi,
            shape: BoxShape.circle,
            border: Border.all(color: Mixart.border),
          ),
          child: Text(j.apelido[0].toUpperCase(),
              style: Mixart.display(size: 14, color: Mixart.brand)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(j.apelido,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Mixart.ui(size: 13.5, weight: FontWeight.w700)),
              ),
              if (souEu) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Mixart.brand,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('VOCÊ',
                      style: Mixart.ui(size: 9, weight: FontWeight.w800, color: Mixart.onBrand)
                          .copyWith(letterSpacing: 1)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Text(
              '${j.licoes} lições · ${j.projetos} apps · 🗺️ ${j.missoes} · 🎯 ${j.precisao}% · 🎮 ${_fmt(j.arcadePontos)}',
              style: Mixart.ui(size: 10.5, color: Mixart.textFaint),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_valor(j), style: Mixart.display(size: 17, color: Mixart.brand)),
          Text(_criterio == CriterioRanking.precisao ? 'precisão' : _criterio.unidade,
              style: Mixart.ui(size: 9.5, color: Mixart.textFaint)),
        ]),
      ]),
    );
  }
}
