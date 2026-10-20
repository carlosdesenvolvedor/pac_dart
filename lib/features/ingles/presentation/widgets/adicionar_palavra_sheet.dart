import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../../../core/ui/festa.dart';
import '../../data/dicionario_ingles.dart';
import '../../data/tradutor.dart';
import '../../domain/banco_palavras.dart';
import '../../domain/dicionario.dart';
import '../../domain/palavras_novas.dart';
import '../palavras_cubit.dart';

/// Uma linha do "Colar lista": a palavra (como ficou), a tradução usada e o problema (null = entrou).
typedef LinhaColada = ({int linha, String en, String pt, String? erro});

/// Abre o "➕ Adicionar palavra" (uma palavra, ou "Colar lista" com várias). Devolve as palavras que
/// entraram no banco (vazio se nada entrou) e, quando entrou alguma, avisa no snackbar de [context].
/// Sem o [PalavrasCubit] (Dart, C#) não abre. [tradutor] é injetável (testes); sem ele vale o do app.
Future<List<String>> mostrarAdicionarPalavra(BuildContext context, {Tradutor? tradutor}) async {
  final cubit = PalavrasCubit.de(context);
  if (cubit == null) return const [];
  Tradutor? t = tradutor;
  if (t == null) {
    try {
      t = context.read<Tradutor>();
    } catch (_) {}
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  final entraram = <String>[];
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Mixart.surface,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 620),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusLg))),
    builder: (_) => AdicionarPalavraSheet(cubit: cubit, tradutor: t ?? TradutorMyMemory(), aoEntrar: entraram.add),
  );
  if (entraram.isNotEmpty && messenger != null) {
    final unica = entraram.length == 1 ? entraram.first : null;
    final noJogo = entraram.where((e) => RegExp(r'^[A-Za-z]{3,14}$').hasMatch(e)).length;
    final texto = unica != null
        ? (noJogo == 1 ? '"$unica" vai aparecer no Arcade 🎮' : '"$unica" entrou nas suas palavras')
        : (noJogo > 0
            ? '${entraram.length} palavras novas · $noJogo vão aparecer no Arcade 🎮'
            : '${entraram.length} palavras novas no seu banco');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        key: const Key('palavra-adicionada'),
        backgroundColor: Mixart.surfaceHi,
        content: Text(texto, style: Mixart.ui(size: 13, color: Mixart.text)),
      ));
  }
  return entraram;
}

/// Lê "palavra = tradução" (também `;`, `:`, tab ou " - ") linha a linha. A tradução pode faltar.
List<({int linha, String en, String pt})> lerListaColada(String texto) {
  final r = <({int linha, String en, String pt})>[];
  final linhas = texto.split(RegExp(r'\r?\n'));
  final sep = RegExp(r'\s*(?:=|\t|;|:|\s[-–—]\s)\s*');
  for (var i = 0; i < linhas.length; i++) {
    final l = linhas[i].trim().replaceAll(RegExp(r'^[•*·\-–]\s*'), '');
    if (l.isEmpty) continue;
    final m = sep.firstMatch(l);
    if (m == null) {
      r.add((linha: i + 1, en: l, pt: ''));
    } else {
      r.add((linha: i + 1, en: l.substring(0, m.start).trim(), pt: l.substring(m.end).trim()));
    }
  }
  return r;
}

/// O conteúdo da folha (público para os testes e a prévia).
class AdicionarPalavraSheet extends StatefulWidget {
  final PalavrasCubit cubit;
  final Tradutor tradutor;
  final void Function(String en) aoEntrar;

  /// Começa no "Colar lista".
  final bool lista;

  const AdicionarPalavraSheet({super.key, required this.cubit, required this.tradutor, required this.aoEntrar, this.lista = false});

  static const maxLinhas = 100;

  @override
  State<AdicionarPalavraSheet> createState() => _AdicionarPalavraSheetState();
}

class _AdicionarPalavraSheetState extends State<AdicionarPalavraSheet> {
  late bool _modoLista = widget.lista;
  final _en = TextEditingController();
  final _pt = TextEditingController();
  final _texto = TextEditingController();
  final _focoEn = FocusNode();

  /// A tradução foi posta por nós (dicionário/tradutor) e pode ser trocada quando a palavra muda.
  bool _ptAuto = false;
  String? _origemPt; // 'dicionário' | 'tradutor'
  String? _erroEn;
  String? _erroSalvar;
  bool _traduzindo = false;
  String? _avisoTraducao;
  List<LinhaColada>? _relatorio;
  int _festa = 0;

  PalavrasCubit get _cubit => widget.cubit;
  Dicionario? get _dic => _cubit.state.indice?.dic ?? DicionarioIngles.pronto;

  @override
  void dispose() {
    _en.dispose();
    _pt.dispose();
    _texto.dispose();
    _focoEn.dispose();
    super.dispose();
  }

  String _doDicionario(String en) => traducaoCurta(_dic?.literal(en), max: 30);

  ({String en, String? erro}) get _validacao => validarPalavraNova(_en.text, _cubit.state.banco);

  void _mudouEn(String texto) {
    final v = validarPalavraNova(texto, _cubit.state.banco);
    setState(() {
      _erroSalvar = null;
      _avisoTraducao = null;
      _erroEn = texto.trim().isEmpty ? null : v.erro;
      if (_pt.text.trim().isEmpty || _ptAuto) {
        final sug = v.erro == null ? _doDicionario(v.en) : '';
        _pt.text = sug;
        _ptAuto = sug.isNotEmpty;
        _origemPt = sug.isNotEmpty ? 'dicionário' : null;
      }
    });
  }

  Future<void> _traduzir() async {
    final v = _validacao;
    if (v.erro != null || _traduzindo) return;
    setState(() {
      _traduzindo = true;
      _avisoTraducao = null;
    });
    String? achou;
    try {
      final r = await widget.tradutor.traduzir([v.en]);
      achou = r.isEmpty ? null : r.first.trim();
    } catch (_) {
      achou = null;
    }
    if (!mounted) return;
    setState(() {
      _traduzindo = false;
      if (achou == null || achou.isEmpty) {
        _avisoTraducao = 'Não deu para traduzir agora — escreva você';
      } else if (_validacao.en.toLowerCase() == v.en.toLowerCase()) {
        _pt.text = achou;
        _ptAuto = true;
        _origemPt = 'tradutor';
      }
    });
  }

  void _salvar() {
    final v = _validacao;
    if (v.erro != null) {
      setState(() => _erroEn = v.erro);
      return;
    }
    final erro = _cubit.adicionar(v.en, _pt.text);
    if (erro != null) {
      setState(() => _erroSalvar = erro);
      return;
    }
    widget.aoEntrar(v.en);
    Navigator.of(context).maybePop();
  }

  void _adicionarLista() {
    final linhas = lerListaColada(_texto.text);
    if (linhas.isEmpty) {
      setState(() => _relatorio = const []);
      return;
    }
    final r = <LinhaColada>[];
    for (final l in linhas.take(AdicionarPalavraSheet.maxLinhas)) {
      final v = validarPalavraNova(l.en, _cubit.state.banco);
      if (v.erro != null) {
        r.add((linha: l.linha, en: l.en, pt: l.pt, erro: v.erro));
        continue;
      }
      final pt = l.pt.isNotEmpty ? l.pt : _doDicionario(v.en);
      if (pt.isEmpty) {
        r.add((linha: l.linha, en: v.en, pt: '', erro: 'Falta a tradução (escreva "palavra = tradução")'));
        continue;
      }
      final erro = _cubit.adicionar(v.en, pt);
      if (erro == null) widget.aoEntrar(v.en);
      r.add((linha: l.linha, en: v.en, pt: pt, erro: erro));
    }
    if (linhas.length > AdicionarPalavraSheet.maxLinhas) {
      r.add((linha: linhas[AdicionarPalavraSheet.maxLinhas].linha, en: '…', pt: '', erro: 'Só as ${AdicionarPalavraSheet.maxLinhas} primeiras linhas de cada vez'));
    }
    setState(() {
      _relatorio = r;
      if (r.any((x) => x.erro == null)) {
        _festa++;
        _texto.clear();
      }
    });
  }

  InputDecoration _campo(String rotulo, String dica, {String? erro, Widget? sufixo}) => InputDecoration(
        labelText: rotulo,
        labelStyle: Mixart.ui(size: 13, color: Mixart.textMuted),
        hintText: dica,
        hintStyle: Mixart.ui(size: 13.5, color: Mixart.textFaint),
        errorText: erro,
        errorMaxLines: 2,
        errorStyle: Mixart.ui(size: 12, color: Mixart.danger),
        filled: true,
        fillColor: Mixart.bg,
        suffixIcon: sufixo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.brand, width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.danger, width: 1.4)),
      );

  Widget _abas() {
    Widget aba(String rotulo, bool ativa, VoidCallback onTap, Key chave) => Expanded(
          child: Material(
            color: ativa ? Mixart.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(Mixart.radiusChip),
            child: InkWell(
              key: chave,
              borderRadius: BorderRadius.circular(Mixart.radiusChip),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(rotulo,
                    textAlign: TextAlign.center,
                    style: Mixart.ui(size: 13, weight: FontWeight.w800, color: ativa ? Mixart.onBrand : Mixart.textMuted)),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Mixart.bg,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusChip),
      ),
      child: Row(children: [
        aba('Uma palavra', !_modoLista, () => setState(() => _modoLista = false), const Key('palavra-uma')),
        const SizedBox(width: 4),
        aba('📋 Colar lista', _modoLista, () => setState(() => _modoLista = true), const Key('palavra-colar')),
      ]),
    );
  }

  Widget _umaPalavra() {
    final v = _validacao;
    final valida = _en.text.trim().isNotEmpty && v.erro == null;
    final podeSalvar = valida && _pt.text.trim().isNotEmpty;
    final semTraducao = valida && _pt.text.trim().isEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        key: const Key('palavra-en'),
        controller: _en,
        focusNode: _focoEn,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.next,
        inputFormatters: [LengthLimitingTextInputFormatter(40)],
        style: Mixart.mono(size: 17, weight: FontWeight.w700, color: Mixart.text),
        decoration: _campo('Em inglês', 'ex.: apple', erro: _erroEn),
        onChanged: _mudouEn,
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('palavra-pt'),
        controller: _pt,
        textInputAction: TextInputAction.done,
        inputFormatters: [LengthLimitingTextInputFormatter(60)],
        style: Mixart.ui(size: 15, weight: FontWeight.w600, color: Mixart.text),
        decoration: _campo('Tradução', 'ex.: maçã', erro: _erroSalvar),
        onChanged: (_) => setState(() {
          _ptAuto = false;
          _origemPt = null;
          _erroSalvar = null;
        }),
        onSubmitted: (_) => podeSalvar ? _salvar() : null,
      ),
      if (_origemPt != null && _pt.text.trim().isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(_origemPt == 'dicionário' ? '📖 Tradução do dicionário do curso — pode trocar' : '✨ Tradução automática — confira',
            key: const Key('palavra-origem-pt'), style: Mixart.ui(size: 12, color: Mixart.textMuted)),
      ],
      if (semTraducao || _avisoTraducao != null) ...[
        const SizedBox(height: 10),
        Row(children: [
          Botao3D(
            key: const Key('palavra-traduzir'),
            rotulo: _traduzindo ? 'Traduzindo…' : '✨ Traduzir',
            contorno: true,
            expandir: false,
            altura: 40,
            tamanhoTexto: 13.5,
            onTap: _traduzindo || !valida ? null : _traduzir,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _avisoTraducao ?? 'Não está no dicionário do curso.',
              key: _avisoTraducao != null ? const Key('palavra-aviso-traducao') : null,
              style: Mixart.ui(size: 12.5, color: _avisoTraducao != null ? Mixart.danger : Mixart.textMuted),
            ),
          ),
        ]),
      ],
      const SizedBox(height: 18),
      Botao3D(
        key: const Key('palavra-salvar'),
        rotulo: 'Salvar palavra',
        icone: Icons.check_rounded,
        onTap: podeSalvar ? _salvar : null,
      ),
    ]);
  }

  Widget _colarLista() {
    final rel = _relatorio;
    final ok = rel?.where((r) => r.erro == null).length ?? 0;
    final ruins = (rel?.length ?? 0) - ok;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Uma palavra por linha, com a tradução depois do "=". Sem tradução, uso a do dicionário do curso.',
          style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4)),
      const SizedBox(height: 10),
      TextField(
        key: const Key('palavra-lista'),
        controller: _texto,
        minLines: 4,
        maxLines: 8,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.multiline,
        style: Mixart.mono(size: 14, color: Mixart.text),
        decoration: _campo('Lista', 'apple = maçã\nbook = livro\nhappy = feliz'),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 14),
      Botao3D(
        key: const Key('palavra-salvar'),
        rotulo: 'Adicionar todas',
        icone: Icons.playlist_add_rounded,
        onTap: _texto.text.trim().isEmpty ? null : _adicionarLista,
      ),
      if (rel != null) ...[
        const SizedBox(height: 14),
        Container(
          key: const Key('palavra-relatorio'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Mixart.bg,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              rel.isEmpty
                  ? 'Nenhuma linha com palavra.'
                  : '${ok == 1 ? '1 palavra adicionada' : '$ok palavras adicionadas'}'
                      '${ruins > 0 ? ' · $ruins com problema' : ''}',
              key: const Key('palavra-resumo'),
              style: Mixart.ui(size: 13, weight: FontWeight.w800, color: ruins > 0 && ok == 0 ? Mixart.danger : Mixart.text),
            ),
            for (final r in rel) ...[
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: r.erro == null ? '✅ ' : '⚠️ '),
                  TextSpan(text: 'linha ${r.linha}: ', style: Mixart.ui(size: 12, color: Mixart.textFaint)),
                  TextSpan(text: r.en, style: Mixart.mono(size: 12.5, weight: FontWeight.w700, color: Mixart.text)),
                  TextSpan(
                    text: r.erro == null ? ' → ${r.pt}' : ' — ${r.erro}',
                    style: Mixart.ui(size: 12.5, color: r.erro == null ? Mixart.textMuted : Mixart.danger),
                  ),
                ]),
                style: Mixart.ui(size: 12.5, color: Mixart.text),
              ),
            ],
          ]),
        ),
        if (ok > 0) ...[
          const SizedBox(height: 12),
          Botao3D(
            key: const Key('palavra-pronto'),
            rotulo: 'Pronto',
            contorno: true,
            altura: 44,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final teclado = MediaQuery.viewInsetsOf(context).bottom;
    return Stack(children: [
      SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + teclado),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text('➕ Adicionar palavra', style: Mixart.display(size: 20)),
          const SizedBox(height: 4),
          Text('Ela entra no seu banco, aparece nos jogos do Arcade e no treino de palavras.',
              style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4)),
          const SizedBox(height: 14),
          _abas(),
          const SizedBox(height: 16),
          if (_modoLista) _colarLista() else _umaPalavra(),
        ]),
      ),
      if (_festa > 0)
        Positioned.fill(
          child: Confete(key: ValueKey('festa-lista-$_festa'), quantidade: 26, origem: const Alignment(0, .4)),
        ),
    ]);
  }
}
