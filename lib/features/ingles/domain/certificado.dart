import 'dart:math';

import '../../curso/domain/curriculo.dart';

/// 🎓 O certificado de CONCLUSÃO de um nível do curso de inglês (curso livre: não precisa de autorização do MEC).
///
/// Regras (pedido do dono, 25/out/2026):
/// - sai só com a trilha de revisão do nível concluída, [fracaoMinimaDeLicoes] das lições do nível feitas e a
///   **prova final** ([questoesDaProva] exercícios das lições do nível) com nota ≥ [notaMinima];
/// - leva o nome que o aluno digita (a conta só tem e-mail), a data, o nível, a nota, a carga horária estimada do
///   conteúdo e um [codigo] que abre a página pública de verificação (`?certificado=<codigo>` no site);
/// - NUNCA diz "oficial", "reconhecido pelo MEC" nem "equivale a TOEFL/IELTS/Cambridge" (ver [textoDeConteudo]).
/// Dart puro: o app grava no Firestore (`certificados/<codigo>`) e monta o PDF.

/// Exercícios da prova final.
const questoesDaProva = 20;

/// Nota mínima (%) para passar: a mesma conta do resumo da revisão (de primeira = 1, com tropeço = ½).
const notaMinima = 80;

/// Fração das lições do nível que precisa estar feita para liberar a prova.
const fracaoMinimaDeLicoes = .8;

/// Depois de não passar, a próxima tentativa só depois disto (perguntas novas, sem "chutar até passar").
const esperaDepoisDeReprovar = Duration(hours: 1);

/// Minutos de prática estimados por frase (5 digitações intercaladas + a revisão dos dias seguintes).
const minutosDePraticaPorFrase = 1.0;

/// O que o certificado diz sobre o conteúdo (sem prometer proficiência oficial).
const textoDeConteudo = 'Conteúdo organizado pelos níveis do Quadro Europeu Comum de Referência para Línguas (CEFR). '
    'Certificado de conclusão de curso livre; não é certificado de proficiência.';

/// Um nível do curso que dá certificado: o código ("B2"), o nome ("B2 · Desenvoltura") e a trilha de revisão.
class NivelCertificado {
  final String codigo, nome, trilhaDeRevisao;
  const NivelCertificado(this.codigo, this.nome, this.trilhaDeRevisao);

  /// O nome sem o código: "Desenvoltura".
  String get titulo => nome.contains('·') ? nome.split('·').last.trim() : nome;
}

/// O código do nível pela etapa da trilha: "B2 · Desenvoltura" → "B2".
String codigoDaEtapa(String etapa) => etapa.split(RegExp(r'[ ·—-]')).first.toUpperCase();

/// A trilha de revisão que fecha cada nível (o DEV fecha com o dia inteiro de tech lead).
const _revisaoDoNivel = {
  'A1': 'revisao-a1',
  'A2': 'revisao-a2',
  'B1': 'revisao-b1',
  'B2': 'revisao-b2',
  'C1': 'revisao-c1',
  'DEV': 'pro-dia-de-trabalho',
};

/// O slug da trilha (o prefixo do id da 1ª lição).
String slugDaTrilha(Trilha t) => t.licoes.isEmpty ? '' : t.licoes.first.id.split('.').first;

/// Os níveis do curso que têm trilha de revisão, na ordem do curso.
List<NivelCertificado> niveisDoCurso(List<Trilha> trilhas) {
  final vistos = <String>{};
  final r = <NivelCertificado>[];
  for (final t in trilhas) {
    if (t.etapa.isEmpty) continue;
    final c = codigoDaEtapa(t.etapa);
    final rev = _revisaoDoNivel[c];
    if (rev == null || !vistos.add(c)) continue;
    if (!trilhas.any((x) => codigoDaEtapa(x.etapa) == c && slugDaTrilha(x) == rev)) continue;
    r.add(NivelCertificado(c, t.etapa, rev));
  }
  return r;
}

/// As trilhas do nível [nivel] (pelo código da etapa), com o índice no curso.
List<(int, Trilha)> trilhasDoNivel(List<Trilha> trilhas, String nivel) => [
      for (var i = 0; i < trilhas.length; i++)
        if (codigoDaEtapa(trilhas[i].etapa) == nivel) (i, trilhas[i]),
    ];

/// Onde o aluno está para o certificado do [nivel].
class SituacaoDoNivel {
  final int licoes, feitas;
  final bool revisaoFeita;
  const SituacaoDoNivel({required this.licoes, required this.feitas, required this.revisaoFeita});

  int get minimoDeLicoes => (licoes * fracaoMinimaDeLicoes).ceil();
  bool get liberaProva => revisaoFeita && feitas >= minimoDeLicoes;
}

/// A situação do [nivel]: [feita] diz se a lição `l` da trilha `t` (índices do curso) está concluída.
SituacaoDoNivel situacaoDoNivel(List<Trilha> trilhas, NivelCertificado nivel, bool Function(int t, int l) feita) {
  var licoes = 0, feitas = 0;
  var revisao = false;
  for (final (t, tr) in trilhasDoNivel(trilhas, nivel.codigo)) {
    var todas = tr.licoes.isNotEmpty;
    for (var l = 0; l < tr.licoes.length; l++) {
      licoes++;
      if (feita(t, l)) {
        feitas++;
      } else {
        todas = false;
      }
    }
    if (slugDaTrilha(tr) == nivel.trilhaDeRevisao) revisao = todas;
  }
  return SituacaoDoNivel(licoes: licoes, feitas: feitas, revisaoFeita: revisao);
}

/// A carga horária estimada do CONTEÚDO do nível, em horas inteiras: as aulas do professor ([segundosDeAula],
/// pela duração estimada de cada uma) + [minutosDePraticaPorFrase] por frase. É o conteúdo, não o tempo que o
/// aluno passou no app (o certificado diz "carga horária do conteúdo").
int horasDoNivel(List<Trilha> trilhas, String nivel, double Function(Licao l) segundosDeAula) {
  var segundos = 0.0;
  for (final (_, t) in trilhasDoNivel(trilhas, nivel)) {
    for (final l in t.licoes) {
      segundos += segundosDeAula(l) + l.trechos.length * minutosDePraticaPorFrase * 60;
    }
  }
  return max(1, (segundos / 3600).round());
}

/// A nota (%) da prova: de primeira = 1, com tropeço = ½ (a mesma conta do resumo da revisão).
int notaDaProva({required int dePrimeira, required int comTropeco, required int total}) =>
    total <= 0 ? 0 : ((dePrimeira + comTropeco * .5) * 100 / total).round();

/// Letras do código: sem 0/O, 1/I/L, para ditar e digitar sem confusão.
const _alfabeto = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

/// Um código novo: "PCL-B2-7KQ4-M9XZ" (o nível + 8 letras aleatórias: 31^8 ≈ 850 bilhões).
String gerarCodigo(String nivel, Random rnd) {
  String bloco() => String.fromCharCodes([for (var i = 0; i < 4; i++) _alfabeto.codeUnitAt(rnd.nextInt(_alfabeto.length))]);
  return 'PCL-${nivel.toUpperCase()}-${bloco()}-${bloco()}';
}

final _formatoDoCodigo = RegExp(r'^PCL-(A1|A2|B1|B2|C1|DEV)-[A-HJKMNP-Z2-9]{4}-[A-HJKMNP-Z2-9]{4}$');

/// O código digitado/colado, normalizado (maiúsculas, sem espaços), ou null se não tem o formato.
String? normalizarCodigo(String bruto) {
  final c = bruto.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  return _formatoDoCodigo.hasMatch(c) ? c : null;
}

/// O endereço da página de verificação do [codigo] no [site] (com a barra no fim).
String urlDeVerificacao(String site, String codigo) => '$site?certificado=$codigo';

/// O nome como sai no certificado: espaços normalizados; null se curto/estranho demais.
String? nomeParaCertificado(String bruto) {
  final n = bruto.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (n.length < 5 || n.length > 80 || !n.contains(' ')) return null;
  if (!RegExp(r"^[\p{L}][\p{L} .'-]*$", unicode: true).hasMatch(n)) return null;
  return n;
}

/// Um certificado emitido (o documento `certificados/<codigo>`).
class Certificado {
  final String codigo, uid, nome, nivel, nomeDoNivel;
  final DateTime emitidoEm;
  final int nota, horas, licoes;

  const Certificado({
    required this.codigo,
    required this.uid,
    required this.nome,
    required this.nivel,
    required this.nomeDoNivel,
    required this.emitidoEm,
    required this.nota,
    required this.horas,
    required this.licoes,
  });

  Map<String, dynamic> toJson() => {
        'versao': 1,
        'uid': uid,
        'nome': nome,
        'nivel': nivel,
        'nomeDoNivel': nomeDoNivel,
        'emitidoEm': emitidoEm.toUtc().toIso8601String(),
        'nota': nota,
        'horas': horas,
        'licoes': licoes,
      };

  static Certificado? fromJson(String codigo, Map<String, dynamic>? j) {
    if (j == null) return null;
    final em = DateTime.tryParse('${j['emitidoEm']}');
    if (em == null || j['nome'] is! String || j['nivel'] is! String) return null;
    return Certificado(
      codigo: codigo,
      uid: '${j['uid'] ?? ''}',
      nome: j['nome'] as String,
      nivel: j['nivel'] as String,
      nomeDoNivel: '${j['nomeDoNivel'] ?? j['nivel']}',
      emitidoEm: em,
      nota: (j['nota'] as num?)?.toInt() ?? 0,
      horas: (j['horas'] as num?)?.toInt() ?? 0,
      licoes: (j['licoes'] as num?)?.toInt() ?? 0,
    );
  }
}

const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

/// "26 de outubro de 2026" (no fuso de quem vê).
String dataPorExtenso(DateTime d) {
  final l = d.toLocal();
  return '${l.day} de ${_meses[l.month - 1]} de ${l.year}';
}
