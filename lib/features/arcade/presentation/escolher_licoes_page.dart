import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../../core/ui/festa.dart';
import '../../curso/domain/curriculo.dart';
import '../../curso/domain/mapa_regras.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../ingles/domain/cartoes_texto.dart';
import '../../ingles/domain/palavras_novas.dart';
import '../../ingles/presentation/palavras_cubit.dart';
import '../domain/vocabulario_jogo.dart';

/// Abre "📚 Lições das palavras" (de quais lições vêm as palavras dos jogos do Arcade). Fora do inglês
/// (sem o [PalavrasCubit] ou o [CursoBloc]) não faz nada. Devolve true quando a pessoa salvou.
Future<bool> abrirEscolherLicoes(BuildContext context) async {
  if (PalavrasCubit.de(context) == null) return false;
  try {
    BlocProvider.of<CursoBloc>(context, listen: false);
  } catch (_) {
    return false;
  }
  final r = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const EscolherLicoesPage()));
  return r ?? false;
}

/// O aviso de poucas palavras do vocabulário [v] montado com lições escolhidas (o hub e a tela de escolher
/// usam a mesma regra): faltar nas curtas/médias é "poucas palavras" (`alerta`); faltar só nas longas
/// (9+ letras, raras nas primeiras lições) é uma nota. Null quando não precisou completar.
({String texto, bool alerta, int quantas})? avisoPoucasPalavras(VocabularioJogo v) {
  if (v.enchimentoCurtasMedias > 0) {
    return (texto: 'Poucas palavras nessas lições', alerta: true, quantas: v.enchimento);
  }
  if (v.enchimentoLongas > 0) {
    return (texto: 'Poucas palavras longas (9+ letras) nessas lições', alerta: false, quantas: v.enchimentoLongas);
  }
  return null;
}

/// Uma lição na lista: pode ser marcada (feita, a atual ou já alcançada no mapa) ou ainda trancada.
class _ItemLicao {
  final Licao licao;
  final bool feita;
  final bool atual;
  final bool disponivel;
  const _ItemLicao(this.licao, {required this.feita, required this.atual, required this.disponivel});
}

/// Uma unidade (trilha) na lista, com as lições dela.
class _Unidade {
  final int indice;
  final Trilha trilha;
  final String titulo;
  final List<_ItemLicao> licoes;
  const _Unidade(this.indice, this.trilha, this.titulo, this.licoes);

  Iterable<_ItemLicao> get disponiveis => licoes.where((l) => l.disponivel);
}

/// 📚 Lições das palavras: a pessoa escolhe de quais lições vêm as palavras dos jogos (Chuva, Rali,
/// Turismo) — ou deixa no Automático. O curso aparece por etapa e unidade (abre e fecha), com as lições
/// feitas e a atual marcáveis (as trancadas aparecem apagadas; unidades inteiras trancadas ficam de fora),
/// quantas palavras cada uma dá e algumas delas (EN em cima, PT embaixo). Nada é gravado até "Salvar".
class EscolherLicoesPage extends StatefulWidget {
  const EscolherLicoesPage({super.key});

  @override
  State<EscolherLicoesPage> createState() => _EscolherLicoesPageState();
}

class _EscolherLicoesPageState extends State<EscolherLicoesPage> {
  PalavrasCubit? _cubit;

  /// O rascunho: as lições marcadas (null = Automático) e o "incluir minhas palavras".
  Set<String>? _escolha;
  bool _minhas = true;

  /// Como estava gravado (para saber se há o que salvar).
  Set<String>? _gravada;
  bool _minhasGravada = true;

  /// As unidades abertas (pelo índice da trilha).
  final Set<int> _abertas = {};

  // memória da lista (refeita só quando o curso muda)
  Object? _chaveUnidades;
  List<_Unidade> _unidades = const [];
  int _trancadas = 0;

  /// As lições que aparecem na lista (as marcáveis e as trancadas das unidades abertas) e todas as do
  /// curso — uma lição escolhida que não está em nenhuma das duas (texto apagado, curso mudou) é fantasma.
  Set<String> _idsNaLista = const {};
  Set<String> _idsNoCurso = const {};

  @override
  void initState() {
    super.initState();
    final cubit = _cubit = PalavrasCubit.de(context);
    final st = context.read<CursoBloc>().state;
    if (cubit != null) {
      cubit.prepararIndice(st.trilhas);
      _gravada = cubit.licoesDoJogo;
      _minhasGravada = cubit.minhasNoJogo;
    }
    _escolha = _gravada == null ? null : {..._gravada!};
    _minhas = _minhasGravada;
    // abertas de início: as unidades com lição marcada; sem nenhuma, a da lição atual
    for (var t = 0; t < st.trilhas.length; t++) {
      if (st.trilhas[t].licoes.any((l) => _escolha?.contains(l.id) ?? false)) _abertas.add(t);
    }
    if (_abertas.isEmpty && st.trilhaIdx >= 0 && st.trilhaIdx < st.trilhas.length) _abertas.add(st.trilhaIdx);
  }

  bool get _mudou {
    final a = _escolha, b = _gravada;
    if ((a == null) != (b == null)) return true;
    if (a != null && (a.length != b!.length || !a.containsAll(b))) return true;
    return a != null && _minhas != _minhasGravada;
  }

  /// As lições marcadas que aparecem na lista (as que a barra conta).
  Set<String> get _marcadasNaLista {
    final e = _escolha;
    return e == null ? const {} : e.intersection(_idsNaLista);
  }

  /// Dá para salvar: o Automático, ou pelo menos 1 lição marcada que exista (não vale só fantasma).
  bool get _valida => _escolha == null || _marcadasNaLista.isNotEmpty;

  // ---------- a lista ----------

  List<_Unidade> _montar(CursoState st) {
    final chave = (st.trilhas, st.concluidas, st.trilhaIdx, st.licaoIdx);
    final ant = _chaveUnidades;
    if (ant is (List<Trilha>, Set<String>, int, int) &&
        identical(ant.$1, chave.$1) &&
        identical(ant.$2, chave.$2) &&
        ant.$3 == chave.$3 &&
        ant.$4 == chave.$4) {
      return _unidades;
    }
    final alcance = alcanceDoMapa(st.trilhas, st.concluidas, (st.trilhaIdx, st.licaoIdx));
    final r = <_Unidade>[];
    var trancadas = 0;
    for (var t = 0; t < st.trilhas.length; t++) {
      final trilha = st.trilhas[t];
      final itens = <_ItemLicao>[];
      for (var l = 0; l < trilha.licoes.length; l++) {
        final licao = trilha.licoes[l];
        if (licao.id.isEmpty) continue;
        final feita = st.concluidas.contains(licao.id);
        final atual = t == st.trilhaIdx && l == st.licaoIdx;
        final estado = estadoDoNo(feita: feita, atual: atual, pos: (t, l), alcance: alcance, propria: trilha.propria);
        itens.add(_ItemLicao(licao, feita: feita, atual: atual, disponivel: estado != EstadoNo.trancada));
      }
      if (itens.isEmpty) continue;
      if (!itens.any((i) => i.disponivel)) {
        trancadas++;
        continue;
      }
      final titulo = trilha.textoId == idCartoesAvulsos ? tituloCartoesAvulsos : trilha.nivel;
      r.add(_Unidade(t, trilha, titulo, itens));
    }
    _chaveUnidades = chave;
    _trancadas = trancadas;
    _idsNaLista = {
      for (final u in r)
        for (final i in u.licoes) i.licao.id,
    };
    _idsNoCurso = {
      for (final t in st.trilhas)
        for (final l in t.licoes)
          if (l.id.isNotEmpty) l.id,
    };
    return _unidades = r;
  }

  /// As palavras de [l] que vão para os jogos (sem as que a pessoa tirou dos jogos ou apagou).
  List<(String, String)> _palavrasDe(IndicePalavras ind, Set<String> fora, Licao l) => [
        for (final p in [...ind.palavrasDeJogo(l), ...ind.comunsDeJogo(l)])
          if (!fora.contains(p.$1.toLowerCase())) p,
      ];

  // ---------- ações ----------

  void _alternar(String id, bool marcar) {
    setState(() {
      final e = _escolha ?? <String>{};
      if (marcar) {
        e.add(id);
      } else {
        e.remove(id);
      }
      _escolha = e;
    });
  }

  void _alternarUnidade(_Unidade u, bool marcar) {
    setState(() {
      final e = _escolha ?? <String>{};
      for (final i in u.disponiveis) {
        if (marcar) {
          e.add(i.licao.id);
        } else {
          e.remove(i.licao.id);
        }
      }
      _escolha = e;
    });
  }

  void _automatico() => setState(() => _escolha = null);

  void _todasConcluidas(List<_Unidade> unidades) => setState(() {
        _escolha = {
          for (final u in unidades)
            for (final i in u.licoes)
              if (i.feita) i.licao.id,
        };
        for (final u in unidades) {
          if (u.licoes.any((i) => i.feita)) _abertas.add(u.indice);
        }
      });

  void _limpar() => setState(() => _escolha = <String>{});

  /// Grava na ordem do curso e fecha.
  void _salvar(List<_Unidade> unidades) {
    final cubit = _cubit;
    if (cubit == null || !_valida) return;
    final e = _escolha;
    cubit.escolherLicoesDoJogo(
      e == null
          ? null
          : [
              for (final u in unidades)
                for (final i in u.licoes)
                  if (e.contains(i.licao.id)) i.licao.id,
              // as de unidades ainda trancadas continuam escolhidas; as que nem existem mais no curso
              // (texto apagado, curso mudou) saem
              ...e.where((id) => !_idsNaLista.contains(id) && _idsNoCurso.contains(id)),
            ],
      incluirMinhas: _minhas,
    );
    _gravada = e == null ? null : {...e};
    _minhasGravada = _minhas;
    Navigator.of(context).pop(true);
  }

  Future<void> _aoSairSemSalvar(List<_Unidade> unidades) async {
    final valida = _valida;
    final r = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Mixart.surface,
        title: Text(valida ? 'Salvar a escolha?' : 'Nenhuma lição marcada', style: Mixart.display(size: 18)),
        content: Text(
            valida
                ? 'Você mudou as lições das palavras dos jogos.'
                : 'Marque pelo menos 1 lição ou descarte a mudança.',
            style: Mixart.ui(size: 13.5, color: Mixart.textMuted)),
        actions: [
          TextButton(
            key: const Key('licoes-continuar'),
            onPressed: () => Navigator.of(c).pop(),
            child: Text('Continuar escolhendo',
                style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.textMuted)),
          ),
          TextButton(
            key: const Key('licoes-descartar'),
            onPressed: () => Navigator.of(c).pop('descartar'),
            child: Text('Descartar', style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.textMuted)),
          ),
          if (valida)
            TextButton(
              key: const Key('licoes-salvar-dialogo'),
              onPressed: () => Navigator.of(c).pop('salvar'),
              child: Text('Salvar', style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: Mixart.brand)),
            ),
        ],
      ),
    );
    if (!mounted) return;
    if (r == 'salvar') {
      _salvar(unidades);
    } else if (r == 'descartar') {
      setState(() {
        _escolha = _gravada == null ? null : {..._gravada!};
        _minhas = _minhasGravada;
      });
      Navigator.of(context).pop(false);
    }
  }

  // ---------- tela ----------

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) return Scaffold(backgroundColor: Mixart.bg);
    return BlocBuilder<CursoBloc, CursoState>(
      builder: (context, st) => BlocBuilder<PalavrasCubit, PalavrasState>(
        bloc: cubit,
        builder: (context, ps) {
          final unidades = _montar(st);
          final ind = ps.indice;
          final fora = {
            for (final p in ps.banco.palavras.values)
              if (p.removida || !p.noJogo) p.chave,
          };
          final itens = <Widget Function()>[
            () => _topo(unidades, cubit),
          ];
          String? etapa;
          var proprias = false;
          for (final u in unidades) {
            if (u.trilha.propria) {
              if (!proprias) {
                proprias = true;
                itens.add(() => _rotuloEtapa('MEUS TEXTOS'));
              }
            } else if (u.trilha.etapa != etapa) {
              etapa = u.trilha.etapa;
              final e = etapa;
              if (e.isNotEmpty) itens.add(() => _rotuloEtapa(e.toUpperCase()));
            }
            itens.add(() => _cartaoUnidade(u, ind, fora));
          }
          if (_trancadas > 0) itens.add(() => _rodapeTrancadas());
          if (ind == null) itens.add(() => _preparando());

          return PopScope(
            canPop: !_mudou,
            onPopInvokedWithResult: (saiu, _) {
              if (!saiu) _aoSairSemSalvar(unidades);
            },
            child: Scaffold(
              backgroundColor: Mixart.bg,
              body: SafeArea(
                bottom: false,
                child: ListView.builder(
                  key: const Key('licoes-lista'),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: itens.length,
                  itemBuilder: (context, i) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: itens[i](),
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: _barraResumo(st, cubit, unidades),
            ),
          );
        },
      ),
    );
  }

  Widget _topo(List<_Unidade> unidades, PalavrasCubit cubit) {
    final auto = _escolha == null;
    final temFeitas = unidades.any((u) => u.licoes.any((i) => i.feita));
    final k = cubit.quantasMinhasNoJogo;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(
          key: const Key('licoes-voltar'),
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
          style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ARCADE · ENGLISH',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.brand).copyWith(letterSpacing: 2)),
            const SizedBox(height: 2),
            Semantics(
              header: true,
              child: Text('📚 Lições das palavras',
                  style: Mixart.display(size: 21), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ]),
      const SizedBox(height: 14),
      Text(
        'Escolha de quais lições vêm as palavras da Chuva, do Rali e do Turismo — ou deixe no Automático.',
        style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.5),
      ),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _Pilula(
          key: const Key('licoes-automatico'),
          rotulo: '✨ Automático',
          selecionada: auto,
          onTap: auto ? null : _automatico,
          dica: 'Voltar ao automático: os jogos escolhem as palavras',
        ),
        _Pilula(
          key: const Key('licoes-todas-concluidas'),
          rotulo: '✅ Todas as concluídas',
          onTap: temFeitas ? () => _todasConcluidas(unidades) : null,
          dica: 'Marcar todas as lições que você já concluiu',
        ),
        _Pilula(
          key: const Key('licoes-limpar'),
          rotulo: 'Limpar',
          onTap: _escolha == null || _escolha!.isNotEmpty ? _limpar : null,
          dica: 'Desmarcar todas as lições',
        ),
      ]),
      const SizedBox(height: 12),
      if (auto)
        Container(
          key: const Key('licoes-aviso-automatico'),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Mixart.brandSub,
            border: Border.all(color: Mixart.brandDim),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Text(
            '✨ No Automático os jogos usam as palavras em treino, as que vencem hoje, as das suas últimas '
            'lições, as suas e uma amostra das antigas. Marque lições abaixo para escolher você.',
            style: Mixart.ui(size: 12.5, color: Mixart.text).copyWith(height: 1.5),
          ),
        ),
      if (auto) const SizedBox(height: 4),
      Material(
        color: Colors.transparent,
        child: SwitchListTile(
          key: const Key('licoes-incluir-minhas'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          value: auto ? true : _minhas,
          onChanged: auto ? null : (v) => setState(() => _minhas = v),
          activeThumbColor: Mixart.onBrand,
          activeTrackColor: Mixart.brand,
          title: Text('Incluir minhas palavras',
              style: Mixart.ui(size: 14, weight: FontWeight.w700, color: auto ? Mixart.textMuted : Mixart.text)),
          subtitle: Text(
            auto
                ? 'No Automático elas sempre entram'
                : k == 0
                    ? 'As que você adicionar ou guardar lendo'
                    : k == 1
                        ? '1 palavra que você adicionou ou guardou lendo'
                        : '$k palavras que você adicionou ou guardou lendo',
            style: Mixart.ui(size: 12, color: Mixart.textMuted),
          ),
        ),
      ),
      const SizedBox(height: 6),
    ]);
  }

  Widget _rotuloEtapa(String texto) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Semantics(
          header: true,
          child: Text(texto,
              style: Mixart.ui(size: 10.5, weight: FontWeight.w700, color: Mixart.textMuted).copyWith(letterSpacing: 2)),
        ),
      );

  Widget _rodapeTrancadas() => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(
          '🔒 Mais $_trancadas unidade${_trancadas == 1 ? '' : 's'} '
          '${_trancadas == 1 ? 'abre' : 'abrem'} conforme você avança no curso.',
          style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5),
        ),
      );

  Widget _preparando() => Padding(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Mixart.brand)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Contando as palavras das lições…', style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
          ),
        ]),
      );

  Widget _cartaoUnidade(_Unidade u, IndicePalavras? ind, Set<String> fora) {
    final disponiveis = u.disponiveis.toList();
    final marcadas = disponiveis.where((i) => _escolha?.contains(i.licao.id) ?? false).length;
    final bool? estado = marcadas == 0 ? false : (marcadas == disponiveis.length ? true : null);
    final palavras = <String>{};
    if (ind != null) {
      for (final i in disponiveis) {
        for (final p in _palavrasDe(ind, fora, i.licao)) {
          palavras.add(p.$1.toLowerCase());
        }
      }
    }
    final emoji = u.trilha.emoji.isEmpty ? '📘' : u.trilha.emoji;
    final resumo = [
      if (marcadas > 0) '$marcadas de ${disponiveis.length} marcada${disponiveis.length == 1 ? '' : 's'}'
      else '${disponiveis.length} ${disponiveis.length == 1 ? 'lição liberada' : 'lições liberadas'}',
      if (ind != null) '${palavras.length} palavra${palavras.length == 1 ? '' : 's'}',
    ].join(' · ');
    final cor = marcadas > 0 ? Mixart.brandDim : Mixart.border;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: cor, width: marcadas > 0 ? 1.4 : 1),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            key: PageStorageKey('unidade-${u.indice}'),
            initiallyExpanded: _abertas.contains(u.indice),
            onExpansionChanged: (v) => v ? _abertas.add(u.indice) : _abertas.remove(u.indice),
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: const EdgeInsets.fromLTRB(4, 2, 12, 2),
            childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            iconColor: Mixart.text,
            collapsedIconColor: Mixart.textMuted,
            leading: Semantics(
              label: 'Marcar todas as lições liberadas de ${u.titulo}',
              child: Checkbox(
                key: Key('unidade-${u.trilha.baralhoId}'),
                tristate: true,
                value: estado,
                activeColor: Mixart.brand,
                checkColor: Mixart.onBrand,
                side: BorderSide(color: Mixart.textMuted, width: 1.6),
                onChanged: (_) => _alternarUnidade(u, estado != true),
              ),
            ),
            title: Text('$emoji  ${u.titulo}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Mixart.ui(size: 14.5, weight: FontWeight.w700, color: Mixart.text)),
            subtitle: Text(resumo, style: Mixart.ui(size: 12, color: Mixart.textMuted)),
            children: [
              for (final i in u.licoes) _linhaLicao(i, ind, fora),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linhaLicao(_ItemLicao i, IndicePalavras? ind, Set<String> fora) {
    final l = i.licao;
    final marcada = _escolha?.contains(l.id) ?? false;
    final palavras = ind == null ? const <(String, String)>[] : _palavrasDe(ind, fora, l);
    final n = palavras.length;
    final status = !i.disponivel
        ? '🔒 ainda não chegou aqui'
        : i.atual
            ? 'lição atual'
            : i.feita
                ? 'feita'
                : 'liberada';
    final nome = l.nome.isEmpty ? l.id : l.nome;
    return Opacity(
      opacity: i.disponivel ? 1 : .5,
      child: CheckboxListTile(
        key: Key('licao-${l.id}'),
        value: marcada,
        onChanged: i.disponivel ? (v) => _alternar(l.id, v ?? false) : null,
        controlAffinity: ListTileControlAffinity.leading,
        titleAlignment: ListTileTitleAlignment.top,
        dense: true,
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 14, 0),
        activeColor: Mixart.brand,
        checkColor: Mixart.onBrand,
        side: BorderSide(color: Mixart.textMuted, width: 1.6),
        title: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text('${l.emoji.isEmpty ? '' : '${l.emoji} '}$nome',
                style: Mixart.ui(size: 13.5, weight: FontWeight.w600, color: Mixart.text).copyWith(height: 1.35)),
          ),
          const SizedBox(width: 8),
          if (ind != null)
            Text('$n palavra${n == 1 ? '' : 's'}',
                style: Mixart.ui(
                    size: 11.5, weight: FontWeight.w700, color: i.disponivel ? Mixart.textMuted : Mixart.textFaint)),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 2),
          Text(status,
              style: Mixart.ui(
                  size: 11,
                  weight: FontWeight.w600,
                  color: i.atual ? Mixart.brand : (i.disponivel ? Mixart.textMuted : Mixart.textFaint))),
          if (i.disponivel && palavras.isNotEmpty) ...[
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                for (final (en, pt) in palavras.take(3)) _amostra(en, pt),
              ]),
            ),
            const SizedBox(height: 4),
          ],
        ]),
      ),
    );
  }

  Widget _amostra(String en, String pt) => Container(
        constraints: const BoxConstraints(maxWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Mixart.surfaceHi,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Mixart.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(en,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Mixart.mono(size: 12, weight: FontWeight.w700, color: Mixart.text)),
          Text(pt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Mixart.ui(size: 10, weight: FontWeight.w600, color: Mixart.textMuted)),
        ]),
      );

  Widget _barraResumo(CursoState st, PalavrasCubit cubit, List<_Unidade> unidades) {
    final e = _escolha;
    final String resumo;
    String? aviso;
    var alerta = false;
    if (e == null) {
      resumo = '✨ Automático';
      aviso = 'Os jogos escolhem as palavras pelo que você está estudando.';
    } else {
      final existentes = _marcadasNaLista;
      final nL = existentes.length;
      final nP = cubit.palavrasDasLicoes(st, existentes).length;
      // a prévia do vocabulário com esta escolha: dela saem as "suas" que entram mesmo e o enchimento
      final v = cubit.state.indice == null
          ? null
          : cubit.vocabularioJogo(st, escolha: (licoes: existentes, minhas: _minhas));
      final k = _minhas ? (v?.minhas ?? 0) : 0;
      resumo = '$nL ${nL == 1 ? 'lição' : 'lições'} · $nP palavra${nP == 1 ? '' : 's'}'
          '${k > 0 ? ' + $k sua${k == 1 ? '' : 's'}' : ''}';
      if (nL == 0) {
        aviso = 'Marque pelo menos 1 lição — ou volte ao Automático.';
        alerta = true;
      } else if (v != null) {
        final poucas = avisoPoucasPalavras(v);
        aviso = [
          if (poucas != null) '${poucas.texto}: os jogos completam com ${poucas.quantas} das mais usadas do inglês.',
          if (nP > 120) 'Cada partida usa até 120 delas (40 de cada tamanho), sorteadas entre as lições a cada dia.',
        ].join(' ');
        if (aviso.isEmpty) aviso = null;
        alerta = poucas?.alerta ?? false;
      }
    }
    final corAviso = alerta ? escurecer(CoresFesta.coral, quanto: .25, soNoClaro: true) : Mixart.textMuted;
    return Container(
      decoration: BoxDecoration(color: Mixart.surface, border: Border(top: BorderSide(color: Mixart.border))),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(resumo,
                          key: const Key('licoes-total'),
                          style: Mixart.ui(size: 14.5, weight: FontWeight.w800, color: Mixart.text)),
                      if (aviso != null) ...[
                        const SizedBox(height: 3),
                        Text(aviso,
                            key: const Key('licoes-aviso'),
                            style: Mixart.ui(size: 11.5, weight: FontWeight.w600, color: corAviso).copyWith(height: 1.4)),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(width: 12),
                Botao3D(
                  key: const Key('licoes-salvar'),
                  rotulo: 'Salvar',
                  icone: Icons.check_rounded,
                  expandir: false,
                  altura: 44,
                  tamanhoTexto: 14,
                  onTap: _valida ? () => _salvar(unidades) : null,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Um botão-pílula (as ações rápidas): marcada = cheia na cor da marca. Foco pelo teclado e leitor de tela.
class _Pilula extends StatelessWidget {
  final String rotulo;
  final String dica;
  final bool selecionada;
  final VoidCallback? onTap;

  const _Pilula({super.key, required this.rotulo, required this.dica, this.selecionada = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ativa = onTap != null;
    final fundo = selecionada ? Mixart.brand : Mixart.surfaceHi;
    final texto = selecionada ? Mixart.onBrand : (ativa ? Mixart.text : Mixart.textFaint);
    return Semantics(
      button: true,
      selected: selecionada,
      enabled: ativa,
      hint: dica,
      child: Tooltip(
        message: dica,
        child: Material(
          color: fundo,
          shape: StadiumBorder(side: BorderSide(color: selecionada ? Mixart.brand : Mixart.border)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Text(rotulo, style: Mixart.ui(size: 13, weight: FontWeight.w700, color: texto)),
            ),
          ),
        ),
      ),
    );
  }
}
