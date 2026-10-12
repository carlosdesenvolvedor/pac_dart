import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../data/tradutor.dart';
import '../domain/baralhos.dart';
import '../domain/config_srs.dart';
import '../domain/srs.dart';
import '../domain/texto_salvo.dart';
import 'exportar_anki_dialog.dart';
import 'fixacao.dart';
import 'importar_cartoes_page.dart';
import 'navegador_cartoes_page.dart';
import 'novo_cartao_page.dart';
import 'revisao_cubit.dart';

/// "Baralhos", no jeito do Anki: o que vence hoje, a previsão dos próximos
/// dias, a retenção real, os baralhos (uma trilha cada, agrupados por etapa, e
/// "Meus textos") com o interruptor do sentido inglês → português, o navegador de
/// cartões e os ajustes.
class BaralhosPage extends StatefulWidget {
  const BaralhosPage({super.key});

  @override
  State<BaralhosPage> createState() => _BaralhosPageState();
}

class _BaralhosPageState extends State<BaralhosPage> {
  IndiceBaralhos? _indice;
  List<Trilha>? _trilhasDoIndice;
  List<EntradaHistorico> _historico = const [];

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    final r = context.read<RevisaoCubit>();
    List<EntradaHistorico> h;
    try {
      h = await r.repo.carregarHistorico(desdeDia: r.hoje - 40);
    } catch (_) {
      h = const [];
    }
    if (mounted) setState(() => _historico = h);
  }

  IndiceBaralhos _indiceDe(List<Trilha> trilhas) {
    if (!identical(_trilhasDoIndice, trilhas)) {
      _indice = IndiceBaralhos.de(trilhas);
      _trilhasDoIndice = trilhas;
    }
    return _indice!;
  }

  Future<void> _estudar({String? baralho}) async {
    await abrirRevisao(context, baralho: baralho);
    if (mounted) await _carregarHistorico();
  }

  Future<void> _novoCartao() async {
    Tradutor tradutor;
    try {
      tradutor = context.read<Tradutor>();
    } catch (_) {
      tradutor = TradutorMyMemory();
    }
    await Navigator.of(context).push<int>(MaterialPageRoute<int>(builder: (_) => NovoCartaoPage(tradutor: tradutor)));
  }

  Future<void> _importar() async {
    final bloc = context.read<CursoBloc>();
    final revisao = context.read<RevisaoCubit>();
    final texto = await Navigator.of(context).push<TextoSalvo>(MaterialPageRoute<TextoSalvo>(builder: (_) => const ImportarCartoesPage()));
    if (texto == null || bloc.isClosed) return;
    bloc.add(TextoCriado(texto, abrir: false));
    // lista de cartões é para virar: o inglês → português já entra ligado (dá para desligar aqui)
    await revisao.mudarConfig(revisao.state.config.comReversos(['txt:${texto.id}'], ligar: true));
  }

  void _exportar(IndiceBaralhos indice) => mostrarExportarAnki(context, indice: indice, historico: _historico);

  void _abrirAjustes() => showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF141414),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusLg))),
        builder: (_) => BlocProvider.value(value: context.read<RevisaoCubit>(), child: const _Ajustes()),
      );

  @override
  Widget build(BuildContext context) {
    final curso = context.watch<CursoBloc>().state;
    final revisao = context.watch<RevisaoCubit>();
    final st = revisao.state;
    final indice = _indiceDe(curso.trilhas);
    final hoje = revisao.hoje;
    final ligados = st.config.reversos;
    final devidasTotal = st.quantasDevidas(hoje);
    final novas = revisao.novasReversas(indice.frasesDosLigados(ligados)).length;
    final revisadasHoje = _historico.where((e) => e.dia == hoje).length;
    final retencao = retencaoReal(_historico, desdeDia: hoje - 29);
    final carga = previsaoDeCarga(st.cartoes, hoje);
    final atividade = revisoesPorDia(_historico, hoje);

    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 48), children: [
              Row(children: [
                IconButton(
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
                  style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
                ),
                const SizedBox(width: 12),
                const Text('🧠', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(child: Text('Baralhos', style: Mixart.display(size: 22))),
                IconButton(
                  key: const Key('ajustes-baralhos'),
                  tooltip: 'Ajustes da revisão',
                  onPressed: _abrirAjustes,
                  icon: Icon(Icons.tune_rounded, color: Mixart.text, size: 21),
                  style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
                ),
              ]),
              const SizedBox(height: 16),
              _Hoje(
                aRevisar: devidasTotal,
                limite: st.config.limiteRevisoes,
                novas: novas,
                revisadasHoje: revisadasHoje,
                maduras: st.maduras,
                cartoes: st.cartoes.length,
                onEstudar: () => _estudar(),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                  key: const Key('novo-cartao'),
                  onPressed: _novoCartao,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Novo cartão'),
                ),
                OutlinedButton.icon(
                  key: const Key('importar-cartoes'),
                  onPressed: _importar,
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Importar lista'),
                ),
                OutlinedButton.icon(
                  key: const Key('exportar-anki'),
                  onPressed: () => _exportar(indice),
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: const Text('Exportar para o Anki'),
                ),
              ]),
              const SizedBox(height: 12),
              _Barras(
                titulo: 'Próximos 14 dias',
                subtitulo: 'cartões que vencem em cada dia (hoje inclui os atrasados)',
                valores: carga,
                rotulos: [for (var i = 0; i < carga.length; i++) i == 0 ? 'hoje' : '$i'],
                chaveBase: 'carga',
              ),
              const SizedBox(height: 12),
              _Barras(
                titulo: 'Retenção real: ${retencao == null ? 'ainda poucas revisões' : '${(retencao * 100).round()}%'}',
                subtitulo: 'revisões dos últimos 14 dias · o que você lembrou nos últimos 30 dias, '
                    'de cartões já aprendidos (meta: ${(st.config.retencao * 100).round()}%)',
                valores: atividade,
                rotulos: [for (var i = 0; i < atividade.length; i++) i == atividade.length - 1 ? 'hoje' : '${i - atividade.length + 1}'],
                chaveBase: 'atividade',
              ),
              const SizedBox(height: 18),
              if (indice.baralhos.isEmpty)
                Text('Ainda não há baralhos.', style: Mixart.ui(size: 13, color: Mixart.textMuted))
              else
                for (final grupo in _ordenar(indice.grupos)) ...[
                  _CabecalhoGrupo(
                    grupo: grupo,
                    baralhos: indice.doGrupo(grupo),
                    ligados: ligados,
                    onTodos: (ligar) => revisao.mudarConfig(
                        st.config.comReversos([for (final b in indice.doGrupo(grupo)) b.id], ligar: ligar)),
                  ),
                  for (final b in indice.doGrupo(grupo))
                    _LinhaBaralho(
                      baralho: b,
                      contagem: indice.contar(b, st.cartoes, hoje, ligados: ligados),
                      onInverter: (ligar) => revisao.mudarConfig(st.config.comReversos([b.id], ligar: ligar)),
                      onEstudar: () => _estudar(baralho: b.id),
                      onCartoes: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => BlocProvider.value(
                          value: revisao,
                          child: NavegadorCartoesPage(baralho: b),
                        ),
                      )),
                    ),
                  const SizedBox(height: 10),
                ],
            ]),
          ),
        ),
      ),
    );
  }

  /// "Meus textos" primeiro (é o que a pessoa mais mexe), depois o curso na ordem.
  List<String> _ordenar(List<String> grupos) =>
      [...grupos.where((g) => g == 'Meus textos'), ...grupos.where((g) => g != 'Meus textos')];
}

class _Hoje extends StatelessWidget {
  final int aRevisar, limite, novas, revisadasHoje, maduras, cartoes;
  final VoidCallback onEstudar;
  const _Hoje({
    required this.aRevisar,
    required this.limite,
    required this.novas,
    required this.revisadasHoje,
    required this.maduras,
    required this.cartoes,
    required this.onEstudar,
  });

  @override
  Widget build(BuildContext context) {
    final nada = aRevisar == 0 && novas == 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.brandDim),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$aRevisar', key: const Key('a-revisar-hoje'), style: Mixart.display(size: 44, color: Mixart.brand)),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                aRevisar == 1 ? 'cartão para revisar hoje' : 'cartões para revisar hoje',
                style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.text),
              ),
            ),
          ),
        ]),
        if (aRevisar > limite)
          Text('Vão ser $limite hoje (o limite dos ajustes); o resto fica para amanhã.',
              style: Mixart.ui(size: 12, color: Mixart.textMuted)),
        if (novas > 0)
          Text('+ $novas ${novas == 1 ? 'cartão novo' : 'cartões novos'} de inglês → português na cota de hoje',
              key: const Key('novos-hoje'), style: Mixart.ui(size: 12, color: Mixart.textMuted)),
        const SizedBox(height: 12),
        Wrap(spacing: 18, runSpacing: 6, children: [
          _Mini('revisados hoje', '$revisadasHoje'),
          _Mini('maduros (≥ 3 sem)', '$maduras'),
          _Mini('cartões', '$cartoes'),
        ]),
        const SizedBox(height: 14),
        FilledButton(
          key: const Key('estudar-tudo'),
          onPressed: nada ? null : onEstudar,
          style: FilledButton.styleFrom(
            backgroundColor: Mixart.brand,
            foregroundColor: Mixart.onBrand,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          child: Text(nada ? 'Nada para estudar agora 🎉' : 'Estudar agora',
              style: Mixart.ui(size: 14, weight: FontWeight.w800, color: nada ? Mixart.textFaint : Mixart.onBrand)),
        ),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  final String rotulo, valor;
  const _Mini(this.rotulo, this.valor);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(valor, style: Mixart.mono(size: 14, weight: FontWeight.w700, color: Mixart.text)),
        const SizedBox(width: 6),
        Text(rotulo, style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
      ]);
}

/// Um gráfico de barras simples (sem pacote): valor em cima, barra, rótulo embaixo.
class _Barras extends StatelessWidget {
  final String titulo, subtitulo, chaveBase;
  final List<int> valores;
  final List<String> rotulos;
  const _Barras({
    required this.titulo,
    required this.subtitulo,
    required this.valores,
    required this.rotulos,
    required this.chaveBase,
  });

  @override
  Widget build(BuildContext context) {
    final maior = valores.fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.text)),
        const SizedBox(height: 2),
        Text(subtitulo, style: Mixart.ui(size: 11.5, color: Mixart.textMuted).copyWith(height: 1.4)),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < valores.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text(valores[i] == 0 ? '' : '${valores[i]}',
                        key: Key('$chaveBase-$i'), style: Mixart.mono(size: 9.5, color: Mixart.textMuted)),
                    const SizedBox(height: 2),
                    Container(
                      height: maior == 0 ? 2 : (valores[i] / maior * 56).clamp(2, 56).toDouble(),
                      decoration: BoxDecoration(
                        color: valores[i] == 0 ? Mixart.border : Mixart.brand,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(rotulos[i], style: Mixart.ui(size: 9, color: Mixart.textFaint)),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _CabecalhoGrupo extends StatelessWidget {
  final String grupo;
  final List<Baralho> baralhos;
  final Set<String> ligados;
  final ValueChanged<bool> onTodos;
  const _CabecalhoGrupo({required this.grupo, required this.baralhos, required this.ligados, required this.onTodos});

  @override
  Widget build(BuildContext context) {
    final todosLigados = baralhos.every((b) => ligados.contains(b.id));
    final frases = baralhos.fold<int>(0, (s, b) => s + b.frases.length);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(grupo.toUpperCase(),
                style: Mixart.display(size: 14, color: Mixart.brand).copyWith(letterSpacing: 1.6)),
            Text('${baralhos.length} ${baralhos.length == 1 ? 'baralho' : 'baralhos'} · $frases frases',
                style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
          ]),
        ),
        TextButton(
          key: Key('inverter-grupo-$grupo'),
          onPressed: () => onTodos(!todosLigados),
          child: Text(todosLigados ? 'Desligar inglês → português' : 'Ligar inglês → português',
              style: Mixart.ui(size: 11.5, weight: FontWeight.w700, color: Mixart.textMuted)),
        ),
      ]),
    );
  }
}

class _LinhaBaralho extends StatelessWidget {
  final Baralho baralho;
  final ContagemBaralho contagem;
  final ValueChanged<bool> onInverter;
  final VoidCallback onEstudar, onCartoes;
  const _LinhaBaralho({
    required this.baralho,
    required this.contagem,
    required this.onInverter,
    required this.onEstudar,
    required this.onCartoes,
  });

  @override
  Widget build(BuildContext context) {
    final c = contagem;
    final temAlgo = c.aRevisar > 0 || c.invertidasNovas > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: c.aRevisar > 0 ? Mixart.brandDim : Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(baralho.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(baralho.nome, style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.text), overflow: TextOverflow.ellipsis),
              Text(
                '${c.aprendidas} de ${c.total} ${c.total == 1 ? 'frase aprendida' : 'frases aprendidas'} · ${c.maduras} ${c.maduras == 1 ? 'maduro' : 'maduros'}'
                '${c.invertido ? ' · inglês → português: ${c.invertidasTotal}' : ''}',
                style: Mixart.ui(size: 11.5, color: Mixart.textMuted),
              ),
            ]),
          ),
          if (c.aRevisar > 0)
            Container(
              key: Key('devidas-${baralho.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Mixart.brandSub, border: Border.all(color: Mixart.brandDim), borderRadius: BorderRadius.circular(999)),
              child: Text('${c.aRevisar} a revisar', style: Mixart.ui(size: 11.5, weight: FontWeight.w800, color: Mixart.brand)),
            ),
        ]),
        const SizedBox(height: 4),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
          Switch(
            key: Key('inverter-${baralho.id}'),
            value: c.invertido,
            onChanged: onInverter,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(c.invertido ? 'inglês → português ligado${c.invertidasNovas > 0 ? ' · ${c.invertidasNovas} ${c.invertidasNovas == 1 ? 'novo' : 'novos'}' : ''}' : 'estudar também de inglês → português',
              style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
          const SizedBox(width: 6),
          TextButton(
            key: Key('cartoes-${baralho.id}'),
            onPressed: onCartoes,
            child: Text('Cartões', style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textMuted)),
          ),
          TextButton(
            key: Key('estudar-${baralho.id}'),
            onPressed: temAlgo ? onEstudar : null,
            child: Text('Estudar', style: Mixart.ui(size: 12, weight: FontWeight.w800, color: temAlgo ? Mixart.brand : Mixart.textFaint)),
          ),
        ]),
      ]),
    );
  }
}

class _Ajustes extends StatelessWidget {
  const _Ajustes();

  @override
  Widget build(BuildContext context) {
    final revisao = context.watch<RevisaoCubit>();
    final cfg = revisao.state.config;
    Widget opcoes<T>(String titulo, String ajuda, List<T> valores, T atual, String Function(T) rotulo, ValueChanged<T> mudou, String chave) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: Mixart.text)),
        const SizedBox(height: 2),
        Text(ajuda, style: Mixart.ui(size: 11.5, color: Mixart.textMuted).copyWith(height: 1.4)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final v in valores)
            ChoiceChip(
              key: Key('$chave-${rotulo(v)}'),
              label: Text(rotulo(v)),
              selected: v == atual,
              onSelected: (_) => mudou(v),
              selectedColor: Mixart.brandSub,
              labelStyle: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: v == atual ? Mixart.brand : Mixart.textMuted),
              side: BorderSide(color: v == atual ? Mixart.brandDim : Mixart.border),
              backgroundColor: Mixart.surface,
            ),
        ]),
        const SizedBox(height: 16),
      ]);
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ajustes da revisão', style: Mixart.display(size: 19)),
          const SizedBox(height: 14),
          opcoes<int>('Revisões por dia', 'O máximo de cartões vencidos que entram na revisão de um dia; o resto fica para o seguinte.',
              ConfigSrs.opcoesLimite, cfg.limiteRevisoes, (v) => '$v', (v) => revisao.mudarConfig(cfg.copyWith(limiteRevisoes: v)), 'limite'),
          opcoes<int>('Novos de inglês → português por dia', 'Quantos cartões de virar-e-avaliar entram por dia nos baralhos com o sentido ligado (0 = nenhum novo).',
              ConfigSrs.opcoesNovos, cfg.novosPorDia, (v) => '$v', (v) => revisao.mudarConfig(cfg.copyWith(novosPorDia: v)), 'novos'),
          opcoes<double>('Retenção desejada', 'Quanto da memória o agendador tenta manter. 90% é o padrão do Anki; mais alto exige muito mais revisões.',
              ConfigSrs.opcoesRetencao, ConfigSrs.opcoesRetencao.firstWhere((r) => (r - cfg.retencao).abs() < .001, orElse: () => cfg.retencao),
              (v) => '${(v * 100).round()}%', (v) => revisao.mudarConfig(cfg.copyWith(retencao: v)), 'retencao'),
        ]),
      ),
    );
  }
}
