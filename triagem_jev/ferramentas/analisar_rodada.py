#!/usr/bin/env python3
"""Analisa um resultado.json do processador em lote (app/bin/triagem_lote.dart) contra o gabarito.

Uso:
  python3 -I ferramentas/analisar_rodada.py resultado.json dados.json [--alvo 0.95] > analise.json

Saída (JSON): para cada sinal do modelo de decisão, a curva recall × fração lida e o ponto de corte
com recall >= alvo; para cada LLM sozinho, recall, precisão, fração que ele manda ler, custo e
tempo; AUC; e tudo separado por artigo / literatura cinzenta com texto / só título.
"""
import json
import sys


def tipo(estudo):
    if estudo.get("tipo_fonte") == "artigo":
        return "artigo"
    return "cinza_texto" if estudo.get("resumo") else "cinza_titulo"


def auc(pontos):
    """AUC pela estatística de Mann-Whitney: chance de um incluído ter nota maior que um excluído."""
    pos = [s for s, g in pontos if g]
    neg = [s for s, g in pontos if not g]
    if not pos or not neg:
        return None
    ganhos = sum((p > n) + 0.5 * (p == n) for p in pos for n in neg)
    return ganhos / (len(pos) * len(neg))


def main():
    args = sys.argv[1:]
    alvo = float(args[args.index("--alvo") + 1]) if "--alvo" in args else 0.95
    r = json.load(open(args[0], encoding="utf-8"))
    dados = {e["id"]: e for e in json.load(open(args[1], encoding="utf-8"))["estudos"]}
    linhas = [x for x in r["por_estudo"] if x["gabarito"] in ("incluir", "excluir") and "prob_inclusao" in x["jev"]]
    n = len(linhas)
    pos_total = sum(x["gabarito"] == "incluir" for x in linhas)
    llms = sorted({m for x in linhas for m in (x.get("llm") or {})})

    def lik(x):
        pc = x["jev"]["por_criterio"]
        return ((pc[0]["likert_esperado"] or 1) - 1) / 6 if pc else 0.0

    sinais = {
        "pergunta_geral": lambda x: x["jev"]["prob_inclusao"],
        "likert_criterio": lik,
        "nota_1_7": lambda x: ((x["jev"]["nota"] or 1) - 1) / 6,
    }

    def avaliar(sel, grupo=None):
        base = [x for x in linhas if grupo is None or tipo(dados[x["id"]]) == grupo]
        p = sum(x["gabarito"] == "incluir" for x in base)
        seg = [x for x in base if sel(x)]
        vp = sum(x["gabarito"] == "incluir" for x in seg)
        return {
            "n": len(base), "incluidos": p, "seguem": len(seg), "vp": vp,
            "recall": vp / p if p else None,
            "precisao": vp / len(seg) if seg else None,
            "fracao_lida": len(seg) / len(base) if base else None,
        }

    saida = {"itens": n, "incluidos": pos_total, "alvo_recall": alvo, "sinais": {}, "llms": {}, "custos": {}}
    for nome, f in sinais.items():
        cortes = sorted({round(f(x), 4) for x in linhas}, reverse=True)
        curva, escolhido = [], None
        for t in cortes:
            a = avaliar(lambda x, t=t: f(x) >= t)
            curva.append({"corte": t, "recall": a["recall"], "fracao_lida": a["fracao_lida"]})
            if escolhido is None and a["recall"] >= alvo:
                escolhido = t
        saida["sinais"][nome] = {
            "auc": auc([(f(x), x["gabarito"] == "incluir") for x in linhas]),
            "corte_alvo": escolhido,
            "no_corte": {g or "todos": avaliar(lambda x: f(x) >= escolhido, g) for g in (None, "artigo", "cinza_texto", "cinza_titulo")},
            "curva": curva,
        }
    for m in llms:
        segue = lambda x, m=m: ((x["llm"].get(m) or {}).get("sugestao") or "incerto") != "excluir"
        cus = sum((x["llm"].get(m) or {}).get("custo_usd") or 0 for x in linhas)
        ms = sum((x["llm"].get(m) or {}).get("ms") or 0 for x in linhas)
        saida["llms"][m] = {
            "sozinho": {g or "todos": avaliar(segue, g) for g in (None, "artigo", "cinza_texto", "cinza_titulo")},
            "custo_usd": cus, "tempo_ms": ms, "custo_por_item": cus / n, "ms_por_item": ms / n,
        }
    cj = sum(x["jev"]["custo_usd"] or 0 for x in linhas)
    mj = sum(x["jev"]["ms"] or 0 for x in linhas)
    saida["custos"]["jev"] = {"custo_usd": cj, "tempo_ms": mj, "custo_por_item": cj / n, "ms_por_item": mj / n}

    # Jev no corte calibrado (pergunta geral) → LLM só nos que seguem → pesquisador.
    t = saida["sinais"]["pergunta_geral"]["corte_alvo"]
    seg = [x for x in linhas if x["jev"]["prob_inclusao"] >= t]
    for m in llms:
        cus = cj + sum((x["llm"].get(m) or {}).get("custo_usd") or 0 for x in seg)
        ms = mj + sum((x["llm"].get(m) or {}).get("ms") or 0 for x in seg)
        so = saida["llms"][m]
        saida["llms"][m]["com_jev"] = {
            "corte": t, "itens_ao_llm": len(seg), "custo_usd": cus, "tempo_ms": ms,
            "custo_relativo": cus / so["custo_usd"] if so["custo_usd"] else None,
            "tempo_relativo": ms / so["tempo_ms"] if so["tempo_ms"] else None,
            # Para 1.000 itens e 6 rodadas (o grupo usa de 6 a 10), proporcional ao medido.
            "mil_6_rodadas_usd": cus / n * 1000 * 6, "so_mil_6_rodadas_usd": so["custo_usd"] / n * 1000 * 6,
            "mil_6_rodadas_h": ms / n * 1000 * 6 / 3.6e6, "so_mil_6_rodadas_h": so["tempo_ms"] / n * 1000 * 6 / 3.6e6,
        }
    json.dump(saida, sys.stdout, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
