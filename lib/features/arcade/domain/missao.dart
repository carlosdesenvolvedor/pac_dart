import 'package:equatable/equatable.dart';

/// Os palcos do Lógica Animada.
enum Cena { porta, blitz, colheita, semaforo, foguete, ponte, mercado, cofre }

/// Um passo da execução animada: legenda narrando + o que muda na cena.
class PassoCena extends Equatable {
  final String legenda;
  final Map<String, Object> muda;
  const PassoCena(this.legenda, [this.muda = const {}]);

  @override
  List<Object?> get props => [legenda, muda];
}

/// Uma missão do Lógica Animada: o jogador PREVÊ o resultado, DIGITA o
/// código pra destravar e ASSISTE a lógica rodar em cena.
class Missao extends Equatable {
  final Cena cena;
  final String titulo;

  /// A situação narrada ("a porta está a 6 passos…").
  final String historia;

  /// O código Dart digitado no motor Pac-Man (sempre 100% digitável).
  final String codigo;

  /// Pergunta de previsão (o teste de lógica) + alternativas.
  final String pergunta;
  final List<String> opcoes;
  final int certa;

  /// Por que a resposta é essa — aparece na vitória.
  final String explica;

  /// 🔮 Ajudas misteriosas, da mais vaga à mais reveladora.
  final List<String> dicas;

  /// Roteiro da execução animada (aplicado sobre [dados]).
  final List<PassoCena> passos;

  /// Estado inicial da cena (idades, total de passos, emoji da fruta…).
  final Map<String, Object> dados;

  /// Pontos base (a previsão certa bonifica; cada ajuda desconta).
  final int pontos;

  const Missao({
    required this.cena,
    required this.titulo,
    required this.historia,
    required this.codigo,
    required this.pergunta,
    required this.opcoes,
    required this.certa,
    required this.explica,
    required this.dicas,
    required this.passos,
    required this.dados,
    required this.pontos,
  });

  @override
  List<Object?> get props =>
      [cena, titulo, historia, codigo, pergunta, opcoes, certa, explica, dicas, passos, dados, pontos];
}
