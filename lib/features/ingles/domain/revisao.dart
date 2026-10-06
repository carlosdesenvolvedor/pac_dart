import 'package:equatable/equatable.dart';

/// Como foi a frase digitada DE MEMÓRIA numa revisão.
enum ResultadoRevisao {
  /// Muitas palavras erradas, muita dica ou "não sei": desce duas caixas.
  errou,

  /// Saiu com tropeços (poucos erros ou uma dica): fica na mesma caixa.
  hesitou,

  /// Saiu limpa: sobe de caixa e o intervalo cresce.
  acertou,
}

/// "Foi erro de digitação": sobe a nota um nível (errou → hesitou →
/// acertou). Uma vez por sessão (DESIGN §2.5).
ResultadoRevisao contestar(ResultadoRevisao r) => switch (r) {
      ResultadoRevisao.errou => ResultadoRevisao.hesitou,
      _ => ResultadoRevisao.acertou,
    };

/// Estado de uma frase na revisão espaçada (sistema de caixas de Leitner).
class CartaoRevisao extends Equatable {
  /// 1 = acabou de aprender … [Revisao.intervalos].length = dominada.
  final int caixa;

  /// Dia (contado desde 1970, no fuso local) em que a frase volta.
  final int proximoDia;

  /// Quantas vezes ela já caiu de volta para a caixa 1.
  final int lapsos;

  const CartaoRevisao({required this.caixa, required this.proximoDia, this.lapsos = 0});

  /// "caixa|dia|lapsos" — compacto para caber milhares no documento.
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

  bool devidaEm(int hoje) => proximoDia <= hoje;
  bool get dominada => caixa >= Revisao.intervalos.length;

  @override
  List<Object?> get props => [caixa, proximoDia, lapsos];
}

/// Regras da revisão espaçada do curso de inglês.
class Revisao {
  /// Dias até a próxima revisão para cada caixa (caixa 1 = índice 0) —
  /// expansivos, como no dossiê 01 §5.4 (alternativa ao FSRS).
  static const intervalos = [1, 3, 7, 16, 35, 80, 180];

  /// Teto de frases por revisão do dia (o resto fica para amanhã) — a meta
  /// "normal" do DESIGN §2.8.
  static const limiteDiario = 80;

  /// Dia local de [d], contado desde 1970 (muda à meia-noite de quem estuda).
  static int dia(DateTime d) => DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  /// Frase recém-aprendida numa lição: entra na caixa 1 e volta amanhã.
  static CartaoRevisao novo(int hoje) => CartaoRevisao(caixa: 1, proximoDia: hoje + intervalos[0]);

  /// Frase de uma trilha que a pessoa provou que já sabe (nivelamento):
  /// caixa 3, volta em uma semana.
  static CartaoRevisao testada(int hoje) => CartaoRevisao(caixa: 3, proximoDia: hoje + intervalos[2]);

  /// Próximo estado depois de revisar [c] hoje.
  static CartaoRevisao avaliar(CartaoRevisao c, ResultadoRevisao r, int hoje) {
    switch (r) {
      case ResultadoRevisao.acertou:
        final caixa = (c.caixa + 1).clamp(1, intervalos.length);
        return CartaoRevisao(caixa: caixa, proximoDia: hoje + intervalos[caixa - 1], lapsos: c.lapsos);
      case ResultadoRevisao.hesitou:
        return CartaoRevisao(caixa: c.caixa, proximoDia: hoje + intervalos[c.caixa - 1], lapsos: c.lapsos);
      case ResultadoRevisao.errou:
        // desce duas caixas (não zera) e volta amanhã
        final caixa = (c.caixa - 2).clamp(1, intervalos.length);
        return CartaoRevisao(caixa: caixa, proximoDia: hoje + intervalos[0], lapsos: c.lapsos + 1);
    }
  }


  /// Chaves das frases que vencem até [hoje], as mais atrasadas primeiro
  /// (empate: as de caixa menor, mais frágeis), no máximo [limite].
  static List<String> devidas(Map<String, CartaoRevisao> cartoes, int hoje, {int limite = limiteDiario}) {
    final lista = cartoes.entries.where((e) => e.value.devidaEm(hoje)).toList()
      ..sort((a, b) {
        final atraso = a.value.proximoDia.compareTo(b.value.proximoDia);
        if (atraso != 0) return atraso;
        final caixa = a.value.caixa.compareTo(b.value.caixa);
        return caixa != 0 ? caixa : a.key.compareTo(b.key);
      });
    return lista.take(limite).map((e) => e.key).toList();
  }

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
