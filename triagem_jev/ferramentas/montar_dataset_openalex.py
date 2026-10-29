#!/usr/bin/env python3
"""Monta um arquivo de triagem (o formato de app/assets/exemplo_triagem.json) com estudos reais do
OpenAlex e o gabarito de uma revisão sistemática publicada.

Uso:
  python3 -I ferramentas/montar_dataset_openalex.py config.json saida.json

config.json:
  {
    "projeto": "DDD em arquitetura de software (gabarito: <revisão>)",
    "buscas": ["\"domain-driven design\"", "\"domain driven design\" microservices"],
    "anos": [2003, 2023],              # período da revisão
    "alvo": 1000,                      # quantos estudos no total (os incluídos sempre entram)
    "criterios": [{"id": "C1", "texto": "..."}],
    "gabarito": "gabarito-incluidos.json"   # {"incluidos": [{"titulo", "ano", "doi"}]}
  }

Cada busca vai no filtro title_and_abstract.search do OpenAlex, só obras com resumo, ordenadas por
relevância. Os estudos incluídos pela revisão viram gabarito "incluir"; os demais, "excluir" (é uma
aproximação: a revisão não publicou a decisão de cada candidato, só a lista final).
"""
import difflib
import json
import re
import sys
import time
import urllib.parse
import urllib.request

API = "https://api.openalex.org/works"
CAMPOS = "id,doi,title,abstract_inverted_index,publication_year,type,keywords,primary_location,relevance_score"


def obter(url):
    for tentativa in range(5):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "triagem-jev/0.1"}), timeout=60) as r:
                return json.load(r)
        except Exception as e:  # noqa: BLE001 — rede instável: tenta de novo
            if tentativa == 4:
                raise
            time.sleep(2 ** tentativa)
            print(f"  nova tentativa ({e})", file=sys.stderr)


def resumo(inv):
    if not inv:
        return ""
    pos = {}
    for palavra, idxs in inv.items():
        for i in idxs:
            pos[i] = palavra
    return " ".join(pos[i] for i in sorted(pos))


def normal(t):
    return re.sub(r"[^a-z0-9]+", " ", (t or "").lower()).strip()


def buscar(busca, anos, maximo):
    filtro = f"title_and_abstract.search:{busca},has_abstract:true,publication_year:{anos[0]}-{anos[1]}"
    cursor, obras = "*", []
    while cursor and len(obras) < maximo:
        q = urllib.parse.urlencode({"filter": filtro, "select": CAMPOS, "per-page": 200, "cursor": cursor, "sort": "relevance_score:desc"})
        d = obter(f"{API}?{q}")
        obras += d["results"]
        cursor = d["meta"].get("next_cursor")
        print(f"  {busca}: {len(obras)} de {d['meta']['count']}", file=sys.stderr)
        if not d["results"]:
            break
    return obras


def por_doi_ou_titulo(inc):
    if inc.get("doi"):
        doi = inc["doi"].lower().removeprefix("https://doi.org/")
        d = obter(f"{API}?{urllib.parse.urlencode({'filter': f'doi:{doi}', 'select': CAMPOS})}")
        if d["results"]:
            return d["results"][0]
    t = inc.get("titulo", "")
    q = urllib.parse.urlencode({"filter": f"title.search:{t[:180]}", "select": CAMPOS, "per-page": 5})
    for o in obter(f"{API}?{q}")["results"]:
        if difflib.SequenceMatcher(None, normal(o.get("title")), normal(t)).ratio() > 0.9:
            return o
    return None


def main():
    cfg = json.load(open(sys.argv[1], encoding="utf-8"))
    incluidos = json.load(open(cfg["gabarito"], encoding="utf-8"))["incluidos"]
    anos, alvo = cfg["anos"], cfg["alvo"]

    pool = {}
    for b in cfg["buscas"]:
        for o in buscar(b, anos, alvo * 2):
            pool.setdefault(o["id"], o)
    print(f"candidatos únicos nas buscas: {len(pool)}", file=sys.stderr)

    # Os incluídos da revisão: acha cada um no pool (DOI ou título) ou busca direto no OpenAlex.
    dois = {(o.get("doi") or "").lower(): k for k, o in pool.items() if o.get("doi")}
    titulos = {normal(o.get("title")): k for k, o in pool.items()}
    positivos, nao_achados = set(), []
    for inc in incluidos:
        doi = ("https://doi.org/" + inc["doi"].lower().removeprefix("https://doi.org/")) if inc.get("doi") else ""
        k = dois.get(doi) or titulos.get(normal(inc.get("titulo")))
        if not k:
            o = por_doi_ou_titulo(inc)
            if o and o.get("abstract_inverted_index"):
                pool[o["id"]] = o
                k = o["id"]
        if k:
            positivos.add(k)
        else:
            nao_achados.append(inc.get("titulo"))

    # Os incluídos sempre entram; o resto, por relevância, até o alvo.
    resto = sorted((k for k in pool if k not in positivos), key=lambda k: -(pool[k].get("relevance_score") or 0))
    escolhidos = list(positivos) + resto[: max(0, alvo - len(positivos))]
    escolhidos.sort(key=lambda k: -(pool[k].get("relevance_score") or 0))

    estudos = []
    for i, k in enumerate(escolhidos, 1):
        o = pool[k]
        fonte = (o.get("primary_location") or {}).get("source") or {}
        estudos.append({
            "id": f"S{i:04d}",
            "titulo": (o.get("title") or "").strip(),
            "resumo": resumo(o.get("abstract_inverted_index")),
            "palavras_chave": [kw.get("display_name") for kw in (o.get("keywords") or [])][:8],
            "tipo_fonte": "artigo",
            "url": o.get("doi") or o["id"],
            "ano": o.get("publication_year"),
            "veiculo": fonte.get("display_name"),
            "openalex": o["id"],
            "gabarito": "incluir" if k in positivos else "excluir",
        })
    saida = {
        "projeto": cfg["projeto"],
        "fonte": {"base": "OpenAlex", "buscas": cfg["buscas"], "anos": anos, "gabarito": cfg["gabarito"],
                  "incluidos_na_revisao": len(incluidos), "incluidos_achados": len(positivos), "nao_achados": nao_achados},
        "criterios": cfg["criterios"],
        "estudos": estudos,
    }
    json.dump(saida, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"{len(estudos)} estudos · {len(positivos)}/{len(incluidos)} incluídos da revisão achados · "
          f"{len(nao_achados)} não achados → {sys.argv[2]}", file=sys.stderr)


if __name__ == "__main__":
    main()
