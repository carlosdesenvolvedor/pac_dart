/// As vertentes do app: cada uma tem o próprio currículo, o próprio
/// progresso e a própria marca (PAC·DART, PAC·C#, PAC·ENGLISH).
enum Linguagem {
  dart(
    id: 'dart',
    marca: 'DART',
    subtitulo: 'DART & FLUTTER',
    nomeCurso: 'Dart & Flutter',
    pastaAssets: 'assets',
    prefixoProgresso: '',
    emoji: '🎯',
  ),
  csharp(
    id: 'csharp',
    marca: 'C#',
    subtitulo: 'C# & .NET',
    nomeCurso: 'C# & .NET',
    pastaAssets: 'assets/csharp',
    prefixoProgresso: 'cs_',
    emoji: '🟣',
  ),

  /// Curso de inglês: o "trecho" é uma FRASE em inglês (cod) com a tradução
  /// em cima (dica). Não é linguagem de programação — nada de sintaxe,
  /// copiar ou rodar.
  ingles(
    id: 'ingles',
    marca: 'ENGLISH',
    subtitulo: 'INGLÊS',
    nomeCurso: 'Inglês',
    pastaAssets: 'assets/ingles',
    prefixoProgresso: 'en_',
    emoji: '🗽',
  );

  const Linguagem({
    required this.id,
    required this.marca,
    required this.subtitulo,
    required this.nomeCurso,
    required this.pastaAssets,
    required this.prefixoProgresso,
    required this.emoji,
  });

  /// Chave estável (preferências, Firestore).
  final String id;

  /// O que vem depois de "PAC·" no logo.
  final String marca;

  /// Linha pequena embaixo do logo.
  final String subtitulo;

  /// Nome do curso em texto corrido ("Sua jornada C# & .NET").
  final String nomeCurso;

  final String pastaAssets;

  /// Prefixo dos campos de progresso. O Dart fica SEM prefixo para o
  /// progresso de quem já estudava continuar onde estava.
  final String prefixoProgresso;
  final String emoji;

  String get curriculo => '$pastaAssets/curriculo.json';
  String get master => '$pastaAssets/master.json';

  /// Só o Dart tem o mapa do que roda no DartPad.
  String? get rodaveis => this == Linguagem.dart ? 'assets/roda.json' : null;

  /// "PAC·DART", "PAC·C#", "PAC·ENGLISH".
  String get nomeApp => 'PAC·$marca';

  /// É um curso de programação (código, sintaxe, copiar/rodar, arcade de
  /// lógica)? O inglês não é.
  bool get ehProgramacao => this != Linguagem.ingles;

  static Linguagem? porId(String? id) {
    for (final l in values) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// Linguagem em uso agora — como `Mixart.atual`: quem pinta código
  /// (destaque de sintaxe, botão copiar) lê daqui sem precisar de contexto.
  /// Quem troca é o `LinguagemCubit`; nos testes antigos fica Dart.
  static Linguagem atual = Linguagem.dart;
}
