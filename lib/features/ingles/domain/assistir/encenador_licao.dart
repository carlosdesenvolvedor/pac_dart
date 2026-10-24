import '../../../arcade/domain/historia_turismo.dart';
import '../../../curso/domain/curriculo.dart';
import '../expressao.dart';
import 'historia_licao.dart';

/// 🎬 A encenação AUTOMÁTICA de uma lição (📺 Escutar assistindo): monta a cena em tempo de execução a
/// partir da lição (cenário, elenco, gestos, emoções), para toda lição poder ser assistida desde o 1º dia.
/// Puro e determinístico (sem `Random`, sem relógio). A história autoral, quando existe, ganha desta; a
/// tabela `encenacao_auto.json` ([EncenacaoManual]) corrige cenário, hora, remotos, entradas e mudos.
///
/// Plano §4: (4.1) o cenário pelo texto da cena (1º lugar citado, com preposição de lugar e fronteira de
/// palavra); (4.2) hora e clima; (4.3) elenco, posições, telefone/mensagem (remoto via celular) e entrada
/// tardia; (4.4) gestos pelo emoji (por grafema) e depois pelo texto, câmera, reações e o aceno do fim.
/// Toda saída passa no `validarHistoriaLicao` (o teste roda as 626 lições).

/// O gesto de uma frase (pelo emoji e pelo texto).
class GestoDaFrase {
  final AcaoAtor acao;
  final Expressao? emocao;
  final EfeitoHistoria? efeito;
  final PropHistoria? segura;

  const GestoDaFrase({this.acao = AcaoAtor.parado, this.emocao, this.efeito, this.segura});
}

/// A correção de uma lição na tabela `encenacao_auto.json` (plano §4.5). A tabela grava as decisões da
/// lição (D6: mudar a heurística depois não muda o que já foi revisado), então, quando a lição TEM entrada,
/// as listas dela mandam: [remotos], [entram] e [mudos] ausentes = nenhum (a heurística de telefone, de
/// entrada tardia e dos citados na cena não entra). [cenario]/[hora] ausentes (ou inválidos) caem na
/// heurística.
class EncenacaoManual {
  final CenarioHistoria? cenario;
  final HoraHistoria? hora;
  final Map<String, ViaRemota> remotos;
  final Set<String> entram;
  final Set<String> mudos;

  const EncenacaoManual({
    this.cenario,
    this.hora,
    this.remotos = const {},
    this.entram = const {},
    this.mudos = const {},
  });

  /// Tolerante: enum desconhecido → null/ignorado.
  factory EncenacaoManual.fromJson(Map<String, dynamic> j) {
    T? porNome<T extends Enum>(List<T> valores, Object? v) {
      if (v is! String) return null;
      for (final e in valores) {
        if (e.name == v) return e;
      }
      return null;
    }

    Set<String> nomes(Object? v) => v is List ? {for (final x in v) if (x is String) x} : const {};
    final remotos = <String, ViaRemota>{};
    final r = j['remotos'];
    if (r is Map) {
      for (final e in r.entries) {
        final via = porNome(ViaRemota.values, e.value);
        if (e.key is String && via != null) remotos[e.key as String] = via;
      }
    }
    return EncenacaoManual(
      cenario: porNome(CenarioHistoria.values, j['cenario']),
      hora: porNome(HoraHistoria.values, j['hora']),
      remotos: remotos,
      entram: nomes(j['entram']),
      mudos: nomes(j['mudos']),
    );
  }
}

// ───────────────────────────── texto ─────────────────────────────

const _semAcento = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'í': 'i', 'ì': 'i',
  'î': 'i', 'ï': 'i', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

/// Minúsculas e sem acento: as regras casam com `\b` em ASCII.
String _normalizar(String s) {
  final b = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    b.write(_semAcento[c] ?? c);
  }
  return b.toString();
}

RegExp _re(String s) => RegExp(s);

/// Preposição de lugar antes do lugar (4.1): "no café" é o lugar; "toma um café" é a bebida.
const _prep = r'(?:no|na|nos|nas|num|numa|em|ao|a|pro|pra)(?: um| uma)?';

/// Um gatilho de cenário. [contexto] (opcional) confere a vizinhança do achado (o `call` só vale perto de
/// reunião/time).
typedef _Gatilho = (CenarioHistoria, RegExp, bool Function(String texto, int inicio)?);

bool _callDeReuniao(String t, int i) {
  final de = i - 40 < 0 ? 0 : i - 40;
  final ate = i + 44 > t.length ? t.length : i + 44;
  return _reContextoCall.hasMatch(t.substring(de, ate));
}

final _reContextoCall = _re(r'\b(?:daily|reuniao|time|equipe|cliente|sos|mike|sarah|ana|ben)\b');

/// Os gatilhos de lugar, na ordem de desempate (achados na mesma posição: ganha o de cima). O 1º lugar
/// CITADO no texto ganha, não a ordem da tabela.
final List<_Gatilho> _gatilhos = [
  // ── chamada de vídeo (no curso, "chamada" é sempre a chamada do time)
  (
    CenarioHistoria.videochamada,
    _re(r'\b(?:videochamadas?|chamadas? de video|por video|pela camera|na camera|daily)\b'),
    null,
  ),
  (CenarioHistoria.videochamada, _re(r'\bchamadas?\b(?! telefonica)'), null),
  (CenarioHistoria.videochamada, _re(r'\bcompartilh\w* a tela\b'), null),
  (
    CenarioHistoria.videochamada,
    _re(r'\b(?:happy hour|reuniao|apresentacao|clube do livro|almoco|evento|aula|debate|workshop|encontro|curso)'
        r'(?: \w+)? (?:online|virtual|remota)\b'),
    null,
  ),
  (CenarioHistoria.videochamada, _re(r'\bcalls?\b'), _callDeReuniao),
  // ── hotel (a recepção é do hotel quando o texto fala de hotel; senão é a do prédio do escritório)
  (CenarioHistoria.hotel, _re('\\b$_prep (?:hotel|quarto)\\b'), null),
  (CenarioHistoria.hotel, _re(r'\b(?:na|a|pela) recepcao\b(?=.*\bhotel\b)'), null),
  (CenarioHistoria.hotel, _re(r'\bcheck-(?:in|out)\b'), null),
  // ── escritório
  (
    CenarioHistoria.escritorio,
    _re('\\b$_prep (?:escritorio|sala de reunioes?|sala do time|salinha|copa|corredor|predio|recepcao|intervalo'
        '|maquina de cafe|mesa dele|mesa dela)\\b'),
    null,
  ),
  // ── restaurante (o `cafe` do Turismo tem pista pela janela: as lições usam `restaurante`)
  (
    CenarioHistoria.restaurante,
    _re('\\b$_prep (?:cafe|cafeteria|restaurante|padaria|lanchonete|bar|pub|pizzaria|churrascaria)\\b'),
    null,
  ),
  (
    CenarioHistoria.restaurante,
    _re(r'\b(?:no|num|ao|pro) (?:almoco|jantar|happy hour|brunch)\b(?! (?:online|virtual|em casa|na casa))'),
    null,
  ),
  (
    CenarioHistoria.restaurante,
    _re(r'\b(?:almoco|jantar|happy hour) (?:do time|de despedida|com o time|com a equipe|da conferencia'
        r'|do evento|de um ano)\b'),
    null,
  ),
  (CenarioHistoria.restaurante, _re(r'\b(?:garcom|garconete|cardapio)\b'), null),
  // ── loja
  (
    CenarioHistoria.loja,
    _re('\\b$_prep (?:loja|lojinha|mercado|supermercado|farmacia|shopping|feira|livraria|caixa|provador)\\b'),
    null,
  ),
  (CenarioHistoria.loja, _re(r'\bcompras\b'), null),
  // ── aeroporto
  // "para o aeroporto"/"o voo para a conferência" é destino, não lugar
  (CenarioHistoria.aeroporto, _re(r'\b(?:no|num|ao|do|pelo) aeroporto\b'), null),
  (
    CenarioHistoria.aeroporto,
    _re(r'\b(?:no|num|durante o) voo\b|\bvoo (?:\w+ ){0,4}(?:atras\w*|cancelad\w*)\b'),
    null,
  ),
  (CenarioHistoria.aeroporto, _re(r'\b(?:aviao|embarque|imigracao|alfandega|balcao da companhia aerea)\b'), null),
  // ── clínica (provisório: a tenda, até o lote de arte do consultório)
  (
    CenarioHistoria.clinica,
    _re('\\b$_prep (?:medico|medica|consultorio|clinica|dentista|hospital|pronto-socorro)\\b'),
    null,
  ),
  (CenarioHistoria.clinica, _re(r'\bconsulta (?:medica|com)\b'), null),
  // ── casa
  (
    CenarioHistoria.casa,
    _re('\\b$_prep (?:casa|apartamento|cozinha|sala de estar|home office|varanda|quintal|churrasco|festa'
        '|sala d[ao])\\b'),
    null,
  ),
  (CenarioHistoria.casa, _re(r'\bpela casa\b'), null),
  (CenarioHistoria.casa, _re(r'\b(?:churrasco|mudanca)\b'), null),
  // ── cidade
  (CenarioHistoria.cidade, _re(r'\b(?:na|nas|pela|pelas) ruas?\b'), null),
  (CenarioHistoria.cidade, _re(r'\b(?:de|no|num|um|pegar o|pega um) (?:taxi|onibus|metro|trem)\b'), null),
  (
    CenarioHistoria.cidade,
    _re(r'\b(?:na|no|pelo|pela) (?:esquina|caminho|estacao|estacionamento|museu|centro|cinema|oficina|rodovia'
        r'|estrada|ponto de onibus)\b'),
    null,
  ),
  (CenarioHistoria.cidade, _re(r'\b(?:no carro|num carro|de carro|viagem de carro|museu|cinema)\b'), null),
  (CenarioHistoria.cidade, _re(r'\bpasse(?:io|ios|iam|ia|ando)\b|\ba caminho d[oa]\b'), null),
  // ── praia e lago (parque, trilha)
  (CenarioHistoria.praia, _re(r'\b(?:na|numa|pela) praias?\b|\bpraia no lago\b'), null),
  (CenarioHistoria.lago, _re(r'\b(?:no|num|ao|pelo|na|numa) (?:parque|lago|trilha)\b'), null),
  (CenarioHistoria.lago, _re(r'\b(?:parque nacional|(?:no|num) piquenique|acampa\w*)\b'), null),
];

/// Telefone, mensagem, chat, e-mail (sem lugar citado): a pessoa do outro lado fala pelo celular de quem
/// está no palco.
final _reDistancia = _re(r'\b(?:por mensage(?:m|ns)|mensage(?:m|ns)|no chat|pelo chat|do chat|chat do time'
    r'|thread|no canal|canal do time|canal de|e-?mails?|ligacao|ligacoes|telefone|ao telefone|liga|ligar|ligou'
    r'|te liga|por audio|nos comentarios)\b');

/// Num lugar citado, só o verbo de falar de longe conta ("um e-mail hackeado" no café não põe o Ben no
/// celular): mensagem trocada, telefone, ligação, chat, e a chamada de vídeo ("por vídeo, a Sarah").
final _reDistanciaComLugar = _re(r'\b(?:por mensage(?:m|ns)|troca\w* mensagens|manda\w* mensage(?:m|ns)'
    r'|ao telefone|por telefone|pelo telefone|liga|ligar|ligou|te liga|ligacao|ligacoes|no chat|pelo chat'
    r'|chat do time|por audio|(?:por|pela|na|numa) (?:chamada|video|videochamada|camera)|chamada de video)\b');

/// Quem é dono do lugar ("na cozinha da Emma") está nele, não no celular.
final _reDono = _re(r'\b(?:casa|cozinha|sala|apartamento|mesa|carro|festa|quarto) d[ao] (\w+)');

/// Assunto ou evento de trabalho, sem lugar citado: escritório (o 2º nível, depois dos lugares de verdade e
/// do telefone/mensagem).
final _reTrabalho = _re(r'\b(?:trabalho|time|projeto|reuniao|reunioes|equipe|cliente|empresa|codigo|bug|deploy'
    r'|sprint|devs?|produto|release|api|pr|relatorio|diretoria|incidente|readme|rfc|commit|issue|tech lead'
    r'|lancamento|entrega|prazo|code review|entrevista|standup|stand-up|retrospectiva|meetup|conferencia|palestra'
    r'|workshop|planejamento|post-mortem|postmortem|demo|live coding|pair programming|onboarding|plantao'
    r'|quadro branco)\b');

/// Escrever algo (e-mail, relatório, README…): quem escreve segura o notebook.
final _reEscrita = _re(r'\b(?:escrev\w*|redig\w*|e-?mails?|relatorio|readme|document\w*|rfc|adr|changelog|post'
    r'|newsletter|issue|commit)\b');

final _reNoite = _re(r'\b(?:noite|noites|jantar|anoitecer)\b');
final _reTarde = _re(r'\b(?:a tarde|de tarde|fim de tarde|fim da tarde|fim do dia|fim do expediente|pela tarde'
    r'|entardecer)\b');
final _reAmanhecer = _re(r'\b(?:bem cedo|cedinho|de madrugada|amanhecer|nascer do sol)\b');
final _reDia = _re(r'\b(?:manha|manhas|almoco|meio-dia)\b');
final _reChuva = _re(r'\b(?:chuva|chuvoso|chove|chovia|chovendo|tempestade)\b');
final _reNeve = _re(r'\b(?:neve|nevando|neva|nevar|nevasca)\b');

/// Entrada tardia: o verbo logo depois do nome de quem fala (4.3): "a Sarah entra", "a Ana, no Brasil, que
/// entra", "até a Sarah chegar". [_reVaoDaEntrada] é o que pode haver entre o nome e o verbo.
final _reEntrada = _re(r'\b(?:entra|entrou|chega|chegou|chegar|aparece|apareceu)\b');
final _reVaoDaEntrada = _re(r'^(?:, [^,.;:]{1,24},)? (?:que )?$|^, que $');

/// Os canônicos citados pelo nome no texto da cena (normalizado) e nas frases (inglês).
const _nomes = {
  'mike': 'mike', 'sarah': 'sarah', 'ana': 'ana', 'ben': 'ben', 'emma': 'emma', 'lucas': 'lucas', 'julia': 'julia',
  'dra-lee': 'lee',
};
final _reNomes = {for (final e in _nomes.entries) e.key: _re('\\b${e.value}\\b')};

/// "do Mike"/"da Ana" é posse (a pessoa não está na cena), exceto na casa/sala/carro/mesa dela.
final _rePosse = _re(r'(?:^|[^a-z])(?:casa|sala|apartamento|carro|mesa|festa) d[oa] $');
final _rePreposicaoDePosse = _re(r'\bd[oa] $');

// ── texto das frases (inglês) ──
final _reCumprimento = _re(r"^(?:hi|hello|hey|bye|goodbye|good (?:morning|afternoon|evening|night)|see you)\b|"
    r'\b(?:bye|see you)\b');
final _reObrigado = _re(r'\b(?:thanks|thank you)\b');
final _reDesculpa = _re(r'\b(?:sorry|excuse me)\b');
final _reSim = _re(r'^(?:yes|yeah|yep|sure|of course|okay|ok|absolutely|exactly|right)\b');
/// "No problem/No wonder/No way…" não recusam: o "no" do começo só nega sem estas palavras logo depois.
final _reNao = _re(r"^(?:(?:no|nope)\b(?!\s+(?:problem|worries|wonder|matter|sooner|one|need|doubt|way|blockers)\b)"
    r"|not really\b|not yet\b|not at all\b|i don't think so\b)");
final _reSemProblema = _re(r'^(?:no problem|no worries)\b');
final _reNoWay = _re(r'^no way\b');
/// O prop do emoji não vai para a mão quando a frase nega ("I don't drink soda" 🥤🚫 / "No…" / "Not…").
final _reNaoNoComeco = _re(r'^not\b');
/// Sentar só pelo texto, quando quem fala é quem senta (🪑 é quase sempre só o objeto).
final _reSenta = _re(r"^(?:please,? )?(?:sit down|have a seat|take a seat)\b|\bi(?:'ll)? sit\b|\bthe moment i sat down\b");
/// 👋 só acena com cumprimento/despedida ou um destes (no currículo 👋 também é "foi embora/perdeu").
final _reAceno = _re(r'\b(?:hi|welcome|come in|nice trip|head out|sign off|in a hurry|join us|is here|thank you all'
    r'|everyone here)\b');
/// Props que fazem sentido na mão por cima da webcam; o celular só quando a frase fala de telefone/ligação.
final _reTelefone = _re(r'\b(?:phone|call|calls|calling|called)\b');
final _reApresentacao = _re(r'\b(?:present\w*|talk|talks|speech|speak\w*)\b');
final _reOlha = _re(r"^(?:look|here|this is|that's|that is|over there)\b|\blook at\b");
final _reViva = _re(r'\b(?:great|awesome|congrat\w*|amazing|fantastic|excellent|well done|perfect|we did it)\b');
final _reSurpresa = _re(r'\b(?:wow|really|no way|seriously|amazing)\b');
final _reNaoEntendi = _re(r'\b(?:sorry|what|pardon)\?');
final _reDespedida = _re(r"\b(?:bye|goodbye|see you|good night|take care|talk (?:to you )?(?:soon|later)|"
    r'have a (?:good|great|nice))\b');

// ── emojis (chave = o grafema sem U+FE0F e sem tom de pele) ──
const _acaoDoEmoji = {
  '👋': AcaoAtor.acena, '👍': AcaoAtor.concorda, '🙏': AcaoAtor.concorda, '👎': AcaoAtor.nega, '🙅': AcaoAtor.nega,
  '👉': AcaoAtor.aponta, '☝': AcaoAtor.aponta, '👏': AcaoAtor.palmas, '💃': AcaoAtor.danca, '✍': AcaoAtor.escreve,
  '📝': AcaoAtor.escreve, '🤔': AcaoAtor.pensa, '🤝': AcaoAtor.concorda, '✅': AcaoAtor.concorda,
  '❌': AcaoAtor.nega, '🙋': AcaoAtor.acena,
};
const _emocaoDoEmoji = {
  '😊': Expressao.feliz, '🙂': Expressao.feliz, '😄': Expressao.feliz, '😀': Expressao.feliz, '😁': Expressao.feliz,
  '😌': Expressao.feliz, '😎': Expressao.feliz, '🤗': Expressao.feliz, '🥰': Expressao.feliz,
  '😃': Expressao.radiante, '🤩': Expressao.radiante, '🥳': Expressao.radiante, '😍': Expressao.radiante,
  '😂': Expressao.radiante,
  '😢': Expressao.triste, '😞': Expressao.triste, '😔': Expressao.triste, '😕': Expressao.triste,
  '🥺': Expressao.triste, '🙁': Expressao.triste, '☹': Expressao.triste,
  '😮': Expressao.surpreso, '😲': Expressao.surpreso, '😱': Expressao.surpreso, '🤯': Expressao.surpreso,
  '😯': Expressao.surpreso,
  '😠': Expressao.bravo, '😤': Expressao.bravo, '🙄': Expressao.bravo, '😒': Expressao.bravo,
  '🤔': Expressao.pensativo, '🤨': Expressao.pensativo, '🧐': Expressao.pensativo,
  '😬': Expressao.nervoso, '😰': Expressao.nervoso, '😅': Expressao.nervoso, '😟': Expressao.nervoso,
  '😓': Expressao.nervoso,
  '😳': Expressao.timido, '💪': Expressao.determinado,
  '😩': Expressao.cansado, '🥱': Expressao.cansado, '😴': Expressao.cansado, '🤕': Expressao.cansado,
  '🤒': Expressao.cansado, '🤢': Expressao.cansado, '🤧': Expressao.cansado, '😷': Expressao.cansado,
  '😵': Expressao.cansado, '😣': Expressao.cansado, '😖': Expressao.cansado, '😫': Expressao.cansado,
  '🥶': Expressao.cansado, '🥵': Expressao.cansado,
};

/// Emoções do emoji que deixam o "Great…!" virar comemoração (com 🙄 é ironia, não festa).
const _emocoesPositivas = {Expressao.feliz, Expressao.radiante, Expressao.surpreso, Expressao.determinado};

/// Emojis de negação: com eles o prop do emoji não vai para a mão ("I don't drink soda" 🥤🚫).
const _runasDeNegacao = {0x1F6AB, 0x274C, 0x1F645, 0x2796}; // 🚫 ❌ 🙅 ➖
const _efeitoDoEmoji = {
  '❤': EfeitoHistoria.coracoes, '🎉': EfeitoHistoria.confete, '❗': EfeitoHistoria.exclamacao,
  '❓': EfeitoHistoria.interrogacao, '💤': EfeitoHistoria.zzz, '💦': EfeitoHistoria.suor, '🎵': EfeitoHistoria.notas,
  '✨': EfeitoHistoria.brilho, '⭐': EfeitoHistoria.brilho,
};
const _propDoEmoji = {
  '💻': PropHistoria.notebook, '🍕': PropHistoria.prato, '🥗': PropHistoria.prato,
  '🍔': PropHistoria.prato, '🛍': PropHistoria.sacola, '🛒': PropHistoria.sacola, '📄': PropHistoria.documento,
  '📋': PropHistoria.documento, '🪪': PropHistoria.documento, '☕': PropHistoria.cafe, '📱': PropHistoria.celular,
  '☎': PropHistoria.celular, '📞': PropHistoria.celular, '🧳': PropHistoria.mala, '🛂': PropHistoria.passaporte,
  '🗺': PropHistoria.mapa, '🔑': PropHistoria.chave, '🎁': PropHistoria.presente, '📖': PropHistoria.livro,
  '📚': PropHistoria.livro, '✉': PropHistoria.carta, '📧': PropHistoria.carta, '☂': PropHistoria.guardaChuva,
  '🥤': PropHistoria.garrafa, '🎤': PropHistoria.microfone,
};

/// Props do emoji que só cabem em certos lugares: o emoji fala da ideia ("tomar com comida", "viajar"), e a
/// Dra. Lee de prato na mão no consultório ou a mala no lago ficam estranhos. Fora destes cenários a mão fica
/// como estava; os outros props valem em qualquer lugar.
const _propSoEm = {
  PropHistoria.prato: {CenarioHistoria.restaurante, CenarioHistoria.casa, CenarioHistoria.escritorio,
      CenarioHistoria.hotel, CenarioHistoria.praia, CenarioHistoria.lago},
  PropHistoria.mala: {CenarioHistoria.aeroporto, CenarioHistoria.hotel, CenarioHistoria.cidade, CenarioHistoria.casa},
  PropHistoria.sacola: {CenarioHistoria.loja, CenarioHistoria.cidade, CenarioHistoria.casa},
  PropHistoria.passaporte: {CenarioHistoria.aeroporto, CenarioHistoria.hotel},
  PropHistoria.chave: {CenarioHistoria.hotel, CenarioHistoria.casa, CenarioHistoria.cidade},
  PropHistoria.mapa: {CenarioHistoria.cidade, CenarioHistoria.aeroporto, CenarioHistoria.hotel, CenarioHistoria.lago,
      CenarioHistoria.praia},
  PropHistoria.microfone: {CenarioHistoria.escritorio},
  PropHistoria.presente: {CenarioHistoria.casa, CenarioHistoria.restaurante},
};

/// Na videochamada a mão por cima da webcam só segura o que se segura numa call de verdade.
const _propsDaChamada = {PropHistoria.cafe, PropHistoria.notebook, PropHistoria.documento};

/// O prop do emoji cabe no lugar (e na frase: o microfone só com apresentação/palestra, o celular na
/// videochamada só quando a frase fala de telefone/ligação).
bool _propCabe(PropHistoria p, CenarioHistoria c, String en) {
  if (c == CenarioHistoria.videochamada) {
    return _propsDaChamada.contains(p) || (p == PropHistoria.celular && _reTelefone.hasMatch(en));
  }
  if (p == PropHistoria.microfone && !_reApresentacao.hasMatch(en)) return false;
  return _propSoEm[p]?.contains(c) ?? true;
}

bool _ehRegional(int c) => c >= 0x1F1E6 && c <= 0x1F1FF;
bool _ehTomDePele(int c) => c >= 0x1F3FB && c <= 0x1F3FF;

/// Os grafemas de emoji do texto: junta o seletor de variação (U+FE0F/FE0E), o keycap, os tons de pele, as
/// tags, as sequências com ZWJ (`👩‍🎨` é UM grafema, não casa com 🎨) e os pares de bandeira.
List<String> _grafemas(String s) {
  final runas = s.runes.toList();
  final r = <String>[];
  var i = 0;
  while (i < runas.length) {
    final b = StringBuffer()..writeCharCode(runas[i]);
    final regional = _ehRegional(runas[i]);
    i++;
    if (regional && i < runas.length && _ehRegional(runas[i])) b.writeCharCode(runas[i++]);
    while (i < runas.length) {
      final c = runas[i];
      if (c == 0xFE0F || c == 0xFE0E || c == 0x20E3 || _ehTomDePele(c) || (c >= 0xE0020 && c <= 0xE007F)) {
        b.writeCharCode(c);
        i++;
      } else if (c == 0x200D && i + 1 < runas.length) {
        b
          ..writeCharCode(c)
          ..writeCharCode(runas[i + 1]);
        i += 2;
      } else {
        break;
      }
    }
    r.add(b.toString());
  }
  return r;
}

/// A chave de busca do grafema: sem U+FE0F, sem tom de pele e sem a variante de gênero (`👋🏽` → `👋`,
/// `☝️` → `☝`, `🙋‍♀️` → `🙋`, `🙅🏽‍♂️` → `🙅`: a pessoa + ZWJ + ♀/♂ faz o mesmo gesto da pessoa).
String _chaveDoEmoji(String g) {
  final k = String.fromCharCodes(g.runes.where((c) => c != 0xFE0F && c != 0xFE0E && !_ehTomDePele(c)));
  return k.length > 2 && (k.endsWith('‍♀') || k.endsWith('‍♂')) ? k.substring(0, k.length - 2) : k;
}

// ───────────────────────────── o encenador ─────────────────────────────

abstract final class EncenadorLicao {
  /// As posições do elenco em linha, por quantos estão no palco (plano §4.3); o `voce` vai primeiro.
  static const _posicoes = [
    <PosicaoPalco>[],
    [PosicaoPalco.centro],
    [PosicaoPalco.centroEsquerda, PosicaoPalco.centroDireita],
    [PosicaoPalco.esquerda, PosicaoPalco.centro, PosicaoPalco.direita],
    [PosicaoPalco.esquerda, PosicaoPalco.centroEsquerda, PosicaoPalco.centroDireita, PosicaoPalco.direita],
    PosicaoPalco.values,
  ];

  /// No máximo 3 mudos (≤ 3 por cena; a história toda tem uma cena só): até 2 entradas + o aceno do fim.
  static const _maxEntradas = 2;

  /// Sempre devolve uma história válida (validarHistoriaLicao vazio): 1 cena, uma âncora por frase, até 3
  /// passos mudos (entradas tardias e o aceno do fim).
  static HistoriaLicao encenar(Licao licao, {required String etapa, EncenacaoManual? manual}) {
    final texto = _normalizar(licao.cena);
    final achado = _lugar(texto);
    final cenarioManual = _cenarioValido(manual?.cenario);
    var cenario = cenarioManual ?? achado?.$1 ?? _semLugar(texto, etapa);
    final horaManual = manual?.hora;
    final hora = horaManual != null && horasPermitidas(cenario).contains(horaManual)
        ? horaManual
        : horaDe(licao, cenario);
    final clima = [
      if (_reChuva.hasMatch(texto) && climaPermitido(ClimaHistoria.chuva, cenario, hora)) ClimaHistoria.chuva
      else if (_reNeve.hasMatch(texto) && climaPermitido(ClimaHistoria.neve, cenario, hora)) ClimaHistoria.neve,
    ];

    // ── quem fala, na ordem da 1ª fala (o `voce` sempre entra)
    final falantes = <String>[];
    for (final t in licao.trechos) {
      final q = quemNoPalco(t.quem);
      if (q != narrador && !falantes.contains(q)) falantes.add(q);
    }
    final ids = ['voce', ...falantes.where((q) => q != 'voce')];

    // ── remotos (telefone/mensagem; 4.3): só fora da videochamada
    final remotos = <String, ViaRemota>{};
    if (manual != null) {
      for (final e in manual.remotos.entries) {
        if (e.key != 'voce' && ids.contains(e.key) && remotos.length < 2) remotos[e.key] = e.value;
      }
    } else if (cenario != CenarioHistoria.videochamada) {
      final comLugar = cenarioManual != null || achado != null;
      if (!comLugar && _reDistancia.hasMatch(texto)) {
        // sem lugar: a pessoa está em casa e todo mundo que fala está longe
        final candidatos = ids.skip(1).toList();
        if (candidatos.length > 2) {
          cenario = CenarioHistoria.videochamada; // 3+ pessoas longe: vira a chamada do time
        } else {
          for (final q in candidatos) {
            remotos[q] = ViaRemota.celular;
          }
        }
      } else if (comLugar && _reDistanciaComLugar.hasMatch(texto)) {
        // num lugar de verdade, o figurante é de lá (a atendente da loja) e o dono do lugar também ("na
        // cozinha da Emma"); longe fica o canônico citado perto do "por vídeo"/"ao telefone"/"por mensagem"
        final donos = {for (final m in _reDono.allMatches(texto)) m.group(1)};
        final candidatos = [
          for (final q in ids.skip(1))
            if (elencoDasLicoes.contains(q) && !donos.contains(_nomes[q])) q,
        ];
        // ninguém citado perto ("resolve umas coisas por telefone"): todo mundo fica no palco
        for (final q in _longeNoTexto(texto).where(candidatos.contains).take(2)) {
          remotos[q] = ViaRemota.celular;
        }
      }
    }

    // ── mudos presentes: os da tabela, depois os canônicos citados na cena (fora do telefone)
    final mudos = <String>[];
    var figurantesMudos = 0;
    void mudo(String q) {
      if (ids.contains(q) || mudos.contains(q) || q == 'max' || q == 'kim' || q == narrador) return;
      final figurante = figurantesConhecidos.contains(q) && !elencoDasLicoes.contains(q);
      if (!figurante && !elencoDasLicoes.contains(q)) return;
      if (figurante && figurantesMudos >= maxFigurantesMudos) return;
      if (figurante) figurantesMudos++;
      mudos.add(q);
    }

    for (final q in manual?.mudos ?? const <String>{}) {
      mudo(q);
    }
    if (manual == null && remotos.isEmpty) {
      for (final q in _citados(texto)) {
        mudo(q);
      }
    }
    final presentes = [
      for (final q in [...ids, ...mudos])
        if (!remotos.containsKey(q)) q,
    ].take(5).toList();
    final noElenco = {...presentes, ...remotos.keys};

    // ── quem segura o quê no começo: com remoto, o `voce` segura o celular (âncora do remoto)
    final segura = <String, PropHistoria?>{};
    final donoDoCelular = remotos.isEmpty ? null : 'voce';
    if (donoDoCelular != null) {
      segura['voce'] = PropHistoria.celular;
    } else if ((cenario == CenarioHistoria.casa || cenario == CenarioHistoria.escritorio) &&
        _reEscrita.hasMatch(texto)) {
      segura['voce'] = PropHistoria.notebook;
    }

    // ── entradas tardias (4.3): a tabela (quando a lição tem entrada) ou o verbo logo depois do nome; um mudo
    // `entra` antes da 1ª aparição
    final entradas = <int, List<String>>{};
    final citadosAntes = manual == null ? _entradasNoTexto(texto) : const <String>{};
    var nEntradas = 0;
    for (final q in presentes) {
      if (q == 'voce' || nEntradas >= _maxEntradas) continue;
      final daTabela = manual?.entram.contains(q) ?? false;
      final primeiraFala = licao.trechos.indexWhere((t) => quemNoPalco(t.quem) == q);
      if (!daTabela && (!citadosAntes.contains(q) || primeiraFala < 2)) continue;
      var antes = primeiraFala < 0 ? licao.trechos.length ~/ 2 : primeiraFala;
      final nome = _reNomes[q];
      if (nome != null) {
        final citada = licao.trechos.indexWhere((t) => quemNoPalco(t.quem) != q && nome.hasMatch(_normalizar(t.cod)));
        if (citada >= 1 && citada < antes) antes = citada;
      }
      if (antes < 1) continue; // não há vão antes da 1ª frase
      (entradas[antes] ??= []).add(q);
      nEntradas++;
    }
    final invisiveis = {for (final l in entradas.values) ...l};

    final pos = _posicoes[presentes.length];
    final elenco = <AtorEmCena>[
      for (var i = 0; i < presentes.length; i++)
        AtorEmCena(
          quem: presentes[i],
          pos: pos[i],
          visivel: !invisiveis.contains(presentes[i]),
          segura: segura[presentes[i]],
        ),
      for (final e in remotos.entries) AtorEmCena(quem: e.key, remoto: e.value),
    ];

    // ── os passos
    final visivel = {for (final q in presentes) q: !invisiveis.contains(q)};
    final passos = <FalaHistoria>[];
    var comemorou = false;
    String? anterior;
    for (var k = 0; k < licao.trechos.length; k++) {
      for (final q in entradas[k] ?? const <String>[]) {
        passos.add(FalaHistoria(quem: q, mudo: true, acao: AcaoAtor.entra, emocao: Expressao.feliz));
        visivel[q] = true;
      }
      final t = licao.trechos[k];
      final quem = quemNoPalco(t.quem);
      if (quem == narrador || !noElenco.contains(quem)) {
        passos.add(FalaHistoria(quem: quem, en: t.cod, pt: t.dicaPlana));
        continue;
      }
      final remoto = remotos.containsKey(quem);
      final g = gestoDe(t);
      var acao = g.acao;
      var emocao = g.emocao;
      if (acao == AcaoAtor.comemora) {
        if (comemorou) {
          acao = AcaoAtor.parado;
          if (emocao == Expressao.radiante) emocao = Expressao.feliz;
        }
        comemorou = true;
      }
      PropHistoria? seguraNoPasso;
      // na videochamada ninguém senta (a webcam não tem cadeira; `senta` dura até a pessoa andar)
      if (acao == AcaoAtor.senta && cenario == CenarioHistoria.videochamada) acao = AcaoAtor.parado;
      if (remoto) {
        acao = AcaoAtor.parado; // remoto só `parado` (SimulacaoCena): fica a emoção e o efeito
      } else if (quem != donoDoCelular) {
        final atual = segura[quem];
        final doEmoji =
            g.segura != null && _propCabe(g.segura!, cenario, t.cod.trim().toLowerCase()) ? g.segura : null;
        final novo = doEmoji ?? (acao == AcaoAtor.escreve && atual == null ? PropHistoria.documento : null);
        if (novo != null && novo != atual) {
          seguraNoPasso = novo;
          segura[quem] = novo;
        }
      }
      // quem ouve: o citado pelo nome, senão o falante anterior, senão o próximo (presente e visível)
      bool alvoOk(String? q) => q != null && q != quem && visivel[q] == true;
      String? alvo;
      // quem a frase chama pelo nome e está longe (no celular): o gesto fica sem alvo, nada de apontar para outro
      final cod = _normalizar(t.cod);
      final chamaRemoto = remotos.keys.any((q) => _reNomes[q]?.hasMatch(cod) ?? false);
      if (!remoto && !chamaRemoto && (acao == AcaoAtor.acena || acao == AcaoAtor.aponta)) {
        for (final e in _reNomes.entries) {
          if (alvoOk(e.key) && e.value.hasMatch(cod)) {
            alvo = e.key;
            break;
          }
        }
        alvo ??= alvoOk(anterior) ? anterior : null;
        if (alvo == null) {
          for (var j = k + 1; j < licao.trechos.length; j++) {
            final p = quemNoPalco(licao.trechos[j].quem);
            if (p == quem) continue;
            if (alvoOk(p)) alvo = p;
            break;
          }
        }
      }
      final forte = emocao == Expressao.radiante || emocao == Expressao.triste || emocao == Expressao.surpreso;
      final camera = k == 0
          ? CameraHistoria.geral
          : forte && !remoto
              ? CameraHistoria.close
              : presentes.length == 2
                  ? CameraHistoria.medio
                  : CameraHistoria.geral;
      // a reação de quem ouvia (o falante anterior): só a emoção espelhada
      final reacoes = <ReacaoHistoria>[];
      final ouvinte = anterior;
      if (ouvinte != null && ouvinte != quem && (remotos.containsKey(ouvinte) || visivel[ouvinte] == true)) {
        final en = t.cod.toLowerCase();
        final r = _reObrigado.hasMatch(en)
            ? Expressao.feliz
            : en.contains('!') && _reSurpresa.hasMatch(en)
                ? Expressao.surpreso
                : en.contains('!') && _reCumprimento.hasMatch(en)
                    ? Expressao.feliz
                    : null;
        if (r != null) reacoes.add(ReacaoHistoria(quem: ouvinte, emocao: r));
      }
      passos.add(FalaHistoria(
        quem: quem,
        en: t.cod,
        pt: t.dicaPlana,
        acao: acao,
        emocao: emocao,
        alvo: alvo,
        camera: camera,
        efeito: g.efeito,
        segura: seguraNoPasso,
        reacoes: reacoes,
      ));
      anterior = quem;
    }

    // ── o fecho: a última frase é despedida → todo mundo acena (o rabo, no vão do fim da lição)
    final ultima = licao.trechos.isEmpty ? '' : licao.trechos.last.cod.toLowerCase();
    if (_reDespedida.hasMatch(ultima)) {
      final reacoes = <ReacaoHistoria>[
        for (final q in presentes)
          if (q != 'voce' && visivel[q] == true) ReacaoHistoria(quem: q, acao: AcaoAtor.acena, emocao: Expressao.feliz),
        for (final q in remotos.keys) ReacaoHistoria(quem: q, emocao: Expressao.feliz),
      ];
      passos.add(FalaHistoria(
        quem: 'voce',
        mudo: true,
        acao: AcaoAtor.acena,
        emocao: Expressao.feliz,
        reacoes: reacoes.take(4).toList(),
      ));
    }

    final cena = CenaHistoria(cenario: cenario, hora: hora, clima: clima, elenco: elenco, falas: passos);
    return HistoriaLicao.daLicao(licao, [cena], nivel: nivelDaEtapa(etapa), autoral: false);
  }

  static CenarioHistoria? _cenarioValido(CenarioHistoria? c) => c == null || cenariosSoDoTurismo.contains(c) ? null : c;

  /// O 1º lugar citado no texto (normalizado) e onde ele começa; null = nenhum.
  static (CenarioHistoria, int)? _lugar(String texto) {
    (CenarioHistoria, int)? melhor;
    for (final (cenario, re, contexto) in _gatilhos) {
      for (final m in re.allMatches(texto)) {
        if (contexto != null && !contexto(texto, m.start)) continue;
        if (melhor == null || m.start < melhor.$2) melhor = (cenario, m.start);
        break;
      }
    }
    return melhor;
  }

  /// Sem lugar citado: mensagem/telefone → `casa` (o aluno trabalha de casa); trabalho ou etapa DEV →
  /// `escritorio`; o resto → `casa`.
  static CenarioHistoria _semLugar(String texto, String etapa) {
    if (_reDistancia.hasMatch(texto)) return CenarioHistoria.casa;
    if (etapa.trim().toUpperCase().startsWith('DEV') || _reTrabalho.hasMatch(texto)) return CenarioHistoria.escritorio;
    return CenarioHistoria.casa;
  }

  /// Os canônicos citados pelo nome na cena, na ordem do texto (fora a posse: "um dia do Mike").
  static List<String> _citados(String texto) {
    final achados = <(int, String)>[];
    for (final e in _reNomes.entries) {
      for (final m in e.value.allMatches(texto)) {
        final antes = texto.substring(m.start - 30 < 0 ? 0 : m.start - 30, m.start);
        if (_rePreposicaoDePosse.hasMatch(antes) && !_rePosse.hasMatch(antes)) continue;
        achados.add((m.start, e.key));
        break;
      }
    }
    achados.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final a in achados) a.$2];
  }

  /// Quem a cena diz que entra/chega/aparece: o nome logo antes do verbo ([_reVaoDaEntrada]).
  static Set<String> _entradasNoTexto(String texto) {
    final r = <String>{};
    for (final v in _reEntrada.allMatches(texto)) {
      for (final e in _reNomes.entries) {
        for (final m in e.value.allMatches(texto)) {
          if (m.end <= v.start && _reVaoDaEntrada.hasMatch(texto.substring(m.end, v.start))) r.add(e.key);
        }
      }
    }
    return r;
  }

  /// Os canônicos citados perto de um verbo de falar de longe (logo depois dele, senão logo antes), na ordem
  /// do texto: "por vídeo, a Sarah e a Ana" → sarah, ana; "com a Sarah na chamada de vídeo" → sarah.
  static List<String> _longeNoTexto(String texto) {
    final r = <String>[];
    void nomesEm(int de, int ate) {
      final trecho = texto.substring(de < 0 ? 0 : de, ate > texto.length ? texto.length : ate);
      final achados = <(int, String)>[
        for (final e in _reNomes.entries)
          if (e.value.firstMatch(trecho) case final m?) (m.start, e.key),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
      for (final a in achados) {
        if (!r.contains(a.$2)) r.add(a.$2);
      }
    }

    for (final m in _reDistanciaComLugar.allMatches(texto)) {
      final antes = r.length;
      nomesEm(m.end, m.end + 25);
      if (r.length == antes) nomesEm(m.start - 16, m.start);
    }
    return r;
  }

  /// O cenário pela heurística (4.1): o 1º lugar citado na cena (com preposição de lugar e fronteira de
  /// palavra); sem lugar, `casa` (mensagem/telefone ou vida pessoal) ou `escritorio` (trabalho, etapa DEV).
  /// Nunca um cenário de `cenariosSoDoTurismo`.
  static CenarioHistoria cenarioDe(Licao licao, {required String etapa}) {
    final texto = _normalizar(licao.cena);
    return _lugar(texto)?.$1 ?? _semLugar(texto, etapa);
  }

  /// A hora (4.2): o 1º horário citado na cena; senão a 1ª frase (Good morning/afternoon/evening/night);
  /// senão `dia`. Sempre dentro de [horasPermitidas].
  static HoraHistoria horaDe(Licao licao, CenarioHistoria cenario) {
    final texto = _normalizar(licao.cena);
    HoraHistoria? hora;
    var onde = texto.length + 1;
    for (final (h, re) in [
      (HoraHistoria.noite, _reNoite),
      (HoraHistoria.tarde, _reTarde),
      (HoraHistoria.amanhecer, _reAmanhecer),
      (HoraHistoria.dia, _reDia),
    ]) {
      final m = re.firstMatch(texto);
      if (m != null && m.start < onde) {
        onde = m.start;
        hora = h;
      }
    }
    if (hora == null && licao.trechos.isNotEmpty) {
      final en = licao.trechos.first.cod.toLowerCase();
      if (en.contains('good morning')) {
        hora = HoraHistoria.dia;
      } else if (en.contains('good afternoon')) {
        hora = HoraHistoria.tarde;
      } else if (en.contains('good evening') || en.contains('good night')) {
        hora = HoraHistoria.noite;
      }
    }
    final permitidas = horasPermitidas(cenario);
    final h = hora ?? HoraHistoria.dia;
    if (permitidas.contains(h)) return h;
    return permitidas.contains(HoraHistoria.dia) ? HoraHistoria.dia : permitidas.first;
  }

  /// O gesto da frase (4.4): o emoji primeiro (por grafema, sem U+FE0F), depois o texto para o que o emoji
  /// não decidiu. `❓` só vira efeito com "Sorry?/What?/Pardon?"; `✍️`/`📝` escrevem segurando o documento.
  static GestoDaFrase gestoDe(Trecho t) {
    AcaoAtor? acao;
    Expressao? emocao;
    EfeitoHistoria? efeito;
    PropHistoria? segura;
    final en = t.cod.trim().toLowerCase();
    // 👋 só acena com cumprimento/despedida ("We missed the last train 🚆👋" é "foi embora")
    final aceno = _reCumprimento.hasMatch(en) || _reDespedida.hasMatch(en) || _reAceno.hasMatch(en);
    var negada = _reNao.hasMatch(en) || _reNaoNoComeco.hasMatch(en);
    for (final g in _grafemas(t.imagem)) {
      final k = _chaveDoEmoji(g);
      if (g.runes.any(_runasDeNegacao.contains)) negada = true;
      final a = _acaoDoEmoji[k];
      if (a != AcaoAtor.acena || k != '👋' || aceno) acao ??= a;
      emocao ??= _emocaoDoEmoji[k];
      final ef = _efeitoDoEmoji[k];
      if (ef != null && (ef != EfeitoHistoria.interrogacao || _reNaoEntendi.hasMatch(en))) efeito ??= ef;
      segura ??= _propDoEmoji[k];
    }
    if (negada) segura = null;
    if (acao == AcaoAtor.escreve) segura ??= PropHistoria.documento;
    // o texto, se o emoji não decidiu; o "Great…!" só comemora se o emoji não diz o contrário (🙄 = ironia)
    final viva = en.endsWith('!') && _reViva.hasMatch(en) && (emocao == null || _emocoesPositivas.contains(emocao));
    if (acao == null) {
      if (_reCumprimento.hasMatch(en)) {
        acao = AcaoAtor.acena;
      } else if (_reSenta.hasMatch(en)) {
        acao = AcaoAtor.senta;
      } else if (viva) {
        acao = AcaoAtor.comemora;
      } else if (_reNao.hasMatch(en)) {
        acao = AcaoAtor.nega; // antes do "thanks": "No, thanks." recusa
      } else if (_reObrigado.hasMatch(en) || _reSim.hasMatch(en) || _reSemProblema.hasMatch(en)) {
        acao = AcaoAtor.concorda;
      } else if (_reOlha.hasMatch(en)) {
        acao = AcaoAtor.aponta;
      }
    }
    if (emocao == null) {
      if (viva) {
        emocao = Expressao.radiante;
      } else if (_reNoWay.hasMatch(en)) {
        emocao = Expressao.surpreso;
      } else if (_reObrigado.hasMatch(en) && acao != AcaoAtor.nega) {
        // "No, thanks." recusa: o "thanks" não põe sorriso
        emocao = Expressao.feliz;
      } else if (_reDesculpa.hasMatch(en)) {
        emocao = Expressao.timido;
      } else if (en.contains('?')) {
        emocao = Expressao.pensativo;
      }
    }
    return GestoDaFrase(acao: acao ?? AcaoAtor.parado, emocao: emocao, efeito: efeito, segura: segura);
  }

  /// O ícone do chip do balão: os emojis da frase; na placa, 🪧. null = sem ícone.
  static String? iconeDe(Trecho t) {
    if (t.quem == 'placa') return '🪧';
    final i = t.imagem.trim();
    return i.isEmpty ? null : i;
  }
}
