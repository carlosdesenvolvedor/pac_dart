import 'package:equatable/equatable.dart';

/// Como foi a frase digitada DE MEMÓRIA numa revisão.
enum ResultadoRevisao {
  /// Muitas palavras erradas, muita dica ou "não sei": nota "errei" (Again).
  errou,

  /// Saiu com tropeços (poucos erros ou uma dica): nota "difícil" (Hard).
  hesitou,

  /// Saiu limpa: nota "bom" (Good) e o intervalo cresce.
  acertou,
}

/// "Foi erro de digitação": sobe a nota um nível (errou → hesitou →
/// acertou). Uma vez por sessão (DESIGN §2.5).
ResultadoRevisao contestar(ResultadoRevisao r) => switch (r) {
      ResultadoRevisao.errou => ResultadoRevisao.hesitou,
      _ => ResultadoRevisao.acertou,
    };

/// O cartão ANTIGO da revisão (caixas de Leitner), mantido só para LER o que já
/// estava gravado e convertê-lo em [CartaoSrs] (o motor agora é o FSRS).
class CartaoRevisao extends Equatable {
  /// 1 = acabou de aprender … [Revisao.intervalos].length = dominada.
  final int caixa;

  /// Dia (contado desde 1970, no fuso local) em que a frase volta.
  final int proximoDia;

  /// Quantas vezes ela já caiu de volta para a caixa 1.
  final int lapsos;

  const CartaoRevisao({required this.caixa, required this.proximoDia, this.lapsos = 0});

  /// "caixa|dia|lapsos".
  String codificar() => '$caixa|$proximoDia|$lapsos';

  static CartaoRevisao? decodificar(Object? bruto) {
    final partes = '$bruto'.split('|');
    if (partes.length < 2) return null;
    final caixa = int.tryParse(partes[0]);
    final dia = int.tryParse(partes[1]);
    if (caixa == null || dia == null) return null;
    return CartaoRevisao(
      caixa: caixa.clamp(1, Revisao.intervalos.length),
      proximoDia: dia,
      lapsos: partes.length > 2 ? int.tryParse(partes[2]) ?? 0 : 0,
    );
  }

  @override
  List<Object?> get props => [caixa, proximoDia, lapsos];
}

/// Regras comuns da revisão espaçada do curso de inglês (o agendador, que é o
/// FSRS, está em `srs.dart`).
class Revisao {
  /// Dias de cada caixa do formato ANTIGO (Leitner, caixa 1 = índice 0):
  /// só serve para converter o que já estava gravado.
  static const intervalos = [1, 3, 7, 16, 35, 80, 180];

  /// Teto de frases por revisão do dia (o resto fica para amanhã) — a meta
  /// "normal" do DESIGN §2.8.
  static const limiteDiario = 80;

  /// Dia local de [d], contado desde 1970 (muda à meia-noite de quem estuda).
  static int dia(DateTime d) => DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  /// Sufixo do cartão do sentido INVERTIDO (inglês na frente, tradução no verso):
  /// é um cartão à parte, com a memória dele — como o "Basic and reversed" do Anki.
  /// O `~` não aparece em chave de frase (base 36 ou id do conteúdo).
  static const sufixoReversa = '~r';

  /// A chave do cartão inglês → português da frase de chave [chave].
  static String chaveReversa(String chave) => '$chave$sufixoReversa';
  static bool ehReversa(String chave) => chave.endsWith(sufixoReversa);

  /// A chave da frase, sem o sufixo (a mesma para os dois sentidos).
  static String baseDe(String chave) =>
      ehReversa(chave) ? chave.substring(0, chave.length - sufixoReversa.length) : chave;

  /// Chave da frase na revisão: o id opaco do conteúdo (estável mesmo se o
  /// texto for corrigido) ou, sem id, o hash do texto.
  static String chaveDe({required String id, required String cod}) => id.isNotEmpty ? id : chave(cod);

  /// Chave estável de uma frase: hash do texto em inglês. Não depende da
  /// posição no currículo — reordenar trilhas não perde a revisão (corrigir
  /// o texto da frase, sim, e aí ela recomeça).
  static String chave(String frase) {
    // dois hashes polinomiais de 26 bits (cabem no double do JS sem perder
    // precisão) = 52 bits; colisão entre milhares de frases é desprezível
    var a = 7, b = 11;
    for (final c in frase.codeUnits) {
      a = (a * 131 + c) % 67108859;
      b = (b * 257 + c) % 67108837;
    }
    return '${a.toRadixString(36)}${b.toRadixString(36).padLeft(5, '0')}';
  }
}
