import 'salvar_texto_stub.dart' if (dart.library.js_interop) 'salvar_texto_web.dart' as impl;

/// Baixa [conteudo] como um arquivo de texto chamado [nome] (só no navegador). Fora dele
/// (celular, testes) devolve false e quem chama oferece "copiar" no lugar.
bool salvarTexto(String nome, String conteudo) => impl.salvarTexto(nome, conteudo);

/// O dispositivo consegue baixar arquivo (navegador)?
bool get podeSalvarArquivo => impl.podeSalvar;
