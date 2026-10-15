# Google Play — ficha do app (pt-BR)

Tudo para copiar e colar no Play Console. Limites conferidos.

## Dados básicos
| Campo | Valor |
|---|---|
| Nome (máx. 30) | **Paclingo: aprenda digitando** (27) |
| Descrição curta (máx. 80) | **Aprenda inglês, Dart e C# digitando. Treino curto, jogos e tutor com IA.** (72) |
| Categoria | Educação |
| Tipo | App · Gratuito |
| E-mail de contato | `[SEU E-MAIL DE CONTATO]` |
| Política de privacidade | https://pac-dart.web.app/privacidade.html |
| Exclusão de conta (URL) | https://pac-dart.web.app/excluir-conta.html |
| Ícone 512×512 | `branding/play-store-512.png` |
| Capturas de tela (telefone, 9:16) | `branding/lojas/android/*.png` (6 imagens, 1080×1920) |
| Gráfico de recursos 1024×500 | `branding/lojas/grafico-play-1024x500.png` |

## Descrição completa
```
Paclingo transforma digitação em estudo. Em vez de só ler, você digita — e o que passa pelos dedos fica na cabeça.

🗽 INGLÊS, DO ZERO AO AVANÇADO
• Frases reais, com a tradução em cima: você digita a frase em inglês, 5 vezes, cada vez com menos ajuda.
• Revisão espaçada: o app traz de volta o que você está prestes a esquecer.
• Gravações de falantes nativos e voz devagar para ouvir quantas vezes quiser.
• Opcional: fale a frase no microfone e veja o que o app entendeu.

💻 DART & FLUTTER E C# & .NET
• Digite código de verdade, trecho a trecho, e veja o resultado no console.
• Teoria curta em cada lição, quizzes e projetos.
• Do iniciante ao avançado.

🎮 ARCADE DE DIGITAÇÃO
• Jogos de fliperama que treinam velocidade e precisão: corrida, chuva de palavras e mais.
• Combos, recordes pessoais e ranking de jogadores.

🤖 TUTOR COM IA
• Pergunte sobre a lição que está aberta; o tutor enxerga o trecho que você está digitando.

☁️ SEU PROGRESSO NA NUVEM
• Entre com e-mail e senha e continue de onde parou, em qualquer aparelho.
• Sem anúncios. Você pode excluir a conta e todos os dados dentro do app.

As frases e gravações do curso de inglês vêm do projeto Tatoeba (licença CC BY).
```

## Segurança dos dados (Data safety)
Responda assim (o app **não** usa anúncios nem análise):

- **Coleta ou compartilha dados do usuário?** Sim.
- **Dados criptografados em trânsito?** Sim (HTTPS).
- **Usuário pode pedir exclusão?** Sim (no app e pela URL acima).

| Tipo de dado | Coletado | Compartilhado | Finalidade | Obrigatório |
|---|---|---|---|---|
| Informações pessoais → **Endereço de e-mail** | Sim | Não | Gerenciamento da conta | Sim |
| Informações pessoais → **IDs de usuário** (UID do Firebase) | Sim | Não | Funcionalidade do app; Gerenciamento da conta | Sim |
| Atividade no app → **Interações no app** (progresso, pontos, ranking) | Sim | Não | Funcionalidade do app | Sim |
| Mensagens → **Outras mensagens no app** (perguntas ao tutor) | Sim | Não¹ | Funcionalidade do app | Não |
| Áudio → **Gravações de voz** | **Não**² | — | — | — |

¹ Os provedores de serviço que processam o dado em nome do app (Firebase/Google) não contam como "compartilhamento".
² O 🎤 usa o reconhecedor do sistema; o app só recebe o texto e não grava nem guarda áudio.

## Classificação de conteúdo (IARC)
- Categoria: **Referência, notícias ou educação**.
- Violência, sexo, linguagem imprópria, drogas, jogo de azar: **Não**.
- Os usuários interagem entre si ou compartilham conteúdo? **Os apelidos (parte do e-mail antes do @) aparecem no ranking** → responda "Sim, informações de perfil visíveis a outros usuários" se o formulário perguntar.
- Resultado esperado: **Livre / Everyone**.

## Público-alvo
13 anos ou mais (não direcionado a crianças).

## Antes de enviar
- Contas pessoais novas: **teste fechado com 12+ testadores por 14 dias** antes de pedir produção (confira a regra vigente no Play Console).
- Arquivo para subir: `build/app/outputs/bundle/release/app-release.aab` (gere de novo com `flutter build appbundle --release`).
- **App Signing do Google Play:** aceite; a chave de upload está em `~/.paclingo/upload-keystore.jks` (senha em `android/key.properties`). **Faça backup dos dois.** Depois do 1º upload, o Play mostra os SHA-1/SHA-256 do app: cadastre no Firebase (`firebase apps:android:sha:create`).
