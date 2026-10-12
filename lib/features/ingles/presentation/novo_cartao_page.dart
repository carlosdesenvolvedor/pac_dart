import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../data/audio_usuario.dart';
import '../data/tradutor.dart';
import '../domain/audio_usuario.dart';
import '../domain/cartoes_texto.dart';
import 'revisao_cubit.dart';
import 'widgets/audio_da_frase.dart';

/// "Novo cartão": a frente é a frase em INGLÊS, o verso a tradução em português
/// (como o "Adicionar" do Anki), com o áudio opcional. O cartão entra no baralho
/// "Meus cartões", já fica ligado o sentido inglês → português e vira lição para digitar.
/// Dá para criar vários seguidos sem sair.
class NovoCartaoPage extends StatefulWidget {
  final Tradutor tradutor;

  /// Seletor de arquivo injetável (testes).
  final SeletorAudio? seletor;

  const NovoCartaoPage({super.key, required this.tradutor, this.seletor});

  @override
  State<NovoCartaoPage> createState() => _NovoCartaoPageState();
}

class _NovoCartaoPageState extends State<NovoCartaoPage> {
  final _frente = TextEditingController();
  final _verso = TextEditingController();
  ArquivoEscolhido? _audio;
  bool _traduzindo = false;
  bool _criando = false;
  String? _erro;
  String? _aviso;
  String? _ok;
  int _criados = 0;

  @override
  void dispose() {
    _frente.dispose();
    _verso.dispose();
    super.dispose();
  }

  Future<void> _traduzir() async {
    final p = prepararCartao(_frente.text, 'x');
    if (p.cartao == null) {
      setState(() => _erro = p.erro);
      return;
    }
    setState(() {
      _traduzindo = true;
      _erro = null;
      _ok = null;
    });
    try {
      final r = await widget.tradutor.traduzir([p.cartao!.en]);
      if (mounted) _verso.text = r.single;
    } on TraducaoFalhou catch (e) {
      if (mounted) _erro = e.mensagem;
    } catch (_) {
      if (mounted) _erro = 'A tradução não deu certo. Escreva o verso você mesmo.';
    }
    if (mounted) setState(() => _traduzindo = false);
  }

  Future<void> _escolherAudio() async {
    setState(() => _erro = null);
    try {
      final a = await (widget.seletor ?? seletorDeAudioDoSistema)();
      if (a == null || !mounted) return;
      final erro = FormatosAudio.validar(a.bytes);
      setState(() {
        _audio = erro == null ? a : _audio;
        _erro = erro;
      });
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não consegui abrir o arquivo. Tente outro.');
    }
  }

  Future<void> _criar() async {
    final p = prepararCartao(_frente.text, _verso.text);
    final c = p.cartao;
    if (c == null) {
      setState(() {
        _erro = p.erro;
        _ok = null;
      });
      return;
    }
    final bloc = context.read<CursoBloc>();
    final revisao = RevisaoCubit.de(context);
    setState(() {
      _criando = true;
      _erro = null;
      _aviso = null;
      _ok = null;
    });
    final primeiraVez = !bloc.state.trilhas.any((t) => t.textoId == idCartoesAvulsos);
    bloc.add(CartaoAdicionado(c));
    // espera o cartão aparecer no baralho (o bloc grava antes de atualizar)
    try {
      await bloc.stream
          .firstWhere((s) => s.trilhas.any((t) =>
              t.textoId == idCartoesAvulsos &&
              // a mesma frente com outra caixa só troca o verso, mantendo a grafia da 1ª vez
              t.licoes.any((l) => l.trechos.any((x) => x.cod.toLowerCase() == c.en.toLowerCase() && x.dica == c.pt))))
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
    // o 1º cartão liga o inglês → português do baralho (depois a pessoa decide nos Baralhos)
    if (primeiraVez && revisao != null) {
      await revisao.mudarConfig(revisao.state.config.comReversos(['txt:$idCartoesAvulsos'], ligar: true));
    }
    String? avisoAudio;
    final arquivo = _audio;
    if (arquivo != null) {
      final erro = await AudioUsuario.adicionar(c.en, arquivo.bytes);
      if (erro != null) avisoAudio = 'O cartão foi criado, mas o áudio não ficou guardado: $erro';
    }
    if (!mounted) return;
    final total = bloc.state.trilhas
        .where((t) => t.textoId == idCartoesAvulsos)
        .fold<int>(0, (s, t) => s + t.licoes.fold<int>(0, (a, l) => a + l.trechos.length));
    setState(() {
      _criando = false;
      _criados++;
      _ok = 'Cartão criado! "$tituloCartoesAvulsos" tem $total ${total == 1 ? 'cartão' : 'cartões'}.';
      _aviso = [if (p.simplificou) 'Troquei letras acentuadas e aspas curvas da frente por sinais simples, para dar para digitar.', ?avisoAudio]
          .join(' ');
      _frente.clear();
      _verso.clear();
      _audio = null;
    });
  }

  InputDecoration _campo(String dica) => InputDecoration(
        hintText: dica,
        hintStyle: Mixart.ui(size: 13.5, color: Mixart.textFaint),
        filled: true,
        fillColor: Mixart.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.brand, width: 1.4)),
      );

  @override
  Widget build(BuildContext context) {
    final audio = _audio;
    return Scaffold(
      backgroundColor: Mixart.bg,
      appBar: AppBar(
        backgroundColor: Mixart.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(_criados),
          icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
        ),
        title: Text('Novo cartão', style: Mixart.display(size: 17)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 40), children: [
              Text(
                'Frente: a frase em inglês. Verso: a tradução em português. O cartão entra em "$tituloCartoesAvulsos", '
                'já aparece para virar (inglês → português) e vira lição para digitar.',
                style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.55),
              ),
              const SizedBox(height: 16),
              Text('FRENTE · INGLÊS', style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
              const SizedBox(height: 6),
              TextField(
                key: const Key('frente-novo'),
                controller: _frente,
                minLines: 2,
                maxLines: 4,
                style: Mixart.ui(size: 15, color: Mixart.text).copyWith(height: 1.45),
                decoration: _campo('Ex.: I would like a coffee, please.'),
              ),
              const SizedBox(height: 14),
              // Wrap, não Row: no celular estreito o botão desce para a linha de baixo em vez de estourar
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('VERSO · PORTUGUÊS', style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
                  TextButton.icon(
                    key: const Key('traduzir-novo'),
                    onPressed: _traduzindo || _criando ? null : _traduzir,
                    icon: _traduzindo
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.translate_rounded, size: 17, color: Mixart.brand),
                    label: Text('Traduzir para mim', style: Mixart.ui(size: 12.5, weight: FontWeight.w800, color: Mixart.brand)),
                  ),
                ],
              ),
              TextField(
                key: const Key('verso-novo'),
                controller: _verso,
                minLines: 2,
                maxLines: 4,
                style: Mixart.ui(size: 15, color: Mixart.text).copyWith(height: 1.45),
                decoration: _campo('Ex.: Eu gostaria de um café, por favor.'),
              ),
              const SizedBox(height: 14),
              if (AudioUsuario.disponivel) ...[
                Text('ÁUDIO · OPCIONAL', style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
                const SizedBox(height: 6),
                if (audio == null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('audio-novo'),
                      onPressed: _criando ? null : _escolherAudio,
                      icon: const Icon(Icons.headphones_outlined, size: 19),
                      label: const Text('Adicionar o meu áudio'),
                    ),
                  )
                else
                  Container(
                    key: const Key('audio-escolhido'),
                    padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                    decoration: BoxDecoration(
                      color: Mixart.brandSub,
                      border: Border.all(color: Mixart.brandDim),
                      borderRadius: BorderRadius.circular(Mixart.radiusMd),
                    ),
                    child: Row(children: [
                      Icon(Icons.headphones_rounded, size: 18, color: Mixart.brand),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${audio.nome} · ${FormatosAudio.rotulo(FormatosAudio.detectar(audio.bytes) ?? '')} · ${(audio.bytes.length / 1024).round()} KB',
                          style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.text),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        key: const Key('tirar-audio-novo'),
                        tooltip: 'Tirar o áudio',
                        onPressed: () => setState(() => _audio = null),
                        icon: Icon(Icons.close, size: 18, color: Mixart.textMuted),
                      ),
                    ]),
                  ),
                const SizedBox(height: 6),
                Text('Toca no lugar da voz do aparelho, no formato que você enviar.', style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
                const SizedBox(height: 14),
              ],
              if (_erro != null)
                Container(
                  key: const Key('erro-novo'),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Mixart.danger.withValues(alpha: .10),
                    border: Border.all(color: Mixart.danger.withValues(alpha: .5)),
                    borderRadius: BorderRadius.circular(Mixart.radiusMd),
                  ),
                  child: Text(_erro!, style: Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.45)),
                ),
              if (_ok != null) Text(_ok!, key: const Key('ok-novo'), style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.brand)),
              if (_aviso != null && _aviso!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('ℹ️ $_aviso', key: const Key('aviso-novo'), style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.45)),
                ),
              const SizedBox(height: 14),
              Row(children: [
                FilledButton(
                  key: const Key('criar-cartao'),
                  onPressed: _criando ? null : _criar,
                  style: FilledButton.styleFrom(
                    backgroundColor: Mixart.brand,
                    foregroundColor: Mixart.onBrand,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                  ),
                  child: _criando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Criar cartão', style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.onBrand)),
                ),
                const SizedBox(width: 12),
                if (_criados > 0)
                  TextButton(
                    key: const Key('concluir-novo'),
                    onPressed: () => Navigator.of(context).pop(_criados),
                    child: Text('Concluir', style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: Mixart.textMuted)),
                  ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
