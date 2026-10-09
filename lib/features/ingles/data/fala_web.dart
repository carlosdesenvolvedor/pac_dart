import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'escolha_voz.dart';

/// Fala em inglês: a gravação de nativo quando houver ([tocar], um
/// `<audio>` só), senão direto no Web Speech (`speechSynthesis`), sem o
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

Future<List<web.SpeechSynthesisVoice>> _vozes() async {
  var lista = _s.getVoices().toDart;
  if (lista.isNotEmpty) return lista;
  final pronto = Completer<void>();
  _s.onvoiceschanged = ((web.Event _) {
    if (!pronto.isCompleted) pronto.complete();
  }).toJS;
  for (var i = 0; i < 12 && lista.isEmpty; i++) {
    await Future.any([pronto.future, Future<void>.delayed(const Duration(milliseconds: 250))]);
    lista = _s.getVoices().toDart;
  }
  return lista;
}

Future<void> falar(String texto, double velocidade) async {
  final g = ++_geracao;
  final fim = _novaVez();
  _pararGravacao();
  if (!_vozBuscada || _voz == null) {
    final lista = await _vozes();
    _vozBuscada = true;
    web.SpeechSynthesisVoice? melhor;
    var nota = -1;
    for (final v in lista) {
      final n = notaDaVoz(v.name, v.lang, local: v.localService);
      if (n > nota) {
        nota = n;
        melhor = v;
      }
    }
    _voz = melhor;
  }
  if (g != _geracao) return; // outra fala já assumiu (e já encerrou esta vez)
  _s.cancel();
  final u = web.SpeechSynthesisUtterance(texto)
    ..lang = 'en-US'
    ..rate = velocidade;
  final voz = _voz;
  if (voz != null) u.voice = voz;
  u.onerror = ((web.SpeechSynthesisErrorEvent e) {
    // voz de rede que falhou: tenta outra na próxima fala
    if (e.error == 'network' || e.error == 'synthesis-failed') _voz = null;
    _encerrarVez(fim);
  }).toJS;
  u.onend = ((web.Event _) => _encerrarVez(fim)).toJS;
  _corrente = u;
  _s.speak(u);
  await fim.future;
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

/// Toca a gravação [asset] (mp3 do Tatoeba) na [velocidade] (1 = como foi
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

/// Nome da voz escolhida (para mostrar/depurar).
String? get vozAtual => _voz?.name;
