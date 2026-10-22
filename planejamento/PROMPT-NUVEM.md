# Tarefas para a sessão na nuvem (Claude Code)

Você trabalha no repositório `pac_dart` (app Flutter web "Paclingo": bloc, nomes e textos em português). Leia antes:
`ESTADO-DO-PROJETO.md` (seções 🏁 rodada 14, 📺 rodadas 16–18) e `planejamento/RETOMAR-22-OUT-2026.md`.

## Regras
- **Flutter 3.41.2.** Se não estiver instalado, instale (canal stable, 3.41.2) antes de tudo e rode `flutter pub get`.
- **Uma branch por tarefa**, saindo do `main` atual: `claude/<tarefa>`, com commit e push ao final de cada uma. Assim o dono junta e publica cada tarefa separadamente.
- **Não** rode `dart format` em arquivos existentes (só nos arquivos novos, se quiser). Siga o estilo do código ao redor: comentários e nomes em português, tema Mixart.
- **Não** faça deploy (sem login do Firebase aqui). **Não** mexa na branch `lote-vozes-wip`. **Não** rode `tools/ingles/vozes_google.py` nem `bocas_rhubarb.py` (precisam da máquina do dono).
- Testes antigos **não** são editados para passar; se um precisar mudar de propósito, explique num comentário. As 5 falhas de `test/csharp_curriculo_test.dart` já existiam (a tarefa 3 trata delas).
- Antes de cada push: `flutter analyze lib test` sem avisos e os testes da área que você mexeu. Ao terminar todas as tarefas, rode a suíte inteira (`flutter test`) no `main` + a última branch, se der tempo.
- Para conferir desenho: gere PNGs com um teste de widget temporário (`RepaintBoundary.toImage`, com uma fonte TTF de verdade via `FontLoader` para a largura do texto ficar real), olhe as imagens e apague o teste. Nada de `flutter build web` em loop: no máximo um build de probe por tarefa, se precisar.
- Ao final, escreva `planejamento/RELATORIO-NUVEM.md` (no `main` não; numa branch `claude/relatorio`) com: por tarefa, a branch, o que mudou, os testes rodados e o que o dono precisa conferir no aparelho.

## Tarefas (nesta ordem de prioridade)

### 1. Cenários e objetos que faltaram nas histórias — branch `claude/arte-historias`
Leia `planejamento/historias-licoes/PEDIDOS-DE-ARTE.md`. Agrupe os pedidos repetidos e faça os **8 a 10 mais pedidos** (ex.: carro por dentro, recepção de hotel, banco/caixa, sofá com TV, quadro branco, quintal com churrasqueira), como cenários novos em `lib/features/arcade/presentation/historia/fundo_historia.dart` (mesmo estilo dos cenários de lição: interiores, as 4 horas, retrato com 2 filas, sem repetir o cômodo em telas largas) e objetos em `props_historia.dart`. Novos valores entram **no fim** dos enums (`historia_turismo.dart`), atualize `historia_licao.dart`/validadores (Dart e `tools/ingles/historias/validar_historias_licoes.py`, mantendo a paridade do `--auto-teste`). Depois troque os substitutos nas histórias de `assets/ingles/historias/` onde o pedido apontou e valide com `python3 -I tools/ingles/historias/validar_historias_licoes.py --pasta assets/ingles/historias`. O Turismo tem de ficar igual (testes `historia_*`, `turismo_historia_*`). Testes: `historia_*`, `assistir_*`, `ingles_historias_licoes_conteudo_test`, `historias_licoes_paridade_test`.

### 2. Travadas nos jogos (o dono: "mesmo no Leve ainda trava algumas partes") — branch `claude/desempenho-arcade`
Procure o que derruba quadros no navegador: rebuild por quadro sem mudança, alocação dentro de `paint`, `setState` em `Ticker` sem necessidade, listas recriadas a cada quadro, `shouldRepaint` sempre true, timers duplicados; e no Turismo 3D (`web/turismo3d/turismo3d.js`): geometrias/materiais criados por quadro, sombras e luzes no perfil Leve, culling, `PERFIS`. Corrija só o que for seguro, **sem mudar visual nem comportamento**. Meça antes/depois quando possível (contagem de builds/paints num teste, `debug()` do 3D). Testes: `arcade_*`, `turismo_*`, `engenheiro_gt_test`. Relatório do que mudou e do que ficou suspeito.

### 3. Os 5 testes do C# que falham — branch `claude/csharp-curriculo`
Faça os 5 testes de `test/csharp_curriculo_test.dart` passarem corrigindo o **conteúdo** do currículo C# (não enfraqueça os testes). Rode também os testes `csharp_*`.

### 4. Retoques nos mundos 3D do Turismo — branch `claude/turismo-mundos`
Em `web/turismo3d/turismo3d.js` (limites anotados no ESTADO, rodada 14): aurora (pista 25) e estrelas mais visíveis na câmera de perseguição; céu cinza da Cratera Lunar (27); mais partículas na Tempestade de Areia (18) no perfil Leve sem pesar; repetição visível da textura do mar (16). Respeite `PERFIS`, `cularPorDistancia`, `aquecer()` e libere tudo em `destruir()`. Confira com `node --check` numa cópia e com os testes `turismo_*`.

### 5. Pergunta de compreensão depois da historinha da lição — branch `claude/compreensao-licao`
No fim do 📺 da lição (`lib/features/ingles/presentation/ouvir/assistir/assistir_licao_page.dart`), mostre uma pergunta **opcional** sobre a história (3 opções, gerada das frases da lição — por exemplo "Quem disse …?" ou "O que significa …?"), com resposta na hora, botão de ouvir a frase e "Pular". Não grava progresso. Testes novos + `ingles_assistir_*`.

### 6. Pequenos retoques do 📺 (limites do ESTADO, rodadas 16–17) — branch `claude/assistir-retoques`
Os itens da lista "limites conhecidos" do 📺 que não dependem de aparelho: balão de 3+ linhas no celular deitado, o relógio do palco quando um layout empurra o palco para fora sem rolagem, e o que mais estiver anotado como pendente de código. Testes `assistir_*`, `ingles_assistir_*`, `ingles_tocando_ui_test`.

## Fora do escopo (fica para a máquina do dono)
Lote de vozes por personagem, Claude na Conversa (Cloudflare Worker), deploy no Firebase, lojas (Play Store / App Store).
