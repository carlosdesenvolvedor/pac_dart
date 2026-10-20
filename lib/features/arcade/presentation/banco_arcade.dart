import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/linguagem/linguagem.dart';
import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../ingles/domain/erros_palavra.dart';
import '../../ingles/presentation/palavras_cubit.dart';
import '../domain/banco_curriculo.dart';
import '../domain/banco_desafios.dart';
import '../domain/desafio.dart';
import '../domain/palavras_csharp.dart';
import '../domain/palavras_ingles.dart';
import '../domain/tropecos.dart';
import '../domain/vocabulario_jogo.dart';

/// Bancos do Arcade na vertente em uso. No Dart, o banco autoral de sempre;
/// no C#, os desafios de lógica do currículo C# carregado no [CursoBloc].
/// Sem CursoBloc (testes do arcade solto) ou sem desafios suficientes, fica
/// o banco do Dart — os jogos nunca abrem vazios.
class BancoArcade {
  static List<Trilha> _trilhasCs(BuildContext context) {
    if (Linguagem.atual != Linguagem.csharp) return const [];
    try {
      final st = BlocProvider.of<CursoBloc>(context, listen: false).state;
      return st.ehCSharp ? st.trilhas : const [];
    } catch (_) {
      return const [];
    }
  }

  static List<Desafio> desafios(BuildContext context, TipoDesafio tipo) {
    final cs = desafiosDoCurriculo(_trilhasCs(context));
    return cs.where((d) => d.tipo == tipo).length >= 6 ? cs : bancoDesafios;
  }

  static List<DesafioBug> bugs(BuildContext context) {
    final cs = bugsDoCurriculo(_trilhasCs(context));
    return cs.length >= 4 ? cs : bancoBugs;
  }

  /// "Dart", "C#" ou "English" — para os nomes dos jogos e textos do hub.
  static String get linguagem => switch (Linguagem.atual) {
        Linguagem.csharp => 'C#',
        Linguagem.ingles => 'English',
        Linguagem.dart => 'Dart',
      };

  /// No inglês o Arcade só tem os jogos de DIGITAÇÃO (os de lógica são de código).
  static bool get soDigitacao => !Linguagem.atual.ehProgramacao;

  // ---------- vocabulário dos jogos de digitação ----------

  /// As palavras de uma partida. No Dart e no C#, as listas fixas de sempre (as MESMAS instâncias de
  /// [vocabularioDe]). No inglês, o que o aluno estudou ([PalavrasCubit.vocabularioJogo]); sem o
  /// cubit/curso (arcade solto, testes) ou com o índice ainda não pronto, as listas fixas em inglês com
  /// a tradução de cada palavra.
  static VocabularioJogo vocabulario(BuildContext context) {
    if (Linguagem.atual != Linguagem.ingles) return VocabularioJogo.deListas(vocabularioDe());
    try {
      final cubit = PalavrasCubit.de(context);
      if (cubit != null) {
        final st = BlocProvider.of<CursoBloc>(context, listen: false).state;
        final v = cubit.vocabularioJogo(st);
        if (v != null && v.curtas.isNotEmpty && v.medias.isNotEmpty && v.longas.isNotEmpty) return v;
      }
    } catch (_) {}
    return VocabularioJogo.deListas(vocabularioDe(Linguagem.ingles), traducoes: traducoesEn);
  }

  /// O baralho do Rali. Fora do inglês é exatamente [baralhoRaliDe]; no inglês, o vocabulário do
  /// aluno ([vocab], ou [vocabulario]) embaralhado com [rnd] e as palavras em foco na frente.
  static List<String> baralhoRali(BuildContext context, Random rnd, {bool comLongas = false, VocabularioJogo? vocab}) {
    if (Linguagem.atual != Linguagem.ingles) return baralhoRaliDe(rnd, comLongas: comLongas);
    return baralhoDoVocabulario(vocab ?? vocabulario(context), rnd, comLongas: comLongas);
  }

  /// [v] embaralhado (curtas + médias, e as longas com [comLongas]); o foco vai para a frente, na
  /// ordem sorteada.
  static List<String> baralhoDoVocabulario(VocabularioJogo v, Random rnd, {bool comLongas = false}) {
    final todas = <String>[];
    final vistas = <String>{};
    for (final p in [...v.curtas, ...v.medias, if (comLongas) ...v.longas]) {
      if (vistas.add(p)) todas.add(p);
    }
    todas.shuffle(rnd);
    return [...todas.where(v.emFoco), ...todas.where((p) => !v.emFoco(p))];
  }

  /// O cubit das palavras (só no inglês, null sem ele). Pegue no initState: no dispose o context já
  /// não serve para procurar ancestrais.
  static PalavrasCubit? palavras(BuildContext context) =>
      Linguagem.atual == Linguagem.ingles ? PalavrasCubit.de(context) : null;

  /// Manda o que aconteceu com cada palavra na partida (vistas, erros) para o banco do aluno; [falhas]
  /// (palavra → falha da partida, 0–1) alimenta as teimosas com o peso de [fonte].
  static void registrarJogo(BuildContext context, Map<String, (int, int)> stats,
          {FonteErro fonte = FonteErro.chuva, Map<String, double> falhas = const {}}) =>
      palavras(context)?.registrarJogo(stats, fonte: fonte, falhas: falhas);

  // ---------- tropeços da partida (teimosas, só no inglês) ----------

  /// As somas de falha da partida pelas chaves do banco — o `daSessao` da oferta "treinar só elas".
  /// Palavra de função e nome de personagem ficam de fora (o [PalavrasCubit.chaveDeTreino] dá null).
  static Map<String, double> daSessao(PalavrasCubit cubit, TropecosDoJogo t) {
    final r = <String, double>{};
    for (final e in t.somas.entries) {
      final k = cubit.chaveDeTreino(e.key);
      if (k != null) r[k] = (r[k] ?? 0) + e.value;
    }
    return r;
  }

  /// As palavras que escaparam na partida (soma ≥ [min], da que mais escapou), prontas para mostrar:
  /// (como se escreve, tradução do jogo ([VocabularioJogo.traducao]) ou null, vezes). Com [cubit], só as
  /// que se treinam (com chave no banco).
  static List<(String, String?, int)> itensDoJogo(TropecosDoJogo t, VocabularioJogo? v,
          {double min = 1.0, PalavrasCubit? cubit}) =>
      [
        for (final w in t.dificeis(min: min))
          if (cubit == null || cubit.chaveDeTreino(w) != null) (w, v?.traducao(w), t.vezes(w)),
      ];

  /// As chaves do banco de [palavras] (sem repetir; as que não se treinam saem).
  static List<String> chavesDe(PalavrasCubit cubit, Iterable<String> palavras) {
    final r = <String>[];
    for (final w in palavras) {
      final k = cubit.chaveDeTreino(w);
      if (k != null && !r.contains(k)) r.add(k);
    }
    return r;
  }

  /// '📝 Anotadas nesta partida: through ×2 · enough ×1' (até 5), ou null sem nada anotado.
  static String? linhaAnotadas(TropecosDoJogo? t) {
    if (t == null) return null;
    final ws = t.dificeis(min: 0.01).take(5).toList();
    if (ws.isEmpty) return null;
    return '📝 Anotadas nesta partida: ${ws.map((w) => '$w ×${t.vezes(w)}').join(' · ')}';
  }

  /// O aviso leve durante o jogo, quando [w] escapa pela 2ª vez.
  static String textoAviso(String w, int vezes) => '💡 "$w" escapou ${vezes}x — anotei pra revanche';
}

/// Conta, numa partida, quantas vezes cada palavra apareceu resolvida (vista) e quantas vezes a
/// pessoa errou nela. Só o inglês usa (o banco de palavras do aluno).
class PlacarPalavras {
  final Map<String, (int, int)> _stats = {};

  void viu(String palavra) {
    final (v, e) = _stats[palavra] ?? (0, 0);
    _stats[palavra] = (v + 1, e);
  }

  void errou(String palavra) {
    final (v, e) = _stats[palavra] ?? (0, 0);
    _stats[palavra] = (v, e + 1);
  }

  bool get vazio => _stats.isEmpty;

  /// O que juntou até aqui (e zera).
  Map<String, (int, int)> tirar() {
    final r = Map<String, (int, int)>.of(_stats);
    _stats.clear();
    return r;
  }

  /// Entrega o que juntou ao [cubit] (nada quando vazio ou sem cubit). Com [tropecos], a falha de cada
  /// palavra da partida vai junto (0 para as que não tropeçaram), com o peso de [fonte].
  void enviar(PalavrasCubit? cubit, {FonteErro fonte = FonteErro.chuva, TropecosDoJogo? tropecos}) {
    if (cubit == null || _stats.isEmpty) return;
    final stats = tirar();
    if (tropecos == null) {
      cubit.registrarJogo(stats, fonte: fonte);
      return;
    }
    final f = tropecos.falhas;
    cubit.registrarJogo(stats, fonte: fonte, falhas: {for (final w in stats.keys) w: f[w] ?? 0});
  }
}
