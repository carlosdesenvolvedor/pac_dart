import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'escolha_voz.dart';

/// Fala em inglês no Android e no iOS: a gravação de nativo quando houver
/// ([tocar], mp3 do pacote de assets) e, senão, a voz do sistema (`flutter_tts`,
/// a melhor en-US instalada — mesma escolha de voz do navegador, [notaDaVoz]).
/// Mesmo contrato do `fala_web.dart`: [falar] e [tocar] só completam quando a fala
/// ACABA (ou outra a corta, ou falha). No desktop e nos testes da VM ficam
/// mudos ([suportado] = false) e nunca lançam.
final bool suportado = Platform.isAndroid || Platform.isIOS;

FlutterTts? _tts;
AudioPlayer? _player;
bool _vozEscolhida = false;
String? _vozNome;

/// Cada fala nova invalida as anteriores: quem chega tarde não toca nem atropela.
int _geracao = 0;
Completer<void>? _fim;

Completer<void> _novaVez() {
  _encerrarVez();
  return _fim = Completer<void>();
}

void _encerrarVez([Completer<void>? so]) {
  final f = so ?? _fim;
  if (f != null && !f.isCompleted) f.complete();
  if (identical(f, _fim)) _fim = null;
}

Future<FlutterTts> _sintetizador() async {
  final existente = _tts;
  if (existente != null) return existente;
  final tts = _tts = FlutterTts();
  try {
    await tts.setLanguage('en-US');
    await tts.awaitSpeakCompletion(true);
    if (Platform.isIOS) {
      // voz do curso toca mesmo com a chave de silêncio ligada e sem cortar o que já toca
      await tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
      );
    }
  } catch (_) {}
  return tts;
}

Future<void> _escolherVoz(FlutterTts tts) async {
  if (_vozEscolhida) return;
  _vozEscolhida = true;
  try {
    final melhor = await _melhorVoz(tts, 'en');
    if (melhor != null) {
      await tts.setVoice(melhor);
      _vozIngles = melhor;
      _vozNome = melhor['name'];
    }
  } catch (_) {}
}

/// A voz en-US escolhida (para voltar a ela depois de falar outro idioma).
Map<String, String>? _vozIngles;

/// As vozes já escolhidas dos outros idiomas; null = procurou e não há.
final Map<String, Map<String, String>?> _vozPorIdioma = {};

/// O idioma em que o sintetizador ficou (`en` = o normal).
String _idiomaAtual = 'en';

Future<List<Map<String, dynamic>>> _listaDeVozes(FlutterTts tts) async {
  final vozes = (await tts.getVoices as List?) ?? const [];
  return [for (final v in vozes) Map<String, dynamic>.from(v as Map)];
}

Future<Map<String, String>?> _melhorVoz(FlutterTts tts, String idioma) async {
  Map<String, String>? melhor;
  var nota = -1;
  for (final m in await _listaDeVozes(tts)) {
    final n = notaDaVoz('${m['name'] ?? ''}', '${m['locale'] ?? ''}', local: true, idioma: idioma);
    if (n > nota) {
      nota = n;
      melhor = {'name': '${m['name']}', 'locale': '${m['locale']}'};
    }
  }
  return melhor;
}

/// Volta o sintetizador ao en-US (e à voz escolhida) depois de falar outro idioma.
Future<void> _voltarAoIngles(FlutterTts tts) async {
  if (_idiomaAtual == 'en') return;
  _idiomaAtual = 'en';
  try {
    await tts.setLanguage('en-US');
    final voz = _vozIngles;
    if (voz != null) await tts.setVoice(voz);
  } catch (_) {}
}

/// `pt-BR` → `pt`.
String _idiomaDe(String lang) => lang.toLowerCase().replaceAll('_', '-').split('-').first;

/// [velocidade] vem na escala do Web Speech (1 = normal); no `flutter_tts` o normal é 0,5.
Future<void> falar(String texto, double velocidade) async {
  await falarEm(texto, velocidade, 'en-US');
}

/// Fala [texto] na voz do sistema no idioma [lang] (`en-US`, `pt-BR`…). Mesmo contrato do [falar]; outro
/// idioma troca o `setLanguage`/voz só para esta fala e volta ao en-US depois. false = sem voz desse
/// idioma no aparelho (ou plataforma sem TTS).
Future<bool> falarEm(String texto, double velocidade, String lang) async {
  if (!suportado) return false;
  final idioma = _idiomaDe(lang);
  final g = ++_geracao;
  final fim = _novaVez();
  FlutterTts? tts;
  try {
    await _player?.stop();
    tts = await _sintetizador();
    await tts.stop();
    await _escolherVoz(tts);
    if (idioma == 'en') {
      await _voltarAoIngles(tts);
    } else {
      if (!_vozPorIdioma.containsKey(idioma)) _vozPorIdioma[idioma] = await _melhorVoz(tts, idioma);
      final voz = _vozPorIdioma[idioma];
      if (voz == null) return false;
      if (g != _geracao) return true;
      _idiomaAtual = idioma;
      await tts.setLanguage(lang);
      await tts.setVoice(voz);
    }
    if (g != _geracao) return true; // outra fala já assumiu (e já encerrou esta vez)
    await tts.setSpeechRate((.5 * velocidade).clamp(.1, 1.0));
    await tts.speak(texto); // completa quando acaba (awaitSpeakCompletion)
    return true;
  } catch (_) {
    // sem voz instalada ou o sistema recusou: fica mudo
    return idioma == 'en';
  } finally {
    // a próxima fala (se não veio outra no meio) volta a ser em inglês
    if (tts != null && idioma != 'en' && g == _geracao) await _voltarAoIngles(tts);
    _encerrarVez(fim);
  }
}

/// Há voz instalada cujo idioma começa com [prefixo] (ex. `pt`)?
Future<bool> temVozEm(String prefixo) async {
  if (!suportado) return false;
  try {
    final p = prefixo.toLowerCase().replaceAll('_', '-');
    final vozes = await _listaDeVozes(await _sintetizador());
    return vozes.any((m) => '${m['locale'] ?? ''}'.toLowerCase().replaceAll('_', '-').startsWith(p));
  } catch (_) {
    return false;
  }
}

/// Silêncio de [ms]: no aparelho é só um timer (o player daqui não precisa do truque do navegador).
Future<bool> tocarSilencio(int ms) async {
  if (ms > 0) await Future<void>.delayed(Duration(milliseconds: ms));
  return true;
}

/// Os assets já vêm no pacote do app: nada a baixar.
void preaquecer(String asset) {}

/// Só o navegador sabe se a página está escondida; no aparelho o player toca em primeiro plano.
bool get oculto => false;

void parar() {
  if (!suportado) return;
  _geracao++;
  _encerrarVez();
  try {
    unawaited(_tts?.stop().catchError((Object _) => 0) ?? Future<void>.value());
    unawaited(_player?.stop().catchError((Object _) {}) ?? Future<void>.value());
  } catch (_) {}
}

/// Toca a gravação [asset] (chave completa do asset, ex. `assets/ingles/audio/x.mp3`)
/// na [velocidade] (1 = como foi gravada; a lenta estica mantendo o tom). false =
/// não tocou (arquivo faltando) e a voz sintética assume — mas não se outra fala já
/// tomou a vez. true só volta quando a gravação ACABA (ou foi interrompida).
Future<bool> tocar(String asset, double velocidade) {
  // o AssetSource já soma o prefixo `assets/`
  final chave = asset.startsWith('assets/') ? asset.substring(7) : asset;
  return _tocarFonte(AssetSource(chave), velocidade);
}

/// Toca o áudio que o ALUNO anexou ([bytes], no formato dele — [mime]). Mesmo
/// contrato do [tocar]: false = não tocou (formato que este aparelho não decodifica…)
/// e a voz padrão assume.
Future<bool> tocarBytes(Uint8List bytes, String mime, double velocidade) =>
    _tocarFonte(BytesSource(bytes, mimeType: mime), velocidade);

Future<bool> _tocarFonte(Source fonte, double velocidade) async {
  if (!suportado) return false;
  final g = ++_geracao;
  final fim = _novaVez();
  try {
    try {
      await _tts?.stop();
    } catch (_) {}
    final p = _player ??= AudioPlayer();
    await p.stop();
    await p.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, respectSilence: false).build(),
    );
    await p.setPlaybackRate(velocidade);
    final acabou = Completer<void>();
    final sub = p.onPlayerComplete.listen((_) {
      if (!acabou.isCompleted) acabou.complete();
    });
    try {
      await p.play(fonte);
      if (g != _geracao) return true;
      // rede de segurança: gravação nenhuma passa de 30 s
      await Future.any([acabou.future, fim.future, Future<void>.delayed(const Duration(seconds: 30))]);
    } finally {
      await sub.cancel();
    }
    return true;
  } catch (_) {
    final outra = g != _geracao;
    return outra;
  } finally {
    _encerrarVez(fim);
  }
}

/// Nome da voz escolhida (para mostrar/depurar).
String? get vozAtual => _vozNome;

/// Onde está a gravação tocando (s): o player daqui só responde assíncrono — a boca segue o relógio.
double? get posicaoGravacao => null;
