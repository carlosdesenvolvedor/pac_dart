import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../ia/presentation/feedback_cenario.dart' show salvarCartaoDoCenario;
import '../data/tradutor.dart';
import '../data/voz_ingles.dart';
import '../domain/cartoes_texto.dart';
import '../domain/leitura.dart';
import '../domain/nivel_resposta.dart';
import '../domain/texto_salvo.dart';
import 'revisao_cubit.dart';

/// Lê um texto: cada palavra é tocável. Tocar abre a folha com a FRASE INTEIRA e a tradução dela
/// (palavra isolada erra o sentido), a tradução da palavra e o botão que guarda um cartão de
/// lacuna daquela frase em "Meus cartões".
class LeituraPage extends StatelessWidget {
  final Leitura leitura;

  /// Injetáveis (testes): o tradutor das palavras e a voz.
  final Tradutor? tradutor;
  final VozIngles? voz;

  const LeituraPage({super.key, required this.leitura, this.tradutor, this.voz});

  /// Quais palavras já viraram cartão: frase (minúscula) → palavra-alvo (minúscula).
  static Map<String, String> guardadas(CursoState st) {
    final r = <String, String>{};
    for (final t in st.trilhas) {
      if (t.textoId != idCartoesAvulsos) continue;
      for (final l in t.licoes) {
        for (final x in l.trechos) {
          if (x.alvo.isNotEmpty) r[x.cod.toLowerCase()] = x.alvo.toLowerCase();
        }
      }
    }
    return r;
  }

  Future<void> _tocou(BuildContext context, FraseDoTexto frase, String palavra) {
    final curso = context.read<CursoBloc>();
    final revisao = RevisaoCubit.de(context);
    Tradutor t = tradutor ?? TradutorMyMemory();
    if (tradutor == null) {
      try {
        t = context.read<Tradutor>();
      } catch (_) {}
    }
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Mixart.surface,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 620),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusLg))),
      builder: (_) => MultiBlocProvider(
        providers: [BlocProvider.value(value: curso), if (revisao != null) BlocProvider.value(value: revisao)],
        child: FolhaDaPalavra(frase: frase, palavra: palavra, tradutor: t, voz: voz),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guardada = context.select((CursoBloc b) => guardadas(b.state));
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            // o cabeçalho fica parado (o texto rola por baixo): dá para voltar de qualquer ponto da leitura
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(children: [
                IconButton(
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
                  style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
                ),
                const SizedBox(width: 12),
                const Text('📖', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(leitura.titulo, style: Mixart.display(size: 20), overflow: TextOverflow.ellipsis),
                    Text(leitura.etapa, style: Mixart.ui(size: 12, color: Mixart.textMuted)),
                  ]),
                ),
                ]),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 48), children: [
              Text('Toque numa palavra para ver a frase inteira, a tradução e guardar um cartão de lacuna. '
                  'As palavras sublinhadas já viraram cartão.',
                  key: const Key('dica-leitura'), style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5)),
              const SizedBox(height: 16),
              for (var i = 0; i < leitura.frases.length; i++)
                _FraseTocavel(
                  frase: leitura.frases[i],
                  alvoGuardado: guardada[leitura.frases[i].en.toLowerCase()],
                  onPalavra: (p) => _tocou(context, leitura.frases[i], p),
                ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _FraseTocavel extends StatelessWidget {
  final FraseDoTexto frase;
  final String? alvoGuardado;
  final void Function(String palavra) onPalavra;
  const _FraseTocavel({required this.frase, required this.alvoGuardado, required this.onPalavra});

  @override
  Widget build(BuildContext context) {
    final partes = partirFrase(frase.en);
    // a mesma palavra pode aparecer mais de uma vez na frase: só a 1ª leva a chave "palavra-x" (as outras, "palavra-x#2"…)
    final vistas = <String, int>{};
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        key: const Key('frase-leitura'),
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 2,
        children: [
          for (final p in partes)
            if (!p.palavra)
              Text(p.texto, style: Mixart.display(size: 19, weight: FontWeight.w500, color: Mixart.textMuted).copyWith(height: 1.7))
            else
              InkWell(
                key: Key(() {
                  final k = p.texto.toLowerCase();
                  final n = vistas[k] = (vistas[k] ?? 0) + 1;
                  return n == 1 ? 'palavra-$k' : 'palavra-$k#$n';
                }()),
                borderRadius: BorderRadius.circular(6),
                onTap: () => onPalavra(p.texto),
                child: Text(
                  p.texto,
                  style: Mixart.display(size: 19, weight: FontWeight.w500, color: Mixart.text).copyWith(
                    height: 1.7,
                    decoration: alvoGuardado == p.texto.toLowerCase() ? TextDecoration.underline : null,
                    decorationColor: Mixart.brand,
                    decorationThickness: 2,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// A folha de uma palavra: a frase inteira (a palavra destacada) com a tradução, a tradução da palavra
/// com o aviso do sentido, ouvir e guardar o cartão de lacuna.
class FolhaDaPalavra extends StatefulWidget {
  final FraseDoTexto frase;
  final String palavra;
  final Tradutor tradutor;
  final VozIngles? voz;
  const FolhaDaPalavra({super.key, required this.frase, required this.palavra, required this.tradutor, this.voz});

  @override
  State<FolhaDaPalavra> createState() => _FolhaDaPalavraState();
}

enum _Fase { traduzindo, ok, falhou }

class _FolhaDaPalavraState extends State<FolhaDaPalavra> {
  late final VozIngles _voz = widget.voz ?? VozIngles();
  _Fase _fase = _Fase.traduzindo;
  String _traducao = '';
  String _erro = '';
  bool _guardando = false, _guardado = false;

  @override
  void initState() {
    super.initState();
    _traduzir();
  }

  @override
  void dispose() {
    _voz.parar();
    super.dispose();
  }

  Future<void> _traduzir() async {
    setState(() => _fase = _Fase.traduzindo);
    try {
      final r = await widget.tradutor.traduzir([widget.palavra.toLowerCase()]);
      if (!mounted) return;
      setState(() {
        _traducao = r.isEmpty ? '' : r.first.trim();
        _fase = _traducao.isEmpty ? _Fase.falhou : _Fase.ok;
        _erro = 'Não achei uma tradução para esta palavra.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fase = _Fase.falhou;
        _erro = e is TraducaoFalhou ? e.mensagem : 'Não consegui traduzir agora.';
      });
    }
  }

  /// A palavra que o cartão dessa frase já guarda (se houver) — guardar outra TROCA a palavra do cartão.
  String get _jaGuardada => LeituraPage.guardadas(context.read<CursoBloc>().state)[widget.frase.en.toLowerCase()] ?? '';

  Future<void> _guardar(CartaoEscrito c) async {
    if (_guardando) return;
    setState(() => _guardando = true);
    await salvarCartaoDoCenario(context, c);
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _guardado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.frase;
    final palavra = widget.palavra;
    final cartao = cartaoDeLacuna(f, palavra, traducaoDaPalavra: _fase == _Fase.ok ? _traducao : '');
    final ja = _jaGuardada;
    final mesma = ja == palavra.toLowerCase();
    final base = Mixart.display(size: 19, weight: FontWeight.w500, color: Mixart.text).copyWith(height: 1.5);
    return SingleChildScrollView(
      key: const Key('folha-palavra'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(palavra, key: const Key('palavra-tocada'), style: Mixart.display(size: 26, color: Mixart.brand))),
          IconButton(
            tooltip: 'Ouvir a palavra',
            onPressed: () => unawaited(_voz.falar(palavra)),
            icon: Icon(Icons.volume_up_rounded, color: Mixart.brand, size: 22),
          ),
        ]),
        const SizedBox(height: 4),
        // a tradução da palavra isolada: útil, mas pode mudar de sentido conforme a frase
        if (_fase == _Fase.traduzindo)
          Row(children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Mixart.brand)),
            const SizedBox(width: 8),
            Text('Traduzindo…', style: Mixart.ui(size: 13, color: Mixart.textMuted)),
          ])
        else if (_fase == _Fase.ok)
          Text(_traducao, key: const Key('traducao-palavra'), style: Mixart.ui(size: 17, weight: FontWeight.w700, color: Mixart.text))
        else
          Text(_erro, key: const Key('traducao-falhou'), style: Mixart.ui(size: 13, color: Mixart.textMuted)),
        const SizedBox(height: 4),
        Text('Uma palavra sozinha pode mudar de sentido: confira na frase abaixo.',
            key: const Key('aviso-sentido'), style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Mixart.surfaceHi,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('A FRASE', style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text.rich(key: const Key('frase-da-folha'), TextSpan(style: base, children: _comDestaque(f.en, palavra))),
            if (f.pt.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(f.pt, key: const Key('traducao-da-frase'), style: Mixart.ui(size: 14, color: Mixart.textMuted).copyWith(height: 1.45)),
            ],
            IconButton(
              tooltip: 'Ouvir a frase',
              onPressed: () => unawaited(_voz.falar(f.en)),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
              icon: Icon(Icons.volume_up_rounded, color: Mixart.textMuted, size: 20),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        if (cartao == null)
          Text(f.pt.trim().isEmpty
                  ? 'Esta frase não tem tradução, então não dá para guardar o cartão (a tradução é a pista dele).'
                  : 'Não consegui marcar esta palavra na frase.',
              key: const Key('sem-cartao'), style: Mixart.ui(size: 12.5, color: Mixart.textMuted))
        else ...[
          FilledButton(
            key: const Key('guardar-lacuna'),
            onPressed: _guardado || _guardando || mesma ? null : () => _guardar(cartao),
            style: FilledButton.styleFrom(
              backgroundColor: Mixart.brand,
              foregroundColor: Mixart.onBrand,
              disabledBackgroundColor: Mixart.surfaceHi,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Text(
              _guardado || mesma
                  ? '✓ Cartão guardado em "Meus cartões"'
                  : _guardando
                      ? 'Guardando…'
                      : ja.isNotEmpty
                          ? 'Trocar a palavra do cartão ("$ja" → "${cartao.alvo}")'
                          : 'Guardar cartão de lacuna',
              style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: _guardado || mesma ? Mixart.brand : Mixart.onBrand),
            ),
          ),
          const SizedBox(height: 8),
          Text('O cartão mostra a tradução da frase e esconde só "${cartao.alvo}" no inglês.',
              style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
        ],
      ]),
    );
  }

  /// A frase com [palavra] (todas as vezes que aparece) destacada.
  List<InlineSpan> _comDestaque(String frase, String palavra) {
    final alvo = palavra.toLowerCase();
    return [
      for (final p in partirFrase(frase))
        TextSpan(
          text: p.texto,
          style: p.palavra && p.texto.toLowerCase() == alvo
              ? TextStyle(color: Mixart.brand, fontWeight: FontWeight.w800, backgroundColor: Mixart.brandSub)
              : null,
        ),
    ];
  }
}
