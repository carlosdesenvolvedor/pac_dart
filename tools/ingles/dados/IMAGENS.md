# PAC·ENGLISH — âncoras visuais (a parte "PNL" do método, só o que funciona)

Pedido do dono (4/out/2026): "usar programação neurolinguística no método, com imagens para eu repetir — precisa
ser funcional". A PNL como teoria não tem respaldo científico (estilos de aprendizagem VAK não se sustentam), mas três
práticas associadas a ela TÊM efeito medido na memória, e são elas que o curso usa:

1. **Codificação dupla (Paivio; efeito de superioridade da imagem):** palavra + imagem do sentido fixam mais que só a
   palavra. Cada frase tem uma imagem (`img`) mostrada junto da tradução em TODAS as digitações; nas de memória ela
   vira pista sem entregar o inglês.
2. **Memória ligada ao contexto (Godden & Baddeley; reinstalação do contexto):** aprender numa cena e reencontrar a
   mesma cena na hora de lembrar ajuda a recuperar. Cada lição tem a sua cena: foto real + emojis (`imagem`) +
   visualização guiada (`visualizacao`). A cena volta na revisão de cada frase.
3. **Visualização + produção em voz alta (production effect):** ver a cena por alguns segundos e dizer a frase em voz
   alta ao copiar. O app mostra o lembrete; o áudio en-US toca antes da cópia.
(+ Âncora de acerto: o app toca sempre o mesmo som e brilho quando a frase sai de memória.)

## Campos novos no JSON da lição (além do DESIGN.md §5.1)

| Onde | Campo | Obrigatório | Regra |
|---|---|---|---|
| lição | `imagem` | sim | 2 a 4 emojis que mostram a CENA (lugar + objeto + ação). Ex.: café → "☕🧁🧾", aeroporto → "✈️🧳🛂", daily remota → "💻🎧🗓️". |
| lição | `visualizacao` | sim | 1 a 2 frases em PT-BR, **2ª pessoa, presente, sensoriais** (o que você vê, ouve, sente), até 220 caracteres, coerentes com a `cena` e o elenco. Ex.: "Você está no balcão de um café em Chicago. Cheiro de café, fila andando, a atendente sorri e espera seu pedido." |
| lição | `foto_busca` | sim | 3 a 6 palavras em INGLÊS para achar uma foto real e genérica da cena num banco de imagens livres (sem marca, sem pessoa famosa). Ex.: "coffee shop counter barista", "airport check-in desk", "video call home office". |
| frase | `img` | sim | 1 a 3 emojis que mostram o **sentido** da frase (objeto, ação, emoção), concretos e fáceis de ver. Ex.: "Can I pay by card?" → "💳❓"; "I'm allergic to peanuts." → "🥜🚫"; "The build failed again." → "🏗️❌🔁". |

Regras do `img`:
- Mostre o SENTIDO, não as palavras: nada de letras/números, nada de emoji de texto (🆗, 🔤, 🅰️), nem 🇺🇸/🇧🇷 só
  para "inglês/português". Bandeira só quando o país É o conteúdo (Japan → 🇯🇵).
- Frases vizinhas da mesma lição não repetem o mesmo conjunto: varie para que cada imagem leve a UMA frase.
- Para frases abstratas (opinião, hipótese), use emoção + objeto da cena (🤔💭, 🙂👍) e o conjunto da lição.
- Emojis comuns (Unicode 13 ou anterior), que renderizam em qualquer navegador.
