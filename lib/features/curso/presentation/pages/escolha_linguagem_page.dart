import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/brand/logo_pacdart.dart';
import '../../../../core/linguagem/linguagem.dart';
import '../../../../core/linguagem/linguagem_cubit.dart';
import '../../../../core/theme/mixart.dart';

/// Tela de entrada: escolher o curso (PAC·DART, PAC·C# ou PAC·ENGLISH). Aparece na
/// primeira vez e sempre que a pessoa toca em "trocar" no topo.
class EscolhaLinguagemPage extends StatelessWidget {
  /// Aberta por cima do curso (botão ⇄ do topo): tem "voltar", e escolher a
  /// MESMA linguagem só fecha a tela, sem mexer na sessão.
  final bool podeVoltar;

  const EscolhaLinguagemPage({super.key, this.podeVoltar = false});

  static const _descricoes = {
    Linguagem.dart: [
      'Dart do zero e apps Flutter com prévia ao vivo',
      'Estado, navegação, animações, Firebase e pacotes',
      'Arcade com corrida 3D, quiz e Teste Master',
    ],
    Linguagem.csharp: [
      'C# do iniciante ao sênior, com teoria em cada lição',
      '.NET de verdade: ASP.NET Core, EF Core, testes e nuvem',
      'Arquitetura: SOLID, padrões, Clean Architecture, DDD e CQRS',
      'Jogos com C#: lógica de jogo, Unity, Godot e MonoGame',
      'Desafios de lógica além da digitação',
    ],
    Linguagem.ingles: [
      'Inglês do zero ao avançado, frase a frase',
      'A tradução fica em cima e você digita em inglês: cada frase volta 5 vezes, com cada vez menos ajuda, até sair de memória',
      'Áudio em inglês americano, revisão espaçada nos dias seguintes e teste para pular o que já sabe',
    ],
  };

  static final _teclas = {
    LogicalKeyboardKey.digit1: 0,
    LogicalKeyboardKey.digit2: 1,
    LogicalKeyboardKey.digit3: 2,
  };

  void _escolher(BuildContext context, Linguagem l) {
    final cubit = context.read<LinguagemCubit>();
    if (podeVoltar && cubit.state.escolhida == l) {
      Navigator.of(context).pop();
      return;
    }
    // linguagem nova: o app recria o curso inteiro (e esta rota some junto)
    cubit.escolher(l);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          final i = _teclas[e.logicalKey];
          if (i != null && i < Linguagem.values.length) {
            _escolher(context, Linguagem.values[i]);
            return KeyEventResult.handled;
          }
          if (podeVoltar && e.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(children: [
                if (podeVoltar)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Voltar (Esc)',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
                      style: IconButton.styleFrom(
                          backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
                    ),
                  ),
                const LogoPacDart(tamanho: 84),
                const SizedBox(height: 16),
                Text('Escolha sua trilha', style: Mixart.display(size: 30), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Cada curso tem o próprio currículo e o próprio progresso. '
                  'Dá para trocar quando quiser tocando no nome do curso, no topo.',
                  textAlign: TextAlign.center,
                  style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.5),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, caixa) => Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final (i, l) in Linguagem.values.indexed)
                        _CartaoLinguagem(
                          linguagem: l,
                          largura: caixa.maxWidth < 380 ? caixa.maxWidth : 380,
                          atalho: '${i + 1}',
                          novo: l == Linguagem.ingles,
                          atual: podeVoltar && LinguagemCubit.de(context) == l,
                          destaques: _descricoes[l] ?? const [],
                          onTap: () => _escolher(context, l),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text('Atalho: tecla 1, 2 ou 3',
                    style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Números do currículo de uma vertente (lidos do asset).
class _Numeros {
  final int trilhas, licoes, exercicios, desafios;
  const _Numeros(this.trilhas, this.licoes, this.exercicios, this.desafios);
}

Future<_Numeros?> _contar(Linguagem l) async {
  try {
    final lista = jsonDecode(await rootBundle.loadString(l.curriculo)) as List;
    var licoes = 0, ex = 0, desafios = 0;
    for (final t in lista) {
      final m = t as Map<String, dynamic>;
      final ls = (m['licoes'] ?? const []) as List;
      licoes += ls.length;
      for (final li in ls) {
        ex += (((li as Map)['trechos'] ?? const []) as List).length;
      }
      desafios += ((m['desafios'] ?? const []) as List).length;
    }
    return _Numeros(lista.length, licoes, ex, desafios);
  } catch (_) {
    return null;
  }
}

String _milhar(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

class _CartaoLinguagem extends StatefulWidget {
  final Linguagem linguagem;
  final double largura;
  final String atalho;
  final bool novo;
  final bool atual;
  final List<String> destaques;
  final VoidCallback onTap;
  const _CartaoLinguagem({
    required this.linguagem,
    required this.largura,
    required this.atalho,
    required this.novo,
    this.atual = false,
    required this.destaques,
    required this.onTap,
  });

  @override
  State<_CartaoLinguagem> createState() => _CartaoLinguagemState();
}

class _CartaoLinguagemState extends State<_CartaoLinguagem> {
  late final Future<_Numeros?> _numeros = _contar(widget.linguagem);
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.linguagem;
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() => _sobre = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: widget.largura,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Mixart.brand.withValues(alpha: _sobre ? .20 : .10),
                Mixart.surface,
              ],
            ),
            border: Border.all(color: _sobre ? Mixart.brand : Mixart.border, width: _sobre ? 1.6 : 1),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 18), spreadRadius: -24)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // o nome encolhe antes de empurrar os selos para fora do cartão
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(style: Mixart.display(size: 28), children: [
                      const TextSpan(text: 'PAC'),
                      TextSpan(text: '·', style: TextStyle(color: Mixart.brand)),
                      TextSpan(text: l.marca),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.atual)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: Mixart.brand),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('ESTUDANDO', style: Mixart.ui(size: 10, weight: FontWeight.w800, color: Mixart.brand)),
                ),
              if (widget.novo && !widget.atual)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: Mixart.brand, borderRadius: BorderRadius.circular(999)),
                  child: Text('NOVO', style: Mixart.ui(size: 10, weight: FontWeight.w800, color: Mixart.onBrand)),
                ),
              const SizedBox(width: 8),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Mixart.surfaceHi,
                  border: Border.all(color: Mixart.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(widget.atalho, style: Mixart.mono(size: 12, color: Mixart.textMuted)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(l.subtitulo,
                style: Mixart.ui(size: 11, weight: FontWeight.w700, color: Mixart.brand).copyWith(letterSpacing: 2)),
            const SizedBox(height: 14),
            for (final d in widget.destaques)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle, size: 15, color: Mixart.brand),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(d, style: Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.4)),
                  ),
                ]),
              ),
            const SizedBox(height: 8),
            FutureBuilder<_Numeros?>(
              future: _numeros,
              builder: (context, snap) {
                final n = snap.data;
                if (n == null) return const SizedBox(height: 18);
                String conta(int q, String um, String varios) => '${_milhar(q)} ${q == 1 ? um : varios}';
                final partes = [
                  conta(n.trilhas, 'trilha', 'trilhas'),
                  conta(n.licoes, 'lição', 'lições'),
                  l.ehProgramacao
                      ? conta(n.exercicios, 'exercício', 'exercícios')
                      : conta(n.exercicios, 'frase', 'frases'),
                  if (n.desafios > 0) conta(n.desafios, 'desafio', 'desafios'),
                ];
                return Text(partes.join(' · '),
                    style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.textMuted));
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Mixart.brand,
                  foregroundColor: Mixart.onBrand,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: widget.onTap,
                child: Text(widget.atual ? 'Continuar em ${l.nomeCurso}' : 'Estudar ${l.nomeCurso}',
                    style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.onBrand)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
