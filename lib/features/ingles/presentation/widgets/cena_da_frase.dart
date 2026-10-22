import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../../arcade/domain/historia_turismo.dart' show CenarioHistoria, TextoBilingue;
import '../../../arcade/presentation/historia/palco_historia.dart';
import '../../../arcade/presentation/historia/roteiro_visivel.dart';
import '../../data/voz_ingles.dart';
import '../../domain/assistir/historia_licao.dart';
import 'roteiro_da_frase.dart';
import 'traducao_card.dart' show nomeDeQuem;

/// 🎬 A cena da frase no cartão da lição de inglês: o palco do 📺 Escutar assistindo ([PalcoHistoria]) parado
/// no passo da historinha ancorado na frase atual ([ancora] = `historia.ancoras[chaveDaFrase(trecho)]`).
/// Trocar de frase SALTA para a âncora dela ([RoteiroDaFrase.irPara]); a ação do passo anima uma vez e a boca
/// de quem fala mexe com a voz da lição ([VozIngles.falando], texto exato).
///
/// Sem balão (o EN não aparece), sem toque e sem foco (a frase continua com o teclado). O relógio (UM `Ticker`)
/// só anda com [ativo], o app visível, o palco dentro da área visível da página e algo para animar (a ação do
/// passo ou a voz desta frase); parado, nenhum quadro. "Reduzir animações": a ação já no fim e a boca em degraus
/// de 100 ms.
///
/// Keys: `cena-da-frase` (raiz).
class CenaDaFrase extends StatefulWidget {
  const CenaDaFrase({
    super.key,
    required this.historia,
    required this.ancora,
    required this.tamanho,
    this.ativo = true,
    this.titulo = '',
  });

  final HistoriaLicao historia;
  final (int, int) ancora;
  final Size tamanho;

  /// false com o ensaio mental na frente: a cena fica parada (as frases do ensaio falam por cima).
  final bool ativo;

  /// O nome da lição (o cartão de título do palco, sem título autoral).
  final String titulo;

  /// Quantas vezes alguma cena conferiu se ainda aparece na página (os testes provam que não é a cada quadro).
  @visibleForTesting
  static int debugConferencias = 0;

  @override
  State<CenaDaFrase> createState() => _CenaDaFraseState();
}

class _CenaDaFraseState extends State<CenaDaFrase> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _roteiro = RoteiroDaFrase();
  late final Ticker _ticker = createTicker(_aoTique);
  Duration _ultimoTique = Duration.zero;

  /// Relógio do palco (s), o acumulado do "reduzir" e o relógio em degraus (o idle e a boca repintam só
  /// quando ele vira).
  double _relogio = 0, _acumulado = 0;
  final _quadro = ValueNotifier<double>(0);
  late final Listenable _redesenho = Listenable.merge([_roteiro, _quadro]);

  bool _reduzir = false, _oculto = false, _foraDaTela = false;
  ScrollPosition? _rolagem;
  bool _conferenciaAgendada = false;

  /// A voz estava falando a frase desta âncora no último quadro (ao parar, um quadro fecha a boca).
  bool _falavaMinha = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _roteiro.irPara(widget.historia, widget.ancora);
    VozIngles.falando.addListener(_aoFalar);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (r != _reduzir) {
      _reduzir = r;
      _roteiro.reduzir = r;
    }
    // a página que rola em volta: a cada rolagem, confere se a cena ainda aparece
    final rolagem = Scrollable.maybeOf(context)?.position;
    if (!identical(rolagem, _rolagem)) {
      _rolagem?.removeListener(_agendarConferencia);
      _rolagem = rolagem?..addListener(_agendarConferencia);
      _agendarConferencia();
    }
    _sincronizar();
  }

  @override
  void didUpdateWidget(CenaDaFrase old) {
    super.didUpdateWidget(old);
    if (!identical(old.historia, widget.historia) || old.ancora != widget.ancora) {
      _roteiro.irPara(widget.historia, widget.ancora);
    }
    _sincronizar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rolagem?.removeListener(_agendarConferencia);
    VozIngles.falando.removeListener(_aoFalar);
    _ticker.dispose();
    _quadro.dispose();
    _roteiro.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _oculto = state == AppLifecycleState.hidden || state == AppLifecycleState.paused;
    _sincronizar();
  }

  /// A voz da lição está falando a frase desta âncora (texto exato)?
  bool get _falandoMinha {
    final en = _roteiro.en;
    return en != null && VozIngles.falando.value?.frase == en;
  }

  void _aoFalar() {
    if (!mounted) return;
    final agora = _falandoMinha;
    if (_falavaMinha && !agora) _quadro.value += 1e-6; // a voz parou: um quadro fecha a boca
    _falavaMinha = agora;
    _sincronizar();
  }

  // ───────────────────────── visível na página

  void _agendarConferencia() {
    if (_conferenciaAgendada) return;
    _conferenciaAgendada = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _conferenciaAgendada = false;
      _conferirVisivel();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _conferirVisivel() {
    if (!mounted) return;
    CenaDaFrase.debugConferencias++;
    var fora = false;
    final eu = context.findRenderObject();
    final vp = _rolagem == null ? null : Scrollable.maybeOf(context)?.context.findRenderObject();
    if (eu is RenderBox && vp is RenderBox && eu.attached && vp.attached && eu.hasSize && vp.hasSize) {
      final r = MatrixUtils.transformRect(eu.getTransformTo(vp), Offset.zero & eu.size);
      fora = !r.overlaps(Offset.zero & vp.size);
    }
    if (fora != _foraDaTela) {
      _foraDaTela = fora;
      _sincronizar();
    }
  }

  // ───────────────────────── relógio

  void _sincronizar() {
    if (!mounted) return;
    final andar = widget.ativo && !_oculto && !_foraDaTela && (_roteiro.animando || _falandoMinha);
    if (andar && !_ticker.isActive) {
      _ultimoTique = Duration.zero;
      _ticker.start();
    } else if (!andar && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _aoTique(Duration decorrido) {
    final dt = ((decorrido - _ultimoTique).inMicroseconds / 1e6).clamp(0.0, .1);
    _ultimoTique = decorrido;
    if (dt <= 0 || !mounted) return;
    if (_reduzir) {
      // 10 passos por segundo, sem animação entre eles (a ação já está no fim; só a boca da voz)
      _acumulado += dt;
      while (_acumulado >= .1) {
        _acumulado -= .1;
        _quadro.value += .1;
      }
    } else {
      _relogio += dt;
      _roteiro.tick(dt);
      _quadro.value = (_relogio * 30).floor() / 30;
    }
    _sincronizar();
  }

  // ───────────────────────── UI

  @override
  Widget build(BuildContext context) {
    final h = widget.historia;
    final nome = widget.titulo.isEmpty ? h.licaoId : widget.titulo;
    return KeyedSubtree(
      key: const Key('cena-da-frase'),
      child: _AoPintar(
        aoPintar: _rolagem == null ? null : _agendarConferencia,
        child: ExcludeFocus(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.fromSize(
              size: widget.tamanho,
              child: ColoredBox(
                color: const Color(0xFF0E0E14),
                child: RepaintBoundary(
                  child: ListenableBuilder(
                    listenable: _redesenho,
                    builder: (context, _) => PalcoHistoria(
                      roteiro: _roteiro,
                      relogio: _reduzir ? 0 : _quadro.value,
                      cabecalho: CabecalhoPalco(
                        sobretitulo: '🎬',
                        titulo: h.titulo ?? TextoBilingue(nome, nome),
                        rotuloSemantico: rotuloDaCena(_roteiro),
                      ),
                      reduzir: _reduzir,
                      semBalao: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// O que o leitor de tela diz da cena, em português e sem o inglês (a cena não entrega a frase): quem fala,
/// com quem e onde — "Cena da historinha: Mike fala com Você (videochamada)".
@visibleForTesting
String rotuloDaCena(RoteiroDaFrase roteiro) {
  final f = roteiro.falaAtual;
  final estado = roteiro.depois;
  final lugar = _lugares[estado.cenario] ?? estado.cenario.name;
  final quem = f == null || f.ehNarrador ? null : nomeDeQuem(f.quem);
  final alvo = f?.alvo;
  final com = quem == null || alvo == null || alvo == f!.quem || !estado.atores.containsKey(alvo) ? null : nomeDeQuem(alvo);
  final acao = quem == null
      ? 'o narrador conta'
      : f!.mudo || f.en == null
          ? '$quem em cena'
          : '$quem fala${com == null ? '' : ' com $com'}';
  return 'Cena da historinha: $acao ($lugar)';
}

const _lugares = {
  CenarioHistoria.aeroporto: 'aeroporto',
  CenarioHistoria.garagem: 'garagem',
  CenarioHistoria.boxes: 'boxes',
  CenarioHistoria.hotel: 'hotel',
  CenarioHistoria.cafe: 'café',
  CenarioHistoria.clinica: 'clínica',
  CenarioHistoria.plataforma: 'plataforma',
  CenarioHistoria.podio: 'pódio',
  CenarioHistoria.campina: 'campina',
  CenarioHistoria.deserto: 'deserto',
  CenarioHistoria.cidade: 'cidade',
  CenarioHistoria.neve: 'neve',
  CenarioHistoria.vulcao: 'vulcão',
  CenarioHistoria.espaco: 'espaço',
  CenarioHistoria.praia: 'praia',
  CenarioHistoria.ponte: 'ponte',
  CenarioHistoria.canion: 'cânion',
  CenarioHistoria.oasis: 'oásis',
  CenarioHistoria.floresta: 'floresta',
  CenarioHistoria.vale: 'vale',
  CenarioHistoria.lago: 'lago',
  CenarioHistoria.lua: 'lua',
  CenarioHistoria.marte: 'Marte',
  CenarioHistoria.estacao: 'estação espacial',
  CenarioHistoria.autodromo: 'autódromo',
  CenarioHistoria.videochamada: 'videochamada',
  CenarioHistoria.escritorio: 'escritório',
  CenarioHistoria.casa: 'casa',
  CenarioHistoria.restaurante: 'restaurante',
  CenarioHistoria.loja: 'loja',
  CenarioHistoria.copa: 'copa',
  CenarioHistoria.recepcaoHotel: 'recepção do hotel',
  CenarioHistoria.salaDeEstar: 'sala de estar',
  CenarioHistoria.dentroDoCarro: 'dentro do carro',
  CenarioHistoria.cozinha: 'cozinha',
  CenarioHistoria.quintal: 'quintal',
  CenarioHistoria.bar: 'bar',
};

/// Avisa [aoPintar] cada vez que a página pinta este pedaço (o layout moveu a cena, a página rolou): a cena
/// confere depois do quadro se ainda aparece. O desenho tem o próprio `RepaintBoundary` e não repinta isto.
class _AoPintar extends SingleChildRenderObjectWidget {
  const _AoPintar({required this.aoPintar, super.child});

  final VoidCallback? aoPintar;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderAoPintar(aoPintar);

  @override
  void updateRenderObject(BuildContext context, _RenderAoPintar renderObject) => renderObject.aoPintar = aoPintar;
}

class _RenderAoPintar extends RenderProxyBox {
  _RenderAoPintar(this.aoPintar);

  VoidCallback? aoPintar;

  @override
  void paint(PaintingContext context, Offset offset) {
    aoPintar?.call();
    super.paint(context, offset);
  }
}
