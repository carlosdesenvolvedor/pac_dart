# Laboratório do PAC·C#

Valida o currículo C# (`assets/csharp/curriculo.json`) compilando cada exercício com o Roslyn e
rodando os programas (cultura pt-BR). Veja a seção **PAC·C#** do `ESTADO-DO-PROJETO.md`.

```bash
export DOTNET_ROOT=/opt/homebrew/opt/dotnet/libexec      # .NET 10 (o do terminal é o 9)
$DOTNET_ROOT/dotnet build tools/csharp_lab -c Release -o /tmp/paclab   # compila o laboratório FORA do repo
L="$DOTNET_ROOT/dotnet /tmp/paclab/Lab.dll"
$L trilha   trilha.json --fix     # formato + digitação + compila lição e prefixos + roda e preenche "out"
$L desafios trilha.json --fix     # desafios de lógica: executa e corrige o gabarito
$L snippet  x.cs --perfil unity   # testa um código solto (console|web|testes|biblioteca|unity|godot|monogame)
$L montar   trilha.json 3 5       # o programa que o botão "copiar" gera (lição 3 até o trecho 5)
```

- `Montador.cs` é a regra de montagem do programa — espelhada em `lib/core/util/programa_csharp.dart`.
- `stubs/UnityEngine.cs`: stub de compilação da API do Unity 6 (só assinaturas).
- `GUIA-GERADOR.md` / `GUIA-DESAFIOS.md`: o contrato que os agentes geradores seguem.
- `integrar.py`: junta `trilhas/NN-id.json` + `desafios/NN-id.json` no asset (rodar de uma pasta de trabalho).
