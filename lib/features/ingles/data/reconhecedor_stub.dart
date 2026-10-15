import 'dart:async';

import 'reconhecedor_fala.dart';

/// Fora do navegador (testes na VM): sem reconhecimento, nunca lança.
ReconhecedorFala criarReconhecedor() => const _SemReconhecimento();

class _SemReconhecimento extends ReconhecedorFala {
  const _SemReconhecimento();

  @override
  bool get suportado => false;

  @override
  SessaoFala ouvir({
    String idioma = 'en-US',
    required void Function(String texto) aoParcial,
    required void Function(List<String> hipoteses) aoFinal,
    required void Function(ErroFala erro) aoErro,
    required void Function() aoFim,
  }) {
    scheduleMicrotask(() {
      aoErro(ErroFala.naoSuportado);
      aoFim();
    });
    return const _SessaoVazia();
  }
}

class _SessaoVazia implements SessaoFala {
  const _SessaoVazia();
  @override
  void parar() {}
  @override
  void cancelar() {}
}
