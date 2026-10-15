import 'package:equatable/equatable.dart';

import 'avaliacao.dart';
import 'comparar_resposta.dart' show normalizarPalavra;
import 'nivel_resposta.dart';

/// O resultado de "Conferir" no modo Montar da lição (Fase 7): a frase montada com blocos contra a frase certa.
class ConferenciaMontagem extends Equatable {
  /// A frase está montada certa: todas as palavras, na ordem, e nenhum bloco de enfeite.
  final bool certa;

  /// Um valor por bloco escolhido (na ordem em que estão na frase montada): o bloco está no lugar certo.
  final List<bool> escolhidasCertas;

  /// Um erro (1) por palavra da frase que NÃO foi montada no lugar: a chave é onde a palavra começa no texto
  /// (a mesma chave de `errosPorPosicao`/`errosDeFala` que [avaliarDigitacao] lê).
  final Map<int, int> erros;

  const ConferenciaMontagem({required this.certa, required this.escolhidasCertas, required this.erros});

  /// Nada montado: não há o que conferir (não conta erro).
  static const nenhuma = ConferenciaMontagem(certa: false, escolhidasCertas: [], erros: {});

  @override
  List<Object?> get props => [certa, escolhidasCertas, erros];
}

/// Confere [escolhidos] (os blocos na ordem em que a pessoa os pôs) com [frase]. Montar é reconhecer, mas a ordem
/// é exata: as palavras certas em outra ordem NÃO valem. O que casa é a maior sequência em comum (uma palavra
/// de enfeite no meio não estraga as outras); cada palavra da frase que ficou de fora soma 1 erro.
ConferenciaMontagem conferirMontagem(String frase, List<Bloco> escolhidos) {
  if (escolhidos.isEmpty) return ConferenciaMontagem.nenhuma;
  final esperadas = <({String norm, int ini})>[];
  var pos = 0;
  for (final p in partirFrase(frase)) {
    if (p.palavra) esperadas.add((norm: normalizarPalavra(p.texto), ini: pos));
    pos += p.texto.length;
  }
  final dadas = [for (final b in escolhidos) normalizarPalavra(b.texto)];
  final n = esperadas.length, m = dadas.length;

  // maior subsequência comum (igualdade exata das palavras já normalizadas)
  final t = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      t[i][j] = esperadas[i].norm == dadas[j]
          ? t[i + 1][j + 1] + 1
          : (t[i + 1][j] >= t[i][j + 1] ? t[i + 1][j] : t[i][j + 1]);
    }
  }
  final esperadaOk = List<bool>.filled(n, false), dadaOk = List<bool>.filled(m, false);
  var i = 0, j = 0;
  while (i < n && j < m) {
    if (esperadas[i].norm == dadas[j]) {
      esperadaOk[i] = true;
      dadaOk[j] = true;
      i++;
      j++;
    } else if (t[i + 1][j] >= t[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }

  // cada palavra que faltou vira 1 erro na posição em que a palavra começa (hífen: as duas metades são uma palavra só)
  final ps = palavrasDe(frase);
  final erros = <int, int>{};
  for (var w = 0; w < n; w++) {
    if (esperadaOk[w]) continue;
    final ini = esperadas[w].ini;
    var chave = ini;
    for (final p in ps) {
      if (ini >= p.ini && ini < p.fim) {
        chave = p.ini;
        break;
      }
    }
    erros[chave] = 1;
  }
  return ConferenciaMontagem(
    certa: n > 0 && m == n && esperadaOk.every((x) => x),
    escolhidasCertas: dadaOk,
    erros: erros,
  );
}
