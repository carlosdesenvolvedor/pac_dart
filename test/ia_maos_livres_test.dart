import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ia/presentation/maos_livres.dart';
import 'package:pac_dart/features/ingles/data/reconhecedor_fala.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/painel_shadowing.dart';

import 'ingles_shadowing_ui_test.dart' show ReconhecedorFalso;

/// Um timer de mentira: o [_Relogio] o dispara quando o tempo virtual passa do vencimento.
class _TimerFalso implements Timer {
  final Duration vence;
  final void Function() acao;
  bool _ativo = true;
  _TimerFalso(this.vence, this.acao);

  @override
  void cancel() => _ativo = false;
  @override
  bool get isActive => _ativo;
  @override
  int get tick => _ativo ? 0 : 1;
}

/// O tempo dos timers do controlador, andando à mão.
class _Relogio {
  Duration agora = Duration.zero;
  final timers = <_TimerFalso>[];

  Timer criar(Duration d, void Function() f) {
    final t = _TimerFalso(agora + d, f);
    timers.add(t);
    return t;
  }

  /// Anda [d], disparando em ordem os timers que vencem no caminho.
  void passar(Duration d) {
    final fim = agora + d;
    while (true) {
      final vivos = timers.where((t) => t.isActive && t.vence <= fim).toList()..sort((a, b) => a.vence.compareTo(b.vence));
      if (vivos.isEmpty) break;
      final t = vivos.first;
      agora = t.vence;
      t._ativo = false;
      t.acao();
    }
    agora = fim;
  }
}

/// O reconhecedor que anota a ordem (com o "cala o app") num log.
class _Rec extends ReconhecedorFalso {
  final List<String> log;
  _Rec(this.log, {super.ok});
  final idiomas = <String>[];

  @override
  SessaoFala ouvir({
    String idioma = 'en-US',
    required void Function(String texto) aoParcial,
    required void Function(List<String> hipoteses) aoFinal,
    required void Function(ErroFala erro) aoErro,
    required void Function() aoFim,
  }) {
    log.add('ouvir');
    idiomas.add(idioma);
    return super.ouvir(idioma: idioma, aoParcial: aoParcial, aoFinal: aoFinal, aoErro: aoErro, aoFim: aoFim);
  }
}

/// Um reconhecedor que acaba dentro do próprio `ouvir` (como o do navegador sem suporte de verdade).
class _RecQueFalhaNaHora extends ReconhecedorFala {
  final ErroFala erro;
  int vezes = 0;
  _RecQueFalhaNaHora(this.erro);
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
    vezes++;
    aoErro(erro);
    aoFim();
    return _SessaoMorta();
  }
}

class _SessaoMorta implements SessaoFala {
  @override
  void parar() {}
  @override
  void cancelar() {}
}

void main() {
  late List<String> log;
  late _Rec rec;
  late _Relogio relogio;
  late List<String> enviados;
  late List<EstadoMaosLivres> estados;
  late bool pode;
  late bool podeFalar;

  ControladorMaosLivres criar({bool suportado = true, ReconhecedorFala? reconhecedor}) {
    log = [];
    rec = _Rec(log, ok: suportado);
    relogio = _Relogio();
    enviados = [];
    estados = [];
    pode = true;
    podeFalar = true;
    final c = ControladorMaosLivres(
      reconhecedor: reconhecedor ?? rec,
      enviar: (t) {
        log.add('enviar:$t');
        enviados.add(t);
      },
      antesDeOuvir: () async => log.add('calar'),
      podeAbrirSozinho: () => pode,
      podeSegurar: () => podeFalar,
      criarTimer: relogio.criar,
    );
    c.addListener(() {
      if (estados.isEmpty || estados.last != c.estado) estados.add(c.estado);
    });
    addTearDown(c.dispose);
    return c;
  }

  const ms = Duration(milliseconds: 1);

  test('começa desligado; ligar vai ao ocioso; sem reconhecimento de voz não liga e diz o motivo', () {
    final c = criar();
    expect(c.estado, EstadoMaosLivres.desligado);
    expect(c.ligado, isFalse);
    expect(c.disponivel, isTrue);
    expect(c.motivoIndisponivel, isEmpty);
    c.ligar();
    expect(c.estado, EstadoMaosLivres.ocioso);
    c.desligar();
    expect(c.estado, EstadoMaosLivres.desligado);

    final sem = criar(suportado: false);
    expect(sem.disponivel, isFalse);
    expect(sem.motivoIndisponivel, isNotEmpty);
    sem.ligar();
    expect(sem.estado, EstadoMaosLivres.desligado);
    sem.segurar();
    expect(log, isEmpty);
  });

  test('desligado, nada abre o microfone (segurar, fala do personagem)', () async {
    final c = criar();
    c.segurar();
    c.soltar();
    await c.personagemFala(null);
    expect(rec.escutas, isEmpty);
    expect(c.estado, EstadoMaosLivres.desligado);
  });

  group('segurar e soltar', () {
    test('cala o app ANTES de ouvir (en-US); soltar pede o fim e envia o que ouviu', () {
      final c = criar()..ligar();
      c.segurar();
      expect(c.estado, EstadoMaosLivres.ouvindo);
      expect(c.segurando, isTrue);
      expect(c.recado, isEmpty);
      expect(log, ['calar', 'ouvir']);
      expect(rec.idiomas, ['en-US']);
      rec.escutas.last.parcial('I want a');
      expect(c.parcial, 'I want a');
      relogio.passar(const Duration(seconds: 1));
      c.soltar();
      expect(rec.escutas.last.parada, isTrue);
      expect(enviados, isEmpty, reason: 'espera o navegador entregar o fim');
      rec.escutas.last.falou(['I want a coffee', 'I want coffee']);
      expect(enviados, ['I want a coffee']);
      expect(c.estado, EstadoMaosLivres.enviando);
      expect(c.parcial, isEmpty);
    });

    test('o navegador fecha a frase com o dedo no 🎤: reabre e o que vier soma', () {
      final c = criar()..ligar();
      c.segurar();
      relogio.passar(const Duration(seconds: 1));
      rec.escutas.last.falou(['I want a coffee']);
      expect(rec.escutas, hasLength(2), reason: 'reabriu');
      expect(c.estado, EstadoMaosLivres.ouvindo);
      expect(c.parcial, 'I want a coffee');
      rec.escutas.last.parcial('with milk');
      expect(c.parcial, 'I want a coffee with milk');
      c.soltar();
      rec.escutas.last.falou(['with milk']);
      expect(enviados, ['I want a coffee with milk']);
    });

    test('não reabre para sempre (navegador que fecha na hora)', () {
      final r = _RecQueFalhaNaHora(ErroFala.naoOuviu);
      final c = criar(reconhecedor: r)..ligar();
      c.segurar();
      expect(r.vezes, ControladorMaosLivres.maxReaberturas + 1);
      relogio.passar(const Duration(seconds: 1));
      c.soltar();
      expect(c.estado, EstadoMaosLivres.ocioso);
      expect(c.recado, ControladorMaosLivres.recadoNaoOuvi);
      expect(enviados, isEmpty);
    });

    test('soltou sem dizer nada: "Não ouvi nada — tente de novo", nada é enviado', () {
      final c = criar()..ligar();
      c.segurar();
      relogio.passar(const Duration(seconds: 1));
      c.soltar();
      rec.escutas.last.falou(const []);
      expect(c.estado, EstadoMaosLivres.ocioso);
      expect(c.recado, ControladorMaosLivres.recadoNaoOuvi);
      expect(enviados, isEmpty);
    });

    test('soltou e o navegador nunca responde: em 2 s fecha à força e envia o que já ouviu', () {
      final c = criar()..ligar();
      c.segurar();
      relogio.passar(const Duration(seconds: 1));
      rec.escutas.last.falou(['Hello']);
      final e = rec.escutas.last;
      e.parcial('there');
      c.soltar();
      relogio.passar(const Duration(milliseconds: 1999));
      expect(enviados, isEmpty);
      relogio.passar(ms);
      expect(e.cancelada, isTrue);
      expect(enviados, ['Hello'], reason: 'só os resultados finais valem');
      e.falou(['late words']);
      expect(enviados, ['Hello']);
    });

    test('um toque (soltar logo) abre a vez: envia sozinho 1,5 s depois do resultado final', () {
      final c = criar()..ligar();
      c.segurar();
      relogio.passar(const Duration(milliseconds: 100));
      c.soltar();
      expect(c.estado, EstadoMaosLivres.ouvindo);
      expect(c.segurando, isFalse);
      expect(c.recado, ControladorMaosLivres.recadoSuaVez);
      expect(rec.escutas.single.parada, isFalse);
      rec.escutas.single.falou(['A small latte, please']);
      relogio.passar(const Duration(milliseconds: 1499));
      expect(enviados, isEmpty);
      relogio.passar(ms);
      expect(enviados, ['A small latte, please']);
      expect(c.estado, EstadoMaosLivres.enviando);
    });

    test('segurar com a vez aberta vira "segurar": soltar envia o que ouviu', () async {
      final c = criar()..ligar();
      await c.personagemFala(null);
      expect(c.estado, EstadoMaosLivres.ouvindo);
      rec.escutas.last.falou(['Small']);
      c.segurar();
      expect(c.segurando, isTrue);
      expect(rec.escutas, hasLength(2), reason: 'a escuta tinha fechado: reabre para continuar');
      relogio.passar(const Duration(seconds: 3));
      expect(enviados, isEmpty, reason: 'segurando, o silêncio não envia');
      c.soltar();
      rec.escutas.last.falou(['please']);
      expect(enviados, ['Small please']);
    });

    test('enviando, segurar não faz nada', () {
      final c = criar()..ligar();
      c.segurar();
      relogio.passar(const Duration(seconds: 1));
      c.soltar();
      rec.escutas.last.falou(['Hi']);
      expect(c.estado, EstadoMaosLivres.enviando);
      c.segurar();
      expect(rec.escutas, hasLength(1));
      expect(c.estado, EstadoMaosLivres.enviando);
    });
  });

  group('a vez do aluno depois da fala do personagem', () {
    test('o microfone NUNCA abre enquanto a voz soa; abre quando ela acaba', () async {
      final c = criar()..ligar();
      final voz = Completer<void>();
      final fim = c.personagemFala(voz.future);
      expect(c.estado, EstadoMaosLivres.personagemFalando);
      await Future<void>.delayed(Duration.zero);
      relogio.passar(const Duration(seconds: 30));
      expect(rec.escutas, isEmpty);
      voz.complete();
      await fim;
      expect(c.estado, EstadoMaosLivres.ouvindo);
      expect(c.recado, ControladorMaosLivres.recadoSuaVez);
      expect(log, ['calar', 'ouvir']);
      expect(estados, [EstadoMaosLivres.ocioso, EstadoMaosLivres.personagemFalando, EstadoMaosLivres.ouvindo]);
    });

    test('sem voz (null): a vez abre já', () async {
      final c = criar()..ligar();
      await c.personagemFala(null);
      expect(c.estado, EstadoMaosLivres.ouvindo);
      expect(rec.escutas, hasLength(1));
    });

    test('a voz que falha também devolve a vez', () async {
      final c = criar()..ligar();
      await c.personagemFala(Future<void>.error(StateError('sem TTS')));
      expect(c.estado, EstadoMaosLivres.ouvindo);
    });

    test('nada dito em 8 s: fecha o microfone e mostra "Toque no 🎤 para falar"', () async {
      final c = criar()..ligar();
      await c.personagemFala(null);
      relogio.passar(const Duration(milliseconds: 7999));
      expect(c.estado, EstadoMaosLivres.ouvindo);
      relogio.passar(ms);
      expect(c.estado, EstadoMaosLivres.ocioso);
      expect(c.recado, ControladorMaosLivres.recadoToque);
      expect(rec.escutas.single.cancelada, isTrue);
      expect(enviados, isEmpty);
    });

    test('começou a falar: os 8 s não fecham; o silêncio depois do final envia', () async {
      final c = criar()..ligar();
      await c.personagemFala(null);
      relogio.passar(const Duration(seconds: 5));
      rec.escutas.single.parcial('A small');
      relogio.passar(const Duration(seconds: 5));
      expect(c.estado, EstadoMaosLivres.ouvindo);
      rec.escutas.single.falou(['A small latte']);
      relogio.passar(const Duration(milliseconds: 1500));
      expect(enviados, ['A small latte']);
    });

    test('o navegador fecha sem ouvir nada (no-speech): ocioso com "Toque no 🎤"', () async {
      final c = criar()..ligar();
      await c.personagemFala(null);
      rec.escutas.single.deuErro(ErroFala.naoOuviu);
      expect(c.estado, EstadoMaosLivres.ocioso);
      expect(c.recado, ControladorMaosLivres.recadoToque);
      relogio.passar(const Duration(seconds: 10));
      expect(c.estado, EstadoMaosLivres.ocioso);
    });

    test('a conversa não está livre (podeAbrirSozinho = false): fica ocioso, sem microfone', () async {
      final c = criar()..ligar();
      pode = false;
      await c.personagemFala(null);
      expect(rec.escutas, isEmpty);
      expect(c.estado, EstadoMaosLivres.ocioso);
    });

    test('segurar durante a fala: abre (o 🎤 cala o app) e o fim da fala não mexe em nada', () async {
      final c = criar()..ligar();
      final voz = Completer<void>();
      final fim = c.personagemFala(voz.future);
      c.segurar();
      expect(c.estado, EstadoMaosLivres.ouvindo);
      expect(log, ['calar', 'ouvir']);
      voz.complete();
      await fim;
      expect(c.segurando, isTrue);
      expect(rec.escutas, hasLength(1));
    });

    test('pausar (sair, resumo, descanso) durante a fala: nada abre depois', () async {
      final c = criar()..ligar();
      final voz = Completer<void>();
      final fim = c.personagemFala(voz.future);
      c.pausar();
      expect(c.estado, EstadoMaosLivres.ocioso);
      voz.complete();
      await fim;
      expect(rec.escutas, isEmpty);
      expect(c.estado, EstadoMaosLivres.ocioso);
    });

    test('a resposta chega com o aluno segurando o 🎤: nada muda', () async {
      final c = criar()..ligar();
      c.segurar();
      await c.personagemFala(null);
      expect(c.estado, EstadoMaosLivres.ouvindo);
      expect(c.segurando, isTrue);
      expect(rec.escutas.single.cancelada, isFalse);
    });

    test('desligar na fala: nada abre depois', () async {
      final c = criar()..ligar();
      final voz = Completer<void>();
      final fim = c.personagemFala(voz.future);
      c.desligar();
      voz.complete();
      await fim;
      expect(rec.escutas, isEmpty);
      expect(c.estado, EstadoMaosLivres.desligado);
    });
  });

  group('parar, pausar, falhar', () {
    test('⏹ fecha a vez sem enviar', () async {
      final c = criar()..ligar();
      await c.personagemFala(null);
      rec.escutas.single.parcial('I want');
      c.parar();
      expect(rec.escutas.single.cancelada, isTrue);
      expect(c.estado, EstadoMaosLivres.ocioso);
      expect(c.parcial, isEmpty);
      rec.escutas.single.falou(['I want a coffee']);
      relogio.passar(const Duration(seconds: 5));
      expect(enviados, isEmpty);
    });

    test('pausar com o microfone aberto: cancela, nada é enviado, fica ligado', () async {
      final c = criar()..ligar();
      await c.personagemFala(null);
      rec.escutas.single.falou(['Hello']);
      c.pausar();
      relogio.passar(const Duration(seconds: 5));
      expect(enviados, isEmpty);
      expect(c.estado, EstadoMaosLivres.ocioso);
      expect(c.ligado, isTrue);
    });

    test('desligar com o microfone aberto: cancela, nada é enviado', () {
      final c = criar()..ligar();
      c.segurar();
      rec.escutas.single.parcial('Hello');
      c.desligar();
      expect(rec.escutas.single.cancelada, isTrue);
      expect(c.estado, EstadoMaosLivres.desligado);
      c.soltar();
      expect(enviados, isEmpty);
    });

    test('o turno falhou: de "enviando" volta ao ocioso (sem abrir o microfone)', () {
      final c = criar()..ligar();
      c.turnoFalhou();
      expect(c.estado, EstadoMaosLivres.ocioso);
      c.segurar();
      relogio.passar(const Duration(seconds: 1));
      c.soltar();
      rec.escutas.last.falou(['Hi']);
      expect(c.estado, EstadoMaosLivres.enviando);
      c.turnoFalhou();
      expect(c.estado, EstadoMaosLivres.ocioso);
      expect(rec.escutas, hasLength(1));
    });

    test('microfone bloqueado: o modo desliga, o menu fica com o motivo, o recado explica', () {
      final c = criar()..ligar();
      c.segurar();
      rec.escutas.single.deuErro(ErroFala.semPermissao);
      expect(c.estado, EstadoMaosLivres.desligado);
      expect(c.disponivel, isFalse);
      final texto = PainelShadowingState.textoDoErro(ErroFala.semPermissao);
      expect(c.motivoIndisponivel, texto);
      expect(c.recado, texto);
      c.limparRecado();
      expect(c.recado, isEmpty);
      c.ligar();
      expect(c.ligado, isFalse);
    });

    test('sem suporte que só aparece ao ouvir (acaba dentro do ouvir): desliga sem erro', () {
      final r = _RecQueFalhaNaHora(ErroFala.naoSuportado);
      final c = criar(reconhecedor: r)..ligar();
      c.segurar();
      expect(r.vezes, 1);
      expect(c.estado, EstadoMaosLivres.desligado);
      expect(c.disponivel, isFalse);
    });

    test('a conversa não recebe fala (podeSegurar = false): segurar não grava nada', () {
      final c = criar()..ligar();
      podeFalar = false;
      c.segurar();
      relogio.passar(const Duration(seconds: 1));
      c.soltar();
      expect(rec.escutas, isEmpty);
      expect(log, isEmpty, reason: 'nem cala o app');
      expect(c.estado, EstadoMaosLivres.ocioso);
      podeFalar = true;
      c.segurar();
      expect(rec.escutas, hasLength(1));
    });

    test('o turno falhou com recado: ocioso mostrando o recado', () {
      final c = criar()..ligar();
      c.segurar();
      relogio.passar(const Duration(seconds: 1));
      c.soltar();
      rec.escutas.last.falou(['Hi']);
      c.turnoFalhou(recado: ControladorMaosLivres.recadoNoCampo);
      expect(c.estado, EstadoMaosLivres.ocioso);
      expect(c.recado, ControladorMaosLivres.recadoNoCampo);
    });

    test('depois do dispose nada avisa nem envia', () async {
      final log2 = <String>[];
      final r = _Rec(log2);
      final rel = _Relogio();
      final c = ControladorMaosLivres(reconhecedor: r, enviar: (_) => log2.add('enviar'), criarTimer: rel.criar)..ligar();
      await c.personagemFala(null);
      final e = r.escutas.single;
      c.dispose();
      expect(e.cancelada, isTrue);
      e.falou(['Hi']);
      rel.passar(const Duration(seconds: 10));
      expect(log2, ['ouvir']);
    });
  });

  group('pausas, toques e vozes que não acabam', () {
    test('a vez aberta: o navegador fecha na pausa, o microfone reabre e o resto da frase soma', () async {
      final c = criar()..ligar();
      await c.personagemFala(null);
      rec.escutas.last.falou(['I would like']);
      expect(rec.escutas, hasLength(2), reason: 'reabriu durante o silêncio');
      expect(c.estado, EstadoMaosLivres.ouvindo);
      relogio.passar(const Duration(milliseconds: 800));
      rec.escutas.last.parcial('a');
      expect(c.parcial, 'I would like a');
      relogio.passar(const Duration(seconds: 1));
      expect(enviados, isEmpty, reason: 'a fala que continua adia o envio');
      rec.escutas.last.falou(['a coffee']);
      relogio.passar(const Duration(milliseconds: 1499));
      expect(enviados, isEmpty);
      relogio.passar(ms);
      expect(enviados, ['I would like a coffee']);
      expect(rec.escutas.last.cancelada, isTrue, reason: 'a escuta reaberta fecha no envio');
      expect(c.estado, EstadoMaosLivres.enviando);
    });

    test('a vez aberta: a escuta reaberta que nada ouve não apaga o que já foi dito', () async {
      final c = criar()..ligar();
      await c.personagemFala(null);
      rec.escutas.last.falou(['Hello']);
      rec.escutas.last.deuErro(ErroFala.naoOuviu);
      expect(c.estado, EstadoMaosLivres.ouvindo);
      relogio.passar(const Duration(milliseconds: 1500));
      expect(enviados, ['Hello']);
    });

    test('um toque no 🎤 com a vez aberta (nada dito) não fecha a vez', () async {
      final c = criar()..ligar();
      await c.personagemFala(null);
      c.segurar();
      c.soltar();
      expect(c.estado, EstadoMaosLivres.ouvindo);
      expect(c.segurando, isFalse);
      expect(c.recado, ControladorMaosLivres.recadoSuaVez);
      expect(rec.escutas.single.parada, isFalse);
      rec.escutas.single.falou(['Hello']);
      relogio.passar(const Duration(milliseconds: 1500));
      expect(enviados, ['Hello']);
    });

    test('um toque no 🎤 com a vez aberta e algo já dito: envia o que ouviu', () async {
      final c = criar()..ligar();
      await c.personagemFala(null);
      rec.escutas.last.falou(['Small']);
      c.segurar();
      c.soltar();
      expect(rec.escutas.last.parada, isTrue);
      rec.escutas.last.falou(const []);
      expect(enviados, ['Small']);
    });

    test('segurando, várias frases com pausas: o limite de reaberturas só conta escutas vazias', () {
      final c = criar()..ligar();
      c.segurar();
      relogio.passar(const Duration(seconds: 1));
      final palavras = [for (var i = 0; i < ControladorMaosLivres.maxReaberturas + 4; i++) 'w$i'];
      for (final p in palavras) {
        rec.escutas.last.falou([p]);
      }
      expect(rec.escutas, hasLength(palavras.length + 1));
      expect(c.estado, EstadoMaosLivres.ouvindo);
      c.soltar();
      rec.escutas.last.falou(const []);
      expect(enviados, [palavras.join(' ')]);
    });

    test('segurando, o navegador fecha na hora vez após vez: não finge que ouve, envia o que já tinha', () {
      final c = criar()..ligar();
      c.segurar();
      relogio.passar(const Duration(seconds: 1));
      rec.escutas.last.falou(['Hi']);
      for (var i = 0; i < ControladorMaosLivres.maxReaberturas; i++) {
        rec.escutas.last.deuErro(ErroFala.naoOuviu);
      }
      expect(enviados, ['Hi']);
      expect(c.estado, EstadoMaosLivres.enviando);
      c.soltar();
      expect(enviados, ['Hi']);
    });

    test('segurando, sem rede: fecha já e explica (sem tela de "ouvindo" com o microfone fechado)', () {
      final c = criar()..ligar();
      c.segurar();
      relogio.passar(const Duration(seconds: 1));
      rec.escutas.last.deuErro(ErroFala.semRede);
      expect(rec.escutas, hasLength(1));
      expect(c.estado, EstadoMaosLivres.ocioso);
      expect(c.recado, PainelShadowingState.textoDoErro(ErroFala.semRede));
    });

    test('a voz que nunca avisa o fim: passado o limite, cala o app e abre a vez', () async {
      final c = criar()..ligar();
      final voz = Completer<void>(); // nunca completa (o Chrome perdeu o onend)
      final fim = c.personagemFala(voz.future, limite: const Duration(seconds: 12));
      await Future<void>.delayed(Duration.zero);
      relogio.passar(const Duration(milliseconds: 11999));
      await Future<void>.delayed(Duration.zero);
      expect(c.estado, EstadoMaosLivres.personagemFalando);
      expect(rec.escutas, isEmpty);
      relogio.passar(ms);
      await fim;
      expect(c.estado, EstadoMaosLivres.ouvindo);
      expect(log, ['calar', 'calar', 'ouvir'], reason: 'cala o que restar antes de abrir');
    });

    test('a voz que acaba antes do limite: o limite não faz mais nada', () async {
      final c = criar()..ligar();
      final voz = Completer<void>();
      final fim = c.personagemFala(voz.future, limite: const Duration(seconds: 12));
      voz.complete();
      await fim;
      expect(log, ['calar', 'ouvir']);
      rec.escutas.single.falou(['Hello']);
      relogio.passar(const Duration(milliseconds: 1500));
      expect(enviados, ['Hello']);
      relogio.passar(const Duration(seconds: 20));
      expect(log.where((l) => l == 'calar'), hasLength(1));
    });
  });
}
