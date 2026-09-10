import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/gemini/chave_gemini.dart';
import '../domain/turismo.dart';

/// 🎧 A engenheira de pista da equipe PAC·DART: depois da corrida, o Gemini
/// (a mesma chave do Prof. Dash, guardada no Firestore) lê a telemetria e
/// manda pelo rádio um debrief curto — resultado, UMA dica prática e uma
/// curiosidade de Dart/Flutter sobre uma ficha pega na pista. Sem chave, sem
/// rede ou fora do ar, a engenheira "de bolso" ([TelemetriaGt.debriefLocal])
/// responde na hora: a tela de fim nunca espera a IA.
class EngenheiroGt {
  /// O alias que acompanha o flash mais novo (o mesmo do tutor).
  static const _modelo = 'gemini-flash-latest';

  static const _persona = '''
Você é a engenheira de pista da equipe PAC·DART no Dart Turismo, um jogo de
corrida que ensina Dart e Flutter. Você fala pelo rádio com o piloto logo
depois da corrida, em português do Brasil.

Regras:
- No máximo 3 frases curtas (até ~60 palavras no total). Sem markdown, sem
  listas, no máximo um emoji.
- Tom de equipe de corrida: direto, animado, sem sermão.
- 1ª frase: comente o resultado com UM dado concreto da telemetria (medalha,
  tempo em relação ao ouro, batidas, combo ou precisão).
- 2ª frase: UMA dica prática pra próxima corrida, coerente com o modo de
  controle (digitação: ritmo/precisão/combustível; setas: faixa livre/freio).
- 3ª frase (só se houver fichas de código pegas): uma curiosidade CORRETA de
  uma frase sobre UMA das fichas em Dart/Flutter. Se não tiver certeza, pule.
''';

  final http.Client _http;
  EngenheiroGt({http.Client? client}) : _http = client ?? http.Client();

  Future<String> debrief(TelemetriaGt t) async {
    final chave = await ChaveGemini.obter();
    if (chave == null) return t.debriefLocal;
    try {
      final resp = await _http
          .post(
            Uri.parse('https://generativelanguage.googleapis.com/v1beta/'
                'models/$_modelo:generateContent?key=$chave'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': _persona}
                ]
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': 'TELEMETRIA DA CORRIDA:\n${t.resumo}'}
                  ]
                }
              ],
              'generationConfig': {'temperature': 0.8, 'maxOutputTokens': 400},
            }),
          )
          .timeout(const Duration(seconds: 14));
      if (resp.statusCode != 200) return t.debriefLocal;
      final texto = extrairTexto(resp.body);
      return texto == null || texto.isEmpty ? t.debriefLocal : texto;
    } catch (_) {
      return t.debriefLocal;
    }
  }

  /// O texto da 1ª candidata da resposta do generateContent (null se vier
  /// vazio ou num formato inesperado).
  static String? extrairTexto(String corpo) {
    try {
      final json = jsonDecode(corpo) as Map<String, dynamic>;
      final candidatos = json['candidates'] as List?;
      if (candidatos == null || candidatos.isEmpty) return null;
      final conteudo = (candidatos.first as Map)['content'] as Map?;
      final partes = conteudo?['parts'] as List?;
      if (partes == null) return null;
      final texto = partes.map((p) => ((p as Map)['text'] ?? '').toString()).join().trim();
      return texto.isEmpty ? null : texto;
    } catch (_) {
      return null;
    }
  }
}

/// O que a engenheira enxerga de uma corrida.
class TelemetriaGt {
  final String pista;
  final String dificuldade;
  final String carro;
  final bool porSetas;
  final bool chegou;
  final int medalha;
  final double tempo;
  final double tempoOuro;
  final double tempoLimite;
  final double distancia;
  final double percorrido;
  final int precisao;
  final int colisoes;
  final int melhorCombo;
  final int palavras;
  final int portaisLimpos;
  final int totalPortais;
  final List<String> fichas;

  const TelemetriaGt({
    required this.pista,
    required this.dificuldade,
    required this.carro,
    required this.porSetas,
    required this.chegou,
    required this.medalha,
    required this.tempo,
    required this.tempoOuro,
    required this.tempoLimite,
    required this.distancia,
    required this.percorrido,
    required this.precisao,
    required this.colisoes,
    required this.melhorCombo,
    required this.palavras,
    required this.portaisLimpos,
    required this.totalPortais,
    required this.fichas,
  });

  factory TelemetriaGt.de(TurismoEngine e, {required String carro}) {
    final p = e.pista;
    return TelemetriaGt(
      pista: p.nome,
      dificuldade: p.dificuldade,
      carro: carro,
      porSetas: e.porSetas,
      chegou: e.terminou,
      medalha: e.medalha,
      tempo: e.tempoFinal ?? e.tempo,
      tempoOuro: p.tempoOuro,
      tempoLimite: p.tempoLimite,
      distancia: p.distancia,
      percorrido: e.posicao,
      precisao: e.precisao,
      colisoes: e.colisoes,
      melhorCombo: e.melhorCombo,
      palavras: e.palavras,
      portaisLimpos: e.portaisLimpos,
      totalPortais: e.portais.length,
      fichas: [
        for (final portal in e.portais)
          for (final f in portal.fichas)
            if (f.pega) f.texto,
      ],
    );
  }

  static const _nomesMedalha = ['sem medalha', 'bronze', 'prata', 'ouro'];

  String get resumo {
    final linhas = <String>[
      'pista: $pista ($dificuldade, ${(distancia / 1000).toStringAsFixed(1)} km) · carro: $carro',
      'modo de controle: ${porSetas ? 'setas (← → faixa, ↑ acelera, ↓ freia)' : 'digitação (as palavras dos portais dirigem)'}',
      chegou
          ? 'resultado: chegou — ${_nomesMedalha[medalha]} · tempo ${tempo.toStringAsFixed(1)} s · ouro até ${tempoOuro.toStringAsFixed(1)} s · limite ${tempoLimite.toStringAsFixed(0)} s'
          : 'resultado: tempo esgotado aos ${percorrido.round()} m de ${distancia.round()} m',
      'batidas: $colisoes · melhor combo: $melhorCombo',
      porSetas
          ? 'portais passados pela faixa livre: $portaisLimpos de $totalPortais'
          : 'palavras acertadas: $palavras · precisão das teclas: $precisao%',
      fichas.isEmpty
          ? 'fichas de código pegas: nenhuma'
          : 'fichas de código pegas: ${fichas.toSet().take(8).join(', ')}',
    ];
    return linhas.join('\n');
  }

  /// A engenheira de bolso: regras simples, sempre disponível.
  String get debriefLocal {
    final b = StringBuffer();
    if (!chegou) {
      b.write('Ficamos a ${(distancia - percorrido).round()} m da bandeirada. ');
      b.write(porSetas
          ? 'Segure o ↑ o tempo todo e só freie se a faixa livre estiver bloqueada por um carro.'
          : 'Não deixe a palavra de combustível esperando: cada tecla certa é gás, e parar de digitar é ir parando.');
    } else if (medalha == 3) {
      b.write('Ouro com ${tempo.toStringAsFixed(1)} s, ${(tempoOuro - tempo).toStringAsFixed(1)} s abaixo da marca! ');
      b.write(colisoes == 0 ? 'Volta limpa, sem batidas — é assim que se fecha um campeonato.' : 'Tira essas $colisoes batidas e o tempo cai ainda mais.');
    } else {
      final falta = (tempo - tempoOuro).toStringAsFixed(1);
      b.write('${_nomesMedalha[medalha][0].toUpperCase()}${_nomesMedalha[medalha].substring(1)} em ${tempo.toStringAsFixed(1)} s — faltaram $falta s pro ouro. ');
      if (colisoes > 0) {
        b.write(porSetas
            ? 'Foram $colisoes batidas: troque de faixa assim que a placa aparecer, não em cima do portal.'
            : 'Foram $colisoes batidas: leia a placa do portal antes de digitar e não troque de palavra pela metade.');
      } else if (!porSetas && precisao < 90) {
        b.write('Precisão de $precisao%: cada erro custa o combo — melhor digitar um pouco mais devagar e certo.');
      } else {
        b.write(porSetas
            ? 'Sem batidas: agora é não tirar o pé do ↑ nem nas curvas.'
            : 'Sem batidas: agora é emendar as palavras de combustível pra segurar o combo x3.');
      }
    }
    if (fichas.isNotEmpty) {
      final dica = _curiosidade(fichas.first);
      if (dica != null) b.write(' $dica');
    }
    return b.toString();
  }

  static String? _curiosidade(String ficha) {
    const dicas = {
      '=>': 'Ficha "=>": em Dart a seta é açúcar pra uma função de uma expressão só — `int dobro(int x) => x * 2;`.',
      'async': 'Ficha "async": marcar uma função com async faz ela devolver um Future e libera o await lá dentro.',
      'await': 'Ficha "await": await só funciona dentro de uma função async e pausa aquela função, não o app inteiro.',
      'final': 'Ficha "final": uma variável final recebe valor uma vez só — o objeto por dentro ainda pode mudar.',
      'const': 'Ficha "const": const é constante em tempo de compilação; widgets const nem são reconstruídos.',
      'late': 'Ficha "late": late promete que a variável vai ser iniciada antes do primeiro uso — ou lança erro na hora.',
      '{ }': 'Ficha "{ }": chaves abrem blocos e também literais de Map e Set — `{}` vazio é um Map.',
      '{}': 'Ficha "{}": chaves abrem blocos e também literais de Map e Set — `{}` vazio é um Map.',
      '??': 'Ficha "??": o operador ?? devolve o lado direito só quando o esquerdo é null.',
      '?.': 'Ficha "?.": o acesso ?. pula a chamada e devolve null quando o objeto é null.',
      '...': 'Ficha "...": o spread ... despeja uma lista dentro de outra literal — `[1, ...outra]`.',
      'setState': 'Ficha "setState": setState avisa o Flutter que o estado mudou e agenda a reconstrução do widget.',
      'Widget': 'Ficha "Widget": em Flutter tudo na tela é Widget — imutável, barato de recriar a cada frame.',
      'build': 'Ficha "build": build descreve a UI a partir do estado atual e pode rodar muitas vezes por segundo.',
      'Future': 'Ficha "Future": um Future é um valor que ainda vai chegar — then ou await pra usá-lo.',
      'Stream': 'Ficha "Stream": um Stream entrega vários valores ao longo do tempo; await for consome um a um.',
      'void': 'Ficha "void": void diz que a função não devolve nada de útil — main() é void.',
      'class': 'Ficha "class": toda classe em Dart herda de Object; sem extends, é Object direto.',
      'List': 'Ficha "List": List é a lista ordenada de Dart; growable por padrão e tipada — `List<int>`.',
      'Map': 'Ficha "Map": Map guarda pares chave→valor; `{}` literal vazio já é um Map.',
    };
    return dicas[ficha] ?? dicas[ficha.trim()];
  }
}
