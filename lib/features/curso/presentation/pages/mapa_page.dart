import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/curriculo.dart';
import '../bloc/curso_bloc.dart';
import '../widgets/pacman.dart';
import 'projeto_page.dart';
import 'quiz_page.dart';
import 'teoria_page.dart';

/// Mapa da Jornada: um caminho de nós por trilha (concluída ✓, atual com
/// Pac-Man, disponível apagada), com dashboard de progresso. Tocar num nó
/// abre a lição (praticar) ou o quiz. Progresso vem do estado local.
class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final _busca = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: BlocBuilder<CursoBloc, CursoState>(
        builder: (context, st) {
          if (st.status != CursoStatus.pronto) {
            return Center(child: CircularProgressIndicator(color: Mixart.brand));
          }
          final buscando = _query.trim().isNotEmpty;
          return Stack(children: [
            const Positioned.fill(child: _FundoPontilhado()),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: CustomScrollView(slivers: [
                  _BarraTopo(
                    st: st,
                    controle: _busca,
                    onBusca: (v) => setState(() => _query = v),
                  ),
                  if (buscando)
                    _Resultados(st: st, query: _query)
                  else ...[
                    SliverToBoxAdapter(child: _HeroDashboard(st: st)),
                    for (var t = 0; t < st.trilhas.length; t++) ...[
                      SliverToBoxAdapter(child: _SecaoTrilha(st: st, t: t)),
                      const SliverToBoxAdapter(child: _Conector()),
                    ],
                    if (st.masterApps.isNotEmpty)
                      SliverToBoxAdapter(child: _SecaoMaster(projetos: st.masterApps)),
                    const SliverToBoxAdapter(child: SizedBox(height: 56)),
                  ],
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

/// Remove acentos e caixa para busca tolerante.
String _norm(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';
  var r = s.toLowerCase();
  for (var i = 0; i < de.length; i++) {
    r = r.replaceAll(de[i], para[i]);
  }
  return r;
}

// ───────────────────────── barra superior ─────────────────────────
class _BarraTopo extends StatelessWidget {
  final CursoState st;
  final TextEditingController controle;
  final ValueChanged<String> onBusca;
  const _BarraTopo({required this.st, required this.controle, required this.onBusca});

  @override
  Widget build(BuildContext context) {
    final total = st.trilhas.fold<int>(0, (s, t) => s + t.licoes.length);
    final feitas = st.concluidas.length;
    final pct = total == 0 ? 0 : (feitas * 100 / total).round();
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Mixart.bg.withValues(alpha: .92),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
      ),
      title: Row(children: [
        Text('Mapa da Jornada', style: Mixart.display(size: 17)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: Mixart.brandSub,
            border: Border.all(color: Mixart.brandDim),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('$pct%', style: Mixart.mono(size: 11, weight: FontWeight.w700, color: Mixart.brand)),
        ),
      ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: controle,
            onChanged: onBusca,
            style: Mixart.ui(size: 14, color: Mixart.text),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar lição ou app por nome…',
              hintStyle: Mixart.ui(size: 13.5, color: Mixart.textFaint),
              prefixIcon: Icon(Icons.search, size: 19, color: Mixart.textMuted),
              suffixIcon: controle.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, size: 17, color: Mixart.textMuted),
                      onPressed: () {
                        controle.clear();
                        onBusca('');
                      },
                    ),
              filled: true,
              fillColor: Mixart.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
                borderSide: BorderSide(color: Mixart.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
                borderSide: BorderSide(color: Mixart.brand, width: 1.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lista de resultados da busca: lições, projetos e apps que casam com o nome.
class _Resultados extends StatelessWidget {
  final CursoState st;
  final String query;
  const _Resultados({required this.st, required this.query});

  @override
  Widget build(BuildContext context) {
    final q = _norm(query.trim());
    final itens = <Widget>[];

    for (var t = 0; t < st.trilhas.length; t++) {
      final tr = st.trilhas[t];
      for (var l = 0; l < tr.licoes.length; l++) {
        final lic = tr.licoes[l];
        if (_norm(lic.nome).contains(q)) {
          itens.add(_ItemResultado(
            emoji: lic.emoji,
            nome: lic.nome,
            contexto: '${tr.emoji} ${tr.nivel} · lição',
            feito: st.licaoConcluida(t, l),
            onTap: () => mostrarOpcoesLicao(context, st, t, l, st.quizNotas[st.chave(t, l)]),
          ));
        }
      }
      for (final p in tr.projetos) {
        if (_norm(p.nome).contains(q)) {
          itens.add(_ItemResultado(
            emoji: p.emoji,
            nome: p.nome,
            contexto: '${tr.emoji} ${tr.nivel} · mão na massa',
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => ProjetoPage(nivel: tr.nivel, projeto: p),
            )),
          ));
        }
      }
    }
    for (final p in st.masterApps) {
      if (_norm(p.nome).contains(q)) {
        itens.add(_ItemResultado(
          emoji: p.emoji,
          nome: p.nome,
          contexto: '🏆 Teste Master · app',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ProjetoPage(nivel: 'Flutter', projeto: p, master: true),
          )),
        ));
      }
    }

    if (itens.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(children: [
            Icon(Icons.search_off, size: 40, color: Mixart.textFaint),
            const SizedBox(height: 12),
            Text('Nada encontrado para "$query"',
                textAlign: TextAlign.center, style: Mixart.ui(size: 14, color: Mixart.textMuted)),
          ]),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 4),
                child: Text('${itens.length} resultado${itens.length == 1 ? '' : 's'}',
                    style: Mixart.ui(size: 11.5, weight: FontWeight.w600, color: Mixart.textMuted)),
              );
            }
            return itens[i - 1];
          },
          childCount: itens.length + 1,
        ),
      ),
    );
  }
}

class _ItemResultado extends StatelessWidget {
  final String emoji, nome, contexto;
  final bool feito;
  final VoidCallback onTap;
  const _ItemResultado(
      {required this.emoji, required this.nome, required this.contexto, this.feito = false, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Mixart.surface,
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                border: Border.all(color: Mixart.border),
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
              ),
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nome, style: Mixart.ui(size: 14, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(contexto, style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
                  ]),
                ),
                if (feito) Icon(Icons.check_circle, size: 17, color: Mixart.brand),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: Mixart.textFaint),
              ]),
            ),
          ),
        ),
      );
}

// ───────────────────────── dashboard ─────────────────────────
class _HeroDashboard extends StatelessWidget {
  final CursoState st;
  const _HeroDashboard({required this.st});

  @override
  Widget build(BuildContext context) {
    final totalLicoes = st.trilhas.fold<int>(0, (s, t) => s + t.licoes.length);
    final feitas = st.concluidas.length;
    final totalEx = st.trilhas.fold<int>(0, (s, t) => s + t.licoes.fold<int>(0, (a, l) => a + l.trechos.length));
    final estrelas = st.quizNotas.values.fold<int>(0, (s, v) => s + v);
    final trilhasIniciadas =
        List.generate(st.trilhas.length, (t) => List.generate(st.trilhas[t].licoes.length, (l) => st.licaoConcluida(t, l)).any((f) => f))
            .where((v) => v)
            .length;
    final pct = totalLicoes == 0 ? 0.0 : feitas / totalLicoes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF161616), Mixart.surface],
          ),
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 18), spreadRadius: -24)],
        ),
        child: Column(children: [
          Row(children: [
            _AnelProgresso(pct: pct, tamanho: 76, texto: '${(pct * 100).round()}%', grosso: true),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Sua jornada Dart & Flutter', style: Mixart.display(size: 18)),
                const SizedBox(height: 4),
                Text(_frase(pct), style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.45)),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            _StatTile(emoji: '🏁', valor: '$feitas/$totalLicoes', rotulo: 'lições'),
            const SizedBox(width: 10),
            _StatTile(emoji: '⭐', valor: '$estrelas', rotulo: 'estrelas'),
            const SizedBox(width: 10),
            _StatTile(emoji: '🧩', valor: '$trilhasIniciadas/${st.trilhas.length}', rotulo: 'trilhas'),
            const SizedBox(width: 10),
            _StatTile(emoji: '⌨️', valor: _compacto(totalEx), rotulo: 'exercícios'),
          ]),
        ]),
      ),
    );
  }

  String _frase(double pct) {
    if (pct <= 0) return 'Comece pela primeira lição e vá comendo o código com o Pac-Man.';
    if (pct < .25) return 'Bom começo! Continue avançando pela trilha.';
    if (pct < .6) return 'Você está pegando o ritmo. Siga em frente!';
    if (pct < 1) return 'Reta final — falta pouco para dominar tudo.';
    return 'Currículo completo! Você é fera. 🏆';
  }

  static String _compacto(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _StatTile extends StatelessWidget {
  final String emoji, valor, rotulo;
  const _StatTile({required this.emoji, required this.valor, required this.rotulo});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: Mixart.bg,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 5),
            FittedBox(child: Text(valor, style: Mixart.display(size: 16))),
            const SizedBox(height: 2),
            Text(rotulo, style: Mixart.ui(size: 9.5, weight: FontWeight.w600, color: Mixart.textFaint).copyWith(letterSpacing: .5)),
          ]),
        ),
      );
}

// ───────────────────────── seção de trilha ─────────────────────────
class _SecaoTrilha extends StatelessWidget {
  final CursoState st;
  final int t;
  const _SecaoTrilha({required this.st, required this.t});

  @override
  Widget build(BuildContext context) {
    final trilha = st.trilhas[t];
    final feitas = List.generate(trilha.licoes.length, (l) => st.licaoConcluida(t, l));
    final concluidas = feitas.where((f) => f).length;
    final ehAtual = t == st.trilhaIdx;
    final completa = concluidas == trilha.licoes.length;
    final pct = trilha.licoes.isEmpty ? 0.0 : concluidas / trilha.licoes.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: ehAtual ? Mixart.brandDim : Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          boxShadow: ehAtual
              ? const [BoxShadow(color: Color(0x22FFC73B), blurRadius: 34, spreadRadius: -12)]
              : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // cabeçalho da trilha
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: completa ? Mixart.brand : Mixart.surfaceHi,
                  shape: BoxShape.circle,
                  border: Border.all(color: completa ? Mixart.brand : Mixart.border),
                ),
                child: Text(trilha.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(trilha.nivel, style: Mixart.display(size: 18), overflow: TextOverflow.ellipsis)),
                    if (completa) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.verified, size: 16, color: Mixart.brand),
                    ] else if (ehAtual) ...[
                      const SizedBox(width: 8),
                      _EtiquetaAtual(),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text('$concluidas de ${trilha.licoes.length} lições · ${_ex(trilha)} exercícios',
                      style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
                ]),
              ),
              const SizedBox(width: 10),
              _AnelProgresso(pct: pct, tamanho: 40),
            ]),
          ),
          if (trilha.descricao.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
              child: Text(trilha.descricao,
                  style: Mixart.ui(size: 12, color: Mixart.textFaint).copyWith(height: 1.45)),
            ),
          // caminho de nós
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 20),
            child: LayoutBuilder(
              builder: (context, box) => _CaminhoLicoes(st: st, t: t, largura: box.maxWidth),
            ),
          ),
          if (trilha.temProjetos) _MaoNaMassa(nivel: trilha.nivel, projetos: trilha.projetos),
        ]),
      ),
    );
  }

  int _ex(Trilha t) => t.licoes.fold<int>(0, (a, l) => a + l.trechos.length);
}

/// Rodapé "Mão na Massa": 3 projetos completos ao fim do módulo.
class _MaoNaMassa extends StatelessWidget {
  final String nivel;
  final List<Projeto> projetos;
  const _MaoNaMassa({required this.nivel, required this.projetos});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Mixart.brandSub,
        border: Border.all(color: Mixart.brandDim),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.construction, size: 16, color: Mixart.brand),
          const SizedBox(width: 8),
          Text('MÃO NA MASSA',
              style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 1.5)),
          const SizedBox(width: 8),
          Text('· construa ${projetos.length} apps',
              style: Mixart.ui(size: 11, color: Mixart.textMuted)),
        ]),
        const SizedBox(height: 10),
        for (final p in projetos)
          _ChipProjeto(
            projeto: p,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => ProjetoPage(nivel: nivel, projeto: p),
            )),
          ),
      ]),
    );
  }
}

class _ChipProjeto extends StatelessWidget {
  final Projeto projeto;
  final VoidCallback onTap;
  final bool master;
  const _ChipProjeto({required this.projeto, required this.onTap, this.master = false});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Row(children: [
            Text(projeto.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(projeto.nome, style: Mixart.ui(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(projeto.descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Mixart.ui(size: 11.5, color: Mixart.textMuted).copyWith(height: 1.35)),
              ]),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Mixart.brandSub,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(projeto.flutter ? Icons.phone_iphone : Icons.terminal, size: 12, color: Mixart.brand),
                const SizedBox(width: 4),
                Text(projeto.flutter ? 'app' : 'programa',
                    style: Mixart.ui(size: 10, weight: FontWeight.w600, color: Mixart.brand)),
              ]),
            ),
          ]),
        ),
      );
}

/// Seção especial do Teste Master: os apps Flutter finais.
class _SecaoMaster extends StatelessWidget {
  final List<Projeto> projetos;
  const _SecaoMaster({required this.projetos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Mixart.brand.withValues(alpha: .18), Mixart.surface],
          ),
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          boxShadow: const [BoxShadow(color: Color(0x22FFC73B), blurRadius: 40, spreadRadius: -14)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
            child: Row(children: [
              const Text('🏆', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Teste Master', style: Mixart.display(size: 20)),
                  Text('${projetos.length} apps Flutter para construir, do simples ao avançado',
                      style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
            child: Text(
                'Cada app se monta na telinha enquanto você digita. Ao terminar, copie o código e rode numa IDE de verdade.',
                style: Mixart.ui(size: 12, color: Mixart.textFaint).copyWith(height: 1.45)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              for (final p in projetos)
                _ChipProjeto(
                  projeto: p,
                  master: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ProjetoPage(nivel: 'Flutter', projeto: p, master: true),
                  )),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _EtiquetaAtual extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Mixart.brandSub,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text('ATUAL',
            style: Mixart.ui(size: 9, weight: FontWeight.w700, color: Mixart.brand).copyWith(letterSpacing: 1)),
      );
}

// ───────────────────────── caminho + nós ─────────────────────────
class _CaminhoLicoes extends StatelessWidget {
  final CursoState st;
  final int t;
  final double largura;
  const _CaminhoLicoes({required this.st, required this.t, required this.largura});

  static const _passoY = 84.0;
  static const _no = 54.0;
  static const _margem = 14.0;
  static const _rotuloMin = 92.0;

  /// Amplitude adaptativa: grande no desktop, menor no celular, sempre
  /// deixando espaço para o rótulo caber do lado de fora.
  double _amplitude() {
    final ideal = math.min(largura * 0.28, 104.0);
    final maxParaRotulo = largura / 2 - _no / 2 - _margem - _rotuloMin;
    return math.max(0, math.min(ideal, maxParaRotulo));
  }

  /// Zigue-zague equilibrado: alterna esquerda/direita do centro.
  Offset _pos(int i) {
    final centro = largura / 2;
    final dx = centro + (i.isEven ? -1 : 1) * _amplitude();
    return Offset(dx, i * _passoY + _no / 2 + 6);
  }

  @override
  Widget build(BuildContext context) {
    final licoes = st.trilhas[t].licoes;
    final altura = licoes.length * _passoY + 14;
    final pontos = List.generate(licoes.length, _pos);
    return SizedBox(
      height: altura,
      child: Stack(clipBehavior: Clip.none, children: [
        CustomPaint(
          size: Size(largura, altura),
          painter: _TrilhoPainter(
            pontos: pontos,
            feitas: List.generate(licoes.length, (l) => st.licaoConcluida(t, l)),
          ),
        ),
        for (var l = 0; l < licoes.length; l++) _montaNo(context, l, pontos[l]),
      ]),
    );
  }

  Widget _montaNo(BuildContext context, int l, Offset p) {
    final licao = st.trilhas[t].licoes[l];
    final feita = st.licaoConcluida(t, l);
    final atual = t == st.trilhaIdx && l == st.licaoIdx;
    final ladoDireito = l.isOdd; // lane do zigue-zague (robusto p/ amplitude pequena)
    final nota = st.quizNotas[st.chave(t, l)];

    final node = _NoLicao(
      emoji: licao.emoji,
      feita: feita,
      atual: atual,
      nota: nota,
      onTap: () => _abreOpcoes(context, l, nota),
    );

    // rótulo para fora do nó (também clicável); o texto encosta no nó
    final rotulo = _Rotulo(
      nome: licao.nome,
      feita: feita,
      atual: atual,
      nota: nota,
      alinhaDireita: !ladoDireito,
      onTap: () => _abreOpcoes(context, l, nota),
    );

    return Positioned(
      top: p.dy - _passoY / 2,
      left: 0,
      right: 0,
      height: _passoY,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        // rótulo para FORA do nó (lado com mais espaço), centrado na vertical
        Positioned(
          top: 0,
          bottom: 0,
          left: ladoDireito ? p.dx + _no / 2 + 12 : _margem,
          right: ladoDireito ? _margem : largura - (p.dx - _no / 2) + 12,
          child: Align(
            alignment: ladoDireito ? Alignment.centerLeft : Alignment.centerRight,
            child: rotulo,
          ),
        ),
        Positioned(left: p.dx - _no / 2, top: _passoY / 2 - _no / 2, child: node),
      ]),
    );
  }

  void _abreOpcoes(BuildContext context, int l, int? nota) =>
      mostrarOpcoesLicao(context, st, t, l, nota);
}

/// Abre a folha de opções de uma lição (Teoria / Praticar / Quiz). Reutilizada
/// pelos nós do mapa e pelos resultados da busca.
void mostrarOpcoesLicao(BuildContext context, CursoState st, int t, int l, int? nota) {
  final licao = st.trilhas[t].licoes[l];
  final cursoBloc = context.read<CursoBloc>();
  final feita = st.licaoConcluida(t, l);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF141414),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusLg))),
    builder: (sheet) => _LicaoSheet(
      licao: licao,
      feita: feita,
      nota: nota,
      onTeoria: () {
        Navigator.of(sheet).pop();
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => TeoriaPage(
            nivel: st.trilhas[t].nivel,
            licao: licao,
            onPraticar: () {
              cursoBloc.add(TrilhaSelecionada(t));
              cursoBloc.add(LicaoSelecionada(l));
              Navigator.of(context).pop();
            },
          ),
        ));
      },
      onPraticar: () {
        Navigator.of(sheet).pop();
        cursoBloc.add(TrilhaSelecionada(t));
        cursoBloc.add(LicaoSelecionada(l));
        Navigator.of(context).pop();
      },
      onQuiz: () {
        Navigator.of(sheet).pop();
        final pool = st.trilhas[t].licoes.expand((li) => li.trechos.map((tr) => tr.cod)).toList();
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => QuizPage(trilhaIdx: t, licaoIdx: l, licao: licao, poolTrilha: pool),
        ));
      },
    ),
  );
}

class _Rotulo extends StatelessWidget {
  final String nome;
  final bool feita, atual;
  final int? nota;
  final bool alinhaDireita;
  final VoidCallback onTap;
  const _Rotulo(
      {required this.nome,
      required this.feita,
      required this.atual,
      this.nota,
      required this.alinhaDireita,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Column(
        crossAxisAlignment: alinhaDireita ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            nome,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alinhaDireita ? TextAlign.right : TextAlign.left,
            style: Mixart.ui(
              size: 12.5,
              weight: atual ? FontWeight.w700 : FontWeight.w600,
              color: atual
                  ? Mixart.brand
                  : feita
                      ? Mixart.text
                      : Mixart.textFaint,
            ),
          ),
          if (atual)
            Text('você está aqui', style: Mixart.ui(size: 10, weight: FontWeight.w600, color: Mixart.brand))
          else if (nota != null)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.star, size: 10, color: nota! >= 8 ? Mixart.brand : Mixart.textMuted),
              const SizedBox(width: 2),
              Text('$nota/10',
                  style: Mixart.ui(size: 10, weight: FontWeight.w600, color: nota! >= 8 ? Mixart.brand : Mixart.textMuted)),
            ]),
        ],
      ),
      ),
    );
  }
}

class _NoLicao extends StatefulWidget {
  final String emoji;
  final bool feita, atual;
  final int? nota;
  final VoidCallback onTap;
  const _NoLicao(
      {required this.emoji, required this.feita, required this.atual, this.nota, required this.onTap});

  @override
  State<_NoLicao> createState() => _NoLicaoState();
}

class _NoLicaoState extends State<_NoLicao> with SingleTickerProviderStateMixin {
  AnimationController? _pulso;

  @override
  void initState() {
    super.initState();
    if (widget.atual) {
      _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulso?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tam = _CaminhoLicoes._no;

    Widget miolo;
    BoxDecoration deco;
    List<BoxShadow> sombra = const [];

    if (widget.feita) {
      deco = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD766), Mixart.brand],
        ),
        shape: BoxShape.circle,
      );
      sombra = const [BoxShadow(color: Color(0x55FFC73B), blurRadius: 16, spreadRadius: -2)];
      miolo = Icon(Icons.check_rounded, size: 26, color: Mixart.onBrand);
    } else if (widget.atual) {
      deco = BoxDecoration(
        color: Mixart.brandSub,
        shape: BoxShape.circle,
        border: Border.all(color: Mixart.brand, width: 2.5),
      );
      miolo = const Padding(padding: EdgeInsets.all(9), child: Pacman(tamanho: 26));
    } else {
      deco = BoxDecoration(
        color: Mixart.surfaceHi,
        shape: BoxShape.circle,
        border: Border.all(color: Mixart.border),
      );
      miolo = Opacity(opacity: .55, child: Text(widget.emoji, style: const TextStyle(fontSize: 20)));
    }

    Widget circulo = Container(
      width: tam,
      height: tam,
      alignment: Alignment.center,
      decoration: deco.copyWith(boxShadow: sombra),
      child: miolo,
    );

    if (widget.atual && _pulso != null) {
      // anel de brilho pulsante atrás do Pac-Man
      circulo = Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
        AnimatedBuilder(
          animation: _pulso!,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_pulso!.value);
            return Container(
              width: tam + 14 + t * 10,
              height: tam + 14 + t * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Mixart.brand.withValues(alpha: .35 - t * .25), width: 2),
              ),
            );
          },
        ),
        circulo,
      ]);
    }

    return InkWell(
      onTap: widget.onTap,
      customBorder: const CircleBorder(),
      child: Stack(clipBehavior: Clip.none, children: [
        circulo,
        if (widget.nota != null && widget.nota! >= 8)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Mixart.bg, shape: BoxShape.circle),
              child: Icon(Icons.star, size: 14, color: Mixart.brand),
            ),
          ),
      ]),
    );
  }
}

/// Linha do caminho: trecho percorrido em amarelo com brilho, resto tracejado.
class _TrilhoPainter extends CustomPainter {
  final List<Offset> pontos;
  final List<bool> feitas;
  _TrilhoPainter({required this.pontos, required this.feitas});

  @override
  void paint(Canvas canvas, Size size) {
    if (pontos.length < 2) return;
    final glow = Paint()
      ..color = const Color(0x33FFC73B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final feito = Paint()
      ..color = Mixart.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final pendente = Paint()
      ..color = Mixart.surfaceHi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < pontos.length - 1; i++) {
      final a = pontos[i], b = pontos[i + 1];
      final meioY = (a.dy + b.dy) / 2;
      final caminho = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, meioY, b.dx, meioY, b.dx, b.dy);
      if (feitas[i]) {
        canvas.drawPath(caminho, glow);
        canvas.drawPath(caminho, feito);
      } else {
        _tracejado(canvas, caminho, pendente);
      }
    }
  }

  void _tracejado(Canvas canvas, Path caminho, Paint p) {
    for (final metric in caminho.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final fim = math.min(dist + 7, metric.length);
        canvas.drawPath(metric.extractPath(dist, fim), p);
        dist += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_TrilhoPainter old) => old.pontos != pontos || old.feitas != feitas;
}

// ───────────────────────── folha da lição ─────────────────────────
class _LicaoSheet extends StatelessWidget {
  final Licao licao;
  final bool feita;
  final int? nota;
  final VoidCallback onTeoria, onPraticar, onQuiz;
  const _LicaoSheet(
      {required this.licao,
      required this.feita,
      this.nota,
      required this.onTeoria,
      required this.onPraticar,
      required this.onQuiz});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Mixart.surfaceHi, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: feita ? Mixart.brand : Mixart.surfaceHi,
                shape: BoxShape.circle,
                border: Border.all(color: feita ? Mixart.brand : Mixart.border),
              ),
              child: feita
                  ? Icon(Icons.check_rounded, color: Mixart.onBrand, size: 24)
                  : Text(licao.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(licao.nome, style: Mixart.display(size: 19)),
                Text('${licao.trechos.length} exercícios${feita ? ' · concluída' : ''}',
                    style: Mixart.ui(size: 12, color: feita ? Mixart.brand : Mixart.textMuted)),
              ]),
            ),
            if (nota != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Mixart.brandSub,
                  border: Border.all(color: Mixart.brandDim),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star, size: 13, color: Mixart.brand),
                  const SizedBox(width: 4),
                  Text('$nota/10', style: Mixart.ui(size: 11.5, weight: FontWeight.w700, color: Mixart.brand)),
                ]),
              ),
          ]),
          if (licao.resumo.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Mixart.bg,
                border: Border.all(color: Mixart.border),
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.menu_book_outlined, size: 16, color: Mixart.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(licao.resumo,
                      style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5)),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          if (licao.temTeoria) ...[
            _OpcaoSheet(
              icone: Icons.menu_book_outlined,
              titulo: 'Teoria (Nivelamento)',
              subtitulo: 'entenda o conceito antes de digitar',
              destaque: true,
              onTap: onTeoria,
            ),
            const SizedBox(height: 10),
          ],
          _OpcaoSheet(
            icone: Icons.keyboard_alt_outlined,
            titulo: feita ? 'Praticar de novo' : 'Praticar lição',
            subtitulo: 'digite os exercícios com o Pac-Man',
            destaque: !licao.temTeoria,
            onTap: onPraticar,
          ),
          const SizedBox(height: 10),
          _OpcaoSheet(
            icone: Icons.quiz_outlined,
            titulo: 'Quiz da lição',
            subtitulo: nota != null
                ? 'seu recorde: $nota/10 — tente superar'
                : 'até 10 perguntas — escolha e digite o código certo',
            onTap: onQuiz,
          ),
        ]),
      ),
    );
  }
}

class _OpcaoSheet extends StatelessWidget {
  final IconData icone;
  final String titulo, subtitulo;
  final bool destaque;
  final VoidCallback onTap;
  const _OpcaoSheet(
      {required this.icone,
      required this.titulo,
      required this.subtitulo,
      this.destaque = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: destaque ? Mixart.brandSub : Mixart.surface,
            border: Border.all(color: destaque ? Mixart.brandDim : Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Mixart.brand, shape: BoxShape.circle),
              child: Icon(icone, size: 20, color: Mixart.onBrand),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo, style: Mixart.ui(size: 14.5, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitulo, style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
              ]),
            ),
            Icon(Icons.chevron_right, size: 18, color: Mixart.textFaint),
          ]),
        ),
      );
}

// ───────────────────────── conector entre trilhas ─────────────────────────
class _Conector extends StatelessWidget {
  const _Conector();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 30,
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 3,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(color: Mixart.surfaceHi, borderRadius: BorderRadius.circular(2)),
              ),
          ]),
        ),
      );
}

// ───────────────────────── auxiliares ─────────────────────────
class _AnelProgresso extends StatelessWidget {
  final double pct;
  final double tamanho;
  final String? texto;
  final bool grosso;
  const _AnelProgresso({required this.pct, required this.tamanho, this.texto, this.grosso = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: tamanho,
        height: tamanho,
        child: Stack(fit: StackFit.expand, children: [
          CircularProgressIndicator(
            value: pct,
            strokeWidth: grosso ? 6 : 4,
            backgroundColor: Mixart.surfaceHi,
            color: Mixart.brand,
            strokeCap: StrokeCap.round,
          ),
          if (texto != null)
            Center(child: Text(texto!, style: Mixart.display(size: tamanho * .26, color: Mixart.text))),
        ]),
      );
}

/// Fundo com pontos discretos + um brilho radial no topo, para dar profundidade.
class _FundoPontilhado extends StatelessWidget {
  const _FundoPontilhado();
  @override
  Widget build(BuildContext context) => const CustomPaint(painter: _PontosPainter());
}

class _PontosPainter extends CustomPainter {
  const _PontosPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final brilho = Paint()
      ..shader = const RadialGradient(colors: [Color(0x14FFC73B), Color(0x00FFC73B)]).createShader(
        Rect.fromCircle(center: Offset(size.width / 2, 40), radius: size.width * .7),
      );
    canvas.drawRect(Offset.zero & size, brilho);

    final ponto = Paint()..color = const Color(0x0DFFFFFF);
    const passo = 34.0;
    for (var y = 0.0; y < size.height; y += passo) {
      for (var x = 0.0; x < size.width; x += passo) {
        canvas.drawCircle(Offset(x, y), 1, ponto);
      }
    }
  }

  @override
  bool shouldRepaint(_PontosPainter old) => false;
}
