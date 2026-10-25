# Sessão na nuvem — 🎓 aulas longas do Prof. Beto (B2, C1 e DEV)

Você trabalha no repositório `pac_dart` (app Flutter "Paclingo", curso de inglês para brasileiros). As aulas
faladas do professor (6 a 10 minutos por lição) já estão prontas no A1 e o dono aprovou o nível; o A2 e o B1 estão
sendo escritos na máquina do dono. **Você escreve as aulas de um bloco de trilhas** (o bloco vem no fim do pedido:
`BLOCO=B2` ou `BLOCO=C1+DEV`).

## Leia antes
- `tools/ingles/aulas/PROMPT_AULAS.md` — o pedido ao AUTOR (1º bloco) e ao REVISOR (último bloco). Siga à risca.
- `tools/ingles/aulas/exemplo_aula.json` — uma aula pronta (do A1: copie tom e estrutura; a profundidade é a do nível).
- `tools/ingles/aulas/validar_aulas.py` — o validador (o docstring tem o formato).

## Preparar
```
git checkout -b claude/aulas-b2        # ou claude/aulas-c1-dev
LOTE=/tmp/aulas_lote
python3 -I tools/ingles/aulas/montar_contexto.py --etapa B2 --saida $LOTE          # BLOCO=B2
python3 -I tools/ingles/aulas/montar_contexto.py --etapa C1 --saida $LOTE          # BLOCO=C1+DEV
python3 -I tools/ingles/aulas/montar_contexto.py --etapa DEV --saida $LOTE         #   (as duas)
```
O comando imprime as trilhas do bloco (slug e número de lições), na ordem do curso.

## Para CADA trilha: 3 subagentes em sequência (Agent tool), até 5 trilhas ao mesmo tempo
Em todos: `$A = tools/ingles/aulas` (caminho absoluto no seu clone), `$LOTE = /tmp/aulas_lote`, `<SLUG>` = a trilha,
`<NIVEL>` = o nível dela (B2 · Desenvoltura, C1 · Domínio ou DEV · Inglês profissional de dev). Os subagentes
escrevem SÓ em `$LOTE/<SLUG>.json`. Validador: `python3 -I $A/validar_aulas.py $LOTE/<SLUG>.json`.

1. **Autor** — "Siga o bloco do autor de `$A/PROMPT_AULAS.md` para a trilha <SLUG> (nível <NIVEL>). Aulas de VERDADE
   de 6 a 10 minutos cada (mire em 7 a 9), com muitos detalhes e curiosidades garantidas, figuras na lousa quando
   o professor cita uma coisa (a foto da cena e emojis), partes com nome, desafios com pausa. Abra a FOTO de cada
   lição com Read antes de contar a cena. Escreva uma lição por vez no mesmo JSON e rode o validador até ✓."
2. **Revisor** — "Siga o bloco do REVISOR de `$A/PROMPT_AULAS.md` para <SLUG> (nível <NIVEL>); leia também
   `$LOTE/contexto_<SLUG>.md`. Se faltar lição, escreva-a pelo bloco do autor. Confira duração (6 a 10 min) e
   nível (nem infantil, nem acima do aluno). Corrija direto no arquivo; validador até ✓."
3. **Verificador (adversarial)** — "O autor e o revisor já passaram; parta do princípio de que há erro. Fala por
   fala: (1) cada curiosidade, fato de cultura, etimologia, diferença EUA/Reino Unido, costume de trabalho —
   tente REFUTAR; se você não confirmaria em Oxford, Merriam-Webster, Cambridge ou Etymonline, corte ou troque
   por algo garantido (nada de números, datas, estatísticas, anedotas incertas); (2) regras de gramática e uso
   certas para o nível, sem simplificação que vira erro; (3) cada "en" correto e natural, "tr" fiel, frases da
   lição copiadas exatas; (4) pronúncia descrita em português, nunca escrita com letras do português, nenhum
   inglês no "pt"; (5) figura combina, desafio com a resposta logo depois, duração 6 a 10 min. Corrija direto
   no arquivo; validador até ✓. Responda: válido sim/não, correções curtas por lição, dúvidas para o dono."

Quando o verificador terminar e o validador der ✓: copie `$LOTE/<SLUG>.json` para `assets/ingles/aulas/<SLUG>.json`,
faça commit (`🎓 Aula longa: <slug> (<nível>)`) e **push na hora** (o dono puxa aos poucos). Se uma trilha não
fechar ✓ depois de uma rodada extra de correção, pule-a e anote no relatório.

## Regras
- **Não** mexa em `assets/ingles/aulas/indice.json`, em `web/aula_voz/`, no validador, no PROMPT_AULAS.md, no
  currículo nem em código do app. **Não** rode `tools/ingles/aulas/vozes_aula.py` nem `bocas_rhubarb.py` (as
  vozes e as bocas são feitas na máquina do dono). **Não** faça deploy, não mexa no `main`.
- Se o validador barrar uma palavra que é nome próprio ou que o brasileiro fala em português, reescreva a fala
  (ponha o termo no "quadro" ou numa fala "en") e anote a palavra no relatório.
- Se achar erro no currículo (frase, tradução, teoria), não repita o erro na aula e anote no relatório.
- Não precisa de Flutter para esta tarefa.

## Ao terminar
Escreva `planejamento/RELATORIO-NUVEM-AULAS-<BLOCO>.md` na mesma branch: por trilha, ✓ ou o que faltou, a duração
de cada aula (`python3 -c` com `validar_aulas.minutos`), as correções do verificador em 1 linha e TODAS as dúvidas
para o dono. Commit e push.
