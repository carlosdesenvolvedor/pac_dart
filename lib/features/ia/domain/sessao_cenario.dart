import 'package:equatable/equatable.dart';

import 'cenario.dart';
import 'conversa_resposta.dart';
import 'explicacao.dart';
import 'seguranca_texto.dart';

/// Uma fala da conversa.
class Turno extends Equatable {
  final bool doAluno;
  final String texto;

  /// A tradução (fala do personagem).
  final String traducao;

  /// A correção do Prof. Dash (fala do aluno; null até a resposta chegar, ou quando ela veio sem estrutura).
  final CorrecaoTurno? correcao;

  /// Ideias de resposta (fala do personagem).
  final List<String> sugestoes;

  /// Palavras que podem ser novas (fala do personagem).
  final List<PalavraSugerida> palavras;

  const Turno({
    required this.doAluno,
    required this.texto,
    this.traducao = '',
    this.correcao,
    this.sugestoes = const [],
    this.palavras = const [],
  });

  @override
  List<Object?> get props => [doAluno, texto, traducao, correcao, sugestoes, palavras];
}

/// A conversa de um cenário, como máquina de turnos pura: o personagem abre; a pessoa fala, o
/// personagem responde (e o Prof. Dash corrige a fala da pessoa no mesmo turno)… até a pessoa dar as
/// [Cenario.maxTurnos] falas ou o personagem encerrar a cena. Nada de IA aqui: só o estado e o
/// histórico que vai ao modelo.
class SessaoCenario extends Equatable {
  /// O que a pessoa escreve num turno é cortado aqui (custo e injeção de prompt).
  static const maxFala = PedidoExplicacao.maxResposta;

  /// Quantas falas anteriores vão no histórico do pedido (memória curta, custo previsível).
  static const falasNoHistorico = 8;

  final Cenario cenario;
  final List<Turno> turnos;

  /// O personagem encerrou a cena (o `fim` do modelo foi aceito).
  final bool fechada;

  const SessaoCenario._(this.cenario, this.turnos, {this.fechada = false});

  /// Começa com a abertura do personagem (fixa: não gasta cota), com a tradução e as primeiras ideias
  /// de resposta (as dicas do cenário).
  factory SessaoCenario.nova(Cenario c) => SessaoCenario._(c, [
        Turno(doAluno: false, texto: c.abertura, traducao: c.aberturaPt, sugestoes: c.dicas.take(3).toList()),
      ]);

  int get turnosDoAluno => turnos.where((t) => t.doAluno).length;

  /// A pessoa falou e o personagem ainda não respondeu (ou a resposta falhou).
  bool get esperandoDash => turnos.last.doAluno;

  /// A pessoa já deu todas as falas e o personagem respondeu a última, ou o personagem fechou a cena.
  bool get encerrada => (turnosDoAluno >= cenario.maxTurnos && !esperandoDash) || fechada;

  /// É a última fala da pessoa? (o personagem então se despede)
  bool get ultimaFala => turnosDoAluno >= cenario.maxTurnos;

  /// Pode escrever mais uma fala?
  bool get podeFalar => !esperandoDash && !encerrada && turnosDoAluno < cenario.maxTurnos;

  /// A fala da pessoa, cortada e numa linha só; vazia = ignorada (nada muda).
  SessaoCenario aluno(String texto) {
    if (!podeFalar) return this;
    var t = texto.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return this;
    if (t.length > maxFala) t = t.substring(0, maxFala);
    return SessaoCenario._(cenario, [...turnos, Turno(doAluno: true, texto: t)], fechada: fechada);
  }

  /// A resposta do personagem (e a correção do Prof. Dash) à última fala da pessoa: a correção vai
  /// para o turno da pessoa, a fala entra como turno do personagem; `fechada` = `r.fim` aceito
  /// (`turnosDoAluno >= 2 || ultimaFala`: um modelo que encerra na 1ª fala é ignorado).
  /// Sem fala pendente ou com `r.fala` vazia → this.
  SessaoCenario responder(RespostaTurno r) {
    final fala = r.fala.trim();
    if (!esperandoDash || fala.isEmpty) return this;
    final dele = turnos.last;
    final fecha = r.fim && (turnosDoAluno >= 2 || ultimaFala);
    return SessaoCenario._(
      cenario,
      [
        ...turnos.sublist(0, turnos.length - 1),
        Turno(doAluno: true, texto: dele.texto, correcao: r.correcao),
        Turno(doAluno: false, texto: fala, traducao: r.traducao, sugestoes: r.sugestoes, palavras: r.palavras),
      ],
      fechada: fechada || fecha,
    );
  }

  /// As ideias de resposta da última fala do personagem.
  List<String> get sugestoesAtuais {
    for (final t in turnos.reversed) {
      if (!t.doAluno) return t.sugestoes;
    }
    return const [];
  }

  /// A resposta do personagem só em texto (sem correção nem estrutura).
  SessaoCenario dash(String texto) => responder(RespostaTurno.simples(texto.trim()));

  /// Desfaz a última fala da pessoa (o personagem não respondeu: a pessoa tenta de novo sem perder o texto).
  SessaoCenario semUltimaFala() =>
      esperandoDash ? SessaoCenario._(cenario, turnos.sublist(0, turnos.length - 1), fechada: fechada) : this;

  /// A conversa até aqui em "Aluno: …" / "{nome do personagem}: …" (as últimas [falasNoHistorico]),
  /// SEM a fala atual da pessoa e com os dados pessoais das falas dela mascarados. Sem correções.
  String historicoParaResposta() {
    final antes = esperandoDash ? turnos.sublist(0, turnos.length - 1) : turnos;
    final ultimas = antes.length <= falasNoHistorico ? antes : antes.sublist(antes.length - falasNoHistorico);
    return _formatar(ultimas, mascarar: true);
  }

  /// A conversa inteira, como está (local: nunca vai ao modelo).
  String transcricao() => _formatar(turnos);

  /// [mascarar] = a cópia que vai ao modelo: dados pessoais mascarados e marcadores forjados
  /// (`<<<FIM>>>`/`<<<ALUNO>>>`) tirados — senão uma fala antiga reabriria um bloco falso no histórico.
  String _formatar(Iterable<Turno> ts, {bool mascarar = false}) => [
        for (final t in ts)
          t.doAluno
              ? 'Aluno: ${mascarar ? mascararDadosPessoais(semMarcadores(t.texto)) : t.texto}'
              : '${cenario.nomePersonagem}: ${t.texto}',
      ].join('\n');

  @override
  List<Object?> get props => [cenario, turnos, fechada];
}
