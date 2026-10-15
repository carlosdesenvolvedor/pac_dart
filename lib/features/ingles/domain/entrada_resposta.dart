import 'package:shared_preferences/shared_preferences.dart';

import 'revisao.dart';
import 'roteiro.dart';

/// Como a pessoa RESPONDE cada frase da lição de inglês (Fase 7): digitando, falando ou montando a frase
/// com blocos de palavras (o estilo do Duolingo, o mesmo "Fácil" dos cartões de revisão).
enum EntradaResposta {
  digitar('digitar', '⌨️', 'Digitar'),
  falar('falar', '🎤', 'Falar'),
  montar('montar', '🧩', 'Montar');

  const EntradaResposta(this.id, this.emoji, this.rotulo);
  final String id, emoji, rotulo;

  /// O modo de quem nunca escolheu: digitar (o diferencial do app).
  static const padrao = EntradaResposta.digitar;

  /// Pelo id guardado; id desconhecido, vazio ou de outro tipo ⇒ null (a tela cai no [padrao]).
  static EntradaResposta? porId(Object? id) {
    if (id is! String) return null;
    for (final e in values) {
      if (e.id == id) return e;
    }
    return null;
  }
}

/// O teclado virtual do celular só abre em Digitar. Falar e Montar não o pedem (no computador não há teclado
/// virtual: o foco segue valendo para Enter, Esc e Tab).
bool abreTeclado(EntradaResposta entrada, {required bool celular}) => entrada == EntradaResposta.digitar || !celular;

/// A nota do passo conforme COMO ele foi respondido. Montar é RECONHECER as palavras, digitar de memória é LEMBRAR:
/// por isso, na PROVA final (D5), uma montagem certa conta só "tropeçou" (meio ponto) — a mesma ideia do 👁
/// (frase à vista). Errar continua errando, e a nota nunca melhora. Digitar e falar valem inteiro.
ResultadoRevisao notaDaEntrada(ResultadoRevisao r, {required EntradaResposta entrada, required Degrau degrau}) {
  if (entrada == EntradaResposta.montar && degrau == Degrau.prova && r == ResultadoRevisao.acertou) {
    return ResultadoRevisao.hesitou;
  }
  return r;
}

/// A última escolha da pessoa, neste aparelho (`SharedPreferences`). Nunca lança: sem armazenamento ou com dado
/// estragado vale o [EntradaResposta.padrao].
class PrefsEntrada {
  static const chave = 'en_entrada';

  /// A escolha guardada em [p] (quem já tem as preferências abertas lê direto, sem esperar).
  static EntradaResposta ler(SharedPreferences p) {
    try {
      return EntradaResposta.porId(p.get(chave)) ?? EntradaResposta.padrao;
    } catch (_) {
      return EntradaResposta.padrao;
    }
  }

  static Future<EntradaResposta> carregar() async {
    try {
      return ler(await SharedPreferences.getInstance());
    } catch (_) {
      return EntradaResposta.padrao;
    }
  }

  static Future<void> salvar(EntradaResposta e) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(chave, e.id);
    } catch (_) {}
  }
}
