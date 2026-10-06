# 06 — Áudio (TTS) no navegador e digitação de inglês em teclados brasileiros

Frente de pesquisa técnica para o curso de Inglês do PAC·DART (Flutter web, pac-dart.web.app).
Data: 04/10/2026. Escopo: (A) como fazer o app *falar* as frases em inglês e (B) como garantir que a
pessoa consiga *digitar* inglês em teclado brasileiro sem o motor punir erros que são do teclado, não dela.

> Método: fontes primárias na web (MDN, browser-compat-data, Chrome/Apple/Microsoft, W3C, Hugging Face,
> licenças originais), leitura do código-fonte do `flutter_tts` e do motor de texto do Flutter web, arquivos
> KLC oficiais dos layouts do Windows, e **simulação real dos layouts do macOS** com `UCKeyTranslate`
> (script em `_fontes/layouts.swift`, ao lado deste arquivo). Também li (sem alterar nada) o estado atual do
> repositório para que as recomendações encaixem no que já existe. Itens que não consegui confirmar numa
> fonte estão marcados como **(a verificar)**.

---

## 0. Resumo executivo

**Áudio**

1. **Web Speech API (`speechSynthesis`) já resolve o MVP de graça**, mas a qualidade depende do navegador:
   Edge (vozes "Microsoft ... Online (Natural)") é excelente; Chrome desktop ("Google US English") é bom;
   **Safari/iOS é fraco** (só vozes pré-instaladas, como a Samantha compacta; as vozes premium/Siri não
   aparecem para páginas web, e a Apple diz que isso é intencional).
2. O Mac do dono só tem as vozes padrão instaladas (Samantha, Daniel, Eloquence e as vozes "de brincadeira"):
   **no Safari dele o curso vai soar robótico; no Chrome/Edge do mesmo Mac, bem melhor.**
3. A integração atual via `flutter_tts` tem **riscos concretos no web**: `getVoices()` não espera o
   `voiceschanged` (no Chrome a 1ª chamada vem vazia), `setLanguage('en-US')` não faz nada quando a lista
   está vazia (a 1ª frase pode sair com a **voz em português** padrão do sistema), e `stop()`+`speak()` em
   sequência depende de um estado que só muda quando chega um evento assíncrono (o "ouvir de novo" pode ser
   ignorado). Recomendo um invólucro próprio com `package:web` (que o projeto já usa), com uns 120 linhas.
4. **Destaque palavra a palavra (`onboundary`) não funciona no Chrome com vozes Google** (bug registrado no
   MDN/BCD) nem no Android. Só use destaque quando houver dado real: `boundary` detectado em tempo de execução
   (Edge/Safari/Firefox) ou timestamps de áudio pré-gerado.
5. **Áudio pré-gerado no build é a fase 2 recomendada**: **Kokoro-82M** (pesos Apache-2.0, voz `af_heart`
   nota A) gera inglês muito natural e **devolve o tempo de cada palavra** (dá para destacar palavra por
   palavra em qualquer navegador). Uma frase típica tem 8–16 KB (medido: Opus 24 kbps ≈ 8 KB; MP3 32 kbps
   ≈ 11 KB para 2,6 s). 6.000 frases × 2 velocidades ≈ 135–170 MB: cabe com folga no plano gratuito do
   Firebase Hosting (10 GB armazenados, 10 GB/mês de saída ≈ 333 MB/dia).
6. **Proibido / não recomendado como fonte de áudio publicado**: `say` do macOS (a licença do macOS proíbe
   gravar/publicar as vozes do sistema), vozes Piper treinadas em datasets não comerciais (`lessac`,
   `ryan`, `hfc_*`), `edge-tts` (uso não licenciado do serviço da Microsoft) e Gemini TTS em tempo de
   execução (o próprio código do projeto anota cota grátis de ~10 áudios por dia).

**Teclado**

7. **No layout ABNT2 (Windows e Mac — é o layout do dono, confirmado nas preferências do macOS) o apóstrofo
   e as aspas NÃO são teclas mortas.** Digitar inglês é tranquilo. O risco é confundir `´` (acento agudo,
   tecla morta ao lado do P) com `'` (apóstrofo, tecla à esquerda do 1 no PC) — o famoso "don´t".
8. **No US-International (Windows e o "U.S. International – PC" do Mac) e no layout "Brasileiro" do Mac**
   (ID interno `Brazilian-Pro`), `'` e `"` são teclas mortas: `'`+`c` = **ç** (o'clock vira "oçlock"),
   `'`+vogal = vogal com acento agudo, `"`+vogal = trema, e `'`+espaço = `'` (**o espaço é consumido**).
9. O desenho atual do motor (TextField invisível + esperar a composição terminar + limpar o campo a cada
   caractere) **está correto** e neutraliza boa parte das "aspas inteligentes" do macOS. O `TypingBloc` já
   desdobra `ç`→`'c`, `á`→`'a` etc. Faltam: aceitar `´` e `` ` `` como apóstrofo (com dica), NBSP do
   Option+Espaço, `…`, caracteres invisíveis, normalizar também o texto-alvo e engolir espaço repetido.
10. **Regra de ouro para quem escreve o conteúdo: só ASCII imprimível** (U+0020–U+007E), apóstrofo reto,
    sem travessão, sem reticências, sem aspas curvas, evitar aspas duplas e `& < > # @ * _ | \ { } [ ] ~ ^ ```,
    nada de acentos (cafe, naive), uma frase por item, um espaço entre palavras, pontuação final sempre.
11. **Correção por modo**: em "Copie" tudo é exigido (está à vista); em "De memória" a maiúscula do início
    da frase fica livre e a pontuação (`, . ! ? ; : "`) é preenchida sozinha — apóstrofo e hífen dentro da
    palavra continuam exigidos, porque são ortografia.

---

## 1. O que já existe no repositório (lido, não alterado)

Para não recomendar o que já está feito:

- `lib/features/ingles/data/voz_ingles.dart` — classe `VozIngles` sobre `flutter_tts`: escolhe a "melhor voz"
  por pontuação (`natural`/`neural` +6, `google` +5, `premium`/`enhanced` +4, nomes como aria/jenny/samantha
  +2; en-US vale mais que outros "en"); velocidades `.95` (normal) e `.6` (lenta). Já tenta escolher a voz de
  novo se a 1ª lista vier vazia.
- `lib/features/ingles/domain/roteiro.dart` — modos `ver` ("Copie"), `pistas` ("Com pistas": só a 1ª letra de
  cada palavra) e `memoria` ("De memória": só a tradução; errou uma letra, ela aparece).
- `lib/features/ingles/presentation/palco_ingles.dart` — toca o áudio automaticamente na estreia da frase e nos
  modos pistas/memória, e tem os botões "ouvir" e "ouvir devagar".
- `lib/features/curso/presentation/bloc/typing_bloc.dart` — motor letra a letra, compartilhado com os cursos de
  programação. Já tem: `equivalenciasTeclado` (˜→~, ˆ→^, aspas curvas→retas, – e —→-), `composicoesUsIntl`
  (desdobra `á`→`'a`, `ç`→`'c`, `ä`→`"a`, …) e `_espacoQueSoltaAcento` (engole o espaço que "solta" um acento
  morto `~ ^ ´ ``).
- `lib/features/curso/presentation/widgets/code_view.dart` e `ingles/presentation/widgets/frase_view.dart` —
  TextField invisível com `autocorrect: false`, `enableSuggestions: false`; o texto só é processado quando
  `composing.isCollapsed` (composição de acento terminada) e o campo é limpo a cada lote.
- `lib/core/voz/voz_natural*.dart` — já existe um player de PCM16 via Web Audio (`AudioContext` +
  `AudioBufferSourceNode`) usado pela voz Gemini do tutor. Reaproveitável para áudio pré-gerado (com a ressalva
  da seção A8 sobre velocidade).
- `web/index.html` — `<html>` **sem atributo `lang`**.

Fatos da máquina do dono (lidos com comandos só de leitura):

- Layout ativo no macOS: **`Brazilian-ABNT2`** (`com.apple.HIToolbox` → `AppleEnabledInputSources`).
- Vozes em inglês instaladas para o sistema (`say -v '?'`): **Samantha, Daniel**, as Eloquence (Eddy, Flo,
  Grandma, Grandpa, Reed, Rocko, Sandy, Shelley), Fred/Junior/Kathy/Ralph e as vozes "de brincadeira" (Albert,
  Bad News, Bahh, Bells, Boing, Bubbles, Cellos, Good News, Jester, Organ, Superstar, Trinoids, Whisper, Wobble,
  Zarvox). **Nenhuma voz premium/aprimorada.**

---

# PARTE A — ÁUDIO

## A1. Web Speech API em 1 minuto

- `window.speechSynthesis` (o "motor") + `SpeechSynthesisUtterance` (uma fala: `text`, `lang`, `voice`,
  `rate`, `pitch`, `volume` e os eventos `start`, `end`, `error`, `boundary`, `pause`, `resume`).
- `speechSynthesis.getVoices()` devolve as vozes (`name`, `lang`, `voiceURI`, `localService`, `default`).
  `localService=false` = voz remota (precisa de rede, pode ter latência). [MDN localService]
- `rate`: de 0.1 a 10, padrão 1; "1 = velocidade normal da voz"; motores podem limitar mais a faixa.
  [MDN rate]
- Códigos de erro (`SpeechSynthesisErrorEvent.error`): `canceled`, `interrupted`, `audio-busy`,
  `audio-hardware`, `network`, `synthesis-unavailable`, `synthesis-failed`, `language-unavailable`,
  `voice-unavailable`, `text-too-long`, `invalid-argument`, `not-allowed`. [MDN error]
- **Precisa de gesto do usuário**: desde o Chrome 71, `speak()` falha "se o documento não recebeu uma ativação
  do usuário" (o texto oficial fala em o documento *ter recebido* ativação, ou seja, um clique ou tecla
  anterior na página já basta). [Chrome 71 deps] Como o curso é de digitação, qualquer tecla digitada conta
  como gesto — o autoplay na estreia de cada frase funciona depois da primeira interação. No iOS, convém
  "destravar" a voz falando algo (até uma string curta) dentro do primeiro toque **(a verificar no aparelho)**.
- Para `<audio>`/Web Audio (áudio pré-gerado) vale a política de autoplay do Chrome: som só depois de
  interação (ou MEI alto); `play()` devolve uma Promise que rejeita se bloqueado; `AudioContext` pode nascer
  `suspended` e precisa de `resume()` após o gesto. [Chrome autoplay]

## A2. Que vozes em inglês existem em cada navegador/SO

Base principal: o levantamento do projeto Readium Speech (CC0, mantém a lista das vozes recomendadas por
idioma, com nome exato e nota de qualidade) e o documento "SpeechSynthesis in browsers and OSes".
[Readium WebSpeech] [Readium en.json]

| Ambiente | Vozes en-US/en-GB que aparecem no `getVoices()` | Qualidade | Local / rede | `boundary` |
|---|---|---|---|---|
| **Edge** (Windows e macOS) | `Microsoft AvaMultilingual Online (Natural) - English (United States)`, idem **Andrew**, **Emma**, **Brian** (também sem "Multilingual"), **Jenny**, **Aria**, **Guy**, Michelle, Christopher, Eric, Roger, Steffan, Ana (voz infantil). en-GB: **Sonia**, **Libby**, **Ryan**, **Thomas**, Maisie (infantil). Mais as vozes do SO. | muito alta ("quase humana") | **rede** (nuvem da Microsoft) | geralmente sim **(detectar em runtime)** |
| **Chrome desktop** (Win/Mac/Linux) | `Google US English` (feminina), `Google UK English Female`, `Google UK English Male` + vozes do SO (Windows: Microsoft David/Zira/Mark; Mac: Samantha, Daniel etc.) | alta (as Google) | Google = **rede** | **não** com vozes Google; sim com vozes do SO |
| **Safari macOS** | só as **pré-instaladas**: Samantha (versão compacta), Daniel, Eloquence, as "de brincadeira". Vozes baixadas (Ava/Zoe/Evan premium, Siri) **não aparecem** | baixa a normal | local | sim (só `word`, nunca `sentence`) |
| **iPhone/iPad** (todo navegador usa WebKit) | idem Safari | baixa a normal | local | sim |
| **Firefox desktop** | vozes do SO (Windows SAPI; vozes do macOS) | normal | local | sim |
| **Chrome Android** | a voz padrão do sistema (Google TTS); **não dá para trocar** pela página | alta | local/rede | **não** |
| **Windows 11 — vozes Natural do Narrador** (Aria/Jenny/Guy offline) | só aparecem no **Edge** ("não listadas corretamente no Chrome ou Firefox") | alta | local | — |

Detalhes que importam:

- **Edge**: "mais de 250 vozes pré-carregadas em 75 idiomas"; todas as "Natural" exigem internet; **não aceita
  ajuste de pitch**; e "exige escapar certos caracteres" — o Edge envolve o texto em SSML, então `&`, `<` e `>`
  no texto da frase são risco. No macOS, o Edge às vezes mostra só 18 vozes até a API ser usada uma vez.
  [Readium WebSpeech] Em **julho de 2026 (Edge 150)** houve uma regressão: `getVoices()` devolveu
  `"Microsoft undefined Online (Natural) - undefined"` para todas as vozes Natural, e a fala caía na Microsoft
  David; corrigido na 150.0.4078.99. Conselho da comunidade: rejeitar entradas incompletas e cair para uma voz
  local confirmada. Em máquinas gerenciadas, a política `ConfigureOnlineTextToSpeech` pode desligar as vozes
  online. [Edge 150]
- **Chrome**: as vozes Google "não disparam os callbacks como a especificação manda"; falas longas param depois
  de ~14–15 s (ou 200–300 caracteres). Paliativo clássico: `pause()`+`resume()` a cada ~14 s (quebra no
  Android, onde `pause` = `cancel`). [Caktus] [jankapunkt] [codersblock] Para frases curtas de curso (< ~25
  palavras) esse bug **não aparece**. Com voz remota, `rate > 2` impede a fala e pitch 0 vira 1. [codersblock]
- **Safari**: `voiceschanged` só existe a partir do Safari 16 [BCD SpeechSynthesis]; `addEventListener` não
  funcionava para `voiceschanged` em versões antigas (use `onvoiceschanged`); nomes de voz **não são únicos**
  (use `voiceURI`); o evento `end` **não dispara** quando `cancel()` interrompe a fala; pitch ≤ 0.5 soa igual;
  baixar o `rate` para < 0.5 depois de usar ≥ 0.5 mantém o valor antigo; no iOS a chave de silêncio emudece tudo.
  [codersblock] Vozes premium instaladas **somem** da lista do Safari (e no iOS 18/macOS Sequoia a situação
  piorou); resposta de um engenheiro da Apple: "é esperado que, com a Web Speech API, só as vozes pré-instaladas
  estejam disponíveis". Chrome e Edge no mesmo Mac listam todas. [Apple Forums 723503]
- **Android**: a voz não muda (usa a padrão do aparelho), `boundary` não dispara, `pause` = `cancel`, e o `lang`
  vem com sublinhado (`en_US`) ou em 3 letras no Firefox (`eng-USA-f00`). [codersblock] [jankapunkt]
- **Linux (Chromium)**: pode não ter voz nenhuma sem flags; eSpeak é a pior qualidade possível. [jankapunkt]

### Hierarquia de qualidade (Readium)

1. Edge Natural; vozes Apple equivalentes às da Siri (que a web não acessa)
2. vozes normais do macOS, vozes Natural do Windows, vozes Android do ChromeOS
3. vozes padrão do Chrome/ChromeOS, vozes do SO no Firefox
4. eSpeak ("devem ser evitadas a todo custo")

### Lista de nomes para o ranking (extraída do `json/en.json` do Readium, CC0)

- **Nota "veryHigh"** (só Edge): Emma, Ava, Jenny, Aria, Michelle, Ana*, Andrew, Brian, Guy, Eric, Steffan,
  Christopher, Roger (en-US); Sonia, Libby, Maisie*, Ryan, Thomas (en-GB). *infantis: evitar como padrão.
- **"high"**: `Google US English`, `Google UK English Female/Male` (Chrome desktop); Android/ChromeOS
  `Google US English 1..7 (Natural)` (e apelidos `Android Speech Recognition and Synthesis from Google
  en-us-x-tpc-network` etc.); Apple **Ava, Zoe** (nas versões aprimoradas), **Alex**, Jamie, Serena.
- **"normal"**: Apple Samantha, Allison, Nicky, Joelle, Evan, Nathan, Tom, Kate, Stephanie, Oliver, Daniel;
  Windows `Microsoft Zira/David/Mark - English (United States)`, `Microsoft Hazel/Susan/George - English
  (Great Britain)`.
- **Excluir sempre** (listas `filters/novelty.json` e `filters/veryLowQuality.json`): Albert, Bad News, Bahh,
  Bells, Boing, Bubbles, Cellos, Good News, Jester, Organ, Superstar, Trinoids, Whisper, Wobble, Zarvox, Eddy,
  Flo, Fred, Grandma, Grandpa, Jacques, Junior, Kathy, Ralph, Reed, Rocko, Sandy, Shelley e todo `eSpeak *`.

(Uma cópia de `en.json` e dos filtros está em `_fontes/`.)

## A3. Armadilhas da Web Speech API, com mitigação

| # | Armadilha | Onde | Mitigação |
|---|---|---|---|
| 1 | `getVoices()` vem **vazio** na 1ª chamada (lista assíncrona; o Chrome busca vozes extras do servidor quando há rede) | Chrome desktop/Android, Firefox Android | esperar `voiceschanged` **com timeout** (2–3 s) e, em paralelo, sondar a cada 250 ms (Safari antigo não tem o evento) |
| 2 | Sem `lang` nem `voice`, o navegador usa a voz padrão — num Windows/Mac em português, **voz em português lendo inglês** | todos | sempre `utterance.lang = 'en-US'` **e** `utterance.voice = melhor`; e `<html lang="pt-BR">` + `lang` explícito na fala |
| 3 | Vozes Google **sem `boundary`**; falas > ~14 s cortam | Chrome | não prometer destaque; frases curtas; se um dia houver fala longa, pausar/retomar a cada 14 s |
| 4 | `end` não dispara no `cancel()` | Safari | não depender do `end` para liberar a próxima fala; controlar por "geração" (contador) |
| 5 | Voz some / muda de nome (atualização, rede caiu, Edge 150) | Edge, Chrome | revalidar a voz salva a cada sessão; ignorar nomes com `undefined`; ao `error` = `network`/`synthesis-failed`, marcar a voz como quebrada e repetir com uma voz `localService=true` |
| 6 | `speak()` sem gesto → `not-allowed` | Chrome 71+, iOS | 1ª fala sempre depois de um clique/tecla (no curso isso acontece naturalmente) |
| 7 | Nomes duplicados/localizados ("Eddy (Inglês (EUA))") | Safari, macOS | identificar por `voiceURI`; comparar por "contém" |
| 8 | Utterance coletada pelo GC no meio da fala, `end` nunca chega (relato antigo e recorrente) | Chrome **(a verificar)** | guardar referência forte da utterance corrente num campo |
| 9 | `pause()` = `cancel()` | Android | não oferecer "pausar"; só "parar" e "ouvir de novo" |
| 10 | `&`, `<`, `>` no texto | Edge (SSML) | autor não usa esses caracteres (seção B8) |
| 11 | chave de silêncio | iOS | curso 100 % funcional sem som; mostrar "sem som? confira o volume" |

## A4. O que o `flutter_tts` faz no web (código lido) e os riscos no `VozIngles` atual

Lido em `lib/flutter_tts_web.dart` (versão atual do repositório dlutton/flutter_tts; pub.dev 4.2.x) [flutter_tts]:

- Usa **uma única** `SpeechSynthesisUtterance` reaproveitada em todas as falas.
- `getVoices()` = `synth.getVoices()` **na hora**, sem esperar `voiceschanged`; devolve só `{name, locale}`
  (não expõe `localService` nem `voiceURI`).
- `setLanguage(lang)` só define `utterance.voice`/`utterance.lang` **se** encontrar uma voz com esse prefixo
  na lista; com a lista vazia, **não faz nada** (não fixa o `lang`).
- `stop()` chama `cancel()` só se o estado interno não for `stopped`; `speak()` só fala se o estado for
  `stopped`/`paused`. O estado só muda nos handlers `onEnd`/`onError`, que chegam **depois** (evento
  assíncrono do navegador).
- No `onStart`, se a voz não é local, liga um `Timer` de 14 s com `pause()`+`resume()` (o paliativo do bug do
  Chrome).
- `onBoundary` ignora `sentence` e calcula a palavra a partir do `charIndex` procurando espaço/pontuação.

Consequências para o `VozIngles`:

1. **Primeira fala no Chrome**: `_preparar()` roda `setLanguage('en-US')` com a lista ainda vazia (não fixa
   `lang`) e `_escolherMelhorVoz()` também não acha nada. A retentativa (`_vozEscolhida`) só ajuda nas falas
   seguintes. A primeira frase pode sair na voz padrão do sistema — **em português** num SO em pt-BR (o
   `index.html` não declara `lang`). Risco alto justamente na estreia da 1ª lição.
2. **"Ouvir de novo" enquanto fala**: `falar()` faz `await stop()` e logo `await speak()`. Se o evento de fim do
   `cancel()` ainda não chegou, o estado continua `playing` e o `speak()` é **descartado em silêncio**. No
   Safari, onde o `end` não dispara no `cancel()` [codersblock], o estado pode ficar preso; se nem `error`
   chegar, a voz para de vez **(a verificar no Safari; reproduzir clicando "ouvir" duas vezes rápido)**.
3. A pontuação não exclui as vozes "de brincadeira"/Eloquence nem nomes com `undefined` (Edge 150). Risco
   baixo, mas a correção é barata.
4. Sem `voiceURI`, não dá para lembrar a voz escolhida com segurança no Safari.

**Recomendação**: trocar o `flutter_tts` por um invólucro fino com `package:web` só para o curso de inglês
(o projeto já depende de `web: ^1.1.0`). Esboço (não compilado — é guia para quem implementa):

```dart
import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class FalaWeb {
  web.SpeechSynthesisVoice? _voz;
  web.SpeechSynthesisUtterance? _corrente; // referência forte (evita GC no meio da fala)
  int _geracao = 0;

  web.SpeechSynthesis get _s => web.window.speechSynthesis;

  /// Espera a lista de vozes: evento voiceschanged OU sondagem a cada 250 ms, até 3 s.
  Future<List<web.SpeechSynthesisVoice>> vozes() async {
    var lista = _s.getVoices().toDart;
    if (lista.isNotEmpty) return lista;
    final pronto = Completer<void>();
    _s.onvoiceschanged = ((web.Event _) {
      if (!pronto.isCompleted) pronto.complete();
    }).toJS;
    for (var i = 0; i < 12 && lista.isEmpty; i++) {
      await Future.any([pronto.future, Future.delayed(const Duration(milliseconds: 250))]);
      lista = _s.getVoices().toDart;
    }
    return lista;
  }

  Future<void> falar(String texto, {double rate = .95}) async {
    final g = ++_geracao;
    _voz ??= escolherMelhor(await vozes());       // ranking da seção A5
    if (g != _geracao) return;                      // outra fala já assumiu
    _s.cancel();                                    // não depende de evento de fim
    final u = web.SpeechSynthesisUtterance(texto)
      ..lang = 'en-US'                              // SEMPRE, mesmo sem voz
      ..rate = rate;
    if (_voz != null) u.voice = _voz;
    u.onerror = ((web.SpeechSynthesisErrorEvent e) {
      if (e.error == 'network' || e.error == 'synthesis-failed') _voz = null; // tenta outra na próxima
    }).toJS;
    _corrente = u;
    _s.speak(u);
  }

  void parar() { _geracao++; _s.cancel(); }
}
```

(Se mesmo assim o Safari ignorar um `speak()` logo após `cancel()`, um atraso de ~50–100 ms entre os dois é
o paliativo comum **(a verificar)**.)

## A5. Algoritmo de escolha de voz recomendado

1. Esperar a lista (A4). Normalizar `lang` (`_`→`-`, minúsculas).
2. Descartar: `lang` que não começa com `en`; nomes das listas de exclusão (A2); nomes contendo `undefined`;
   vozes infantis (Ana, Maisie) como **padrão** (podem ficar escolhíveis no seletor).
3. Pontuar:
   - +100 nome casa com `Microsoft (Ava|Andrew|Emma|Brian)(Multilingual)? Online \(Natural\)` ou
     `Microsoft (Jenny|Aria|Guy|Michelle|Christopher|Eric|Roger|Steffan) Online \(Natural\)`;
   - +80 `Google US English` (Chrome desktop) ou `Google US English \d \(Natural\)` (Android/ChromeOS);
   - +70 Apple aprimoradas quando aparecem (Chrome/Edge no Mac): Ava, Zoe, Evan, Alex, Nathan, Allison, Tom;
   - +50 Samantha; +40 Microsoft Zira/David/Mark; +30 qualquer outra en-US;
   - +10 se `lang == en-US` (o curso é inglês americano); en-GB fica como reserva (Sonia, Libby, Ryan, Daniel);
   - +5 se `localService == true` (desempate: funciona sem rede).
4. Guardar a escolha por aparelho em `localStorage` (por `voiceURI`), com try/catch; revalidar a cada sessão.
5. Se a melhor nota for "normal" ou pior (Safari/iOS/Firefox), mostrar uma dica única e discreta: "Para uma
   voz mais natural, abra o curso no Edge ou no Chrome."
6. Oferecer nas configurações: seletor de voz com "testar" e "Voz do curso (padrão) / Voz do navegador" quando
   houver áudio pré-gerado.

## A6. Velocidade e destaque palavra a palavra

**Velocidade**

- Normal: `rate` 0.9–1.0 (o atual `.95` está bom). Lenta: **0.7–0.75** para frases; 0.6 só para palavra
  isolada ou trecho muito curto — em várias vozes neurais 0.6 soa arrastado **(julgamento de escuta; testar
  nas vozes Edge/Google)**. Nunca passar de 2 (Chrome com voz remota para de falar). [codersblock]
- No Safari, depois de usar `rate ≥ 0.5`, baixar para `< 0.5` não tem efeito [codersblock] — mais um motivo
  para não descer de 0.6.
- Com áudio pré-gerado, gerar a versão lenta **no próprio TTS** (Kokoro tem parâmetro `speed`; 0.8 soa
  natural). Esticar no navegador: `<audio>` com `playbackRate` 0.75 e `preservesPitch = true` (padrão `true`,
  suportado amplamente desde dez/2023) funciona, mas com artefatos. **Atenção: no Web Audio
  (`AudioBufferSourceNode.playbackRate`), mudar a velocidade muda o tom** (voz de "disco lento") — o player
  PCM que já existe no projeto não serve para "devagar" sem uma segunda gravação. [MDN preservesPitch]

**Destaque palavra a palavra**

- `boundary` traz `charIndex`, `charLength`, `name` (`word`/`sentence`) e `elapsedTime`. Não é Baseline. No
  browser-compat-data o Chrome aparece como **implementação parcial: "o evento boundary não dispara como
  esperado"** (crbug 40715888). [MDN boundary] [BCD]
- Não dispara: Chrome com vozes Google, Android. No macOS só vem `word`; no Chrome/Edge do Windows o
  `sentence` vem com `charLength` 0; Safari não preenche `charLength`. [codersblock] [jankapunkt]
- **Recomendação**: destaque **só com dado real**. Detecte em runtime: se o 1º `boundary` não chegar até
  ~600 ms depois do `start`, desligue o destaque naquela voz (guarde o resultado). Não simule tempos por
  contagem de letras — o descompasso confunde mais do que ajuda.
- Com áudio pré-gerado pelo Kokoro, os **timestamps por palavra** vêm do próprio modelo (`start_ts`/`end_ts`
  de cada token, calculados das durações previstas — `KPipeline.join_timestamps` em `kokoro/pipeline.py`).
  Exportar num JSON junto com o áudio dá destaque exato em qualquer navegador. [Kokoro pipeline]

## A7. Alternativa: áudio pré-gerado no build

### Candidatos e licenças

| Opção | Licença | Qualidade p/ inglês | Observações |
|---|---|---|---|
| **Kokoro-82M** (hexgrad) | **Apache-2.0** (pesos); treinado "exclusivamente em áudio permissivo/sem copyright" (domínio público, Apache/MIT e áudio sintético de modelos fechados) | **muito boa**; `af_heart` nota **A**, `af_bella` A-, `af_nicole` B-; masculinas en-US no máximo C+ (`am_michael`, `am_fenrir`, `am_puck`); en-GB `bf_emma` B- | 24 kHz; v1.0 de 27/01/2025; G2P `misaki` com eSpeak-ng como fallback; aceita pronúncia manual (`[Kokoro](/kˈOkəɹO/)`); devolve tempo por palavra. **Fraqueza declarada em falas curtas (< 10–20 tokens)** — justamente as frases do nível zero. [Kokoro HF] [Kokoro VOICES] |
| Kokoro no navegador (`kokoro-js`, Transformers.js) | Apache-2.0 | igual | modelo de **86–92 MB** (q8) a 325 MB (fp32), WASM/WebGPU — pesado demais para ser o padrão; no máximo um "modo voz neural offline" opcional. [kokoro.js] [Kokoro ONNX] |
| **Piper** (Rhasspy → Open Home Foundation) | motor: antigo MIT (repositório arquivado em out/2025), atual **GPL-3.0** (OHF-Voice/piper1-gpl); **cada voz tem a licença do seu dataset** | boa (VITS, 22 kHz), menos natural que o Kokoro | usar o motor no build não "contamina" o áudio gerado (a GPL cobre o programa, não a saída — entendimento usual, não é parecer jurídico). [Piper GPL] |
| `say` do macOS | **proibido para publicar**: a licença do macOS permite usar as vozes do sistema só "para criar conteúdo original para uso pessoal, não comercial" e veda "gravação, publicação ou redistribuição ... em contexto com ou sem fins lucrativos, de compartilhamento público ou comercial" (seção 2.F). [macOS SLA] | — | — |
| `edge-tts` (pacote não oficial que usa o "Ler em voz alta" do Edge) | sem licença de redistribuição; uso não oficial do serviço | excelente | pode quebrar ou ser bloqueado a qualquer momento; **não recomendado** |
| Gemini TTS em tempo de execução | — | muito boa | o próprio projeto anota "a cota grátis do TTS é ~10 áudios por DIA" (`voz_natural.dart`) — inviável para um curso; no build, só com plano pago **(custo não pesquisado)** |

**Vozes Piper en-US/en-GB — licença conferida no MODEL_CARD de cada uma** [Piper voices]:

| Voz | Dataset | Licença | Usar? |
|---|---|---|---|
| `en_US-ljspeech-high/medium` | LJ Speech | domínio público | **sim** |
| `en_US-kristin-medium`, `en_US-norman-medium`, `en_US-john-medium` | LibriVox (montados por Bryce Beattie) | domínio público | **sim** |
| `en_GB-cori-high/medium` | LibriVox | domínio público | **sim** |
| `en_US-libritts_r-medium` (904 falantes) | LibriTTS-R | CC BY 4.0 | sim, **com atribuição** |
| `en_GB-alba-medium` | Edinburgh DataShare | CC BY 4.0 | sim, com atribuição |
| `en_US-lessac-*` | Blizzard 2013 | **só pesquisa**; veda "desenvolvimento, comercialização ... de produtos de síntese de voz" e distribuição fora do acordo [Lessac] | **não** |
| `en_US-ryan-*` | RyanSpeech | CC BY-NC-SA 4.0 | **não** |
| `en_US-hfc_female/male` | Hi-Fi-CAPTAIN | CC BY-NC-SA 4.0 | **não** |
| `en_US-amy-*`, `en_GB-jenny_dioco` | "ver URL" | indefinida | evitar |

Modelos Piper têm ~63 MB (medium) a ~120 MB (high) — irrelevante, porque rodam só no build.

**Escolha**: Kokoro `af_heart` como voz única do curso (consistência ajuda a memorizar), `af_bella` como
segunda voz opcional para diálogos. Para frases muito curtas ("Hi.", "Thank you."), ouvir uma amostra antes
de publicar; se soarem mal, gerar com `speed` 0.9 ou dentro de uma frase-moldura e cortar pelos timestamps
**(técnica sugerida, não testada)**.

### Pipeline sugerido (roda no Mac, fora do app)

```python
# esboço — pip install "kokoro>=0.9.4" soundfile ; brew install espeak-ng ffmpeg
from kokoro import KPipeline
import hashlib, json, numpy as np, soundfile as sf, subprocess

pipe = KPipeline(lang_code='a')            # 'a' = inglês americano
def gerar(texto, voz='af_heart', speed=1.0):
    pedacos, palavras = [], []
    for r in pipe(texto, voice=voz, speed=speed):
        pedacos.append(r.audio.numpy())
        palavras += [(t.text, t.start_ts, t.end_ts) for t in (r.tokens or [])]
    chave = hashlib.sha1(f'{voz}|{speed}|{texto}'.encode()).hexdigest()[:12]
    sf.write(f'/tmp/{chave}.wav', np.concatenate(pedacos), 24000)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', f'/tmp/{chave}.wav',
                    '-ac', '1', '-ar', '24000', '-b:a', '32k', f'saida/{chave}.mp3'], check=True)
    return chave, palavras
```

Controle de qualidade opcional: transcrever cada arquivo com um ASR (ex.: Whisper) e marcar para revisão
humana os que divergirem do texto (pega heterônimos como *read/live/lead*, nomes e siglas).

## A8. Formato, tamanho e custo de hospedagem

**Medição real** (frase de 9 palavras, 2,56 s, "I don't think we should leave before seven o'clock.",
mono 24 kHz; arquivo de teste gerado só para medir tamanho, não distribuído):

| Formato | Tamanho | ≈ KB por segundo |
|---|---|---|
| Opus 24 kbps (Ogg) | 8,1 KB | 3,2 |
| Opus 24 kbps (WebM) | 9,1 KB | 3,6 |
| MP3 32 kbps CBR | 10,7 KB | 4,2 |
| AAC 32 kbps (M4A) | 11,7 KB | 4,6 |
| MP3 VBR -V7 (22 kHz) | 14,3 KB | 5,6 |
| MP3 48 kbps CBR | 15,9 KB | 6,2 |

- Xiph recomenda **24 kbps em Opus mono para audiolivro/podcast** (a partir daí sai banda cheia).
  [Xiph Opus]
- **Compatibilidade**: Opus no `<audio>` é "parcial" no Safari macOS e só "suportado" no iOS a partir do
  18.4 (caniuse). [caniuse Opus] → **MP3 mono 24 kHz, 32–40 kbps** é a escolha sem dor de cabeça (toca em
  tudo); Opus/WebM com MP3 de reserva (`canPlayType`) economiza ~25 %, o que nessa escala não importa.

**Projeção** (média de 3 s por frase; versão lenta com speed 0.8 ≈ 3,75 s):

| Frases | MP3 32 kbps (normal + lenta) | Opus 24 kbps (normal + lenta) |
|---|---|---|
| 3.000 | ≈ 85 MB | ≈ 68 MB |
| 6.000 | ≈ 170 MB | ≈ 135 MB |
| 10.000 | ≈ 280 MB | ≈ 225 MB |

**Firebase Hosting (plano Spark, gratuito)**: 10 GB de armazenamento e **10 GB/mês de transferência**
(≈ 333 MB/dia); arquivo até 2 GB; passar dos 10 GB/mês no Spark **desativa o site** (com período de
carência) até o mês virar; no Blaze, US$ 0,026/GB armazenado e US$ 0,15/GB transferido além da franquia.
O limite de armazenamento conta as versões (releases) guardadas — configurar a retenção. [Firebase Hosting]

Consumo estimado: um aluno ativo que estuda 40 frases novas + 80 revisões por dia baixa ~120 arquivos únicos
(o navegador guarda em cache os repetidos) ≈ **1,5–3,5 MB/dia**. A franquia aguenta ~100–200 alunos ativos
por dia; para o dono sozinho, ~50–100 MB/mês. Se um dia o curso crescer muito, o áudio pode ir para um
bucket separado (por exemplo um armazenamento de objetos sem cobrança de saída), mantendo o app no Hosting.

**Como servir**:

- Colocar em `web/audio/en/<voz>/<n|l>/<hash>.mp3` (o Flutter copia `web/` tal e qual para `build/web`),
  **não** em `assets:` do `pubspec.yaml` — milhares de entradas incham o `AssetManifest` que o app baixa.
- Nome = hash de `voz|velocidade|texto` → editou a frase, muda o nome; nada fica velho em cache.
- `firebase.json`:
  ```json
  "headers": [{ "source": "/audio/**",
                "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }] }]
  ```
- Manifesto (no próprio currículo ou num JSON à parte): `id da frase → {n: hash, l: hash, palavras: [[ini, fim], ...]}`.
- Tocar com `HTMLAudioElement` (via `package:web`) — dá `playbackRate` com `preservesPitch` e lida bem com
  MP3; ou buscar os bytes e usar `decodeAudioData` no `AudioContext` que já existe (sem mudar velocidade).
- Pré-carregar o áudio da **próxima** frase enquanto a atual é digitada (uma requisição pequena) — elimina a
  latência na estreia.

## A9. Estratégia recomendada

**Fase 1 (agora, sem pipeline):** Web Speech com o invólucro próprio (A4) + ranking (A5) + dica "use Edge/
Chrome" quando só houver voz fraca + destaque só se `boundary` existir de verdade.

**Fase 2 (quando o conteúdo estabilizar):** áudio pré-gerado com Kokoro `af_heart` (normal + lenta + tempos
por palavra), MP3 32–40 kbps em `web/audio/`, nome por hash, cache imutável.

**Ordem de reprodução em tempo de execução:**

1. arquivo pré-gerado da frase (se existir no manifesto);
2. Web Speech com a melhor voz do aparelho (cobre frases novas ainda sem áudio e falhas de rede do arquivo);
3. silêncio com aviso discreto ("sem voz neste navegador") — o curso continua funcionando.

Opção nas configurações: "Voz do curso" (padrão) ou "Voz do navegador" (quem gosta das vozes Natural do Edge).

## A10. Como usar o áudio na aula

| Momento | Comportamento | Por quê |
|---|---|---|
| **Estreia da frase** (1ª cópia) | toca 1× automaticamente, velocidade normal, antes de começar a digitar; destaque por palavra se houver dado | modelo sonoro antes da escrita; liga som ↔ grafia |
| **Durante a cópia** | atalho **Tab** = ouvir de novo; **Shift+Tab** = devagar (Tab nunca aparece no conteúdo e o motor já intercepta Tab para não perder o foco). **Não usar Ctrl+Espaço**: no Mac é o atalho padrão para trocar a fonte de entrada | repetir sem tirar as mãos do teclado |
| **Ao concluir a frase** | "eco" opcional: toca de novo a frase inteira (liga/desliga nas configurações) | reforço: "foi isso que você escreveu, e soa assim" |
| **Com pistas / De memória** | a tradução PT fica em cima; o áudio é uma **dica sob demanda** (Tab); tocar automaticamente só se o aluno ligar | não entregar a resposta de bandeja; o esforço de lembrar é o que fixa |
| **Ditado** (fase de revisão, nunca na 1ª exposição) | só o áudio (e opcionalmente a tradução); a pessoa digita o que ouve | treino de compreensão; homófonos (*there/their*, *to/too/two*, *right/write*) exigem a tradução visível ou frases já aprendidas |
| **Velocidades** | normal ~0.95 / lenta ~0.7 (Web Speech) ou speed 0.8 gerado | lento ajuda a separar palavras ligadas ("wanna", "gonna") |
| **Sem som** | tudo funciona sem áudio; nenhum passo depende de ouvir | iOS no silencioso, Firefox no Linux sem vozes, biblioteca |

---

# PARTE B — TECLADO

## B1. Os layouts que o curso vai encontrar

Fontes: arquivos KLC oficiais dos layouts do Windows (kbdlayout.info, extraídos de `kbdusx.dll` e
`kbdbr.dll` versão 10.0.25393) [KLC US-Intl] [KLC ABNT] e **simulação com `UCKeyTranslate` dos layouts
instalados no macOS 26 desta máquina** (`_fontes/layouts.swift`).

| Layout | `'` é tecla morta? | `"` é morta? | `'` + `c` | `'` + `a` | Outras mortas | Observações |
|---|---|---|---|---|---|---|
| **ABNT2 — Windows** ("Português (Brasil ABNT2)", KBDBR) | **não** (tecla à esquerda do 1) | **não** | `'c` | `'a` | `´` e `` ` `` (tecla ao lado do P), `~` e `^` (ao lado do Ç), `¨` (Shift+6) | `?` = Shift + tecla `/?` ao lado do Shift direito (em notebooks sem ela: AltGr+W; `/` = AltGr+Q) |
| **Brasileiro – ABNT2 — Mac** (o do dono) | **não** | **não** | `'c` | `'a` | `´` `` ` `` `~` `^` `¨` | Option+Shift+(tecla do `'`) = `’`; Option+`-` = `–`; Option+Shift+`-` = `—`; Option+`;` = `…`; **Option+Espaço = espaço inseparável (NBSP)** |
| **US-International — Windows** (KBDUSX) | **sim** | **sim** | **`ç`** | **`á`** | `` ` `` `~` `^` | `'`+espaço = `'` (o espaço some) |
| **U.S. International – PC — Mac** | **sim** | **sim** | **`ç`** | **`á`** | `` ` `` `~` `^` (Shift+6) | idêntico ao do Windows na prática |
| **"Brasileiro" — Mac** (ID `com.apple.keylayout.Brazilian-Pro`) | **sim** | **sim** | **`ç`** | **`á`** | `` ` `` `~` | comporta-se como o US-Intl-PC |
| **"Brasileiro – Legado", "U.S.", "ABC" — Mac** | não | não | `'c` | `'a` | acentos via Option (Option+E = `´` etc.) | seguros para inglês |

**Tabelas de combinação do US-International (Windows, do KLC oficial):**

- `'` (ACUTE/CEDILLA): a→á, e→é, i→í, o→ó, u→ú, y→ý, A→Á, E→É, I→Í, O→Ó, U→Ú, Y→Ý, **c→ç, C→Ç**, espaço→`'`
- `"` (UMLAUT): a→ä, e→ë, i→ï, o→ö, u→ü, y→ÿ, A→Ä, E→Ë, I→Ï, O→Ö, U→Ü, espaço→`"` (Y maiúsculo não combina)
- `^`: â ê î ô û (e maiúsculas), espaço→`^` · `` ` ``: à è ì ò ù (e maiúsculas), espaço→`` ` `` · `~`: ã õ ñ (e maiúsculas), espaço→`~`
- Letra que não combina: sai o sinal **e** a letra (`'`+`t` = `'t`). [Wikipedia QWERTY]

**ABNT2 no Mac (simulado):** `´`+t = `´t`, `´`+espaço = `´` (U+00B4), `~`+espaço = `˜` (U+02DC, **não** é o
`~` ASCII), Shift+`~`+espaço = `ˆ` (U+02C6), `¨`+espaço = `¨`. É exatamente o que o `TypingBloc` já trata
para o `~` e o `^` dos cursos de programação.

## B2. Frases inglesas que quebram (só nos layouts com `'`/`"` mortos)

| Escrita certa | O que sai digitando "normal" no US-Intl | Motivo |
|---|---|---|
| o'clock | oçlock | `'`+c = ç |
| 'cause, O'Connor | çause, OÇonnor | idem |
| y'all, ma'am, D'Angelo | yáll, máam, DÁngelo | `'`+vogal = agudo |
| get 'em | get ém | idem |
| "I am here," she said. | Ïam here,... | `"`+I = Ï |
| "Are you OK?" / "Oh!" / "Everyone" | Äre / Öh / Ëveryone | `"`+vogal = trema |
| "you" (entre aspas) | ÿou | `"`+y = ÿ |
| the students' books | the students'books (se der um espaço só) | `'`+espaço vira `'` e **come** o espaço |
| He said "no" and left. | ...said "noand left | `"`+espaço come o espaço |

**Sem problema** em qualquer layout: don't, can't, won't, it's, I'm, you're, we've, I'd, I'll, let's, Mary's,
rock 'n' roll (`n` não combina com `'`), '90s (dígito). Ou seja: **as contrações comuns funcionam**; o
problema se concentra em apóstrofo antes de vogal/c/y e em aspas duplas.

**No ABNT2** o problema é outro: usar `´` (ou `` ` ``) no lugar de `'` — "don´t", "it`s". É um hábito muito
comum no Brasil. Também `´`+vogal vira vogal acentuada ("y´all" → "yáll").

## B3. O que o navegador entrega e o que o Flutter web repassa

| Plataforma | Aperta a tecla morta | 2ª tecla combina (c, vogal) | 2ª tecla não combina (t) | morta + espaço |
|---|---|---|---|---|
| **Windows** (Chrome/Edge) | `keydown` com `key = "Dead"`; **nada é inserido** | insere o caractere composto (`ç`, `á`) | insere `'` e `t` | insere só `'` |
| **macOS** (Chrome, Safari, Firefox) | `compositionstart` + o sinal aparece **marcado** no campo | `compositionend` troca pelo composto | termina com `´t`/`'t` | termina com o sinal sozinho |

Fonte: discussão no W3C (Ryosuke Niwa, Apple, 2016): no Mac, "apertar `'` insere `'` e dispara
`compositionstart`; apertar `u` troca `'` por `ü` e dispara `compositionend`"; no Windows "a tecla morta não
insere nada, e a segunda tecla insere o caractere composto". [W3C dead keys] (Firefox no Windows pode
divergir **(a verificar)**.)

No Flutter web, o `TextField` vira um `<input>`/`<textarea>` escondido; o motor ouve `compositionstart/
update/end` (`CompositionAwareMixin`) e expõe a região em composição em `TextEditingValue.composing`. O motor
web define `autocorrect` (`on`/`off`), `autocapitalize` (conforme `textCapitalization`) e `autocomplete=off`,
mas **não define `spellcheck`**, e **não implementa `smartQuotesType`/`smartDashesType`** (procurei no código
do motor web e eles não aparecem; esses parâmetros só valem no iOS nativo). [Flutter text_editing]

**Conclusão**: o desenho do PAC·DART — processar só quando `composing.isCollapsed` e limpar o campo a cada
lote — é o certo para as duas plataformas. Pontos de atenção:

- O código do projeto já registra empiricamente que, depois de uma tecla morta, "o espaço chega aqui como uma
  tecla a mais". Vale **estender a regra de engolir esse espaço para `'` e `"`** (quem usa US-Intl tem o
  hábito de apertar `'`+espaço antes de qualquer letra, por segurança).
- Backspace durante a composição (Mac): o `onKeyEvent` intercepta o Backspace e apaga um caractere já
  digitado **e** a composição é cancelada. Raro; se incomodar, ignorar Backspace enquanto houver composição.
- Detectar quem usa US-Intl: no DOM, `keydown` com `key === "Dead"` e `code === "Quote"` indica `'` morto.
  Dá para mostrar **uma vez** a dica "No seu teclado o `'` é tecla morta: o motor entende `ç` como `'c`, e
  para `'` antes de espaço aperte espaço duas vezes". Como o Flutter apresenta essa tecla no `KeyEvent` é
  algo a conferir empiricamente; um ouvinte de `keydown` via `package:web` é o caminho garantido.

## B4. Substituições automáticas do sistema

| Fonte | O que faz | Efeito no curso | Defesa |
|---|---|---|---|
| macOS/Safari "Aspas inteligentes" (Editar > Substituições, ou Ajustes > Teclado > Fontes de Entrada) | no Safari, a aspa reta **só vira curva quando a próxima tecla é digitada**; a última aspa de um texto nunca curva [leancrew] | como o motor **limpa o campo a cada caractere**, não sobra aspa anterior para trocar — neutralizado na prática | manter a limpeza imediata; normalizar `’`→`'` por garantia |
| iOS/iPadOS "Pontuação inteligente" | insere `’` e `“ ”` já na digitação; a correção da Wikimedia foi `spellcheck="false"` [Wikimedia T385525] | o Flutter não põe `spellcheck=false` → no iPad/iPhone virão aspas curvas | normalizar no motor (seção B5) |
| Option+Espaço (Mac) | insere **NBSP** (U+00A0) | quem segura Option um instante a mais gera "espaço" que não é espaço | NBSP → espaço |
| Option+`;`, Option+`-` (Mac ABNT2) | `…`, `–`, `—` | só por acidente | normalizar |
| "Ponto com espaço duplo" (iOS; macOS) | dois espaços viram `. ` | com o campo limpo a cada tecla, o 2º espaço não tem contexto → não dispara (a verificar no iPad) | engolir espaço repetido |
| Autocapitalização (celular) | maiúscula automática | `textCapitalization.none` → `autocapitalize="off"` | já está assim |

## B5. Auditoria do motor (`TypingBloc`) e o que acrescentar

**Já coberto** (bom trabalho): aspas curvas → retas; `–`/`—` → `-`; `˜`/`ˆ` do Mac → `~`/`^`; desdobrar
composto do US-Intl (`ç` vale por `'c` quando é isso que o texto espera, idem `á`/`ä`/`à`/`â`/`ã`/`ñ`, com
maiúsculas); engolir o espaço que solta acento morto.

**Lacunas recomendadas:**

1. **Apóstrofo contextual**: quando o esperado é `'`, aceitar também `´` (U+00B4), `` ` `` (U+0060), `’`, `‘`,
   `‛` (U+201B), `ʼ` (U+02BC), `′` (U+2032), `＇` (U+FF07). Contar como **acerto**, mas mostrar **uma dica única**
   para `´`/`` ` ``: "No inglês o apóstrofo é a tecla `'` (no ABNT2, à esquerda do 1), não o acento `´`."
   Contextual (só quando o esperado é `'`) é mais seguro do que um mapeamento global.
2. **Aspas contextuais**: quando o esperado é `"`, aceitar `“ ” „ ‟ ″ ＂`.
3. **Espaços**: NBSP (U+00A0), U+2007, U+2009, U+202F, U+3000 → espaço.
4. **Reticências**: `…` vale por `...` (consome os três pontos, como o desdobramento do `ç`). Melhor ainda: não
   ter `...` no conteúdo (B8).
5. **Invisíveis**: U+200B, U+200C, U+200D, U+2060, U+FEFF, U+00AD (hífen suave) → ignorar sem erro.
6. **Forma decomposta**: se um grafema chegar como letra + acento combinante (U+0300–U+036F), tratá-lo como o
   composto equivalente antes de consultar a tabela (o Dart não tem NFC no core; uma tabelinha basta, ou o
   pacote `unorm_dart`).
7. **Espaço repetido** (o segundo espaço quando o esperado não é espaço) e **espaço logo após `'`/`"`** → engolir,
   sem erro, em todos os modos. Nunca exigir dois espaços.
8. **Normalizar também o texto-alvo** ao carregar a frase, com a mesma tabela. Assim um `’` que escape no JSON
   não cria uma letra impossível de digitar. (O validador do build — B8 — deve barrar isso antes; a
   normalização em tempo de execução é só rede de segurança.)
9. **Contar erro por posição** (opcional): três teclas erradas no mesmo caractere = 1 erro na precisão. Para
   memorização, o que interessa é "em quantos pontos da frase errei".

Esboço da tabela (Dart):

```dart
/// Variantes aceitas SÓ quando o esperado é o caractere-chave.
const variantesContextuais = {
  "'": {'´', '`', '’', '‘', '‛', 'ʼ', '′', '＇'},
  '"': {'“', '”', '„', '‟', '″', '＂'},
  '-': {'‐', '‑', '‒', '–', '—', '−'},
  ' ': {' ', ' ', ' ', ' ', '　'},
};
const invisiveis = {'​', '‌', '‍', '⁠', '﻿', '­'};
```

## B6. Regras de correção recomendadas por modo

| Regra | Copie | Com pistas | De memória | Ditado (futuro) |
|---|---|---|---|---|
| Letras | exigidas | exigidas | exigidas (errou → a letra aparece, como hoje) | exigidas |
| Maiúscula da 1ª letra da frase | exigida | exigida (a pista já mostra a inicial com a caixa certa) | **livre** (o motor corrige sozinho) | livre |
| Outras maiúsculas (I, nomes, dias, meses, idiomas, nacionalidades) | exigidas | exigidas | exigidas, com dica específica no erro ("em inglês, *Monday* e *English* levam maiúscula") | exigidas |
| Pontuação `, . ! ? ; :` | exigida | exigida e **mostrada na pista** | **preenchida sozinha** pelo Pac-Man; se a pessoa digitar, aceita sem duplicar | sozinha |
| Aspas `"` | exigidas | mostradas | sozinhas | sozinhas |
| Apóstrofo dentro da palavra (don't, Mary's) | exigido (variantes aceitas) | exigido e **mostrado na pista** (`d__'_`) | exigido | exigido |
| Hífen dentro da palavra (twenty-one) | exigido | mostrado | exigido | exigido |
| Contração × forma longa (don't × do not) | o que está escrito | idem | o que está escrito (a tradução não diz qual); o erro revela | idem |
| Espaço duplo / espaço após `'` `"` ou acento morto | engolido | engolido | engolido | engolido |
| Variantes tipográficas e compostos de tecla morta | aceitos | aceitos | aceitos | aceitos |

Justificativa:

- No "Copie" tudo está à vista; exigir é coerente com o resto do PAC·DART e fixa a grafia completa.
- No "De memória" o objetivo é lembrar **palavras e ordem**, não adivinhar onde vai a vírgula. Maiúscula do
  início da frase não ensina nada; já as maiúsculas de *I*, dias, meses, idiomas e nacionalidades **são
  conteúdo** — é onde o brasileiro erra (em português esses nomes são minúsculos).
- Apóstrofo é ortografia ("dont" é erro de escrita), então nunca vira opcional.
- Ferramentas de repetição espaçada fazem algo parecido para respostas digitadas: o Anki compara a resposta e
  mostra o que acertou/errou, e tem a opção `type:nc:` para ignorar diacríticos ("elite" = "élite").
  [Anki] (Política de tolerância do Duolingo não foi conferida — a cota de buscas acabou **(a verificar)**.)

## B7. Dicas de teclado para mostrar ao aluno (onboarding)

1. "O apóstrofo `'` fica à esquerda do 1 no teclado ABNT2. O acento `´` (ao lado do P) não é apóstrofo."
2. "O `?` fica na tecla `/?` ao lado do Shift direito (ou AltGr+W em notebooks sem essa tecla)."
3. Se detectar US-Intl (B3): "No seu teclado, `'` e `"` são teclas mortas. Pode digitar normal: entendemos
   `ç` como `'c`. Para `'` ou `"` antes de um espaço, aperte espaço duas vezes."
4. Mac: "Se aparecer um espaço estranho, solte o Option antes de apertar Espaço."

## B8. Regras para quem escreve o conteúdo (checklist + validador)

**Obrigatório**

1. **Só ASCII imprimível** no campo em inglês: U+0020 a U+007E. Nada de `’ ‘ “ ” – — … « »` nem espaço
   inseparável.
2. **Apóstrofo reto `'`** em contrações e possessivos — e use contrações em frases de conversa (é o inglês
   real; as comuns funcionam em todos os layouts).
3. **Uma frase (ou duas curtas) por item**, sem quebra de linha e sem tabulação; **um** espaço entre palavras;
   sem espaço no começo/fim; **pontuação final sempre** (`.`, `?` ou `!`).
4. **Ortografia e pontuação dos EUA**, coerentes em todo o curso: *color, center, Mr., Mrs., Dr.* (com ponto).
   O áudio é en-US.
5. **Maiúsculas corretas do inglês**: *I*, nomes próprios, dias, meses, idiomas, nacionalidades (são
   conteúdo do curso).

**Evitar**

6. **Aspas duplas**: prefira discurso indireto (*She said that she was tired.*) ou diálogo em itens
   separados, com o nome do personagem fora do texto digitado.
7. **Travessão e reticências**: troque por vírgula, ponto ou parênteses; hesitação vira vírgula.
8. **`& < > # @ * _ | \ { } [ ] ~ ^ ``** — não são naturais em frases; `&`/`<`/`>` quebram as vozes do Edge
   (SSML); `~ ^ `` são teclas mortas no ABNT2.
9. **Palavras com acento** (café, naïve, résumé, fiancé, jalapeño, déjà vu): use a forma sem acento aceita no
   inglês (*cafe, naive*) ou evite a palavra.
10. **Símbolos fora do ASCII** (`£ € °`): escreva *pounds, euros, degrees*; `$` pode (Shift+4).
11. **Números**: por extenso de 1 a 10 (aprender números é conteúdo); dígitos para horas (*7:30*), anos e
    preços.
12. **Nomes de pessoas** simples que o TTS pronuncia bem (Tom, Anna, Mike, Sarah).
13. **Heterônimos** (*read, live, lead, wind, tear*): marcar no item; o pipeline do Kokoro aceita pronúncia
    manual, a Web Speech não.

**Campos sugeridos por frase**: `en` (o que se digita, ASCII), `pt` (tradução, pode ter acentos),
`fala` (opcional: texto alternativo só para o TTS, ex.: siglas), `pronuncia` (opcional: fonemas para o
Kokoro), `audio` (hashes normal/lenta + tempos por palavra, preenchido pelo pipeline).

**Validador do build** (regra a regra, falhando com o id da frase):

```dart
final soAscii = RegExp(r'^[\x20-\x7E]+$');
final proibidos = RegExp(r'[&<>#@*_|\\{}\[\]~^`]');
bool valida(String en) =>
    soAscii.hasMatch(en) &&
    !proibidos.hasMatch(en) &&
    !en.contains('  ') &&
    en == en.trim() &&
    !en.contains('...') &&
    RegExp(r'[.?!]"?$').hasMatch(en);   // termina com pontuação
```

Avisos (não bloqueiam): presença de `"`; apóstrofo seguido de vogal/c/y (avisa que no US-Intl isso compõe —
o motor trata, mas vale saber); frase longa demais para o nível.

---

## Apêndice 1 — Saída da simulação dos layouts do macOS (resumo)

`UCKeyTranslate` com o tipo de teclado desta máquina; "MORTA" = a tecla não produz caractere e deixa estado
de tecla morta. Script e saída completa: `_fontes/layouts.swift`.

```
Brazilian – ABNT2
  tecla 50        -> ' direta          | Shift -> " direta | Shift+Opt -> ’
  tecla 33        -> MORTA ´ : +a=á +c=´c +t=´t      | Shift -> MORTA ` : +a=à
  tecla 39        -> MORTA ˜ (U+02DC): +a=ã +n=ñ     | Shift -> MORTA ˆ (U+02C6): +a=â
  Shift+6         -> MORTA ¨ : +a=ä +y=ÿ
  Opt+-  -> –   Shift+Opt+- -> —   Opt+; -> …

U.S. International – PC  (idêntico em "Brazilian" = com.apple.keylayout.Brazilian-Pro)
  tecla 39        -> MORTA ' : +a=á +e=é +i=í +o=ó +u=ú +c=ç +t='t +s='s +n='n +y='y +A=Á
  Shift+tecla 39  -> MORTA " : +a=ä +e=ë +i=ï +o=ö +u=ü +c="c +t="t +y=ÿ +A=Ä +I=Ï
  tecla 50        -> MORTA ` | Shift -> MORTA ~ : +a=ã +o=õ +n=ñ   | Shift+6 -> MORTA ^

Brazilian – Legacy / U.S. / ABC
  tecla 39        -> ' direta | Shift -> " direta  (acentos só via Option)
```

## Apêndice 2 — Fontes

Áudio / Web Speech
- MDN — SpeechSynthesisUtterance.rate: https://developer.mozilla.org/en-US/docs/Web/API/SpeechSynthesisUtterance/rate
- MDN — SpeechSynthesisErrorEvent.error: https://developer.mozilla.org/en-US/docs/Web/API/SpeechSynthesisErrorEvent/error
- MDN — boundary event: https://developer.mozilla.org/en-US/docs/Web/API/SpeechSynthesisUtterance/boundary_event
- MDN — SpeechSynthesisVoice.localService: https://developer.mozilla.org/en-US/docs/Web/API/SpeechSynthesisVoice/localService
- MDN — HTMLMediaElement.preservesPitch: https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/preservesPitch
- MDN browser-compat-data (BCD): https://github.com/mdn/browser-compat-data/blob/main/api/SpeechSynthesisUtterance.json e https://github.com/mdn/browser-compat-data/blob/main/api/SpeechSynthesis.json
- Readium — SpeechSynthesis in browsers and OSes: https://readium.org/speech/docs/WebSpeech.html
- Readium — Voices and filtering: https://raw.githubusercontent.com/readium/speech/HEAD/docs/VoicesAndFiltering.md
- Readium — lista de vozes en (CC0): https://raw.githubusercontent.com/readium/speech/main/json/en.json ; filtros: https://raw.githubusercontent.com/readium/speech/main/json/filters/novelty.json e https://raw.githubusercontent.com/readium/speech/main/json/filters/veryLowQuality.json
- Coders Block — JavaScript text-to-speech and its many quirks: https://codersblock.com/blog/javascript-text-to-speech-and-its-many-quirks/
- jankapunkt — Cross-browser speech synthesis: https://dev.to/jankapunkt/cross-browser-speech-synthesis-the-hard-way-and-the-easy-way-353
- Caktus — The Halting Problem (Chrome/Google voices): https://www.caktusgroup.com/blog/2025/11/03/the-halting-problem/
- Apple Developer Forums 723503 (vozes ausentes no Safari): https://developer.apple.com/forums/thread/723503
- Microsoft Tech Community — Edge 150 getVoices "undefined": https://techcommunity.microsoft.com/discussions/edgeinsiderdiscussions/edge-version-150-javascript-speechsynthesis-getvoices-undefined-voices/4538591
- Chrome 71 deprecations (speak sem ativação): https://developer.chrome.com/blog/chrome-71-deps-rems/
- Chrome autoplay policy: https://developer.chrome.com/blog/autoplay
- flutter_tts (pub.dev): https://pub.dev/packages/flutter_tts ; código web: https://github.com/dlutton/flutter_tts/blob/master/lib/flutter_tts_web.dart

Áudio pré-gerado / licenças / hospedagem
- Kokoro-82M (modelo, licença, dados): https://huggingface.co/hexgrad/Kokoro-82M
- Kokoro VOICES.md (notas das vozes, fraqueza em falas curtas): https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md
- Kokoro (biblioteca, timestamps): https://github.com/hexgrad/kokoro e https://github.com/hexgrad/kokoro/blob/main/kokoro/pipeline.py
- kokoro.js (navegador): https://github.com/hexgrad/kokoro/tree/main/kokoro.js ; tamanhos ONNX: https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX
- Piper voices (índice e MODEL_CARDs): https://huggingface.co/rhasspy/piper-voices
- Licença Lessac/Blizzard 2013: https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/license.html
- Piper migrou para GPL (fonte secundária): https://www.promptquorum.com/power-local-llm/piper-tts-review
- Licença do macOS Sequoia, seção 2.F (vozes do sistema): https://www.apple.com/legal/sla/docs/macOSSequoia.pdf
- Firebase Hosting — cotas e preços: https://firebase.google.com/docs/hosting/usage-quotas-pricing
- Xiph — Opus Recommended Settings: https://wiki.xiph.org/Opus_Recommended_Settings
- caniuse — Opus: https://caniuse.com/opus

Teclado / entrada de texto
- KLC do US-International (kbdusx.dll): https://kbdlayout.info/kbdusx (download KLC)
- KLC do ABNT (kbdbr.dll): https://kbdlayout.info/kbdbr (download KLC)
- Wikipedia — QWERTY, US-International: https://en.wikipedia.org/wiki/QWERTY#US-International
- W3C public-webapps — teclas mortas Mac × Windows (R. Niwa, 2016): https://lists.w3.org/Archives/Public/public-webapps/2016JanMar/0033.html
- Flutter web engine — text_editing.dart: https://github.com/flutter/flutter/blob/master/engine/src/flutter/lib/web_ui/lib/src/engine/text_editing/text_editing.dart ; composition_aware_mixin.dart e text_capitalization.dart na mesma pasta
- Dr. Drang — A Mac smart quote curiosity: https://leancrew.com/all-this/2025/03/a-mac-smart-quote-curiosity/
- Wikimedia Phabricator T385525 (iOS smart quotes, spellcheck=false): https://phabricator.wikimedia.org/T385525
- Anki Manual — Checking your answer: https://docs.ankiweb.net/templates/fields.html
- Canaltech — acentos no MacBook (US Internacional PC): https://canaltech.com.br/macos/como-usar-acentos-macbook/

Evidência local (esta máquina, só leitura)
- `defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleEnabledInputSources` → `Brazilian-ABNT2`
- `say -v '?'` → vozes inglesas instaladas (sem premium)
- `_fontes/layouts.swift` (simulação `UCKeyTranslate`), `_fontes/kbdusx.txt` e `_fontes/kbdbr.txt` (KLC convertidos),
  `_fontes/readium-en.json`, `_fontes/flutter_tts_web.dart`, `_fontes/fl_text_editing.dart`, `_fontes/kokoro_pipeline.py`
