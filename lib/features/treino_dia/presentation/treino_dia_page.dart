import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../../core/ui/festa.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../habito/presentation/habito_cubit.dart';
import '../../ingles/presentation/ouvir/ouvir_acoes.dart' show tocarItens;
import '../../ingles/presentation/ouvir/ouvir_cubit.dart';
import '../../ingles/presentation/ouvir/ouvir_state.dart';
import '../domain/montar_plano.dart';
import '../domain/plano_treino.dart';
import 'blocos_treino.dart';
import 'treino_dia_cubit.dart';
import 'widgets/cartao_bloco.dart';
import 'widgets/painel_ouvir_treino.dart';

/// O hub do "⚡ Treino do dia": monta (ou retoma) o plano de hoje, mostra as etapas e abre uma por vez
/// (sem emendar sozinho). Uma rota só para a sessão inteira; o 🎧 Ouvir roda aqui dentro
/// ([PainelOuvirTreino]).
///
/// A ordem ao abrir (FASE-9 §9.1): primeiro o plano salvo (`carregar`, aparelho + nuvem) — com o de
/// hoje, retoma; sem ele, espera as fontes ([lerFontes]) e monta. Passados 8 s sem tudo pronto, oferece
/// "Tentar de novo" e "Começar assim mesmo" (plano `incompleto`, completado depois).
class TreinoDiaPage extends StatefulWidget {
  const TreinoDiaPage({super.key});

  /// Depois deste tempo montando, a tela oferece "Tentar de novo" / "Começar assim mesmo".
  static const demora = Duration(seconds: 8);

  @override
  State<TreinoDiaPage> createState() => _TreinoDiaPageState();
}

enum _Fase { montando, pronto }

/// Para que dia de plano a sessão do 🎧 Ouvir do treino foi aberta, por player — sobrevive à página
/// fechada (a sessão segue tocando). A fonte da sessão é só `avulso` + título, sem dia.
final _diaDaSessaoOuvir = Expando<int>('diaDaSessaoOuvir');

class _TreinoDiaPageState extends State<TreinoDiaPage> {
  TreinoDiaCubit? _treino;
  HabitoCubit? _habito;
  OuvirCubit? _ouvir;
  CursoBloc? _curso;

  _Fase _fase = _Fase.montando;
  bool _demorando = false;
  Timer? _relogio;

  /// "Começar assim mesmo" tocado: os botões somem e a tela diz "Começando…" até montar.
  bool _comecando = false;

  /// Uma etapa está aberta por cima (os botões esperam ela voltar).
  bool _rodando = false;

  /// O 🎧 Ouvir está tocando aqui dentro (o painel no lugar dos cartões).
  bool _ouvindo = false;

  /// As faixas da sessão do Ouvir do treino (o alvo; metade dele vale quando param por fora).
  int _alvoOuvir = 0;

  /// O Ouvir parou antes da metade: o botão vira "▶ Ouvir de novo".
  bool _ouvirDeNovo = false;

  /// A faixa de aviso depois de uma etapa ("✓ Revisão feita! Próximo: …").
  String? _aviso;

  /// O bônus desta sessão: true = ganhou agora; false = o plano valia, mas a conta já tinha ganhado hoje.
  bool? _bonusGanho;

  /// Ao abrir, o treino de hoje já estava completo ("Volte amanhã…").
  bool _jaEstavaCompleto = false;

  @override
  void initState() {
    super.initState();
    _treino = TreinoDiaCubit.de(context);
    _habito = HabitoCubit.de(context);
    _ouvir = OuvirCubit.de(context);
    try {
      _curso = BlocProvider.of<CursoBloc>(context, listen: false);
    } catch (_) {}
    if (_treino != null) unawaited(_preparar());
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  int get _agoraMs => _treino!.agora().millisecondsSinceEpoch;

  // ── montar / retomar ────────────────────────────────────────────────────

  void _armarRelogio() {
    _relogio?.cancel();
    _relogio = Timer(TreinoDiaPage.demora, () {
      if (mounted && _fase == _Fase.montando) setState(() => _demorando = true);
    });
  }

  Future<void> _preparar() async {
    final t = _treino!;
    _armarRelogio();
    // o plano salvo ANTES de tudo: sem isso um plano de hoje (2/4 em outro aparelho) seria trocado
    await t.carregar();
    if (!mounted || _fase != _Fase.montando) return;
    final hoje = t.planoDeHoje;
    if (hoje != null) {
      _pronto(retomado: true);
      // um plano já concluído (até o curto) fica como está: "Feito hoje ✓ — volte amanhã"
      if (!hoje.concluido && (hoje.incompleto || hoje.curto) && !hoje.algumAtivoResolvido) {
        unawaited(_completarComFontes());
      }
      return;
    }
    final f = await lerFontes(context);
    if (!mounted || _fase != _Fase.montando) return;
    _montar(f);
  }

  /// "Começar assim mesmo": monta com o que já carregou (o plano fica `incompleto`).
  Future<void> _comecarAssimMesmo() async {
    final t = _treino!;
    if (_comecando) return;
    setState(() => _comecando = true);
    // o `carregar` da nuvem tem prazo próprio (o repositório cai no aparelho): esta espera termina
    await t.carregar();
    if (!mounted || _fase != _Fase.montando) return;
    if (t.planoDeHoje != null) return _pronto(retomado: true);
    final f = await lerFontes(context, ate: Duration.zero);
    if (!mounted || _fase != _Fase.montando) return;
    _montar(f);
  }

  void _tentarDeNovo() {
    setState(() => _demorando = false);
    _armarRelogio();
  }

  void _montar(FontesTreino f) {
    final t = _treino!;
    if (t.planoDeHoje == null) {
      t.iniciar(() => montarPlano(f, dia: t.hoje, curso: t.curso, agoraMs: _agoraMs));
    }
    _pronto(retomado: false);
  }

  void _pronto({required bool retomado}) {
    _relogio?.cancel();
    final p = _treino!.state.plano;
    setState(() {
      _fase = _Fase.pronto;
      _demorando = false;
      _comecando = false;
      _jaEstavaCompleto = retomado && (p?.concluido ?? false);
    });
    _retomarOuvir();
    _talvezBonus();
  }

  /// Um plano `incompleto` (ou curto) ganha as etapas ativas que faltavam, enquanto nenhuma foi feita
  /// e ele não está concluído.
  Future<void> _completarComFontes({Duration? ate}) async {
    final f = await lerFontes(context, ate: ate);
    final t = _treino!;
    final p = t.state.plano;
    if (p == null || p.concluido || p.algumAtivoResolvido) return;
    t.completar((atual) => completarPlano(atual, f, agoraMs: _agoraMs));
    if (mounted) setState(() {});
  }

  // ── as etapas ───────────────────────────────────────────────────────────

  Future<void> _rodarProximo() async {
    final t = _treino!;
    if (_rodando || _ouvindo) return;
    var p = t.state.plano;
    if (p == null) return;
    setState(() {
      _rodando = true;
      _aviso = null;
    });
    try {
      // as fontes que faltavam podem ter chegado: as etapas novas entram na frente e vão primeiro
      if (p.incompleto && !p.algumAtivoResolvido) {
        await _completarComFontes(ate: Duration.zero);
        if (!mounted) return;
        p = t.state.plano ?? p;
      }
      final b = p.proximo;
      if (b == null) return;
      if (b.tipo == TipoBloco.ouvir) {
        _comecarOuvir(b, p);
        return;
      }
      // o player do curso tocando pausa (o pausar guarda a posição) — a etapa tem voz própria
      final o = _ouvir;
      if (o != null && o.state.status == StatusOuvir.tocando && !ehDoTreino(o.state)) o.pausar();
      FimDoBloco fim;
      try {
        fim = await switch (b.tipo) {
          TipoBloco.revisao => rodarRevisao(context),
          TipoBloco.palavras => rodarPalavras(context),
          TipoBloco.rali => rodarRali(context, p),
          TipoBloco.quiz => rodarQuiz(context, b, p.dia),
          TipoBloco.ouvir => Future.value(const BlocoInterrompido()),
        };
      } catch (_) {
        fim = const BlocoInterrompido();
      }
      // a página pode ter saído enquanto a etapa estava aberta: o plano anota mesmo assim
      _aplicar(b, fim);
    } finally {
      if (mounted) setState(() => _rodando = false);
    }
  }

  void _aplicar(BlocoTreino b, FimDoBloco fim) {
    final t = _treino!;
    String? aviso;
    switch (fim) {
      case BlocoFeito(:final resultado, :final total, :final chavesOuvir, :final foco):
        if (chavesOuvir.isNotEmpty) t.anotarOuvir(chavesOuvir);
        if (foco.isNotEmpty) t.anotarFoco(foco);
        t.marcar(b.id, EstadoBloco.feito, resultado: resultado, total: total);
        aviso = '✓ ${_feito(b)}!${_proximoTexto()}';
      case BlocoVazio(aviso: final texto):
        t.marcar(b.id, EstadoBloco.feito, resultado: 0, vazio: true);
        aviso = '$texto${_proximoTexto()}';
      case BlocoInterrompido():
        aviso = null;
    }
    _talvezBonus();
    if (mounted) setState(() => _aviso = aviso);
  }

  void _pular(BlocoTreino b) {
    final t = _treino!;
    if (b.tipo == TipoBloco.ouvir) _pararOuvir();
    t.marcar(b.id, EstadoBloco.pulado);
    _talvezBonus();
    setState(() => _aviso = '⏭ Etapa pulada.${_proximoTexto()}');
  }

  String _proximoTexto() {
    final prox = _treino!.state.plano?.proximo;
    return prox == null ? '' : ' Próximo: ${_tituloCurto(prox)}';
  }

  /// Concluído e valendo: marca o plano ANTES (gravado) e só então pede o bônus ao hábito, que tem a
  /// trava de 1× por conta por dia.
  void _talvezBonus() {
    final t = _treino!;
    final p = t.state.plano;
    if (p == null || !p.concluido) return;
    if (t.tomarBonus()) _bonusGanho = _habito?.ganharBonusTreino(bonusTreino) ?? false;
  }

  // ── 🎧 Ouvir ────────────────────────────────────────────────────────────

  BlocoTreino? get _blocoOuvir {
    for (final b in _treino!.state.plano?.blocos ?? const <BlocoTreino>[]) {
      if (b.tipo == TipoBloco.ouvir) return b;
    }
    return null;
  }

  void _comecarOuvir(BlocoTreino b, PlanoTreino p) {
    final o = _ouvir;
    final st = _curso?.state;
    if (o == null || st == null) return _aplicar(b, const BlocoVazio(AvisosTreino.semOuvir));
    // já tocando (saiu da página no meio e voltou): só reata, sem recomeçar do zero; a de outro dia
    // (o app aberto virou a meia-noite) fecha e a de hoje toca do começo
    if (ehDoTreino(o.state) && o.state.ativo) {
      if (_sessaoDoPlano(o, p)) return _retomarOuvir();
      o.fechar();
    }
    // outra sessão (curso, setlist) fecha antes: o fechar guarda a posição dela
    if (o.state.ativo && o.state.fonte?.id != 'avulso') o.fechar();
    final itens = trechoParaOuvir(st, p);
    if (itens.isEmpty) return _aplicar(b, const BlocoVazio(AvisosTreino.semOuvir));
    unawaited(tocarItens(context, itens, titulo: tituloOuvirTreino));
    _diaDaSessaoOuvir[o] = p.dia;
    // o alvo são as FAIXAS (um item `doTrecho` vira várias), lidas depois de tocar
    if (!ehDoTreino(o.state) || o.state.fila.isEmpty) return _aplicar(b, const BlocoVazio(AvisosTreino.semOuvir));
    setState(() {
      _alvoOuvir = o.state.fila.length;
      _ouvirDeNovo = false;
      _ouvindo = true;
    });
  }

  /// A sessão do treino que está no player foi aberta para o dia de [p] (e não é a de ontem que ficou
  /// lá, com o app aberto desde antes da meia-noite).
  bool _sessaoDoPlano(OuvirCubit o, PlanoTreino? p) =>
      p != null && ehDoTreino(o.state) && _diaDaSessaoOuvir[o] == p.dia;

  /// Ao abrir: a sessão do treino que ficou tocando é reatada; se ela acabou enquanto a página estava
  /// fechada, a etapa fica feita. Só a sessão aberta para o dia DESTE plano ([_sessaoDoPlano]).
  void _retomarOuvir() {
    final o = _ouvir;
    final b = _blocoOuvir;
    if (o == null || b == null || b.resolvido || !o.state.ativo) return;
    if (!_sessaoDoPlano(o, _treino!.state.plano)) return;
    if (o.state.status == StatusOuvir.acabou) {
      final k = o.state.ouvidas > 0 ? o.state.ouvidas : o.state.fila.length;
      o.fechar();
      _aplicar(b, BlocoFeito(resultado: k));
      return;
    }
    if (_treino!.state.plano?.proximo?.id != b.id) return;
    setState(() {
      _alvoOuvir = o.state.fila.length;
      _ouvindo = true;
    });
  }

  void _ouvirTerminou(int ouvidas) {
    final b = _blocoOuvir;
    if (!_ouvindo || b == null || b.resolvido) return;
    setState(() => _ouvindo = false);
    _ouvir?.fechar();
    _aplicar(b, BlocoFeito(resultado: ouvidas));
  }

  /// Fechado por fora: com metade das frases ouvidas vale; senão volta a pendente ("Ouvir de novo").
  void _ouvirParou(int ouvidas) {
    final b = _blocoOuvir;
    if (!_ouvindo || b == null || b.resolvido) return;
    setState(() => _ouvindo = false);
    if (_alvoOuvir > 0 && ouvidas >= (_alvoOuvir / 2).ceil()) {
      _aplicar(b, BlocoFeito(resultado: ouvidas));
    } else {
      setState(() {
        _ouvirDeNovo = true;
        _aviso = 'O 🎧 Ouvir parou no começo — toque em “Ouvir de novo” ou pule esta etapa.';
      });
    }
  }

  void _pararOuvir() {
    if (!_ouvindo) return;
    setState(() => _ouvindo = false);
    final o = _ouvir;
    if (o != null && ehDoTreino(o.state)) o.fechar();
  }

  // ── textos ──────────────────────────────────────────────────────────────

  String _emoji(BlocoTreino b) => switch (b.tipo) {
        TipoBloco.revisao => '🔁',
        TipoBloco.palavras => '🔥',
        TipoBloco.ouvir => '🎧',
        TipoBloco.rali => '🏁',
        TipoBloco.quiz => '🧩',
      };

  String _nomeCurto(BlocoTreino b) => switch (b.tipo) {
        TipoBloco.revisao => 'Revisão',
        TipoBloco.palavras => 'Palavras',
        TipoBloco.ouvir => 'Ouvir',
        TipoBloco.rali => 'Rali',
        TipoBloco.quiz => 'Quiz',
      };

  String _tituloCurto(BlocoTreino b) => '${_emoji(b)} ${_nomeCurto(b)}';

  String _feito(BlocoTreino b) => switch (b.tipo) {
        TipoBloco.revisao => 'Revisão feita',
        TipoBloco.palavras => 'Palavras feitas',
        TipoBloco.ouvir => 'Ouvir feito',
        TipoBloco.rali => 'Rali feito',
        TipoBloco.quiz => 'Quiz feito',
      };

  String? _nomeDaLicao(BlocoTreino b) {
    final st = _curso?.state;
    if (st == null || b.t < 0 || b.t >= st.trilhas.length) return null;
    final ls = st.trilhas[b.t].licoes;
    return b.l < 0 || b.l >= ls.length ? null : ls[b.l].nome;
  }

  String _titulo(BlocoTreino b) => switch (b.tipo) {
        TipoBloco.revisao => 'Revisão do dia',
        TipoBloco.palavras => 'Palavras',
        TipoBloco.ouvir => 'Ouvir',
        TipoBloco.rali => 'Rali relâmpago',
        TipoBloco.quiz => _nomeDaLicao(b) == null ? 'Quiz de revisão' : 'Quiz · ${_nomeDaLicao(b)}',
      };

  String _subtitulo(BlocoTreino b, PlanoTreino p) {
    String n(int k, String um, String varios) => '$k ${k == 1 ? um : varios}';
    switch (b.tipo) {
      case TipoBloco.revisao:
        return [
          if (b.qtd > 0) n(b.qtd, 'frase de memória', 'frases de memória'),
          if (b.qtd2 > 0) n(b.qtd2, 'cartão', 'cartões'),
          '~${b.minutos} min',
        ].join(' · ');
      case TipoBloco.palavras:
        return 'até ${b.qtd > 0 ? b.qtd : LimitesTreino.palavras} palavras · ~${b.minutos} min';
      case TipoBloco.ouvir:
        return '${n(b.qtd > 0 ? b.qtd : LimitesTreino.ouvir, 'frase', 'frases')} para ouvir · ~${b.minutos} min';
      case TipoBloco.rali:
        return p.curso == 'ingles'
            ? '1 fase com as suas palavras · ~${b.minutos} min'
            : '1 fase digitando código · ~${b.minutos} min';
      case TipoBloco.quiz:
        return 'até ${b.qtd > 0 ? b.qtd : 10} perguntas · ~${b.minutos} min';
    }
  }

  /// O texto depois de "✓ Feito · ".
  String? _resultado(BlocoTreino b) {
    if (b.estado != EstadoBloco.feito) return null;
    if (b.vazio) return b.tipo == TipoBloco.revisao ? 'em dia' : 'nada pendente';
    final k = b.resultado;
    return switch (b.tipo) {
      TipoBloco.revisao => '$k ${k == 1 ? 'revisada' : 'revisadas'}',
      TipoBloco.palavras => '$k ${k == 1 ? 'palavra' : 'palavras'}',
      TipoBloco.ouvir => '$k ${k == 1 ? 'frase ouvida' : 'frases ouvidas'}',
      TipoBloco.rali => k > 0 ? '$k pts' : 'jogou',
      TipoBloco.quiz => '$k/${b.total}',
    };
  }

  /// O selo do resumo final.
  String _resumo(BlocoTreino b) {
    if (b.estado == EstadoBloco.pulado) return '⏭ ${_nomeCurto(b)}';
    if (b.vazio) return '${_emoji(b)} em dia';
    final k = b.resultado;
    return switch (b.tipo) {
      TipoBloco.revisao => '🔁 $k ${k == 1 ? 'frase' : 'frases'}',
      TipoBloco.palavras => '🔥 $k ${k == 1 ? 'palavra' : 'palavras'}',
      TipoBloco.ouvir => '🎧 $k ${k == 1 ? 'ouvida' : 'ouvidas'}',
      TipoBloco.rali => k > 0 ? '🏁 $k pts' : '🏁 jogou',
      TipoBloco.quiz => '🧩 $k/${b.total}',
    };
  }

  static const _semana = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
  static const _meses = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

  /// "ter, 21 out".
  String get _data {
    final d = _treino!.agora();
    return '${_semana[d.weekday - 1]}, ${d.day} ${_meses[d.month - 1]}';
  }

  // ── tela ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = _treino;
    return Scaffold(
      key: const Key('treino-dia-pagina'),
      backgroundColor: Mixart.bg,
      appBar: AppBar(
        backgroundColor: Mixart.bg,
        foregroundColor: Mixart.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Fechar o treino',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('⚡ Treino do dia', style: Mixart.display(size: 18)),
      ),
      body: t == null
          ? Center(
              child: Text('O treino do dia não está disponível aqui.', style: Mixart.ui(color: Mixart.textMuted)))
          : BlocBuilder<TreinoDiaCubit, TreinoDiaState>(
              bloc: t,
              builder: (context, s) {
                final p = s.plano;
                if (_fase == _Fase.montando || p == null) return _montando();
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: p.concluido ? _fim(p) : _hub(p),
                  ),
                );
              },
            ),
    );
  }

  Widget _montando() {
    return Center(
      key: const Key('treino-dia-montando'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3, color: Mixart.brand),
            ),
            const SizedBox(height: 18),
            Text('Montando seu treino…',
                textAlign: TextAlign.center, style: Mixart.display(size: 17, color: Mixart.text)),
            if (_comecando) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text('Começando…',
                    key: const Key('treino-dia-comecando'),
                    textAlign: TextAlign.center,
                    style: Mixart.ui(size: 13.5, color: Mixart.textMuted)),
              ),
            ] else if (_demorando) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text('Está demorando um pouco…',
                    key: const Key('treino-dia-demorando'),
                    textAlign: TextAlign.center,
                    style: Mixart.ui(size: 13.5, color: Mixart.textMuted)),
              ),
              const SizedBox(height: 20),
              Botao3D(
                key: const Key('treino-dia-tentar'),
                rotulo: 'Tentar de novo',
                contorno: true,
                onTap: _tentarDeNovo,
              ),
              const SizedBox(height: 12),
              Botao3D(
                key: const Key('treino-dia-comecar-assim'),
                rotulo: 'Começar assim mesmo',
                onTap: () => unawaited(_comecarAssimMesmo()),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _hub(PlanoTreino p) {
    final prox = p.proximo;
    final n = p.blocos.length;
    final rotulo = p.resolvidos == 0 && !_ouvirDeNovo
        ? '▶ Começar'
        : prox?.tipo == TipoBloco.ouvir && _ouvirDeNovo
            ? '▶ Ouvir de novo'
            : '▶ Continuar · ${prox == null ? '' : _tituloCurto(prox)}';
    return ListView(
      key: const Key('treino-dia-lista'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Text('~${p.minutos} min · $n ${n == 1 ? 'etapa' : 'etapas'} · $_data',
            key: const Key('treino-dia-subtitulo'), style: Mixart.ui(size: 13, color: Mixart.textMuted)),
        const SizedBox(height: 12),
        _BarraEtapas(plano: p, titulo: _titulo),
        if (_aviso != null) ...[
          const SizedBox(height: 14),
          _Faixa(key: const Key('treino-dia-aviso'), texto: _aviso!),
        ],
        if (p.curto) ...[
          const SizedBox(height: 14),
          const _Faixa(
            key: Key('treino-dia-curto'),
            texto: 'Ainda há pouco para revisar — o treino de hoje é curto. Depois, siga para a sua próxima '
                'lição ✍️.',
            discreta: true,
          ),
        ],
        const SizedBox(height: 16),
        if (_ouvindo && _ouvir != null)
          PainelOuvirTreino(
            ouvir: _ouvir!,
            aoTerminar: _ouvirTerminou,
            aoParar: _ouvirParou,
            aoPular: () {
              final b = _blocoOuvir;
              if (b != null) _pular(b);
            },
          )
        else ...[
          for (final b in p.blocos) ...[
            CartaoBloco(
              bloco: b,
              emoji: _emoji(b),
              titulo: _titulo(b),
              subtitulo: _subtitulo(b, p),
              resultado: _resultado(b),
              atual: prox?.id == b.id,
              onPular: prox?.id == b.id && !_rodando ? () => _pular(b) : null,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          if (prox != null)
            Botao3D(
              key: const Key('treino-dia-comecar'),
              rotulo: rotulo,
              onTap: _rodando ? null : () => unawaited(_rodarProximo()),
            ),
        ],
      ],
    );
  }

  Widget _fim(PlanoTreino p) {
    final valeu = p.feitos >= 1;
    final h = _habito;
    final String? linhaBonus = _bonusGanho == true
        ? '+$bonusTreino na meta pelo treino completo ⚡'
        : (_bonusGanho == false || (_bonusGanho == null && p.bonus))
            ? 'Bônus do treino já ganho hoje ✓'
            : null;
    return Stack(children: [
      ListView(
        key: const Key('treino-dia-fim'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Center(child: Text(valeu ? '⚡' : '🌤️', style: const TextStyle(fontSize: 52))),
          const SizedBox(height: 8),
          Text(valeu ? 'Treino do dia completo! ⚡' : 'Hoje foi só uma passada',
              key: const Key('treino-dia-fim-titulo'),
              textAlign: TextAlign.center,
              style: Mixart.display(size: 24)),
          const SizedBox(height: 6),
          Text(
            _jaEstavaCompleto
                ? 'Volte amanhã para um treino novo 🌅'
                : valeu
                    ? 'Mandou bem — ${p.feitos} de ${p.blocos.length} ${p.blocos.length == 1 ? 'etapa feita' : 'etapas feitas'}.'
                    : 'Tudo bem pular às vezes. Que tal uma lição agora?',
            key: const Key('treino-dia-fim-sub'),
            textAlign: TextAlign.center,
            style: Mixart.ui(size: 14, color: Mixart.textMuted).copyWith(height: 1.4),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in p.blocos)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: b.feitoDeVerdade ? Mixart.brandSub : Mixart.surfaceHi,
                    border: Border.all(color: b.feitoDeVerdade ? Mixart.brandDim : Mixart.border),
                    borderRadius: BorderRadius.circular(Mixart.radiusChip),
                  ),
                  child: Text(_resumo(b),
                      style: Mixart.ui(
                          size: 13,
                          weight: FontWeight.w700,
                          color: b.feitoDeVerdade ? Mixart.text : Mixart.textMuted)),
                ),
            ],
          ),
          if (h != null) ...[
            const SizedBox(height: 18),
            BlocBuilder<HabitoCubit, HabitoState>(
              bloc: h,
              builder: (context, hs) {
                final agora = h.agora();
                final dias = hs.habito.sequenciaVisivel(agora);
                final feitas = hs.habito.feitasHoje(agora);
                return Container(
                  key: const Key('treino-dia-sequencia'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Mixart.surface,
                    border: Border.all(color: Mixart.border),
                    borderRadius: BorderRadius.circular(Mixart.radiusLg),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(dias > 0 ? '🔥 $dias ${dias == 1 ? 'dia seguido' : 'dias seguidos'}' : '🔥 Sua sequência começa hoje',
                        style: Mixart.display(size: 16)),
                    const SizedBox(height: 4),
                    Text('Meta de hoje: $feitas/${hs.habito.meta}',
                        key: const Key('treino-dia-meta'), style: Mixart.ui(size: 13, color: Mixart.textMuted)),
                    if (linhaBonus != null) ...[
                      const SizedBox(height: 8),
                      Text(linhaBonus,
                          key: const Key('treino-dia-bonus'),
                          style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)),
                    ],
                  ]),
                );
              },
            ),
          ],
          const SizedBox(height: 22),
          Botao3D(
            key: const Key('treino-dia-ir-licao'),
            rotulo: '✍️ Continuar minha lição',
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
          const SizedBox(height: 12),
          Botao3D(
            key: const Key('treino-dia-fechar'),
            rotulo: 'Fechar',
            contorno: true,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      if (valeu && !_jaEstavaCompleto) const Positioned.fill(child: Confete()),
    ]);
  }
}

/// A barra de etapas (`treino-dia-progresso`): feita = marca; pulada = apagada; a atual = contorno da
/// marca; pendente = superfície.
class _BarraEtapas extends StatelessWidget {
  final PlanoTreino plano;
  final String Function(BlocoTreino) titulo;
  const _BarraEtapas({required this.plano, required this.titulo});

  @override
  Widget build(BuildContext context) {
    final n = plano.blocos.length;
    final atual = plano.proximo?.id;
    return Row(
      key: const Key('treino-dia-progresso'),
      children: [
        for (var i = 0; i < n; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _segmento(plano.blocos[i], i, n, plano.blocos[i].id == atual)),
        ],
      ],
    );
  }

  Widget _segmento(BlocoTreino b, int i, int n, bool atual) {
    final estado = switch (b.estado) {
      EstadoBloco.feito => 'feita',
      EstadoBloco.pulado => 'pulada',
      EstadoBloco.pendente => atual ? 'agora' : 'pendente',
    };
    final (Color cor, Color borda) = switch (b.estado) {
      EstadoBloco.feito => (Mixart.brand, Mixart.brand),
      EstadoBloco.pulado => (Mixart.border.withValues(alpha: .55), Mixart.border),
      EstadoBloco.pendente => atual ? (Mixart.surface, Mixart.brand) : (Mixart.surfaceHi, Mixart.border),
    };
    return Semantics(
      container: true,
      label: 'Etapa ${i + 1} de $n: ${titulo(b)}, $estado',
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: cor,
          border: Border.all(color: borda, width: atual ? 1.6 : 1),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

/// Uma faixa de texto (o aviso depois de uma etapa, a dica do treino curto).
class _Faixa extends StatelessWidget {
  final String texto;
  final bool discreta;
  const _Faixa({super.key, required this.texto, this.discreta = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: discreta ? Mixart.surface : Mixart.brandSub,
        border: Border.all(color: discreta ? Mixart.border : Mixart.brandDim),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Semantics(
        liveRegion: !discreta,
        child: Text(texto, style: Mixart.ui(size: 13.5, color: Mixart.text).copyWith(height: 1.4)),
      ),
    );
  }
}
