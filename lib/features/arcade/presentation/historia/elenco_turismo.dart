import 'package:flutter/material.dart';

import '../../../ingles/data/voz_ingles.dart';
import '../../../ingles/presentation/widgets/elenco_ingles.dart';
import '../../domain/historia_turismo.dart';

/// 🎭 O elenco da história do English Turismo: os 8 do curso + o aluno ([ElencoIngles]) e 2 extras só do
/// jogo — [max] (o rival de preto, Team Thunder) e [kim] (a locutora do torneio). O `narrador` não tem corpo.
///
/// Aparências, nomes, cores dos chips e vozes seguem o cânone do elenco da história (plano, tabela 5.6).
abstract final class ElencoTurismo {
  static const max = Aparencia(
    pele: Color(0xFFFFDCC4),
    cabelo: Color(0xFFEDE6D2),
    roupa: Color(0xFF26262E),
    estilo: Cabelo.curto,
    detalhe: Color(0xFFFF8A1F),
  );
  static const kim = Aparencia(
    pele: Color(0xFF8D5A3B),
    cabelo: Color(0xFF7A3E9E),
    roupa: Color(0xFFE84393),
    estilo: Cabelo.bob,
    fone: true,
    brincos: true,
    cilios: true,
  );

  static const _corNarrador = Color(0xFF3A2A33);

  /// max/kim → extras; narrador → null; senão [ElencoIngles.de].
  static Aparencia? de(String quem) => switch (quem) {
        'max' => max,
        'kim' => kim,
        narrador => null,
        _ => ElencoIngles.de(quem),
      };

  /// O rótulo do chip do balão ('Dra. Lee', 'Você', 'Max', 'Kim'…).
  static String nomeDe(String quem) => switch (quem) {
        'voce' => 'Você',
        'dra-lee' => 'Dra. Lee',
        narrador => 'Narrador',
        '' => '',
        _ => quem[0].toUpperCase() + quem.substring(1),
      };

  /// A cor do chip do balão = a roupa do personagem (narrador: 0xFF3A2A33).
  static Color corDe(String quem) => de(quem)?.roupa ?? _corNarrador;

  /// A voz de cada um (tom + variante da voz en-US do sistema): ninguém soa igual a ninguém.
  static const _vozes = {
    'voce': PerfilVoz(),
    'mike': PerfilVoz(tom: .88),
    'sarah': PerfilVoz(tom: 1.10, variante: 1),
    'ana': PerfilVoz(tom: 1.18),
    'ben': PerfilVoz(tom: .80, variante: 1),
    'emma': PerfilVoz(tom: 1.05, variante: 1),
    'lucas': PerfilVoz(tom: 1.22),
    'julia': PerfilVoz(tom: 1.30, variante: 1),
    'dra-lee': PerfilVoz(tom: .98, variante: 1),
    'max': PerfilVoz(tom: .76),
    'kim': PerfilVoz(tom: 1.20, variante: 1),
    narrador: PerfilVoz(tom: .95),
  };

  /// A voz do personagem (tom + variante); quem não está no elenco usa [PerfilVoz.padrao].
  static PerfilVoz perfilDeVoz(String quem) => _vozes[quem] ?? PerfilVoz.padrao;

  /// O carro que o personagem dirige: o Max dirige o rival; os outros, o carro do Team Star.
  static PropHistoria carroDe(String quem) => quem == 'max' ? PropHistoria.carroRival : PropHistoria.carro;
}
