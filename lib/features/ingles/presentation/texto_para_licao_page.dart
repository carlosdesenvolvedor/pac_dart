import 'package:flutter/material.dart';

import '../../../core/theme/mixart.dart';
import '../data/tradutor.dart';
import '../domain/texto_para_frases.dart';
import '../domain/texto_salvo.dart';

/// "Crie uma lição com o seu texto": a pessoa cola um texto em inglês, o app
/// separa em frases, traduz (serviço automático), mostra para ela corrigir e
/// devolve um [TextoSalvo] — quem chamou transforma em trilha. A voz das
/// lições é a sintética do aparelho (texto próprio não tem gravação de nativo).
class TextoParaLicaoPage extends StatefulWidget {
  final Tradutor tradutor;

  /// Texto já preenchido (testes).
  final String textoInicial;

  const TextoParaLicaoPage({super.key, required this.tradutor, this.textoInicial = ''});

  @override
  State<TextoParaLicaoPage> createState() => _TextoParaLicaoPageState();
}

enum _Fase { entrada, traduzindo, revisao }

class _Par {
  final String en;
  final TextEditingController pt;
  _Par(this.en, String traducao) : pt = TextEditingController(text: traducao);
}

class _TextoParaLicaoPageState extends State<TextoParaLicaoPage> {
  final _titulo = TextEditingController();
  late final _texto = TextEditingController(text: widget.textoInicial);

  _Fase _fase = _Fase.entrada;
  late TextoDividido _dividido = dividirEmFrases(widget.textoInicial);
  int _feitas = 0;
  String? _erro;
  bool _erroDeCota = false;
  List<_Par> _pares = [];

  @override
  void dispose() {
    _titulo.dispose();
    _texto.dispose();
    for (final p in _pares) {
      p.pt.dispose();
    }
    super.dispose();
  }

  Future<void> _traduzir() async {
    final frases = _dividido.frases;
    if (frases.isEmpty) return;
    setState(() {
      _fase = _Fase.traduzindo;
      _feitas = 0;
      _erro = null;
    });
    try {
      final pt = await widget.tradutor.traduzir(frases, aoProgredir: (f, _) {
        if (mounted) setState(() => _feitas = f);
      });
      if (!mounted) return;
      for (final p in _pares) {
        p.pt.dispose();
      }
      setState(() {
        _pares = [for (var i = 0; i < frases.length; i++) _Par(frases[i], pt[i])];
        _fase = _Fase.revisao;
      });
    } on TraducaoFalhou catch (e) {
      if (mounted) {
        setState(() {
          _fase = _Fase.entrada;
          _erro = e.mensagem;
          _erroDeCota = e.cota;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _fase = _Fase.entrada;
          _erro = 'A tradução não deu certo. Tente de novo daqui a pouco.';
          _erroDeCota = false;
        });
      }
    }
  }

  bool get _tudoTraduzido => _pares.isNotEmpty && _pares.every((p) => p.pt.text.trim().isNotEmpty);

  int get _qtdLicoes => repartirEmLicoes(_pares).length;

  void _criar() {
    if (!_tudoTraduzido) return;
    final frases = [for (final p in _pares) FraseDoTexto(p.en, p.pt.text.trim())];
    var titulo = _titulo.text.trim();
    if (titulo.isEmpty) titulo = tituloDaPrimeiraFrase([for (final f in frases) f.en]);
    Navigator.of(context).pop(TextoSalvo(
      id: TextoSalvo.novoId(),
      titulo: titulo,
      criadoEm: DateTime.now(),
      frases: frases,
    ));
  }

  void _tirar(_Par p) {
    setState(() => _pares.remove(p));
    // o campo ainda está na árvore até o fim do quadro
    WidgetsBinding.instance.addPostFrameCallback((_) => p.pt.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      appBar: AppBar(
        backgroundColor: Mixart.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
        ),
        title: Text('Lição com o seu texto', style: Mixart.display(size: 17)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: switch (_fase) {
              _Fase.entrada => _entrada(),
              _Fase.traduzindo => _traduzindo(),
              _Fase.revisao => _revisao(),
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- entrada

  InputDecoration _campo(String dica) => InputDecoration(
        hintText: dica,
        hintStyle: Mixart.ui(size: 13.5, color: Mixart.textFaint),
        filled: true,
        fillColor: Mixart.surface,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          borderSide: BorderSide(color: Mixart.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          borderSide: BorderSide(color: Mixart.brand, width: 1.4),
        ),
      );

  Widget _entrada() {
    final n = _dividido.frases.length;
    final licoes = repartirEmLicoes(_dividido.frases).length;
    return ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 40), children: [
      Text(
        'Cole um texto em inglês — uma notícia, um e-mail, a letra de uma música. Eu separo em frases, '
        'traduzo para o português e monto as lições: você digita cada frase como no resto do curso.',
        style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.55),
      ),
      const SizedBox(height: 16),
      TextField(
        key: const Key('titulo-texto'),
        controller: _titulo,
        maxLength: 40,
        style: Mixart.ui(size: 14, color: Mixart.text),
        decoration: _campo('Título (se deixar em branco, uso o começo do texto)'),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('texto-colado'),
        controller: _texto,
        minLines: 9,
        maxLines: 16,
        keyboardType: TextInputType.multiline,
        onChanged: (v) => setState(() {
          _dividido = dividirEmFrases(v);
          _erro = null;
        }),
        style: Mixart.ui(size: 14, color: Mixart.text).copyWith(height: 1.5),
        decoration: _campo('Cole aqui o texto em inglês…'),
      ),
      const SizedBox(height: 12),
      if (n > 0)
        Text(
          '$n ${n == 1 ? 'frase' : 'frases'} · $licoes ${licoes == 1 ? 'lição' : 'lições'}',
          key: const Key('contagem'),
          style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.brand),
        ),
      if (_dividido.cortado)
        _aviso('O texto tem ${_dividido.total} frases; vou usar só as primeiras $maxFrasesPorTexto. '
            'Para o resto, crie outra lição com o final do texto.'),
      if (_dividido.partidas > 0)
        _aviso(
            '${_dividido.partidas} ${_dividido.partidas == 1 ? 'frase comprida foi dividida' : 'frases compridas foram divididas'} '
            'em pedaços curtos, cada um com uma ideia inteira, para os exercícios ficarem rápidos. '
            'Você confere os pedaços e as traduções na próxima tela.',
            chave: const Key('aviso-divididas')),
      if (_dividido.simplificou)
        _aviso('Troquei aspas curvas, travessões e letras acentuadas por sinais simples (café → cafe) '
            'para dar para digitar no teclado.'),
      if (_erro != null)
        Container(
          key: const Key('erro-traducao'),
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Mixart.danger.withValues(alpha: .10),
            border: Border.all(color: Mixart.danger.withValues(alpha: .5)),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Text(_erro!, style: Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.45)),
        ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(
          key: const Key('botao-traduzir'),
          onPressed: n == 0 ? null : _traduzir,
          style: FilledButton.styleFrom(
            backgroundColor: Mixart.brand,
            foregroundColor: Mixart.onBrand,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          ),
          child: Text(_erroDeCota && _erro != null ? 'Tentar de novo' : 'Traduzir e revisar',
              style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.onBrand)),
        ),
      ),
      const SizedBox(height: 18),
      Text(
        'A tradução é automática (MyMemory, serviço gratuito com limite diário): você revisa e corrige antes de '
        'criar a lição. A voz é a do próprio aparelho — texto seu não tem gravação de falante nativo.',
        style: Mixart.ui(size: 11.5, color: Mixart.textFaint).copyWith(height: 1.5),
      ),
    ]);
  }

  Widget _aviso(String t, {Key? chave}) => Padding(
        key: chave,
        padding: const EdgeInsets.only(top: 8),
        child: Text('ℹ️ $t', style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.45)),
      );

  // -------------------------------------------------------------- traduzindo

  Widget _traduzindo() {
    final total = _dividido.frases.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Traduzindo…', style: Mixart.display(size: 20)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            key: const Key('progresso-traducao'),
            value: total == 0 ? null : _feitas / total,
            color: Mixart.brand,
            backgroundColor: Mixart.border,
            minHeight: 6,
          ),
          const SizedBox(height: 12),
          Text('$_feitas de $total frases', style: Mixart.ui(size: 13, color: Mixart.textMuted)),
        ]),
      ),
    );
  }

  // ----------------------------------------------------------------- revisão

  Widget _revisao() {
    final n = _pares.length;
    final licoes = _qtdLicoes;
    return Column(children: [
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          itemCount: n + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Confira a tradução. Corrija o que ficou estranho — é ela que aparece em cima, '
                  'enquanto você digita o inglês. A lixeira tira uma frase da lição.',
                  style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.5),
                ),
              );
            }
            final p = _pares[i - 1];
            return Container(
              key: ValueKey(p),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
              decoration: BoxDecoration(
                color: Mixart.surface,
                border: Border.all(color: Mixart.border),
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.en, style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.text).copyWith(height: 1.4)),
                    const SizedBox(height: 6),
                    TextField(
                      key: Key('pt-${i - 1}'),
                      controller: p.pt,
                      minLines: 1,
                      maxLines: 4,
                      onChanged: (_) => setState(() {}),
                      style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.4),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        border: InputBorder.none,
                        hintText: 'Escreva a tradução',
                        hintStyle: Mixart.ui(size: 13, color: Mixart.danger),
                      ),
                    ),
                  ]),
                ),
                IconButton(
                  tooltip: 'Tirar esta frase',
                  onPressed: () => _tirar(p),
                  icon: Icon(Icons.delete_outline, size: 19, color: Mixart.textFaint),
                ),
              ]),
            );
          },
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        decoration: BoxDecoration(color: Mixart.bg, border: Border(top: BorderSide(color: Mixart.border))),
        child: Row(children: [
          TextButton(
            onPressed: () => setState(() => _fase = _Fase.entrada),
            child: Text('← Editar o texto', style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.textMuted)),
          ),
          const Spacer(),
          FilledButton(
            key: const Key('botao-criar'),
            onPressed: _tudoTraduzido ? _criar : null,
            style: FilledButton.styleFrom(
              backgroundColor: Mixart.brand,
              foregroundColor: Mixart.onBrand,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            ),
            child: Text(
              n == 0 ? 'Nenhuma frase' : 'Criar $licoes ${licoes == 1 ? 'lição' : 'lições'} · $n ${n == 1 ? 'frase' : 'frases'}',
              style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.onBrand),
            ),
          ),
        ]),
      ),
    ]);
  }
}
