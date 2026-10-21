/// Como terminou uma fala do player: tocou até o fim, foi cortada por outra fala do app, ou não há
/// voz para ela (ex.: navegador sem voz pt-BR).
enum FimDaFala { acabou, cortada, semVoz }

/// A saída de áudio do "🎧 Ouvir" (no app, `SaidaVozIngles`; nos testes, um fake com Completers).
abstract class SaidaDeAudio {
  Future<FimDaFala> en(String texto, {required double fator});

  Future<FimDaFala> pt(String texto, {required double fator});

  Future<FimDaFala> silencio(Duration d);

  void parar();

  void preaquecer(String texto);

  bool get somLiberado;

  /// Segundos a 1×.
  double duracaoDe(String en);

  bool temGravacao(String en);
}

/// Opcional (como o `SessaoMidiaComRepetir`): a saída sabe se a frase toca o áudio que o ALUNO anexou —
/// que pode durar bem mais que a estimativa, e o vigia do player dá mais folga a ele.
abstract class SaidaComAudioDoAluno {
  bool temAudioDoAluno(String en);
}
