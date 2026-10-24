#!/usr/bin/env python3
"""Gera a VOZ do professor nas 🎓 aulas (Google Cloud Text-to-Speech, Chirp 3 HD): as falas em português com a voz
pt-BR dele e os exemplos em inglês com a mesma voz em en-US (o mesmo timbre nos dois idiomas).

Entrada: assets/ingles/aulas/<slug>.json (todas as trilhas do indice.json).
Saída:
  assets/ingles/voz_aula/<hash>.mp3     um por (voz, idioma, texto); rodar de novo só gera o que falta e apaga os órfãos
  assets/ingles/vozes_aula.json         {"pt|texto": asset, "en|texto": asset} — o app toca isto
Depois: python3 -I tools/ingles/bocas_rhubarb.py (a boca do professor; o português vai com o reconhecedor fonético).

Uso (na raiz do projeto, com o gcloud logado):
  python3 tools/ingles/aulas/vozes_aula.py --gcp music-system-421ee [--seco] [--limite N]
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

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
AULAS = os.path.join(RAIZ, 'assets/ingles/aulas')
PASTA = os.path.join(RAIZ, 'assets/ingles/voz_aula')
PREFIXO_ASSET = 'assets/ingles/voz_aula/'
INDICE = os.path.join(RAIZ, 'assets/ingles/vozes_aula.json')
API = 'https://texttospeech.googleapis.com/v1/text:synthesize'

# o Prof. Beto: a voz "Sadaltager" (Chirp 3 HD), nos dois idiomas
VOZ = 'Sadaltager'
IDIOMA = {'pt': 'pt-BR', 'en': 'en-US'}


class Token:
    def __init__(self):
        self._t, self._em, self._lock = None, 0, threading.Lock()

    def __call__(self):
        with self._lock:
            if not self._t or time.time() - self._em > 2400:
                self._t = subprocess.check_output(['gcloud', 'auth', 'print-access-token'], text=True).strip()
                self._em = time.time()
            return self._t


def sintetizar(texto, lingua, gcp, token):
    codigo = IDIOMA[lingua]
    corpo = json.dumps({
        'input': {'text': texto},
        'voice': {'languageCode': codigo, 'name': f'{codigo}-Chirp3-HD-{VOZ}'},
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


def universo():
    """{"pt|texto" / "en|texto": (lingua, texto)} de todas as aulas do índice."""
    with open(os.path.join(AULAS, 'indice.json'), encoding='utf-8') as f:
        slugs = list(json.load(f)['trilhas'])
    r = {}
    for s in slugs:
        with open(os.path.join(AULAS, f'{s}.json'), encoding='utf-8') as f:
            dados = json.load(f)
        for aula in dados['licoes'].values():
            for fala in aula['falas']:
                lingua = 'en' if 'en' in fala else 'pt'
                texto = fala[lingua].strip()
                r[f'{lingua}|{texto}'] = (lingua, texto)
    return r


def nome_mp3(lingua, texto):
    return hashlib.sha1(f'{VOZ}|{lingua}|{texto}'.encode()).hexdigest()[:14] + '.mp3'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--gcp', required=True)
    ap.add_argument('--paralelo', type=int, default=6)
    ap.add_argument('--limite', type=int, default=0)
    ap.add_argument('--seco', action='store_true')
    a = ap.parse_args()
    pedidos = universo()
    if not pedidos:
        print('nenhuma fala: nada a fazer')
        return 1
    indice, falta = {}, {}
    for chave, (lingua, texto) in sorted(pedidos.items()):
        nome = nome_mp3(lingua, texto)
        indice[chave] = PREFIXO_ASSET + nome
        if not os.path.exists(os.path.join(PASTA, nome)):
            falta[nome] = (lingua, texto)
    usados = {os.path.basename(v) for v in indice.values()}
    existentes = [n for n in os.listdir(PASTA) if n.endswith('.mp3')] if os.path.isdir(PASTA) else []
    orfaos = sorted(n for n in existentes if n not in usados)
    letras = sum(len(t) for _, t in falta.values())
    print(f'aulas: {len(pedidos)} falas · faltam {len(falta)} ({letras} letras) · {len(orfaos)} órfão(s)')
    if a.seco:
        return 0
    itens = list(falta.items())
    if a.limite:
        itens = itens[:a.limite]
    token, erros, lock = Token(), [], threading.Lock()
    os.makedirs(PASTA, exist_ok=True)

    def gera(item):
        nome, (lingua, texto) = item
        try:
            mp3 = sintetizar(texto, lingua, a.gcp, token)
            tmp = os.path.join(PASTA, nome + '.tmp')
            with open(tmp, 'wb') as f:
                f.write(mp3)
            os.replace(tmp, os.path.join(PASTA, nome))
        except Exception as e:  # noqa: BLE001 — registra e segue; rodar de novo completa
            with lock:
                erros.append(str(e))

    with cf.ThreadPoolExecutor(a.paralelo) as ex:
        list(ex.map(gera, itens))
    if erros:
        print(f'{len(erros)} erro(s); o índice NÃO foi escrito. Primeiro: {erros[0]}')
        return 1
    if a.limite:
        print(f'gerados {len(itens)} (teste: índice e órfãos intocados)')
        return 0
    for n in orfaos:
        os.remove(os.path.join(PASTA, n))
    with open(INDICE, 'w', encoding='utf-8') as f:
        json.dump(indice, f, ensure_ascii=False, indent=0, sort_keys=True)
        f.write('\n')
    print(f'ok: {len(indice)} falas no índice, {len(itens)} geradas, {len(orfaos)} órfão(s) apagados')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
