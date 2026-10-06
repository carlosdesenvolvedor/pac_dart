using System.Collections.Immutable;
using System.Reflection;
using System.Text;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.Diagnostics;

namespace PacLab;

/// <summary>Como o código de uma trilha é compilado/rodado.</summary>
public sealed record Perfil(
    string Nome,
    bool AceitaComandos,
    bool Roda,
    string[] UsingsGlobais,
    NullableContextOptions Nullable,
    LanguageVersion Versao,
    bool Unity,
    string Descricao);

public static class Perfis
{
    static readonly string[] UsingsConsole =
    [
        "System", "System.Collections.Generic", "System.IO", "System.Linq", "System.Net.Http",
        "System.Threading", "System.Threading.Tasks",
    ];

    static readonly string[] UsingsWeb =
    [
        .. UsingsConsole, "System.Net.Http.Json", "Microsoft.AspNetCore.Builder", "Microsoft.AspNetCore.Hosting",
        "Microsoft.AspNetCore.Http", "Microsoft.AspNetCore.Routing", "Microsoft.Extensions.Configuration",
        "Microsoft.Extensions.DependencyInjection", "Microsoft.Extensions.Hosting", "Microsoft.Extensions.Logging",
    ];

    public static readonly string[] Nomes = ["console", "web", "testes", "biblioteca", "unity", "godot", "monogame"];

    public static Perfil Obter(string nome) => nome switch
    {
        "console" => new("console", true, true, UsingsConsole, NullableContextOptions.Enable, LanguageVersion.CSharp14, false,
            "dotnet new console (.NET 10, C# 14, ImplicitUsings e Nullable ligados) — roda e confere a saída"),
        "web" => new("web", true, false, UsingsWeb, NullableContextOptions.Enable, LanguageVersion.CSharp14, false,
            "dotnet new web (ASP.NET Core .NET 10) — só compila"),
        "testes" => new("testes", false, false, [.. UsingsConsole, "Xunit"], NullableContextOptions.Enable, LanguageVersion.CSharp14, false,
            "dotnet new xunit (xUnit 2.9 + global using Xunit) — biblioteca, só compila"),
        "biblioteca" => new("biblioteca", false, false, UsingsConsole, NullableContextOptions.Enable, LanguageVersion.CSharp14, false,
            "dotnet new classlib — só tipos, só compila"),
        "unity" => new("unity", false, false, [], NullableContextOptions.Disable, LanguageVersion.CSharp9, true,
            "script do Unity 6 (C# 9, sem ImplicitUsings, sem Nullable) — compila contra um stub do UnityEngine"),
        "godot" => new("godot", false, false, [], NullableContextOptions.Disable, LanguageVersion.CSharp12, false,
            "script C# do Godot 4 (GodotSharp, sem ImplicitUsings) — só compila"),
        "monogame" => new("monogame", true, false, [], NullableContextOptions.Disable, LanguageVersion.CSharp12, false,
            "projeto MonoGame DesktopGL (sem ImplicitUsings) — só compila"),
        _ => throw new ArgumentException($"perfil desconhecido: {nome}"),
    };
}

public sealed record Diag(string Id, string Mensagem, int Linha, int Coluna, bool Erro);

public sealed record ResultadoCompilacao(List<Diag> Erros, List<Diag> Avisos, byte[]? Imagem)
{
    public bool Ok => Erros.Count == 0 && Avisos.Count == 0;
}

public static class Compilador
{
    /// <summary>Avisos tolerados (código de exercício é pedaço de programa).</summary>
    public static readonly HashSet<string> AvisosTolerados =
    [
        "CS0168", // variável declarada e não usada
        "CS0219", // variável atribuída e não usada
        "CS8321", // função local não usada
        "CS0169", // campo não usado
        "CS0414", // campo atribuído e não usado
        "CS0649", // campo nunca atribuído (inspector do Unity)
        "CS0067", // evento nunca usado
        "CS0162", // código inalcançável
        "CS1591", // falta comentário XML
        "CS0105", // using repetido
    ];

    static readonly Lazy<ImmutableArray<MetadataReference>> RefsBase = new(() =>
    {
        var tpa = ((string?)AppContext.GetData("TRUSTED_PLATFORM_ASSEMBLIES") ?? "").Split(Path.PathSeparator,
            StringSplitOptions.RemoveEmptyEntries);
        var fora = new[] { "Lab.dll", "Microsoft.CodeAnalysis" };
        return tpa
            .Where(p => p.EndsWith(".dll", StringComparison.OrdinalIgnoreCase))
            .Where(p => !fora.Any(f => Path.GetFileName(p).StartsWith(f, StringComparison.Ordinal)))
            .Select(p => (MetadataReference)MetadataReference.CreateFromFile(p))
            .ToImmutableArray();
    });

    /// <summary>API do .NET Standard 2.1 — é o que os scripts do Unity 6 enxergam da BCL
    /// (nada de PriorityQueue, Random.Shared, Random.Shuffle…).</summary>
    static readonly Lazy<ImmutableArray<MetadataReference>> RefsNetStandard = new(() =>
    {
        var dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            ".nuget", "packages", "netstandard.library.ref", "2.1.0", "ref", "netstandard2.1");
        return Directory.GetFiles(dir, "*.dll").Select(p => (MetadataReference)MetadataReference.CreateFromFile(p)).ToImmutableArray();
    });

    static readonly Lazy<MetadataReference> RefUnity = new(() =>
    {
        var arq = Path.Combine(AppContext.BaseDirectory, "stubs", "UnityEngine.cs");
        var arvore = CSharpSyntaxTree.ParseText(File.ReadAllText(arq), new CSharpParseOptions(LanguageVersion.CSharp12));
        var comp = CSharpCompilation.Create("UnityEngine", [arvore], RefsNetStandard.Value,
            new CSharpCompilationOptions(OutputKind.DynamicallyLinkedLibrary, nullableContextOptions: NullableContextOptions.Disable));
        using var ms = new MemoryStream();
        var r = comp.Emit(ms);
        if (!r.Success)
        {
            var erros = string.Join("\n", r.Diagnostics.Where(d => d.Severity == DiagnosticSeverity.Error).Take(20));
            throw new InvalidOperationException("stub do UnityEngine não compila:\n" + erros);
        }
        return MetadataReference.CreateFromImage(ms.ToArray());
    });

    /// <summary>Carrega dlls de analisador/gerador (Godot.SourceGenerators).</summary>
    sealed class CarregadorAnalisador : IAnalyzerAssemblyLoader
    {
        public void AddDependencyLocation(string fullPath) { }
        public Assembly LoadFromPath(string fullPath) => Assembly.LoadFrom(fullPath);
    }

    /// <summary>Propriedades de MSBuild que os geradores do Godot leem (projeto fictício).</summary>
    sealed class OpcoesGodot : AnalyzerConfigOptionsProvider
    {
        sealed class Opcoes(Dictionary<string, string> d) : AnalyzerConfigOptions
        {
            public override bool TryGetValue(string key, out string value)
            {
                if (d.TryGetValue(key, out var v)) { value = v; return true; }
                value = "";
                return false;
            }
        }

        static readonly Opcoes Globais = new(new()
        {
            ["build_property.GodotProjectDir"] = "/godot/projeto/",
            ["build_property.GodotProjectDirBase64"] = Convert.ToBase64String(Encoding.UTF8.GetBytes("/godot/projeto/")),
            ["build_property.GodotSourceGenerators"] = "",
            ["build_property.GodotDisabledSourceGenerators"] = "",
            ["build_property.IsGodotToolsProject"] = "false",
        });
        static readonly Opcoes Vazias = new(new());
        public override AnalyzerConfigOptions GlobalOptions => Globais;
        public override AnalyzerConfigOptions GetOptions(SyntaxTree tree) => Vazias;
        public override AnalyzerConfigOptions GetOptions(AdditionalText textFile) => Vazias;
    }

    static readonly Lazy<ImmutableArray<ISourceGenerator>> GeradoresGodot = new(() =>
    {
        var raiz = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".nuget", "packages", "godot.sourcegenerators");
        var dll = Directory.GetFiles(raiz, "Godot.SourceGenerators.dll", SearchOption.AllDirectories).OrderByDescending(x => x).First();
        var r = new AnalyzerFileReference(dll, new CarregadorAnalisador());
        return r.GetGenerators(LanguageNames.CSharp).ToImmutableArray();
    });

    public static ResultadoCompilacao Compilar(string codigo, Perfil perfil, bool executavel, bool emitir,
        IEnumerable<string>? permitir = null)
    {
        var parse = new CSharpParseOptions(perfil.Versao);
        var arvores = new List<SyntaxTree>
        {
            CSharpSyntaxTree.ParseText(codigo, parse, path: perfil.Nome == "godot" ? "/godot/projeto/Script.cs" : "Program.cs",
                encoding: Encoding.UTF8),
        };
        if (perfil.UsingsGlobais.Length > 0)
        {
            var g = string.Join("\n", perfil.UsingsGlobais.Select(u => $"global using global::{u};"));
            arvores.Add(CSharpSyntaxTree.ParseText(g, parse, path: "GlobalUsings.g.cs"));
        }
        var opcoes = new CSharpCompilationOptions(
            executavel ? OutputKind.ConsoleApplication : OutputKind.DynamicallyLinkedLibrary,
            nullableContextOptions: perfil.Nullable,
            allowUnsafe: true,
            optimizationLevel: OptimizationLevel.Debug);
        var refs = perfil.Unity ? RefsNetStandard.Value.Add(RefUnity.Value) : RefsBase.Value;
        var comp = CSharpCompilation.Create("Programa", arvores, refs, opcoes);
        var diagsGeradores = ImmutableArray<Diagnostic>.Empty;
        if (perfil.Nome == "godot")
        {
            // scripts do Godot 4 dependem dos geradores ([Signal] → SignalName, [Export]…)
            var driver = CSharpGeneratorDriver.Create(GeradoresGodot.Value, parseOptions: parse, optionsProvider: new OpcoesGodot());
            driver.RunGeneratorsAndUpdateCompilation(comp, out var comp2, out diagsGeradores);
            comp = (CSharpCompilation)comp2;
        }

        IEnumerable<Diagnostic> diags;
        byte[]? imagem = null;
        if (emitir)
        {
            using var ms = new MemoryStream();
            var r = comp.Emit(ms);
            diags = r.Diagnostics;
            if (r.Success) imagem = ms.ToArray();
        }
        else diags = comp.GetDiagnostics();
        diags = diags.Concat(diagsGeradores);

        var tolerados = new HashSet<string>(AvisosTolerados);
        if (permitir != null) foreach (var p in permitir) tolerados.Add(p);

        var erros = new List<Diag>();
        var avisos = new List<Diag>();
        foreach (var d in diags)
        {
            if (d.Location.SourceTree?.FilePath == "GlobalUsings.g.cs" && d.Severity != DiagnosticSeverity.Error) continue;
            // aviso dentro de código gerado (Godot) não é do exercício
            if (d.Location.SourceTree != null && d.Location.SourceTree.FilePath.EndsWith(".g.cs") && d.Severity != DiagnosticSeverity.Error) continue;
            var pos = d.Location.GetLineSpan().StartLinePosition;
            var diag = new Diag(d.Id, d.GetMessage(System.Globalization.CultureInfo.GetCultureInfo("pt-BR")), pos.Line, pos.Character,
                d.Severity == DiagnosticSeverity.Error);
            if (d.Severity == DiagnosticSeverity.Error) erros.Add(diag);
            else if (d.Severity == DiagnosticSeverity.Warning && !d.IsSuppressed && !tolerados.Contains(d.Id)) avisos.Add(diag);
        }
        return new ResultadoCompilacao(erros, avisos, imagem);
    }

    /// <summary>Aquece o compilador (a 1ª compilação é lenta).</summary>
    public static void Aquecer() => Compilar("System.Console.WriteLine(1);", Perfis.Obter("console"), true, false);
}
