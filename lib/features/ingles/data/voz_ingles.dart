import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/som/sons.dart';
import 'audio_nativo.dart';
import 'audio_usuario.dart';
import 'fala_stub.dart'
    if (dart.library.js_interop) 'fala_web.dart'
    if (dart.library.io) 'fala_nativo.dart' as fala;

/// Fala as frases do curso de inglês em inglês americano com a melhor voz
/// que o navegador tiver. Grátis e sem cota (Web Speech API): as vozes de
/// rede ("Microsoft … Online (Natural)" no Edge, "Google US English" no
/// Chrome) soam bem melhor que as locais. Frase com gravação de nativo
/// (Tatoeba, [AudioNativo]) toca o mp3 no lugar — nunca as duas vozes
/// juntas; se o mp3 falhar, a sintética assume. O áudio que o ALUNO anexou à
/// frase ([AudioUsuario]) vem na frente de tudo, no formato dele. Nunca lança:
/// plataforma sem TTS (testes na VM) só fica muda.
class VozIngles {
  /// Toca o áudio do aluno (injetável nos testes; no app, o `<audio>`/player de cada plataforma).
  final Future<bool> Function(Uint8List bytes, String mime, double velocidade)? tocarClipe;

  /// Cada fala nova invalida a anterior que ainda esperava o áudio baixar.
  int _vez = 0;

  VozIngles({this.tocarClipe});

  /// Velocidade normal e a lenta (🐢) no `rate` do Web Speech — abaixo de
  /// 0,7 as vozes neurais arrastam (dossiê 06 §A6).
  static const velocidadeNormal = .95;
  static const velocidadeLenta = .72;

  /// A gravação de nativo: 1 = como foi gravada; a lenta estica ~20%
  /// (abaixo disso a fala natural começa a soar arrastada).
  static const velocidadeGravada = 1.0;
  static const velocidadeGravadaLenta = .8;

  /// Pref: a voz automática (e o Enter) fala devagar. Pedido do dono: o
  /// padrão é a lenta.
  static const prefLenta = 'en_voz_lenta';
  static bool lentaPorPadrao = true;

  /// Lê a preferência salva (chamar uma vez ao abrir o palco).
  static Future<bool> carregarPreferencia() async {
    try {
      final p = await SharedPreferences.getInstance();
      lentaPorPadrao = p.getBool(prefLenta) ?? true;
    } catch (_) {}
    return lentaPorPadrao;
  }

  static Future<void> salvarPreferencia(bool lenta) async {
    lentaPorPadrao = lenta;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(prefLenta, lenta);
    } catch (_) {}
  }

  /// Fala [frase] por cima do que estiver tocando. [lenta] = 🐢; null = a
  /// velocidade padrão escolhida pelo aluno. Completa quando a fala ACABA
  /// (ou foi cortada por outra, ou falhou) — quem não precisa esperar só não
  /// dá `await`.
  Future<void> falar(String frase, {bool? lenta}) async {
    final minha = ++_vez;
    try {
      final devagar = lenta ?? lentaPorPadrao;
      // 1. o áudio que o aluno anexou à frase
      if (AudioUsuario.tem(frase)) {
        final meu = await AudioUsuario.clipeDe(frase);
        if (minha != _vez) return; // outra fala assumiu enquanto o áudio baixava
        if (meu != null &&
            await (tocarClipe ?? fala.tocarBytes)(meu.bytes, meu.mime, devagar ? velocidadeGravadaLenta : velocidadeGravada)) {
          return;
        }
      }
      final gravacao = AudioNativo.paraTocar(frase);
      if (gravacao != null &&
          await fala.tocar(gravacao, devagar ? velocidadeGravadaLenta : velocidadeGravada)) {
        return;
      }
      await fala.falar(frase, devagar ? velocidadeLenta : velocidadeNormal);
    } catch (_) {}
  }

  Future<void> parar() async {
    _vez++;
    try {
      fala.parar();
    } catch (_) {}
  }

  /// O navegador já deixa tocar sozinho (a página teve tecla/clique)? Antes
  /// do 1º gesto o `<audio>` e a voz sintética ficam mudos.
  bool get somLiberado => Sons.liberado;

  /// A frase tem gravação de nativo (toca o mp3, não a voz sintética)?
  static bool temVozNativa(String frase) => AudioNativo.daFrase(frase) != null;

  /// A voz em uso (null fora do navegador ou antes da 1ª fala).
  String? get vozAtual => fala.vozAtual;
}
