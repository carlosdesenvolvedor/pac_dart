import 'package:shared_preferences/shared_preferences.dart';

/// Personagens jogáveis do Arcade.
enum Personagem {
  pac('Pac', 'O devorador de código original'),
  dash('Dash', 'O passarinho azul do Flutter');

  final String rotulo;
  final String descricao;
  const Personagem(this.rotulo, this.descricao);
}

/// Escolha do personagem, persistida por dispositivo (mesmo padrão do tema:
/// valor estático mutável + shared_preferences — os jogos leem `atual`).
abstract final class PersonagemStore {
  static const _chave = 'personagem';
  static Personagem atual = Personagem.pac;

  static Future<Personagem> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      final nome = p.getString(_chave);
      atual =
          Personagem.values.firstWhere((e) => e.name == nome, orElse: () => Personagem.pac);
    } catch (_) {
      // sem storage (teste/plataforma exótica): fica no padrão
    }
    return atual;
  }

  static Future<void> trocar(Personagem novo) async {
    atual = novo;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chave, novo.name);
    } catch (_) {}
  }
}
