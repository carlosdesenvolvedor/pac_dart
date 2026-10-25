"""Gera a BOCA (lip sync) de cada áudio do PAC·ENGLISH com o Rhubarb Lip Sync (MIT, github.com/DanielSWolf/rhubarb-lip-sync).

Para cada mp3 (voz gerada do personagem em assets/ingles/vozes.json, falas da história do Turismo em
assets/ingles/vozes_historia.json e gravação de nativo — reserva — no campo `au` do currículo),
converte para wav 16 kHz com o ffmpeg e roda o Rhubarb com o TEXTO da frase (--dialogFile, bem mais preciso). O
resultado vai para assets/ingles/bocas.json:

  {"assets/ingles/voz/<hash>.mp3": "0X 9B 15E 41C …"}   (centésimos de segundo + visema A–H/X)

Rodar de novo só processa o que falta e apaga as entradas de áudios que não existem mais. Uso:

  python3 -I tools/ingles/bocas_rhubarb.py [--rhubarb CAMINHO] [--processos N] [--limite N]

Precisa do ffmpeg no PATH e do binário do Rhubarb (padrão: ~/development/rhubarb/rhubarb). ~4 s por frase por núcleo.
"""

import argparse
import json
import os
import subprocess
import sys
import tempfile
from concurrent.futures import ProcessPoolExecutor, as_completed

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CURRICULO = os.path.join(RAIZ, 'assets/ingles/curriculo.json')
VOZES = os.path.join(RAIZ, 'assets/ingles/vozes.json')
VOZES_HISTORIA = os.path.join(RAIZ, 'assets/ingles/vozes_historia.json')
# (🎓 a boca das aulas do professor sai junto com a voz: tools/ingles/aulas/vozes_aula.py, com fonetico=True no
# português — o reconhecedor de inglês do Rhubarb não serve para ele)
FONETICOS = set()
SAIDA = os.path.join(RAIZ, 'assets/ingles/bocas.json')
RHUBARB_PADRAO = os.path.expanduser('~/development/rhubarb/rhubarb')


def audios():
    """{asset: texto} de todas as falas com áudio."""
    r = {}
    with open(VOZES, encoding='utf-8') as f:
        for texto, asset in json.load(f).items():
            r[asset] = texto
    if os.path.exists(VOZES_HISTORIA):  # história do Turismo: chave "quem|texto"
        with open(VOZES_HISTORIA, encoding='utf-8') as f:
            for chave, asset in json.load(f).items():
                r[asset] = chave.split('|', 1)[1]
    with open(CURRICULO, encoding='utf-8') as f:
        cur = json.load(f)
    for trilha in cur if isinstance(cur, list) else cur['trilhas']:
        for licao in trilha['licoes']:
            for t in licao['trechos']:
                if t.get('au'):
                    r[t['au']] = t['cod']
    return {a: t for a, t in r.items() if os.path.exists(os.path.join(RAIZ, a))}


def compacta(cues):
    return ' '.join(f"{round(c['start'] * 100)}{c['value']}" for c in cues) + f" {round(cues[-1]['end'] * 100)}X" if cues else ''


def processa(rhubarb, asset, texto, fonetico=False):
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, 'a.wav')
        txt = os.path.join(tmp, 'a.txt')
        subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', os.path.join(RAIZ, asset), '-ar', '16000', '-ac', '1', wav],
                       check=True)
        with open(txt, 'w', encoding='utf-8') as f:
            f.write(texto)
        opcoes = ['-r', 'phonetic'] if fonetico else ['-d', txt]
        out = subprocess.run([rhubarb, '-q', '-f', 'json', '--extendedShapes', 'GHX', *opcoes, wav],
                             check=True, capture_output=True, text=True).stdout
    return asset, compacta(json.loads(out)['mouthCues'])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rhubarb', default=RHUBARB_PADRAO)
    ap.add_argument('--processos', type=int, default=max(1, (os.cpu_count() or 2) - 2))
    ap.add_argument('--limite', type=int, default=0, help='processa no máximo N novos (teste)')
    a = ap.parse_args()

    todos = audios()
    feitos = {}
    if os.path.exists(SAIDA):
        with open(SAIDA, encoding='utf-8') as f:
            feitos = {k: v for k, v in json.load(f).items() if k in todos}
    falta = [(asset, texto) for asset, texto in sorted(todos.items()) if asset not in feitos]
    if a.limite:
        falta = falta[:a.limite]
    print(f'{len(todos)} áudios, {len(feitos)} prontos, {len(falta)} a fazer com {a.processos} processos', flush=True)

    def salva():
        with open(SAIDA, 'w', encoding='utf-8') as f:
            json.dump(dict(sorted(feitos.items())), f, ensure_ascii=False, separators=(',', ':'))

    erros = 0
    with ProcessPoolExecutor(a.processos) as ex:
        futuros = [ex.submit(processa, a.rhubarb, asset, texto, asset in FONETICOS) for asset, texto in falta]
        for i, fu in enumerate(as_completed(futuros), 1):
            try:
                asset, boca = fu.result()
                feitos[asset] = boca
            except Exception as e:  # noqa: BLE001 — um áudio ruim não derruba o lote
                erros += 1
                print('ERRO', e, file=sys.stderr, flush=True)
            if i % 100 == 0:
                salva()
                print(f'{i}/{len(falta)}', flush=True)
    salva()
    print(f'pronto: {len(feitos)} bocas em {os.path.relpath(SAIDA, RAIZ)} ({erros} erros)')


if __name__ == '__main__':
    main()
