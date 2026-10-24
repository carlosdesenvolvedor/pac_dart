import '../../../arcade/domain/historia_turismo.dart';
import '../../../curso/domain/curriculo.dart';
import '../baralhos.dart' show chaveDaFrase;

/// 📺 A historinha de uma lição, no "Escutar assistindo" do 🎧 Ouvir: o modelo (Dart puro), o parse do JSON
/// de uma trilha (`assets/ingles/historias/<slug>.json`, plano §16) e o validador (regras L-* da §5.3).
///
/// As falas com texto são as FRASES DA LIÇÃO (âncoras, pelo `Trecho.id`): o `en`/`pt` vem do currículo na
/// hora do parse, nunca do JSON. As ligações entre as frases são passos MUDOS (só atuação). O palco e a
/// [SimulacaoCena] são os do Turismo; o validador do Dart manda sobre o espelho em Python.

/// Os personagens canônicos que podem aparecer em qualquer lição (Max e Kim são só do Turismo).
const elencoDasLicoes = {'voce', 'mike', 'sarah', 'ana', 'ben', 'emma', 'lucas', 'julia', 'dra-lee'};

/// Os 39 papéis que falam no currículo (conferido em 24/out/2026; jack, fazendeiro e esposa são do conto
/// "Jack Hannaford") + 3 só para figurante mudo (D20).
/// Fonte única: o FigurantesHistoria (grupo B) tem uma aparência fixa para cada um destes.
const figurantesConhecidos = {
  'amigo-do-ben', 'atendente', 'caixa', 'cfo', 'cliente', 'colega', 'convidada', 'convidado', 'corretora',
  'desenvolvedora', 'dev-junior', 'dev-nova', 'dev-novo', 'dev-pleno', 'diretora', 'engenheira', 'engenheiro',
  'entrevistador', 'estagiaria', 'farmaceutica', 'gestora', 'guia', 'marido', 'moradora', 'motorista',
  'participante', 'passageira', 'passageiro', 'proprietario', 'recepcionista', 'recrutadora', 'seguranca',
  'stakeholder', 'supervisora', 'vendedor', 'vizinha', 'jack', 'fazendeiro', 'esposa',
  'oficial', 'garcom', 'vendedora'};

/// Figurantes que estão na cena sem falar nenhuma frase da lição (por lição, somando as cenas).
const maxFigurantesMudos = 2;

/// Mudos por história (somando as cenas); por cena valem os do Turismo (≤ 3, ≤ 2 seguidos).
const maxMudosPorHistoria = 4;

/// Tamanho máximo do `arco` da trilha (caracteres).
const maxArco = 300;

/// Cenários de corrida/espaço: só o Turismo usa.
const cenariosSoDoTurismo = {CenarioHistoria.boxes, CenarioHistoria.podio, CenarioHistoria.autodromo,
    CenarioHistoria.plataforma, CenarioHistoria.espaco, CenarioHistoria.lua, CenarioHistoria.marte,
    CenarioHistoria.estacao, CenarioHistoria.garagem};

/// Props de corrida/espaço: só o Turismo usa.
const propsSoDoTurismo = {PropHistoria.carro, PropHistoria.carroRival, PropHistoria.rodaDeOuro, PropHistoria.foguete,
    PropHistoria.capacete, PropHistoria.pneu, PropHistoria.trofeu, PropHistoria.medalha, PropHistoria.bandeira};

/// Ações de deslocamento: nunca numa âncora (a voz do Ouvir não espera a andança); vão num passo mudo.
const acoesQueDeslocam = {AcaoAtor.entra, AcaoAtor.anda, AcaoAtor.corre, AcaoAtor.dirige, AcaoAtor.desce, AcaoAtor.sai};

/// '', 'placa' e 'narradora' (a voz que conta os contos) → narrador; o resto como veio.
String quemNoPalco(String quem) => quem.isEmpty || quem == 'placa' || quem == 'narradora' ? narrador : quem;

/// A1→a1, A2→a2, B1→b1, B2/C1/DEV→b2 (pelo começo de `Trilha.etapa`).
NivelIngles nivelDaEtapa(String etapa) {
  final e = etapa.trim().toUpperCase();
  if (e.startsWith('A1')) return NivelIngles.a1;
  if (e.startsWith('A2')) return NivelIngles.a2;
  if (e.startsWith('B1')) return NivelIngles.b1;
  return NivelIngles.b2;
}

/// O slug da trilha de uma lição ('primeiro-contato.oi-tudo-bem' → 'primeiro-contato').
String slugDaLicao(String licaoId) {
  final i = licaoId.indexOf('.');
  return i > 0 ? licaoId.substring(0, i) : licaoId;
}

/// O slug de uma trilha do curso (o prefixo do id das lições).
String _slugDaTrilha(Trilha t) => t.licoes.isEmpty ? '' : slugDaLicao(t.licoes.first.id);

class HistoriaLicao {
  final String licaoId;
  final NivelIngles nivel;

  /// Obrigatório na autoral (o chip "✨ história especial"); a automática não tem.
  final TextoBilingue? titulo;

  /// As cenas, com as âncoras já com quem/en/pt do currículo.
  final List<CenaHistoria> cenas;

  /// `chaveDaFrase` → (cena, passo).
  final Map<String, (int, int)> ancoras;
  final bool autoral;

  const HistoriaLicao({
    required this.licaoId,
    required this.nivel,
    this.titulo,
    required this.cenas,
    required this.ancoras,
    required this.autoral,
  });

  /// Monta a partir das cenas já prontas (a automática usa isto): calcula [ancoras] pelas falas com texto
  /// na ordem, casando com os trechos da [licao] (falas com texto = trechos, na ordem).
  factory HistoriaLicao.daLicao(
    Licao licao,
    List<CenaHistoria> cenas, {
    required NivelIngles nivel,
    TextoBilingue? titulo,
    required bool autoral,
  }) {
    final ancoras = <String, (int, int)>{};
    var k = 0;
    for (var c = 0; c < cenas.length; c++) {
      final falas = cenas[c].falas;
      for (var p = 0; p < falas.length; p++) {
        if (falas[p].mudo) continue;
        if (k < licao.trechos.length) ancoras.putIfAbsent(chaveDaFrase(licao.trechos[k]), () => (c, p));
        k++;
      }
    }
    return HistoriaLicao(
      licaoId: licao.id,
      nivel: nivel,
      titulo: titulo,
      cenas: cenas,
      ancoras: ancoras,
      autoral: autoral,
    );
  }
}

class HistoriasDaTrilha {
  final int versao;
  final String trilha;
  final String? arco;
  final Map<String, HistoriaLicao> licoes;

  const HistoriasDaTrilha({required this.versao, required this.trilha, this.arco, required this.licoes});

  /// estrito=true: FormatException clara ("primeiro-contato.oi-tudo-bem cena[0] passo 3: frase 'f-x' desconhecida").
  /// estrito=false (app): lição com erro (de parse ou do [validarHistoriaLicao]) é descartada
  /// (aviso?.call(motivo)) e cai na automática. Erro no próprio arquivo (sem `licoes`, versão desconhecida)
  /// lança FormatException nos dois modos.
  factory HistoriasDaTrilha.fromJson(
    Map<String, dynamic> j, {
    required Trilha trilha,
    bool estrito = true,
    void Function(String motivo)? aviso,
  }) {
    _chaves(j, const {'versao', 'trilha', 'arco', 'licoes'}, 'arquivo', estrito);
    final versao = j['versao'];
    if (versao is! int) _erro('arquivo', "'versao' ausente ou não é inteiro");
    if (versao != 1) _erro('arquivo', 'versao $versao (esperava 1)');
    final slug = j['trilha'];
    if (slug is! String) _erro('arquivo', "'trilha' ausente ou não é texto");
    final arco = j['arco'];
    if (arco != null && arco is! String && estrito) _erro('arquivo', "'arco' não é texto");
    final brutas = _mapa(j['licoes'], "arquivo 'licoes'");
    final porId = {for (final l in trilha.licoes) l.id: l};
    final nivel = nivelDaEtapa(trilha.etapa);
    final licoes = <String, HistoriaLicao>{};
    for (final e in brutas.entries) {
      final lid = e.key;
      try {
        final licao = porId[lid];
        if (licao == null) _erro(lid, "não é lição da trilha '${_slugDaTrilha(trilha)}'");
        final h = _lerLicao(lid, _mapa(e.value, lid), licao, nivel, estrito);
        if (!estrito) {
          final erros = validarHistoriaLicao(h, licao);
          if (erros.isNotEmpty) _erro('', erros.first);
        }
        licoes[lid] = h;
      } on FormatException catch (x) {
        if (estrito) rethrow;
        aviso?.call('lição descartada: ${x.message}');
      }
    }
    return HistoriasDaTrilha(versao: versao, trilha: slug, arco: arco is String ? arco : null, licoes: licoes);
  }
}

// ───────────────────────────── parse ─────────────────────────────

Never _erro(String ctx, String msg) => throw FormatException(ctx.isEmpty ? msg : '$ctx: $msg');

void _chaves(Map<String, dynamic> j, Set<String> validas, String ctx, bool estrito, {String dica = ''}) {
  if (!estrito) return;
  for (final k in j.keys) {
    if (!validas.contains(k)) _erro(ctx, "chave '$k' desconhecida$dica");
  }
}

Map<String, dynamic> _mapa(Object? v, String ctx) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, x) => MapEntry('$k', x));
  _erro(ctx, 'esperava um objeto JSON');
}

List<Object?> _lista(Object? v, String ctx, String campo) {
  if (v is List) return v;
  _erro(ctx, v == null ? "'$campo' ausente" : "'$campo' não é uma lista");
}

T? _porNome<T extends Enum>(List<T> valores, Object? v) {
  if (v is! String) return null;
  for (final e in valores) {
    if (e.name == v) return e;
  }
  return null;
}

/// Reaproveita o parse do Turismo, com o lugar exato na mensagem.
T _comCtx<T>(String ctx, T Function() ler) {
  try {
    return ler();
  } on FormatException catch (e) {
    _erro(ctx, e.message);
  }
}

const _proibidosNaAncora = ['en', 'pt', 'pt_f', 'mudo'];

HistoriaLicao _lerLicao(String lid, Map<String, dynamic> j, Licao licao, NivelIngles nivel, bool estrito) {
  _chaves(j, const {'titulo', 'cenas'}, lid, estrito);
  TextoBilingue? titulo;
  final tj = j['titulo'];
  if (tj != null) {
    final t = _mapa(tj, '$lid titulo');
    _chaves(t, const {'en', 'pt'}, '$lid titulo', estrito);
    final en = t['en'], pt = t['pt'];
    if (en is! String || pt is! String) _erro('$lid titulo', "'en' e 'pt' têm de ser texto");
    titulo = TextoBilingue(en, pt);
  }
  final cenasJ = _lista(j['cenas'], lid, 'cenas');
  final trechos = {for (final t in licao.trechos) chaveDaFrase(t): t};
  final cenas = <CenaHistoria>[];
  final ancoras = <String, (int, int)>{};
  for (var ci = 0; ci < cenasJ.length; ci++) {
    final ctx = '$lid cena[$ci]';
    final cj = _mapa(cenasJ[ci], ctx);
    if (cj.containsKey('falas')) _erro(ctx, "chave 'falas' desconhecida (use 'passos', não 'falas')");
    _chaves(cj, const {'cenario', 'hora', 'clima', 'elenco', 'objetos', 'passos'}, ctx, estrito);
    final cenario = _porNome(CenarioHistoria.values, cj['cenario']) ??
        _erro(ctx, cj['cenario'] == null ? "'cenario' ausente" : "cenario '${cj['cenario']}' inválido");
    final hora = _porNome(HoraHistoria.values, cj['hora']) ??
        _erro(ctx, cj['hora'] == null ? "'hora' ausente" : "hora '${cj['hora']}' inválida");
    final clima = <ClimaHistoria>[];
    for (final v in cj['clima'] == null ? const <Object?>[] : _lista(cj['clima'], ctx, 'clima')) {
      final c = _porNome(ClimaHistoria.values, v);
      if (c != null) {
        clima.add(c);
      } else if (estrito) {
        _erro(ctx, "clima '$v' inválido");
      }
    }
    final elencoJ = cj['elenco'] == null ? const <Object?>[] : _lista(cj['elenco'], ctx, 'elenco');
    final objetosJ = cj['objetos'] == null ? const <Object?>[] : _lista(cj['objetos'], ctx, 'objetos');
    final passosJ = _lista(cj['passos'], ctx, 'passos');
    final elenco = [
      for (var i = 0; i < elencoJ.length; i++)
        _comCtx('$ctx elenco[$i]', () => AtorEmCena.fromJson(_mapa(elencoJ[i], '$ctx elenco[$i]'), estrito: estrito)),
    ];
    final objetos = [
      for (var i = 0; i < objetosJ.length; i++)
        _comCtx('$ctx objetos[$i]', () => ObjetoEmCena.fromJson(_mapa(objetosJ[i], '$ctx objetos[$i]'), estrito: estrito)),
    ];
    final passos = <FalaHistoria>[];
    for (var pi = 0; pi < passosJ.length; pi++) {
      final pc = '$ctx passo ${pi + 1}';
      final pj = Map<String, dynamic>.of(_mapa(passosJ[pi], pc));
      if (pj.containsKey('frase')) {
        // L-âncora: o texto vem do currículo
        for (final k in _proibidosNaAncora) {
          if (pj.containsKey(k)) _erro(pc, "âncora não leva '$k' (o texto vem do currículo)");
        }
        final fid = pj.remove('frase');
        final tr = trechos[fid];
        if (tr == null) _erro(pc, "frase '$fid' desconhecida");
        final q = quemNoPalco(tr.quem);
        final quemJ = pj['quem'];
        if (quemJ != null && quemJ != q) _erro(pc, "quem '$quemJ' não bate com o da frase ('$q')");
        pj
          ..['quem'] = q
          ..['en'] = tr.cod
          ..['pt'] = tr.dicaPlana;
        passos.add(_comCtx(pc, () => FalaHistoria.fromJson(pj, estrito: estrito)));
        ancoras.putIfAbsent(fid as String, () => (ci, passos.length - 1));
      } else if (pj['mudo'] == true) {
        passos.add(_comCtx(pc, () => FalaHistoria.fromJson(pj, estrito: estrito)));
      } else {
        // L-ligação
        _erro(pc, "fala sem 'frase': falas de ligação são só atuadas (mudo)");
      }
    }
    cenas.add(CenaHistoria(cenario: cenario, hora: hora, clima: clima, elenco: elenco, objetos: objetos, falas: passos));
  }
  return HistoriaLicao(licaoId: lid, nivel: nivel, titulo: titulo, cenas: cenas, ancoras: ancoras, autoral: true);
}

// ───────────────────────────── validação ─────────────────────────────

final _reTermos = [
  for (final t in termosProibidos)
    (t, RegExp('(?<![\\p{L}\\p{N}])${RegExp.escape(t)}(?![\\p{L}\\p{N}])', caseSensitive: false, unicode: true)),
];

/// [] = ok. Regras 5.3 (L-título, L-cobertura, L-âncora, L-ligação, L-cenas, L-cenário/props, L-elenco, L-base,
/// L-narrador). L-ligação e os campos proibidos da L-âncora são do parse (depois dele não se distingue o que
/// veio do JSON); aqui uma fala com texto que não é a de nenhuma frase da lição também é erro.
List<String> validarHistoriaLicao(HistoriaLicao h, Licao licao) {
  final erros = <String>[];
  final lid = h.licaoId;
  // L-título
  final tit = h.titulo;
  if (tit == null) {
    if (h.autoral) erros.add('$lid: titulo ausente (obrigatório na história autoral)');
  } else {
    final en = tit.en.trim();
    if (en.isEmpty || en.split(RegExp(r'\s+')).length > 6 || en.runes.any((r) => r > 127)) {
      erros.add('$lid: titulo.en tem de ter de 1 a 6 palavras, só ASCII');
    }
    for (final (termo, re) in _reTermos) {
      if (re.hasMatch(tit.en) || re.hasMatch(tit.pt)) erros.add("$lid: termo proibido '$termo' no título");
    }
    if (tit.pt.trim().isEmpty) erros.add('$lid: titulo.pt vazio');
  }
  // L-cenas
  if (h.cenas.isEmpty || h.cenas.length > 2) erros.add('$lid: de 1 a 2 cenas');

  final ordem = [for (final t in licao.trechos) chaveDaFrase(t)];
  final trechoDe = {for (final t in licao.trechos) chaveDaFrase(t): t};
  final falantes = {for (final t in licao.trechos) quemNoPalco(t.quem)};
  final temNarrador = falantes.contains(narrador);
  final permitidos = {...elencoDasLicoes, ...falantes, ...figurantesConhecidos}..remove(narrador);
  final porPasso = {for (final e in h.ancoras.entries) e.value: e.key};
  final vistas = <String>[];
  final figurantesMudos = <String>{};
  var mudos = 0;

  void propOk(PropHistoria? p, String onde) {
    if (p != null && propsSoDoTurismo.contains(p)) erros.add("$onde: prop '${p.name}' é só do Turismo");
  }

  for (var ci = 0; ci < h.cenas.length; ci++) {
    final cena = h.cenas[ci];
    final ctx = '$lid cena[$ci]';
    var ancorasNaCena = 0;
    // L-cenário/props
    if (cenariosSoDoTurismo.contains(cena.cenario)) erros.add("$ctx: cenário '${cena.cenario.name}' é só do Turismo");
    // L-elenco
    for (final a in cena.elenco) {
      if (a.quem == narrador) continue; // a base já acusa
      if (a.quem == 'max' || a.quem == 'kim') {
        erros.add("$ctx: '${a.quem}' é só do Turismo");
      } else if (!permitidos.contains(a.quem)) {
        erros.add("$ctx: '${a.quem}' não é do elenco das lições nem figurante conhecido");
      } else if (figurantesConhecidos.contains(a.quem) && !falantes.contains(a.quem)) {
        figurantesMudos.add(a.quem);
      }
      if (a.noCarro) erros.add('$ctx: noCarro é só do Turismo');
      propOk(a.segura, ctx);
    }
    for (final o in cena.objetos) {
      propOk(o.prop, ctx);
    }
    for (var pi = 0; pi < cena.falas.length; pi++) {
      final f = cena.falas[pi];
      final pc = '$ctx passo ${pi + 1}';
      final cen = f.cenario;
      if (cen != null && cenariosSoDoTurismo.contains(cen)) erros.add("$pc: cenário '${cen.name}' é só do Turismo");
      propOk(f.segura, pc);
      for (final r in f.reacoes) {
        propOk(r.segura, pc);
      }
      for (final m in f.objetos) {
        propOk(m.prop, pc);
      }
      if (f.mudo) {
        mudos++;
        continue;
      }
      ancorasNaCena++;
      // L-narrador
      if (f.ehNarrador && !temNarrador) erros.add('$pc: narrador só onde a frase é de placa');
      // L-âncora
      if (acoesQueDeslocam.contains(f.acao)) {
        erros.add("$pc: acao '${f.acao.name}' desloca: vai num passo mudo antes ou depois");
      }
      final chave = porPasso[(ci, pi)];
      final tr = chave == null ? null : trechoDe[chave];
      if (chave == null || tr == null) {
        // uma fala com texto que não é âncora: repetida, ou de fora da lição
        final igual = licao.trechos.where((t) => t.cod == f.en && quemNoPalco(t.quem) == f.quem).firstOrNull;
        if (igual != null) {
          vistas.add(chaveDaFrase(igual));
        } else {
          erros.add("$pc: fala sem 'frase': falas de ligação são só atuadas (mudo)");
        }
        continue;
      }
      vistas.add(chave);
      final q = quemNoPalco(tr.quem);
      if (f.quem != q) erros.add("$pc: quem '${f.quem}' não bate com o da frase ('$q')");
      if (f.en != tr.cod || f.pt != tr.dicaPlana) {
        erros.add("$pc: o texto não é o da frase '$chave' (a âncora puxa en/pt do currículo)");
      }
    }
    if (ancorasNaCena == 0) erros.add('$ctx: cena sem nenhuma âncora (frase)');
    // L-base
    validarCenaBase(ctx, cena, h.nivel, erros,
        personagens: {for (final a in cena.elenco) a.quem}..remove(narrador),
        validarTextos: false,
        rotuloPasso: 'passo');
  }
  if (mudos > maxMudosPorHistoria) erros.add('$lid: $mudos passos mudos (máx. $maxMudosPorHistoria na história)');
  if (figurantesMudos.length > maxFigurantesMudos) {
    final nomes = figurantesMudos.toList()..sort();
    erros.add('$lid: ${figurantesMudos.length} figurantes mudos (máx. $maxFigurantesMudos): ${nomes.join(', ')}');
  }
  // L-cobertura
  if (!_mesmaLista(vistas, ordem)) {
    final faltam = [for (final k in ordem) if (!vistas.contains(k)) k];
    final contagem = <String, int>{};
    for (final k in vistas) {
      contagem[k] = (contagem[k] ?? 0) + 1;
    }
    final repetidas = [for (final e in contagem.entries) if (e.value > 1) e.key]..sort();
    if (faltam.isNotEmpty) erros.add('$lid: frases faltando: ${faltam.join(', ')}');
    if (repetidas.isNotEmpty) erros.add('$lid: frases repetidas: ${repetidas.join(', ')}');
    if (faltam.isEmpty && repetidas.isEmpty) erros.add('$lid: frases fora da ordem da lição');
  }
  return erros;
}

bool _mesmaLista(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// L-arquivo + validarHistoriaLicao de cada lição. [avisos] recebe as lições sem história.
List<String> validarHistoriasDaTrilha(HistoriasDaTrilha h, Trilha trilha, {List<String>? avisos}) {
  final erros = <String>[];
  final slug = _slugDaTrilha(trilha);
  if (h.versao != 1) erros.add('arquivo: versao tem de ser 1');
  if (h.trilha != slug) erros.add("arquivo: trilha '${h.trilha}' diferente da trilha '$slug'");
  final arco = h.arco;
  if (arco != null && arco.length > maxArco) erros.add('arquivo: arco com ${arco.length} caracteres (máx. $maxArco)');
  final porId = {for (final l in trilha.licoes) l.id: l};
  for (final l in trilha.licoes) {
    if (!h.licoes.containsKey(l.id)) avisos?.add('${l.id}: sem história (trilha incompleta)');
  }
  for (final e in h.licoes.entries) {
    final licao = porId[e.key];
    if (licao == null) {
      erros.add("${e.key}: não é lição da trilha '$slug'");
      continue;
    }
    erros.addAll(validarHistoriaLicao(e.value, licao));
  }
  return erros;
}
