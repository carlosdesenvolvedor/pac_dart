# App Store — ficha do app (pt-BR)

## Dados básicos
| Campo | Valor |
|---|---|
| Nome (máx. 30) | **Paclingo** |
| Subtítulo (máx. 30) | **Aprenda digitando** (17) |
| Texto promocional (máx. 170) | **Frases reais em inglês, código de verdade em Dart e C#, jogos de arcade e um tutor com IA. Digite, erre, repita — e fixe de vez.** (128) |
| Palavras-chave (máx. 100) | `inglês,digitação,programação,idiomas,curso,código,estudar,frases,vocabulário,tutor,quiz,jogo,teclado` (100) |
| Categoria principal / secundária | Educação / Jogos de palavras (ou Produtividade) |
| URL de suporte | https://pac-dart.web.app/privacidade.html (ou uma página própria) |
| URL de privacidade | https://pac-dart.web.app/privacidade.html |
| Direitos autorais | `© 2026 [SEU NOME OU EMPRESA]` |
| Capturas (iPhone 6,9") | `branding/lojas/ios/*.png` (6 imagens, 1320×2868) |
| Ícone 1024 | `branding/app-store-1024.png` (já está no projeto iOS) |

> Não use "Flutter", "Pac-Man" nem "Dash" em nome, subtítulo ou palavras-chave: são marcas de terceiros (Guideline 2.3.7). Citar "Dart" e "Flutter" na descrição, como assunto do curso, é aceitável.

## Descrição
Use o mesmo texto da descrição completa do Google Play (`google-play.md`), sem os emojis de seção se preferir.

## Privacidade do app (App Privacy / "nutrition label")
Dados **coletados**, todos **vinculados ao usuário**, **sem rastreamento** (Tracking: Não):

| Tipo | Uso |
|---|---|
| Informações de contato → **Endereço de e-mail** | Funcionalidade do app |
| Identificadores → **ID do usuário** | Funcionalidade do app |
| Dados de uso → **Interação com o produto** (progresso, pontos) | Funcionalidade do app |
| Conteúdo do usuário → **Outro conteúdo do usuário** (perguntas ao tutor) | Funcionalidade do app *(não vinculado: o e-mail não é enviado ao tutor)* |

Não coletado: localização, contatos, fotos, saúde, finanças, histórico de navegação, áudio (o reconhecimento de voz é do sistema; o app não guarda áudio).

## Classificação etária
**4+** (sem conteúdo sensível; sem acesso irrestrito à web; sem jogos de azar).

## Conformidade de exportação
Só usa criptografia padrão (HTTPS): **isento**. É uma declaração sua: se concordar, adicione ao `ios/Runner/Info.plist`
`<key>ITSAppUsesNonExemptEncryption</key><false/>` para o Xcode não perguntar a cada envio.

## Notas para a revisão da Apple
A Apple **exige uma conta de teste** para apps com login. Crie uma conta nova no app (ex.: `revisao@…`), use uma senha simples e coloque em "Informações de login" + "Notas":

```
O app tem login por e-mail e senha (Firebase Authentication). Use a conta de teste informada.
O curso de inglês tem um botão de microfone opcional (Reconhecimento de Fala do iOS).
A exclusão de conta fica em: ícone do perfil (círculo com a inicial, no topo) > Excluir minha conta.
```

## Como gerar o arquivo para enviar
No Mac, com sua conta de desenvolvedor: abra `ios/Runner.xcworkspace` no Xcode > Runner > Signing & Capabilities > escolha o seu **Team**; depois `flutter build ipa --release` e envie pelo app **Transporter** (ou Xcode > Organizer).
