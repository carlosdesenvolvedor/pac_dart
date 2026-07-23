import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/missao.dart';
import 'avatares.dart';
import 'cenario.dart';

/// O palco do Lógica Animada: desenha a cena da missão a partir do
/// [estado] (o `dados` da missão + os `muda` dos passos já executados).
class CenaMissao extends StatelessWidget {
  final Missao missao;
  final Map<String, Object> estado;

  /// Trilha de origem — define o pano de fundo (cicla os 6 cenários).
  final int trilha;

  const CenaMissao({super.key, required this.missao, required this.estado, required this.trilha});

  int _n(String k, [int d = 0]) => ((estado[k] as num?) ?? d).toInt();
  double _f(String k, [double d = 0]) => ((estado[k] as num?) ?? d).toDouble();
  bool _b(String k) => estado[k] == true;
  String _s(String k, [String d = '']) => (estado[k] as String?) ?? d;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Mixart.radiusMd),
      child: SizedBox(
        height: 188,
        child: LayoutBuilder(builder: (context, box) {
          return Stack(children: [
            Positioned.fill(child: CenarioFase(fase: trilha % 6 + 1)),
            Positioned.fill(child: Container(color: const Color(0x3406070B))),
            // chão
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(height: 26, color: const Color(0xB32E3238)),
            ),
            ...switch (missao.cena) {
              Cena.porta => _porta(box),
              Cena.blitz => _blitz(box),
              Cena.colheita => _colheita(box),
              Cena.semaforo => _semaforo(box),
              Cena.foguete => _foguete(box),
              Cena.ponte => _ponte(box),
              Cena.mercado => _mercado(box),
              Cena.cofre => _cofre(box),
            },
          ]);
        }),
      ),
    );
  }

  // ---------- 🚪 porta ----------
  List<Widget> _porta(BoxConstraints box) {
    final total = _n('total', 1);
    final frac = (_n('avanco') / total).clamp(0.0, 1.0);
    final aberta = _b('aberta');
    final placa = _s('placa');
    final xPorta = box.maxWidth - 74;
    return [
      // porta
      Positioned(
        left: xPorta,
        bottom: 24,
        child: Container(
          width: 46,
          height: 74,
          decoration: BoxDecoration(
            color: aberta ? const Color(0xFF1A1208) : const Color(0xFF6D4C2F),
            border: Border.all(color: aberta ? Mixart.brand : const Color(0xFF4E361F), width: 3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: aberta ? [BoxShadow(color: Mixart.brandDim, blurRadius: 16)] : const [],
          ),
          child: aberta
              ? Icon(Icons.star, size: 18, color: Mixart.brand)
              : const Align(
                  alignment: Alignment(0.55, 0),
                  child:
                      SizedBox(width: 6, height: 6, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFD9B36C), shape: BoxShape.circle))),
                ),
        ),
      ),
      if (placa.isNotEmpty)
        Positioned(
          left: xPorta - 40,
          bottom: 106,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xE610131A),
              border: Border.all(color: Mixart.brandDim),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(placa, style: Mixart.mono(size: 11, color: Mixart.brand)),
          ),
        ),
      AnimatedPositioned(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        left: 16 + frac * (xPorta - 62),
        bottom: 22,
        child: const AvatarPersonagem(tamanho: 38),
      ),
    ];
  }

  // ---------- 🚓 blitz ----------
  List<Widget> _blitz(BoxConstraints box) {
    final rotulos = (estado['rotulos'] as List?)?.cast<String>() ?? const <String>[];
    final atual = _n('atual', -1);
    const carros = ['🚗', '🚙', '🚕', '🚐'];
    final larguraVaga = (box.maxWidth - 120) / (rotulos.isEmpty ? 1 : rotulos.length);
    return [
      // guarita do guarda
      Positioned(
        left: 12,
        bottom: 22,
        child: Column(children: [
          const Text('🚨', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          const AvatarPersonagem(tamanho: 34),
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: const Color(0xE610131A), borderRadius: BorderRadius.circular(999)),
            child: const Text('👮 blitz',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      for (var i = 0; i < rotulos.length; i++)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          left: 104 + i * larguraVaga,
          bottom: atual == i ? 34 : 24,
          child: Column(children: [
            if (estado.containsKey('v$i'))
              Text(_b('v$i') ? '✅' : '⛔', style: const TextStyle(fontSize: 15))
            else
              const SizedBox(height: 18),
            AnimatedScale(
              scale: atual == i ? 1.25 : 1,
              duration: const Duration(milliseconds: 250),
              child: Text(carros[i % carros.length], style: const TextStyle(fontSize: 28)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: const Color(0xE610131A), borderRadius: BorderRadius.circular(999)),
              child: Text(rotulos[i],
                  style: const TextStyle(
                      color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
    ];
  }

  // ---------- 🍇 colheita ----------
  List<Widget> _colheita(BoxConstraints box) {
    final total = _n('total', 1);
    final colhidas = _n('colhidas');
    final emoji = _s('emoji', '🍎');
    return [
      Positioned(
        left: 24,
        bottom: 18,
        child: const Text('🌳', style: TextStyle(fontSize: 64)),
      ),
      // frutas ainda na árvore
      for (var i = colhidas; i < total; i++)
        Positioned(
          left: 34 + (i % 3) * 22,
          bottom: 64 + (i ~/ 3) * 20,
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
      Positioned(
        right: 26,
        bottom: 22,
        child: Column(children: [
          const Text('🧺', style: TextStyle(fontSize: 34)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: const Color(0xE610131A), borderRadius: BorderRadius.circular(999)),
            child: Text('$emoji x $colhidas',
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      Positioned(
        left: box.maxWidth / 2 - 20,
        bottom: 22,
        child: const AvatarPersonagem(tamanho: 36),
      ),
    ];
  }

  // ---------- 🚦 semáforo ----------
  List<Widget> _semaforo(BoxConstraints box) {
    final cor = _s('cor', 'apagado');
    final seguindo = _s('acao') == 'siga';
    Color luz(String qual, Color acesa) => cor == qual ? acesa : const Color(0xFF23262C);
    return [
      Positioned(
        right: 46,
        bottom: 24,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF15181D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF31353C), width: 2),
            ),
            child: Column(children: [
              for (final (qual, c) in [
                ('vermelho', const Color(0xFFF2555A)),
                ('amarelo', const Color(0xFFFFC73B)),
                ('verde', const Color(0xFF57C765)),
              ])
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: luz(qual, c),
                    shape: BoxShape.circle,
                    boxShadow: cor == qual ? [BoxShadow(color: c, blurRadius: 10)] : const [],
                  ),
                ),
            ]),
          ),
          Container(width: 4, height: 34, color: const Color(0xFF31353C)),
        ]),
      ),
      AnimatedPositioned(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        left: seguindo ? box.maxWidth - 40 : 40,
        bottom: 22,
        child: const Text('🚗', style: TextStyle(fontSize: 30)),
      ),
    ];
  }

  // ---------- 🚀 foguete ----------
  List<Widget> _foguete(BoxConstraints box) {
    final contagem = _n('contagem');
    final altura = _f('altura');
    return [
      Positioned(
        left: box.maxWidth / 2 - 34,
        bottom: 20,
        child: Container(width: 68, height: 8, color: const Color(0xFF4A4F57)),
      ),
      AnimatedPositioned(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInCubic,
        left: box.maxWidth / 2 - 16,
        bottom: 28 + altura * 150,
        child: Text(altura > 0 ? '🚀' : '🚀', style: const TextStyle(fontSize: 32)),
      ),
      if (altura > 0)
        Positioned(
          left: box.maxWidth / 2 - 10,
          bottom: 24 + altura * 120,
          child: const Text('🔥', style: TextStyle(fontSize: 18)),
        ),
      if (contagem > 0)
        Positioned(
          left: 24,
          top: 18,
          child: Text('$contagem',
              style: Mixart.display(size: 44, color: Mixart.brand)),
        ),
      Positioned(
        left: box.maxWidth / 2 - 74,
        bottom: 22,
        child: const AvatarPersonagem(tamanho: 34),
      ),
    ];
  }

  // ---------- 🛒 mercado ----------
  List<Widget> _mercado(BoxConstraints box) {
    final rotulos = (estado['rotulos'] as List?)?.cast<String>() ?? const <String>[];
    final atual = _n('atual', -1);
    final display = _s('display', '···');
    final larguraVaga = (box.maxWidth - 190) / (rotulos.isEmpty ? 1 : rotulos.length);
    return [
      Positioned(
        left: 14,
        bottom: 22,
        child: const AvatarPersonagem(tamanho: 36),
      ),
      // prateleira de produtos
      for (var i = 0; i < rotulos.length; i++)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          left: 66 + i * larguraVaga,
          bottom: atual == i ? 40 : 30,
          child: AnimatedScale(
            scale: atual == i ? 1.2 : 1,
            duration: const Duration(milliseconds: 250),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xE610131A),
                border: Border.all(
                    color: atual == i ? Mixart.brand : const Color(0xFF31353C)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(rotulos[i],
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      // caixa registradora com visor
      Positioned(
        right: 16,
        bottom: 24,
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1F14),
              border: Border.all(color: const Color(0xFF2F6B45)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(display,
                style: Mixart.mono(size: 13, color: const Color(0xFF6BE398))),
          ),
          const SizedBox(height: 4),
          const Text('🧾', style: TextStyle(fontSize: 24)),
        ]),
      ),
    ];
  }

  // ---------- 🔐 cofre ----------
  List<Widget> _cofre(BoxConstraints box) {
    final aberto = _b('aberto');
    final display = _s('display', '···');
    return [
      Positioned(
        left: 22,
        bottom: 22,
        child: const AvatarPersonagem(tamanho: 38),
      ),
      // painel da senha
      Positioned(
        right: 34,
        top: 18,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xE610131A),
            border: Border.all(color: aberto ? Mixart.brand : const Color(0xFF31353C)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(display, style: Mixart.mono(size: 13, color: Mixart.brand)),
        ),
      ),
      // a porta redonda do cofre
      Positioned(
        right: 40,
        bottom: 30,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: aberto ? const Color(0xFF141007) : const Color(0xFF4A5058),
            border: Border.all(
                color: aberto ? Mixart.brand : const Color(0xFF31353C), width: 7),
            boxShadow:
                aberto ? [BoxShadow(color: Mixart.brandDim, blurRadius: 22)] : const [],
          ),
          child: Center(
            child: Text(aberto ? '💎' : '🔒', style: const TextStyle(fontSize: 30)),
          ),
        ),
      ),
    ];
  }

  // ---------- 🌉 ponte ----------
  List<Widget> _ponte(BoxConstraints box) {
    final pranchas = _n('pranchas', 1);
    final colocadas = _n('colocadas');
    final travessia = _f('travessia');
    final margem = box.maxWidth * 0.26;
    final vaoLargura = box.maxWidth - margem * 2;
    final larguraPrancha = vaoLargura / pranchas;
    return [
      // penhascos
      Positioned(
          left: 0, bottom: 0, child: Container(width: margem, height: 66, color: const Color(0xFF3B3F46))),
      Positioned(
          right: 0, bottom: 0, child: Container(width: margem, height: 66, color: const Color(0xFF3B3F46))),
      // pranchas colocadas
      for (var i = 0; i < colocadas && i < pranchas; i++)
        Positioned(
          left: margem + i * larguraPrancha,
          bottom: 58,
          child: Container(
            width: larguraPrancha - 3,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5A2B),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFF5E3D1D)),
            ),
          ),
        ),
      AnimatedPositioned(
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
        left: (margem - 48) + travessia * (vaoLargura + 52),
        bottom: 66,
        child: const AvatarPersonagem(tamanho: 34),
      ),
    ];
  }
}
