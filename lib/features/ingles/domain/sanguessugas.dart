import '../../curso/domain/curriculo.dart';
import 'baralhos.dart';
import 'revisao.dart';
import 'srs.dart';

/// Sanguessuga (leech, no Anki): o cartão que a pessoa erra e erra, e que gasta tempo demais.
/// O padrão é o do Anki: 8 lapsos (vezes que errou depois de já aprendido).
const limiteSanguessuga = 8;

/// Um cartão sanguessuga: qual (digitar de memória ou o virado inglês → português), a frase e os lapsos.
class Sanguessuga {
  /// A chave do cartão (com o sufixo do sentido, se for o de virar).
  final String chave;

  /// A frase do curso a que ele pertence.
  final Trecho frase;
  final CartaoSrs cartao;

  const Sanguessuga({required this.chave, required this.frase, required this.cartao});

  /// É o cartão de virar (inglês → português)?
  bool get reverso => Revisao.ehReversa(chave);

  int get lapsos => cartao.lapsos;
}

/// Os cartões de [cartoes] com [limite] lapsos ou mais, do que mais erra para o que menos, sem os
/// suspensos (esses a pessoa já resolveu) e sem os de frases que saíram do curso/dos textos.
List<Sanguessuga> sanguessugasDe(Map<String, CartaoSrs> cartoes, IndiceBaralhos indice, {int limite = limiteSanguessuga}) {
  final r = <Sanguessuga>[];
  for (final e in cartoes.entries) {
    final c = e.value;
    if (c.suspenso || c.lapsos < limite) continue;
    final frase = indice.porChave[Revisao.baseDe(e.key)];
    if (frase == null) continue;
    r.add(Sanguessuga(chave: e.key, frase: frase, cartao: c));
  }
  r.sort((a, b) {
    final porLapsos = b.lapsos.compareTo(a.lapsos);
    return porLapsos != 0 ? porLapsos : a.chave.compareTo(b.chave);
  });
  return r;
}

// Palavras comuns demais para servirem de "ponte" entre duas frases.
const _comuns = {
  'the', 'and', 'you', 'your', 'that', 'this', 'with', 'have', 'from', 'are', 'was', 'were', 'for', 'not', 'but', 'what',
  'when', 'where', 'who', 'how', 'why', 'can', 'could', 'would', 'should', 'will', 'there', 'their', 'they', 'them', 'then',
  'than', 'been', 'has', 'had', 'does', 'did', 'its', 'our', 'out', 'about', 'into', 'just', 'very', 'some', 'any', 'more',
};

/// As palavras que "pesam" na frase: letras, 4 ou mais, em minúsculas e fora das comuns.
List<String> palavrasChave(String frase) => [
      for (final m in RegExp(r"[A-Za-z]+(?:'[A-Za-z]+)?").allMatches(frase))
        if (m.group(0)!.length >= 4 && !_comuns.contains(m.group(0)!.toLowerCase())) m.group(0)!.toLowerCase(),
    ];

/// Até [max] OUTRAS frases (de [todas]) que usam uma palavra da [frase] — para ver a palavra difícil em
/// outro contexto. Escolhe a palavra mais RARA entre as da frase (a que aparece em menos frases, mas em
/// pelo menos uma outra), porque é ela que mais ajuda; sem outra frase, lista vazia.
List<Trecho> exemplosParecidos(Trecho frase, Iterable<Trecho> todas, {int max = 2}) {
  final minhas = palavrasChave(frase.cod).toSet();
  if (minhas.isEmpty) return const [];
  final porPalavra = <String, List<Trecho>>{for (final p in minhas) p: []};
  final vistas = <String>{frase.cod.toLowerCase()};
  for (final t in todas) {
    if (!vistas.add(t.cod.toLowerCase())) continue;
    final dela = palavrasChave(t.cod).toSet();
    for (final p in minhas) {
      if (dela.contains(p)) porPalavra[p]!.add(t);
    }
  }
  final candidatas = [
    for (final e in porPalavra.entries)
      if (e.value.isNotEmpty) e,
  ]..sort((a, b) {
      final porRaridade = a.value.length.compareTo(b.value.length);
      return porRaridade != 0 ? porRaridade : a.key.compareTo(b.key);
    });
  if (candidatas.isEmpty) return const [];
  // frases curtas primeiro: fáceis de ler como exemplo
  final lista = [...candidatas.first.value]..sort((a, b) => a.cod.length.compareTo(b.cod.length));
  return lista.take(max).toList();
}

/// A palavra-ponte usada por [exemplosParecidos] (para destacar na tela).
String? palavraPonte(Trecho frase, Iterable<Trecho> todas) {
  final ex = exemplosParecidos(frase, todas, max: 1);
  if (ex.isEmpty) return null;
  final minhas = palavrasChave(frase.cod).toSet();
  final dela = palavrasChave(ex.first.cod).toSet();
  final comuns = minhas.intersection(dela).toList()..sort();
  return comuns.isEmpty ? null : comuns.first;
}
