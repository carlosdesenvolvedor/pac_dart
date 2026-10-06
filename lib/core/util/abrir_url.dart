import 'abrir_url_stub.dart' if (dart.library.js_interop) 'abrir_url_web.dart' as impl;

/// Abre [url] numa aba nova do navegador. Fora da web (testes, VM) não faz
/// nada e devolve false — quem chama mostra o plano B.
bool abrirUrl(String url) => impl.abrirUrl(url);
