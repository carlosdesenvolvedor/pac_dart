import 'package:equatable/equatable.dart';
import 'package:fsrs/fsrs.dart';

import 'revisao.dart';

export 'package:fsrs/fsrs.dart' show Rating;

/// O "Anki" do curso de inglês: cada frase é um cartão com a memória medida
/// pelo FSRS (o agendador do Anki moderno) — estabilidade, dificuldade e o dia
/// da próxima revisão. Tudo em DIAS inteiros do calendário local (o mesmo
/// `Revisao.dia` de sempre): o pacote conta dias pela diferença truncada entre
/// datas-hora, então ele só recebe meia-noite UTC de cada dia.

/// O estado de memória de uma frase. Sempre "em revisão": o motor da lição já
/// faz as repetições do mesmo dia, então não há etapas de aprendizado.
class CartaoSrs extends Equatable {
  /// Dias até a chance de lembrar cair a 90% (cresce a cada acerto).
  final double estabilidade;

  /// 1 (fácil) a 10 (difícil) — a frase em si, para esta pessoa.
  final double dificuldade;

  /// Dia (desde 1970, fuso local) da última revisão e da próxima.
  final int ultimoDia;
  final int proximoDia;

  /// Quantas vezes foi revisada e quantas vezes errou depois de aprendida.
  final int revisoes;
  final int lapsos;

  /// "Suspenso" (como no Anki): fora das revisões até a pessoa reativar.
  final bool suspenso;

  /// "Enterrado": escondido até este dia (0 = não está). Some das revisões de
  /// hoje sem mexer na agenda; amanhã volta.
  final int enterradoAte;

  const CartaoSrs({
    required this.estabilidade,
    required this.dificuldade,
    required this.ultimoDia,
    required this.proximoDia,
    this.revisoes = 1,
    this.lapsos = 0,
    this.suspenso = false,
    this.enterradoAte = 0,
  });

  /// Vence hoje e aparece na revisão (suspenso e enterrado não aparecem).
  bool devidaEm(int hoje) => !suspenso && enterradoAte <= hoje && proximoDia <= hoje;

  CartaoSrs comSuspenso(bool valor) => CartaoSrs(
        estabilidade: estabilidade,
        dificuldade: dificuldade,
        ultimoDia: ultimoDia,
        proximoDia: proximoDia,
        revisoes: revisoes,
        lapsos: lapsos,
        suspenso: valor,
      );

  CartaoSrs comEnterradoAte(int dia) => CartaoSrs(
        estabilidade: estabilidade,
        dificuldade: dificuldade,
        ultimoDia: ultimoDia,
        proximoDia: proximoDia,
        revisoes: revisoes,
        lapsos: lapsos,
        enterradoAte: dia,
      );

  /// "Madura" no Anki: a memória já dura 3 semanas ou mais.
  bool get madura => estabilidade >= 21;

  /// `f|próximo|último|estabilidade|dificuldade|revisões|lapsos[|s | |e<dia>]` —
  /// compacto para caber milhares num documento. O `f` marca a versão (FSRS); o
  /// 8º campo, só quando existe, é `s` (suspenso) ou `e<dia>` (enterrado até).
  String codificar() =>
      'f|$proximoDia|$ultimoDia|${_num(estabilidade)}|${_num(dificuldade)}|$revisoes|$lapsos'
      '${suspenso ? '|s' : (enterradoAte > 0 ? '|e$enterradoAte' : '')}';

  static String _num(double v) => double.parse(v.toStringAsFixed(4)).toString();

  /// Lê o formato atual E o antigo (caixa de Leitner: `caixa|dia|lapsos`),
  /// que é convertido na hora — quem já estudava não perde a agenda.
  static CartaoSrs? decodificar(Object? bruto) {
    final texto = '$bruto';
    final p = texto.split('|');
    if (p.first != 'f') {
      final antigo = CartaoRevisao.decodificar(bruto);
      return antigo == null ? null : CartaoSrs.doLeitner(antigo);
    }
    if (p.length < 7) return null;
    final prox = int.tryParse(p[1]), ult = int.tryParse(p[2]);
    final est = double.tryParse(p[3]), dif = double.tryParse(p[4]);
    final rev = int.tryParse(p[5]), lap = int.tryParse(p[6]);
    if (prox == null || ult == null || est == null || dif == null || rev == null || lap == null) return null;
    if (!est.isFinite || est <= 0 || !dif.isFinite) return null;
    final extra = p.length > 7 ? p[7] : '';
    return CartaoSrs(
      estabilidade: est,
      dificuldade: dif.clamp(minDifficulty, maxDifficulty),
      ultimoDia: ult,
      proximoDia: prox,
      revisoes: rev,
      lapsos: lap,
      suspenso: extra == 's',
      enterradoAte: extra.startsWith('e') ? int.tryParse(extra.substring(1)) ?? 0 : 0,
    );
  }

  /// A caixa de Leitner vira estabilidade (o intervalo da caixa, em dias) e o
  /// dia da próxima revisão é mantido.
  factory CartaoSrs.doLeitner(CartaoRevisao c) {
    final intervalo = Revisao.intervalos[c.caixa.clamp(1, Revisao.intervalos.length) - 1];
    return CartaoSrs(
      estabilidade: intervalo.toDouble(),
      dificuldade: AgendadorFsrs.dificuldadeInicial,
      ultimoDia: c.proximoDia - intervalo,
      proximoDia: c.proximoDia,
      revisoes: c.caixa,
      lapsos: c.lapsos,
    );
  }

  @override
  List<Object?> get props => [estabilidade, dificuldade, ultimoDia, proximoDia, revisoes, lapsos, suspenso, enterradoAte];
}

/// Uma revisão registrada (o "histórico" do Anki): alimenta as estatísticas e,
/// com milhares delas, a otimização dos parâmetros do FSRS.
class EntradaHistorico extends Equatable {
  /// Dia (desde 1970, fuso local) e frase (a mesma chave do cartão).
  final int dia;
  final String chave;

  /// 1 = errei · 2 = difícil · 3 = bom · 4 = fácil (as notas do Anki).
  final int nota;

  /// Foi a 1ª vez da frase (a lição terminada, o nivelamento, um cartão novo): fica
  /// de fora da "retenção real", que só mede o que já tinha sido aprendido.
  final bool primeira;

  const EntradaHistorico(this.dia, this.chave, this.nota, {this.primeira = false});

  /// `dia|chave|nota` (+ `|n` na 1ª vez).
  String codificar() => '$dia|$chave|$nota${primeira ? '|n' : ''}';

  static EntradaHistorico? decodificar(Object? bruto) {
    final p = '$bruto'.split('|');
    if (p.length != 3 && !(p.length == 4 && p[3] == 'n')) return null;
    final dia = int.tryParse(p[0]), nota = int.tryParse(p[2]);
    if (dia == null || nota == null || nota < 1 || nota > 4 || p[1].isEmpty) return null;
    return EntradaHistorico(dia, p[1], nota, primeira: p.length == 4);
  }

  @override
  List<Object?> get props => [dia, chave, nota, primeira];
}

/// Como a digitação de memória vira nota do Anki: limpa = bom, com tropeço ou
/// dica = difícil, errada/"não sei" = errei. "Fácil" só vem quando alguém medir
/// velocidade ([facil]) — o botão dos cartões de virar-e-avaliar.
Rating notaDoResultado(ResultadoRevisao r, {bool facil = false}) => switch (r) {
      ResultadoRevisao.errou => Rating.again,
      ResultadoRevisao.hesitou => Rating.hard,
      ResultadoRevisao.acertou => facil ? Rating.easy : Rating.good,
    };

/// O agendador FSRS-6 (pacote `fsrs`) com os ajustes do curso: retenção 90%,
/// sem etapas de aprendizado (a lição já repete a frase no mesmo dia), intervalo
/// máximo de 1 ano e a 1ª revisão sempre no dia seguinte (o sono entre as
/// sessões — dossiê 01 §5.4).
class AgendadorFsrs {
  static const retencaoPadrao = 0.90;
  static const intervaloMaximo = 365;

  final Scheduler _s;
  final double _retencao;
  final bool _fuzz;
  final List<double>? _parametros;

  /// [fuzz] espalha um pouco os intervalos para as revisões não virem em bloco
  /// (desligado nos testes, para os números serem exatos).
  AgendadorFsrs({double retencao = retencaoPadrao, bool fuzz = true, List<double>? parametros})
      : _retencao = retencao,
        _fuzz = fuzz,
        _parametros = parametros,
        _s = Scheduler(
          parameters: parametros ?? defaultParameters,
          desiredRetention: retencao,
          learningSteps: const [],
          relearningSteps: const [],
          maximumInterval: intervaloMaximo,
          enableFuzzing: fuzz,
        );

  /// O mesmo agendador sem o fuzz: os números EXATOS que os botões mostram.
  late final AgendadorFsrs _exato =
      _fuzz ? AgendadorFsrs(retencao: _retencao, fuzz: false, parametros: _parametros) : this;

  /// A dificuldade que o FSRS dá a uma frase recém-aprendida com nota "bom".
  static final double dificuldadeInicial = () {
    final s = Scheduler(learningSteps: const [], relearningSteps: const [], enableFuzzing: false);
    final c = s.reviewCard(Card(cardId: 0, due: _utc(0)), Rating.good, reviewDateTime: _utc(0)).card;
    return _arredonda(c.difficulty!);
  }();

  static DateTime _utc(int dia) => DateTime.utc(1970, 1, 1 + dia);
  static int _dia(DateTime d) => d.difference(DateTime.utc(1970)).inDays;
  static double _arredonda(double v) => double.parse(v.toStringAsFixed(4));

  CartaoSrs _de(Card c, int hoje, {required int revisoes, required int lapsos, int? volta}) => CartaoSrs(
        estabilidade: _arredonda(c.stability!),
        dificuldade: _arredonda(c.difficulty!),
        ultimoDia: hoje,
        proximoDia: volta ?? _dia(c.due),
        revisoes: revisoes,
        lapsos: lapsos,
      );

  /// A frase acabou de ser aprendida na lição (a prova dela vale [nota]):
  /// volta AMANHÃ, seja qual for a estabilidade. Com [voltaAmanha] falso (um
  /// cartão de virar-e-avaliar que a pessoa vê pela 1ª vez, como no Anki) a
  /// nota decide: "fácil" já volta daqui a semanas.
  CartaoSrs novo(int hoje, {Rating nota = Rating.good, bool voltaAmanha = true}) {
    final c = _s.reviewCard(Card(cardId: 0, due: _utc(hoje)), nota, reviewDateTime: _utc(hoje)).card;
    return _de(c, hoje, revisoes: 1, lapsos: 0, volta: voltaAmanha ? hoje + 1 : null);
  }

  /// Em quantos dias [c] volta com cada nota — o que os 4 botões mostram.
  /// [c] null = cartão que a pessoa vê pela 1ª vez.
  Map<Rating, int> previsao(CartaoSrs? c, int hoje) {
    final a = _exato;
    return {
      for (final n in Rating.values)
        n: (c == null ? a.novo(hoje, nota: n, voltaAmanha: false) : a.avaliar(c, n, hoje)).proximoDia - hoje,
    };
  }

  /// Frase de uma trilha que a pessoa provou que já sabe (nivelamento): entra
  /// como "fácil" e a 1ª revisão, que confirma ou derruba, vem em 1 semana.
  CartaoSrs testada(int hoje) {
    final c = _s.reviewCard(Card(cardId: 0, due: _utc(hoje)), Rating.easy, reviewDateTime: _utc(hoje)).card;
    return _de(c, hoje, revisoes: 1, lapsos: 0, volta: hoje + 7);
  }

  Card _card(CartaoSrs c) => Card(
        cardId: 0,
        state: State.review,
        stability: c.estabilidade,
        difficulty: c.dificuldade,
        due: _utc(c.proximoDia),
        lastReview: _utc(c.ultimoDia),
      );

  /// O próximo estado de [c] depois de revisar hoje com [nota].
  CartaoSrs avaliar(CartaoSrs c, Rating nota, int hoje) {
    final r = _s.reviewCard(_card(c), nota, reviewDateTime: _utc(hoje)).card;
    return _de(r, hoje, revisoes: c.revisoes + 1, lapsos: c.lapsos + (nota == Rating.again ? 1 : 0));
  }

  /// Chance (0–1) de lembrar [c] hoje.
  double retrievabilidade(CartaoSrs c, int hoje) => _s.getCardRetrievability(_card(c), currentDateTime: _utc(hoje));

  /// Chaves das frases que vencem até [hoje], as que a pessoa tem MENOS chance
  /// de lembrar primeiro (empate: a mais atrasada), no máximo [limite].
  List<String> devidas(Map<String, CartaoSrs> cartoes, int hoje, {int limite = Revisao.limiteDiario}) {
    final lista = [
      for (final e in cartoes.entries)
        if (e.value.devidaEm(hoje)) (e.key, retrievabilidade(e.value, hoje), e.value.proximoDia),
    ]..sort((a, b) {
        final r = a.$2.compareTo(b.$2);
        if (r != 0) return r;
        final atraso = a.$3.compareTo(b.$3);
        return atraso != 0 ? atraso : a.$1.compareTo(b.$1);
      });
    return [for (final e in lista.take(limite)) e.$1];
  }
}

/// "1 dia", "6 dias", "3 sem", "2 meses", "1 ano": o intervalo nos botões da revisão.
String rotuloIntervalo(int dias) {
  if (dias <= 1) return '1 dia';
  if (dias < 14) return '$dias dias';
  if (dias < 60) return '${(dias / 7).round()} sem';
  if (dias < 365) {
    final m = (dias / 30).round();
    return m == 1 ? '1 mês' : '$m meses';
  }
  final a = (dias / 365).round();
  return a == 1 ? '1 ano' : '$a anos';
}
