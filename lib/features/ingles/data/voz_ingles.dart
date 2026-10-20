import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/som/sons.dart';
import '../domain/boca.dart';
import 'audio_nativo.dart';
import 'audio_usuario.dart';
import 'bocas_ingles.dart';
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
/// A fala que está soando agora — os personagens mexem a boca com ela ([VozIngles.falando]).
class FalaEmCurso {
  final String frase;
  final TrilhaBoca boca;

  /// Quando a fala começou e a velocidade do áudio (1 = como foi gravado).
  final DateTime inicio;
  final double velocidade;

  /// Tocando um mp3 (a boca segue a posição dele quando a plataforma informa).
  final bool gravacao;

  FalaEmCurso({
    required this.frase,
    required this.boca,
    required this.inicio,
    this.velocidade = 1,
    this.gravacao = false,
  });

  /// O segundo da fala (no tempo da [boca]) em [agora].
  double segundo(DateTime agora) {
    if (gravacao) {
      final pos = fala.posicaoGravacao;
      if (pos != null) return pos;
    }
    final dt = agora.difference(inicio).inMicroseconds / 1e6;
    return gravacao ? dt * velocidade : dt;
  }

  /// A boca em [agora].
  Visema visema(DateTime agora) => boca.em(segundo(agora));
}

class VozIngles {
  /// O que está sendo falado agora (null = silêncio). Vale para todas as vozes do app.
  static final falando = ValueNotifier<FalaEmCurso?>(null);

  /// Quanto cada palavra dura na voz sintética (a boca dela é estimada pelo texto).
  static const segPorPalavraLenta = .46;
  static const segPorPalavra = .34;

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
    final devagar = lenta ?? lentaPorPadrao;
    try {
      await _falar(frase, devagar, minha);
    } finally {
      // acabou (ou foi cortada por outra, que já se anunciou): a boca fecha
      if (minha == _vez) falando.value = null;
    }
  }

  void _anuncia(String frase, TrilhaBoca boca, {double velocidade = 1, bool gravacao = false}) {
    falando.value = FalaEmCurso(
      frase: frase,
      boca: boca,
      inicio: DateTime.now(),
      velocidade: velocidade,
      gravacao: gravacao,
    );
  }

  TrilhaBoca _bocaDoTexto(String frase, bool devagar, {double fator = 1}) =>
      TrilhaBoca.doTexto(frase, segPorPalavra: (devagar ? segPorPalavraLenta : segPorPalavra) * fator);

  Future<void> _falar(String frase, bool devagar, int minha) async {
    try {
      // 1. o áudio que o aluno anexou à frase
      if (AudioUsuario.tem(frase)) {
        final meu = await AudioUsuario.clipeDe(frase);
        if (minha != _vez) return; // outra fala assumiu enquanto o áudio baixava
        if (meu != null) {
          // o áudio do aluno não tem boca gerada: segue o texto
          _anuncia(frase, _bocaDoTexto(frase, devagar, fator: .8));
          if (await (tocarClipe ?? fala.tocarBytes)(meu.bytes, meu.mime, devagar ? velocidadeGravadaLenta : velocidadeGravada)) {
            return;
          }
        }
      }
      final gravacao = AudioNativo.paraTocar(frase);
      if (gravacao != null) {
        final v = devagar ? velocidadeGravadaLenta : velocidadeGravada;
        final boca = BocasIngles.de(gravacao);
        _anuncia(frase, boca ?? _bocaDoTexto(frase, devagar, fator: .8), velocidade: v, gravacao: boca != null);
        if (await fala.tocar(gravacao, v)) return;
        if (minha != _vez) return;
      }
      _anuncia(frase, _bocaDoTexto(frase, devagar));
      await fala.falar(frase, devagar ? velocidadeLenta : velocidadeNormal);
    } catch (_) {}
  }

  Future<void> parar() async {
    _vez++;
    falando.value = null;
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
