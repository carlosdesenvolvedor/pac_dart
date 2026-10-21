import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../habito/presentation/habito_cubit.dart';
import '../../ingles/data/reconhecedor_fala.dart';
import '../../ingles/data/voz_ingles.dart';
import '../../ingles/presentation/palavras_cubit.dart';
import '../domain/cenario.dart';
import '../domain/nivel_conversa.dart';
import '../domain/sessao_cenario.dart';
import 'cenario_cubit.dart';
import 'ia_cubit.dart';
import 'preferencias_conversa.dart';
import 'resumo_conversa.dart';
import 'widgets/bolha_conversa.dart';
import 'widgets/microfone_conversa.dart';

/// A Conversa com IA de um cenário: um personagem do palco faz o outro papel (rosto, boca e voz), a
/// pessoa responde em inglês (digitando ou pelo 🎤, que escreve no campo) e o Prof. Dash corrige cada
/// fala na hora, num campo separado. O resumo do fim é local. Sem [IaCubit] na árvore não abre.
class ConversaPage extends StatelessWidget {
  final Cenario cenario;

  /// O nível escolhido na lista ('' = o do progresso do aluno).
  final String nivel;

  /// A voz e o microfone (injetáveis nos testes; null = os de verdade).
  final VozIngles? voz;
  final ReconhecedorFala? reconhecedor;

  const ConversaPage({super.key, required this.cenario, this.nivel = '', this.voz, this.reconhecedor});

  /// Quem cria o microfone de verdade (o probe e os testes trocam).
  static ReconhecedorFala Function() fabricaReconhecedor = ReconhecedorFala.navegador;

  /// O CursoBloc da árvore, ou null (testes de tela sem curso).
  static CursoBloc? _curso(BuildContext context) {
    try {
      return context.read<CursoBloc>();
    } catch (_) {
      return null;
    }
  }

  /// O nível da conversa: o [nivel] pedido; senão o da fronteira do aluno (com o curso na árvore); senão
  /// o da etapa do cenário.
  String _nivelEfetivo(CursoBloc? curso) {
    if (niveisConversa.contains(nivel)) return nivel;
    final aluno = curso != null
        ? nivelDoAluno(trilhas: curso.state.trilhas, concluidas: curso.state.concluidas)
        : codigoDoNivel(cenario.etapa);
    return nivelDaConversa(aluno: aluno);
  }

  @override
  Widget build(BuildContext context) {
    final ia = IaCubit.de(context);
    if (ia == null) return const Scaffold(body: SizedBox.shrink());
    final curso = _curso(context);
    final n = _nivelEfetivo(curso);
    final palavras = PalavrasCubit.de(context);
    // as palavras que o aluno já viu (vazio sem o cubit ou antes do índice ficar pronto)
    final vocabulario = palavras == null
        ? const <String>[]
        : vocabularioParaPrompt(palavras.palavrasDoAluno(curso?.state ?? const CursoState()).map((p) => p.en));
    final habito = HabitoCubit.de(context);
    return BlocProvider(
      create: (_) => CenarioCubit(
        ia: ia,
        cenario: cenario,
        nivel: n,
        vocabulario: vocabulario,
        aoPraticar: habito == null ? null : () => habito.praticou(),
      ),
      child: _Conversa(pagina: this),
    );
  }
}

class _Conversa extends StatefulWidget {
  final ConversaPage pagina;
  const _Conversa({required this.pagina});

  @override
  State<_Conversa> createState() => _ConversaState();
}

class _ConversaState extends State<_Conversa> {
  final _campo = TextEditingController();
  final _foco = FocusNode(debugLabel: 'fala da conversa');
  final _rolagem = ScrollController();

  late final VozIngles _voz = widget.pagina.voz ?? VozIngles();
  late final ReconhecedorFala _reconhecedor = widget.pagina.reconhecedor ?? ConversaPage.fabricaReconhecedor();

  /// A fala que o avatar do topo acompanha (nunca null: o 🔊 da correção e o player não mexem a boca dele).
  late String _noPalco = widget.pagina.cenario.abertura;

  /// Tradução de todas as falas (começa ligada em A1/A2) e as bolhas abertas uma a uma ("Ver tradução").
  late bool _traducao = nivelIniciante(context.read<CenarioCubit>().nivel);
  final _abertas = <int>{};

  /// Ler as falas novas em voz alta (pref do aparelho; padrão ligada).
  bool _vozAuto = true;

  /// O microfone está ouvindo (a voz automática fica quieta: o reconhecedor ouviria o personagem).
  bool _ouvindo = false;
  String _parcial = '';
  String _recado = '';

  /// O texto do campo quando o recado do microfone apareceu: mexeu no campo (digitou, tocou numa ideia), o
  /// recado sai e a faixa volta para as ideias.
  String _textoDoRecado = '';

  /// B1+: as ideias de resposta ficam atrás de um toque.
  bool _ideias = false;

  /// Quantos turnos a tela já viu (para saber quando chega uma fala nova do personagem).
  int _turnosVistos = 1;

  /// O relógio da janela de descanso: tique de 1 s só no aviso do limite (o único com contagem); nas outras
  /// janelas, um disparo no fim dela (para o Enviar voltar).
  Timer? _relogio;
  bool _relogioConta = false;

  /// A página está saindo (o microfone avisa que fechou no dispose: nada de setState aí).
  bool _saindo = false;
  double _insetAnterior = 0;

  /// O último erro que a tela viu (para saber quando chega um erro novo).
  ErroCenario _erroVisto = ErroCenario.nenhum;

  @override
  void initState() {
    super.initState();
    _campo.addListener(_aoEditarCampo);
    _iniciar();
  }

  void _aoEditarCampo() {
    if (_recado.isNotEmpty && _campo.text != _textoDoRecado) _mudar(() => _recado = '');
  }

  /// A velocidade da voz do aluno (até hoje só o palco lia) e a pref da voz automática; depois, a abertura.
  Future<void> _iniciar() async {
    await VozIngles.carregarPreferencia();
    final auto = await PreferenciasConversa.vozAuto();
    if (!mounted) return;
    setState(() => _vozAuto = auto);
    if (auto && !_ouvindo && _voz.somLiberado) unawaited(_voz.falar(widget.pagina.cenario.abertura));
  }

  @override
  void deactivate() {
    _saindo = true;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _saindo = false;
  }

  @override
  void dispose() {
    _relogio?.cancel();
    unawaited(_voz.parar());
    _campo.dispose();
    _foco.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  CenarioCubit get _cubit => context.read<CenarioCubit>();

  void _mudar(VoidCallback f) {
    if (mounted && !_saindo) setState(f);
  }

  /// O microfone abriu/fechou. O dispose dele (o rodapé some quando a conversa termina com ele aberto) chega
  /// no meio do fechamento da árvore: aí o setState fica para depois do quadro.
  void _aoMudarOuvindo(bool v) {
    _ouvindo = v;
    if (!v) _parcial = '';
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _mudar(() {}));
    } else {
      _mudar(() {});
    }
  }

  void _enviar() {
    final c = _cubit;
    final st = c.state;
    final t = _campo.text;
    // esperando a resposta, na janela de descanso ou sem falas: o texto fica no campo, nada é enviado nem apagado
    if (t.trim().isEmpty || st.aguardando || st.terminou || !st.sessao.podeFalar || c.emEspera) return;
    _campo.clear();
    setState(() => _recado = '');
    c.enviar(t);
  }

  void _preencher(String t) {
    _campo.text = t;
    _campo.selection = TextSelection.collapsed(offset: t.length);
  }

  void _rolarParaOFim() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_rolagem.hasClients) {
          _rolagem.animateTo(_rolagem.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });

  /// O relógio da janela de descanso. Só o aviso do limite (429 por minuto) mostra contagem: 1 tique por
  /// segundo enquanto a janela está aberta. Nas outras (o limite do dia vai até 12 h) nada muda na tela: um
  /// disparo só no fim da janela, para o Enviar voltar.
  void _garantirRelogio(CenarioState st) {
    final ate = st.esperaAte;
    if (ate == null || !_cubit.emEspera) {
      _relogio?.cancel();
      _relogio = null;
      return;
    }
    final contagem = st.erro == ErroCenario.limite;
    if (_relogio != null && _relogioConta == contagem) return;
    _relogio?.cancel();
    _relogioConta = contagem;
    if (contagem) {
      _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (!_cubit.emEspera) {
          _relogio?.cancel();
          _relogio = null;
        }
        setState(() {});
      });
    } else {
      _relogio = Timer(ate.difference(_cubit.agora()), () {
        _relogio = null;
        if (!mounted) return;
        setState(() {});
        // o relógio do cubit ainda não passou da janela (relógio injetado): confere de novo depois
        if (_cubit.emEspera) _garantirRelogio(_cubit.state);
      });
    }
  }

  void _aoMudar(BuildContext context, CenarioState st) {
    // a fala que não foi volta para o campo (ninguém digita de novo)
    final volta = st.falaPendente;
    if (volta != null && _campo.text.isEmpty) _preencher(volta);
    final ts = st.sessao.turnos;
    if (ts.length > _turnosVistos && !ts.last.doAluno) {
      // chegou a fala do personagem: o avatar do topo acompanha e, com a voz automática, ela é lida — mas
      // nunca com o microfone aberto (ele escreveria a fala do personagem no campo)
      final fala = ts.last.texto;
      setState(() => _noPalco = fala);
      if (_vozAuto && !_ouvindo) unawaited(_voz.falar(fala));
    }
    _turnosVistos = ts.length;
    // um erro novo (a fala que falhou) vale mais que o recado velho do microfone
    if (st.erro != ErroCenario.nenhum && st.erro != _erroVisto && _recado.isNotEmpty) setState(() => _recado = '');
    _erroVisto = st.erro;
    _garantirRelogio(st);
    _rolarParaOFim();
  }

  Future<void> _voltar() => Navigator.of(context).maybePop();

  Future<void> _confirmarSaida() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Mixart.surface,
        title: Text('Sair da conversa?', style: Mixart.display(size: 18)),
        content: Text('A conversa não fica salva. O que você já salvou como cartão continua.',
            style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.45)),
        actions: [
          TextButton(
            key: const Key('sair-conversa-continuar'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Continuar conversando', style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.brand)),
          ),
          TextButton(
            key: const Key('sair-conversa-confirmar'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sair', style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.danger)),
          ),
        ],
      ),
    );
    if (sair == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _alternarVoz() async {
    final v = !_vozAuto;
    setState(() => _vozAuto = v);
    if (!v) unawaited(_voz.parar());
    await PreferenciasConversa.salvarVozAuto(v);
  }

  void _deNovo() {
    final p = widget.pagina;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => ConversaPage(cenario: p.cenario, nivel: _cubit.nivel, voz: p.voz, reconhecedor: p.reconhecedor),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // o teclado abriu (ou fechou): a última fala continua à vista
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset != _insetAnterior) {
      _insetAnterior = inset;
      _rolarParaOFim();
    }
    final largo = MediaQuery.sizeOf(context).width >= 600;
    return BlocConsumer<CenarioCubit, CenarioState>(
      listener: _aoMudar,
      builder: (context, st) {
        final c = st.sessao.cenario;
        final falou = st.sessao.turnosDoAluno > 0;
        return PopScope(
          canPop: !(falou && !st.terminou),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmarSaida();
          },
          child: Scaffold(
            backgroundColor: Mixart.bg,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(children: [
                    Padding(padding: EdgeInsets.fromLTRB(largo ? 16 : 8, 8, largo ? 12 : 4, 4), child: _topo(c, st, largo)),
                    Expanded(
                      child: ListView(
                        key: const Key('lista-conversa'),
                        controller: _rolagem,
                        padding: EdgeInsets.fromLTRB(largo ? 20 : 12, 8, largo ? 20 : 12, 16),
                        children: [
                          _objetivo(c),
                          for (var i = 0; i < st.sessao.turnos.length; i++) _bolha(i, st.sessao.turnos[i], c),
                          if (st.aguardando) _Digitando(rotulo: '${c.nomePersonagem} está digitando…'),
                          if (st.resumo != null)
                            ResumoConversaView(
                              resumo: st.resumo!,
                              cenario: c,
                              onDeNovo: _deNovo,
                              onSair: () => Navigator.of(context).pop(),
                            ),
                        ],
                      ),
                    ),
                    if (!st.terminou && (st.sessao.podeFalar || st.aguardando)) ...[
                      _faixa(st, largo),
                      _rodape(st, largo),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topo(Cenario c, CenarioState st, bool largo) {
    final nivel = _cubit.nivel;
    return Row(children: [
      IconButton(
        tooltip: 'Voltar',
        onPressed: _voltar,
        icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
      ),
      const SizedBox(width: 2),
      AvatarPersonagem(key: const Key('avatar-conversa'), quem: c.quem, tamanho: largo ? 56 : 44, frase: _noPalco),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('${c.emoji} ${c.titulo}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Mixart.display(size: largo ? 19 : 16.5)),
          const SizedBox(height: 1),
          BlocBuilder<IaCubit, IaState>(
            builder: (_, ia) => Text(
              'com ${c.nomePersonagem} · $nivel'
              '${ia.carregado ? ' · ${ia.restantes == 1 ? 'resta 1 uso' : 'restam ${ia.restantes} usos'} hoje' : ''}',
              key: const Key('conversa-restantes'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Mixart.ui(size: 12, color: Mixart.textMuted),
            ),
          ),
        ]),
      ),
      IconButton(
        key: const Key('alternar-traducao'),
        tooltip: _traducao ? 'Esconder tradução' : 'Mostrar tradução',
        isSelected: _traducao,
        onPressed: () => setState(() => _traducao = !_traducao),
        icon: Icon(Icons.translate_rounded, size: 20, color: _traducao ? Mixart.brand : Mixart.textMuted),
      ),
      PopupMenuButton<String>(
        key: const Key('menu-conversa'),
        tooltip: 'Mais opções',
        color: Mixart.surface,
        icon: Icon(Icons.more_vert_rounded, color: Mixart.text, size: 22),
        onSelected: (v) {
          if (v == 'voz') _alternarVoz();
          if (v == 'terminar') _cubit.terminar();
        },
        itemBuilder: (_) {
          final podeTerminar = st.sessao.turnosDoAluno > 0 && !st.terminou && !st.aguardando;
          return [
            PopupMenuItem(
              key: const Key('alternar-voz'),
              value: 'voz',
              child: Text(_vozAuto ? 'Não ler as falas em voz alta' : 'Ler as falas em voz alta',
                  style: Mixart.ui(size: 13.5, color: Mixart.text)),
            ),
            PopupMenuItem(
              key: const Key('terminar-conversa'),
              value: 'terminar',
              enabled: podeTerminar,
              // a cor explícita venceria o estilo "desligado" do menu: desligado, o item fica apagado
              child: Text('Terminar conversa',
                  style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: podeTerminar ? Mixart.text : Mixart.textFaint)),
            ),
          ];
        },
      ),
    ]);
  }

  Widget _objetivo(Cenario c) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Mixart.brandSub,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🎯 ${c.objetivo}', key: const Key('objetivo-cenario'), style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.text).copyWith(height: 1.4)),
          const SizedBox(height: 4),
          Text('${c.nomePersonagem} faz o papel de ${c.papel}. A cada fala sua, o Prof. Dash corrige na hora — erre à vontade.',
              style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.4)),
          const SizedBox(height: 4),
          Text('Não use dados pessoais de verdade: invente nomes, telefones e endereços.',
              key: const Key('aviso-dados'), style: Mixart.ui(size: 11, color: Mixart.textFaint).copyWith(height: 1.35)),
        ]),
      );

  Widget _bolha(int i, Turno t, Cenario c) {
    if (t.doAluno) {
      final melhor = t.correcao?.melhor ?? '';
      return BolhaAluno(
        indice: i,
        turno: t,
        // a versão certa na voz do app (o avatar do topo não mexe a boca: _noPalco é a fala do personagem)
        onOuvirCorrecao: melhor.isEmpty ? null : () => unawaited(_voz.falar(melhor)),
      );
    }
    return BolhaPersonagem(
      indice: i,
      turno: t,
      cenario: c,
      mostrarTraducao: _traducao || _abertas.contains(i),
      onOuvir: () => _ouvirFala(t.texto),
      onOuvirDevagar: () => _ouvirFala(t.texto, lenta: true),
      onVerTraducao: () => setState(() => _abertas.add(i)),
    );
  }

  void _ouvirFala(String fala, {bool? lenta}) {
    setState(() => _noPalco = fala);
    unawaited(_voz.falar(fala, lenta: lenta));
  }

  /// A faixa logo acima do campo (uma linha, ~40 px): o painel do microfone, o recado dele, o aviso de erro ou
  /// as ideias de resposta — um de cada vez, nunca empilhados (cabe em 360×640 com o teclado aberto).
  Widget _faixa(CenarioState st, bool largo) {
    final pad = EdgeInsets.fromLTRB(largo ? 20 : 12, 6, largo ? 20 : 12, 6);
    if (_ouvindo) {
      return Container(
        key: const Key('ouvindo-conversa'),
        width: double.infinity,
        padding: pad,
        color: Mixart.surfaceHi,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('🎙️ Ouvindo… fale em inglês', style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.danger)),
          if (_parcial.isNotEmpty)
            Text(_parcial,
                key: const Key('parcial-conversa'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Mixart.ui(size: 13, color: Mixart.text).copyWith(fontStyle: FontStyle.italic)),
        ]),
      );
    }
    final aviso = _aviso(st);
    // com a janela de descanso aberta o Enviar está desligado: o aviso (e a contagem) vale mais que o recado
    // do microfone ("toque em Enviar")
    if (_recado.isNotEmpty && !(aviso != null && _cubit.emEspera)) {
      return Container(
        width: double.infinity,
        padding: pad,
        child: Text(_recado,
            key: const Key('recado-microfone'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.textMuted).copyWith(height: 1.35)),
      );
    }
    if (aviso != null) {
      return Container(
        key: aviso.$1,
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 96),
        padding: pad,
        decoration: BoxDecoration(color: Mixart.surfaceHi, border: Border(top: BorderSide(color: Mixart.border))),
        child: SingleChildScrollView(
          child: Text(aviso.$2, style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4)),
        ),
      );
    }
    return _ideiasDeResposta(st, largo);
  }

  /// O aviso do erro (key, texto), ou null. O do limite some quando a janela passa.
  (Key, String)? _aviso(CenarioState st) {
    switch (st.erro) {
      case ErroCenario.nenhum:
        return null;
      case ErroCenario.semCota:
        return (const Key('cenario-sem-cota'), 'Por hoje acabaram seus usos da IA — amanhã tem mais 🐦 Sua fala ficou guardada no campo.');
      case ErroCenario.limite:
        final ate = st.esperaAte;
        if (ate == null || !_cubit.emEspera) return null;
        final ms = ate.difference(_cubit.agora()).inMilliseconds;
        final s = ms <= 0 ? 0 : (ms / 1000).ceil();
        return (
          const Key('cenario-limite'),
          'Muita gente conversando com a IA agora (o limite grátis do app encheu). Tente de novo em $s s — '
              'sua fala ficou no campo e não gastou nada.'
        );
      case ErroCenario.limiteDia:
        return (
          const Key('cenario-limite-dia'),
          'A IA grátis do app chegou ao limite de hoje para todo mundo. Volte amanhã — sua fala ficou no campo e não '
              'gastou nada.'
              // sem nenhuma fala respondida não há resumo (o Terminar fica desligado)
              '${st.sessao.turnosDoAluno > 0 ? ' O resumo continua funcionando: toque em ⋮ › Terminar conversa.' : ''}'
        );
      case ErroCenario.ocupado:
        return (const Key('cenario-ocupado'), 'A IA está sobrecarregada neste momento. Tente de novo em alguns segundos — não gastou nada.');
      case ErroCenario.semRede:
        return (
          const Key('cenario-sem-rede'),
          'Sem internet agora. Sua fala ficou no campo — confira a conexão e toque em Enviar de novo (não gastou nada).'
        );
      case ErroCenario.indisponivel:
        return (const Key('cenario-indisponivel'), 'A IA está indisponível no momento. Tente mais tarde — não gastou nada.');
      case ErroCenario.recusada:
        return (const Key('cenario-recusada'), 'Não consegui responder a essa fala. Tente dizer de outro jeito, dentro da situação.');
      case ErroCenario.falhou:
        return (const Key('cenario-falhou'), 'Não consegui falar com a IA agora (isso não gastou seu limite do dia). Tente de novo.');
    }
  }

  /// As ideias de resposta numa linha que rola de lado: A1/A2 sempre à vista; B1+ atrás de "💡 Ideias de resposta".
  Widget _ideiasDeResposta(CenarioState st, bool largo) {
    final s = st.sessao;
    var ideias = s.sugestoesAtuais;
    if (ideias.isEmpty && s.turnosDoAluno == 0) ideias = s.cenario.dicas.take(3).toList();
    if (ideias.isEmpty) return const SizedBox.shrink();
    final iniciante = nivelIniciante(_cubit.nivel);
    final abertas = iniciante || _ideias;
    final itens = <Widget>[
      if (iniciante)
        Padding(padding: const EdgeInsets.only(right: 6), child: Center(child: Text('💡', style: Mixart.ui(size: 15))))
      else
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: TextButton(
            key: const Key('mostrar-sugestoes'),
            onPressed: () => setState(() => _ideias = !_ideias),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 32)),
            child: Text(_ideias ? '💡 Esconder ideias' : '💡 Ideias de resposta',
                style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.brand)),
          ),
        ),
      if (abertas)
        for (var i = 0; i < ideias.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              key: Key('sugestao-$i'),
              tooltip: ideias[i],
              visualDensity: VisualDensity.compact,
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(_curta(ideias[i]), maxLines: 1, overflow: TextOverflow.ellipsis, style: Mixart.ui(size: 12.5, color: Mixart.text)),
              ),
              backgroundColor: Mixart.surfaceHi,
              side: BorderSide(color: Mixart.border),
              onPressed: () {
                // preenche o campo sem enviar (um toque, não um Enter: pode pedir o foco)
                _preencher(ideias[i]);
                _foco.requestFocus();
              },
            ),
          ),
    ];
    return SizedBox(
      key: const Key('sugestoes-conversa'),
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(largo ? 20 : 12, 4, largo ? 20 : 12, 4),
        children: itens,
      ),
    );
  }

  /// No chip, até ~60 letras (o texto inteiro vai para o campo).
  static String _curta(String t) => t.length <= 60 ? t : '${t.substring(0, 57).trimRight()}…';

  Widget _rodape(CenarioState st, bool largo) {
    final s = st.sessao;
    final livre = s.podeFalar && !st.aguardando && !_cubit.emEspera;
    final k = (s.turnosDoAluno + (s.podeFalar ? 1 : 0)).clamp(1, s.cenario.maxTurnos);
    return Container(
      padding: EdgeInsets.fromLTRB(largo ? 20 : 12, 8, largo ? 20 : 10, 10),
      decoration: BoxDecoration(color: Mixart.surface, border: Border(top: BorderSide(color: Mixart.border))),
      child: Row(children: [
        Expanded(
          // uma linha só: o Enter envia pelo próprio campo (onSubmitted)
          child: TextField(
            key: const Key('campo-conversa'),
            controller: _campo,
            focusNode: _foco,
            // sem autofocus: na web, focar o campo durante a transição da tela dá erro no motor de texto (a pessoa toca no campo)
            // O campo NUNCA é desligado nem perde o foco enquanto o personagem responde (readOnly/enabled/requestFocus no meio
            // do Enter derrubam a conexão do teclado na web com um erro do motor); só o envio é ignorado até a resposta chegar.
            maxLines: 1,
            maxLength: SessaoCenario.maxFala,
            textInputAction: TextInputAction.done,
            // onEditingComplete vazio: o padrão do "done" seria tirar o foco do campo a cada Enter (e dar erro na web)
            onEditingComplete: () {},
            onSubmitted: (_) => _enviar(),
            style: Mixart.ui(size: 14, color: Mixart.text),
            decoration: InputDecoration(
              // no celular a dica encurta para o "fala k de n" caber
              hintText: '${largo ? 'Responda em inglês' : 'Em inglês'}… (fala $k de ${s.cenario.maxTurnos})',
              hintStyle: Mixart.ui(size: 13.5, color: Mixart.textFaint),
              hintMaxLines: 1,
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: Mixart.surfaceHi,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.brand)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        MicrofoneConversa(
          reconhecedor: _reconhecedor,
          antesDeOuvir: _voz.calarTudo,
          aoMudarOuvindo: _aoMudarOuvindo,
          aoParcial: (t) => _mudar(() => _parcial = t),
          aoRecado: (t) => _mudar(() {
            _recado = t;
            _textoDoRecado = _campo.text;
          }),
          // o ditado vai para o CAMPO: a pessoa confere e envia (nunca sozinho)
          aoOuvir: _preencher,
        ),
        const SizedBox(width: 6),
        IconButton.filled(
          key: const Key('enviar-conversa'),
          tooltip: 'Enviar',
          onPressed: livre ? _enviar : null,
          style: IconButton.styleFrom(backgroundColor: Mixart.brand, foregroundColor: Mixart.onBrand),
          icon: const Icon(Icons.send_rounded, size: 18),
        ),
      ]),
    );
  }
}

class _Digitando extends StatelessWidget {
  final String rotulo;
  const _Digitando({required this.rotulo});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10, left: 4),
        child: Row(children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Mixart.brand)),
          const SizedBox(width: 8),
          Flexible(child: Text(rotulo, key: const Key('dash-digitando'), style: Mixart.ui(size: 12.5, color: Mixart.textMuted))),
        ]),
      );
}

