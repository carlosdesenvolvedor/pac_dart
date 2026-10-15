# Fase 1B — Lembrete diário no celular

> Plano para execução por um agente. Escrito em 13/out/2026. Especificação de origem: seção 9 de [`FASE-1-HABITO-DIARIO.md`](FASE-1-HABITO-DIARIO.md).
> **Autorizada pelo dono em 13/out/2026** ("Pode seguir com 1B"): mexe em `pubspec.yaml`/`pubspec.lock`, `android/` e `ios/` (que têm trabalho de lojas do dono sem commit — edição pontual, com backup).
> **Só Android e iOS.** Web e desktop não recebem lembrete (push web exigiria FCM + chave VAPID + service worker + envio agendado no servidor: fase própria).

## 1. O que a pessoa vai ver

Na folha **"Sua sequência"** (toque no chip do cabeçalho), no fim, a seção **"🔔 Lembrete diário"**:
- **Lembrar de estudar** (liga/desliga). Ao LIGAR, o aparelho pede a permissão de notificação (iOS; Android 13+). Negada ⇒ continua desligado e a tela explica como liberar nas configurações.
- Ligado: botão **"Horário: 20:00"** abre o seletor de hora (24 h). Padrão **20:00**, **desligado** de fábrica.
- A frase explica a regra: "Todo dia às 20:00 — só se a meta do dia ainda não foi batida."
- No navegador/desktop a seção mostra uma linha: "O lembrete diário funciona no app do celular (Android e iOS)."

A notificação é acolhedora e **sem culpa** (nada de "você vai perder a sequência", nenhum número de dias): 4 textos que giram por dia, por exemplo
"Hora de uma pausa com o inglês 🐦 — Bastam alguns minutos. O Prof. Dash está esperando você!".

## 2. Decisões (o agente segue; o dono pode mudar)

| # | Decisão | Por quê |
|---|---|---|
| D1 | `flutter_local_notifications` (22.3.2) + `timezone` (0.11.2), **só esses dois pacotes novos**. | A especificação. |
| D2 | **Notificações únicas para os próximos 7 dias** (não "diária repetida"): ids fixos `7100…7106`; a cada reagendamento cancela os 7 e agenda de novo. | A regra "só dispara se a meta de hoje ainda não foi batida" não existe numa notificação repetida; assim hoje sai da lista quando a meta é batida, e os próximos 6 dias seguem valendo mesmo se a pessoa não abrir o app. |
| D3 | **Reagenda** quando: o app abre e o lembrete é lido · liga/desliga · muda o horário · **a meta do dia é batida** (hoje sai) · (cada abertura renova os 7 dias). **Não** reagenda a cada exercício (só quando "bateu hoje" muda). | Poucas chamadas à plataforma. |
| D4 | O horário passado de hoje não é agendado (ligar às 21:00 com horário 20:00 ⇒ começa amanhã). Meta já batida hoje ⇒ hoje fora. | Nunca notifica "retroativo". |
| D5 | **Instantes absolutos**: cada lembrete é `DateTime(ano, mês, dia + i, hora, minuto)` **local** (o Dart cuida de horário de verão) convertido com `TZDateTime.from(…, tz.UTC)`. Não precisa do **nome** do fuso do aparelho (nem de um 3º pacote `flutter_timezone`): só o instante importa. | Menos dependências, mesmo resultado. |
| D6 | **Android: alarme não exato** (`AndroidScheduleMode.inexactAllowWhileIdle`) — **sem** `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` (a Play restringe alarmes exatos e um lembrete de estudo não precisa de minuto exato). Manifest: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` e os 2 receivers do plugin (reagenda após reiniciar). Gradle: `desugar_jdk_libs` (o plugin exige). | Boa prática e menos fricção na loja. |
| D7 | **iOS:** o `AppDelegate` aponta o `UNUserNotificationCenter` para o `FlutterAppDelegate`; permissões **só ao ligar** (nada de pedir no início do app). | Pedido no momento certo. |
| D8 | **A configuração é do aparelho e da conta**: `SharedPreferences` em `lembrete_v1:{uid}` (`{v:1, ligado, hora, minuto}`, JSON tolerante). **Nada vai ao Firestore** ⇒ `firestore.rules` intacto; uma conta que sai deixa de ter lembretes (o último cubit aberto cancela ao fechar; o da conta nova assume). | Lembrete é do aparelho (como o áudio). |
| D9 | Interface `AgendadorDeLembrete` (`disponivel`, `pedirPermissao`, `substituir`, `cancelarTodos`) com **`AgendadorNulo`** (web/desktop/testes) e **`AgendadorDoCelular`** (plugin). A política "só se a meta não foi batida" é **função pura** (`proximosLembretes`) testada sem plataforma. | Testável e sem plugin nos testes. |
| D10 | O lembrete **não toca** em hábito/ranking/agenda: só LÊ o `HabitoCubit` (se bateu hoje). | Escopo. |

### Perguntas em aberto (padrões)
1. Horário padrão: **20:00** (da especificação). 2. Quantos dias à frente: **7**. 3. Textos: os 4 do código (sem número de dias, sem culpa). 4. Som/vibração: os padrões do sistema. 5. Atualizar o `Podfile`/versão mínima do iOS: só se o build exigir.

## 3. Arquivos
**Novos:** `lib/features/habito/domain/lembrete.dart` (`ConfigLembrete`, `LembreteAgendado`, `proximosLembretes`, textos) · `data/lembrete_repository.dart` · `data/agendador_lembrete.dart` (interface + `AgendadorNulo`) · `data/agendador_celular.dart` (plugin) ·
`presentation/lembrete_cubit.dart` · seção nova em `widgets/sequencia_sheet.dart` · testes `lembrete_test`, `lembrete_repository_test`, `lembrete_cubit_test`, `lembrete_ui_test`, `lembrete_app_test`.
**Editados com cirurgia:** `pubspec.yaml`/`pubspec.lock` (os dois pacotes) · `android/app/src/main/AndroidManifest.xml` · `android/app/build.gradle.kts` · `ios/Runner/AppDelegate.swift` (+ `ios/Podfile.lock`/`Pods` pelo `pod install`) · `lib/main.dart` (providers) · `lib/main_portfolio_probe.dart` (agendador falso "disponível" para a prova no Chrome).
**Não toca:** `firestore.rules`, `IaCubit`, reconhecedor, `HabitoCubit` (só lê).

## 4. Critérios de aceite
- [ ] `flutter pub get` ok; **`flutter build apk --debug` compila** (Gradle, desugaring, manifest) e **`flutter build ios --simulator --no-codesign` compila** (pod install); o probe web **ainda abre** (sem tela branca).
- [ ] Política pura: horário passado fora · meta batida tira hoje · 7 dias · desligado ⇒ nenhum · virada de mês/ano · ids estáveis · textos sem número e sem culpa.
- [ ] Ligar pede permissão; negada ⇒ continua desligado + aviso; concedida ⇒ agenda; mudar horário reagenda; desligar cancela; **bater a meta reagenda sem hoje**; exercício que não bate a meta **não** reagenda.
- [ ] Web/desktop/testes: seção com a linha "funciona no app do celular", nada agendado, nada quebra; sem o cubit na árvore a folha segue igual à de antes (testes antigos).
- [ ] Sem Firestore novo; `firestore.rules` intacto. `dart analyze lib test` limpo; `flutter test`: só as 5 falhas antigas do C#.
- [ ] **Mutações** pegas (restaurar e conferir por hash) e **prova no Chrome** (probe, agendador falso "disponível": liga → permissão → lista dos 7 horários no console; muda horário; bate a meta → hoje some) a 1027 e 390 px, sem erro de console.
- [ ] Prova **no simulador do iOS**, se possível: o app roda, o lembrete é agendado e aparece em `pendingNotificationRequests`. Prova real num Android/iPhone físico = do dono.
- [ ] `ESTADO-DO-PROJETO.md` atualizado. **Nada commitado, nada publicado.**

## 5. Fora do escopo
Push web/FCM · notificação com ação/ícone próprio · lembrete por dia da semana · lembrete "inteligente" por horário de estudo · alarme exato · widget na tela inicial · mexer em `firestore.rules`.
