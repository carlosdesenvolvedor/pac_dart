#!/usr/bin/env python3
"""Lista as lições por cenário, lendo encenacao_auto.json (para a prova visual do 📺 e para revisar a tabela).

Uso:
    python3 -I listar_por_cenario.py                     → contagem por cenário + as 5 primeiras lições de cada
    python3 -I listar_por_cenario.py --cenario loja      → todas as lições de um cenário
    python3 -I listar_por_cenario.py --amostra [--url]   → UMA lição AUTOMÁTICA por cenário + uma com figurante
                                                            falando (atendente…), para as screenshots do probe
Opções: --tabela CAMINHO (padrão: encenacao_auto.json desta pasta; no repo, assets/ingles/historias/)
        --curriculo CAMINHO · --url (imprime a URL do probe: /?licao=<id>#/assistir-en)
        --todas (na --amostra, aceita também lições de trilhas que já têm história autoral)

"Automática" = a trilha da lição NÃO tem <slug>.json autoral ao lado da tabela (nem no indice.json): é o
EncenadorLicao que monta o palco. A escolha da --amostra é determinística (a 1ª lição na ordem do curso que
tenha o maior número de falantes no palco, até 4, para a screenshot mostrar mais de um personagem).
"""
import json
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
_REPO = os.path.normpath(os.path.join(AQUI, '..', '..', '..'))
if not os.path.isfile(os.path.join(_REPO, 'assets', 'ingles', 'curriculo.json')):
    _REPO = '/Users/fazplay/pac_dart'
CURRICULO = os.path.join(_REPO, 'assets', 'ingles', 'curriculo.json')
ELENCO_DAS_LICOES = {'voce', 'mike', 'sarah', 'ana', 'ben', 'emma', 'lucas', 'julia', 'dra-lee'}


def padrao_tabela():
    for p in (os.path.join(AQUI, 'encenacao_auto.json'), os.path.join(_REPO, 'assets', 'ingles', 'historias', 'encenacao_auto.json')):
        if os.path.isfile(p):
            return p
    return os.path.join(AQUI, 'encenacao_auto.json')


def autorais(pasta):
    r = set()
    try:
        r |= set((json.load(open(os.path.join(pasta, 'indice.json'), encoding='utf-8')).get('trilhas') or {}).keys())
    except (OSError, ValueError):
        pass
    for f in os.listdir(pasta):
        if f.endswith('.json') and f not in ('indice.json', 'encenacao_auto.json', 'exemplo_licao.json'):
            r.add(f[:-5])
    return r


def main(argv):
    args = argv[1:]

    def opc(nome, padrao):
        if nome in args:
            k = args.index(nome)
            v = args[k + 1]
            del args[k:k + 2]
            return v
        return padrao

    tabela = opc('--tabela', padrao_tabela())
    curriculo = opc('--curriculo', CURRICULO)
    cenario = opc('--cenario', None)
    url = '--url' in args
    try:
        tab = json.load(open(tabela, encoding='utf-8'))['licoes']
    except (OSError, ValueError, KeyError) as e:
        print(f'tabela ilegível ({tabela}): {e}', file=sys.stderr)
        return 2
    licoes = [l for t in json.load(open(curriculo, encoding='utf-8')) for l in t['licoes']]
    por_id = {l['id']: l for l in licoes}
    com_historia = autorais(os.path.dirname(os.path.abspath(tabela)))

    def linha(lid):
        e = tab[lid]
        l = por_id.get(lid)
        extra = []
        if e.get('remotos'):
            extra.append('remotos ' + ','.join(e['remotos']))
        if e.get('entram'):
            extra.append('entram ' + ','.join(e['entram']))
        if e.get('mudos'):
            extra.append('mudos ' + ','.join(e['mudos']))
        marca = ' ✨' if lid.split('.')[0] in com_historia else ''
        nome = f" — {l['emoji']} {l['nome']}" if l else ''
        s = f"  {lid}{marca} [{e['hora']}{'; ' + '; '.join(extra) if extra else ''}]{nome}"
        return s + (f'\n      /?licao={lid}#/assistir-en' if url else '')

    grupos = {}
    for lid in [l['id'] for l in licoes if l['id'] in tab]:
        grupos.setdefault(tab[lid]['cenario'], []).append(lid)
    if cenario:
        ids = grupos.get(cenario, [])
        print(f'{cenario}: {len(ids)} lições')
        for lid in ids:
            print(linha(lid))
        return 0 if ids else 1
    if '--amostra' in args:
        todas = '--todas' in args

        def falantes(lid):
            q = {x['quem'] for x in por_id[lid]['trechos'] if x['quem'] not in ('', 'placa')}
            return q - set(tab[lid].get('remotos', {}))

        print('Amostra (uma automática por cenário):')
        for cen in sorted(grupos, key=lambda c: -len(grupos[c])):
            cand = [x for x in grupos[cen] if todas or x.split('.')[0] not in com_historia]
            if not cand:
                continue
            escolha = max(cand, key=lambda x: (min(len(falantes(x)), 4), -grupos[cen].index(x)))
            print(f'- {cen} ({len(grupos[cen])} no total)')
            print(linha(escolha))
        fig = [x for x in tab if (todas or x.split('.')[0] not in com_historia)
               and any(q not in ELENCO_DAS_LICOES and q not in ('', 'placa') for q in falantes(x))]
        alvo = next((x for x in fig if any(q == 'atendente' for q in falantes(x))), fig[0] if fig else None)
        if alvo:
            print('- com figurante falando')
            print(linha(alvo))
        return 0
    total = sum(len(v) for v in grupos.values())
    print(f'{total} lições em {len(grupos)} cenários ({tabela})')
    for cen in sorted(grupos, key=lambda c: -len(grupos[c])):
        ids = grupos[cen]
        print(f'{cen}: {len(ids)}')
        for lid in ids[:5]:
            print(linha(lid))
        if len(ids) > 5:
            print(f'  … (+{len(ids) - 5}; use --cenario {cen})')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
