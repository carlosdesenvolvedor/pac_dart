// "📝 Virar lição" das palavras teimosas: uma lição de texto (das que a pessoa cola) montada com frases DO
// CURSO que têm essas palavras — de preferência de lições já concluídas, curtas, e nunca a frase em que o
// erro aconteceu (a pessoa reencontra a palavra num contexto NOVO). Dart puro.
//
// Custo conhecido: a revisão espaçada (RevisaoCubit) reconhece as frases do curso pelo id e as de texto
// pelo `cod`, então cada frase desta lição vira um cartão de frase a mais (até 8) mesmo que a frase do
// curso já tenha o seu. Aceito: são poucas e são justamente as frases das palavras que a pessoa erra.
import '../../curso/domain/curriculo.dart';
import 'avaliacao.dart' show palavrasDe;
import 'dicionario.dart';
import 'leitura.dart' show alvoNaTraducao;
import 'texto_salvo.dart';

/// Uma frase candidata: o trecho, as chaves-alvo que ela contém (e como cada uma está escrita nela).
class _Candidata {
  final Trecho t;
  final bool concluida;
  final int palavras;
  final Map<String, String> alvos;
  _Candidata(this.t, this.concluida, this.palavras, this.alvos);
}

/// Monta o texto ("🔥 Teimosas · dd/mm") com até [max] frases que cobrem [chaves]: primeiro uma frase por
/// palavra (a que cobre mais palavras ainda sem frase ganha; depois a de lição concluída; depois a mais
/// curta), depois uma 2ª passada até [max]. Frases: não próprias, de 3 a 12 palavras, até 70 letras, com
/// tradução e fora de [evitar] (os `cod` onde o erro aconteceu). Palavra sem frase no curso usa
/// [exemploExtra] (frase e tradução; ex.: o exemplo do índice), se houver. Null com menos de 2 frases.
///
/// [chaveDe]: a chave de uma palavra da frase (para casar "works" com "work"); sem ela, só a forma exata.
/// [traducao]: a tradução curta de uma chave (para marcar o `alvoPt`).
TextoSalvo? textoDePalavras(
  List<String> chaves,
  List<Trilha> trilhas, {
  Set<String> concluidas = const {},
  String? Function(String chave)? traducao,
  String? Function(String palavra)? chaveDe,
  ({String frase, String traducao})? Function(String chave)? exemploExtra,
  Set<String> evitar = const {},
  int max = 8,
  DateTime? agora,
}) {
  final alvos = <String>[];
  for (final c in chaves) {
    final k = Dicionario.normalizar(c);
    if (k.isNotEmpty && !alvos.contains(k)) alvos.add(k);
  }
  if (alvos.isEmpty) return null;
  final alvoSet = alvos.toSet();
  final evitarNorm = {for (final e in evitar) e.trim().toLowerCase()};

  final candidatas = <_Candidata>[];
  final vistasCod = <String>{};
  for (final tr in trilhas) {
    if (tr.propria) continue;
    for (final l in tr.licoes) {
      final concl = concluidas.contains(l.id);
      for (final t in l.trechos) {
        final cod = t.cod.trim();
        if (cod.isEmpty || cod.length > 70 || cod.contains('\n') || t.dicaPlana.trim().isEmpty) continue;
        final norm = cod.toLowerCase();
        if (evitarNorm.contains(norm)) continue;
        final ps = palavrasDe(cod);
        if (ps.length < 3 || ps.length > 12) continue;
        Map<String, String>? achadas;
        for (final p in ps) {
          final w = cod.substring(p.ini, p.fim);
          var k = Dicionario.normalizar(w);
          if (!alvoSet.contains(k) && chaveDe != null) k = Dicionario.normalizar(chaveDe(w) ?? '');
          if (alvoSet.contains(k)) (achadas ??= {}).putIfAbsent(k, () => w);
        }
        if (achadas == null) continue;
        if (!vistasCod.add(norm)) {
          // a mesma frase em duas lições: fica a versão de lição concluída
          if (concl) {
            final i = candidatas.indexWhere((c) => c.t.cod.trim().toLowerCase() == norm);
            if (i >= 0 && !candidatas[i].concluida) candidatas[i] = _Candidata(t, true, ps.length, achadas);
          }
          continue;
        }
        candidatas.add(_Candidata(t, concl, ps.length, achadas));
      }
    }
  }

  int preferencia(_Candidata a, _Candidata b) {
    if (a.concluida != b.concluida) return a.concluida ? -1 : 1;
    final n = a.palavras.compareTo(b.palavras);
    return n != 0 ? n : a.t.cod.length.compareTo(b.t.cod.length);
  }

  final escolhidas = <_Candidata>[];
  final cobertas = <String>{};
  // 1ª passada: cobertura gulosa (uma frase com 2 palavras-alvo ainda sem frase ganha)
  while (escolhidas.length < max) {
    _Candidata? melhor;
    var ganho = 0;
    for (final c in candidatas) {
      if (escolhidas.contains(c)) continue;
      final g = c.alvos.keys.where((k) => !cobertas.contains(k)).length;
      if (g == 0) continue;
      if (g > ganho || (g == ganho && melhor != null && preferencia(c, melhor) < 0)) {
        melhor = c;
        ganho = g;
      }
    }
    if (melhor == null) break;
    escolhidas.add(melhor);
    cobertas.addAll(melhor.alvos.keys);
  }
  // 2ª passada: mais uma frase por palavra, revezando, até completar
  final porPalavra = {
    for (final k in alvos) k: ([for (final c in candidatas) if (c.alvos.containsKey(k)) c]..sort(preferencia)),
  };
  var mudou = true;
  while (escolhidas.length < max && mudou) {
    mudou = false;
    for (final k in alvos) {
      if (escolhidas.length >= max) break;
      final prox = porPalavra[k]!.where((c) => !escolhidas.contains(c)).firstOrNull;
      if (prox == null) continue;
      escolhidas.add(prox);
      mudou = true;
    }
  }

  final frases = <FraseDoTexto>[];
  final codsUsados = <String>{};
  for (final c in escolhidas) {
    if (!codsUsados.add(c.t.cod.trim().toLowerCase())) continue;
    // a palavra-alvo da frase: a 1ª das teimosas que ela tem (na ordem pedida)
    final k = alvos.firstWhere(c.alvos.containsKey);
    final pt = c.t.dicaPlana.trim();
    frases.add(FraseDoTexto(c.t.cod.trim(), pt, alvo: c.alvos[k]!, alvoPt: alvoNaTraducao(pt, traducao?.call(k) ?? '')));
  }
  // palavras sem frase do curso: o exemplo de reserva
  if (exemploExtra != null) {
    for (final k in alvos) {
      if (frases.length >= max) break;
      if (cobertas.contains(k)) continue;
      final ex = exemploExtra(k);
      if (ex == null || ex.frase.trim().isEmpty || ex.traducao.trim().isEmpty) continue;
      final norm = ex.frase.trim().toLowerCase();
      if (evitarNorm.contains(norm) || !codsUsados.add(norm)) continue;
      String alvo = '';
      for (final p in palavrasDe(ex.frase)) {
        final w = ex.frase.substring(p.ini, p.fim);
        if (Dicionario.normalizar(w) == k || (chaveDe != null && Dicionario.normalizar(chaveDe(w) ?? '') == k)) {
          alvo = w;
          break;
        }
      }
      frases.add(FraseDoTexto(ex.frase.trim(), ex.traducao.trim(),
          alvo: alvo, alvoPt: alvo.isEmpty ? '' : alvoNaTraducao(ex.traducao, traducao?.call(k) ?? '')));
    }
  }
  if (frases.length < 2) return null;
  final quando = agora ?? DateTime.now();
  String dois(int n) => n.toString().padLeft(2, '0');
  return TextoSalvo(
    id: TextoSalvo.novoId(quando),
    titulo: '🔥 Teimosas · ${dois(quando.day)}/${dois(quando.month)}',
    criadoEm: quando,
    frases: frases,
  );
}
