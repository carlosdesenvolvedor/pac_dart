#!/usr/bin/env python3
"""Monta o contexto de um lote de historinhas do 📺 Escutar assistindo: um contexto_<slug>.md por trilha, com
tudo o que o autor precisa ler (plano §10.2 passo 2). Só lê; não muda nada no projeto.

Uso:
    python3 -I montar_contexto_lote.py <slug> [<slug> ...] --saida PASTA
        [--curriculo CAMINHO] [--historias PASTA ...] [--tabela encenacao_auto.json]

Cada contexto traz: etapa e nível do palco; as trilhas vizinhas; o `arco` das 2 trilhas anteriores (se já
houver <slug>.json numa das pastas --historias: padrão = a --saida, esta pasta e assets/ingles/historias/ do
repo); o fio da etapa e o elenco (DESIGN.md §5.5) e as proibições (§5.7); os cenários e props PERMITIDOS (lidos
por regex de historia_turismo.dart, menos os do Turismo e os vetados pela receita); os figurantes conhecidos
(historia_licao.dart); as regras L-* em resumo; o exemplo oficial (exemplo_licao.json); e, por lição: id, nome,
cena, visualização, emojis, foto, falantes (com a 1ª frase de cada um), a sugestão da encenação automática
(encenacao_auto.json) e a tabela das frases (id, quem, img, cod, dica, contexto, 🎙️ = gravação do Tatoeba).
"""
import importlib.util
import json
import os
import re
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location('vhl', os.path.join(AQUI, 'validar_historias_licoes.py'))
V = importlib.util.module_from_spec(spec)
spec.loader.exec_module(V)
REPO = V._REPO
DESIGN = os.path.join(REPO, 'tools', 'ingles', 'dados', 'DESIGN.md')
FIO_POR_ETAPA = {
    'A1': 'a primeira viagem a Chicago para conhecer o time (imigração, hotel, escritório, cidade)',
    'A2': 'os primeiros meses no emprego: viagens, saúde e rotina',
    'B1': 'a entrevista para uma vaga sênior e três meses no escritório de Austin',
    'B2': 'o time cresce (reuniões, code review, incidentes) e a vida prática nos EUA (carro, atendimento)',
    'C1': 'o aluno vira tech lead e tem vida social com os americanos',
    'DEV': 'um dia inteiro de tech lead (entrevista sênior, design, review, incidentes, clientes)',
}
CENARIOS_BONS = ['videochamada', 'escritorio', 'casa', 'restaurante', 'loja', 'copa', 'recepcaoHotel', 'salaDeEstar',
                 'aeroporto', 'hotel', 'clinica',
                 'cidade', 'praia', 'lago', 'ponte']


def secao(md, titulo, ate):
    m = re.search(re.escape(titulo) + r'\n(.*?)\n' + re.escape(ate), md, re.S)
    return m.group(1).strip() if m else None


def arco_de(slug, pastas):
    for p in pastas:
        arq = os.path.join(p, f'{slug}.json')
        if os.path.isfile(arq):
            try:
                return json.load(open(arq, encoding='utf-8')).get('arco')
            except ValueError:
                return None
    return None


def celula(s):
    return (s or '').replace('|', '/').replace('\n', ' ')


def contexto(slug, ts, ordem, pastas, tabela, design):
    _, D, _ = V.motor()
    C = V.consts_licao()
    i = ordem.index(slug)
    t = ts[slug]
    etapa = t['etapa']
    chave_etapa = etapa.split()[0].upper()
    out = [f'# Contexto do lote: trilha `{slug}` ({i + 1}ª de {len(ordem)})', '',
           '> Gerado por `montar_contexto_lote.py` (lê o currículo e o código; não muda nada). Leia junto com a '
           '`RECEITA.md` e o `PROMPT_LOTE.md`. Você ENCENA: o texto das falas vem do currículo pelo id.', '',
           f'- **Etapa:** {etapa} → nível do palco `{V.nivel_da_etapa(etapa)}` (só regula a velocidade do balão)',
           f'- **Trilha:** {t["emoji"]} {t["nivel"]} — {t["descricao"]}',
           f'- **Fio da etapa:** {FIO_POR_ETAPA.get(chave_etapa, "(ver DESIGN §5.5)")}',
           f'- **Anterior:** `{ordem[i - 1]}`' if i else '- **Anterior:** (nenhuma)',
           f'- **Próxima:** `{ordem[i + 1]}`' if i + 1 < len(ordem) else '- **Próxima:** (nenhuma)', '']
    arcos = [(ordem[k], arco_de(ordem[k], pastas)) for k in (i - 2, i - 1) if k >= 0]
    out.append('## Arco das trilhas anteriores (continuidade)')
    achou = False
    for s, a in arcos:
        if a:
            out.append(f'- `{s}`: {a}')
            achou = True
    if not achou:
        out.append('- (nenhuma das 2 anteriores tem história autoral ainda: comece o fio pela descrição da trilha)')
    out += ['', '## Elenco e ficha do aluno (DESIGN.md §5.5)']
    if design:
        s55 = secao(design, '### 5.5 Cenas, elenco, ficha do aluno e reciclagem', '### 5.6')
        if s55:
            bal = [b for b in s55.split('\n- ') if b.startswith(('**Elenco fixo', '**Ficha do aluno', '**Fio narrativo'))]
            out += ['- ' + b.strip() for b in bal]
    out += ['- **Nas lições valem:** ' + ', '.join(f'`{q}`' for q in sorted(C['elencoDasLicoes'])) +
            ' + quem fala na lição + até ' + str(C['maxFigurantesMudos']) + ' figurantes mudos desta lista: ' +
            ', '.join(f'`{q}`' for q in sorted(C['figurantesConhecidos'])) + '. **Max e Kim: nunca.**', '',
            '## Proibições (DESIGN.md §5.7)']
    if design:
        s57 = secao(design, '### 5.7 Proibições de conteúdo', '### 5.8')
        if s57:
            out.append(s57)
    vetados = V.CENARIOS_VETADOS | C['cenariosSoDoTurismo']
    props = [p for p in D['PropHistoria'] if p not in C['propsSoDoTurismo'] and p not in V.PROPS_EVITADAS and p != 'nada']
    out += ['', '## Listas permitidas (lidas do código)',
            '- **Cenários:** ' + ', '.join(f'`{c}`' for c in CENARIOS_BONS if c in D['CenarioHistoria']) +
            ' (nunca: ' + ', '.join(f'`{c}`' for c in D['CenarioHistoria'] if c in vetados) + ')',
            '- **Horas:** ' + ', '.join(f'`{h}`' for h in D['HoraHistoria']) + ' · **Clima** nos interiores: só `chuva`/`neve`.',
            '- **Props:** ' + ', '.join(f'`{p}`' for p in props) + ' (`"nada"` esvazia a mão, só em passo ou reação)',
            '- **Ações:** ' + ', '.join(f'`{a}`' for a in D['AcaoAtor'] if a not in ('dirige', 'desce')) +
            ' — deslocam (só em passo mudo): ' + ', '.join(f'`{a}`' for a in sorted(C['acoesQueDeslocam']) if a not in ('dirige', 'desce')),
            '- **Emoções:** ' + ', '.join(f'`{e}`' for e in D['Expressao']),
            '- **Efeitos:** ' + ', '.join(f'`{e}`' for e in D['EfeitoHistoria'] if e not in V.EFEITOS_EVITADOS),
            '- **Câmeras:** ' + ', '.join(f'`{c}`' for c in D['CameraHistoria'] if c not in V.CAMERAS_EVITADAS) +
            ' (`dupla` exige `alvo` ator; `close` ≤ 2 por lição; `tremida` ≤ 1 por trilha)',
            '- **Posições:** ' + ', '.join(f'`{p}`' for p in D['PosicaoPalco']), '',
            '## Regras que o validador cobra (resumo da §5.3 do plano; detalhe na RECEITA §6)',
            '- toda frase da lição exatamente uma vez, NA ORDEM, como `{"frase": "<id>"}`; âncora sem `en`/`pt`/`pt_f`/`mudo`;'
            ' passo com texto e sem `frase` = erro (ligações só atuadas);',
            '- `titulo` obrigatório (`en` 1–6 palavras ASCII, sem marca/cidade proibida; `pt` não vazio);',
            f'- 1–2 cenas, cada uma com ≥ 1 âncora; mudos ≤ 3 por cena, ≤ 2 seguidos, ≤ {C["maxMudosPorHistoria"]} na lição;',
            '- âncora nunca com `entra`/`anda`/`corre`/`sai`; elenco ≤ 5 presentes com `pos` única; ≤ 2 remotos (só `celular`,'
            ' alguém no palco segurando `celular` enquanto o remoto fala; remoto só `parado`); videochamada sem remoto;',
            '- toda a simulação do palco do Turismo (quem está invisível só `entra`; `alvo` visível; `mostra`/`escreve` com prop…);',
            '- receita: fecho com sorriso; nada de cenário vetado, `fogos`/`relampago`/`fumaca`/`estrelaCadente`, `panoramica`.', '']
    out += ['## Exemplo oficial (plano §5.4, passa com 0 erros)', '', '```json',
            open(os.path.join(AQUI, 'exemplo_licao.json'), encoding='utf-8').read().rstrip(), '```', '']
    for l in t['licoes']:
        trechos = l['trechos']
        ordem_falantes = []
        for k, x in enumerate(trechos):
            q = V.quem_no_palco(x['quem'])
            if q not in [a for a, _ in ordem_falantes]:
                ordem_falantes.append((q, k + 1))
        cods = {x['cod']: k + 1 for k, x in enumerate(trechos)}
        sug = (tabela or {}).get(l['id'])
        sug_txt = '(sem entrada)' if not sug else ' · '.join(
            [f"`{sug['cenario']}`/`{sug['hora']}`"] +
            ([f"remotos: {', '.join(sug['remotos'])}"] if sug.get('remotos') else []) +
            ([f"entram tarde: {', '.join(sug['entram'])}"] if sug.get('entram') else []) +
            ([f"presentes sem falar: {', '.join(sug['mudos'])}"] if sug.get('mudos') else []))
        out += [f'## `{l["id"]}` — {l["emoji"]} {l["nome"]}', '',
                f'- **cena:** {l["cena"]}',
                f'- **visualização (foto):** {l.get("visualizacao", "")}',
                f'- **emojis:** {l.get("imagem", "")} · **foto:** `{os.path.basename(l.get("foto") or "") or "(sem foto)"}`',
                '- **falantes (1ª frase):** ' + ', '.join(f'{q} (#{n})' for q, n in ordem_falantes),
                f'- **encenação automática hoje (encenacao_auto.json):** {sug_txt}',
                f'- **frases:** {len(trechos)}', '',
                '| # | frase (id) | quem | img | cod (EN, não mexer) | dica (PT) | contexto (fala do outro) |',
                '|---|---|---|---|---|---|---|']
        for k, x in enumerate(trechos, 1):
            ctx = x.get('contexto') or ''
            if ctx:
                ctx = f'↩ #{cods[ctx]}' if ctx in cods else f'«{celula(ctx)}» (fora do texto)'
            au = ' 🎙️' if x.get('au') else ''
            out.append(f'| {k} | `{x["id"]}` | {x["quem"] or "(placa)"}{au} | {x.get("img", "")} | {celula(x["cod"])} | '
                       f'{celula(V.dica_plana(x["dica"]))} | {ctx} |')
        out.append('')
    out += ['🎙️ = a frase toca uma gravação humana do Tatoeba (a voz pode não ser a do personagem; decisão do dono, '
            'plano D19). Não muda a encenação.', '']
    return '\n'.join(out)


def main(argv):
    args = argv[1:]

    def opc(nome, padrao):
        if nome in args:
            k = args.index(nome)
            v = args[k + 1]
            del args[k:k + 2]
            return v
        return padrao

    curriculo = opc('--curriculo', V.CURRICULO)
    saida = opc('--saida', None)
    tab = opc('--tabela', None)
    if tab is None:  # ao lado das ferramentas (scratchpad) ou no asset do app (repo, depois da integração)
        tab = next((p for p in (os.path.join(AQUI, 'encenacao_auto.json'),
                                os.path.join(REPO, 'assets', 'ingles', 'historias', 'encenacao_auto.json'))
                    if os.path.isfile(p)), os.path.join(AQUI, 'encenacao_auto.json'))
    pastas = []
    while '--historias' in args:
        pastas.append(opc('--historias', None))
    slugs = [a for a in args if not a.startswith('--')]
    if not slugs or not saida:
        print(__doc__, file=sys.stderr)
        return 2
    tr = json.load(open(curriculo, encoding='utf-8'))
    ordem = [V.slug_da_licao(t['licoes'][0]['id']) for t in tr if t.get('licoes')]
    ts = V.trilhas_por_slug(curriculo)
    pastas = pastas or [saida, AQUI, os.path.join(REPO, 'assets', 'ingles', 'historias')]
    try:
        tabela = json.load(open(tab, encoding='utf-8')).get('licoes')
    except (OSError, ValueError):
        tabela = None
    design = open(DESIGN, encoding='utf-8').read() if os.path.isfile(DESIGN) else None
    os.makedirs(saida, exist_ok=True)
    for s in slugs:
        if s not in ts:
            print(f'trilha {s!r} não existe no currículo', file=sys.stderr)
            return 2
        arq = os.path.join(saida, f'contexto_{s}.md')
        texto = contexto(s, ts, ordem, pastas, tabela, design)
        open(arq, 'w', encoding='utf-8').write(texto)
        print(f'{arq} ({len(ts[s]["licoes"])} lições, {len(texto) // 1024} KB)')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
