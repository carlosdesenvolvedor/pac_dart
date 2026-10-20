import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../arcade/presentation/arcade_page.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../data/voz_ingles.dart';
import 'palavras_cubit.dart';
import 'treino_palavras.dart';

/// As ações das "🔥 Palavras teimosas", as mesmas em todo lugar que as oferece (fim de lição, revisões,
/// jogos, Minhas palavras). Todas null-safe: sem o [PalavrasCubit] (Dart, C#, testes) não fazem nada.

/// "🎯 Treinar só elas": aceita a oferta e abre a revanche (relembrar → ouvir → digitar sem dica → digitar
/// de novo) com [chaves]. [origem]: de onde veio (fimDeLicao, rali…), só para registro/depuração.
Future<void> treinarTeimosas(BuildContext context, List<String> chaves, {String origem = '', VozIngles? voz}) async {
  final cubit = PalavrasCubit.de(context);
  if (cubit == null || chaves.isEmpty) return;
  cubit.aceitar();
  final vistas = <String>{};
  final palavras = [
    for (final k in chaves)
      if (vistas.add(k.toLowerCase())) cubit.comoPalavraNova(k.toLowerCase()),
  ].where((p) => p.en.trim().isNotEmpty && p.pt.trim().isNotEmpty).toList();
  if (palavras.isEmpty) return;
  await abrirTreinoPalavras(context, palavras, titulo: '🔥 Revanche das teimosas', revanche: true, voz: voz);
}

/// "🎮 Jogar com elas": aceita a oferta e põe [chaves] em foco nos jogos (vêm primeiro). Fora de um jogo,
/// abre o Arcade; [dentroDoJogo] (ex.: "⚡ Próxima fase com elas" no Rali): só o foco — quem chamou segue.
void jogarComTeimosas(BuildContext context, List<String> chaves, {bool dentroDoJogo = false}) {
  final cubit = PalavrasCubit.de(context);
  if (cubit == null || chaves.isEmpty) return;
  cubit.aceitar();
  cubit.focar([
    for (final k in chaves)
      if (cubit.comoPalavraNova(k.toLowerCase()) case final p when p.deJogo) p.en,
  ]);
  if (dentroDoJogo) return;
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ArcadePage()));
}

/// "📝 Virar lição": uma lição de texto com frases do curso que têm [chaves] (fora de [evitar], as frases
/// onde o erro aconteceu). Deu: cria o texto (`TextoCriado`, já posiciona nele) e volta para a 1ª tela.
/// Não deu (menos de 2 frases): avisa e sugere o treino. Devolve se criou.
Future<bool> virarLicao(BuildContext context, List<String> chaves, {Set<String> evitar = const {}}) async {
  CursoBloc? curso;
  try {
    curso = context.read<CursoBloc>();
  } catch (_) {}
  return virarLicaoCom(
    cubit: PalavrasCubit.de(context),
    curso: curso,
    nav: Navigator.maybeOf(context),
    mensageiro: ScaffoldMessenger.maybeOf(context),
    chaves: chaves,
    evitar: evitar,
  );
}

/// [virarLicao] com tudo já capturado (para quem chama depois de um `await`, com o contexto talvez já
/// desmontado — ex.: o "📝 Virar lição" do resumo da revanche).
bool virarLicaoCom({
  required PalavrasCubit? cubit,
  required CursoBloc? curso,
  required NavigatorState? nav,
  required ScaffoldMessengerState? mensageiro,
  required List<String> chaves,
  Set<String> evitar = const {},
}) {
  if (cubit == null || curso == null || chaves.isEmpty) return false;
  final texto = cubit.licaoDePalavras(chaves, curso.state, evitar: evitar);
  if (texto == null) {
    mensageiro
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        key: const Key('snack-sem-licao'),
        backgroundColor: Mixart.surfaceHi,
        content: Text('Não achei frases do curso com essas palavras — que tal treinar no 🎯?',
            style: Mixart.ui(size: 13, color: Mixart.text)),
      ));
    return false;
  }
  cubit.aceitar();
  curso.add(TextoCriado(texto));
  nav?.popUntil((r) => r.isFirst);
  return true;
}
