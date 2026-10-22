# Fixtures de paridade Dart ↔ Python (historinhas das lições)

Cada `<caso>.json` é um arquivo de trilha mínimo (o exemplo oficial §5.4 com UMA mudança). `<caso>.esperado.txt` tem as mensagens EXATAS do Dart, uma por linha, na ordem (vazio = 0 erros):

- a trilha de referência é a do 1º `Licao.id` em `licoes` (o campo `trilha` pode estar errado de propósito);
- se `HistoriasDaTrilha.fromJson(estrito: true)` lança, a única linha é a `FormatException.message`;
- senão, as linhas são o `validarHistoriasDaTrilha(h, trilha)` (os avisos de "sem história" não entram).

Quem gerou (sessão do piloto, no scratchpad): `_trabalho/gerar_fixtures.py` (os .json) e `_trabalho/gravar_esperados.py` (roda o Dart por um harness só de leitura e grava os .esperado.txt). Quem confere: `python3 -I validar_historias_licoes.py --auto-teste` e `test/historias_licoes_paridade_test.dart` (integração). Em divergência, o Dart manda: o teste de paridade mostra as mensagens que o Dart deu; regrave o `.esperado.txt` com elas e conserte o Python. Caso novo = um `.json` mínimo aqui + o `.esperado.txt` com a saída do Dart.

| caso | regra | o que muda |
|---|---|---|
| `00_boa` | — | o exemplo oficial do plano §5.4: 0 erros |
| `01_arquivo_versao` | L-arquivo | versao 2 (parse) |
| `02_arquivo_trilha_diferente` | L-arquivo | campo 'trilha' diferente da trilha das lições |
| `03_arquivo_arco_longo` | L-arquivo | arco com 301 caracteres |
| `04_arquivo_licao_de_outra_trilha` | L-arquivo | chave de lição de outra trilha (parse) |
| `05_arquivo_chave_desconhecida` | L-arquivo | chave desconhecida no arquivo (parse) |
| `06_titulo_ausente` | L-título | sem titulo |
| `07_titulo_longo` | L-título | titulo.en com 7 palavras |
| `08_titulo_termo_proibido` | L-título | cidade proibida no título ('austin') |
| `09_titulo_pt_vazio` | L-título | titulo.pt vazio |
| `10_cobertura_frase_faltando` | L-cobertura | a última âncora some |
| `11_cobertura_fora_da_ordem` | L-cobertura | duas âncoras trocadas de lugar |
| `12_cobertura_frase_desconhecida` | L-cobertura | frase 'f-zzzzzz' (parse) |
| `13_cobertura_frase_repetida` | L-cobertura | a 1ª âncora repetida no fim |
| `14_ancora_com_en` | L-âncora | âncora com 'en' (parse) |
| `15_ancora_quem_errado` | L-âncora | quem da âncora diferente do da frase (parse) |
| `16_ancora_desloca` | L-âncora | acao 'sai' numa âncora |
| `17_ligacao_com_texto` | L-ligação | passo com texto e sem 'frase' (parse) |
| `18_cenas_tres` | L-cenas | 3 cenas |
| `19_cenas_sem_ancora` | L-cenas | a 2ª cena só tem um mudo |
| `20_cenas_cinco_mudos_na_historia` | L-cenas | 5 mudos na história (3 + 2, nunca 3 seguidos) |
| `21_cenas_quatro_mudos_na_cena` | L-cenas | 4 mudos numa cena (máx. 3 por cena) |
| `22_cenas_tres_mudos_seguidos` | L-cenas | 3 mudos seguidos |
| `23_cenario_do_turismo` | L-cenário/props | cenário 'garagem' |
| `24_prop_do_turismo` | L-cenário/props | objeto 'trofeu' na cena e 'medalha' na mão num passo |
| `25_elenco_max` | L-elenco | o 'max' no elenco |
| `26_elenco_desconhecido` | L-elenco | 'pirata' não é do elenco nem figurante conhecido |
| `27_elenco_tres_figurantes` | L-elenco | 3 figurantes mudos (máx. 2) |
| `28_narrador_no_elenco` | L-narrador | o narrador no elenco (só a frase de placa vira narrador) |
| `29_base_alvo_invisivel` | L-base | alvo na Ana antes de ela entrar |
| `30_base_mudo_vazio` | L-base | passo mudo sem nada acontecendo |
| `31_base_dupla_sem_alvo` | L-base | camera dupla sem alvo ator |
| `32_base_entra_ja_visivel` | L-base | mudo 'entra' de quem já está visível |
| `33_base_posicao_repetida` | L-base | duas pessoas na mesma posição inicial |
| `34_base_remoto_sem_celular` | L-base | o Mike remoto e ninguém segurando celular |
| `35_parse_falas_em_vez_de_passos` | parse | a cena usa 'falas' (formato do Turismo) |
| `36_parse_enum_invalido` | parse | emocao 'happy' numa âncora |
| `37_parse_elenco_nao_objeto` | parse | item do elenco que não é objeto (mensagem com o lugar duas vezes) |
| `38_parse_reacao_invalida` | parse | reação com acao inválida (contexto aninhado) |
