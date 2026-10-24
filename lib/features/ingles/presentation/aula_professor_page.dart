import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/domain/curriculo.dart';
import '../data/aulas_repo.dart';
import '../data/voz_ingles.dart';
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

/// 🎓 A aula do professor: o Prof. Beto (rosto com a boca sincronizada) fala cada trecho da aula em português e
/// diz os exemplos em inglês; a lousa mostra o que está escrito (o quadro, ou o exemplo com a tradução) e a
/// legenda, o que ele está dizendo. Toca sozinha, uma fala depois da outra; ⏮ ⏯ ⏭, 🐢 e "📜 Ler a aula" (o
/// texto todo, tocar numa fala começa dali). Espaço = tocar/pausar, ← → = fala anterior/seguinte, Esc = sair.
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
    if (widget.tocarAoAbrir && _voz.somLiberado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tocarDaqui(0);
      });
    }
  }

  @override
  void dispose() {
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
    });
    for (var k = _i; k < _falas.length; k++) {
      if (!mounted || s != _sessao) return;
      setState(() => _i = k);
      final f = _falas[k];
      final r = await _voz.falarNaAula(f.texto, ingles: f.ingles, fator: _devagar ? .8 : 1);
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
    }
    if (!mounted || s != _sessao) return;
    setState(() {
      _tocando = false;
      _fim = true;
    });
  }

  void _pausar() {
    _sessao++;
    _cortarRespiro();
    _voz.parar();
    setState(() => _tocando = false);
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
      });
    }
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
                      Expanded(child: _lousa(alta: true)),
                    ])
                  else ...[
                    _professor(140),
                    const SizedBox(height: 12),
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
            Text('Aula do $nomeDoProfessor · ${widget.licao.nome}',
                style: Mixart.ui(size: 12, color: Mixart.textMuted), overflow: TextOverflow.ellipsis),
          ]),
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

  /// A lousa: o exemplo em inglês com a tradução, ou o quadro da fala (fica até aparecer outra coisa escrita).
  Widget _lousa({required bool alta}) {
    final f = lousaAte(_falas, _i);
    const verde = Color(0xFF1F3A2E), giz = Color(0xFFF4F1E8);
    final conteudo = f == null
        ? Text(widget.licao.nome,
            textAlign: TextAlign.center, style: Mixart.display(size: 22, color: giz.withValues(alpha: .7)))
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
    return Container(
      constraints: BoxConstraints(minHeight: alta ? 260 : 150),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: verde,
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        border: Border.all(color: const Color(0xFF6B4A2B), width: 8),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(f), child: conteudo),
      ),
    );
  }

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
          value: _fim ? 1 : (_i + (_tocando ? .5 : 0)) / _falas.length,
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
        Text('${_i + 1} / ${_falas.length}', style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textMuted)),
      ]),
      if (!_comecou) ...[
        const SizedBox(height: 8),
        Text('Toque em ▶ para o professor começar a aula',
            style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.brand)),
      ],
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
          for (var k = 0; k < _falas.length; k++)
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
        ]),
      );
}
