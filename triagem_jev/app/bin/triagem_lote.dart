// Triagem em lote (centenas ou milhares de estudos), fora do navegador: as mesmas peças do app
// (domínio + clientes que passam pelo Worker), com chamadas em paralelo e cache para retomar.
//
//   dart run bin/triagem_lote.dart --projeto dados.json --saida rodada/ \
//     --llm anthropic/claude-sonnet-5.5 --llm openai/gpt-6-luna --llm ollama/qwen2.5:7b
//
// O Jev roda em TODOS os estudos. Cada LLM também roda em TODOS, para medir "só LLM" de verdade;
// o cenário "Jev + LLM" é o subconjunto que o Jev encaminhou (incluídos e incertos), com as mesmas
// chamadas. Cada resposta bruta fica em <saida>/<modelo>.jsonl: rodar de novo só refaz o que falta.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:triagem_jev/features/triagem/data/cliente_decisao.dart';
import 'package:triagem_jev/features/triagem/data/cliente_llm.dart';
import 'package:triagem_jev/features/triagem/domain/config_triagem.dart';
import 'package:triagem_jev/features/triagem/domain/decisoes.dart';
import 'package:triagem_jev/features/triagem/domain/estudo.dart';
import 'package:triagem_jev/features/triagem/domain/metricas.dart';
import 'package:triagem_jev/features/triagem/domain/resultado_estudo.dart';

const _uso = '''
Uso: dart run bin/triagem_lote.dart --projeto <arquivo.json> --saida <pasta> [opções]
  --worker <url>        Worker (padrão http://localhost:8787)
  --decisao <modelo>    modelo de decisão (padrão typesafe/jev-1.14)
  --llm <modelo>        LLM a comparar (repita; ex.: ollama/qwen2.5:7b)
  --conc <n>            chamadas simultâneas por modelo de API (padrão 8)
  --conc-local <n>      chamadas simultâneas ao modelo local (padrão 1)
  --limite <n>          só os n primeiros estudos (para ensaiar)
  --excluir <p>         limite de exclusão (padrão 0.30)
  --incluir <p>         limite de inclusão (padrão 0.80)''';

Future<void> main(List<String> argv) async {
  final a = _Args(argv);
  final projetoPath = a.um('projeto'), saidaPath = a.um('saida');
  if (projetoPath == null || saidaPath == null) {
    stderr.writeln(_uso);
    exit(64);
  }
  final worker = Uri.parse(a.um('worker') ?? 'http://localhost:8787');
  final modeloDecisao = a.um('decisao') ?? 'typesafe/jev-1.14';
  final llms = a.todos('llm');
  final conc = int.parse(a.um('conc') ?? '8'), concLocal = int.parse(a.um('conc-local') ?? '1');
  final saida = Directory(saidaPath)..createSync(recursive: true);

  var projeto = ProjetoTriagem.fromJson(jsonDecode(File(projetoPath).readAsStringSync()) as Map<String, dynamic>);
  final limite = int.tryParse(a.um('limite') ?? '');
  final estudos = limite == null ? projeto.estudos : projeto.estudos.take(limite).toList();
  final precos = TabelaPrecos.fromJson(
    jsonDecode(File('assets/precos.json').readAsStringSync()) as Map<String, dynamic>,
  );
  final config = ConfigTriagem(
    limiteExcluir: double.parse(a.um('excluir') ?? '0.30'),
    limiteIncluir: double.parse(a.um('incluir') ?? '0.80'),
    modeloDecisao: modeloDecisao,
    precos: precos,
  );
  for (final m in [modeloDecisao, ...llms]) {
    if (!precos.conhece(m)) stderr.writeln('aviso: $m não está em assets/precos.json (custo 0)');
  }
  final ids = [for (final c in projeto.criterios) c.id];
  stdout.writeln('${estudos.length} estudos · ${projeto.criterios.length} critérios · decisão $modeloDecisao · LLMs $llms');

  // Etapa 1: modelo de decisão em todos.
  final cliDecisao = ClienteDecisaoOpenRouter(worker: worker, modelo: modeloDecisao);
  final ordem = const [Decisao.incluir, Decisao.excluir, Decisao.incerto];
  final decisoes = await _rodar<DecisaoModelo>(
    rotulo: modeloDecisao,
    arquivo: File('${saida.path}/${_slug(modeloDecisao)}.jsonl'),
    estudos: estudos,
    conc: conc,
    chamar: (e) => cliDecisao.decidir(e, projeto.criterios, ordemOpcoes: ordem).then((r) => (r.bruto, r.valor.uso.ms)),
    mapear: (e, bruto, ms) => ClienteDecisaoOpenRouter.mapearResposta(
      jsonDecode(bruto) as Map<String, dynamic>,
      e.id,
      modeloDecisao,
      ordem,
      ms,
      criterios: ids,
    ),
  );

  // Etapa 2: cada LLM em todos os estudos.
  final porLlm = <String, Map<String, _Feito<JustificativaLlm>>>{};
  for (final m in llms) {
    final cli = ClienteLlmOpenRouter(worker: worker, modelo: m);
    porLlm[m] = await _rodar<JustificativaLlm>(
      rotulo: m,
      arquivo: File('${saida.path}/${_slug(m)}.jsonl'),
      estudos: estudos,
      conc: m.startsWith('ollama/') ? concLocal : conc,
      chamar: (e) => cli.justificar(e, projeto.criterios).then((r) => (r.bruto, r.valor.uso.ms)),
      mapear: (e, bruto, ms) =>
          ClienteLlmOpenRouter.mapearResposta(jsonDecode(bruto) as Map<String, dynamic>, e.id, m, ms),
    );
  }

  // Resultados: o domínio do app calcula faixas e métricas, como na tela.
  ResultadoEstudo etapa1(Estudo e) {
    final d = decisoes[e.id];
    final v = d?.valor;
    final dec = v?.comCusto(precos.de(modeloDecisao).custo(v.uso.tokensEntrada, v.uso.tokensSaida));
    // Erro no modelo de decisão → incerto (segue para o pesquisador), como no app.
    return ResultadoEstudo(
      e,
      decisao: dec,
      faixa: dec == null ? Faixa.incerto : Faixa.de(dec.probInclusao, config),
      erro: d?.erro,
    );
  }

  final resultadosJev = [for (final e in estudos) etapa1(e)];
  final jevSozinho = Metricas.de(resultadosJev, (r) => r.faixa?.comoDecisao);
  final custoJev = resultadosJev.fold<double>(0, (s, r) => s + (r.decisao?.custo ?? 0));
  final msJev = resultadosJev.fold<int>(0, (s, r) => s + (r.decisao?.uso.ms ?? 0));
  final encaminhados = resultadosJev.where((r) => r.faixa!.vaiParaLlm).length;

  final cenarios = <Map<String, dynamic>>[
    {
      'cenario': 'jev',
      'modelo': modeloDecisao,
      'metricas': jevSozinho.toJson(),
      'custo_usd': custoJev,
      'tempo_ms_somado': msJev,
      'chamadas_llm': 0,
    },
  ];
  final porEstudoLlm = <String, Map<String, dynamic>>{for (final e in estudos) e.id: {}};
  for (final MapEntry(key: m, value: feitos) in porLlm.entries) {
    JustificativaLlm? j(String id) {
      final f = feitos[id]?.valor;
      return f?.comCusto(precos.de(m).custo(f.uso.tokensEntrada, f.uso.tokensSaida));
    }

    final soLlm = [for (final r in resultadosJev) ResultadoEstudo(r.estudo, justificativa: j(r.estudo.id))];
    // LLM que falhou num estudo → incerto (segue para o pesquisador).
    final mSo = Metricas.de(soLlm, (r) => r.justificativa?.decisaoSugerida ?? Decisao.incerto);
    final combinado = [
      for (final r in resultadosJev) r.faixa!.vaiParaLlm ? r.copyWith(justificativa: j(r.estudo.id)) : r,
    ];
    final mComb = Metricas.de(combinado, (r) => r.faixa!.vaiParaLlm ? (r.justificativa?.decisaoSugerida ?? Decisao.incerto) : Decisao.excluir);
    double custo(Iterable<ResultadoEstudo> rs) => rs.fold(0, (s, r) => s + (r.justificativa?.custo ?? 0));
    int ms(Iterable<ResultadoEstudo> rs) => rs.fold(0, (s, r) => s + (r.justificativa?.uso.ms ?? 0));
    final sub = combinado.where((r) => r.faixa!.vaiParaLlm);
    cenarios
      ..add({
        'cenario': 'so_llm',
        'modelo': m,
        'metricas': mSo.toJson(),
        'custo_usd': custo(soLlm),
        'tempo_ms_somado': ms(soLlm),
        'chamadas_llm': soLlm.where((r) => r.justificativa != null).length,
        'erros': feitos.values.where((f) => f.erro != null).length,
      })
      ..add({
        'cenario': 'jev_mais_llm',
        'modelo': m,
        'metricas': mComb.toJson(),
        'custo_usd': custoJev + custo(sub),
        'tempo_ms_somado': msJev + ms(sub),
        'chamadas_llm': sub.length,
      });
    for (final r in resultadosJev) {
      final f = feitos[r.estudo.id];
      porEstudoLlm[r.estudo.id]![m] = {
        'sugestao': f?.valor?.decisaoSugerida.name,
        'criterios': f?.valor?.criteriosAtendidos,
        'justificativa': f?.valor?.justificativa,
        'ms': f?.valor?.uso.ms,
        'custo_usd': j(r.estudo.id)?.custo,
        'inicio_ms': f?.inicio,
        if (f?.erro != null) 'erro': f!.erro,
      };
    }
  }

  final resultado = {
    'projeto': projeto.nome,
    'criterios': [for (final c in projeto.criterios) c.toJson()],
    'config': config.toJson(),
    'estudos': estudos.length,
    'encaminhados_ao_llm': encaminhados,
    'cenarios': cenarios,
    'por_estudo': [
      for (final r in resultadosJev)
        {
          'id': r.estudo.id,
          'titulo': r.estudo.titulo,
          'tipo_fonte': r.estudo.tipoFonte.name,
          'gabarito': r.estudo.gabarito?.name,
          'faixa': r.faixa?.name,
          'jev': r.decisao == null
              ? {'erro': r.erro}
              : {
                  'prob_inclusao': r.decisao!.probInclusao,
                  'escolha': r.decisao!.escolha.name,
                  'confianca': r.decisao!.confianca,
                  'nota': r.decisao!.notaEsperada,
                  'soma_likert': r.decisao!.somaLikert,
                  'por_criterio': [for (final c in r.decisao!.porCriterio) c.toJson()],
                  'ms': r.decisao!.uso.ms,
                  'tokens_entrada': r.decisao!.uso.tokensEntrada,
                  'custo_usd': r.decisao!.custo,
                  'inicio_ms': decisoes[r.estudo.id]?.inicio,
                },
          'llm': porEstudoLlm[r.estudo.id],
        },
    ],
  };
  File('${saida.path}/resultado.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(resultado));
  stdout.writeln('\nCenário | modelo | recall | precisão | custo US\$ | tempo somado');
  for (final c in cenarios) {
    final m = c['metricas'] as Map<String, dynamic>;
    String p(Object? v) => v == null ? '—' : '${((v as num) * 100).toStringAsFixed(1)}%';
    stdout.writeln(
      '${c['cenario']} | ${c['modelo']} | ${p(m['recall'])} | ${p(m['precisao'])} | '
      '${(c['custo_usd'] as double).toStringAsFixed(4)} | ${((c['tempo_ms_somado'] as int) / 60000).toStringAsFixed(1)} min',
    );
  }
  stdout.writeln('\nresultado em ${saida.path}/resultado.json');
  exit(0);
}

/// Uma chamada feita (ou lida do cache): resposta mapeada, ou o erro.
class _Feito<T> {
  final T? valor;
  final String? erro;
  final int? inicio;
  const _Feito(this.valor, this.erro, this.inicio);
}

/// Roda [chamar] em todos os estudos com [conc] chamadas simultâneas, gravando cada resposta bruta
/// numa linha de [arquivo]. O que já está no arquivo (sem erro) não é chamado de novo.
Future<Map<String, _Feito<T>>> _rodar<T>({
  required String rotulo,
  required File arquivo,
  required List<Estudo> estudos,
  required int conc,
  required Future<(String, int)> Function(Estudo) chamar,
  required T Function(Estudo, String bruto, int ms) mapear,
}) async {
  final feitos = <String, _Feito<T>>{};
  final porId = {for (final e in estudos) e.id: e};
  if (arquivo.existsSync()) {
    for (final linha in arquivo.readAsLinesSync().where((l) => l.trim().isNotEmpty)) {
      final j = jsonDecode(linha) as Map<String, dynamic>;
      final e = porId[j['id']];
      if (e == null || j['erro'] != null) continue;
      try {
        feitos[e.id] = _Feito(mapear(e, j['bruto'] as String, j['ms'] as int), null, j['inicio_ms'] as int?);
      } catch (_) {
        // Resposta guardada que não se lê mais: chama de novo.
      }
    }
  }
  final fila = [for (final e in estudos) if (!feitos.containsKey(e.id)) e];
  stdout.writeln('$rotulo: ${feitos.length} do cache, ${fila.length} a chamar ($conc por vez)');
  final saida = arquivo.openWrite(mode: FileMode.append);
  var feitosAgora = 0, erros = 0;
  final relogio = Stopwatch()..start();

  Future<void> trabalhador() async {
    while (fila.isNotEmpty) {
      final e = fila.removeLast();
      final inicio = DateTime.now().millisecondsSinceEpoch;
      String? erro;
      for (var tentativa = 0; tentativa < 4; tentativa++) {
        try {
          final (bruto, ms) = await chamar(e);
          feitos[e.id] = _Feito(mapear(e, bruto, ms), null, inicio);
          saida.writeln(jsonEncode({'id': e.id, 'inicio_ms': inicio, 'ms': ms, 'bruto': bruto}));
          erro = null;
          break;
        } catch (ex) {
          erro = '$ex';
          // Chave recusada, sem crédito ou pedido inválido não melhoram com nova tentativa.
          if (RegExp(r'Chave recusada|Sem crédito|HTTP 4(00|13)').hasMatch(erro)) break;
          await Future<void>.delayed(Duration(seconds: 2 << tentativa));
        }
      }
      if (erro != null) {
        erros++;
        feitos[e.id] = _Feito(null, erro, inicio);
        saida.writeln(jsonEncode({'id': e.id, 'inicio_ms': inicio, 'erro': erro}));
      }
      feitosAgora++;
      if (feitosAgora % 25 == 0 || fila.isEmpty) {
        stdout.writeln(
          '  $rotulo: ${feitos.length}/${estudos.length} · $erros erro(s) · ${(relogio.elapsedMilliseconds / 1000).toStringAsFixed(0)} s',
        );
      }
    }
  }

  await Future.wait([for (var i = 0; i < conc; i++) trabalhador()]);
  await saida.flush();
  await saida.close();
  return feitos;
}

String _slug(String modelo) => modelo.replaceAll(RegExp(r'[^a-zA-Z0-9.]+'), '_');

class _Args {
  final Map<String, List<String>> _v = {};
  _Args(List<String> argv) {
    for (var i = 0; i < argv.length - 1; i++) {
      if (argv[i].startsWith('--')) (_v[argv[i].substring(2)] ??= []).add(argv[++i]);
    }
  }
  String? um(String k) => _v[k]?.last;
  List<String> todos(String k) => _v[k] ?? const [];
}
