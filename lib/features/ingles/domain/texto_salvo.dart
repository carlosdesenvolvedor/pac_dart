import 'package:equatable/equatable.dart';

import '../../curso/domain/curriculo.dart';
import 'limpar_traducao.dart';
import 'texto_para_frases.dart';

/// Uma frase do texto colado e a tradução (automática, corrigida ou não).
class FraseDoTexto extends Equatable {
  final String en;
  final String pt;

  /// Cartão de lacuna da leitura: a palavra (da frase em inglês) que a pessoa quis guardar e, se
  /// achada na tradução, o pedaço dela que corresponde. Vazios = frase comum (o caso de sempre).
  final String alvo, alvoPt;

  const FraseDoTexto(this.en, this.pt, {this.alvo = '', this.alvoPt = ''});

  Map<String, dynamic> toJson() => {
        'en': en,
        'pt': pt,
        if (alvo.isNotEmpty) 'alvo': alvo,
        if (alvoPt.isNotEmpty) 'alvoPt': alvoPt,
      };

  static FraseDoTexto? fromJson(Object? j) {
    if (j is! Map) return null;
    final en = j['en'], pt = j['pt'];
    if (en is! String || pt is! String || en.isEmpty) return null;
    // registros antigos não têm alvo: continuam valendo. A tradução passa pela limpeza de novo: textos salvos
    // antes de o app tirar as marcas do MyMemory (`<g id="1">…</g>`) ficam certos sem a pessoa refazer a lição.
    return FraseDoTexto(en, limparTraducao(pt),
        alvo: j['alvo'] is String ? j['alvo'] as String : '',
        alvoPt: j['alvoPt'] is String ? limparTraducao(j['alvoPt'] as String) : '');
  }

  @override
  List<Object?> get props => [en, pt, alvo, alvoPt];
}

/// Um texto que a pessoa colou: guardamos só os pares inglês/português; as
/// lições são remontadas daqui (a mesma divisão, sempre).
class TextoSalvo extends Equatable {
  /// Rótulo da faixa do mapa onde moram os textos colados.
  static const etapa = 'Meus textos';

  /// Início do id das lições destes textos (a chave do progresso delas).
  static const prefixoLicao = 'txt-';

  final String id;
  final String titulo;
  final DateTime criadoEm;
  final List<FraseDoTexto> frases;

  /// Lições de 8 frases em sequência (8, 8, 1…) em vez de equilibradas: para o baralho que
  /// CRESCE de uma em uma ("Meus cartões"), assim acrescentar uma frase nunca muda o que
  /// já está nas lições anteriores (o progresso delas é por id).
  final bool sequencial;

  const TextoSalvo({
    required this.id,
    required this.titulo,
    required this.criadoEm,
    required this.frases,
    this.sequencial = false,
  });

  /// Id curto e único o bastante para uma pessoa só ("k3j9x2a").
  static String novoId([DateTime? agora]) => (agora ?? DateTime.now()).microsecondsSinceEpoch.toRadixString(36);

  /// Cada texto vira UMA trilha de lições de até 8 frases ("Parte 1", "Parte 2"…).
  /// As frases não levam `id`: a revisão espaçada as reconhece pelo texto, e a
  /// mesma frase em dois textos é a mesma carta.
  Trilha comoTrilha() {
    final partes = sequencial ? repartirEmSequencia(frases) : repartirEmLicoes(frases);
    return Trilha(
      nivel: titulo,
      emoji: '📝',
      descricao: '${frases.length} ${frases.length == 1 ? 'frase' : 'frases'} do seu texto, com tradução automática.',
      etapa: etapa,
      textoId: id,
      licoes: [
        for (var i = 0; i < partes.length; i++)
          Licao(
            id: '$prefixoLicao$id-${i + 1}',
            nome: 'Parte ${i + 1}',
            emoji: '📝',
            trechos: [for (final f in partes[i]) Trecho(cod: f.en, dica: f.pt, out: '', alvo: f.alvo, alvoPt: f.alvoPt)],
          ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'criadoEm': criadoEm.millisecondsSinceEpoch,
        'frases': [for (final f in frases) f.toJson()],
        if (sequencial) 'seq': true,
      };

  /// Null se o registro está quebrado (nunca derruba o app por causa de um texto).
  static TextoSalvo? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], titulo = j['titulo'], quando = j['criadoEm'], lista = j['frases'];
    if (id is! String || id.isEmpty || titulo is! String || lista is! List) return null;
    final frases = [for (final e in lista) ?FraseDoTexto.fromJson(e)];
    if (frases.isEmpty) return null;
    return TextoSalvo(
      id: id,
      titulo: titulo,
      criadoEm: DateTime.fromMillisecondsSinceEpoch(quando is int ? quando : 0),
      frases: frases,
      sequencial: j['seq'] == true,
    );
  }

  /// Uma cópia com [frases] no lugar.
  TextoSalvo comFrases(List<FraseDoTexto> novas) =>
      TextoSalvo(id: id, titulo: titulo, criadoEm: criadoEm, frases: novas, sequencial: sequencial);

  @override
  List<Object?> get props => [id, titulo, criadoEm, frases, sequencial];
}
