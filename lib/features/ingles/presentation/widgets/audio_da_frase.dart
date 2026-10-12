import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../data/audio_usuario.dart';
import '../../data/voz_ingles.dart';
import '../../domain/audio_usuario.dart';

/// O arquivo que a pessoa escolheu (nome e bytes) — null = cancelou.
typedef ArquivoEscolhido = ({String nome, Uint8List bytes});
typedef SeletorAudio = Future<ArquivoEscolhido?> Function();

/// O seletor de verdade: a janela de arquivos do sistema, só com os formatos de áudio.
Future<ArquivoEscolhido?> seletorDeAudioDoSistema() async {
  final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: FormatosAudio.extensoes);
  if (f == null) return null;
  return (nome: f.name, bytes: await f.readAsBytes());
}

/// O 🎧 ao lado do 🔊: abre a folha para anexar o SEU áudio à frase (como o
/// `[sound:…]` do Anki). Fica realçado quando a frase já tem áudio seu. Some quando
/// não há onde guardar (outro curso, teste sem Firebase).
class BotaoAudioDaFrase extends StatelessWidget {
  final String frase;

  /// Voz injetável (testes); no app, a de sempre.
  final VozIngles? voz;
  final SeletorAudio? seletor;

  /// Botão redondo pequeno, igual aos do cartão da tradução (🔊 🐢 💡 👁).
  final bool redondo;

  const BotaoAudioDaFrase({super.key, required this.frase, this.voz, this.seletor, this.redondo = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AudioUsuario.versao,
      builder: (context, _, _) {
        if (!AudioUsuario.disponivel) return const SizedBox.shrink();
        final tem = AudioUsuario.tem(frase);
        final dica = tem ? 'Seu áudio desta frase (toque para ouvir, trocar ou remover)' : 'Adicionar o seu áudio a esta frase';
        void abrir() => mostrarAudioDaFrase(context, frase, voz: voz, seletor: seletor);
        final icone = tem ? Icons.headphones_rounded : Icons.headphones_outlined;
        if (redondo) {
          return Tooltip(
            message: dica,
            child: Material(
              key: const Key('audio-da-frase'),
              color: tem ? Mixart.brand : Mixart.surfaceHi,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(color: tem ? Mixart.brand : Mixart.border),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: abrir,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(icone, size: 18, color: tem ? Mixart.onBrand : Mixart.brand),
                ),
              ),
            ),
          );
        }
        return IconButton(
          key: const Key('audio-da-frase'),
          tooltip: dica,
          onPressed: abrir,
          icon: Icon(icone, size: 21, color: tem ? Mixart.brand : Mixart.textMuted),
        );
      },
    );
  }
}

/// Abre a folha "Seu áudio desta frase".
Future<void> mostrarAudioDaFrase(BuildContext context, String frase, {VozIngles? voz, SeletorAudio? seletor}) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusLg))),
      builder: (_) => _Folha(frase: frase, voz: voz, seletor: seletor ?? seletorDeAudioDoSistema),
    );

class _Folha extends StatefulWidget {
  final String frase;
  final VozIngles? voz;
  final SeletorAudio seletor;
  const _Folha({required this.frase, required this.voz, required this.seletor});

  @override
  State<_Folha> createState() => _FolhaState();
}

class _FolhaState extends State<_Folha> {
  late final VozIngles _voz = widget.voz ?? VozIngles();
  bool _ocupado = false;
  String? _erro;
  String? _ok;

  @override
  void dispose() {
    _voz.parar();
    super.dispose();
  }

  Future<void> _escolher() async {
    setState(() {
      _ocupado = true;
      _erro = null;
      _ok = null;
    });
    String? erro;
    var enviou = false;
    try {
      final arquivo = await widget.seletor();
      if (arquivo != null) {
        erro = await AudioUsuario.adicionar(widget.frase, arquivo.bytes);
        enviou = erro == null;
      }
    } catch (_) {
      erro = 'Não consegui abrir o arquivo. Tente outro.';
    }
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _erro = erro;
      _ok = enviou ? 'Pronto! Este áudio passa a tocar nesta frase, em todas as telas.' : null;
    });
  }

  Future<void> _remover() async {
    setState(() {
      _ocupado = true;
      _erro = null;
      _ok = null;
    });
    final erro = await AudioUsuario.remover(widget.frase);
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _erro = erro;
      _ok = erro == null ? 'Removido: a frase volta à voz de antes.' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AudioUsuario.versao,
      builder: (context, _, _) {
        final info = AudioUsuario.infoDe(widget.frase);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Seu áudio desta frase', style: Mixart.display(size: 19)),
              const SizedBox(height: 6),
              Text(widget.frase, style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.brand).copyWith(height: 1.4)),
              const SizedBox(height: 12),
              if (info == null)
                Text(
                  'Hoje esta frase toca com a gravação do curso ou com a voz do aparelho. Envie um arquivo seu '
                  '(${FormatosAudio.extensoes.take(5).join(', ')}… até ${FormatosAudio.maxBytes ~/ 1024} KB) e ele passa a tocar '
                  'no lugar, do jeito que você enviou, em todas as telas.',
                  style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5),
                )
              else
                Text(
                  'Tocando o seu áudio: ${info.formato} · ${(info.tamanho / 1024).round()} KB.',
                  key: const Key('info-audio'),
                  style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5),
                ),
              if (_erro != null) ...[
                const SizedBox(height: 10),
                Text(_erro!, key: const Key('erro-audio'), style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.danger).copyWith(height: 1.45)),
              ],
              if (_ok != null) ...[
                const SizedBox(height: 10),
                Text(_ok!, key: const Key('ok-audio'), style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.brand)),
              ],
              const SizedBox(height: 14),
              Wrap(spacing: 10, runSpacing: 10, children: [
                if (info != null)
                  OutlinedButton.icon(
                    key: const Key('ouvir-meu-audio'),
                    onPressed: _ocupado ? null : () => unawaited(_voz.falar(widget.frase)),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Ouvir'),
                  ),
                FilledButton.icon(
                  key: const Key('escolher-audio'),
                  onPressed: _ocupado ? null : _escolher,
                  style: FilledButton.styleFrom(backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
                  icon: _ocupado
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file_rounded, size: 19),
                  label: Text(info == null ? 'Escolher arquivo de áudio' : 'Trocar o arquivo'),
                ),
                if (info != null)
                  TextButton(
                    key: const Key('remover-audio'),
                    onPressed: _ocupado ? null : _remover,
                    child: Text('Remover', style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.danger)),
                  ),
              ]),
            ]),
          ),
        );
      },
    );
  }
}
