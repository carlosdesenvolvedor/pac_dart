import 'dart:async' show TimeoutException;
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'falha_ia.dart';
import 'tutor_service.dart';

/// Uma falha que veio do Worker da Conversa (`workers/conversa-claude`): a [FalhaIa] de sempre (o
/// [IaCubit] decide a janela de descanso pelo [tipo]) mais o código do Worker, a mensagem em pt-BR que
/// ele mandou e o `Retry-After` — o [TutorConversaRoteador] decide por eles se o turno cai para o Gemini.
///
/// Os códigos e o [TipoFalhaIa] de cada um (ver [ClaudeTutorService.falhaDe]):
/// - `sem_chave`, `nao_autenticado`, `origem_negada`, `nao_encontrado` → credencial; `rede` → semRede
///   (os cinco caem para o Gemini e o Claude fica "fora" por 10 min);
/// - `pedido_invalido` → outro (só aquele turno cai para o Gemini: o Gemini não tem o teto do Worker);
/// - `limite_pessoal` → limitePessoal (NÃO cai: a pessoa usou as falas do dia; [retryAfter] = até a
///   meia-noite UTC; não abre a janela compartilhada — o roteador segura a Conversa até lá);
/// - `limite_geral` → limite. Com [retryAfter] longo (o teto do dia do Worker, até a meia-noite UTC) o
///   roteador manda o turno ao Gemini e deixa o Claude de lado até lá; curto/sem (429 da Anthropic) → a
///   janela de descanso que dobra;
/// - `ia_falhou` → ocupado (recusada quando o Worker diz que a IA "não quis responder"); `ia_demorou`
///   (também o tempo esgotado do lado do app) → ocupado. O turno volta ao campo e não gasta uso; seguidas
///   ([ehPane]) o roteador desiste do Claude por 10 min.
class FalhaClaude extends FalhaIa {
  /// O `erro` do Worker ('sem_chave', 'nao_autenticado', 'limite_pessoal', …), 'nao_encontrado' (404 sem
  /// corpo do Worker), 'rede' (DNS, conexão recusada, CORS; o tempo esgotado do lado do app é 'ia_demorou') ou
  /// `http_<status>` (resposta sem o corpo do Worker que não se encaixa em nenhum outro).
  final String codigo;

  /// A `mensagem` (pt-BR) do Worker; '' quando não veio.
  final String mensagem;

  /// O `Retry-After` do 429 (null quando não veio ou não é número).
  final Duration? retryAfter;

  const FalhaClaude(
    super.tipo, {
    required this.codigo,
    this.mensagem = '',
    this.retryAfter,
    super.status,
    super.detalhe,
  });

  /// Os códigos em que o Claude está "fora" (Worker não publicado, sem chave, sem sessão, origem barrada,
  /// rede): o turno cai para o Gemini uma vez e o roteador memoriza por [TutorConversaRoteador.foraPor].
  static const codigosQueCaemParaGemini = {'sem_chave', 'nao_autenticado', 'origem_negada', 'nao_encontrado', 'rede'};

  /// Os códigos em que SÓ aquele turno vai ao Gemini, sem deixar o Claude de lado: o pedido passou do
  /// teto do Worker (24 falas / 16.000 caracteres) ou ele o recusou — o Gemini não tem esse teto.
  static const codigosQueCaemSoNoTurno = {'pedido_invalido'};

  /// Este erro manda o turno para o Gemini (ver [codigosQueCaemParaGemini]).
  bool get caiParaGemini => codigosQueCaemParaGemini.contains(codigo);

  /// Este erro manda só este turno para o Gemini (ver [codigosQueCaemSoNoTurno]).
  bool get caiSoNoTurno => codigosQueCaemSoNoTurno.contains(codigo);

  /// Uma pane do lado da IA que, repetida, quer dizer "Claude fora" (chave revogada, sem crédito, teto
  /// de gastos, MODELO errado — o Worker devolve tudo como `ia_falhou`; página 5xx da Cloudflare; IA
  /// que só demora): `ia_falhou` (menos a recusa), `ia_demorou` e `http_5xx`. O roteador conta as
  /// seguidas e, em [TutorConversaRoteador.panesParaFora], manda ao Gemini.
  bool get ehPane =>
      (codigo == 'ia_falhou' && tipo != TipoFalhaIa.recusada) || codigo == 'ia_demorou' || codigo.startsWith('http_5');

  /// Sem o texto do aluno (o corpo de erro do Worker só tem `erro` e `mensagem`).
  @override
  String toString() => 'Claude ${status ?? '-'} ($codigo): ${mensagem.isNotEmpty ? mensagem : detalhe}';
}

/// A Conversa com IA falando com o Claude (Haiku) pelo Worker da Cloudflare — `POST <url>/v1/turno` com o
/// ID token do Firebase. A chave da Anthropic mora só no Worker; o app nunca a vê.
///
/// Só o [perguntarJson] é usado (os turnos da `ConversaPage`). [perguntar]/[perguntarComo] existem para
/// cumprir os contratos e devolvem um fluxo com [FalhaIa] (outro) — o Tutor, o "Por quê?" e a Escrita
/// seguem no Gemini (o [TutorConversaRoteador] nunca os manda para cá).
///
/// O pedido: `system` = a persona; UMA fala do aluno = [GeminiTutorService.montarPrompt] (o contexto,
/// a conversa recente e a fala — o mesmo texto que o Gemini recebe); `esquema` = o [esquemaTurno] como
/// está (o Worker normaliza o formato do Gemini); `maxTokens`.
///
/// Nunca loga nada — e o texto do aluno não entra em nenhuma [FalhaClaude].
class ClaudeTutorService implements TutorService, TutorComPersona, TutorJson {
  /// O teto de caracteres do Worker (`system` + falas); acima disso nem chama: [FalhaClaude]
  /// `pedido_invalido`, e o roteador manda o turno ao Gemini.
  static const maxCaracteres = 16000;

  /// A base do Worker (`config/tutor.urlConversa`, ex.: `https://paclingo-conversa.<sub>.workers.dev`),
  /// sem `/v1/turno`.
  final String url;

  final http.Client _http;

  /// O ID token do Firebase, pedido de novo a CADA chamada (o SDK renova sozinho); null = sem sessão.
  final Future<String?> Function() _obterToken;

  /// Relógio injetável (testes).
  final DateTime Function() _agora;

  /// O limite do lado do app: acima dos 25 s em que o Worker desiste da Anthropic (mais o JWT/KV/ida e
  /// volta), para o 504 `ia_demorou` dele chegar antes. Esgotado → também `ia_demorou` (não cai).
  final Duration timeout;

  /// O `restantesHoje` da última resposta 200 do Worker (null = ainda nenhuma).
  int? restantesHoje;

  ClaudeTutorService({
    required this.url,
    http.Client? client,
    Future<String?> Function()? obterToken,
    DateTime Function()? agora,
    this.timeout = const Duration(seconds: 35),
  })  : _http = client ?? http.Client(),
        _obterToken = obterToken ?? _tokenDoFirebase,
        _agora = agora ?? DateTime.now;

  static Future<String?> _tokenDoFirebase() async => FirebaseAuth.instance.currentUser?.getIdToken();

  /// O endereço do turno: [url] sem a barra final + `/v1/turno`.
  Uri get urlTurno => Uri.parse('${url.endsWith('/') ? url.substring(0, url.length - 1) : url}/v1/turno');

  /// O relógio (testes).
  DateTime agora() => _agora();

  /// O cliente http.
  http.Client get cliente => _http;

  /// O token de agora (null = sem sessão).
  Future<String?> obterToken() => _obterToken();

  /// O `Retry-After` em segundos (número inteiro) → Duration; senão null.
  static Duration? _retryAfter(Map<String, String> cabecalhos) {
    String? v;
    for (final e in cabecalhos.entries) {
      if (e.key.toLowerCase() == 'retry-after') v = e.value.trim();
    }
    final s = v == null ? null : int.tryParse(v);
    return s == null || s < 0 ? null : Duration(seconds: s);
  }

  /// Resposta não-200 do Worker → [FalhaClaude] com o [TipoFalhaIa] que o [IaCubit] entende. Corpo sem
  /// o JSON do Worker (404 de rota que não existe, página da Cloudflare) → o código sai do status.
  static FalhaClaude falhaDe(int status, String corpo, {Map<String, String> cabecalhos = const {}}) {
    var codigo = '';
    var mensagem = '';
    try {
      final j = jsonDecode(corpo);
      if (j is Map) {
        if (j['erro'] is String) codigo = j['erro'] as String;
        if (j['mensagem'] is String) mensagem = j['mensagem'] as String;
      }
    } catch (_) {
      // não é o JSON do Worker
    }
    if (codigo.isEmpty) {
      codigo = switch (status) {
        401 => 'nao_autenticado',
        403 => 'origem_negada',
        404 => 'nao_encontrado',
        429 => 'limite_geral',
        _ => 'http_$status',
      };
    }
    final tipo = switch (codigo) {
      'sem_chave' || 'nao_autenticado' || 'origem_negada' || 'nao_encontrado' => TipoFalhaIa.credencial,
      'pedido_invalido' => TipoFalhaIa.outro,
      'limite_pessoal' => TipoFalhaIa.limitePessoal,
      'limite_geral' => TipoFalhaIa.limite,
      'ia_falhou' when mensagem.contains('não quis') => TipoFalhaIa.recusada,
      'ia_falhou' || 'ia_demorou' => TipoFalhaIa.ocupado,
      _ => FalhaIa.tipoDoStatus(status, ''),
    };
    // o detalhe nunca leva um corpo que não é do Worker inteiro (página HTML, …): só o começo
    final detalhe = corpo.length > 200 ? corpo.substring(0, 200) : corpo;
    return FalhaClaude(tipo,
        codigo: codigo, mensagem: mensagem, retryAfter: _retryAfter(cabecalhos), status: status, detalhe: detalhe);
  }

  @override
  Future<String> perguntarJson({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
    required Map<String, Object?> esquema,
    int maxTokens = 600,
  }) async {
    final fala = GeminiTutorService.montarPrompt(contexto: contexto, historico: historico, pergunta: pergunta);
    if (persona.length + fala.length > maxCaracteres) {
      throw const FalhaClaude(TipoFalhaIa.outro,
          codigo: 'pedido_invalido', detalhe: 'o turno passou do teto de caracteres do Worker');
    }

    String? token;
    try {
      token = await _obterToken();
    } catch (e) {
      // o SDK não conseguiu o token (sem rede para renovar, sessão revogada): sem token, sem Claude
      throw FalhaClaude(TipoFalhaIa.credencial, codigo: 'nao_autenticado', detalhe: 'token: ${e.runtimeType}');
    }
    if (token == null || token.isEmpty) {
      throw const FalhaClaude(TipoFalhaIa.credencial, codigo: 'nao_autenticado', detalhe: 'sem sessão');
    }

    final http.Response resp;
    try {
      resp = await _http
          .post(
            urlTurno,
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({
              'system': persona,
              'mensagens': [
                {'papel': 'aluno', 'texto': fala}
              ],
              'esquema': esquema,
              'maxTokens': maxTokens,
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      // o Worker pode estar só lento (a Anthropic demorou): como o 504 dele — não cai nem deixa o Claude de lado
      throw const FalhaClaude(TipoFalhaIa.ocupado, codigo: 'ia_demorou', detalhe: 'tempo esgotado do lado do app');
    } catch (e) {
      // DNS, conexão recusada, CORS (o navegador esconde o status): o Worker não respondeu
      throw FalhaClaude(TipoFalhaIa.semRede, codigo: 'rede', detalhe: 'Worker fora de alcance: ${e.runtimeType}');
    }

    final corpo = utf8.decode(resp.bodyBytes, allowMalformed: true);
    if (resp.statusCode != 200) throw falhaDe(resp.statusCode, corpo, cabecalhos: resp.headers);

    Object? json;
    try {
      json = jsonDecode(corpo);
    } catch (_) {
      json = null;
    }
    final texto = json is Map ? json['texto'] : null;
    if (texto is! String) {
      // sem o corpo no detalhe: seria a resposta da IA, e o erro pode acabar num log
      throw FalhaClaude(TipoFalhaIa.outro,
          codigo: 'resposta_ilegivel', status: 200, detalhe: 'resposta ilegível (${corpo.length} caracteres)');
    }
    final restantes = (json as Map)['restantesHoje'];
    if (restantes is num) restantesHoje = restantes.toInt();
    return texto;
  }

  static const _soConversa = FalhaIa(TipoFalhaIa.outro, detalhe: 'o Claude só atende a Conversa (perguntarJson)');

  @override
  Stream<String> perguntar({
    required String contexto,
    required String historico,
    required String pergunta,
  }) =>
      Stream.error(_soConversa);

  @override
  Stream<String> perguntarComo({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
  }) =>
      Stream.error(_soConversa);
}
