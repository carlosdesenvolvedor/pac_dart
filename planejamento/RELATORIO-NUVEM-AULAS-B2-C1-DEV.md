# Relatório da nuvem — 🎓 aulas longas do Prof. Beto: B2, C1 e DEV

Branch `claude/aulas-b2-c1-dev` (a partir do `main` 8ad1c5d). Feito conforme `planejamento/PROMPT-NUVEM-AULAS.md`:
para cada trilha, três subagentes em sequência (autor → revisor → verificador adversarial), até 5 trilhas ao mesmo
tempo; a cada trilha ✓, cópia para `assets/ingles/aulas/<slug>.json`, commit `🎓 Aula longa: <slug> (<nível>)` e push.

## Resumo

- **47 de 47 trilhas ✓** (B2 22 · C1 14 · DEV 11) — **243 aulas**, todas aprovadas pelo
  `validar_aulas.py` (rodado de novo no fim sobre os 47 arquivos em `assets/ingles/aulas/`: 47 ✓, saída 0).
- **Duração:** mínimo 7,0 · máximo 9,4 · média 8,4 min por aula (soma ≈ 33,9 h de aula falada). Nenhuma fora de 6–10.
- **Nenhuma trilha precisou de rodada extra** nem foi pulada.
- **Só arquivos novos em `assets/ingles/aulas/`** (47 arquivos, nada mais no diff contra o `main`). Não mexi em
  `indice.json`, `web/aula_voz/`, validador, `PROMPT_AULAS.md`, currículo nem código; não rodei vozes nem bocas; sem deploy.
- **Formato:** os arquivos estão no mesmo formato do A1 (2 espaços, uma fala por linha). Houve um commit só de
  formatação (`ebe85ad`) para as 3 primeiras trilhas, sem mudar conteúdo.
- A2 e B1 não foram tocados.

### Observações de processo
- O verificador de `dev-planning-retro` achou **frases em inglês errado dentro de falas "en"** (a voz leria como certo).
  Elas foram para o "quadro" marcadas como erro; uma busca nas trilhas já entregues não achou outro caso (depois o revisor de
  `dev-code-review` achou e corrigiu mais um, "Do you know why did...?"). A partir
  daí o pedido ao autor passou a dizer que forma errada vai só no quadro.
- Os autores em paralelo dividiam a mesma pasta de rascunho e chegaram a sobrescrever scripts uns dos outros. Nada se
  perdeu nos JSON finais (conferido: cada arquivo só tem lições da própria trilha). Depois disso, uma pasta por trilha.
- A partir da 1ª leva, o pedido ao autor também proíbe números, datas, leis locais e fusos, e manda deixar termos de
  dev fora das falas "pt" — vários revisores tinham cortado exatamente isso (galão em litros, regra de Nova Jersey,
  horário de verão do Brasil, imposto do Oregon, horas de diferença com Londres, região de nuvem em Ohio…).
- Alguns revisores/verificadores não conseguiram abrir o Etymonline (sem rede) e conferiram etimologias de memória;
  nesses casos a regra foi cortar o que não fosse garantido.

## Duração de cada aula (min, pela `validar_aulas.minutos`)

### B2

| trilha | ✓ | aulas | minutos de cada aula |
|---|---|---|---|
| `tempos-narrativos-completos` | ✓ | 5 | fazia-horas-que-eu-estava-trabalhando 9,1 · fazia-tempo-que-voce-esperava 9,1 · tinha-feito-x-vinha-fazendo 8,5 · os-quatro-tempos-numa-historia 7,8 · cena-a-semana-da-release 7,8 |
| `futuro-avancado` | ✓ | 5 | ate-sexta-vamos-ter-terminado 9,2 · quando-voce-acordar-ja-mandei 8,7 · vai-fazer-dez-anos-que 8,0 · prestes-a-sair-provavel-chuva 8,4 · cena-o-roadmap-da-demo 7,9 |
| `passiva-2` | ✓ | 6 | esta-sendo-consertado 9,2 · ja-foi-feito 8,3 · deveria-ter-sido-enviado 7,6 · mandei-consertar 7,3 · ouvi-dizer-que-e-a-previsao 7,3 · cena-status-de-um-incidente 7,9 |
| `deducao-no-passado` | ✓ | 5 | devo-ter-deixado-no-escritorio 9,3 · nao-pode-ter-sido-ele 8,6 · por-que-o-build-quebrou 8,3 · nao-precisava-didn-t-have-to 8,0 · cena-o-misterio-do-e-mail 7,8 |
| `wish-condicionais-mistas` | ✓ | 6 | queria-ter-mais-tempo 9,4 · queria-ter-estudado-mais 9,0 · queria-que-ele-parasse 7,4 · prefiro-ja-esta-na-hora 7,3 · se-eu-tivesse-aceitado-estaria 8,0 · cena-escolhas-de-carreira 7,2 |
| `situacao-carro-estrada` | ✓ | 4 | alugando-o-carro 9,0 · na-estrada-e-no-posto 9,1 · estacionamento-e-multa 8,5 · o-carro-deu-problema 8,5 |
| `dev-planning-retro` | ✓ | 5 | quantos-pontos-isso-vale 9,3 · qual-e-o-trade-off 8,5 · entendo-seu-ponto-mas 7,8 · o-que-foi-bem-nesta-sprint 7,6 · cena-a-retro-do-sprint-ruim 7,9 |
| `verbos-de-relato` | ✓ | 5 | ela-sugeriu-adiar-a-demo 9,0 · ele-admitiu-ter-errado 8,8 · avisaram-esperam-nao-permitem 8,1 · ofereceu-recusou-prometeu 7,4 · cena-a-ata-da-reuniao 7,3 |
| `habitos-costume` | ✓ | 5 | a-gente-passava-o-verao-na-praia 8,8 · estou-acostumado-a 9,1 · voce-vai-se-acostumar 7,9 · ele-fica-me-interrompendo 8,1 · cena-um-ano-depois-da-mudanca 8,4 |
| `relativas-3` | ✓ | 5 | o-que-surpreendeu-todo-mundo 9,0 · as-pessoas-com-quem-eu-trabalho 7,7 · o-time-com-quem-falamos 7,7 · os-arquivos-guardados-no-servidor 8,3 · cena-arquitetura-e-noticias 8,0 |
| `dev-code-review` | ✓ | 6 | detalhe-tem-um-typo-aqui 9,1 · isso-pode-causar-problema 8,9 · voce-poderia-adicionar-um-teste 8,6 · bloqueante-ou-nao 8,2 · bem-observado-resolvido 8,0 · cena-uma-revisao-completa 8,8 |
| `argumentar-conectores` | ✓ | 6 | apesar-da-chuva 9,0 · enquanto-eu-por-outro-lado 8,8 · ainda-assim-portanto 8,5 · por-um-lado-por-outro 7,4 · resumindo-no-geral 7,4 · cena-remoto-ou-presencial 7,5 |
| `enfase-inversao-clivadas` | ✓ | 5 | nunca-vi-um-lugar-tao-bonito 9,1 · mal-sentei-o-celular-tocou 8,9 · o-que-eu-preciso-e-de-ferias 8,9 · o-motivo-pelo-qual-escrevo 9,0 · cena-pedido-e-experiencia 8,5 |
| `phrasal-verbs-b2` | ✓ | 5 | se-dar-bem-e-nao-decepcionar 9,1 · deu-certo-valeu-a-pena 9,1 · investigar-e-descartar 9,1 · assumir-e-levantar-um-assunto 8,9 · cena-planejar-a-migracao 8,7 |
| `situacao-telefone-reclamacao` | ✓ | 4 | esperando-na-linha 9,3 · cobranca-errada 9,1 · a-internet-caiu-de-novo 8,1 · cancelar-o-plano 8,8 |
| `colocacoes-expressoes` | ✓ | 6 | tomar-uma-decisao 8,8 · fazer-uma-pausa-prestar-atencao 7,9 · transito-pesado-prazo-apertado 7,9 · aconteca-o-que-acontecer 7,7 · antes-de-mais-nada 7,9 · cena-noticia-ruim-com-educacao 8,0 |
| `funcoes-conversa-b2` | ✓ | 6 | meu-palpite-e-que 9,2 · boa-pergunta-deixa-eu-pensar 9,0 · vamos-ouvir-a-ana 8,6 · isso-eu-consigo-aceitar 8,8 · mentira-nao-acredito 8,5 · cena-negociar-e-reagir 8,6 |
| `dev-incidentes` | ✓ | 6 | o-servidor-caiu 8,8 · ainda-estamos-investigando 9,0 · revertemos-o-deploy 8,7 · a-causa-raiz-foi 8,7 · postmortem-sem-culpados 8,8 · cena-sexta-a-noite 8,9 |
| `escrita-formal` | ✓ | 5 | escrevo-para-solicitar 8,5 · escrevo-para-reclamar 8,1 · infelizmente-nao-podemos 7,4 · obrigado-pela-paciencia 7,1 · cena-a-reclamacao-completa 7,2 |
| `resenhar-criticar` | ✓ | 5 | confuso-entediado-decepcionante 9,1 · bem-bom-simplesmente-incrivel 9,1 · de-longe-o-melhor 8,7 · nao-correspondeu-as-expectativas 8,4 · cena-avaliar-a-ferramenta-nova 8,6 |
| `registro-variantes` | ✓ | 4 | eu-entendo-sim 9,0 · para-a-chefe-e-para-o-amigo 9,0 · digitar-americano-reconhecer-britanico 8,9 · cena-dois-registros 8,7 |
| `revisao-b2` | ✓ | 4 | lancamento-adiado-propor-e-objetar 9,2 · negociar-prazo-e-escopo 8,7 · debate-sobre-prioridades 8,3 · checkpoint-resumo-e-decisao 7,4 |

### C1

| trilha | ✓ | aulas | minutos de cada aula |
|---|---|---|---|
| `inversoes-escrita-formal` | ✓ | 5 | nao-so-como-tambem-relatorio 9,1 · em-hipotese-alguma-politica 7,8 · caso-precise-should-you-had-we-e-mail 8,1 · contanto-que-caso-contrario 7,3 · cena-discurso-de-fim-de-ano-e-e-mail 7,7 |
| `clivadas-fronting` | ✓ | 5 | foi-a-ana-quem-achou 9,1 · foi-so-na-sexta-que 9,2 · o-que-a-gente-fez-foi-clivada-com-verbo 8,6 · por-mais-estranho-que-pareca 8,2 · cena-final-pingos-nos-is 8,6 |
| `modalidade-avancada` | ✓ | 5 | na-certa-vai-dar-problema 9,0 · pode-muito-bem-ser 8,7 · bem-que-a-gente-podia 7,9 · o-certo-era-ter-avisado 7,4 · cena-final-o-go-no-go 8,1 |
| `passivas-impessoais` | ✓ | 5 | acredita-se-amplamente-que 8,9 · ele-teria-saido-da-empresa 8,0 · tendo-sido-avisados 7,8 · teria-sido-to-have-been-participio 7,7 · cena-final-relatorio-a-diretoria 7,4 |
| `hedging-registro` | ✓ | 6 | umas-trinta-pessoas 9,1 · meio-que-pisca 7,8 · eu-diria-que 7,9 · ao-que-parece-ate-certo-ponto 7,3 · mesmo-recado-dois-registros 7,3 · cena-final-estimativa-e-relatorio 7,0 |
| `conceder-rebater` | ✓ | 6 | e-verdade-que 8,6 · dito-isso 8,2 · tudo-bem-mesmo-assim 7,5 · pode-se-argumentar-que 7,5 · embora-eu-concorde 7,6 · cena-final-debate-com-a-diretoria 7,6 |
| `situacao-vida-social` | ✓ | 5 | small-talk-o-jogo-e-o-fim-de-semana 9,1 · thanksgiving-na-casa-da-emma 8,6 · o-ben-em-curitiba 8,1 · saindo-com-o-time-a-rodada-e-a-conta 8,1 · conversa-que-nao-e-de-trabalho 8,5 |
| `nominalizacao-participiais` | ✓ | 6 | a-implementacao-do-sistema 9,1 · uma-diminuicao-nos-erros 7,9 · tendo-terminado-o-relatorio 8,2 · construido-em-2009 8,6 · se-for-se-nao-substituicao 7,6 · cena-final-atualizacao-executiva 7,6 |
| `idioms-colocacoes-fortes` | ✓ | 6 | vamos-encerrar-por-hoje 9,1 · e-moleza-sem-atalhos 9,1 · vitorias-faceis-e-numeros-por-alto 8,6 · voltamos-a-estaca-zero 8,2 · colocacoes-fortes-de-trabalho 8,5 · cena-final-papo-de-corredor 7,6 |
| `precisao-lexical` | ✓ | 5 | sensato-e-abrangente 8,9 · sensivel-compreensivo-antecipar 8,0 · palestra-romance-e-fantasia 8,2 · alegar-afirmar-enorme 8,2 · cena-final-e-mail-e-apresentacao 8,4 |
| `phrasal-verbs-c1` | ✓ | 5 | o-que-provocou-isso 9,2 · por-se-a-fazer-e-dar-conta 8,4 · escalar-e-passar-o-bastao 8,2 · deixar-claro-e-estabelecer-regras 7,8 · cena-final-a-origem-e-a-escala 7,8 |
| `ingles-tecnico-academico` | ✓ | 6 | ate-que-ponto-ler-um-artigo 8,9 · dar-origem-a-e-responder-por 9,0 · levar-em-conta-e-a-luz-de 8,6 · em-conformidade-com-a-especificacao 9,0 · por-meio-de-a-secao-de-resultados 8,7 · cena-final-o-artigo-e-os-resultados 8,0 |
| `conversa-natural-c1` | ✓ | 5 | nem-me-fale 8,9 · nem-ai-e-nao-e-a-toa 8,1 · justica-seja-feita 8,4 · falar-e-facil 7,7 · cena-final-happy-hour-com-o-time 7,3 |
| `revisao-c1` | ✓ | 4 | apresentacao-para-a-diretoria 8,5 · post-mortem-de-um-incidente 8,5 · negociacao-de-prazo-e-escopo 7,9 · checkpoint-c1-um-ano-de-tech-lead 7,3 |

### DEV

| trilha | ✓ | aulas | minutos de cada aula |
|---|---|---|---|
| `pro-entrevista-senior` | ✓ | 6 | fale-de-voce-versao-senior 9,2 · contar-um-caso-o-contexto 8,5 · contar-um-caso-acao-e-resultado 7,9 · live-coding-pensar-em-voz-alta 7,5 · negociar-a-oferta-e-o-modelo-remoto 7,5 · cena-a-entrevista-completa 7,4 |
| `pro-design-sistemas` | ✓ | 6 | requisitos-e-estimativas 9,2 · propor-a-arquitetura 8,8 · dados-replicas-e-particoes 9,1 · filas-e-pontos-de-falha 9,0 · trade-offs-e-defender-escolhas 8,1 · cena-a-sessao-de-system-design 8,4 |
| `pro-code-review-avancado` | ✓ | 5 | rotulos-de-severidade 9,1 · discordar-com-tato 8,8 · defender-a-sua-decisao 7,7 · revisar-o-codigo-de-um-junior 8,3 · cena-o-pr-polemico 7,8 |
| `pro-escrita-tecnica` | ✓ | 6 | rfc-contexto-e-motivacao 9,0 · alternativas-e-desvantagens 8,4 · escopo-compatibilidade-e-rollout 7,9 · adr-registrar-a-decisao 8,3 · descricao-de-pr-e-changelog 8,4 · cena-a-rfc-da-nova-api 8,0 |
| `pro-incidentes-comunicacao` | ✓ | 5 | declarar-e-coordenar-o-incidente 9,0 · pagina-de-status-para-clientes 8,4 · linha-do-tempo-e-causa-raiz 7,8 · postmortem-sem-culpados 8,3 · cena-postmortem-com-a-diretoria 7,9 |
| `pro-apresentacoes-demos` | ✓ | 5 | abrir-e-mostrar-o-roteiro 9,3 · conduzir-a-demo 8,2 · transicoes-e-mensagem-principal 8,2 · perguntas-dificeis-e-encerramento 8,1 · cena-demo-na-sprint-review 7,4 |
| `pro-negociar-prazo-escopo` | ✓ | 5 | prazos-realistas 9,1 · dizer-nao-com-tato 8,5 · propor-alternativas-e-cortar-escopo 7,4 · alinhar-prioridades-e-expectativas 7,3 · cena-o-cliente-impaciente 7,5 |
| `pro-lideranca-feedback` | ✓ | 5 | conduzir-um-1-1 8,9 · dar-feedback-construtivo 9,0 · receber-criticas 8,4 · delegar-e-mentorar 8,0 · cena-avaliacao-de-desempenho 7,5 |
| `pro-clientes-email-formal` | ✓ | 5 | abrir-e-fechar-e-mails-formais 9,0 · comunicar-atrasos 9,1 · recusar-pedidos-com-elegancia 9,0 · pedir-desculpas-e-escalar 9,0 · cena-o-cliente-irritado 8,2 |
| `pro-carreira-networking` | ✓ | 4 | puxar-conversa-num-evento 9,1 · apresentar-o-que-voce-faz 8,9 · trocar-contatos-e-manter-contato 9,1 · cena-um-dia-de-conferencia 8,3 |
| `pro-dia-de-trabalho` | ✓ | 4 | manha-standup-e-mensagens 9,0 · meio-do-dia-design-e-code-review 8,9 · tarde-incidente-cliente-e-prazo 8,5 · fim-do-dia-1-1-e-mail-e-papo 8,3 |


## Correções do verificador (1 linha por trilha)

### B2
- `tempos-narrativos-completos` — regra de "had been + -ing" restrita a um ponto do passado; "cleared the sidewalk" (neve); tradução "Eu vinha pintando a sala"; generalização sobre pais americanos cortada.
- `futuro-avancado` — regra de *earlier* (y→i); *retire* suavizado; *likely that* + will só para futuro; "likely to love".
- `passiva-2` — anedota das obras em Chicago cortada; sede aceita singular/plural; desafio "before deployment"; 🦋→🐛.
- `deducao-no-passado` — pronúncia de must've/couldn't've; *laundry basket*; *advise* também = informar; desafio "might have fallen out in the car".
- `wish-condicionais-mistas` — "o inglês perdeu o subjuntivo" → "aparece pouco"; *prefer* + to/-ing; exceção educada "If you would follow me".
- `situacao-carro-estrada` — regra de Nova Jersey cortada; CEP na bomba com ressalva; "have dinner, sem artigo".
- `dev-planning-retro` — 2 frases erradas tiradas de falas "en" e postas no quadro; th sonoro = garganta vibrando.
- `verbos-de-relato` — *refuse* (lixo) também muda o som final; *minutes* sem a hipótese "letra miúda"; *still hasn't* existe.
- `habitos-costume` — exceção *we'd better*; "horário de Brasília"; percent × per cent; *start* aceita -ing.
- `relativas-3` — fusos com números cortados; mito da preposição sem "vem do latim"; Maratona = lugar, mensageiro = lenda.
- `dev-code-review` — regra inventada "dois-pontos, nunca parênteses" cortada; falso cognato é *actual*, não *current*.
- `argumentar-conectores` — erro na lousa "I focus myself"; never+the+less (o "the" antigo); "see you Tuesday" sem preposição nos EUA.
- `enfase-inversao-clivadas` — *such* + artigo no singular; *impressed with/by*; "All that we need is" é correto (o erro é o *of*).
- `phrasal-verbs-b2` — *on/in the team*; "What did come up?" não é erro; *roll out* não é necessariamente aos poucos.
- `situacao-telefone-reclamacao` — *on hold* (substantivo); *ticket number* no lugar de *confirmation number*; *look into* tônico no verbo.
- `colocacoes-expressoes` — percent × per cent; "I'll be ten minutes late" = futuro simples; *take a note of* existe.
- `funcoes-conversa-b2` — *Chances are (that)*; question tag com auxiliar/be; entonação de "No way!".
- `dev-incidentes` — origem de *page/pager* estava invertida (revisor); *heads up* só como imagem; "Identified the root cause." = cortado, não erro.
- `escrita-formal` — "I write to request" → evite; estatística de *I'm afraid* cortada; *place an order* (make an order existe).
- `resenhar-criticar` — *absolutely* aceita a força em dois lugares; *paperback* = capa mole.
- `registro-variantes` — *could* = passado de *can* como cortesia; com dia da semana o normal é *on*; *slippery* "da mesma família de".
- `revisao-b2` — *deadline* sem Guerra Civil nem tiro; *unrealistic*; dívida técnica "tratada como incontável".

### C1
- `inversoes-escrita-formal` — *far better* = reforço; *should* + forma base; *provide* = olhar adiante, prever.
- `clivadas-fronting` — "rastrear" é de outra raiz; motivo inventado do nome "pseudoclivada" trocado.
- `modalidade-avancada` — *book* = registrar num livro; *ought* (g e h mudos); *caught* = particípio.
- `passivas-impessoais` — "a half of" → "half of"; *merger* via anglo-francês; erro "o português nega duas vezes" corrigido.
- `hedging-registro` — "in mid-June"; *reddish* no lugar de *tired-ish*; *extent* forte na 2ª sílaba.
- `conceder-rebater` — erro típico real "I must to admit"; *from* no fim da frase sai na forma forte; *call* sem origem no esporte.
- `situacao-vida-social` — duplo sentido em português ("ter alguém por cima") trocado; *excited* tem sim outro sentido.
- `nominalizacao-participiais` — *it's* = it is / it has.
- `idioms-colocacoes-fortes` — *cut corners* e *square one* só como truque de memória (origem incerta); flap do t em *quarter*.
- `precisao-lexical` — *prejudice* também = dano; pronúncia de *claims*; *it* antecipatório.
- `phrasal-verbs-c1` — verbo como sujeito: o natural é -ing; *make out* "costuma" vir com can/could ("make out with" foi cortado pelo revisor).
- `ingles-tecnico-academico` — *whether* = pergunta embutida; *based in* = tem sede em.
- `conversa-natural-c1` — regra do comparativo (1 sílaba ou 2 em -y); *news* nasceu como plural de *new*; ditado incerto trocado.
- `revisao-c1` — *percents* existe (raro); *make a presentation* é correto; *provided* = "estipulado que".

### DEV
- `pro-entrevista-senior` — *mentor* (a palavra vem do nome); "at my last company" mais natural que "in", não erro.
- `pro-design-sistemas` — pronúncia de *partition* estava errada (chiado só no -tion); *cache* sem história incerta.
- `pro-code-review-avancado` — *shard* caído = dados fora do ar (não somem); *treatment* incontável.
- `pro-escrita-tecnica` — *supercede* = evite (variante menos comum); *log* (madeira do navio → logbook) confirmado.
- `pro-incidentes-comunicacao` — *It took us* = it antecipatório; *expire* (sentidos diferentes nas duas línguas); deploy ≠ publicação.
- `pro-apresentacoes-demos` — past simple "não é erro, só não marca a mudança"; *this quarter* = período aberto.
- `pro-negociar-prazo-escopo` — *stretched thin* estava explicado ao contrário (= pouca gente para trabalho demais).
- `pro-lideranca-feedback` — *realize* = realizar só no formal (carry out a task).
- `pro-clientes-email-formal` — "tr" de *deer* "Veado" → "Cervo"; *recommend you to use* = evite (Oxford registra como formal); ⚡ tirado de Wednesday.
- `pro-carreira-networking` — "Yes, I mind." tirado do quadro; *also* antes do verbo principal ou depois de be/auxiliar.
- `pro-dia-de-trabalho` — pronúncia de *async* e *queue* sem letras do português; "It's been a long day." no quadro.

## Dúvidas para o dono

### 1. Códigos internos vazados no `curriculo.json`
Prefixos tipo `BRnn:` aparecem no texto da teoria (o aluno vê). As aulas não os leem.
BR01 `clivadas-fronting.cena-final-pingos-nos-is` · BR28 `inversoes-escrita-formal.contanto-que-caso-contrario` ·
BR41 `resenhar-criticar.cena-avaliar-a-ferramenta-nova` · BR42 `modalidade-avancada.bem-que-a-gente-podia` ·
BR53 `clivadas-fronting.foi-so-na-sexta-que` · BR57 `inversoes-escrita-formal.caso-precise-should-you-had-we-e-mail` e
`…cena-discurso-de-fim-de-ano-e-e-mail` · BR58 `dev-incidentes.cena-sexta-a-noite` ·
BR60 `phrasal-verbs-b2.cena-planejar-a-migracao` e `phrasal-verbs-c1.o-que-provocou-isso`.

### 2. Erros ou exageros no currículo (as aulas NÃO repetem; vale corrigir a teoria/notas)
- **Marcado como errado, mas é correto ou só menos comum:**
  "It's probable that the meeting runs late" (futuro-avancado; com *will run* é gramatical) ·
  "at the weekend" e "Has he got…?" (habitos-costume; são britânicos) · "the guy sat next to…" (relativas-3) ·
  "Have a minute?" (registro-variantes; elipse informal) · "What we did was to roll back" (clivadas-fronting) ·
  "be disposed to" (funcoes-conversa-b2; raro/formal) · "complain of" (escrita-formal; existe para sintomas) ·
  "we applied already" (dev-incidentes; americano informal) · "Identified the root cause." (dev-incidentes, BR58; é forma cortada de status) ·
  "revenues" (revisao-b2; existe em finanças) · "well good" e "main actress" (resenhar-criticar) · "recommend you to use" (pro-clientes-email-formal; raro/formal) ·
  "say to Ana" (pro-dia-de-trabalho; "say something to Ana" é certo) · "Did you go… so far?" (pro-carreira-networking; americano informal) ·
  "in my last company" (pro-entrevista-senior; *at* é mais natural) · "proposes to cache", "out of scope of", "we never ran" (pro-escrita-tecnica) ·
  past simple no lugar de *used to* (pro-apresentacoes-demos) · "I'm testing it for a month" (resenhar-criticar; certo como plano).
- **Regras absolutas demais:** "Nunca would depois de if" (wish-condicionais-mistas, revisao-c1; existe "if you would…" de cortesia) ·
  "assume = supor (não: assumir)" (dev-planning-retro, phrasal-verbs-b2, revisao-b2, pro-lideranca-feedback; existe *assume responsibility/control*) ·
  "não: discard" (revisao-b2) · "não: bigger" para delay e "o hífen faz parte de seven-ish" (hedging-registro; *sevenish* existe — o app aceita as duas na digitação?) ·
  "in the long term = só de texto" (conceder-rebater) · "wind up = tom de resultado ruim" (phrasal-verbs-c1) ·
  "roll out = lançar aos poucos" (phrasal-verbs-b2) · whereas/while "vêm depois de vírgula" (argumentar-conectores) ·
  "adjetivo curto faz -er" (conversa-natural-c1; *easy* tem duas sílabas) · "Try as we might pede a principal no passado" (clivadas-fronting) ·
  "para empresa, o pronome é it" (modalidade-avancada; a própria lição usa *They*) · "escalate it: o inglês pede o objeto" (pro-clientes-email-formal) ·
  objeto obrigatório em "check it"/"on it" (pro-dia-de-trabalho) · "help someone get started (sem to)" (pro-lideranca-feedback; o to é opcional) ·
  "Deadline is Monday" sem preposição (revisao-b2; *is on Monday* também é certo) · "high season é raro nos EUA" (ingles-tecnico-academico) ·
  "bring forward é britânico, nos EUA move up" (precisao-lexical) · "por extenso até dez: one percent, mas 80 percent" (pro-entrevista-senior; é convenção de manual de estilo).
- **Notas erradas ou enganosas:** "pick this back up… não: resume, que é currículo" (dev-planning-retro; o verbo *resume* = retomar) ·
  *stretched thin* = "gente demais fazendo coisa demais" (pro-negociar-prazo-escopo; é o contrário) ·
  "Why didn't you use… (não: added)" (pro-design-sistemas; parece trocado, o erro seria *used*) ·
  "eventually também é no fim" (pro-code-review-avancado; não se troca na frase) ·
  "last = o último de uma série que terminou" (dev-code-review; também = o anterior) ·
  nota de All we need "sem that e sem of" (enfase-inversao-clivadas; o *that* é opcional) ·
  "support (não é suporte técnico)" (enfase-inversao-clivadas; também pode ser) ·
  *boil down to* comparado com *summarize* (phrasal-verbs-c1; está mais perto de "se resumir a") ·
  "Sincerely = Cordialmente / Best regards = Atenciosamente" (escrita-formal; par discutível) ·
  "ground floor é britânico" (registro-variantes; também nos EUA) · "ought to = mais firme e formal que should" (modalidade-avancada; discutível).
- **Promessas da trilha que as frases não cumprem:** passiva-2 promete "It is said that" (a lição deixa para o C1) ·
  deducao-no-passado promete *can't have* e *needn't have × didn't need to* (frases só têm *couldn't have*) ·
  verbos-de-relato, lição 3 "…não permitem" sem nenhuma frase com *allow* ·
  phrasal-verbs-b2: títulos com *let down* e *work out* e lição "Assumir…" sem *take on* nas frases.
- **Falas que respondem a perguntas que não existem:** tempos-narrativos-completos ("Not long. I'd only been sleeping…" — sugestão: "I barely slept. I'd only been sleeping…" ou acrescentar a pergunta do Ben) ·
  situacao-telefone-reclamacao ("No, they never called me back.") · conversa-natural-c1 ("it does", "I just know all the words", "I'd love to", "Me neither", "It'll go by fast").
  Nas aulas, a pergunta aparece como exemplo do professor, sem inventar fala de cena.
- **Contradições internas:** registro-variantes ("it won't happen again" é promessa e o Mike elogia "without promising anything") ·
  deducao-no-passado (id da lição 1 fala em escritório; a cena é em casa) · conversa-natural-c1 (cena "num bar", "until the bar closes", foto é sala com sofá) ·
  passivas-impessoais (cena fala em newsletter interna; foto e aula mostram chamada de vídeo).
- **Frases da lição que poderiam soar mais naturais:** "Yesterday I dropped the call twice during the demo" (habitos-costume → "I got dropped from the call" / "my call dropped") ·
  "It took us 19 minutes to realize." (pro-incidentes-comunicacao → "…to realize it") · "It's worth the work" (conceder-rebater; "the effort" é mais comum) ·
  "She said it was moved" (pro-dia-de-trabalho; "had been moved" é a forma de livro) · tradução com "(educado)" no começo (pro-entrevista-senior — deve aparecer na lousa?).

### 3. Fotos que não batem com a cena (as aulas descrevem só o que aparece)
O caso mais comum é **o elenco**: o aluno é o Carlos, mas a foto mostra uma mulher ou outras pessoas.
- passiva-2 (formulário de imposto; rua com bonde, não Chicago) · tempos-narrativos-completos (aeroporto com aviões United, portão B62; estrada de dia sem neve; "600 W. 7th Street") ·
  wish-condicionais-mistas (3 fotos com elenco diferente) · situacao-carro-estrada (fila de check-in; estacionamento coberto; avenida com palmeiras) ·
  dev-planning-retro (post-its, não cartas) · habitos-costume (4 fotos) · verbos-de-relato (reunião presencial × chamada) · relativas-3 (3 fotos) ·
  enfase-inversao-clivadas (lago, sem cabana; homem dormindo, sem a Ana) · phrasal-verbs-b2 (duas mulheres × Ben) · situacao-telefone-reclamacao (2 fotos com uma mulher) ·
  argumentar-conectores (três homens, sem a Ana) · colocacoes-expressoes (presencial × vídeo) · funcoes-conversa-b2 (bar ao vivo × happy hour online; presencial × call) ·
  dev-incidentes (2 fotos) · escrita-formal (papel e caneta × e-mail) · resenhar-criticar (senhor de boina; copa sem série) · revisao-b2 (sem a Sarah) · registro-variantes (2 fotos com uma mulher).
- C1: inversoes-escrita-formal (sem brinde; colegas dançando, sem discurso) · clivadas-fronting (esboços de telas × linha do tempo) · modalidade-avancada (lousa de matemática) ·
  passivas-impessoais · hedging-registro (passaporte e cartão de embarque) · conceder-rebater (quadro presencial × call) · situacao-vida-social (2 fotos) ·
  nominalizacao-participiais (auditório × reunião com a diretoria) · idioms-colocacoes-fortes (3 fotos) · precisao-lexical (4 fotos) · phrasal-verbs-c1 (2 fotos) ·
  ingles-tecnico-academico (armários que parecem painéis elétricos) · conversa-natural-c1 (sala × bar; copa sem máquina de café) · revisao-c1 (3 fotos).
- DEV: pro-entrevista-senior (candidata mulher, 4 rostos) · pro-design-sistemas (quem desenha é uma mulher) · pro-code-review-avancado (reunião presencial × thread escrita) ·
  pro-incidentes-comunicacao (4 fotos) · pro-apresentacoes-demos (3 fotos) · pro-negociar-prazo-escopo (Sarah com outro rosto; homem de fone) ·
  pro-lideranca-feedback (moça × "o dev júnior"; duas mulheres) · pro-clientes-email-formal (uma mulher) · pro-carreira-networking (bancada × almoço; latinhas × café) · pro-dia-de-trabalho (2 fotos).

### 4. Palavras que o validador barrou (português ou nome próprio)
Reescrevi a fala em todos os casos.
- **São do português e foram barradas:** manual, editor, motel, rude, original, ideal, usual, festival, supervisor, gerais, local, cafezinho, freelancers, chances.
- **Termos de dev/siglas barrados no "pt":** patch, config, spam, beta, perfect (de present perfect), ticket, framework, script, endpoint(s), gateway, logs, builds, downloads, slide, infra, URL, git, PDF, mobile, checkout, laptops, TV, SSL/TLS, cause, lot, logins.
- **Outros:** "to" (vários), "in" (prefixo), "is" (de "pingos nos is"), "d'água" (o apóstrofo conta como inglês); ✓/✗ no "quadro" contam como emoji.
- **O validador aceita e ficou no "pt" em algumas aulas:** deploy, bug, login, cache, API, logada, Slack. Aceita como português de dev, ou prefere tirar?

### 5. Pequenas decisões que deixei com você
- *estepe* ← marca britânica Stepney (situacao-carro-estrada): *Stepney* está no Oxford, mas a ligação com o português vem dos dicionários brasileiros. Cortar se quiser rigor máximo.
- *deadline*: em revisao-b2 o verificador tirou, a pedido, o "risco de levar tiro" do prisioneiro, que o Merriam-Webster registra. Voltar com ele?
- Frases que só ilustram: "I'd rather wait. By Friday, we'd lost two days." (dev-planning-retro); truque de *dessert* "os nativos lembram assim" (deducao-no-passado); KISS chamado de "princípio de programação" (verbos-de-relato).
- Título da aula da manhã em pro-dia-de-trabalho tem "tech lead" em inglês, igual à teoria escrita. Manter?
- Em pro-carreira-networking, a "participante" do estande seria uma expositora; e "a engenheira" da lição 4 não é a da lição 2.
