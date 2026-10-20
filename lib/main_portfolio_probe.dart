// Entrypoint de PROVA VISUAL do app inteiro SEM Firebase: usuário de mentira
// já logado, progresso local, ranking em memória e um Prof. Dash que responde
// na hora. Serve pra fotografar as telas (portfólio) sem credenciais.
//   flutter build web -t lib/main_portfolio_probe.dart --output=build/probe_app
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/app_user.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/curso/data/progresso_repository.dart';
import 'features/habito/data/agendador_lembrete.dart';
import 'features/habito/data/habito_repository.dart';
import 'features/habito/domain/lembrete.dart';
import 'features/ia/data/cota_repository.dart';
import 'features/ingles/data/audio_usuario_repository.dart';
import 'features/ingles/data/palavras_repository.dart';
import 'features/ingles/data/reconhecedor_fala.dart';
import 'features/ingles/data/revisao_repository.dart';
import 'features/ingles/data/tradutor.dart';
import 'features/ingles/presentation/sessao_cartoes_page.dart';
import 'features/ingles/presentation/widgets/frase_view.dart';
import 'features/ranking/data/ranking_repository.dart';
import 'features/ranking/domain/jogador_ranking.dart';
import 'features/tutor/data/tutor_service.dart';
import 'main.dart';

void main() {
  // shadowing: no Chrome automatizado não há microfone nem reconhecimento; quem "fala" é a prova (Playwright)
  // pondo o texto em `window.__dito` antes de tocar em 🎤 Falar
  SessaoCartoesPage.fabricaReconhecedor = () => const _ReconhecedorFake();
  // lição de inglês (modo 🎤 Falar): o mesmo reconhecedor de mentira
  FraseView.fabricaReconhecedor = () => const _ReconhecedorFake();
  runApp(_app());
}

PacDartApp _app() => PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoPorLinguagem: (_, l) => LocalProgressoRepository(prefixo: l.prefixoProgresso),
      revisaoBuilder: (_) => LocalRevisaoRepository(),
      habitoBuilder: (_) => LocalHabitoRepository(),
      agendadorBuilder: () => _AgendadorFake(),
      iaCotaBuilder: (_) => LocalCotaRepository(),
      audioBuilder: (_) => MemoriaAudioUsuarioRepository(),
      palavrasBuilder: (u) => LocalPalavrasRepository(u.uid),
      rankingBuilder: () => _RankingFake(),
      tutorBuilder: () => _TutorFake(),
      tradutorBuilder: () => _TradutorFake(),
    );

/// Agendador de mentira para a prova no Chrome: "disponível" (a folha mostra o interruptor), loga no console o que seria
/// agendado e nega a permissão se `window.__negarLembrete` estiver ligado. Nada vai ao sistema de verdade.
class _AgendadorFake implements AgendadorDeLembrete {
  @override
  bool get disponivel => true;

  @override
  Future<bool> pedirPermissao() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final v = globalContext['__negarLembrete'];
    final negar = v.isA<JSBoolean>() && (v as JSBoolean).toDart;
    debugPrint('LEMBRETE permissao ${negar ? 'NEGADA' : 'concedida'}');
    return !negar;
  }

  @override
  Future<void> substituir(List<LembreteAgendado> lembretes) async {
    debugPrint('LEMBRETE agendados ${lembretes.length}: ${[for (final l in lembretes) l.quando.toIso8601String().substring(0, 16)].join(' | ')}');
  }

  @override
  Future<void> cancelarTodos() async => debugPrint('LEMBRETE cancelados');
}

/// Reconhecedor de mentira para a prova no Chrome: devolve o que estiver em `window.__dito` (vazio = "não ouvi").
class _ReconhecedorFake extends ReconhecedorFala {
  const _ReconhecedorFake();

  @override
  bool get suportado => true;

  @override
  SessaoFala ouvir({
    String idioma = 'en-US',
    required void Function(String texto) aoParcial,
    required void Function(List<String> hipoteses) aoFinal,
    required void Function(ErroFala erro) aoErro,
    required void Function() aoFim,
  }) {
    final s = _EscutaFake();
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (s.cancelada) return;
      final v = globalContext['__dito'];
      final dito = v.isA<JSString>() ? (v as JSString).toDart : '';
      if (dito.isEmpty) {
        aoErro(ErroFala.naoOuviu);
      } else {
        aoParcial(dito.split(' ').first);
        aoFinal([dito]);
      }
      aoFim();
    });
    return s;
  }
}

class _EscutaFake implements SessaoFala {
  bool cancelada = false;
  @override
  void parar() {}
  @override
  void cancelar() => cancelada = true;
}

class _AuthFake implements AuthRepository {
  static const _user = AppUser(uid: 'carlos', email: 'carlos@cgmixart.com.br');
  @override
  Stream<AppUser?> get mudancas => Stream.value(_user);
  @override
  AppUser? get atual => _user;
  @override
  Future<void> entrar(String email, String senha) async {}
  @override
  Future<void> cadastrar(String email, String senha) async {}
  @override
  Future<void> redefinirSenha(String email) async {}
  @override
  Future<void> sair() async {}
}

class _RankingFake implements RankingRepository {
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async {}
  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async => true;
  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

/// Traduz sem rede: uma tabelinha para as palavras da leitura e "tradução de …" para o resto.
class _TradutorFake implements Tradutor {
  static const _palavras = {'breakfast': 'café da manhã', 'bus': 'ônibus', 'sister': 'irmã', 'cheese': 'queijo', 'walk': 'caminhar'};
  // frases do vídeo de apresentação (texto colado): traduções de verdade em vez do "tradução de …"
  static const _frases = {
    'I wake up at six every morning.': 'Eu acordo às seis todas as manhãs.',
    'I drink coffee and read the news on my phone.': 'Eu tomo café e leio as notícias no celular.',
    'Then I go to work by bus.': 'Depois eu vou trabalhar de ônibus.',
    'My team is friendly, and we talk about new ideas.': 'Minha equipe é simpática, e a gente conversa sobre ideias novas.',
  };
  @override
  Future<List<String>> traduzir(List<String> frases, {void Function(int feitas, int total)? aoProgredir}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return [for (final f in frases) _palavras[f] ?? _frases[f] ?? 'tradução de $f'];
  }
}

class _TutorFake implements TutorService {
  @override
  Stream<String> perguntar({
    required String contexto,
    required String historico,
    required String pergunta,
  }) async* {
    // sanguessugas: uma dica de memória para a frase que a pessoa erra sempre
    if (contexto.contains('PEDIDO: dica de memória')) {
      for (final p in const [
        'Pense em **"Good morning"** como *"gude mórnin"*: o **good** soa como "gude". ',
        'Imagine alguém dizendo "gude" (bom) e depois o sol da **manhã** (*morning*) nascendo. ',
        'Frase completa: **Good morning, Mike!**',
      ]) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        yield p;
      }
      return;
    }
    // cenários guiados: o feedback (um JSON) e as falas do Dash (em inglês, sem corrigir)
    if (contexto.contains('MODO FEEDBACK DE CENÁRIO')) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      yield '```json\n{"foi_bem":["Você pediu com educação (please).","Respondeu rápido e sem travar."],'
          '"correcoes":[{"sua":"I want a coffee.","melhor":"Can I have a coffee, please?","porque":"**I want** soa seco; **Can I have…?** é o jeito educado de pedir."}],'
          '"frases":[{"en":"Can I have a coffee, please?","pt":"Posso pedir um café, por favor?"},'
          '{"en":"For here, please.","pt":"Para tomar aqui, por favor."},{"en":"How much is it?","pt":"Quanto custa?"}]}\n```';
      return;
    }
    // escrita corrigida: um JSON com dois erros (as frases da pessoa vêm numeradas no contexto)
    if (contexto.contains('MODO CORREÇÃO DE ESCRITA')) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      yield '```json\n{"em_ingles":true,"corrigido":"Yesterday I went to the market. I bought some cheese.",'
          '"elogio":"Você contou o dia em ordem e usou bem o passado.",'
          '"erros":[{"sua":"Yesterday I go to the market.","melhor":"Yesterday I went to the market.","pt":"Ontem eu fui ao mercado.",'
          '"porque":"**Yesterday** pede o passado: *go* vira **went**."},'
          '{"sua":"I buy some cheese.","melhor":"I bought some cheese.","pt":"Eu comprei um pouco de queijo.",'
          '"porque":"Mesma ideia: *buy* no passado é **bought**."}]}\n```';
      return;
    }
    if (contexto.contains('MODO CENÁRIO')) {
      final n = RegExp(r'Fala do aluno número (\d+)').firstMatch(contexto)?.group(1);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      yield switch (n) {
        '1' => 'Sure! What size would you like?',
        '2' => 'Great. Would you like anything to eat with that?',
        _ => "Perfect. That's four dollars. Have a nice day!",
      };
      return;
    }
    // "Por quê?": a explicação de um erro (um pedido que começa com PEDIDO:)
    if (contexto.startsWith('PEDIDO: explicar um erro')) {
      for (final p in const [
        'Quase! 🐦 O **"I\'m"** é a contração de *I am*: ',
        'em português a gente omite o sujeito, mas em inglês ele é obrigatório. ',
        'Armadilha de brasileiro: dizer *"Am Ana"*. O certo é **I\'m Ana** (Eu sou a Ana).',
      ]) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        yield p;
      }
      return;
    }
    // no inglês o Prof. Dash fala da frase da vez (o vídeo de apresentação grava essa cena)
    final ingles = contexto.contains('Frase em inglês');
    final partes = ingles ? _partesIngles : _partesDart;
    for (final p in partes) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      yield p;
    }
  }

  static const _partesIngles = [
    'Piu! Boa! 🐦 ',
    '**"I\'m here on business"** se fala ligado: *aim-hír-on-BIZ-nis*. ',
    'O **business** tem só duas sílabas (BIZ-nis), o *i* do meio some. ',
    '\n\nNa imigração, resposta curta é o que o oficial espera:\n\n',
    '- *On business.* (a negócios)\n- *On vacation.* (de férias)\n- *For five days.* (por cinco dias)\n\n',
    'Quer treinar a pergunta que vem antes? *What\'s the purpose of your visit?*',
  ];

  static const _partesDart = [
    'Piu! Boa pergunta. ',
    'Nesse trecho, `final` diz que a variável recebe valor uma vez só. ',
    'O objeto por dentro ainda pode mudar, o que não pode é apontar pra outro. ',
    '\n\n```dart\nfinal nomes = <String>[];\nnomes.add(\'Dash\'); // ok\n// nomes = []; // erro: final não recebe de novo\n```\n\n',
    'Quer que eu mostre a diferença pra `const`? 🐦',
  ];
}
