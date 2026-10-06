import '../../curso/domain/curriculo.dart';
import 'desafio.dart';

/// Monta o banco do Arcade a partir dos desafios de lógica de um currículo
/// (a vertente C# não tem banco autoral próprio: reaproveita os desafios
/// validados das trilhas).
///
/// - `saida`  → Corrida do Código (lógica: "o que aparece no console?")
/// - `lacuna` → Gol (sintaxe: "complete a peça que falta")
/// - `bug`    → Caça-Bug (uma linha estragada)
///
/// Os jogos usam 3 alternativas: fica a certa + as 2 primeiras erradas.
/// O nível do jogo (1–3) vem da ETAPA da trilha — Iniciante 1,
/// Intermediário 2, Avançado/Sênior 3 — para a escadinha das fases subir
/// junto com o curso.
int _nivelDaEtapa(String etapa) => switch (etapa) {
      'Iniciante' => 1,
      'Intermediário' => 2,
      '' => 1,
      _ => 3,
    };

/// Só entra no jogo o que cabe na tela do arcade (código e opções curtos).
bool _cabe(String cod, List<String> opcoes) =>
    cod.split('\n').length <= 10 && opcoes.every((o) => o.length <= 60 && !o.contains('\n'));

List<Desafio> desafiosDoCurriculo(List<Trilha> trilhas) {
  final banco = <Desafio>[];
  for (final t in trilhas) {
    final nivel = _nivelDaEtapa(t.etapa);
    for (final d in t.desafios) {
      final ehLogica = d.tipo == TipoDesafioLogica.saida;
      final ehSintaxe = d.tipo == TipoDesafioLogica.lacuna;
      if (!ehLogica && !ehSintaxe) continue;
      if (d.opcoes.length < 3 || d.certa < 0 || d.certa >= d.opcoes.length) continue;
      if (!_cabe(d.cod, d.opcoes)) continue;
      final erradas = [for (var i = 0; i < d.opcoes.length; i++) if (i != d.certa) d.opcoes[i]];
      banco.add(Desafio(
        tipo: ehLogica ? TipoDesafio.logica : TipoDesafio.sintaxe,
        nivel: nivel,
        pergunta: ehLogica ? 'O que aparece no console?' : d.enunciado,
        codigo: d.cod,
        opcoes: [d.opcoes[d.certa], ...erradas.take(2)],
        certa: 0,
        explica: d.explicacao,
      ));
    }
  }
  return banco;
}

List<DesafioBug> bugsDoCurriculo(List<Trilha> trilhas) => [
      for (final t in trilhas)
        for (final d in t.desafios)
          if (d.tipo == TipoDesafioLogica.bug &&
              d.linhaBug >= 0 &&
              d.linhaBug < d.linhas.length &&
              // o Caça-Bug escolhe a linha pelas teclas 1–9
              d.linhas.length <= 9 &&
              d.linhas.every((l) => !l.contains('\n')))
            DesafioBug(
              nivel: _nivelDaEtapa(t.etapa),
              missao: d.enunciado,
              linhas: d.linhas,
              linhaComBug: d.linhaBug,
              explica: '${d.explicacao} Correção: ${d.correcao}',
            ),
    ];
