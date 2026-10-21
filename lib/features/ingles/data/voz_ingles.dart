import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/som/sons.dart';
import '../domain/boca.dart';
import '../domain/saida_audio.dart';
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

  /// Falas DESTA instância ainda soando (ou esperando o áudio): com zero, o [parar] não corta as outras
  /// vozes do app — a página que fecha sem ter falado nada não pausa o player do "🎧 Ouvir" (FASE-8).
  int _emCurso = 0;

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
    final g = ++_vezGlobal;
    final devagar = lenta ?? lentaPorPadrao;
    _emCurso++;
    try {
      await _falar(
        frase,
        minha,
        vGravada: devagar ? velocidadeGravadaLenta : velocidadeGravada,
        vSintetica: devagar ? velocidadeLenta : velocidadeNormal,
        segPalavra: devagar ? segPorPalavraLenta : segPorPalavra,
      );
    } finally {
      _emCurso--;
      _fecharBoca(minha, g);
    }
  }

  /// Acabou (ou foi cortada por outra, que já se anunciou): a boca fecha — mas só se ninguém do app
  /// falou depois ([vezGlobal]) ou se o que está anunciado ainda é a fala DESTA instância. Assim o player
  /// cortado não fecha a boca de quem o cortou (FASE-8).
  void _fecharBoca(int minha, int g) {
    if (minha != _vez) return;
    if (g == _vezGlobal || (falando.value != null && identical(falando.value, _meuAnuncio))) falando.value = null;
  }

  /// O último [FalaEmCurso] que esta instância anunciou.
  FalaEmCurso? _meuAnuncio;

  void _anuncia(String frase, TrilhaBoca boca, {double velocidade = 1, bool gravacao = false}) {
    falando.value = _meuAnuncio = FalaEmCurso(
      frase: frase,
      boca: boca,
      inicio: DateTime.now(),
      velocidade: velocidade,
      gravacao: gravacao,
    );
  }

  /// [vGravada] = `rate` do mp3/áudio do aluno; [vSintetica] = `rate` do Web Speech; [segPalavra] = a boca
  /// estimada pelo texto (o áudio do aluno e o mp3 sem boca gerada usam 80% dela).
  Future<void> _falar(
    String frase,
    int minha, {
    required double vGravada,
    required double vSintetica,
    required double segPalavra,
  }) async {
    try {
      // 1. o áudio que o aluno anexou à frase
      if (AudioUsuario.tem(frase)) {
        final meu = await AudioUsuario.clipeDe(frase);
        if (minha != _vez) return; // outra fala assumiu enquanto o áudio baixava
        if (meu != null) {
          // o áudio do aluno não tem boca gerada: segue o texto
          _anuncia(frase, TrilhaBoca.doTexto(frase, segPorPalavra: segPalavra * .8));
          if (await (tocarClipe ?? fala.tocarBytes)(meu.bytes, meu.mime, vGravada)) {
            return;
          }
        }
      }
      final gravacao = AudioNativo.paraTocar(frase);
      if (gravacao != null) {
        final boca = BocasIngles.de(gravacao);
        _anuncia(
          frase,
          boca ?? TrilhaBoca.doTexto(frase, segPorPalavra: segPalavra * .8),
          velocidade: vGravada,
          gravacao: boca != null,
        );
        if (await fala.tocar(gravacao, vGravada)) return;
        if (minha != _vez) return;
      }
      _anuncia(frase, TrilhaBoca.doTexto(frase, segPorPalavra: segPalavra));
      await fala.falar(frase, vSintetica);
    } catch (_) {}
  }

  /// Cala o que ESTA instância está falando. Sem fala dela em curso não mexe em nada das outras vozes
  /// (nem no player do "🎧 Ouvir"): fechar uma página que não falou nada não corta ninguém.
  Future<void> parar() async {
    _vez++;
    if (_emCurso == 0) return;
    _calarGlobal();
  }

  /// Cala QUALQUER voz do app, desta instância ou não (o player também) — o microfone abrindo: senão o
  /// reconhecedor ouve o próprio app.
  Future<void> calarTudo() async {
    _calarGlobal();
    await parar();
  }

  void _calarGlobal() {
    _vezGlobal++;
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

  // ── "🎧 Ouvir" (FASE-8) ──────────────────────────────────────────────────

  /// Contador de falas de TODAS as instâncias (a `_vez` é de cada uma): o player sabe se outra voz do
  /// app o cortou. Sobe já no começo de [falar], [falarNoPlayer], [falarPt], [silencio] e no [parar] que
  /// cala uma fala de verdade.
  static int _vezGlobal = 0;
  static int get vezGlobal => _vezGlobal;
  /// O maior pedaço de silêncio tocado de uma vez no `<audio>` (os mais longos vão em pedaços).
  static const _silencioMaxMs = 16000;

  /// Fala do player: ignora [lentaPorPadrao]; mp3 e áudio do aluno a `rate = fator`, Web Speech a
  /// `clamp(.95 * fator, .6, 1.2)`. [FimDaFala.cortada] = outra fala do app (ou um [parar]) entrou no meio.
  Future<FimDaFala> falarNoPlayer(String frase, {required double fator}) async {
    final minha = ++_vez;
    final g = ++_vezGlobal;
    final f = fator <= 0 ? 1.0 : fator;
    _emCurso++;
    try {
      await _falar(
        frase,
        minha,
        vGravada: f,
        vSintetica: (velocidadeNormal * f).clamp(.6, 1.2).toDouble(),
        segPalavra: segPorPalavra / f,
      );
    } finally {
      _emCurso--;
      _fecharBoca(minha, g);
    }
    return g == _vezGlobal ? FimDaFala.acabou : FimDaFala.cortada;
  }

  /// A tradução na voz pt-BR do sistema (sem boca); sem voz pt-BR → [FimDaFala.semVoz].
  Future<FimDaFala> falarPt(String texto, {double fator = 1}) async {
    final g = ++_vezGlobal;
    _vez++; // uma fala desta instância que ainda esperava o áudio não toca mais por cima
    falando.value = null; // a voz do sistema corta o que estiver soando: nenhuma boca segue mexendo
    var falou = false;
    _emCurso++;
    try {
      falou = await fala.falarEm(texto, (velocidadeNormal * fator).clamp(.6, 1.2).toDouble(), 'pt-BR');
    } catch (_) {
    } finally {
      _emCurso--;
    }
    if (g != _vezGlobal) return FimDaFala.cortada;
    return falou ? FimDaFala.acabou : FimDaFala.semVoz;
  }

  /// Silêncio de [d]. No navegador ele TOCA no mesmo `<audio>` (um WAV de zeros): a aba segue "tocando
  /// som" e os intervalos não dependem de timer; fora dele é um `Future.delayed`. Nunca anuncia boca.
  Future<FimDaFala> silencio(Duration d) async {
    final g = ++_vezGlobal;
    _emCurso++;
    try {
      if (kIsWeb) {
        falando.value = null; // o silêncio toma o `<audio>`: quem falava parou de verdade
        var resta = d.inMilliseconds;
        while (resta > 0 && g == _vezGlobal) {
          final ms = resta > _silencioMaxMs ? _silencioMaxMs : resta;
          await fala.tocarSilencio(ms);
          resta -= ms;
        }
      } else if (d > Duration.zero) {
        await Future<void>.delayed(d);
      }
    } catch (_) {
    } finally {
      _emCurso--;
    }
    return g == _vezGlobal ? FimDaFala.acabou : FimDaFala.cortada;
  }

  /// Segundos da fala a 1× (a última marca da boca do mp3, ou palavras × [segPorPalavra]).
  static double duracaoDe(String frase) {
    final pelaBoca = BocasIngles.duracaoDe(AudioNativo.paraTocar(frase));
    if (pelaBoca != null && pelaBoca > 0) return pelaBoca;
    return _palavras(frase) * segPorPalavra;
  }

  static int _palavras(String s) => s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).length;

  /// Começa a baixar o mp3 da frase (sem tocar). Nunca lança.
  static void preaquecer(String frase) {
    try {
      final asset = AudioNativo.paraTocar(frase);
      if (asset != null) fala.preaquecer(asset);
    } catch (_) {}
  }

  /// A página está escondida (aba em segundo plano / tela apagada)? Só o navegador sabe; fora dele, false.
  static bool get paginaOculta {
    try {
      return fala.oculto;
    } catch (_) {
      return false;
    }
  }

  static Future<bool>? _temVozPt;
  static DateTime? _semVozPtDesde;

  /// O navegador tem voz pt-BR para a tradução do player? Fora do navegador assume que sim (o aviso é só
  /// da web). O "sim" vale a sessão toda; o "não" é perguntado de novo depois de 10 s (as vozes podem
  /// carregar tarde, como no Chrome do Android). Nunca lança.
  static Future<bool> temVozPt() {
    if (!kIsWeb) return Future.value(true);
    final nao = _semVozPtDesde;
    if (nao != null && DateTime.now().difference(nao) > const Duration(seconds: 10)) {
      _temVozPt = null;
      _semVozPtDesde = null;
    }
    return _temVozPt ??= fala.temVozEm('pt').catchError((_) => false).then((tem) {
      if (!tem) _semVozPtDesde = DateTime.now();
      return tem;
    });
  }
}
