import 'package:equatable/equatable.dart';

import 'estudo.dart';
import 'resultado_estudo.dart';

/// Matriz de confusão e métricas contra o gabarito (seção 7 do plano).
///
/// "Positivo" = o estudo segue adiante. "Incerto" conta como positivo: na triagem, incerto vai para
/// o pesquisador ler, e é isso que protege o recall. Estudos sem gabarito (ou com gabarito
/// "incerto") ficam fora da matriz.
class Metricas extends Equatable {
  final int vp;
  final int fp;
  final int fn;
  final int vn;

  /// Estudos do conjunto inteiro, com ou sem gabarito.
  final int total;

  /// Quantos o pesquisador não precisou ler com atenção (excluídos na etapa 1).
  final int dispensados;

  /// Decisões exatamente iguais ao gabarito (três classes; "incerto" nunca bate).
  final int iguais;

  const Metricas({
    this.vp = 0,
    this.fp = 0,
    this.fn = 0,
    this.vn = 0,
    this.total = 0,
    this.dispensados = 0,
    this.iguais = 0,
  });

  /// [decisaoDe] escolhe qual decisão avaliar (etapa 1, sistema, final…).
  factory Metricas.de(List<ResultadoEstudo> resultados, Decisao? Function(ResultadoEstudo) decisaoDe) {
    var vp = 0, fp = 0, fn = 0, vn = 0, dispensados = 0, iguais = 0;
    for (final r in resultados) {
      if (r.faixa == Faixa.excluido) dispensados++;
      final g = r.estudo.gabarito;
      final d = decisaoDe(r);
      if (g == null || g == Decisao.incerto || d == null) continue;
      if (d == g) iguais++;
      final previsto = d != Decisao.excluir;
      final real = g == Decisao.incluir;
      if (previsto && real) {
        vp++;
      } else if (previsto && !real) {
        fp++;
      } else if (!previsto && real) {
        fn++;
      } else {
        vn++;
      }
    }
    return Metricas(vp: vp, fp: fp, fn: fn, vn: vn, total: resultados.length, dispensados: dispensados, iguais: iguais);
  }

  int get avaliados => vp + fp + fn + vn;

  /// A métrica mais importante: perder estudo relevante é o pior erro numa revisão.
  double? get recall => vp + fn == 0 ? null : vp / (vp + fn);
  double? get precisao => vp + fp == 0 ? null : vp / (vp + fp);
  double? get acuracia => avaliados == 0 ? null : (vp + vn) / avaliados;
  double? get concordancia => avaliados == 0 ? null : iguais / avaliados;

  /// Kappa de Cohen (binário: segue / não segue) entre o sistema e o gabarito.
  double? get kappa {
    final n = avaliados;
    if (n == 0) return null;
    final po = (vp + vn) / n;
    final pe = ((vp + fp) * (vp + fn) + (fn + vn) * (fp + vn)) / (n * n);
    if (pe == 1) return null;
    return (po - pe) / (1 - pe);
  }

  /// Percentual de estudos que o pesquisador não precisou ler com atenção.
  double? get reducaoTrabalho => total == 0 ? null : dispensados / total;

  Map<String, dynamic> toJson() => {
    'vp': vp,
    'fp': fp,
    'fn': fn,
    'vn': vn,
    'avaliados': avaliados,
    'recall': recall,
    'precisao': precisao,
    'acuracia': acuracia,
    'concordancia': concordancia,
    'kappa': kappa,
    'reducao_trabalho': reducaoTrabalho,
  };

  @override
  List<Object?> get props => [vp, fp, fn, vn, total, dispensados, iguais];
}
