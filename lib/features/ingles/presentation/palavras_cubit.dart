import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../arcade/domain/palavras_ingles.dart';
import '../../arcade/domain/vocabulario_jogo.dart';
import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../data/dicionario_ingles.dart';
import '../data/palavras_repository.dart';
import '../domain/banco_palavras.dart';
import '../domain/dicionario.dart';
import '../domain/erros_palavra.dart';
import '../domain/licao_de_palavras.dart';
import '../domain/palavras_novas.dart';
import '../domain/revisao.dart';
import '../domain/srs.dart';
import '../domain/teimosas.dart';
import '../domain/texto_salvo.dart';
import '../domain/vocabulario_aluno.dart';

class PalavrasState extends Equatable {
  /// O banco de palavras do aluno (o que foi treinado, adicionado, editado ou tirado dos jogos).
  final BancoPalavras banco;

  /// O banco já foi lido do aparelho/nuvem?
  final bool carregado;

  /// O índice das palavras do curso (null até [PalavrasCubit.prepararIndice] terminar).
  final IndicePalavras? indice;

  /// O dia (desde 1970, fuso local) da última mudança.
  final int hoje;

  const PalavrasState({this.banco = BancoPalavras.vazio, this.carregado = false, this.indice, this.hoje = 0});

  PalavrasState copyWith({BancoPalavras? banco, bool? carregado, IndicePalavras? indice, int? hoje}) => PalavrasState(
        banco: banco ?? this.banco,
        carregado: carregado ?? this.carregado,
        indice: indice ?? this.indice,
        hoje: hoje ?? this.hoje,
      );

  @override
  List<Object?> get props => [banco, carregado, indice, hoje];
}

/// As palavras do aluno no PAC·ENGLISH: as novas de cada lição, o banco "Minhas palavras" (com o cartão
/// FSRS de cada palavra treinada) e o vocabulário dos jogos do Arcade. Só existe no inglês.
///
/// Offline-first, como o hábito: cada ação muda a tela na hora e grava depois (em ordem, sem empilhar);
/// o que for feito antes de o banco carregar entra por cima do que vier gravado.
class PalavrasCubit extends Cubit<PalavrasState> {
  final PalavrasRepository repo;

  /// Relógio injetável (testes).
  final DateTime Function() agora;

  /// O agendador dos cartões (testes: sem fuzz).
  final AgendadorFsrs? agendador;

  /// De onde vem o dicionário (testes: um pronto, sem asset).
  final Future<Dicionario> Function() _carregarDicionario;

  final List<BancoPalavras Function(BancoPalavras)> _pendentes = [];
  Future<void>? _carregando;
  BancoPalavras? _aGravar;
  bool _gravando = false;
  Future<void>? _gravacao;

  PalavrasCubit({
    required this.repo,
    DateTime Function()? agora,
    this.agendador,
    Future<Dicionario> Function()? carregarDicionario,
  })  : agora = agora ?? DateTime.now,
        _carregarDicionario = carregarDicionario ?? DicionarioIngles.carregar,
        super(const PalavrasState()) {
    carregar();
  }

  /// O cubit acima de [context], ou null (Dart, C#, testes de tela sem ele).
  static PalavrasCubit? de(BuildContext context) {
    try {
      return BlocProvider.of<PalavrasCubit>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  int get _hoje => Revisao.dia(agora());
  int get _ms => agora().millisecondsSinceEpoch;

  /// Lê o banco (o repositório já mescla aparelho × nuvem). Chamar de novo reaproveita a leitura.
  Future<void> carregar() => _carregando ??= _carregar();

  Future<void> _carregar() async {
    BancoPalavras lido;
    try {
      lido = await repo.carregar();
    } catch (_) {
      lido = BancoPalavras.vazio;
    }
    if (isClosed) return;
    var b = lido;
    for (final f in _pendentes) {
      b = f(b);
    }
    final tinha = _pendentes.isNotEmpty;
    _pendentes.clear();
    emit(state.copyWith(banco: b, carregado: true, hoje: _hoje));
    if (tinha) _salvar(b);
  }

  /// Monta (uma vez por lista de trilhas) o índice das palavras do curso: espera o dicionário embutido
  /// e emite. Chamar de novo com as mesmas trilhas é de graça.
  Future<IndicePalavras?> prepararIndice(List<Trilha> trilhas) async {
    final Dicionario dic;
    try {
      dic = await _carregarDicionario();
    } catch (_) {
      return state.indice;
    }
    if (isClosed) return state.indice;
    final ind = IndicePalavras.de(trilhas, dic);
    if (!identical(ind, state.indice)) emit(state.copyWith(indice: ind, hoje: _hoje));
    return ind;
  }

  // ---------- consultas ----------

  /// As palavras novas de [licao] (do curso, ou de um texto próprio: as que o curso ainda não apresentou).
  /// Vazio até o índice ficar pronto.
  List<PalavraNova> novasDaLicao(CursoState st, Licao licao) {
    final ind = state.indice;
    if (ind == null) return const [];
    final doCurso = ind.novasPorLicao[licao.id];
    if (doCurso != null) return doCurso;
    final propria = licao.id.startsWith(TextoSalvo.prefixoLicao) ||
        st.trilhas.any((t) => t.propria && t.licoes.any((l) => identical(l, licao)));
    return propria ? novasDaLicaoPropria(licao, ind, concluidas: st.concluidas) : const [];
  }

  /// O vocabulário dos jogos do Arcade com o que o aluno estudou (null fora do inglês ou com o índice
  /// ainda não pronto — aí os jogos usam as listas fixas). Usa a escolha gravada das lições dos jogos
  /// ([licoesDoJogo]); [escolha] troca por outra só nesta conta (a prévia da tela de escolher:
  /// `licoes` null = automático).
  VocabularioJogo? vocabularioJogo(CursoState st, {({Set<String>? licoes, bool minhas})? escolha}) {
    final ind = state.indice;
    if (ind == null || !st.ehIngles || st.trilhas.isEmpty) return null;
    String? atual;
    try {
      atual = st.licao.id;
    } catch (_) {}
    return montarVocabularioIngles(
      trilhas: st.trilhas,
      concluidas: st.concluidas,
      indice: ind,
      banco: state.banco,
      hoje: _hoje,
      licaoAtualId: atual,
      licoesEscolhidas: escolha != null ? escolha.licoes : state.banco.licoesJogo,
      incluirMinhas: escolha?.minhas ?? state.banco.minhasNoJogo,
    );
  }

  // ---------- as lições das palavras dos jogos ----------

  /// As lições escolhidas para as palavras dos jogos (null = automático).
  Set<String>? get licoesDoJogo {
    final l = state.banco.licoesJogo;
    return l == null ? null : Set.unmodifiable(l);
  }

  /// Com lições escolhidas, as palavras da pessoa também entram nos jogos?
  bool get minhasNoJogo => state.banco.minhasNoJogo;

  /// Escolhe de quais lições vêm as palavras dos jogos ([ids] null = volta ao automático) e se as palavras
  /// da pessoa entram junto ([incluirMinhas] null = como estava). Vai para a nuvem com o banco.
  void escolherLicoesDoJogo(Iterable<String>? ids, {bool? incluirMinhas}) {
    final ms = _ms;
    final lista = ids?.toList();
    _mudar((b) {
      final minhas = incluirMinhas ?? b.minhasNoJogo;
      final igual = minhas == b.minhasNoJogo &&
          (lista == null
              ? b.licoesJogo == null
              : b.licoesJogo != null && b.licoesJogo!.length == lista.toSet().length && b.licoesJogo!.toSet().containsAll(lista));
      return igual ? b : b.comLicoesJogo(lista, minhas: minhas, agora: ms);
    });
  }

  /// As palavras que [licoes] dão aos jogos, (como se escreve, tradução), sem repetir e sem as tiradas dos
  /// jogos — o total da tela de escolher. Vazio até o índice ficar pronto.
  List<(String, String)> palavrasDasLicoes(CursoState st, Iterable<String> licoes) {
    final ind = state.indice;
    if (ind == null) return const [];
    return palavrasDasLicoesEscolhidas(trilhas: st.trilhas, escolhidas: licoes, indice: ind, banco: state.banco, hoje: _hoje);
  }

  /// As palavras da pessoa que podem entrar nos jogos com "incluir minhas palavras" (as adicionadas e as
  /// guardadas lendo, fora as tiradas dos jogos e as que o jogo não aceita: expressões, apóstrofo, mais de
  /// 14 letras). Quantas entram de fato numa escolha sai de [VocabularioJogo.minhas].
  int get quantasMinhasNoJogo => [
        for (final p in state.banco.ativas)
          if (p.origem != OrigemPalavra.licao && p.noJogo && _reMinhaNoJogo.hasMatch(p.en.trim())) p,
      ].length;
  static final _reMinhaNoJogo = RegExp(r'^[A-Za-z]{3,14}$');

  /// As palavras do banco que vencem hoje (as mais atrasadas primeiro).
  List<PalavraDoBanco> get devidasHoje => state.banco.devidas(_hoje);
  int get quantasDevidas => devidasHoje.length;

  /// A força de [en] (nova se não está no banco).
  ForcaPalavra forcaDe(String en) => BancoPalavras.forca(state.banco[en], _hoje);

  /// Tudo o que o aluno já viu: o banco (sem as apagadas) + as palavras novas das lições concluídas que
  /// não estão nele (como [OrigemPalavra.licao], sem cartão). Banco primeiro (o mexido por último antes),
  /// depois as das lições, da mais recente para a mais antiga.
  List<PalavraDoBanco> palavrasDoAluno(CursoState st) {
    final banco = state.banco;
    final r = [...banco.ativas]..sort((a, b) {
        final u = b.atualizadoEm.compareTo(a.atualizadoEm);
        return u != 0 ? u : a.chave.compareTo(b.chave);
      });
    final ind = state.indice;
    if (ind == null || !st.ehIngles) return r;
    final vistas = {...banco.palavras.keys};
    final licoes = [
      for (final t in st.trilhas)
        if (!t.propria)
          for (final l in t.licoes)
            if (st.concluidas.contains(l.id)) l.id,
    ];
    for (final id in licoes.reversed) {
      for (final p in ind.novasDe(id)) {
        if (!vistas.add(p.chave)) continue;
        r.add(PalavraDoBanco(en: p.en, pt: p.pt, licaoId: p.licaoId, exemplo: p.exemplo));
      }
    }
    return r;
  }

  // ---------- ações ----------

  /// Adiciona uma palavra da pessoa. Devolve o erro (pt-BR) ou null quando entrou.
  String? adicionar(String en, String pt, {String? exemplo, OrigemPalavra origem = OrigemPalavra.minha}) {
    final v = validarPalavraNova(en, state.banco);
    if (v.erro != null) return v.erro;
    final traducao = pt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (traducao.isEmpty) return 'Escreva a tradução em português';
    final ms = _ms;
    final p = PalavraDoBanco(
      en: v.en,
      pt: traducao,
      origem: origem,
      exemplo: exemplo == null || exemplo.trim().isEmpty ? null : exemplo.trim(),
      criadaEm: ms,
      atualizadoEm: ms,
    );
    _mudar((b) => b.com(p));
    return null;
  }

  /// Troca a tradução de [en] (uma palavra de lição que não estava no banco passa a estar).
  void editar(String en, {required String pt}) {
    final traducao = pt.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (traducao.isEmpty) return;
    final ms = _ms;
    _mudar((b) {
      final p = b[en] ?? _daLicao(en, ms);
      return p == null ? b : b.com(p.copyWith(pt: traducao, atualizadoEm: ms));
    });
  }

  /// Apaga [en] (lápide: some também nos outros aparelhos).
  void remover(String en) {
    final ms = _ms;
    _mudar((b) {
      final p = b[en] ?? _daLicao(en, ms);
      return p == null || p.removida ? b : b.com(p.copyWith(removida: true, atualizadoEm: ms));
    });
  }

  /// Põe/tira [en] dos jogos ([valor] null = inverte).
  void alternarJogo(String en, [bool? valor]) {
    final ms = _ms;
    _mudar((b) {
      final p = b[en] ?? _daLicao(en, ms);
      if (p == null) return b;
      final novo = valor ?? !p.noJogo;
      return novo == p.noJogo ? b : b.com(p.copyWith(noJogo: novo, atualizadoEm: ms));
    });
  }

  /// O resultado de uma sessão de treino: cada palavra ganha (ou atualiza) o cartão FSRS e todas vão para
  /// a frente do "em treino" (aparecem primeiro nos jogos). Teimosas: cada nota vira uma evidência de
  /// treino (errou 1, hesitou 0,5, acertou 0), e as treinadas não são sugeridas de novo até amanhã.
  /// Devolve as palavras DOMINADAS agora (como se escrevem).
  List<String> registrarTreino(Map<String, (ResultadoRevisao, PalavraNova)> resultados) {
    if (resultados.isEmpty) return const [];
    final ms = _ms, hoje = _hoje;
    final peso = pesoDaFonte(FonteErro.treino);
    final dominadas = <String>[];
    _mudar((b) {
      dominadas.clear();
      var r = b;
      for (final e in resultados.entries) {
        final (resultado, nova) = e.value;
        final base = r[e.key] ?? r[nova.en] ?? _novaNoBanco(nova, ms);
        final agendada = agendar(base.copyWith(removida: false), resultado, hoje, agendador: agendador, agora: ms);
        final f = switch (resultado) {
          ResultadoRevisao.errou => 1.0,
          ResultadoRevisao.hesitou => 0.5,
          ResultadoRevisao.acertou => 0.0,
        };
        final ev = EvidenciaPalavra(chave: agendada.chave, peso: peso, falha: f, fonte: FonteErro.treino);
        final (comErro, dominou) = aplicarEvidencias(agendada, [ev], hoje);
        r = r.com(comErro.copyWith(naoSugerirAte: math.max(comErro.naoSugerirAte, hoje + 1)));
        if (dominou) dominadas.add(comErro.en);
      }
      return r.comEmTreino([for (final e in resultados.entries) e.value.$2.en], ms);
    });
    return List.unmodifiable(dominadas);
  }

  /// Quantas exposições (N) uma partida dá, no máximo, a cada palavra nas teimosas.
  static const vistasMaxPorPartida = 2;

  /// O que aconteceu com cada palavra numa partida do Arcade: (vistas, erros). Só exposição — não mexe
  /// no cartão. Palavra que não está no banco só entra se a pessoa errou (vira candidata a "fraca"), e
  /// só com tradução (a do curso, [traducoes] — a que o jogo mostrou —, o dicionário ou a lista fixa) e
  /// se não for palavra de função nem nome de personagem.
  ///
  /// Teimosas: cada palavra da partida vira UMA evidência da [fonte] (peso do jogo, N pelas vistas até
  /// [vistasMaxPorPartida], falha = [falhas] da palavra — a soma por ocorrência, até 1 — ou
  /// min(1, erros/2)), nunca com crédito de acerto limpo (jogo é cópia). Os dois lados têm teto por
  /// partida: um jogo nunca vale mais que uns 2 encontros com a palavra.
  void registrarJogo(
    Map<String, (int, int)> stats, {
    Map<String, String> traducoes = const {},
    FonteErro fonte = FonteErro.chuva,
    Map<String, double> falhas = const {},
  }) {
    if (stats.isEmpty) return;
    final ms = _ms, hoje = _hoje;
    final peso = pesoDaFonte(fonte);
    _mudar((b) {
      var r = b;
      for (final e in stats.entries) {
        final (vistas, erros) = e.value;
        if (vistas <= 0 && erros <= 0) continue;
        var p = r[e.key];
        if (p == null) {
          if (erros <= 0 || _funcaoOuNome(e.key)) continue;
          p = _daLicao(e.key, ms) ?? _doJogo(e.key, traducoes[e.key] ?? traducoes[e.key.toLowerCase()], ms);
          if (p == null) continue;
        }
        r = r.com(p.copyWith(
          vistasJogo: p.vistasJogo + (vistas < 0 ? 0 : vistas),
          errosJogo: p.errosJogo + (erros < 0 ? 0 : erros),
        ));
      }
      // a carga de erro (teimosas)
      for (final e in stats.entries) {
        final (vistas, erros) = e.value;
        if (vistas <= 0 && erros <= 0) continue;
        final k = chaveDeTreino(e.key);
        if (k == null) continue;
        final dada = falhas[e.key] ?? falhas[e.key.toLowerCase()];
        final f = (dada ?? math.min(1.0, (erros < 0 ? 0 : erros) / 2)).clamp(0.0, 1.0);
        final p = r[k] ?? (f >= 1 ? _novaPorErro(k, ms) : null);
        if (p == null || p.removida) continue;
        // simétrico com a falha (no máximo 1 por partida): N também tem teto — copiar a palavra 8 vezes
        // num jogo não "limpa" uma teimosa sem ela ter sido lembrada
        final n = vistas.clamp(1, vistasMaxPorPartida).toDouble();
        final ev = EvidenciaPalavra(chave: k, peso: peso, falha: f, fonte: fonte, vistas: n);
        r = r.com(aplicarEvidencias(p, [ev], hoje).$1);
      }
      return r;
    });
  }

  /// Resultados de lembrar a palavra de memória (o modo memória do Rali): alimentam o FSRS. Palavra de
  /// função (the, and, with…) e nome de personagem não ganham cartão — a não ser que a própria pessoa
  /// tenha posto a palavra no banco.
  void registrarMemoria(Map<String, ResultadoRevisao> resultados) {
    if (resultados.isEmpty) return;
    final ms = _ms, hoje = _hoje;
    _mudar((b) {
      var r = b;
      for (final e in resultados.entries) {
        final ja = r[e.key];
        if ((ja == null || ja.origem == OrigemPalavra.licao) && _funcaoOuNome(e.key)) continue;
        final p = ja ?? _daLicao(e.key, ms);
        if (p == null) continue;
        r = r.com(agendar(p, e.value, hoje, agendador: agendador, agora: ms));
      }
      return r;
    });
  }

  // ---------- teimosas ----------

  /// A chave de "palavra que se treina" de [w] (como sai de uma frase, de um cartão ou de um jogo), ou null
  /// para ignorá-la: curtas (< 3), com apóstrofo ou dígito, de função, nomes das personagens. Palavra do
  /// curso → ela mesma; senão a 1ª base do curso ("works" → work); senão a do dicionário, se não for nome
  /// próprio. Sempre em minúsculas (a chave do banco; como se escreve: [IndicePalavras.formaDe]). Sem o
  /// índice pronto, null (nada é capturado).
  String? chaveDeTreino(String w) {
    final ind = state.indice;
    if (ind == null) return null;
    final k = Dicionario.normalizar(w);
    if (k.length < 3 || k.contains("'") || _reDigito.hasMatch(k) || stopwordsEn.contains(k) || ind.nomes.contains(k)) {
      return null;
    }
    if (ind.palavra(k) != null) return ind.formaDe(k).toLowerCase();
    for (final b in Dicionario.bases(k)) {
      if (b.length >= 3 && !stopwordsEn.contains(b) && ind.palavra(b) != null) return ind.formaDe(b).toLowerCase();
    }
    final gloss = ind.dic.literal(k);
    if (gloss != null && !ehNomeProprio(gloss)) return k;
    return null;
  }

  static final _reDigito = RegExp(r'[0-9]');

  /// Grava as evidências de uma lição, revisão ou sessão de cartões (UMA chamada no fim): agrupa por
  /// palavra, cria no banco só a que errou de vez (falha ≥ 1) e aplica a carga. Devolve as palavras
  /// DOMINADAS agora (como se escrevem).
  List<String> registrarErros(List<EvidenciaPalavra> evs) {
    if (evs.isEmpty) return const [];
    final hoje = _hoje, ms = _ms;
    final grupos = <String, List<EvidenciaPalavra>>{};
    for (final e in evs) {
      final k = e.chave.toLowerCase();
      if (k.isEmpty) continue;
      (grupos[k] ??= []).add(e);
    }
    final dominadas = <String>[];
    _mudar((b) {
      dominadas.clear();
      var r = b;
      for (final g in grupos.entries) {
        var p = r[g.key];
        if (p == null) {
          if (!g.value.any((e) => e.errou)) continue;
          p = _novaPorErro(g.key, ms);
          if (p == null) continue;
        }
        if (p.removida) continue;
        final (nova, dominou) = aplicarEvidencias(p, g.value, hoje);
        r = r.com(nova);
        if (dominou) dominadas.add(nova.en);
      }
      return r;
    });
    return List.unmodifiable(dominadas);
  }

  /// As teimosas de hoje (no máximo [max]), da mais teimosa para a menos. [extras]: chaves com +1 de carga
  /// só nesta conta (ex.: as palavras das frases sanguessugas).
  List<PalavraDoBanco> teimosas({int max = 8, Iterable<String> extras = const []}) =>
      palavrasTeimosas(state.banco, _hoje, max: max, extras: extras);

  /// Quantas teimosas há hoje.
  int get quantasTeimosas => palavrasTeimosas(state.banco, _hoje, max: 1 << 30).length;

  /// As palavras já dominadas (a mais recente primeiro).
  List<PalavraDoBanco> get dominadas => [
        for (final p in state.banco.ativas)
          if (p.dominadaEm > 0) p,
      ]..sort((a, b) {
          final d = b.dominadaEm.compareTo(a.dominadaEm);
          return d != 0 ? d : a.chave.compareTo(b.chave);
        });

  /// A oferta "treinar só elas" para [local], ou null (a política não deixa agora, ou não chega ao mínimo).
  /// [daSessao]: chave → soma das falhas DESTA lição/sessão/partida. Não grava nada: quem mostrar chama
  /// [marcarMostrada].
  SugestaoTeimosas? sugestao(LocalSugestao local, {Map<String, double> daSessao = const {}, int? agoraMs}) {
    final b = state.banco;
    final hoje = _hoje;
    if (!podeOferecer(b.sugestao, hoje, agoraMs ?? _ms, local)) return null;
    final sessao = <String, double>{};
    for (final e in daSessao.entries) {
      final k = e.key.toLowerCase();
      final p = b[k];
      if (p != null && (p.removida || p.naoSugerirAte > hoje)) continue;
      sessao[k] = (sessao[k] ?? 0) + e.value;
    }
    final s = montarSugestao(daSessao: sessao, globais: teimosas());
    if (s == null) return null;
    final ind = state.indice;
    final formas = <String, String>{}, traducoes = <String, String>{};
    final vezes = {...s.vezes};
    for (final k in s.palavras) {
      final p = b[k];
      formas[k] = p?.en ?? ind?.formaDe(k) ?? k;
      final pt = (p != null && p.pt.isNotEmpty) ? p.pt : (ind?.traducao(k) ?? traducaoCurta(ind?.dic.literal(k)));
      traducoes[k] = pt;
      if (p != null) vezes[k] = math.max(vezes[k] ?? 1, vezesDe(p));
    }
    return SugestaoTeimosas(palavras: s.palavras, vezes: vezes, daSessao: s.daSessao, formas: formas, traducoes: traducoes);
  }

  /// A oferta apareceu na tela (conta para o limite do dia e o intervalo).
  void marcarMostrada() {
    final hoje = _hoje, ms = _ms;
    _mudar((b) => b.comSugestao(sugestaoMostrada(b.sugestao, hoje, ms)));
  }

  /// "Agora não": volta amanhã (no 3º seguido, daqui a 3 dias). Devolve quantos "Agora não" seguidos.
  int adiar() {
    final hoje = _hoje;
    _mudar((b) => b.comSugestao(sugestaoAdiada(b.sugestao, hoje)));
    return state.banco.sugestao.recusasSeguidas;
  }

  /// Aceitou a oferta (treinar, jogar ou virar lição).
  void aceitar() => _mudar((b) => b.comSugestao(sugestaoAceita(b.sugestao)));

  /// "Já sei essa": [en] não é sugerida pelos próximos 14 dias.
  void jaSei(String en) {
    final hoje = _hoje;
    _mudar((b) {
      final p = b[en];
      if (p == null) return b;
      return b.com(p.copyWith(naoSugerirAte: math.max(p.naoSugerirAte, hoje + 14)));
    });
  }

  /// [chave] pronta para o treino: a do curso (com a tradução que a pessoa editou, se editou), senão a do
  /// banco, senão a do dicionário.
  PalavraNova comoPalavraNova(String chave) {
    final ind = state.indice;
    final b = state.banco[chave];
    final doCurso = ind?.palavra(chave);
    if (doCurso != null) {
      if (b != null && b.pt.isNotEmpty && b.pt != doCurso.pt && b.pt != doCurso.ptCompleta) {
        return PalavraNova(
          en: doCurso.en,
          pt: b.pt,
          ptCompleta: b.pt,
          licaoId: doCurso.licaoId,
          exemplo: doCurso.exemplo,
          exemploPt: doCurso.exemploPt,
          trechoId: doCurso.trechoId,
        );
      }
      return doCurso;
    }
    if (b != null) return b.comoPalavraNova;
    final gloss = ind?.dic.literal(chave);
    return PalavraNova(en: chave, pt: traducaoCurta(gloss), ptCompleta: gloss ?? '');
  }

  /// "📝 Virar lição": o texto com frases do curso que têm [chaves] (fora de [evitar], as frases onde o
  /// erro aconteceu), ou null se não deu para montar 2 frases.
  TextoSalvo? licaoDePalavras(List<String> chaves, CursoState st, {Set<String> evitar = const {}}) {
    final ind = state.indice;
    return textoDePalavras(
      chaves,
      st.trilhas,
      concluidas: st.concluidas,
      traducao: (k) => ind?.traducao(k) ?? state.banco[k]?.pt,
      chaveDe: chaveDeTreino,
      exemploExtra: (k) {
        final ex = ind?.exemploDe(k);
        return ex == null || ex.frase.isEmpty ? null : (frase: ex.frase, traducao: ex.traducao);
      },
      evitar: evitar,
      agora: agora(),
    );
  }

  /// [ens] passam a ser o foco (vêm primeiro nos jogos).
  void focar(Iterable<String> ens) {
    final lista = [for (final e in ens) if (e.trim().isNotEmpty) e.trim()];
    if (lista.isEmpty) return;
    final ms = _ms;
    _mudar((b) => b.comEmTreino(lista, ms));
  }

  // ---------- interno ----------

  PalavraDoBanco? _daLicao(String en, int ms) {
    final p = state.indice?.palavra(en);
    if (p == null) return null;
    return _novaNoBanco(p, ms);
  }

  /// A entrada nova de uma palavra que errou de vez: a do curso, senão a do dicionário (com o exemplo do
  /// curso, se houver). Sem tradução, null.
  PalavraDoBanco? _novaPorErro(String k, int ms) {
    final daLicao = _daLicao(k, ms);
    if (daLicao != null) return daLicao;
    final ind = state.indice;
    final pt = traducaoCurta(ind?.dic.literal(k));
    if (pt.isEmpty) return null;
    final ex = ind?.exemploDe(k)?.frase;
    return PalavraDoBanco(
      en: k,
      pt: pt,
      exemplo: ex == null || ex.isEmpty ? null : ex,
      criadaEm: ms,
      atualizadoEm: ms,
    );
  }

  /// Palavra de função ou nome de personagem (sem o índice, só as de função)?
  bool _funcaoOuNome(String en) {
    final ind = state.indice;
    return ind != null ? ind.ehFuncaoOuNome(en) : stopwordsEn.contains(Dicionario.normalizar(en));
  }

  /// Uma palavra de jogo que não é do curso: com a tradução [dada] (a do jogo), a do dicionário ou a
  /// da lista fixa — sem nenhuma, null (nunca entra no banco sem tradução). Fora da lista fixa, ela
  /// veio de "Meus cartões"/texto colado: origem leitura.
  PalavraDoBanco? _doJogo(String en, String? dada, int ms) {
    final k = Dicionario.normalizar(en);
    if (k.isEmpty) return null;
    final literal = state.indice?.dic.literal(k);
    String? pt;
    for (final t in [dada, literal == null ? null : traducaoCurta(literal), traducoesEn[k]]) {
      if (t != null && t.trim().isNotEmpty) {
        pt = t.trim();
        break;
      }
    }
    if (pt == null) return null;
    return PalavraDoBanco(
      en: en.trim(),
      pt: pt,
      origem: traducoesEn.containsKey(k) ? OrigemPalavra.licao : OrigemPalavra.leitura,
      criadaEm: ms,
      atualizadoEm: ms,
    );
  }

  PalavraDoBanco _novaNoBanco(PalavraNova p, int ms) => PalavraDoBanco(
        en: p.en,
        pt: p.pt,
        origem: p.licaoId.isEmpty
            ? OrigemPalavra.minha
            : (p.licaoId.startsWith(TextoSalvo.prefixoLicao) ? OrigemPalavra.leitura : OrigemPalavra.licao),
        licaoId: p.licaoId.isEmpty ? null : p.licaoId,
        exemplo: p.exemplo.isEmpty ? null : p.exemplo,
        criadaEm: ms,
        atualizadoEm: ms,
      );

  void _mudar(BancoPalavras Function(BancoPalavras) f) {
    if (isClosed) return;
    final antes = state.banco;
    final depois = f(antes);
    if (!state.carregado) {
      // ainda lendo: a tela muda já, e a mudança é refeita por cima do que vier gravado
      _pendentes.add(f);
      if (depois != antes) emit(state.copyWith(banco: depois, hoje: _hoje));
      return;
    }
    if (depois == antes) return;
    emit(state.copyWith(banco: depois, hoje: _hoje));
    _salvar(depois);
  }

  /// Grava em ordem e sem empilhar: chegando outro estado durante a gravação, só o mais novo vai depois.
  /// Erro (sem rede) é engolido: o aparelho já guardou e o próximo salvar tenta de novo.
  void _salvar(BancoPalavras b) {
    _aGravar = b.podado(_hoje);
    if (_gravando) return;
    _gravando = true;
    _gravacao = _laco();
  }

  Future<void> _laco() async {
    try {
      while (_aGravar != null) {
        final vez = _aGravar!;
        _aGravar = null;
        try {
          await repo.salvar(vez);
        } catch (_) {}
      }
    } finally {
      _gravando = false;
    }
  }

  /// Termina quando a gravação em curso acabar (testes).
  @visibleForTesting
  Future<void> get gravacoes => _gravacao ?? Future.value();
}
