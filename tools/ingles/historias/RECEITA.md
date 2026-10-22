# RECEITA: os lotes de historinhas do 📺 Escutar assistindo (um JSON por trilha)

> **Onde a historinha aparece (decisão do dono: "no lugar de colocar na lição, coloque na opção do play list, escutar assistindo"):** **não** é na lição. É no 🎧 **Ouvir** (a playlist): o botão 📺 de cada setlist, o "📺 Assistir" da página da setlist, o cartão **"📺 Escutar assistindo"** do curso e o modo **📺 Assistir** do "Tocando agora". Enquanto o Ouvir toca as frases de uma lição, o palco de desenho animado do Turismo encena essas frases: cada personagem diz a sua com a boca sincronizada.
> **Toda lição já tem desenho** desde o dia 1: o encenador automático (`EncenadorLicao`, Dart) monta o palco em tempo de execução, corrigido pela tabela `encenacao_auto.json` (§15). A história **autoral** de uma lição (este lote) substitui a automática e ganha o selo "✨ história especial".
> A unidade de trabalho é a **lição**, porque a fila do Ouvir é feita das frases das lições. Um **autor encena uma trilha** (de 3 a 7 lições) e sai um JSON por trilha; um **lote** junta de 3 a 5 trilhas seguidas (≈ 15–25 lições).
> Fonte de tudo: `plano_historias_licoes.md` (§3.2–3.4, §5, §10, e o **esquema final na §16**; revisão 2 de 22/out/2026). Em qualquer divergência, **o Dart manda** (`HistoriasDaTrilha.fromJson(estrito: true)` + `validarHistoriasDaTrilha`), depois o validador Python oficial (que é um espelho provado do Dart, §11), depois esta receita.

`$H` = **a pasta desta receita**: no repo, `tools/ingles/historias/` (depois da integração); na sessão do piloto, `$SP/historias_licoes/` (`$SP` = o scratchpad da sessão).
`$LOTE` = a pasta de trabalho do lote, fora do projeto (ex.: `$SP/lote_2/`). O autor só escreve lá.
Projeto: `/Users/fazplay/pac_dart` (**só leitura para o autor e o revisor**: não crie nem edite nada lá, não rode `flutter`; quem copia e testa é o lead).

---

## 1. O que você faz (e o que NÃO faz)

Você **encena**, não escreve. As falas já existem: são as frases da lição (`trechos`), na ordem, ditas por quem está em `quem`. Para cada lição, você escreve só:

- um **título** curto (`en` de até 6 palavras, ASCII, e `pt`);
- **1 ou 2 cenas**: o lugar (`cenario`), a hora, o elenco (posição, o que cada um segura, a emoção inicial, quem começa escondido) e os objetos;
- os **passos**: uma **âncora** `{"frase": "<id>"}` para **cada** frase, na ordem da lição, com gesto, emoção, câmera, alvo e reações que combinem com ela, e **até 4 passos mudos** (`"mudo": true`) que ligam as falas (alguém entra, anda até o balcão, entrega a chave, todos acenam no fim).

E, uma vez por arquivo, o **`arco`** da trilha (até 300 caracteres, em pt-BR).

**Proibido:** escrever inglês ou português de fala. Na âncora não vai `en`, `pt`, `pt_f` nem `mudo`: o app puxa o texto do currículo pelo id. Passo com texto e sem `frase` é erro, porque as falas de ligação são **só atuadas**.

---

## 2. Entradas (leia nesta ordem)

1. **O contexto da trilha**, `$LOTE/contexto_<slug>.md`, gerado pelo lead (§9 passo 2) com:
   ```
   python3 -I $H/montar_contexto_lote.py <slug> [<slug> ...] --saida $LOTE
   ```
   O script só lê (currículo, `historia_turismo.dart`, `historia_licao.dart`, DESIGN.md, `encenacao_auto.json`). Ele traz: a etapa e o nível do palco, a descrição da trilha, as trilhas vizinhas, o **`arco` das 2 trilhas anteriores** (se já tiverem arquivo), o fio da etapa e o elenco (DESIGN §5.5), as proibições (§5.7), as listas permitidas lidas do código, as regras do validador em resumo, o exemplo oficial e, por lição: `id`, `nome`, `cena` (o roteiro em PT), `visualizacao` (a descrição da foto), `imagem` (emojis), a foto, os falantes com a 1ª frase de cada um, **a encenação automática de hoje** (a linha da tabela: lugar, hora, remotos, quem entra tarde) e a tabela das frases (`id`, `quem`, `img`, `cod` = EN, `dica` = PT, `contexto` = a fala do outro: "↩ #n" quando é outra frase da lição, «…» (fora do texto) quando não é; 🎙️ = a frase toca uma gravação humana do Tatoeba).
   - `<slug>` = o prefixo do `Licao.id` antes do 1º `.` (ex.: `situacao-hotel`). A lista dos 121 slugs na ordem do curso está no §13.
2. **Este arquivo inteiro**, principalmente §4 (elenco), §5 (esquema), §6 (limites) e §7 (como encenar), e o `PROMPT_LOTE.md`.
3. Para consulta, quando precisar: `$H/exemplo_licao.json` (o exemplo oficial do plano §5.4), `$H/primeiro-contato.json` e `$H/numeros-horas-soletrar.json` (o piloto, 12 lições revisadas) e `tools/ingles/dados/DESIGN.md` §5.5 (elenco e ficha do aluno) e §5.7 (proibições).

## 3. Saída

- **Um arquivo por trilha:** `$LOTE/<slug>.json` (o nome do arquivo é igual ao campo `trilha`).
- **Se precisar de algo que não existe** (cenário, prop, figurante mudo): use o mais próximo e anote em `$LOTE/pedidos_de_arte.md` (uma linha por pedido: lição, o que faltou, o que você usou no lugar). Os pedidos viram lotes de arte (plano §12.2), nunca código dentro do lote.
- Não crie outros arquivos. O lead é quem copia para `assets/ingles/historias/` e atualiza o `indice.json`.
- O lote 1 (piloto, fase 1) está pronto: as **12 lições** de `primeiro-contato` (5) e `numeros-horas-soletrar` (7), em `$H/` (§14). Os próximos lotes seguem a ordem do §13 (plano §12.1).

---

## 4. Cânone do elenco (o das LIÇÕES, não o do Turismo)

Os ids são exatamente estes. A aparência já está no código (não se descreve no JSON). Os papéis seguem o **curso** (DESIGN §5.5). Os papéis da história do Turismo (Ben mecânico, Emma dona do café, Mike navegador) **não valem aqui**.

| id | quem é nas lições | visual fixo (para escolher gestos e props coerentes) |
|---|---|---|
| `voce` | **o aluno**: dev brasileiro, trabalha **remoto, de casa**, para uma empresa americana sem marca. Adora café. Não invente biografia (idade, namorada, cidade) | pele morena, cabelo curto, **fone de ouvido**, roupa roxa |
| `mike` | tech lead americano, em Chicago. Calmo e didático | óculos, crachá, roupa azul |
| `sarah` | product manager, em Austin. Organizada | loira de rabo de cavalo com laço rosa, roupa coral |
| `ana` | colega brasileira, designer. Otimista | cabelo cacheado escuro com flor, roupa amarela |
| `ben` | amigo americano, em Boston (**não** é colega de trabalho) | gorro verde listrado, cachecol |
| `emma` | vizinha, anfitriã nas viagens | (aparência do Turismo) |
| `lucas`, `julia` | irmão e irmã do aluno | (aparência do Turismo) |
| `dra-lee` | médica | jaleco, estetoscópio, coque |

**Quem pode estar no palco de uma lição** = os 9 acima **∪** os `quem` que **falam nessa lição** **∪ até 2 figurantes mudos** da lista fixa abaixo (o corpo de cada figurante é fixo no código e o rótulo é automático).

**Figurantes conhecidos** (os únicos que podem entrar sem falar; 36 papéis do currículo + 3 só para mudo): `amigo-do-ben`, `atendente`, `caixa`, `cfo`, `cliente`, `colega`, `convidada`, `convidado`, `corretora`, `desenvolvedora`, `dev-junior`, `dev-nova`, `dev-novo`, `dev-pleno`, `diretora`, `engenheira`, `engenheiro`, `entrevistador`, `estagiaria`, `farmaceutica`, `gestora`, `guia`, `marido`, `moradora`, `motorista`, `participante`, `passageira`, `passageiro`, `proprietario`, `recepcionista`, `recrutadora`, `seguranca`, `stakeholder`, `supervisora`, `vendedor`, `vizinha`, **`oficial`**, **`garcom`**, **`vendedora`**.
- **Max e Kim: nunca** (só existem no Turismo).
- **Figurante que não fala na lição** pode entrar **mudo**, no máximo **2 por lição**, e **só** se estiver na lista acima (ex.: o `oficial` da imigração, a `recepcionista` no balcão, o `garcom`). Ele reage, entrega coisas e aponta, mas não tem frase. Papel fora da lista: encene como na §7.6 e registre em `pedidos_de_arte.md` ("figurante novo: <papel>").
- Um canônico citado na `cena` que não fala pode entrar mudo, se couber (máx. 5 presentes).
- **`quem: "placa"`** (4 frases no curso, em `obrigacao-conselho`) vira **`narrador`**: a âncora fica sem `quem`, e o app injeta o narrador (legenda com 🪧). O narrador **não** entra no `elenco`, não faz `acao`, não segura nada e não leva câmera `close`.
- `quem` na âncora é opcional. Se vier, tem de ser igual ao da frase.

---

## 5. Esquema (o subconjunto usado nas lições) e listas permitidas

### 5.1 Arquivo
```json
{
  "versao": 1,
  "trilha": "<slug>",
  "arco": "<pt-BR, até 300 caracteres: o fio da trilha em 1–2 frases>",
  "licoes": {
    "<Licao.id>": {
      "titulo": { "en": "<1–6 palavras, ASCII>", "pt": "<pt-BR>" },   // OBRIGATÓRIO (o chip "✨ história especial" mostra)
      "cenas": [ <cena>, <cena opcional> ]
    }
  }
}
```
Chaves aceitas: arquivo `versao, trilha, arco, licoes`; lição `titulo, cenas`; cena `cenario, hora, clima, elenco, objetos, passos` (é **`passos`**, não `falas`; e **`cenas`**, não `intro`/`fim`).

### 5.2 Cena
```json
{
  "cenario": "casa", "hora": "dia", "clima": [],
  "elenco": [
    { "quem": "voce", "pos": "centroEsquerda", "segura": "cafe", "emocao": "nervoso" },
    { "quem": "mike", "pos": "centroDireita" },
    { "quem": "sarah", "pos": "direita", "visivel": false },
    { "quem": "ana", "remoto": "celular" }
  ],
  "objetos": [ { "prop": "notebook", "pos": "centro" } ],
  "passos": [ … ]
}
```
- **Ator:** `quem` (obrigatório), `pos` (obrigatório para quem está no palco, inclusive quem começa escondido; **proibido** para remoto), `visivel` (padrão `true`), `remoto` (só `"celular"` nas lições), `segura` (prop), `emocao` (padrão `neutro`). **Não use** `noCarro`.
- **Objeto:** `prop` e `pos` obrigatórios; `visivel` opcional.

### 5.3 Passos
- **Âncora:** `{"frase": "<Trecho.id>", …}` com qualquer destes campos: `acao`, `emocao`, `alvo` (id de ator **ou** nome de prop visível no palco), `camera`, `efeito`, `segura`, `reacoes`, `objetos`, `clima`, `hora`, `cenario`, `quem` (só para conferir), `para` (só com `entra`/`anda`/`corre`, e esses **não** valem na âncora).
- **Mudo:** `{"mudo": true, "quem": "<ator presente>", …}` com os mesmos campos (menos `frase`). Tem de acontecer **alguma coisa** (`acao` ≠ `parado`, ou `emocao`, `efeito`, `segura`, `reacoes` ou `objetos`).
- **Reação** (dentro de `reacoes`, no máx. 4 por passo): `{"quem", "emocao", "acao", "efeito", "segura"}`, com pelo menos um campo além de `quem`. Não pode ser de quem fala. Remoto só reage com `emocao`.
- **Movimento de objeto** (dentro de `objetos` de um passo, no máx. 3): `{"prop", "acao", "pos", "de"}`. `aparece`/`entra` exigem `pos`; `passa` não leva `pos`; `some`/`sai`/`voa`/`roda`/`treme` exigem exatamente 1 objeto visível daquele prop; `de` = um ator presente que **está segurando** aquele prop (ele solta).

### 5.4 Listas permitidas nas lições

**Cenários** (os 8 primeiros foram desenhados para as lições: os 5 da fase 1 do 📺 e os 3 da 2ª leva, que veio dos pedidos de arte dos lotes):

| cenário | use para | cuidado |
|---|---|---|
| `videochamada` | chamada de vídeo, daily, reunião online, "na chamada" | todos ficam **presentes**, cada um na sua moldura de webcam; quem está `visivel:false` aparece como moldura apagada e **acende** no mudo `entra`. **Sem `anda`/`corre`/`senta`**, porque as molduras não andam. Sem remoto |
| `escritorio` | escritório de Chicago ou Austin, sala de reunião, corredor, entrevista presencial | |
| `casa` | casa do aluno (ele trabalha de casa), vizinhos, família, festa, mensagem ou telefone de casa | |
| `restaurante` | restaurante, **café**, padaria, lanchonete, almoço | o `cafe` do Turismo tem uma pista de corrida na janela: **não use `cafe`** |
| `loja` | loja, mercado, farmácia, caixa, compras | |
| `copa` | copa/cozinha do escritório: café, intervalo, fila da cafeteira, papo de corredor, micro-ondas | tem a cafeteira, o bebedouro e, na tela larga, a parede de vidro da sala de reunião; reunião de verdade continua no `escritorio` |
| `recepcaoHotel` | recepção/saguão do hotel: check-in, check-out, pedir algo no balcão, recepcionista | o balcão (com o sino), o escaninho das chaves e o elevador; o quarto continua sendo o `hotel` |
| `salaDeEstar` | sala com sofá e TV: ver série/filme/jogo, "no sofá", festa em casa, chegar cansado e se jogar no sofá | a TV fica no meio da parede (acima das cabeças) e o sofá perto da borda direita; cozinha e mesa de trabalho continuam na `casa` |
| `aeroporto` | aeroporto, imigração, embarque, bagagem | |
| `hotel` | quarto de hotel | é um **quarto**; o check-in e o balcão são a `recepcaoHotel` |
| `clinica` | médico, dentista, consulta | provisório (é uma tenda), até chegar o "consultório" |
| `cidade` | rua, caminho, táxi, ônibus, esquina, passeio | |
| `praia`, `lago`, `ponte` | férias, parque, passeio na água | |

**Não use** (são proibidos ou desenham pista de corrida): `boxes`, `podio`, `autodromo`, `plataforma`, `espaco`, `lua`, `marte`, `estacao`, `garagem` (proibidos pelo validador); `cafe`, `campina`, `deserto`, `neve`, `vulcao`, `canion`, `floresta`, `vale`, `oasis` (passam no validador, mas não servem para as lições: têm pista ou são exóticos). Neve na rua = `cidade` com `"clima": ["neve"]`.

**Hora:** `amanhecer`, `dia`, `tarde`, `noite` (as 4 valem em todos os cenários acima). Siga a `cena` ("à noite", "de manhã") e as frases ("Good evening" → `noite`). Na dúvida, `dia`.

**Clima:** quase sempre `[]`. Interiores (`videochamada`, `escritorio`, `casa`, `restaurante`, `loja`, `copa`, `recepcaoHotel`, `salaDeEstar`, `aeroporto`, `hotel`, `clinica`): só `chuva` ou `neve` (pela janela). Exteriores: `chuva`, `neve`, `neblina`, `folhas`, `vento`; `arcoIris` só de `dia`/`tarde`; `estrelas` só à `noite`; `neon` só na `cidade`. Só use se a `cena` pedir.

**Props:** `notebook`, `prato`, `sacola`, `documento` (fase 1), `telao` (tela grande de reunião num pedestal, com gráfico: slides, tela compartilhada na sala, TV do bar), `quadroBranco` (quadro de rodinhas com caixas, setas e post-its: retro, kanban, prós e contras), `caixa` (de papelão: mudança, pedido, coisas antigas), `bolo` (com velinhas: aniversário, sobremesa, torta), `caderno` (de espiral: anotações, bloquinho, metas), `casaco` (casaco/jaqueta), `taca` (o brinde) (2ª leva; `telao` e `quadroBranco` são móveis: ponha como `objetos`, na mão eles encolhem), `celular`, `cafe` (a caneca), `mala`, `passaporte`, `mapa`, `chave`, `presente`, `livro`, `carta`, `garrafa`, `guardaChuva`, `cachecol`, `microfone`. Em `segura`, `"nada"` esvazia a mão (só em passo ou reação, nunca no `elenco`). **Proibidos:** `carro`, `carroRival`, `rodaDeOuro`, `foguete`, `capacete`, `pneu`, `trofeu`, `medalha`, `bandeira`. Evite `radio` (remoto por rádio exige carro).

**Posições** (`pos`, `para`), da esquerda para a direita: `esquerda`, `centroEsquerda`, `centro`, `centroDireita`, `direita`. Quem está à direita do centro começa olhando para a esquerda, e vice-versa. Para duas pessoas frente a frente, use `centroEsquerda` e `centroDireita`.

**Ações** (`acao`):
- na âncora e no mudo: `parado`, `acena`, `concorda`, `nega`, `aponta`, `pensa`, `palmas`, `mostra` (precisa de prop na mão), `escreve` (prop na mão ou `alvo` objeto), `olha` (exige `alvo`), `abraca` (exige `alvo`), `senta`, `pula`, `comemora`, `danca`, `treme`, `rodopia`, `cai`, `dorme`, `arremessa` (exige `alvo`);
- **só no mudo** (deslocam): `entra` (quem estava `visivel:false`; `para` opcional), `anda`/`corre` (exigem `para`), `sai`;
- **nunca**: `dirige`, `desce` (são do carro).
- Use com parcimônia: `cai`, `treme` e `rodopia` (só humor físico leve, seguido de alguém rindo), `dorme`, `arremessa`, `danca`.
- Em `reacoes`, valem: `parado`, `acena`, `concorda`, `nega`, `aponta`, `pensa`, `palmas`, `mostra`, `escreve`, `olha`, `senta`, `pula`, `comemora`, `danca`, `treme`, `rodopia`, `cai`, `dorme`.

**Emoções** (`emocao`): `neutro`, `feliz`, `radiante`, `triste`, `surpreso`, `bravo`, `pensativo`, `nervoso`, `timido`, `determinado`, `cansado`.

**Efeitos** (`efeito`): `coracoes`, `confete`, `brilho`, `notas`, `interrogacao`, `exclamacao`, `suor`, `zzz`, `estalo`. Evite nas lições: `fogos`, `relampago`, `fumaca`, `estrelaCadente`.

**Câmera** (`camera`): `geral`, `medio`, `close`, `dupla` (exige `alvo` ator), `aproxima`. Evite `panoramica`. `tremida` só num esbarrão cômico (no máx. 1 por trilha).

---

## 6. Limites

### 6.1 Estruturais (o validador cobra)

| item | limite |
|---|---|
| cenas por lição | 1 a 2; cada cena com ≥ 1 âncora (a `cena` cita 3 lugares? junte dois no mesmo cenário, ex.: recepção e corredor no mesmo `escritorio`) |
| cobertura | **toda** frase da lição aparece **exatamente uma vez**, **na ordem da lição**; nenhuma `frase` desconhecida |
| passos mudos | ≤ **4 na lição** (somando as cenas), ≤ 3 por cena, ≤ **2 seguidos** |
| atores presentes por cena | ≤ 5, cada um numa `pos` diferente (quem começa escondido também precisa de `pos` única) |
| figurantes mudos por lição | ≤ 2, só da lista de figurantes conhecidos (§4) |
| remotos por cena | ≤ 2, só `celular`; enquanto o remoto fala, alguém **no palco** tem de estar segurando `celular`; o remoto só faz `acao: parado` e não segura nada |
| objetos por cena | ≤ 4, cada um numa `pos` diferente |
| reações por passo | ≤ 4 |
| movimentos de objeto por passo | ≤ 3 |
| título | **obrigatório**; `en`: 1 a 6 palavras, só ASCII, sem marca nem cidade proibida; `pt`: não vazio |
| `arco` | ≤ 300 caracteres |

### 6.2 Por nível (o nível só regula a velocidade da máquina de escrever do balão; o resto é gosto)

| etapa | nível do palco | título `en` | encenação |
|---|---|---|---|
| A1 · Fundação | `a1` | só palavras de nível A1, de preferência as das próprias frases da lição ("The first call", "Prices at the store") | um gesto claro e grande por frase; emoções bem marcadas; poucos efeitos; 1 cena quase sempre |
| A2 · Dia a dia | `a2` | vocabulário A2 | igual, com mais reações dos ouvintes |
| B1 · Independência | `b1` | vocabulário B1 | gestos mais contidos; `pensa`, `concorda`, câmera `medio`/`close` nas falas de opinião |
| B2, C1 e DEV | `b2` | vocabulário do nível, ainda ≤ 6 palavras | reunião e trabalho: pouco deslocamento, foco em rosto, reações e `notebook`/`documento` |

As lições têm 8 frases (61%), 10 frases (38%) ou de 9 a 14 (10 lições). Com o padrão do Ouvir, uma lição dura de 25 a 40 s. Sem eco, os silêncios entre as frases são curtos (de 0,5 a 1,5 s).

---

## 7. Como encenar (o mini-arco)

### 7.1 Como o palco toca (entenda antes de escrever)
- **Quem manda é o Ouvir.** Cada âncora aparece quando o Ouvir toca aquela frase. A ação da âncora acontece **enquanto a voz fala**.
- **Os mudos tocam nos silêncios** entre uma frase e a próxima (de 0,5 a 9 s, mais 1,5 s no fim da lição). Se o silêncio for curto, o palco acelera ou **pula direto para o estado final** do mudo. Então **a cena tem de se entender mesmo sem ver o mudo animar**: o estado depois dele (quem está onde, quem segura o quê) tem de contar a história sozinho.
- **Mudo antes da 1ª âncora** só anima quando a lição chega vindo da faixa anterior. Se a fila começa nela, ele é pulado (mas o efeito vale: quem "entrou" já está lá).
- **Mudo depois da última âncora** (o "rabo") toca no silêncio do fim da lição: é o lugar ideal para o aceno final, a entrega da chave ou o "todos sorriem".
- Uma lição pode tocar **avulsa** numa setlist, ou começar de qualquer frase (⏮/⏭). **Cada lição se sustenta sozinha:** o estado inicial (elenco, props, emoção) tem de fazer sentido sem a lição anterior.

### 7.2 Os três tempos de cada lição
1. **Abertura** (o estado inicial + a 1ª âncora): o lugar, quem está ali e o humor já dizem a situação. Ex.: o `voce` `nervoso`, com `cafe` na mão, na `videochamada`. Câmera `geral` ou `medio` na 1ª âncora.
2. **Virada** (no meio): o problema da `cena` (atraso, "não entendi", preço caro, reserva que não aparece, alguém que entra) marcado com emoção ou efeito (`surpreso` + `exclamacao`, `nervoso` + `suor`, `pensativo` + `interrogacao`) e, se couber, um mudo (alguém entra, anda até o balcão, mostra o documento).
3. **Fecho**: alívio e sorriso. A última âncora ou o rabo mudo com `feliz`/`radiante`, `concorda`, `acena` ou `palmas`. **Toda historinha termina num sorriso**, inclusive as de reclamação ou imprevisto.

### 7.3 A âncora combina com a frase
- Leia o `cod`, a `dica`, o `img` (emojis) e o `contexto`. O gesto e a emoção têm de dizer **o mesmo** que a frase.
- Pistas pelo emoji (sugestão, não regra): 👋 `acena`; 👍🙏 `concorda`; 👎🙅 `nega`; 👉☝️ `aponta`; 👏 `palmas`; ✍️📝 `escreve` (com `documento` na mão); 🪑 `senta`; 🤔 `pensa`/`pensativo`; 😊🙂😄 `feliz`; 😃🤩🥳 `radiante`; 😢😞 `triste`; 😮😲🤯😱 `surpreso`; 😠 `bravo`; 😬😰 `nervoso`; 😳😅 `timido`; 💪 `determinado`; 😩🥱 `cansado`; ❤️ `coracoes`; 🎉 `confete`; ❗ `exclamacao`; ❓ `interrogacao` (só em "Sorry?/What?/Pardon?" ou dúvida real); 💦 `suor`; 🎵 `notas`; ✨⭐ `brilho`; 💻 `notebook`; 🍽️🍕 `prato`; 🛍️🛒 `sacola`; 📄📋🪪 `documento`; ☕ `cafe`; 📱📞 `celular`; 🧳 `mala`; 🛂 `passaporte`; 🗺️ `mapa`; 🔑 `chave`; 🎁 `presente`; 📖 `livro`; ✉️📧 `carta`.
- Pistas pelo texto: hi/bye/see you → `acena`; thanks → `concorda` + `feliz`; sorry/excuse me → `timido`; yes/sure/OK → `concorda`; no/not → `nega`; look/here/this → `aponta` (com `alvo`, se houver objeto ou pessoa).
- A `dica` às vezes diz para quem é a fala ("(para a Sarah)"): use `alvo: "sarah"`.
- **Reações** dão vida a quem ouve: quem recebe um "thanks" fica `feliz`; um "!" provoca `surpreso`; uma pergunta deixa o outro `pensativo`. Uma reação por âncora já basta. Não exagere.
- Câmera: `geral` na abertura; `medio` no diálogo a dois; `close` na emoção forte (no máx. 2 por lição); `dupla` (com `alvo` ator) no momento do encontro.

### 7.4 As falas "fora do texto" (o campo `contexto`)
Muitas frases respondem a alguém cuja fala **não** é frase da lição ("What's the purpose of your visit?"). Essa fala **não** vira texto. Se quem pergunta estiver no palco (porque fala em outra frase da lição, ou é canônico), mostre que ele perguntou:
- **no silêncio antes da resposta**, com um mudo dele (`acao: "pensa"` ou `"aponta"`, `efeito: "interrogacao"`), para as 1–2 perguntas mais importantes (lembre o limite de 4 mudos); ou
- **na âncora anterior**, com uma reação dele (`emocao: "pensativo"`, `acao: "aponta"`).

### 7.5 Situações típicas

| situação (pela `cena`) | encenação |
|---|---|
| **Chamada de vídeo** | `videochamada`; todos presentes, até 5; quem "entra depois" começa `visivel: false` e acende num mudo `entra` logo antes da 1ª fala dele. Props na mão valem (`cafe`, `documento`) |
| **Mensagem / chat / telefone** | o `voce` no lugar dele (`casa`, `escritorio`, ou onde a `cena` diz: loja, rua) segurando `celular` do começo ao fim da conversa; o outro com `"remoto": "celular"`. Para "digitando", use `escreve` no `voce` (o celular está na mão). Não esvazie a mão do `voce` antes da última fala do remoto |
| **Presencial a dois** | `centroEsquerda` × `centroDireita`; o `voce` à esquerda |
| **Balcão** (hotel, loja, restaurante, aeroporto) | o atendente de um lado e o `voce` do outro (se o atendente não fala na lição, ele entra como **figurante mudo** da lista: `recepcionista`, `atendente`, `caixa`, `garcom`, `oficial`…); a entrega (chave, passaporte, sacola, prato) num mudo: `{"mudo": true, "quem": "recepcionista", "segura": "nada", "reacoes": [{"quem": "voce", "segura": "chave", "emocao": "feliz"}]}` |
| **Alguém chega atrasado** | `visivel: false` + `pos` no elenco; mudo `entra` antes da 1ª fala; `suor` ou `timido` na fala de desculpa |
| **Mudança de lugar ou de dia** no meio da `cena` ("no dia seguinte…") | 2ª cena, com o elenco de novo; a ordem das âncoras continua |
| **Placa / aviso** | âncora sem `quem` (vira narrador); quem está no palco pode `olha`/`aponta` em reação |
| **Lição de exercício sem diálogo** (conjugações, frases soltas de um só falante) | uma situação simples e coerente com a `cena` (o `voce` estudando em `casa` com `livro` ou `notebook`, contando algo a um canônico que só reage); variar o gesto a cada 2–3 frases para não ficar parado |

### 7.6 Monólogo com interlocutor que não pode entrar
Primeiro tente o **figurante mudo** (§4): se o interlocutor está na lista (`oficial`, `garcom`, `recepcionista`…), ponha-o no palco calado, reagindo. Só quando o papel **não** está na lista, ou já há 2 figurantes mudos, ele não pode estar no palco. Coloque o `voce` em `centroEsquerda` (olhando para a direita, para "fora de cena"), com o prop da situação (`passaporte`, `documento`, `mala`) e gestos de quem responde (`concorda`, `mostra`, `aponta`). Você pode pôr um objeto do outro lado (ex.: `documento` em `direita`, como o balcão) e usar `alvo` nele. Anote o figurante em `pedidos_de_arte.md`.

### 7.7 Continuidade da trilha (o arco)
- Escreva o `arco` primeiro: em 1–2 frases, o fio das lições da trilha (onde, com quem, o que muda do começo ao fim). Siga o **fio da etapa** (DESIGN §5.5): A1, a primeira viagem a Chicago para conhecer o time; A2, os primeiros meses no emprego, viagens, saúde e rotina; B1, a entrevista para uma vaga sênior e três meses no escritório de Austin; B2, o time cresce (reuniões, code review, incidentes) e a vida prática nos EUA; C1, o aluno vira tech lead e tem vida social com os americanos; DEV, um dia inteiro de tech lead.
- Mantenha entre as lições da trilha: o mesmo lugar para a mesma situação, a hora coerente, os mesmos props de cada um (o `cafe` do `voce`, o `documento` da Sarah). Uma piada visual recorrente pequena é bem-vinda (o `voce` sempre com café).
- Mas a regra §7.1 vence: nada essencial pode depender de ter visto a lição anterior.

---

## 8. Regras de conteúdo

1. **Frases intocadas.** O texto das falas é o do currículo, palavra por palavra, porque o app puxa pelo id. Você não copia, não resume e não "melhora" nada.
2. **Sem marcas** (no título, no arco e nas escolhas visuais): nenhuma empresa, app, rede social, loja, bebida ou carro. Nada de cidades no título além de Chicago (o validador barra Austin, Boston, Recife, Curitiba e outras).
3. **Para crianças e famílias:** sem violência, ferimentos, armas, doença grave, política, religião, insultos ou romance. Humor físico só leve (`cai`, `treme`, `estalo`, `suor`), sempre seguido de alguém sorrindo. Ninguém fica `bravo` no fecho.
4. **pt-BR natural** no `titulo.pt` e no `arco`: como um brasileiro diria, sem decalque do inglês ("A primeira chamada", não "A chamada primeira"). O `titulo.en`: capitalização de frase, sem ponto final, ASCII (sem acento nem emoji).
5. **Coerência com a `cena`, a `visualizacao` e a foto:** o lugar, a hora e quem está presente batem com o que o texto da lição descreve.
6. **Elenco certo:** os papéis do curso (§4), nunca Max/Kim, figurante calado só da lista e no máximo 2, o `voce` sem biografia inventada.
7. **Nada de corrida ou espaço:** nenhum cenário nem prop do Turismo.

---

## 9. Passo a passo do lote (plano §10.2)

**Lead (preparar)**
1. **Escolher** de 3 a 5 trilhas seguidas do §13 que ainda não têm arquivo em `assets/ingles/historias/` (≈ 15–25 lições). Ordem: o resto do A1, depois uma etapa por vez (plano §12.1).
2. **Montar o contexto:** `python3 -I $H/montar_contexto_lote.py <slug> [<slug> ...] --saida $LOTE`. Rodar antes `python3 -I $H/validar_historias_licoes.py --auto-teste` (a paridade com o Dart tem de dar 100%).
3. **Disparar 1 autor por trilha** com o `$H/PROMPT_LOTE.md` (trocando `<slug>` e `$LOTE`). As trilhas do mesmo lote vão em sequência quando uma depende do `arco` da anterior; na dúvida, rode `montar_contexto_lote.py` de novo depois de cada trilha pronta (ele relê os arcos de `$LOTE`).

**Autor (uma trilha)**
4. Leia `$LOTE/contexto_<slug>.md` e esta receita. Escreva primeiro o `arco` da trilha, seguindo o arco das anteriores.
5. Para cada lição: decida o lugar e a hora (§5.4; a "encenação automática de hoje" no contexto é um bom ponto de partida, não uma ordem), monte o elenco com as posições, marque quem entra depois, escolha os props. Depois escreva as âncoras na ordem da tabela (copie os ids, não digite à mão) e encaixe os mudos (≤ 4).
6. Escreva `$LOTE/<slug>.json` (JSON válido, UTF-8, indentação de 2 espaços).
7. Valide (§11) até sair **0 erros**: `python3 -I $H/validar_historias_licoes.py $LOTE/<slug>.json`. Os avisos de "sem história" não podem aparecer (não deixe lição de fora).
8. Faça a autochecagem (§10) lição a lição e entregue: o caminho do arquivo, o número de lições e de mudos, os pedidos de arte (se houver) e qualquer dúvida de coerência.

**Revisor (outro agente, a mesma trilha)**
9. Confere: cena coerente com a `cena` e com a foto; ação e emoção combinam com cada frase; continuidade (figurino, props, lugar) dentro da trilha; cada lição se sustenta sozinha; fecho com sorriso; nada de Max/Kim, marcas ou cenário de corrida. Corrige no próprio arquivo e revalida (0 erros).

**Lead (publicar)**
10. Copia `$LOTE/<slug>.json` para `assets/ingles/historias/`, acrescenta cada slug no `indice.json` (versão 1) e roda `python3 -I tools/ingles/historias/validar_historias_licoes.py --pasta assets/ingles/historias` (índice = arquivos presentes, trilhas, tabela) e **só** `~/development/flutter/bin/flutter test test/ingles_historias_licoes_conteudo_test.dart`. A prova visual é opcional (2–3 lições, reaproveitando `build/probe`). Commit `📺 Histórias: lote N (trilhas …)`.
11. **Sem código.** Se o lote pediu cenário ou prop que não existe, a lição usou o mais próximo e o pedido ficou em `$LOTE/pedidos_de_arte.md`: os pedidos viram um **lote de arte** (plano §12.2).
12. **"Só conteúdo" não é "sem publicar"** (P14): o lote é asset do bundle. O dono só vê a historinha nova depois do **build + deploy** de sempre. O lote termina no deploy, não no commit.
13. **Trilha regerada no currículo** (ids novos): as histórias dela caem na automática no app e o teste de conteúdo acusa. Refaça o lote daquela trilha com esta mesma receita (e confira a linha dela no `encenacao_auto.json`, §15).

---

## 10. Autochecagem (antes de entregar)

**Formato**
- [ ] `versao: 1`; `trilha` = slug = nome do arquivo; todas as lições da trilha estão em `licoes`, com os ids exatos; toda lição tem `titulo`.
- [ ] Toda frase aparece uma vez, na ordem da tabela; nenhuma âncora com `en`/`pt`/`pt_f`/`mudo`; nenhum passo com texto sem `frase`.
- [ ] `cenas` (1–2) e `passos` (nunca `falas`/`intro`/`fim`); ≤ 4 mudos por lição, ≤ 3 por cena, ≤ 2 seguidos; todo mudo faz alguma coisa.
- [ ] Nenhuma âncora com `entra`/`anda`/`corre`/`sai`/`dirige`/`desce`.

**Palco**
- [ ] Cada `pos` é única na cena (inclusive a de quem começa escondido); ≤ 5 presentes; remoto sem `pos`, só `celular`, e alguém segurando `celular` enquanto ele fala.
- [ ] Quem fala está no elenco e visível na hora da fala (quem começa `visivel: false` tem um mudo `entra` antes).
- [ ] `mostra`/`escreve` só com prop na mão (ou `escreve` com `alvo` objeto); `olha`/`abraca`/`arremessa` com `alvo`; `dupla` com `alvo` ator; `alvo` = outro ator visível ou prop visível no palco.
- [ ] Na `videochamada`: nada de `anda`/`corre`/`senta` e nada de remoto.
- [ ] Narrador (placa) só na frase de placa: sem `acao`, sem `segura`, sem `close`.

**Conteúdo**
- [ ] Cenário da lista boa (§5.4); nenhum do Turismo, nem `cafe`, nem com pista.
- [ ] Elenco: canônicos + quem fala na lição + no máx. 2 figurantes mudos da lista; nada de Max/Kim.
- [ ] Gesto e emoção de cada âncora combinam com o sentido da frase e o emoji.
- [ ] Mini-arco: abertura clara, virada visível, fecho com sorriso.
- [ ] A lição se entende sozinha (estado inicial coerente) e a trilha tem continuidade (lugar, hora, props).
- [ ] Título: `en` de 1 a 6 palavras, ASCII, do nível; `pt` natural; nenhum dos dois com marca ou cidade proibida. `arco` ≤ 300 caracteres, em pt-BR natural.
- [ ] Nada sensível; nada de marca; o `voce` sem biografia inventada.

---

## 11. Validador

**Oficial:** `$H/validar_historias_licoes.py` (Python, só a biblioteca padrão). Ele é um **espelho do Dart**: reproduz `HistoriasDaTrilha.fromJson(estrito: true)` + `validarHistoriasDaTrilha` mensagem por mensagem (inclusive "o parse estrito para no 1º erro") e, por cima, as regras desta receita, marcadas com `[receita]` (cenários vetados, efeitos e câmeras evitados, remoto na videochamada, fecho com sorriso, closes por lição, `tremida` por trilha, título com capitalização de frase).
```
python3 -I $H/validar_historias_licoes.py --auto-teste                     # 1º: a paridade com o Dart (tem de dar 100%)
python3 -I $H/validar_historias_licoes.py $LOTE/<slug>.json                 # o arquivo da trilha (repita até 0 erros)
python3 -I $H/validar_historias_licoes.py $LOTE/<slug>.json --so-dart       # só o que o Dart cobra (sem [receita])
python3 -I $H/validar_historias_licoes.py --tabela $H/encenacao_auto.json   # a tabela da encenação automática (§15)
python3 -I $H/validar_historias_licoes.py --pasta assets/ingles/historias   # o que o app carrega: índice + trilhas + tabela
```
Opções: `--curriculo CAMINHO` (padrão: `assets/ingles/curriculo.json` do repo) e `--dart CAMINHO` (padrão: `historia_turismo.dart`, lido por regex). Código de saída: 0 sem erros, 1 com erros, 2 uso/arquivo inválido. Aceita também o pacote do piloto (`{"versao", "lote", "descricao", "arquivos": {...}}`).
- Os enums (cenários, props, ações, emoções…) são lidos por regex de `lib/features/arcade/domain/historia_turismo.dart` (pelo motor `$H/validar_historia.py`, cópia do validador do Turismo) e as constantes das lições (`elencoDasLicoes`, `figurantesConhecidos`, `cenariosSoDoTurismo`, limites) de `lib/features/ingles/domain/assistir/historia_licao.dart`: um valor novo no Dart (um cenário de um lote de arte) entra sozinho, sem editar o Python.
- **Paridade provada, não prometida:** `$H/fixtures/` tem 39 casos (um `.json` mínimo por regra L-* do plano §5.3, mais L-base e mensagens de leitura) e, para cada um, o `.esperado.txt` com as mensagens **exatas do Dart**. O `--auto-teste` confere o Python contra eles; o `test/historias_licoes_paridade_test.dart` (integração) confere o Dart contra os mesmos arquivos. Na sessão do piloto, 1.400 mutações aleatórias das 12 lições deram **0 diferenças** Dart × Python (`_trabalho/fuzz_paridade.py`). Se um dia divergir: **o Dart manda** — regrave os esperados com o Dart (`_trabalho/gravar_esperados.py`, no scratchpad) e conserte o Python.

**A palavra final** é do teste Dart `test/ingles_historias_licoes_conteudo_test.dart`, que **o lead** roda depois de copiar o arquivo para o projeto. O autor e o revisor não rodam `flutter`.

**Erros comuns → conserto**

| mensagem | conserto |
|---|---|
| `frases faltando` / `fora da ordem` / `repetidas` | refaça as âncoras copiando os ids da tabela do contexto, na ordem |
| `fala sem 'frase'` | essa fala de ligação vira um mudo (gesto, sem texto) ou sai |
| `âncora não leva 'en'` | apague `en`/`pt`/`pt_f`/`mudo` da âncora |
| `acao 'entra' desloca` | mova o deslocamento para um mudo antes ou depois da âncora |
| `'X' não está visível (use acao entra)` | ponha um mudo `{"mudo": true, "quem": "X", "acao": "entra"}` antes da 1ª fala dele |
| `'X' já está visível (entra)` | tire o `entra`, ou ponha `visivel: false` no elenco |
| `fala pelo celular, mas ninguém no palco segura celular` | `segura: "celular"` no `voce` (no elenco ou num passo anterior), e não esvazie a mão antes |
| `posição inicial 'P' repetida` / `dois atores em 'P'` | redistribua as posições (quem começa escondido também ocupa a sua) |
| `alvo 'X' não é ator presente nem objeto visível` | ponha o objeto em `objetos` da cena (ou num movimento `aparece`), ou troque o alvo |
| `passo mudo sem nada acontecendo` | dê ao mudo uma `acao`, `emocao`, `efeito`, `segura` ou `reacoes` |
| `mais de 2 passos mudos seguidos` / `N passos mudos (máx. 3)` (na cena) / `N passos mudos (máx. 4 na história)` | junte mudos (um mudo pode ter ação + reações + movimento de objeto) ou corte |
| `'X' não é do elenco das lições nem figurante conhecido` | troque por um papel da lista (§4) ou encene como na §7.6 e anote em `pedidos_de_arte.md` |
| `N figurantes mudos (máx. 2)` | deixe só os 2 figurantes mais importantes |
| `titulo ausente` | escreva o `titulo` (`en` + `pt`) da lição |
| `cenário 'X' é só do Turismo` / `prop 'X' é só do Turismo` | troque pelo mais próximo da lista §5.4 |
| `chave 'falas' desconhecida (use 'passos', não 'falas')` | a cena das lições usa `passos` |
| `de 1 a 2 cenas` / `cena sem nenhuma âncora (frase)` | junte dois lugares no mesmo cenário; toda cena precisa de pelo menos uma frase |
| `[receita] …` | regra desta receita (o Dart aceitaria, mas o lote não): siga a mensagem |

(Erro de leitura do JSON — `frase 'f-x' desconhecida`, `âncora não leva 'en'`, `fala sem 'frase'`, enum inválido, chave desconhecida — para a leitura ali: o validador mostra **só esse** erro, como o Dart. Conserte e rode de novo; os erros de palco aparecem depois. "passo N" conta todos os passos da cena, âncoras e mudos, a partir de 1.)

---

## 12. Exemplos

**Oficial** (videochamada, entrada tardia, reações): `$H/exemplo_licao.json` = o plano §5.4 (`primeiro-contato.oi-tudo-bem`), o mesmo texto que o `test/historia_licao_modelo_test.dart` prende. Passa com 0 erros no Dart e no Python.

**O piloto** (`$H/primeiro-contato.json` e `$H/numeros-horas-soletrar.json`, 12 lições): balcão com figurante mudo, esbarrão com humor leve, telefone com remoto, duas cenas no mesmo dia, noite no Brasil. Leia antes de escrever o primeiro lote.

**Telefone/mensagem numa loja** (validado no oficial: 0 erros):
```json
{
  "versao": 1,
  "trilha": "numeros-horas-soletrar",
  "arco": "Os números do dia a dia na primeira semana: telefone, preços na loja, horas entre Chicago e o Brasil e o nome soletrado no cadastro.",
  "licoes": {
    "numeros-horas-soletrar.cem-mil-e-os-precos": {
      "titulo": { "en": "Prices at the store", "pt": "Os preços na loja" },
      "cenas": [
        {
          "cenario": "loja", "hora": "dia", "clima": [],
          "elenco": [
            { "quem": "voce", "pos": "centroEsquerda", "segura": "celular", "emocao": "pensativo" },
            { "quem": "ana", "remoto": "celular", "emocao": "feliz" }
          ],
          "objetos": [ { "prop": "notebook", "pos": "direita" } ],
          "passos": [
            { "frase": "f-8c4f01", "acao": "escreve", "camera": "medio" },
            { "frase": "f-21268e", "emocao": "surpreso" },
            { "frase": "f-f307e9", "acao": "escreve", "emocao": "pensativo" },
            { "frase": "f-52c0fe", "emocao": "nervoso" },
            { "mudo": true, "quem": "voce", "acao": "anda", "para": "centroDireita" },
            { "frase": "f-9a1fcf", "acao": "aponta", "alvo": "notebook", "emocao": "surpreso" },
            { "frase": "f-aefcd4", "emocao": "surpreso" },
            { "frase": "f-4558ab", "acao": "escreve", "emocao": "surpreso", "camera": "close" },
            { "frase": "f-c73db6", "emocao": "surpreso",
              "reacoes": [ { "quem": "voce", "acao": "concorda", "emocao": "feliz" } ] },
            { "mudo": true, "quem": "voce", "acao": "nega", "emocao": "feliz", "efeito": "suor" }
          ]
        }
      ]
    }
  }
}
```
Leitura: o `voce` passeia pela loja e manda mensagens para a Ana (`escreve` com o celular na mão). Ela se assusta com cada preço. No silêncio depois do "That's expensive.", ele anda até o notebook e aponta para ele. No rabo, ri sem graça e balança a cabeça: "não vou levar".

---

## 13. Os 121 slugs na ordem do curso

**A1 (29):** `primeiro-contato`, `numeros-horas-soletrar`, `eu-e-voce-be`, `ele-ela-nos-eles`, `perguntas-com-be`, `familia-e-posse`, `coisas-e-descricoes`, `instrucoes-e-lets`, `situacao-hotel`, `presente-simples`, `perguntas-com-do`, `terceira-pessoa`, `conjugar-s-es-ies`, `rotina-dias-horarios`, `can-pedidos-habilidades`, `gostos-e-lazer`, `situacao-cafe-restaurante`, `presente-continuo`, `pronomes-objeto`, `there-is-lugares`, `quantidades-compras`, `situacao-caminho-compras`, `passado-was-were`, `passado-simples-afirmativo`, `passado-perguntas-negativas`, `planos-going-to`, `comparar`, `dev-ponte-a1`, `revisao-a1`.

**A2 (23):** `perguntas-todos-tempos`, `contar-historia`, `passado-continuo`, `tres-futuros`, `superlativos`, `quantificadores-incontaveis`, `situacao-viagem`, `present-perfect-experiencias`, `present-perfect-just-yet`, `obrigacao-conselho`, `verbo-to-ing`, `situacao-saude`, `convites-pedidos`, `dev-calls-daily`, `se-e-quando`, `talvez-might`, `fazer-ficar-perder-ganhar`, `relativas-definidoras`, `adverbios-phrasal-possessivos`, `dev-slack-commits`, `conhecer-levar-emprestar-dizer`, `falsos-cognatos-ortografia`, `revisao-a2`.

**B1 (22):** `ja-fui-x-fui`, `ha-quanto-tempo`, `eu-costumava`, `tempos-narrativos`, `previsoes-futuro-continuo`, `segunda-condicional`, `situacao-entrevista`, `passiva-1`, `deducao-perguntas-indiretas`, `discurso-indireto`, `modais-no-passado`, `terceira-condicional`, `situacao-aluguel-contas`, `relativas-gerundio`, `regencia-preposicoes`, `ligar-ideias`, `opinar-conduzir-conversa`, `dev-docs-email`, `dev-reunioes`, `phrasal-verbs-b1`, `falsos-cognatos-trabalho`, `revisao-b1`.

**B2 (22):** `tempos-narrativos-completos`, `futuro-avancado`, `passiva-2`, `deducao-no-passado`, `wish-condicionais-mistas`, `situacao-carro-estrada`, `dev-planning-retro`, `verbos-de-relato`, `habitos-costume`, `relativas-3`, `dev-code-review`, `argumentar-conectores`, `enfase-inversao-clivadas`, `phrasal-verbs-b2`, `situacao-telefone-reclamacao`, `colocacoes-expressoes`, `funcoes-conversa-b2`, `dev-incidentes`, `escrita-formal`, `resenhar-criticar`, `registro-variantes`, `revisao-b2`.

**C1 (14):** `inversoes-escrita-formal`, `clivadas-fronting`, `modalidade-avancada`, `passivas-impessoais`, `hedging-registro`, `conceder-rebater`, `situacao-vida-social`, `nominalizacao-participiais`, `idioms-colocacoes-fortes`, `precisao-lexical`, `phrasal-verbs-c1`, `ingles-tecnico-academico`, `conversa-natural-c1`, `revisao-c1`.

**DEV (11):** `pro-entrevista-senior`, `pro-design-sistemas`, `pro-code-review-avancado`, `pro-escrita-tecnica`, `pro-incidentes-comunicacao`, `pro-apresentacoes-demos`, `pro-negociar-prazo-escopo`, `pro-lideranca-feedback`, `pro-clientes-email-formal`, `pro-carreira-networking`, `pro-dia-de-trabalho`.

Casos especiais conhecidos: `obrigacao-conselho` tem as 4 frases de `placa` (narrador); 10 lições têm 5 falantes (sem espaço para mudos extras no palco); 3 lições não têm o `voce` falando (`conjugar-s-es-ies.vogal-y-so-s`, `conjugar-s-es-ies.treino-do-y-ies-ou-s`, `present-perfect-experiencias.papo-de-almoco-o-que-voce-ja-fez`), e ele pode entrar mudo, se fizer sentido.

---

## 14. Lote 1 (piloto, fase 1): as 12 lições — pronto

A1 · Fundação, nível `a1`, 104 frases. Detalhes (falantes, cenário previsto, frases com gravação do Tatoeba) no plano §17.

- `primeiro-contato` (5): `oi-tudo-bem` (videochamada; a Ana entra), `prazer-ate-amanha` (videochamada; a Sarah entra atrasada; todos acenam no rabo), `obrigado-desculpa-com-licenca` (`escritorio`, uma cena: a `recepcionista` como figurante mudo, o Mike mudo, o esbarrão com o café da Sarah), `nao-entendi-pode-repetir` (videochamada; a Sarah muda), `cena-a-primeira-chamada` (videochamada; o `voce` começa `determinado`).
- `numeros-horas-soletrar` (7): `zero-a-doze-o-telefone` (videochamada; o `voce` anota no `documento`), `treze-a-dezenove-o-teen` e `vinte-a-noventa-e-nove-o-hifen` (`loja`; o atendente; a `sacola` no rabo), `cem-mil-e-os-precos` (`loja`; a Ana pelo `celular`), `que-horas-sao` (videochamada; 2 cenas, dia e noite no Brasil), `como-se-escreve-soletrar` (videochamada; a Sarah anota), `cena-o-cadastro-por-telefone` (`casa`, noite; a Sarah pelo `celular`).

Estado (22/out/2026): os 2 arquivos e o exemplo dão **0 erros** no Dart (harness de leitura) e no validador oficial (com o `--auto-teste` 100%); revisão cruzada feita contra o cânone, a `cena` e "cada lição se sustenta sozinha" (uma correção: em `zero-a-doze-o-telefone` o `voce` agora anota no `documento`, como o plano pede). Falta só o lead: copiar para `assets/ingles/historias/`, pôr no `indice.json` e rodar o teste de conteúdo.

---

## 15. A tabela `encenacao_auto.json` (a encenação automática das 602 lições)

**O que é:** para cada lição do curso, uma linha que corrige o encenador automático (plano §4.5, D6, I13): o lugar e a hora, e quando for o caso quem fala pelo celular, quem entra tarde e quem está presente sem falar. A história autoral (os arquivos de trilha) **ganha** da tabela; a tabela ganha da heurística do `EncenadorLicao`. Ela grava **as 602 lições explicitamente**, para que uma mudança futura na heurística não mude decisões já revisadas.

```json
{ "versao": 1, "licoes": {
    "primeiro-contato.oi-tudo-bem": {"cenario": "videochamada", "hora": "dia", "entram": ["ana"]},
    "numeros-horas-soletrar.cem-mil-e-os-precos": {"cenario": "loja", "hora": "dia", "remotos": {"ana": "celular"}},
    "primeiro-contato.obrigado-desculpa-com-licenca": {"cenario": "escritorio", "hora": "dia", "mudos": ["mike", "recepcionista"]}
} }
```
Campos: `cenario` e `hora` (sempre), `remotos` `{quem: "celular"}`, `entram` `[quem]`, `mudos` `[quem]` (opcionais). Uma linha por lição, na ordem do curso.

**Como foi feita (fase 1):** uma 1ª passada pela heurística do plano §4.1 e depois a **revisão humana trilha a trilha** das 602 lições, lendo a `cena`, os falantes e a 1ª frase de cada uma. Critérios usados:
- o lugar onde acontece **a maior parte das frases** (a `cena` às vezes cita dois: "no avião… depois, na chamada");
- chamada de vídeo, daily, reunião remota, "por vídeo" → `videochamada` (todos nas molduras, sem remoto);
- telefone, mensagem, chat, e-mail, comentário de PR → o lugar de quem fala (`casa` na maior parte; `escritorio` no B1, quando o aluno passa três meses no escritório de Austin) + os outros falantes como `remotos` (no máx. 2; com 3 ou mais, `videochamada`);
- avião e balcão de embarque → `aeroporto`; carro, táxi, rua, estação, passeio, museu → `cidade`; café, bar, almoço e jantar fora, happy hour → `restaurante`; banco, farmácia, feira → `loja`; recepção e quarto de hotel → `hotel`;
- `entram`: só quando a `cena` diz que a pessoa chega, entra ou aparece depois (e ela não abre a lição); `mudos`: um canônico ou figurante que a `cena` põe na situação sem fala (até 2 figurantes; ≤ 5 presentes);
- hora: de manhã cedo, acordando, café da manhã, "começo do dia" → `amanhecer`; "segunda de manhã" de trabalho → `dia`; almoço, "fim do dia", "sexta à tarde", happy hour → `tarde`; jantar, festa, "à noite", bar → `noite`; na dúvida, `dia`.
- Resultado: videochamada 245, casa 160, escritório 89, restaurante 45, cidade 26, loja 15, aeroporto 10, hotel 10, clínica 1, lago 1 · 111 lições com remoto, 30 com entrada tardia, 19 com presentes sem falar (`python3 -I $H/listar_por_cenario.py` mostra tudo).

**Quando mexer** (é conteúdo: não precisa de código):
- **trilha nova ou regerada** no currículo → acrescente/corrija as linhas dela (o teste de conteúdo exige as 602, ou quantas o curso tiver);
- **lote de arte** novo (ex.: `consultorio` substituindo a tenda da `clinica`, `salaDeAula`, `metro`) → troque o `cenario` das lições que pedem esse lugar;
- a revisão visual achou uma lição automática fora de lugar → corrija a linha.
Depois de mexer: `python3 -I $H/validar_historias_licoes.py --tabela <caminho>/encenacao_auto.json` (0 erros) e o teste de conteúdo (o lead).

**O que o validador cobra na tabela:** uma entrada para cada lição do curso e nenhuma a mais; `cenario`/`hora` válidos (nunca os do Turismo nem os vetados; hora dentro de `horasPermitidas`); `remotos` só `celular`, só de quem fala, nunca o `voce`, no máx. 2 e nunca na `videochamada`; `entram` só de quem fala, nunca o `voce`, nem quem abre a lição, nem um remoto, no máx. 2; `mudos` nunca quem fala, nunca Max/Kim, só canônicos ou figurantes conhecidos (≤ 2), e no total ≤ 5 presentes.

---

## 16. As ferramentas desta pasta

| arquivo | para quê |
|---|---|
| `RECEITA.md` | esta receita |
| `PROMPT_LOTE.md` | o prompt do autor de uma trilha (o lead troca `<slug>` e `$LOTE`) |
| `montar_contexto_lote.py` | gera `contexto_<slug>.md` para cada trilha do lote (§2) |
| `validar_historias_licoes.py` | o validador oficial: espelho do Dart + regras da receita; `--auto-teste`, `--tabela`, `--pasta`, `--so-dart` (§11) |
| `validar_historia.py` | o motor da cena (cópia do validador do Turismo: enums por regex + `SimulacaoCena`); o oficial importa por caminho |
| `fixtures/` | os 39 casos de paridade Dart ↔ Python (`<caso>.json` + `<caso>.esperado.txt`; ver `fixtures/LEIAME.md`) |
| `listar_por_cenario.py` | lista as lições por cenário a partir do `encenacao_auto.json`; `--amostra --url` dá uma lição automática por cenário (e uma com figurante) com a URL do probe (`/?licao=<id>#/assistir-en`) para a prova visual |
| `exemplo_licao.json` | o exemplo oficial (plano §5.4) |
| `primeiro-contato.json`, `numeros-horas-soletrar.json` | o lote 1 (piloto) |
| `encenacao_auto.json` | a tabela das 602 lições (§15) |

Depois da integração, os 3 JSONs de conteúdo (`primeiro-contato.json`, `numeros-horas-soletrar.json`, `encenacao_auto.json`) moram em `assets/ingles/historias/` (é de lá que o app carrega); `montar_contexto_lote.py` e `listar_por_cenario.py` acham a tabela lá sozinhos. As ferramentas, a receita, o prompt, o exemplo e `fixtures/` ficam em `tools/ingles/historias/`.

Todos rodam com `python3 -I` (biblioteca padrão; nenhum depende da pasta atual). Os caminhos padrão são relativos ao repo quando a pasta está em `tools/ingles/historias/`, e caem em `/Users/fazplay/pac_dart` fora dele.
