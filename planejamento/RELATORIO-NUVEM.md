# Relatório da sessão na nuvem (22/out/2026)

Pedido: `planejamento/PROMPT-NUVEM.md`. Cada tarefa numa branch própria saindo do `main` (`8d78d55`), com commit e push. Sem deploy.

**Regra do dono (no meio da sessão):** só o curso de **inglês** muda; o Dart e o C# ficam como estavam.
- O Turismo 3D (`web/turismo3d/turismo3d.js`) e o `pintarTexto` do Arcade são compartilhados pelos 3 cursos. Por isso as mudanças neles só ligam no inglês: a chave `ingles` vai no config do `montar`, e o `pintarTexto` confere `Linguagem.atual`.
- Com Dart ou C#, o caminho é o de antes. O simulador do 3D deu números idênticos aos do `main`, e na pista da cidade o registro bate quadro a quadro.

## Como juntar

- **Ordem sugerida:** `arte-historias`, `desempenho-arcade`, `turismo-mundos`, `compreensao-licao`, `assistir-retoques`.
- **Conflitos:** só no `ESTADO-DO-PROJETO.md`, porque cada tarefa acrescenta a sua seção no fim. Resolva mantendo as duas partes.
- **`vista_3d_web.dart`:** as branches 2 e 4 acrescentam a mesma linha `'ingles'`, no mesmo lugar, e o git junta sem conflito.
- **Prova da junção:** juntei as 5 numa pasta à parte. O `flutter analyze lib test` não deu avisos e o `node --check` do JS passou. A suíte inteira está no fim deste relatório.
- **Tarefa 3 (C#):** cancelada pelo dono ("do C# nem no Dart é para mexer"). **Não junte a branch `claude/csharp-curriculo`**: o GitHub recusou apagá-la daqui. Ela corrigia 2 dos 5 testes; os outros 3 dependem de 11 trilhas e dos desafios de lógica, que nunca foram commitados. As 5 falhas continuam como estavam.

---

## 1) Cenários e objetos que faltaram nas histórias — `claude/arte-historias` (`a4e3ee5`)

**O que mudou:** agrupei os pedidos do `PEDIDOS-DE-ARTE.md` (a contagem está no topo do arquivo) e desenhei os 10 mais pedidos.

| O que foi pedido | Lições (aprox.) | Virou |
|---|---|---|
| telão / tela compartilhada | ~30 | prop `telao` |
| copa / máquina de café | ~14 | cenário `copa` |
| recepção de hotel | ~13 | cenário `recepcaoHotel` |
| quadro branco / kanban | ~13 | prop `quadroBranco` |
| sofá + TV | ~12 | cenário `salaDeEstar` |
| caixa de mudança | ~12 | prop `caixa` |
| bolo / torta | ~11 | prop `bolo` |
| caderno | ~10 | prop `caderno` |
| casaco | ~9 | prop `casaco` |
| taça | ~8 | prop `taca` |

- Os cenários têm as 4 horas e mostram um cômodo só em qualquer largura. No retrato há 2 filas, e a TV e o sofá não ficam atrás dos atores. Os valores entraram no fim dos enums (o Turismo não muda).
- As histórias tiveram 100 trocas de substitutos em 58 arquivos. Só mudaram cenário, prop e alvo; nenhum id de frase.
- A RECEITA §5.4 e o `montar_contexto_lote.py` foram atualizados.

**Testes:**
- `historia_*`, `turismo_historia_*`, `assistir_*`, `ingles_assistir_*`, `ingles_historias_licoes_conteudo` e `historias_licoes_paridade`: **628/628**.
- Novo: `historia_cenarios_licao2_test` (12).
- Validador `--pasta`: 0 erros, só o aviso de sempre (`prazer-ate-amanha`). `--auto-teste`: 59/59.
- **3 testes antigos mudaram de propósito**, cada um com comentário. Eles conferiam "os últimos N valores do enum", e a 2ª leva entrou depois; agora conferem a fatia de cada leva:
  - `historia_fundo_test`: a contagem passou de 111 para 123 pares de cenário e hora.
  - `historia_licao_modelo_test` e `historia_cenarios_licao_test`: a fatia 25..30 e a 24..28.
  - Continuam tão rígidos quanto antes.

**Ficou de fora:** os próximos da lista (carro por dentro / táxi, foto, crachá, cadeira, cozinha, bar, quintal com churrasqueira). Ainda há um notebook sobrando no chão da recepção em `check-in-tenho-uma-reserva`.

**Conferir no aparelho**, com o celular em pé e deitado:
- `situacao-hotel.check-in-tenho-uma-reserva` (a recepção);
- `perguntas-com-be.cena-um-colega-novo` (a copa);
- `there-is-lugares.em-cima-da-mesa-embaixo-do-sofa` (a sala);
- `conceder-rebater.dito-isso` (o telão).

## 2) Travadas nos jogos — `claude/desempenho-arcade` (`d33a5af`)

**A causa:** o Turismo 3D compilava shaders no meio da corrida.
- As luzes dos postes acendiam e apagavam com `visible`, o que muda o número de luzes no shader.
- As faíscas das fichas nasciam e morriam com material próprio, então o shader era apagado e recompilado a cada ficha.

**O que mudou (só no inglês):**
- **Luzes dos postes:** viraram um pool de 4 controlado pela intensidade.
- **Faíscas:** um material "guardião" fica compilado desde a preparação.
- **Texturas das placas e fichas:** sobem antes de aparecer, uma por quadro.
- **Tráfego:** os carros são achados por um índice, em vez de uma busca na lista.
- **`debug()`:** ganhou `programasNovosNaCorrida`.
- **Velocímetro:** o `pintarTexto` guarda o texto já medido.

**Medidas no simulador** (Leve, programas de shader compilados durante a corrida):

| Tema | `main` | Agora, no inglês |
|---|---|---|
| 3 (cidade) | 72 | **0** |
| 26 (estádio) | 71 | **0** |
| 1 (campina) | 26 | **0** |

Uploads de textura na corrida: de 129 para 94. Com Dart ou C#, os números são idênticos aos do `main`.

**Testes:** `arcade_*`, `turismo_*`, `progresso_turismo_30` e `engenheiro_gt`: **287/287**. Novo: `arcade_desempenho_test` (3), que inclui a prova de que fora do inglês não há cache.

**Suspeitos, sem mexer** (detalhes no ESTADO, rodada 19):
- o Leve ainda tem sombra PCF e luzes dinâmicas (desligar muda o visual: decisão sua);
- quando o jogo rebaixa a qualidade sozinho no meio da corrida, recompila tudo de uma vez;
- o `jsify` do estado inteiro a cada quadro;
- os pincéis dos tiros da Chuva, criados a cada quadro.

**Conferir no aparelho (no curso de inglês, Leve, na máquina que trava):**
- corra num mundo com postes (pistas 3, 17, 18, 25 ou 26) pegando fichas;
- no console, `turismo3d.debug().programasNovosNaCorrida` deve ficar em **0**;
- os postes iluminam como antes;
- no Dart, o Turismo continua igual.

## 3) Testes do C# — cancelada (ver "Como juntar")

## 4) Retoques nos mundos 3D — `claude/turismo-mundos` (`07c7176`)

**O que mudou (só no inglês; no Dart e no C# o motor segue igual):**
- **Aurora (pista 25):** 3 cortinas cobrindo o horizonte todo, de 4° a 20°, onde a câmera de perseguição enxerga. Antes eram 2, só para a frente da largada.
- **Estrelas (temas 15, 21, 23):** ~60% caem na vista (antes ~25%), com ponto de 2,8 px.
- **Cratera Lunar (pista 27):** céu preto com estrelas, no lugar do cinza com morros.
- **Tempestade de Areia (pista 18):**

  | | Antes | Agora |
  |---|---|---|
  | Grãos (Alto / Leve / Mínimo) | 900 / 450 / 180 | 1400 / 1120 / 490 |
  | Área em volta do carro | 140×160 m | 80×120 m |

  Usa o mesmo buffer, criado na montagem.
- **Mar (pista 16):** a textura é lida em duas escalas, então o padrão se repete a cada 140 m (antes 20 m), e as ondas acalmam com a distância.
- Nada é criado por quadro. O shader da água compila no `aquecer()`, e tudo é liberado no `destruir()`.

**Testes:** `turismo_*` e `progresso_turismo_30`: **131/131**. Novo: `turismo_mundos_ingles_test` (2), que confere a chave no config e os retoques presos a ela. `node --check` passou.

**Screenshots:** antes e depois no Chromium do Playwright, com renderização por software.

**Conferir no aparelho:**
- pista 18 no Leve: o FPS com 1120 grãos;
- pista 25: a aurora nas curvas;
- pista 27: o céu preto;
- pista 16: o mar na câmera alta e na de perseguição;
- uma pista no Dart e uma no C#: nada mudou.

A versão do módulo continua 30, então dê **hard refresh**.

## 5) Pergunta de compreensão depois da historinha — `claude/compreensao-licao` (`7d9ad7e`)

**O que mudou:** no fim do 📺 da lição aparece uma pergunta opcional.
- **Tipos:** "Quem disse «…»?" (só com 2 ou mais falantes) ou "O que significa «…»?", com 3 opções tiradas das frases da lição.
- **Escolha fixa:** a mesma lição sempre faz a mesma pergunta, porque a semente é o id da lição.
- **Resposta:** aparece na hora, verde ou vermelha, mostrando a certa.
- **Botões:** 🔊 ouvir, "Pular", "Ver de novo" e "Voltar para a lição".
- **Teclado:** 1/2/3 escolhem e Esc pula.
- **Progresso:** não grava nada.
- **Quando não aparece:** lição com menos de 3 frases, ou com resposta ambígua, fica sem pergunta.
- **Arquivos novos:** `domain/assistir/pergunta_compreensao.dart` e `ouvir/assistir/pergunta_assistir.dart`.

**Testes:** `ingles_assistir_pergunta_test` (9) e `ingles_assistir_pergunta_widget_test` (3), novos. `ingles_assistir_*` e `assistir_*`: **210/210**. PNG conferido em 360×640 e 1280×720.

**Conferir no aparelho:** a pergunta no celular em pé com texto ampliado; o 🔊 com a voz de verdade; o leitor de tela nas opções.

## 6) Pequenos retoques do 📺 — `claude/assistir-retoques` (`7f1f6dc`)

**O que mudou:**
- **Frase longa na chamada de uma fila:** o balão compacto usa a largura toda e a letra encolhe até 12 px, então fica em 2 linhas acima das cabeças. As molduras não pulam de tamanho, e o Turismo e o ⛶ continuam idênticos byte a byte.
- **Relógio do palco empurrado para fora sem rolagem:** um vigia de pintura refaz a conferência de visibilidade. No caminho, um `RepaintBoundary` fez o "Tocando agora" parar de se redesenhar a cada quadro (antes eram 63 vezes por segundo).
- **Emojis com gênero** (🙋‍♀️, 🙅‍♂️…): viram gesto, o que dá gesto a mais 58 frases nas lições automáticas.

**Testes:**
- `assistir_*`, `ingles_assistir_*` e `ingles_tocando_ui_test`: **218/218**.
- `historia_*` e `turismo_historia_*`: **434/434**, sem edição.
- 3 testes novos, cada um conferido falhando sem a sua correção.

**Conferir no aparelho:**
- o celular deitado com texto ampliado na chamada (a letra de 12 px ainda se lê bem?);
- o "Tocando agora" ficou mais fluido?

---

## Suíte inteira (as 5 branches juntas em cima do `main`)

`flutter test` (sem filtro) numa pasta à parte, com o `main` + as 5 branches juntas (só o `ESTADO-DO-PROJETO.md` precisou de resolução, mantendo as duas partes):

- **3.250 testes: 3.244 passam e 6 falham.** As 6 falhas já existem no `main` e não vêm destas branches:
  - as 5 do `csharp_curriculo_test`: faltam as trilhas e os desafios do C#, e a tarefa foi cancelada pelo dono;
  - `ingles_curriculo_test` "o motor digita toda frase…": estoura o limite de 30 s nesta máquina e falha igual no `main`.
- `flutter analyze lib test`: sem avisos.
- `node --check` do `turismo3d.js` juntado: ok. Há uma só declaração da chave `ingles` no config e no JS.
