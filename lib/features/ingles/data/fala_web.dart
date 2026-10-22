import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'escolha_voz.dart';
import 'voz_ingles.dart' show ordemVozesEnUs;

/// Fala em inglês: o mp3 da frase quando houver (voz do personagem ou gravação
/// de nativo — [tocar], um `<audio>` só), senão direto no Web Speech (`speechSynthesis`), sem o
/// flutter_tts: espera a lista de vozes (no Chrome a 1ª chamada vem
/// vazia), SEMPRE marca `lang = en-US` (senão a 1ª frase pode sair na voz
/// portuguesa do sistema) e cancela antes de falar sem depender de evento
/// de fim (o "ouvir de novo" nunca é engolido).
///
/// [falar] e [tocar] só completam quando a fala ACABA (ou é interrompida por
/// outra, ou falha): quem precisa esperar — o ensaio mental — espera; quem
/// não precisa só não dá `await`.
const suportado = true;

web.SpeechSynthesisVoice? _voz;
bool _vozBuscada = false;

/// Referência forte à fala em curso (evita o coletor encerrar no meio) —
/// só é escrita, de propósito.
// ignore: unused_element
web.SpeechSynthesisUtterance? _corrente;
int _geracao = 0;

/// O fim da fala em curso (sintética ou gravação). Uma fala nova, [parar] ou
/// o fim de verdade o completam — nunca fica alguém esperando para sempre.
Completer<void>? _fim;

/// Começa a vez de uma fala nova: a anterior conta como terminada.
Completer<void> _novaVez() {
  _encerrarVez();
  return _fim = Completer<void>();
}

void _encerrarVez([Completer<void>? so]) {
  final f = so ?? _fim;
  if (f != null && !f.isCompleted) f.complete();
  if (identical(f, _fim)) _fim = null;
}

web.SpeechSynthesis get _s => web.window.speechSynthesis;

/// Até quando não vale esperar as vozes de novo: a última espera de 3 s voltou sem nenhuma (navegador sem
/// Web Speech, comum no Linux). Um `voiceschanged` solta antes. Sem isso cada frase (e cada tradução do
/// player) esperaria 3 s em silêncio.
DateTime? _semVozesAte;

Future<List<web.SpeechSynthesisVoice>> _vozes() async {
  var lista = _s.getVoices().toDart;
  if (lista.isNotEmpty) return lista;
  final ate = _semVozesAte;
  if (ate != null && DateTime.now().isBefore(ate)) return lista;
  final pronto = Completer<void>();
  _s.onvoiceschanged = ((web.Event _) {
    _semVozesAte = null;
    if (!pronto.isCompleted) pronto.complete();
  }).toJS;
  for (var i = 0; i < 12 && lista.isEmpty; i++) {
    await Future.any([pronto.future, Future<void>.delayed(const Duration(milliseconds: 250))]);
    lista = _s.getVoices().toDart;
  }
  _semVozesAte = lista.isEmpty ? DateTime.now().add(const Duration(seconds: 30)) : null;
  return lista;
}

Future<void> falar(String texto, double velocidade) async {
  await falarEm(texto, velocidade, 'en-US');
}

/// As vozes já escolhidas dos outros idiomas (o inglês fica em [_voz]); null = procurou e não há.
final Map<String, web.SpeechSynthesisVoice?> _vozPorIdioma = {};

/// `pt-BR` → `pt`.
String _idiomaDe(String lang) => lang.toLowerCase().replaceAll('_', '-').split('-').first;

/// Fala [texto] no Web Speech no idioma [lang] (`en-US`, `pt-BR`…), com a melhor voz dele ([notaDaVoz]).
/// Mesmo contrato do [falar] (só completa quando acaba, é cortada ou falha). false = não há voz desse
/// idioma no navegador (só para os idiomas que não são o inglês — o inglês sempre tenta).
Future<bool> falarEm(String texto, double velocidade, String lang) => _falarEm(texto, velocidade, lang);

/// A voz de um personagem (história do English Turismo): `pitch = `[tom] (0,5–2) e a [variante]-ésima melhor
/// voz en-US pela [notaDaVoz] (0 = a melhor; variante além da lista = a melhor). Mesmo contrato do [falar].
Future<void> falarComPerfil(String texto, double velocidade, {double tom = 1, int variante = 0}) async {
  await _falarEm(texto, velocidade, 'en-US', tom: tom.clamp(.5, 2).toDouble(), variante: variante);
}

/// As vozes en-US do navegador da melhor para a pior ([notaDaVoz]; empate = a ordem do navegador, como em
/// [_melhorVoz]), sem as que não servem. null = ainda não montada (ou uma voz falhou e é preciso refazer).
List<web.SpeechSynthesisVoice>? _rankingEnUs;

List<web.SpeechSynthesisVoice> _ordenarEnUs(List<web.SpeechSynthesisVoice> lista) => [
      for (final i in ordemVozesEnUs([for (final v in lista) (v.name, v.lang, v.localService)])) lista[i],
    ];

/// A voz da [variante] (o [_voz] já escolhido para a 0 ou quando a lista não chega até ela).
Future<web.SpeechSynthesisVoice?> _vozDaVariante(int variante) async {
  if (variante <= 0) return _voz;
  var ranking = _rankingEnUs;
  if (ranking == null) {
    ranking = _ordenarEnUs(await _vozes());
    if (ranking.isNotEmpty) _rankingEnUs = ranking; // lista vazia = vozes ainda carregando: tenta de novo
  }
  return variante < ranking.length ? ranking[variante] : _voz;
}

/// [tom] null = sem `pitch` (a voz como o navegador fala: o caminho de sempre); com [tom], [variante]
/// escolhe a voz en-US ([falarComPerfil]).
Future<bool> _falarEm(String texto, double velocidade, String lang, {double? tom, int variante = 0}) async {
  final g = ++_geracao;
  final fim = _novaVez();
  _pararGravacao();
  final idioma = _idiomaDe(lang);
  final ingles = idioma == 'en';
  web.SpeechSynthesisVoice? voz;
  if (ingles) {
    if (!_vozBuscada || _voz == null) {
      final lista = await _vozes();
      _vozBuscada = true;
      _voz = _melhorVoz(lista, 'en');
    }
    voz = _voz;
    if (tom != null && variante > 0) voz = await _vozDaVariante(variante) ?? voz;
  } else {
    if (!_vozPorIdioma.containsKey(idioma)) {
      final lista = await _vozes();
      final melhor = _melhorVoz(lista, idioma);
      // lista vazia = as vozes ainda não carregaram: procura de novo na próxima
      if (lista.isNotEmpty) _vozPorIdioma[idioma] = melhor;
      voz = melhor;
    } else {
      voz = _vozPorIdioma[idioma];
    }
    if (voz == null) {
      if (g == _geracao) _encerrarVez(fim);
      return false;
    }
  }
  if (g != _geracao) return true; // outra fala já assumiu (e já encerrou esta vez)
  _s.cancel();
  final u = web.SpeechSynthesisUtterance(texto)
    ..lang = ingles ? 'en-US' : lang
    ..rate = velocidade;
  if (tom != null) u.pitch = tom;
  if (voz != null) u.voice = voz;
  u.onerror = ((web.SpeechSynthesisErrorEvent e) {
    // voz de rede que falhou: tenta outra na próxima fala
    if (e.error == 'network' || e.error == 'synthesis-failed') {
      if (ingles) {
        _voz = null;
        _rankingEnUs = null;
      } else {
        _vozPorIdioma.remove(idioma);
      }
    }
    _encerrarVez(fim);
  }).toJS;
  u.onend = ((web.Event _) => _encerrarVez(fim)).toJS;
  _corrente = u;
  _s.speak(u);
  await fim.future;
  return true;
}

web.SpeechSynthesisVoice? _melhorVoz(List<web.SpeechSynthesisVoice> lista, String idioma) {
  web.SpeechSynthesisVoice? melhor;
  var nota = -1;
  for (final v in lista) {
    final n = notaDaVoz(v.name, v.lang, local: v.localService, idioma: idioma);
    if (n > nota) {
      nota = n;
      melhor = v;
    }
  }
  return melhor;
}

/// Há voz no navegador cujo idioma começa com [prefixo] (ex. `pt`)?
Future<bool> temVozEm(String prefixo) async {
  try {
    final p = prefixo.toLowerCase().replaceAll('_', '-');
    return (await _vozes()).any((v) => v.lang.toLowerCase().replaceAll('_', '-').startsWith(p));
  } catch (_) {
    return false;
  }
}

void parar() {
  _geracao++;
  _encerrarVez();
  try {
    _s.cancel();
  } catch (_) {}
  _corrente = null;
  _pararGravacao();
}

/// O player das gravações (um só: tocar outra frase troca o `src`).
web.HTMLAudioElement? _audio;
String? _srcAtual;

void _pararGravacao() {
  try {
    _audio?.pause();
  } catch (_) {}
}

/// Toca o mp3 [asset] (voz do personagem ou gravação do Tatoeba) na [velocidade] (1 = como foi
/// gravada; a lenta estica sem engrossar a voz — `preservesPitch`). Cancela
/// a voz sintética e a gravação anterior; a mesma frase de novo recomeça do
/// zero. false = não tocou (arquivo faltando, navegador bloqueou) e a voz
/// sintética assume — mas não se outra fala já tomou a vez. true só volta
/// quando a gravação ACABA (ou foi interrompida).
Future<bool> tocar(String asset, double velocidade) async {
  final g = ++_geracao;
  final fim = _novaVez();
  try {
    _s.cancel();
  } catch (_) {}
  _corrente = null;
  try {
    final a = _audio ??= web.HTMLAudioElement()..preload = 'auto';
    a.pause();
    final src = ui_web.assetManager.getAssetUrl(asset);
    if (_srcAtual == src) {
      a.currentTime = 0;
    } else {
      _srcAtual = src;
      a.src = src;
    }
    // trocar o src recarrega e volta ao defaultPlaybackRate: os dois
    a
      ..preservesPitch = true
      ..defaultPlaybackRate = velocidade
      ..playbackRate = velocidade
      ..onended = ((web.Event _) => _encerrarVez(fim)).toJS
      ..onerror = ((web.Event _) => _encerrarVez(fim)).toJS;
    await a.play().toDart;
    await fim.future;
    return true;
  } catch (_) {
    _srcAtual = null; // a próxima tentativa recarrega
    final outra = g != _geracao;
    if (!outra) _encerrarVez(fim); // a sintética abre outra vez
    return outra;
  }
}

/// O endereço (`blob:`) do áudio do aluno em uso — liberado ao trocar de áudio.
String? _urlDoAluno;

/// Toca o áudio que o ALUNO anexou ([bytes], no formato dele — [mime]) pelo mesmo
/// `<audio>` das gravações. Mesmo contrato do [tocar]: false = não tocou (formato que
/// este navegador não decodifica…) e a voz padrão assume; true só volta quando acaba.
Future<bool> tocarBytes(Uint8List bytes, String mime, double velocidade) async {
  final g = ++_geracao;
  final fim = _novaVez();
  try {
    _s.cancel();
  } catch (_) {}
  _corrente = null;
  try {
    final a = _audio ??= web.HTMLAudioElement()..preload = 'auto';
    a.pause();
    final url = web.URL.createObjectURL(web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime)));
    final antigo = _urlDoAluno;
    _urlDoAluno = url;
    _srcAtual = url;
    a
      ..src = url
      ..preservesPitch = true
      ..defaultPlaybackRate = velocidade
      ..playbackRate = velocidade
      ..onended = ((web.Event _) => _encerrarVez(fim)).toJS
      ..onerror = ((web.Event _) => _encerrarVez(fim)).toJS;
    if (antigo != null) web.URL.revokeObjectURL(antigo);
    await a.play().toDart;
    await fim.future;
    return true;
  } catch (_) {
    _srcAtual = null;
    final outra = g != _geracao;
    if (!outra) _encerrarVez(fim);
    return outra;
  }
}

/// Nome da voz escolhida (para mostrar/depurar).
String? get vozAtual => _voz?.name;

/// Onde está a gravação tocando (s, no tempo do arquivo), para a boca do personagem acompanhar o som de
/// verdade (o `<audio>` pode demorar a começar); null = nenhuma gravação tocando.
double? get posicaoGravacao {
  final a = _audio;
  if (a == null || a.paused || a.ended) return null;
  return a.currentTime.toDouble();
}

// ── "🎧 Ouvir" (FASE-8) ──────────────────────────────────────────────────

/// O silêncio tocado no `<audio>` (WAV 8 bits, 8 kHz, mono: 16 s = 128 KB), por "balde" — de 100 ms até
/// 2 s, de 500 ms acima disso (as pausas longas variam muito e ±250 ms não se nota). Guarda só os
/// [_maxSilencios] usados mais recentemente (a ordem do mapa = do uso mais antigo ao mais novo); o que sai
/// tem a URL (`blob:`) liberada — menos o que está no `<audio>` agora.
final Map<int, String> _silencios = {};

const _taxaSilencio = 8000;
const _maxSilencios = 24;

String _urlDoSilencio(int ms) {
  final m = ms.clamp(100, 16000);
  final balde = m <= 2000 ? (m + 50) ~/ 100 * 100 : ((m + 250) ~/ 500 * 500).clamp(2000, 16000);
  final ja = _silencios.remove(balde);
  if (ja != null) return _silencios[balde] = ja; // volta para o fim (o mais novo)
  final url = _wavDeSilencio(balde);
  _silencios[balde] = url;
  while (_silencios.length > _maxSilencios) {
    final velho = _silencios.entries.firstWhere((e) => e.value != _srcAtual, orElse: () => _silencios.entries.first);
    if (velho.value == _srcAtual) break; // (só sobrou o que está tocando)
    _silencios.remove(velho.key);
    try {
      web.URL.revokeObjectURL(velho.value);
    } catch (_) {}
  }
  return url;
}

String _wavDeSilencio(int ms) {
  final dados = ms * _taxaSilencio ~/ 1000; // 1 byte por amostra
  final b = ByteData(44 + dados);
  void texto(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  texto(0, 'RIFF');
  b.setUint32(4, 36 + dados, Endian.little);
  texto(8, 'WAVE');
  texto(12, 'fmt ');
  b.setUint32(16, 16, Endian.little); // tamanho do bloco fmt
  b.setUint16(20, 1, Endian.little); // PCM
  b.setUint16(22, 1, Endian.little); // mono
  b.setUint32(24, _taxaSilencio, Endian.little);
  b.setUint32(28, _taxaSilencio, Endian.little); // bytes por segundo
  b.setUint16(32, 1, Endian.little); // bytes por amostra
  b.setUint16(34, 8, Endian.little); // bits
  texto(36, 'data');
  b.setUint32(40, dados, Endian.little);
  final bytes = b.buffer.asUint8List();
  bytes.fillRange(44, 44 + dados, 0x80); // PCM de 8 bits é sem sinal: o silêncio é o meio (128)
  return web.URL.createObjectURL(web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'audio/wav')));
}

/// Toca [ms] de silêncio (até 16 s) no mesmo `<audio>` das gravações — a aba continua "tocando som", e o
/// próximo passo vem do `ended`, não de um timer que o navegador congela em segundo plano. Mesmo contrato
/// do [tocar]: uma fala nova ou [parar] cortam; true quando acaba (ou foi cortado). Se o navegador recusar
/// tocar, espera [ms] num timer (cortável do mesmo jeito) e devolve false.
Future<bool> tocarSilencio(int ms) async {
  if (ms <= 0) return true;
  final g = ++_geracao;
  final fim = _novaVez();
  try {
    _s.cancel();
  } catch (_) {}
  _corrente = null;
  try {
    final a = _audio ??= web.HTMLAudioElement()..preload = 'auto';
    a.pause();
    final url = _urlDoSilencio(ms);
    if (_srcAtual == url) {
      a.currentTime = 0;
    } else {
      _srcAtual = url;
      a.src = url;
    }
    a
      ..defaultPlaybackRate = 1
      ..playbackRate = 1
      ..onended = ((web.Event _) => _encerrarVez(fim)).toJS
      ..onerror = ((web.Event _) => _encerrarVez(fim)).toJS;
    await a.play().toDart;
    await fim.future;
    return true;
  } catch (_) {
    _srcAtual = null;
    if (g != _geracao) return true;
    await Future.any([fim.future, Future<void>.delayed(Duration(milliseconds: ms))]);
    if (g == _geracao) _encerrarVez(fim);
    return false;
  }
}

/// Os assets que já pedimos ao servidor (não pede duas vezes).
final Set<String> _preaquecidos = {};

/// Começa a baixar o áudio [asset] sem tocar (o cache do navegador entrega rápido quando a vez dele
/// chegar). Fogo e esquece; nunca lança.
void preaquecer(String asset) {
  if (!_preaquecidos.add(asset)) return;
  if (_preaquecidos.length > 400) _preaquecidos.clear();
  try {
    final url = ui_web.assetManager.getAssetUrl(asset);
    web.window.fetch(url.toJS).toDart.then((_) {}, onError: (Object _) {
      _preaquecidos.remove(asset);
    });
  } catch (_) {}
}

/// A página está escondida (aba em segundo plano / tela apagada)?
bool get oculto {
  try {
    return web.document.visibilityState == 'hidden';
  } catch (_) {
    return false;
  }
}
