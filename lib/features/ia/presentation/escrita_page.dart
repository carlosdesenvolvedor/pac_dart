import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../domain/escrita.dart';
import 'escrita_cubit.dart';
import 'feedback_cenario.dart' show salvarCartaoDoCenario;
import 'ia_cubit.dart';
import 'widgets/botao_por_que.dart' show comNegrito;

/// Escrever 2–3 frases em inglês e ser corrigido pelo Prof. Dash: cada erro pode virar um cartão.
/// Sem [IaCubit] na árvore não abre. Não há nota: a IA só corrige e explica.
class EscritaPage extends StatelessWidget {
  const EscritaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ia = IaCubit.de(context);
    if (ia == null) return const Scaffold(body: SizedBox.shrink());
    return BlocProvider(create: (_) => EscritaCubit(ia: ia), child: const _Escrita());
  }
}

class _Escrita extends StatefulWidget {
  const _Escrita();

  @override
  State<_Escrita> createState() => _EscritaState();
}

class _EscritaState extends State<_Escrita> {
  final _campo = TextEditingController();

  /// As frases (em inglês) que já viraram cartão nesta correção.
  final _salvos = <String>{};
  final _salvando = <String>{};
  bool _salvandoTodos = false;

  @override
  void initState() {
    super.initState();
    _campo.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _tema(TemaEscrita t) {
    // sem requestFocus: na web, mexer no foco durante um toque derruba a conexão do teclado
    final atual = _campo.text;
    final novo = atual.trim().isEmpty ? t.comeco : '${atual.trimRight()}\n${t.comeco}';
    _campo.value = TextEditingValue(text: novo, selection: TextSelection.collapsed(offset: novo.length));
  }

  Future<void> _salvar(ErroEscrito e) async {
    final c = e.cartao;
    if (c == null || _salvando.contains(c.en) || _salvos.contains(c.en)) return;
    setState(() => _salvando.add(c.en));
    await salvarCartaoDoCenario(context, c);
    if (!mounted) return;
    setState(() {
      _salvando.remove(c.en);
      _salvos.add(c.en);
    });
  }

  Future<void> _salvarTodos(List<ErroEscrito> erros) async {
    if (_salvandoTodos) return;
    setState(() => _salvandoTodos = true);
    // um de cada vez: cada cartão espera aparecer no baralho antes do próximo
    for (final e in erros) {
      if (!mounted) return;
      await _salvar(e);
    }
    if (mounted) setState(() => _salvandoTodos = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EscritaCubit, EscritaState>(builder: (context, st) {
      final prep = TextoEscrito.preparar(_campo.text);
      return Scaffold(
        backgroundColor: Mixart.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                key: const Key('lista-escrita'),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 48),
                children: [
                  Row(children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
                      style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
                    ),
                    const SizedBox(width: 12),
                    const Text('📝', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Escrever', style: Mixart.display(size: 22))),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                      'Escreva 2–3 frases em inglês sobre o seu dia. O Prof. Dash corrige e explica em português, '
                      'e cada erro pode virar um cartão para você revisar. Não tem nota.',
                      style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.5)),
                  const SizedBox(height: 6),
                  BlocBuilder<IaCubit, IaState>(
                    builder: (_, ia) => Text(ia.carregado ? (ia.restantes == 1 ? 'Resta 1 uso hoje' : 'Restam ${ia.restantes} usos hoje') : '',
                        key: const Key('escrita-restantes'), style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textFaint)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (var i = 0; i < temasDeEscrita.length; i++)
                      ActionChip(
                        key: Key('tema-escrita-$i'),
                        label: Text('${temasDeEscrita[i].emoji} ${temasDeEscrita[i].rotulo}', style: Mixart.ui(size: 12, color: Mixart.text)),
                        backgroundColor: Mixart.surfaceHi,
                        side: BorderSide(color: Mixart.border),
                        onPressed: () => _tema(temasDeEscrita[i]),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  // O campo NUNCA é desligado, não tem autofocus nem requestFocus (na web isso derruba a conexão do
                  // teclado com um erro do motor). Multilinha: o Enter quebra linha; só o botão envia.
                  TextField(
                    key: const Key('campo-escrita'),
                    controller: _campo,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 1000,
                    keyboardType: TextInputType.multiline,
                    style: Mixart.ui(size: 14.5, color: Mixart.text).copyWith(height: 1.45),
                    decoration: InputDecoration(
                      hintText: 'Today I woke up early and…',
                      hintStyle: Mixart.ui(size: 13.5, color: Mixart.textFaint),
                      counterText: '',
                      filled: true,
                      fillColor: Mixart.surfaceHi,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.brand)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: Text(
                          prep == null
                              ? 'Até ${TextoEscrito.maxFrases} frases, cada uma com até ${TextoEscrito.maxLetras} letras.'
                              : '${prep.frases.length} de ${TextoEscrito.maxFrases} frases'
                                  '${prep.cortouFrases ? ' — só as ${TextoEscrito.maxFrases} primeiras vão para a correção' : ''}'
                                  '${prep.cortouLetras ? ' — frase longa cortada em ${TextoEscrito.maxLetras} letras' : ''}',
                          key: const Key('escrita-contador'),
                          style: Mixart.ui(size: 12, color: Mixart.textMuted)),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      key: const Key('corrigir-escrita'),
                      onPressed: st.aguardando ? null : () => context.read<EscritaCubit>().corrigir(_campo.text),
                      style: FilledButton.styleFrom(backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
                      child: Text('Corrigir', style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: Mixart.onBrand)),
                    ),
                  ]),
                  if (st.aguardando)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Row(children: [
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Mixart.brand)),
                        const SizedBox(width: 8),
                        Flexible(child: Text('O Prof. Dash está corrigindo…', key: const Key('escrita-corrigindo'), style: Mixart.ui(size: 12.5, color: Mixart.textMuted))),
                      ]),
                    ),
                  if (st.erro == ErroEscrita.semTexto)
                    _aviso(const Key('escrita-sem-texto'), 'Escreva alguma coisa em inglês primeiro. 🙂'),
                  if (st.erro == ErroEscrita.falhou)
                    _aviso(const Key('escrita-falhou'),
                        'Não consegui falar com o Prof. Dash agora (isso não gastou seu limite do dia). Seu texto continua aí: confere a internet e tenta de novo.'),
                  if (st.erro == ErroEscrita.semCota)
                    _aviso(const Key('escrita-sem-cota'), 'Por hoje o Prof. Dash descansou — amanhã tem mais 🐦 Seu texto continua aí.'),
                  if (st.resultado != null) ...[
                    const SizedBox(height: 16),
                    _resultado(st.resultado!),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _aviso(Key k, String t) => Container(
        key: k,
        width: double.infinity,
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Mixart.surfaceHi, border: Border.all(color: Mixart.border), borderRadius: BorderRadius.circular(Mixart.radiusMd)),
        child: Text(t, style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.45)),
      );

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(t, style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: .8)),
      );

  Widget _resultado(ResultadoEscrita r) {
    final List<Widget> corpo;
    if (!r.estruturado) {
      corpo = [
        const SizedBox(height: 8),
        Text('Não consegui organizar a correção, mas aqui está o que o Prof. Dash disse:',
            key: const Key('escrita-crua'), style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
        const SizedBox(height: 8),
        SelectableText(r.textoCru ?? '', style: Mixart.ui(size: 13.5, color: Mixart.text).copyWith(height: 1.5)),
      ];
    } else if (!r.emIngles) {
      corpo = [
        const SizedBox(height: 8),
        Text('Parece que esse texto não está em inglês. Escreva em inglês (mesmo com erros!) e tente de novo. 🙂',
            key: const Key('escrita-nao-ingles'), style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.45)),
      ];
    } else {
      final salvaveis = r.salvaveis;
      final faltam = salvaveis.where((e) => !_salvos.contains(e.cartao!.en)).toList();
      corpo = [
        if (r.semErros)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Sem erros desta vez! 🎉', key: const Key('escrita-sem-erros'), style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.text)),
          ),
        if (r.corrigido.isNotEmpty) ...[
          _titulo('SEU TEXTO CORRIGIDO'),
          SelectableText(r.corrigido, key: const Key('escrita-corrigido'), style: Mixart.ui(size: 14.5, color: Mixart.text).copyWith(height: 1.5)),
        ],
        if (r.elogio.isNotEmpty) ...[
          _titulo('O QUE FOI BEM'),
          Text('✅ ${r.elogio}', style: Mixart.ui(size: 13.5, color: Mixart.text).copyWith(height: 1.45)),
        ],
        if (r.erros.isNotEmpty) ...[
          _titulo('PARA MELHORAR'),
          for (var i = 0; i < r.erros.length; i++) _erro(i, r.erros[i]),
          if (salvaveis.length > 1)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: const Key('salvar-todos'),
                onPressed: faltam.isEmpty || _salvandoTodos ? null : () => _salvarTodos(faltam),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Mixart.brandDim),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: Text(faltam.isEmpty ? '✓ Todos salvos' : (_salvandoTodos ? 'Salvando…' : 'Salvar todos (${faltam.length})'),
                    style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.brand)),
              ),
            ),
        ],
        const SizedBox(height: 10),
        TextButton(
          key: const Key('escrever-outro'),
          onPressed: () {
            _campo.clear();
            setState(() {
              _salvos.clear();
              _salvando.clear();
              _salvandoTodos = false;
            });
            context.read<EscritaCubit>().recomecar();
          },
          child: Text('Escrever outro texto', style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)),
        ),
      ];
    }
    return Container(
      key: const Key('resultado-escrita'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(color: Mixart.surface, border: Border.all(color: Mixart.brandDim), borderRadius: BorderRadius.circular(Mixart.radiusLg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🐦 Correção do Prof. Dash', style: Mixart.display(size: 18)),
        ...corpo,
      ]),
    );
  }

  Widget _erro(int i, ErroEscrito e) {
    final c = e.cartao;
    final salvo = c != null && _salvos.contains(c.en), salvando = c != null && _salvando.contains(c.en);
    return Container(
      key: Key('erro-escrita-$i'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Mixart.surfaceHi,
        border: Border.all(color: salvo ? Mixart.brand : Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(e.sua, style: Mixart.ui(size: 13, color: Mixart.danger).copyWith(decoration: TextDecoration.lineThrough, decorationColor: Mixart.danger)),
        const SizedBox(height: 3),
        SelectableText(e.melhor, style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.brand)),
        if (e.pt.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(e.pt, style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
        ],
        if (e.porque.isNotEmpty) ...[
          const SizedBox(height: 6),
          SelectableText.rich(comNegrito(e.porque, Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.45))),
        ],
        if (c != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            key: Key('salvar-erro-$i'),
            onPressed: salvo || salvando ? null : () => _salvar(e),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: salvo ? Mixart.brand : Mixart.brandDim),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Text(salvo ? '✓ Salvo' : (salvando ? 'Salvando…' : 'Salvar como cartão'),
                style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.brand)),
          ),
        ],
      ]),
    );
  }
}
