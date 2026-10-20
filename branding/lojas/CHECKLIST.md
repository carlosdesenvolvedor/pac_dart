# Checklist de publicação — Paclingo

✅ = pronto no projeto · 👤 = só você pode fazer · ⚠️ = decisão sua

## 1. Antes de qualquer envio
- ✅ **ID definitivo `com.carlos.paclingo`** (projeto, Firebase e `firebase_options.dart`). Para trocar de novo antes do 1º upload: `python3 tool/trocar_id.py <novo.id>`.
- ⚠️ **Marcas de terceiros** (risco de recusa/derrubada): o Pac (círculo amarelo de boca em cunha) lembra o Pac-Man (Bandai Namco);
  "Prof. Dash"/"Dash" é o mascote do Dart/Flutter (Google). Alternativa segura: dar nomes e visual próprios (a logo do mascote azul-bolha, em
  `branding/outras-versoes/`, é uma opção). Evite "Pac-Man", "Flutter" e "Dash" em nome/subtítulo/palavras-chave das lojas.
- 👤 **Me passe o nome (ou empresa) e o e-mail de contato** que vão aparecer nas páginas de privacidade e nas fichas — preencho `[SEU NOME OU EMPRESA]` /
  `[SEU E-MAIL DE CONTATO]` em `web/privacidade.html`, `web/excluir-conta.html` e nas fichas e publico as páginas (o e-mail ficará público; não publico sem você pedir).
- ✅ Site e regras do Firestore publicados em 11/out/2026 (Paclingo no ar; "Excluir minha conta" funcionando). **Faltam no ar só** `privacidade.html` e
  `excluir-conta.html` (aguardam o contato acima): depois, `flutter build web --release && firebase deploy --only hosting`.

## 2. Contas
- 👤 Google Play Console (US$ 25, uma vez).
- 👤 Apple Developer Program (US$ 99/ano).

## 3. Android
- ✅ Projeto `android/`, ícones, permissões (internet, microfone), assinatura de release (`android/key.properties`, fora do git).
- ✅ Arquivo: `build/app/outputs/bundle/release/app-release.aab` (153,7 MB; as vozes/fotos do inglês pesam 117 MB — dá para enxugar depois).
- 👤 **Backup** de `~/.paclingo/upload-keystore.jks` e da senha em `android/key.properties`.
- 👤 Criar o app no Play Console, subir o `.aab`, preencher a ficha (`google-play.md`), Data safety, classificação e público-alvo.
- 👤 Conta pessoal nova: teste fechado (12+ testadores, 14 dias) antes da produção.
- 👤 Depois do 1º upload: cadastrar os SHA do "App Signing" no Firebase e (recomendado) ligar o App Check com Play Integrity.
- ⚠️ **Prender a chave de API do Android ao app** (o GitHub alertou em 14/out/2026: ela está no repositório público, commit 2153671,
  `lib/firebase_options.dart` L62). No Google Cloud (projeto `pac-dart` > Credenciais > "Android key (auto created by Firebase)",
  uid `ad11c6ee-…`): restrição "Apps Android" = `com.carlos.paclingo` com o SHA-1 de release `8F:0B:C3:DD:A6:21:05:56:EA:1E:D4:0F:A4:27:85:60:DA:26:12:88`,
  o de debug `7B:F3:B5:07:EE:E9:D2:50:F2:C3:F8:13:AB:5A:92:1D:90:7A:39:DD` **e o SHA-1 do "App Signing" da Play Console** (sem ele,
  login e Firestore param no app baixado da loja). Manter a lista de APIs como está. Depois fechar o alerta no GitHub como "won't fix"
  (chave do Firebase restrita ao app).

## 4. iOS
- ✅ Projeto `ios/`, ícones, permissões (microfone e reconhecimento de fala), Firebase configurado, compila no simulador e em dispositivo.
- 👤 Xcode: abrir `ios/Runner.xcworkspace` > Signing & Capabilities > escolher o **Team**; registrar o Bundle ID no portal da Apple.
- 👤 `flutter build ipa --release` e enviar pelo Transporter; preencher a ficha (`app-store.md`), App Privacy e a **conta de teste** para a revisão.
- 👤 (recomendado) App Check com App Attest/DeviceCheck.
- ⚠️ **Prender a chave de API do iOS ao app** (mesmo alerta do GitHub, `lib/firebase_options.dart` L70): Google Cloud > Credenciais >
  "iOS key (auto created by Firebase)", uid `ec9bcfb7-…`: restrição "Apps iOS" = `com.carlos.paclingo`. Depois fechar o alerta no GitHub.

## 5. O que o app faz no celular (feito e verificado)
- ✅ Login, progresso e ranking (Firebase) — o app abre no simulador do iPhone com o Firebase de verdade.
- ✅ Efeitos sonoros (sintetizados em Dart, `lib/core/som/`), voz do inglês (gravações + voz do sistema), microfone do inglês (`speech_to_text`), links.
- ✅ Tutor com IA pelo Firebase AI Logic (sem chave dentro do app).
- ✅ Excluir a conta pelo app (exigência da Apple e do Google).
- ⚠️ Ainda **não testado em aparelho real**: som, voz, microfone e teclado do celular (só emulados/simulador). Teste antes de enviar.

## 6. Pontos de atenção que ficam com você
- **Cota do tutor:** o Firebase AI Logic usa a cota **gratuita** do projeto (sem cobrança ligada). Se o app crescer, ligue o App Check
  (impede que terceiros usem a sua cota) e avalie o plano pago.
- **Apelido no ranking** = parte do e-mail antes do `@`, visível a todos os usuários logados (está dito na política de privacidade). Se preferir,
  troque por um apelido escolhido pelo usuário.
- **Gravar tela/áudio:** o app não guarda áudio. **Crianças:** público 13+.
