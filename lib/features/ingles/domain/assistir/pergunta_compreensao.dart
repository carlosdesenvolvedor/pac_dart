import '../fila_ouvir.dart';

/// 📺❓ A pergunta de compreensão OPCIONAL do fim da historinha da lição: "Quem disse «…»?" (as opções são
/// os falantes da lição) ou "O que significa «…»?" (as opções são traduções de outras frases da lição).
///
/// Tudo puro (sem Flutter) e determinístico: a semente é o id da lição, então a mesma lição faz sempre a
/// mesma pergunta, com as opções na mesma ordem (o `assistir_pergunta_test` prende). Não grava nada.

/// Que tipo de pergunta.
enum TipoPergunta { quemDisse, significado }

/// Uma pergunta pronta: o [enunciado] já com a frase, a [frase] em inglês (para o 🔊), 3 [opcoes] e o
/// índice da [certa].
class PerguntaCompreensao {
  final TipoPergunta tipo;
  final String frase, enunciado;
  final List<String> opcoes;
  final int certa;

  const PerguntaCompreensao({
    required this.tipo,
    required this.frase,
    required this.enunciado,
    required this.opcoes,
    required this.certa,
  });
}

/// Falantes que completam as opções do "Quem disse" quando a lição só tem 2 (os mais comuns do curso).
const falantesCanonicos = ['voce', 'mike', 'ana', 'sarah', 'ben', 'emma'];

/// Quantas opções a pergunta tem.
const opcoesDaPergunta = 3;

/// A pergunta da lição [licaoId] sobre as [faixas] dela, ou null quando não dá (menos de 3 frases, ou nem
/// 2 falantes nem 3 traduções distintas). [nomeDe] dá o nome de um falante (`nomeDeQuem`; null = narrador).
PerguntaCompreensao? perguntaDaLicao(
  String licaoId,
  List<Faixa> faixas, {
  required String? Function(String quem) nomeDe,
}) {
  final frases = [for (final f in faixas) if (f.en.trim().isNotEmpty) f];
  if (frases.length < opcoesDaPergunta) return null;
  var semente = _hash(licaoId);
  int sorteio(int n) {
    semente = _misturar(semente);
    return semente % n;
  }

  final tipos = [
    ?_quemDisse(frases, nomeDe, sorteio),
    ?_significado(frases, sorteio),
  ];
  if (tipos.isEmpty) return null;
  return tipos[sorteio(tipos.length)];
}

/// "Quem disse «…»?": só com ≥ 2 falantes distintos (o narrador não conta) e uma frase que só um deles diz.
PerguntaCompreensao? _quemDisse(List<Faixa> frases, String? Function(String) nomeDe, int Function(int) sorteio) {
  // quem diz cada frase (a mesma frase na boca de dois não serve: a resposta ficaria ambígua)
  final quemDiz = <String, Set<String>>{};
  for (final f in frases) {
    if (nomeDe(f.quem) == null) continue;
    (quemDiz[_norm(f.en)] ??= {}).add(f.quem);
  }
  final falantes = {for (final s in quemDiz.values) ...s}.toList();
  if (falantes.length < 2) return null;
  final candidatas = [
    for (final f in frases)
      if (nomeDe(f.quem) != null && quemDiz[_norm(f.en)]!.length == 1) f,
  ];
  if (candidatas.isEmpty) return null;
  final alvo = candidatas[sorteio(candidatas.length)];
  final outros = [for (final q in falantes) if (q != alvo.quem) q];
  final escolhidos = <String>[alvo.quem];
  while (escolhidos.length < opcoesDaPergunta && outros.isNotEmpty) {
    escolhidos.add(outros.removeAt(sorteio(outros.length)));
  }
  // completa com um canônico que não está na lição
  for (final q in falantesCanonicos) {
    if (escolhidos.length >= opcoesDaPergunta) break;
    if (!falantes.contains(q)) escolhidos.add(q);
  }
  final nomes = [for (final q in escolhidos) nomeDe(q)!];
  if (nomes.toSet().length < opcoesDaPergunta) return null;
  return _montar(TipoPergunta.quemDisse, alvo.en, 'Quem disse «${alvo.en.trim()}»?', nomes, sorteio);
}

/// "O que significa «…»?": a tradução certa e 2 de outras frases da lição (todas diferentes entre si).
PerguntaCompreensao? _significado(List<Faixa> frases, int Function(int) sorteio) {
  final comPt = [for (final f in frases) if (f.pt.trim().isNotEmpty) f];
  final traducoes = {for (final f in comPt) _norm(f.pt)};
  if (traducoes.length < opcoesDaPergunta) return null;
  // frase repetida com traduções diferentes ficaria ambígua: cada inglês com uma tradução só
  final ptsDoEn = <String, Set<String>>{};
  for (final f in comPt) {
    (ptsDoEn[_norm(f.en)] ??= {}).add(_norm(f.pt));
  }
  final candidatas = [for (final f in comPt) if (ptsDoEn[_norm(f.en)]!.length == 1) f];
  if (candidatas.isEmpty) return null;
  final alvo = candidatas[sorteio(candidatas.length)];
  final vistas = {_norm(alvo.pt)};
  final outras = <String>[];
  for (final f in comPt) {
    if (vistas.add(_norm(f.pt))) outras.add(f.pt.trim());
  }
  final opcoes = <String>[alvo.pt.trim()];
  while (opcoes.length < opcoesDaPergunta && outras.isNotEmpty) {
    opcoes.add(outras.removeAt(sorteio(outras.length)));
  }
  if (opcoes.length < opcoesDaPergunta) return null;
  return _montar(TipoPergunta.significado, alvo.en, 'O que significa «${alvo.en.trim()}»?', opcoes, sorteio);
}

/// Embaralha as [opcoes] (a certa é a 1ª) e guarda onde a certa caiu.
PerguntaCompreensao _montar(
  TipoPergunta tipo,
  String frase,
  String enunciado,
  List<String> opcoes,
  int Function(int) sorteio,
) {
  final certa = opcoes.first;
  final ordem = [...opcoes];
  for (var i = ordem.length - 1; i > 0; i--) {
    final j = sorteio(i + 1);
    final t = ordem[i];
    ordem[i] = ordem[j];
    ordem[j] = t;
  }
  return PerguntaCompreensao(
    tipo: tipo,
    frase: frase.trim(),
    enunciado: enunciado,
    opcoes: List.unmodifiable(ordem),
    certa: ordem.indexOf(certa),
  );
}

String _norm(String s) => s.trim().toLowerCase();

/// Um hash de 31 bits (o `String.hashCode` muda entre a web e a VM; as contas cabem nos 53 bits da web).
int _hash(String s) {
  var h = 7;
  for (final u in s.codeUnits) {
    h = (h * 31 + u) % 0x7fffffff;
  }
  return h % 0x7ffffffe + 1;
}

/// Um passo do gerador "minimal standard" (Park–Miller): nunca zera e dá o mesmo na web e na VM.
int _misturar(int x) => (x * 48271) % 0x7fffffff;
