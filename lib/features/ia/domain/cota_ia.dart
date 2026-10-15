import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Quantas vezes por dia a pessoa pode pedir algo à IA (Prof. Dash). Dart puro.
///
/// A cota é "macia": vive no cliente (a chave do Gemini também viaja no cliente na web), então
/// quem quiser burlar burla. A trava de verdade é a cota do projeto no Google; aqui o objetivo é
/// custo previsível e uso sem exagero para quem estuda de boa-fé.
class CotaIa extends Equatable {
  /// Usos por dia (um "Por quê?", um turno de cenário ou um feedback valem 1 cada).
  static const limitePadrao = 30;

  /// O dia (`diaDe`) a que [usos] se refere.
  final int dia;
  final int usos;

  const CotaIa({this.dia = 0, this.usos = 0});

  static const vazia = CotaIa();

  /// Usos que valem em [hoje]: dia novo = zero; relógio que volta atrás é ignorado.
  int _usosEm(int hoje) => hoje > dia ? 0 : usos;

  int restantes(int hoje, {int limite = limitePadrao}) => math.max(0, limite - _usosEm(hoje));

  bool temSaldo(int hoje, {int limite = limitePadrao}) => _usosEm(hoje) < limite;

  /// Gasta [n] usos em [hoje] (vira o dia sozinha).
  CotaIa gastar(int hoje, {int n = 1}) {
    final d = hoje < dia ? dia : hoje;
    return CotaIa(dia: d, usos: (d > dia ? 0 : usos) + n);
  }

  /// Junta a cota deste aparelho com a da nuvem: vence o dia mais novo; no mesmo dia, o
  /// maior número de usos (mesclar nunca devolve uso "de graça"). Comutativa e idempotente.
  static CotaIa mesclar(CotaIa a, CotaIa b) {
    if (a.dia != b.dia) return a.dia > b.dia ? a : b;
    return a.usos >= b.usos ? a : b;
  }

  Map<String, Object?> toJson() => {'v': 1, 'dia': dia, 'usos': usos};

  /// Nunca lança: dado estragado vira cota vazia (perdoa; a mescla com a nuvem corrige).
  factory CotaIa.fromJson(Object? bruto) {
    if (bruto is! Map) return vazia;
    int n(String k) {
      final v = bruto[k];
      return v is num && v.isFinite && v >= 0 ? v.toInt() : 0;
    }

    return CotaIa(dia: n('dia'), usos: n('usos'));
  }

  @override
  List<Object?> get props => [dia, usos];
}
