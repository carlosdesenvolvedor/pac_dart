# Fase 8 — "🎧 Ouvir": playlist do curso e setlists no PAC·ENGLISH

> 🛠️ **EM IMPLEMENTAÇÃO em 20/out/2026** (sem commit/deploy), dividida em 4 grupos com arquivos separados (seção 5). O que saiu, as
> divergências deste plano e a prova vão para `ESTADO-DO-PROJETO.md`, seção "🎧 Ouvir — Fase 8".

> Pedido do dono: uma seção para **só ESCUTAR as lições, em sequência** — o curso inteiro na ordem ou **setlists pessoais** montadas
> "conforme for fazendo", jogando nelas uma frase, uma parte da lição, a lição inteira, a unidade, a etapa ou tudo — com um **player que
> continua tocando** enquanto a pessoa navega. **Só o curso de Inglês** (Dart e C# não mudam: sem botão no HUD, sem mini-player).
> ⚠️ **Antes de executar:** SDK em `~/development/flutter`; **UMA pasta de probe, apagada no fim; nada de `flutter build web` em loop**;
> prefira `flutter test`. Nada em `lib/features/arcade/*` nem em `traducao_card.dart`.

Fatos do código que o plano usa (conferidos na fonte antes de escrever):

- `VozIngles.falar` sobe o `_vez` da instância **antes** do 1º `await`; o `finally` limpa `falando` quando `minha == _vez`. Como a
  conferência é por instância, um player cortado limparia a boca da instância que o cortou.
- `fala_web.tocar` devolve `true` tanto quando o clipe acaba quanto quando outro `_novaVez()` o corta (**corte parece fim normal**).
- O Web Speech está fixo em `lang = 'en-US'`; **não existe mp3 em português**.
- O `_AppShell` (`MaterialApp`) não tinha `builder:` nem `navigatorKey` e é reconstruído quando o tema muda.
- `TrilhaBoca.duracao` existe; `BocasIngles` tem `de(asset)` mas não a duração. Rótulos de `etapa` começam com A1, A2, B1, B2, C1, DEV.
- O curso tem 121 unidades, 602 lições e 5.308 frases, todas com mp3 (≈ 3 h 58 min de fala, 2,7 s por frase em média).

---

## 1. Notas dos três desenhos (1–10)

| | Atende o pedido | UX de ouvir | Confiável na web | Esforço/risco (maior = mais seguro) | Testável | Total |
|---|---|---|---|---|---|---|
| **mvp** | 9 | 7 | 5 (pausas com timer, sem Media Session) | 9 | 8 | **38** |
| **ouvinte** | 7 (seis receitas é mais que o pedido) | 10 | 7 (asset de silêncio + Media Session) | 4 | 8 | **36** |
| **risco** | 8 | 7 | 9 (silêncio WAV encadeado no `ended`, vigia) | 7 | 9 (interface `SaidaDeAudio`) | **40** |

**A síntese pega:** do *mvp* o escopo, o hub, a tela da setlist, a divisão de arquivos e o padrão de persistência; do *risco* o contrato do
motor, `FimDaFala`, o silêncio de verdade no mesmo `<audio>`, o vigia, etapa por código, foto da frase e a regra "nunca toca sozinho";
do *ouvinte* o item `trecho` (um **conjunto de chaves** de frases: cobre escolhas contíguas e salteadas), "Tocar daqui", "Ouvir daqui até
o fim do curso", o timer de desligar, "Praticar esta lição", esconder o mini-player com o teclado aberto e pausas por fase.

## 2. O que a v1 entrega, nas palavras do dono

- **"Colocar para tocar e escutar… tudo na ordem":** "Curso na ordem" com ▶ Continuar (de onde parou), ▶ Da minha lição atual e
  ↺ Do começo; e "Ouvir daqui até o fim do curso" em qualquer lição.
- **"Criar meu setlist… conforme for fazendo":** setlists com nome — criar, renomear, apagar, reordenar, desfazer; sincronizam entre aparelhos.
- **"Uma frase, uma parte da lição, a lição inteira, ou tudo, a sessão":** itens `frase`, `trecho` (algumas frases da lição), `licao`,
  `trilha` (unidade, texto próprio ou "Meus cartões"), `etapa` (A1…DEV) e `curso`.
- **"Jogar no setlist":** botão ➕ em cinco lugares — ao lado do 🎧 no cartão da frase do palco; na folha da lição do mapa (mais
  "Escolher frases…"); no guia da unidade; em todos os níveis do "Explorar" do hub; no menu do navegador de cartões.
  Toque = põe na última setlist usada (snackbar com **Desfazer / Trocar**); toque longo = escolhe a setlist.
- **Player:** tela "Tocando agora" com o personagem falando (o lip-sync já existe), o inglês grande e a legenda em português;
  **mini-player persistente** que sobrevive à troca de rota; velocidade, repetir 1–3×, tamanho da pausa (Curta/Média/Longa/Eco), modo
  (Só inglês / Inglês → português / Português → inglês), "2ª vez devagar", "Repetir tudo" e timer de desligar; controles na tela de
  bloqueio e teclas de mídia pela Media Session (web, sem garantia); o player **pausa sozinho** quando outro áudio do app fala.

## 3. Decisões do dono (padrões da v1)

| # | Decisão | Padrão |
|---|---|---|
| D1 | Lição trancada pode tocar? | **Sim**, com 🔒 e a dica "Lição à frente — pode ouvir à vontade". Ouvir nunca marca progresso. |
| D2 | Ouvir conta na meta do dia / sequência? | **Não** na v1. |
| D3 | Áudio em português | Sem mp3 PT: os passos em português usam a **voz pt-BR do navegador**. Sem voz pt-BR (ou página oculta no iOS) o passo vira **silêncio do mesmo tamanho** e o texto aparece na tela. Modo padrão: **Só inglês**. |
| D4 | Plataforma | No app nativo o player funciona **só com o app aberto**. Áudio em segundo plano no nativo pede permissões novas e fica para depois. |

## 4. Contrato compartilhado (congelado na Fase 0; cada grupo implementa o seu)

### 4.1 Domínio — Grupo A

**`lib/features/ingles/domain/setlist.dart`**
```dart
enum TipoItem { frase, trecho, licao, trilha, etapa, curso }
enum ResultadoAdicao { adicionado, jaEstava, cheia }

class ItemSetlist {
  final String id;            // novoIdItem(): 'i' + micros base36 + 2 letras aleatórias
  final TipoItem tipo;
  final String ref;           // ver a tabela de refs
  final List<String> chaves;  // só trecho: chaveDaFrase das escolhidas, na ordem da lição
  final String licaoId;       // frase/trecho: dica de busca; '' nos outros
  final String rotulo;        // foto do nome para mostrar quando a ref quebrar
  final String en, pt;        // só frase: foto, para a frase órfã ainda tocar; '' nos outros
  final int criadoEm;         // ms desde 1970
  String get assinatura => '${tipo.name}|$ref|${chaves.join(',')}';
  factory ItemSetlist.daFrase(Trecho f, {Licao? licao});
  factory ItemSetlist.daTexto({required String en, required String pt});   // navegador de cartões; chave = Revisao.chave(en)
  factory ItemSetlist.doTrecho(Licao l, List<Trecho> escolhidas);          // 1 frase → frase; todas → licao; senão trecho
  factory ItemSetlist.daLicao(Licao l);
  factory ItemSetlist.daTrilha(Trilha t);
  factory ItemSetlist.daEtapa(String etapa);    // ref = codigoEtapa(etapa)
  factory ItemSetlist.doCurso();
  static String codigoEtapa(String etapa) => etapa.split('·').first.trim(); // 'A1' … 'DEV'
  Map<String, dynamic> toJson();
  factory ItemSetlist.fromJson(Map<String, dynamic> j);  // tolerante: tipo desconhecido é descartado por quem lê o banco
}

class Setlist { id, nome, emoji, itens, criadoEm, editadoEm, apagada /* lápide */; copyWith; int get frasesAprox; }

class BancoSetlists {
  static const maxSetlists = 50, maxItens = 300, maxBytes = 900000;
  final Map<String, Setlist> porId; final String ultimaUsada;
  List<Setlist> get visiveis;   // sem as apagadas, editadoEm mais novo primeiro
  criar / renomear / apagar / adicionar / remover / restaurar (desfazer) / mover / usar;
  static BancoSetlists mesclar(BancoSetlists local, BancoSetlists nuvem);
  String toJsonString();                           // poda lápides com mais de 90 dias
  static BancoSetlists fromJsonString(String? s);  // nunca lança; entrada ruim → vazio
}
```

**Regra do `mesclar`:** por id de setlist vence o `editadoEm` maior; empate → vence a apagada; `ultimaUsada` vem do `local`.

**Tabela de refs** (resolvidas na hora de tocar contra `CursoState.trilhas`, para correções de conteúdo chegarem sozinhas):

| tipo | `ref` | Vira |
|---|---|---|
| frase | `chaveDaFrase(trecho)` (o `Trecho.id`, ou `Revisao.chave(cod)` nos textos do aluno) | 1 frase: procura em `licaoId`, depois no índice global; sem achar, toca a foto `en`/`pt` (frase órfã) |
| trecho | `Licao.id` | as frases com chave em `chaves`, na ordem da lição; chaves sumidas são puladas; nenhuma → a lição inteira |
| licao | `Licao.id` (`txt-<id>-<n>` também) | todas as frases da lição |
| trilha | `Trilha.baralhoId` (`tr:<slug>` / `txt:<textoId>`) | todas as lições da unidade (cobre "Meus cartões" = `txt:cartoes`) |
| etapa | `A1`/`A2`/`B1`/`B2`/`C1`/`DEV` | todas as unidades não-`propria` com o mesmo `codigoEtapa` |
| curso | `''` | todas as unidades não-`propria`, na ordem do curso |

**JSON guardado:** doc `users/{uid}/setlists/v1`, campo `b` com o JSON em string; espelho local na pref `en_setlists_<uid>`.
```json
{"v":1,"u":"<ultimaUsada>","s":{"<setlistId>":{"n":"Inglês no ônibus","e":"🎧","c":1760000000000,"m":1760000000000,"x":false,
  "i":[{"i":"ikx3a9f2","t":"trecho","r":"primeiro-contato.oi-tudo-bem","k":["f-1a2b3c","f-4d5e6f"],
        "l":"primeiro-contato.oi-tudo-bem","n":"Oi, tudo bem? · 2 frases","c":1760000000000},
       {"i":"ikx3aa01","t":"frase","r":"f-9z8y7x","l":"…","n":"“Nice to meet you.”","en":"Nice to meet you.","pt":"Prazer.","c":1760000000001}]}}}
```
Chaves vazias/padrão ficam de fora. `x:true` é lápide e o `i` dela vai como `[]`.

**`lib/features/ingles/domain/fila_ouvir.dart`** (Dart puro): `Faixa` (chave, en, pt = `dicaPlana`, quem, licaoId, licaoNome,
licaoEmoji, trilhaNome, etapa, itemIdx, primeiraDaLicao, temGravacao, segundos a 1×); `IndiceOuvir.de(trilhas)` (memoizado por
`identical(trilhas)`, com `frase`, `licao`, `trilha`, `etapas`, `trilhas`); `FilaOuvir` (faixas, `inicioDoItem`, `indisponiveis`,
somas de prefixo `segundosTotal`/`segundosDe`, `indiceDaChave(chave, dica:)`, `inicioDaLicao`/`proximaLicao`/`licaoAnterior`);
`resolverFila(ix, itens, duracaoDe:, temGravacao:)`, `contarFrases(ix, item)` e `formatarDuracao(seg)` ("38 s", "4 min", "3 h 58 min").

### 4.2 Áudio e motor — Grupo B

**`domain/saida_audio.dart`:** `enum FimDaFala { acabou, cortada, semVoz }` e a interface `SaidaDeAudio` (`en`, `pt`, `silencio`,
`parar`, `preaquecer`, `somLiberado`, `duracaoDe`, `temGravacao`). **É ela que os testes trocam por uma falsa.**

**Acréscimos em `VozIngles` (só aditivos):** `static vezGlobal` (sobe em `falar` e `parar`; o `finally` passa a limpar `falando` só se
`minha == _vez && g == _vezGlobal` — a boca deixa de ser apagada por um player cortado); `falarNoPlayer(frase, fator:)` (ignora
`lentaPorPadrao`); `falarPt(texto)` (`fala.falarEm(…, 'pt-BR')`; sem voz → `semVoz`; não anuncia boca); `silencio(d)` (web:
`fala.tocarSilencio(ms)`; fora da web `Future.delayed`); `static duracaoDe(frase)` (pela trilha da boca, senão palavras × s/palavra) e
`static preaquecer(frase)`. Cada método novo começa com `final g = ++_vezGlobal;` e devolve `g == _vezGlobal ? acabou : cortada`.

**Camada `fala_*`** (assinaturas antigas mantidas): `falarEm(texto, velocidade, lang)`, `temVozEm(prefixo)`, `tocarSilencio(ms)` (WAV
16-bit 8 kHz mono de zeros feito em Dart, blobs em baldes de 100 ms até 16 s, mesmo contrato `_novaVez`/`_geracao` do `tocar`),
`preaquecer(asset)` e `oculto` (`document.visibilityState`). Nativo: `falarEm` troca o idioma do TTS e volta para en-US; stub: `false`.
`escolha_voz.dart` também pontua vozes pt-BR; `bocas_ingles.dart` ganha `static double? duracaoDe(String? asset)` (só o último token).

**`domain/config_ouvir.dart`:** `ModoOuvir { soIngles, inglesPortugues, portuguesIngles }`, `PausaOuvir { curta, media, longa, eco }`,
`DesligarEm { nunca, min15, min30, min60, fimDaLicao }`, `FaseOuvir { ouvindo, traducao, pense, suaVez, respiro }`; `ConfigOuvir`
(modo `soIngles`, velocidade 1.0 ∈ {0,75; 0,9; 1; 1,15}, repetições 1..3, `segundaDevagar` (2ª passada a 0,8×), pausa `media`,
`mostrarTraducao` true, `repetirTudo` false; `toJson`/`fromJson` tolerante); passos `FalaEn`/`FalaPt`/`Silencio`;
`passosDa(faixa, config, fimDeLicao:)` e `pausaPara(pausa, segundos, velocidade)`.

- **Pausas:** curta 0,5 s; média 1,0 s; longa 2,0 s; eco `clamp(seg*1.2/v + 0.8, 1.5, 9)` (fase `suaVez`); pense
  `clamp(seg*1.5/v + 1.0, 2, 10)`; fim de lição +1,5 s.
- **Passos por modo:** soIngles `[FalaEn, pausa] × repetições`; inglesPortugues `FalaEn, 0,4 s, FalaPt, pausa`;
  portuguesIngles `FalaPt, pense, FalaEn, pausa`.

**`data/sessao_midia.dart`** (+ `_web`/`_stub` por import condicional, como `fala_*`): `SessaoMidia.criar()`, `atualizar(titulo,
artista, album, tocando)`, `acoes(play, pause, proxima, anterior, parar)`, `limpar()`, `oculta`. Na web a capa é `icons/Icon-512.png`
e `seekbackward` vira `repetirAtual`.

**`data/preferencias_ouvir.dart`:** pref `en_ouvir_cfg` (a `ConfigOuvir`) e `en_ouvir_pos_<uid>` (`{fonteId: {"i","k","m"}}`, só local);
`PreferenciasOuvirMemoria` para testes. **`data/saida_voz_ingles.dart`:** `SaidaVozIngles implements SaidaDeAudio`.

**`presentation/ouvir/ouvir_state.dart` e `ouvir_cubit.dart`:** `StatusOuvir { parado, tocando, pausado, acabou }`,
`MotivoPausa { usuario, outraFala, semSom, timer }`, `FonteOuvir(id /* 'curso' | 'setlist:<id>' | 'avulso' */, titulo)`, `OuvirState`
(status, motivo, fonte, fila, indice, fase, vez/de, config, desligar, desligaAs, telaCheia, ouvidas; `atual`, `restanteSeg`, `ativo`).
`OuvirCubit({saida, prefs, midia, esperar, agora})` com `de(context)` (null fora do inglês), `tocar`, `pausar`, `continuar`,
`alternar`, `proxima`, `anterior`, `repetirAtual`, `irPara`, `proximaLicao`, `licaoAnterior`, `configurar`, `desligarEm`,
`telaCheia`, `fechar` (para e limpa; a posição salva fica), `posicaoSalva` e `close` (`saida.parar()`, `midia.limpar()`).

**Regras do motor:**
- **Um laço por `_token`:** `pausar`, `proxima`, `anterior`, `irPara`, `fechar` e `tocar` sobem o token e chamam `saida.parar()` antes —
  o `cortada` que o próprio corte gera é ignorado.
- **Cada passo** é `Future.any([saida.x(...), esperar(limite)])`, `limite = segundos/v*2.5 + 3 s`. Estourou: `saida.parar()` e pula a frase.
  `cortada` com token vivo → `pausado` + `outraFala` e **nunca volta sozinho**. `pt` com `semVoz` (ou `midia.oculta` no iOS web) →
  silêncio do tamanho estimado.
- **Três `en` seguidos terminando em < 150 ms** → `pausado` + `semSom` (navegador bloqueado ou stub).
- `continuar` sempre chama `saida.parar()` e recomeça a frase atual; `anterior` até 1,5 s do começo volta uma frase, senão recomeça.
- **Depois de cada frase:** `ouvidas++`, preaquece `i+1` e `i+2`; salva a posição a cada 5 frases, ao pausar, ao fechar e na virada de lição.
- **Timer:** só conferido entre frases; `fimDaLicao` para na próxima frase com `primeiraDaLicao` → `pausado` + `timer`.
- **Fim da fila:** `repetirTudo` volta ao 0; senão `acabou`. Emite só quando muda frase, fase, status ou config (a boca segue no
  `VozIngles.falando`). Media Session a cada frase: título = EN, artista = `"$quem · $licaoNome"`, álbum = `"Paclingo · ${fonte.titulo}"`.
- **Nunca toca sozinho:** depois de recarregar o estado é `parado`; o hub oferece "Continuar".

### 4.3 Setlists: cubit e repositório — Grupo A

`data/setlists_repository.dart` copia `palavras_repository.dart` um para um: `SetlistsRepository { carregar(); salvar(b); }` (nenhum
lança), `LocalSetlistsRepository(uid)`, `MemoriaSetlistsRepository([banco])` e `FirestoreSetlistsRepository(uid)` (local primeiro;
carregar mescla aparelho + nuvem com `mesclar`; salvar em transação com o espelho local de reserva).

`presentation/ouvir/setlists_cubit.dart`: `SetlistsCubit({repo, agora})` com `de`, `carregar` (memoizado), `criar`, `renomear`,
`apagar`, `adicionar(item, setlistId:)` (null → `ultimaUsada`, ou cria "Minha setlist"), `remover`, `restaurar`, `mover` e
`moverItemPara` (o "Trocar" do snackbar). Gravações em série, só a mais nova vai depois, 600 ms de folga.

### 4.4 Funções públicas da UI — Grupo C (`presentation/ouvir/ouvir_acoes.dart`), usadas pelo D

```dart
Future<void> abrirOuvir(BuildContext c);
Future<void> abrirTocando(BuildContext c);
Future<void> tocarItens(BuildContext c, List<ItemSetlist> itens, {required String titulo});  // fonte 'avulso'
Future<void> tocarCursoDesde(BuildContext c, String licaoId);       // "Ouvir daqui até o fim do curso"
Future<void> porNaSetlist(BuildContext c, ItemSetlist item);        // põe rápido + snackbar (Desfazer / Trocar)
Future<void> escolherSetlist(BuildContext c, ItemSetlist item);     // folha "Pôr em qual setlist?"
Future<void> escolherFrasesDaLicao(BuildContext c, Licao l);        // folha com as frases para marcar
class BotaoPorNaSetlist extends StatelessWidget { item: ItemSetlist Function(); redondo = true; } // toque = põe; longo = escolhe
class NavegadorOuvir { final chave = GlobalKey<NavigatorState>(); static NavegadorOuvir? de(BuildContext c); }
class OuvirShell extends StatelessWidget { child; static Widget envolver(BuildContext c, Widget child); } // sem OuvirCubit → child
SaidaDeAudio saidaPadrao();                                         // SaidaVozIngles(); usada pelo main
```
Toda função volta na hora quando `OuvirCubit.de` ou `SetlistsCubit.de` é null.

**Por que `NavegadorOuvir` é um por curso:** nasce dentro do `_cursoDe` (chave `uid:linguagem`), então outra conta ou outra linguagem
ganha outra chave. Uma `GlobalKey` estática faria o Flutter reaproveitar o Navigator antigo (e a pilha de rotas) depois de trocar de conta.

### 4.5 Regra do Firestore — Grupo A
```
// Setlists do "Ouvir" (inglês): um documento `v1` com o banco inteiro.
match /users/{uid}/setlists/{doc} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```
**Ordem do deploy:** publicar as regras **antes** do hosting. A exclusão de conta também apaga `users/{uid}/setlists`.

## 5. Grupos e arquivos (sem dois donos no mesmo arquivo)

**Fase 0 (líder):** esqueletos com as assinaturas da seção 4 (corpos `throw UnimplementedError()` ou triviais). Feita em 20/out/2026.

| Grupo | Arquivos novos | Arquivos alterados |
|---|---|---|
| **A: domínio, persistência, regras** | `domain/setlist.dart`, `domain/fila_ouvir.dart`, `data/setlists_repository.dart`, `presentation/ouvir/setlists_cubit.dart`, `test/ingles_setlist_test.dart`, `test/ingles_fila_ouvir_test.dart`, `test/ingles_setlists_repository_test.dart`, `test/ingles_setlists_cubit_test.dart` | `firestore.rules`, `lib/features/auth/data/exclusao_de_conta.dart`, `test/firestore_rules_test.dart` |
| **B: áudio e motor** | `domain/saida_audio.dart`, `domain/config_ouvir.dart`, `data/saida_voz_ingles.dart`, `data/preferencias_ouvir.dart`, `data/sessao_midia*.dart`, `presentation/ouvir/ouvir_state.dart`, `presentation/ouvir/ouvir_cubit.dart`, `test/ingles_voz_vez_global_test.dart`, `test/ingles_config_ouvir_test.dart`, `test/ingles_ouvir_cubit_test.dart` | `data/voz_ingles.dart`, `fala_web.dart`, `fala_nativo.dart`, `fala_stub.dart`, `escolha_voz.dart`, `bocas_ingles.dart` (tudo aditivo) |
| **C: telas do Ouvir** | `presentation/ouvir/ouvir_acoes.dart`, `ouvir_page.dart`, `setlist_page.dart`, `tocando_page.dart`, `mini_player.dart`, `escolher_setlist_sheet.dart`, `escolher_frases_sheet.dart`, `widgets/arvore_curso.dart` (padrão copiado de `escolher_licoes_page.dart`, nunca importado), `widgets/chips_ouvir.dart`, `test/ingles_ouvir_ui_test.dart`, `test/ingles_tocando_ui_test.dart`, `test/ingles_mini_player_ui_test.dart` | nenhum |
| **D: fiação e documentação** | `test/ingles_ouvir_app_test.dart`, este arquivo | `lib/main.dart`, `curso/presentation/widgets/hud.dart`, `curso/presentation/pages/mapa_page.dart`, `curso/presentation/pages/mapa/guia_trilha.dart`, `ingles/presentation/palco_ingles.dart` (só `acaoAudio`), `ingles/presentation/navegador_cartoes_page.dart`, `ESTADO-DO-PROJETO.md` |

### D: as edições (como ficaram)

- **`main.dart`:** `PacDartApp` ganhou `setlistsBuilder` (`SetlistsRepository Function(AppUser)?`) e `saidaOuvirBuilder`
  (`SaidaDeAudio Function()?`). No `_cursoDe`, **só no inglês**: `RepositoryProvider(create: (_) => NavegadorOuvir())`,
  `SetlistsCubit(repo: setlistsBuilder ?? (Firebase iniciado ? Firestore… : Local…))..carregar()` e
  `OuvirCubit(saida: saidaOuvirBuilder?.call() ?? saidaPadrao(), prefs: PreferenciasOuvir(uid), midia: SessaoMidia.criar())`.
  No `_AppShell`: `navigatorKey: NavegadorOuvir.de(context)?.chave` e `builder: (c, child) => OuvirShell.envolver(c, child!)`
  (no Dart/C# não há chave e o filho passa como veio).
- **`hud.dart`:** `_Toggle` "Ouvir" (`Icons.headset_rounded` — o `headphones` já é o 🎧 "seu áudio" do palco e um teste conta esse ícone; `Key('ouvir-hud')`) quando `OuvirCubit.de(context) != null`;
  aceso enquanto o player está ativo; abre `abrirOuvir`.
- **`mapa_page.dart`:** `_CartaoOuvir` depois do `_CartaoLer` (`ouvir-cartao-mapa`; enquanto toca diz "Tocando: «…»"). Na folha da lição,
  só no inglês com o player, um bloco "🎧 OUVIR — SEM DIGITAR": "▶ Ouvir esta lição" (`ouvir-licao-tocar` → `tocarItens([daLicao])`),
  "⏩ Ouvir daqui até o fim do curso" (`ouvir-licao-daqui` → `tocarCursoDesde`; some em texto próprio), "➕ Pôr na setlist"
  (`ouvir-licao-add`; **toque longo** abre `escolherFrasesDaLicao`) e "Escolher frases…" (`ouvir-licao-frases`). A folha fecha antes de
  cada ação (o player e o snackbar aparecem no mapa) e agora **rola** em tela baixa.
- **`guia_trilha.dart`:** `onOuvir` / `onSetlist` opcionais → "🎧 Ouvir a unidade" (`Botao3D`, `ouvir-unidade-tocar`) e ➕ redondo de 48 px
  (`ouvir-unidade-add`, semântica "Pôr na setlist"); o `mapa_page` só passa no inglês com o player.
- **`palco_ingles.dart`:** `acaoAudio: Row(min, [BotaoAudioDaFrase(...), SizedBox(6), BotaoPorNaSetlist(key: Key('botao-setlist'),
  item: () => ItemSetlist.daFrase(_trecho, licao: curso.licao))])`. Nada mais muda no palco.
- **`navegador_cartoes_page.dart`:** item `'setlist'` "➕ Pôr na setlist" no menu ⋮ (cada linha tem o `Trecho`, então `daFrase`).

## 6. UI (Grupo C)

**`OuvirShell`** (no `MaterialApp.builder`, acima do Navigator): `Material` → `Column[Expanded(MediaQuery com a altura menos a barra e
padding de baixo 0 → child), MiniPlayer]` — o conteúdo encolhe em vez de ficar coberto. **Não há Overlay nesse nível:** usar
`Semantics(label:)`, nunca `Tooltip`; o "Tocando agora" abre por `NavegadorOuvir.de(c)!.chave.currentState!.push(...)`.
Some quando `parado`, `telaCheia` ou `viewInsets.bottom > 0` (teclado do palco aberto). Barra de 64 px + SafeArea, linha de progresso
de 3 px, `ClipOval(PersonagemFalante)` de 36–40 px (fundo `0xFFFFF1DC`), a linha EN e "{lição} · 34/212" (com reticências), ⏯ ⏭ ✕.
Interrompido: "Pausado — outra fala começou"; fim: "Fim de «{nome}» 🎉". Desktop (≥ 900 px): cartão centralizado de 720 px, margem 12.

**`OuvirPage`** ("🎧 Ouvir", largura máx. 720): (1) cartão "Curso na ordem" ("5.308 frases · ~4 h", ▶ Continuar
`ouvir-curso-continuar` com "Parou em: {emoji} {lição} ({etapa})", ▶ Da minha lição atual `ouvir-curso-atual`, ↺ Do começo
`ouvir-curso-inicio`); (2) "Minhas setlists" (cartões `setlist-<id>` com emoji, nome, "{n} itens · {m} frases · ~{x} min", ▶ e ⋯
Renomear/Apagar; "＋ Nova setlist" `ouvir-nova-setlist`; estado vazio); (3) "Explorar o curso" (`ArvoreCurso` etapa → unidade → lição,
▶ e ➕ em toda linha, "Escolher frases…" nas lições, 🔒 nas trancadas que ainda tocam, "Meus textos" com a etiqueta "voz do sistema").

**`SetlistPage`:** nome editável, resumo, ▶ Tocar (`setlist-tocar`), `ReorderableListView` com alça; ícone por tipo (💬 frase, ✂️ trecho,
📘 lição, 🧭 unidade, 🏔 etapa, 🌍 curso), rótulo, contagem e duração; remover com ✕ ou deslizando (snackbar **Desfazer**); ⋯ com
Tocar daqui, Mover para cima/baixo, Remover; item indisponível em cinza com Remover; tocar numa linha toca a partir dela.

**`TocandoPage`** (`telaCheia(true)` ao abrir, `false` ao fechar): ⌄ minimizar, título da fonte, "Lição 2 de 14 · Frase 4 de 9"; rosto
(96 px no celular, 140 no largo) com o nome; trilha "{etapa} › {unidade} › {lição}"; EN em `Mixart.display` (quebra, nunca FittedBox);
legenda PT; chip da fase; "Frase 37 de 412 · faltam ~18 min" + `LinearProgressIndicator`. Controles ⏮ lição, ⏪ frase, ⏯ (64 px,
`ouvir-play`), ⏩ frase, ⏭ lição, ↺ repetir. Chips (quebram linha): velocidade, modo, repetir, 2ª devagar, pausa, tradução, repetir tudo,
timer. Ações: "➕ Pôr esta frase na setlist", "✍️ Praticar esta lição" (pausa, `LicaoSelecionada`, volta à 1ª rota) e "A seguir"
recolhível (20 próximas, `ListView.builder`). Avisos para `outraFala`, `semSom`, `timer` e `acabou`. Teclado só com a rota no topo:
Espaço ⏯, ←/→ frase, R repete, Esc minimiza. Desktop (≥ 900 px): duas colunas, player e "A seguir".

**Folhas:** `escolher_setlist_sheet` (rádio com a última usada marcada, "＋ Nova setlist" com nome e 8 emojis; com sessão ativa também
"▶ Tocar agora"); `escolher_frases_sheet` (caixas com EN, PT e 🔊 de prévia; "➕ Pôr {n} frases na setlist" `frases-add` e
"▶ Ouvir só estas" `frases-tocar`; a seleção passa por `ItemSetlist.doTrecho`).

**Regras de toda tela:** só tokens `Mixart.*` (recolorem no claro e no escuro); alvos ≥ 48 px; `Semantics` "Tocar", "Pausar",
"Próxima frase", "Frase anterior", "Próxima lição", "Lição anterior", "Repetir frase", "Fechar player", "Pôr na setlist"; a frase não é
live region tocando, avisos usam `SemanticsService.announce`; `disableAnimations` deixa rosto e progresso parados.
360/390 px: uma coluna, chips quebrando, cinco controles de 48 px e só ⏯ ⏭ ✕ no mini-player.

## 7. Textos da UI (canônicos)

| Onde | Texto |
|---|---|
| HUD / cartão | **Ouvir** · "🎧 Ouvir — escute as lições na ordem ou monte suas setlists, sem digitar." |
| Hub | "Escute as lições sem digitar — no ônibus, na academia, lavando a louça." · **Curso na ordem** · "{n} frases · ~{t}" · **Continuar** · **Da minha lição atual** · **Do começo** · "Parou em: {lição}" · **Minhas setlists** · **＋ Nova setlist** · **Explorar o curso** · **Meus textos** · "voz do sistema" |
| Sem setlists | "Monte sua setlist: toque em ➕ numa frase, lição ou unidade enquanto estuda." |
| Setlist vazia | "Sua setlist está vazia. Toque em ➕ numa frase, lição ou unidade enquanto estuda." |
| Ações | **Ouvir esta lição** · **Ouvir daqui até o fim do curso** · **Ouvir a unidade** · **Ouvir a etapa** · **Pôr na setlist** · **Escolher frases…** · **Tocar agora** · **Tocar daqui** · "Pôr {n} frases na setlist" · **Ouvir só estas** |
| Snackbars | "Adicionado a «{nome}»." **Desfazer** · **Trocar** · "Já está em «{nome}»." · "«{nome}» está cheia (300 itens)." |
| Gerenciar | "Pôr em qual setlist?" · "Nome da setlist" · "Ex.: Inglês no ônibus" · **Criar** · **Renomear** · "Apagar «{nome}»? As frases continuam no curso; só a lista some." **Apagar** / **Cancelar** · "Removido." **Desfazer** · "Item indisponível (saiu do curso)" · **Remover** · **Mover para cima** / **Mover para baixo** |
| Rótulos | "Minha setlist" (criada sozinha) · "Curso inteiro" · "Etapa {A1}" · "Unidade: {nome}" · "{lição} · {n} frases" · "Lição à frente — pode ouvir à vontade" |
| Player | "Lição {a} de {b} · Frase {c} de {d}" · "Frase {i} de {n} · faltam ~{t}" · **A seguir** · **Praticar esta lição** · "Pôr esta frase na setlist" |
| Fases | "🔊 Ouça ({vez}/{de})" · "🇧🇷 Tradução" · "🧠 Pense: como se diz em inglês?" · "🗣️ Sua vez — repita em voz alta" |
| Chips | "Velocidade 0,75× / 0,9× / 1× / 1,15×" · "Só inglês / Inglês → português / Português → inglês" · "Repetir 1× 2× 3×" · "2ª vez devagar" · "Pausa: Curta / Média / Longa / Eco 🗣" · "Tradução" · "🔁 Repetir tudo" · "⏾ Desligar: 15 min · 30 min · 1 h · No fim da lição · Desligado" |
| Avisos | "Pausado: outra fala começou. ▶ para continuar." · "Não consegui tocar o som. Toque ▶ para tentar de novo." · "Timer acabou — até amanhã! 🌙" · "Fim de «{nome}» 🎉 Você ouviu {n} frases." **Tocar de novo** |
| Voz PT | "Seu navegador não tem voz em português — a tradução aparece só na tela." · "Com a tela apagada, o português pode não tocar. Use «Só inglês»." |

## 8. Chaves de teste

`ouvir-hud`, `ouvir-cartao-mapa`, `ouvir-curso-continuar`, `ouvir-curso-atual`, `ouvir-curso-inicio`, `ouvir-nova-setlist`,
`setlist-<id>`, `setlist-tocar`, `setlist-item-<itemId>`, `ouvir-play`, `ouvir-proxima`, `ouvir-anterior`, `ouvir-proxima-licao`,
`ouvir-licao-anterior`, `ouvir-repetir`, `mini-player`, `mini-player-play`, `mini-player-fechar`, `botao-setlist`, `ouvir-licao-tocar`,
`ouvir-licao-daqui`, `ouvir-licao-add`, `ouvir-licao-frases`, `ouvir-unidade-tocar`, `ouvir-unidade-add`, `frases-add`, `frases-tocar`,
`ouvir-banner-outra-fala`, `ouvir-banner-sem-som`, `ouvir-banner-fim`.

## 9. Testes por grupo

Convenções: `SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false})`, achar por `Key`, `_anda` em vez de
`pumpAndSettle` nos testes de app, conferir 360, 390 e 1400 px no claro e no escuro.

- **A** — `ingles_setlist_test` (ida e volta do JSON com chaves curtas e padrões de fora; entrada corrompida/desconhecida → banco vazio
  ou item descartado, sem lançar; `assinatura` → `jaEstava`; limites de itens e bytes → `cheia`; `mover`/`remover`/`restaurar`; `mesclar`:
  última edição vence, empate vai para a lápide, edição nova vence lápide velha, lápides com mais de 90 dias somem; `doTrecho`;
  `codigoEtapa`) · `ingles_fila_ouvir_test` (cada `TipoItem` na ordem do diálogo; `trecho` com chave sumida e volta para a lição inteira;
  `frase` por hash; órfã com foto toca, sem foto vai para `indisponiveis`; `curso`/`etapa` sem `propria`; `inicioDoItem`, somas de prefixo,
  `indiceDaChave` com dica e sem, `proximaLicao`/`licaoAnterior`, `formatarDuracao`) · `ingles_setlists_repository_test` (Memória e Local;
  pref corrompida → vazio; Firestore com `fake_cloud_firestore` e a mescla aparelho + nuvem) · `ingles_setlists_cubit_test` ("Minha
  setlist" criada sozinha; `ultimaUsada`; `moverItemPara`; gravações em série, só a mais nova) · `firestore_rules_test` (o caminho novo).
- **B** — `ingles_voz_vez_global_test` (`vezGlobal` sobe na hora; `falarNoPlayer` → `cortada` quando outra `VozIngles()` fala, `acabou`
  quando ninguém fala; ignora `lentaPorPadrao`; player cortado não apaga mais a boca da outra instância) · `ingles_config_ouvir_test`
  (passos exatos por modo, repetições com "2ª devagar", limites das pausas, pausa extra no fim da lição, `fromJson` tolerante) ·
  `ingles_ouvir_cubit_test` (saída falsa com Completers + `esperar`/`agora` falsos: ordem; pausar e continuar recomeça a frase; próxima,
  anterior (regra de 1,5 s), próxima/anterior lição; `cortada` → `pausado`/`outraFala` sem avançar; 3 retornos instantâneos → `semSom`;
  vigia pula frase presa; `pt` `semVoz` vira silêncio; timer de N minutos e `fimDaLicao` param na virada; fim → `acabou`, `repetirTudo`
  volta; posição salva e restaurada; `close` chama `parar`; Media Session falsa recebe metadados e ações).
- **C** — `ingles_ouvir_ui_test` (seções do hub, subtítulo do continuar, criar setlist, vazio, folha de escolha, checklist gerando
  `trecho`, `SetlistPage` com reordenar, deslizar + desfazer e item indisponível; 360/390/1400 px, claro e escuro, sem estouro) ·
  `ingles_tocando_ui_test` (chip da fase, controles, chips mudam a config, avisos, duas colunas em 1400 px, atalhos só com a rota no topo) ·
  `ingles_mini_player_ui_test` (dentro de `MaterialApp(builder: OuvirShell.envolver)`: barra fica nas rotas, some com o "Tocando agora" e
  com teclado, ✕ limpa, toque abre o "Tocando agora", não existe sem `OuvirCubit`).
- **D** — `ingles_ouvir_app_test`: `PacDartApp(..., setlistsBuilder: (_) => MemoriaSetlistsRepository(), saidaOuvirBuilder: () =>
  _SaidaFake(), linguagemInicial: Linguagem.ingles)` em `runAsync`: (1) HUD 🎧 → "Do começo" → o mini-player aparece; (2) abre e fecha o
  Mapa → continua; (3) ➕ na folha da lição → snackbar e o hub mostra "Minha setlist" com 1 item; (4) o ➕ do palco (`botao-setlist`)
  existe (e põe a frase); (5) a saída devolve `cortada` → o aviso aparece; (6) o app de Dart não tem `ouvir-hud`, nem mini-player, nem
  `OuvirShell`. Mais um caso em 390 px (HUD e cartão sem estouro). A `_SaidaFake` deixa cada fala **pendente** (o player fica parado na
  frase, sem relógio de verdade) e `parar()` corta as pendentes; no fim o teste deixa vencer os relógios (`pump(30 min)`).

## 10. Validação e deploy (o líder faz)

- Os agentes só escrevem código. O líder roda `flutter analyze` e `flutter test` (os novos e a suíte inteira). **Um** build de prova web,
  numa pasta reaproveitada e apagada depois — nunca `flutter build web` em loop.
- Publicar `firestore.rules` **antes** do hosting.
- **Conferir em aparelho de verdade** (comportamento em segundo plano não provado): (1) Chrome desktop com a aba oculta por 20 min — a
  fila anda e as pausas ficam perto do tamanho? (2) Chrome Android com a tela bloqueada — continua tocando e aparece notificação de mídia?
  (a notificação deve pedir ~5 s de mídia; os clipes têm 2,7 s em média) (3) Safari iOS bloqueado por 10 min (4) setlist de texto do aluno
  (Web Speech) com a aba oculta (5) tocar 🔊 no palco com a playlist tocando → pausa com aviso (6) 360 px com mini-player + teclado do palco
  (7) tema claro.

## 11. Fica para depois (fora da v1)

- **Áudio nativo em segundo plano e tela de bloqueio:** `audio_service`, `UIBackgroundModes audio`, `FOREGROUND_SERVICE`, `WAKE_LOCK` —
  precisa de autorização do dono e mexe na revisão das lojas.
- **mp3 pt-BR:** adaptar `tools/ingles/vozes_google.py` (~5,3 mil arquivos, 55–60 MB, gerados fora do projeto) — precisa de autorização.
- **Mais receitas:** "Conversa: você responde" e "Pra dormir". **Mais conteúdo:** embaralhar, os 512 exemplos da teoria, leituras (sem mp3).
- **Notificação no Android:** faixa silenciosa de companhia, só se a conferência 2 falhar.
- Outros: Screen Wake Lock; "Tocar em seguida"; refazer a fila quando a setlist tocando é editada (a v1 toca uma foto); posição na nuvem;
  ➕ em `sessao_cartoes_page`, `BannerUnidade` e na vitória do palco; "Só o que já estudei"; lista "⭐ Frases difíceis" do `RevisaoCubit`;
  minutos ouvidos no `HabitoCubit`; tirar rotas do Arcade do mini-player com `SemMiniPlayer` quando o trabalho do Arcade acabar.
