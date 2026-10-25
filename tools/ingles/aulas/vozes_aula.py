#!/usr/bin/env python3
"""Gera a VOZ e a BOCA do professor nas 🎓 aulas (Google Cloud Text-to-Speech, Chirp 3 HD + Rhubarb Lip Sync): as
falas em português com a voz pt-BR dele e os exemplos em inglês com a mesma voz em en-US (o mesmo timbre nos dois
idiomas).

As aulas longas (5 a 10 minutos cada) passam de 200 MB de mp3: elas NÃO vão no pacote do app (o .aab da Play Store
estouraria) — ficam em web/, que o `flutter build web` copia para o site, e o app busca de lá (VozesAula).

Entrada: assets/ingles/aulas/<slug>.json (todas as trilhas do indice.json).
Saída:
  web/aula_voz/<hash>.mp3      um por (voz, idioma, texto); rodar de novo só gera o que falta e apaga os órfãos
  web/aula_voz/<slug>.json     {"pt|texto": ["<hash>.mp3", "<boca>"], "en|texto": [...]} — o app toca isto
A boca: o Rhubarb (tools/ingles/bocas_rhubarb.py), com o texto no inglês e o reconhecedor fonético no português.

Uso (na raiz do projeto, com o gcloud logado):
  python3 -I tools/ingles/aulas/vozes_aula.py --gcp music-system-421ee [--seco] [--limite N] [--sem-boca] [--so a,b]
--so: só essas trilhas (gera e escreve os índices delas; os órfãos ficam para a rodada completa).
"""
import argparse
import base64
import concurrent.futures as cf
import hashlib
import json
import os
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
sys.path.insert(0, os.path.join(RAIZ, 'tools', 'ingles'))
import bocas_rhubarb  # noqa: E402 — o mesmo processamento das outras bocas do app

AULAS = os.path.join(RAIZ, 'assets/ingles/aulas')
PASTA = os.path.join(RAIZ, 'web/aula_voz')
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
            with urllib.request.urlopen(req, timeout=90) as r:
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
    """{slug: {"pt|texto" / "en|texto": (lingua, texto)}} de todas as aulas do índice."""
    with open(os.path.join(AULAS, 'indice.json'), encoding='utf-8') as f:
        slugs = list(json.load(f)['trilhas'])
    r = {}
    for s in slugs:
        with open(os.path.join(AULAS, f'{s}.json'), encoding='utf-8') as f:
            dados = json.load(f)
        falas = r.setdefault(s, {})
        for aula in dados['licoes'].values():
            for fala in aula['falas']:
                lingua = 'en' if 'en' in fala else 'pt'
                texto = fala[lingua].strip()
                falas[f'{lingua}|{texto}'] = (lingua, texto)
    return r


def nome_mp3(lingua, texto):
    return hashlib.sha1(f'{VOZ}|{lingua}|{texto}'.encode()).hexdigest()[:14] + '.mp3'


def bocas_prontas():
    """{arquivo: boca} dos índices já escritos (rodar de novo não refaz a boca de quem não mudou)."""
    r = {}
    if not os.path.isdir(PASTA):
        return r
    for n in os.listdir(PASTA):
        if n.endswith('.json'):
            try:
                with open(os.path.join(PASTA, n), encoding='utf-8') as f:
                    for v in json.load(f).values():
                        if isinstance(v, list) and len(v) > 1 and v[1]:
                            r[v[0]] = v[1]
            except (OSError, ValueError):
                pass
    return r


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--gcp', required=True)
    ap.add_argument('--paralelo', type=int, default=6)
    ap.add_argument('--processos', type=int, default=max(1, (os.cpu_count() or 2) - 2))
    ap.add_argument('--rhubarb', default=bocas_rhubarb.RHUBARB_PADRAO)
    ap.add_argument('--limite', type=int, default=0)
    ap.add_argument('--seco', action='store_true')
    ap.add_argument('--sem-boca', action='store_true', help='só as vozes (a boca fica para a próxima rodada)')
    ap.add_argument('--so', default='', help='só estas trilhas (separadas por vírgula)')
    a = ap.parse_args()
    por_trilha = universo()
    so = [x for x in a.so.split(',') if x]
    if so:
        por_trilha = {k: v for k, v in por_trilha.items() if k in so}
    pedidos = {k: v for falas in por_trilha.values() for k, v in falas.items()}
    if not pedidos:
        print('nenhuma fala: nada a fazer')
        return 1
    falta = {}
    for chave, (lingua, texto) in sorted(pedidos.items()):
        nome = nome_mp3(lingua, texto)
        if not os.path.exists(os.path.join(PASTA, nome)):
            falta[nome] = (lingua, texto)
    usados = {nome_mp3(l, t) for l, t in pedidos.values()}
    existentes = [n for n in os.listdir(PASTA) if n.endswith('.mp3')] if os.path.isdir(PASTA) else []
    orfaos = [] if so else sorted(n for n in existentes if n not in usados)
    letras = sum(len(t) for _, t in falta.values())
    bocas = {k: v for k, v in bocas_prontas().items() if k in usados}
    sem_boca = len(usados) - len(bocas)
    print(f'aulas: {len(pedidos)} falas em {len(por_trilha)} trilhas · faltam {len(falta)} vozes ({letras} letras) · '
          f'{sem_boca} sem boca · {len(orfaos)} órfão(s)', flush=True)
    if a.seco:
        return 0
    itens = list(falta.items())
    if a.limite:
        itens = itens[:a.limite]
    token, erros, lock = Token(), [], threading.Lock()
    os.makedirs(PASTA, exist_ok=True)
    feitos = [0]

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
        with lock:
            feitos[0] += 1
            if feitos[0] % 200 == 0:
                print(f'voz {feitos[0]}/{len(itens)}', flush=True)

    with cf.ThreadPoolExecutor(a.paralelo) as ex:
        list(ex.map(gera, itens))
    if erros:
        print(f'{len(erros)} erro(s) de voz; os índices NÃO foram escritos. Primeiro: {erros[0]}')
        return 1
    if a.limite:
        print(f'gerados {len(itens)} (teste: índices e órfãos intocados)')
        return 0

    # a boca de cada mp3 novo (o português pelo reconhecedor fonético; o inglês com o texto)
    if not a.sem_boca:
        textos = {nome_mp3(l, t): (l, t) for l, t in pedidos.values()}
        fazer = [n for n in sorted(usados) if n not in bocas]
        print(f'bocas: {len(fazer)} a fazer com {a.processos} processos', flush=True)
        ruins = 0
        with cf.ProcessPoolExecutor(a.processos) as ex:
            futuros = {ex.submit(bocas_rhubarb.processa, a.rhubarb, os.path.relpath(os.path.join(PASTA, n), RAIZ),
                                 textos[n][1], textos[n][0] == 'pt'): n for n in fazer}
            for i, fu in enumerate(cf.as_completed(futuros), 1):
                try:
                    _, boca = fu.result()
                    bocas[futuros[fu]] = boca
                except Exception as e:  # noqa: BLE001 — uma boca ruim não derruba o lote (a boca pelo texto assume)
                    ruins += 1
                    print('ERRO boca', e, file=sys.stderr, flush=True)
                if i % 200 == 0:
                    print(f'boca {i}/{len(fazer)}', flush=True)
        print(f'bocas prontas ({ruins} erros)', flush=True)

    for n in orfaos:
        os.remove(os.path.join(PASTA, n))
    for slug, falas in por_trilha.items():
        indice = {}
        for chave, (lingua, texto) in sorted(falas.items()):
            nome = nome_mp3(lingua, texto)
            indice[chave] = [nome, bocas.get(nome, '')]
        with open(os.path.join(PASTA, f'{slug}.json'), 'w', encoding='utf-8') as f:
            json.dump(indice, f, ensure_ascii=False, separators=(',', ':'), sort_keys=True)
    for n in [] if so else os.listdir(PASTA):  # índice de trilha que saiu do curso
        if n.endswith('.json') and n[:-5] not in por_trilha:
            os.remove(os.path.join(PASTA, n))
    print(f'ok: {len(pedidos)} falas, {len(itens)} vozes geradas, {len(orfaos)} órfão(s) apagados, '
          f'{len(por_trilha)} índices em web/aula_voz/')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
