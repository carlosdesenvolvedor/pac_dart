import 'dart:async';
import 'dart:io';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'reconhecedor_fala.dart';

/// Reconhecimento de voz no Android (SpeechRecognizer) e no iOS (Speech): o
/// plugin `speech_to_text`. No desktop e nos testes da VM diz "não suportado".
ReconhecedorFala criarReconhecedor() => const _Nativo();

final _stt = SpeechToText();
bool _iniciado = false;

/// A escuta em curso (o plugin só aceita um ouvinte de erro/estado por app, então
/// ele repassa para a sessão da vez).
_Sessao? _atual;

class _Nativo extends ReconhecedorFala {
  const _Nativo();

  @override
  bool get suportado => Platform.isAndroid || Platform.isIOS;

  @override
  SessaoFala ouvir({
    String idioma = 'en-US',
    required void Function(String texto) aoParcial,
    required void Function(List<String> hipoteses) aoFinal,
    required void Function(ErroFala erro) aoErro,
    required void Function() aoFim,
  }) {
    if (!suportado) {
      // desktop / teste da VM: sem plugin, avisa e pronto
      scheduleMicrotask(() {
        aoErro(ErroFala.naoSuportado);
        aoFim();
      });
      return const _SessaoVazia();
    }
    _atual?.cancelar(); // uma escuta só: a anterior termina aqui
    final s = _Sessao(aoParcial: aoParcial, aoFinal: aoFinal, aoErro: aoErro, aoFim: aoFim);
    _atual = s;
    unawaited(s.iniciar(idioma));
    return s;
  }
}

class _SessaoVazia implements SessaoFala {
  const _SessaoVazia();
  @override
  void parar() {}
  @override
  void cancelar() {}
}

class _Sessao implements SessaoFala {
  final void Function(String) aoParcial;
  final void Function(List<String>) aoFinal;
  final void Function(ErroFala) aoErro;
  final void Function() aoFim;

  _Sessao({required this.aoParcial, required this.aoFinal, required this.aoErro, required this.aoFim});

  bool _terminou = false;
  bool _cancelada = false;
  bool _finalEntregue = false;
  bool _erroEntregue = false;
  String _ultimoParcial = '';

  Future<void> iniciar(String idioma) async {
    try {
      if (!_iniciado) {
        // a 1ª vez pede a permissão do microfone (e do reconhecimento, no iOS)
        _iniciado = await _stt.initialize(
          onError: (SpeechRecognitionError e) => _atual?._erro(e.errorMsg),
          onStatus: (String s) {
            if (s == 'done' || s == 'notListening') _atual?._fim();
          },
        );
      }
      if (_cancelada) return;
      if (!_iniciado) {
        _falhar(await _stt.hasPermission ? ErroFala.naoSuportado : ErroFala.semPermissao);
        return;
      }
      await _stt.listen(
        onResult: _resultado,
        listenOptions: SpeechListenOptions(
          localeId: await _localeDe(idioma),
          listenFor: const Duration(seconds: 25),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          listenMode: ListenMode.confirmation,
          cancelOnError: false,
        ),
      );
    } catch (_) {
      _falhar(ErroFala.outro);
    }
  }

  /// O plugin quer `en_US` (Android) ou `en-US` (iOS) conforme o aparelho: acha o
  /// que existe de inglês americano e, na falta, qualquer inglês.
  Future<String?> _localeDe(String idioma) async {
    try {
      final chave = idioma.toLowerCase().replaceAll('-', '_');
      final locais = await _stt.locales();
      for (final l in locais) {
        if (l.localeId.toLowerCase().replaceAll('-', '_') == chave) return l.localeId;
      }
      for (final l in locais) {
        if (l.localeId.toLowerCase().startsWith(chave.substring(0, 2))) return l.localeId;
      }
    } catch (_) {}
    return null; // o padrão do aparelho
  }

  void _resultado(SpeechRecognitionResult r) {
    if (_cancelada || _terminou) return;
    final hipoteses = <String>[];
    for (final a in r.alternates) {
      final t = a.recognizedWords.trim();
      if (t.isNotEmpty && !hipoteses.contains(t)) hipoteses.add(t);
    }
    if (r.finalResult && hipoteses.isNotEmpty) {
      _finalEntregue = true;
      aoFinal(hipoteses);
    } else if (r.recognizedWords.isNotEmpty) {
      _ultimoParcial = r.recognizedWords;
      aoParcial(r.recognizedWords);
    }
  }

  void _erro(String codigo) {
    if (_cancelada || _erroEntregue || _terminou) return;
    final erro = switch (codigo) {
      'error_permission' => ErroFala.semPermissao,
      'error_audio' || 'error_audio_error' => ErroFala.semMicrofone,
      'error_network' || 'error_network_timeout' || 'error_server' => ErroFala.semRede,
      'error_no_match' || 'error_speech_timeout' || 'error_no_speech' => ErroFala.naoOuviu,
      'error_language_not_supported' || 'error_language_unavailable' => ErroFala.naoSuportado,
      _ => ErroFala.outro,
    };
    _erroEntregue = true;
    aoErro(erro);
  }

  void _fim() {
    if (_terminou) return;
    _terminou = true;
    if (identical(_atual, this)) _atual = null;
    if (!_cancelada && !_finalEntregue && !_erroEntregue) {
      // o sistema fechou sem o "final": vale o último parcial
      if (_ultimoParcial.isNotEmpty) {
        _finalEntregue = true;
        aoFinal([_ultimoParcial]);
      } else {
        _erroEntregue = true;
        aoErro(ErroFala.naoOuviu);
      }
    }
    aoFim();
  }

  void _falhar(ErroFala erro) {
    if (_terminou) return;
    _terminou = true;
    if (identical(_atual, this)) _atual = null;
    _erroEntregue = true;
    aoErro(erro);
    aoFim();
  }

  @override
  void parar() {
    if (_terminou) return;
    unawaited(_stt.stop().catchError((Object _) {}));
    // o "done" do plugin fecha a conta; se não vier, a guarda fecha
    Timer(const Duration(seconds: 2), _fim);
  }

  @override
  void cancelar() {
    if (_terminou) return;
    _cancelada = true;
    unawaited(_stt.cancel().catchError((Object _) {}));
    _fim();
  }
}
