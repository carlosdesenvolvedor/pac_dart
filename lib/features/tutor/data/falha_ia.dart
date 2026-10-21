import 'dart:async' show TimeoutException;

/// Por que a chamada à IA falhou (a tela escolhe a mensagem e o [IaCubit] decide se descansa).
/// [limitePessoal]: a PESSOA usou as falas do dia no Worker da Conversa (Claude) — não abre a janela
/// de descanso compartilhada (o Gemini segue livre para o resto); o roteador segura sozinho até o
/// `Retry-After`.
enum TipoFalhaIa { limite, limiteDiario, limitePessoal, ocupado, semRede, credencial, recusada, outro }

/// Erro tipado da IA. O `toString()` mantém `Gemini <status>: <detalhe>` (o
/// `TutorCubit._erroAmigavel` procura '429'/'403' nesse texto). Dart puro: não importa firebase_ai.
class FalhaIa implements Exception {
  final TipoFalhaIa tipo;
  final int? status;
  final String detalhe;
  const FalhaIa(this.tipo, {this.status, this.detalhe = ''});

  /// 429 → limite, ou limiteDiario quando [ehLimiteDiario] (corpo); 500/502/503/504 → ocupado;
  /// 401/403 → credencial; 400 cujo corpo tem "API key"/"API_KEY" → credencial; resto → outro.
  static TipoFalhaIa tipoDoStatus(int status, String corpo) => switch (status) {
        429 => ehLimiteDiario(corpo) ? TipoFalhaIa.limiteDiario : TipoFalhaIa.limite,
        500 || 502 || 503 || 504 => TipoFalhaIa.ocupado,
        401 || 403 => TipoFalhaIa.credencial,
        400 when corpo.contains('API key') || corpo.contains('API_KEY') => TipoFalhaIa.credencial,
        _ => TipoFalhaIa.outro,
      };

  static final _porDia = RegExp(r'per[ _]?day', caseSensitive: false);

  /// O corpo do 429 fala de cota POR DIA: "PerDay", "per day", "per_day" (sem caixa), ou um
  /// quotaId que termina em "PerDay".
  static bool ehLimiteDiario(String corpo) => _porDia.hasMatch(corpo);

  static final _statusGemini = RegExp(r'Gemini (\d{3}):');

  /// Qualquer erro → FalhaIa. FalhaIa → ela mesma; TimeoutException, ou mensagem com SocketException /
  /// ClientException / "Failed host lookup" / "XMLHttpRequest" / "Connection" → semRede; "429" /
  /// "RESOURCE_EXHAUSTED" / "quota" → limite (limiteDiario quando [ehLimiteDiario]); "503" / "UNAVAILABLE" /
  /// "overloaded" → ocupado; "blocked" / "SAFETY" → recusada; "API key" / "PERMISSION_DENIED" →
  /// credencial; senão outro.
  static FalhaIa de(Object erro) {
    if (erro is FalhaIa) return erro;
    final msg = '$erro';
    if (erro is TimeoutException) return FalhaIa(TipoFalhaIa.semRede, detalhe: msg);
    // o texto antigo do serviço REST ("Gemini 429: {corpo}") já diz o status
    final s = _statusGemini.firstMatch(msg);
    if (s != null) {
      final status = int.parse(s.group(1)!);
      final tipo = tipoDoStatus(status, msg);
      if (tipo != TipoFalhaIa.outro) return FalhaIa(tipo, status: status, detalhe: msg.substring(s.end).trim());
    }
    final baixo = msg.toLowerCase();
    TipoFalhaIa tipo;
    if (msg.contains('SocketException') ||
        msg.contains('ClientException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('XMLHttpRequest') ||
        msg.contains('Connection')) {
      tipo = TipoFalhaIa.semRede;
    } else if (msg.contains('429') || msg.contains('RESOURCE_EXHAUSTED') || baixo.contains('quota')) {
      tipo = ehLimiteDiario(msg) ? TipoFalhaIa.limiteDiario : TipoFalhaIa.limite;
    } else if (msg.contains('503') || msg.contains('UNAVAILABLE') || baixo.contains('overloaded')) {
      tipo = TipoFalhaIa.ocupado;
    } else if (msg.contains('API key') || msg.contains('PERMISSION_DENIED')) {
      // antes do "blocked": o 403 do referer diz "Requests from referer … are blocked."
      tipo = TipoFalhaIa.credencial;
    } else if (baixo.contains('blocked') || msg.contains('SAFETY')) {
      tipo = TipoFalhaIa.recusada;
    } else {
      tipo = TipoFalhaIa.outro;
    }
    return FalhaIa(tipo, detalhe: msg);
  }

  @override
  String toString() => status != null ? 'Gemini $status: $detalhe' : 'FalhaIa(${tipo.name}): $detalhe';
}
