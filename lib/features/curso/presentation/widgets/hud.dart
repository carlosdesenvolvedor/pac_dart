import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/linguagem/linguagem_cubit.dart';
import '../../../../core/som/sons.dart';
import '../../../../core/brand/logo_pacdart.dart';
import '../../../../core/theme/mixart.dart';
import '../../../../core/theme/seletor_tema.dart';
import '../../../arcade/presentation/arcade_page.dart';
import '../../../auth/presentation/auth_cubit.dart';
import '../../../auth/presentation/excluir_conta_dialog.dart';
import '../../../habito/presentation/widgets/chip_sequencia.dart';
import '../../../ingles/presentation/fixacao.dart';
import '../../../ingles/presentation/ouvir/ouvir_acoes.dart';
import '../../../ingles/presentation/ouvir/ouvir_cubit.dart';
import '../../../ingles/presentation/ouvir/ouvir_state.dart';
import '../../../ingles/presentation/revisao_cubit.dart';
import '../../../ranking/presentation/ranking_page.dart';
import '../bloc/typing_bloc.dart';
import '../bloc/voz_cubit.dart';
import '../pages/escolha_linguagem_page.dart';
import '../pages/mapa_page.dart';

/// Cabeçalho: logo Pac-Man, título e estatísticas ao vivo.
class Hud extends StatefulWidget {
  const Hud({super.key});

  @override
  State<Hud> createState() => _HudState();
}

class _HudState extends State<Hud> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    Sons.carregar().then((_) {
      if (mounted) setState(() {});
    });
    // relógio e PPM atualizam a cada segundo
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _tempo(DateTime? inicio) {
    if (inicio == null) return '0:00';
    final s = DateTime.now().difference(inicio).inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 10,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            const _LogoPac(),
            const SizedBox(width: 12),
            const _Marca(),
          ]),
          BlocBuilder<TypingBloc, TypingState>(
            builder: (context, st) => Wrap(spacing: 8, runSpacing: 8, children: [
              _Stat('SCORE', '${st.score}', cor: Mixart.brand),
              _Stat('PPM', '${st.ppm(DateTime.now())}'),
              _Stat('PRECISÃO', '${st.precisao}%'),
              _Stat('ERROS', '${st.errosSessao}', cor: Mixart.danger),
              _Stat('TEMPO', _tempo(st.inicioSessao)),
            ]),
          ),
          // Wrap: no celular os botões quebram linha em vez de sumir pela borda
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            // não é const de propósito: o relógio do Hud (1 s) redesenha o chip na virada do dia
            // ignore: prefer_const_constructors
            ChipSequencia(),
            _Toggle(
              rotulo: 'Mapa',
              icone: Icons.route_outlined,
              ligado: false,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MapaPage()),
              ),
            ),
            _Toggle(
              rotulo: 'Arcade',
              icone: Icons.sports_esports_outlined,
              ligado: false,
              onTap: () => Navigator.of(context).push(
                // com o nome, o mini-player do "🎧 Ouvir" some (e pausa) enquanto o Arcade está aberto
                MaterialPageRoute<void>(builder: (_) => const ArcadePage(), settings: const RouteSettings(name: rotaArcade)),
              ),
            ),
            _Toggle(
              rotulo: 'Ranking',
              icone: Icons.emoji_events_outlined,
              ligado: false,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RankingPage()),
              ),
            ),
            // inglês: a revisão espaçada do dia no lugar da narração das
            // dicas (o áudio das frases fica no próprio palco)
            if (RevisaoCubit.de(context) != null)
              BlocBuilder<RevisaoCubit, RevisaoState>(
                builder: (context, rv) {
                  final n = rv.quantasDevidas(context.read<RevisaoCubit>().hoje);
                  return _Toggle(
                    rotulo: n > 0 ? 'Revisão · $n' : 'Revisão',
                    icone: Icons.replay_rounded,
                    ligado: n > 0,
                    onTap: () => abrirRevisao(context),
                  );
                },
              )
            else
              BlocBuilder<VozCubit, bool>(
                builder: (context, vozOn) => _Toggle(
                  rotulo: 'Voz',
                  icone: Icons.campaign_outlined,
                  ligado: vozOn,
                  onTap: () => context.read<VozCubit>().alternar(),
                ),
              ),
            // inglês: escutar as lições na ordem ou as setlists, sem digitar (aceso enquanto toca)
            if (OuvirCubit.de(context) != null)
              BlocBuilder<OuvirCubit, OuvirState>(
                buildWhen: (a, b) => a.ativo != b.ativo,
                builder: (context, ov) => _Toggle(
                  key: const Key('ouvir-hud'),
                  rotulo: 'Ouvir',
                  // headset, não headphones: o 🎧 (headphones) do palco é o "seu áudio" da frase
                  icone: Icons.headset_rounded,
                  ligado: ov.ativo,
                  onTap: () => abrirOuvir(context),
                ),
              ),
            _Toggle(
              rotulo: 'Som',
              icone: Icons.music_note_outlined,
              ligado: Sons.ligado,
              onTap: () {
                Sons.alternar();
                setState(() {});
              },
            ),
            const SeletorTema(compacto: true),
            const _ContaBotao(),
          ]),
        ],
      ),
    );
  }
}

/// PACLINGO + a linha da vertente (DART & FLUTTER, C# & .NET, INGLÊS), que também é o
/// botão de trocar de curso (volta para a tela "Escolha sua trilha").
class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    final lg = LinguagemCubit.de(context);
    final temCubit = LinguagemCubit.existe(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(
        text: TextSpan(style: Mixart.display(size: 26), children: [
          const TextSpan(text: 'PAC'),
          TextSpan(text: 'LINGO', style: TextStyle(color: Mixart.brand)),
        ]),
      ),
      InkWell(
        onTap: temCubit
            ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const EscolhaLinguagemPage(podeVoltar: true),
                ))
            : null,
        borderRadius: BorderRadius.circular(6),
        child: Tooltip(
          message: temCubit ? 'Trocar de curso (Dart ⇄ C# ⇄ Inglês)' : '',
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(lg.subtitulo,
                style: Mixart.ui(size: 10, weight: FontWeight.w600, color: Mixart.brand).copyWith(letterSpacing: 2.4)),
            if (temCubit) ...[
              const SizedBox(width: 5),
              Icon(Icons.swap_horiz_rounded, size: 14, color: Mixart.brand),
            ],
          ]),
        ),
      ),
    ]);
  }

}

class _LogoPac extends StatelessWidget {
  const _LogoPac();
  @override
  Widget build(BuildContext context) => const LogoPacDart(tamanho: 42);
}

/// Botão de conta: mostra o usuário e permite sair.
class _ContaBotao extends StatelessWidget {
  const _ContaBotao();

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user);
    return PopupMenuButton<String>(
      tooltip: 'Sua conta',
      color: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        side: BorderSide(color: Mixart.border),
      ),
      offset: const Offset(0, 46),
      onSelected: (v) {
        if (v == 'sair') context.read<AuthCubit>().sair();
        if (v == 'excluir') mostrarExcluirConta(context);
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Logado como', style: Mixart.ui(size: 10, weight: FontWeight.w600, color: Mixart.textFaint)),
            const SizedBox(height: 2),
            Text(user?.email ?? '—', style: Mixart.ui(size: 12.5, weight: FontWeight.w600, color: Mixart.text)),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'sair',
          child: Row(children: [
            Icon(Icons.logout, size: 16, color: Mixart.danger),
            const SizedBox(width: 10),
            Text('Sair da conta', style: Mixart.ui(size: 13, weight: FontWeight.w600, color: Mixart.danger)),
          ]),
        ),
        PopupMenuItem<String>(
          value: 'excluir',
          child: Row(children: [
            Icon(Icons.delete_forever_outlined, size: 16, color: Mixart.textMuted),
            const SizedBox(width: 10),
            Text('Excluir minha conta', style: Mixart.ui(size: 13, weight: FontWeight.w600, color: Mixart.textMuted)),
          ]),
        ),
      ],
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Mixart.surfaceHi,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          (user?.apelido.isNotEmpty ?? false) ? user!.apelido[0].toUpperCase() : '?',
          style: Mixart.display(size: 15, color: Mixart.brand),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String k, v;
  final Color? cor;
  const _Stat(this.k, this.v, {this.cor});
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Mixart.surfaceHi,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(children: [
          Text(k, style: Mixart.ui(size: 9.5, weight: FontWeight.w600, color: Mixart.textMuted).copyWith(letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(v, style: Mixart.display(size: 17, color: cor ?? Mixart.text)),
        ]),
      );
}

class _Toggle extends StatelessWidget {
  final String rotulo;
  final IconData icone;
  final bool ligado;
  final VoidCallback onTap;
  const _Toggle({super.key, required this.rotulo, required this.icone, required this.ligado, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: ligado ? Mixart.brand : Mixart.surfaceHi,
            border: Border.all(color: ligado ? Mixart.brand : Mixart.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icone, size: 17, color: ligado ? Mixart.onBrand : Mixart.textMuted),
            const SizedBox(width: 7),
            Text(rotulo,
                style: Mixart.ui(
                    size: 13,
                    weight: ligado ? FontWeight.w700 : FontWeight.w500,
                    color: ligado ? Mixart.onBrand : Mixart.textMuted)),
          ]),
        ),
      );
}
