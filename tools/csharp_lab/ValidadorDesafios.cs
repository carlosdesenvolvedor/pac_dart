using System.Text.Json.Nodes;

namespace PacLab;

/// <summary>
/// Valida os desafios de lógica (não são de digitação): a resposta certa sai da
/// execução REAL do C#, e o validador corrige/preenche o gabarito com --fix.
/// Tipos: saida, valor, lacuna, ordenar, bug, escolha.
/// </summary>
public static class ValidadorDesafios
{
    public static readonly string[] Tipos = ["saida", "valor", "lacuna", "ordenar", "bug", "escolha"];
    const string M = Montador.Marca;

    public static int Principal(string[] args)
    {
        if (args.Length == 0)
        {
            Console.Error.WriteLine("uso: Lab desafios <arquivo.json> [--fix]   (objeto de trilha com \"desafios\", lista de trilhas, ou lista de desafios)");
            return 2;
        }
        var arq = args[0];
        bool fix = args.Contains("--fix");
        JsonNode raiz;
        try { raiz = Json.Ler(arq); }
        catch (Exception e)
        {
            Console.WriteLine($"[ERRO] JSON inválido: {e.Message}\nRESULTADO: FALHOU (corrija os erros e rode de novo)");
            return 1;
        }
        var listas = new List<(string nome, JsonArray desafios)>();
        if (raiz is JsonArray arr && arr.Count > 0 && arr[0] is JsonObject o0 && o0.ContainsKey("tipo"))
            listas.Add(("desafios", arr));
        else if (raiz is JsonArray trilhas)
        {
            foreach (var t in trilhas)
                if (t?["desafios"] is JsonArray d) listas.Add((Json.Str(t, "nivel") ?? "?", d));
        }
        else if (raiz?["desafios"] is JsonArray d1) listas.Add((Json.Str(raiz, "nivel") ?? "?", d1));

        var rel = new Relatorio();
        Compilador.Aquecer();
        foreach (var (nome, desafios) in listas)
        {
            ChecarConjunto(desafios, $"Trilha \"{nome}\"", rel);
            var tarefas = Enumerable.Range(0, desafios.Count).ToList();
            Parallel.ForEachAsync(tarefas, new ParallelOptions { MaxDegreeOfParallelism = 3 }, async (i, _) =>
            {
                try { await Validar(desafios[i]!.AsObject(), $"D{i}", rel, fix); }
                catch (Exception e) { rel.Erro($"D{i}", $"falha interna: {e.GetType().Name}: {e.Message}"); }
            }).GetAwaiter().GetResult();
        }
        File.WriteAllText(arq + ".desafios.txt", rel.Texto());
        Console.Write(rel.Texto(70));
        if (fix && raiz != null) Json.Gravar(arq, raiz);
        return rel.Erros > 0 ? 1 : 0;
    }

    static void ChecarConjunto(JsonArray desafios, string onde, Relatorio rel)
    {
        if (desafios.Count < 12) rel.Aviso(onde, $"{desafios.Count} desafios (o combinado é 14 a 18)");
        var porTipo = desafios.GroupBy(d => Json.Str(d, "tipo") ?? "").ToDictionary(g => g.Key, g => g.Count());
        foreach (var t in new[] { "saida", "valor", "lacuna", "ordenar", "bug" })
            if (!porTipo.ContainsKey(t)) rel.Aviso(onde, $"nenhum desafio do tipo \"{t}\"");
        int jogos = desafios.Count(d => (Json.Str(d, "tema") ?? "") == "jogo");
        if (desafios.Count > 0 && jogos * 100 / desafios.Count < 25) rel.Aviso(onde, $"só {jogos} desafio(s) com tema de jogo (o combinado é ≥ 30%)");
    }

    static string Normal(string s) => s.Replace("\r\n", "\n").TrimEnd('\n', ' ');

    static async Task<(bool ok, string saida, string motivo)> CompilarRodar(string codigo, List<string> permitir, string? entrada = null,
        bool alternativa = false)
    {
        var pm = Montador.Montar([codigo]);
        var perfil = Perfis.Obter("console");
        bool exe = pm.TemComandos || pm.TemMainClassico;
        if (!exe) return (false, "", "o código não tem comandos para rodar");
        var r = Compilador.Compilar(pm.Codigo, perfil, true, true, permitir);
        if (r.Imagem == null || r.Avisos.Count > 0)
        {
            var d = r.Erros.Concat(r.Avisos).First();
            var linha = d.Linha >= 0 && d.Linha < pm.Origem.Count ? pm.Origem[d.Linha].Linha + 1 : 0;
            return (false, "", $"não compila (linha {linha}): {d.Id}: {d.Mensagem}");
        }
        if (alternativa)
        {
            // opção errada/variação: uma execução curta basta (muitas entram em laço infinito)
            var ea = await Executor.Rodar(r.Imagem, entrada, 2500);
            return ea.Ok ? (true, Normal(ea.Saida), "") : (false, ea.Saida, "falhou");
        }
        var e1T = Executor.Rodar(r.Imagem, entrada, 8000);
        var e2T = Executor.Rodar(r.Imagem, entrada, 8000);
        var e1 = await e1T;
        var e2 = await e2T;
        if (!e1.Ok) return (false, e1.Saida, e1.Estourou ? "passou de 8 s rodando (ou imprimiu demais)" : $"erro ao rodar: {e1.Erro.Trim().Split('\n')[0]}");
        if (e1.Saida != e2.Saida || Validador.ReNaoDeterministico().IsMatch(codigo))
            return (false, e1.Saida, "a saída muda a cada execução (desafio precisa ser determinístico; use Random com semente fixa)");
        return (true, Normal(e1.Saida), "");
    }

    static bool Compila(string codigo, List<string> permitir)
    {
        var pm = Montador.Montar([codigo]);
        var r = Compilador.Compilar(pm.Codigo, Perfis.Obter("console"), pm.TemComandos || pm.TemMainClassico, false, permitir);
        return r.Erros.Count == 0;
    }

    static async Task Validar(JsonObject d, string ondeBase, Relatorio rel, bool fix)
    {
        Interlocked.Increment(ref rel.Desafios);
        var tipo = Json.Str(d, "tipo") ?? "";
        var titulo = Json.Str(d, "titulo") ?? "";
        var onde = $"{ondeBase} [{tipo}] \"{titulo}\"";
        if (!Tipos.Contains(tipo)) { rel.Erro(onde, $"tipo inválido (use {string.Join(", ", Tipos)})"); return; }
        if (titulo.Length == 0) rel.Erro(onde, "falta \"titulo\"");
        if (titulo.Length > 44) rel.Aviso(onde, $"título longo ({titulo.Length} > 44)");
        if ((Json.Str(d, "enunciado") ?? "").Trim().Length == 0) rel.Erro(onde, "falta \"enunciado\"");
        if ((Json.Str(d, "explicacao") ?? "").Trim().Length == 0) rel.Erro(onde, "falta \"explicacao\"");
        var nivel = Json.Int(d, "nivel");
        if (nivel is null or < 1 or > 3) rel.Erro(onde, "\"nivel\" tem que ser 1, 2 ou 3");
        var tema = Json.Str(d, "tema");
        if (tema != null && tema != "jogo" && tema != "") rel.Aviso(onde, "\"tema\" só aceita \"jogo\"");
        var permitir = Json.Strs(d, "permitir");
        var cod = Json.Str(d, "cod") ?? "";

        switch (tipo)
        {
            case "saida":
            {
                var ops = Json.Strs(d, "opcoes");
                var certa = Json.Int(d, "certa") ?? -1;
                if (!ChecarOpcoes(ops, certa, 4, onde, rel)) return;
                if (cod.Length == 0) { rel.Erro(onde, "falta \"cod\""); return; }
                var (ok, saida, motivo) = await CompilarRodar(cod, permitir);
                if (!ok) { rel.Erro(onde, motivo); return; }
                if (saida.Length == 0) { rel.Erro(onde, "o programa não imprime nada"); return; }
                if (saida.Split('\n').Length > 6 || saida.Length > 140) rel.Aviso(onde, "saída grande demais para virar alternativa (até 6 linhas / 140 caracteres)");
                var iReal = ops.Select(Normal).ToList().IndexOf(saida);
                if (iReal >= 0 && iReal != certa)
                {
                    if (fix) { d["certa"] = iReal; certa = iReal; Interlocked.Increment(ref rel.Corrigidas); rel.Aviso(onde, $"\"certa\" corrigida para a opção {iReal} (a saída real é {Resumo(saida)})"); }
                    else { rel.Erro(onde, $"a alternativa certa é a {iReal}, não a {certa}: a saída real é {Resumo(saida)}"); return; }
                }
                if (Normal(ops[certa]) != saida)
                {
                    if (fix) { ((JsonArray)d["opcoes"]!)[certa] = saida; Interlocked.Increment(ref rel.Corrigidas); rel.Aviso(onde, $"alternativa certa corrigida para a saída real: {Resumo(saida)}"); }
                    else rel.Erro(onde, $"a alternativa certa não bate com a saída real: {Resumo(saida)}");
                }
                break;
            }
            case "valor":
            {
                var expr = Json.Str(d, "expr") ?? "";
                if (cod.Length == 0 || expr.Length == 0) { rel.Erro(onde, "\"valor\" precisa de \"cod\" e \"expr\""); return; }
                var programa = cod + "\nglobal::System.Console.Write(\"" + M + "\" + (" + expr + "));";
                var pm = Montador.Montar([cod, "global::System.Console.Write(\"" + M + "\" + (" + expr + "));"]);
                _ = programa;
                var perfil = Perfis.Obter("console");
                var r = Compilador.Compilar(pm.Codigo, perfil, true, true, permitir);
                if (r.Imagem == null || r.Avisos.Count > 0)
                {
                    var dg = r.Erros.Concat(r.Avisos).First();
                    rel.Erro(onde, $"não compila: {dg.Id}: {dg.Mensagem}");
                    return;
                }
                var e1 = await Executor.Rodar(r.Imagem, null, 8000);
                var e2 = await Executor.Rodar(r.Imagem, null, 8000);
                if (!e1.Ok) { rel.Erro(onde, e1.Estourou ? "passou de 8 s" : $"erro ao rodar: {e1.Erro.Trim().Split('\n')[0]}"); return; }
                if (e1.Saida != e2.Saida || Validador.ReNaoDeterministico().IsMatch(cod)) { rel.Erro(onde, "resultado muda a cada execução"); return; }
                var k = e1.Saida.LastIndexOf(M, StringComparison.Ordinal);
                var valor = Normal(e1.Saida[(k + 1)..]);
                if (valor.Length == 0 || valor.Length > 30 || valor.Contains('\n')) rel.Aviso(onde, $"resposta ruim para digitar: \"{Resumo(valor)}\" (use algo curto: número, palavra, True/False)");
                var resp = Json.Str(d, "resposta") ?? "";
                if (resp != valor)
                {
                    if (fix) { d["resposta"] = valor; Interlocked.Increment(ref rel.Corrigidas); if (resp.Length > 0) rel.Aviso(onde, $"resposta corrigida de \"{resp}\" para \"{valor}\""); }
                    else rel.Erro(onde, $"\"resposta\" = \"{resp}\", mas o valor real é \"{valor}\"");
                }
                if (Json.Strs(d, "opcoes").Count > 0) rel.Aviso(onde, "tipo \"valor\" é de digitar a resposta — \"opcoes\" será ignorado");
                break;
            }
            case "lacuna":
            {
                var ops = Json.Strs(d, "opcoes");
                var certa = Json.Int(d, "certa") ?? -1;
                if (!ChecarOpcoes(ops, certa, 4, onde, rel)) return;
                int n = CountOf(cod, "___");
                if (n != 1) { rel.Erro(onde, $"\"cod\" precisa ter exatamente uma lacuna ___ (tem {n})"); return; }
                var (ok, saida, motivo) = await CompilarRodar(cod.Replace("___", ops[certa]), permitir);
                if (!ok) { rel.Erro(onde, $"com a opção certa: {motivo}"); return; }
                var esperado = Json.Str(d, "esperado") ?? "";
                if (Normal(esperado) != saida)
                {
                    if (fix) { d["esperado"] = saida; Interlocked.Increment(ref rel.Corrigidas); }
                    else rel.Erro(onde, $"\"esperado\" não bate com a saída real: {Resumo(saida)}");
                }
                for (int i = 0; i < ops.Count; i++)
                {
                    if (i == certa) continue;
                    var alt = cod.Replace("___", ops[i]);
                    if (!Compila(alt, permitir)) continue;
                    var (ok2, s2, _) = await CompilarRodar(alt, permitir, alternativa: true);
                    if (ok2 && s2 == saida) rel.Erro(onde, $"a opção errada \"{ops[i]}\" também produz a saída esperada (ambíguo)");
                }
                break;
            }
            case "ordenar":
            {
                var linhas = Json.Strs(d, "linhas");
                if (linhas.Count < 4 || linhas.Count > 10) { rel.Erro(onde, $"\"linhas\" precisa ter de 4 a 10 cartões (tem {linhas.Count})"); return; }
                if (linhas.Any(l => l.Split('\n').Length > 3)) { rel.Erro(onde, "cada cartão de \"linhas\" tem no máximo 3 linhas"); return; }
                if (linhas.Any(l => l.Trim() == "{")) rel.Aviso(onde, "cartão só com chave: junte o { com a linha de cima (ex.: \"for (...)\\n{\") para a ordem não ficar ambígua");
                if (linhas.Distinct().Count() < 3) { rel.Erro(onde, "linhas iguais demais"); return; }
                var (ok, saida, motivo) = await CompilarRodar(string.Join("\n", linhas), permitir);
                if (!ok) { rel.Erro(onde, $"na ordem certa: {motivo}"); return; }
                if (saida.Length == 0) { rel.Erro(onde, "o programa não imprime nada"); return; }
                var esperado = Json.Str(d, "esperado") ?? "";
                if (Normal(esperado) != saida)
                {
                    if (fix) { d["esperado"] = saida; Interlocked.Increment(ref rel.Corrigidas); }
                    else rel.Erro(onde, $"\"esperado\" não bate com a saída real: {Resumo(saida)}");
                }
                for (int i = 0; i + 1 < linhas.Count; i++)
                {
                    if (linhas[i] == linhas[i + 1]) continue;
                    var troca = new List<string>(linhas);
                    (troca[i], troca[i + 1]) = (troca[i + 1], troca[i]);
                    var alt = string.Join("\n", troca);
                    if (!Compila(alt, permitir)) continue;
                    var (ok2, s2, _) = await CompilarRodar(alt, permitir, alternativa: true);
                    if (ok2 && s2 == saida)
                        rel.Erro(onde, $"ordem ambígua: as linhas {i + 1} e {i + 2} podem trocar de lugar e o resultado é o mesmo — torne a ordem única");
                }
                break;
            }
            case "bug":
            {
                var linhas = Json.Strs(d, "linhas");
                var lb = Json.Int(d, "linhaBug") ?? -1;
                var corr = Json.Str(d, "correcao") ?? "";
                if (linhas.Count < 3 || lb < 0 || lb >= linhas.Count || corr.Length == 0)
                {
                    rel.Erro(onde, "\"bug\" precisa de \"linhas\" (3+), \"linhaBug\" (índice 0-based) e \"correcao\"");
                    return;
                }
                if (corr.Trim() == linhas[lb].Trim()) { rel.Erro(onde, "\"correcao\" é igual à linha com bug"); return; }
                var certo = new List<string>(linhas) { [lb] = corr };
                var (ok, saida, motivo) = await CompilarRodar(string.Join("\n", certo), permitir);
                if (!ok) { rel.Erro(onde, $"com a correção: {motivo}"); return; }
                var esperado = Json.Str(d, "esperado") ?? "";
                if (Normal(esperado) != saida)
                {
                    if (fix) { d["esperado"] = saida; Interlocked.Increment(ref rel.Corrigidas); }
                    else rel.Erro(onde, $"\"esperado\" não bate com a saída real corrigida: {Resumo(saida)}");
                }
                var comBug = string.Join("\n", linhas);
                if (Compila(comBug, permitir))
                {
                    var (ok2, s2, _) = await CompilarRodar(comBug, permitir, alternativa: true);
                    if (ok2 && s2 == saida) rel.Erro(onde, "o código \"com bug\" já produz a saída esperada — o bug não aparece");
                }
                break;
            }
            case "escolha":
            {
                var ops = Json.Strs(d, "opcoes");
                var certa = Json.Int(d, "certa") ?? -1;
                if (!ChecarOpcoes(ops, certa, 0, onde, rel)) return;
                if (cod.Length > 0)
                {
                    var primeira = cod.Split('\n')[0].ToLowerInvariant();
                    if (!(primeira.Contains("não compila") || primeira.Contains("nao compila")) && !Compila(cod, permitir))
                    {
                        var pm = Montador.Montar([cod]);
                        var r = Compilador.Compilar(pm.Codigo, Perfis.Obter("console"), pm.TemComandos || pm.TemMainClassico, false, permitir);
                        var dg = r.Erros.FirstOrDefault();
                        rel.Erro(onde, $"\"cod\" não compila: {dg?.Id}: {dg?.Mensagem}");
                    }
                }
                break;
            }
        }
    }

    static int CountOf(string s, string sub)
    {
        int n = 0, i = 0;
        while ((i = s.IndexOf(sub, i, StringComparison.Ordinal)) >= 0) { n++; i += sub.Length; }
        return n;
    }

    static string Resumo(string s) => s.Length > 90 ? s[..90].Replace("\n", "⏎") + "…" : s.Replace("\n", "⏎");

    static bool ChecarOpcoes(List<string> ops, int certa, int exigidas, string onde, Relatorio rel)
    {
        if (exigidas > 0 && ops.Count != exigidas) { rel.Erro(onde, $"precisa de exatamente {exigidas} \"opcoes\" (tem {ops.Count})"); return false; }
        if (exigidas == 0 && (ops.Count < 2 || ops.Count > 4)) { rel.Erro(onde, "precisa de 2 a 4 \"opcoes\""); return false; }
        if (ops.Any(o => o.Trim().Length == 0)) { rel.Erro(onde, "opção vazia"); return false; }
        if (ops.Select(o => o.Trim()).Distinct().Count() != ops.Count) { rel.Erro(onde, "opções repetidas"); return false; }
        if (certa < 0 || certa >= ops.Count) { rel.Erro(onde, "\"certa\" fora do intervalo das opções"); return false; }
        return true;
    }
}
