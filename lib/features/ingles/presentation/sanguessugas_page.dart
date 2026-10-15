import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../ia/domain/explicacao.dart';
import '../../ia/presentation/widgets/botao_por_que.dart';
import '../data/voz_ingles.dart';
import '../domain/baralhos.dart';
import '../domain/sanguessugas.dart';
import 'revisao_cubit.dart';

/// As sanguessugas: os cartões que a pessoa erra demais (8 lapsos ou mais). Cada uma vem com
/// ajuda — a explicação que a própria frase já tem, outra frase com a mesma palavra, uma dica de
/// memória do Prof. Dash — e a saída honesta: suspender e seguir a vida.
class SanguessugasPage extends StatefulWidget {
  /// Voz injetável (testes).
  final VozIngles? voz;
  const SanguessugasPage({super.key, this.voz});

  @override
  State<SanguessugasPage> createState() => _SanguessugasPageState();
}

class _SanguessugasPageState extends State<SanguessugasPage> {
  late final VozIngles _voz = widget.voz ?? VozIngles();
  IndiceBaralhos? _indice;
  List<Trilha>? _trilhasDoIndice;

  @override
  void dispose() {
    _voz.parar();
    super.dispose();
  }

  IndiceBaralhos _indiceDe(List<Trilha> trilhas) {
    if (!identical(_trilhasDoIndice, trilhas)) {
      _indice = IndiceBaralhos.de(trilhas);
      _trilhasDoIndice = trilhas;
    }
    return _indice!;
  }

  void _suspender(Sanguessuga s) {
    final revisao = context.read<RevisaoCubit>();
    unawaited(revisao.suspender(s.chave, suspenso: true));
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: Mixart.surfaceHi,
        content: Text('Suspensa: sai das revisões até você reativar (no navegador do baralho).',
            style: Mixart.ui(size: 13, color: Mixart.text)),
        action: SnackBarAction(
          key: const Key('desfazer-suspensao'),
          label: 'Desfazer',
          textColor: Mixart.brand,
          onPressed: () => unawaited(revisao.suspender(s.chave, suspenso: false)),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final curso = context.watch<CursoBloc>().state;
    final st = context.watch<RevisaoCubit>().state;
    final indice = _indiceDe(curso.trilhas);
    final lista = sanguessugasDe(st.cartoes, indice);
    final todas = indice.porChave.values;
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 48), children: [
              Row(children: [
                IconButton(
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
                  style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
                ),
                const SizedBox(width: 12),
                const Text('🩸', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(child: Text('Sanguessugas', style: Mixart.display(size: 22))),
              ]),
              const SizedBox(height: 10),
              Text(
                  'São os cartões que você já errou $limiteSanguessuga vezes ou mais: gastam seu tempo e desanimam. '
                  'Em vez de insistir do mesmo jeito, veja outra frase com a mesma palavra, peça uma dica de memória '
                  'ou suspenda o cartão e siga em frente.',
                  style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.5)),
              const SizedBox(height: 14),
              if (lista.isEmpty)
                Container(
                  key: const Key('sem-sanguessugas'),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Mixart.surface,
                    border: Border.all(color: Mixart.border),
                    borderRadius: BorderRadius.circular(Mixart.radiusLg),
                  ),
                  child: Text('Nenhuma sanguessuga agora 🎉 Nenhum cartão passou de $limiteSanguessuga erros.',
                      style: Mixart.ui(size: 13.5, color: Mixart.textMuted)),
                )
              else
                for (final s in lista)
                  _CartaoSanguessuga(
                    key: ValueKey(s.chave),
                    s: s,
                    todas: todas,
                    voz: _voz,
                    onSuspender: () => _suspender(s),
                  ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CartaoSanguessuga extends StatefulWidget {
  final Sanguessuga s;
  final Iterable<Trecho> todas;
  final VozIngles voz;
  final VoidCallback onSuspender;
  const _CartaoSanguessuga({super.key, required this.s, required this.todas, required this.voz, required this.onSuspender});

  @override
  State<_CartaoSanguessuga> createState() => _CartaoSanguessugaState();
}

class _CartaoSanguessugaState extends State<_CartaoSanguessuga> {
  bool _exemplos = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final f = s.frase;
    final exemplos = _exemplos ? exemplosParecidos(f, widget.todas) : const <Trecho>[];
    final ponte = _exemplos ? palavraPonte(f, widget.todas) : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.cod, key: const Key('sanguessuga-frase'), style: Mixart.display(size: 18).copyWith(height: 1.3)),
              const SizedBox(height: 3),
              Text(f.dicaPlana, style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.4)),
            ]),
          ),
          IconButton(
            tooltip: 'Ouvir',
            onPressed: () => unawaited(widget.voz.falar(f.cod)),
            icon: Icon(Icons.volume_up_rounded, color: Mixart.brand, size: 21),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _Etiqueta(s.reverso ? '🔄 cartão de virar' : '⌨️ digitar de memória', Mixart.textMuted),
          _Etiqueta('🩸 errou ${s.lapsos} vezes', Mixart.danger, chave: const Key('sanguessuga-lapsos')),
        ]),
        if (f.literal.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('ao pé da letra: ${f.literal}', style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.45)),
        ],
        if (f.conceito.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('💡 ${Trecho.semTags(f.conceito)}', style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.45)),
        ],
        if (_exemplos) ...[
          const SizedBox(height: 10),
          Container(
            key: const Key('exemplos-sanguessuga'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Mixart.surfaceHi,
              border: Border.all(color: Mixart.border),
              borderRadius: BorderRadius.circular(Mixart.radiusMd),
            ),
            child: exemplos.isEmpty
                ? Text('Não achei outra frase do curso com as palavras desta. Tente a dica de memória.',
                    style: Mixart.ui(size: 12.5, color: Mixart.textMuted))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ponte == null ? 'Outras frases parecidas' : 'Outras frases com "$ponte"',
                        style: Mixart.ui(size: 11.5, weight: FontWeight.w800, color: Mixart.brand)),
                    const SizedBox(height: 6),
                    for (final e in exemplos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.cod, style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.text)),
                          Text(e.dicaPlana, style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
                        ]),
                      ),
                  ]),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          _Acao(
            chave: const Key('outra-frase'),
            texto: _exemplos ? '📖 Esconder frases' : '📖 Outra frase',
            onTap: () => setState(() => _exemplos = !_exemplos),
          ),
          _Acao(chave: const Key('suspender-sanguessuga'), texto: '⏸ Suspender', onTap: widget.onSuspender),
        ]),
        // a dica de memória é da IA (cota e cache); sem IA na árvore ela simplesmente não existe
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: BotaoPorQue(
            pedido: PedidoMnemonico(frase: f.cod, traducao: f.dicaPlana, lapsos: s.lapsos, literal: f.literal),
            rotulo: 'Dica de memória',
            emoji: '🧠',
            chaveBotao: const Key('dica-de-memoria'),
          ),
        ),
      ]),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color cor;
  final Key? chave;
  const _Etiqueta(this.texto, this.cor, {this.chave});

  @override
  Widget build(BuildContext context) => Container(
        key: chave,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: .1),
          border: Border.all(color: cor.withValues(alpha: .5)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(texto, style: Mixart.ui(size: 11.5, weight: FontWeight.w700, color: cor)),
      );
}

class _Acao extends StatelessWidget {
  final Key chave;
  final String texto;
  final VoidCallback onTap;
  const _Acao({required this.chave, required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        key: chave,
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Mixart.surfaceHi,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(texto, style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.textMuted)),
        ),
      );
}
