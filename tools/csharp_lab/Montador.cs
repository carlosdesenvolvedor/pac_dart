using System.Text;
using System.Text.RegularExpressions;

namespace PacLab;

public enum TipoPedaco { Using, Namespace, Tipo, Comando }

/// <summary>Um pedaço de topo de um trecho: using, namespace de arquivo, tipo ou comando.</summary>
public sealed record Pedaco(TipoPedaco Tipo, List<string> Linhas, int LinhaInicial);

/// <summary>Uma linha do programa montado e de onde ela veio (trecho, linha no trecho).</summary>
public sealed record LinhaOrigem(int Trecho, int Linha);

public sealed class ProgramaMontado
{
    public string Codigo = "";
    public List<LinhaOrigem> Origem = new();
    public bool TemComandos;
    public bool TemMainClassico;
}

/// <summary>
/// Monta um programa C# a partir de trechos de exercício, na mesma regra que o
/// app usa no botão "copiar": usings no topo, comandos (top-level statements)
/// na ordem, e declarações de tipo (class/record/struct/interface/enum/
/// delegate/namespace) no fim — o C# exige que os comandos venham antes dos tipos.
/// A MESMA regra está espelhada em Dart em lib/core/util/programa_csharp.dart.
/// </summary>
public static partial class Montador
{
    [GeneratedRegex(@"^(global\s+)?using\s+(static\s+)?[A-Za-z_][\w.]*\s*;\s*(//.*)?$")]
    private static partial Regex ReUsing();

    [GeneratedRegex(@"^(global\s+)?using\s+[A-Za-z_]\w*\s*=\s*[^;]+;\s*(//.*)?$")]
    private static partial Regex ReUsingAlias();

    [GeneratedRegex(@"^namespace\s+[A-Za-z_][\w.]*\s*;\s*(//.*)?$")]
    private static partial Regex ReNamespaceArquivo();

    [GeneratedRegex(@"^namespace\s+[A-Za-z_][\w.]*\s*(\{.*)?$")]
    private static partial Regex ReNamespaceBloco();

    [GeneratedRegex(@"^((public|internal|private|protected|file|abstract|sealed|static|partial|readonly|ref|unsafe|new)\s+)*(class|struct|interface|enum|delegate)\b")]
    private static partial Regex ReTipo();

    [GeneratedRegex(@"^((public|internal|private|protected|file|abstract|sealed|static|partial|readonly|ref|unsafe|new)\s+)*record\s+((struct|class)\s+)?[A-Za-z_]\w*")]
    private static partial Regex ReRecord();

    [GeneratedRegex(@"\bstatic\s+(async\s+)?(void|int|Task|Task\s*<\s*int\s*>)\s+Main\s*\(")]
    private static partial Regex ReMainClassico();

    /// <summary>Estado do scanner: profundidade de chaves e se a linha terminou dentro de literal/comentário.</summary>
    private sealed class Scanner
    {
        public int Profundidade;
        public bool EmComentarioBloco;
        public bool EmLiteralMultilinha; // string verbatim/raw que atravessa linhas
        public string FechoLiteral = "";   // o que fecha o literal multilinha
        public bool LiteralVerbatim;
    }

    /// <summary>
    /// Pula um literal de string/char começando em s[i] (já sabendo que é início de literal).
    /// Devolve o índice logo após o fim, ou s.Length se não fechou nesta string.
    /// Trata interpolação com buracos que contêm outras strings.
    /// </summary>
    internal static int PularLiteral(string s, int i, out bool fechou)
    {
        fechou = true;
        int n = s.Length;
        // prefixos $ e @ em qualquer ordem
        int j = i;
        int dolares = 0;
        bool verbatim = false;
        while (j < n && (s[j] == '$' || s[j] == '@'))
        {
            if (s[j] == '$') dolares++; else verbatim = true;
            j++;
        }
        if (j >= n) { fechou = false; return n; }
        if (s[j] == '\'')
        {
            // char literal
            int k = j + 1;
            while (k < n)
            {
                if (s[k] == '\\') { k += 2; continue; }
                if (s[k] == '\'') return k + 1;
                if (s[k] == '\n') return k; // quebrado
                k++;
            }
            fechou = false;
            return n;
        }
        if (s[j] != '"') return j + 1;
        // raw string? 3+ aspas
        int aspas = 0;
        while (j + aspas < n && s[j + aspas] == '"') aspas++;
        if (aspas >= 3)
        {
            string fecho = new('"', aspas);
            int k = s.IndexOf(fecho, j + aspas, StringComparison.Ordinal);
            if (k < 0) { fechou = false; return n; }
            int fim = k + aspas;
            while (fim < n && s[fim] == '"') fim++; // aspas extras fazem parte do fecho
            return fim;
        }
        if (aspas == 2 && !verbatim)
        {
            // string vazia ""
            return j + 2;
        }
        int p = j + 1;
        bool interp = dolares > 0;
        while (p < n)
        {
            char c = s[p];
            if (verbatim)
            {
                if (c == '"')
                {
                    if (p + 1 < n && s[p + 1] == '"') { p += 2; continue; }
                    return p + 1;
                }
            }
            else
            {
                if (c == '\\') { p += 2; continue; }
                if (c == '"') return p + 1;
                if (c == '\n') return p; // string normal não atravessa linha
            }
            if (interp && c == '{')
            {
                if (p + 1 < n && s[p + 1] == '{') { p += 2; continue; }
                // buraco de interpolação
                int prof = 1;
                p++;
                while (p < n && prof > 0)
                {
                    char d = s[p];
                    if (d == '"' || d == '\'' || ((d == '$' || d == '@') && p + 1 < n && (s[p + 1] == '"' || s[p + 1] == '$' || s[p + 1] == '@')))
                    {
                        p = PularLiteral(s, p, out var f2);
                        if (!f2) { fechou = false; return n; }
                        continue;
                    }
                    if (d == '{') prof++;
                    else if (d == '}') prof--;
                    p++;
                }
                continue;
            }
            if (interp && c == '}' && p + 1 < n && s[p + 1] == '}') { p += 2; continue; }
            p++;
        }
        fechou = false;
        return n;
    }

    /// <summary>Analisa uma linha: atualiza profundidade e devolve o último caractere significativo (fora de string/comentário).</summary>
    private static char AnalisarLinha(string linha, Scanner sc)
    {
        char ultimo = '\0';
        int i = 0;
        int n = linha.Length;
        if (sc.EmLiteralMultilinha)
        {
            int k = linha.IndexOf(sc.FechoLiteral, StringComparison.Ordinal);
            if (sc.LiteralVerbatim)
            {
                // procura " que não seja ""
                k = -1;
                for (int q = 0; q < n; q++)
                {
                    if (linha[q] == '"')
                    {
                        if (q + 1 < n && linha[q + 1] == '"') { q++; continue; }
                        k = q; break;
                    }
                }
                if (k < 0) return '\0';
                sc.EmLiteralMultilinha = false;
                i = k + 1;
                ultimo = '"';
            }
            else
            {
                if (k < 0) return '\0';
                sc.EmLiteralMultilinha = false;
                i = k + sc.FechoLiteral.Length;
                while (i < n && linha[i] == '"') i++;
                ultimo = '"';
            }
        }
        while (i < n)
        {
            char c = linha[i];
            if (sc.EmComentarioBloco)
            {
                int k = linha.IndexOf("*/", i, StringComparison.Ordinal);
                if (k < 0) return ultimo;
                sc.EmComentarioBloco = false;
                i = k + 2;
                continue;
            }
            if (c == '/' && i + 1 < n && linha[i + 1] == '/') break;
            if (c == '/' && i + 1 < n && linha[i + 1] == '*') { sc.EmComentarioBloco = true; i += 2; continue; }
            if (c == '"' || c == '\'' || ((c == '$' || c == '@') && i + 1 < n && (linha[i + 1] == '"' || linha[i + 1] == '$' || linha[i + 1] == '@')))
            {
                int ini = i;
                int fim = PularLiteral(linha, i, out bool fechou);
                if (!fechou)
                {
                    // literal que atravessa a linha: verbatim @"..." ou raw """..."""
                    int j = ini;
                    bool verb = false;
                    while (j < n && (linha[j] == '$' || linha[j] == '@')) { if (linha[j] == '@') verb = true; j++; }
                    int aspas = 0;
                    while (j + aspas < n && linha[j + aspas] == '"') aspas++;
                    if (aspas >= 3) { sc.EmLiteralMultilinha = true; sc.FechoLiteral = new string('"', aspas); sc.LiteralVerbatim = false; }
                    else if (verb) { sc.EmLiteralMultilinha = true; sc.FechoLiteral = "\""; sc.LiteralVerbatim = true; }
                    return '"';
                }
                i = fim;
                ultimo = '"';
                continue;
            }
            if (c == '{') sc.Profundidade++;
            else if (c == '}') sc.Profundidade--;
            if (!char.IsWhiteSpace(c)) ultimo = c;
            i++;
        }
        return ultimo;
    }

    private static bool LinhaNeutra(string t) =>
        t.Length == 0 || t.StartsWith("//") || t.StartsWith("#") || t.StartsWith("/*") || t.StartsWith("*");

    /// <summary>Linha que só tem atributo(s): [Flags], [ApiController], [HttpGet("x")]…</summary>
    private static bool LinhaDeAtributo(string t) => t.StartsWith("[") && t.EndsWith("]");

    /// <summary>Fatia um trecho em pedaços de topo.</summary>
    public static List<Pedaco> Fatiar(string cod)
    {
        var linhas = cod.Replace("\r\n", "\n").Split('\n');
        var pedacos = new List<Pedaco>();
        var atual = new List<string>();
        int inicioAtual = 0;
        var sc = new Scanner();

        for (int li = 0; li < linhas.Length; li++)
        {
            string linha = linhas[li];
            if (atual.Count == 0) inicioAtual = li;
            bool estavaEmLiteral = sc.EmLiteralMultilinha || sc.EmComentarioBloco;
            atual.Add(linha);
            char ultimo = AnalisarLinha(linha, sc);
            if (sc.EmLiteralMultilinha || sc.EmComentarioBloco) continue;
            if (sc.Profundidade != 0) continue;
            if (ultimo != ';' && ultimo != '}') continue;
            // olha a próxima linha significativa: continuação do mesmo comando?
            string prox = "";
            for (int k = li + 1; k < linhas.Length; k++)
            {
                var t = linhas[k].Trim();
                if (t.Length == 0 || t.StartsWith("//")) continue;
                prox = t;
                break;
            }
            if (ultimo == '}' && Regex.IsMatch(prox, @"^(else|catch|finally|while)\b")) continue;
            if (ultimo == '}' && (prox.StartsWith(".") || prox.StartsWith(")") || prox.StartsWith(",") || prox.StartsWith(";"))) continue;
            _ = estavaEmLiteral;
            pedacos.Add(Classificar(atual, inicioAtual));
            atual = new List<string>();
        }
        if (atual.Count > 0)
        {
            if (atual.All(l => l.Trim().Length == 0) && pedacos.Count > 0)
            {
                // só linhas em branco no fim: descarta
            }
            else pedacos.Add(Classificar(atual, inicioAtual));
        }
        return pedacos;
    }

    private static Pedaco Classificar(List<string> linhas, int inicio)
    {
        string primeira = "";
        foreach (var l in linhas)
        {
            var t = l.Trim();
            if (LinhaNeutra(t)) continue;
            if (LinhaDeAtributo(t)) continue;
            primeira = t;
            break;
        }
        TipoPedaco tipo;
        if (ReUsing().IsMatch(primeira) || ReUsingAlias().IsMatch(primeira)) tipo = TipoPedaco.Using;
        else if (ReNamespaceArquivo().IsMatch(primeira)) tipo = TipoPedaco.Namespace;
        else if (ReNamespaceBloco().IsMatch(primeira) || ReTipo().IsMatch(primeira) || ReRecord().IsMatch(primeira)) tipo = TipoPedaco.Tipo;
        else tipo = TipoPedaco.Comando;
        return new Pedaco(tipo, new List<string>(linhas), inicio);
    }

    public const string Marca = "\u001e";

    /// <summary>
    /// Monta o programa dos trechos na ordem. Com <paramref name="marcas"/>, insere antes dos
    /// comandos de cada trecho um Console.Out.Write com uma marca, para separar a saída por trecho.
    /// </summary>
    public static ProgramaMontado Montar(IReadOnlyList<string> trechos, bool marcas = false)
    {
        var usings = new List<(string texto, LinhaOrigem o)>();
        var vistos = new HashSet<string>();
        var comandos = new List<(string texto, LinhaOrigem o)>();
        var tipos = new List<(string texto, LinhaOrigem o)>();
        var pm = new ProgramaMontado();

        for (int t = 0; t < trechos.Count; t++)
        {
            var pedacos = Fatiar(trechos[t]);
            string? nsArquivo = null;
            bool abriuNs = false;
            if (marcas)
                comandos.Add(($"global::System.Console.Out.Write(\"{Marca}#{t}{Marca}\");", new LinhaOrigem(-1, -1)));
            foreach (var p in pedacos)
            {
                switch (p.Tipo)
                {
                    case TipoPedaco.Using:
                        for (int i = 0; i < p.Linhas.Count; i++)
                        {
                            var tx = p.Linhas[i].Trim();
                            if (tx.Length == 0) continue;
                            var chave = Regex.Replace(tx, @"\s*//.*$", "");
                            if (vistos.Add(chave)) usings.Add((tx, new LinhaOrigem(t, p.LinhaInicial + i)));
                        }
                        break;
                    case TipoPedaco.Namespace:
                        if (abriuNs) tipos.Add(("}", new LinhaOrigem(t, p.LinhaInicial)));
                        var linhaNs = p.Linhas.First(l => l.Trim().StartsWith("namespace")).Trim();
                        nsArquivo = linhaNs[..linhaNs.LastIndexOf(';')].Trim();
                        tipos.Add((nsArquivo, new LinhaOrigem(t, p.LinhaInicial)));
                        tipos.Add(("{", new LinhaOrigem(t, p.LinhaInicial)));
                        abriuNs = true;
                        break;
                    case TipoPedaco.Tipo:
                        for (int i = 0; i < p.Linhas.Count; i++)
                            tipos.Add((p.Linhas[i], new LinhaOrigem(t, p.LinhaInicial + i)));
                        break;
                    case TipoPedaco.Comando:
                        if (p.Linhas.Any(l => !LinhaNeutra(l.Trim()))) pm.TemComandos = true;
                        if (abriuNs)
                        {
                            // comando depois de namespace de arquivo: deixa no lugar (vai dar erro, de propósito)
                            for (int i = 0; i < p.Linhas.Count; i++)
                                tipos.Add((p.Linhas[i], new LinhaOrigem(t, p.LinhaInicial + i)));
                        }
                        else
                        {
                            for (int i = 0; i < p.Linhas.Count; i++)
                                comandos.Add((p.Linhas[i], new LinhaOrigem(t, p.LinhaInicial + i)));
                        }
                        break;
                }
            }
            if (abriuNs) tipos.Add(("}", new LinhaOrigem(t, -1)));
            if (ReMainClassico().IsMatch(trechos[t])) pm.TemMainClassico = true;
        }

        var sb = new StringBuilder();
        void Add(string texto, LinhaOrigem o)
        {
            sb.Append(texto).Append('\n');
            pm.Origem.Add(o);
        }
        foreach (var (tx, o) in usings) Add(tx, o);
        if (usings.Count > 0) Add("", new LinhaOrigem(-1, -1));
        foreach (var (tx, o) in comandos) Add(tx, o);
        if (comandos.Count > 0 && tipos.Count > 0) Add("", new LinhaOrigem(-1, -1));
        foreach (var (tx, o) in tipos) Add(tx, o);
        pm.Codigo = sb.ToString();
        return pm;
    }
}
