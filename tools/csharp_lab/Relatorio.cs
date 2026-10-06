using System.Collections.Concurrent;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Unicode;

namespace PacLab;

public sealed class Relatorio
{
    readonly ConcurrentQueue<(int ordem, string nivel, string onde, string msg)> _itens = new();
    int _seq;
    public int Preenchidas;
    public int Corrigidas;
    public int Licoes, Trechos, Projetos, Desafios, Blocos;

    public int Erros => _itens.Count(i => i.nivel == "ERRO");
    public int Avisos => _itens.Count(i => i.nivel == "AVISO");

    public void Erro(string onde, string msg) => _itens.Enqueue((Interlocked.Increment(ref _seq), "ERRO", onde, msg));
    public void Aviso(string onde, string msg) => _itens.Enqueue((Interlocked.Increment(ref _seq), "AVISO", onde, msg));

    public string Texto(int limite = int.MaxValue)
    {
        var sb = new StringBuilder();
        var ordenados = _itens.OrderBy(i => i.nivel == "ERRO" ? 0 : 1).ThenBy(i => i.onde, StringComparer.Ordinal).ThenBy(i => i.ordem).ToList();
        int n = 0;
        foreach (var (_, nivel, onde, msg) in ordenados)
        {
            if (n++ >= limite)
            {
                sb.AppendLine($"... e mais {ordenados.Count - limite} itens (veja o relatório completo)");
                break;
            }
            sb.AppendLine($"[{nivel}] {onde}: {msg}");
        }
        sb.AppendLine($"== {Licoes} lições, {Trechos} trechos, {Projetos} projetos, {Desafios} desafios, {Blocos} blocos de teoria · " +
                      $"{Erros} erro(s), {Avisos} aviso(s) · saídas preenchidas: {Preenchidas} · respostas corrigidas: {Corrigidas}");
        sb.AppendLine(Erros == 0 ? "RESULTADO: OK (sem erros)" : "RESULTADO: FALHOU (corrija os erros e rode de novo)");
        return sb.ToString();
    }
}

public static class Json
{
    public static readonly JsonSerializerOptions Opcoes = new()
    {
        WriteIndented = true,
        Encoder = JavaScriptEncoder.Create(UnicodeRanges.All),
    };

    public static JsonNode Ler(string arq) => JsonNode.Parse(File.ReadAllText(arq),
        documentOptions: new JsonDocumentOptions { AllowTrailingCommas = false, CommentHandling = JsonCommentHandling.Disallow })!;

    public static void Gravar(string arq, JsonNode no)
    {
        var tmp = arq + ".tmp";
        File.WriteAllText(tmp, no.ToJsonString(Opcoes) + "\n", new UTF8Encoding(false));
        File.Move(tmp, arq, true);
    }

    public static string? Str(JsonNode? n, string campo)
    {
        if (n is not JsonObject o || !o.TryGetPropertyValue(campo, out var v) || v is null) return null;
        return v is JsonValue jv && jv.TryGetValue<string>(out var s) ? s : null;
    }

    public static int? Int(JsonNode? n, string campo)
    {
        if (n is not JsonObject o || !o.TryGetPropertyValue(campo, out var v) || v is null) return null;
        return v is JsonValue jv && jv.TryGetValue<int>(out var i) ? i : null;
    }

    public static List<string> Strs(JsonNode? n, string campo)
    {
        if (n is not JsonObject o || !o.TryGetPropertyValue(campo, out var v) || v is not JsonArray a) return [];
        return a.Select(x => x is JsonValue jv && jv.TryGetValue<string>(out var s) ? s : "").ToList();
    }
}
