# PROMPT_LOTE — autor de uma trilha (📺 Escutar assistindo)

> **Para o lead:** copie o bloco abaixo para o agente autor, trocando `<slug>`, `$LOTE` (a pasta do lote, ex.: `$SP/lote_2`) e `$H` (a pasta das ferramentas: `tools/ingles/historias` no repo). Antes, rode `python3 -I $H/montar_contexto_lote.py <slug> ... --saida $LOTE` e `python3 -I $H/validar_historias_licoes.py --auto-teste`. Um autor por trilha. Depois, um **revisor** (outro agente) com o bloco do fim.

---

```
Você vai ENCENAR (não escrever) as historinhas das lições da trilha <slug> do curso de inglês do Paclingo,
para o modo "📺 Escutar assistindo" do 🎧 Ouvir (a playlist): enquanto o Ouvir toca as frases de uma lição,
um palco de desenho animado encena essas frases, e cada personagem diz a sua com a boca sincronizada.

LEIA, nesta ordem:
  1. $LOTE/contexto_<slug>.md   (as lições, as cenas, as frases com os ids, o arco das trilhas anteriores,
                                 as listas permitidas e o exemplo oficial)
  2. $H/RECEITA.md              (inteira: elenco §4, esquema §5, limites §6, como encenar §7, regras §8)
  3. $H/primeiro-contato.json e $H/numeros-horas-soletrar.json (o piloto: 12 lições revisadas, para pegar o tom)

Cada lição JÁ É uma cena: as frases (a tabela do contexto) são as falas, NA ORDEM, ditas por quem está em `quem`.
Você NÃO escreve inglês nem português de fala. Para cada lição, escreva só:
  - titulo {en: até 6 palavras, ASCII, capitalização de frase, sem ponto final, vocabulário do nível; pt: natural}
  - 1 (ou 2) cenas: cenario (lista permitida), hora, clima (normalmente []), elenco com pos/segura/emocao/visivel,
    objetos
  - passos: um {"frase": "<id>"} para CADA frase, na ordem (copie os ids do contexto), com acao/emocao/camera/
    alvo/reacoes/segura que combinem com o sentido da frase e o emoji `img`; até 4 passos {"mudo": true, ...}
    para ligar as falas (alguém entra, anda até o balcão, entrega um objeto, todos acenam no fim).
    Deslocamentos (entra/anda/corre/sai) SÓ em passo mudo.
E, uma vez no arquivo, o "arco" da trilha (pt-BR, até 300 caracteres), continuando o arco das anteriores.

REGRAS (o validador cobra; detalhe na RECEITA §6):
  - elenco = voce, mike, sarah, ana, ben, emma, lucas, julia, dra-lee + os papéis que falam na lição + até 2
    figurantes mudos da lista fixa (RECEITA §4). NUNCA Max nem Kim. `placa` vira narrador (sem quem, sem elenco).
  - 1–2 cenas (a cena cita 3 lugares? junte dois no mesmo cenário); mudos ≤ 3 por cena, ≤ 2 seguidos, ≤ 4 na lição;
    toda cena com pelo menos uma frase.
  - videochamada: todos presentes nas molduras, sem remoto, sem anda/corre/senta; quem chega depois começa
    "visivel": false e acende num mudo "entra".
  - telefone/mensagem: o voce segurando "celular" do começo ao fim; o outro com "remoto": "celular" (só parado).
  - titulo obrigatório; ficha do aluno: dev brasileiro, trabalha remoto de casa, adora café; sem biografia inventada.
  - cada lição faz sentido SOZINHA (pode tocar avulsa numa setlist), mas mantenha a continuidade da trilha
    (lugar, hora, props de cada um).
  - toda historinha termina num sorriso (fecho com feliz/radiante; ninguém bravo/triste no fim).
  - nada de marca, cidade proibida no título, tema sensível, cenário de corrida/espaço, prop do Turismo.
  - faltou cenário, prop ou figurante? use o mais próximo e anote em $LOTE/pedidos_de_arte.md (uma linha por
    pedido: lição, o que faltou, o que usou no lugar). Nunca peça código.

FORMATO: exatamente o esquema da RECEITA §5 e o exemplo do contexto. Escreva $LOTE/<slug>.json (UTF-8,
indentação de 2 espaços). Não crie outros arquivos (só o pedidos_de_arte.md, se precisar). Não toque no projeto,
não rode flutter.

VALIDE até 0 erros (e sem nenhum aviso de "sem história"):
  python3 -I $H/validar_historias_licoes.py $LOTE/<slug>.json
Erros de leitura (frase desconhecida, âncora com en, enum inválido…) aparecem um por vez: conserte e rode de novo.
A tabela "Erros comuns → conserto" da RECEITA §11 diz o que fazer com cada mensagem.

ENTREGUE: o caminho do arquivo; por lição, o título, o cenário, o número de mudos e os figurantes mudos; os
pedidos de arte (se houver); e qualquer dúvida de coerência com a `cena` ou a foto.
```

---

## Revisor (outro agente, a mesma trilha)

```
Revise $LOTE/<slug>.json (historinhas do 📺 Escutar assistindo) contra $LOTE/contexto_<slug>.md e $H/RECEITA.md.
Confira, lição a lição:
  - o lugar, a hora e quem está presente batem com a `cena` e com a foto (`visualizacao`);
  - o gesto, a emoção e a câmera de cada âncora combinam com o sentido da frase e o emoji; as reações de quem ouve
    fazem sentido; nenhum gesto contradiz a fala;
  - abertura clara, virada visível, fecho com sorriso;
  - a lição se entende sozinha (estado inicial coerente) e a trilha tem continuidade (figurino, props, lugar);
  - o elenco é o das lições (nunca Max/Kim; no máx. 2 figurantes mudos, da lista); o voce sem biografia inventada;
  - título curto, natural nos dois idiomas, do nível; arco em pt-BR natural, ≤ 300 caracteres;
  - nada de marca, tema sensível, cenário de corrida/espaço.
Corrija direto no arquivo (sem mexer em nenhum id de frase nem na ordem) e revalide até 0 erros:
  python3 -I $H/validar_historias_licoes.py $LOTE/<slug>.json
Entregue a lista do que mudou (lição → o quê e por quê).
```
