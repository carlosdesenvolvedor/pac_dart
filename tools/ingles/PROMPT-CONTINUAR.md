ultracode — Continuar a geração do curso de inglês (PAC·ENGLISH) do app pac_dart: falta o nível C1+dev (o B2 já está no ar desde 6/out/2026).

CONTEXTO
- O app (Flutter web, pac-dart.web.app) já tem o 3º curso, de inglês, pronto e em produção com A1, A2, B1 e B2 completos
  (95 trilhas, 4.166 frases). Leia a memória do projeto (pac-english-vertente) e a seção "PAC·ENGLISH" do
  ESTADO-DO-PROJETO.md antes de começar.
- Tudo o que você precisa está em /Users/fazplay/pac_dart/tools/ingles/:
  - dados/esboco.json (120 trilhas / 595 lições; fonte única do curso), dados/DESIGN.md (contrato do conteúdo, §5.1),
    dados/IMAGENS.md (âncoras visuais obrigatórias), dados/pacotes.json (os pacotes de cada nível),
    dados/pesquisa/*.md (dossiês) e dados/pesquisa/fontes07/tatoeba_candidatas_en_ptbr.tsv (frases do Tatoeba).
  - dados/trilhas/<trilha>/NN.json: as lições já geradas e revisadas de A1, A2, B1 e B2.
  - workflow_gerar_trilhas.js (autor → revisor nativo EN → revisor PT/progressão por pacote), validar.js, integrar.py.
  - As fotos de TODAS as lições (inclusive B2, C1 e dev) já estão em assets/ingles/fotos/<id-da-lição>.jpg.

O QUE FAZER (um nível por vez, com deploy ao fim de cada um)
1. Copie tools/ingles/dados para o seu scratchpad (ex.: <scratchpad>/ingles) e use esse caminho como `scr`
   (os agentes do workflow só escrevem dentro de `scr`; nada de escrever direto no projeto).
2. B2: rode o Workflow com scriptPath /Users/fazplay/pac_dart/tools/ingles/workflow_gerar_trilhas.js e
   args = {"scr": "<scratchpad>/ingles", "projeto": "/Users/fazplay/pac_dart", "pacotes": <os 8 pacotes de "b2"
   em pacotes.json, cada um como {"nome", "trilhas"}>}. Cada pacote só vale com "RESULTADO: OK" do validador.
3. Quando o B2 terminar:
   a. copie <scratchpad>/ingles/trilhas/* de volta para tools/ingles/dados/trilhas/ (sem as pastas que começam com _);
   b. valide cada trilha: node tools/ingles/validar.js <pasta-da-trilha> --esboco tools/ingles/dados/esboco.json;
   c. integre: python3 tools/ingles/integrar.py tools/ingles/dados/trilhas tools/ingles/dados/esboco.json
      --etapas a1,a2,b1,b2 (acrescente --excluir t1,t2 para trilha que não passou);
   d. flutter test test/ingles_curriculo_test.dart (só o teste de volume pode falhar até o C1 entrar);
   e. flutter build web --no-wasm-dry-run && firebase deploy --only hosting --project=pac-dart;
   f. confira em produção (curl do assets/assets/ingles/curriculo.json) e avise o dono para dar Cmd+Shift+R.
4. C1+dev: mesmo processo com os 10 pacotes de "c1" e "dev" em pacotes.json; integre com
   --etapas a1,a2,b1,b2,c1,dev. Agora o teste de volume tem que passar (≥ 100 trilhas, ≥ 4.000 frases).
5. Depois do deploy final, atualize a memória do projeto e a seção PAC·ENGLISH do ESTADO-DO-PROJETO.md.

REGRAS
- Um nível por vez: rodar vários juntos queima a cota de 5 h em ~30 min (~7–8 milhões de tokens de agente por nível).
- Se o dono pedir para parar (cota acabando), pare o workflow na hora (TaskStop) e anote onde parou.
- Não faça commit nem push sem o dono pedir. Deploy de cada nível está autorizado.
- O progresso do inglês é guardado pelo id da lição (estável): trilhas novas entram sem bagunçar o que ele já fez.
