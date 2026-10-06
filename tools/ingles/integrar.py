#!/usr/bin/env python3
"""Monta assets/ingles/curriculo.json a partir das lições geradas (contrato do DESIGN.md §5.1).

    python3 tools/ingles/integrar.py <pasta_trilhas> <esboco.json> [--saida assets/ingles/curriculo.json]

<pasta_trilhas>/<id-da-trilha>/NN.json = uma lição. As trilhas entram na ORDEM do esboço (as que faltam são
puladas com aviso). Cada frase vira um Trecho do app: cod, dica, lit (sem o "[lit.: ...]"), conceito, alvo,
alvo_pt, contexto, quem, alt e src (atribuição do Tatoeba). A lição leva nome, emoji, cena, resumo e teoria.
"""
import json, os, re, sys

# fotos das cenas e créditos (gerados pelo workflow de fotos)
FOTOS = 'assets/ingles/fotos'
CREDITOS = {}
if os.path.exists(os.path.join(FOTOS, 'creditos.json')):
    CREDITOS = json.load(open(os.path.join(FOTOS, 'creditos.json'), encoding='utf-8'))


def limpa_lit(lit):
    lit = (lit or '').strip()
    m = re.match(r'^\[\s*lit\.?:\s*(.*?)\s*\]$', lit)
    return m.group(1) if m else lit


# ficha do aluno (DESIGN §5.5): {campo} → valor padrão (inglês no cod, português na dica)
PERFIL = {'nome': ('Carlos', 'Carlos'), 'sobrenome': ('Souza', 'Souza'), 'sobrenome_soletrado': ('S-O-U-Z-A', 'S-O-U-Z-A'),
          'cidade': ('Curitiba', 'Curitiba'), 'cidade_natal': ('Curitiba', 'Curitiba'),
          'idade': ('thirty-two', 'trinta e dois'), 'anos_dev': ('eight', 'oito')}


def perfil(texto, lingua):
    return re.sub(r'\{([a-z_]+)\}', lambda m: PERFIL.get(m.group(1), (m.group(0), m.group(0)))[lingua], texto or '')


def formas_aceitas(f, cod):
    """var (trocas locais de forma) e opcional (palavras que podem faltar) → frases inteiras aceitas."""
    trocas = []
    for v in f.get('var') or []:
        em = perfil(v.get('em', ''), 0)
        if em and em in cod:
            trocas.append([(em, perfil(a, 0)) for a in v.get('aceita') or []])
    for w in f.get('opcional') or []:
        trocas.append([(w + ' ', ''), (' ' + w, '')])
    saida = []
    for grupo in trocas:
        for de, para in grupo:
            alt = re.sub(r'\s+', ' ', cod.replace(de, para, 1)).strip()
            if alt != cod and alt not in saida:
                saida.append(alt)
    # combinação de duas trocas (ex.: forma plena + palavra opcional)
    if len(trocas) >= 2:
        for (d1, p1) in trocas[0]:
            for (d2, p2) in trocas[1]:
                alt = re.sub(r'\s+', ' ', cod.replace(d1, p1, 1).replace(d2, p2, 1)).strip()
                if alt != cod and alt not in saida:
                    saida.append(alt)
    return saida[:8]


def trecho(f, por_id):
    cod, dica = perfil(f['cod'], 0), perfil(f['dica'], 1)
    tr = {'cod': cod, 'dica': dica}
    if f.get('id'):
        tr['id'] = f['id']
    for de, para, lingua in [('conceito', 'conceito', 1), ('alvo', 'alvo', 0), ('alvo_pt', 'alvo_pt', 1), ('quem', 'quem', None)]:
        if f.get(de):
            tr[para] = perfil(f[de], lingua) if lingua is not None else f[de]
    ctx = f.get('contexto')
    if ctx:
        ref = por_id.get(ctx)
        if ref is not None:  # id da fala anterior: o app mostra o PT dela até ela ser concluída
            i, alvo = ref
            tr['contexto'] = perfil(alvo['cod'], 0)
            tr['contexto_pt'] = perfil(alvo['dica'], 1)
            tr['contexto_de'] = i
        else:
            tr['contexto'] = perfil(ctx, 0)
    if f.get('teste'):
        tr['teste'] = True
    if f.get('lit'):
        tr['lit'] = limpa_lit(f['lit'])
    alt = formas_aceitas(f, cod)
    if alt:
        tr['alt'] = alt
    if f.get('img'):
        tr['img'] = f['img']
    fo = f.get('fonte')
    if fo and str(f.get('origem', '')).startswith('tatoeba'):  # atribuição CC BY 2.0 FR
        pt_id = fo.get('pt_id')
        tr['src'] = ':'.join(['tatoeba', str(fo['en_id']), str(fo['en_autor']),
                              str(pt_id) if pt_id else '-', str(fo.get('pt_autor') or '-'),
                              '1' if fo.get('modificada') else '0'])
    return tr


def main():
    args = sys.argv[1:]
    saida = 'assets/ingles/curriculo.json'
    if '--saida' in args:
        i = args.index('--saida'); saida = args[i + 1]; del args[i:i + 2]
    # --etapas a1,a2: publica só esses níveis (o resto ainda está sendo gerado)
    etapas_ok = None
    if '--etapas' in args:
        i = args.index('--etapas'); etapas_ok = set(args[i + 1].split(',')); del args[i:i + 2]
    # --excluir t1,t2: trilhas que ficam de fora (incompletas); --previa a2: níveis ainda sem revisão
    excluir, previa = set(), set()
    if '--excluir' in args:
        i = args.index('--excluir'); excluir = set(args[i + 1].split(',')); del args[i:i + 2]
    if '--previa' in args:
        i = args.index('--previa'); previa = set(args[i + 1].split(',')); del args[i:i + 2]
    pasta, esboco_arq = args
    esboco = json.load(open(esboco_arq, encoding='utf-8'))
    etapas = {e['id']: e for e in esboco.get('etapas', [])}
    trilhas, faltam, incompletas = [], [], []
    for t in sorted(esboco['trilhas'], key=lambda x: x['ordem']):
        if etapas_ok is not None and t.get('etapa') not in etapas_ok:
            continue
        if t['id'] in excluir:
            continue
        dir_t = os.path.join(pasta, t['id'])
        arqs = sorted(a for a in os.listdir(dir_t) if re.match(r'^\d\d\.json$', a)) if os.path.isdir(dir_t) else []
        if not arqs:
            faltam.append(t['id']); continue
        n_plano = len(t.get('licoes') or []) or t.get('nLicoes') or len(arqs)
        if len(arqs) < n_plano:
            incompletas.append(f"{t['id']} ({len(arqs)}/{n_plano})")
        etapa = etapas.get(t.get('etapa'), {})
        # a faixa do mapa casa pelo id da etapa (a1 → "A1", dev → "DEV")
        cefr = str(t.get('etapa', '')).upper()
        trilha = {
            'nivel': t['nivel'], 'emoji': t['emoji'],
            'descricao': t.get('descricao', '') + (' (Prévia: frases ainda em revisão.)' if t.get('etapa') in previa else ''),
            # a faixa do mapa usa o nível no começo ("A1 · Fundação")
            'etapa': f"{cefr} · {etapa.get('nome', '')}".strip(' ·'),
            'fundo': t.get('fundo', ''),
            'licoes': [],
        }
        for a in arqs:
            l = json.load(open(os.path.join(dir_t, a), encoding='utf-8'))
            por_id = {f.get('id'): (i, f) for i, f in enumerate(l['trechos']) if f.get('id')}
            licao = {
                'id': l.get('id', ''), 'nome': l['nome'], 'emoji': l['emoji'], 'cena': l.get('cena', ''),
                'resumo': l.get('resumo', ''), 'teoria': l.get('teoria', []),
                'imagem': l.get('imagem', ''), 'visualizacao': l.get('visualizacao', ''),
                'trechos': [trecho(f, por_id) for f in l['trechos']],
            }
            # foto real da cena (assets/ingles/fotos/<id da lição>.jpg), escolhida pelo workflow de fotos
            nome_foto = f"{l.get('id', '')}.jpg"
            if os.path.exists(os.path.join(FOTOS, nome_foto)):
                licao['foto'] = f'assets/ingles/fotos/{nome_foto}'
                cred = CREDITOS.get(nome_foto)
                if cred:
                    licao['foto_credito'] = cred
            trilha['licoes'].append(licao)
        trilhas.append(trilha)
    os.makedirs(os.path.dirname(saida) or '.', exist_ok=True)
    json.dump(trilhas, open(saida, 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
    nl = sum(len(t['licoes']) for t in trilhas)
    nf = sum(len(l['trechos']) for t in trilhas for l in t['licoes'])
    nt = sum(1 for t in trilhas for l in t['licoes'] for f in l['trechos'] if 'src' in f)
    print(f'{len(trilhas)} trilhas · {nl} lições · {nf} frases ({nt} do Tatoeba) → {saida}')
    if faltam:
        print(f'faltam {len(faltam)} trilhas: {", ".join(faltam)}')
    if incompletas:
        print(f'incompletas: {", ".join(incompletas)}')


if __name__ == '__main__':
    main()
