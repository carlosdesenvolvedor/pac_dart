import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../domain/progresso_missoes.dart';
import 'missao_page.dart';
import 'widgets/arcade_ui.dart';

/// 🗺️ Lógica Animada — escolha a trilha da missão. Cada trilha do Mapa tem
/// seu próprio estoque de missões geradas; libera jogando o Mapa (basta 1
/// lição concluída da trilha — a primeira já vem aberta).
class MissoesPage extends StatefulWidget {
  const MissoesPage({super.key});

  @override
  State<MissoesPage> createState() => _MissoesPageState();
}

class _MissoesPageState extends State<MissoesPage> {
  final Map<int, int> _proximas = {};

  @override
  void initState() {
    super.initState();
    _carregaProgresso();
  }

  Future<void> _carregaProgresso() async {
    final curso = context.read<CursoBloc>().state;
    for (var t = 0; t < curso.trilhas.length; t++) {
      final p = await ProgressoMissoes.proxima(t);
      if (!mounted) return;
      setState(() => _proximas[t] = p);
    }
  }

  bool _liberada(CursoState curso, int t) =>
      t == 0 || curso.concluidas.any((c) => c.startsWith('$t:'));

  @override
  Widget build(BuildContext context) {
    final curso = context.watch<CursoBloc>().state;
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: curso.status != CursoStatus.pronto
                ? Center(child: CircularProgressIndicator(color: Mixart.brand))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                    children: [
                      const CabecalhoJogo(
                          rotulo: 'ARCADE · MISSÕES', titulo: '🗺️ Lógica Animada'),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Mixart.brandSub,
                          border: Border.all(color: Mixart.brandDim),
                          borderRadius: BorderRadius.circular(Mixart.radiusMd),
                        ),
                        child: Text(
                          'Cada missão é uma cena travada: PREVEJA o resultado da '
                          'lógica, DIGITE o código pra destravar e ASSISTA ele rodar '
                          'animado. Na dúvida, a 🔮 Ajuda Misteriosa dá pistas. As '
                          'missões são geradas sem fim, trilha a trilha — estude no '
                          'Mapa pra liberar mais mundos!',
                          style:
                              Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.55),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _grade(curso),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _grade(CursoState curso) {
    return LayoutBuilder(builder: (context, box) {
      final colunas = box.maxWidth >= 880
          ? 3
          : box.maxWidth >= 580
              ? 2
              : 1;
      final largura = (box.maxWidth - (colunas - 1) * 12) / colunas;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        for (var t = 0; t < curso.trilhas.length; t++)
          if (curso.trilhas[t].licoes.isNotEmpty)
            SizedBox(width: largura, child: _cartao(curso, t)),
      ]);
    });
  }

  Widget _cartao(CursoState curso, int t) {
    final trilha = curso.trilhas[t];
    final liberada = _liberada(curso, t);
    final feitas = _proximas[t] ?? 0;
    return Material(
      color: Mixart.surface,
      borderRadius: BorderRadius.circular(Mixart.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        onTap: liberada
            ? () => Navigator.of(context)
                .push(MaterialPageRoute<void>(
                  builder: (_) => MissaoPage(
                    trilhaIdx: t,
                    trilhaNome: trilha.nivel,
                    trilhaEmoji: trilha.emoji,
                  ),
                ))
                .then((_) => _carregaProgresso())
            : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: liberada ? Mixart.border : Mixart.surfaceHi),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Opacity(
            opacity: liberada ? 1 : 0.55,
            child: Row(children: [
              Text(liberada ? trilha.emoji : '🔒', style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(trilha.nivel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mixart.display(size: 14.5)),
                  const SizedBox(height: 3),
                  Text(
                    liberada
                        ? (feitas == 0
                            ? 'começar a missão 1'
                            : '$feitas cumprida${feitas > 1 ? 's' : ''} · próxima: ${feitas + 1}')
                        : 'conclua 1 lição no Mapa',
                    style: Mixart.ui(size: 11, color: Mixart.textMuted),
                  ),
                ]),
              ),
              if (liberada)
                Icon(Icons.play_circle_outline, size: 20, color: Mixart.brand),
            ]),
          ),
        ),
      ),
    );
  }
}
