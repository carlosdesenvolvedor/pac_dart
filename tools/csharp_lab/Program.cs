using System.Text;
using PacLab;

Console.OutputEncoding = new UTF8Encoding(false);

if (args.Length >= 2 && args[0] == "--rodar") return Executor.RodarAqui(args[1]);

if (args.Length == 0)
{
    Console.WriteLine("""
        Laboratório do PAC·C#
          Lab trilha <arq.json> [--fix] [--sem-rodar] [--licao N] [--sem-teoria] [--sem-projetos]
              valida trilha(s): formato, digitação, compila cada lição (e cada prefixo), roda e confere/preenche "out"
          Lab desafios <arq.json> [--fix]
              valida os desafios de lógica (a resposta certa vem da execução real)
          Lab snippet <arq.cs> [--perfil console|web|testes|biblioteca|unity|godot|monogame] [--rodar] [--entrada "texto"]
              compila (e roda) um arquivo solto do mesmo jeito que um trecho
          Lab montar <arq.json> <licao> [trechoFinal]
              mostra o programa que o botão "copiar" gera para a lição até o trecho
        """);
    return 2;
}

switch (args[0])
{
    case "trilha":
        return Validador.Principal(args[1..]);
    case "desafios":
        return ValidadorDesafios.Principal(args[1..]);
    case "snippet":
    {
        var arq = args[1];
        var iP = Array.IndexOf(args, "--perfil");
        var perfil = Perfis.Obter(iP >= 0 ? args[iP + 1] : "console");
        var iE = Array.IndexOf(args, "--entrada");
        var entrada = iE >= 0 ? args[iE + 1].Replace("\\n", "\n") : null;
        var cod = File.ReadAllText(arq);
        var pm = Montador.Montar([cod]);
        bool exe = pm.TemComandos || pm.TemMainClassico;
        var r = Compilador.Compilar(pm.Codigo, perfil, exe, args.Contains("--rodar"));
        foreach (var d in r.Erros.Concat(r.Avisos))
        {
            var o = d.Linha >= 0 && d.Linha < pm.Origem.Count ? pm.Origem[d.Linha].Linha + 1 : 0;
            Console.WriteLine($"{(d.Erro ? "ERRO" : "AVISO")} linha {o}: {d.Id}: {d.Mensagem}");
        }
        if (r.Erros.Count == 0 && r.Avisos.Count == 0) Console.WriteLine("COMPILA: ok");
        if (args.Contains("--rodar") && r.Imagem != null && exe)
        {
            var e = Executor.Rodar(r.Imagem, entrada).GetAwaiter().GetResult();
            Console.WriteLine("---- saída ----");
            Console.Write(e.Saida);
            if (!e.Ok) Console.WriteLine($"---- falhou ({(e.Estourou ? "tempo esgotado" : "código " + e.Codigo)}) ----\n{e.Erro}");
        }
        return r.Erros.Count == 0 && r.Avisos.Count == 0 ? 0 : 1;
    }
    case "montar":
    {
        var raiz = Json.Ler(args[1]);
        var trilha = raiz is System.Text.Json.Nodes.JsonArray a ? a[0]! : raiz;
        var li = int.Parse(args[2]);
        var trechos = (System.Text.Json.Nodes.JsonArray)trilha["licoes"]![li]!["trechos"]!;
        int ate = args.Length > 3 ? int.Parse(args[3]) : trechos.Count - 1;
        var cods = trechos.Take(ate + 1).Where(t => (Json.Str(t, "l") ?? "cs") == "cs").Select(t => Json.Str(t, "cod") ?? "").ToList();
        Console.Write(Montador.Montar(cods).Codigo);
        return 0;
    }
    case "montar-lote":
    {
        // para o teste de paridade com lib/core/util/programa_csharp.dart
        var raiz = Json.Ler(args[1]);
        var lista = raiz is System.Text.Json.Nodes.JsonArray arr ? arr.ToList() : [raiz];
        var saida = new System.Text.Json.Nodes.JsonObject();
        for (int ti = 0; ti < lista.Count; ti++)
        {
            var licoes = lista[ti]!["licoes"] as System.Text.Json.Nodes.JsonArray ?? [];
            for (int li = 0; li < licoes.Count; li++)
            {
                var cods = new List<string>();
                var trechos = (System.Text.Json.Nodes.JsonArray)licoes[li]!["trechos"]!;
                for (int k = 0; k < trechos.Count; k++)
                {
                    if ((Json.Str(trechos[k], "l") ?? "cs") != "cs") continue;
                    cods.Add(Json.Str(trechos[k], "cod") ?? "");
                    saida[$"{ti}:{li}:{k}"] = Montador.Montar(cods).Codigo;
                }
            }
        }
        File.WriteAllText(args[2], saida.ToJsonString(Json.Opcoes));
        Console.WriteLine($"{saida.Count} programas");
        return 0;
    }
    default:
        Console.Error.WriteLine($"modo desconhecido: {args[0]}");
        return 2;
}
