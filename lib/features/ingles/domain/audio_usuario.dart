import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// O áudio que o ALUNO anexa a uma frase (como o `[sound:…]` do Anki): o arquivo
/// fica exatamente como foi enviado, no formato dele, e passa a tocar no lugar da
/// gravação do curso e da voz do aparelho.
class ClipeAudio extends Equatable {
  final Uint8List bytes;

  /// `audio/mpeg`, `audio/mp4`, `audio/wav`, `audio/ogg`, `audio/webm` ou `audio/flac`.
  final String mime;

  const ClipeAudio(this.bytes, this.mime);

  int get tamanho => bytes.length;

  @override
  List<Object?> get props => [bytes, mime];
}

/// O que se sabe de um clipe sem baixá-lo (o índice).
class InfoAudio extends Equatable {
  final String mime;
  final int tamanho;
  const InfoAudio(this.mime, this.tamanho);

  /// `mime|tamanho`.
  String codificar() => '$mime|$tamanho';

  static InfoAudio? decodificar(Object? bruto) {
    final p = '$bruto'.split('|');
    if (p.length != 2) return null;
    final n = int.tryParse(p[1]);
    if (!FormatosAudio.mimes.contains(p[0]) || n == null || n <= 0) return null;
    return InfoAudio(p[0], n);
  }

  /// "MP3", "M4A"… para mostrar.
  String get formato => FormatosAudio.rotulo(mime);

  @override
  List<Object?> get props => [mime, tamanho];
}

/// Os formatos aceitos e a conferência pelo CONTEÚDO do arquivo (a extensão sozinha
/// engana: um `.mp3` que na verdade é uma foto não toca).
abstract final class FormatosAudio {
  /// O máximo por frase: um documento do Firestore guarda até 1 MiB, e uma frase
  /// curta em mp3 de voz cabe com folga (~1 minuto a 96 kbps).
  static const maxBytes = 800 * 1024;

  static const extensoes = ['mp3', 'm4a', 'mp4', 'aac', 'wav', 'ogg', 'oga', 'opus', 'webm', 'flac'];

  static const mimes = ['audio/mpeg', 'audio/mp4', 'audio/wav', 'audio/ogg', 'audio/webm', 'audio/flac'];

  static String rotulo(String mime) => switch (mime) {
        'audio/mpeg' => 'MP3',
        'audio/mp4' => 'M4A',
        'audio/wav' => 'WAV',
        'audio/ogg' => 'OGG',
        'audio/webm' => 'WEBM',
        'audio/flac' => 'FLAC',
        _ => 'áudio',
      };

  /// O tipo do áudio pelos primeiros bytes; null = não é um áudio que a gente conheça.
  static String? detectar(Uint8List b) {
    if (b.length < 12) return null;
    bool tem(int de, String texto) {
      for (var i = 0; i < texto.length; i++) {
        if (b[de + i] != texto.codeUnitAt(i)) return false;
      }
      return true;
    }

    if (tem(0, 'ID3')) return 'audio/mpeg';
    if (b[0] == 0xFF && (b[1] & 0xE0) == 0xE0 && (b[1] & 0x06) != 0) return 'audio/mpeg'; // quadro MPEG sem tag
    if (tem(0, 'RIFF') && tem(8, 'WAVE')) return 'audio/wav';
    if (tem(0, 'OggS')) return 'audio/ogg';
    if (tem(0, 'fLaC')) return 'audio/flac';
    if (tem(4, 'ftyp')) return 'audio/mp4'; // m4a, mp4, aac em contêiner MP4
    if (b[0] == 0x1A && b[1] == 0x45 && b[2] == 0xDF && b[3] == 0xA3) return 'audio/webm';
    return null;
  }

  /// A mensagem (em português) do que há de errado com o arquivo, ou null se serve.
  static String? validar(Uint8List bytes) {
    if (bytes.isEmpty) return 'O arquivo está vazio.';
    if (bytes.length > maxBytes) {
      return 'O arquivo tem ${(bytes.length / 1024).round()} KB; o máximo é ${maxBytes ~/ 1024} KB '
          '(uma frase curta em MP3 cabe com folga).';
    }
    if (detectar(bytes) == null) {
      return 'Isso não parece um arquivo de áudio que eu consiga tocar '
          '(${extensoes.take(6).join(', ')}…). Confira o arquivo.';
    }
    return null;
  }
}
