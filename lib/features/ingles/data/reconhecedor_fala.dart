import 'reconhecedor_stub.dart'
    if (dart.library.js_interop) 'reconhecedor_web.dart'
    if (dart.library.io) 'reconhecedor_nativo.dart' as impl;

/// Por que a escuta não deu certo (o app só precisa saber o bastante para
/// dizer o que fazer).
enum ErroFala {
  /// O navegador (ou a pessoa) bloqueou o microfone.
  semPermissao,

  /// Sem microfone disponível.
  semMicrofone,

  /// O reconhecimento do navegador é feito num servidor: sem internet não vai.
  semRede,

  /// Abriu o microfone mas ninguém falou (ou não deu para entender).
  naoOuviu,

  /// O navegador não tem reconhecimento de voz (Firefox, Safari de PWA…).
  naoSuportado,
  outro,
}

/// Uma escuta em curso: dá para pedir o resultado agora ou desistir.
abstract class SessaoFala {
  /// Para de ouvir e entrega o que já ouviu (o fim da fala, no toque).
  void parar();

  /// Desiste: nada é entregue.
  void cancelar();
}

/// Reconhece o que a pessoa fala em inglês (Web Speech API do navegador:
/// grátis, sem chave e sem cota, mas precisa de internet no Chrome e do
/// toque que a inicia). O [ReconhecedorFala.navegador] é o de verdade;
/// os testes injetam o deles.
abstract class ReconhecedorFala {
  const ReconhecedorFala();

  /// O reconhecedor do navegador (no teste na VM: um que diz "não suportado").
  factory ReconhecedorFala.navegador() => impl.criarReconhecedor();

  /// Este navegador sabe reconhecer voz.
  bool get suportado;

  /// Começa a ouvir (precisa vir de um TOQUE: sem gesto o navegador não
  /// abre o microfone). [aoParcial] vem enquanto a pessoa fala; [aoFinal]
  /// traz as hipóteses do reconhecedor, a mais provável primeiro; [aoErro]
  /// só se deu errado; [aoFim] SEMPRE vem, por último, uma vez só.
  SessaoFala ouvir({
    String idioma = 'en-US',
    required void Function(String texto) aoParcial,
    required void Function(List<String> hipoteses) aoFinal,
    required void Function(ErroFala erro) aoErro,
    required void Function() aoFim,
  });
}
