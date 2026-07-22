import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../bloc/curso_bloc.dart';

/// Barra com os dois dropdowns (Trilha ▾ / Lição ▾) + contador.
class MenuTrilhas extends StatelessWidget {
  const MenuTrilhas({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CursoBloc, CursoState>(
      builder: (context, st) {
        if (st.status != CursoStatus.pronto) return const SizedBox.shrink();
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MenuBotao(
              kicker: 'TRILHA',
              emoji: st.trilha.emoji,
              nome: st.trilha.nivel,
              itens: [
                for (var i = 0; i < st.trilhas.length; i++)
                  _ItemMenu(
                    emoji: st.trilhas[i].emoji,
                    nome: st.trilhas[i].nivel,
                    sub: '${st.trilhas[i].licoes.length} lições',
                    atual: i == st.trilhaIdx,
                    concluida: false,
                    onTap: () => context.read<CursoBloc>().add(TrilhaSelecionada(i)),
                  ),
              ],
            ),
            _MenuBotao(
              kicker: 'LIÇÃO',
              emoji: st.licao.emoji,
              nome: st.licao.nome,
              itens: [
                for (var i = 0; i < st.trilha.licoes.length; i++)
                  _ItemMenu(
                    emoji: st.trilha.licoes[i].emoji,
                    nome: st.trilha.licoes[i].nome,
                    sub: '${st.trilha.licoes[i].trechos.length} exercícios',
                    atual: i == st.licaoIdx,
                    concluida: st.licaoConcluida(st.trilhaIdx, i),
                    onTap: () => context.read<CursoBloc>().add(LicaoSelecionada(i)),
                  ),
              ],
            ),
            Text(
              'Trilha ${st.trilhaIdx + 1}/${st.trilhas.length} · Lição ${st.licaoIdx + 1}/${st.trilha.licoes.length}',
              style: Mixart.mono(size: 11, color: Mixart.textFaint),
            ),
          ],
        );
      },
    );
  }
}

class _ItemMenu {
  final String emoji, nome, sub;
  final bool atual, concluida;
  final VoidCallback onTap;
  const _ItemMenu({
    required this.emoji,
    required this.nome,
    required this.sub,
    required this.atual,
    required this.concluida,
    required this.onTap,
  });
}

class _MenuBotao extends StatelessWidget {
  final String kicker, emoji, nome;
  final List<_ItemMenu> itens;
  const _MenuBotao({required this.kicker, required this.emoji, required this.nome, required this.itens});

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Color(0xFF141414)),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
            side: BorderSide(color: Mixart.border),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(7)),
        maximumSize: const WidgetStatePropertyAll(Size(340, 420)),
      ),
      builder: (context, controller, _) => InkWell(
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: controller.isOpen ? Mixart.brand : Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kicker,
                  style: Mixart.ui(size: 9, weight: FontWeight.w600, color: Mixart.textFaint)
                      .copyWith(letterSpacing: 1.6)),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Text(nome,
                    overflow: TextOverflow.ellipsis,
                    style: Mixart.ui(size: 13.5, weight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(width: 10),
            Icon(controller.isOpen ? Icons.expand_less : Icons.expand_more,
                size: 17, color: controller.isOpen ? Mixart.brand : Mixart.textFaint),
          ]),
        ),
      ),
      menuChildren: [
        for (final it in itens)
          MenuItemButton(
            onPressed: it.onTap,
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(it.atual ? Mixart.brand : Colors.transparent),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 11, vertical: 9)),
            ),
            child: SizedBox(
              width: 250,
              child: Row(children: [
                SizedBox(width: 24, child: Text(it.emoji, style: const TextStyle(fontSize: 15))),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(it.nome,
                      overflow: TextOverflow.ellipsis,
                      style: Mixart.ui(
                          size: 13,
                          weight: FontWeight.w600,
                          color: it.atual ? Mixart.onBrand : Mixart.textMuted)),
                ),
                Text(it.sub,
                    style: Mixart.ui(
                        size: 10.5,
                        weight: FontWeight.w400,
                        color: it.atual ? Mixart.onBrand.withValues(alpha: .6) : Mixart.textFaint)),
                if (it.concluida) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check, size: 14, color: it.atual ? Mixart.onBrand : Mixart.brand),
                ],
              ]),
            ),
          ),
      ],
    );
  }
}
