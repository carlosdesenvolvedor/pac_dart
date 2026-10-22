# Retomar daqui (22/out/2026)

O trabalho parou por limite de sessão. O que está no ar e o que ficou pela metade:

## No ar (main, deploy feito)
- 🏁 English Turismo com 30 pistas e a história "The Golden Wheel" (velocidade 1×/.85×/.7×/.5×, voltar falas).
- 📺 Escutar assistindo no 🎧 Ouvir: desenho automático nas 602 lições + histórias escritas nas trilhas A1, A2, B1 e B2 (96 trilhas, `assets/ingles/historias/`).
- Detalhes em `ESTADO-DO-PROJETO.md` (seções 🏁 rodada 14 e 📺 rodada 16).

## Pela metade
1. **📺 na lição (prioridade do dono).** Ainda não começou no código. Ideia: link "📺 Assistir a historinha" no começo da lição (ao lado de "🎬 rever o ensaio mental", `palco_ingles.dart`), botão na tela de vitória e opção `sheet-assistir` na folha da lição do mapa (`mapa_page.dart`, molde do `onPalavras`). Abrir pausa voz/teclas como o `_conhecerAntes` e volta ao mesmo ponto; não mexe no progresso. Decidir antes se usa o `OuvirCubit` global ou um player próprio da lição (preferível: não bagunçar a fila do Ouvir).
2. **Histórias do C1 e Dev (25 trilhas).** Rascunhos já VALIDADOS em `tools/ingles/historias/rascunhos_c1_dev/` (alguns sem a passada do revisor). Para publicar: revisar (receita em `tools/ingles/historias/RECEITA.md`), copiar para `assets/ingles/historias/`, acrescentar no `indice.json` e rodar `flutter test test/ingles_historias_licoes_conteudo_test.dart`.
3. **Lote de voz por personagem.** Branch `lote-vozes-wip` (NÃO está no main): troca as ~410 gravações do Tatoeba pela voz Chirp do personagem e dá mp3 por personagem à história do Turismo (max/kim/narrador incluídos). Parado durante a geração/revisão; falta revisar, rodar a suíte e a prova no navegador. Plano em `planejamento/historias-licoes/PLANO-VOZES.md`. Precisa de `gcloud` logado (projeto `music-system-421ee`), Rhubarb e ffmpeg — só roda na máquina do dono. ATENÇÃO: `tools/ingles/vozes_google.py` apaga mp3 órfãos; rodar o modo de simulação antes.

## Plano do 📺
`planejamento/historias-licoes/PLANO.md` (arquitetura, regras do conteúdo, receita de lotes).
