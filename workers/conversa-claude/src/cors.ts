/** Origens do app web publicado. */
const ORIGENS_FIXAS = new Set(['https://pac-dart.web.app', 'https://pac-dart.firebaseapp.com']);

/** `flutter run -d chrome` sobe em http://localhost:<porta> (ou 127.0.0.1). */
const ORIGEM_LOCAL = /^http:\/\/(localhost|127\.0\.0\.1)(:\d{1,5})?$/;

export type DecisaoOrigem =
  | { tipo: 'sem_origem' } // app nativo / curl: permitido (o token continua obrigatório)
  | { tipo: 'permitida'; origem: string }
  | { tipo: 'negada' };

export function origemPermitida(origem: string): boolean {
  return ORIGENS_FIXAS.has(origem) || ORIGEM_LOCAL.test(origem);
}

export function decidirOrigem(origem: string | null): DecisaoOrigem {
  if (origem === null || origem === '') return { tipo: 'sem_origem' };
  return origemPermitida(origem) ? { tipo: 'permitida', origem } : { tipo: 'negada' };
}

/** Cabeçalhos CORS das respostas normais (não-preflight). */
export function cabecalhosCors(decisao: DecisaoOrigem): Record<string, string> {
  if (decisao.tipo !== 'permitida') return {};
  return {
    'Access-Control-Allow-Origin': decisao.origem,
    'Access-Control-Expose-Headers': 'Retry-After',
    Vary: 'Origin',
  };
}

/** Cabeçalhos da resposta ao preflight (OPTIONS). */
export function cabecalhosPreflight(decisao: DecisaoOrigem): Record<string, string> {
  return {
    ...cabecalhosCors(decisao),
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'authorization, content-type',
    'Access-Control-Max-Age': '86400',
  };
}
