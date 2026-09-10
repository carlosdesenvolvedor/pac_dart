import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../../core/theme/mixart.dart';
import '../../domain/turismo.dart';
import 'pista_gt.dart';
import 'cenario.dart';
import 'velocimetro.dart';

@JS('turismo3d')
external JSObject? get _turismo3dObj;

extension type _Turismo3d(JSObject _) implements JSObject {
  external JSPromise<JSAny?> montar(web.HTMLCanvasElement canvas, JSAny config);
  external void atualizar(JSAny estado);
  external void destruir();
  external bool get pronto;
  external String? get erro;
  external double get progresso;
}

/// Setas das faixas, como no painel 3D.
const setasFaixa = ['⬅ ESQUERDA', '⬆ MEIO', '➡ DIREITA'];

/// 🏎️ A corrida renderizada de verdade em 3D (Three.js + WebGL) dentro de
/// um `HtmlElementView`: a lógica continua em Dart e, a cada frame, o
/// estado do motor vai pro JS (`window.turismo3d.atualizar`). O HUD
/// (velocímetro, progresso) é Flutter por cima. Se o módulo JS não carregou,
/// a vista em Canvas assume.
class Vista3D extends StatefulWidget {
  final TurismoEngine engine;
  final double relogio;
  final String carro;
  final List<String> trafego;

  /// Som ligado e jogo pausado (o motor gravado obedece aos dois).
  final bool som;
  final bool pausado;

  /// Câmera: perseguicao · capo · cinema · alta.
  final String camera;

  /// 🎸 Música da fase ligada.
  final bool musica;

  /// Qualidade (auto · alta · leve) e tremor de câmera na batida.
  final String qualidade;
  final bool tremor;

  /// 👻 A melhor volta da pista (carro translúcido), se houver.
  final VoltaFantasma? fantasma;
  const Vista3D({
    super.key,
    required this.engine,
    required this.relogio,
    this.carro = 'porsche_930',
    this.trafego = const [],
    this.som = true,
    this.pausado = false,
    this.camera = 'perseguicao',
    this.musica = true,
    this.qualidade = 'auto',
    this.tremor = true,
    this.fantasma,
  });

  static bool get disponivel => _turismo3dObj != null;

  @override
  State<Vista3D> createState() => _Vista3DState();
}

class _Vista3DState extends State<Vista3D> {
  static const _tipo = 'pac-turismo3d';
  static bool _registrado = false;
  static int _serie = 0;

  late final String _id = 'turismo3d-${_serie++}';
  _Turismo3d? _js;
  bool _montado = false;
  bool _pronto = false;
  bool _falhou = false;
  double _largura = 0;
  double _altura = 0;

  @override
  void initState() {
    super.initState();
    final obj = _turismo3dObj;
    if (obj == null) {
      _falhou = true;
      return;
    }
    _js = _Turismo3d(obj);
    if (!_registrado) {
      _registrado = true;
      ui_web.platformViewRegistry.registerViewFactory(_tipo, (int viewId, {Object? params}) {
        final canvas = web.HTMLCanvasElement()
          ..id = (params as String?) ?? 'turismo3d'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.display = 'block'
          // os toques atravessam pro Flutter (o campo de digitação fica focado)
          ..style.pointerEvents = 'none';
        return canvas;
      });
    }
  }

  void _montar() {
    final js = _js;
    final canvas = web.document.getElementById(_id) as web.HTMLCanvasElement?;
    if (js == null || canvas == null || _montado) return;
    _montado = true;
    final e = widget.engine;
    final config = {
      'tema': e.pista.tema,
      'pista': e.pista.numero,
      'qualidade': widget.qualidade,
      'fantasma': widget.fantasma?.amostras,
      'fantasmaPasso': VoltaFantasma.passo,
      'musica': e.pista.musica.isEmpty ? null : 'assets3d/som/musica/${e.pista.musica}',
      'segmentos': [for (final s in e.segmentos) s.curva],
      'comprimentoSegmento': TurismoEngine.comprimentoSegmento,
      'distancia': e.pista.distancia,
      'carro': widget.carro,
      'trafego': widget.trafego,
      'portais': [
        for (final p in e.portais)
          {
            'indice': p.indice,
            'z': p.z,
            'faixas': p.faixas,
            'palavras': p.palavras,
            'carros': [for (final c in p.carros) {'faixa': c.faixa, 'z': c.z}],
            'fichas': [for (final f in p.fichas) {'z': f.z, 'faixa': f.faixa, 'texto': f.texto}],
          },
      ],
    };
    js.montar(canvas, config.jsify()!).toDart.then((_) {
      if (mounted) setState(() => _pronto = js.pronto);
    }).catchError((Object erro) {
      if (mounted) setState(() => _falhou = true);
    });
  }

  @override
  void didUpdateWidget(covariant Vista3D old) {
    super.didUpdateWidget(old);
    final js = _js;
    if (js == null) return;
    // o elemento do platform view só entra no DOM quando o frame compõe:
    // insiste até achar o canvas (a página redesenha a cada frame)
    if (!_montado) {
      _montar();
      return;
    }
    final e = widget.engine;
    final digitando = e.portalParaDigitar;
    // as palavras na vez, cada uma flutuando SOBRE A FAIXA pra onde leva
    // (esquerda/meio/direita) — quem lê já sabe pra que lado vai
    final palavras = <Map<String, Object>>[];
    if (e.porSetas) {
      // modo setas: a placa mostra a SETA da faixa livre, com a palavra de legenda
      final p = e.portalAtual;
      if (p != null) {
        for (var i = 0; i < p.palavras.length; i++) {
          palavras.add({
            'texto': p.palavras[i],
            'digitadas': 0,
            'faixa': p.faixas[i],
            'rotulo': setasFaixa[p.faixas[i]],
            'tipo': 'seta',
            'ativa': true,
          });
        }
      }
    } else if (digitando != null) {
      for (var i = 0; i < digitando.palavras.length; i++) {
        final travada = e.palavraTravada;
        palavras.add({
          'texto': digitando.palavras[i],
          'digitadas': travada == i ? e.digitadas : 0,
          'faixa': digitando.faixas[i],
          'rotulo': setasFaixa[digitando.faixas[i]],
          'tipo': 'portal',
          'ativa': travada == null || travada == i,
        });
      }
    } else if (e.palavraGas != null) {
      palavras.add({
        'texto': e.palavraGas!,
        'digitadas': e.gasDigitadas,
        'faixa': e.faixa,
        'rotulo': '⛽ COMBUSTÍVEL — acelere',
        'tipo': 'gas',
        'ativa': true,
      });
    }
    js.atualizar({
      'largura': _largura,
      'altura': _altura,
      'palavras': palavras,
      'posicao': e.posicao,
      'tempo': e.tempo,
      'velocidade': e.velocidade,
      'velMax': e.velMax,
      'x': e.xAtual,
      'xAlvo': e.xAlvo,
      'faixa': e.faixa,
      'som': widget.som,
      'pausado': widget.pausado,
      'camera': widget.camera,
      'musica': widget.musica,
      'tremor': widget.tremor,
      'acabou': !e.correndo,
      'impacto': e.impacto,
      'boost': e.boost,
      // só a janela de portais em volta do carro viaja por frame (as pistas
      // têm até 60+ portais; mandar todos era lixo pro GC a 60 fps)
      'portais': [
        for (final p in _janelaDePortais(e))
          {
            'indice': p.indice,
            'digitado': p.digitado,
            'batido': p.batido,
            'travada': identical(p, digitando) ? (e.palavraTravada ?? -1) : -1,
            'carros': [
              for (final c in p.carros) {'z': c.z, 'ativo': c.ativo, 'batido': c.batido},
            ],
            'fichas': [for (final f in p.fichas) f.pega],
          },
      ],
    }.jsify()!);
    if (!_pronto && js.pronto) setState(() => _pronto = true);
  }

  /// Do portal anterior ao 5º à frente: é o que o JS precisa animar.
  Iterable<Portal> _janelaDePortais(TurismoEngine e) {
    final atual = e.portalAtual?.indice ?? e.portais.length;
    final de = (atual - 2).clamp(0, e.portais.length);
    final ate = (atual + 6).clamp(0, e.portais.length);
    return e.portais.getRange(de, ate);
  }

  @override
  void dispose() {
    _relogioCarga?.cancel();
    _js?.destruir();
    super.dispose();
  }

  Timer? _relogioCarga;

  /// Tela de carga: barra com o progresso real (céu → pista → carro → tráfego).
  Widget _carregando() {
    _relogioCarga ??= Timer.periodic(const Duration(milliseconds: 150), (t) {
      if (!mounted || _pronto) {
        t.cancel();
        _relogioCarga = null;
        return;
      }
      setState(() {});
    });
    final js = _js;
    final progresso = js == null ? 0.0 : js.progresso.clamp(0.0, 1.0);
    final etapa = progresso < .2
        ? 'preparando o motor 3D'
        : progresso < .45
            ? 'baixando o céu'
            : progresso < .85
                ? 'construindo a pista e o carro'
                : 'chamando o tráfego';
    return Positioned.fill(
      child: Container(
        color: const Color(0xEE0B0E14),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🏎️', style: TextStyle(fontSize: 34)),
            const SizedBox(height: 10),
            Text('${nomeDaFase(widget.engine.pista.tema)} em 3D',
                style: Mixart.display(size: 16, color: Colors.white)),
            const SizedBox(height: 6),
            Text('$etapa… ${(progresso * 100).round()}%',
                style: Mixart.ui(size: 11.5, color: Colors.white70)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 8,
                backgroundColor: Colors.white12,
                color: Mixart.brand,
              ),
            ),
            const SizedBox(height: 10),
            Text('carros por Lexyc16 (CC BY 4.0) · céus e texturas Poly Haven (CC0)',
                style: Mixart.ui(size: 9.5, color: Colors.white38)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_falhou) return VistaCorrida(engine: widget.engine, relogio: widget.relogio);
    final e = widget.engine;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Mixart.radiusLg),
      child: LayoutBuilder(builder: (context, box) {
        _largura = box.maxWidth;
        _altura = box.maxHeight;
        return Stack(children: [
        Positioned.fill(
          child: HtmlElementView(
            viewType: _tipo,
            creationParams: _id,
            onPlatformViewCreated: (_) =>
                WidgetsBinding.instance.addPostFrameCallback((_) => _montar()),
          ),
        ),
        if (!_pronto) _carregando(),
        Positioned(
          right: 16,
          bottom: 16,
          child: Velocimetro(fracao: e.fracaoVel, kmh: (e.velocidade * 3.6).round()),
        ),
        ]);
      }),
    );
  }
}
