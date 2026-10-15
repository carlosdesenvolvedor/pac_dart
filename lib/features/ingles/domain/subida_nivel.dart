import 'dart:convert';

import 'nivel_resposta.dart';
import 'srs.dart';

/// A escada de níveis do cartão (Fácil → Médio → Avançado) e quando SUGERIR trocar de degrau.
/// Só sugere: quem decide é a pessoa ("Só virar" fica fora da escada, é autoavaliação).
///
/// Subir: [acertosParaSubir] acertos seguidos no degrau. Descer: [errosParaDescer] erros nas
/// últimas [janelaParaDescer] respostas do degrau. "Difícil" não conta para nada (nem quebra a série).
class SerieDeNivel {
  static const acertosParaSubir = 10;
  static const janelaParaDescer = 8;
  static const errosParaDescer = 4;

  /// Quantas respostas por degrau são lembradas.
  static const guardadas = 10;

  /// Por degrau: as últimas respostas (true = acertou, false = errou), da mais antiga à mais nova.
  final Map<NivelResposta, List<bool>> porNivel;

  const SerieDeNivel([this.porNivel = const {}]);

  static const escada = [NivelResposta.facil, NivelResposta.medio, NivelResposta.avancado];

  /// A 1ª nota de um cartão no degrau [nivel]. "Só virar" e "Difícil" não entram.
  SerieDeNivel registrar(NivelResposta nivel, Rating nota) {
    if (!escada.contains(nivel) || nota == Rating.hard) return this;
    final acertou = nota == Rating.good || nota == Rating.easy;
    final lista = [...?porNivel[nivel], acertou];
    final cortada = lista.length > guardadas ? lista.sublist(lista.length - guardadas) : lista;
    return SerieDeNivel({...porNivel, nivel: cortada});
  }

  /// Recomeça a contagem do degrau (a pessoa trocou de nível ou disse "agora não").
  SerieDeNivel limpar(NivelResposta nivel) => SerieDeNivel({...porNivel}..remove(nivel));

  /// O degrau que vale sugerir a partir de [atual], ou null.
  NivelResposta? sugestao(NivelResposta atual) {
    final i = escada.indexOf(atual);
    final l = porNivel[atual];
    if (i < 0 || l == null) return null;
    if (i < escada.length - 1 && l.length >= acertosParaSubir && l.sublist(l.length - acertosParaSubir).every((x) => x)) {
      return escada[i + 1];
    }
    if (i > 0 && l.length >= janelaParaDescer) {
      final erros = l.sublist(l.length - janelaParaDescer).where((x) => !x).length;
      if (erros >= errosParaDescer) return escada[i - 1];
    }
    return null;
  }

  String codificar() => jsonEncode({for (final e in porNivel.entries) e.key.id: e.value.map((x) => x ? 1 : 0).toList()});

  /// Nunca lança: texto estragado volta a uma série vazia.
  static SerieDeNivel decodificar(String? texto) {
    if (texto == null) return const SerieDeNivel();
    try {
      final j = jsonDecode(texto);
      if (j is! Map) return const SerieDeNivel();
      final r = <NivelResposta, List<bool>>{};
      for (final e in j.entries) {
        final n = NivelResposta.porId('${e.key}');
        if (n == null || !escada.contains(n) || e.value is! List) continue;
        final l = [for (final x in e.value as List) if (x == 0 || x == 1) x == 1];
        if (l.isNotEmpty) r[n] = l.length > guardadas ? l.sublist(l.length - guardadas) : l;
      }
      return SerieDeNivel(r);
    } catch (_) {
      return const SerieDeNivel();
    }
  }
}
