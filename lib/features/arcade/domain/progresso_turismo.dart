import 'package:shared_preferences/shared_preferences.dart';

/// Situação do campeonato Dart Turismo (por dispositivo): até que pista o
/// jogador chegou e a melhor medalha/tempo de cada uma.
class EstadoCampeonato {
  /// Maior pista liberada (1 = só a primeira).
  final int pistaMax;
  final Map<int, int> medalhas;
  final Map<int, double> tempos;

  /// Moedas acumuladas (fichas + bônus de medalha) e carros já comprados.
  final int moedas;
  final Set<String> comprados;
  const EstadoCampeonato({
    this.pistaMax = 1,
    this.medalhas = const {},
    this.tempos = const {},
    this.moedas = 0,
    this.comprados = const {},
  });

  static const vazio = EstadoCampeonato();

  bool temCarro(String id) => comprados.contains(id) || carrosGt.first.id == id;

  int medalhaDe(int pista) => medalhas[pista] ?? 0;
  double? tempoDe(int pista) => tempos[pista];
  bool liberada(int pista) => pista <= pistaMax;
  int get totalMedalhas => medalhas.values.where((m) => m > 0).length;
  int get ouros => medalhas.values.where((m) => m == 3).length;
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

  static Future<EstadoCampeonato> carregar({int totalPistas = 10}) async {
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
      return EstadoCampeonato(
        pistaMax: (p.getInt(_chaveMax) ?? 1).clamp(1, totalPistas),
        medalhas: medalhas,
        tempos: tempos,
        moedas: p.getInt(_chaveMoedas) ?? 0,
        comprados: (p.getStringList(_chaveComprados) ?? const []).toSet(),
      );
    } catch (_) {
      return EstadoCampeonato.vazio;
    }
  }

  /// Corrida concluída: guarda a medalha/tempo se forem melhores e libera a
  /// próxima pista.
  static Future<void> registrar({
    required int pista,
    required int medalha,
    required double tempo,
    int totalPistas = 10,
  }) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (medalha > (p.getInt(_chaveMedalha(pista)) ?? 0)) {
        await p.setInt(_chaveMedalha(pista), medalha);
      }
      final antes = p.getDouble(_chaveTempo(pista));
      if (antes == null || tempo < antes) await p.setDouble(_chaveTempo(pista), tempo);
      if (medalha > 0) {
        final max = p.getInt(_chaveMax) ?? 1;
        final novo = (pista + 1).clamp(1, totalPistas);
        if (novo > max) await p.setInt(_chaveMax, novo);
      }
    } catch (_) {}
  }
}

/// Câmeras da vista 3D, na ordem em que o botão 🎥 (ou a tecla C) gira.
const camerasGt = ['perseguicao', 'capo', 'cinema', 'alta'];
const nomesCamera = {
  'perseguicao': 'Perseguição',
  'capo': 'Capô',
  'cinema': 'Cinema (TV)',
  'alta': 'Helicóptero',
};
