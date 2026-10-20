// "Palavras teimosas" do PAC·ENGLISH — a CAPTURA: de cada frase (ou cartão) respondida de memória sai,
// no máximo, UMA evidência por palavra: o quanto ela falhou (0 = limpa, 1 = errou de vez) e quanto pesa
// a fonte (lição, revisão, cartão, treino, jogos). Três teclas erradas em "through" numa frase contam
// uma vez só. Dart puro: quem chama dá a chave de cada palavra ([PalavrasCubit.chaveDeTreino]).
import 'package:equatable/equatable.dart';

import 'avaliacao.dart' show palavrasDe;
import 'comparar_resposta.dart';
import 'entrada_resposta.dart';

/// De onde veio a evidência.
enum FonteErro {
  licao,
  revisao,
  cartao,
  treino,
  chuva,
  rali,
  turismo;

  /// Jogo do Arcade (cópia: nunca dá crédito de "acertou limpo").
  bool get deJogo => this == chuva || this == rali || this == turismo;
}

/// O peso de cada fonte. Na lição e na revisão, o modo de responder multiplica: Montar ×0,6 e Falar ×0,4
/// (montar é reconhecer; a fala erra nomes e tropeça no reconhecimento de voz).
double pesoDaFonte(FonteErro fonte, {EntradaResposta entrada = EntradaResposta.digitar}) {
  final base = switch (fonte) {
    FonteErro.licao || FonteErro.revisao || FonteErro.cartao => 1.0,
    FonteErro.treino => 0.7,
    FonteErro.chuva || FonteErro.rali => 0.5,
    FonteErro.turismo => 0.3,
  };
  if (fonte != FonteErro.licao && fonte != FonteErro.revisao) return base;
  return switch (entrada) {
    EntradaResposta.digitar => base,
    EntradaResposta.montar => base * 0.6,
    EntradaResposta.falar => base * 0.4,
  };
}

/// Uma evidência sobre uma palavra: [chave] (minúsculas, como o banco guarda), [peso] da fonte, [falha]
/// em 0–1 e [vistas] (quantas exposições ela representa: os jogos mandam uma por palavra por partida).
/// Soma na carga: E += peso·falha; N += peso·vistas.
class EvidenciaPalavra extends Equatable {
  final String chave;
  final double peso;
  final double falha;
  final FonteErro fonte;
  final double vistas;

  const EvidenciaPalavra({
    required this.chave,
    required this.peso,
    required this.falha,
    required this.fonte,
    this.vistas = 1,
  });

  /// Errou de vez (conta no "errou Nx" e zera a sequência de acertos).
  bool get errou => falha >= 1;

  /// Saiu limpa.
  bool get limpa => falha <= 0;

  @override
  List<Object?> get props => [chave, peso, falha, fonte, vistas];

  @override
  String toString() => 'Ev($chave, p=$peso, f=$falha, ${fonte.name})';
}

final _reLetra = RegExp(r'[A-Za-z0-9]');

/// As evidências de UMA frase digitada de memória.
///
/// [fraseAceita] é o texto que VALEU (o `st.chars.join()` — pode ser a alternativa "I am" no lugar de
/// "I'm"), nunca o `Trecho.cod`: as palavras saem de [palavrasDe] sobre ele, e [teclas], [extras] e
/// [reveladas] são posições nele.
/// - teclas erradas (soma crua dentro da palavra — sem a tolerância de 1 erro da nota): 0 → limpa;
///   1 → 0,5 numa palavra de 5+ letras, 0,3 nas curtas; 2+ (ou qualquer letra revelada) → 1;
/// - [extras] (`errosDeFala`: falar e montar marcam a 1ª letra da palavra): 1+ → falha 1;
/// - [desistiu] (Esc "não sei"): do trecho revelado no fim, só a 1ª palavra (a do cursor) leva falha 1;
///   as seguintes não dão evidência nenhuma (a pessoa nem chegou nelas). Tabs antes continuam valendo.
/// [chaveDe] devolve a chave da palavra, ou null para ignorá-la. Uma evidência por chave (a pior).
List<EvidenciaPalavra> evidenciasDaFrase(
  String fraseAceita, {
  Map<int, int> teclas = const {},
  Map<int, int> extras = const {},
  EntradaResposta entrada = EntradaResposta.digitar,
  Set<int> reveladas = const {},
  bool desistiu = false,
  required FonteErro fonte,
  required String? Function(String) chaveDe,
}) {
  final ps = palavrasDe(fraseAceita);
  if (ps.isEmpty) return const [];
  // onde começa o trecho revelado pelo "não sei" (o fim da frase, revelado sem buracos)
  var inicioDesistencia = fraseAceita.length;
  if (desistiu) {
    var i = fraseAceita.length;
    while (i > 0 && (reveladas.contains(i - 1) || !_reLetra.hasMatch(fraseAceita[i - 1]))) {
      i--;
    }
    // só vale se alguma letra foi de fato revelada
    var algum = false;
    for (var j = i; j < fraseAceita.length; j++) {
      if (reveladas.contains(j)) {
        algum = true;
        break;
      }
    }
    if (algum) inicioDesistencia = i;
  }
  final peso = pesoDaFonte(fonte, entrada: entrada);
  final porChave = <String, double>{};
  final ordem = <String>[];
  var passouDoCursor = false;
  for (final p in ps) {
    final w = fraseAceita.substring(p.ini, p.fim);
    double f;
    if (desistiu && p.fim > inicioDesistencia) {
      if (passouDoCursor) continue; // depois da palavra do cursor: nenhuma evidência
      passouDoCursor = true;
      f = 1;
    } else {
      var erros = 0;
      var revelou = false;
      for (var i = p.ini; i < p.fim; i++) {
        erros += teclas[i] ?? 0;
        if (reveladas.contains(i)) revelou = true;
      }
      if (revelou || erros >= 2) {
        f = 1;
      } else if (erros == 1) {
        f = (p.fim - p.ini) >= 5 ? 0.5 : 0.3;
      } else {
        f = 0;
      }
      var falou = 0;
      for (var i = p.ini; i < p.fim; i++) {
        falou += extras[i] ?? 0;
      }
      if (falou >= 1) f = 1;
    }
    final k = chaveDe(w);
    if (k == null || k.isEmpty) continue;
    final ja = porChave[k];
    if (ja == null) ordem.add(k);
    if (ja == null || f > ja) porChave[k] = f > 1 ? 1 : f;
  }
  return [
    for (final k in ordem) EvidenciaPalavra(chave: k, peso: peso, falha: porChave[k]!, fonte: fonte),
  ];
}

/// As evidências de um cartão conferido palavra a palavra (PT→EN, "digitar a resposta"): cada palavra da
/// resposta esperada com acerto true → limpa, false → falha 1; null (pontuação, ou as palavras que o
/// nível Médio deixa à vista) → sem evidência.
List<EvidenciaPalavra> evidenciasDaComparacao(
  ComparacaoResposta c, {
  required FonteErro fonte,
  required String? Function(String) chaveDe,
}) {
  final peso = pesoDaFonte(fonte);
  final porChave = <String, double>{};
  final ordem = <String>[];
  for (final s in c.esperada) {
    final a = s.acerto;
    if (a == null) continue;
    final k = chaveDe(s.texto);
    if (k == null || k.isEmpty) continue;
    final f = a ? 0.0 : 1.0;
    final ja = porChave[k];
    if (ja == null) ordem.add(k);
    if (ja == null || f > ja) porChave[k] = f;
  }
  return [
    for (final k in ordem) EvidenciaPalavra(chave: k, peso: peso, falha: porChave[k]!, fonte: fonte),
  ];
}
