import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../ingles/domain/cartoes_texto.dart';
import 'seguranca_texto.dart';
import 'sessao_cenario.dart';

/// A correção do Prof. Dash para UMA fala do aluno (vem no mesmo JSON da resposta do personagem).
class CorrecaoTurno extends Equatable {
  static const maxPorque = 240, maxDica = 160, maxMelhor = 300;

  /// Tinha erro de verdade (false = "✅ Certinho!").
  final bool precisa;

  /// O jeito certo (em inglês), a tradução dele, o porquê (pt-BR) e a dica opcional.
  final String melhor, pt, porque, dica;

  /// [melhor]/[pt] vieram com marcador da máscara ([número]/[email]/[link]), já restaurado para a
  /// tela: essa correção não vira cartão nem item de setlist.
  final bool comDadosPessoais;

  const CorrecaoTurno({
    required this.precisa,
    this.melhor = '',
    this.pt = '',
    this.porque = '',
    this.dica = '',
    this.comDadosPessoais = false,
  });

  /// O cartão que a correção pode virar (validado por `prepararCartao`), ou null.
  CartaoEscrito? get cartao => precisa && !comDadosPessoais ? prepararCartao(melhor, pt).cartao : null;

  @override
  List<Object?> get props => [precisa, melhor, pt, porque, dica, comDadosPessoais];
}

/// Uma palavra solta da fala do personagem que pode ser nova para o aluno.
class PalavraSugerida extends Equatable {
  final String en, pt;
  const PalavraSugerida(this.en, this.pt);

  @override
  List<Object?> get props => [en, pt];
}

/// Um turno respondido: a fala do personagem e a correção da fala do aluno, num JSON só.
class RespostaTurno extends Equatable {
  static const maxFala = 300, maxTraducao = 400, maxSugestoes = 3, maxSugestao = 120, maxPalavras = 3;

  final String fala, traducao;
  final CorrecaoTurno? correcao;
  final List<String> sugestoes;
  final List<PalavraSugerida> palavras;
  final bool fim;

  /// false = veio como texto puro (só a fala).
  final bool estruturada;

  const RespostaTurno({
    required this.fala,
    this.traducao = '',
    this.correcao,
    this.sugestoes = const [],
    this.palavras = const [],
    this.fim = false,
    this.estruturada = true,
  });

  /// Só a fala, sem estrutura (serviço sem JSON ou modelo que ignorou o formato).
  factory RespostaTurno.simples(String fala) => RespostaTurno(fala: fala, estruturada: false);

  /// Tolerante; nunca lança. null = nenhuma fala aproveitável.
  /// [falaEnviada] = a fala do aluno EXATAMENTE como foi ao modelo (mascarada, sem marcadores);
  /// [trechos] = os originais que a máscara trocou, em ordem (`TextoMascarado.trechos`).
  static RespostaTurno? interpretar(String bruto, {required String falaEnviada, List<String> trechos = const []}) {
    // As cercas ```json em volta não atrapalham: o JSON vai do primeiro "{" ao último "}".
    final txt = bruto.trim();
    if (txt.isEmpty) return null;
    // O que vem depois de uma cerca ``` (ou ```json) de abertura: uma cerca truncada cedo
    // ("```json\n{\"cor") é JSON quebrado, não fala.
    final resto = txt.replaceFirst(_cercaDeAbertura, '').trim();
    final ini = txt.indexOf('{');
    if (ini < 0) return resto.isEmpty || resto.startsWith('[') ? null : _soFala(txt);

    final fimJson = txt.lastIndexOf('}');
    Object? j;
    if (fimJson > ini) j = _decodificar(txt.substring(ini, fimJson + 1));
    if (j is! Map) {
      // JSON truncado (MAX_TOKENS) ou quebrado: salva só a fala, se ela veio inteira.
      final m = RegExp(r'"fala"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(txt);
      if (m != null) {
        final f = _decodificar('"${m.group(1)}"');
        return f is String ? _soFala(f) : null;
      }
      // Sem cara de JSON (um "{" solto no meio do texto): é texto puro.
      if (resto.startsWith('{') || txt.contains('"fala"') || txt.contains('"correcao"')) return null;
      return _soFala(txt);
    }

    final fala = j['fala'] is String ? _cortarFrase(limparFala(j['fala'] as String), maxFala) : '';
    if (fala.isEmpty) return null;

    final sugestoes = <String>[];
    final vistasSug = <String>{fala.toLowerCase()};
    if (j['sugestoes'] is List) {
      for (final e in j['sugestoes'] as List) {
        if (e is! String) continue;
        final sug = limparFala(e);
        if (sug.isEmpty || sug.length > maxSugestao || !vistasSug.add(sug.toLowerCase())) continue;
        sugestoes.add(sug);
        if (sugestoes.length == maxSugestoes) break;
      }
    }

    final palavras = <PalavraSugerida>[];
    final vistasPal = <String>{};
    if (j['palavras'] is List) {
      for (final e in j['palavras'] as List) {
        if (e is! Map || e['en'] is! String || e['pt'] is! String) continue;
        final en = (e['en'] as String).trim().toLowerCase();
        final pt = _umaLinha(e['pt'] as String);
        if (!_palavraSolta.hasMatch(en) || _palavrasBasicas.contains(en)) continue;
        if (pt.isEmpty || pt.length > 60 || !vistasPal.add(en)) continue;
        palavras.add(PalavraSugerida(en, pt));
        if (palavras.length == maxPalavras) break;
      }
    }

    return RespostaTurno(
      fala: fala,
      traducao: _cortarFrase(_umaLinha(j['traducao'] is String ? j['traducao'] as String : ''), maxTraducao),
      correcao: _correcao(j['correcao'], falaEnviada, trechos),
      sugestoes: sugestoes,
      palavras: palavras,
      fim: j['fim'] == true,
    );
  }

  /// `jsonDecode` tolerante: quebra de linha/tab CRUA dentro de uma string (o `jsonDecode` recusa:
  /// "Control character in string") vira espaço numa 2ª tentativa — fora das strings é só espaço, e
  /// todo campo passa por `_umaLinha`/`limparFala`. null = ilegível.
  static Object? _decodificar(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {}
    try {
      return jsonDecode(s.replaceAll(RegExp(r'[\r\n\t]'), ' '));
    } catch (_) {
      return null;
    }
  }

  static RespostaTurno? _soFala(String t) {
    final f = _cortarFrase(limparFala(t), maxFala);
    return f.isEmpty ? null : RespostaTurno.simples(f);
  }

  static CorrecaoTurno? _correcao(Object? c, String falaEnviada, List<String> trechos) {
    if (c is! Map) return null;
    String campo(String k, int max) => c[k] is String ? _cortarFrase(_umaLinha(c[k] as String), max) : '';
    var melhor = campo('melhor', CorrecaoTurno.maxMelhor);
    var pt = campo('pt', RespostaTurno.maxTraducao);
    // Correção vazia, ou igual ao que foi ENVIADO (mascarado) tirando maiúsculas/pontuação: não é correção.
    if (c['precisa'] != true || melhor.isEmpty || _normalizar(melhor) == _normalizar(falaEnviada)) {
      return const CorrecaoTurno(precisa: false);
    }
    // Marcador da máscara, ou um marcador que o modelo traduziu/inventou ("[number]", "[phone number]"):
    // nos dois casos a correção não vira cartão nem item de setlist.
    final comDados = temMarcadorDeDados(melhor) ||
        temMarcadorDeDados(pt) ||
        _marcadorQualquer.hasMatch(melhor) ||
        _marcadorQualquer.hasMatch(pt);
    if (comDados) {
      melhor = restaurarDados(melhor, trechos);
      pt = restaurarDados(pt, trechos);
    }
    return CorrecaoTurno(
      precisa: true,
      melhor: melhor,
      pt: pt,
      porque: campo('porque', CorrecaoTurno.maxPorque),
      dica: campo('dica', CorrecaoTurno.maxDica),
      comDadosPessoais: comDados,
    );
  }

  @override
  List<Object?> get props => [fala, traducao, correcao, sugestoes, palavras, fim, estruturada];
}

/// A limpeza da fala do personagem: tira cercas ```, crases, *, _, # e emoji (a parte do emoji reusa a
/// regra do `textoFalavel`) e aspas em volta "…"/“…”, e junta os espaços. NÃO INSERE TEXTO: ao contrário
/// do `textoFalavel`, um bloco de código não vira frase em português.
String limparFala(String t) {
  var s = t.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  s = s.replaceAll(RegExp(r'[`*_#]'), '');
  s = s.replaceAll(_emoji, '');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  // Aspas em volta da fala inteira ("…" ou “…”).
  while (s.length >= 2 &&
      ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith('“') && s.endsWith('”')))) {
    s = s.substring(1, s.length - 1).trim();
  }
  return s;
}

/// A mesma regra de emoji do `textoFalavel`.
final _emoji = RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}]', unicode: true);

/// Cerca ``` de abertura (com ou sem a linguagem: ```json).
final _cercaDeAbertura = RegExp(r'^```[a-zA-Z]*');

/// Um marcador entre colchetes em qualquer língua ([número], [number], [phone number]…).
final _marcadorQualquer = RegExp(r'\[[^\]\n]{2,20}\]');

/// Uma palavra solta, a mesma regra do `validarPalavraNova` (só letras, 2 a 14) já em minúsculas.
final _palavraSolta = RegExp(r'^[a-z]{2,14}$');

/// Palavras básicas demais para virar "palavra nova".
const _palavrasBasicas = {
  'the', 'a', 'an', 'you', 'i', 'is', 'are', 'to', 'of', 'and', 'it', 'in', 'on', 'for', 'my', 'your', 'me', 'we', 'be', 'do',
};

String _umaLinha(String t) => t.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Corta em [max]: no último ".", "?" ou "!" antes do limite; sem isso, corte seco com "…".
String _cortarFrase(String t, int max) {
  if (t.length <= max) return t;
  final s = t.substring(0, max);
  final fim = s.lastIndexOf(RegExp(r'[.?!](?=\s|$)'));
  if (fim > 0) return s.substring(0, fim + 1);
  return '${s.substring(0, max - 1).trimRight()}…';
}

/// Minúsculas, sem pontuação e sem espaço sobrando (para "a correção é igual à fala?").
/// O apóstrofo some ANTES (sem virar espaço): "dont" e "don't" são a mesma fala — contração não se corrige.
String _normalizar(String t) => t
    .toLowerCase()
    .replaceAll(RegExp("['’‘`]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// O esquema JSON de um turno (formato REST, usado pelo `GeminiTutorService.perguntarJson`).
/// `correcao` vem primeiro no `propertyOrdering` de propósito: o modelo julga a fala do aluno antes
/// de escrever a resposta.
const Map<String, Object?> esquemaTurno = {
  'type': 'OBJECT',
  'properties': {
    'correcao': {
      'type': 'OBJECT',
      'properties': {
        'precisa': {'type': 'BOOLEAN'},
        'melhor': {'type': 'STRING'},
        'pt': {'type': 'STRING'},
        'porque': {'type': 'STRING'},
        'dica': {'type': 'STRING'},
      },
      'required': ['precisa'],
    },
    'fala': {'type': 'STRING'},
    'traducao': {'type': 'STRING'},
    'sugestoes': {
      'type': 'ARRAY',
      'items': {'type': 'STRING'},
    },
    'palavras': {
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'en': {'type': 'STRING'},
          'pt': {'type': 'STRING'},
        },
        'required': ['en', 'pt'],
      },
    },
    'fim': {'type': 'BOOLEAN'},
  },
  'required': ['correcao', 'fala', 'traducao', 'fim'],
  'propertyOrdering': ['correcao', 'fala', 'traducao', 'sugestoes', 'palavras', 'fim'],
};

/// O mesmo contrato em palavras, para os serviços sem `TutorJson` (vai no fim da pergunta).
const String formatoTurnoTexto = 'Devolva SOMENTE um JSON válido (sem texto antes ou depois): '
    '{"correcao":{"precisa":true|false,"melhor":"...","pt":"...","porque":"...","dica":"..."},'
    '"fala":"...","traducao":"...","sugestoes":["..."],"palavras":[{"en":"...","pt":"..."}],"fim":true|false}';

/// Uma correção do resumo: a fala do aluno e o que o Prof. Dash disse dela.
class ItemCorrecao extends Equatable {
  final String sua;
  final CorrecaoTurno correcao;
  const ItemCorrecao(this.sua, this.correcao);

  @override
  List<Object?> get props => [sua, correcao];
}

/// O resumo do fim da conversa: local, feito das correções de cada turno (0 usos, nunca falha).
class ResumoConversa extends Equatable {
  static const maxPalavras = 8;

  /// Quantas falas o aluno deu e quantas saíram certas de primeira.
  final int falas, certas;
  final List<ItemCorrecao> correcoes;
  final List<PalavraSugerida> palavras;

  /// exemplos[i] = a fala do personagem em que palavras[i] apareceu ('' quando a palavra não está nela).
  final List<String> exemplos;

  const ResumoConversa({
    required this.falas,
    required this.certas,
    this.correcoes = const [],
    this.palavras = const [],
    this.exemplos = const [],
  });

  /// O resumo de [s] (uma fala do aluno ainda sem resposta não conta).
  factory ResumoConversa.de(SessaoCenario s) {
    final turnos = s.esperandoDash ? s.turnos.sublist(0, s.turnos.length - 1) : s.turnos;
    var falas = 0, certas = 0;
    final correcoes = <ItemCorrecao>[];
    final palavras = <PalavraSugerida>[];
    final exemplos = <String>[];
    final vistas = <String>{};
    for (final t in turnos) {
      if (t.doAluno) {
        falas++;
        final c = t.correcao;
        if (c == null) continue;
        if (c.precisa) {
          correcoes.add(ItemCorrecao(t.texto, c));
        } else {
          certas++;
        }
      } else {
        for (final p in t.palavras) {
          if (palavras.length >= maxPalavras) break;
          if (!vistas.add(p.en.toLowerCase())) continue;
          palavras.add(p);
          // só é exemplo se a palavra (ou uma forma dela: "order" em "ordered") está na fala; senão, nenhum
          final naFala = RegExp('\\b${RegExp.escape(p.en)}', caseSensitive: false).hasMatch(t.texto);
          exemplos.add(naFala ? t.texto : '');
        }
      }
    }
    return ResumoConversa(falas: falas, certas: certas, correcoes: correcoes, palavras: palavras, exemplos: exemplos);
  }

  @override
  List<Object?> get props => [falas, certas, correcoes, palavras, exemplos];
}
