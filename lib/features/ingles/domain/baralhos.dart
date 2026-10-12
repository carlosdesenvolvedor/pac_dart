import 'package:equatable/equatable.dart';

import '../../curso/domain/curriculo.dart';
import 'revisao.dart';
import 'srs.dart';

/// A chave da frase na revisão (o id do conteúdo; sem id, o hash do texto).
String chaveDaFrase(Trecho f) => Revisao.chaveDe(id: f.id, cod: f.cod);

/// Os baralhos do inglês, no jeito do Anki: cada trilha é um baralho, agrupados
/// pela etapa do curso (A1, A2…) e, à parte, "Meus textos" (um baralho por texto
/// colado). Só organiza as frases que já existem — não guarda nada.
class Baralho extends Equatable {
  /// `Trilha.baralhoId` (`tr:<slug>` ou `txt:<id>`).
  final String id;
  final String nome;
  final String emoji;

  /// A etapa do curso ("A1 · Fundação") ou "Meus textos".
  final String grupo;
  final bool propria;

  /// As frases (cada chave uma vez, na ordem do curso).
  final List<Trecho> frases;

  const Baralho({
    required this.id,
    required this.nome,
    required this.emoji,
    required this.grupo,
    required this.propria,
    required this.frases,
  });

  @override
  List<Object?> get props => [id, nome, emoji, grupo, propria, frases];
}

/// As contagens de um baralho para uma tela "Baralhos" (os números do Anki).
class ContagemBaralho extends Equatable {
  /// Frases do baralho.
  final int total;

  /// Frases que já são cartão digitado (português → inglês).
  final int aprendidas;

  /// Cartões português → inglês que vencem hoje.
  final int devidas;

  /// Cartões de memória de 3 semanas ou mais (os dois sentidos).
  final int maduras;

  /// O sentido inglês → português está ligado neste baralho?
  final bool invertido;

  /// Cartões inglês → português que já existem, vencem hoje e ainda sem cartão.
  final int invertidasDevidas;
  final int invertidasNovas;
  final int invertidasTotal;

  const ContagemBaralho({
    required this.total,
    required this.aprendidas,
    required this.devidas,
    required this.maduras,
    required this.invertido,
    required this.invertidasDevidas,
    required this.invertidasNovas,
    required this.invertidasTotal,
  });

  /// O que vence hoje no baralho, nos dois sentidos.
  int get aRevisar => devidas + invertidasDevidas;

  @override
  List<Object?> get props =>
      [total, aprendidas, devidas, maduras, invertido, invertidasDevidas, invertidasNovas, invertidasTotal];
}

/// Os baralhos de uma lista de trilhas + o caminho de uma chave de cartão até a
/// frase e os baralhos dela.
class IndiceBaralhos {
  final List<Baralho> baralhos;

  /// Chave da frase (sem o sufixo do sentido) → a frase.
  final Map<String, Trecho> porChave;

  /// Chave da frase → baralhos que a têm (uma frase pode estar em mais de uma trilha).
  final Map<String, List<String>> baralhosDe;

  IndiceBaralhos._(this.baralhos, this.porChave, this.baralhosDe);

  /// Monta pelos [trilhas] do currículo carregado (as do curso e as do aluno).
  factory IndiceBaralhos.de(List<Trilha> trilhas) {
    final baralhos = <Baralho>[];
    final porChave = <String, Trecho>{};
    final baralhosDe = <String, List<String>>{};
    for (final t in trilhas) {
      if (t.licoes.isEmpty) continue;
      final id = t.baralhoId;
      final frases = <Trecho>[];
      final vistas = <String>{};
      for (final l in t.licoes) {
        for (final f in l.trechos) {
          final k = chaveDaFrase(f);
          if (!vistas.add(k)) continue;
          frases.add(f);
          porChave.putIfAbsent(k, () => f);
          (baralhosDe[k] ??= []).add(id);
        }
      }
      baralhos.add(Baralho(
        id: id,
        nome: t.nivel,
        emoji: t.emoji,
        grupo: t.propria ? 'Meus textos' : (t.etapa.isEmpty ? 'Curso' : t.etapa),
        propria: t.propria,
        frases: frases,
      ));
    }
    return IndiceBaralhos._(baralhos, porChave, baralhosDe);
  }

  Baralho? baralho(String id) {
    for (final b in baralhos) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Os grupos na ordem em que aparecem (o curso por etapa e "Meus textos" no fim).
  List<String> get grupos {
    final r = <String>[];
    for (final b in baralhos) {
      if (!r.contains(b.grupo)) r.add(b.grupo);
    }
    return r;
  }

  List<Baralho> doGrupo(String grupo) => [for (final b in baralhos) if (b.grupo == grupo) b];

  /// A chave [chave] (de cartão, em qualquer sentido) pertence ao baralho [baralho]?
  bool pertence(String chave, String baralho) => baralhosDe[Revisao.baseDe(chave)]?.contains(baralho) ?? false;

  /// As contagens do baralho [b] dado o estado dos [cartoes] hoje.
  /// [ligados] são os baralhos com o sentido inglês → português ligado.
  ContagemBaralho contar(Baralho b, Map<String, CartaoSrs> cartoes, int hoje, {required Set<String> ligados}) {
    var aprendidas = 0, devidas = 0, maduras = 0, invDevidas = 0, invNovas = 0, invTotal = 0;
    final invertido = ligados.contains(b.id);
    for (final f in b.frases) {
      final k = chaveDaFrase(f);
      final c = cartoes[k];
      if (c != null) {
        aprendidas++;
        if (c.devidaEm(hoje)) devidas++;
        if (c.madura) maduras++;
      }
      final r = cartoes[Revisao.chaveReversa(k)];
      if (r != null) {
        invTotal++;
        if (r.devidaEm(hoje)) invDevidas++;
        if (r.madura) maduras++;
      } else if (invertido) {
        invNovas++;
      }
    }
    return ContagemBaralho(
      total: b.frases.length,
      aprendidas: aprendidas,
      devidas: devidas,
      maduras: maduras,
      invertido: invertido,
      invertidasDevidas: invDevidas,
      invertidasNovas: invNovas,
      invertidasTotal: invTotal,
    );
  }

  /// As frases dos baralhos [ligados], na ordem do curso, sem repetir.
  List<Trecho> frasesDosLigados(Set<String> ligados) {
    final vistas = <String>{};
    return [
      for (final b in baralhos)
        if (ligados.contains(b.id))
          for (final f in b.frases)
            if (vistas.add(chaveDaFrase(f))) f,
    ];
  }
}

/// Quantos cartões vencem em cada um dos próximos [dias] dias (o dia 0 é hoje e
/// já inclui os atrasados) — o "previsão" das estatísticas do Anki. Suspensos não entram.
List<int> previsaoDeCarga(Map<String, CartaoSrs> cartoes, int hoje, {int dias = 14}) {
  final r = List<int>.filled(dias, 0);
  for (final c in cartoes.values) {
    if (c.suspenso) continue;
    final quando = (c.proximoDia > c.enterradoAte ? c.proximoDia : c.enterradoAte) - hoje;
    final i = quando < 0 ? 0 : quando;
    if (i < dias) r[i]++;
  }
  return r;
}

/// A retenção REAL: das revisões de cartões já aprendidos desde [desdeDia], que
/// fração foi lembrada (nota "difícil", "bom" ou "fácil"). Null com menos de
/// [minimo] revisões — número que ainda não quer dizer nada.
double? retencaoReal(Iterable<EntradaHistorico> historico, {required int desdeDia, int minimo = 5}) {
  var total = 0, lembradas = 0;
  for (final e in historico) {
    if (e.primeira || e.dia < desdeDia) continue;
    total++;
    if (e.nota >= 2) lembradas++;
  }
  return total < minimo ? null : lembradas / total;
}

/// Quantas revisões foram feitas em cada um dos últimos [dias] dias (o último
/// elemento é hoje).
List<int> revisoesPorDia(Iterable<EntradaHistorico> historico, int hoje, {int dias = 14}) {
  final r = List<int>.filled(dias, 0);
  for (final e in historico) {
    final i = e.dia - (hoje - dias + 1);
    if (i >= 0 && i < dias) r[i]++;
  }
  return r;
}

/// Quando o cartão volta, em português ("vence hoje", "amanhã", "em 3 sem"…).
String descreverVencimento(CartaoSrs c, int hoje) {
  if (c.suspenso) return 'suspenso';
  if (c.enterradoAte > hoje) return 'enterrado até amanhã';
  final d = c.proximoDia - hoje;
  if (d < 0) return 'atrasado ${-d} ${-d == 1 ? 'dia' : 'dias'}';
  if (d == 0) return 'vence hoje';
  if (d == 1) return 'amanhã';
  return 'em ${rotuloIntervalo(d)}';
}
