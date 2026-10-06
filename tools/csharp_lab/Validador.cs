using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

namespace PacLab;

/// <summary>Valida trilhas do PAC·C# (formato, digitação, compilação, execução e saídas).</summary>
public static partial class Validador
{
    public static readonly HashSet<char> Digitaveis = BuildDigitaveis();

    static HashSet<char> BuildDigitaveis()
    {
        var s = new HashSet<char>();
        for (int c = 0x20; c < 0x7F; c++) s.Add((char)c);
        s.Add('\n');
        foreach (var c in "áàâãéêíóôõúüçÁÀÂÃÉÊÍÓÔÕÚÜÇ") s.Add(c);
        return s;
    }

    public static readonly string[] Etapas = ["Iniciante", "Intermediário", "Avançado", "Sênior"];
    public static readonly string[] Fundos = ["fundamentos", "logica", "colecoes", "objetos", "avancado", "flutter", "desafios", "pacotes"];
    public static readonly string[] TiposBloco = ["h", "p", "code", "tip", "warn"];
    public static readonly string[] NomesDart =
    [
        "Fundamentos", "Lógica", "Coleções", "Objetos", "Avançado", "Flutter", "Desafios", "Pacotes", "Dart Moderno", "Assíncrono",
        "Testes", "Navegação", "Animações", "Layout Pro", "Rede e APIs", "Persistência", "Arquitetura", "Pacotes II",
        "Dart Idiomático", "Coleções Pro", "Formulários e Gestos", "Estado Avançado", "UI e Material 3", "Cupertino iOS",
        "Firebase", "Erros e Exceções", "Datas e Texto", "Ciclo de Vida", "Widgets Avançados", "Debug e Performance",
        "Plataforma Nativa", "i18n e Acessibilidade",
    ];
    public static readonly string[] LinguagensExtras = ["bash", "json", "xml", "sql", "yaml", "proto", "http", "dockerfile", "texto"];

    [GeneratedRegex(@"new\s+Random\s*\(\s*\)|Random\.Shared|DateTime(Offset)?\.(Now|UtcNow|Today)|Guid\.NewGuid|Stopwatch|Environment\.(TickCount|ProcessorCount|MachineName|UserName|CurrentManagedThreadId|ProcessId)|GetHashCode\s*\(|Task\.Run|Parallel\.|new\s+Thread\b|\.AsParallel\(|ThreadPool\.|TimeProvider\.System|Process\.|ManagedThreadId|DateOnly\.FromDateTime\(DateTime\.(Now|Today)")]
    public static partial Regex ReNaoDeterministico();

    [GeneratedRegex(@"\u001e#(\d+)\u001e")]
    private static partial Regex ReMarca();

    public sealed class Opcoes
    {
        public bool Fix;
        public bool SemRodar;
        public int? SoLicao;
        public bool SemTeoria;
        public bool SemProjetos;
    }

    public static int Principal(string[] args)
    {
        if (args.Length == 0)
        {
            Console.Error.WriteLine("uso: Lab trilha <arquivo.json> [--fix] [--sem-rodar] [--licao N] [--sem-teoria] [--sem-projetos]");
            return 2;
        }
        var arq = args[0];
        var op = new Opcoes
        {
            Fix = args.Contains("--fix"),
            SemRodar = args.Contains("--sem-rodar"),
            SemTeoria = args.Contains("--sem-teoria"),
            SemProjetos = args.Contains("--sem-projetos"),
        };
        var iL = Array.IndexOf(args, "--licao");
        if (iL >= 0 && iL + 1 < args.Length) op.SoLicao = int.Parse(args[iL + 1]);

        JsonNode raiz;
        try { raiz = Json.Ler(arq); }
        catch (Exception e)
        {
            Console.WriteLine($"[ERRO] JSON inválido em {arq}: {e.Message}");
            Console.WriteLine("RESULTADO: FALHOU (corrija os erros e rode de novo)");
            return 1;
        }
        var trilhas = raiz is JsonArray arr ? arr.Select(n => n!.AsObject()).ToList() : [raiz.AsObject()];
        var rel = new Relatorio();
        Compilador.Aquecer();
        for (int ti = 0; ti < trilhas.Count; ti++)
            ValidarTrilha(trilhas[ti], ti, rel, op).GetAwaiter().GetResult();

        var texto = rel.Texto();
        File.WriteAllText(arq + ".relatorio.txt", texto);
        Console.Write(rel.Texto(70));
        if (op.Fix) Json.Gravar(arq, raiz);
        return rel.Erros > 0 ? 1 : 0;
    }

    public static async Task ValidarTrilha(JsonObject trilha, int ti, Relatorio rel, Opcoes op)
    {
        var nivel = Json.Str(trilha, "nivel") ?? "";
        var ondeT = $"Trilha \"{nivel}\"";
        if (nivel.Length == 0) rel.Erro(ondeT, "falta \"nivel\" (nome da trilha)");
        if (nivel.Length > 24) rel.Aviso(ondeT, $"nome da trilha longo ({nivel.Length} > 24)");
        if (NomesDart.Contains(nivel)) rel.Erro(ondeT, "nome igual ao de uma trilha da vertente Dart — escolha outro");
        if (string.IsNullOrWhiteSpace(Json.Str(trilha, "emoji"))) rel.Erro(ondeT, "falta \"emoji\"");
        if (string.IsNullOrWhiteSpace(Json.Str(trilha, "descricao"))) rel.Erro(ondeT, "falta \"descricao\"");
        var etapa = Json.Str(trilha, "etapa") ?? "";
        if (!Etapas.Contains(etapa)) rel.Erro(ondeT, $"\"etapa\" deve ser um de: {string.Join(", ", Etapas)}");
        var fundo = Json.Str(trilha, "fundo") ?? "";
        if (!Fundos.Contains(fundo)) rel.Erro(ondeT, $"\"fundo\" deve ser um de: {string.Join(", ", Fundos)}");
        var nomePerfil = Json.Str(trilha, "perfil") ?? "";
        if (!Perfis.Nomes.Contains(nomePerfil))
        {
            rel.Erro(ondeT, $"\"perfil\" deve ser um de: {string.Join(", ", Perfis.Nomes)}");
            nomePerfil = "console";
        }
        var perfil = Perfis.Obter(nomePerfil);

        var licoes = trilha["licoes"] as JsonArray ?? [];
        bool soProjetos = licoes.Count == 0 && (trilha["projetos"] as JsonArray)?.Count > 0;
        if (licoes.Count == 0 && !soProjetos) { rel.Erro(ondeT, "sem \"licoes\""); return; }
        if (!soProjetos && (licoes.Count < 10 || licoes.Count > 14)) rel.Aviso(ondeT, $"{licoes.Count} lições (o combinado é 11 a 13)");

        var nomes = new HashSet<string>();
        foreach (var l in licoes)
        {
            var nm = Json.Str(l, "nome") ?? "";
            if (!nomes.Add(nm)) rel.Erro(ondeT, $"lição repetida: \"{nm}\"");
        }

        // cods repetidos na trilha
        var vistos = new Dictionary<string, string>();
        for (int li = 0; li < licoes.Count; li++)
        {
            if (licoes[li]?["trechos"] is not JsonArray tr) continue;
            for (int k = 0; k < tr.Count; k++)
            {
                var c = Json.Str(tr[k], "cod") ?? "";
                if (c.Length == 0) continue;
                var onde = $"L{li} T{k}";
                if (vistos.TryGetValue(c, out var antes)) rel.Aviso(ondeT, $"trecho {onde} repete o código de {antes}");
                else vistos[c] = onde;
            }
        }

        var indices = Enumerable.Range(0, licoes.Count).Where(i => op.SoLicao == null || op.SoLicao == i).ToList();
        await Parallel.ForEachAsync(indices, new ParallelOptions { MaxDegreeOfParallelism = 3 }, async (li, _) =>
        {
            try { await ValidarLicao(licoes[li]!.AsObject(), perfil, li, rel, op); }
            catch (Exception e) { rel.Erro($"L{li}", $"falha interna do validador: {e.GetType().Name}: {e.Message}"); }
        });

        if (op.SoLicao == null && !op.SemProjetos)
        {
            var projetos = trilha["projetos"] as JsonArray ?? [];
            if (projetos.Count == 0 && perfil.Roda) rel.Aviso(ondeT, "trilha sem projetos \"Mão na Massa\" (o combinado é 2 a 3)");
            for (int pi = 0; pi < projetos.Count; pi++)
            {
                try { await ValidarProjeto(projetos[pi]!.AsObject(), perfil, pi, rel); }
                catch (Exception e) { rel.Erro($"Projeto {pi}", $"falha interna do validador: {e.Message}"); }
            }
        }
    }

    /// <summary>Checagens de digitação/estilo de um código que a pessoa vai digitar.</summary>
    public static void ChecarDigitavel(string cod, string onde, Relatorio rel, int maxLinhas)
    {
        if (cod.Length == 0) { rel.Erro(onde, "código vazio"); return; }
        var ruins = cod.Where(ch => !Digitaveis.Contains(ch)).Distinct().ToList();
        if (ruins.Count > 0)
            rel.Erro(onde, "caractere(s) impossível(is) de digitar no teclado ABNT: " +
                           string.Join(" ", ruins.Select(c => $"U+{(int)c:X4}'{c}'")) + " (use só ASCII + acentos do pt-BR; nada de tab, emoji, °, →)");
        var linhas = cod.Split('\n');
        if (linhas[0].Trim().Length == 0 || linhas[^1].Trim().Length == 0) rel.Erro(onde, "linha em branco no começo ou no fim do código");
        for (int i = 0; i < linhas.Length; i++)
        {
            var l = linhas[i];
            if (l.Length > 0 && l[^1] == ' ') rel.Erro(onde, $"espaço sobrando no fim da linha {i + 1} (invisível para quem digita)");
            if (l.Length > 80) rel.Erro(onde, $"linha {i + 1} muito longa ({l.Length} > 80 colunas) — quebre a linha");
            else if (l.Length > 78) rel.Aviso(onde, $"linha {i + 1} longa ({l.Length} > 78 colunas)");
            var ind = l.Length - l.TrimStart(' ').Length;
            if (l.Trim().Length > 0 && ind % 4 != 0 && !l.TrimStart().StartsWith('.') && !l.TrimStart().StartsWith("&&") &&
                !l.TrimStart().StartsWith("||") && !l.TrimStart().StartsWith("?") && !l.TrimStart().StartsWith(":"))
                rel.Aviso(onde, $"linha {i + 1} com indentação de {ind} espaços (use múltiplos de 4)");
            if (i > 0 && l.Trim().Length == 0 && linhas[i - 1].Trim().Length == 0) rel.Erro(onde, "duas linhas em branco seguidas");
        }
        if (linhas.Length > maxLinhas) rel.Aviso(onde, $"{linhas.Length} linhas (o combinado é até {maxLinhas})");
    }

    static bool TagsBalanceadas(string s)
    {
        int abre = Regex.Matches(s, "<b>").Count, fecha = Regex.Matches(s, "</b>").Count;
        int abreC = Regex.Matches(s, "<code>").Count, fechaC = Regex.Matches(s, "</code>").Count;
        return abre == fecha && abreC == fechaC && !Regex.IsMatch(Regex.Replace(s, "</?(b|code)>", ""), "<[a-zA-Z/]");
    }

    static string Linguagem(JsonNode? n) => (Json.Str(n, "l") ?? "cs").ToLowerInvariant();

    static async Task ValidarLicao(JsonObject licao, Perfil perfil, int li, Relatorio rel, Opcoes op)
    {
        Interlocked.Increment(ref rel.Licoes);
        var nome = Json.Str(licao, "nome") ?? "";
        var onde = $"L{li} \"{nome}\"";
        if (nome.Length == 0) rel.Erro(onde, "falta \"nome\"");
        if (nome.Length > 32) rel.Aviso(onde, $"nome longo ({nome.Length} > 32)");
        if (string.IsNullOrWhiteSpace(Json.Str(licao, "emoji"))) rel.Erro(onde, "falta \"emoji\"");
        var resumo = Json.Str(licao, "resumo") ?? "";
        if (resumo.Length == 0) rel.Erro(onde, "falta \"resumo\"");
        if (resumo.Length > 280) rel.Aviso(onde, $"resumo longo ({resumo.Length} > 280)");
        var permitir = Json.Strs(licao, "permitir");
        var entrada = Json.Str(licao, "entrada");

        // ---------- teoria ----------
        var teoria = licao["teoria"] as JsonArray ?? [];
        if (teoria.Count < 3) rel.Erro(onde, $"teoria com {teoria.Count} bloco(s) (mínimo 3; o combinado é 5 a 9)");
        int codeBlocos = 0;
        for (int b = 0; b < teoria.Count; b++)
        {
            var t = Json.Str(teoria[b], "t") ?? "";
            var c = Json.Str(teoria[b], "c") ?? "";
            if (!TiposBloco.Contains(t)) rel.Erro(onde, $"teoria bloco {b}: tipo \"{t}\" inválido (use h, p, code, tip, warn)");
            if (c.Trim().Length == 0) rel.Erro(onde, $"teoria bloco {b}: conteúdo vazio");
            if (t == "code")
            {
                codeBlocos++;
                Interlocked.Increment(ref rel.Blocos);
                var lg = Linguagem(teoria[b]);
                if (lg != "cs" && !LinguagensExtras.Contains(lg)) rel.Erro(onde, $"teoria bloco {b}: \"l\" = \"{lg}\" desconhecida");
                if (lg == "cs" && !op.SemTeoria) ValidarBlocoTeoria(c, perfil, $"{onde} teoria bloco {b}", rel, permitir);
            }
        }
        if (codeBlocos == 0) rel.Erro(onde, "teoria sem nenhum bloco \"code\"");

        // ---------- trechos ----------
        var trechos = licao["trechos"] as JsonArray ?? [];
        Interlocked.Add(ref rel.Trechos, trechos.Count);
        if (trechos.Count < 6) rel.Erro(onde, $"só {trechos.Count} trechos (mínimo 6; o combinado é 8 a 11)");
        else if (trechos.Count < 8 || trechos.Count > 14) rel.Aviso(onde, $"{trechos.Count} trechos (o combinado é 8 a 11)");

        var cods = new List<string>();
        var idx = new List<int>();
        var repetidos = new HashSet<string>();
        int curtos = 0;
        for (int k = 0; k < trechos.Count; k++)
        {
            var tr = trechos[k] as JsonObject;
            var ondeK = $"{onde} T{k}";
            if (tr == null) { rel.Erro(ondeK, "trecho não é objeto"); continue; }
            var cod = Json.Str(tr, "cod") ?? "";
            var dica = Json.Str(tr, "dica") ?? "";
            var conceito = Json.Str(tr, "conceito");
            ChecarDigitavel(cod, ondeK, rel, 12);
            if (!repetidos.Add(cod)) rel.Erro(ondeK, "código repetido dentro da lição");
            if (dica.Trim().Length == 0) rel.Erro(ondeK, "falta \"dica\"");
            else
            {
                if (!TagsBalanceadas(dica)) rel.Erro(ondeK, "dica com marcação desbalanceada (só <b>…</b> e <code>…</code>)");
                if (dica.Length > 170) rel.Aviso(ondeK, $"dica longa ({dica.Length} > 170)");
            }
            if (conceito != null && conceito.Length > 480) rel.Aviso(ondeK, $"conceito longo ({conceito.Length} > 480)");
            if (cod.Length <= 90 && cod.Count(ch => ch == '\n') <= 2) curtos++;
            var lg = Linguagem(tr);
            if (lg == "cs") { cods.Add(cod); idx.Add(k); }
            else
            {
                if (!LinguagensExtras.Contains(lg)) rel.Erro(ondeK, $"\"l\" = \"{lg}\" desconhecida");
                if ((Json.Str(tr, "out") ?? "").Trim().Length == 0) rel.Erro(ondeK, "falta \"out\" (descreva o resultado)");
            }
        }
        if (curtos < 4) rel.Aviso(onde, $"só {curtos} trechos curtos (≤ 90 caracteres e ≤ 3 linhas) — o quiz precisa de pelo menos 4");
        if (cods.Count == 0) return;
        var outs = new string?[trechos.Count];

        // ---------- compila a lição inteira ----------
        var pm = Montador.Montar(cods);
        if (!perfil.AceitaComandos && pm.TemComandos)
        {
            rel.Erro(onde, $"o perfil \"{perfil.Nome}\" não aceita comandos soltos (top-level statements): coloque o código dentro de classes/métodos");
            return;
        }
        bool exe = pm.TemComandos || pm.TemMainClassico;
        var r = Compilador.Compilar(pm.Codigo, perfil, exe, false, permitir);
        if (r.Erros.Count > 0 || r.Avisos.Count > 0)
        {
            foreach (var d in r.Erros.Concat(r.Avisos).Take(8))
                rel.Erro(OndeDiag(onde, pm, d, idx), $"{d.Id}: {d.Mensagem}");
            return;
        }

        // ---------- cada prefixo também compila (botão "copiar" do trecho k) ----------
        for (int k = 1; k < cods.Count; k++)
        {
            var pk = Montador.Montar(cods.Take(k).ToList());
            var rk = Compilador.Compilar(pk.Codigo, perfil, pk.TemComandos || pk.TemMainClassico, false, permitir);
            if (rk.Erros.Count > 0)
            {
                var d = rk.Erros[0];
                rel.Erro(OndeDiag(onde, pk, d, idx),
                    $"usa algo que só é declarado num trecho DEPOIS (o programa até o trecho {idx[k - 1]} não compila): {d.Id}: {d.Mensagem}");
                break;
            }
        }

        // ---------- roda e confere as saídas ----------
        bool rodar = perfil.Roda && exe && !op.SemRodar;
        if (!rodar)
        {
            for (int k = 0; k < trechos.Count; k++)
                if ((Json.Str(trechos[k], "out") ?? "").Trim().Length == 0)
                    rel.Erro($"{onde} T{k}", "falta \"out\" (descreva o que o trecho faz/mostra)");
            return;
        }
        var pmM = Montador.Montar(cods, marcas: true);
        var rm = Compilador.Compilar(pmM.Codigo, perfil, true, true, permitir);
        if (rm.Imagem == null)
        {
            var d = rm.Erros.FirstOrDefault() ?? rm.Avisos.FirstOrDefault();
            rel.Erro(onde, "um trecho começa no meio de um comando (ex.: um trecho termina no if e o outro começa no else) — " +
                           (d == null ? "" : $"{d.Id}: {d.Mensagem}"));
            return;
        }
        var e1T = Executor.Rodar(rm.Imagem, entrada);
        var e2T = Executor.Rodar(rm.Imagem, entrada);
        var e1 = await e1T;
        var e2 = await e2T;
        var s1 = Separar(e1.Saida);
        var s2 = Separar(e2.Saida);
        if (!e1.Ok)
        {
            int ultimo = s1.Count == 0 ? 0 : s1.Keys.Max();
            var k = idx.Count > ultimo ? idx[ultimo] : -1;
            var motivo = e1.Estourou ? "passou de 10 s rodando (laço infinito? esperando entrada? use \"entrada\" na lição)"
                : e1.Erro.Contains("EXCECAO:") ? e1.Erro.Trim().Split('\n')[0] : $"saiu com código {e1.Codigo}: {e1.Erro.Trim().Split('\n').FirstOrDefault()}";
            rel.Erro($"{onde} T{k}", $"ao rodar a lição: {motivo}");
            return;
        }
        for (int j = 0; j < cods.Count; j++)
        {
            var k = idx[j];
            var tr = trechos[k]!.AsObject();
            var ondeK = $"{onde} T{k}";
            s1.TryGetValue(j, out var a);
            s2.TryGetValue(j, out var b);
            a = (a ?? "").TrimEnd('\n');
            b = (b ?? "").TrimEnd('\n');
            var outAtual = Json.Str(tr, "out") ?? "";
            if (a.Length == 0)
            {
                if (outAtual.Trim().Length == 0) rel.Erro(ondeK, "o trecho não imprime nada e está sem \"out\" (descreva o resultado, ex.: \"nome = \\\"Ana\\\"\")");
                continue;
            }
            bool det = a == b && !ReNaoDeterministico().IsMatch(cods[j]);
            if (a.Split('\n').Length > 25 || a.Length > 1500) rel.Aviso(ondeK, $"saída longa ({a.Split('\n').Length} linhas) — diminua para caber no console");
            if (det)
            {
                if (outAtual != a)
                {
                    if (op.Fix) { tr["out"] = a; Interlocked.Increment(ref rel.Preenchidas); }
                    else rel.Aviso(ondeK, $"\"out\" difere da saída real (rode com --fix para preencher): real = {Resumir(a)}");
                }
            }
            else if (outAtual.Trim().Length == 0)
                rel.Erro(ondeK, "saída muda a cada execução e \"out\" está vazio: escreva um exemplo e diga que varia");
        }
    }

    static string Resumir(string s) => s.Length > 80 ? s[..80].Replace("\n", "⏎") + "…" : s.Replace("\n", "⏎");

    static Dictionary<int, string> Separar(string saida)
    {
        var d = new Dictionary<int, string>();
        var ms = ReMarca().Matches(saida);
        for (int i = 0; i < ms.Count; i++)
        {
            int ini = ms[i].Index + ms[i].Length;
            int fim = i + 1 < ms.Count ? ms[i + 1].Index : saida.Length;
            d[int.Parse(ms[i].Groups[1].Value)] = saida[ini..fim];
        }
        return d;
    }

    static string OndeDiag(string onde, ProgramaMontado pm, Diag d, List<int> idx)
    {
        if (d.Linha >= 0 && d.Linha < pm.Origem.Count)
        {
            var o = pm.Origem[d.Linha];
            if (o.Trecho >= 0 && o.Trecho < idx.Count)
                return $"{onde} T{idx[o.Trecho]} linha {o.Linha + 1}";
        }
        return onde;
    }

    public static void ValidarBlocoTeoria(string c, Perfil perfil, string onde, Relatorio rel, List<string> permitir)
    {
        var primeira = c.Split('\n')[0].ToLowerInvariant();
        bool naoCompila = primeira.Contains("não compila") || primeira.Contains("nao compila");
        var pm = Montador.Montar([c]);
        bool exe = pm.TemComandos || pm.TemMainClassico;
        if (!perfil.AceitaComandos && pm.TemComandos && !naoCompila)
        {
            rel.Erro(onde, $"o perfil \"{perfil.Nome}\" não aceita comandos soltos: ponha o exemplo dentro de uma classe/método");
            return;
        }
        var r = Compilador.Compilar(pm.Codigo, perfil, exe, false, permitir);
        if (naoCompila)
        {
            if (r.Erros.Count == 0) rel.Erro(onde, "bloco marcado \"não compila\" na 1ª linha, mas compila");
            return;
        }
        if (r.Erros.Count > 0 || r.Avisos.Count > 0)
        {
            var d = r.Erros.Concat(r.Avisos).First();
            var linha = d.Linha >= 0 && d.Linha < pm.Origem.Count && pm.Origem[d.Linha].Linha >= 0 ? pm.Origem[d.Linha].Linha + 1 : 0;
            rel.Erro(onde, $"exemplo da teoria não compila sozinho (linha {linha}): {d.Id}: {d.Mensagem} " +
                           "— todo bloco \"code\" precisa ser completo; se é de propósito, escreva \"// não compila\" na 1ª linha");
        }
    }

    static async Task ValidarProjeto(JsonObject p, Perfil perfil, int pi, Relatorio rel)
    {
        Interlocked.Increment(ref rel.Projetos);
        var nome = Json.Str(p, "nome") ?? "";
        var onde = $"Projeto {pi} \"{nome}\"";
        foreach (var campo in new[] { "nome", "emoji", "descricao", "cod" })
            if (string.IsNullOrWhiteSpace(Json.Str(p, campo))) rel.Erro(onde, $"falta \"{campo}\"");
        if (p["flutter"] is JsonValue fv && fv.TryGetValue<bool>(out var fl) && fl) rel.Erro(onde, "\"flutter\" tem que ser false");
        p["flutter"] = false;
        var cod = Json.Str(p, "cod") ?? "";
        ChecarDigitavel(cod, onde, rel, 70);
        var pm = Montador.Montar([cod]);
        if (!perfil.AceitaComandos && pm.TemComandos) { rel.Erro(onde, $"o perfil \"{perfil.Nome}\" não aceita comandos soltos"); return; }
        bool exe = pm.TemComandos || pm.TemMainClassico;
        var permitir = Json.Strs(p, "permitir");
        var r = Compilador.Compilar(pm.Codigo, perfil, exe, perfil.Roda && exe, permitir);
        if (r.Erros.Count > 0 || r.Avisos.Count > 0)
        {
            foreach (var d in r.Erros.Concat(r.Avisos).Take(6))
            {
                var o = d.Linha >= 0 && d.Linha < pm.Origem.Count ? pm.Origem[d.Linha].Linha + 1 : 0;
                rel.Erro($"{onde} linha {o}", $"{d.Id}: {d.Mensagem}");
            }
            return;
        }
        if (!(perfil.Roda && exe) || r.Imagem == null)
        {
            if ((Json.Str(p, "out") ?? "").Trim().Length == 0) rel.Erro(onde, "falta \"out\" (descreva o resultado)");
            return;
        }
        var entrada = Json.Str(p, "entrada");
        var t1 = Executor.Rodar(r.Imagem, entrada);
        var t2 = Executor.Rodar(r.Imagem, entrada);
        var e1 = await t1;
        var e2 = await t2;
        if (!e1.Ok)
        {
            rel.Erro(onde, e1.Estourou ? "passou de 10 s rodando" : $"erro ao rodar: {e1.Erro.Trim().Split('\n')[0]}");
            return;
        }
        var a = e1.Saida.TrimEnd('\n');
        if (a.Length == 0) { rel.Erro(onde, "o programa não imprime nada"); return; }
        if (a.Split('\n').Length < 3) rel.Aviso(onde, "projeto imprime menos de 3 linhas");
        if (a.Split('\n').Length > 40) rel.Aviso(onde, $"projeto imprime {a.Split('\n').Length} linhas (reduza para até 40)");
        bool det = e1.Saida == e2.Saida && !ReNaoDeterministico().IsMatch(cod);
        var outAtual = Json.Str(p, "out") ?? "";
        if (det)
        {
            if (outAtual != a) { p["out"] = a; Interlocked.Increment(ref rel.Preenchidas); }
        }
        else if (outAtual.Trim().Length == 0) rel.Erro(onde, "saída varia a cada execução e \"out\" está vazio");
    }
}
