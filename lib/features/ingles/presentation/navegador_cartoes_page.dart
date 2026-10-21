import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../data/audio_usuario.dart';
import '../data/voz_ingles.dart';
import '../domain/baralhos.dart';
import '../domain/revisao.dart';
import '../domain/setlist.dart';
import '../domain/srs.dart';
import 'ouvir/ouvir_acoes.dart';
import 'ouvir/ouvir_cubit.dart';
import 'revisao_cubit.dart';
import 'widgets/audio_da_frase.dart';

/// O "navegador de cartões" do Anki, de um baralho: cada frase com a situação
/// dos dois sentidos (digitar de memória e inglês → português) e as ações de
/// suspender (some até reativar) e enterrar (some até amanhã).
class NavegadorCartoesPage extends StatefulWidget {
  final Baralho baralho;

  /// Voz injetável (testes).
  final VozIngles? voz;

  const NavegadorCartoesPage({super.key, required this.baralho, this.voz});

  @override
  State<NavegadorCartoesPage> createState() => _NavegadorCartoesPageState();
}

class _NavegadorCartoesPageState extends State<NavegadorCartoesPage> {
  late final VozIngles _voz = widget.voz ?? VozIngles();
  final _busca = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _voz.parar();
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final revisao = context.watch<RevisaoCubit>();
    final st = revisao.state;
    final hoje = revisao.hoje;
    final f = _filtro.trim().toLowerCase();
    // "🎧 Ouvir": ➕ pôr a frase na setlist (só com o player na árvore)
    final comSetlist = OuvirCubit.de(context) != null;
    final frases = [
      for (final t in widget.baralho.frases)
        if (f.isEmpty || t.cod.toLowerCase().contains(f) || t.dicaPlana.toLowerCase().contains(f)) t,
    ];
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Row(children: [
                  IconButton(
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
                    style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
                  ),
                  const SizedBox(width: 12),
                  Text(widget.baralho.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.baralho.nome, style: Mixart.display(size: 19), overflow: TextOverflow.ellipsis),
                      Text('${frases.length} de ${widget.baralho.frases.length} cartões',
                          style: Mixart.ui(size: 12, color: Mixart.textMuted)),
                    ]),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: TextField(
                  key: const Key('busca-cartoes'),
                  controller: _busca,
                  onChanged: (v) => setState(() => _filtro = v),
                  style: Mixart.ui(size: 14, color: Mixart.text),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Buscar no inglês ou na tradução…',
                    hintStyle: Mixart.ui(size: 13.5, color: Mixart.textFaint),
                    prefixIcon: Icon(Icons.search, size: 19, color: Mixart.textMuted),
                    filled: true,
                    fillColor: Mixart.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.brand, width: 1.4)),
                  ),
                ),
              ),
              Expanded(
                child: frases.isEmpty
                    ? Center(child: Text('Nenhum cartão encontrado.', style: Mixart.ui(size: 13, color: Mixart.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
                        itemCount: frases.length,
                        itemBuilder: (_, i) {
                          final t = frases[i];
                          final k = RevisaoCubit.chaveDe(t);
                          return _Linha(
                            key: ValueKey(k),
                            en: t.cod,
                            pt: t.dicaPlana,
                            direto: st.cartoes[k],
                            invertido: st.cartoes[Revisao.chaveReversa(k)],
                            invertidoLigado: st.config.reversoLigado(widget.baralho.id),
                            hoje: hoje,
                            onOuvir: () => unawaited(_voz.falar(t.cod)),
                            onAudio: () => mostrarAudioDaFrase(context, t.cod, voz: _voz),
                            onSetlist: comSetlist ? () => porNaSetlist(context, ItemSetlist.daFrase(t)) : null,
                            onSuspender: (rev, valor) =>
                                revisao.suspender(rev ? Revisao.chaveReversa(k) : k, suspenso: valor),
                            onEnterrar: (rev) => revisao.enterrar(rev ? Revisao.chaveReversa(k) : k),
                          );
                        },
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  final String en, pt;
  final CartaoSrs? direto, invertido;
  final bool invertidoLigado;
  final int hoje;
  final VoidCallback onOuvir, onAudio;

  /// ➕ "Pôr na setlist" (null = sem o "🎧 Ouvir").
  final VoidCallback? onSetlist;
  final void Function(bool reverso, bool suspender) onSuspender;
  final void Function(bool reverso) onEnterrar;

  const _Linha({
    super.key,
    required this.en,
    required this.pt,
    required this.direto,
    required this.invertido,
    required this.invertidoLigado,
    required this.hoje,
    required this.onOuvir,
    required this.onAudio,
    this.onSetlist,
    required this.onSuspender,
    required this.onEnterrar,
  });

  Widget _chip(String sentido, CartaoSrs? c, {required bool ligado}) {
    final String texto;
    Color cor = Mixart.textMuted;
    if (c == null) {
      texto = ligado ? 'novo' : 'ainda não';
    } else {
      texto = descreverVencimento(c, hoje);
      if (c.suspenso) cor = Mixart.danger;
      if (!c.suspenso && c.devidaEm(hoje)) cor = Mixart.brand;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: .10),
        border: Border.all(color: cor.withValues(alpha: .45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$sentido · $texto${c == null ? '' : ' · memória ${c.estabilidade < 10 ? c.estabilidade.toStringAsFixed(1) : c.estabilidade.round()} d'}',
        style: Mixart.ui(size: 10.5, weight: FontWeight.w700, color: cor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(en, style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.text).copyWith(height: 1.35)),
            const SizedBox(height: 2),
            Text(pt, style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.35)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _chip('digitar', direto, ligado: false), // sem cartão = ainda não aprendida numa lição
              if (invertido != null || invertidoLigado) _chip('virar', invertido, ligado: invertidoLigado),
            ]),
          ]),
        ),
        PopupMenuButton<String>(
          key: ValueKey('menu-$en'),
          tooltip: 'Ações do cartão',
          icon: Icon(Icons.more_vert, color: Mixart.textMuted, size: 20),
          color: Mixart.surface,
          onSelected: (v) {
            switch (v) {
              case 'ouvir':
                onOuvir();
              case 'audio':
                onAudio();
              case 'setlist':
                onSetlist?.call();
              case 'susp-d':
                onSuspender(false, !(direto?.suspenso ?? false));
              case 'susp-v':
                onSuspender(true, !(invertido?.suspenso ?? false));
              case 'ent-d':
                onEnterrar(false);
              case 'ent-v':
                onEnterrar(true);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'ouvir', child: Text('🔊 Ouvir')),
            if (AudioUsuario.disponivel)
              PopupMenuItem(
                  value: 'audio', child: Text(AudioUsuario.tem(en) ? '🎧 Seu áudio…' : '🎧 Adicionar o seu áudio…')),
            if (onSetlist != null) const PopupMenuItem(value: 'setlist', child: Text('➕ Pôr na setlist')),
            if (direto != null) ...[
              PopupMenuItem(value: 'susp-d', child: Text(direto!.suspenso ? '▶️ Reativar (digitar)' : '⏸ Suspender (digitar)')),
              if (!direto!.suspenso) const PopupMenuItem(value: 'ent-d', child: Text('🌙 Enterrar até amanhã (digitar)')),
            ],
            if (invertido != null) ...[
              PopupMenuItem(value: 'susp-v', child: Text(invertido!.suspenso ? '▶️ Reativar (virar)' : '⏸ Suspender (virar)')),
              if (!invertido!.suspenso) const PopupMenuItem(value: 'ent-v', child: Text('🌙 Enterrar até amanhã (virar)')),
            ],
          ],
        ),
      ]),
    );
  }
}
