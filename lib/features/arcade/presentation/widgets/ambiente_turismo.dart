import 'package:flutter/material.dart';

import 'cenario.dart';

/// O clima desenhado por cima do fallback 2D do Turismo (celular nativo e WebGL que falhou).
enum Clima2D { nenhum, chuva, neve, folhas, areia, estrelas, brasas, fogos, neblina, aurora, vagalumes }

/// 🌍 O mundo de uma pista do Turismo no fallback 2D — espelho da tabela `TEMAS` do 3D
/// (`web/turismo3d/turismo3d.js`). Temas 1–6 são os mundos clássicos de `cenario.dart`;
/// 7–26 só existem no English Turismo (pistas 11–30) e pintam por cima de um mundo [base].
class AmbienteTurismo {
  /// 1..26 (o `PistaGt.tema`).
  final int tema;

  /// 1..6 → `CenarioFase`/`chaoDaFase` existentes.
  final int base;

  /// Nome CURTO do mundo (≠ nome da pista).
  final String nome;
  final String emoji;
  final bool noturno;

  /// Véu de cor sobre o céu do mundo [base] e a força dele (0 = nenhum).
  final Color? tintaCeu;
  final double tintaForca;

  /// Chão próprio; null = `chaoDaFase(base)`.
  final TemaChao? chao;
  final Clima2D clima;

  /// ⛈️ Clarão de relâmpago por cima da chuva (o `relampago` do tema no 3D); some com
  /// "reduzir animações" e respeita o limite de flash (ver `CamadaClima2D`).
  final bool relampago;

  const AmbienteTurismo({
    required this.tema,
    required this.base,
    required this.nome,
    required this.emoji,
    required this.noturno,
    this.tintaCeu,
    this.tintaForca = 0,
    this.chao,
    this.clima = Clima2D.nenhum,
    this.relampago = false,
  });

  /// O chão efetivo (o próprio ou o do mundo [base]).
  TemaChao get chaoEfetivo => chao ?? chaoDaFase(base);

  /// 1..6: os mundos clássicos (nome/emoji de `cenario.dart`, noturno = base ∈ {3, 5, 6});
  /// 7..26: a tabela do English Turismo; fora disso → [de] (1).
  static AmbienteTurismo de(int tema) {
    if (tema >= 1 && tema <= 6) {
      return AmbienteTurismo(
        tema: tema,
        base: tema,
        nome: nomeDaFase(tema),
        emoji: emojiDaFase(tema),
        noturno: tema == 3 || tema == 5 || tema == 6,
      );
    }
    return _extras[tema] ?? de(1);
  }

  /// O tema que vai pro módulo 3D (`web/turismo3d/turismo3d.js`): os mundos 7–26 só quando o
  /// módulo carregado está na versão [esperada] (ou mais nova); com um módulo velho do cache, o
  /// mundo [base] — que ele conhece — em vez de cair em Campina sem aviso.
  static int temaPara3d(int tema, {required int versaoModulo, required int esperada}) =>
      tema > 6 && versaoModulo < esperada ? de(tema).base : tema;

  static const _extras = <int, AmbienteTurismo>{
    7: AmbienteTurismo(
      tema: 7,
      base: 1,
      nome: 'Campina ao Entardecer',
      emoji: '🌇',
      noturno: false,
      tintaCeu: Color(0xFFFF8A3D),
      tintaForca: .35,
      chao: TemaChao(
          claro: Color(0xFF9DAE5A), escuro: Color(0xFF8A9A4C), neblina: Color(0xFFF0A46A), adereco: Adereco.arvore),
      clima: Clima2D.vagalumes,
    ),
    8: AmbienteTurismo(
      tema: 8,
      base: 1,
      nome: 'Vale Enevoado',
      emoji: '🌫️',
      noturno: false,
      tintaCeu: Color(0xFFC9D3DC),
      tintaForca: .45,
      chao: TemaChao(
          claro: Color(0xFF7FA37A), escuro: Color(0xFF6E916A), neblina: Color(0xFFC9D3DC), adereco: Adereco.pinheiro),
      clima: Clima2D.neblina,
    ),
    9: AmbienteTurismo(
      tema: 9,
      base: 1,
      nome: 'Bosque de Outono',
      emoji: '🍁',
      noturno: false,
      tintaCeu: Color(0xFFFFB060),
      tintaForca: .25,
      chao: TemaChao(
          claro: Color(0xFFC98A3A), escuro: Color(0xFFB57A30), neblina: Color(0xFFF6D2A6), adereco: Adereco.arvore),
      clima: Clima2D.folhas,
    ),
    10: AmbienteTurismo(
      tema: 10,
      base: 1,
      nome: 'Campina sob Raios',
      emoji: '⛈️',
      noturno: true,
      tintaCeu: Color(0xFF3E4A57),
      tintaForca: .55,
      chao: TemaChao(
          claro: Color(0xFF4F6B45), escuro: Color(0xFF44603C), neblina: Color(0xFF5D6873), adereco: Adereco.arvore),
      clima: Clima2D.chuva,
      relampago: true,
    ),
    11: AmbienteTurismo(
      tema: 11,
      base: 2,
      nome: 'Litoral Ensolarado',
      emoji: '🏖️',
      noturno: false,
      tintaCeu: Color(0xFF7FD3F5),
      tintaForca: .25,
      chao: TemaChao(
          claro: Color(0xFFF1DDB0), escuro: Color(0xFFE3CC9C), neblina: Color(0xFFCFE6F5), adereco: Adereco.arvore),
    ),
    12: AmbienteTurismo(
      tema: 12,
      base: 1,
      nome: 'Mar Aberto',
      emoji: '🌉',
      noturno: false,
      tintaCeu: Color(0xFF7FC4F0),
      tintaForca: .30,
      chao: TemaChao(
          claro: Color(0xFF2A86B8), escuro: Color(0xFF2379A8), neblina: Color(0xFFD6ECFF), adereco: Adereco.poste),
    ),
    13: AmbienteTurismo(
      tema: 13,
      base: 2,
      nome: 'Paredões Vermelhos',
      emoji: '🏜️',
      noturno: false,
      tintaCeu: Color(0xFFE07040),
      tintaForca: .25,
      chao: TemaChao(
          claro: Color(0xFFC8643C), escuro: Color(0xFFB5583A), neblina: Color(0xFFE0A070), adereco: Adereco.rocha),
    ),
    14: AmbienteTurismo(
      tema: 14,
      base: 2,
      nome: 'Deserto em Fúria',
      emoji: '🌪️',
      noturno: false,
      tintaCeu: Color(0xFFD9A35C),
      tintaForca: .50,
      clima: Clima2D.areia,
    ),
    15: AmbienteTurismo(
      tema: 15,
      base: 2,
      nome: 'Oásis Noturno',
      emoji: '🌙',
      noturno: true,
      tintaCeu: Color(0xFF0B1330),
      tintaForca: .70,
      chao: TemaChao(
          claro: Color(0xFF6E6152), escuro: Color(0xFF615546), neblina: Color(0xFF10162B), adereco: Adereco.arvore),
      clima: Clima2D.estrelas,
    ),
    16: AmbienteTurismo(
      tema: 16,
      base: 3,
      nome: 'Centro ao Sol',
      emoji: '🏙️',
      noturno: false,
      tintaCeu: Color(0xFF8EC9FF),
      tintaForca: .65,
      chao: TemaChao(
          claro: Color(0xFF9E9E9E), escuro: Color(0xFF8C8C8C), neblina: Color(0xFFDFE8F0), adereco: Adereco.poste),
    ),
    17: AmbienteTurismo(
      tema: 17,
      base: 3,
      nome: 'Metrópole Molhada',
      emoji: '🌧️',
      noturno: true,
      tintaCeu: Color(0xFF223040),
      tintaForca: .35,
      clima: Clima2D.chuva,
    ),
    18: AmbienteTurismo(
      tema: 18,
      base: 3,
      nome: 'Distrito Neon',
      emoji: '🌆',
      noturno: true,
      tintaCeu: Color(0xFFFF2FD0),
      tintaForca: .25,
      chao: TemaChao(
          claro: Color(0xFF2B3542),
          escuro: Color(0xFF232C38),
          neblina: Color(0xFF6C8BB5),
          linha: Color(0xFF22E6FF),
          adereco: Adereco.poste),
    ),
    19: AmbienteTurismo(
      tema: 19,
      base: 4,
      nome: 'Montanha Branca',
      emoji: '🌨️',
      noturno: false,
      tintaCeu: Color(0xFFDFE8F2),
      tintaForca: .45,
      clima: Clima2D.neve,
    ),
    20: AmbienteTurismo(
      tema: 20,
      base: 4,
      nome: 'Lago de Gelo',
      emoji: '🧊',
      noturno: false,
      tintaCeu: Color(0xFFBFE3FF),
      tintaForca: .20,
      chao: TemaChao(
          claro: Color(0xFFBFE3FF), escuro: Color(0xFFAED6F5), neblina: Color(0xFFEAF3FF), adereco: Adereco.pinheiro),
      clima: Clima2D.neve,
    ),
    21: AmbienteTurismo(
      tema: 21,
      base: 4,
      nome: 'Céu de Aurora',
      emoji: '🌌',
      noturno: true,
      tintaCeu: Color(0xFF0D1830),
      tintaForca: .70,
      chao: TemaChao(
          claro: Color(0xFF9FB4D8), escuro: Color(0xFF8EA3C7), neblina: Color(0xFF0D1830), adereco: Adereco.pinheiro),
      clima: Clima2D.aurora,
    ),
    22: AmbienteTurismo(
      tema: 22,
      base: 5,
      nome: 'Cratera de Fogo',
      emoji: '🌋',
      noturno: true,
      tintaCeu: Color(0xFFFF3A1A),
      tintaForca: .20,
      clima: Clima2D.brasas,
    ),
    23: AmbienteTurismo(
      tema: 23,
      base: 6,
      nome: 'Superfície Lunar',
      emoji: '🌕',
      noturno: true,
      tintaCeu: Color(0xFF05070D),
      tintaForca: .30,
      chao: TemaChao(
          claro: Color(0xFF9E9E9E), escuro: Color(0xFF8A8A8A), neblina: Color(0xFF05070D), adereco: Adereco.rocha),
      clima: Clima2D.estrelas,
    ),
    24: AmbienteTurismo(
      tema: 24,
      base: 2,
      nome: 'Planeta Vermelho',
      emoji: '🔴',
      noturno: false,
      tintaCeu: Color(0xFFC0623A),
      tintaForca: .50,
      chao: TemaChao(
          claro: Color(0xFFB5532D), escuro: Color(0xFFA0482A), neblina: Color(0xFFC0623A), adereco: Adereco.rocha),
      clima: Clima2D.areia,
    ),
    25: AmbienteTurismo(
      tema: 25,
      base: 6,
      nome: 'Órbita da Terra',
      emoji: '🛰️',
      noturno: true,
      tintaCeu: Color(0xFF060A18),
      tintaForca: .30,
      chao: TemaChao(
          claro: Color(0xFF151C33),
          escuro: Color(0xFF0E1326),
          neblina: Color(0xFF7C4DFF),
          linha: Color(0xFF22E6FF),
          adereco: Adereco.cristal),
      clima: Clima2D.estrelas,
    ),
    26: AmbienteTurismo(
      tema: 26,
      base: 3,
      nome: 'Autódromo das Lendas',
      emoji: '🏆',
      noturno: true,
      tintaCeu: Color(0xFF141A28),
      tintaForca: .20,
      clima: Clima2D.fogos,
    ),
  };
}
