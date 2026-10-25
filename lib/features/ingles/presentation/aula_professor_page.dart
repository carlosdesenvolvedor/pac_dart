import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/domain/curriculo.dart';
import '../data/aulas_repo.dart';
import '../data/voz_ingles.dart';
import '../data/vozes_aula.dart';
import '../domain/aula_professor.dart';
import '../domain/saida_audio.dart' show FimDaFala;
import 'widgets/elenco_ingles.dart';

/// Preferências da aula: abrir sozinha na 1ª visita de cada lição (padrão: sim) e as lições já vistas.
abstract final class PrefsAula {
  static const chaveAuto = 'en_aula_auto';
  static const chaveVistas = 'en_aulas_vistas';

  static Future<bool> autoLigada() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(chaveAuto) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> salvarAuto(bool ligada) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(chaveAuto, ligada);
    } catch (_) {}
  }

  static Future<bool> jaViu(String licaoId) async {
    try {
      return ((await SharedPreferences.getInstance()).getStringList(chaveVistas) ?? const []).contains(licaoId);
    } catch (_) {
      return false;
    }
  }

  static const chavePosicoes = 'en_aula_posicoes';

  /// Onde o aluno parou na aula da lição (índice da fala; 0 = do começo).
  static Future<int> posicao(String licaoId) async {
    try {
      final j = jsonDecode((await SharedPreferences.getInstance()).getString(chavePosicoes) ?? '{}');
      final v = j is Map ? j[licaoId] : null;
      return v is int ? v : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Guarda onde parou (0 = terminou ou voltou ao começo: apaga). As 60 aulas mais recentes.
  static Future<void> salvarPosicao(String licaoId, int i) async {
    try {
      final p = await SharedPreferences.getInstance();
      final j = jsonDecode(p.getString(chavePosicoes) ?? '{}');
      final m = <String, int>{
        if (j is Map)
          for (final e in j.entries)
            if (e.key is String && e.value is int && e.key != licaoId) e.key as String: e.value as int,
      };
      if (i > 0) m[licaoId] = i;
      while (m.length > 60) {
        m.remove(m.keys.first);
      }
      await p.setString(chavePosicoes, jsonEncode(m));
    } catch (_) {}
  }

  static Future<void> marcarVista(String licaoId) async {
    try {
      final p = await SharedPreferences.getInstance();
      final l = p.getStringList(chaveVistas) ?? <String>[];
      if (!l.contains(licaoId)) await p.setStringList(chaveVistas, [...l, licaoId]);
    } catch (_) {}
  }
}

/// Abre a 🎓 aula do professor da [licao] (se ela tem). [primeiraVez] = aberta sozinha no começo da lição (o
/// botão diz "Começar a lição" e aparece a chave "abrir sozinha"). Devolve false se a lição não tem aula.
Future<bool> abrirAulaProfessor(BuildContext context, Licao licao, {bool primeiraVez = false, VozIngles? voz}) async {
  final nav = Navigator.of(context);
  final aula = await AulasRepo.daLicao(licao.id);
  if (aula == null || !nav.mounted) return false;
  unawaited(PrefsAula.marcarVista(licao.id));
  await nav.push<void>(MaterialPageRoute<void>(
    builder: (_) => AulaProfessorPage(licao: licao, aula: aula, primeiraVez: primeiraVez, voz: voz),
  ));
  return true;
}

/// 🎓 A aula do professor (5 a 10 minutos, em partes): o Prof. Beto (rosto com a boca sincronizada) fala cada
/// trecho da aula em português e diz os exemplos em inglês; a lousa mostra o que está escrito (o quadro, ou o
/// exemplo com a tradução), a figura (a foto da cena ou emojis) e a legenda, o que ele está dizendo. Toca
/// sozinha, uma fala depois da outra, com o silêncio dos desafios ("sua vez"); ⏮ ⏯ ⏭, as partes (pular para
/// uma), 🐢 e "📜 Ler a aula" (o texto todo, tocar numa fala começa dali). Lembra onde o aluno parou.
/// Espaço = tocar/pausar, ← → = fala anterior/seguinte, Esc = sair.
class AulaProfessorPage extends StatefulWidget {
  final Licao licao;
  final AulaLicao aula;
  final bool primeiraVez;
  final VozIngles? voz;

  /// Começa a falar ao abrir (se o navegador já liberou o som).
  final bool tocarAoAbrir;

  const AulaProfessorPage({
    super.key,
    required this.licao,
    required this.aula,
    this.primeiraVez = false,
    this.voz,
    this.tocarAoAbrir = true,
  });

  @override
  State<AulaProfessorPage> createState() => _AulaProfessorPageState();
}

class _AulaProfessorPageState extends State<AulaProfessorPage> {
  late final VozIngles _voz = widget.voz ?? VozIngles();
  final _foco = FocusNode();
  int _i = 0;
  bool _tocando = false, _fim = false, _texto = false, _devagar = false, _comecou = false;
  bool? _auto;

  /// Voltou de onde tinha parado (mostra "↺ Do começo").
  bool _retomou = false;

  /// Segundos do desafio em curso ("sua vez"); 0 = nenhum.
  int _pensando = 0;

  /// O índice das vozes da trilha (no site); a aula começa sem esperar demais por ele.
  late final Future<bool> _vozes = VozesAula.carregar(_trilha);

  String get _trilha => trilhaDaLicao(widget.licao.id);

  /// Cada "tocar daqui" ganha um número: o laço antigo para quando outro começa (ou ao pausar).
  int _sessao = 0;

  List<FalaAula> get _falas => widget.aula.falas;

  /// A pausa entre as falas: um Timer que o [dispose] cancela (nada fica pendurado depois de sair).
  Timer? _respiro;
  Completer<void>? _fimRespiro;

  /// Corta a pausa em curso (o laço que a esperava acorda e vê que a sessão mudou).
  void _cortarRespiro() {
    _respiro?.cancel();
    if (_fimRespiro case final c? when !c.isCompleted) c.complete();
  }

  Future<void> _esperar(Duration d) {
    _cortarRespiro();
    final c = _fimRespiro = Completer<void>();
    _respiro = Timer(d, () {
      if (!c.isCompleted) c.complete();
    });
    return c.future;
  }

  @override
  void initState() {
    super.initState();
    if (widget.primeiraVez) PrefsAula.autoLigada().then((v) => mounted ? setState(() => _auto = v) : null);
    unawaited(_vozes);
    _abrir();
  }

  Future<void> _abrir() async {
    final pos = await PrefsAula.posicao(widget.licao.id);
    if (!mounted) return;
    if (pos > 0 && pos < _falas.length - 1) {
      setState(() {
        _i = pos;
        _retomou = true;
      });
    }
    if (widget.tocarAoAbrir && _voz.somLiberado) _tocarDaqui(_i);
  }

  @override
  void dispose() {
    if (_comecou) unawaited(PrefsAula.salvarPosicao(widget.licao.id, _fim ? 0 : _i));
    _sessao++;
    _cortarRespiro();
    _voz.parar();
    _foco.dispose();
    super.dispose();
  }

  Future<void> _tocarDaqui(int inicio) async {
    final s = ++_sessao;
    setState(() {
      _i = inicio.clamp(0, _falas.length - 1);
      _tocando = true;
      _fim = false;
      _comecou = true;
      _pensando = 0;
    });
    // as vozes vêm do site: espera um pouco por elas; sem rede, a voz do aparelho começa
    await _vozes.timeout(const Duration(seconds: 3), onTimeout: () => false);
    for (var k = _i; k < _falas.length; k++) {
      if (!mounted || s != _sessao) return;
      setState(() => _i = k);
      if (_secaoComeca(k)) unawaited(PrefsAula.salvarPosicao(widget.licao.id, k));
      final f = _falas[k];
      if (k + 1 < _falas.length) {
        VozIngles.preaquecerAula(_trilha, _falas[k + 1].texto, ingles: _falas[k + 1].ingles);
      }
      final r = await _voz.falarNaAula(f.texto, ingles: f.ingles, fator: _devagar ? .8 : 1, trilha: _trilha);
      if (!mounted || s != _sessao) return;
      if (r == FimDaFala.cortada) {
        setState(() => _tocando = false);
        return;
      }
      // sem voz nenhuma no aparelho: o tempo de ler a legenda
      final pausa = r == FimDaFala.semVoz
          ? Duration(milliseconds: (f.texto.length * 70).clamp(1500, 9000))
          : Duration(milliseconds: f.ingles ? 650 : 300);
      await _esperar(pausa);
      if (f.pausa > 0 && mounted && s == _sessao) {
        // o desafio: silêncio para o aluno pensar e responder em voz alta
        setState(() => _pensando = f.pausa);
        await _esperar(Duration(seconds: f.pausa));
        if (mounted && s == _sessao) setState(() => _pensando = 0);
      }
    }
    if (!mounted || s != _sessao) return;
    unawaited(PrefsAula.salvarPosicao(widget.licao.id, 0));
    setState(() {
      _tocando = false;
      _fim = true;
      _retomou = false;
    });
  }

  bool _secaoComeca(int k) => widget.aula.secoes.any((x) => x.inicio == k);

  void _pausar() {
    _sessao++;
    _cortarRespiro();
    _voz.parar();
    unawaited(PrefsAula.salvarPosicao(widget.licao.id, _i));
    setState(() {
      _tocando = false;
      _pensando = 0;
    });
  }

  void _alternar() => _tocando ? _pausar() : _tocarDaqui(_fim ? 0 : _i);

  void _irPara(int i) {
    if (i < 0 || i >= _falas.length) return;
    if (_tocando) {
      _tocarDaqui(i);
    } else {
      _voz.parar();
      setState(() {
        _i = i;
        _fim = false;
        _comecou = true;
        _pensando = 0;
      });
    }
  }

  void _doComeco() {
    setState(() => _retomou = false);
    unawaited(PrefsAula.salvarPosicao(widget.licao.id, 0));
    _irPara(0);
  }

  void _sair() => Navigator.of(context).maybePop();

  KeyEventResult _tecla(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.space) {
      _alternar();
    } else if (k == LogicalKeyboardKey.arrowRight) {
      _irPara(_i + 1);
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      _irPara(_i - 1);
    } else if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter || k == LogicalKeyboardKey.escape) {
      _sair();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _foco,
      autofocus: true,
      onKeyEvent: _tecla,
      child: Scaffold(
        backgroundColor: Mixart.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: LayoutBuilder(builder: (context, box) {
                final largo = box.maxWidth >= 720;
                return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
                  _topo(),
                  const SizedBox(height: 14),
                  if (largo)
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 250, child: _professor(190)),
                      const SizedBox(width: 18),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _parteAtual(),
                        _lousa(alta: true),
                      ])),
                    ])
                  else ...[
                    _professor(140),
                    const SizedBox(height: 12),
                    _parteAtual(),
                    _lousa(alta: false),
                  ],
                  const SizedBox(height: 14),
                  _controles(),
                  const SizedBox(height: 16),
                  _rodape(),
                  if (_texto) ...[const SizedBox(height: 16), _transcricao()],
                ]);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topo() => Row(children: [
        IconButton(
          key: const Key('aula-sair'),
          tooltip: 'Sair da aula',
          onPressed: _sair,
          icon: Icon(Icons.close, color: Mixart.text, size: 20),
          style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🎓 ${widget.aula.titulo}',
                key: const Key('aula-titulo'),
                style: Mixart.display(size: 19),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            Text('Aula do $nomeDoProfessor · ${widget.licao.nome} · ≈ ${_minutos(widget.aula.segundos)} min',
                key: const Key('aula-tempo'),
                style: Mixart.ui(size: 12, color: Mixart.textMuted),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(width: 8),
        // a aula é longa: praticar fica sempre à mão (o botão grande está no fim da tela)
        TextButton(
          key: const Key('aula-pular'),
          onPressed: _sair,
          child: Text(widget.primeiraVez ? 'Lição →' : 'Praticar →',
              style: Mixart.ui(size: 12.5, weight: FontWeight.w800, color: Mixart.brand)),
        ),
      ]);

  /// O professor e o balão com o que ele está dizendo agora.
  Widget _professor(double tamanho) {
    final f = _falas[_i];
    return Column(children: [
      Container(
        decoration: BoxDecoration(
          color: Mixart.surface,
          shape: BoxShape.circle,
          border: Border.all(color: Mixart.border),
        ),
        padding: const EdgeInsets.all(6),
        child: ClipOval(child: PersonagemFalante(quem: quemProfessor, tamanho: tamanho)),
      ),
      const SizedBox(height: 6),
      Text(nomeDoProfessor, style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.brand)),
      const SizedBox(height: 10),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Container(
          key: ValueKey('legenda-$_i'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: f.ingles ? Mixart.brandDim : Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Text(
            f.texto,
            key: const Key('aula-legenda'),
            textAlign: TextAlign.center,
            style: f.ingles
                ? Mixart.ui(size: 15, weight: FontWeight.w800, color: Mixart.brand)
                : Mixart.ui(size: 14.5, color: Mixart.text).copyWith(height: 1.45),
          ),
        ),
      ),
    ]);
  }

  static int _minutos(double segundos) => math.max(1, (segundos / 60).round());

  /// A parte em que a aula está, em cima da lousa ("Parte 2 de 7 · A regra").
  Widget _parteAtual() {
    final secoes = widget.aula.secoes;
    if (secoes.length < 2) return const SizedBox.shrink();
    final k = widget.aula.secaoDe(_i);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('Parte ${k + 1} de ${secoes.length} · ${secoes[k].nome}',
          key: const Key('aula-parte-atual'),
          style: Mixart.ui(size: 12.5, weight: FontWeight.w800, color: Mixart.brand),
          overflow: TextOverflow.ellipsis),
    );
  }

  /// A lousa: o exemplo em inglês com a tradução, ou o quadro da fala (fica até aparecer outra coisa escrita),
  /// com a figura do que ele está citando (a foto da cena ou emojis) e, no desafio, o "sua vez".
  Widget _lousa({required bool alta}) {
    final f = lousaAte(_falas, _i);
    final figura = figuraAte(_falas, _i);
    const verde = Color(0xFF1F3A2E), giz = Color(0xFFF4F1E8);
    final Widget? texto = f == null
        ? (figura.isEmpty
            ? Text(widget.licao.nome,
                textAlign: TextAlign.center, style: Mixart.display(size: 22, color: giz.withValues(alpha: .7)))
            : null)
        : f.ingles
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                Text(f.en,
                    key: const Key('aula-lousa-en'),
                    textAlign: TextAlign.center,
                    style: Mixart.display(size: alta ? 30 : 24, color: giz)),
                const SizedBox(height: 10),
                Text(f.tr,
                    textAlign: TextAlign.center,
                    style: Mixart.ui(size: alta ? 16 : 14, color: giz.withValues(alpha: .75))),
              ])
            : Text(f.quadro,
                key: const Key('aula-lousa-quadro'),
                textAlign: TextAlign.center,
                style: Mixart.display(size: alta ? 26 : 21, color: giz));
    final conteudo = Column(mainAxisSize: MainAxisSize.min, children: [
      if (figura.isNotEmpty) _figura(figura, alta: alta),
      if (figura.isNotEmpty && texto != null) SizedBox(height: alta ? 16 : 12),
      ?texto,
    ]);
    return Container(
      constraints: BoxConstraints(minHeight: alta ? 300 : 190),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: verde,
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        border: Border.all(color: const Color(0xFF6B4A2B), width: 8),
      ),
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey('$figura|${f?.texto}|${f?.quadro}'), child: conteudo),
        ),
        if (_pensando > 0) ...[const SizedBox(height: 16), _suaVez(giz)],
      ]),
    );
  }

  /// A figura na lousa: a foto da cena (moldura branca, meio torta, como presa no quadro) ou os emojis grandes.
  Widget _figura(String figura, {required bool alta}) {
    if (figura == figuraFoto) {
      final foto = widget.licao.foto;
      if (foto.isEmpty) return const SizedBox.shrink();
      return Transform.rotate(
        angle: -.025,
        child: Container(
          key: const Key('aula-figura-foto'),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0xFFF7F4EC), borderRadius: BorderRadius.circular(6)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: alta ? 180 : 130,
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.asset(foto, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
              ),
            ),
          ),
        ),
      );
    }
    return Text(figura,
        key: const Key('aula-figura'),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: alta ? 64 : 48, height: 1.15));
  }

  /// O desafio: a vez do aluno responder, com a barra do tempo que falta.
  Widget _suaVez(Color giz) => Column(key: const Key('aula-pensando'), mainAxisSize: MainAxisSize.min, children: [
        Text('🤔 Sua vez! Responda em voz alta…',
            style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: giz)),
        const SizedBox(height: 8),
        SizedBox(
          width: 180,
          child: TweenAnimationBuilder<double>(
            key: ValueKey('pensa-$_i'),
            tween: Tween(begin: 1, end: 0),
            duration: Duration(seconds: _pensando),
            builder: (_, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 5,
                backgroundColor: giz.withValues(alpha: .15),
                color: giz.withValues(alpha: .8),
              ),
            ),
          ),
        ),
      ]);

  Widget _controles() {
    Widget redondo(Key k, IconData icone, String dica, VoidCallback? onTap, {bool destaque = false}) => Tooltip(
          message: dica,
          child: Material(
            color: destaque ? Mixart.brand : Mixart.surfaceHi,
            shape: CircleBorder(side: BorderSide(color: destaque ? Mixart.brand : Mixart.border)),
            child: InkWell(
              key: k,
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(destaque ? 16 : 11),
                child: Icon(icone, size: destaque ? 30 : 22, color: destaque ? Mixart.onBrand : Mixart.text),
              ),
            ),
          ),
        );
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: _fim ? 1 : 1 - widget.aula.segundosDesde(_i) / math.max(1, widget.aula.segundos),
          minHeight: 6,
          backgroundColor: Mixart.surfaceHi,
          color: Mixart.brand,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 14, runSpacing: 10, children: [
        redondo(const Key('aula-anterior'), Icons.skip_previous_rounded, 'Fala anterior (←)', _i > 0 ? () => _irPara(_i - 1) : null),
        redondo(
          const Key('aula-tocar'),
          _tocando ? Icons.pause_rounded : (_fim ? Icons.replay_rounded : Icons.play_arrow_rounded),
          _tocando ? 'Pausar (Espaço)' : (_fim ? 'Ouvir a aula de novo' : 'Ouvir (Espaço)'),
          _alternar,
          destaque: true,
        ),
        redondo(const Key('aula-proxima'), Icons.skip_next_rounded, 'Próxima fala (→)',
            _i < _falas.length - 1 ? () => _irPara(_i + 1) : null),
        Text(
            _fim
                ? '${_falas.length} / ${_falas.length}'
                : '${_i + 1} / ${_falas.length} · faltam ${_minutos(widget.aula.segundosDesde(_i) / (_devagar ? .8 : 1))} min',
            key: const Key('aula-contador'),
            style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textMuted)),
      ]),
      if (_retomou && !_fim) ...[
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
          Text('Continuando de onde você parou', style: Mixart.ui(size: 12, color: Mixart.textMuted)),
          TextButton(
            key: const Key('aula-do-comeco'),
            onPressed: _doComeco,
            child: Text('↺ Do começo', style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.brand)),
          ),
        ]),
      ],
      if (!_comecou) ...[
        const SizedBox(height: 8),
        Text('Toque em ▶ para o professor começar a aula',
            style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.brand)),
      ],
      if (widget.aula.secoes.length > 1) ...[const SizedBox(height: 12), _partes()],
      const SizedBox(height: 10),
      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
        FilterChip(
          key: const Key('aula-devagar'),
          label: Text('🐢 Mais devagar', style: Mixart.ui(size: 12, weight: FontWeight.w700)),
          selected: _devagar,
          onSelected: (v) {
            setState(() => _devagar = v);
            if (_tocando) _tocarDaqui(_i);
          },
        ),
        FilterChip(
          key: const Key('aula-ler'),
          label: Text('📜 Ler a aula', style: Mixart.ui(size: 12, weight: FontWeight.w700)),
          selected: _texto,
          onSelected: (v) => setState(() => _texto = v),
        ),
      ]),
    ]);
  }

  /// As partes da aula: tocar numa pula para o começo dela (tocando, segue tocando dali).
  Widget _partes() {
    final secoes = widget.aula.secoes;
    final atual = widget.aula.secaoDe(_i);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (var k = 0; k < secoes.length; k++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: k == atual ? Mixart.brand : Mixart.surfaceHi,
              shape: StadiumBorder(side: BorderSide(color: k == atual ? Mixart.brand : Mixart.border)),
              child: InkWell(
                key: Key('aula-parte-$k'),
                customBorder: const StadiumBorder(),
                onTap: () => _irPara(secoes[k].inicio),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text('${k + 1}. ${secoes[k].nome}',
                      style: Mixart.ui(
                          size: 11.5,
                          weight: FontWeight.w800,
                          color: k == atual ? Mixart.onBrand : Mixart.text)),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _rodape() => Column(children: [
        Center(
          child: FilledButton(
            key: const Key('aula-praticar'),
            style: FilledButton.styleFrom(
              backgroundColor: _fim ? Mixart.brand : Mixart.surfaceHi,
              foregroundColor: _fim ? Mixart.onBrand : Mixart.text,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: _sair,
            child: Text(widget.primeiraVez ? 'Começar a lição →' : 'Praticar a lição →',
                style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: _fim ? Mixart.onBrand : Mixart.text)),
          ),
        ),
        if (widget.primeiraVez && _auto != null) ...[
          const SizedBox(height: 6),
          Center(
            child: InkWell(
              key: const Key('aula-auto'),
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                final v = !_auto!;
                setState(() => _auto = v);
                PrefsAula.salvarAuto(v);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_auto! ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      size: 18, color: Mixart.textMuted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('Abrir a aula sozinha nas lições novas',
                        style: Mixart.ui(size: 12, color: Mixart.textMuted)),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ]);

  Widget _transcricao() => Container(
        key: const Key('aula-texto'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var k = 0; k < _falas.length; k++) ...[
            if (_falas[k].secao.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(8, k == 0 ? 0 : 14, 8, 4),
                child: Text(_falas[k].secao, style: Mixart.display(size: 15, color: Mixart.brand)),
              ),
            InkWell(
              onTap: () => _tocarDaqui(k),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: k == _i ? Mixart.brandSub : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _falas[k].ingles
                    ? Text.rich(TextSpan(children: [
                        TextSpan(
                            text: _falas[k].en,
                            style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: Mixart.brand)),
                        TextSpan(text: '  ${_falas[k].tr}', style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
                      ]))
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_falas[k].pt, style: Mixart.ui(size: 13.5, color: Mixart.text).copyWith(height: 1.45)),
                        if (_falas[k].quadro.isNotEmpty)
                          Text('✎ ${_falas[k].quadro}',
                              style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.textMuted)),
                      ]),
              ),
            ),
          ],
        ]),
      );
}
