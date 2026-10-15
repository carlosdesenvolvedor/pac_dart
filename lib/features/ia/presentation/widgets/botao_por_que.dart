import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/explicacao.dart';
import '../ia_cubit.dart';

/// "💡 Por quê?": pede ao Prof. Dash uma explicação curta, em português, do erro de [pedido] e
/// a mostra num cartão logo abaixo. Sem [IaCubit] na árvore (testes antigos) não existe.
///
/// Quem usa decide QUANDO mostrar (só depois de errar/hesitar): aqui só se pede e se mostra.
class BotaoPorQue extends StatefulWidget {
  final PedidoIa pedido;

  /// O rótulo e o emoji do botão ("Por quê?" 💡 por padrão; a sanguessuga usa "Dica de memória" 🧠).
  final String rotulo, emoji;

  /// Chave do botão (várias na mesma tela precisam de chaves diferentes nos testes).
  final Key chaveBotao;

  const BotaoPorQue({
    super.key,
    required this.pedido,
    this.rotulo = 'Por quê?',
    this.emoji = '💡',
    this.chaveBotao = const Key('por-que'),
  });

  @override
  State<BotaoPorQue> createState() => _BotaoPorQueState();
}

enum _Fase { pronto, carregando, ok, semCota, falhou }

class _BotaoPorQueState extends State<BotaoPorQue> {
  _Fase _fase = _Fase.pronto;
  String _texto = '';

  Future<void> _pedir(IaCubit ia) async {
    if (_fase == _Fase.carregando) return;
    setState(() => _fase = _Fase.carregando);
    final r = await ia.explicar(widget.pedido);
    if (!mounted) return;
    setState(() {
      _texto = r.texto;
      _fase = switch (r.status) {
        StatusIa.ok => _Fase.ok,
        StatusIa.semCota => _Fase.semCota,
        StatusIa.falhou => _Fase.falhou,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final ia = IaCubit.de(context);
    if (ia == null || !widget.pedido.temErro) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_fase == _Fase.pronto || _fase == _Fase.carregando || _fase == _Fase.falhou)
        Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          InkWell(
            key: widget.chaveBotao,
            onTap: _fase == _Fase.carregando ? null : () => _pedir(ia),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Mixart.brandSub,
                border: Border.all(color: Mixart.brandDim),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_fase == _Fase.carregando)
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Mixart.brand))
                else
                  Text(widget.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 7),
                Text(
                  switch (_fase) {
                    _Fase.carregando => 'O Prof. Dash está pensando…',
                    _Fase.falhou => 'Tentar de novo',
                    _ => widget.rotulo,
                  },
                  style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.brand),
                ),
              ]),
            ),
          ),
          BlocBuilder<IaCubit, IaState>(
            bloc: ia,
            builder: (_, st) => st.carregado
                ? Text(st.restantes == 1 ? 'resta 1 uso hoje' : 'restam ${st.restantes} usos hoje',
                    key: const Key('ia-restantes'), style: Mixart.ui(size: 11, color: Mixart.textFaint))
                : const SizedBox.shrink(),
          ),
        ]),
      if (_fase == _Fase.falhou)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Não consegui falar com o Prof. Dash agora (isso não gastou seu limite do dia). Confere a internet?',
              key: const Key('ia-falhou'), style: Mixart.ui(size: 12, color: Mixart.textMuted)),
        ),
      if (_fase == _Fase.semCota)
        _Cartao(
          chave: const Key('sem-cota'),
          child: Text('Por hoje o Prof. Dash descansou — amanhã tem mais 🐦\nVocê segue estudando normalmente.',
              style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.5)),
        ),
      if (_fase == _Fase.ok)
        _Cartao(
          chave: const Key('explicacao-ia'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🐦 Prof. Dash', style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: .6)),
            const SizedBox(height: 6),
            SelectableText.rich(comNegrito(_texto, Mixart.ui(size: 13.5, color: Mixart.text).copyWith(height: 1.55))),
          ]),
        ),
    ]);
  }
}

class _Cartao extends StatelessWidget {
  final Key chave;
  final Widget child;
  const _Cartao({required this.chave, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        key: chave,
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Mixart.surfaceHi,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: child,
      );
}

/// Markdown de bolso: **negrito**, *itálico* e `código` (o resto fica como veio).
TextSpan comNegrito(String texto, TextStyle base) {
  final partes = <InlineSpan>[];
  final re = RegExp(r'\*\*(.+?)\*\*|\*([^*\n]+?)\*|`([^`]+)`');
  var i = 0;
  for (final m in re.allMatches(texto)) {
    if (m.start > i) partes.add(TextSpan(text: texto.substring(i, m.start)));
    if (m.group(1) != null) {
      partes.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w800)));
    } else if (m.group(2) != null) {
      partes.add(TextSpan(text: m.group(2), style: const TextStyle(fontStyle: FontStyle.italic)));
    } else {
      partes.add(TextSpan(text: m.group(3), style: TextStyle(color: Mixart.brand, fontWeight: FontWeight.w600)));
    }
    i = m.end;
  }
  if (i < texto.length) partes.add(TextSpan(text: texto.substring(i)));
  return TextSpan(style: base, children: partes);
}
