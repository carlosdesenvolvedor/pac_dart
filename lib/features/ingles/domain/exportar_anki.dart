import 'baralhos.dart';
import 'srs.dart';

/// Exportar para o Anki de verdade: o arquivo de texto separado por TAB que o
/// "Importar" do Anki lê (frente = inglês, verso = tradução, 3ª coluna = tags).
/// Só texto: o áudio e a memória (intervalos) não vão — o Anki recomeça os cartões.

/// Um nome de tag que o Anki aceita (sem espaço): `Paclingo::A1_Fundação::Primeiro_contato`.
String tagDoAnki(Iterable<String> partes) => partes
    // primeiro tira os símbolos (· : ' ,), depois junta as palavras com "_" — senão "A1 · Fundação" daria "A1__Fundação"
    .map((p) => p.replaceAll(RegExp(r'[^\p{L}\p{N}_\-\s]', unicode: true), '').trim().replaceAll(RegExp(r'\s+'), '_'))
    .where((p) => p.isNotEmpty)
    .join('::');

String _campo(String s) => s.replaceAll(RegExp(r'[\t\r\n]+'), ' ').trim();

/// O texto para o Anki importar. [invertido] põe o português na frente.
/// Frases repetidas em vários baralhos saem uma vez só (com as tags dos dois).
String exportarParaAnki(Iterable<Baralho> baralhos, {bool invertido = false}) {
  final linhas = <String, (String, String, List<String>)>{};
  for (final b in baralhos) {
    final tag = tagDoAnki(['Paclingo', b.grupo, b.nome]);
    for (final f in b.frases) {
      final en = _campo(f.cod), pt = _campo(f.dicaPlana);
      if (en.isEmpty || pt.isEmpty) continue;
      final k = en.toLowerCase();
      final atual = linhas[k];
      if (atual == null) {
        linhas[k] = (en, pt, [tag]);
      } else if (!atual.$3.contains(tag)) {
        atual.$3.add(tag);
      }
    }
  }
  final b = StringBuffer()
    ..writeln('#separator:tab')
    ..writeln('#html:false')
    ..writeln('#tags column:3');
  for (final (en, pt, tags) in linhas.values) {
    b.writeln('${invertido ? pt : en}\t${invertido ? en : pt}\t${tags.join(' ')}');
  }
  return b.toString();
}

/// O histórico de revisões em CSV (`data,sentido,frase,nota,primeira_vez`), para guardar ou
/// analisar fora do app (e, com milhares de revisões, otimizar os parâmetros do FSRS).
/// [frases] devolve o texto em inglês de uma chave; sem ele, sai a própria chave.
String exportarHistorico(Iterable<EntradaHistorico> historico, {String Function(String chave)? frases}) {
  String csv(String s) => s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  final b = StringBuffer('data,sentido,frase,nota,primeira_vez\n');
  final ordenado = [...historico]..sort((a, c) => a.dia.compareTo(c.dia));
  for (final e in ordenado) {
    final reversa = e.chave.endsWith('~r');
    final base = reversa ? e.chave.substring(0, e.chave.length - 2) : e.chave;
    final d = DateTime.utc(1970, 1, 1 + e.dia);
    final data = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    b.writeln('$data,${reversa ? 'ingles-portugues' : 'portugues-ingles'},${csv(frases?.call(base) ?? base)},${e.nota},${e.primeira ? 1 : 0}');
  }
  return b.toString();
}
