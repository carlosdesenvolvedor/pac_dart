# Plano — lote "trocar as vozes" (Tatoeba → voz do personagem) + D15 (mp3 por personagem na história do Turismo)

Passo só de leitura (22/out/2026). Nada foi alterado no projeto. Números medidos nos arquivos atuais
(script de contagem: `scratchpad/vozes_analise/conta.py`; listas: `scratchpad/vozes_analise/faltam_curso.json`
= as 407 frases do curso que ainda não têm voz de personagem, `scratchpad/vozes_analise/historia_pares.json` = os 434 pares
(quem, texto) da história).

---

## 0. Números exatos

| O quê | Quantidade |
|---|---|
| Trechos (frases) do curso de inglês (`assets/ingles/curriculo.json`) | 5.308 |
| Trechos com `au` (gravação do Tatoeba) | **410** |
| Textos distintos com `au` | **407** (407 mp3 distintos em `assets/ingles/audio/`, todos existem; 7,1 MB) |
| Textos com `au` que repetem (mesmo mp3) | 3: "Do you want to go out tonight?" (ana, depois ben), "How was your trip to Boston?" (sarah, depois ana), "I would be happy to do so." (voce, 2×) |
| Quem fala as 410 frases com `au` | voce 164, ana 67, mike 56, sarah 28, ben 28, emma 26, julia 10, atendente 7, lucas 7, dev-novo 4, recepcionista 3, farmaceutica 2, recrutadora 2, entrevistador 2, passageiro 1, guia 1, proprietario 1, amigo-do-ben 1 |
| Texto com `au` que também aparece num trecho SEM `au` | 0 |
| Texto com `au` que já está em `vozes.json` | 0 (o script pula todos hoje) |
| Exemplos da teoria (`t: "ex"`) | 569; **57** têm o mesmo texto de uma frase com `au` (hoje tocam o Tatoeba; o script os pula pelo conjunto `nativas`) |
| `assets/ingles/vozes.json` | 5.131 textos = 5.131 mp3 em `assets/ingles/voz/` (64 MB) |
| `assets/ingles/bocas.json` | 5.538 entradas = 5.131 (voz/) + 407 (audio/) — 694 KB |
| Universo do curso depois da troca | 5.538 textos (5.131 + 407); **407 para gerar, 10.792 letras; 0 órfãos** |
| História "The Golden Wheel" (3 JSON, 30 capítulos, intro+fim) | 533 falas: 93 mudas (sem `en`) + **440 faladas** |
| Pares distintos (quem, texto) na história | **434** (433 textos distintos) |
| Mesmo texto com falantes diferentes na história | 1: "Copy that!" (voce e max) |
| Texto da história igual a frase do curso | 0 |
| Quem fala na história (pares) | voce 125, mike 54, max 39, ana 37, ben 37, narrador 36, sarah 34, kim 19, emma 17, julia 14, lucas 12, dra-lee 10 |
| Letras da história | **16.775** |
| Total a sintetizar | 841 mp3, 27.567 letras (Chirp 3 HD: ~2,8% da cota gratuita de 1 milhão de letras/mês; mesmo pago, ~US$ 0,83) |

---

## 1. Como o pipeline funciona hoje

### 1.1 `tools/ingles/vozes_google.py` (Google Cloud TTS, Chirp 3 HD en-US)
- **Elenco** (`ELENCO`): voce=Orus, mike=Puck, ben=Fenrir, lucas=Iapetus, ana=Kore, sarah=Aoede, emma=Leda, julia=Zephyr,
  dra-lee=Sulafat, narrador=Charon, placa=Charon. Papéis menores: `voz_do_papel(papel)` escolhe da lista `FEMININAS`
  ou `MASCULINAS` pelo gênero da palavra (sets `FEMININOS`/`MASCULINOS` + terminação), neutro → as duas listas; o índice é
  `sha1(papel) % len(pool)` (determinístico).
- **Universo** (`pedidos`, texto → papel, **a 1ª fala vence** via `setdefault`):
  1. cada trecho de cada lição: `papel = quem or 'narrador'`; **`if not f.get('au')`** → só entra se NÃO tiver `au`
     (linha 129: é aqui que as 407 frases do Tatoeba ficam de fora);
  2. cada exemplo da teoria (`b['t']=='ex'`, 1ª linha de `b['c']`) entra como `narrador`, **menos** os textos do
     conjunto `nativas` (linha 131/137: os 57 exemplos iguais a frases com `au`).
- **Arquivo**: `assets/ingles/voz/<sha1("Voz|texto")[:14]>.mp3` (o nome depende da VOZ e do texto: trocar a voz de um
  papel gera arquivo novo e o antigo vira órfão).
- **Gera só o que falta** (arquivo não existe), 6 threads, token do `gcloud auth print-access-token` só em memória
  (renovado a cada 40 min; nunca escrito em disco).
- **Índice**: `assets/ingles/vozes.json` = `{texto: "assets/ingles/voz/<hash>.mp3"}` (só o que existe em disco).
- **⚠️ Órfãos**: todo `.mp3` de `assets/ingles/voz/` que não está no índice novo é **apagado** (`os.remove`), exceto
  com `--limite`. Ou seja: o universo de cada execução precisa conter TUDO que deve continuar com voz.
- Também grava `tools/ingles/dados/vozes_google.json` (`{vozes: {papel: nome completo}, gcp_api, total}`).
- Vozes Chirp 3 HD ainda **sem dono**: `Achird` (m), `Zubenelgenubi` (m), `Gacrux` (f). Por coincidência do hash,
  `voz_do_papel('max') = Achird` e `voz_do_papel('kim') = Gacrux` (justamente duas das livres).

### 1.2 `tools/ingles/bocas_rhubarb.py` (lip sync)
- `audios()` = `{asset: texto}` de `vozes.json` **+** cada trecho com `au` (`r[t['au']] = t['cod']`), só o que existe.
- Para cada um que falta em `bocas.json`: ffmpeg → wav 16 kHz mono → `rhubarb -f json --extendedShapes GHX -d texto.txt`
  → formato compacto `"0X 9B 15E … 222X"` (centésimos + visema).
- Incremental; entradas cujo asset não está mais em `audios()` saem do `bocas.json` (não apaga mp3).
- ~4 s por áudio por núcleo (máquina: 8 núcleos → 6 processos). 841 áudios novos ≈ 10 min.

### 1.3 Lado do app
- **Carga** (`lib/features/curso/data/curriculo_loader.dart`): `AudioNativo.registrar(trilhas)` (os `au`) e, só no
  inglês, `AudioNativo.registrarGeradas(vozes.json)` e `BocasIngles.registrar(bocas.json)`, cada um em try/catch.
- **`AudioNativo`** (`lib/features/ingles/data/audio_nativo.dart`): `_porFrase` (cod → `au`) e `_geradas` (texto → mp3).
  `daFrase(f)` = só o Tatoeba; **`paraTocar(f) = _porFrase[f] ?? _geradas[f]`** ← a prioridade Tatoeba > personagem.
- **`VozIngles._falar`** (`lib/features/ingles/data/voz_ingles.dart`): 1) áudio do aluno (`AudioUsuario`); 2)
  `AudioNativo.paraTocar` → anuncia `FalaEmCurso(gravacao: boca != null)` com a boca de `BocasIngles.de(asset)` (sem boca:
  pelo texto × .8) e `fala.tocar(asset, vGravada)`; falhou → 3) voz sintética.
  `falar()` usa vGravada 1,0/0,8 (🐢); `falarNoPlayer(frase, fator:)` usa `vGravada = fator`.
- **`FalaEmCurso.gravacao`**: com mp3 + boca, a boca segue a posição real do `<audio>` (`fala.posicaoGravacao`). Usado no
  Assistir (`roteiro_seguidor.dart:517`, `fator: fc.gravacao ? 1 : _fatorFala`) e no palco da história
  (`palco_historia.dart:590`, `fc.frase == en` → `fc.visema(agora)`). Nada disso muda: é por asset, não por origem.
- **Ouvir** (`SaidaVozIngles`): `en()` → `voz.falarNoPlayer(texto, fator:)` (sem perfil = caminho acima);
  `temGravacao(en) = AudioNativo.paraTocar(en) != null || AudioUsuario.tem(en)` (só diz "é mp3", não "é Tatoeba");
  `duracaoDe` → `VozIngles.duracaoDe` = última marca da boca do asset de `paraTocar`. Com a troca, tudo continua
  verdadeiro (passa a apontar para o mp3 do personagem).
- **`VozIngles.temVozNativa(f)`** = `AudioNativo.daFrase(f) != null` — **ninguém em `lib/` usa**; só os testes.
- **UI que fala de "gravação de nativo"**:
  - `lib/features/ingles/presentation/widgets/traducao_card.dart:202-210` — linha "🎙️ voz nativa: CK (CC BY-NC-ND 3.0),
    Tatoeba" (link `urlDaGravacao`) sempre que `trecho.audioCredito` não é vazio. Depois da troca o 🔊 não toca mais essa
    gravação → o crédito fica falso.
  - `lib/features/curso/presentation/pages/mapa_page.dart:383-480` (`_CreditosIngles`) — "Vozes nativas: N frases tocam
    a gravação de um falante nativo… no lugar da voz sintética" + "As demais frases usam a voz… do seu navegador (Web
    Speech)" (esta já está errada hoje: as demais tocam Chirp).
  - `texto_para_licao_page.dart:11/244` ("texto seu não tem gravação de falante nativo") — continua verdadeiro; opcional
    trocar por "voz de personagem".
  - Comentários desatualizados (só doc): `voz_ingles.dart:15-22`, `audio_nativo.dart:3-9`, `fala_web.dart:11/214`,
    `fala_nativo.dart:11`, `voz_jogo.dart:10`, `curriculo_loader.dart:23`, `curriculo.dart:254`.
  - Nenhum teste fixa os textos dessas duas telas.
- **Quem grava `au` no currículo**: `tools/ingles/audio_nativo.py` → `tools/ingles/dados/audio_nativo.json` (407) →
  `tools/ingles/integrar.py:102-106` grava `au`/`au_cred` no trecho. Não é preciso mexer nisso para a troca.

### 1.4 História do Turismo
- `HistoriaTurismoRepo` carrega `assets/ingles/turismo_historia_{a,b,c}.json` (cache, tolerante).
- `RoteiroHistoria._falar()` (`lib/features/arcade/presentation/historia/roteiro_historia.dart:478-500`):
  `voz.falarNoPlayer(en, fator: _velocidade, perfil: ElencoTurismo.perfilDeVoz(f.quem))`; o limite de espera é
  `_limiteVoz = tFala + VozIngles.duracaoDe(en) / _velocidade * 2 + 5`.
- `VozIngles.falarNoPlayer(..., perfil != null)` → `_falarComPerfil`: **sempre** a sintética com `pitch = tom` e a
  `variante`-ésima voz en-US, boca pelo texto (pula de propósito o áudio do aluno e o mp3 do curso).
- `ElencoTurismo._vozes` (`elenco_turismo.dart:58-74`): tom/variante de voce, mike, sarah, ana, ben, emma, lucas, julia,
  dra-lee, max, kim, narrador.
- `player_historia.dart:293` `_ouvir(p.en)` (chips das 143 palavras do capítulo) usa `falarNoPlayer` sem perfil —
  caminho do curso (hoje sintética; nenhuma dessas palavras tem mp3). Fora do escopo.
- Velocidades da história: 1 / .85 / .7 / .5 (o mp3 toca com `playbackRate` = fator e `preservesPitch = true` na web;
  `AudioPlayer` com rate no aparelho).
- Os 5 fakes de teste que sobrescrevem `falarNoPlayer(String, {required double fator, PerfilVoz? perfil})`:
  `test/historia_galeria_test.dart:21`, `test/historia_player_test.dart:34`, `test/historia_velocidade_voltar_test.dart:21`,
  `test/turismo_historia_conteudo_test.dart:26`, `test/turismo_historia_integracao_test.dart:37`. **Mudar a assinatura de
  `falarNoPlayer` quebra a compilação dos 5** (override precisa aceitar todos os nomeados) → o desenho abaixo não mexe nela.
- Nenhum desses testes carrega o `CurriculoLoader` (montam `PlayerHistoria`/`abrirCenaDaHistoria` direto), então o índice
  da história fica vazio neles.

---

## 2. Desenho decidido (mínimo e seguro)

### 2.1 Curso: o mp3 do personagem vence o Tatoeba (Tatoeba vira reserva)
- **Dados**: NÃO mexer em `curriculo.json`, `integrar.py`, `audio_nativo.py` nem em `assets/ingles/audio/`. Os 410 `au`
  continuam no currículo como **reserva** (só tocam se o mp3 do personagem faltar). Assim o lote não reescreve o
  currículo, os testes de integridade do Tatoeba (`ingles_curriculo_test.dart:86-120`) seguem valendo e o
  `bocas_rhubarb.py` continua achando as bocas do Tatoeba (nenhuma entrada sai do `bocas.json`).
- **`vozes_google.py`**: tirar o `if not f.get('au')` (linha 129) e o filtro `nativas` dos exemplos (linhas 131/137).
  Resultado: universo 5.538 = 5.131 de hoje + 407; 0 órfãos no curso. Os 57 exemplos da teoria iguais a frases `au` passam a
  tocar a voz do personagem da frase (regra de sempre: o trecho entra antes da teoria, `setdefault`).
- **Textos repetidos com falantes diferentes** (2 textos, 4 trechos): o índice é por texto, então vale a 1ª fala do
  currículo — "Do you want to go out tonight?" fica na voz da **Ana** (Kore) também quando o Ben diz; "How was your trip
  to Boston?" fica na voz da **Sarah** (Aoede) também quando a Ana diz. Não é regressão (hoje as duas falas tocam a mesma
  gravação do Tatoeba). Resolver de verdade exigiria passar `quem` até o `_falar` (Ouvir, palco, revisão…) — fora deste lote.
- **`AudioNativo`**: `paraTocar(f) = _geradas[f] ?? _porFrase[f]` (personagem > Tatoeba). Novo
  `static bool tocaGravacaoDeNativo(String f)` = `_geradas[f.trim()] == null && _porFrase[f.trim()] != null` (o Tatoeba é o
  que vai tocar de fato). `daFrase` e `temVozNativa` ficam como estão ("há gravação registrada").
- **Crédito na UI** (a licença CC BY-NC-ND só exige crédito quando a gravação é usada):
  - `traducao_card.dart`: mostrar "🎙️ voz nativa…" só se `AudioNativo.tocaGravacaoDeNativo(trecho.cod)` (na prática some).
  - `mapa_page.dart` `_CreditosIngles`: contar `vozes`/`gravadas` só dos trechos com `tocaGravacaoDeNativo`; trocar o
    parágrafo final por algo como "As falas dos personagens usam vozes geradas pelo Google Cloud Text-to-Speech (Chirp 3 HD),
    sempre a mesma voz por personagem; sem o áudio, a voz em inglês do seu navegador." (mantém o bloco do Tatoeba quando
    `gravadas > 0`).
  - Atualizar os comentários listados em 1.3.
- **Remoção do Tatoeba (NÃO neste lote; receita para depois, se o dono quiser os 7,1 MB de volta)**: `integrar.py` para
  de gravar `au`/`au_cred` (ou `audio_nativo.json` vazio) → rodar `integrar.py` → apagar `assets/ingles/audio/*.mp3` com
  `find assets/ingles/audio -name '*.mp3' -delete` → tirar `- assets/ingles/audio/` do pubspec → apagar o teste
  `ingles_curriculo_test.dart:86-120` e os trechos de `au` nos testes 122/171 → rodar `bocas_rhubarb.py` (as 407 bocas do
  Tatoeba saem sozinhas). Na web o peso não pesa no download (asset baixa sob demanda); pesa no APK/IPA (+7,1 MB).

### 2.2 História: índice separado, chave com quem fala, pasta separada
- **Por que separado**: o índice do curso é `texto → asset`; na história o mesmo texto pode ter falantes diferentes
  ("Copy that!" = voce e max) e o mesmo texto de uma frase do curso tem de soar com a voz do personagem da história, não com a
  do curso. Chave **`"quem|texto"`** (nenhum texto da história tem `|`; nenhum tem espaço nas pontas; texto exatamente como
  no JSON, que o app repassa cru — `_textoOpc` não normaliza).
- **Arquivos novos**:
  - `assets/ingles/voz_historia/<sha1("Voz|texto")[:14]>.mp3` (434 arquivos) — **pasta própria**: a limpeza de órfãos
    de cada pasta só olha o seu universo, então rodar o `vozes_google.py` antigo (sem a história) **não apaga** os mp3 da
    história, e o teste "nenhum mp3 sobrando em voz/" não muda.
  - `assets/ingles/vozes_historia.json` = `{"quem|texto": "assets/ingles/voz_historia/<hash>.mp3"}` (já coberto por
    `- assets/ingles/` no pubspec).
  - pubspec: **+ `- assets/ingles/voz_historia/`** (diretório de asset não é recursivo).
- **Vozes da história** (mapa explícito `ELENCO_HISTORIA`, sem depender do hash):
  - os 9 do curso = a mesma voz do curso (voce Orus, mike Puck, sarah Aoede, ana Kore, ben Fenrir, emma Leda, lucas
    Iapetus, julia Zephyr, dra-lee Sulafat);
  - **max = Achird** (m, livre), **kim = Gacrux** (f, livre), **narrador da história = Zubenelgenubi** (m, a última livre).
    Alternativa (decisão do dono, mesmo custo): narrador = Charon, o mesmo narrador dos exemplos da teoria.
  - quem não estiver no mapa (não há hoje) → `voz_do_papel(quem)`.
- **`vozes_google.py`** (um script só, como pede o D15):
  - nova seção que lê `assets/ingles/turismo_historia_{a,b,c}.json` → `capitulos[].intro|fim[].falas[]` com `en` e sem
    `mudo` → `pedidos_hist["quem|en"] = (quem, en)`;
  - gera o que falta em `voz_historia/`, grava `vozes_historia.json`, apaga órfãos **só** de `voz_historia/`;
  - **trava de segurança**: universo da história vazio (JSON ausente/quebrado) ou do curso vazio → não apaga órfãos
    daquela pasta (avisa e sai com erro);
  - **`--seco`** (dry run): calcula os universos e imprime "N textos · faltam X (Y letras) · Z órfãos" por pasta, sem chamar a
    API e sem escrever/apagar nada. Esperado: curso 5.538 / faltam 407 / 10.792 letras / 0 órfãos; história 434 / faltam
    434 / 16.775 letras / 0 órfãos;
  - `vozes_google.json`: acrescentar `"historia": {quem: voz}`.
- **`bocas_rhubarb.py`**: `audios()` também lê `vozes_historia.json` (se existir): `r[asset] = chave.split('|', 1)[1]`.
  Boca é por asset, sem colisão.
- **App**:
  - `AudioNativo`: `_historia` + `static const indiceHistoria = 'assets/ingles/vozes_historia.json'`,
    `registrarHistoria(Map)`, `daHistoria(String quem, String frase)` → `_historia['$quem|${frase.trim()}']`,
    `totalHistoria`, `limpar()` limpa também.
  - `CurriculoLoader.carregar` (inglês): carregar `AudioNativo.indiceHistoria` num try/catch próprio, junto do
    `vozes.json` (as bocas da história também só chegam por aqui, então o índice fica no mesmo lugar). Sem ele: a sintética
    com perfil, como hoje.
  - `VozIngles`: método NOVO, sem mexer na assinatura de `falarNoPlayer`:
    ```dart
    /// A fala de um personagem da história: o mp3 dele ([AudioNativo.daHistoria]) com a boca do Rhubarb;
    /// sem mp3 (ou se não tocar) → a sintética com o [perfil] (o caminho de hoje).
    Future<FimDaFala> falarNaHistoria(String frase,
        {required double fator, required String quem, required PerfilVoz perfil}) {
      final audio = AudioNativo.daHistoria(quem, frase);
      if (audio == null) return falarNoPlayer(frase, fator: fator, perfil: perfil);
      return _falarNoPlayerHistoria(frase, audio, fator: fator, perfil: perfil);
    }
    ```
    `_falarNoPlayerHistoria` repete a casca do `falarNoPlayer` (`++_vez`, `++_vezGlobal`, `_emCurso`, `_fecharBoca`,
    retorno acabou/cortada) e dentro: `boca = BocasIngles.de(audio)`; `_anuncia(frase, boca ?? doTexto(seg*.8),
    velocidade: f, gravacao: boca != null)`; `if (await fala.tocar(audio, f)) return;` `if (minha != _vez) return;` →
    `_falarComPerfil(...)` (reserva). Como sem mp3 ele delega para `falarNoPlayer`, os 5 fakes de teste continuam
    recebendo as falas sem nenhuma edição.
  - `VozIngles.duracaoNaHistoria(String quem, String frase)` = boca do mp3 da história, senão `duracaoDe(frase)`.
  - `roteiro_historia.dart` `_falar()`: `voz.falarNaHistoria(en, fator: _velocidade, quem: f.quem, perfil:
    ElencoTurismo.perfilDeVoz(f.quem))` e `_limiteVoz` com `VozIngles.duracaoNaHistoria(f.quem, en)`.
    (Opcional: `fala.preaquecer` do mp3 da próxima fala para não haver atraso na web.)
  - `elenco_turismo.dart`: só o comentário de `_vozes` ("reserva quando falta o mp3"). Tom/variante continuam.
  - **Não tocar** em `palco_historia.dart`, `balao_fala.dart`, `palco_assistir.dart`, `tocando_page.dart` (outro agente):
    nenhum precisa mudar (a boca já segue `FalaEmCurso` por `frase == en`).

---

## 3. Ordem de execução (próximas etapas)

1. **Backup** (sem `rm`): copiar `assets/ingles/vozes.json`, `assets/ingles/bocas.json` e
   `tools/ingles/dados/vozes_google.json` para `scratchpad/backup_vozes/`.
2. Editar `vozes_google.py` (2.1 + 2.2 + `--seco` + trava) e `bocas_rhubarb.py`.
3. `python3 -I tools/ingles/vozes_google.py --gcp music-system-421ee --seco` → conferir os números do item 2.2
   (**0 órfãos nas duas pastas**). Só seguir se bater.
4. Teste pequeno: `--limite 4` (não apaga nada) → ouvir 1 mp3 de max, kim, narrador e um ex-Tatoeba.
5. Execução completa (841 mp3, 27.567 letras; nunca imprimir token). Rodar de novo até "0 erro(s)".
6. `python3 -I tools/ingles/bocas_rhubarb.py` (≈ 841 áudios, ~10 min). Conferir a contagem abaixo.
7. Código do app (2.1 + 2.2) e testes (item 5). `flutter analyze lib test` + testes do foco. Sem build, sem commit.

Contagem esperada no fim: `vozes.json` 5.538; `voz/` 5.538 mp3; `vozes_historia.json` 434; `voz_historia/` 434 mp3;
`bocas.json` = 5.538 (voz/) + 407 (audio/, reserva) + 434 (voz_historia/) = **6.379** entradas.

---

## 4. Tamanho

- 407 mp3 novos do curso ≈ **3,0 MB** (ajuste linear dos 5.131 atuais: ~2,0 KB + ~200 B/letra).
- 434 mp3 da história ≈ **4,2 MB**.
- `vozes.json` +~25 KB; `vozes_historia.json` ~35 KB; `bocas.json` +~105 KB (≈125 B por entrada).
- Total ≈ **+7,4 MB** de assets (voz/ 64 → ~67 MB; voz_historia/ ~4,2 MB). Se depois remover o Tatoeba: −7,1 MB.
- Na web nada disso entra no download inicial (cada mp3 baixa quando toca).

---

## 5. Testes

### Atualizar
- `test/ingles_curriculo_test.dart`
  - `:140` "voz gerada por personagem: toda frase e todo exemplo da teoria têm áudio (nativo ou gerado)" → exigir
    `indice.containsKey(x.f.cod)` para **toda** frase (sem a saída `x.f.audio.isNotEmpty`) e
    `indice.containsKey(en)` para todo exemplo (sem `nativas`); renomear para "…têm a voz do personagem".
  - `:171` "o que tocar: gravação de nativo > voz gerada do personagem > voz sintética" → "voz do personagem > gravação de
    nativo (reserva) > sintética": `paraTocar(nativa.cod) == 'assets/ingles/voz/x.mp3'`; sem gerada registrada para ela →
    `paraTocar == nativa.audio`; `tocaGravacaoDeNativo` false com gerada / true sem gerada.
  - `:122` (registro → `daFrase`/`temVozNativa`) e `:86` (integridade do Tatoeba) **ficam** (o `au` continua como reserva).
- Nenhuma edição necessária (devem continuar passando): `test/voz_perfil_test.dart` (tests atuais),
  `test/historia_player_test.dart`, `test/turismo_historia_conteudo_test.dart`, `test/historia_galeria_test.dart`,
  `test/historia_velocidade_voltar_test.dart`, `test/turismo_historia_integracao_test.dart`, `test/historia_ator_test.dart`
  (perfilDeVoz), `test/historia_figurantes_test.dart`, `test/ingles_ouvir_*`, `test/ingles_tocando_ui_test.dart`,
  `test/assistir_*` (este último está sendo editado por outro agente: só rodar).

### Acrescentar
- `test/voz_perfil_test.dart`, grupo novo **"falarNaHistoria"**:
  1. sem mp3 da história (mesmo com mp3 do CURSO para o texto, `'Hello.'` no setUp) → delega: sintética com o perfil,
     anúncio `gravacao: false`, `falarComPerfil` 1×.
  2. com `AudioNativo.registrarHistoria({'sarah|Hello.': _mp3h})` + `BocasIngles.registrar({_mp3h: boca})` → anúncios
     `[gravacao: true (boca do mp3, velocidade = fator), gravacao: false]` e `falarComPerfil` 1× (na VM o `tocar` dá false →
     reserva), resultado `FimDaFala.acabou`, boca fechada no fim.
  3. a chave tem quem fala: `'max|Copy that!'` registrado não toca para `quem: 'voce'`.
  4. `fator: .5` → anúncio do mp3 com `velocidade .5`; `duracaoNaHistoria` = duração da boca do mp3; sem mp3 = `duracaoDe`.
  5. cortada por outra `VozIngles` → `FimDaFala.cortada`.
- `test/historia_velocidade_voltar_test.dart` (ou arquivo novo `test/historia_voz_mp3_test.dart`): fake que sobrescreve
  `falarNaHistoria` e registra `(frase, quem, perfil)` → o `RoteiroHistoria` passa `f.quem` e `perfilDeVoz(f.quem)`.
- Teste de DADOS novo (ex.: `test/vozes_historia_test.dart`, lê por `dart:io`): toda fala com `en` e sem `mudo` dos 3 JSON
  tem `"quem|en"` em `assets/ingles/vozes_historia.json`; cada asset existe e tem > 1000 bytes; nenhum mp3 sobrando em
  `assets/ingles/voz_historia/`; pubspec tem `- assets/ingles/voz_historia/`; todo asset de `vozes.json` e de
  `vozes_historia.json` tem boca em `assets/ingles/bocas.json`; max, kim e narrador aparecem.
- `AudioNativo` (no `ingles_curriculo_test.dart`): `registrarHistoria`/`daHistoria`/`limpar`.

### Rodar (foco)
`~/development/flutter/bin/flutter analyze lib test` e
`~/development/flutter/bin/flutter test test/ingles_curriculo_test.dart test/voz_perfil_test.dart test/historia_player_test.dart
test/historia_velocidade_voltar_test.dart test/historia_galeria_test.dart test/turismo_historia_conteudo_test.dart
test/turismo_historia_integracao_test.dart test/historia_ator_test.dart test/historia_figurantes_test.dart
test/ingles_boca_test.dart test/ingles_tocando_ui_test.dart test/ingles_ouvir_ui_test.dart test/ingles_ouvir_cubit_test.dart
test/ingles_ouvir_app_test.dart test/vozes_historia_test.dart`. (As 5 falhas de `test/csharp_curriculo_test.dart` já existiam.)

---

## 6. Riscos e cuidados

- **Órfãos**: pastas separadas + trava de universo vazio + `--seco` antes. Nunca rodar com o currículo ou a história
  quebrados. `--limite` nunca apaga.
- **Ordem**: publicar `vozes.json` novo sem as bocas novas não quebra (boca pelo texto × .8, `gravacao: false`), mas
  rodar o Rhubarb antes de qualquer deploy.
- **Credenciais**: o token só existe em memória no `Token()`; não logar headers nem respostas de erro inteiras (o
  `sintetizar` já corta em 300 bytes do corpo da resposta, que não contém o token).
- **Arquivos de outro agente**: não editar `palco_assistir.dart`, `palco_historia.dart`, `balao_fala.dart`,
  `tocando_page.dart` (nenhum precisa).
- **Docs** a atualizar no fim: `ESTADO-DO-PROJETO.md` (linhas ~200-205 vozes Chirp, ~441 prioridade "aluno > Tatoeba >
  Chirp" → "aluno > Chirp > Tatoeba (reserva)", ~2420/2453 D15 feito), `tools/ingles/PROMPT-CONTINUAR.md` (ordem
  integrar → vozes_google → bocas_rhubarb, agora com a história).
