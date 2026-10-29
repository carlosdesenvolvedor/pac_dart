import 'package:equatable/equatable.dart';

/// As três decisões possíveis em qualquer etapa (modelo, LLM, gabarito ou pesquisador).
enum Decisao {
  incluir,
  excluir,
  incerto;

  static Decisao? deTexto(String? t) => switch (t?.trim().toLowerCase()) {
    'incluir' || 'incluído' || 'incluido' || 'include' => Decisao.incluir,
    'excluir' || 'excluído' || 'excluido' || 'exclude' => Decisao.excluir,
    'incerto' || 'uncertain' => Decisao.incerto,
    _ => null,
  };
}

/// Artigo revisado por pares ou literatura cinzenta (blog, documentação, issue…), que costuma vir
/// sem resumo formal — um dos pontos que a pesquisa quer observar.
enum TipoFonte {
  artigo,
  literaturaCinzenta;

  static TipoFonte deTexto(String? t) => switch (t?.trim().toLowerCase()) {
    'literatura_cinzenta' ||
    'literatura cinzenta' ||
    'cinzenta' ||
    'blog' ||
    'issue' ||
    'documentacao' ||
    'discussao' ||
    'forum' ||
    'video' ||
    'post' => TipoFonte.literaturaCinzenta,
    _ => TipoFonte.artigo,
  };

  String get rotulo => this == artigo ? 'artigo' : 'literatura cinzenta';
}

class Estudo extends Equatable {
  final String id;
  final String titulo;
  final String resumo;
  final List<String> palavrasChave;
  final TipoFonte tipoFonte;
  final String url;

  /// A decisão humana de referência (null = estudo sem gabarito; fica fora das métricas).
  final Decisao? gabarito;

  const Estudo({
    required this.id,
    required this.titulo,
    this.resumo = '',
    this.palavrasChave = const [],
    this.tipoFonte = TipoFonte.artigo,
    this.url = '',
    this.gabarito,
  });

  factory Estudo.fromJson(Map<String, dynamic> j) => Estudo(
    id: '${j['id']}',
    titulo: '${j['titulo'] ?? ''}',
    resumo: '${j['resumo'] ?? ''}',
    palavrasChave: [for (final p in (j['palavras_chave'] as List? ?? const [])) '$p'],
    tipoFonte: TipoFonte.deTexto(j['tipo_fonte'] as String?),
    url: '${j['url'] ?? ''}',
    gabarito: Decisao.deTexto(j['gabarito'] as String?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'resumo': resumo,
    'palavras_chave': palavrasChave,
    'tipo_fonte': tipoFonte == TipoFonte.artigo ? 'artigo' : 'literatura_cinzenta',
    'url': url,
    'gabarito': gabarito?.name,
  };

  /// O "estado" enviado aos modelos: só o que importa para a decisão (o Jev perde precisão com
  /// informação irrelevante, então nada de url nem gabarito aqui).
  /// O site de origem da literatura cinzenta (ex.: github.com); null para artigo ou sem URL.
  String? get site {
    if (tipoFonte == TipoFonte.artigo || url.isEmpty) return null;
    final h = Uri.tryParse(url)?.host ?? '';
    return h.isEmpty ? null : h.replaceFirst(RegExp(r'^www\.'), '');
  }

  String get estadoTexto {
    final b = StringBuffer()
      ..writeln('Tipo de fonte: ${tipoFonte.rotulo}')
      ..writeln('Título: $titulo');
    if (site case final s?) b.writeln('Site: $s');
    if (resumo.isNotEmpty) b.writeln('${tipoFonte == TipoFonte.artigo ? 'Resumo' : 'Trecho do texto'}: $resumo');
    if (palavrasChave.isNotEmpty) b.writeln('Palavras-chave: ${palavrasChave.join(', ')}');
    return b.toString().trimRight();
  }

  @override
  List<Object?> get props => [id, titulo, resumo, palavrasChave, tipoFonte, url, gabarito];
}

/// Critério de inclusão, sempre escrito na forma positiva (sem "não").
class Criterio extends Equatable {
  final String id;
  final String texto;
  const Criterio(this.id, this.texto);

  factory Criterio.fromJson(Map<String, dynamic> j) => Criterio('${j['id']}', '${j['texto']}');
  Map<String, dynamic> toJson() => {'id': id, 'texto': texto};

  @override
  List<Object?> get props => [id, texto];
}

/// O arquivo de entrada: nome, critérios e estudos.
class ProjetoTriagem extends Equatable {
  final String nome;
  final List<Criterio> criterios;
  final List<Estudo> estudos;
  const ProjetoTriagem({required this.nome, required this.criterios, required this.estudos});

  factory ProjetoTriagem.fromJson(Map<String, dynamic> j) {
    final criterios = [
      for (final c in (j['criterios'] as List? ?? const [])) Criterio.fromJson(c as Map<String, dynamic>),
    ];
    final estudos = [for (final e in (j['estudos'] as List? ?? const [])) Estudo.fromJson(e as Map<String, dynamic>)];
    if (criterios.isEmpty) throw const FormatException('O arquivo não tem "criterios".');
    if (estudos.isEmpty) throw const FormatException('O arquivo não tem "estudos".');
    final ids = <String>{};
    for (final e in estudos) {
      if (!ids.add(e.id)) throw FormatException('Id de estudo repetido: ${e.id}');
    }
    return ProjetoTriagem(nome: '${j['projeto'] ?? 'Triagem'}', criterios: criterios, estudos: estudos);
  }

  Map<String, dynamic> toJson() => {
    'projeto': nome,
    'criterios': [for (final c in criterios) c.toJson()],
    'estudos': [for (final e in estudos) e.toJson()],
  };

  String get criteriosTexto => [for (final c in criterios) '${c.id}: ${c.texto}'].join('\n');

  @override
  List<Object?> get props => [nome, criterios, estudos];
}
