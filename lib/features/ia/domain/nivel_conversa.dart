import '../../curso/domain/curriculo.dart';
import '../../curso/domain/mapa_regras.dart';

/// Os níveis da conversa com IA (CEFR), do mais fácil ao mais difícil.
const niveisConversa = ['A1', 'A2', 'B1', 'B2', 'C1'];

/// 'A1 · Fundação' → 'A1'; 'DEV · …' → 'B2'; 'C2…' → 'C1'; desconhecido/vazio → ''.
String codigoDoNivel(String etapa) {
  final e = etapa.trim().toUpperCase();
  if (e.startsWith('DEV')) return 'B2';
  final m = RegExp(r'^([ABC])([12])(?![0-9])').firstMatch(e);
  if (m == null) return '';
  final codigo = '${m.group(1)}${m.group(2)}';
  return codigo == 'C2' ? 'C1' : codigo;
}

/// A1 = 0 … C1 = 4; desconhecido = 0.
int ordemDoNivel(String nivel) {
  final i = niveisConversa.indexOf(nivel.trim().toUpperCase());
  return i < 0 ? 0 : i;
}

/// Dart puro: NÃO importa o CursoState (presentation/bloc); a página passa state.trilhas/state.concluidas.
/// O MAIOR nível já alcançado pela FRONTEIRA: o maior `codigoDoNivel(etapa)` das trilhas não próprias de 0
/// até a da fronteira (`f = fronteira(trilhas, concluidas)`, mapa_regras.dart), inclusive. Curso inteiro
/// feito (f == null) → o maior entre todas as trilhas não próprias. Desconhecido ou vazio → 'A1'.
/// Assim uma lição feita adiante numa unidade DEV ou C1 não sobe o nível; só a fronteira chegar lá (inclusive
/// pelo "Já sei esta trilha", de propósito). E as unidades DEV (que contam como B2) vêm DEPOIS do C1 no
/// currículo: quem terminou o C1 e está no DEV continua C1, não cai para B2.
String nivelDoAluno({required List<Trilha> trilhas, required Set<String> concluidas}) {
  final f = fronteira(trilhas, concluidas);
  final ate = f == null ? trilhas.length - 1 : f.$1;
  var melhor = '';
  for (var i = 0; i <= ate && i < trilhas.length; i++) {
    if (trilhas[i].propria) continue;
    final c = codigoDoNivel(trilhas[i].etapa);
    if (c.isEmpty) continue;
    if (melhor.isEmpty || ordemDoNivel(c) > ordemDoNivel(melhor)) melhor = c;
  }
  return melhor.isEmpty ? 'A1' : melhor;
}

/// Um [escolhido] válido (um de [niveisConversa]) vence; senão [aluno]; senão 'A1'.
String nivelDaConversa({required String aluno, String escolhido = ''}) {
  final e = escolhido.trim().toUpperCase();
  if (niveisConversa.contains(e)) return e;
  final a = codigoDoNivel(aluno);
  return a.isEmpty ? 'A1' : a;
}

/// `ordemDoNivel(codigoDoNivel(etapaCenario)) > ordemDoNivel(nivel)`.
bool acimaDoNivel(String etapaCenario, String nivel) => ordemDoNivel(codigoDoNivel(etapaCenario)) > ordemDoNivel(nivel);

/// A1 ou A2.
bool nivelIniciante(String nivel) => const {'A1', 'A2'}.contains(codigoDoNivel(nivel));

/// Palavras sem repetição, só letras/'/-, de 2 a 24 caracteres, até [max].
List<String> vocabularioParaPrompt(Iterable<String> palavras, {int max = 30}) {
  final valida = RegExp(r"^[a-z'-]{2,24}$");
  final vistas = <String>{};
  final r = <String>[];
  for (final p in palavras) {
    if (r.length >= max) break;
    final w = p.trim().toLowerCase();
    if (!valida.hasMatch(w) || !w.contains(RegExp('[a-z]'))) continue;
    if (vistas.add(w)) r.add(w);
  }
  return r;
}
