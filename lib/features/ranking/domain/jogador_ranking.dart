import 'package:equatable/equatable.dart';

/// A linha pública de um jogador no ranking (doc `ranking/{uid}`).
/// Tudo aqui é acumulado ao longo da vida da conta.
class JogadorRanking extends Equatable {
  final String uid;
  final String apelido;

  /// Pontuação geral (digitação + quiz + arcade).
  final int pontos;

  /// Toques CORRETOS de código digitado.
  final int teclas;
  final int erros;
  final int licoes;
  final int projetos;
  final int quizAcertos;
  final int arcadePontos;

  /// Missões do Lógica Animada cumpridas.
  final int missoes;

  /// Melhor pontuação por joguinho ('corrida' | 'futebol' | 'cacaBug').
  final Map<String, int> arcadeRecordes;

  const JogadorRanking({
    required this.uid,
    required this.apelido,
    this.pontos = 0,
    this.teclas = 0,
    this.erros = 0,
    this.licoes = 0,
    this.projetos = 0,
    this.quizAcertos = 0,
    this.arcadePontos = 0,
    this.missoes = 0,
    this.arcadeRecordes = const {},
  });

  /// Volume de digitação avaliado (certos + errados).
  int get volume => teclas + erros;

  /// Precisão de digitação em % (100 sem volume — ninguém nasce errando).
  int get precisao => volume == 0 ? 100 : (teclas * 100 / volume).round();

  int recordeDoJogo(String jogo) => arcadeRecordes[jogo] ?? 0;

  factory JogadorRanking.deDados(String uid, Map<String, dynamic> d) {
    int n(String campo) => ((d[campo] as num?) ?? 0).toInt();
    final recordes = (d['arcade'] as Map?) ?? const {};
    return JogadorRanking(
      uid: uid,
      apelido: (d['apelido'] as String?) ?? 'jogador',
      pontos: n('pontos'),
      teclas: n('teclas'),
      erros: n('erros'),
      licoes: n('licoes'),
      projetos: n('projetos'),
      quizAcertos: n('quizAcertos'),
      arcadePontos: n('arcadePontos'),
      missoes: n('missoes'),
      arcadeRecordes:
          recordes.map((k, v) => MapEntry(k.toString(), ((v as num?) ?? 0).toInt())),
    );
  }

  @override
  List<Object?> get props => [
        uid, apelido, pontos, teclas, erros, licoes, projetos,
        quizAcertos, arcadePontos, missoes, arcadeRecordes,
      ];
}

/// Os quatro jeitos de ler o pódio.
enum CriterioRanking {
  pontos('Geral', '🏆', 'pts'),
  precisao('Precisão', '🎯', '%'),
  teclas('Digitação', '⌨️', 'toques'),
  arcade('Arcade', '🎮', 'pts');

  final String rotulo;
  final String emoji;
  final String unidade;
  const CriterioRanking(this.rotulo, this.emoji, this.unidade);

  int valor(JogadorRanking j) => switch (this) {
        pontos => j.pontos,
        precisao => j.precisao,
        teclas => j.teclas,
        arcade => j.arcadePontos,
      };
}

/// Precisão só entra na disputa com um mínimo de código digitado —
/// senão 3 toques perfeitos venceriam de quem digitou o curso inteiro.
const volumeMinimoPrecisao = 300;

/// Ordena para exibição. No critério precisão, quem ainda não digitou o
/// mínimo desce pro fim da fila (mas continua listado).
List<JogadorRanking> ordenarRanking(List<JogadorRanking> jogadores, CriterioRanking criterio) {
  final lista = [...jogadores];
  int compara(JogadorRanking a, JogadorRanking b) {
    final v = criterio.valor(b).compareTo(criterio.valor(a));
    if (v != 0) return v;
    final p = b.pontos.compareTo(a.pontos);
    return p != 0 ? p : a.apelido.compareTo(b.apelido);
  }

  if (criterio != CriterioRanking.precisao) {
    lista.sort(compara);
    return lista;
  }
  final valendo = lista.where((j) => j.volume >= volumeMinimoPrecisao).toList()..sort(compara);
  final aquecendo = lista.where((j) => j.volume < volumeMinimoPrecisao).toList()..sort(compara);
  return [...valendo, ...aquecendo];
}
