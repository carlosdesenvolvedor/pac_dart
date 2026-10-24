"""Monta o contexto (markdown) de cada trilha para o autor das AULAS DO PROFESSOR.

Uso:
  python3 -I tools/ingles/aulas/montar_contexto.py --etapa A1 --saida PASTA      (todas as trilhas do A1)
  python3 -I tools/ingles/aulas/montar_contexto.py slug1 slug2 --saida PASTA
Escreve PASTA/contexto_<slug>.md e imprime a lista de slugs (na ordem do curso). Só lê o currículo.
"""
import argparse
import json
import os

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
CURRICULO = os.path.join(RAIZ, 'assets', 'ingles', 'curriculo.json')


def slug_de(t):
    return t['licoes'][0]['id'].split('.')[0]


def contexto(t, anteriores):
    linhas = [f'# Trilha `{slug_de(t)}` — {t["emoji"]} {t["nivel"]} ({t["etapa"]})', '', t.get('descricao', ''), '']
    if anteriores:
        linhas += ['Trilhas que o aluno JÁ fez antes desta (pode citar o que ele já sabe):',
                   ', '.join(anteriores), '']
    for l in t['licoes']:
        linhas += [f'## Lição `{l["id"]}` — {l["emoji"]} {l["nome"]}', '']
        if l.get('cena'):
            linhas.append(f'- **Cena:** {l["cena"]}')
        if l.get('resumo'):
            linhas.append(f'- **Resumo:** {l["resumo"]}')
        if l.get('teoria'):
            linhas += ['- **Teoria escrita que já existe (não repita palavra por palavra; a aula é falada):**']
            for b in l['teoria']:
                c = b['c'].replace('\n', ' / ')
                linhas.append(f'  - [{b["t"]}] {c}')
        linhas += ['', '| quem | inglês (cod — copie EXATO se usar num "en") | português | alvo | nota do autor |',
                   '|---|---|---|---|---|']
        for tr in l['trechos']:
            cel = [tr.get('quem', ''), tr['cod'], tr.get('dica', ''), tr.get('alvo', ''), tr.get('conceito', '')]
            linhas.append('| ' + ' | '.join(str(c).replace('|', '/').replace('\n', ' ') for c in cel) + ' |')
        linhas.append('')
    return '\n'.join(linhas)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('slugs', nargs='*')
    ap.add_argument('--etapa')
    ap.add_argument('--saida', required=True)
    a = ap.parse_args()
    with open(CURRICULO, encoding='utf-8') as f:
        trilhas = [t for t in json.load(f) if t['licoes']]
    os.makedirs(a.saida, exist_ok=True)
    feitas = []
    for t in trilhas:
        s = slug_de(t)
        quer = (a.etapa and t['etapa'].upper().startswith(a.etapa.upper())) or s in a.slugs
        if quer:
            with open(os.path.join(a.saida, f'contexto_{s}.md'), 'w', encoding='utf-8') as f:
                f.write(contexto(t, list(feitas)))
            print(s, len(t['licoes']))
        feitas.append(f'{t["nivel"]} ({s})')


if __name__ == '__main__':
    main()
