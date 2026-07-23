/// Quais exercícios/projetos viram um programa que **compila** no DartPad.
///
/// Não dá para descobrir isso na hora dentro do app (precisaria do analisador
/// do Dart), então a resposta vem pronta em `assets/roda.json`, gerada offline:
///
/// ```
/// SAIDA=<lab>/lib/gen flutter test test/tools/rodavel_check.dart
/// cd <lab> && flutter analyze          # quem tem erro fica de fora
/// ```
///
/// Boa parte do currículo NÃO tem como rodar: trechos que usam pacotes que o
/// DartPad não carrega (dio, sqflite, shared_preferences, Firebase), o
/// `package:test`, ou que são pedaços soltos demais. Nesses o botão "rodar"
/// simplesmente não aparece — melhor não ter botão do que ter botão que abre
/// uma tela cheia de erro vermelho.
class MapaRodavel {
  /// "trilha:licao" → um caractere por trecho ('1' roda, '0' não).
  final Map<String, String> licoes;

  /// Chaves "proj:t:i" e "master:i" que rodam.
  final Set<String> projetos;

  const MapaRodavel({this.licoes = const {}, this.projetos = const {}});

  /// Vazio = ninguém roda (se o asset falhar, o botão só some).
  static const vazio = MapaRodavel();

  bool trecho(int t, int l, int x) {
    final marcas = licoes['$t:$l'];
    return marcas != null && x >= 0 && x < marcas.length && marcas[x] == '1';
  }

  bool projeto(String chave) => projetos.contains(chave);

  factory MapaRodavel.fromJson(Map<String, dynamic> j) => MapaRodavel(
        licoes: ((j['licoes'] ?? const {}) as Map)
            .map((k, v) => MapEntry(k.toString(), v.toString())),
        projetos: ((j['projetos'] ?? const []) as List).map((e) => e.toString()).toSet(),
      );
}
