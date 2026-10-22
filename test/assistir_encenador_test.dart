import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/domain/assistir/encenador_licao.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historia_licao.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart' show chaveDaFrase;
import 'package:pac_dart/features/ingles/domain/expressao.dart';

/// 📺 A encenação automática (plano §4): as 602 lições do currículo real viram uma história válida, sempre
/// igual, rápido, sem nada do Turismo; os casos conhecidos da heurística ficam presos aqui.
///
/// `--dart-define=DISTRIBUICAO=<arquivo>` grava a contagem de cenários (revisão do lead, plano §9 D); com
/// `--dart-define=TABELA=<encenacao_auto.json>` também encena as 602 com a tabela (tem de dar 0 erros) e lista
/// onde a heurística e a tabela discordam no cenário (para o grupo F revisar).

final _trilhas = (jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
    .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
    .toList();
final _doCurso = [
  for (final t in _trilhas)
    if (!t.propria)
      for (final l in t.licoes)
        if (l.id.isNotEmpty) (t: t, l: l),
];

({Trilha t, Licao l}) _achar(String id) => _doCurso.firstWhere((e) => e.l.id == id);

HistoriaLicao _encenar(String id, {EncenacaoManual? manual}) {
  final e = _achar(id);
  return EncenadorLicao.encenar(e.l, etapa: e.t.etapa, manual: manual);
}

Licao _licao(String cena, {List<Trecho>? trechos}) => Licao(
      nome: 'Teste',
      emoji: '🧪',
      id: 'teste.licao',
      cena: cena,
      trechos: trechos ??
          const [
            Trecho(id: 'f-1', quem: 'voce', cod: 'Hello!', dica: 'Olá!', out: ''),
            Trecho(id: 'f-2', quem: 'mike', cod: 'Hi!', dica: 'Oi!', out: ''),
          ],
    );

Trecho _t(String cod, String img, {String quem = 'voce'}) =>
    Trecho(id: 'f-x', quem: quem, cod: cod, dica: 'x', out: '', imagem: img);

/// Tudo o que a história decide, num texto só (para comparar duas rodadas).
String _assinatura(HistoriaLicao h) {
  final b = StringBuffer('${h.licaoId}|${h.nivel.name}|${h.autoral}|${h.ancoras}\n');
  for (final c in h.cenas) {
    b.writeln('${c.cenario.name} ${c.hora.name} ${c.clima.map((x) => x.name)}');
    for (final a in c.elenco) {
      b.writeln(' ${a.quem} ${a.pos?.name} ${a.visivel} ${a.remoto?.name} ${a.segura?.name} ${a.emocao.name}');
    }
    for (final f in c.falas) {
      b.writeln('  ${f.quem} ${f.mudo} ${f.en} ${f.acao.name} ${f.emocao?.name} ${f.alvo} ${f.camera?.name} '
          '${f.efeito?.name} ${f.segura?.name} ${f.reacoes.map((r) => '${r.quem}/${r.acao?.name}/${r.emocao?.name}')}');
    }
  }
  return b.toString();
}

void main() {
  group('as 602 lições do currículo', () {
    late final Map<String, HistoriaLicao> historias;
    late final int ms;

    setUpAll(() {
      final sw = Stopwatch()..start();
      historias = {for (final e in _doCurso) e.l.id: EncenadorLicao.encenar(e.l, etapa: e.t.etapa)};
      ms = sw.elapsedMilliseconds;
    });

    test('todas viram uma história válida (validarHistoriaLicao vazio), em menos de 15 s', () {
      expect(_doCurso.length, greaterThanOrEqualTo(602));
      final erros = <String>[];
      for (final e in _doCurso) {
        final h = historias[e.l.id]!;
        expect(h.autoral, isFalse);
        expect(h.titulo, isNull);
        expect(h.ancoras, hasLength(e.l.trechos.length), reason: e.l.id);
        erros.addAll(validarHistoriaLicao(h, e.l));
      }
      expect(erros, isEmpty, reason: erros.take(10).join('\n'));
      expect(ms, lessThan(15000));
    });

    test('determinístico: duas rodadas dão exatamente a mesma encenação', () {
      for (final e in _doCurso) {
        final deNovo = EncenadorLicao.encenar(e.l, etapa: e.t.etapa);
        expect(_assinatura(deNovo), _assinatura(historias[e.l.id]!), reason: e.l.id);
      }
    });

    test('nada do Turismo: nenhum cenário de corrida/espaço, nunca Max nem Kim, nenhum prop de corrida', () {
      for (final h in historias.values) {
        for (final c in h.cenas) {
          expect(cenariosSoDoTurismo, isNot(contains(c.cenario)), reason: h.licaoId);
          final quem = {
            for (final a in c.elenco) a.quem,
            for (final f in c.falas) ...[f.quem, for (final r in f.reacoes) r.quem],
          };
          expect(quem.intersection({'max', 'kim'}), isEmpty, reason: h.licaoId);
          for (final f in c.falas) {
            expect(f.cenario == null || !cenariosSoDoTurismo.contains(f.cenario), isTrue, reason: h.licaoId);
            expect(f.segura == null || !propsSoDoTurismo.contains(f.segura), isTrue, reason: h.licaoId);
            expect(f.camera, isNot(anyOf(CameraHistoria.tremida, CameraHistoria.panoramica)), reason: h.licaoId);
          }
        }
      }
    });

    test('limites: 1 cena, ≤ 5 presentes, ≤ 2 remotos, ≤ 3 mudos, no máximo 1 comemora por lição', () {
      for (final h in historias.values) {
        final c = h.cenas.single;
        expect(c.elenco.where((a) => !a.ehRemoto).length, lessThanOrEqualTo(5), reason: h.licaoId);
        expect(c.elenco.where((a) => a.ehRemoto).length, lessThanOrEqualTo(2), reason: h.licaoId);
        expect(c.falas.where((f) => f.mudo).length, lessThanOrEqualTo(3), reason: h.licaoId);
        expect(c.falas.where((f) => !f.mudo && f.acao == AcaoAtor.comemora).length, lessThanOrEqualTo(1),
            reason: h.licaoId);
        expect(c.elenco.first.quem, 'voce', reason: h.licaoId);
      }
    });

    test('remoto: sempre `parado`, sem prop, e alguém no palco segura o celular', () {
      var comRemoto = 0;
      for (final h in historias.values) {
        final c = h.cenas.single;
        final remotos = {for (final a in c.elenco) if (a.ehRemoto) a.quem};
        if (remotos.isEmpty) continue;
        comRemoto++;
        expect(c.elenco.firstWhere((a) => a.quem == 'voce').segura, PropHistoria.celular, reason: h.licaoId);
        for (final f in c.falas.where((f) => remotos.contains(f.quem))) {
          expect(f.acao, AcaoAtor.parado, reason: '${h.licaoId}: ${f.en}');
          expect(f.segura, isNull, reason: '${h.licaoId}: ${f.en}');
        }
        // o dono do celular não larga o celular (senão o remoto fica sem âncora)
        for (final f in c.falas.where((f) => f.quem == 'voce')) {
          expect(f.segura, isNull, reason: '${h.licaoId}: ${f.en}');
        }
      }
      expect(comRemoto, greaterThan(20));
    });

    test('placa → narrador (com 🪧 no chip), sem ação; o narrador nunca entra no elenco', () {
      var placas = 0;
      for (final e in _doCurso) {
        final h = historias[e.l.id]!;
        expect(h.cenas.single.elenco.map((a) => a.quem), isNot(contains(narrador)));
        for (final t in e.l.trechos.where((t) => t.quem == 'placa')) {
          placas++;
          final (c, p) = h.ancoras[chaveDaFrase(t)]!;
          final f = h.cenas[c].falas[p];
          expect(f.quem, narrador);
          expect(f.acao, AcaoAtor.parado);
          expect(f.segura, isNull);
          expect(f.camera, isNot(CameraHistoria.close));
          expect(EncenadorLicao.iconeDe(t), '🪧');
        }
      }
      expect(placas, greaterThanOrEqualTo(1));
      expect(EncenadorLicao.iconeDe(_t('Hi!', '👋🙂')), '👋🙂');
      expect(EncenadorLicao.iconeDe(_t('Hi!', '  ')), isNull);
    });

    test('monólogo (um só no palco) → `centro`; dois → voce à centroEsquerda', () {
      var sozinhos = 0;
      for (final h in historias.values) {
        final presentes = h.cenas.single.elenco.where((a) => !a.ehRemoto).toList();
        if (presentes.length == 1) {
          sozinhos++;
          expect(presentes.single.pos, PosicaoPalco.centro, reason: h.licaoId);
        } else if (presentes.length == 2) {
          expect(presentes.first.pos, PosicaoPalco.centroEsquerda, reason: h.licaoId);
          expect(presentes.last.pos, PosicaoPalco.centroDireita, reason: h.licaoId);
        }
      }
      expect(sozinhos, greaterThan(0));
    });

    test('distribuição dos cenários (e o arquivo da revisão, com --dart-define=DISTRIBUICAO)', () {
      final porCenario = <CenarioHistoria, List<String>>{};
      for (final h in historias.values) {
        (porCenario[h.cenas.single.cenario] ??= []).add(h.licaoId);
      }
      // os 5 cenários novos das lições aparecem, e a chamada/trabalho/casa dominam (2/3 das lições)
      for (final c in [
        CenarioHistoria.videochamada,
        CenarioHistoria.escritorio,
        CenarioHistoria.casa,
        CenarioHistoria.restaurante,
        CenarioHistoria.loja,
      ]) {
        expect(porCenario[c], isNotNull, reason: c.name);
      }
      expect(porCenario[CenarioHistoria.cafe], isNull, reason: 'o café do Turismo tem pista pela janela');
      const saida = String.fromEnvironment('DISTRIBUICAO');
      if (saida.isEmpty) return;
      final ordem = porCenario.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
      final total = historias.length;
      final remotos = historias.values.where((h) => h.cenas.single.elenco.any((a) => a.ehRemoto)).length;
      final entradas = historias.values.where((h) => h.cenas.single.elenco.any((a) => !a.visivel)).length;
      final fechos = historias.values.where((h) => h.cenas.single.falas.last.mudo).length;
      final b = StringBuffer()
        ..writeln('📺 Distribuição da encenação AUTOMÁTICA (EncenadorLicao, só a heurística, sem a tabela)')
        ..writeln('Gerado por test/assistir_encenador_test.dart; $total lições; ${ms}ms para encenar todas.')
        ..writeln()
        ..writeln('cenário        lições     %');
      for (final e in ordem) {
        b.writeln('${e.key.name.padRight(14)} ${'${e.value.length}'.padLeft(6)} '
            '${(100 * e.value.length / total).toStringAsFixed(1).padLeft(5)}');
      }
      b
        ..writeln()
        ..writeln('com remoto pelo celular (telefone/mensagem): $remotos')
        ..writeln('com entrada tardia (mudo `entra`): $entradas')
        ..writeln('com o aceno do fim (despedida): $fechos')
        ..writeln()
        ..writeln('── por cenário: cada lição com o elenco (@ = remoto, + = entra depois, :prop = segura) e a cena');
      for (final e in ordem) {
        b
          ..writeln()
          ..writeln('## ${e.key.name} (${e.value.length})');
        for (final id in e.value) {
          final c = historias[id]!.cenas.single;
          final elenco = [
            for (final a in c.elenco)
              '${a.quem}${a.ehRemoto ? '@' : ''}${a.visivel ? '' : '+'}${a.segura == null ? '' : ':${a.segura!.name}'}',
          ].join(',');
          b.writeln('${c.hora.name.padRight(9)} $id | $elenco | ${_achar(id).l.cena}');
        }
      }
      const tabela = String.fromEnvironment('TABELA');
      if (tabela.isNotEmpty) {
        final j = jsonDecode(File(tabela).readAsStringSync()) as Map<String, dynamic>;
        final linhas = (j['licoes'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, EncenacaoManual.fromJson(v as Map<String, dynamic>)));
        final erros = <String>[];
        final discordam = <String>[];
        for (final e in _doCurso) {
          final m = linhas[e.l.id];
          if (m == null) {
            erros.add('${e.l.id}: sem entrada na tabela');
            continue;
          }
          final h = EncenadorLicao.encenar(e.l, etapa: e.t.etapa, manual: m);
          erros.addAll(validarHistoriaLicao(h, e.l));
          final heur = historias[e.l.id]!.cenas.single.cenario;
          if (h.cenas.single.cenario != heur) {
            final nova = h.cenas.single.cenario.name;
            discordam.add('${heur.name.padRight(12)} → ${nova.padRight(12)} ${e.l.id} | ${e.l.cena}');
          }
        }
        b
          ..writeln()
          ..writeln('── com a tabela $tabela: ${linhas.length} entradas, ${erros.length} erros de validação')
          ..writeAll(erros.map((x) => '$x\n'))
          ..writeln()
          ..writeln('── heurística → tabela: ${discordam.length} lições com cenário diferente')
          ..writeAll(discordam.map((x) => '$x\n'));
        expect(erros, isEmpty, reason: erros.take(10).join('\n'));
      }
      File(saida)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(b.toString());
    });
  });

  group('casos conhecidos da heurística (4.1–4.3)', () {
    test('oi-tudo-bem → videochamada; a Ana entra tarde, num mudo logo antes do "Hi, Ana!"', () {
      final h = _encenar('primeiro-contato.oi-tudo-bem');
      final c = h.cenas.single;
      expect(c.cenario, CenarioHistoria.videochamada);
      expect(c.elenco.firstWhere((a) => a.quem == 'ana').visivel, isFalse);
      final (_, p) = h.ancoras['f-34d001']!; // "Hi, Ana! Good afternoon!"
      final entra = c.falas[p - 1];
      expect(entra.mudo, isTrue);
      expect(entra.quem, 'ana');
      expect(entra.acao, AcaoAtor.entra);
      expect(c.falas[p].alvo, 'ana');
      expect(c.falas.where((f) => f.mudo && f.acao == AcaoAtor.entra), hasLength(1));
    });

    test('treze-a-dezenove-o-teen → loja (o caso "adaptaDOR" não vira clínica)', () {
      final e = _achar('numeros-horas-soletrar.treze-a-dezenove-o-teen');
      expect(EncenadorLicao.cenarioDe(e.l, etapa: e.t.etapa), CenarioHistoria.loja);
      expect(_encenar(e.l.id).cenas.single.cenario, CenarioHistoria.loja);
    });

    test('cem-mil-e-os-precos → loja, com a Ana pelo celular e o voce segurando o celular', () {
      final c = _encenar('numeros-horas-soletrar.cem-mil-e-os-precos').cenas.single;
      expect(c.cenario, CenarioHistoria.loja);
      expect(c.elenco.firstWhere((a) => a.quem == 'ana').remoto, ViaRemota.celular);
      expect(c.elenco.firstWhere((a) => a.quem == 'voce').segura, PropHistoria.celular);
    });

    test('preposição de lugar: "toma um café" é a bebida; "no café" é o lugar', () {
      expect(EncenadorLicao.cenarioDe(_licao('Você toma um café e conta da sua família.'), etapa: 'A1'),
          isNot(CenarioHistoria.restaurante));
      expect(EncenadorLicao.cenarioDe(_licao('Você adora café e fala do seu dia.'), etapa: 'A1'),
          isNot(CenarioHistoria.restaurante));
      expect(EncenadorLicao.cenarioDe(_licao('No café perto do hotel, você pede um bolo.'), etapa: 'A1'),
          CenarioHistoria.restaurante);
      expect(EncenadorLicao.cenarioDe(_licao('Numa cafeteria, você conversa com a Ana.'), etapa: 'A1'),
          CenarioHistoria.restaurante);
    });

    test('o 1º lugar citado ganha (não a ordem da tabela)', () {
      expect(EncenadorLicao.cenarioDe(_licao('Num café perto do escritório, a Sarah pergunta.'), etapa: 'A1'),
          CenarioHistoria.restaurante);
      expect(EncenadorLicao.cenarioDe(_licao('No escritório, depois do café, a Sarah pergunta.'), etapa: 'A1'),
          CenarioHistoria.escritorio);
      expect(EncenadorLicao.cenarioDe(_licao('Hora do almoço no escritório: todos com fome.'), etapa: 'A1'),
          CenarioHistoria.escritorio);
    });

    test('`call` só vale perto de reunião/time; "chamada" e "por vídeo" são a chamada do time', () {
      expect(EncenadorLicao.cenarioDe(_licao('Primeira call com um cliente novo.'), etapa: 'B1'),
          CenarioHistoria.videochamada);
      expect(EncenadorLicao.cenarioDe(_licao('Você explica o que a palavra call quer dizer.'), etapa: 'A2'),
          isNot(CenarioHistoria.videochamada));
      expect(EncenadorLicao.cenarioDe(_licao('Por vídeo, você conta para o Ben a sua rotina.'), etapa: 'A1'),
          CenarioHistoria.videochamada);
      expect(EncenadorLicao.cenarioDe(_licao('Num happy hour online, o time comemora.'), etapa: 'B2'),
          CenarioHistoria.videochamada);
    });

    test('sem lugar: trabalho/DEV → escritorio; mensagem → casa (com o outro pelo celular); o resto → casa', () {
      expect(EncenadorLicao.cenarioDe(_licao('Você revisa o PR do time.'), etapa: 'B2'), CenarioHistoria.escritorio);
      expect(EncenadorLicao.cenarioDe(_licao('Você explica o raciocínio.'), etapa: 'DEV · Inglês'),
          CenarioHistoria.escritorio);
      expect(EncenadorLicao.cenarioDe(_licao('Você conta para a Julia o fim de semana.'), etapa: 'A1'),
          CenarioHistoria.casa);
      final msg = EncenadorLicao.encenar(_licao('Você e o Mike trocam mensagens sobre o fim de semana.'), etapa: 'A1');
      expect(msg.cenas.single.cenario, CenarioHistoria.casa);
      expect(msg.cenas.single.elenco.firstWhere((a) => a.quem == 'mike').remoto, ViaRemota.celular);
    });

    test('a hora pelo texto da cena, senão pela 1ª frase; o clima só quando a cena diz', () {
      final noite = EncenadorLicao.encenar(_licao('À noite, numa chamada com o Mike.'), etapa: 'A1').cenas.single;
      expect(noite.hora, HoraHistoria.noite);
      final tarde = EncenadorLicao.encenar(_licao('Sexta à tarde, no escritório.'), etapa: 'A1').cenas.single;
      expect(tarde.hora, HoraHistoria.tarde);
      final pelaFrase = EncenadorLicao.encenar(
          _licao('Numa chamada.', trechos: const [
            Trecho(id: 'f-1', quem: 'voce', cod: 'Good evening, Mike.', dica: 'Boa noite, Mike.', out: ''),
          ]),
          etapa: 'A1');
      expect(pelaFrase.cenas.single.hora, HoraHistoria.noite);
      final chuva = EncenadorLicao.encenar(_licao('Num dia de chuva, em casa.'), etapa: 'A1').cenas.single;
      expect(chuva.clima, [ClimaHistoria.chuva]);
      expect(EncenadorLicao.encenar(_licao('Em casa.'), etapa: 'A1').cenas.single.clima, isEmpty);
    });

    test('canônico citado na cena sem falar entra mudo; a posse ("um dia do Mike") não', () {
      final c = EncenadorLicao.encenar(
              _licao('No escritório, você apresenta a Ana ao Ben.', trechos: const [
                Trecho(id: 'f-1', quem: 'voce', cod: 'This is Ana.', dica: 'Esta é a Ana.', out: ''),
              ]),
              etapa: 'A1')
          .cenas
          .single;
      expect(c.elenco.map((a) => a.quem), ['voce', 'ana', 'ben']);
      final posse = EncenadorLicao.encenar(
              _licao('Você conta para a Julia como é um dia normal do Mike.', trechos: const [
                Trecho(id: 'f-1', quem: 'voce', cod: 'He works a lot.', dica: 'Ele trabalha muito.', out: ''),
              ]),
              etapa: 'A1')
          .cenas
          .single;
      expect(posse.elenco.map((a) => a.quem), ['voce', 'julia']);
    });

    test('a despedida no fim: um mudo com todo mundo acenando', () {
      final h = _encenar('primeiro-contato.prazer-ate-amanha');
      final ultimo = h.cenas.single.falas.last;
      expect(ultimo.mudo, isTrue);
      expect(ultimo.acao, AcaoAtor.acena);
      expect(ultimo.reacoes.map((r) => r.quem).toSet(), {'sarah', 'mike', 'ana'});
      expect(ultimo.reacoes.every((r) => r.acao == AcaoAtor.acena), isTrue);
    });
  });

  group('EncenacaoManual vence a heurística', () {
    test('cenário e hora da tabela (cenário do Turismo é ignorado)', () {
      final h = _encenar('numeros-horas-soletrar.treze-a-dezenove-o-teen',
          manual: EncenacaoManual.fromJson({'cenario': 'restaurante', 'hora': 'noite'}));
      expect(h.cenas.single.cenario, CenarioHistoria.restaurante);
      expect(h.cenas.single.hora, HoraHistoria.noite);
      final turismo = _encenar('numeros-horas-soletrar.treze-a-dezenove-o-teen',
          manual: const EncenacaoManual(cenario: CenarioHistoria.marte));
      expect(turismo.cenas.single.cenario, CenarioHistoria.loja);
    });

    test('a entrada da tabela manda nas listas: sem `remotos`/`entram`/`mudos` = nenhum', () {
      const id = 'numeros-horas-soletrar.cem-mil-e-os-precos';
      final semRemoto = _encenar(id, manual: EncenacaoManual.fromJson({'cenario': 'loja', 'hora': 'dia'}));
      expect(semRemoto.cenas.single.elenco.any((a) => a.ehRemoto), isFalse);
      expect(validarHistoriaLicao(semRemoto, _achar(id).l), isEmpty);
      final comRemoto = _encenar(id,
          manual: EncenacaoManual.fromJson({
            'cenario': 'loja',
            'remotos': {'ana': 'celular'},
          }));
      expect(comRemoto.cenas.single.elenco.firstWhere((a) => a.quem == 'ana').remoto, ViaRemota.celular);
      // a heurística punha a Ana entrando tarde em oi-tudo-bem; a entrada da tabela sem `entram`, não
      const oi = 'primeiro-contato.oi-tudo-bem';
      final semEntrada = _encenar(oi, manual: EncenacaoManual.fromJson({'cenario': 'videochamada'}));
      expect(semEntrada.cenas.single.elenco.every((a) => a.visivel), isTrue);
      expect(validarHistoriaLicao(semEntrada, _achar(oi).l), isEmpty);
      // e sem `mudos`, o citado na cena que não fala não entra
      final citado = EncenadorLicao.encenar(
          _licao('No escritório, você apresenta a Ana ao Ben.', trechos: const [
            Trecho(id: 'f-1', quem: 'voce', cod: 'This is Ana.', dica: 'Esta é a Ana.', out: ''),
          ]),
          etapa: 'A1',
          manual: const EncenacaoManual(cenario: CenarioHistoria.escritorio));
      expect(citado.cenas.single.elenco.map((a) => a.quem), ['voce']);
    });

    test('remotos da tabela: alguém no celular, o voce segurando o celular; nunca o voce', () {
      const id = 'numeros-horas-soletrar.que-horas-sao';
      final h = _encenar(id,
          manual: EncenacaoManual.fromJson({
            'cenario': 'casa',
            'remotos': {'mike': 'celular', 'voce': 'celular'},
          }));
      final c = h.cenas.single;
      expect(c.cenario, CenarioHistoria.casa);
      expect(c.elenco.firstWhere((a) => a.quem == 'mike').remoto, ViaRemota.celular);
      expect(c.elenco.firstWhere((a) => a.quem == 'voce').remoto, isNull);
      expect(c.elenco.firstWhere((a) => a.quem == 'voce').segura, PropHistoria.celular);
      expect(validarHistoriaLicao(h, _achar(id).l), isEmpty);
    });

    test('mudos: canônico e figurante de figurantesConhecidos (no máximo 2 figurantes), sempre válido', () {
      const id = 'primeiro-contato.nao-entendi-pode-repetir';
      final h = _encenar(id,
          manual: EncenacaoManual.fromJson({
            'cenario': 'escritorio',
            'mudos': ['sarah', 'recepcionista', 'garcom', 'vendedora', 'max', 'desconhecido'],
          }));
      final quem = h.cenas.single.elenco.map((a) => a.quem).toList();
      expect(quem, containsAll(['sarah', 'recepcionista', 'garcom']));
      expect(quem, isNot(contains('vendedora')));
      expect(quem, isNot(contains('max')));
      expect(quem, isNot(contains('desconhecido')));
      expect(validarHistoriaLicao(h, _achar(id).l), isEmpty);
    });

    test('entram: a tabela força a entrada tardia', () {
      const id = 'numeros-horas-soletrar.que-horas-sao';
      final l = _achar(id).l;
      final h = _encenar(id, manual: EncenacaoManual.fromJson({'entram': ['mike']}));
      final c = h.cenas.single;
      final mike = c.elenco.firstWhere((a) => a.quem == 'mike');
      expect(l.trechos.indexWhere((t) => t.quem == 'mike'), greaterThanOrEqualTo(1));
      expect(mike.visivel, isFalse);
      expect(c.falas.where((f) => f.mudo && f.quem == 'mike' && f.acao == AcaoAtor.entra), hasLength(1));
      expect(validarHistoriaLicao(h, l), isEmpty);
    });
  });

  group('gestoDe (4.4): o emoji primeiro, por grafema; depois o texto', () {
    test('emoji → ação (com U+FE0F e tom de pele)', () {
      expect(EncenadorLicao.gestoDe(_t('Wait.', '☝️🐌')).acao, AcaoAtor.aponta);
      // "Welcome" não é cumprimento no texto: o aceno vem do 👋 (com o tom de pele tirado)
      expect(EncenadorLicao.gestoDe(_t('Welcome.', '👋🏽')).acao, AcaoAtor.acena);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '👍')).acao, AcaoAtor.concorda);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '🙅')).acao, AcaoAtor.nega);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '👏')).acao, AcaoAtor.palmas);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '🤝')).acao, AcaoAtor.concorda);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '✅')).acao, AcaoAtor.concorda);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '❌')).acao, AcaoAtor.nega);
      expect(EncenadorLicao.gestoDe(_t('Me!', '🙋')).acao, AcaoAtor.acena);
      final escreve = EncenadorLicao.gestoDe(_t('Okay.', '✍️'));
      expect(escreve.acao, AcaoAtor.escreve);
      expect(escreve.segura, PropHistoria.documento);
      final pensa = EncenadorLicao.gestoDe(_t('Hmm.', '🤔'));
      expect(pensa.acao, AcaoAtor.pensa);
      expect(pensa.emocao, Expressao.pensativo);
    });

    test('emoji → emoção, efeito e prop', () {
      expect(EncenadorLicao.gestoDe(_t('Okay.', '😃')).emocao, Expressao.radiante);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '😬')).emocao, Expressao.nervoso);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '💪')).emocao, Expressao.determinado);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '❤️')).efeito, EfeitoHistoria.coracoes);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '🎉')).efeito, EfeitoHistoria.confete);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '☕')).segura, PropHistoria.cafe);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '🛍️')).segura, PropHistoria.sacola);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '🗺️')).segura, PropHistoria.mapa);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '💻')).segura, PropHistoria.notebook);
    });

    test('o prop do emoji tem de caber no lugar: nada de prato no consultório nem mala no lago', () {
      Set<PropHistoria?> nasMaos(HistoriaLicao h) => {
            for (final c in h.cenas) ...[
              for (final a in c.elenco) a.segura,
              for (final f in c.falas) f.segura,
            ],
          };
      // 🍽️ = "tomar com comida" (consultório) · 🧳 = "viajar" (conversa no parque)
      expect(nasMaos(_encenar('situacao-saude.na-consulta-os-conselhos-da-dra-lee')), isNot(contains(PropHistoria.prato)));
      expect(nasMaos(_encenar('segunda-condicional.se-eu-tivesse-mais-tempo',
              manual: const EncenacaoManual(cenario: CenarioHistoria.lago))),
          isNot(contains(PropHistoria.mala)));
      // no lugar certo, o mesmo emoji ainda vira o prop
      final noRestaurante = Licao(id: 'teste.prato', nome: 'T', emoji: '🧪', cena: 'No restaurante.', trechos: [
        _t('Hello!', '👋'),
        _t('The pizza, please.', '🍕', quem: 'mike'),
      ]);
      expect(nasMaos(EncenadorLicao.encenar(noRestaurante, etapa: 'A1 · Fundação')), contains(PropHistoria.prato));
    });

    test('ZWJ é um grafema só: 👩‍💻 não é o 💻 (nem 👩‍🎨 o 🎨)', () {
      expect(EncenadorLicao.gestoDe(_t('Okay.', '👩‍💻')).segura, isNull);
      expect(EncenadorLicao.gestoDe(_t('Okay.', '🧑‍💻📄')).segura, PropHistoria.documento);
      final ana = EncenadorLicao.gestoDe(_t("How's it going, Carlos?", '👩‍🎨❓', quem: 'ana'));
      expect(ana.acao, AcaoAtor.parado);
      expect(ana.efeito, isNull, reason: '❓ só com Sorry?/What?/Pardon?');
      expect(ana.emocao, Expressao.pensativo);
      expect(EncenadorLicao.gestoDe(_t('Sorry?', '❓')).efeito, EfeitoHistoria.interrogacao);
    });

    test('o texto decide o que o emoji não decidiu', () {
      expect(EncenadorLicao.gestoDe(_t('Good morning, Mike!', '☀️')).acao, AcaoAtor.acena);
      expect(EncenadorLicao.gestoDe(_t('See you tomorrow!', '')).acao, AcaoAtor.acena);
      final obrigado = EncenadorLicao.gestoDe(_t('Thank you so much.', ''));
      expect(obrigado.acao, AcaoAtor.concorda);
      expect(obrigado.emocao, Expressao.feliz);
      expect(EncenadorLicao.gestoDe(_t("Sorry, I'm late.", '')).emocao, Expressao.timido);
      expect(EncenadorLicao.gestoDe(_t('Yes, of course.', '')).acao, AcaoAtor.concorda);
      expect(EncenadorLicao.gestoDe(_t('No, thanks.', '')).acao, AcaoAtor.nega);
      expect(EncenadorLicao.gestoDe(_t('Look at this.', '')).acao, AcaoAtor.aponta);
      final viva = EncenadorLicao.gestoDe(_t('Great job, team!', ''));
      expect(viva.acao, AcaoAtor.comemora);
      expect(viva.emocao, Expressao.radiante);
      expect(EncenadorLicao.gestoDe(_t('Where is it?', '')).emocao, Expressao.pensativo);
      // o emoji ganha do texto
      expect(EncenadorLicao.gestoDe(_t('Where is it?', '😊')).emocao, Expressao.feliz);
      expect(EncenadorLicao.gestoDe(_t('It is here.', '')).acao, AcaoAtor.parado);
    });

    test('emoção do emoji: as caras mais usadas no currículo', () {
      for (final (e, x) in [
        ('😌', Expressao.feliz), ('😍', Expressao.radiante), ('😂', Expressao.radiante), ('😔', Expressao.triste),
        ('😱', Expressao.surpreso), ('😤', Expressao.bravo), ('🙄', Expressao.bravo), ('🤨', Expressao.pensativo),
        ('😅', Expressao.nervoso), ('😟', Expressao.nervoso), ('😴', Expressao.cansado), ('🤢', Expressao.cansado),
        ('🥶', Expressao.cansado), ('😵', Expressao.cansado),
      ]) {
        expect(EncenadorLicao.gestoDe(_t('Okay.', e)).emocao, x, reason: e);
      }
    });

    test('ironia e recusa: 🙄 não comemora; "No, thanks." com 🤢 não sorri', () {
      final ironia = EncenadorLicao.gestoDe(_t('Great. First my connection, now the last train!', '🙄✈️🚆'));
      expect(ironia.acao, isNot(AcaoAtor.comemora));
      expect(ironia.emocao, Expressao.bravo);
      final doente = EncenadorLicao.gestoDe(_t('No, thanks. I feel sick.', '☕🙅🤢'));
      expect(doente.acao, AcaoAtor.nega);
      expect(doente.emocao, Expressao.cansado);
      expect(doente.segura, isNull, reason: 'recusou o café: não segura o café');
      expect(EncenadorLicao.gestoDe(_t('No, thanks.', '')).emocao, isNull);
    });

    test('"No problem/No wonder/No way" não negam com a cabeça', () {
      expect(EncenadorLicao.gestoDe(_t("No problem. It's cold today!", '')).acao, AcaoAtor.concorda);
      expect(EncenadorLicao.gestoDe(_t('No worries.', '')).acao, AcaoAtor.concorda);
      expect(EncenadorLicao.gestoDe(_t("No wonder you're tired.", '')).acao, AcaoAtor.parado);
      final noWay = EncenadorLicao.gestoDe(_t('No way! That was fast.', ''));
      expect(noWay.acao, isNot(AcaoAtor.nega));
      expect(noWay.emocao, Expressao.surpreso);
      expect(EncenadorLicao.gestoDe(_t('No one came.', '')).acao, AcaoAtor.parado);
      expect(EncenadorLicao.gestoDe(_t('No, I live in Chicago.', '')).acao, AcaoAtor.nega);
      expect(EncenadorLicao.gestoDe(_t('Nope.', '')).acao, AcaoAtor.nega);
      expect(EncenadorLicao.gestoDe(_t('Not yet.', '')).acao, AcaoAtor.nega);
    });

    test('👋 só acena com cumprimento/despedida; 🪑 é só a cadeira', () {
      expect(EncenadorLicao.gestoDe(_t('Oh no. We missed the last train.', '🚆👋😩')).acao, isNot(AcaoAtor.acena));
      expect(EncenadorLicao.gestoDe(_t('Meanwhile, we kept losing users every week.', '📉👋')).acao, AcaoAtor.parado);
      expect(EncenadorLicao.gestoDe(_t('Sorry! Hi, Carlos!', '👋')).acao, AcaoAtor.acena);
      expect(EncenadorLicao.gestoDe(_t('Sarah, would you like to join us?', '👋👥')).acao, AcaoAtor.acena);
      expect(EncenadorLicao.gestoDe(_t('Bye, Mike.', '👋')).acao, AcaoAtor.acena);
      expect(EncenadorLicao.gestoDe(_t('Those two chairs are very comfortable.', '🪑')).acao, AcaoAtor.parado);
      expect(EncenadorLicao.gestoDe(_t('For here or to go?', '🪑🥤❓')).acao, AcaoAtor.parado);
      expect(EncenadorLicao.gestoDe(_t('The moment I sat down, my phone started ringing.', '🪑📱🔔')).acao,
          AcaoAtor.senta);
      expect(EncenadorLicao.gestoDe(_t('Please, have a seat.', '')).acao, AcaoAtor.senta);
    });

    test('emoji de metáfora: 🍽️/💧 não viram prop; negado (🚫/No…) não vai para a mão', () {
      expect(EncenadorLicao.gestoDe(_t('A table for four.', '🍽️👥')).segura, isNull);
      expect(EncenadorLicao.gestoDe(_t('A drop in the bucket.', '💧🪣')).segura, isNull);
      expect(EncenadorLicao.gestoDe(_t("I don't drink soda.", '🥤🚫☕')).segura, isNull);
      expect(EncenadorLicao.gestoDe(_t("No, there aren't any here.", '🍕')).segura, isNull);
      expect(EncenadorLicao.gestoDe(_t('Not the pizza.', '🍕')).segura, isNull);
      expect(EncenadorLicao.gestoDe(_t('The pizza, please.', '🍕')).segura, PropHistoria.prato);
    });
  });

  group('props e alvos no palco (S1/S6)', () {
    Licao licao(String cena, List<Trecho> trechos) =>
        Licao(id: 'teste.props', nome: 'T', emoji: '🧪', cena: cena, trechos: trechos);
    Set<PropHistoria?> nasMaos(HistoriaLicao h) => {
          for (final c in h.cenas) ...[
            for (final a in c.elenco) a.segura,
            for (final f in c.falas) f.segura,
          ],
        };

    test('na videochamada só café, notebook, documento (e celular quando a frase fala de telefone)', () {
      const chamada = EncenacaoManual(cenario: CenarioHistoria.videochamada);
      final h = EncenadorLicao.encenar(
          licao('Na call do time.', [
            _t('It checks the password.', '🔑', quem: 'mike'),
            _t("That's it from me.", '🎤', quem: 'ana'),
            _t('Under-promise and over-deliver.', '🤏🎁', quem: 'sarah'),
            _t('Your background, please.', '🗺️📈'),
            _t('Here is the doc.', '📄', quem: 'mike'),
            _t('Let me check my messages.', '📱', quem: 'ana'),
          ]),
          etapa: 'DEV',
          manual: chamada);
      final m = nasMaos(h);
      for (final p in [PropHistoria.chave, PropHistoria.microfone, PropHistoria.presente, PropHistoria.mapa,
          PropHistoria.celular]) {
        expect(m, isNot(contains(p)), reason: p.name);
      }
      expect(m, contains(PropHistoria.documento));
      final tel = EncenadorLicao.encenar(licao('Na call.', [_t("I'll call you later.", '📱', quem: 'mike')]),
          etapa: 'DEV', manual: chamada);
      expect(nasMaos(tel), contains(PropHistoria.celular));
    });

    test('chave/mapa/microfone/presente só onde cabem', () {
      HistoriaLicao em(CenarioHistoria c, Trecho t) =>
          EncenadorLicao.encenar(licao('Cena.', [t]), etapa: 'A1', manual: EncenacaoManual(cenario: c));
      expect(nasMaos(em(CenarioHistoria.escritorio, _t('It checks the password.', '🔑'))),
          isNot(contains(PropHistoria.chave)));
      expect(nasMaos(em(CenarioHistoria.hotel, _t('Here is your key.', '🔑'))), contains(PropHistoria.chave));
      expect(nasMaos(em(CenarioHistoria.escritorio, _t('Your background.', '🗺️'))), isNot(contains(PropHistoria.mapa)));
      expect(nasMaos(em(CenarioHistoria.cidade, _t('Look at the map.', '🗺️'))), contains(PropHistoria.mapa));
      expect(nasMaos(em(CenarioHistoria.escritorio, _t("That's it from me.", '🎤'))),
          isNot(contains(PropHistoria.microfone)));
      expect(nasMaos(em(CenarioHistoria.escritorio, _t("I'll present the demo.", '🎤'))),
          contains(PropHistoria.microfone));
      expect(nasMaos(em(CenarioHistoria.escritorio, _t('Over-deliver.', '🎁'))), isNot(contains(PropHistoria.presente)));
      expect(nasMaos(em(CenarioHistoria.casa, _t('This is for you.', '🎁'))), contains(PropHistoria.presente));
    });

    test('ninguém senta na videochamada', () {
      final h = EncenadorLicao.encenar(
          licao('Na call.', [_t('The moment I sat down, my phone rang.', '🪑'), _t('Oh no!', '', quem: 'mike')]),
          etapa: 'DEV',
          manual: const EncenacaoManual(cenario: CenarioHistoria.videochamada));
      expect(h.cenas.expand((c) => c.falas).map((f) => f.acao), isNot(contains(AcaoAtor.senta)));
    });

    test('o gesto para quem está no celular fica sem alvo (não aponta para outro)', () {
      final h = _encenar('convites-pedidos.quer-vir-jantar-would-you-like-to',
          manual: const EncenacaoManual(
              cenario: CenarioHistoria.casa, remotos: {'sarah': ViaRemota.celular, 'ana': ViaRemota.celular}));
      final f = h.cenas.expand((c) => c.falas).firstWhere((f) => (f.en ?? '').startsWith('Sarah, would you like'));
      expect(f.acao, AcaoAtor.acena);
      expect(f.alvo, isNull);
    });
  });

  group('tabela encenacao_auto.json: correções da revisão (T1–T7)', () {
    final tabela = (jsonDecode(File('assets/ingles/historias/encenacao_auto.json').readAsStringSync())
        as Map<String, dynamic>)['licoes'] as Map<String, dynamic>;
    CenaHistoria cena(String id) =>
        _encenar(id, manual: EncenacaoManual.fromJson(tabela[id] as Map<String, dynamic>)).cenas.single;
    AtorEmCena ator(CenaHistoria c, String q) => c.elenco.firstWhere((a) => a.quem == q);

    test('Lucas abre a porta em pessoa (entra), a Ana no celular', () {
      final c = cena('deducao-perguntas-indiretas.deve-estar-nao-pode-ser');
      expect(ator(c, 'lucas').ehRemoto, isFalse);
      expect(ator(c, 'lucas').visivel, isFalse);
      expect(ator(c, 'ana').remoto, ViaRemota.celular);
      expect(c.falas.any((f) => f.quem == 'lucas' && f.mudo && f.acao == AcaoAtor.entra), isTrue);
    });

    test('a passageira está no avião, não numa webcam', () {
      final c = cena('eu-e-voce-be.voce-e-sou-sim');
      expect(c.cenario, CenarioHistoria.aeroporto);
      expect(ator(c, 'passageira').ehRemoto, isFalse);
      expect(ator(c, 'dev-novo').remoto, ViaRemota.celular);
      expect(ator(c, 'sarah').remoto, ViaRemota.celular);
    });

    test('documentando a API: Mike entra na sala e o voce fica com o notebook', () {
      final c = cena('dev-docs-email.este-metodo-esta-obsoleto');
      expect(c.elenco.any((a) => a.ehRemoto), isFalse);
      expect(ator(c, 'mike').visivel, isFalse);
      expect(ator(c, 'voce').segura, PropHistoria.notebook);
    });

    test('recado: quem liga (cliente) e o Mike estão no celular; a Ana no palco', () {
      final c = cena('pronomes-objeto.cena-deixando-recado');
      expect(ator(c, 'cliente').remoto, ViaRemota.celular);
      expect(ator(c, 'mike').remoto, ViaRemota.celular);
      expect(ator(c, 'ana').ehRemoto, isFalse);
      expect(c.falas.where((f) => f.quem == 'cliente').map((f) => f.segura), everyElement(isNull));
    });

    test('segunda de manhã no escritório, só a Sarah na chamada', () {
      final c = cena('passado-was-were.ontem-eu-estava-em-casa');
      expect(c.cenario, CenarioHistoria.escritorio);
      expect(ator(c, 'sarah').remoto, ViaRemota.celular);
      expect(c.elenco.where((a) => a.ehRemoto).map((a) => a.quem), ['sarah']);
    });

    test('o voce avisa o Mike, que ouve ao lado (mudo)', () {
      final c = cena('dev-docs-email.so-retomando-meu-ultimo-e-mail');
      expect(ator(c, 'mike').ehRemoto, isFalse);
      expect(ator(c, 'mike').visivel, isTrue);
      expect(ator(c, 'cliente').remoto, ViaRemota.celular);
    });
  });
}
