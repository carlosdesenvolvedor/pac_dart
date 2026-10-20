// Regras puras do mapa "estilo Duolingo" do PAC·ENGLISH: estrelas da nota, até onde a pessoa chegou
// (a fronteira), o estado visual de cada nó, o desenho em seno do caminho e o baú do fim da unidade.
// Nada aqui bloqueia: o "trancado" é só aparência (o nó continua abrindo a folha da lição).
import 'dart:math' as math;

import 'curriculo.dart';

/// Uma posição no curso: (trilha, lição).
typedef PosicaoMapa = (int, int);

/// Estrelas de uma nota de 0 a 10 (DESIGN.md §148): 9–10 = 3, 7–8 = 2, 5–6 = 1, o resto (ou sem nota) = 0.
int estrelasDaNota(int? nota) {
  if (nota == null) return 0;
  if (nota >= 9) return 3;
  if (nota >= 7) return 2;
  if (nota >= 5) return 1;
  return 0;
}

/// A chave de progresso da lição [l] da trilha [t] (a mesma regra de `CursoState.chave`: o id da lição
/// quando tem, senão "t:l").
String chaveDaLicao(List<Trilha> trilhas, int t, int l) {
  if (t >= 0 && t < trilhas.length && l >= 0 && l < trilhas[t].licoes.length) {
    final id = trilhas[t].licoes[l].id;
    if (id.isNotEmpty) return id;
  }
  return '$t:$l';
}

/// A primeira lição ainda não feita, na ordem do curso, pulando as trilhas próprias (textos colados).
/// Trilhas passadas no teste de nivelamento já estão em [concluidas], então a fronteira passa por cima
/// delas. Null = o curso inteiro está feito.
PosicaoMapa? fronteira(List<Trilha> trilhas, Set<String> concluidas) {
  for (var t = 0; t < trilhas.length; t++) {
    if (trilhas[t].propria) continue;
    for (var l = 0; l < trilhas[t].licoes.length; l++) {
      if (!concluidas.contains(chaveDaLicao(trilhas, t, l))) return (t, l);
    }
  }
  return null;
}

/// [a] vem depois de [b] na ordem do curso?
bool depoisDe(PosicaoMapa a, PosicaoMapa b) => a.$1 > b.$1 || (a.$1 == b.$1 && a.$2 > b.$2);

/// Até onde o mapa fica "aberto": a fronteira, ou a lição atual quando a pessoa pulou para a frente
/// (pelo menu ou pela busca). Null = nada parece trancado.
PosicaoMapa? alcanceDoMapa(List<Trilha> trilhas, Set<String> concluidas, PosicaoMapa atual) {
  final f = fronteira(trilhas, concluidas);
  if (f == null) return null;
  final (t, _) = atual;
  if (t >= 0 && t < trilhas.length && !trilhas[t].propria && depoisDe(atual, f)) return atual;
  return f;
}

/// Os quatro jeitos de um nó aparecer.
enum EstadoNo { feita, atual, disponivel, trancada }

/// O estado visual da lição em [pos]: feita > atual > trancada (depois do [alcance], fora das trilhas
/// próprias) > disponível.
EstadoNo estadoDoNo({
  required bool feita,
  required bool atual,
  required PosicaoMapa pos,
  required PosicaoMapa? alcance,
  bool propria = false,
}) {
  if (feita) return EstadoNo.feita;
  if (atual) return EstadoNo.atual;
  if (!propria && alcance != null && depoisDe(pos, alcance)) return EstadoNo.trancada;
  return EstadoNo.disponivel;
}

/// O desenho do caminho: 8 passos de um seno (centro, meio, borda, meio, centro, meio, outra borda, meio).
const offsetsSeno = [0.0, .5, 1.0, .5, 0.0, -.5, -1.0, -.5];

/// O deslocamento (−1…1, vezes a amplitude) do item número [indiceGlobal] do caminho. O índice é contínuo
/// entre as unidades, então a curva segue de uma unidade para a outra.
double offsetSenoidal(int indiceGlobal) => offsetsSeno[indiceGlobal % offsetsSeno.length];

/// Largura a partir da qual o rótulo vai ao lado do nó (abaixo disso, vai embaixo).
const larguraRotuloAoLado = 520.0;

/// Quanto o caminho balança para cada lado numa faixa de largura [w]: estreito = 30% (até 90 px), largo =
/// 24% (até 120 px). Num celular de 360 (faixa de ~304) dá 90 px — o caminho serpenteia de verdade.
double amplitudeDuolingo(double w) {
  if (w <= 0) return 0;
  final a = w < larguraRotuloAoLado ? math.min(w * .30, 90.0) : math.min(w * .24, 120.0);
  // o nó (64 px) nunca sai da faixa
  return math.max(0, math.min(a, w / 2 - 32));
}

/// Primeiro índice global de cada trilha do curso no seno (as próprias não entram e recebem −1). Cada
/// unidade ocupa as suas lições + 1 vaga no fim (o baú), tenha ou não baú, para a curva não pular quando
/// o índice de palavras fica pronto.
List<int> iniciosDoSeno(List<Trilha> trilhas) {
  final r = <int>[];
  var i = 0;
  for (final t in trilhas) {
    if (t.propria) {
      r.add(-1);
      continue;
    }
    r.add(i);
    i += t.licoes.length + 1;
  }
  return r;
}

/// O número da unidade (1, 2, …) da trilha [t], contando só as do curso; 0 = trilha própria.
int numeroDaUnidade(List<Trilha> trilhas, int t) {
  if (t < 0 || t >= trilhas.length || trilhas[t].propria) return 0;
  var n = 0;
  for (var k = 0; k <= t; k++) {
    if (!trilhas[k].propria) n++;
  }
  return n;
}

// ---------------------------------------------------------------------------
// Baú do fim da unidade
// ---------------------------------------------------------------------------

/// Quantas palavras novas a unidade precisa para ganhar baú.
const minimoPalavrasDoBau = 4;

enum EstadoBau { trancado, pronto, aberto }

/// A conquista guardada em `projetosFeitos` quando o baú da trilha é aberto e treinado.
String chaveDoBau(String baralhoId) => 'bau:$baralhoId';

/// A trilha ganha baú? Só as do curso, com [nPalavras] novas suficientes.
bool temBau(Trilha trilha, int nPalavras) => !trilha.propria && nPalavras >= minimoPalavrasDoBau;

/// O baú já foi aberto (e treinado)?
bool bauAberto(Set<String> projetosFeitos, String baralhoId) => projetosFeitos.contains(chaveDoBau(baralhoId));

/// Pronto para abrir: todas as lições feitas e ainda não aberto.
bool bauPronto({required bool completa, required Set<String> projetosFeitos, required String baralhoId}) =>
    completa && !bauAberto(projetosFeitos, baralhoId);

EstadoBau estadoDoBau({required bool completa, required Set<String> projetosFeitos, required String baralhoId}) {
  if (bauAberto(projetosFeitos, baralhoId)) return EstadoBau.aberto;
  return completa ? EstadoBau.pronto : EstadoBau.trancado;
}

/// Só UM baú pronto balança no mapa (os outros ficam parados, só com o brilho): o mais perto de onde a
/// pessoa está — o último pronto até a [trilhaAtual] ou, se nenhum, o primeiro depois dela. Null = nenhum.
int? bauQueBalanca(Iterable<int> trilhasComBauPronto, int trilhaAtual) {
  int? antes, depois;
  for (final t in trilhasComBauPronto) {
    if (t <= trilhaAtual) {
      if (antes == null || t > antes) antes = t;
    } else if (depois == null || t < depois) {
      depois = t;
    }
  }
  return antes ?? depois;
}

/// O personagem principal da trilha: quem mais fala nas frases (sem contar "voce" e frases sem ninguém).
/// Empate = quem apareceu primeiro. Null = ninguém fala.
String? personagemDaTrilha(Trilha trilha) {
  final conta = <String, int>{};
  final ordem = <String>[];
  for (final l in trilha.licoes) {
    for (final f in l.trechos) {
      final q = f.quem.trim();
      if (q.isEmpty || q == 'voce') continue;
      if (!conta.containsKey(q)) ordem.add(q);
      conta[q] = (conta[q] ?? 0) + 1;
    }
  }
  String? melhor;
  for (final q in ordem) {
    if (melhor == null || conta[q]! > conta[melhor]!) melhor = q;
  }
  return melhor;
}
