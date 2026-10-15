import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'reconhecedor_fala.dart';

/// Reconhecimento de voz do navegador (Web Speech API): `SpeechRecognition`
/// ou, no Chrome/Safari, `webkitSpeechRecognition`. Uma escuta nova a cada
/// toque (reaproveitar o objeto é a receita do "já está ouvindo" no iOS).
ReconhecedorFala criarReconhecedor() => const _Navegador();

JSFunction? _construtor() {
  for (final nome in const ['SpeechRecognition', 'webkitSpeechRecognition']) {
    final v = globalContext.getProperty<JSAny?>(nome.toJS);
    if (v != null && v.isA<JSFunction>()) return v as JSFunction;
  }
  return null;
}

extension type _Evento._(JSObject _) implements JSObject {
  external _Lista get results;
  external String? get error;
}

extension type _Lista._(JSObject _) implements JSObject {
  external int get length;
  external _Resultado item(int i);
}

extension type _Resultado._(JSObject _) implements JSObject {
  external bool get isFinal;
  external int get length;
  external _Alternativa item(int i);
}

extension type _Alternativa._(JSObject _) implements JSObject {
  external String get transcript;
}

class _Navegador extends ReconhecedorFala {
  const _Navegador();

  @override
  bool get suportado => _construtor() != null;

  @override
  SessaoFala ouvir({
    String idioma = 'en-US',
    required void Function(String texto) aoParcial,
    required void Function(List<String> hipoteses) aoFinal,
    required void Function(ErroFala erro) aoErro,
    required void Function() aoFim,
  }) {
    final sessao = _Sessao(aoParcial: aoParcial, aoFinal: aoFinal, aoErro: aoErro, aoFim: aoFim);
    sessao.iniciar(idioma);
    return sessao;
  }
}

class _Sessao implements SessaoFala {
  final void Function(String) aoParcial;
  final void Function(List<String>) aoFinal;
  final void Function(ErroFala) aoErro;
  final void Function() aoFim;

  _Sessao({required this.aoParcial, required this.aoFinal, required this.aoErro, required this.aoFim});

  JSObject? _rec;
  Timer? _guarda;
  bool _cancelada = false;
  bool _terminou = false;
  bool _finalEntregue = false;
  bool _erroEntregue = false;
  String _ultimoParcial = '';

  /// O navegador chegou a abrir o microfone (`onaudiostart`/`onstart`). Se nunca abriu e a escuta acabou sem nada,
  /// é um navegador que "tem" a API mas não reconhece de verdade (o Chrome no iPhone): vale o 🎤 do teclado.
  bool _comecou = false;
  final _inicio = DateTime.now();

  /// Um navegador de verdade abre o microfone em décimos de segundo; passado isto sem nenhum sinal, é "sem suporte".
  static const _prazoParaAbrir = Duration(seconds: 3);

  /// Já pediram "parar" e o navegador ainda não fechou: um 2º `parar()` — ou [_esperaParar] — força o fim.
  bool _pediuParar = false;
  Timer? _forcaFim;

  /// Quanto esperar o `onend` depois do `stop()`: o Safari/Chrome do iPhone às vezes nunca manda.
  static const _esperaParar = Duration(milliseconds: 1500);

  /// Teto da escuta inteira (uma frase não leva isso).
  static const _tetoDaEscuta = Duration(seconds: 15);

  void iniciar(String idioma) {
    final ctor = _construtor();
    if (ctor == null) {
      _falhar(ErroFala.naoSuportado);
      return;
    }
    try {
      final r = ctor.callAsConstructor<JSObject>();
      _rec = r;
      r.setProperty('lang'.toJS, idioma.toJS);
      // uma frase só: o navegador fecha sozinho quando a pessoa para de falar
      r.setProperty('continuous'.toJS, false.toJS);
      r.setProperty('interimResults'.toJS, true.toJS);
      r.setProperty('maxAlternatives'.toJS, 5.toJS);
      r.setProperty('onstart'.toJS, ((JSObject _) => _comecou = true).toJS);
      r.setProperty('onaudiostart'.toJS, ((JSObject _) => _comecou = true).toJS);
      r.setProperty('onresult'.toJS, ((_Evento e) => _resultado(e)).toJS);
      r.setProperty('onerror'.toJS, ((_Evento e) => _erro(e.error ?? '')).toJS);
      r.setProperty('onend'.toJS, ((JSObject _) => _fim()).toJS);
      r.callMethod<JSAny?>('start'.toJS);
      // rede de segurança: sem fala nem erro o navegador pode nunca fechar
      _guarda = Timer(_tetoDaEscuta, parar);
    } catch (_) {
      _falhar(ErroFala.outro);
    }
  }

  void _resultado(_Evento e) {
    if (_cancelada) return;
    _comecou = true;
    try {
      final lista = e.results;
      final hipoteses = <String>[];
      var parcial = '';
      var final_ = false;
      for (var i = 0; i < lista.length; i++) {
        final r = lista.item(i);
        if (r.isFinal) {
          final_ = true;
          for (var k = 0; k < r.length; k++) {
            final t = r.item(k).transcript.trim();
            if (t.isNotEmpty && !hipoteses.contains(t)) hipoteses.add(t);
          }
        } else if (r.length > 0) {
          parcial = '$parcial ${r.item(0).transcript}'.trim();
        }
      }
      if (final_ && hipoteses.isNotEmpty) {
        _finalEntregue = true;
        aoFinal(hipoteses);
      } else if (parcial.isNotEmpty) {
        _ultimoParcial = parcial;
        aoParcial(parcial);
      }
    } catch (_) {
      // evento estranho: o onend fecha a conta
    }
  }

  void _erro(String codigo) {
    if (_cancelada || _erroEntregue) return;
    final erro = switch (codigo) {
      'not-allowed' || 'service-not-allowed' => ErroFala.semPermissao,
      'audio-capture' => ErroFala.semMicrofone,
      'network' => ErroFala.semRede,
      'no-speech' => ErroFala.naoOuviu,
      'aborted' => null, // foi a gente que parou
      'language-not-supported' || 'bad-grammar' => ErroFala.naoSuportado,
      _ => ErroFala.outro,
    };
    if (erro == null) return;
    _erroEntregue = true;
    aoErro(erro);
  }

  void _fim() {
    if (_terminou) return;
    _terminou = true;
    _guarda?.cancel();
    _forcaFim?.cancel();
    if (!_cancelada && !_finalEntregue && !_erroEntregue) {
      // alguns navegadores fecham sem o "final": vale o último parcial
      if (_ultimoParcial.isNotEmpty) {
        _finalEntregue = true;
        aoFinal([_ultimoParcial]);
      } else {
        _erroEntregue = true;
        // 3 s sem abrir o microfone: o navegador só finge que reconhece voz (Chrome no iPhone) ⇒ "use o 🎤 do teclado"
        final semSinal = !_comecou && DateTime.now().difference(_inicio) > _prazoParaAbrir;
        aoErro(semSinal ? ErroFala.naoSuportado : ErroFala.naoOuviu);
      }
    }
    aoFim();
  }

  void _falhar(ErroFala erro) {
    if (_terminou) return;
    scheduleMicrotask(() {
      if (_terminou) return;
      _terminou = true;
      _erroEntregue = true;
      aoErro(erro);
      aoFim();
    });
  }

  @override
  void parar() {
    if (_terminou) return;
    // 2º pedido de parar (a pessoa tocou de novo): o navegador não respondeu, fecha agora
    if (_pediuParar) {
      _forcarFim();
      return;
    }
    _pediuParar = true;
    try {
      _rec?.callMethod<JSAny?>('stop'.toJS);
    } catch (_) {
      _fim();
      return;
    }
    // o `stop()` deveria entregar o resultado e disparar `onend`; se o navegador nunca disparar, não fica "Ouvindo…" para sempre
    _forcaFim?.cancel();
    _forcaFim = Timer(_esperaParar, _forcarFim);
  }

  void _forcarFim() {
    if (_terminou) return;
    try {
      _rec?.callMethod<JSAny?>('abort'.toJS);
    } catch (_) {}
    _fim();
  }

  @override
  void cancelar() {
    if (_terminou) return;
    _cancelada = true;
    try {
      _rec?.callMethod<JSAny?>('abort'.toJS);
    } catch (_) {}
    // o onend de um abort nem sempre chega: fecha a conta já
    _fim();
  }
}
