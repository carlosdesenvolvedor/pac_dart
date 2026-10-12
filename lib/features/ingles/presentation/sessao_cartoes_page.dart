import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/domain/curriculo.dart';
import '../data/voz_ingles.dart';
import '../domain/comparar_resposta.dart';
import '../domain/srs.dart';
import 'widgets/cena_visual.dart';

/// A nota que a pessoa deu a uma frase (a 1ª vez que ela apareceu na sessão).
class ResultadoCartao {
  final Trecho frase;
  final Rating nota;
  const ResultadoCartao(this.frase, this.nota);
}

/// O cartão do Anki: inglês na FRENTE, tradução no VERSO. A pessoa lê/ouve o
/// inglês e RESPONDE ESCREVENDO a tradução (ou só lembra e vira, com a chave
/// desligada): a resposta é conferida palavra por palavra e sugere uma nota. Avalia
/// com 4 botões — Errei, Difícil, Bom, Fácil — cada um com o tempo até o cartão voltar.
/// Só a 1ª nota de cada frase vale para o agendador; a que sai "Errei" volta
/// ainda nesta sessão (sem contar de novo) até ser lembrada.
/// Celular (Android/iOS): muda só as dicas de uso (sem tecla de atalho).
bool get _ehCelular => defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

class SessaoCartoesPage extends StatefulWidget {
  final String titulo, subtitulo, emoji;

  /// As frases (a ordem é a da sessão).
  final List<Trecho> itens;

  /// Chaves (a da frase) dos cartões que a pessoa vê pela PRIMEIRA vez: ganham a
  /// etiqueta "NOVO" e a previsão dos botões parte de um cartão novo.
  final Set<String> novas;

  /// Chave da frase → chave do cartão (para saber se é nova). O `RevisaoCubit` dá.
  final String Function(Trecho frase) chaveDe;

  /// Em quantos dias a frase volta com cada nota (os textos dos botões).
  final Map<Rating, int> Function(Trecho frase) previsao;

  /// A 1ª nota de cada frase.
  final FutureOr<void> Function(Trecho frase, Rating nota) onNota;
  final void Function(List<ResultadoCartao> resultados)? onFim;

  /// Veio emendada em outra sequência: sair devolve false, terminar true.
  final bool emSequencia;

  /// A lição de onde veio cada frase (a cena ajuda a lembrar).
  final Licao? Function(Trecho frase)? cenaDe;

  /// Botão a mais ao lado do 🔊 (o áudio do aluno).
  final Widget Function(BuildContext context, Trecho frase)? acaoExtra;

  final VozIngles? voz;

  /// Pref: responder ESCREVENDO a tradução (padrão ligado).
  static const prefEscrita = 'en_cartao_escrita';

  const SessaoCartoesPage({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.emoji = '🔄',
    required this.itens,
    required this.chaveDe,
    required this.previsao,
    required this.onNota,
    this.novas = const {},
    this.onFim,
    this.emSequencia = false,
    this.cenaDe,
    this.acaoExtra,
    this.voz,
  });

  @override
  State<SessaoCartoesPage> createState() => _SessaoCartoesPageState();
}

class _Item {
  final Trecho frase;

  /// Voltou na sessão depois de "Errei": não conta de novo para o agendador.
  final bool repeticao;
  const _Item(this.frase, {this.repeticao = false});
}

class _SessaoCartoesPageState extends State<SessaoCartoesPage> {
  /// Quantas voltas uma frase errada pode ter na sessão.
  static const _maxVoltas = 2;

  /// Pref do palco: tocar o áudio sozinho.
  static const _prefAudio = 'en_audio_auto';

  late final VozIngles _voz = widget.voz ?? VozIngles();
  final _foco = FocusNode(debugLabel: 'cartões');
  late final List<_Item> _fila = [for (final f in widget.itens) _Item(f)];
  final List<ResultadoCartao> _resultados = [];
  final Map<String, int> _voltas = {};
  int _i = 0;
  bool _virado = false;
  bool _fim = false;
  bool _audioAuto = true;

  /// Responder escrevendo: o campo, o que foi conferido e a nota que combina.
  bool _escrita = true;
  final _resposta = TextEditingController();
  final _focoCampo = FocusNode(debugLabel: 'resposta escrita');
  ComparacaoResposta? _comparacao;
  Rating? _sugerida;

  _Item get _item => _fila[_i];

  @override
  void initState() {
    super.initState();
    if (_fila.isEmpty) {
      _fim = true;
    } else {
      _comecar();
    }
  }

  Future<void> _comecar() async {
    try {
      final p = await SharedPreferences.getInstance();
      _audioAuto = p.getBool(_prefAudio) ?? true;
      _escrita = p.getBool(SessaoCartoesPage.prefEscrita) ?? true;
    } catch (_) {}
    if (!mounted) return;
    setState(() {});
    _falarSeAuto();
    _focarCampo();
  }

  @override
  void dispose() {
    _voz.parar();
    _foco.dispose();
    _focoCampo.dispose();
    _resposta.dispose();
    super.dispose();
  }

  /// O cursor vai para o campo de escrita (quando ele é o modo e ainda não virou).
  void _focarCampo() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _escrita && !_virado && !_fim) _focoCampo.requestFocus();
      });

  Future<void> _alternarEscrita(bool ligado) async {
    setState(() => _escrita = ligado);
    if (ligado) {
      _focarCampo();
    } else {
      _foco.requestFocus();
    }
    try {
      (await SharedPreferences.getInstance()).setBool(SessaoCartoesPage.prefEscrita, ligado);
    } catch (_) {}
  }

  void _falarSeAuto() {
    if (_audioAuto && !_fim && _voz.somLiberado) unawaited(_voz.falar(_item.frase.cod));
  }

  /// Vira sem resposta escrita: "Mostrar resposta", ou "Não sei" no modo de escrita
  /// (que já sugere "Errei").
  void _virar() {
    if (_virado || _fim) return;
    setState(() {
      _virado = true;
      _comparacao = null;
      _sugerida = _escrita ? Rating.again : null;
    });
    _foco.requestFocus();
  }

  /// Confere o que a pessoa escreveu com a tradução do cartão e sugere a nota.
  void _conferir() {
    if (_virado || _fim) return;
    final texto = _resposta.text.trim();
    if (texto.isEmpty) return _virar();
    final c = compararResposta(_item.frase.dicaPlana, texto);
    setState(() {
      _virado = true;
      _comparacao = c;
      _sugerida = c.sugerida;
    });
    _foco.requestFocus();
  }

  Future<void> _nota(Rating nota) async {
    if (!_virado || _fim) return;
    final item = _item;
    final k = widget.chaveDe(item.frase);
    if (!item.repeticao) {
      _resultados.add(ResultadoCartao(item.frase, nota));
      try {
        await widget.onNota(item.frase, nota);
      } catch (_) {}
      if (!mounted) return;
    }
    if (nota == Rating.again) {
      final voltas = _voltas[k] ?? 0;
      if (voltas < _maxVoltas) {
        _voltas[k] = voltas + 1;
        // volta daqui a umas frases (ou no fim, se a sessão for curta)
        _fila.insert((_i + 1 + 4).clamp(_i + 1, _fila.length), _Item(item.frase, repeticao: true));
      }
    }
    _proximo();
  }

  void _proximo() {
    if (_i < _fila.length - 1) {
      setState(() {
        _i++;
        _virado = false;
        _comparacao = null;
        _sugerida = null;
        _resposta.clear();
      });
      _falarSeAuto();
      _focarCampo();
      return;
    }
    _voz.parar();
    setState(() => _fim = true);
    widget.onFim?.call(List.unmodifiable(_resultados));
  }

  void _sair({required bool seguir}) => Navigator.of(context).pop(seguir);

  KeyEventResult _tecla(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (_fim) {
      if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter || k == LogicalKeyboardKey.space) {
        _sair(seguir: true);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    // escrevendo a resposta: as teclas são do campo (Enter confere pelo próprio campo)
    if (_escrita && !_virado) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _virado ? _nota(_sugerida ?? Rating.good) : _virar();
      return KeyEventResult.handled;
    }
    if (_virado) {
      final nota = switch (k) {
        LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1 => Rating.again,
        LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2 => _item.repeticao ? null : Rating.hard,
        LogicalKeyboardKey.digit3 || LogicalKeyboardKey.numpad3 => Rating.good,
        LogicalKeyboardKey.digit4 || LogicalKeyboardKey.numpad4 => _item.repeticao ? null : Rating.easy,
        _ => null,
      };
      if (nota != null) {
        _nota(nota);
        return KeyEventResult.handled;
      }
    }
    if (k == LogicalKeyboardKey.keyR) {
      unawaited(_voz.falar(_item.frase.cod));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Focus(
          focusNode: _foco,
          autofocus: true,
          onKeyEvent: _tecla,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
                _topo(),
                const SizedBox(height: 16),
                if (_fim) _resumo() else _cartao(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topo() => Row(children: [
        IconButton(
          tooltip: widget.emSequencia ? 'Sair da sequência' : 'Voltar',
          onPressed: () => _sair(seguir: false),
          icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
          style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
        ),
        const SizedBox(width: 12),
        Text(widget.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.titulo, style: Mixart.display(size: 20), overflow: TextOverflow.ellipsis),
            Text(widget.subtitulo, style: Mixart.ui(size: 12, color: Mixart.textMuted), overflow: TextOverflow.ellipsis),
          ]),
        ),
        if (!_fim)
          Text('${_i + 1} / ${_fila.length}', style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textMuted)),
      ]);

  Widget _etiqueta(String t, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: .12),
          border: Border.all(color: cor.withValues(alpha: .55)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(t, style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: cor).copyWith(letterSpacing: 1)),
      );

  Widget _ouvir(Trecho f) => Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          key: const Key('ouvir-cartao'),
          tooltip: 'Ouvir (R)',
          onPressed: () => unawaited(_voz.falar(f.cod, lenta: false)),
          icon: Icon(Icons.volume_up_rounded, color: Mixart.brand, size: 22),
        ),
        IconButton(
          tooltip: 'Ouvir devagar',
          onPressed: () => unawaited(_voz.falar(f.cod, lenta: true)),
          icon: Icon(Icons.slow_motion_video_rounded, color: Mixart.textMuted, size: 21),
        ),
        if (widget.acaoExtra != null) widget.acaoExtra!(context, f),
      ]);

  Widget _cartao() {
    final item = _item;
    final f = item.frase;
    final k = widget.chaveDe(f);
    final nova = widget.novas.contains(k) && !item.repeticao;
    final prev = widget.previsao(f);
    final licao = widget.cenaDe?.call(f);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: _i / _fila.length,
          minHeight: 6,
          backgroundColor: Mixart.surfaceHi,
          color: Mixart.brand,
        ),
      ),
      const SizedBox(height: 14),
      Row(children: [
        _etiqueta(item.repeticao ? 'DE NOVO' : (nova ? 'NOVO' : 'REVISÃO'),
            item.repeticao ? Mixart.danger : (nova ? Mixart.brand : Mixart.textMuted)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.repeticao
                ? (_escrita ? 'Você errou: escreva de novo ou vire e confira' : 'Você errou: vire e confira o sentido')
                : (_escrita ? 'Leia o inglês e escreva a tradução em português' : 'Leia o inglês e tente lembrar o sentido'),
            style: Mixart.ui(size: 12, color: Mixart.textMuted),
          ),
        ),
      ]),
      Align(
        alignment: Alignment.centerRight,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('✍️ Responder escrevendo', style: Mixart.ui(size: 11.5, weight: FontWeight.w700, color: Mixart.textMuted)),
          Switch(
            key: const Key('alternar-escrita'),
            value: _escrita,
            onChanged: _alternarEscrita,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ]),
      ),
      if (licao != null && CenaVisual(licao: licao).temAlgo) ...[
        CenaVisual(licao: licao, compacta: true),
        const SizedBox(height: 10),
      ],
      Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: _virado ? Mixart.brandDim : Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('INGLÊS', style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
          const SizedBox(height: 6),
          Text(f.cod,
              key: const Key('frente-cartao'),
              style: Mixart.display(size: 27, weight: FontWeight.w700).copyWith(height: 1.3)),
          Align(alignment: Alignment.centerRight, child: _ouvir(f)),
          if (_virado) ...[
            Divider(color: Mixart.border, height: 22),
            if (_comparacao case final c?) ...[
              Text('SUA RESPOSTA', style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
              const SizedBox(height: 6),
              _comMarcas(c.digitada, key: const Key('sua-resposta'), tamanho: 19, cor: Mixart.text, certa: _verde, errada: Mixart.danger, sublinhaErro: false),
              const SizedBox(height: 14),
            ],
            Text('PORTUGUÊS', style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
            const SizedBox(height: 6),
            if (_comparacao case final c?)
              _comMarcas(c.esperada, key: const Key('verso-cartao'), tamanho: 24, cor: Mixart.brand, certa: Mixart.brand, errada: Mixart.danger, sublinhaErro: true)
            else
              Text(f.dicaPlana,
                  key: const Key('verso-cartao'),
                  style: Mixart.display(size: 24, weight: FontWeight.w600, color: Mixart.brand).copyWith(height: 1.3)),
            if (_comparacao case final c?) ...[
              const SizedBox(height: 10),
              Text(
                c.exata
                    ? 'Idêntica! ✅ ${c.acertadas} de ${c.totalEsperadas} palavras.'
                    : 'Você acertou ${c.acertadas} de ${c.totalEsperadas} palavras · sugestão: ${_nomeDaNota(c.sugerida)}',
                key: const Key('resumo-comparacao'),
                style: Mixart.ui(size: 12.5, weight: FontWeight.w800, color: Mixart.textMuted),
              ),
            ],
            if (f.literal.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('ao pé da letra: ${f.literal}', style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.45)),
            ],
            if (f.conceito.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('💡 ${f.conceito}', style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.45)),
            ],
          ],
        ]),
      ),
      const SizedBox(height: 16),
      if (!_virado && _escrita)
        _campoDeEscrita()
      else if (!_virado)
        Center(
          child: InkWell(
            key: const Key('mostrar-resposta'),
            canRequestFocus: false,
            onTap: _virar,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              constraints: const BoxConstraints(minWidth: 240, minHeight: 52),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              decoration: BoxDecoration(color: Mixart.brand, borderRadius: BorderRadius.circular(999)),
              child: Text('Mostrar resposta', style: Mixart.ui(size: 15, weight: FontWeight.w800, color: Mixart.onBrand)),
            ),
          ),
        )
      else
        _notas(prev, repeticao: item.repeticao),
      const SizedBox(height: 14),
      Text(
        !_virado && _escrita
            ? (_ehCelular ? 'Escreva a tradução e toque em Conferir' : 'Enter confere · "Não sei" mostra a resposta')
            : (_virado && _sugerida != null)
                ? (_ehCelular
                    ? 'Toque na nota que combina (a sugerida vem marcada)'
                    : 'Espaço aceita a sugestão · 1 Errei · 2 Difícil · 3 Bom · 4 Fácil')
                : (_ehCelular
                    ? 'Toque em "Mostrar resposta" e avalie o quanto você lembrou'
                    : 'Espaço vira · 1 Errei · 2 Difícil · 3 Bom (ou Espaço) · 4 Fácil · R ouve'),
        textAlign: TextAlign.center,
        style: Mixart.ui(size: 11.5, color: Mixart.textFaint),
      ),
    ]);
  }

  static const _verde = Color(0xFF4CD08A);

  static String _nomeDaNota(Rating n) => switch (n) {
        Rating.again => 'Errei',
        Rating.hard => 'Difícil',
        Rating.good => 'Bom',
        Rating.easy => 'Fácil',
      };

  /// O texto com as palavras coloridas: acertou ([certa]) ou não ([errada], sublinhada
  /// quando [sublinhaErro]); o espaço e a pontuação ficam na [cor] do texto.
  Widget _comMarcas(List<Segmento> segmentos,
      {required Key key, required double tamanho, required Color cor, required Color certa, required Color errada, required bool sublinhaErro}) {
    final base = Mixart.display(size: tamanho, weight: FontWeight.w600, color: cor).copyWith(height: 1.35);
    return Text.rich(
      key: key,
      TextSpan(children: [
        for (final s in segmentos)
          TextSpan(
            text: s.texto,
            style: s.acerto == null
                ? base
                : base.copyWith(
                    color: s.acerto! ? certa : errada,
                    decoration: !s.acerto! && sublinhaErro ? TextDecoration.underline : null,
                    decorationColor: errada,
                  ),
          ),
      ]),
    );
  }

  /// "Escreva a tradução": o campo e os botões Conferir / Não sei.
  Widget _campoDeEscrita() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          key: const Key('resposta-escrita'),
          controller: _resposta,
          focusNode: _focoCampo,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _conferir(),
          style: Mixart.ui(size: 16, color: Mixart.text),
          decoration: InputDecoration(
            hintText: 'Escreva aqui a tradução em português…',
            hintStyle: Mixart.ui(size: 14, color: Mixart.textFaint),
            filled: true,
            fillColor: Mixart.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.brand, width: 1.4)),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FilledButton(
            key: const Key('conferir-resposta'),
            onPressed: _conferir,
            style: FilledButton.styleFrom(
              backgroundColor: Mixart.brand,
              foregroundColor: Mixart.onBrand,
              minimumSize: const Size(160, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Text('Conferir', style: Mixart.ui(size: 15, weight: FontWeight.w800, color: Mixart.onBrand)),
          ),
          TextButton(
            key: const Key('nao-sei-cartao'),
            onPressed: _virar,
            child: Text('Não sei', style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.textMuted)),
          ),
        ]),
      ]);

  Widget _notas(Map<Rating, int> prev, {required bool repeticao}) {
    String intervalo(Rating n) => repeticao ? 'nesta sessão' : rotuloIntervalo(prev[n] ?? 1);
    final s = _sugerida;
    final botoes = repeticao
        ? [
            _BotaoNota(const Key('nota-errei'), '1 · Ainda não', 'volta de novo', Mixart.danger, () => _nota(Rating.again),
                sugerido: s == Rating.again),
            _BotaoNota(const Key('nota-bom'), '3 · Lembrei', 'segue', Mixart.brand, () => _nota(Rating.good),
                sugerido: s != null && s != Rating.again),
          ]
        : [
            _BotaoNota(const Key('nota-errei'), '1 · Errei', intervalo(Rating.again), Mixart.danger, () => _nota(Rating.again),
                sugerido: s == Rating.again),
            _BotaoNota(const Key('nota-dificil'), '2 · Difícil', intervalo(Rating.hard), const Color(0xFFE0A030), () => _nota(Rating.hard),
                sugerido: s == Rating.hard),
            _BotaoNota(const Key('nota-bom'), '3 · Bom', intervalo(Rating.good), Mixart.brand, () => _nota(Rating.good),
                sugerido: s == Rating.good),
            _BotaoNota(const Key('nota-facil'), '4 · Fácil', intervalo(Rating.easy), const Color(0xFF4FC3F7), () => _nota(Rating.easy),
                sugerido: s == Rating.easy),
          ];
    return LayoutBuilder(builder: (context, caixa) {
      final colunas = caixa.maxWidth < 420 && botoes.length > 2 ? 2 : botoes.length;
      final largura = (caixa.maxWidth - 10 * (colunas - 1)) / colunas;
      return Wrap(spacing: 10, runSpacing: 10, children: [for (final b in botoes) SizedBox(width: largura, child: b)]);
    });
  }

  Widget _resumo() {
    int n(Rating r) => _resultados.where((x) => x.nota == r).length;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(children: [
        Text(_resultados.isEmpty ? 'Nada para revisar agora 🎉' : 'Pronto!', style: Mixart.display(size: 26, color: Mixart.brand)),
        const SizedBox(height: 14),
        if (_resultados.isNotEmpty)
          Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
            _Placar('🔁 ERREI', '${n(Rating.again)}'),
            _Placar('🟡 DIFÍCIL', '${n(Rating.hard)}'),
            _Placar('✅ BOM', '${n(Rating.good)}'),
            _Placar('⚡ FÁCIL', '${n(Rating.easy)}'),
          ]),
        const SizedBox(height: 18),
        FilledButton(
          key: const Key('continuar-cartoes'),
          style: FilledButton.styleFrom(
            backgroundColor: Mixart.brand,
            foregroundColor: Mixart.onBrand,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          onPressed: () => _sair(seguir: true),
          child: Text('Continuar →', style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.onBrand)),
        ),
      ]),
    );
  }
}

class _BotaoNota extends StatelessWidget {
  final String rotulo, intervalo;
  final Color cor;
  final VoidCallback onTap;

  /// A nota que a conferência da resposta escrita sugere: borda grossa e fundo mais forte.
  final bool sugerido;
  const _BotaoNota(Key key, this.rotulo, this.intervalo, this.cor, this.onTap, {this.sugerido = false}) : super(key: key);

  @override
  Widget build(BuildContext context) => InkWell(
        canRequestFocus: false,
        onTap: onTap,
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: sugerido ? .24 : .10),
            border: Border.all(color: cor.withValues(alpha: sugerido ? 1 : .7), width: sugerido ? 2.4 : 1),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(rotulo, style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: cor)),
            const SizedBox(height: 2),
            Text(sugerido ? '$intervalo · sugerida' : intervalo, style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
          ]),
        ),
      );
}

class _Placar extends StatelessWidget {
  final String rotulo, valor;
  const _Placar(this.rotulo, this.valor);

  @override
  Widget build(BuildContext context) => Container(
        width: 118,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Mixart.surfaceHi,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(children: [
          Text(valor, style: Mixart.display(size: 24)),
          const SizedBox(height: 2),
          Text(rotulo, style: Mixart.ui(size: 10, weight: FontWeight.w800, color: Mixart.textMuted).copyWith(letterSpacing: .8)),
        ]),
      );
}
