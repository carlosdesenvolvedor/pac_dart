// 🔁 "Revisão até aqui" do PAC·ENGLISH (estilo Duolingo): uma sessão CURTA — 10 exercícios — com frases
// sorteadas de TODAS as lições já concluídas, cada uma pedida de um jeito: ✍️ escrever em inglês, 🧩 montar
// com blocos, 👂 escutar e escrever o que ouviu e 🎤 falar. "Não posso escutar / falar agora" tira o tipo da
// sessão (e das próximas, por uma hora). Dart puro: a tela só mostra e responde.
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../curso/domain/curriculo.dart';
import 'avaliacao.dart' show palavrasDe;

/// Quantos exercícios tem a revisão (o "tipo Duolingo": poucos e variados).
const exerciciosDaRevisaoMista = 10;

/// Os jeitos de pedir uma frase na revisão.
enum TipoExercicio {
  escrever('escrever', '✍️', 'Escreva em inglês'),
  blocos('blocos', '🧩', 'Monte a frase em inglês'),
  escutar('escutar', '👂', 'Escute e escreva o que ouviu'),
  falar('falar', '🎤', 'Fale a frase em inglês');

  const TipoExercicio(this.id, this.emoji, this.titulo);
  final String id, emoji, titulo;

  /// O peso de cada tipo na sessão completa (3 + 3 + 2 + 2 = 10).
  int get peso => switch (this) {
        TipoExercicio.escrever || TipoExercicio.blocos => 3,
        TipoExercicio.escutar || TipoExercicio.falar => 2,
      };
}

/// Um exercício da revisão: a frase, de que lição veio e como ela é pedida.
class ExercicioMisto {
  final Trecho trecho;
  final Licao licao;
  final TipoExercicio tipo;

  /// Voltou no fim porque saiu errada (não vale nota de novo).
  final bool repeticao;

  const ExercicioMisto(this.trecho, this.licao, this.tipo, {this.repeticao = false});

  ExercicioMisto comTipo(TipoExercicio t) => ExercicioMisto(trecho, licao, t, repeticao: repeticao);

  @override
  String toString() => '${tipo.id}(${trecho.cod}${repeticao ? ' · volta' : ''})';
}

/// A frase serve para [tipo]? Blocos pedem 3+ palavras (com 1–2 não há o que montar); falar e escutar, frases
/// que cabem numa fala só (até 14 e 18 palavras). Escrever serve para tudo.
bool serveParaTipo(Trecho f, TipoExercicio tipo) {
  final n = palavrasDe(f.cod).length;
  return switch (tipo) {
    TipoExercicio.escrever => n > 0,
    TipoExercicio.blocos => n >= 3,
    TipoExercicio.falar => n > 0 && n <= 14,
    TipoExercicio.escutar => n > 0 && n <= 18,
  };
}

/// Quantos exercícios de cada tipo, entre os [disponiveis], para [total] (maiores restos; empate na ordem do
/// enum). Escrever e blocos estão sempre disponíveis.
Map<TipoExercicio, int> cotasDosTipos(Set<TipoExercicio> disponiveis, int total) {
  final tipos = [for (final t in TipoExercicio.values) if (disponiveis.contains(t)) t];
  if (tipos.isEmpty || total <= 0) return {};
  final soma = tipos.fold<int>(0, (a, t) => a + t.peso);
  final cotas = {for (final t in tipos) t: total * t.peso ~/ soma};
  var falta = total - cotas.values.fold<int>(0, (a, b) => a + b);
  final porResto = [...tipos]..sort((a, b) => ((total * b.peso) % soma).compareTo((total * a.peso) % soma));
  for (var i = 0; falta > 0; i++, falta--) {
    final t = porResto[i % porResto.length];
    cotas[t] = cotas[t]! + 1;
  }
  return cotas;
}

/// Monta a revisão: até [total] frases das lições [estudadas] (na ordem do curso), espalhadas — no máximo uma
/// por lição até todas as lições terem dado uma —, sorteadas com [peso] (maior = sai mais; o app dá mais peso
/// às frases que a pessoa tem menos chance de lembrar) e com um empurrão para as lições mais recentes. Cada
/// frase ganha um tipo, nas cotas de [cotasDosTipos], sem o mesmo tipo três vezes seguidas.
List<ExercicioMisto> montarRevisaoMista(
  List<Licao> estudadas, {
  double Function(Trecho f)? peso,
  bool podeEscutar = true,
  bool podeFalar = true,
  int total = exerciciosDaRevisaoMista,
  Random? rnd,
}) {
  final r = rnd ?? Random();
  final licoes = [for (final l in estudadas) if (l.trechos.any((f) => palavrasDe(f.cod).isNotEmpty)) l];
  if (licoes.isEmpty || total <= 0) return const [];

  // sorteio ponderado sem reposição (chave = u^(1/w)): dentro de cada lição, as frases na ordem da chave
  final grupos = <({Licao licao, List<(double, Trecho)> frases})>[];
  final vistas = <String>{};
  for (var i = 0; i < licoes.length; i++) {
    final recencia = 1 + .6 * (licoes.length == 1 ? 1 : i / (licoes.length - 1));
    final frases = <(double, Trecho)>[];
    for (final f in licoes[i].trechos) {
      if (palavrasDe(f.cod).isEmpty || !vistas.add(f.cod.trim())) continue;
      final w = max(.05, (peso?.call(f) ?? 1) * recencia);
      frases.add((pow(max(1e-12, r.nextDouble()), 1 / w).toDouble(), f));
    }
    if (frases.isEmpty) continue;
    frases.sort((a, b) => b.$1.compareTo(a.$1));
    grupos.add((licao: licoes[i], frases: frases));
  }
  // rodada a rodada: a melhor frase de cada lição; entre as lições, a de chave maior primeiro
  final escolhidas = <(Trecho, Licao)>[];
  for (var rodada = 0; escolhidas.length < total; rodada++) {
    final daRodada = [
      for (final g in grupos)
        if (rodada < g.frases.length) (g.frases[rodada].$1, g.frases[rodada].$2, g.licao),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    if (daRodada.isEmpty) break;
    for (final (_, f, l) in daRodada) {
      if (escolhidas.length >= total) break;
      escolhidas.add((f, l));
    }
  }
  escolhidas.shuffle(r);

  final disponiveis = {
    TipoExercicio.escrever,
    TipoExercicio.blocos,
    if (podeEscutar) TipoExercicio.escutar,
    if (podeFalar) TipoExercicio.falar,
  };
  final cotas = cotasDosTipos(disponiveis, escolhidas.length);
  final tipos = [for (final e in cotas.entries) for (var i = 0; i < e.value; i++) e.key]..shuffle(r);

  // cada frase pega o 1º tipo da lista que serve para ela (escrever serve para todas)
  final exercicios = <ExercicioMisto>[];
  for (final (f, l) in escolhidas) {
    final i = tipos.indexWhere((t) => serveParaTipo(f, t));
    final tipo = i < 0 ? TipoExercicio.escrever : tipos.removeAt(i);
    exercicios.add(ExercicioMisto(f, l, tipo));
  }
  return semTrincas(exercicios);
}

/// Reordena para não ter o mesmo tipo três vezes seguidas (quando dá): troca o 3º da trinca com o próximo de
/// outro tipo. Não muda quais exercícios há.
List<ExercicioMisto> semTrincas(List<ExercicioMisto> lista) {
  final l = [...lista];
  for (var i = 2; i < l.length; i++) {
    if (l[i].tipo != l[i - 1].tipo || l[i].tipo != l[i - 2].tipo) continue;
    final j = l.indexWhere((e) => e.tipo != l[i].tipo, i + 1);
    if (j < 0) break;
    final tmp = l[i];
    l[i] = l[j];
    l[j] = tmp;
  }
  return l;
}

/// "Não posso escutar / falar agora": a partir de [desde], cada exercício do tipo [tirar] vira outro — alterna
/// escrever e blocos (o que servir para a frase), para a sessão continuar variada. Os outros ficam como estão.
List<ExercicioMisto> semOTipo(List<ExercicioMisto> lista, TipoExercicio tirar, {int desde = 0}) {
  var alterna = lista.where((e) => e.tipo == TipoExercicio.blocos).length <=
      lista.where((e) => e.tipo == TipoExercicio.escrever).length;
  return [
    for (var i = 0; i < lista.length; i++)
      if (i < desde || lista[i].tipo != tirar)
        lista[i]
      else
        lista[i].comTipo(() {
          final quer = alterna ? TipoExercicio.blocos : TipoExercicio.escrever;
          alterna = !alterna;
          return serveParaTipo(lista[i].trecho, quer) ? quer : TipoExercicio.escrever;
        }()),
  ];
}

/// O tipo da volta de uma frase que saiu errada: escrever (de memória), ou blocos se ela foi errada escrevendo
/// — do mesmo jeito de novo cansa; montar deixa reconhecer a frase certa.
TipoExercicio tipoDaVolta(ExercicioMisto e) =>
    e.tipo == TipoExercicio.escrever && serveParaTipo(e.trecho, TipoExercicio.blocos)
        ? TipoExercicio.blocos
        : TipoExercicio.escrever;

/// "Não posso escutar / falar agora" vale por uma hora (como no Duolingo), neste aparelho.
class PrefsRevisaoMista {
  static const chaveSemAudio = 'en_rev_sem_audio_ate';
  static const chaveSemFala = 'en_rev_sem_fala_ate';
  static const pausa = Duration(hours: 1);

  /// Até quando escutar ([semAudio]) e falar ([semFala]) estão desligados (null = ligados).
  static Future<({DateTime? semAudio, DateTime? semFala})> carregar({DateTime? agora}) async {
    try {
      final p = await SharedPreferences.getInstance();
      final ag = agora ?? DateTime.now();
      DateTime? ate(String k) {
        final v = p.getInt(k);
        if (v == null) return null;
        final d = DateTime.fromMillisecondsSinceEpoch(v);
        return d.isAfter(ag) ? d : null;
      }

      return (semAudio: ate(chaveSemAudio), semFala: ate(chaveSemFala));
    } catch (_) {
      return (semAudio: null, semFala: null);
    }
  }

  /// Desliga [tipo] (escutar ou falar) pela [pausa].
  static Future<void> desligar(TipoExercicio tipo, {DateTime? agora}) async {
    final k = switch (tipo) {
      TipoExercicio.escutar => chaveSemAudio,
      TipoExercicio.falar => chaveSemFala,
      _ => null,
    };
    if (k == null) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(k, (agora ?? DateTime.now()).add(pausa).millisecondsSinceEpoch);
    } catch (_) {}
  }
}
