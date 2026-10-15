# Prompt para o agente — Fase 1A (Hábito diário)

> Cole o texto abaixo (tudo dentro do bloco) em um agente novo, sem contexto. Ele é autossuficiente.

````
Você vai implementar uma funcionalidade num app Flutter que já existe. Responda e escreva textos de interface sempre em português do Brasil.

## O projeto
O Paclingo (nome interno antigo: PAC·DART) fica em /Users/fazplay/pac_dart. É um app Flutter (web, com projetos Android/iOS em andamento), Dart ^3.11, flutter_bloc, Firebase (Auth + Firestore, projeto "pac-dart"). Ensina por DIGITAÇÃO: o aluno digita trechos de código (cursos Dart & Flutter e C# & .NET) ou frases em inglês (curso Inglês) e o app corrige e agenda revisões. Publicado em https://pac-dart.web.app.

## Sua tarefa
Implementar a **Fase 1A — Hábito diário**: sequência de dias (🔥), meta do dia em exercícios, congelamento (❄️) e as telas dessa funcionalidade. A especificação completa, com decisões já tomadas, modelo de dados, regras exatas, etapas, casos de borda e critérios de aceite, está em:

  /Users/fazplay/pac_dart/planejamento/FASE-1-HABITO-DIARIO.md

LEIA ESSE ARQUIVO INTEIRO ANTES DE ESCREVER CÓDIGO e siga-o. Faça só a Fase 1A (a seção 9, "Fase 1B — Lembrete", NÃO é sua tarefa: não adicione pacotes nem mexa em android/ ou ios/). Para contexto, leia também (sem implementar nada dali):
- /Users/fazplay/pac_dart/planejamento/MELHORIAS-PESQUISA.md (por que a fase existe e o que vem depois)
- /Users/fazplay/pac_dart/ESTADO-DO-PROJETO.md — é a fonte de verdade do estado do projeto. Leia o começo ("Rodar, testar, publicar"), a seção "🧪 Testes" e o trecho sobre o Anki/RevisaoCubit (é o padrão de cubit + repositório local/Firestore que você vai imitar).

Quando a especificação e a realidade do código divergirem, siga a realidade, escolha o caminho de menor intrusão e registre a divergência no relatório final. Nas "perguntas em aberto" da especificação, use o padrão indicado e registre.

## Regras de convivência com o repositório (importante)
1. A árvore de trabalho do git está SUJA com trabalho do dono que NÃO é seu (projetos android/ e ios/, branding/, preparação das lojas, e alterações dentro de vários arquivos, por exemplo lib/main.dart, lib/main_portfolio_probe.dart, lib/features/curso/presentation/widgets/hud.dart, lib/features/curso/presentation/pages/home_page.dart, pubspec.yaml). Antes de começar, rode `git status --short` e guarde essa lista.
2. Nesses arquivos já modificados, faça SÓ edições cirúrgicas (ferramenta de edição pontual) no trecho de que precisa. NUNCA rode `git checkout`, `git restore`, `git stash`, `git reset`, `git clean`, nem reformate/reescreva arquivo inteiro, nem apague pastas (`rm -rf`).
3. NÃO faça commit, NÃO faça push, NÃO publique (nada de `firebase deploy`) e NÃO altere `firestore.rules`. O dono pede commit/publicação quando quiser.
4. NÃO adicione dependências ao pubspec.yaml. A fase foi desenhada para não precisar.
5. Código novo deve parecer com o código vizinho: mesma densidade de comentários (em português, explicando o porquê), mesmos nomes e padrões (`Mixart.*` para cores/tipografia, padrão `Cubit.de(context)` que devolve null quando o cubit não existe na árvore — igual a `RankingCubit.de` e `RevisaoCubit.de`).

## Como trabalhar
- Siga as etapas 1 a 7 da especificação, em ordem, rodando os testes de cada etapa antes de seguir.
- Comandos: `flutter test <arquivo>`, `flutter test` (suíte inteira), `dart analyze lib test`. Baseline conhecido: a suíte tem 5 falhas ANTIGAS, todas em test/csharp_curriculo_test.dart (conteúdo do C# incompleto) — não tente consertá-las; elas devem continuar sendo as únicas.
- Escreva testes de verdade (domínio com tabela de casos, repositórios, cubit com repositório e relógio falsos, widgets, e um teste de app). Nos testes de widget use `Mixart.usarGoogleFonts = false;` e `SharedPreferences.setMockInitialValues({...})` (veja test/ingles_cartoes_ui_test.dart como modelo). Depois de escrever os testes, VALIDE-OS por mutação: quebre de propósito cada ponto crítico listado nos critérios de aceite, confirme que algum teste falha e então desfaça a quebra (faça backup do arquivo antes e restaure; confira com `diff`).
- Prova em navegador real (critério de aceite): faça um build do probe, `flutter build web -t lib/main_portfolio_probe.dart --output=build/probe_habito`, sirva com `python3 -m http.server 8793 --directory build/probe_habito` e use o Playwright (MCP) em http://localhost:8793/. ATENÇÃO: em Flutter web NÃO ligue a acessibilidade/semântica; dirija por coordenadas (`page.mouse.click`) e teclado. No probe, a tecla Esc passa a tela de "ensaio mental" do curso de inglês, e depois o HUD aparece no topo; "Mapa" → "Baralhos e cartões" leva à revisão. Teste em 1027 px e 390 px de largura (`browser_resize`) e confira o console. Ao final encerre o servidor (`pkill -f "http.server 8793"`).
- Pare e pergunte ao dono somente se algo exigir decisão que muda o produto (não para detalhes técnicos).

## Definição de pronto
Todos os itens da seção "Critérios de aceite" da especificação, mais:
- `ESTADO-DO-PROJETO.md` atualizado com uma seção "🔥 Hábito diário" (o que foi feito, decisões D1–D8, arquivos, testes e a contagem nova de testes na seção "🧪 Testes").
- Nenhum arquivo fora do escopo alterado. Ao final, compare `git status --short` com a lista do início: as únicas diferenças devem ser seus arquivos novos/alterados.

## Relatório final (formato)
1. O que foi entregue (3–6 linhas, em português simples, para quem não leu o código).
2. Lista de arquivos criados e alterados (e, nos que já estavam sujos, quais linhas você mexeu).
3. Resultado dos testes: nº de testes novos, resultado da suíte inteira (quantos passam/falham e confirmação de que as falhas são só as 5 antigas), `dart analyze`.
4. Mutações feitas e qual teste pegou cada uma.
5. Prova no Chrome: o que você viu (descreva as telas) e o que testou.
6. Divergências da especificação, decisões que você tomou e riscos/pendências.
7. Confirmação explícita: nada commitado, nada publicado, firestore.rules intacto.
````
