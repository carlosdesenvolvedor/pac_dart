/// Botão "rodar" do PAC·C#: abre o programa no SharpLab (sharplab.io) já no
/// modo **Run**, que compila e executa C# no servidor e mostra a saída.
///
/// O estado do SharpLab mora no hash da URL (lido no fonte do SharpLab:
/// `WebApp/app/features/persistent-state/handlers/url.ts`):
///
///     #v2:  +  LZString.compressToBase64(opções + '|' + código)
///
/// com opções `t:run` (alvo = rodar) e o código "pré-comprimido" — o único
/// passo obrigatório dessa pré-compressão é escapar `@` como `@@` (o resto é
/// um dicionário opcional de palavras que só encurta a URL).
library;

import 'programa_csharp.dart';

/// `LZString.compressToBase64` (lz-string 1.5.0), portado 1:1 — trabalha em
/// unidades UTF-16, igual ao JavaScript.
String lzCompressToBase64(String entrada) {
  const chaves = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
  final r = _comprimir(entrada, 6, (v) => chaves[v]);
  return switch (r.length % 4) {
    1 => '$r===',
    2 => '$r==',
    3 => '$r=',
    _ => r,
  };
}

String _comprimir(String s, int bitsPorChar, String Function(int) charDe) {
  final dicionario = <String, int>{};
  final aCriar = <String>{};
  var w = '';
  var aumentarEm = 2;
  var tamDic = 3;
  var numBits = 2;
  final dados = StringBuffer();
  var valDados = 0;
  var posDados = 0;

  void bit(int b) {
    valDados = (valDados << 1) | b;
    if (posDados == bitsPorChar - 1) {
      posDados = 0;
      dados.write(charDe(valDados));
      valDados = 0;
    } else {
      posDados++;
    }
  }

  void escreveBits(int valor, int quantos) {
    for (var i = 0; i < quantos; i++) {
      bit(valor & 1);
      valor >>= 1;
    }
  }

  void diminui() {
    aumentarEm--;
    if (aumentarEm == 0) {
      aumentarEm = 1 << numBits;
      numBits++;
    }
  }

  void emiteW() {
    if (aCriar.contains(w)) {
      final c = w.codeUnitAt(0);
      if (c < 256) {
        for (var i = 0; i < numBits; i++) {
          bit(0);
        }
        escreveBits(c, 8);
      } else {
        for (var i = 0; i < numBits; i++) {
          bit(i == 0 ? 1 : 0);
        }
        escreveBits(c, 16);
      }
      diminui();
      aCriar.remove(w);
    } else {
      escreveBits(dicionario[w]!, numBits);
    }
    diminui();
  }

  for (var ii = 0; ii < s.length; ii++) {
    final c = s[ii];
    if (!dicionario.containsKey(c)) {
      dicionario[c] = tamDic++;
      aCriar.add(c);
    }
    final wc = w + c;
    if (dicionario.containsKey(wc)) {
      w = wc;
    } else {
      emiteW();
      dicionario[wc] = tamDic++;
      w = c;
    }
  }
  if (w.isNotEmpty) emiteW();

  // fim do fluxo
  escreveBits(2, numBits);
  // descarrega o último caractere
  while (true) {
    valDados <<= 1;
    if (posDados == bitsPorChar - 1) {
      dados.write(charDe(valDados));
      break;
    }
    posDados++;
  }
  return dados.toString();
}

/// URL do SharpLab que abre [codigo] no modo Run. Para os trechos do curso,
/// monte o código com `programaCSharp(trechos, paraSharpLab: true)`.
String urlSharpLab(String codigo) {
  final precomprimido = codigo.replaceAll('@', '@@');
  return 'https://sharplab.io/#v2:${lzCompressToBase64('t:run|$precomprimido')}';
}

/// Usings de bibliotecas que o SharpLab NÃO tem (ele só roda a biblioteca
/// padrão do .NET). Programa que usa uma delas fica sem o botão "rodar".
final _usingsDeFora = RegExp(
    r'^\s*using\s+(static\s+)?(Microsoft\.(EntityFrameworkCore|AspNetCore|Extensions)|Dapper|Serilog|MediatR|'
    r'FluentValidation|ErrorOr|Mapster|Polly|Refit|Newtonsoft|Humanizer|Bogus|Spectre|StackExchange|'
    r'RabbitMQ|OpenTelemetry|Xunit|Moq|NSubstitute|Shouldly|BenchmarkDotNet|UnityEngine|Godot|Microsoft\.Xna|TMPro)\b',
    multiLine: true);

/// O programa dá para rodar no SharpLab? Só perfil console, sem bibliotecas
/// de fora e sem ler do teclado (o SharpLab não tem entrada).
bool rodaNoSharpLab(String programa, String perfil) =>
    (perfil.isEmpty || perfil == 'console') &&
    !_usingsDeFora.hasMatch(programa) &&
    !programa.contains('Console.ReadLine') &&
    !programa.contains('Console.ReadKey') &&
    !programa.contains('WebApplication') &&
    !programa.contains('Host.Create');

/// O trecho (com o contexto da lição) dá para rodar no SharpLab?
bool trechoRodaNoSharpLab(List<String> trechos, String perfil) =>
    temComandosCSharp(trechos) && rodaNoSharpLab(programaCSharp(trechos), perfil);
