import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../../../core/theme/seletor_tema.dart';
import '../../../auth/presentation/auth_cubit.dart';
import '../bloc/typing_bloc.dart';
import '../bloc/voz_cubit.dart';
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
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(
                text: TextSpan(style: Mixart.display(size: 26), children: [
                  TextSpan(text: 'PAC'),
                  TextSpan(text: '·', style: TextStyle(color: Mixart.brand)),
                  TextSpan(text: 'DART'),
                ]),
              ),
              Text('DART & FLUTTER',
                  style: Mixart.ui(size: 10, weight: FontWeight.w600, color: Mixart.brand)
                      .copyWith(letterSpacing: 2.4)),
            ]),
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
          Row(mainAxisSize: MainAxisSize.min, children: [
            _Toggle(
              rotulo: 'Mapa',
              icone: Icons.route_outlined,
              ligado: false,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MapaPage()),
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<VozCubit, bool>(
              builder: (context, vozOn) => _Toggle(
                rotulo: 'Voz',
                icone: Icons.campaign_outlined,
                ligado: vozOn,
                onTap: () => context.read<VozCubit>().alternar(),
              ),
            ),
            const SizedBox(width: 8),
            const SeletorTema(compacto: true),
            const SizedBox(width: 8),
            const _ContaBotao(),
          ]),
        ],
      ),
    );
  }
}

class _LogoPac extends StatelessWidget {
  const _LogoPac();
  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: Mixart.brand, shape: BoxShape.circle),
        child: Icon(Icons.play_arrow, color: Mixart.onBrand),
      );
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
  const _Toggle({required this.rotulo, required this.icone, required this.ligado, required this.onTap});
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
