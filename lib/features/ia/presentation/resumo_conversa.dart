import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../ingles/domain/setlist.dart';
import '../../ingles/presentation/ouvir/ouvir_acoes.dart' show BotaoPorNaSetlist;
import '../../ingles/presentation/palavras_cubit.dart';
import '../domain/cenario.dart';
import '../domain/conversa_resposta.dart';
import 'feedback_cenario.dart';
import 'widgets/botao_por_que.dart' show comNegrito;

/// O fim da conversa (key 'resumo-conversa'): os números, as correções para revisar (cartão e ➕ setlist)
/// e as palavras novas para Minhas palavras. Local: não gasta nenhum uso.
class ResumoConversaView extends StatefulWidget {
  final ResumoConversa resumo;
  final Cenario cenario;
  final VoidCallback onDeNovo;
  final VoidCallback onSair;

  const ResumoConversaView({
    super.key,
    required this.resumo,
    required this.cenario,
    required this.onDeNovo,
    required this.onSair,
  });

  @override
  State<ResumoConversaView> createState() => _ResumoConversaViewState();
}

class _ResumoConversaViewState extends State<ResumoConversaView> {
  final _salvos = <int>{};
  final _salvando = <int>{};

  /// As palavras que a pessoa desmarcou (as outras, ainda fora do banco, vão no "Adicionar").
  final _desmarcadas = <String>{};

  /// O erro do `adicionar` por palavra (raro: a regra já foi aplicada no parser).
  final _erros = <String, String>{};

  Future<void> _salvar(int i, CorrecaoTurno c) async {
    final cartao = c.cartao;
    if (cartao == null || _salvando.contains(i) || _salvos.contains(i)) return;
    setState(() => _salvando.add(i));
    await salvarCartaoDoCenario(context, cartao);
    if (!mounted) return;
    setState(() {
      _salvando.remove(i);
      _salvos.add(i);
    });
  }

  static bool _jaTem(PalavrasState st, String en) {
    final p = st.banco[en];
    return p != null && !p.removida;
  }

  void _adicionar(PalavrasCubit palavras) {
    final r = widget.resumo;
    var entraram = 0;
    final erros = <String, String>{};
    for (var i = 0; i < r.palavras.length; i++) {
      final p = r.palavras[i];
      if (_desmarcadas.contains(p.en) || _jaTem(palavras.state, p.en)) continue;
      final erro = palavras.adicionar(p.en, p.pt, exemplo: i < r.exemplos.length ? r.exemplos[i] : null);
      if (erro == null) {
        entraram++;
      } else {
        erros[p.en] = erro;
      }
    }
    setState(() {
      _erros
        ..clear()
        ..addAll(erros);
    });
    if (entraram > 0) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(entraram == 1 ? '1 palavra entrou em Minhas palavras.' : '$entraram palavras entraram em Minhas palavras.'),
      ));
    }
  }

  Widget _titulo(String t, {Key? key}) => Padding(
        key: key,
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(t, style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: .6)),
      );

  @override
  Widget build(BuildContext context) {
    final r = widget.resumo;
    final k = r.correcoes.length;
    final palavras = PalavrasCubit.de(context);
    return Container(
      key: const Key('resumo-conversa'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.brandDim),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🐦 Fim da conversa com ${widget.cenario.nomePersonagem}!', style: Mixart.display(size: 18)),
        const SizedBox(height: 6),
        Text(
          'Você falou ${r.falas} ${r.falas == 1 ? 'vez' : 'vezes'} em inglês · '
          '${r.certas} ${r.certas == 1 ? 'certinha' : 'certinhas'} de primeira · '
          '$k ${k == 1 ? 'correção' : 'correções'}',
          key: const Key('resumo-numeros'),
          style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.text).copyWith(height: 1.45),
        ),
        const SizedBox(height: 2),
        Text('Este resumo não gastou nenhum uso.', style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
        if (r.correcoes.isNotEmpty) ...[
          _titulo('✏️ Para revisar'),
          for (var i = 0; i < r.correcoes.length; i++) _correcao(i, r.correcoes[i]),
        ],
        if (palavras != null && r.palavras.isNotEmpty)
          BlocBuilder<PalavrasCubit, PalavrasState>(
            bloc: palavras,
            builder: (context, st) => _palavras(palavras, st),
          ),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 8, children: [
          FilledButton(
            key: const Key('conversar-de-novo'),
            onPressed: widget.onDeNovo,
            style: FilledButton.styleFrom(backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
            child: Text('Conversar de novo', style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.onBrand)),
          ),
          OutlinedButton(
            key: const Key('outras-situacoes'),
            onPressed: widget.onSair,
            style: OutlinedButton.styleFrom(side: BorderSide(color: Mixart.border)),
            child: Text('Outras situações', style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.text)),
          ),
        ]),
      ]),
    );
  }

  Widget _correcao(int i, ItemCorrecao item) {
    final c = item.correcao;
    final cartao = c.cartao; // null com dado pessoal (comDadosPessoais) ou sem cartão válido
    final salvo = _salvos.contains(i), salvando = _salvando.contains(i);
    return Container(
      key: Key('resumo-correcao-$i'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Mixart.surfaceHi,
        border: Border.all(color: salvo ? Mixart.brand : Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.sua,
            style: Mixart.ui(size: 13, color: Mixart.danger).copyWith(decoration: TextDecoration.lineThrough, decorationColor: Mixart.danger, height: 1.4)),
        const SizedBox(height: 3),
        SelectableText(c.melhor, style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.text).copyWith(height: 1.4)),
        if (c.pt.isNotEmpty) Text(c.pt, style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4)),
        if (c.porque.isNotEmpty) ...[
          const SizedBox(height: 4),
          SelectableText.rich(comNegrito(c.porque, Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.45))),
        ],
        if (cartao != null) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (podeSalvarCartao(context))
              OutlinedButton(
                key: Key('resumo-cartao-$i'),
                onPressed: salvo || salvando ? null : () => _salvar(i, c),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: salvo ? Mixart.brand : Mixart.brandDim),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: Text(salvo ? '✓ Salvo' : (salvando ? 'Salvando…' : 'Salvar como cartão'),
                    style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.brand)),
              ),
            BotaoPorNaSetlist(item: () => ItemSetlist.daTexto(en: c.melhor, pt: c.pt), redondo: true),
          ]),
        ],
      ]),
    );
  }

  /// "Adicionar n às Minhas palavras"; com nada a adicionar, diz por quê (nunca "Adicionar 0").
  static String _rotuloAdicionar(int n, {required bool todasJa}) {
    if (n > 0) return 'Adicionar $n às Minhas palavras';
    return todasJa ? '✓ Já estão nas suas palavras' : 'Nenhuma palavra marcada';
  }

  Widget _palavras(PalavrasCubit cubit, PalavrasState st) {
    final r = widget.resumo;
    final lista = r.palavras.take(ResumoConversa.maxPalavras).toList();
    final aAdicionar = [
      for (final p in lista)
        if (!_desmarcadas.contains(p.en) && !_jaTem(st, p.en)) p,
    ];
    return Column(key: const Key('resumo-palavras'), crossAxisAlignment: CrossAxisAlignment.start, children: [
      _titulo('📚 Palavras novas'),
      for (final p in lista)
        Builder(builder: (context) {
          final ja = _jaTem(st, p.en);
          final erro = _erros[p.en];
          return CheckboxListTile(
            key: Key('palavra-${p.en}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Mixart.brand,
            value: !ja && !_desmarcadas.contains(p.en),
            onChanged: ja
                ? null
                : (v) => setState(() {
                      if (v == true) {
                        _desmarcadas.remove(p.en);
                      } else {
                        _desmarcadas.add(p.en);
                      }
                    }),
            title: Text('${p.en} — ${p.pt}', style: Mixart.ui(size: 13.5, weight: FontWeight.w600, color: ja ? Mixart.textFaint : Mixart.text)),
            subtitle: ja
                ? Text('já está nas suas palavras', style: Mixart.ui(size: 11.5, color: Mixart.textFaint))
                : (erro != null ? Text(erro, style: Mixart.ui(size: 11.5, color: Mixart.danger)) : null),
          );
        }),
      const SizedBox(height: 6),
      OutlinedButton(
        key: const Key('adicionar-palavras'),
        onPressed: aAdicionar.isEmpty ? null : () => _adicionar(cubit),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Mixart.brandDim),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: Text(_rotuloAdicionar(aAdicionar.length, todasJa: lista.every((p) => _jaTem(st, p.en))),
            style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: aAdicionar.isEmpty ? Mixart.textFaint : Mixart.brand)),
      ),
    ]);
  }
}
