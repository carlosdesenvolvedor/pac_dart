import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../curso/presentation/bloc/typing_bloc.dart';

/// Monta o "campo de visão" do Prof. Dash: tudo o que o aluno está
/// estudando AGORA, num texto curto que vai junto de cada pergunta.
String contextoDoEstudo(CursoState curso, TypingState typing) {
  if (curso.status != CursoStatus.pronto) {
    return 'O aluno está abrindo o app (currículo ainda carregando).';
  }
  final trilha = curso.trilha;
  final licao = curso.licao;
  final trecho = curso.trecho;

  final teoria = [
    for (final b in licao.teoria)
      if (b.tipo == 'p') Trecho.semTags(b.conteudo),
  ].take(2).join(' ');

  final b = StringBuffer()
    ..writeln('Trilha: ${trilha.emoji} ${trilha.nivel} '
        '(${curso.trilhaIdx + 1} de ${curso.trilhas.length})')
    ..writeln('Lição: ${licao.emoji} ${licao.nome} '
        '(${curso.licaoIdx + 1} de ${trilha.licoes.length})');
  if (licao.resumo.isNotEmpty) b.writeln('Resumo da lição: ${licao.resumo}');
  if (teoria.isNotEmpty) b.writeln('Teoria (começo): $teoria');
  b
    ..writeln('Exercício atual: trecho ${curso.trechoIdx + 1} '
        'de ${licao.trechos.length}')
    ..writeln('Dica do exercício: ${trecho.dicaPlana}')
    ..writeln('Código que o aluno está digitando:\n${trecho.cod}');
  if (trecho.out.isNotEmpty) b.writeln('Saída esperada no console: ${trecho.out}');
  if (trecho.temConceito) b.writeln('Conceito extra da lição: ${trecho.conceito}');
  b.write('Digitação na sessão: ${typing.precisao}% de precisão, '
      '${typing.errosSessao} erro(s), progresso do trecho '
      '${(typing.progresso * 100).round()}%.');
  return b.toString();
}
