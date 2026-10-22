import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../curso/domain/curriculo.dart';
import '../../data/historias_licoes_repo.dart';
import '../fila_ouvir.dart';
import 'encenador_licao.dart';
import 'historia_licao.dart';

/// 📺 O serviço das historinhas: para cada faixa do 🎧 Ouvir, a história da lição dela — a autoral (se a
/// trilha já carregou e tem a lição com a âncora da faixa) ou a automática ([EncenadorLicao], memoizada por
/// lição, com a correção da tabela `encenacao_auto.json` quando ela já chegou).
///
/// Carregamento sob demanda (plano §6.9, I6): [preparar]/[prepararLicao] buscam o índice, a tabela e o
/// arquivo da trilha (e o da trilha seguinte) pelo [HistoriasLicoesRepo]; nunca lançam. Uma trilha que está
/// no índice e ainda não foi pedida começa a carregar sozinha (em segundo plano) quando [para] ou
/// [carregando] a encontram, para a autoral chegar na faixa seguinte.
///
/// Troca para a autoral na FRONTEIRA da faixa, nunca no meio: [para] fixa a história devolvida para cada
/// faixa (lição + `Faixa.chave`) entre as [_fixadasMax] faixas pedidas por último. Assim o palco pode chamar
/// [para] a cada emissão do Ouvir (e também para a faixa SEGUINTE, ao planejar o vão) sem a cena mudar no
/// meio da frase quando a autoral (ou a tabela) chega; uma faixa que saiu da lista recalcula na volta.
class HistoriasLicoes {
  HistoriasLicoes(this.trilhas, {this.bundle, this.timeout = const Duration(seconds: 8)});

  final List<Trilha> trilhas;

  /// O bundle dos assets (null = `rootBundle`); injetável nos testes.
  final AssetBundle? bundle;

  /// O tempo máximo para baixar o arquivo de uma trilha.
  final Duration timeout;

  static HistoriasLicoes? _ultimo;

  /// Memoizado por identical(trilhas).
  static HistoriasLicoes de(List<Trilha> trilhas) {
    final u = _ultimo;
    if (u != null && identical(u.trilhas, trilhas)) return u;
    return _ultimo = HistoriasLicoes(trilhas);
  }

  // ── o currículo indexado (só as trilhas do curso; a própria não tem desenho)
  Map<String, (Trilha, Licao)>? _porLicao;
  Map<String, Trilha>? _porSlug;
  List<String>? _slugs;

  // ── o que já chegou
  Map<String, int>? _indice;
  Map<String, EncenacaoManual>? _tabela;
  Future<void>? _base;
  Stopwatch? _desdeBase;

  /// O índice/tabela em voo há mais que [timeout] (a rede travou sem falhar): o palco não espera mais por ele
  /// e o próximo [preparar] tenta de novo.
  bool get _baseTravada => _base != null && (_desdeBase?.elapsed ?? Duration.zero) > timeout;
  final _autorais = <String, HistoriasDaTrilha>{};
  final _pedidos = <String, Future<void>>{};
  final _falhas = <String>{};
  final _automaticas = <String, HistoriaLicao>{};

  // ── as faixas fixadas (a mais recente por último): a mesma faixa devolve a mesma história
  static const _fixadasMax = 3;
  final _fixadas = <String, HistoriaLicao>{};

  void _indexar() {
    if (_porLicao != null) return;
    final porLicao = <String, (Trilha, Licao)>{};
    final porSlug = <String, Trilha>{};
    final slugs = <String>[];
    for (final t in trilhas) {
      if (t.propria || t.licoes.isEmpty) continue;
      final slug = slugDaLicao(t.licoes.first.id);
      if (slug.isNotEmpty && !porSlug.containsKey(slug)) {
        porSlug[slug] = t;
        slugs.add(slug);
      }
      for (final l in t.licoes) {
        if (l.id.isNotEmpty) porLicao.putIfAbsent(l.id, () => (t, l));
      }
    }
    _porLicao = porLicao;
    _porSlug = porSlug;
    _slugs = slugs;
  }

  (Trilha, Licao)? _licao(String licaoId) {
    _indexar();
    return _porLicao![licaoId];
  }

  /// A trilha seguinte do curso (a pré-carga), ou null.
  String? _proxima(String slug) {
    _indexar();
    final s = _slugs!;
    final i = s.indexOf(slug);
    return i < 0 || i + 1 >= s.length ? null : s[i + 1];
  }

  /// Síncrono: a autoral (se a trilha já carregou e tem a lição), senão a automática (memo por licaoId,
  /// com a EncenacaoManual se a tabela já carregou). null = faixa sem lição do curso ou trilha própria.
  HistoriaLicao? para(Faixa f) {
    if (f.licaoId.isEmpty) return null;
    final achou = _licao(f.licaoId);
    if (achou == null) return null;
    final k = '${f.licaoId}\n${f.chave}';
    final fixada = _fixadas.remove(k);
    if (fixada != null) return _fixadas[k] = fixada;
    final (trilha, licao) = achou;
    final slug = slugDaLicao(licao.id);
    _aoFundo(slug);
    final autoral = _autorais[slug]?.licoes[licao.id];
    // a faixa precisa ter âncora na autoral (frase nova no currículo → a automática da lição inteira)
    final h = autoral != null && autoral.ancoras.containsKey(f.chave)
        ? autoral
        : _automaticas[licao.id] ??= EncenadorLicao.encenar(licao, etapa: trilha.etapa, manual: _tabela?[licao.id]);
    if (_fixadas.length >= _fixadasMax) _fixadas.remove(_fixadas.keys.first);
    return _fixadas[k] = h;
  }

  /// 🎬 A cena da LIÇÃO (o palco da lição, não o Ouvir): a autoral se a trilha já chegou e tem a âncora
  /// [chave] (sem [chave], basta ter a lição); senão a automática (memo por lição). Só leitura: não fixa faixa
  /// nenhuma, então não empurra para fora as faixas que o palco do 📺 fixou. null = lição fora do curso ou
  /// trilha própria.
  HistoriaLicao? daLicao(String licaoId, {String? chave}) {
    if (licaoId.isEmpty) return null;
    final achou = _licao(licaoId);
    if (achou == null) return null;
    final (trilha, licao) = achou;
    final slug = slugDaLicao(licao.id);
    _aoFundo(slug);
    final autoral = _autorais[slug]?.licoes[licao.id];
    if (autoral != null && (chave == null || autoral.ancoras.containsKey(chave))) return autoral;
    return _automaticas[licao.id] ??= EncenadorLicao.encenar(licao, etapa: trilha.etapa, manual: _tabela?[licao.id]);
  }

  /// Carrega índice, tabela e a trilha da faixa (e a próxima trilha). Nunca lança. Chamado ao abrir o
  /// OuvirPage (com a lição atual do curso) e em todo botão 📺 (I6). Uma trilha que falhou é tentada de novo.
  Future<void> preparar(Faixa f) => f.licaoId.isEmpty ? _prepararBase() : prepararLicao(f.licaoId);

  /// Pré-carga pelo id da lição (o OuvirPage ainda não tem Faixa).
  Future<void> prepararLicao(String licaoId) async {
    try {
      await _prepararBase();
      final achou = _licao(licaoId);
      if (achou == null) return;
      final slug = slugDaLicao(achou.$2.id);
      final prox = _proxima(slug);
      await Future.wait([_carregar(slug, deNovo: true), if (prox != null) _carregar(prox, deNovo: true)]);
    } catch (e) {
      debugPrint('📺 historinhas: preparar $licaoId falhou: $e');
    }
  }

  bool temAutoral(String licaoId) {
    final achou = _licao(licaoId);
    if (achou == null) return false;
    return _autorais[slugDaLicao(achou.$2.id)]?.licoes.containsKey(licaoId) ?? false;
  }

  /// A trilha da lição está no índice mas o arquivo ainda não chegou (o palco espera até 400 ms). Também
  /// true enquanto o próprio índice está a caminho. Se a trilha ainda não foi pedida, começa a carregar.
  bool carregando(String licaoId) {
    final achou = _licao(licaoId);
    if (achou == null) return false;
    final idx = _indice;
    if (idx == null) return _base != null && !_baseTravada;
    final slug = slugDaLicao(achou.$2.id);
    if (!idx.containsKey(slug) || _autorais.containsKey(slug) || _falhas.contains(slug)) return false;
    _aoFundo(slug);
    return _pedidos.containsKey(slug);
  }

  /// Índice + tabela (uma vez por vez; o repo guarda o que deu certo e tenta de novo o que falhou).
  Future<void> _prepararBase() {
    final emVoo = _base;
    if (emVoo != null && !_baseTravada) return emVoo;
    late final Future<void> futuro;
    futuro = () async {
      try {
        final r = await Future.wait([
          HistoriasLicoesRepo.trilhasComHistoria(bundle: bundle, timeout: timeout),
          HistoriasLicoesRepo.encenacaoAuto(bundle: bundle, timeout: timeout),
        ]);
        _indice = r[0] as Map<String, int>;
        final tabela = r[1] as Map<String, EncenacaoManual>;
        if (tabela.isNotEmpty && !identical(tabela, _tabela)) {
          _tabela = tabela;
          _automaticas.clear(); // a próxima faixa já sai com a correção da tabela
        }
      } catch (e) {
        debugPrint('📺 historinhas: índice/tabela indisponíveis: $e');
      } finally {
        // um pedido travado que chega tarde não apaga o que o substituiu
        if (identical(_base, futuro)) _base = null;
      }
    }();
    // o corpo para no 1º `await`, então o `finally` só roda depois desta linha
    _desdeBase = Stopwatch()..start();
    return _base = futuro;
  }

  /// Começa a carregar em segundo plano a trilha (e a seguinte) quando o índice já chegou e a lista, sem
  /// martelar uma que falhou (essa só volta no próximo [preparar]).
  void _aoFundo(String slug) {
    final idx = _indice;
    if (idx == null) return;
    for (final s in [slug, ?_proxima(slug)]) {
      if (idx.containsKey(s) && !_autorais.containsKey(s) && !_pedidos.containsKey(s) && !_falhas.contains(s)) {
        unawaited(_carregar(s));
      }
    }
  }

  Future<void> _carregar(String slug, {bool deNovo = false}) {
    if (_autorais.containsKey(slug)) return Future.value();
    final emVoo = _pedidos[slug];
    if (emVoo != null) return emVoo;
    if (_falhas.contains(slug) && !deNovo) return Future.value();
    final trilha = _porSlug?[slug];
    if (trilha == null || !(_indice?.containsKey(slug) ?? false)) return Future.value();
    _falhas.remove(slug);
    final futuro = () async {
      try {
        final j = await HistoriasLicoesRepo.trilha(slug, bundle: bundle, timeout: timeout);
        if (j == null) {
          _falhas.add(slug);
          return;
        }
        _autorais[slug] = HistoriasDaTrilha.fromJson(j,
            trilha: trilha, estrito: false, aviso: (m) => debugPrint('📺 historinhas $slug: $m'));
      } catch (e) {
        _falhas.add(slug);
        debugPrint('📺 historinhas: trilha $slug descartada: $e');
      } finally {
        _pedidos.remove(slug);
      }
    }();
    // o corpo para no 1º `await`, então o `finally` só roda depois desta linha
    return _pedidos[slug] = futuro;
  }
}
