import 'package:equatable/equatable.dart';

/// Trilha → Lição → Trecho (um exercício de digitação).
class Trilha extends Equatable {
  final String nivel;
  final String emoji;

  /// Frase curta descrevendo o que a trilha ensina (pode ser vazia).
  final String descricao;
  final List<Licao> licoes;

  /// Projetos "Mão na Massa" ao fim do módulo (programas completos).
  final List<Projeto> projetos;

  /// Etapa da carreira (C#): Iniciante, Intermediário, Avançado ou Sênior.
  /// Vazia nas trilhas do Dart.
  final String etapa;

  /// Foto de fundo da fase (fundamentos, logica…); vazio = pelo nome.
  final String fundo;

  /// Como o código da trilha roda (C#): console, web, testes, biblioteca,
  /// unity, godot, monogame. Decide o texto do botão "copiar".
  final String perfil;

  /// Desafios de lógica (não são de digitação) com o que foi visto até aqui.
  final List<DesafioLogica> desafios;

  const Trilha({
    required this.nivel,
    required this.emoji,
    this.descricao = '',
    required this.licoes,
    this.projetos = const [],
    this.etapa = '',
    this.fundo = '',
    this.perfil = '',
    this.desafios = const [],
  });

  bool get temDesafios => desafios.isNotEmpty;

  /// Trilha especial só de projetos (ex.: "Teste Master").
  bool get soProjetos => licoes.isEmpty && projetos.isNotEmpty;
  bool get temProjetos => projetos.isNotEmpty;

  factory Trilha.fromJson(Map<String, dynamic> j) => Trilha(
        nivel: j['nivel'] as String,
        emoji: j['emoji'] as String,
        descricao: (j['descricao'] ?? '') as String,
        licoes: ((j['licoes'] ?? const []) as List)
            .map((e) => Licao.fromJson(e as Map<String, dynamic>))
            .toList(),
        projetos: ((j['projetos'] ?? const []) as List)
            .map((e) => Projeto.fromJson(e as Map<String, dynamic>))
            .toList(),
        etapa: (j['etapa'] ?? '') as String,
        fundo: (j['fundo'] ?? '') as String,
        perfil: (j['perfil'] ?? '') as String,
        desafios: ((j['desafios'] ?? const []) as List)
            .map((e) => DesafioLogica.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [nivel, emoji, descricao, licoes, projetos, etapa, fundo, perfil, desafios];
}

/// Um projeto/app completo que a pessoa digita ("Mão na Massa" / Teste Master).
class Projeto extends Equatable {
  final String nome;
  final String emoji;
  final String descricao;
  final String cod;
  final String out;
  final bool flutter;

  const Projeto({
    required this.nome,
    required this.emoji,
    required this.descricao,
    required this.cod,
    required this.out,
    this.flutter = false,
  });

  factory Projeto.fromJson(Map<String, dynamic> j) => Projeto(
        nome: j['nome'] as String,
        emoji: (j['emoji'] ?? '🛠️') as String,
        descricao: (j['descricao'] ?? '') as String,
        cod: j['cod'] as String,
        out: (j['out'] ?? '') as String,
        flutter: (j['flutter'] ?? false) as bool,
      );

  /// Converte para um Trecho, para reusar o motor de digitação.
  Trecho get comoTrecho => Trecho(cod: cod, dica: descricao, out: out);

  @override
  List<Object?> get props => [nome, emoji, descricao, cod, out, flutter];
}

/// Um bloco da teoria ("Nivelamento") de uma lição.
class BlocoTeoria extends Equatable {
  /// h (subtítulo), p (parágrafo), code (código), tip (dica), warn (cuidado).
  final String tipo;
  final String conteudo;

  /// Linguagem de um bloco `code` que não é a do curso (bash, json, xml,
  /// sql…) — pinta sem destaque de sintaxe. Vazio = a linguagem do curso.
  final String linguagem;

  const BlocoTeoria({required this.tipo, required this.conteudo, this.linguagem = ''});

  factory BlocoTeoria.fromJson(Map<String, dynamic> j) => BlocoTeoria(
        tipo: (j['t'] ?? 'p') as String,
        conteudo: (j['c'] ?? '') as String,
        linguagem: (j['l'] ?? '') as String,
      );

  @override
  List<Object?> get props => [tipo, conteudo, linguagem];
}

class Licao extends Equatable {
  final String nome;
  final String emoji;

  /// Visão geral do que a lição ensina (pode ser vazia).
  final String resumo;

  /// Teoria em blocos, lida antes de praticar (pode ser vazia).
  final List<BlocoTeoria> teoria;
  final List<Trecho> trechos;

  /// Inglês: a situação da cena em uma frase ("No café perto do hotel…").
  final String cena;

  /// Inglês: id estável da lição ("presente-simples.gosto-de-cafe") — a
  /// chave do progresso, imune a trilhas novas entrando no meio do curso.
  final String id;

  /// Inglês: a cena em 2–4 emojis (âncora visual, também na revisão).
  final String imagem;

  /// Inglês: visualização guiada, em 2ª pessoa e no presente ("Você está no
  /// balcão de um café em Chicago…") — ver a cena antes de falar.
  final String visualizacao;

  /// Inglês: foto real da cena (asset) e o crédito dela (licença aberta).
  final String foto;
  final String fotoCredito;

  const Licao({
    required this.nome,
    required this.emoji,
    this.resumo = '',
    this.cena = '',
    this.id = '',
    this.imagem = '',
    this.visualizacao = '',
    this.foto = '',
    this.fotoCredito = '',
    this.teoria = const [],
    required this.trechos,
  });

  bool get temTeoria => teoria.isNotEmpty;

  factory Licao.fromJson(Map<String, dynamic> j) => Licao(
        nome: j['nome'] as String,
        emoji: j['emoji'] as String,
        resumo: (j['resumo'] ?? '') as String,
        cena: (j['cena'] ?? '') as String,
        id: (j['id'] ?? '') as String,
        imagem: (j['imagem'] ?? '') as String,
        visualizacao: (j['visualizacao'] ?? '') as String,
        foto: (j['foto'] ?? '') as String,
        fotoCredito: (j['foto_credito'] ?? '') as String,
        teoria: ((j['teoria'] ?? const []) as List)
            .map((e) => BlocoTeoria.fromJson(e as Map<String, dynamic>))
            .toList(),
        trechos: (j['trechos'] as List).map((e) => Trecho.fromJson(e as Map<String, dynamic>)).toList(),
      );

  @override
  List<Object?> get props => [nome, emoji, resumo, teoria, trechos, cena, id, imagem, visualizacao, foto, fotoCredito];
}

class Trecho extends Equatable {
  /// Código a digitar (com \n reais e indentação de 2 espaços).
  final String cod;

  /// Dica curta; pode conter marcação <b>…</b>.
  final String dica;

  /// Saída esperada mostrada no console ao "compilar".
  final String out;

  /// Explicação aprofundada opcional ("Entenda melhor").
  final String conceito;

  /// Trecho que não é código da linguagem do curso (um comando `dotnet`,
  /// um appsettings.json…): bash, json, xml, sql… Vazio = a do curso.
  final String linguagem;

  /// Inglês: tradução palavra por palavra ("Eu tenho fome" → "Eu estou
  /// faminto"), mostrada sob a tradução natural quando ajuda a entender a
  /// estrutura. Vazio nos cursos de programação.
  final String literal;

  /// Inglês: o pedaço da frase que a lição ensina (um chunk do [cod]),
  /// destacado ao digitar. Vazio = sem destaque.
  final String alvo;

  /// Inglês: o trecho da tradução que corresponde ao [alvo] (destacado no PT).
  final String alvoPt;

  /// Inglês: a fala anterior da cena (desambigua respostas como "Yes, please.").
  final String contexto;

  /// Inglês: a mesma fala em português e o índice dela na lição (-1 = não é
  /// frase do curso). Enquanto aquela frase não foi concluída, o app mostra
  /// o PT — o inglês dela ainda está sendo decorado.
  final String contextoPt;
  final int contextoDe;

  /// Inglês: id opaco e estável da frase ("f-7c1e2a") — a chave da revisão
  /// espaçada. Vazio = usa o hash do texto.
  final String id;

  /// Inglês: frase que representa a lição no teste de nivelamento.
  final bool teste;

  /// Inglês: gravação de um falante nativo das MESMAS palavras (Tatoeba),
  /// asset mp3 tocado no lugar da voz sintética. Vazio = voz do navegador.
  final String audio;

  /// Inglês: autor e licença da [audio] ("CK · CC BY-NC-ND 3.0") — a
  /// licença exige atribuição.
  final String audioCredito;

  /// Inglês: quem fala ("voce", "mike", "atendente"…). Vazio = narrador.
  final String quem;

  /// Inglês: formas equivalentes aceitas de memória (I'd ↔ I would).
  final List<String> alternativas;

  /// Inglês: a imagem do SENTIDO da frase (1–3 emojis), mostrada junto da
  /// tradução em todas as digitações — palavra + imagem fixam mais
  /// (codificação dupla) e, de memória, ela vira pista.
  final String imagem;

  /// Inglês: de onde veio a frase, quando não é autoral —
  /// `tatoeba:idEN:autorEN:idPT:autorPT:adaptada` (PT "-" = tradução do curso)
  /// (CC BY 2.0 FR exige atribuição). Vazio = frase do curso.
  final String fonte;

  const Trecho({
    required this.cod,
    required this.dica,
    required this.out,
    this.conceito = '',
    this.linguagem = '',
    this.literal = '',
    this.alvo = '',
    this.fonte = '',
    this.alvoPt = '',
    this.contexto = '',
    this.quem = '',
    this.alternativas = const [],
    this.imagem = '',
    this.contextoPt = '',
    this.contextoDe = -1,
    this.id = '',
    this.teste = false,
    this.audio = '',
    this.audioCredito = '',
  });

  factory Trecho.fromJson(Map<String, dynamic> j) => Trecho(
        cod: j['cod'] as String,
        dica: (j['dica'] ?? '') as String,
        out: (j['out'] ?? '') as String,
        conceito: (j['conceito'] ?? '') as String,
        linguagem: (j['l'] ?? '') as String,
        literal: (j['lit'] ?? '') as String,
        alvo: (j['alvo'] ?? '') as String,
        fonte: (j['src'] ?? '') as String,
        alvoPt: (j['alvo_pt'] ?? '') as String,
        contexto: (j['contexto'] ?? '') as String,
        quem: (j['quem'] ?? '') as String,
        alternativas: ((j['alt'] ?? const []) as List).map((e) => e.toString()).toList(),
        imagem: (j['img'] ?? '') as String,
        contextoPt: (j['contexto_pt'] ?? '') as String,
        contextoDe: (j['contexto_de'] ?? -1) as int,
        id: (j['id'] ?? '') as String,
        teste: (j['teste'] ?? false) as bool,
        audio: (j['au'] ?? '') as String,
        audioCredito: (j['au_cred'] ?? '') as String,
      );

  /// É código da linguagem do curso (entra no programa do botão "copiar")?
  bool get ehCodigoDoCurso => linguagem.isEmpty || linguagem == 'cs' || linguagem == 'dart';

  /// Remove a marcação <b>/<code> de um texto (para TTS e cartões).
  static String semTags(String s) =>
      s.replaceAll(RegExp(r'</?b>'), '').replaceAll(RegExp(r'</?code>'), '');

  /// Dica sem a marcação, para TTS e cartões.
  String get dicaPlana => semTags(dica);

  bool get temConceito => conceito.isNotEmpty;

  @override
  List<Object?> get props =>
      [cod, dica, out, conceito, linguagem, literal, alvo, fonte, alvoPt, contexto, quem, alternativas, imagem,
        contextoPt, contextoDe, id, teste, audio, audioCredito];
}

/// Tipos de desafio de lógica (não são de digitação).
enum TipoDesafioLogica {
  /// "O que este programa imprime?" — 4 alternativas de saída.
  saida,

  /// "Qual o valor final de X?" — a pessoa DIGITA a resposta.
  valor,

  /// Código com uma lacuna ___ — 4 alternativas para preencher.
  lacuna,

  /// Cartões embaralhados — pôr na ordem certa (Parsons).
  ordenar,

  /// Código com uma linha errada — tocar na linha do bug.
  bug,

  /// Pergunta conceitual de múltipla escolha.
  escolha;

  static TipoDesafioLogica? porNome(String? n) {
    for (final t in values) {
      if (t.name == n) return t;
    }
    return null;
  }
}

/// Um desafio de lógica da trilha. O gabarito foi tirado da execução REAL
/// do código (laboratório do PAC·C#), não escrito à mão.
class DesafioLogica extends Equatable {
  final TipoDesafioLogica tipo;
  final String titulo;
  final String enunciado;

  /// Código mostrado (saida/valor/lacuna/escolha). Na lacuna tem um `___`.
  final String cod;
  final List<String> opcoes;
  final int certa;

  /// Tipo valor: resposta canônica + outras aceitas.
  final String resposta;
  final List<String> aceitas;

  /// Tipo ordenar: cartões na ordem certa. Tipo bug: as linhas do código.
  final List<String> linhas;

  /// Tipo bug: índice da linha com defeito e a linha corrigida.
  final int linhaBug;
  final String correcao;

  /// Saída que o código certo produz (lacuna/ordenar/bug).
  final String esperado;
  final String explicacao;

  /// 1 (fácil) a 3 (difícil).
  final int nivel;

  /// "jogo" quando o desafio tem tema de game.
  final String tema;

  const DesafioLogica({
    required this.tipo,
    required this.titulo,
    required this.enunciado,
    this.cod = '',
    this.opcoes = const [],
    this.certa = 0,
    this.resposta = '',
    this.aceitas = const [],
    this.linhas = const [],
    this.linhaBug = -1,
    this.correcao = '',
    this.esperado = '',
    this.explicacao = '',
    this.nivel = 1,
    this.tema = '',
  });

  bool get ehJogo => tema == 'jogo';

  static List<String> _strs(Object? v) => ((v ?? const []) as List).map((e) => e.toString()).toList();

  factory DesafioLogica.fromJson(Map<String, dynamic> j) => DesafioLogica(
        tipo: TipoDesafioLogica.porNome(j['tipo'] as String?) ?? TipoDesafioLogica.escolha,
        titulo: (j['titulo'] ?? '') as String,
        enunciado: (j['enunciado'] ?? '') as String,
        cod: (j['cod'] ?? '') as String,
        opcoes: _strs(j['opcoes']),
        certa: (j['certa'] ?? 0) as int,
        resposta: (j['resposta'] ?? '') as String,
        aceitas: _strs(j['aceitas']),
        linhas: _strs(j['linhas']),
        linhaBug: (j['linhaBug'] ?? -1) as int,
        correcao: (j['correcao'] ?? '') as String,
        esperado: (j['esperado'] ?? '') as String,
        explicacao: (j['explicacao'] ?? '') as String,
        nivel: (j['nivel'] ?? 1) as int,
        tema: (j['tema'] ?? '') as String,
      );

  @override
  List<Object?> get props => [tipo, titulo, enunciado, cod, opcoes, certa, resposta, aceitas, linhas, linhaBug,
        correcao, esperado, explicacao, nivel, tema];
}
