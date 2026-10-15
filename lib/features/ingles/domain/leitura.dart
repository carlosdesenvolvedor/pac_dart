import 'package:equatable/equatable.dart';

import '../../curso/domain/curriculo.dart';
import 'cartoes_texto.dart';
import 'nivel_resposta.dart';
import 'texto_salvo.dart';

/// Um texto para LER: frases em inglês, cada uma com a tradução (para a pessoa ver a frase inteira
/// ao tocar numa palavra). Vem do JSON dos textos graduados ou dos "Meus textos" já traduzidos.
class Leitura extends Equatable {
  final String id, titulo;

  /// A etapa do curso (A1…B2) ou "Meus textos".
  final String etapa;
  final List<FraseDoTexto> frases;

  /// Veio dos textos da própria pessoa (colados) e não dos graduados.
  final bool propria;

  const Leitura({required this.id, required this.titulo, required this.etapa, required this.frases, this.propria = false});

  /// Nunca lança: texto sem id, título ou frases é descartado (null).
  static Leitura? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], titulo = j['titulo'], lista = j['frases'];
    if (id is! String || id.isEmpty || titulo is! String || titulo.isEmpty || lista is! List) return null;
    final frases = [for (final e in lista) ?FraseDoTexto.fromJson(e)];
    if (frases.isEmpty) return null;
    final etapa = j['etapa'];
    return Leitura(id: id, titulo: titulo, etapa: etapa is String && etapa.isNotEmpty ? etapa : 'A1', frases: frases);
  }

  /// A leitura de uma trilha de texto colado (as frases voltam das lições). Null se não é texto da pessoa
  /// ou é a lista de cartões ("Meus cartões" não é um texto para ler).
  static Leitura? deTrilha(Trilha t) {
    if (!t.propria || t.textoId.isEmpty || t.textoId == idCartoesAvulsos) return null;
    final frases = [
      for (final l in t.licoes)
        for (final x in l.trechos) FraseDoTexto(x.cod, x.dicaPlana),
    ];
    if (frases.isEmpty) return null;
    return Leitura(id: t.textoId, titulo: t.nivel, etapa: TextoSalvo.etapa, frases: frases, propria: true);
  }

  @override
  List<Object?> get props => [id, titulo, etapa, frases, propria];
}

/// Os textos graduados do JSON (itens inválidos e ids repetidos são ignorados).
List<Leitura> leiturasDeJson(Object? bruto) {
  final vistos = <String>{};
  final r = <Leitura>[];
  if (bruto is! List) return r;
  for (final j in bruto) {
    final l = Leitura.fromJson(j);
    if (l != null && vistos.add(l.id)) r.add(l);
  }
  return r;
}

/// O pedaço da tradução [pt] da frase que corresponde à tradução da palavra ([traducaoDaPalavra]):
/// só vale se a palavra traduzida aparece INTEIRA na frase em português (sem ligar para caixa e acento
/// final); senão '' — uma tradução de palavra isolada erra o sentido, e nesse caso não marcamos nada.
String alvoNaTraducao(String pt, String traducaoDaPalavra) {
  final t = traducaoDaPalavra.trim();
  if (t.isEmpty || t.contains(' ')) return '';
  final m = RegExp('(?<![\\p{L}])${RegExp.escape(t)}(?![\\p{L}])', caseSensitive: false, unicode: true).firstMatch(pt);
  return m == null ? '' : pt.substring(m.start, m.end);
}

/// O cartão de lacuna para a [palavra] tocada na [frase] (com a tradução da frase como pista).
/// Null se a frase não tem tradução (sem ela o cartão não teria o que mostrar na frente) ou se a
/// palavra não está na frase.
CartaoEscrito? cartaoDeLacuna(FraseDoTexto frase, String palavra, {String traducaoDaPalavra = ''}) {
  final p = palavra.trim();
  if (p.isEmpty || frase.pt.trim().isEmpty) return null;
  final achada = partirFrase(frase.en).where((x) => x.palavra && x.texto.toLowerCase() == p.toLowerCase()).firstOrNull;
  if (achada == null) return null;
  return CartaoEscrito(frase.en, frase.pt, alvo: achada.texto, alvoPt: alvoNaTraducao(frase.pt, traducaoDaPalavra));
}
