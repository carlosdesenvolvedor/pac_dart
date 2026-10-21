import 'dart:async';

import '../domain/saida_audio.dart';
import 'audio_nativo.dart';
import 'audio_usuario.dart';
import 'voz_ingles.dart';

/// A saída de áudio do "🎧 Ouvir" no app: os mp3 do curso / áudio do aluno / Web Speech via [VozIngles]
/// (o português, pela voz pt-BR do sistema; o silêncio, tocado no mesmo `<audio>`).
class SaidaVozIngles implements SaidaDeAudio, SaidaComAudioDoAluno {
  final VozIngles voz;

  SaidaVozIngles({VozIngles? voz}) : voz = voz ?? VozIngles();

  @override
  Future<FimDaFala> en(String texto, {required double fator}) => voz.falarNoPlayer(texto, fator: fator);

  @override
  Future<FimDaFala> pt(String texto, {required double fator}) => voz.falarPt(texto, fator: fator);

  @override
  Future<FimDaFala> silencio(Duration d) => voz.silencio(d);

  @override
  void parar() => unawaited(voz.parar());

  @override
  void preaquecer(String texto) => VozIngles.preaquecer(texto);

  @override
  bool get somLiberado => voz.somLiberado;

  @override
  double duracaoDe(String en) => VozIngles.duracaoDe(en);

  /// Toca um áudio de verdade (mp3 do curso ou o que o aluno anexou), não a voz sintética.
  @override
  bool temGravacao(String en) => AudioNativo.paraTocar(en) != null || AudioUsuario.tem(en);

  @override
  bool temAudioDoAluno(String en) => AudioUsuario.tem(en);
}
