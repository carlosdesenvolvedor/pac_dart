import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'escolha_voz.dart';

/// Fala em inglês direto no Web Speech (`speechSynthesis`), sem o
/// flutter_tts: espera a lista de vozes (no Chrome a 1ª chamada vem
/// vazia), SEMPRE marca `lang = en-US` (senão a 1ª frase pode sair na voz
/// portuguesa do sistema) e cancela antes de falar sem depender de evento
/// de fim (o "ouvir de novo" nunca é engolido).
const suportado = true;

web.SpeechSynthesisVoice? _voz;
bool _vozBuscada = false;

/// Referência forte à fala em curso (evita o coletor encerrar no meio) —
/// só é escrita, de propósito.
// ignore: unused_element
web.SpeechSynthesisUtterance? _corrente;
int _geracao = 0;

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
  if (g != _geracao) return; // outra fala já assumiu
  _s.cancel();
  final u = web.SpeechSynthesisUtterance(texto)
    ..lang = 'en-US'
    ..rate = velocidade;
  final voz = _voz;
  if (voz != null) u.voice = voz;
  u.onerror = ((web.SpeechSynthesisErrorEvent e) {
    // voz de rede que falhou: tenta outra na próxima fala
    if (e.error == 'network' || e.error == 'synthesis-failed') _voz = null;
  }).toJS;
  _corrente = u;
  _s.speak(u);
}

void parar() {
  _geracao++;
  try {
    _s.cancel();
  } catch (_) {}
  _corrente = null;
}

/// Nome da voz escolhida (para mostrar/depurar).
String? get vozAtual => _voz?.name;
