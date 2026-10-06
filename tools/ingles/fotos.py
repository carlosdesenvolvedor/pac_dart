#!/usr/bin/env python3
"""Fotos reais das cenas do PAC·ENGLISH (Unsplash, licença Unsplash: uso livre, crédito ao fotógrafo).

1) folhas:   python3 tools/ingles/fotos.py folhas <candidatos.json> <pasta_saida>
   Baixa as miniaturas (até 9 por cena) e monta <pasta>/folhas/<chave>.jpg — grade 3×3 numerada 1..9
   para quem escolhe olhar uma imagem só por cena.
2) consolidar: python3 tools/ingles/fotos.py consolidar <candidatos.json> <pasta_escolhas> <escolhas.json>
   Junta os lotes dos agentes ({"<chave>": {"n", "reserva", "motivo"}}) num {"<chave>": n}; se a mesma foto
   foi escolhida para duas cenas, a segunda fica com a reserva (ou sem foto).
3) baixar:   python3 tools/ingles/fotos.py baixar <candidatos.json> <escolhas.json> <pasta_fotos>
   escolhas = {"<chave>": n (1..9) ou 0 = nenhuma}. Baixa a escolhida em 800×500 (recorte central,
   JPEG ~q62) como <pasta_fotos>/<chave>.jpg e grava/atualiza <pasta_fotos>/creditos.json
   ({"<chave>.jpg": "Nome Sobrenome / Unsplash"}).

Os candidatos vêm da busca do site (feita no Chrome do dono): {"<chave>": [{id, autor, usuario, w, h, alt,
raw (https://images.unsplash.com/photo-…), q}]}. Fotos premium (Unsplash+) já vêm filtradas.
"""
import io, json, os, sys, urllib.request
from concurrent.futures import ThreadPoolExecutor

from PIL import Image, ImageDraw, ImageFont

UA = {'User-Agent': 'Mozilla/5.0 (Macintosh) pac-dart-curso/1.0'}


def baixa(url, tentativas=3):
    for _ in range(tentativas):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=40) as r:
                return r.read()
        except Exception:
            pass
    return None


def fonte(tam):
    for f in ['/System/Library/Fonts/Supplemental/Arial Bold.ttf', '/System/Library/Fonts/Helvetica.ttc']:
        if os.path.exists(f):
            try:
                return ImageFont.truetype(f, tam)
            except Exception:
                pass
    return ImageFont.load_default()


def folha(chave, cands, pasta):
    destino = os.path.join(pasta, 'folhas', f'{chave}.jpg')
    if os.path.exists(destino):
        return destino
    W, H, pad = 320, 200, 6
    img = Image.new('RGB', (3 * W + 4 * pad, 3 * H + 4 * pad), (20, 20, 20))
    d = ImageDraw.Draw(img)
    f = fonte(34)
    urls = [c['raw'] + f'?w={W}&h={H}&fit=crop&q=60&fm=jpg' for c in cands[:9]]
    with ThreadPoolExecutor(9) as ex:
        dados = list(ex.map(baixa, urls))
    for i, b in enumerate(dados):
        x, y = pad + (i % 3) * (W + pad), pad + (i // 3) * (H + pad)
        if b:
            try:
                t = Image.open(io.BytesIO(b)).convert('RGB').resize((W, H))
                img.paste(t, (x, y))
            except Exception:
                pass
        d.rectangle([x, y, x + 46, y + 44], fill=(255, 199, 59))
        d.text((x + 12, y + 3), str(i + 1), fill=(0, 0, 0), font=f)
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    img.save(destino, quality=72)
    return destino


def cmd_folhas(cand_arq, pasta):
    cands = json.load(open(cand_arq, encoding='utf-8'))
    feitas = 0
    with ThreadPoolExecutor(4) as ex:
        for _ in ex.map(lambda kv: folha(kv[0], kv[1], pasta), [(k, v) for k, v in cands.items() if v]):
            feitas += 1
    vazias = [k for k, v in cands.items() if not v]
    print(f'{feitas} folhas em {pasta}/folhas' + (f'; sem candidatos: {", ".join(vazias)}' if vazias else ''))


def cmd_consolidar(cand_arq, pasta_esc, saida):
    cands = json.load(open(cand_arq, encoding='utf-8'))
    lotes = {}
    for a in sorted(os.listdir(pasta_esc)):
        if a.endswith('.json'):
            lotes.update(json.load(open(os.path.join(pasta_esc, a), encoding='utf-8')))
    usadas, final, trocas, sem = set(), {}, 0, []
    for chave in cands:  # na ordem do curso: a cena que vem antes fica com a foto
        e = lotes.get(chave) or {}
        lista = cands.get(chave) or []
        escolhida = 0
        for k, n in enumerate([e.get('n', 0), e.get('reserva', 0)]):
            n = int(n or 0)
            if 1 <= n <= len(lista) and lista[n - 1]['id'] not in usadas:
                escolhida = n
                trocas += k
                break
        if escolhida:
            usadas.add(lista[escolhida - 1]['id'])
        else:
            sem.append(chave)
        final[chave] = escolhida
    json.dump(final, open(saida, 'w', encoding='utf-8'), indent=0)
    print(f'{len(final) - len(sem)}/{len(final)} cenas com foto ({trocas} pela reserva); sem foto: {len(sem)}')
    if sem:
        print('sem foto: ' + ', '.join(sem))


def cmd_baixar(cand_arq, esc_arq, pasta_fotos):
    cands = json.load(open(cand_arq, encoding='utf-8'))
    escolhas = json.load(open(esc_arq, encoding='utf-8'))
    os.makedirs(pasta_fotos, exist_ok=True)
    cred_arq = os.path.join(pasta_fotos, 'creditos.json')
    creditos = json.load(open(cred_arq, encoding='utf-8')) if os.path.exists(cred_arq) else {}
    tarefas = []
    for chave, n in escolhas.items():
        n = int(n) if str(n).isdigit() else 0
        lista = cands.get(chave) or []
        if n < 1 or n > len(lista):
            continue
        tarefas.append((chave, lista[n - 1]))

    def uma(t):
        chave, c = t
        b = baixa(c['raw'] + '?w=800&h=500&fit=crop&crop=entropy&q=62&fm=jpg')
        if not b:
            return chave, None
        with open(os.path.join(pasta_fotos, f'{chave}.jpg'), 'wb') as fp:
            fp.write(b)
        return chave, f"{c['autor']} / Unsplash"

    ok = 0
    with ThreadPoolExecutor(8) as ex:
        for chave, cred in ex.map(uma, tarefas):
            if cred:
                creditos[f'{chave}.jpg'] = cred
                ok += 1
    json.dump(creditos, open(cred_arq, 'w', encoding='utf-8'), ensure_ascii=False, indent=0, sort_keys=True)
    total = sum(os.path.getsize(os.path.join(pasta_fotos, a)) for a in os.listdir(pasta_fotos) if a.endswith('.jpg'))
    print(f'{ok}/{len(tarefas)} fotos baixadas · pasta com {total / 1e6:.1f} MB')


if __name__ == '__main__':
    if sys.argv[1] == 'folhas':
        cmd_folhas(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == 'consolidar':
        cmd_consolidar(sys.argv[2], sys.argv[3], sys.argv[4])
    elif sys.argv[1] == 'baixar':
        cmd_baixar(sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        print(__doc__)
