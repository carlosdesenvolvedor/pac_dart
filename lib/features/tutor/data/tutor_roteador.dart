import 'package:http/http.dart' as http;

import '../../../core/gemini/chave_gemini.dart';
import 'tutor_claude.dart';
import 'tutor_service.dart';

/// O serviço do [IaCubit] em produção: TUDO vai ao [gemini] (o `GeminiTutorService` no web, o
/// `FirebaseAiTutorService` no nativo), exceto o [perguntarJson] — os turnos da Conversa com IA —, que vai
/// ao Claude pelo Worker quando `config/tutor` tem `provedorConversa == 'claude'` E `urlConversa` não vazio.
///
/// Desligado por padrão. Fallback: o Claude "fora" (ver [FalhaClaude.caiParaGemini]) → aquele turno vai ao
/// Gemini uma vez e o roteador não tenta o Claude por [foraPor]; `pedido_invalido` → só aquele turno vai ao
/// Gemini; `limite_geral` com `Retry-After` longo (o teto do dia do Worker para todo mundo) → o turno vai
/// ao Gemini e o Claude fica de lado até o `Retry-After`; [panesParaFora] panes seguidas
/// ([FalhaClaude.ehPane]: chave revogada, sem crédito, teto de gastos…) → o turno vai ao Gemini e o Claude
/// fica de lado por [foraPor]. `limite_pessoal` NÃO cai para o Gemini: a falha sobe (limitePessoal, que não
/// abre a janela compartilhada) e, até o `Retry-After`, o roteador a repete sem chamar o Worker. O resto
/// (limite_geral curto, ia_falhou/ia_demorou avulsos, …) sobe como está. Nunca loga nada.
class TutorConversaRoteador implements TutorService, TutorComPersona, TutorJson {
  /// O serviço de sempre (Gemini REST ou Firebase AI).
  final TutorService gemini;

  final http.Client? _client;
  final Future<String?> Function()? _obterToken;
  final DateTime Function() _agora;

  /// Lê um campo String de `config/tutor` (padrão: [ChaveGemini.campoRecente], que nunca lança).
  final Future<String?> Function(String nome) _lerCampo;

  /// O contrato do turno em palavras (`formatoTurnoTexto`), para quando o [gemini] não é [TutorJson]
  /// (o Firebase AI do nativo): o roteador refaz ali o caminho "JSON no prompt" do [IaCubit.consultarJson],
  /// que deixa de valer porque o roteador É [TutorJson]. '' = a pergunta vai como está.
  final String formatoSemJson;

  /// Cria o serviço do Claude para uma url (injetável nos testes; padrão: [ClaudeTutorService]).
  final ClaudeTutorService Function(String url)? _fabricaClaude;

  /// Os campos de `config/tutor` que ligam o Claude na Conversa.
  static const campoProvedor = 'provedorConversa', campoUrl = 'urlConversa', provedorClaude = 'claude';

  /// Quanto tempo o roteador deixa o Claude de lado depois de uma falha que cai para o Gemini.
  static const foraPor = Duration(minutes: 10);

  /// Quanto tempo a leitura da config vale (só aqui: o [lerCampo] padrão sempre vai ao banco quando este
  /// cache vence): ligar ou desligar o Claude no Firestore chega ao app aberto em até ~5 min, sem recarregar.
  static const configValePor = Duration(minutes: 5);

  /// Um `limite_geral` com `Retry-After` acima disso é o teto do DIA do Worker (até a meia-noite UTC), não
  /// um 429 passageiro da Anthropic (que vem curto ou sem): o turno vai ao Gemini.
  static const limiteGeralLongo = Duration(minutes: 2);

  /// Quantas panes seguidas ([FalhaClaude.ehPane]) deixam o Claude de lado por [foraPor].
  static const panesParaFora = 3;

  TutorConversaRoteador({
    required this.gemini,
    http.Client? client,
    Future<String?> Function()? obterToken,
    DateTime Function()? agora,
    Future<String?> Function(String nome)? lerCampo,
    this.formatoSemJson = '',
    ClaudeTutorService Function(String url)? fabricaClaude,
  })  : _client = client,
        _obterToken = obterToken,
        _agora = agora ?? DateTime.now,
        _lerCampo = lerCampo ?? _lerCampoPadrao,
        _fabricaClaude = fabricaClaude;

  /// Sempre do banco (a releitura que falha fica com o cache do [ChaveGemini]): o único cache da config é o
  /// daqui ([configValePor]) — o do [ChaveGemini] pode ter sido lido minutos antes por outra tela, e os
  /// dois em série levariam o desligar a ~10 min.
  static Future<String?> _lerCampoPadrao(String nome) => ChaveGemini.campoRecente(nome, maxIdade: Duration.zero);

  /// Até quando o Claude está de lado depois de uma falha que caiu para o Gemini.
  DateTime? _foraAte;

  /// A última `limite_pessoal` (a falha repetida até o `Retry-After`) e até quando ela vale.
  FalhaClaude? _limitePessoal;
  DateTime? _limitePessoalAte;

  /// Panes seguidas do Claude ([FalhaClaude.ehPane]); zera a cada resposta (ou recusa) dele.
  int _panes = 0;

  /// A url lida da config (null = Claude desligado) e quando; a leitura em andamento (chamadas juntas leem 1 vez).
  String? _urlConfig;
  DateTime? _configLidaEm;
  Future<String?>? _lendoConfig;

  /// O serviço do Claude em uso (um por url: guarda o `restantesHoje`).
  ClaudeTutorService? _claude;

  /// A url da config quando `provedorConversa == 'claude'` e `urlConversa` é http(s) com host (http só em
  /// localhost/127.0.0.1, o `wrangler dev`); senão null. Lida no máximo a cada [configValePor].
  Future<String?> _urlDaConfig() {
    final lida = _configLidaEm;
    if (lida != null && agora().difference(lida) < configValePor) return Future.value(_urlConfig);
    return _lendoConfig ??= () async {
      try {
        final provedor = (await lerCampo(campoProvedor))?.trim().toLowerCase();
        final url = provedor == provedorClaude ? urlValida(await lerCampo(campoUrl)) : null;
        _urlConfig = url;
        _configLidaEm = agora();
        return url;
      } catch (_) {
        return null; // (o lerCampo padrão nunca lança; um injetado que lança = desligado, sem guardar)
      } finally {
        _lendoConfig = null;
      }
    }();
  }

  /// [bruta] aparada se for uma base de Worker aceitável (https com host; http só local); senão null.
  static String? urlValida(String? bruta) {
    final t = bruta?.trim() ?? '';
    final u = Uri.tryParse(t);
    if (u == null || u.host.isEmpty) return null;
    final local = u.host == 'localhost' || u.host == '127.0.0.1';
    return u.scheme == 'https' || (u.scheme == 'http' && local) ? t : null;
  }

  /// A url do Worker quando o Claude está ligado na config e não está "fora"; senão null (vai ao Gemini).
  Future<String?> urlClaudeAtiva() async {
    if (claudeForaAte != null) return null;
    return _urlDaConfig();
  }

  /// Até quando o Claude fica de lado (null = disponível).
  DateTime? get claudeForaAte {
    final ate = _foraAte;
    return ate != null && agora().isBefore(ate) ? ate : null;
  }

  /// O serviço do Claude para [url] (o da fábrica ou um [ClaudeTutorService] com o client/token/relógio daqui).
  ClaudeTutorService claudePara(String url) =>
      _fabricaClaude?.call(url) ??
      ClaudeTutorService(url: url, client: _client, obterToken: _obterToken, agora: _agora);

  /// O serviço do Claude em uso para [url] (reaproveitado enquanto a url não muda).
  ClaudeTutorService _claudeEmUso(String url) {
    final c = _claude;
    if (c != null && c.url == url) return c;
    return _claude = claudePara(url);
  }

  /// O `restantesHoje` da última resposta do Worker (null = o Claude ainda não respondeu).
  int? get restantesNoClaude => _claude?.restantesHoje;

  /// O relógio (testes).
  DateTime agora() => _agora();

  /// Lê um campo da config (testes).
  Future<String?> lerCampo(String nome) => _lerCampo(nome);

  /// Um turno da Conversa: o Claude quando ligado e disponível (com o fallback do topo), senão o Gemini.
  @override
  Future<String> perguntarJson({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
    required Map<String, Object?> esquema,
    int maxTokens = 600,
  }) async {
    Future<String> noGemini() => _jsonNoGemini(
        persona: persona, contexto: contexto, historico: historico, pergunta: pergunta, esquema: esquema, maxTokens: maxTokens);

    final url = await urlClaudeAtiva();
    if (url == null) return noGemini();

    // a pessoa já usou as falas de hoje no Worker: repete a falha até o Retry-After, sem chamar
    final lp = _limitePessoal, lpAte = _limitePessoalAte;
    if (lp != null && lpAte != null && agora().isBefore(lpAte)) throw lp;

    try {
      final texto = await _claudeEmUso(url).perguntarJson(
          persona: persona, contexto: contexto, historico: historico, pergunta: pergunta, esquema: esquema, maxTokens: maxTokens);
      _panes = 0;
      return texto;
    } on FalhaClaude catch (f) {
      _panes = f.ehPane ? _panes + 1 : 0;
      if (f.caiParaGemini) {
        _foraAte = agora().add(foraPor);
        return noGemini();
      }
      if (f.caiSoNoTurno) return noGemini();
      // o teto do dia do Worker para todo mundo: até a meia-noite UTC só o Gemini (e a janela de descanso
      // compartilhada nem abre — o "Por quê?", a Escrita e a palavra seguem no Gemini)
      final ra = f.retryAfter;
      if (f.codigo == 'limite_geral' && ra != null && ra > limiteGeralLongo) {
        _foraAte = agora().add(ra);
        return noGemini();
      }
      // panes seguidas (chave revogada, sem crédito, teto de gastos, MODELO errado…): o Claude está fora
      if (_panes >= panesParaFora) {
        _panes = 0;
        _foraAte = agora().add(foraPor);
        return noGemini();
      }
      if (f.codigo == 'limite_pessoal') {
        _limitePessoal = f;
        // sem Retry-After (o Worker sempre manda): até a próxima meia-noite UTC, quando o Worker zera
        _limitePessoalAte = ra != null ? agora().add(ra) : _proximaMeiaNoiteUtc(agora());
      }
      rethrow;
    }
  }

  /// A próxima 00:00 UTC depois de [t] (quando o Worker zera as contagens do dia).
  static DateTime _proximaMeiaNoiteUtc(DateTime t) {
    final u = t.toUtc();
    return DateTime.utc(u.year, u.month, u.day + 1);
  }

  /// O turno no [gemini]: [TutorJson] → `perguntarJson`; senão o caminho "JSON no prompt" do
  /// [IaCubit.consultarJson] (a pergunta + [formatoSemJson]), juntando o streaming.
  Future<String> _jsonNoGemini({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
    required Map<String, Object?> esquema,
    required int maxTokens,
  }) {
    final g = gemini;
    if (g is TutorJson) {
      return (g as TutorJson).perguntarJson(
          persona: persona, contexto: contexto, historico: historico, pergunta: pergunta, esquema: esquema, maxTokens: maxTokens);
    }
    final comFormato = formatoSemJson.isEmpty ? pergunta : '$pergunta\n\n$formatoSemJson';
    return _juntar(perguntarComo(persona: persona, contexto: contexto, historico: historico, pergunta: comFormato));
  }

  static Future<String> _juntar(Stream<String> fluxo) async {
    final b = StringBuffer();
    await for (final pedaco in fluxo) {
      b.write(pedaco);
    }
    return b.toString();
  }

  @override
  Stream<String> perguntar({
    required String contexto,
    required String historico,
    required String pergunta,
  }) =>
      gemini.perguntar(contexto: contexto, historico: historico, pergunta: pergunta);

  /// O mesmo desvio do [IaCubit.consultar]: sem [TutorComPersona] a persona vai no contexto.
  @override
  Stream<String> perguntarComo({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
  }) {
    final g = gemini;
    return g is TutorComPersona
        ? (g as TutorComPersona).perguntarComo(persona: persona, contexto: contexto, historico: historico, pergunta: pergunta)
        : g.perguntar(contexto: '$persona\n\n$contexto', historico: historico, pergunta: pergunta);
  }
}
