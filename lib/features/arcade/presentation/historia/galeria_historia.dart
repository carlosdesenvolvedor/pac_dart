import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../../ingles/data/voz_ingles.dart';
import '../../domain/historia_turismo.dart';
import '../../domain/turismo.dart';
import '../widgets/ambiente_turismo.dart';
import 'player_historia.dart';

/// O emoji do mundo da pista [n] do English Turismo (o mesmo do campeonato).
String emojiDoCapitulo(int n) {
  if (n < 1 || n > pistasGtIngles.length) return '📖';
  return AmbienteTurismo.de(pistasGtIngles[n - 1].tema).emoji;
}

/// 📖 A galeria da história: os 30 capítulos, travados até a pista chegar; "▶ Abertura", "▶ Chegada" e
/// "📜 Resumo até aqui". Tudo estático (nenhuma animação contínua).
class GaleriaHistoriaPage extends StatefulWidget {
  const GaleriaHistoriaPage({
    super.key,
    required this.historia,
    required this.pistaMax,
    required this.chegadas,
    this.voz,
  });

  final HistoriaTurismo historia;
  final int pistaMax;

  /// Pistas cuja chegada já foi liberada (a corrida terminou).
  final Set<int> chegadas;
  final VozIngles? voz;

  @override
  State<GaleriaHistoriaPage> createState() => _GaleriaHistoriaPageState();
}

class _GaleriaHistoriaPageState extends State<GaleriaHistoriaPage> {
  /// Uma voz para a galeria inteira (o player de cada capítulo usa esta, se não vier uma de fora).
  late final VozIngles _voz = widget.voz ?? VozIngles();
  bool _abrindo = false;

  @override
  void dispose() {
    if (widget.voz == null) _voz.parar();
    super.dispose();
  }

  Future<void> _abrir(CapituloHistoria c, ParteDoCapitulo parte) async {
    if (_abrindo) return;
    _abrindo = true;
    try {
      await abrirCenaDaHistoria(
        context,
        capitulo: c,
        parte: parte,
        voz: _voz,
        creditos: parte == ParteDoCapitulo.fim && c.pista == widget.historia.capitulos.last.pista && c.gancho == null,
      );
    } finally {
      _abrindo = false;
    }
  }

  void _resumo() {
    final liberados = widget.historia.capitulos.where((c) => c.pista <= widget.pistaMax).toList();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _ResumoPage(capitulos: liberados, chegadas: widget.chegadas),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final caps = widget.historia.capitulos;
    return Scaffold(
      backgroundColor: Mixart.bg,
      appBar: AppBar(
        backgroundColor: Mixart.surface,
        foregroundColor: Mixart.text,
        title: Text(
          '📖 ${widget.historia.titulo.en}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Mixart.ui(size: 16, weight: FontWeight.w800, color: Mixart.text),
        ),
      ),
      body: LayoutBuilder(builder: (context, c) {
        final largura = c.maxWidth;
        final colunas = largura >= 1200 ? 3 : (largura >= 760 ? 2 : 1);
        final w = (largura - 16 * 2 - 12 * (colunas - 1)) / colunas;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.historia.titulo.pt,
                  style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(fontStyle: FontStyle.italic)),
              const SizedBox(height: 4),
              Text('${caps.where((c) => c.pista <= widget.pistaMax).length} de ${caps.length} capítulos liberados',
                  style: Mixart.ui(size: 12, color: Mixart.textFaint)),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('galeria-resumo'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Mixart.brandDim),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
                ),
                onPressed: _resumo,
                child: Text('📜 Resumo até aqui', style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [for (final cap in caps) SizedBox(width: w, child: _cartao(cap))],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _cartao(CapituloHistoria c) {
    final travado = c.pista > widget.pistaMax;
    final chegada = widget.chegadas.contains(c.pista);
    return DecoratedBox(
      key: Key('galeria-capitulo-${c.pista}'),
      decoration: BoxDecoration(
        color: travado ? Mixart.bg : Mixart.surface,
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        border: Border.all(color: travado ? Mixart.border : Mixart.brandDim),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(travado ? '🔒' : emojiDoCapitulo(c.pista), style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chapter ${c.pista} · ${c.nivel.json}',
                          style: Mixart.ui(size: 11, weight: FontWeight.w700, color: Mixart.textFaint)),
                      Text(c.titulo.en,
                          style: Mixart.ui(
                              size: 16, weight: FontWeight.w800, color: travado ? Mixart.textFaint : Mixart.text)),
                      Text(c.titulo.pt,
                          style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (travado)
              Text('🔒 chegue à pista ${c.pista}', style: Mixart.ui(size: 13, color: Mixart.textFaint))
            else ...[
              Text(c.resumo, style: Mixart.ui(size: 13, color: Mixart.textMuted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _botao('galeria-abertura-${c.pista}', '▶ Abertura', () => _abrir(c, ParteDoCapitulo.intro)),
                  if (chegada)
                    _botao('galeria-chegada-${c.pista}', '▶ Chegada', () => _abrir(c, ParteDoCapitulo.fim)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _botao(String chave, String texto, VoidCallback onTap) => OutlinedButton(
        key: Key(chave),
        style: OutlinedButton.styleFrom(
          foregroundColor: Mixart.brand,
          side: BorderSide(color: Mixart.brandDim),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
        ),
        onPressed: onTap,
        child: Text(texto, style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)),
      );
}

/// 📜 "Resumo até aqui": o resumo e o gancho de cada capítulo liberado.
class _ResumoPage extends StatelessWidget {
  const _ResumoPage({required this.capitulos, required this.chegadas});

  final List<CapituloHistoria> capitulos;
  final Set<int> chegadas;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Mixart.bg,
        appBar: AppBar(
          backgroundColor: Mixart.surface,
          foregroundColor: Mixart.text,
          title: Text('📜 Resumo até aqui', style: Mixart.ui(size: 16, weight: FontWeight.w800, color: Mixart.text)),
        ),
        body: ListaResumo(capitulos: capitulos, chegadas: chegadas),
      );
}

/// A lista do "Resumo até aqui" (usada na galeria e no aviso de capítulos perdidos).
class ListaResumo extends StatelessWidget {
  const ListaResumo({super.key, required this.capitulos, this.chegadas, this.encolher = false});

  final List<CapituloHistoria> capitulos;

  /// Mostra o gancho só dos capítulos com chegada liberada (null = de todos).
  final Set<int>? chegadas;
  final bool encolher;

  @override
  Widget build(BuildContext context) => ListView.separated(
        key: const Key('historia-resumo'),
        shrinkWrap: encolher,
        padding: const EdgeInsets.all(16),
        itemCount: capitulos.length,
        separatorBuilder: (_, _) => Divider(color: Mixart.border, height: 20),
        itemBuilder: (context, i) {
          final c = capitulos[i];
          final gancho = c.gancho;
          final mostraGancho = gancho != null && (chegadas == null || chegadas!.contains(c.pista));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${emojiDoCapitulo(c.pista)} ${c.pista}. ${c.titulo.en}',
                  style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.text)),
              const SizedBox(height: 2),
              Text(c.resumo, style: Mixart.ui(size: 13, color: Mixart.textMuted)),
              if (mostraGancho)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('➜ ${gancho.pt}',
                      style: Mixart.ui(size: 12, color: Mixart.textFaint).copyWith(fontStyle: FontStyle.italic)),
                ),
            ],
          );
        },
      );
}

/// O que fazer ao correr uma pista sem ter visto os capítulos anteriores.
enum EscolhaPerdidos { doComeco, resumo, seguir }

/// Pergunta ao aluno se quer ver os capítulos perdidos, ler o resumo (1..[ate]) ou seguir.
/// [perdidos] = os capítulos que ele ainda não viu (o texto cita só esses); null = todos de 1 a [ate].
/// "📜 Ler o resumo" mostra os resumos ali mesmo e devolve [EscolhaPerdidos.resumo] ao fechar.
/// Fechar o diálogo por fora → null.
Future<EscolhaPerdidos?> abrirCapitulosPerdidos(BuildContext context,
    {required HistoriaTurismo historia, required int ate, List<int>? perdidos}) {
  final caps = historia.capitulos.where((c) => c.pista <= ate).toList();
  return showDialog<EscolhaPerdidos>(
    context: context,
    builder: (_) => _DialogoPerdidos(capitulos: caps, ate: ate, perdidos: perdidos),
  );
}

/// "o capítulo 10" · "os capítulos 1 a 10" · "os capítulos 4, 7 e 10" · "os capítulos 1 a 3 e 7" — as
/// sequências seguidas viram "a".
String textoCapitulosPerdidos(List<int> perdidos) {
  final ns = perdidos.toSet().toList()..sort();
  if (ns.isEmpty) return 'nenhum capítulo';
  if (ns.length == 1) return 'o capítulo ${ns.first}';
  final partes = <String>[];
  var i = 0;
  while (i < ns.length) {
    var j = i;
    while (j + 1 < ns.length && ns[j + 1] == ns[j] + 1) {
      j++;
    }
    if (j - i >= 2) {
      partes.add('${ns[i]} a ${ns[j]}');
    } else {
      for (var k = i; k <= j; k++) {
        partes.add('${ns[k]}');
      }
    }
    i = j + 1;
  }
  final lista = partes.length == 1
      ? partes.first
      : '${partes.sublist(0, partes.length - 1).join(', ')} e ${partes.last}';
  return 'os capítulos $lista';
}

class _DialogoPerdidos extends StatefulWidget {
  const _DialogoPerdidos({required this.capitulos, required this.ate, this.perdidos});

  final List<CapituloHistoria> capitulos;
  final int ate;
  final List<int>? perdidos;

  @override
  State<_DialogoPerdidos> createState() => _DialogoPerdidosState();
}

class _DialogoPerdidosState extends State<_DialogoPerdidos> {
  bool _lendo = false;

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.sizeOf(context).height;
    return AlertDialog(
      backgroundColor: Mixart.surface,
      title: Text(_lendo ? '📜 Resumo até aqui' : '📖 Capítulos perdidos',
          style: Mixart.ui(size: 17, weight: FontWeight.w800, color: Mixart.text)),
      content: _lendo
          ? SizedBox(
              width: 520,
              height: (altura * .5).clamp(160.0, 520.0),
              child: ListaResumo(capitulos: widget.capitulos),
            )
          : SingleChildScrollView(
              child: Text(
                'A história começa no capítulo 1 e você ainda não viu '
                '${textoCapitulosPerdidos(widget.perdidos ?? [for (var k = 1; k <= widget.ate; k++) k])}. '
                'Quer ver do começo, ler um resumo ou seguir para a corrida?',
                style: Mixart.ui(size: 14, color: Mixart.textMuted),
              ),
            ),
      actions: _lendo
          ? [
              FilledButton(
                key: const Key('perdidos-resumo-ok'),
                onPressed: () => Navigator.of(context).pop(EscolhaPerdidos.resumo),
                child: const Text('Seguir para a corrida ▶'),
              ),
            ]
          : [
              TextButton(
                key: const Key('perdidos-seguir'),
                onPressed: () => Navigator.of(context).pop(EscolhaPerdidos.seguir),
                child: Text('Seguir ▶', style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.textMuted)),
              ),
              TextButton(
                key: const Key('perdidos-resumo'),
                onPressed: () => setState(() => _lendo = true),
                child: Text('📜 Ler o resumo', style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.brand)),
              ),
              FilledButton(
                key: const Key('perdidos-comeco'),
                style: FilledButton.styleFrom(backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
                onPressed: () => Navigator.of(context).pop(EscolhaPerdidos.doComeco),
                child: Text('▶ Ver do começo', style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.onBrand)),
              ),
            ],
    );
  }
}
