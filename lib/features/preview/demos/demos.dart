import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Demos pré-construídas: Flutter DE VERDADE acontecendo na prévia para os
/// exercícios que não têm saída visual direta (setState, Navigator, Provider…).
/// O casamento é por padrão no texto do código digitado.
Widget? demoPara(String cod) {
  Widget? d;
  for (final regra in _regras) {
    if (regra.casa(cod)) {
      d = regra.constroi(cod);
      break;
    }
  }
  return d;
}

class _Regra {
  final bool Function(String) casa;
  final Widget Function(String) constroi;
  const _Regra(this.casa, this.constroi);
}

bool _tem(String cod, List<String> padroes) => padroes.any(cod.contains);

final _regras = <_Regra>[
  // ---- Formulário (antes de "Estado": validator usa ! etc.) ----
  _Regra(
    (c) => _tem(c, ['GlobalKey<FormState>', 'validator:', 'currentState!.validate', 'onSaved:', 'currentState!.save', 'Form(']),
    (_) => const _DemoFormulario(),
  ),
  // ---- Navegação / diálogos ----
  _Regra((c) => _tem(c, ['showCupertinoDialog', 'CupertinoAlertDialog']), (_) => const _DemoDialogo(cupertino: true)),
  _Regra((c) => _tem(c, ['showDialog', 'AlertDialog']), (_) => const _DemoDialogo()),
  _Regra((c) => _tem(c, ['Hero(', 'PageRouteBuilder']), (_) => const _DemoHero()),
  _Regra((c) => _tem(c, ['Navigator.', 'MaterialPageRoute', "routes: {"]), (_) => const _DemoNavegacao()),
  // ---- Estado ----
  _Regra(
    (c) => _tem(c, ['ChangeNotifier', 'notifyListeners', 'context.watch', 'context.read', 'Provider.of', 'ChangeNotifierProvider']),
    (_) => const _DemoContadorCompartilhado(titulo: 'ChangeNotifier + Provider', evento: 'notifyListeners()'),
  ),
  _Regra(
    (c) => _tem(c, ['ValueNotifier', 'InheritedWidget', '.addListener', 'contador.value', 'contador.dispose', 'Loja.of(']),
    (_) => const _DemoContadorCompartilhado(titulo: 'ValueNotifier', evento: 'value++ → escutas notificadas'),
  ),
  _Regra((c) => _tem(c, ['ligado = !ligado', 'bool ligado']), (_) => const _DemoInterruptor()),
  _Regra(
    (c) => _tem(c, ['setState', 'StatefulWidget', '_ContadorState', 'int n = 0']),
    (_) => const _DemoContador(),
  ),
  // ---- Ciclo de vida ----
  _Regra((c) => _tem(c, ['initState', 'dispose', 'didUpdateWidget']), (_) => const _DemoCicloVida()),
  // ---- Async ----
  _Regra((c) => _tem(c, ['FutureBuilder', 'ConnectionState']), (_) => const _DemoFuture()),
  _Regra((c) => _tem(c, ['StreamBuilder', 'Stream.periodic']), (_) => const _DemoStream()),
  // ---- Tema ----
  _Regra((c) => _tem(c, ['ThemeData', 'Theme.of', 'ColorScheme.fromSeed']), (_) => const _DemoTema()),
  // ---- Animações ----
  _Regra((c) => _tem(c, ['AnimationController', 'Tween(', 'ctrl.forward']), (_) => const _DemoAnimacao()),
  // ---- Abas / rolagem / slivers / responsivo ----
  _Regra((c) => _tem(c, ['TabController', 'TabBarView', 'DefaultTabController', 'TabBar(']), (_) => const _DemoAbas()),
  _Regra((c) => _tem(c, ['SliverAppBar', 'CustomScrollView', 'SliverList', 'SliverGrid']), (_) => const _DemoSlivers()),
  _Regra((c) => _tem(c, ['ScrollController', 'animateTo']), (_) => const _DemoRolagem()),
  _Regra((c) => _tem(c, ['MediaQuery', 'largura > 600', 'LayoutBuilder', 'OrientationBuilder']), (_) => const _DemoResponsivo()),
  // ---- Entrada ----
  _Regra((c) => _tem(c, ['TextEditingController']), (_) => const _DemoEntrada()),
  // ---- Apps mínimos ----
  _Regra(
    (c) => _tem(c, ['CupertinoApp', 'cupertino.dart', 'CupertinoPageScaffold']),
    (_) => const _DemoAppMinima(cupertino: true),
  ),
  _Regra(
    (c) => _tem(c, ['StatelessWidget', 'runApp', 'MaterialApp(home', 'MaterialApp(']),
    (_) => const _DemoAppMinima(),
  ),
  // ---- Estilo e layout (efeito aplicado de verdade) ----
  _Regra((c) => c.contains('TextStyle('), (c) => _DemoTextStyle(cod: c)),
  _Regra((c) => _tem(c, ['Image.asset', 'Image.network']), (c) => _DemoImagem(rede: c.contains('network'))),
  _Regra((c) => c.contains('BoxDecoration('), (c) => _DemoDecoracao(cod: c)),
  _Regra((c) => _tem(c, ['EdgeInsets.', 'SizedBox.shrink']), (c) => _DemoEspacamento(cod: c)),
  _Regra((c) => c.contains('MainAxisAlignment.'), (c) => _DemoAlinhamento(cod: c)),
  _Regra((c) => c.contains('Alignment.'), (c) => _DemoAlign(cod: c)),
  _Regra((c) => _tem(c, ['Expanded(', 'Flexible(']), (c) => _DemoExpanded(flex2: c.contains('flex: 2'))),
  _Regra((c) => _tem(c, ['Stack(', 'Positioned(']), (c) => _DemoStack(cod: c)),
  _Regra((c) => _tem(c, ['Opacity(', 'ClipRRect(', 'Transform.rotate', 'AspectRatio(']), (c) => _DemoEfeito(cod: c)),
  _Regra((c) => c.contains('GridView'), (_) => const _DemoGrade()),
];

// ============================================================
// blocos de apoio
// ============================================================

const _azul = Color(0xFF1565C0);
const _fundo = Color(0xFFFAFAFA);

class _MiniApp extends StatelessWidget {
  final String titulo;
  final Widget corpo;
  final double altura;
  const _MiniApp({required this.titulo, required this.corpo, this.altura = 210});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 235,
          height: altura,
          child: Column(children: [
            Container(
              height: 36,
              color: _azul,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(titulo,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Container(color: _fundo, child: corpo)),
          ]),
        ),
      );
}

class _Caixa extends StatelessWidget {
  final String rotulo;
  final Color cor;
  final double w, h;
  const _Caixa(this.rotulo, {this.cor = _azul, this.w = 44, this.h = 44});
  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(8)),
        child: Text(rotulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
}

// ============================================================
// demos
// ============================================================

/// Contador real com setState.
class _DemoContador extends StatefulWidget {
  const _DemoContador();
  @override
  State<_DemoContador> createState() => _DemoContadorState();
}

class _DemoContadorState extends State<_DemoContador> {
  int n = 0;
  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'Contador',
        corpo: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Você apertou:', style: TextStyle(fontSize: 12, color: Colors.black54)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
            child: Text('$n',
                key: ValueKey(n),
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: _azul)),
          ),
          const SizedBox(height: 6),
          FloatingActionButton.small(
            heroTag: null,
            backgroundColor: _azul,
            onPressed: () => setState(() => n++),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text('setState(() => n++)',
              style: TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: Colors.black45)),
        ]),
      );
}

/// Switch real ligando uma "lâmpada".
class _DemoInterruptor extends StatefulWidget {
  const _DemoInterruptor();
  @override
  State<_DemoInterruptor> createState() => _DemoInterruptorState();
}

class _DemoInterruptorState extends State<_DemoInterruptor> {
  bool ligado = false;
  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'Interruptor',
        corpo: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ligado ? const Color(0xFFFFC73B) : Colors.black12,
              boxShadow: ligado
                  ? [const BoxShadow(color: Color(0x80FFC73B), blurRadius: 24, spreadRadius: 4)]
                  : const [],
            ),
            child: Icon(Icons.lightbulb,
                color: ligado ? Colors.white : Colors.black26, size: 30),
          ),
          const SizedBox(height: 8),
          Switch(value: ligado, onChanged: (v) => setState(() => ligado = v)),
          Text('setState(() => ligado = !ligado)',
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.black45)),
        ]),
      );
}

/// Dois widgets escutando o MESMO estado (ValueNotifier/ChangeNotifier).
class _DemoContadorCompartilhado extends StatefulWidget {
  final String titulo, evento;
  const _DemoContadorCompartilhado({required this.titulo, required this.evento});
  @override
  State<_DemoContadorCompartilhado> createState() => _DemoContadorCompartilhadoState();
}

class _DemoContadorCompartilhadoState extends State<_DemoContadorCompartilhado> {
  final contador = ValueNotifier<int>(0);
  @override
  void dispose() {
    contador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: widget.titulo,
        corpo: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ValueListenableBuilder<int>(
              valueListenable: contador,
              builder: (context, v, child) => Badge(
                label: Text('$v'),
                child: const Icon(Icons.notifications, size: 30, color: _azul),
              ),
            ),
            const SizedBox(width: 28),
            ValueListenableBuilder<int>(
              valueListenable: contador,
              builder: (context, v, child) =>
                  Text('total: $v', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 4),
          const Text('dois widgets, um estado', style: TextStyle(fontSize: 11, color: Colors.black45)),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () => contador.value++,
            child: Text(widget.evento, style: const TextStyle(fontSize: 11)),
          ),
        ]),
      );
}

/// Linha do tempo do ciclo de vida, animada em loop.
class _DemoCicloVida extends StatefulWidget {
  const _DemoCicloVida();
  @override
  State<_DemoCicloVida> createState() => _DemoCicloVidaState();
}

class _DemoCicloVidaState extends State<_DemoCicloVida> {
  static const fases = ['initState', 'build', 'setState → build', 'dispose'];
  int fase = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (mounted) setState(() => fase = (fase + 1) % fases.length);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vivo = fase < 3;
    return _MiniApp(
      titulo: 'Ciclo de vida',
      corpo: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 350),
          opacity: vivo ? 1 : 0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 350),
            scale: vivo ? 1 : .6,
            child: const _Caixa('UI', w: 52, h: 52),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 5, runSpacing: 5, alignment: WrapAlignment.center, children: [
          for (var i = 0; i < fases.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: i == fase ? _azul : const Color(0xFFECEFF1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(fases[i],
                  style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: i == fase ? Colors.white : Colors.black54)),
            ),
        ]),
      ]),
    );
  }
}

/// Navegação REAL entre duas telas (Navigator aninhado + auto-play).
class _DemoNavegacao extends StatefulWidget {
  const _DemoNavegacao();
  @override
  State<_DemoNavegacao> createState() => _DemoNavegacaoState();
}

class _DemoNavegacaoState extends State<_DemoNavegacao> {
  final _nav = GlobalKey<NavigatorState>();
  Timer? _t;
  var _emPush = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      final nav = _nav.currentState;
      if (nav == null || !mounted) return;
      if (_emPush) {
        nav.maybePop();
      } else {
        nav.push(MaterialPageRoute(builder: (_) => _tela2()));
      }
      _emPush = !_emPush;
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Widget _tela1() => Scaffold(
        backgroundColor: _fundo,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Tela 1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () {
                _emPush = true;
                _nav.currentState?.push(MaterialPageRoute(builder: (_) => _tela2()));
              },
              child: const Text('push → Tela 2', style: TextStyle(fontSize: 12)),
            ),
          ]),
        ),
      );

  Widget _tela2() => Scaffold(
        backgroundColor: const Color(0xFFE3F2FD),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Tela 2', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _azul)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                _emPush = false;
                _nav.currentState?.maybePop();
              },
              child: const Text('← pop', style: TextStyle(fontSize: 12)),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'Navegação',
        corpo: Navigator(
          key: _nav,
          onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _tela1()),
        ),
      );
}

/// Hero voando de verdade entre duas telas.
class _DemoHero extends StatefulWidget {
  const _DemoHero();
  @override
  State<_DemoHero> createState() => _DemoHeroState();
}

class _DemoHeroState extends State<_DemoHero> {
  final _nav = GlobalKey<NavigatorState>();
  Timer? _t;
  var _grande = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      final nav = _nav.currentState;
      if (nav == null || !mounted) return;
      _grande ? nav.maybePop() : nav.push(MaterialPageRoute(builder: (_) => _telaGrande()));
      _grande = !_grande;
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  static const _tag = 'foto-demo';

  Widget _foto(double tam) => Hero(
        tag: _tag,
        child: Container(
          width: tam,
          height: tam,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_azul, Color(0xFF64B5F6)]),
            borderRadius: BorderRadius.circular(tam * .18),
          ),
          child: Icon(Icons.image, color: Colors.white, size: tam * .5),
        ),
      );

  Widget _telaLista() => Scaffold(
        backgroundColor: _fundo,
        body: Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _foto(44),
            const SizedBox(width: 10),
            const Text('toque na foto…', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
      );

  Widget _telaGrande() => Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: Center(child: _foto(110)),
      );

  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'Hero',
        corpo: Navigator(
          key: _nav,
          onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _telaLista()),
        ),
      );
}

/// Botão que abre um diálogo REAL (Material ou Cupertino) dentro do celular.
class _DemoDialogo extends StatefulWidget {
  final bool cupertino;
  const _DemoDialogo({this.cupertino = false});
  @override
  State<_DemoDialogo> createState() => _DemoDialogoState();
}

class _DemoDialogoState extends State<_DemoDialogo> {
  final _nav = GlobalKey<NavigatorState>();
  Timer? _t;

  @override
  void initState() {
    super.initState();
    // auto-abre uma vez, logo ao compilar
    _t = Timer(const Duration(milliseconds: 700), _abre);
  }

  void _abre() {
    final ctx = _nav.currentContext;
    if (ctx == null || !mounted) return;
    if (widget.cupertino) {
      showCupertinoDialog<void>(
        context: ctx,
        builder: (c) => CupertinoAlertDialog(
          title: const Text('Atenção'),
          content: const Text('Isto é um diálogo iOS.'),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.pop(c), child: const Text('OK')),
          ],
        ),
      );
    } else {
      showDialog<void>(
        context: ctx,
        builder: (c) => AlertDialog(
          title: const Text('Atenção', style: TextStyle(fontSize: 16)),
          content: const Text('Isto é um diálogo de verdade.', style: TextStyle(fontSize: 13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: widget.cupertino ? 'Diálogo iOS' : 'Diálogo',
        altura: 230,
        corpo: Navigator(
          key: _nav,
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (ctx) => Scaffold(
              backgroundColor: _fundo,
              body: Center(
                child: FilledButton(
                  onPressed: _abre,
                  child: const Text('Abrir diálogo', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
          ),
        ),
      );
}

/// FutureBuilder de verdade: espera → dado chega.
class _DemoFuture extends StatefulWidget {
  const _DemoFuture();
  @override
  State<_DemoFuture> createState() => _DemoFutureState();
}

class _DemoFutureState extends State<_DemoFuture> {
  late Future<String> _f = _carrega();
  Future<String> _carrega() => Future.delayed(const Duration(milliseconds: 1600), () => 'Dados carregados ✓');

  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'FutureBuilder',
        corpo: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          FutureBuilder<String>(
            future: _f,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Column(children: [
                  SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
                  SizedBox(height: 8),
                  Text('ConnectionState.waiting…',
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.black45)),
                ]);
              }
              return Text(snap.data!,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)));
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _f = _carrega()),
            icon: const Icon(Icons.replay, size: 15),
            label: const Text('De novo', style: TextStyle(fontSize: 12)),
          ),
        ]),
      );
}

/// StreamBuilder ao vivo com Stream.periodic.
class _DemoStream extends StatelessWidget {
  const _DemoStream();
  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'StreamBuilder',
        corpo: Center(
          child: StreamBuilder<int>(
            stream: Stream.periodic(const Duration(milliseconds: 800), (i) => i),
            builder: (_, snap) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.podcasts, color: _azul, size: 26),
              const SizedBox(height: 6),
              Text('emitiu: ${snap.data ?? '—'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Text('Stream.periodic', style: TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: Colors.black45)),
            ]),
          ),
        ),
      );
}

/// Tema claro/escuro alternando de verdade.
class _DemoTema extends StatefulWidget {
  const _DemoTema();
  @override
  State<_DemoTema> createState() => _DemoTemaState();
}

class _DemoTemaState extends State<_DemoTema> {
  bool escuro = false;
  @override
  Widget build(BuildContext context) {
    final tema = ThemeData(
      brightness: escuro ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal, brightness: escuro ? Brightness.dark : Brightness.light),
      useMaterial3: true,
    );
    return _MiniApp(
      titulo: 'Tema',
      corpo: Theme(
        data: tema,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          color: tema.colorScheme.surface,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(escuro ? Icons.dark_mode : Icons.light_mode, color: tema.colorScheme.primary, size: 30),
            const SizedBox(height: 6),
            Text(escuro ? 'Brightness.dark' : 'Brightness.light',
                style: TextStyle(
                    fontSize: 11, fontFamily: 'monospace', color: tema.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Switch(value: escuro, onChanged: (v) => setState(() => escuro = v)),
          ]),
        ),
      ),
    );
  }
}

/// AnimationController real com play/repeat.
class _DemoAnimacao extends StatefulWidget {
  const _DemoAnimacao();
  @override
  State<_DemoAnimacao> createState() => _DemoAnimacaoState();
}

class _DemoAnimacaoState extends State<_DemoAnimacao> with SingleTickerProviderStateMixin {
  late final ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..repeat(reverse: true);

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'AnimationController',
        corpo: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedBuilder(
            animation: ctrl,
            builder: (_, child) {
              final t = Curves.easeInOut.transform(ctrl.value);
              return Opacity(
                opacity: .3 + .7 * t,
                child: Transform.scale(scale: .6 + .5 * t, child: const _Caixa('✦', w: 52, h: 52)),
              );
            },
          ),
          const SizedBox(height: 10),
          Text('Tween(begin: 0.0, end: 1.0)',
              style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: Colors.black45)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                onPressed: () => ctrl.repeat(reverse: true),
                icon: const Icon(Icons.play_arrow, size: 18, color: _azul)),
            IconButton(onPressed: ctrl.stop, icon: const Icon(Icons.pause, size: 18, color: _azul)),
          ]),
        ]),
      );
}

/// Abas reais funcionando.
class _DemoAbas extends StatelessWidget {
  const _DemoAbas();
  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'Abas',
        altura: 220,
        corpo: DefaultTabController(
          length: 3,
          child: Column(children: [
            Container(
              color: _azul,
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicatorColor: Colors.white,
                labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                tabs: [Tab(text: 'CASA'), Tab(text: 'BUSCA'), Tab(text: 'PERFIL')],
              ),
            ),
            const Expanded(
              child: TabBarView(children: [
                Center(child: Icon(Icons.home, size: 34, color: _azul)),
                Center(child: Icon(Icons.search, size: 34, color: _azul)),
                Center(child: Icon(Icons.person, size: 34, color: _azul)),
              ]),
            ),
          ]),
        ),
      );
}

/// CustomScrollView com SliverAppBar colapsando, rolando sozinho.
class _DemoSlivers extends StatefulWidget {
  const _DemoSlivers();
  @override
  State<_DemoSlivers> createState() => _DemoSliversState();
}

class _DemoSliversState extends State<_DemoSlivers> {
  final ctrl = ScrollController();
  Timer? _t;
  var _desce = true;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 2100), (_) {
      if (!mounted || !ctrl.hasClients) return;
      ctrl.animateTo(_desce ? ctrl.position.maxScrollExtent : 0,
          duration: const Duration(milliseconds: 1400), curve: Curves.easeInOut);
      _desce = !_desce;
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'Slivers',
        altura: 240,
        corpo: CustomScrollView(
          controller: ctrl,
          slivers: [
            const SliverAppBar(
              pinned: true,
              expandedHeight: 84,
              backgroundColor: _azul,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('SliverAppBar', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => ListTile(
                  dense: true,
                  leading: CircleAvatar(radius: 11, backgroundColor: _azul, child: Text('$i', style: const TextStyle(fontSize: 10, color: Colors.white))),
                  title: Text('Item $i', style: const TextStyle(fontSize: 12)),
                ),
                childCount: 8,
              ),
            ),
          ],
        ),
      );
}

/// ScrollController animando a rolagem de verdade.
class _DemoRolagem extends StatefulWidget {
  const _DemoRolagem();
  @override
  State<_DemoRolagem> createState() => _DemoRolagemState();
}

class _DemoRolagemState extends State<_DemoRolagem> {
  final ctrl = ScrollController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _vai(bool fim) => ctrl.animateTo(fim ? ctrl.position.maxScrollExtent : 0,
      duration: const Duration(seconds: 1), curve: Curves.ease);

  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'ScrollController',
        altura: 230,
        corpo: Column(children: [
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: 12,
              itemBuilder: (_, i) => ListTile(dense: true, title: Text('Linha $i', style: const TextStyle(fontSize: 12))),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(onPressed: () => _vai(true), child: const Text('animateTo(fim)', style: TextStyle(fontSize: 10.5, fontFamily: 'monospace'))),
            TextButton(onPressed: () => _vai(false), child: const Text('animateTo(0)', style: TextStyle(fontSize: 10.5, fontFamily: 'monospace'))),
          ]),
        ]),
      );
}

/// Layout que muda de verdade conforme a largura (arraste o slider).
class _DemoResponsivo extends StatefulWidget {
  const _DemoResponsivo();
  @override
  State<_DemoResponsivo> createState() => _DemoResponsivoState();
}

class _DemoResponsivoState extends State<_DemoResponsivo> {
  double w = 130;
  @override
  Widget build(BuildContext context) {
    final tablet = w > 165;
    return _MiniApp(
      titulo: 'Responsivo',
      altura: 230,
      corpo: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: w,
          height: 86,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              border: Border.all(color: _azul), borderRadius: BorderRadius.circular(8)),
          child: tablet
              ? Row(children: [
                  Expanded(child: _painel('menu')),
                  const SizedBox(width: 5),
                  Expanded(flex: 2, child: _painel('conteúdo')),
                ])
              : _painel('conteúdo'),
        ),
        const SizedBox(height: 4),
        Text(tablet ? 'largura > 600 → Tablet()' : 'largura ≤ 600 → Celular()',
            style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: Colors.black54)),
        Slider(min: 90, max: 210, value: w, onChanged: (v) => setState(() => w = v)),
      ]),
    );
  }

  Widget _painel(String r) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(5)),
        child: Text(r, style: const TextStyle(fontSize: 10, color: _azul)),
      );
}

/// TextEditingController espelhando o texto em tempo real.
class _DemoEntrada extends StatefulWidget {
  const _DemoEntrada();
  @override
  State<_DemoEntrada> createState() => _DemoEntradaState();
}

class _DemoEntradaState extends State<_DemoEntrada> {
  final ctrl = TextEditingController();
  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'TextEditingController',
        corpo: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextField(
              controller: ctrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                  isDense: true, border: OutlineInputBorder(), labelText: 'Digite aqui'),
            ),
            const SizedBox(height: 10),
            Text('ctrl.text = "${ctrl.text}"',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: _azul)),
          ]),
        ),
      );
}

/// Formulário validando de verdade.
class _DemoFormulario extends StatefulWidget {
  const _DemoFormulario();
  @override
  State<_DemoFormulario> createState() => _DemoFormularioState();
}

class _DemoFormularioState extends State<_DemoFormulario> {
  final chave = GlobalKey<FormState>();
  String? resultado;

  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'Formulário',
        altura: 230,
        corpo: Padding(
          padding: const EdgeInsets.all(14),
          child: Form(
            key: chave,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextFormField(
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                    isDense: true, border: OutlineInputBorder(), labelText: 'Nome'),
                validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => setState(() =>
                    resultado = chave.currentState!.validate() ? '✓ enviado!' : null),
                child: const Text('validate()', style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
              ),
              if (resultado != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(resultado!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
        ),
      );
}

/// App mínimo (Material ou Cupertino) montado de verdade.
class _DemoAppMinima extends StatelessWidget {
  final bool cupertino;
  const _DemoAppMinima({this.cupertino = false});
  @override
  Widget build(BuildContext context) {
    if (cupertino) {
      return _MiniApp(
        titulo: 'CupertinoApp',
        corpo: Column(children: [
          Container(
            height: 34,
            color: const Color(0xFFF9F9F9),
            alignment: Alignment.center,
            child: const Text('Minha Tela',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -.3)),
          ),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                onPressed: () {},
                child: const Text('Botão iOS', style: TextStyle(fontSize: 13)),
              ),
            ),
          ),
        ]),
      );
    }
    return _MiniApp(
      titulo: 'MaterialApp',
      corpo: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Olá, Flutter!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          FilledButton(onPressed: () {}, child: const Text('Começar', style: TextStyle(fontSize: 12))),
          const SizedBox(height: 10),
          const Text('runApp → MaterialApp → home',
              style: TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: Colors.black45)),
        ]),
      ),
    );
  }
}

/// TextStyle aplicado de verdade, alternando com o texto sem estilo.
class _DemoTextStyle extends StatefulWidget {
  final String cod;
  const _DemoTextStyle({required this.cod});
  @override
  State<_DemoTextStyle> createState() => _DemoTextStyleState();
}

class _DemoTextStyleState extends State<_DemoTextStyle> {
  bool aplicado = true;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (mounted) setState(() => aplicado = !aplicado);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  TextStyle _estilo() {
    final c = widget.cod;
    return TextStyle(
      fontSize: double.tryParse(RegExp(r'fontSize:\s*([\d.]+)').firstMatch(c)?.group(1) ?? '') ?? 22,
      color: c.contains('Colors.blue')
          ? Colors.blue
          : c.contains('Colors.red')
              ? Colors.red
              : c.contains('Colors.teal')
                  ? Colors.teal
                  : Colors.black87,
      fontWeight: c.contains('FontWeight.bold') ? FontWeight.bold : FontWeight.w400,
      fontStyle: c.contains('FontStyle.italic') ? FontStyle.italic : FontStyle.normal,
      letterSpacing: double.tryParse(RegExp(r'letterSpacing:\s*([\d.]+)').firstMatch(c)?.group(1) ?? ''),
      decoration: c.contains('lineThrough')
          ? TextDecoration.lineThrough
          : c.contains('underline')
              ? TextDecoration.underline
              : null,
    );
  }

  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'TextStyle',
        corpo: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 400),
              style: aplicado ? _estilo() : const TextStyle(fontSize: 22, color: Colors.black87),
              child: const Text('Flutter'),
            ),
            const SizedBox(height: 8),
            Text(aplicado ? 'com estilo' : 'sem estilo',
                style: const TextStyle(fontSize: 10.5, color: Colors.black45)),
          ]),
        ),
      );
}

/// Imagem: asset (aparece direto) ou network (carrega e aparece).
class _DemoImagem extends StatefulWidget {
  final bool rede;
  const _DemoImagem({required this.rede});
  @override
  State<_DemoImagem> createState() => _DemoImagemState();
}

class _DemoImagemState extends State<_DemoImagem> {
  bool carregou = false;

  @override
  void initState() {
    super.initState();
    if (widget.rede) {
      Timer(const Duration(milliseconds: 1300), () {
        if (mounted) setState(() => carregou = true);
      });
    } else {
      carregou = true;
    }
  }

  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: widget.rede ? 'Image.network' : 'Image.asset',
        corpo: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: carregou
                ? Container(
                    key: const ValueKey('img'),
                    width: 110,
                    height: 82,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF64B5F6), Color(0xFF1565C0)]),
                    ),
                    child: const Icon(Icons.landscape, color: Colors.white, size: 38),
                  )
                : const SizedBox(
                    key: ValueKey('load'),
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 3)),
          ),
        ),
      );
}

/// BoxDecoration ligando/desligando para mostrar o efeito.
class _DemoDecoracao extends StatefulWidget {
  final String cod;
  const _DemoDecoracao({required this.cod});
  @override
  State<_DemoDecoracao> createState() => _DemoDecoracaoState();
}

class _DemoDecoracaoState extends State<_DemoDecoracao> {
  bool on = true;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (mounted) setState(() => on = !on);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cod;
    final raio = c.contains('borderRadius') ? 14.0 : 0.0;
    final borda = c.contains('Border.all');
    final sombra = c.contains('boxShadow');
    final circulo = c.contains('BoxShape.circle');
    return _MiniApp(
      titulo: 'BoxDecoration',
      corpo: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: const Color(0xFF90CAF9),
            shape: on && circulo ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: on && !circulo ? BorderRadius.circular(raio) : BorderRadius.zero,
            border: on && borda ? Border.all(color: _azul, width: 3) : null,
            boxShadow: on && sombra
                ? const [BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 5))]
                : const [],
          ),
        ),
      ),
    );
  }
}

/// EdgeInsets pulsando: o recheio aparece e some.
class _DemoEspacamento extends StatefulWidget {
  final String cod;
  const _DemoEspacamento({required this.cod});
  @override
  State<_DemoEspacamento> createState() => _DemoEspacamentoState();
}

class _DemoEspacamentoState extends State<_DemoEspacamento> {
  bool on = true;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1300), (_) {
      if (mounted) setState(() => on = !on);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  EdgeInsets _pad() {
    final c = widget.cod;
    final v = double.tryParse(RegExp(r'\((?:\w+:\s*)?([\d.]+)').firstMatch(c)?.group(1) ?? '') ?? 12;
    if (c.contains('symmetric')) {
      return EdgeInsets.symmetric(
          horizontal: c.contains('horizontal') ? v : 0, vertical: c.contains('vertical') ? v : 0);
    }
    if (c.contains('only')) {
      return EdgeInsets.only(
          top: c.contains('top') ? v : 0,
          left: c.contains('left') ? v : 0,
          right: c.contains('right') ? v : 0,
          bottom: c.contains('bottom') ? v : 0);
    }
    return EdgeInsets.all(v);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cod.contains('SizedBox.shrink')) {
      return _MiniApp(
        titulo: 'SizedBox.shrink',
        corpo: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 500),
            scale: on ? 0 : 1,
            child: const _Caixa('A', w: 52, h: 52),
          ),
        ),
      );
    }
    return _MiniApp(
      titulo: 'EdgeInsets',
      corpo: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          padding: on ? _pad() * 1.6 : EdgeInsets.zero,
          color: const Color(0xFFFFE082),
          child: const _Caixa('filho', w: 76, h: 44),
        ),
      ),
    );
  }
}

/// MainAxisAlignment animando entre start e o valor do exercício.
class _DemoAlinhamento extends StatefulWidget {
  final String cod;
  const _DemoAlinhamento({required this.cod});
  @override
  State<_DemoAlinhamento> createState() => _DemoAlinhamentoState();
}

class _DemoAlinhamentoState extends State<_DemoAlinhamento> {
  bool aplicado = true;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) setState(() => aplicado = !aplicado);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  MainAxisAlignment _valor() {
    final c = widget.cod;
    if (c.contains('spaceBetween')) return MainAxisAlignment.spaceBetween;
    if (c.contains('spaceAround')) return MainAxisAlignment.spaceAround;
    if (c.contains('spaceEvenly')) return MainAxisAlignment.spaceEvenly;
    if (c.contains('.end')) return MainAxisAlignment.end;
    return MainAxisAlignment.center;
  }

  @override
  Widget build(BuildContext context) {
    final nome = RegExp(r'MainAxisAlignment\.(\w+)').firstMatch(widget.cod)?.group(1) ?? 'center';
    return _MiniApp(
      titulo: 'MainAxisAlignment',
      corpo: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 190,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB0BEC5)), borderRadius: BorderRadius.circular(8)),
          child: AnimatedAlignmentRow(alinhamento: aplicado ? _valor() : MainAxisAlignment.start),
        ),
        const SizedBox(height: 8),
        Text(aplicado ? '.$nome' : '.start',
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: _azul)),
      ]),
    );
  }
}

/// Row cujos filhos deslizam suavemente quando o alinhamento muda.
class AnimatedAlignmentRow extends StatelessWidget {
  final MainAxisAlignment alinhamento;
  const AnimatedAlignmentRow({super.key, required this.alinhamento});
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: Row(
          key: ValueKey(alinhamento),
          mainAxisAlignment: alinhamento,
          children: const [_Caixa('A', w: 30, h: 30), SizedBox(width: 4), _Caixa('B', w: 30, h: 30, cor: Color(0xFF42A5F5)), SizedBox(width: 4), _Caixa('C', w: 30, h: 30, cor: Color(0xFF90CAF9))],
        ),
      );
}

/// Alignment: a caixa desliza para o canto indicado.
class _DemoAlign extends StatefulWidget {
  final String cod;
  const _DemoAlign({required this.cod});
  @override
  State<_DemoAlign> createState() => _DemoAlignState();
}

class _DemoAlignState extends State<_DemoAlign> {
  bool aplicado = true;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) setState(() => aplicado = !aplicado);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Alignment _valor() {
    final m = RegExp(r'Alignment\.(\w+)').firstMatch(widget.cod)?.group(1) ?? 'center';
    return switch (m) {
      'topLeft' => Alignment.topLeft,
      'topCenter' => Alignment.topCenter,
      'topRight' => Alignment.topRight,
      'centerLeft' => Alignment.centerLeft,
      'centerRight' => Alignment.centerRight,
      'bottomLeft' => Alignment.bottomLeft,
      'bottomCenter' => Alignment.bottomCenter,
      'bottomRight' => Alignment.bottomRight,
      _ => Alignment.center,
    };
  }

  @override
  Widget build(BuildContext context) {
    final nome = RegExp(r'Alignment\.(\w+)').firstMatch(widget.cod)?.group(1) ?? 'center';
    return _MiniApp(
      titulo: 'Alignment',
      corpo: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 150,
          height: 96,
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB0BEC5)), borderRadius: BorderRadius.circular(8)),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: aplicado ? _valor() : Alignment.center,
            child: const Padding(padding: EdgeInsets.all(4), child: _Caixa('A', w: 28, h: 28)),
          ),
        ),
        const SizedBox(height: 6),
        Text('.$nome', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: _azul)),
      ]),
    );
  }
}

/// Expanded/Flexible reais dividindo o espaço.
class _DemoExpanded extends StatelessWidget {
  final bool flex2;
  const _DemoExpanded({required this.flex2});
  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'Expanded',
        corpo: Center(
          child: Container(
            width: 195,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFB0BEC5)), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Expanded(
                  flex: flex2 ? 2 : 1,
                  child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      color: _azul,
                      child: Text(flex2 ? 'A · flex: 2' : 'A',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))),
              const SizedBox(width: 4),
              Expanded(
                  child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      color: const Color(0xFF90CAF9),
                      child: const Text('B', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))),
            ]),
          ),
        ),
      );
}

/// Stack/Positioned reais com as coordenadas do exercício.
class _DemoStack extends StatelessWidget {
  final String cod;
  const _DemoStack({required this.cod});
  @override
  Widget build(BuildContext context) {
    double? pega(String chave) =>
        double.tryParse(RegExp('$chave:\\s*([\\d.]+)').firstMatch(cod)?.group(1) ?? '');
    final top = pega('top'), left = pega('left'), bottom = pega('bottom');
    final temPos = cod.contains('Positioned');
    return _MiniApp(
      titulo: temPos ? 'Positioned' : 'Stack',
      corpo: Center(
        child: Container(
          width: 150,
          height: 100,
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB0BEC5)), borderRadius: BorderRadius.circular(8)),
          child: Stack(children: [
            const Center(child: _Caixa('A', w: 62, h: 62, cor: Color(0xFF90CAF9))),
            if (temPos)
              Positioned(
                  top: top, left: left ?? (bottom != null ? 8 : null), bottom: bottom,
                  child: const _Caixa('B', w: 30, h: 30))
            else
              const Center(child: _Caixa('B', w: 30, h: 30)),
          ]),
        ),
      ),
    );
  }
}

/// Opacity / ClipRRect / Transform.rotate / AspectRatio aplicados de verdade.
class _DemoEfeito extends StatefulWidget {
  final String cod;
  const _DemoEfeito({required this.cod});
  @override
  State<_DemoEfeito> createState() => _DemoEfeitoState();
}

class _DemoEfeitoState extends State<_DemoEfeito> {
  bool on = true;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (mounted) setState(() => on = !on);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cod;
    const alvo = _Caixa('A', w: 64, h: 64);
    Widget efeito;
    String titulo;
    if (c.contains('Transform.rotate')) {
      titulo = 'Transform.rotate';
      final ang = double.tryParse(RegExp(r'angle:\s*([\d.]+)').firstMatch(c)?.group(1) ?? '') ?? .5;
      efeito = AnimatedRotation(
          duration: const Duration(milliseconds: 500),
          turns: on ? ang / 6.2832 : 0,
          child: alvo);
    } else if (c.contains('Opacity')) {
      titulo = 'Opacity';
      final op = double.tryParse(RegExp(r'opacity:\s*([\d.]+)').firstMatch(c)?.group(1) ?? '') ?? .5;
      efeito = AnimatedOpacity(
          duration: const Duration(milliseconds: 500), opacity: on ? op : 1, child: alvo);
    } else if (c.contains('AspectRatio')) {
      titulo = 'AspectRatio';
      efeito = AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: on ? 128 : 64,
        height: on ? 72 : 64,
        decoration: BoxDecoration(color: _azul, borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text(on ? '16 : 9' : '1 : 1',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      );
    } else {
      titulo = 'ClipRRect';
      efeito = AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
            color: _azul, borderRadius: BorderRadius.circular(on ? 22 : 0)),
        alignment: Alignment.center,
        child: const Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
    }
    return _MiniApp(titulo: titulo, corpo: Center(child: efeito));
  }
}

/// Grade de exemplo com itens.
class _DemoGrade extends StatelessWidget {
  const _DemoGrade();
  @override
  Widget build(BuildContext context) => _MiniApp(
        titulo: 'GridView',
        altura: 220,
        corpo: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(10),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: List.generate(
            4,
            (i) => Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
              child: Text('$i',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _azul)),
            ),
          ),
        ),
      );
}
