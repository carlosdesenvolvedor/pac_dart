import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../../ingles/presentation/palavras_cubit.dart';
import '../bloc/curso_bloc.dart';
import '../widgets/hud.dart';
import 'mapa_page.dart';

/// 🏠 A tela Início (pedido do dono, 26/out/2026): o app abre nela, com o "▶ Continuar" de onde a pessoa parou e
/// o menu de tudo (treinos, ferramentas, mapa, arcade, ranking, som, tema, conta). A lição fica limpa — só o
/// "☰ Início" e a frase — e o mapa fica só com o caminho. Ela abre POR CIMA da lição (a lição não perde o
/// passo em que estava): "Continuar" fecha o Início e volta para a frase.
abstract final class Inicio {
  /// Ligada no app; os testes antigos (lição com o cabeçalho cheio e o mapa com as ferramentas) desligam no
  /// `flutter_test_config.dart`.
  static bool ligado = true;

  /// O nome da rota (o palco sabe que está coberto por ela).
  static const rota = '/inicio';
}

/// Abre a tela Início por cima da lição (sem a animação na abertura do app).
Future<void> abrirInicio(BuildContext context, {bool semAnimacao = false}) => Navigator.of(context).push(
      semAnimacao
          ? PageRouteBuilder<void>(
              settings: const RouteSettings(name: Inicio.rota),
              pageBuilder: (_, _, _) => const InicioPage(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: const Duration(milliseconds: 200),
              transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
            )
          : MaterialPageRoute<void>(settings: const RouteSettings(name: Inicio.rota), builder: (_) => const InicioPage()),
    );

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final temPalavras = PalavrasCubit.de(context) != null;
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: BlocBuilder<CursoBloc, CursoState>(
          builder: (context, st) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: ListView(
                key: const Key('inicio'),
                padding: const EdgeInsets.fromLTRB(0, 18, 0, 48),
                children: [
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: MarcaPaclingo()),
                  const SizedBox(height: 16),
                  _Continuar(st: st),
                  const _Titulo('Hoje'),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: AtalhosHud()),
                  const SizedBox(height: 4),
                  if (st.status == CursoStatus.pronto) const CartaoTreinoDia(),
                  if (st.status == CursoStatus.pronto && st.ehIngles) ...[
                    const _Titulo('Praticar'),
                    const CartaoOuvir(),
                    const CartaoConversar(),
                    const CartaoEscrever(),
                    const CartaoLer(),
                    const CartaoBaralhos(),
                    if (temPalavras) CartaoMinhasPalavras(st: st),
                    const CartaoNovoTexto(),
                  ],
                  if (st.status == CursoStatus.pronto) ...[
                    const _Titulo('Seu progresso'),
                    HeroDashboard(st: st),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;
  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
        child: Text(texto.toUpperCase(),
            style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.textMuted).copyWith(letterSpacing: 1.6)),
      );
}

/// ▶ O cartão grande "Continuar": a trilha e a lição onde a pessoa parou.
class _Continuar extends StatelessWidget {
  final CursoState st;
  const _Continuar({required this.st});

  @override
  Widget build(BuildContext context) {
    final pronto = st.status == CursoStatus.pronto && st.trilhas.isNotEmpty;
    final trilha = pronto ? st.trilha : null;
    final licao = pronto ? st.licao : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Material(
        color: Mixart.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          side: BorderSide(color: Mixart.brand, width: 1.5),
        ),
        child: InkWell(
          key: const Key('inicio-continuar'),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          onTap: pronto ? () => Navigator.of(context).maybePop() : null,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Text(licao?.emoji.isNotEmpty == true ? licao!.emoji : '▶', style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('CONTINUAR',
                      style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 1.6)),
                  const SizedBox(height: 4),
                  Text(licao?.nome ?? 'Carregando…', style: Mixart.display(size: 19), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (trilha != null) ...[
                    const SizedBox(height: 4),
                    Text('${trilha.nivel} · lição ${st.licaoIdx + 1} de ${trilha.licoes.length}',
                        style: Mixart.ui(size: 12.5, color: Mixart.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ]),
              ),
              const SizedBox(width: 10),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: Mixart.brand, shape: BoxShape.circle),
                child: pronto
                    ? Icon(Icons.play_arrow_rounded, size: 32, color: Mixart.onBrand)
                    : Padding(padding: const EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2.5, color: Mixart.onBrand)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// ☰ A barra da lição com a tela Início ligada: o botão de voltar ao Início e a 🔥 sequência. Nada mais.
class BarraDaLicao extends StatelessWidget {
  const BarraDaLicao({super.key});

  @override
  Widget build(BuildContext context) => Row(children: [
        OutlinedButton.icon(
          key: const Key('abrir-inicio'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Mixart.text,
            side: BorderSide(color: Mixart.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () => abrirInicio(context),
          icon: const Icon(Icons.menu_rounded, size: 18),
          label: Text('Início', style: Mixart.ui(size: 13, weight: FontWeight.w800)),
        ),
      ]);
}
