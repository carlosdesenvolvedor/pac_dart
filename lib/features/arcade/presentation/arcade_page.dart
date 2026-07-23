import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/personagem.dart';
import 'widgets/avatares.dart';
import 'caca_bug_page.dart';
import 'chuva_page.dart';
import 'corrida_page.dart';
import 'futebol_page.dart';
import 'missoes_page.dart';
import 'rali_page.dart';
import 'widgets/arcade_ui.dart';

/// 🎮 Hub do Arcade: os joguinhos de Dart, com o recorde pessoal de cada um.
class ArcadePage extends StatefulWidget {
  const ArcadePage({super.key});

  @override
  State<ArcadePage> createState() => _ArcadePageState();
}

class _ArcadePageState extends State<ArcadePage> {
  RankingCubit? _ranking;

  @override
  void initState() {
    super.initState();
    _ranking = RankingCubit.de(context);
    _ranking?.carregarTop(); // atualiza os recordes dos cartões
    PersonagemStore.carregar().then((_) {
      if (mounted) setState(() {});
    });
  }

  static final _jogos = [
    (
      id: 'chuva',
      emoji: '☄️',
      nome: 'Chuva de Código',
      tag: 'DIGITAÇÃO',
      descricao: 'Palavras do Dart despencam do céu e o Pac atira pela boca: '
          'cada letra digitada é um tiro. Não deixe nada tocar o chão!',
      abre: (BuildContext c) => const ChuvaPage(),
    ),
    (
      id: 'rali',
      emoji: '🏁',
      nome: 'Rali de Digitação',
      tag: 'DIGITAÇÃO',
      descricao: 'Cada palavra digitada acelera seu carrinho — palavra perfeita '
          'dá TURBO. A CPU corre no relógio e não espera ninguém.',
      abre: (BuildContext c) => const RaliPage(),
    ),
    (
      id: 'corrida',
      emoji: '🏎️',
      nome: 'Corrida do Código',
      tag: 'LÓGICA',
      descricao: 'Preveja o que o código imprime para acelerar. '
          'Resposta rápida liga o turbo — e a CPU não perdoa derrapada.',
      abre: (BuildContext c) => const CorridaPage(),
    ),
    (
      id: 'futebol',
      emoji: '⚽',
      nome: 'Gol de Dart',
      tag: 'SINTAXE',
      descricao: 'Cinco pênaltis: complete a peça que falta no código e '
          'escolha o canto. Errou a sintaxe? O goleiro agradece.',
      abre: (BuildContext c) => const FutebolPage(),
    ),
    (
      id: 'cacaBug',
      emoji: '🐞',
      nome: 'Caça-Bug',
      tag: 'ATENÇÃO',
      descricao: 'Uma linha do trecho está estragada. Ache e esmague o bug '
          'antes de o relógio zerar — segundos sobrando viram bônus.',
      abre: (BuildContext c) => const CacaBugPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
              children: [
                const CabecalhoJogo(rotulo: 'PAC·DART', titulo: '🎮 Arcade Dart'),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Mixart.brandSub,
                    border: Border.all(color: Mixart.brandDim),
                    borderRadius: BorderRadius.circular(Mixart.radiusMd),
                  ),
                  child: Text(
                    'Treine a lógica e a sintaxe do Dart jogando. Vença as fases, '
                    'viaje pelos cenários e acumule pontos no seu ranking 🏆 — o '
                    'recorde pessoal de cada jogo fica guardado.',
                    style: Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.55),
                  ),
                ),
                const SizedBox(height: 18),
                _seletorPersonagem(),
                const SizedBox(height: 18),
                _cartaoMissoes(),
                const SizedBox(height: 12),
                _cartoes(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cartão de destaque do modo missões (Lógica Animada).
  Widget _cartaoMissoes() {
    return Material(
      color: Mixart.surface,
      borderRadius: BorderRadius.circular(Mixart.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const MissoesPage()))
            .then((_) => _ranking?.carregarTop()),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: Mixart.brandDim, width: 1.4),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
            gradient: LinearGradient(colors: [Mixart.brandSub, Mixart.surface]),
          ),
          child: Row(children: [
            const Text('🗺️', style: TextStyle(fontSize: 38)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text('Lógica Animada', style: Mixart.display(size: 19))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Mixart.brand, borderRadius: BorderRadius.circular(999)),
                    child: Text('NOVO',
                        style:
                            Mixart.ui(size: 9, weight: FontWeight.w800, color: Mixart.onBrand)
                                .copyWith(letterSpacing: 1)),
                  ),
                ]),
                const SizedBox(height: 5),
                Text(
                  'Missões sem fim, trilha a trilha: preveja a lógica, digite o '
                  'código pra destravar a cena e assista ele rodar animado — com '
                  '🔮 Ajuda Misteriosa pra quando bater dúvida.',
                  style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            Icon(Icons.play_circle_fill, size: 34, color: Mixart.brand),
          ]),
        ),
      ),
    );
  }

  Widget _seletorPersonagem() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SEU PERSONAGEM',
          style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.textMuted)
              .copyWith(letterSpacing: 2)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final p in Personagem.values) _cartaoPersonagem(p),
      ]),
    ]);
  }

  Widget _cartaoPersonagem(Personagem p) {
    final escolhido = PersonagemStore.atual == p;
    return Material(
      color: Mixart.surface,
      borderRadius: BorderRadius.circular(Mixart.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        onTap: () {
          PersonagemStore.trocar(p);
          setState(() {});
        },
        child: Container(
          width: 250,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
                color: escolhido ? Mixart.brand : Mixart.border, width: escolhido ? 1.8 : 1),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Row(children: [
            AvatarPersonagem(tamanho: 40, personagem: p),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.rotulo, style: Mixart.display(size: 15)),
                const SizedBox(height: 2),
                Text(p.descricao, style: Mixart.ui(size: 11, color: Mixart.textMuted)),
              ]),
            ),
            if (escolhido) Icon(Icons.check_circle, size: 18, color: Mixart.brand),
          ]),
        ),
      ),
    );
  }

  Widget _cartoes() {
    final cubit = _ranking;
    return LayoutBuilder(builder: (context, box) {
      final colunas = box.maxWidth >= 900
          ? 3
          : box.maxWidth >= 600
              ? 2
              : 1;
      final largura = (box.maxWidth - (colunas - 1) * 12) / colunas;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        for (final j in _jogos) SizedBox(width: largura, child: _cartao(j, cubit)),
      ]);
    });
  }

  Widget _cartao(
      ({
        String id,
        String emoji,
        String nome,
        String tag,
        String descricao,
        Widget Function(BuildContext) abre,
      }) jogo,
      RankingCubit? cubit) {
    return Material(
      color: Mixart.surface,
      borderRadius: BorderRadius.circular(Mixart.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: jogo.abre))
            .then((_) => _ranking?.carregarTop()),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(jogo.emoji, style: const TextStyle(fontSize: 34)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Mixart.surfaceHi,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Mixart.border),
                ),
                child: Text(jogo.tag,
                    style: Mixart.ui(size: 9.5, weight: FontWeight.w700, color: Mixart.brand)
                        .copyWith(letterSpacing: 1.4)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(jogo.nome, style: Mixart.display(size: 18)),
            const SizedBox(height: 6),
            Text(jogo.descricao,
                style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: cubit == null
                    ? const SizedBox.shrink()
                    : BlocBuilder<RankingCubit, RankingState>(
                        bloc: cubit,
                        builder: (context, st) {
                          final recorde = st.meu(cubit.uid)?.recordeDoJogo(jogo.id) ?? 0;
                          return Row(children: [
                            Icon(Icons.workspace_premium_outlined,
                                size: 14, color: Mixart.textMuted),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                  recorde > 0 ? 'recorde: $recorde pts' : 'sem recorde ainda',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
                            ),
                          ]);
                        },
                      ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: Mixart.brand,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.play_arrow_rounded, size: 16, color: Mixart.onBrand),
                  const SizedBox(width: 4),
                  Text('Jogar',
                      style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.onBrand)),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
