#!/usr/bin/env python3
"""Gera a voz de cada frase do PAC·ENGLISH com o Google Cloud Text-to-Speech (vozes Chirp 3 HD, inglês americano).

Cada personagem tem SEMPRE a mesma voz (o aluno, Mike, Ana, Sarah…), e os exemplos da teoria têm a voz do narrador.
Frase com gravação de nativo do Tatoeba (campo "au") não é gerada: a gravação humana continua valendo.

Saída:
  assets/ingles/voz/<hash>.mp3     um arquivo por (voz, texto); rodar de novo só gera o que falta e apaga os órfãos
  assets/ingles/vozes.json         {texto em inglês: asset} — o app consulta depois da gravação de nativo
  tools/ingles/dados/vozes_google.json   quem fala com qual voz (para conferir/regerar)

Uso (rodar DEPOIS do integrar.py, na raiz do projeto; precisa do gcloud logado):
  python3 tools/ingles/vozes_google.py --gcp music-system-421ee
O projeto do Google Cloud só precisa ter a API Text-to-Speech ativa e faturamento (cabe na cota gratuita mensal).
"""
import argparse
import base64
import concurrent.futures as cf
import hashlib
import json
import os
import subprocess
import threading
import time
import urllib.error
import urllib.request

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CURRICULO = os.path.join(RAIZ, 'assets/ingles/curriculo.json')
PASTA = os.path.join(RAIZ, 'assets/ingles/voz')
INDICE = os.path.join(RAIZ, 'assets/ingles/vozes.json')
ELENCO_JSON = os.path.join(RAIZ, 'tools/ingles/dados/vozes_google.json')
API = 'https://texttospeech.googleapis.com/v1/text:synthesize'
PREFIXO = 'en-US-Chirp3-HD-'

# o elenco fixo (dono: "pode escolher sortido") — vozes diferentes para quem conversa muito entre si
ELENCO = {
    'voce': 'Orus',      # o aluno (Carlos, dev brasileiro)
    'mike': 'Puck',
    'ben': 'Fenrir',
    'lucas': 'Iapetus',
    'ana': 'Kore',
    'sarah': 'Aoede',
    'emma': 'Leda',
    'julia': 'Zephyr',
    'dra-lee': 'Sulafat',
    'narrador': 'Charon',  # exemplos da teoria e placas
    'placa': 'Charon',
}
MASCULINAS = ['Achird', 'Algenib', 'Algieba', 'Alnilam', 'Enceladus', 'Rasalgethi', 'Sadachbia', 'Sadaltager',
              'Schedar', 'Umbriel', 'Zubenelgenubi']
FEMININAS = ['Achernar', 'Autonoe', 'Callirrhoe', 'Despina', 'Erinome', 'Gacrux', 'Laomedeia', 'Pulcherrima',
             'Vindemiatrix']
# papéis menores: o gênero vem da palavra em português (recrutadora, diretor…); neutro sorteia pelo hash do papel
FEMININOS = {'recrutadora', 'diretora', 'moradora', 'engenheira', 'corretora', 'passageira', 'estagiaria', 'gestora',
             'farmaceutica', 'desenvolvedora', 'vizinha', 'esposa', 'mae', 'namorada', 'professora', 'medica',
             'enfermeira', 'chefe-dela', 'convidada', 'dev-nova', 'supervisora'}
MASCULINOS = {'entrevistador', 'proprietario', 'passageiro', 'vendedor', 'amigo-do-ben', 'convidado', 'marido',
              'engenheiro', 'dev-novo', 'dev-junior', 'pai', 'irmao', 'professor', 'medico'}


def _h(s):
    return int(hashlib.sha1(s.encode()).hexdigest(), 16)


def voz_do_papel(papel):
    if papel in ELENCO:
        return ELENCO[papel]
    if papel in FEMININOS or papel.endswith(('ora', 'eira', 'ada', '-nova')):
        pool = FEMININAS
    elif papel in MASCULINOS or papel.endswith('or') or papel.endswith('eiro'):
        pool = MASCULINAS
    else:
        pool = MASCULINAS + FEMININAS
    return pool[_h(papel) % len(pool)]


class Token:
    """Token do gcloud, renovado a cada 40 min (vale 1 h)."""

    def __init__(self):
        self._t, self._em, self._lock = None, 0, threading.Lock()

    def __call__(self):
        with self._lock:
            if not self._t or time.time() - self._em > 2400:
                self._t = subprocess.check_output(['gcloud', 'auth', 'print-access-token'], text=True).strip()
                self._em = time.time()
            return self._t


def sintetizar(texto, voz, gcp, token):
    corpo = json.dumps({
        'input': {'text': texto},
        'voice': {'languageCode': 'en-US', 'name': PREFIXO + voz},
        'audioConfig': {'audioEncoding': 'MP3'},
    }).encode()
    for tentativa in range(8):
        req = urllib.request.Request(API, data=corpo, headers={
            'Authorization': 'Bearer ' + token(), 'x-goog-user-project': gcp, 'Content-Type': 'application/json'})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return base64.b64decode(json.load(r)['audioContent'])
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 503) and tentativa < 7:
                time.sleep(min(60, 2 ** tentativa))
                continue
            raise RuntimeError(f'{e.code} {e.read()[:300]!r} em {texto!r}')
        except (urllib.error.URLError, TimeoutError):
            time.sleep(min(60, 2 ** tentativa))
    raise RuntimeError(f'sem resposta para {texto!r}')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--gcp', required=True, help='projeto do Google Cloud com a API Text-to-Speech ativa')
    ap.add_argument('--paralelo', type=int, default=6)
    ap.add_argument('--limite', type=int, default=0, help='gera só N arquivos (teste)')
    a = ap.parse_args()

    trilhas = json.load(open(CURRICULO, encoding='utf-8'))
    pedidos = {}  # texto → papel (a 1ª fala vale; o mesmo texto não muda de voz)
    papeis = {}
    for t in trilhas:
        for l in t['licoes']:
            for f in l['trechos']:
                papel = f.get('quem') or 'narrador'
                papeis.setdefault(papel, voz_do_papel(papel))
                if not f.get('au'):
                    pedidos.setdefault(f['cod'].strip(), papel)
    nativas = {f['cod'].strip() for t in trilhas for l in t['licoes'] for f in l['trechos'] if f.get('au')}
    for t in trilhas:
        for l in t['licoes']:
            for b in l.get('teoria') or []:
                if isinstance(b, dict) and b.get('t') == 'ex':
                    en = b['c'].split('\n')[0].strip()
                    if en and en not in nativas:
                        pedidos.setdefault(en, 'narrador')
    papeis.setdefault('narrador', ELENCO['narrador'])

    os.makedirs(PASTA, exist_ok=True)
    indice, faltam = {}, []
    for texto, papel in sorted(pedidos.items()):
        voz = voz_do_papel(papel)
        nome = hashlib.sha1(f'{voz}|{texto}'.encode()).hexdigest()[:14] + '.mp3'
        indice[texto] = f'assets/ingles/voz/{nome}'
        if not os.path.exists(os.path.join(PASTA, nome)):
            faltam.append((texto, voz, nome))
    if a.limite:
        faltam = faltam[:a.limite]
    letras = sum(len(t) for t, _, _ in faltam)
    print(f'{len(pedidos)} textos · {len(faltam)} para gerar ({letras} letras) · {len(papeis)} papéis')

    token, feitos, erros = Token(), [0], []
    lock = threading.Lock()

    def gera(item):
        texto, voz, nome = item
        try:
            mp3 = sintetizar(texto, voz, a.gcp, token)
            tmp = os.path.join(PASTA, nome + '.tmp')
            open(tmp, 'wb').write(mp3)
            os.replace(tmp, os.path.join(PASTA, nome))
        except Exception as e:  # noqa: BLE001 — registra e segue; rodar de novo completa
            with lock:
                erros.append(str(e))
        with lock:
            feitos[0] += 1
            if feitos[0] % 200 == 0:
                print(f'  {feitos[0]}/{len(faltam)}', flush=True)

    with cf.ThreadPoolExecutor(a.paralelo) as ex:
        list(ex.map(gera, faltam))

    # só entra no índice o que existe em disco; órfãos (texto que saiu do curso) saem
    indice = {t: p for t, p in indice.items() if os.path.exists(os.path.join(RAIZ, p))}
    usados = {os.path.basename(p) for p in indice.values()}
    orfaos = [n for n in os.listdir(PASTA) if n.endswith('.mp3') and n not in usados]
    if not a.limite:
        for n in orfaos:
            os.remove(os.path.join(PASTA, n))
    json.dump(dict(sorted(indice.items())), open(INDICE, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    json.dump({'vozes': {p: PREFIXO + v for p, v in sorted(papeis.items())}, 'gcp_api': 'texttospeech v1',
               'total': len(indice)}, open(ELENCO_JSON, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    tam = sum(os.path.getsize(os.path.join(PASTA, n)) for n in usados if os.path.exists(os.path.join(PASTA, n)))
    print(f'índice: {len(indice)} textos · {tam / 1e6:.1f} MB · {len(erros)} erro(s)'
          + ('' if a.limite else f' · {len(orfaos)} órfão(s) apagado(s)'))
    for e in erros[:10]:
        print('  ERRO', e)
    return 1 if erros else 0


if __name__ == '__main__':
    raise SystemExit(main())
