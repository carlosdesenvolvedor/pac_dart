import 'package:equatable/equatable.dart';

import 'texto_para_frases.dart';
import 'texto_salvo.dart';

/// Os cartões que a pessoa escreve (frente em inglês, verso em português) e as
/// listas que ela importa — no Anki, o "Adicionar" e o "Importar".

/// O baralho dos cartões criados um a um ("Meus cartões").
const idCartoesAvulsos = 'cartoes';
const tituloCartoesAvulsos = 'Meus cartões';

/// Um cartão pronto (o inglês já em letras que se digitam).
class CartaoEscrito extends Equatable {
  final String en;
  final String pt;

  /// Cartão de lacuna da leitura: a palavra guardada (e o pedaço da tradução que corresponde).
  final String alvo, alvoPt;

  const CartaoEscrito(this.en, this.pt, {this.alvo = '', this.alvoPt = ''});

  FraseDoTexto get comoFrase => FraseDoTexto(en, pt, alvo: alvo, alvoPt: alvoPt);

  @override
  List<Object?> get props => [en, pt, alvo, alvoPt];
}

/// A frente (inglês) e o verso (português) que a pessoa digitou, prontos para virar
/// cartão — ou o motivo de não servirem. A frente passa pelo mesmo conserto do texto
/// colado (aspas curvas, acento…), porque ela também vira frase para DIGITAR.
({CartaoEscrito? cartao, String? erro, bool simplificou}) prepararCartao(String frente, String verso) {
  final simplificou = frente.runes.any((r) => r > 0x7E && r != 0xA0);
  final en = simplificarParaDigitar(frente).replaceAll(RegExp(r'\s+'), ' ').trim();
  final pt = verso.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (!RegExp(r'[A-Za-z]').hasMatch(en)) {
    return (cartao: null, erro: 'Escreva a frente em inglês (com pelo menos uma letra).', simplificou: simplificou);
  }
  if (pt.isEmpty) return (cartao: null, erro: 'Escreva o verso: a tradução em português.', simplificou: simplificou);
  if (en.length > 300) return (cartao: null, erro: 'A frente é longa demais para digitar (máx. 300 letras).', simplificou: simplificou);
  return (cartao: CartaoEscrito(en, pt), erro: null, simplificou: simplificou);
}

class ResultadoImportacao extends Equatable {
  final List<CartaoEscrito> cartoes;

  /// Linhas que não viraram cartão (sem verso, sem letra, repetidas).
  final int ignoradas;

  /// Havia aspas curvas, acentos… no inglês: viraram letras simples.
  final bool simplificou;

  /// A lista passou do máximo e o resto foi cortado.
  final bool cortado;

  const ResultadoImportacao({this.cartoes = const [], this.ignoradas = 0, this.simplificou = false, this.cortado = false});

  @override
  List<Object?> get props => [cartoes, ignoradas, simplificou, cortado];
}

/// O máximo de cartões de uma importação (cada um vira frase para digitar 5 vezes).
const maxCartoesPorImportacao = 500;

/// Lê uma lista de cartões, uma por linha, "inglês, separador, português":
/// - o arquivo de texto do Anki (campos separados por TAB; as linhas `#separator:…`,
///   `#html:…` e a coluna extra de tags são entendidas/ignoradas);
/// - `inglês ; português` ou `inglês | português` (o 1º separador da linha vale).
/// Tira o HTML que o Anki guarda (`<br>`, `&nbsp;`…) e as aspas que ele põe em volta
/// de campos com tabulação.
ResultadoImportacao lerListaDeCartoes(String texto, {int max = maxCartoesPorImportacao}) {
  final linhas = texto.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  final cartoes = <CartaoEscrito>[];
  final vistos = <String>{};
  var ignoradas = 0, simplificou = false, cortado = false;
  for (final bruta in linhas) {
    final linha = bruta.trim();
    if (linha.isEmpty || linha.startsWith('#')) continue;
    final campos = _campos(bruta);
    if (campos == null) {
      ignoradas++;
      continue;
    }
    final p = prepararCartao(_semHtml(campos.$1), _semHtml(campos.$2));
    final c = p.cartao;
    if (c == null || !vistos.add(c.en.toLowerCase())) {
      ignoradas++;
      continue;
    }
    if (cartoes.length >= max) {
      cortado = true;
      continue;
    }
    if (p.simplificou) simplificou = true;
    cartoes.add(c);
  }
  return ResultadoImportacao(cartoes: cartoes, ignoradas: ignoradas, simplificou: simplificou, cortado: cortado);
}

/// (frente, verso) de uma linha, ou null se não dá para separar.
(String, String)? _campos(String linha) {
  final partes = linha.contains('\t')
      ? linha.split('\t')
      : (() {
          final i = [linha.indexOf(';'), linha.indexOf('|')].where((x) => x > 0).fold<int?>(null, (a, b) => a == null || b < a ? b : a);
          return i == null ? <String>[] : [linha.substring(0, i), linha.substring(i + 1)];
        })();
  if (partes.length < 2) return null;
  return (_semAspas(partes[0].trim()), _semAspas(partes[1].trim()));
}

String _semAspas(String s) => s.length >= 2 && s.startsWith('"') && s.endsWith('"') ? s.substring(1, s.length - 1).replaceAll('""', '"') : s;

String _semHtml(String s) => s
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&');

/// O baralho de cartões escritos/importados vira um [TextoSalvo] (lições + baralho).
TextoSalvo textoDeCartoes(
  Iterable<CartaoEscrito> cartoes, {
  required String titulo,
  String? id,
  DateTime? criadoEm,
  bool sequencial = false,
}) =>
    TextoSalvo(
      id: id ?? TextoSalvo.novoId(),
      titulo: titulo,
      criadoEm: criadoEm ?? DateTime.now(),
      frases: [for (final c in cartoes) c.comoFrase],
      sequencial: sequencial,
    );
