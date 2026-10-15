// Gera a sequência exata da fila de uma lição de inglês (mesma FilaLicao do app) para o gravador do
// vídeo de apresentação: quem digita qual frase em qual degrau, com um erro de memória de propósito.
//   dart run tool/video_fila.dart <nFrases> <semente> <frasesCurtas: 0,1,3>
import 'dart:convert';
import 'dart:io';

import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/roteiro.dart';

void main(List<String> args) {
  final n = int.parse(args[0]);
  final semente = int.parse(args[1]);
  final curtas = args.length > 2 ? args[2].split(',').map(int.parse).toSet() : <int>{};
  final fila = FilaLicao(n, semente: semente);
  final passos = <Map<String, Object>>[];
  var errou = false;
  while (!fila.terminou && passos.length < 80) {
    final p = fila.atual!;
    final degrau = p.correcao ? 'correcao' : p.degrau.name;
    // o erro de propósito: a 1ª vez de memória (D4) de uma frase curta
    final erro = !errou && !p.correcao && p.degrau == Degrau.memoria && curtas.contains(p.frase);
    if (erro) errou = true;
    passos.add({'frase': p.frase, 'degrau': degrau, 'erro': erro});
    final r = p.modo == ModoFrase.ver ? null : (erro ? ResultadoRevisao.errou : ResultadoRevisao.acertou);
    fila.registrar(r);
  }
  stdout.writeln(jsonEncode(passos));
}
