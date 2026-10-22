import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'progresso_historia.dart';
import 'turismo.dart';

/// Situação do campeonato Dart Turismo (por dispositivo): até que pista o
/// jogador chegou e a melhor medalha/tempo de cada uma.
/// 📊 Números acumulados de todas as corridas (persistidos em JSON).
class EstatisticasGt {
  final int corridas;
  final int chegadas;
  final int voltasLimpas;
  final int palavras;
  final int fichas;
  final int batidas;
  final int melhorCombo;
  final int fantasmasBatidos;
  final int portaisLimpos;
  final double km;
  final double segundos;
  const EstatisticasGt({
    this.corridas = 0,
    this.chegadas = 0,
    this.voltasLimpas = 0,
    this.palavras = 0,
    this.fichas = 0,
    this.batidas = 0,
    this.melhorCombo = 0,
    this.fantasmasBatidos = 0,
    this.portaisLimpos = 0,
    this.km = 0,
    this.segundos = 0,
  });

  static const vazio = EstatisticasGt();

  /// Soma uma corrida que acabou de terminar.
  EstatisticasGt somar(TurismoEngine e, {bool bateuFantasma = false}) => EstatisticasGt(
        corridas: corridas + 1,
        chegadas: chegadas + (e.terminou ? 1 : 0),
        voltasLimpas: voltasLimpas + (e.terminou && e.colisoes == 0 ? 1 : 0),
        palavras: palavras + e.palavras,
        fichas: fichas + e.fichasPegas,
        batidas: batidas + e.colisoes,
        melhorCombo: e.melhorCombo > melhorCombo ? e.melhorCombo : melhorCombo,
        fantasmasBatidos: fantasmasBatidos + (bateuFantasma ? 1 : 0),
        portaisLimpos: portaisLimpos + e.portaisLimpos,
        km: km + e.posicao / 1000,
        segundos: segundos + e.tempo,
      );

  Map<String, num> toJson() => {
        'corridas': corridas,
        'chegadas': chegadas,
        'voltasLimpas': voltasLimpas,
        'palavras': palavras,
        'fichas': fichas,
        'batidas': batidas,
        'melhorCombo': melhorCombo,
        'fantasmasBatidos': fantasmasBatidos,
        'portaisLimpos': portaisLimpos,
        'km': km,
        'segundos': segundos,
      };

  factory EstatisticasGt.fromJson(Map<String, dynamic> j) {
    int i(String k) => (j[k] as num?)?.toInt() ?? 0;
    double d(String k) => (j[k] as num?)?.toDouble() ?? 0;
    return EstatisticasGt(
      corridas: i('corridas'),
      chegadas: i('chegadas'),
      voltasLimpas: i('voltasLimpas'),
      palavras: i('palavras'),
      fichas: i('fichas'),
      batidas: i('batidas'),
      melhorCombo: i('melhorCombo'),
      fantasmasBatidos: i('fantasmasBatidos'),
      portaisLimpos: i('portaisLimpos'),
      km: d('km'),
      segundos: d('segundos'),
    );
  }
}

/// 🏆 Um troféu: condição sobre as estatísticas + o campeonato.
class TrofeuGt {
  final String id;
  final String emoji;
  final String nome;
  final String como;
  final bool Function(EstatisticasGt s, EstadoCampeonato c) ganhou;
  const TrofeuGt(this.id, this.emoji, this.nome, this.como, this.ganhou);
}

final trofeusGt = <TrofeuGt>[
  TrofeuGt('bandeirada', '🏁', 'Primeira bandeirada', 'complete uma pista', (s, c) => s.chegadas >= 1),
  TrofeuGt('ouro', '🥇', 'Ouro na veia', 'ganhe um ouro', (s, c) => c.ouros >= 1),
  TrofeuGt('limpa', '🧼', 'Volta limpa', 'complete uma pista sem batida', (s, c) => s.voltasLimpas >= 1),
  TrofeuGt('combo', '🔥', 'Combo x3', 'chegue a um combo de 10', (s, c) => s.melhorCombo >= 10),
  TrofeuGt('fantasma', '👻', 'Caça-fantasma', 'bata o seu próprio fantasma', (s, c) => s.fantasmasBatidos >= 1),
  TrofeuGt('fichas', '🪙', 'Colecionador', 'pegue 100 fichas de código', (s, c) => s.fichas >= 100),
  TrofeuGt('palavras', '⌨️', 'Mil palavras', 'acerte 1000 palavras', (s, c) => s.palavras >= 1000),
  TrofeuGt('maratona', '🛣️', 'Maratonista', 'percorra 50 km', (s, c) => s.km >= 50),
  TrofeuGt('garagem', '🚗', 'Garagem cheia', 'compre todos os carros', (s, c) => carrosGt.every((k) => c.temCarro(k.id))),
  TrofeuGt('metade', '🥈', 'Meio campeonato', 'medalha em 5 pistas', (s, c) => c.totalMedalhas >= 5),
  // só as 10 clássicas contam: no inglês (30 pistas) o 🏆/👑 abrem no mesmo ponto de sempre
  TrofeuGt('campeao', '🏆', 'Campeão Dart Turismo', 'medalha nas 10 pistas', (s, c) => c.medalhasClassicas >= pistasClassicas),
  TrofeuGt('dourado', '👑', 'Coleção dourada', 'ouro nas 10 pistas', (s, c) => c.ourosClassicos >= pistasClassicas),
];

/// 🌍 Troféus que só existem no English Turismo (30 pistas + história).
final trofeusExtrasIngles = <TrofeuGt>[
  TrofeuGt('volta-mundo', '🌍', 'Volta ao mundo', 'medalha nas pistas 11 a 20',
      (s, c) => c.medalhasEntre(11, 20) >= 10),
  TrofeuGt('lenda', '🏆', 'Lenda do English Turismo', 'medalha nas 30 pistas',
      (s, c) => c.medalhasEntre(1, pistasGtIngles.length) >= pistasGtIngles.length),
  TrofeuGt('historia', '📖', 'História completa', 'assista ao final da história até o fim',
      (s, c) => c.historiaCompleta),
];

/// Os troféus do curso atual: os 12 de sempre (+ os 3 do inglês).
List<TrofeuGt> trofeusDoTurismo({required bool ingles}) => ingles ? [...trofeusGt, ...trofeusExtrasIngles] : trofeusGt;

class EstadoCampeonato {
  /// Maior pista liberada (1 = só a primeira).
  final int pistaMax;
  final Map<int, int> medalhas;
  final Map<int, double> tempos;

  /// Moedas acumuladas (fichas + bônus de medalha) e carros já comprados.
  final int moedas;
  final Set<String> comprados;

  /// Quantas pistas tem o campeonato carregado (10 no Dart/C#, 30 no inglês).
  final int totalPistas;

  /// 📖 O final da história (chegada da pista 30) foi assistido até o fim (`c30`).
  final bool historiaCompleta;
  const EstadoCampeonato({
    this.pistaMax = 1,
    this.medalhas = const {},
    this.tempos = const {},
    this.moedas = 0,
    this.comprados = const {},
    this.totalPistas = pistasClassicas,
    this.historiaCompleta = false,
  });

  static const vazio = EstadoCampeonato();

  bool temCarro(String id) => comprados.contains(id) || carrosGt.first.id == id;

  int medalhaDe(int pista) => medalhas[pista] ?? 0;
  double? tempoDe(int pista) => tempos[pista];
  bool liberada(int pista) => pista <= pistaMax;
  int get totalMedalhas => medalhas.values.where((m) => m > 0).length;
  int get ouros => medalhas.values.where((m) => m == 3).length;

  /// Pistas com medalha entre [de] e [ate] (inclusive).
  int medalhasEntre(int de, int ate) => medalhas.entries.where((e) => e.key >= de && e.key <= ate && e.value > 0).length;

  /// Medalhas e ouros só nas 10 pistas clássicas (os troféus de sempre contam só estas).
  int get medalhasClassicas => medalhasEntre(1, pistasClassicas);
  int get ourosClassicos => medalhas.entries.where((e) => e.key >= 1 && e.key <= pistasClassicas && e.value == 3).length;
}

/// Carros da garagem (modelos glTF em `web/assets3d/carros/<id>/`); o
/// primeiro é de graça, os outros se conquistam com moedas das pistas.
class CarroGt {
  final String id;
  final String nome;
  final String apelido;
  final int preco;
  const CarroGt(this.id, this.nome, this.apelido, this.preco);
}

const carrosGt = [
  CarroGt('porsche_930', 'Porsche 911 Turbo (930)', 'o clássico', 0),
  CarroGt('toyota_ae86', 'Toyota AE86 Trueno', 'o drift', 80),
  CarroGt('mazda_miata', 'Mazda MX-5 Miata', 'o leve', 140),
  CarroGt('honda_nsx', 'Honda NSX 1990', 'o preciso', 260),
  CarroGt('skyline_r34', 'Nissan Skyline R34 GT-R', 'o lendário', 420),
];

/// Bônus de moedas por medalha (índice = medalha).
const moedasPorMedalha = [0, 15, 30, 50];

abstract final class ProgressoTurismo {
  static const _chaveMax = 'turismo_pista_max';
  static const _chaveCarro = 'turismo_carro';
  static const _chaveMoedas = 'turismo_moedas';
  static const _chaveComprados = 'turismo_comprados';
  static const _chaveModo = 'turismo_modo';
  static const _chaveCamera = 'turismo_camera';
  static const _chaveMusica = 'turismo_musica';
  static const _chaveQualidade = 'turismo_qualidade';
  static const _chaveStats = 'turismo_stats';
  static String _chaveFantasma(int pista) => 'turismo_fantasma_$pista';

  /// 👻 A melhor volta gravada da pista (null = ainda não há fantasma).
  static Future<VoltaFantasma?> fantasma(int pista) async {
    try {
      final p = await SharedPreferences.getInstance();
      return VoltaFantasma.desserializar(p.getString(_chaveFantasma(pista)));
    } catch (_) {
      return null;
    }
  }

  static Future<void> salvarFantasma(int pista, VoltaFantasma volta) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chaveFantasma(pista), volta.serializar());
    } catch (_) {}
  }

  /// 📊 Estatísticas acumuladas.
  static Future<EstatisticasGt> estatisticas() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_chaveStats);
      if (s == null) return EstatisticasGt.vazio;
      return EstatisticasGt.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return EstatisticasGt.vazio;
    }
  }

  static Future<void> salvarEstatisticas(EstatisticasGt s) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chaveStats, jsonEncode(s.toJson()));
    } catch (_) {}
  }
  static const _chaveTremor = 'turismo_tremor';

  /// Qualidade da vista 3D: auto · alta · leve.
  static Future<String> qualidade() async {
    try {
      final p = await SharedPreferences.getInstance();
      final q = p.getString(_chaveQualidade);
      return q != null && qualidadesGt.contains(q) ? q : qualidadesGt.first;
    } catch (_) {
      return qualidadesGt.first;
    }
  }

  static Future<void> escolherQualidade(String q) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chaveQualidade, q);
    } catch (_) {}
  }

  /// Tremor de câmera na batida (acessibilidade: dá pra desligar).
  static Future<bool> tremorLigado() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_chaveTremor) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> ligarTremor(bool ligado) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_chaveTremor, ligado);
    } catch (_) {}
  }

  /// O tutorial da 1ª corrida já foi visto neste modo?
  static Future<bool> tutorialVisto({required bool setas}) async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool('turismo_tutorial_${setas ? 'setas' : 'digitacao'}') ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> marcarTutorial({required bool setas}) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('turismo_tutorial_${setas ? 'setas' : 'digitacao'}', true);
    } catch (_) {}
  }

  /// 🎸 Música da fase ligada? (padrão: sim)
  static Future<bool> musicaLigada() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_chaveMusica) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> ligarMusica(bool ligada) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_chaveMusica, ligada);
    } catch (_) {}
  }

  /// Câmera da vista 3D escolhida (padrão: perseguição).
  static Future<String> camera() async {
    try {
      final p = await SharedPreferences.getInstance();
      final c = p.getString(_chaveCamera);
      return c != null && camerasGt.contains(c) ? c : camerasGt.first;
    } catch (_) {
      return camerasGt.first;
    }
  }

  static Future<void> escolherCamera(String id) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chaveCamera, id);
    } catch (_) {}
  }

  /// Modo de controle escolhido (padrão: digitação).
  static Future<bool> modoSetas() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_chaveModo) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> escolherModo({required bool setas}) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_chaveModo, setas);
    } catch (_) {}
  }

  /// Soma moedas conquistadas numa corrida.
  static Future<int> ganharMoedas(int n) async {
    try {
      final p = await SharedPreferences.getInstance();
      final total = (p.getInt(_chaveMoedas) ?? 0) + n;
      await p.setInt(_chaveMoedas, total);
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Compra um carro se houver moedas; devolve se deu certo.
  static Future<bool> comprarCarro(String id) async {
    final carro = carrosGt.firstWhere((c) => c.id == id, orElse: () => carrosGt.first);
    try {
      final p = await SharedPreferences.getInstance();
      final comprados = (p.getStringList(_chaveComprados) ?? const []).toSet();
      if (comprados.contains(id) || carro.preco == 0) return true;
      final moedas = p.getInt(_chaveMoedas) ?? 0;
      if (moedas < carro.preco) return false;
      await p.setInt(_chaveMoedas, moedas - carro.preco);
      await p.setStringList(_chaveComprados, [...comprados, id]);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Carro escolhido na garagem (padrão: o Porsche).
  static Future<String> carroEscolhido() async {
    try {
      final p = await SharedPreferences.getInstance();
      final id = p.getString(_chaveCarro);
      if (id != null && carrosGt.any((c) => c.id == id)) return id;
    } catch (_) {}
    return carrosGt.first.id;
  }

  static Future<void> escolherCarro(String id) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chaveCarro, id);
    } catch (_) {}
  }

  static String _chaveMedalha(int n) => 'turismo_medalha_$n';
  static String _chaveTempo(int n) => 'turismo_tempo_$n';

  /// Lê o campeonato de [totalPistas] pistas. Com mais de 10 (inglês), o desbloqueio das extras é
  /// CALCULADO: quem chegou ao fim da pista n (tempo ou medalha gravados, n de 10 em diante) tem a n+1
  /// liberada, mesmo com o `turismo_pista_max` preso em 10 de antes das 30 pistas. Nada é regravado.
  static Future<EstadoCampeonato> carregar({int totalPistas = pistasClassicas}) async {
    try {
      final p = await SharedPreferences.getInstance();
      final medalhas = <int, int>{};
      final tempos = <int, double>{};
      for (var n = 1; n <= totalPistas; n++) {
        final m = p.getInt(_chaveMedalha(n));
        if (m != null && m > 0) medalhas[n] = m;
        final t = p.getDouble(_chaveTempo(n));
        if (t != null) tempos[n] = t;
      }
      var max = p.getInt(_chaveMax) ?? 1;
      if (totalPistas > pistasClassicas) {
        for (var n = pistasClassicas; n < totalPistas; n++) {
          if ((tempos[n] != null || (medalhas[n] ?? 0) > 0) && max < n + 1) max = n + 1;
        }
      }
      return EstadoCampeonato(
        pistaMax: max.clamp(1, totalPistas),
        medalhas: medalhas,
        tempos: tempos,
        moedas: p.getInt(_chaveMoedas) ?? 0,
        comprados: (p.getStringList(_chaveComprados) ?? const []).toSet(),
        totalPistas: totalPistas,
        historiaCompleta: (p.getStringList(ProgressoHistoria.chaveVistos) ?? const []).contains(ProgressoHistoria.idAssistido(pistasGtIngles.length)),
      );
    } catch (_) {
      return EstadoCampeonato(totalPistas: totalPistas);
    }
  }

  /// Corrida concluída: guarda a medalha/tempo se forem melhores e libera a
  /// próxima pista (com medalha; [chegarLibera] = só chegar já libera — o inglês, sem tempo limite).
  static Future<void> registrar({
    required int pista,
    required int medalha,
    required double tempo,
    int totalPistas = 10,
    bool chegarLibera = false,
  }) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (medalha > (p.getInt(_chaveMedalha(pista)) ?? 0)) {
        await p.setInt(_chaveMedalha(pista), medalha);
      }
      final antes = p.getDouble(_chaveTempo(pista));
      if (antes == null || tempo < antes) await p.setDouble(_chaveTempo(pista), tempo);
      if (medalha > 0 || chegarLibera) {
        final max = p.getInt(_chaveMax) ?? 1;
        final novo = (pista + 1).clamp(1, totalPistas);
        if (novo > max) await p.setInt(_chaveMax, novo);
      }
    } catch (_) {}
  }
}

/// Presets de qualidade da vista 3D (auto decide por tela de toque pequena).
const qualidadesGt = ['auto', 'alta', 'leve'];
const nomesQualidade = {'auto': 'Auto', 'alta': 'Alta (2k)', 'leve': 'Leve'};

/// Câmeras da vista 3D, na ordem em que o botão 🎥 (ou a tecla C) gira.
const camerasGt = ['perseguicao', 'capo', 'cinema', 'alta'];
const nomesCamera = {
  'perseguicao': 'Perseguição',
  'capo': 'Capô',
  'cinema': 'Cinema (TV)',
  'alta': 'Helicóptero',
};
