import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/ator_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/balao_fala.dart';
import 'package:pac_dart/features/arcade/presentation/historia/elenco_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/figurantes_historia.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historia_licao.dart';
import 'package:pac_dart/features/ingles/domain/expressao.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/elenco_ingles.dart';

/// 📺 Grupo B (plano §8.3 e §9): os figurantes das historinhas das lições e o `ElencoTurismo` com a saída do
/// Turismo idêntica à de antes.

/// Tudo o que o desenho lê de uma [Aparencia] (a classe não tem `==`): duas assinaturas iguais = o mesmo boneco.
String _assinatura(Aparencia a) => [
      a.pele.toARGB32(),
      a.cabelo.toARGB32(),
      a.roupa.toARGB32(),
      a.estilo.name,
      a.oculos,
      a.gorro,
      a.brincos,
      a.sardas,
      a.jaleco,
      a.flor,
      a.cilios,
      a.fone,
      a.detalhe?.toARGB32(),
    ].join('|');

/// Distância RGB (0–441) entre duas cores.
double _distancia(Color a, Color b) {
  int c(Color x, int s) => (x.toARGB32() >> s) & 0xFF;
  return math.sqrt([16, 8, 0].map((s) => math.pow(c(a, s) - c(b, s), 2)).fold<num>(0, (x, y) => x + y));
}

const _turismo = ['voce', 'mike', 'sarah', 'ana', 'ben', 'emma', 'lucas', 'julia', 'dra-lee', 'max', 'kim'];

void main() {
  final curso = (jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
      .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
      .toList();
  final licoes = [for (final t in curso) for (final l in t.licoes) l];
  final papeis = {for (final l in licoes) for (final t in l.trechos) t.quem};

  group('a tabela fixa dos 53 figurantesConhecidos', () {
    test('cobre exatamente os figurantesConhecidos, e todos são figurantes', () {
      expect(FigurantesHistoria.tabelados.toSet(), figurantesConhecidos);
      expect(FigurantesHistoria.tabelados, hasLength(53));
      for (final id in figurantesConhecidos) {
        expect(FigurantesHistoria.ehFigurante(id), isTrue, reason: id);
      }
    });

    test('quem NÃO é figurante: o elenco das lições, max/kim, narrador, \'\' e placa', () {
      for (final id in [...elencoDasLicoes, 'max', 'kim', narrador, '', 'placa']) {
        expect(FigurantesHistoria.ehFigurante(id), isFalse, reason: id);
      }
      expect(FigurantesHistoria.ehFigurante('papel-novo'), isTrue);
    });

    test('53 aparências distintas entre si e distintas do elenco (inclusive dos genéricos ele/ela)', () {
      final elenco = {
        for (final id in [..._turismo]) id: ElencoTurismo.de(id)!,
        'ele': ElencoIngles.ele,
        'ela': ElencoIngles.ela,
      };
      final vistas = <String, String>{for (final e in elenco.entries) _assinatura(e.value): e.key};
      for (final id in figurantesConhecidos) {
        final a = FigurantesHistoria.de(id);
        final s = _assinatura(a);
        expect(vistas[s], isNull, reason: '$id saiu igual a ${vistas[s]}');
        vistas[s] = id;
      }
      expect(vistas, hasLength(elenco.length + 53));
    });

    test('a roupa (= a cor do chip) não se confunde: ≥ 30 de distância RGB entre figurantes e do elenco', () {
      final roupas = {
        for (final id in figurantesConhecidos) id: FigurantesHistoria.de(id).roupa,
        for (final id in elencoDasLicoes) id: ElencoTurismo.de(id)!.roupa,
      };
      final ids = roupas.keys.toList();
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          if (elencoDasLicoes.contains(ids[i]) && elencoDasLicoes.contains(ids[j])) continue; // cânone de antes
          expect(_distancia(roupas[ids[i]]!, roupas[ids[j]]!), greaterThanOrEqualTo(30),
              reason: '${ids[i]} × ${ids[j]}');
        }
      }
    });

    test('chip do nome legível em todo figurante (contraste ≥ 4.4, a mesma régua do elenco)', () {
      for (final id in figurantesConhecidos) {
        final cor = ElencoTurismo.corDe(id);
        expect(cor, FigurantesHistoria.de(id).roupa, reason: id);
        expect(BalaoFala.contraste(BalaoFala.textoNoChip(cor), cor), greaterThanOrEqualTo(4.4), reason: id);
      }
    });

    test('uniformes: crachá em quem atende, jaleco na farmacêutica, gorro na motorista', () {
      for (final id in ['atendente', 'recepcionista', 'caixa', 'vendedor', 'vendedora', 'garcom', 'seguranca', 'oficial']) {
        final a = FigurantesHistoria.de(id);
        expect(a.detalhe, isNotNull, reason: '$id: crachá no cordão');
        expect(a.gorro, isFalse, reason: '$id: detalhe com gorro vira cachecol');
      }
      expect(FigurantesHistoria.de('farmaceutica').jaleco, isTrue);
      expect(FigurantesHistoria.de('motorista').gorro, isTrue);
      expect(FigurantesHistoria.de('motorista').detalhe, isNull, reason: 'sem cachecol do Ben');
      // jaleco e gorro continuam marcas do cânone: só esses figurantes os usam
      expect([for (final id in figurantesConhecidos) if (FigurantesHistoria.de(id).jaleco) id], ['farmaceutica']);
      expect([for (final id in figurantesConhecidos) if (FigurantesHistoria.de(id).gorro) id], ['motorista']);
      expect([for (final id in figurantesConhecidos) if (FigurantesHistoria.de(id).flor || FigurantesHistoria.de(id).fone) id],
          isEmpty, reason: 'flor é da Ana; fone é do aluno e da Kim');
    });

    test('o gênero segue a voz do papel (cílios = rosto feminino)', () {
      // voz feminina no vozes_google.py (inclui a motorista e a participante, que são neutras na palavra)
      const delas = {
        'atendente', 'convidada', 'corretora', 'desenvolvedora', 'dev-nova', 'diretora', 'engenheira', 'estagiaria',
        'farmaceutica', 'gestora', 'moradora', 'motorista', 'participante', 'passageira', 'recepcionista',
        'recrutadora', 'supervisora', 'vizinha', 'vendedora', 'esposa',
        'presidente', 'advogada', 'economista', 'pesquisadora', 'consultora', 'prima', 'tia', 'mae',
      };
      for (final id in figurantesConhecidos) {
        expect(FigurantesHistoria.de(id).cilios, delas.contains(id), reason: id);
      }
      expect(FigurantesHistoria.de('guia').cilios, isFalse, reason: 'a guia fala com voz de homem');
    });

    test('o corpo do palco desenha todos os 53 sem exceção', () {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      for (final id in figurantesConhecidos) {
        final a = FigurantesHistoria.de(id);
        CorpoPainter(aparencia: a, pose: const PoseAtor(), frente: false, reduzir: false)
            .paint(c, const Size(120, 240));
        CorpoPainter(aparencia: a, pose: const PoseAtor(), frente: true, reduzir: false)
            .paint(c, const Size(120, 240));
        PersonagemPainter(a, expressao: Expressao.feliz).paint(c, const Size.square(120));
      }
      rec.endRecording().dispose();
    });
  });

  group('papel novo (fora da tabela): paleta por hash estável', () {
    test('FNV-1a de 32 bits (vetores conhecidos)', () {
      expect(FigurantesHistoria.fnv1a(''), 0x811C9DC5);
      expect(FigurantesHistoria.fnv1a('a'), 0xE40C292C);
      expect(FigurantesHistoria.fnv1a('foobar'), 0xBF9CF968);
      expect(FigurantesHistoria.fnv1a('ção'), 0xF14C8E1E, reason: 'sobre os bytes UTF-8');
    });

    test('valores fixos para 3 papéis inventados (não muda entre execuções nem plataformas)', () {
      final astronauta = FigurantesHistoria.de('astronauta');
      expect(FigurantesHistoria.fnv1a('astronauta'), 0xB12F9017);
      expect(astronauta.pele, const Color(0xFFB57A55));
      expect(astronauta.cabelo, const Color(0xFF1E1A1A));
      expect(astronauta.roupa, const Color(0xFF8AC926));
      expect(astronauta.estilo, Cabelo.franja);
      expect(astronauta.cilios, isTrue, reason: 'neutro: o gênero sai do hash');

      final bibliotecaria = FigurantesHistoria.de('bibliotecaria');
      expect(FigurantesHistoria.fnv1a('bibliotecaria'), 0xFCCB246B);
      expect(bibliotecaria.pele, const Color(0xFF8D5A3B));
      expect(bibliotecaria.roupa, const Color(0xFF4CC9F0));
      expect(bibliotecaria.estilo, Cabelo.coque);
      expect(bibliotecaria.brincos, isTrue);

      final pescador = FigurantesHistoria.de('pescador');
      expect(FigurantesHistoria.fnv1a('pescador'), 0xA9F7EDB0);
      expect(pescador.pele, const Color(0xFFFFDCC4));
      expect(pescador.cabelo, const Color(0xFFE3B35A));
      expect(pescador.roupa, const Color(0xFF6A4C93));
      expect(pescador.estilo, Cabelo.cacheado);
      expect(pescador.cilios, isFalse, reason: '-or: masculino, como na voz');
    });

    test('não nulo, estável e com chip legível para 200 papéis inventados', () {
      for (var i = 0; i < 200; i++) {
        final id = 'papel-$i';
        final a = FigurantesHistoria.de(id);
        expect(_assinatura(FigurantesHistoria.de(id)), _assinatura(a), reason: id);
        expect(ElencoTurismo.de(id), isNotNull, reason: id);
        final cor = ElencoTurismo.corDe(id);
        expect(BalaoFala.contraste(BalaoFala.textoNoChip(cor), cor), greaterThanOrEqualTo(4.4), reason: id);
      }
    });
  });

  group('rótulos do chip', () {
    test('a tabela e o padrão (- vira espaço, 1ª maiúscula)', () {
      const esperados = {
        'dev-novo': 'Dev novo',
        'dev-nova': 'Dev nova',
        'dev-junior': 'Dev júnior',
        'dev-pleno': 'Dev pleno',
        'amigo-do-ben': 'Amigo do Ben',
        'cfo': 'CFO',
        'estagiaria': 'Estagiária',
        'farmaceutica': 'Farmacêutica',
        'proprietario': 'Proprietário',
        'seguranca': 'Segurança',
        'garcom': 'Garçom',
        'atendente': 'Atendente',
        'recepcionista': 'Recepcionista',
        'stakeholder': 'Stakeholder',
        'papel-novo-aqui': 'Papel novo aqui',
      };
      for (final e in esperados.entries) {
        expect(FigurantesHistoria.rotulo(e.key), e.value, reason: e.key);
        expect(ElencoTurismo.nomeDe(e.key), e.value, reason: e.key);
      }
      expect(FigurantesHistoria.rotulo(''), '');
    });

    test('nenhum rótulo de figurante com hífen ou começando em minúscula', () {
      for (final id in figurantesConhecidos) {
        final r = ElencoTurismo.nomeDe(id);
        expect(r.contains('-'), isFalse, reason: id);
        expect(r[0], r[0].toUpperCase(), reason: id);
      }
    });

    test('placa → 🪧; o elenco continua com os nomes de sempre', () {
      expect(ElencoTurismo.nomeDe('placa'), '🪧');
      expect(ElencoTurismo.nomeDe('dra-lee'), 'Dra. Lee');
      expect(ElencoTurismo.nomeDe(''), '');
    });
  });

  group('o currículo inteiro (assets/ingles/curriculo.json)', () {
    test('796 lições lidas', () => expect(licoes, hasLength(796)));

    test('todo quem do currículo tem corpo no palco (exceto \'\'/placa), e nenhum papel cai no hash', () {
      for (final q in papeis) {
        if (quemNoPalco(q) == narrador) continue; // '', placa e a narradora dos contos
        expect(ElencoTurismo.de(quemNoPalco(q)), isNotNull, reason: q);
        expect(elencoDasLicoes.contains(q) || figurantesConhecidos.contains(q), isTrue,
            reason: "papel '$q' fora da tabela: acrescentar em figurantesConhecidos e no FigurantesHistoria");
      }
      expect(ElencoTurismo.de(quemNoPalco('placa')), isNull, reason: 'placa → narrador, sem corpo');
      expect(ElencoTurismo.de(quemNoPalco('')), isNull);
    });

    test('em cada uma das 796 lições, personagens diferentes têm aparência diferente', () {
      for (final l in licoes) {
        final quem = {
          for (final t in l.trechos)
            if (quemNoPalco(t.quem) != narrador) t.quem,
        };
        final porAssinatura = <String, String>{};
        for (final q in quem) {
          final s = _assinatura(ElencoTurismo.de(q)!);
          expect(porAssinatura[s], isNull, reason: '${l.id}: $q igual a ${porAssinatura[s]}');
          porAssinatura[s] = q;
        }
      }
    });

    test('com até 2 figurantes mudos (D20), a lição continua sem clones', () {
      // o pior caso: a lição com mais figurantes falando + 2 mudos quaisquer da lista
      for (final l in licoes) {
        final quem = {for (final t in l.trechos) if (quemNoPalco(t.quem) != narrador) t.quem};
        final mudos = figurantesConhecidos.where((f) => !quem.contains(f)).take(2);
        final todos = {...quem, ...mudos};
        final assinaturas = {for (final q in todos) _assinatura(ElencoTurismo.de(q)!)};
        expect(assinaturas, hasLength(todos.length), reason: l.id);
      }
    });
  });

  group('Turismo: os 11 + narrador com a saída idêntica à de antes', () {
    test('de: as mesmas instâncias', () {
      expect(ElencoTurismo.de('voce'), same(ElencoIngles.voce));
      expect(ElencoTurismo.de('mike'), same(ElencoIngles.mike));
      expect(ElencoTurismo.de('sarah'), same(ElencoIngles.sarah));
      expect(ElencoTurismo.de('ana'), same(ElencoIngles.ana));
      expect(ElencoTurismo.de('ben'), same(ElencoIngles.ben));
      expect(ElencoTurismo.de('emma'), same(ElencoIngles.emma));
      expect(ElencoTurismo.de('lucas'), same(ElencoIngles.lucas));
      expect(ElencoTurismo.de('julia'), same(ElencoIngles.julia));
      expect(ElencoTurismo.de('dra-lee'), same(ElencoIngles.draLee));
      expect(ElencoTurismo.de('max'), same(ElencoTurismo.max));
      expect(ElencoTurismo.de('kim'), same(ElencoTurismo.kim));
      expect(ElencoTurismo.de(narrador), isNull);
      for (final id in _turismo) {
        expect(FigurantesHistoria.ehFigurante(id), isFalse, reason: id);
      }
    });

    test('nomeDe: os mesmos rótulos', () {
      const nomes = {
        'voce': 'Você',
        'mike': 'Mike',
        'sarah': 'Sarah',
        'ana': 'Ana',
        'ben': 'Ben',
        'emma': 'Emma',
        'lucas': 'Lucas',
        'julia': 'Julia',
        'dra-lee': 'Dra. Lee',
        'max': 'Max',
        'kim': 'Kim',
        narrador: 'Narrador',
      };
      for (final e in nomes.entries) {
        expect(ElencoTurismo.nomeDe(e.key), e.value, reason: e.key);
      }
    });

    test('corDe: a roupa de cada um; narrador 0xFF3A2A33', () {
      const cores = {
        'voce': Color(0xFF6C5CE7),
        'mike': Color(0xFF34558B),
        'sarah': Color(0xFFFF7F6E),
        'ana': Color(0xFFFFC233),
        'ben': Color(0xFFC0392B),
        'emma': Color(0xFF2BA39A),
        'lucas': Color(0xFF4CAF6E),
        'julia': Color(0xFFB98AE0),
        'dra-lee': Color(0xFF7FB8E8),
        'max': Color(0xFF26262E),
        'kim': Color(0xFFE84393),
        narrador: Color(0xFF3A2A33),
      };
      for (final e in cores.entries) {
        expect(ElencoTurismo.corDe(e.key), e.value, reason: e.key);
      }
    });

    test('perfilDeVoz: os mesmos tons e variantes; figurante usa o padrão', () {
      const vozes = {
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
      for (final e in vozes.entries) {
        expect(ElencoTurismo.perfilDeVoz(e.key), e.value, reason: e.key);
      }
      expect(ElencoTurismo.perfilDeVoz('atendente'), PerfilVoz.padrao, reason: 'a voz das lições é a do Ouvir');
    });

    test('carroDe não muda', () {
      expect(ElencoTurismo.carroDe('max'), PropHistoria.carroRival);
      for (final id in _turismo.where((id) => id != 'max')) {
        expect(ElencoTurismo.carroDe(id), PropHistoria.carro, reason: id);
      }
    });
  });
}
