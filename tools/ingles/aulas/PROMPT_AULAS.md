# PROMPT_AULAS — autor (e revisor) das 🎓 Aulas do Professor (v2: aula inteira, 6 a 10 minutos, qualquer nível)

> **Para o lead:** `python3 -I tools/ingles/aulas/montar_contexto.py --etapa A2 --saida $LOTE` (A1, A2, B1, B2, C1 ou DEV) gera um
> `contexto_<slug>.md` por trilha (com a foto da cena e a aula curta antiga de cada lição). Um autor por trilha
> (3 a 10 lições), depois um revisor por trilha (bloco do fim). Os agentes escrevem SÓ em `$LOTE/<slug>.json`;
> o lead valida, copia para `assets/ingles/aulas/`, atualiza o `indice.json` e gera as vozes e as bocas
> (`vozes_aula.py`, que grava em `web/aula_voz/` — servido pelo site, fora do app do celular).

---

```
Você vai escrever as AULAS DO PROFESSOR das lições da trilha <SLUG> do curso de inglês do Paclingo (app
brasileiro, aluno adulto que fala português; esta trilha é do nível <NIVEL> — veja NÍVEL, mais abaixo).

O QUE É A AULA: antes de digitar as frases da lição, um professor de desenho animado — o Prof. Beto — aparece
na tela, mexendo a boca, e DÁ UMA AULA FALADA (voz sintética pt-BR) de 6 a 10 minutos, como um bom professor
de cursinho: conta a cena como uma historinha, explica cada frase com calma, a regra, a pronúncia, curiosidades,
o erro típico do brasileiro, desafia o aluno e recapitula. Ao lado dele, uma LOUSA mostra o que ele escreve
(o "quadro"), o exemplo em inglês com a tradução, e FIGURAS (a foto da cena ou emojis grandes) quando ele cita
uma coisa. A aula é dividida em PARTES com nome (o aluno vê "Parte 3 de 7 · A regra" e pode pular entre elas).
Não é IA: é um texto pronto, escrito por você, lido igual para todo mundo. Se o contexto trouxer uma aula curta
antiga (1 minuto) da lição, ela foi revisada por um professor — aproveite-a, mas a nova é uma AULA DE VERDADE,
muito maior e com muito mais detalhe. As aulas do A1 (156 lições) já estão prontas e aprovadas pelo dono do app
nesse formato: o nível de capricho é esse.

NÍVEL (adapte a aula ao nível da trilha; a explicação é SEMPRE em português, o aluno é brasileiro):
  - A1/A2: frases curtas, tudo explicado com calma, exemplos extras curtos e do mesmo nível.
  - B1/B2: o aluno já se vira; a aula vai mais fundo: a diferença para as estruturas parecidas que ele já viu
    (por que este tempo e não aquele), o registro (falado, escrito, formal, informal), as colocações, o que
    soa natural e o que soa traduzido; exemplos extras do nível, um pouco mais longos.
  - C1: nuance, registro, ênfase, escolha da palavra exata, o que um nativo instruído diria; contraste com o
    jeito "de livro" e com o português; exemplos sofisticados mas naturais.
  - DEV (inglês profissional de dev): a situação real de trabalho em time internacional (reunião, PR, incidente,
    e-mail, entrevista): o que se diz, por que, o tom certo, o que soa rude ou fraco para um gringo, a cultura
    de trabalho (só o que é amplamente sabido; nada de números ou regras inventadas).
  - História/conto (lições de narrativa): conte a história com vontade, explique cada frase dentro dela.
  Em todo nível: o termo técnico da lição com o nome em português e a regra CERTA, sem simplificação que vira
  erro; o erro típico do brasileiro; desafios; curiosidades garantidas.

OBJETIVO: o aluno ENTENDER e LEMBRAR todas as frases da lição, e sair sabendo o porquê de cada uma.

ESTRUTURA (5 a 10 partes; adapte os nomes à lição — não precisa ser esta ordem nem estes nomes):
  1. A cena: conte a situação como uma historinha (quem, onde, por quê), mostrando a foto ("img": "foto").
  2. Uma parte por grupo de frases: CADA frase da lição aparece pelo menos uma vez como fala "en" EXATA. Para
     cada uma: o sentido, o ao pé da letra quando ajuda, palavra por palavra no quadro, quando usar, uma
     variação comum ou um exemplo extra curto (do nível da trilha).
  3. A regra / o termo técnico da lição (contração, verbo to be, pronome, plural, terceira pessoa, artigo,
     ordem do adjetivo, passado...): o nome do termo em português, a regra simples e CERTA, exemplos.
  4. Pronúncia: o som que o brasileiro erra naquela lição, descrito em português (a língua entre os dentes,
     o r do inglês, a vogal comprida, a sílaba forte) — o exemplo sai em fala "en".
  5. Curiosidade: cultura, costume, diferença entre Estados Unidos e Reino Unido, origem de uma palavra, uma
     conexão com o português (palavras que vieram do latim, cognatos). SÓ FATOS QUE VOCÊ TEM CERTEZA: nada de
     números, datas, estatísticas ou histórias que você não tenha certeza absoluta. Na dúvida, não ponha.
  6. Erros comuns de brasileiro (falso cognato, tradução palavra por palavra, I minúsculo, have para idade...).
  7. Desafio: o professor propõe "como você diria...?" com "pausa" (o aluno pensa e fala em voz alta) e a
     resposta vem na fala "en" seguinte. De 1 a 6 desafios por aula.
  8. Recapitulando + chamada para praticar ("agora é a sua vez de digitar").
  Um truque de memória forte por aula (uma imagem, uma comparação com o português, um som parecido). Pode
  costurar a historinha do começo ao fim (voltar à cena nos exemplos ajuda a memória).

LEIA, nesta ordem:
  1. $LOTE/contexto_<SLUG>.md (as lições: foto, cena, resumo, teoria escrita, as frases com quem fala, inglês
     exato, português, alvo, emoji e a nota do autor, e a aula curta antiga).
  2. A FOTO de cada lição (o caminho está no contexto; abra com a ferramenta Read, que mostra a imagem): conte a
     cena de um jeito que combine com o que aparece nela.
  3. $A/exemplo_aula.json (uma aula pronta e aprovada — pegue o tom, o tamanho, o ritmo e o uso de partes,
     figuras e desafios).
  4. $A/validar_aulas.py (as regras que o validador cobra; o docstring tem o formato).

FORMATO: um arquivo, $LOTE/<SLUG>.json:
  {"versao": 2, "trilha": "<SLUG>", "licoes": {"<id da lição>": {"titulo": "...", "falas": [ ... ]}}}
  Uma aula para CADA lição da trilha (os ids estão no contexto). Cada fala é UMA destas:
    {"pt": "o professor falando em português"}                      → a voz pt-BR lê
    {"en": "I'm good, thanks.", "tr": "Tudo bem, obrigado."}       → ele diz o exemplo em inglês; a lousa mostra
  Campos opcionais:
    "quadro": "I'm = I am"        (só na fala "pt") o que ele escreve na lousa — curto, até 90 caracteres
    "img": "foto"                 a foto da cena da lição (só se a lição tem foto — o contexto diz)
    "img": "☕🥐"                  1 a 4 emojis grandes na lousa (a coisa que ele está citando: comida, lugar,
                                  objeto, bandeira, relógio, clima, pessoa...). Aproveite os emojis do contexto.
    "secao": "A regra"            a parte da aula que COMEÇA nesta fala (a 1ª fala sempre abre a 1ª parte);
                                  até 40 caracteres, sem emoji, em português
    "pausa": 4                    (só na fala "pt") 2 a 8 segundos de silêncio depois dela: o desafio
  A figura e o quadro ficam na lousa até aparecer outra coisa escrita; ponha figura quando ela AJUDA (pelo
  menos 4 por aula, sem exagerar — não é toda fala).
  - "titulo": até 60 caracteres, em português, convidativo (pode citar o inglês: "O tudo bem? dos americanos").
  - 35 a 130 falas; a 1ª e a última em português; DURAÇÃO de 6 a 10 minutos (o validador estima com a conta do
    app: 14 letras por segundo no português, 12 no inglês, meio segundo por fala e as pausas) — mire em 7 a 9
    minutos; português somado 3500 a 8200 caracteres. NÃO encha linguiça: cada fala ensina alguma coisa ou
    leva a história adiante; se faltar tempo, aprofunde (mais um exemplo do dia a dia, um contraste, uma
    curiosidade garantida, mais um desafio).
  - TODA frase da lição (cada "cod" da tabela) aparece pelo menos uma vez como fala "en" copiada EXATAMENTE
    (letra por letra, pontuação igual). As outras "en" podem ser pedacinhos ou exemplos curtos novos, sempre
    inglês correto, natural e do nível da trilha, só ASCII (apóstrofo reto ').
  - 5 a 10 partes ("secao").

REGRAS DA VOZ (a voz pt-BR lê o "pt" e PRONUNCIA ERRADO qualquer inglês):
  - NENHUMA palavra em inglês dentro de "pt" (o validador procura). Quando precisar dizer o inglês, faça a
    fala "pt" terminar chamando o exemplo ("...ele diz assim:") e ponha o inglês na fala "en" seguinte; ou
    escreva o inglês no "quadro" e diga em português ("olha na lousa: a forma curta junta as duas palavras").
    Nomes próprios (Mike, Ana, Chicago, Carlos) e palavras que já são do português (e-mail, site, app, ok,
    hotel, café, pizza) podem.
  - Para falar de um termo em inglês sem dizê-lo, use a tradução ou "essa palavra", "a primeira palavra",
    "o verbo ser e estar", "a palavrinha da lousa".
  - Pronúncia: NUNCA escreva o som do inglês com letras do português ("fala tenquíu") — descreva o movimento
    da boca e ponha o exemplo numa fala "en" (a voz em inglês pronuncia certo).
  - Sem emoji dentro de "pt" (emoji só no "img"), sem aspas, sem markdown, sem parênteses longos, sem
    abreviações (ex., p.ex., vc). Frases curtas, de fala: uma ideia por fala, no máximo ~2 frases (até 320
    caracteres).
  - Tom: professor brasileiro simpático, falando com "você", animado mas sem exagero, sem infantilizar
    (o aluno é adulto, muitas vezes dev). Nada de "Olá, querido aluno!" em toda aula: abra direto na cena.
    O Prof. Beto só se apresenta pelo nome na primeiríssima aula do curso (primeiro-contato.oi-tudo-bem).
    Pode lembrar o que o aluno já viu em trilhas anteriores (a lista está no contexto).
  - O aluno se chama Carlos nas frases; ele é dev brasileiro, trabalha remoto, adora café.
  - Não contradiga a teoria escrita nem as notas do autor do contexto; se achar algo errado nelas, não repita
    o erro e conte na resposta final.

PROCESSO:
  1. Escreva o arquivo (pode escrever uma lição por vez, juntando no mesmo JSON).
  2. Rode: python3 -I $A/validar_aulas.py $LOTE/<SLUG>.json — corrija até sair ✓.
  3. Releia cada aula em voz alta na cabeça: soa natural, como um professor falando? o inglês está 100%
     correto? a regra está certa e simples? cada curiosidade é fato garantido? cada aula ajuda a lembrar as
     frases daquela lição? tem algo repetido demais?
  4. Responda com: o arquivo ✓, a duração estimada de cada aula e, em 1 linha, a curiosidade mais legal.
  NÃO escreva nada fora de $LOTE. NÃO mexa no projeto.
```

---

## Revisor (outro agente, depois do autor)

```
Você é o REVISOR das aulas do professor da trilha <SLUG> do Paclingo (curso de inglês para brasileiros, nível <NIVEL>).
Leia $A/PROMPT_AULAS.md (o pedido ao autor — as regras valem para você), $A/exemplo_aula.json, o
$LOTE/contexto_<SLUG>.md e o $LOTE/<SLUG>.json do autor.

Revise CADA aula como um professor de inglês nativo bilíngue e exigente:
  - inglês: tudo correto e natural? cada "en" que é frase da lição é cópia EXATA? "tr" fiel?
  - conteúdo: a regra/termo explicado está CERTO (nada de simplificação que vira erro)? o sentido das frases
    está certo? o truque de memória funciona e não ensina errado? o erro típico citado é real?
  - CURIOSIDADES: cada uma é fato garantido? Corte ou reescreva qualquer coisa duvidosa, número, data ou
    história que você não confirmaria num dicionário ou enciclopédia.
  - português: natural, falado, sem frase de livro, sem repetir a teoria escrita, sem inglês dentro do "pt"
    e sem pronúncia escrita com letras do português?
  - a aula é uma aula de verdade (6 a 10 minutos) sem encher linguiça? está no nível certo da trilha? as partes têm nomes bons? as figuras
    ("img") combinam com o que ele está dizendo naquela fala? os desafios ("pausa") têm a resposta logo depois?
Corrija direto no arquivo (reescreva falas ruins; não precisa pedir licença). Rode o validador
(python3 -I $A/validar_aulas.py $LOTE/<SLUG>.json) até ✓. Responda com a lista do que mudou (curta, por lição)
e qualquer dúvida que ficou. NÃO escreva fora de $LOTE.
```
