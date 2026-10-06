using System.Diagnostics;
using System.Globalization;
using System.Reflection;
using System.Runtime.Loader;
using System.Text;

namespace PacLab;

public sealed record Execucao(int Codigo, string Saida, string Erro, bool Estourou, long Ms)
{
    public bool Ok => Codigo == 0 && !Estourou;
}

public static class Executor
{
    static readonly SemaphoreSlim Vagas = new(Math.Max(2, Environment.ProcessorCount / 3));

    static string PastaRun
    {
        get
        {
            var p = Environment.GetEnvironmentVariable("PACLAB_RUN") ?? Path.Combine(AppContext.BaseDirectory, "run");
            Directory.CreateDirectory(p);
            return p;
        }
    }

    /// <summary>Roda a imagem num processo filho (com timeout e entrada), em pasta temporária própria.</summary>
    public static async Task<Execucao> Rodar(byte[] imagem, string? entrada, int timeoutMs = 10000)
    {
        await Vagas.WaitAsync();
        var dir = Path.Combine(PastaRun, Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        try
        {
            var dll = Path.Combine(dir, "Programa.dll");
            await File.WriteAllBytesAsync(dll, imagem);
            var psi = new ProcessStartInfo(Environment.ProcessPath!)
            {
                RedirectStandardInput = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                WorkingDirectory = dir,
                StandardOutputEncoding = new UTF8Encoding(false),
                StandardErrorEncoding = new UTF8Encoding(false),
                UseShellExecute = false,
            };
            psi.ArgumentList.Add(typeof(Executor).Assembly.Location);
            psi.ArgumentList.Add("--rodar");
            psi.ArgumentList.Add(dll);
            psi.Environment["TZ"] = "America/Sao_Paulo";
            psi.Environment["LANG"] = "pt_BR.UTF-8";
            psi.Environment["DOTNET_CLI_TELEMETRY_OPTOUT"] = "1";
            var sw = Stopwatch.StartNew();
            using var p = Process.Start(psi)!;
            bool cortou = false;
            var tOut = Task.Run(async () =>
            {
                // lê com teto: programa que imprime sem parar é morto ao passar de 1 MB
                var sb = new StringBuilder();
                var buf = new char[8192];
                int n;
                while ((n = await p.StandardOutput.ReadAsync(buf, 0, buf.Length)) > 0)
                {
                    if (sb.Length < 1_000_000) sb.Append(buf, 0, n);
                    else if (!cortou) { cortou = true; try { p.Kill(true); } catch { } }
                }
                return sb.ToString();
            });
            var tErr = p.StandardError.ReadToEndAsync();
            try
            {
                if (!string.IsNullOrEmpty(entrada)) await p.StandardInput.WriteAsync(entrada);
                p.StandardInput.Close();
            }
            catch (IOException) { }
            bool estourou = false;
            using (var cts = new CancellationTokenSource(timeoutMs))
            {
                try { await p.WaitForExitAsync(cts.Token); }
                catch (OperationCanceledException)
                {
                    estourou = true;
                    try { p.Kill(true); } catch { }
                    try { await p.WaitForExitAsync(); } catch { }
                }
            }
            var saida = await tOut;
            var erro = await tErr;
            if (cortou) estourou = true;
            if (saida.Length > 200_000) saida = saida[..200_000] + "\n[saída cortada]";
            return new Execucao(estourou ? -1 : p.ExitCode, saida.Replace("\r\n", "\n"), erro, estourou, sw.ElapsedMilliseconds);
        }
        finally
        {
            try { Directory.Delete(dir, true); } catch { }
            Vagas.Release();
        }
    }

    /// <summary>Modo filho: carrega a dll e chama o ponto de entrada com cultura pt-BR.</summary>
    public static int RodarAqui(string dll)
    {
        var cult = new CultureInfo("pt-BR");
        CultureInfo.DefaultThreadCurrentCulture = cult;
        CultureInfo.DefaultThreadCurrentUICulture = cult;
        CultureInfo.CurrentCulture = cult;
        CultureInfo.CurrentUICulture = cult;
        Console.OutputEncoding = new UTF8Encoding(false);
        var asm = AssemblyLoadContext.Default.LoadFromAssemblyPath(dll);
        var ep = asm.EntryPoint;
        if (ep == null)
        {
            Console.Error.WriteLine("SEM_PONTO_DE_ENTRADA");
            return 4;
        }
        try
        {
            object?[]? a = ep.GetParameters().Length == 1 ? [Array.Empty<string>()] : null;
            var r = ep.Invoke(null, a);
            if (r is Task t) t.GetAwaiter().GetResult();
            Console.Out.Flush();
            if (r is int codigo) return codigo;
            if (r is Task<int> ti) return ti.Result;
            return 0;
        }
        catch (TargetInvocationException e) when (e.InnerException != null)
        {
            Console.Out.Flush();
            var ex = e.InnerException is AggregateException ag && ag.InnerException != null ? ag.InnerException : e.InnerException;
            Console.Error.WriteLine($"EXCECAO: {ex.GetType().Name}: {ex.Message}");
            return 3;
        }
        catch (Exception e)
        {
            Console.Out.Flush();
            Console.Error.WriteLine($"EXCECAO: {e.GetType().Name}: {e.Message}");
            return 3;
        }
    }
}
