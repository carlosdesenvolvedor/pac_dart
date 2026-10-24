# PROMPT_AULAS — autor (e revisor) das 🎓 Aulas do Professor

> **Para o lead:** `python3 -I tools/ingles/aulas/montar_contexto.py --etapa A1 --saida $LOTE` gera um
> `contexto_<slug>.md` por trilha. Um autor por grupo de trilhas (≈20 lições), depois um revisor (bloco do fim).
> Os agentes escrevem SÓ em `$LOTE/<slug>.json`; o lead valida, copia para `assets/ingles/aulas/`, atualiza o
> `indice.json` e gera as vozes (`vozes_aula.py`) e as bocas (`bocas_rhubarb.py`).

---

```
Você vai escrever as AULAS DO PROFESSOR das lições das trilhas <SLUGS> do curso de inglês do Paclingo
(app brasileiro, aluno adulto que fala português e é iniciante: nível A1).

O QUE É A AULA: antes de digitar as frases da lição, um professor de desenho animado — o Prof. Beto — aparece
na tela, mexendo a boca, e FALA (voz sintética pt-BR) uma explicação curta, como uma historinha, de 1 a 2
minutos. Enquanto ele fala, uma lousa ao lado mostra o "quadro" (o que está escrito) e, quando ele diz um
exemplo em inglês, a lousa mostra o inglês grande com a tradução embaixo. Não é IA: é um texto pronto,
escrito por você, lido igual para todo mundo.

OBJETIVO DA AULA: o aluno ENTENDER e LEMBRAR as frases da lição.
  - Conte a cena da lição como uma historinha (quem está falando, onde, o que acontece) e encaixe as frases
    nela — a cena vira o gancho da memória.
  - Explique o SENTIDO das frases-chave (o "alvo" de cada frase) e, quando ajuda, o ao pé da letra.
  - Explique a REGRA ou o TERMO TÉCNICO importante da lição com palavras simples (contração, verbo to be,
    pronome, plural, terceira pessoa, artigo, ordem do adjetivo, passado...). Diga o nome do termo em português.
  - Dê UM truque de memória por aula (uma imagem, uma comparação com o português, um som parecido, uma
    regrinha que rima) — curto e certeiro.
  - Avise o ERRO típico de brasileiro quando houver (falso cognato, tradução palavra por palavra, I sempre
    maiúsculo, have para idade...). Pode dar uma dica de pronúncia descrita em português (a língua entre os
    dentes no th, o r do inglês...).
  - Termine chamando o aluno para praticar ("agora é com você").
  NÃO tente explicar todas as frases: escolha as 2 a 4 mais importantes. Não repita a teoria escrita palavra
  por palavra (ela existe noutra tela) — a aula é a conversa do professor.

LEIA, nesta ordem:
  1. $LOTE/contexto_<slug>.md de cada trilha (as lições: cena, resumo, teoria escrita, frases com quem fala,
     inglês exato, português, alvo e a nota do autor).
  2. $A/exemplo_aula.json (uma aula pronta e aprovada — pegue o tom, o tamanho e o ritmo).
  3. $A/validar_aulas.py (as regras que o validador cobra; o docstring tem o formato).

FORMATO: um arquivo por trilha, $LOTE/<slug>.json:
  {"versao": 1, "trilha": "<slug>", "licoes": {"<id da lição>": {"titulo": "...", "falas": [ ... ]}}}
  Uma aula para CADA lição da trilha (os ids estão no contexto). Cada fala é UMA destas:
    {"pt": "o professor falando em português"}                       → a voz pt-BR lê
    {"pt": "...", "quadro": "I'm = I am"}                           → além de falar, escreve na lousa
    {"en": "I'm good, thanks.", "tr": "Tudo bem, obrigado."}        → o professor diz o exemplo em inglês
  - "titulo": até 60 caracteres, em português, convidativo (pode citar o inglês: "O tudo bem? dos americanos").
  - 7 a 18 falas; a 1ª e a última em português; português somado 450–1600 caracteres (≈1–2 min).
  - Pelo menos 2 falas "en" copiadas EXATAMENTE (letra por letra, pontuação igual) de frases da lição; as
    outras "en" podem ser pedacinhos (How's = How is não; isso vai no quadro) ou exemplos curtos novos, sempre
    inglês correto, natural e do nível A1, só ASCII (apóstrofo reto ').

REGRAS DA VOZ (a voz pt-BR lê o "pt" e PRONUNCIA ERRADO qualquer inglês):
  - NENHUMA palavra em inglês dentro de "pt" (o validador procura). Quando precisar dizer o inglês, faça a
    fala "pt" terminar chamando o exemplo ("...ele diz assim:") e ponha o inglês na fala "en" seguinte; ou
    escreva o inglês no "quadro" e diga em português ("olha na lousa: a forma curta junta as duas palavras").
    Nomes próprios (Mike, Ana, Chicago, Carlos) e palavras que já são do português (e-mail, site, app, ok,
    hotel, café, pizza) podem.
  - Para falar de um termo em inglês sem dizê-lo, use a tradução ou "essa palavra", "a primeira palavra",
    "o verbo ser e estar", "a palavrinha da lousa".
  - Sem emoji, sem aspas, sem markdown, sem parênteses longos, sem abreviações (ex., p.ex., vc). Frases
    curtas, de fala: uma ideia por fala, no máximo ~2 frases (até 300 caracteres).
  - Tom: professor brasileiro simpático, falando com "você", animado mas sem exagero, sem infantilizar
    (o aluno é adulto, muitas vezes dev). Nada de "Olá, querido aluno!" em toda aula: abra direto na cena.
    O Prof. Beto só se apresenta pelo nome na primeiríssima aula do curso (primeiro-contato.oi-tudo-bem).
  - O aluno se chama Carlos nas frases; ele é dev brasileiro, trabalha remoto, adora café.

PROCESSO:
  1. Escreva o arquivo de cada trilha.
  2. Rode: python3 -I $A/validar_aulas.py $LOTE/<slug>.json — corrija até sair ✓ (todos os seus arquivos).
  3. Releia cada aula em voz alta na cabeça: soa natural? o inglês está 100% correto? a regra está certa e
     simples? cada aula ajuda a lembrar as frases daquela lição?
  4. Responda com: a lista dos arquivos ✓, e em 1 linha por trilha o truque de memória mais legal que usou.
  NÃO escreva nada fora de $LOTE. NÃO mexa no projeto.
```

---

## Revisor (outro agente, depois do autor)

```
Você é o REVISOR das aulas do professor das trilhas <SLUGS> do Paclingo (curso de inglês para brasileiros, A1).
Leia $A/PROMPT_AULAS.md (o pedido ao autor — as regras valem para você), $A/exemplo_aula.json, e para cada
trilha o $LOTE/contexto_<slug>.md e o $LOTE/<slug>.json do autor.

Revise CADA aula como um professor de inglês nativo bilíngue e exigente:
  - inglês: tudo correto e natural? cada "en" que diz ser frase da lição é cópia EXATA? "tr" fiel?
  - conteúdo: a regra/termo explicado está CERTO (nada de simplificação que vira erro)? o sentido das frases
    está certo? o truque de memória funciona e não ensina errado? o erro típico citado é real?
  - português: natural, falado, sem frase de livro, sem repetir a teoria escrita, sem inglês dentro do "pt"?
  - a aula cobre as frases-chave daquela lição e conversa com a cena? cabe em 1–2 minutos?
Corrija direto no arquivo (reescreva falas ruins; não precisa pedir licença). Rode o validador
(python3 -I $A/validar_aulas.py $LOTE/<slug>.json) até ✓. Responda com a lista do que mudou (curta, por lição)
e qualquer dúvida que ficou. NÃO escreva fora de $LOTE.
```
