import 'dart:math';

import 'package:equatable/equatable.dart';

import 'comparar_resposta.dart';
import 'srs.dart';

/// Os níveis de resposta do cartão de virar: quanto o app ajuda quando a pessoa responde a
/// tradução. Do mais fácil ao mais difícil: blocos de palavras para montar a frase (Fácil),
/// lacunas com algumas palavras à vista (Médio) e a frase inteira escrita (Avançado).
/// "Só virar" é o jeito antigo (olha, vira e se avalia). Valem nos dois sentidos do cartão.
enum NivelResposta {
  facil('facil', '🧩', 'Fácil'),
  medio('medio', '✏️', 'Médio'),
  avancado('avancado', '✍️', 'Avançado'),
  livre('livre', '👁', 'Só virar');

  const NivelResposta(this.id, this.emoji, this.rotulo);
  final String id, emoji, rotulo;

  /// O nível pelo id guardado; null se não existir.
  static NivelResposta? porId(String? id) {
    for (final n in values) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// Escreve (campo de texto ou lacunas) em vez de montar com blocos ou só virar.
  bool get escreve => this == medio || this == avancado;
}

/// Para que lado o cartão pergunta: inglês → português (vê o inglês, responde o português),
/// português → inglês (o contrário), misturado (cada cartão sorteia o seu lado) ou ditado:
/// só o ÁUDIO na frente (sem texto) e a pessoa escreve em inglês o que ouviu; shadowing: só o áudio e a pessoa
/// REPETE FALANDO (o reconhecedor confere por palavra, [shadowing.dart]).
enum SentidoCartao {
  enPt('en-pt', 'EN → PT'),
  ptEn('pt-en', 'PT → EN'),
  misto('misto', '🔀 Misturado'),
  audio('audio', '🎧 Áudio → escrever'),
  shadowing('shadowing', '🗣 Ouvir e repetir');

  const SentidoCartao(this.id, this.rotulo);
  final String id, rotulo;

  static SentidoCartao? porId(String? id) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Partes da frase (palavras e o que há entre elas) — base do Médio

class ParteFrase extends Equatable {
  /// O texto como está na frase (a palavra com a grafia original, ou o espaço/pontuação).
  final String texto;

  /// É palavra (letras/números)? O resto é espaço e pontuação.
  final bool palavra;

  /// No Médio: esta palavra fica como lacuna para a pessoa escrever.
  final bool escondida;

  const ParteFrase(this.texto, {this.palavra = false, this.escondida = false});

  ParteFrase comEscondida(bool v) => ParteFrase(texto, palavra: palavra, escondida: v);

  @override
  List<Object?> get props => [texto, palavra, escondida];
}

/// A frase em palavras e separadores, na ordem, sem perder nada (juntar os `texto` devolve a frase).
List<ParteFrase> partirFrase(String frase) {
  final r = <ParteFrase>[];
  var pos = 0;
  for (final m in unidadeDePalavra.allMatches(frase)) {
    if (m.start > pos) r.add(ParteFrase(frase.substring(pos, m.start)));
    r.add(ParteFrase(m[0]!, palavra: true));
    pos = m.end;
  }
  if (pos < frase.length) r.add(ParteFrase(frase.substring(pos)));
  return r;
}

/// Quantas palavras ficam como lacuna numa frase de [n] palavras (um pouco mais da metade;
/// sempre pelo menos 1 e, passando de 1 palavra, sempre sobra 1 à vista).
int quantasEscondidas(int n) {
  if (n <= 1) return n;
  return (n * 0.55).round().clamp(1, n - 1);
}

/// Marca quais palavras viram lacuna: as mais compridas têm mais chance (são as que
/// carregam o sentido), com um sorteio para não ser sempre as mesmas.
List<ParteFrase> esconderPalavras(List<ParteFrase> partes, Random aleatorio) {
  final indices = [for (var i = 0; i < partes.length; i++) if (partes[i].palavra) i];
  final alvo = quantasEscondidas(indices.length);
  final nota = {for (final i in indices) i: partes[i].texto.length + aleatorio.nextDouble() * 3};
  final escondidas = ([...indices]..sort((a, b) => nota[b]!.compareTo(nota[a]!))).take(alvo).toSet();
  return [for (var i = 0; i < partes.length; i++) escondidas.contains(i) ? partes[i].comEscondida(true) : partes[i]];
}

/// O cartão de lacuna da leitura: esconde SÓ a palavra [alvo] (todas as vezes que ela aparece na
/// frase, sem ligar para maiúscula); null se a palavra não está nas [partes] (aí vale o sorteio de sempre).
List<ParteFrase>? lacunaUnica(List<ParteFrase> partes, String alvo) {
  final a = alvo.trim().toLowerCase();
  if (a.isEmpty) return null;
  var achou = false;
  final r = [
    for (final p in partes)
      if (p.palavra && p.texto.toLowerCase() == a)
        () {
          achou = true;
          return p.comEscondida(true);
        }()
      else
        p,
  ];
  return achou ? r : null;
}

/// Quantas lacunas há nas [partes].
int contarLacunas(List<ParteFrase> partes) => partes.where((p) => p.palavra && p.escondida).length;

/// Confere as [respostas] (uma por lacuna, na ordem) com as palavras escondidas de [partes].
/// Cada lacuna vale uma palavra: sem ligar para maiúscula, acento e um errinho de digitação.
/// Só as lacunas contam no "acertou X de Y"; as palavras à vista aparecem neutras. Sugere Bom
/// se acertou todas, Difícil se acertou a maior parte, senão Errei.
ComparacaoResposta conferirLacunas(List<ParteFrase> partes, List<String> respostas) {
  final esperada = <Segmento>[], digitada = <Segmento>[];
  var lacuna = 0, certas = 0;
  for (final p in partes) {
    if (!p.palavra || !p.escondida) {
      esperada.add(Segmento(p.texto));
      digitada.add(Segmento(p.texto));
      continue;
    }
    final dada = lacuna < respostas.length ? respostas[lacuna].trim() : '';
    lacuna++;
    final ok = dada.isNotEmpty && palavrasIguais(p.texto, dada);
    if (ok) certas++;
    esperada.add(Segmento(p.texto, ok));
    digitada.add(Segmento(dada.isEmpty ? '___' : dada, ok));
  }
  final total = contarLacunas(partes);
  final taxa = total == 0 ? 0.0 : certas / total;
  final exata = total > 0 && certas == total;
  return ComparacaoResposta(
    esperada: esperada,
    digitada: digitada,
    cobertura: taxa,
    precisao: taxa,
    exata: exata,
    sugerida: exata ? Rating.good : (taxa >= .6 ? Rating.hard : Rating.again),
  );
}

// ---------------------------------------------------------------------------
// Blocos de palavras — base do Fácil

/// Um bloco para montar a frase: uma palavra da resposta ou uma de enfeite (que não pertence a ela).
class Bloco extends Equatable {
  final int id;
  final String texto;

  /// Palavra que NÃO está na resposta (só para confundir).
  final bool distrator;
  const Bloco(this.id, this.texto, {this.distrator = false});

  @override
  List<Object?> get props => [id, texto, distrator];
}

/// Palavras comuns para completar o banco quando as outras frases não dão enfeites suficientes.
const palavrasDeReservaPt = [
  'casa', 'muito', 'agora', 'sempre', 'amigo', 'trabalho', 'tempo', 'cidade', 'comer', 'falar', 'bonito',
  'ontem', 'amanhã', 'hoje', 'ainda', 'também', 'nunca', 'grande', 'pequeno', 'outro', 'minha', 'nosso',
  'quando', 'porque', 'onde', 'carro', 'água', 'comida', 'dinheiro', 'família', 'escola', 'livro',
];

const palavrasDeReservaEn = [
  'house', 'very', 'now', 'always', 'friend', 'work', 'time', 'city', 'eat', 'speak', 'beautiful',
  'yesterday', 'tomorrow', 'today', 'still', 'also', 'never', 'big', 'small', 'other', 'my', 'our',
  'when', 'because', 'where', 'car', 'water', 'food', 'money', 'family', 'school', 'book',
];

/// Quantos blocos de enfeite entram numa frase de [n] palavras (2 a 5, perto de metade).
int quantosDistratores(int n) => (n * 0.5).round().clamp(2, 5);

/// As palavras de [frases] que dão enfeite: 2+ letras e fora de [proibidas] (já normalizadas),
/// sem repetir, na ordem sorteada.
List<String> _candidatas(Iterable<String> frases, Set<String> proibidas, Random aleatorio) {
  final vistas = <String, String>{}; // normalizada → grafia
  for (final f in ([...frases]..shuffle(aleatorio)).take(60)) {
    for (final p in partirFrase(f)) {
      if (!p.palavra) continue;
      final n = normalizarPalavra(p.texto);
      if (n.length >= 2 && !proibidas.contains(n)) vistas.putIfAbsent(n, () => p.texto);
    }
  }
  return [...vistas.values]..shuffle(aleatorio);
}

/// Os blocos da frase [esperada], embaralhados, misturados com palavras de enfeite que nunca
/// repetem uma palavra da resposta. Os enfeites vêm primeiro de [apoio] (outras frases da
/// sessão, no mesmo idioma da resposta), depois de [extra] (outras frases do curso) e por fim
/// da [reserva]. Mesma semente, mesmos blocos. Frase sem palavra devolve lista vazia.
List<Bloco> montarBlocos(
  String esperada, {
  required List<String> apoio,
  List<String> extra = const [],
  List<String> reserva = palavrasDeReservaPt,
  required Random aleatorio,
  int? distratores,
}) {
  final palavras = [for (final p in partirFrase(esperada)) if (p.palavra) p.texto];
  if (palavras.isEmpty) return const [];
  final proibidas = {for (final p in palavras) normalizarPalavra(p)};
  final quantos = distratores ?? quantosDistratores(palavras.length);
  final enfeites = <String>[];
  final usadas = {...proibidas};
  void completar(List<String> fonte) {
    for (final w in fonte) {
      if (enfeites.length >= quantos) return;
      final n = normalizarPalavra(w);
      if (usadas.add(n)) enfeites.add(w);
    }
  }

  completar(_candidatas(apoio, proibidas, aleatorio));
  if (enfeites.length < quantos) completar(_candidatas(extra, usadas, aleatorio));
  if (enfeites.length < quantos) completar([...reserva]..shuffle(aleatorio));
  final todos = [
    for (final p in palavras) (p, false),
    for (final e in enfeites) (e, true),
  ]..shuffle(aleatorio);
  return [for (var i = 0; i < todos.length; i++) Bloco(i, todos[i].$1, distrator: todos[i].$2)];
}

/// Confere a frase montada com [escolhidos] (na ordem em que a pessoa tocou). Montar com blocos é
/// reconhecer, não lembrar: só a frase certa, na ordem certa, sugere Bom; quase certa (ou as
/// palavras certas em outra ordem), Difícil; senão Errei.
ComparacaoResposta conferirBlocos(String esperada, List<Bloco> escolhidos) {
  final c = compararResposta(esperada, escolhidos.map((b) => b.texto).join(' '));
  final Rating nota = c.exata ? Rating.good : (c.cobertura >= .85 && c.precisao >= .85 ? Rating.hard : Rating.again);
  return c.comSugestao(nota);
}
