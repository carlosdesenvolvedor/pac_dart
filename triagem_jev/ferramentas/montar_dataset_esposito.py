#!/usr/bin/env python3
"""Monta o arquivo de triagem a partir do pacote de replicação de Esposito et al. (2025),
"Generative AI for Software Architecture" (JSS; arXiv 2503.13310; Zenodo 10.5281/zenodo.15032395).

O pacote traz a triagem por título e resumo de TODOS os candidatos, com o voto dos revisores:
630 artigos (com resumo) e 438 itens de literatura cinzenta (URL e título). O gabarito é a coluna
"Included by T/A". A literatura cinzenta não tem resumo: o script baixa a página e guarda um trecho
do texto (as páginas podem ter mudado desde a triagem deles; sem página, fica só o título).

Uso:
  python3 -I ferramentas/montar_dataset_esposito.py "Replication Package.xlsx" saida.json [--brancos 290] [--cinzentos 210] [--semente 42]
"""
import html.parser
import json
import random
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET
import zipfile
from concurrent.futures import ThreadPoolExecutor

NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
      "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships"}

# Tabela 2 do artigo: o critério de inclusão (já na forma positiva). Os de exclusão da triagem por
# título e resumo são de forma (idioma, duplicata, acesso) ou "fora do tópico", que é o I1 ao contrário.
CRITERIOS = [{
    "id": "I1",
    "texto": "Papers should specifically use LLM or Generative AI for Software architecture "
             "(e.g., architectural design, decision-making, modeling, documentation, analysis, evaluation, "
             "migration or maintenance of software architecture).",
}]


def planilhas(caminho):
    z = zipfile.ZipFile(caminho)
    ss = [''.join(t.text or '' for t in si.iter('{%s}t' % NS['m']))
          for si in ET.fromstring(z.read('xl/sharedStrings.xml')).findall('m:si', NS)]
    rels = {r.get('Id'): r.get('Target') for r in ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))}

    def col(ref):
        n = 0
        for ch in re.match(r'[A-Z]+', ref).group():
            n = n * 26 + ord(ch) - 64
        return n - 1

    for sh in ET.fromstring(z.read('xl/workbook.xml')).find('m:sheets', NS):
        alvo = rels[sh.get('{%s}id' % NS['r'])]
        raiz = ET.fromstring(z.read('xl/' + alvo.lstrip('/').replace('xl/', '')))
        linhas = []
        for r in raiz.findall('.//m:sheetData/m:row', NS):
            vals = {}
            for c in r.findall('m:c', NS):
                v = c.find('m:v', NS)
                if v is not None:
                    vals[col(c.get('r'))] = ss[int(v.text)] if c.get('t') == 's' else v.text
                elif c.find('m:is', NS) is not None:
                    vals[col(c.get('r'))] = ''.join(x.text or '' for x in c.find('m:is', NS).iter('{%s}t' % NS['m']))
            if vals:
                linhas.append([vals.get(i, '') for i in range(max(vals) + 1)])
        yield sh.get('name'), linhas


class _Texto(html.parser.HTMLParser):
    """Texto visível dos parágrafos e títulos de uma página (sem script, estilo, menu e rodapé)."""

    def __init__(self):
        super().__init__()
        self.partes, self.pilha, self.desc = [], [], ''

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == 'meta' and (a.get('name') or a.get('property') or '').lower() in ('description', 'og:description'):
            self.desc = self.desc or (a.get('content') or '')
        self.pilha.append(tag)

    def handle_endtag(self, tag):
        while self.pilha and self.pilha.pop() != tag:
            pass

    def handle_data(self, data):
        if any(t in ('script', 'style', 'nav', 'footer', 'header', 'noscript', 'svg') for t in self.pilha):
            return
        if self.pilha and self.pilha[-1] in ('p', 'li', 'h1', 'h2', 'h3', 'blockquote'):
            t = ' '.join(data.split())
            if len(t) > 30:
                self.partes.append(t)


def trecho(url):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (triagem-jev; pesquisa academica)'})
        with urllib.request.urlopen(req, timeout=15) as r:
            if 'html' not in (r.headers.get('content-type') or ''):
                return ''
            p = _Texto()
            p.feed(r.read(800_000).decode('utf-8', 'replace'))
        texto = ' '.join(p.partes) or p.desc
        return texto[:1500].strip()
    except Exception:  # noqa: BLE001 — página fora do ar, bloqueada ou PDF: fica só o título
        return ''


def main():
    args = sys.argv[1:]
    opc = {args[i][2:]: args[i + 1] for i in range(len(args) - 1) if args[i].startswith('--')}
    nb, nc, semente = int(opc.get('brancos', 290)), int(opc.get('cinzentos', 210)), int(opc.get('semente', 42))
    folhas = dict(planilhas(args[0]))

    brancos = [r for r in folhas['White_Literature_Process'][2:] if len(r) > 9 and r[9] in ('0', '1') and r[1].strip()]
    cinzentos = [r for r in folhas['Grey_Literature_Process'][2:] if len(r) > 6 and r[6] in ('0', '1') and r[1].strip()]

    def sortear(linhas, n, idx):
        """Sorteio estratificado: mantém a proporção de incluídos da triagem original."""
        rnd = random.Random(semente)
        pos = [r for r in linhas if r[idx] == '1']
        neg = [r for r in linhas if r[idx] == '0']
        k = round(n * len(pos) / len(linhas))
        return rnd.sample(pos, k) + rnd.sample(neg, n - k)

    sb, sc = sortear(brancos, nb, 9), sortear(cinzentos, nc, 6)
    print(f'brancos: {len(brancos)} triados → {len(sb)} sorteados ({sum(r[9] == "1" for r in sb)} incluídos)', file=sys.stderr)
    print(f'cinzentos: {len(cinzentos)} triados → {len(sc)} sorteados ({sum(r[6] == "1" for r in sc)} incluídos)', file=sys.stderr)

    with ThreadPoolExecutor(16) as ex:
        textos = list(ex.map(trecho, [r[0] for r in sc]))
    print(f'cinzentos com texto da página: {sum(bool(t) for t in textos)}/{len(sc)}', file=sys.stderr)

    estudos = []
    for r in sb:
        estudos.append({'id': f'W{len(estudos) + 1:03d}', 'titulo': r[1].strip(), 'resumo': (r[4] or '').strip(),
                        'palavras_chave': [], 'tipo_fonte': 'artigo', 'url': '', 'ano': r[2], 'veiculo': r[3],
                        'gabarito': 'incluir' if r[9] == '1' else 'excluir'})
    for r, t in zip(sc, textos):
        estudos.append({'id': f'G{len(estudos) - len(sb) + 1:03d}', 'titulo': r[1].strip(), 'resumo': t,
                        'palavras_chave': [], 'tipo_fonte': 'literatura_cinzenta', 'url': r[0].strip(),
                        'busca': r[2], 'gabarito': 'incluir' if r[6] == '1' else 'excluir'})
    random.Random(semente).shuffle(estudos)

    saida = {
        'projeto': 'Esposito et al. (2025), GenAI para arquitetura de software: 500 itens com a triagem humana',
        'fonte': {
            'revisao': 'Esposito, M. et al. Generative AI for Software Architecture. Applications, Challenges, and '
                       'Future Directions. Journal of Systems and Software, 2025. arXiv 2503.13310.',
            'pacote': 'https://doi.org/10.5281/zenodo.15032395 (Replication Package.xlsx)',
            'gabarito': 'coluna "Included by T/A" (dois revisores; um terceiro resolve divergências)',
            'amostra': f'sorteio estratificado, semente {semente}: {nb} de {len(brancos)} artigos e {nc} de {len(cinzentos)} itens de literatura cinzenta',
            'literatura_cinzenta': 'trecho da página baixado em 29/10/2026; a página pode ter mudado desde a triagem original',
        },
        'criterios': CRITERIOS,
        'estudos': estudos,
    }
    json.dump(saida, open(args[1], 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(f'{len(estudos)} itens → {args[1]}', file=sys.stderr)


if __name__ == '__main__':
    main()
