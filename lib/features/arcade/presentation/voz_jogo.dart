import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/mixart.dart';
import '../../ingles/data/voz_ingles.dart';
import 'banco_arcade.dart';

/// Quem fala a palavra no jogo: a [VozIngles] de verdade (o áudio do aluno, a gravação de nativo ou a
/// voz do navegador); os testes trocam por um falso.
abstract interface class FalanteDoJogo {
  /// O navegador já deixa tocar sozinho (a página teve tecla/clique)?
  bool get liberado;

  /// Fala [palavra] na velocidade normal, cortando a que estiver soando. Nunca lança.
  void falar(String palavra);

  /// Corta a fala em curso.
  void parar();
}

/// O [FalanteDoJogo] do app: a mesma voz das lições, sem a 🐢 (no jogo a palavra vem no ritmo normal).
class FalanteIngles implements FalanteDoJogo {
  final VozIngles voz;
  FalanteIngles([VozIngles? voz]) : voz = voz ?? VozIngles();

  @override
  bool get liberado => voz.somLiberado;

  @override
  void falar(String palavra) => unawaited(voz.falar(palavra, lenta: false));

  @override
  void parar() => unawaited(voz.parar());
}

/// 🔊 A voz dos jogos de digitação no inglês: fala a palavra que a pessoa vai digitar (Rali, Turismo,
/// Chuva). Nunca repete a mesma palavra em menos de [janelaRepeticao]; a nova corta a anterior. Fica
/// muda na pausa, no fim de jogo, com a chave desligada ([ligada], salva por aparelho), no Dart e no
/// C# e antes do 1º gesto na página (o navegador bloqueia o áudio). Independe do liga/desliga dos
/// EFEITOS (`Sons.ligado`, invisível no arcade) — tem a chave própria, o chip "🔊 Voz" de cada jogo.
class VozDoJogo {
  /// Pref: falar as palavras nos jogos (padrão: sim).
  static const prefFalar = 'arcade_falar_palavras';
  static bool ligada = true;

  /// Lê a preferência salva (cada jogo chama ao abrir).
  static Future<bool> carregarPreferencia() async {
    try {
      final p = await SharedPreferences.getInstance();
      ligada = p.getBool(prefFalar) ?? true;
    } catch (_) {}
    return ligada;
  }

  static Future<void> salvarPreferencia(bool v) async {
    ligada = v;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(prefFalar, v);
    } catch (_) {}
  }

  /// Nos testes: o falante de toda [VozDoJogo] criada sem um (null = a [VozIngles] de verdade).
  @visibleForTesting
  static FalanteDoJogo Function()? falanteDeTeste;

  /// A mesma palavra de novo dentro desta janela não é falada (o portal que trava de novo, a palavra
  /// repetida no baralho).
  static const janelaRepeticao = Duration(milliseconds: 1500);

  final FalanteDoJogo _falante;
  final DateTime Function() _agora;
  final bool Function() _ingles;

  String? _ultima;
  DateTime? _quando;
  bool _falou = false;
  bool _encerrada = false;

  VozDoJogo({FalanteDoJogo? falante, DateTime Function()? agora, bool Function()? ingles})
      : _falante = falante ?? falanteDeTeste?.call() ?? FalanteIngles(),
        _agora = agora ?? DateTime.now,
        _ingles = ingles ?? (() => BancoArcade.soDigitacao);

  /// A voz vale aqui: chave ligada e o jogo é do inglês.
  bool get ativa => ligada && _ingles();

  /// Fala [palavra] (se puder). Devolve se falou — o Turismo abaixa a música só quando fala.
  /// [forcar]: ignora a [janelaRepeticao] (o Rali repetindo a palavra que a pausa cortou).
  bool falar(String palavra, {bool pausado = false, bool acabou = false, bool forcar = false}) {
    final w = palavra.trim();
    if (_encerrada || w.isEmpty || pausado || acabou || !ativa) return false;
    if (!_falante.liberado) return false;
    final agora = _agora();
    final antes = _quando;
    if (!forcar && w == _ultima && antes != null && agora.difference(antes) < janelaRepeticao) return false;
    _ultima = w;
    _quando = agora;
    _falou = true;
    _falante.falar(w);
    return true;
  }

  /// Corta a fala em curso (pausa, fim de jogo, chave desligada). Sem nada falado, não mexe na voz.
  void calar() {
    if (!_falou) return;
    _falou = false;
    _falante.parar();
  }

  /// O chip "🔊 Voz": liga/desliga (salvo) e, desligando, corta a fala.
  Future<void> alternar() {
    final nova = !ligada;
    if (!nova) calar();
    return salvarPreferencia(nova);
  }

  /// O jogo saiu de cena: cala e não fala mais.
  void encerrar() {
    calar();
    _encerrada = true;
  }
}

/// 🔊 O chip da voz das palavras (só no inglês): pílula como o 🎸 do Turismo.
/// [compacto]: "🔊 Voz" (cabeçalho/HUD, onde o celular aperta); senão, por extenso como os vizinhos
/// ("🔊 Falar palavras ligado"), nas opções do Turismo.
class BotaoVozJogo extends StatelessWidget {
  final VoidCallback onTap;
  final bool compacto;
  const BotaoVozJogo({super.key, required this.onTap, this.compacto = true});

  @override
  Widget build(BuildContext context) {
    final ligada = VozDoJogo.ligada;
    return Semantics(
      container: true,
      button: true,
      toggled: ligada,
      label: 'voz das palavras ${ligada ? 'ligada' : 'desligada'}',
      excludeSemantics: true,
      onTap: onTap, // o excludeSemantics tira a ação do InkWell: sem isto o leitor de tela não aciona
      child: Tooltip(
        message: ligada ? 'Falar as palavras: ligado' : 'Falar as palavras: desligado',
        child: Material(
          color: ligada ? Mixart.brandSub : Mixart.surface,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ShapeDecoration(
                shape: StadiumBorder(side: BorderSide(color: ligada ? Mixart.brand : Mixart.border)),
              ),
              child: Text(
                  compacto
                      ? '${ligada ? '🔊' : '🔇'} Voz'
                      : '${ligada ? '🔊' : '🔇'} Falar palavras ${ligada ? 'ligado' : 'desligado'}',
                  style: Mixart.ui(size: 11, weight: FontWeight.w700, color: ligada ? Mixart.brand : Mixart.text)),
            ),
          ),
        ),
      ),
    );
  }
}
