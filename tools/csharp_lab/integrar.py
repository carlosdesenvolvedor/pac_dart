#!/usr/bin/env python3
"""Junta as trilhas validadas (trilhas/NN-id.json) e os desafios (desafios/NN-id.json)
no asset do app: assets/csharp/curriculo.json. Confere metas e duplicatas.

uso: python3 integrar.py [--saida CAMINHO] [--minimo 4708]
"""
import argparse
import collections
import glob
import json
import os
import re
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
PROJETO = '/Users/fazplay/pac_dart'
CAMPOS_LAB = {'entrada', 'permitir'}  # só servem ao laboratório


def ler(caminho):
    with open(caminho, encoding='utf-8') as f:
        return json.load(f)


def limpar(obj):
    if isinstance(obj, dict):
        return {k: limpar(v) for k, v in obj.items() if k not in CAMPOS_LAB}
    if isinstance(obj, list):
        return [limpar(x) for x in obj]
    return obj


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--saida', default=os.path.join(PROJETO, 'assets/csharp/curriculo.json'))
    ap.add_argument('--minimo', type=int, default=4708)
    ap.add_argument('--seco', action='store_true', help='só mostra os números, não grava')
    a = ap.parse_args()

    arquivos = sorted(glob.glob(os.path.join(AQUI, 'trilhas', '[0-9][0-9]-*.json')))
    if not arquivos:
        sys.exit('nenhuma trilha em trilhas/')
    trilhas = []
    problemas = []
    for arq in arquivos:
        base = os.path.basename(arq)
        t = ler(arq)
        if isinstance(t, list):
            t = t[0]
        rel = arq + '.relatorio.txt'
        if not os.path.exists(rel) or 'RESULTADO: OK' not in open(rel, encoding='utf-8').read():
            problemas.append(f'{base}: sem relatório OK do laboratório')
        dfile = os.path.join(AQUI, 'desafios', base)
        if os.path.exists(dfile):
            d = ler(dfile)
            t['desafios'] = d['desafios'] if isinstance(d, dict) else d
            reld = dfile + '.desafios.txt'
            if not os.path.exists(reld) or 'RESULTADO: OK' not in open(reld, encoding='utf-8').read():
                problemas.append(f'{base}: desafios sem relatório OK')
        else:
            problemas.append(f'{base}: sem arquivo de desafios')
        trilhas.append(limpar(t))

    # números
    L = sum(len(t['licoes']) for t in trilhas)
    E = sum(len(l['trechos']) for t in trilhas for l in t['licoes'])
    P = sum(len(t.get('projetos', [])) for t in trilhas)
    D = sum(len(t.get('desafios', [])) for t in trilhas)
    J = sum(1 for t in trilhas for d in t.get('desafios', []) if d.get('tema') == 'jogo')
    print(f'{len(trilhas)} trilhas · {L} lições · {E} exercícios · {P} projetos · {D} desafios ({J} de jogo)')
    por_etapa = collections.Counter(t.get('etapa') for t in trilhas)
    print('por etapa:', dict(por_etapa))
    for t in trilhas:
        e = sum(len(l['trechos']) for l in t['licoes'])
        print(f"  {t['emoji']} {t['nivel']:<24} {t.get('etapa',''):<13} {t.get('perfil',''):<10} "
              f"{len(t['licoes']):>2} lições {e:>4} ex {len(t.get('projetos', [])):>2} proj {len(t.get('desafios', [])):>3} desafios")

    # checagens globais
    nomes = collections.Counter(t['nivel'] for t in trilhas)
    for n, c in nomes.items():
        if c > 1:
            problemas.append(f'nome de trilha repetido: {n}')
    cods = collections.defaultdict(list)
    for ti, t in enumerate(trilhas):
        for li, l in enumerate(t['licoes']):
            for k, tr in enumerate(l['trechos']):
                cods[tr['cod']].append(f'{ti}:{li}:{k}')
    dups = {c: v for c, v in cods.items() if len(v) > 1}
    if dups:
        print(f'aviso: {len(dups)} códigos repetidos entre trilhas (ex.: {list(dups.items())[:3]})')
    etapas = ['Iniciante', 'Intermediário', 'Avançado', 'Sênior']
    ordem = [etapas.index(t.get('etapa')) if t.get('etapa') in etapas else -1 for t in trilhas]
    if ordem != sorted(ordem):
        problemas.append('etapas fora de ordem (a lista precisa ir de Iniciante a Sênior)')
    if E < a.minimo:
        problemas.append(f'só {E} exercícios (meta mínima {a.minimo})')

    if problemas:
        print('\nPROBLEMAS:')
        for p in problemas:
            print(' -', p)
    if a.seco:
        return
    os.makedirs(os.path.dirname(a.saida), exist_ok=True)
    with open(a.saida, 'w', encoding='utf-8') as f:
        json.dump(trilhas, f, ensure_ascii=False, separators=(',', ':'))
    print(f'\ngravado: {a.saida} ({os.path.getsize(a.saida) // 1024} KB)')


if __name__ == '__main__':
    main()
