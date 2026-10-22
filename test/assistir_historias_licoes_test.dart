import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/historias_licoes_repo.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historias_licoes.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart' show chaveDaFrase;
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';

/// 📺 O serviço das historinhas (plano §6.9, I6): `para` síncrono, a autoral só depois de carregar e só na
/// FRONTEIRA da faixa, a pré-carga da trilha seguinte, a lição ruim caindo sozinha na automática, a tabela
/// `encenacao_auto.json` e o "carregando" dos 400 ms do palco.

/// Um bundle falso: conta os pedidos e pode segurar um arquivo até o teste soltar.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.arquivos);

  final Map<String, String> arquivos;
  final pedidos = <String>[];
  final portoes = <String, Completer<void>>{};

  @override
  Future<ByteData> load(String key) async {
    pedidos.add(key);
    final portao = portoes[key];
    if (portao != null) await portao.future;
    final s = arquivos[key];
    if (s == null) throw StateError('asset $key ausente');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(s)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    expect(cache, isFalse, reason: 'o repo pede cache:false ($key)');
    final b = await load(key);
    return utf8.decode(b.buffer.asUint8List(b.offsetInBytes, b.lengthInBytes));
  }
}

final _trilhas = (jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
    .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
    .toList();

const _oi = 'primeiro-contato.oi-tudo-bem';
const _prazer = 'primeiro-contato.prazer-ate-amanha';
const _treze = 'numeros-horas-soletrar.treze-a-dezenove-o-teen';

String _arq(String slug) => '${HistoriasLicoesRepo.pasta}$slug.json';

Licao _licao(String id) => _trilhas.expand((t) => t.licoes).firstWhere((l) => l.id == id);

Faixa _faixa(String licaoId, int i) {
  final t = _licao(licaoId).trechos[i];
  return Faixa(chave: chaveDaFrase(t), en: t.cod, pt: t.dicaPlana, quem: t.quem, licaoId: licaoId);
}

/// A trilha `primeiro-contato` com a história autoral de `oi-tudo-bem` (o exemplo §5.4 do plano) e uma
/// lição QUEBRADA (`prazer-ate-amanha`, com uma frase que não existe), que tem de cair na automática.
const _primeiroContato = '''
{
  "versao": 1,
  "trilha": "primeiro-contato",
  "arco": "Primeira semana com o time.",
  "licoes": {
    "primeiro-contato.oi-tudo-bem": {
      "titulo": { "en": "The first call", "pt": "A primeira chamada" },
      "cenas": [
        {
          "cenario": "videochamada", "hora": "dia", "clima": [],
          "elenco": [
            { "quem": "voce", "pos": "centroEsquerda", "segura": "cafe", "emocao": "nervoso" },
            { "quem": "mike", "pos": "centroDireita", "emocao": "feliz" },
            { "quem": "ana", "pos": "direita", "visivel": false }
          ],
          "objetos": [],
          "passos": [
            { "frase": "f-ceea0d", "acao": "acena", "emocao": "feliz", "camera": "medio" },
            { "frase": "f-138833", "acao": "acena", "emocao": "radiante" },
            { "frase": "f-cddcb0", "acao": "concorda", "emocao": "feliz",
              "reacoes": [ { "quem": "mike", "emocao": "feliz" } ] },
            { "frase": "f-0f3970", "acao": "concorda" },
            { "mudo": true, "quem": "ana", "acao": "entra", "emocao": "feliz" },
            { "frase": "f-34d001", "acao": "acena", "alvo": "ana", "camera": "geral" },
            { "frase": "f-e15dec", "acao": "acena", "emocao": "feliz" },
            { "frase": "f-3a3e3a", "emocao": "feliz" },
            { "frase": "f-f9d8da", "acao": "aponta", "alvo": "mike",
              "reacoes": [ { "quem": "mike", "acao": "concorda" } ] }
          ]
        }
      ]
    },
    "primeiro-contato.prazer-ate-amanha": {
      "titulo": { "en": "Broken", "pt": "Quebrada" },
      "cenas": [
        { "cenario": "videochamada", "hora": "dia",
          "elenco": [ { "quem": "voce", "pos": "centro" } ],
          "passos": [ { "frase": "f-nao-existe" } ] }
      ]
    }
  }
}''';

const _numeros = '{"versao":1,"trilha":"numeros-horas-soletrar","licoes":{}}';
const _euEVoce = '{"versao":1,"trilha":"eu-e-voce-be","licoes":{}}';
const _indice = '{"versao":1,"trilhas":{"primeiro-contato":1,"numeros-horas-soletrar":1,"eu-e-voce-be":1}}';
const _tabela = '{"versao":1,"licoes":{"$_treze":{"cenario":"restaurante","hora":"noite"}}}';

_Bundle _bundle({bool comTabela = false}) => _Bundle({
      HistoriasLicoesRepo.indice: _indice,
      if (comTabela) HistoriasLicoesRepo.encenacao: _tabela,
      _arq('primeiro-contato'): _primeiroContato,
      _arq('numeros-horas-soletrar'): _numeros,
      _arq('eu-e-voce-be'): _euEVoce,
    });

/// Deixa as futures do bundle andarem (sem relógio: tudo são microtarefas).
Future<void> _assentar() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  // os avisos do serviço (arquivo ausente, lição descartada) são esperados aqui: sem barulho no log
  final debugPrintOriginal = debugPrint;
  setUp(() {
    HistoriasLicoesRepo.limparCache();
    debugPrint = (String? m, {int? wrapWidth}) {};
  });
  tearDown(() => debugPrint = debugPrintOriginal);

  test('de() é memoizado por identical(trilhas)', () {
    final a = HistoriasLicoes.de(_trilhas);
    expect(HistoriasLicoes.de(_trilhas), same(a));
    expect(HistoriasLicoes.de(List.of(_trilhas)), isNot(same(a)));
  });

  test('para é síncrono: faixa de lição → automática; órfã, desconhecida ou de trilha própria → null', () {
    final h = HistoriasLicoes(_trilhas, bundle: _bundle());
    final auto = h.para(_faixa(_oi, 0))!;
    expect(auto.autoral, isFalse);
    expect(auto.licaoId, _oi);
    expect(auto.ancoras, contains(_faixa(_oi, 0).chave));
    expect(h.para(const Faixa(chave: 'x', en: 'Hello.')), isNull);
    expect(h.para(const Faixa(chave: 'x', en: 'Hello.', licaoId: 'nao.existe')), isNull);
    // a trilha própria (texto colado) não tem desenho, mesmo com um id de lição
    const propria = Trilha(nivel: 'Meu texto', emoji: '📝', textoId: 't1', licoes: [
      Licao(nome: 'Parte 1', emoji: '📝', id: 'meu-texto.parte-1', trechos: [
        Trecho(id: 'f-p1', cod: 'My text.', dica: 'Meu texto.', out: ''),
      ]),
    ]);
    final soPropria = HistoriasLicoes(const [propria], bundle: _bundle());
    expect(soPropria.para(const Faixa(chave: 'f-p1', en: 'My text.', licaoId: 'meu-texto.parte-1')), isNull);
    expect(soPropria.carregando('meu-texto.parte-1'), isFalse);
    expect(soPropria.temAutoral('meu-texto.parte-1'), isFalse);
  });

  test('a automática é memoizada por lição (a mesma instância nas faixas da lição)', () {
    final h = HistoriasLicoes(_trilhas, bundle: _bundle());
    final a = h.para(_faixa(_oi, 0));
    expect(h.para(_faixa(_oi, 1)), same(a));
    expect(h.para(_faixa(_oi, 0)), same(a));
  });

  test('a autoral só depois de preparar, e só na FRONTEIRA da faixa (nunca no meio dela)', () async {
    final h = HistoriasLicoes(_trilhas, bundle: _bundle());
    final f0 = _faixa(_oi, 0), f1 = _faixa(_oi, 1);
    final antes = h.para(f0)!;
    expect(antes.autoral, isFalse);
    expect(h.temAutoral(_oi), isFalse);
    await h.preparar(f0);
    expect(h.temAutoral(_oi), isTrue);
    // a mesma faixa continua com a mesma história (o palco pede a cada emissão do Ouvir)
    expect(h.para(f0), same(antes));
    expect(h.para(f0), same(antes));
    // a faixa seguinte já abre a autoral
    final depois = h.para(f1)!;
    expect(depois.autoral, isTrue);
    expect(depois.titulo?.en, 'The first call');
    expect(depois.ancoras[f1.chave], (0, 1));
  });

  test('o palco espiar a faixa seguinte (o plano do vão) não destrava a faixa atual', () async {
    final h = HistoriasLicoes(_trilhas, bundle: _bundle());
    final f = [for (var i = 0; i < 6; i++) _faixa(_oi, i)];
    final atual = h.para(f[0])!;
    final seguinte = h.para(f[1])!;
    await h.preparar(f[0]);
    // no vão da faixa 0 o palco pede a 0 e a 1 várias vezes: as duas ficam como estavam
    for (var i = 0; i < 3; i++) {
      expect(h.para(f[0]), same(atual));
      expect(h.para(f[1]), same(seguinte));
    }
    // a faixa 2 (nunca pedida) já abre a autoral
    expect(h.para(f[2])!.autoral, isTrue);
    // a fila andou; a faixa 0 saiu das fixadas e, ao voltar nela (⏮), também abre a autoral
    h
      ..para(f[3])
      ..para(f[4]);
    expect(h.para(f[0])!.autoral, isTrue);
  });

  test('frase sem âncora na autoral (o currículo ganhou uma frase) → a automática da lição inteira', () async {
    final h = HistoriasLicoes(_trilhas, bundle: _bundle());
    await h.prepararLicao(_oi);
    expect(h.para(_faixa(_oi, 2))!.autoral, isTrue);
    final nova = h.para(const Faixa(chave: 'f-nova', en: 'New line.', licaoId: _oi))!;
    expect(nova.autoral, isFalse);
    expect(nova.licaoId, _oi);
  });

  test('arquivo com uma lição ruim: só ela cai na automática', () async {
    final h = HistoriasLicoes(_trilhas, bundle: _bundle());
    await h.preparar(_faixa(_oi, 0));
    expect(h.temAutoral(_oi), isTrue);
    expect(h.temAutoral(_prazer), isFalse);
    final prazer = h.para(_faixa(_prazer, 0))!;
    expect(prazer.autoral, isFalse);
    expect(prazer.licaoId, _prazer);
    expect(h.para(_faixa(_oi, 3))!.autoral, isTrue);
  });

  test('a próxima trilha do curso é pré-carregada (e só as do índice)', () async {
    final b = _bundle();
    final h = HistoriasLicoes(_trilhas, bundle: b);
    await h.preparar(_faixa(_oi, 0));
    expect(b.pedidos,
        containsAll([HistoriasLicoesRepo.indice, _arq('primeiro-contato'), _arq('numeros-horas-soletrar')]));
    expect(b.pedidos, isNot(contains(_arq('eu-e-voce-be'))), reason: 'só a trilha da faixa e a seguinte');
    // sem chamar de novo: nenhum arquivo pedido duas vezes
    await h.preparar(_faixa(_oi, 1));
    expect(b.pedidos.where((p) => p == _arq('primeiro-contato')), hasLength(1));
  });

  test('para encontra uma trilha do índice ainda não pedida e começa a carregar sozinho', () async {
    final b = _bundle();
    final h = HistoriasLicoes(_trilhas, bundle: b);
    await h.preparar(_faixa(_oi, 0));
    final eu = _trilhas.firstWhere((t) => t.licoes.isNotEmpty && t.licoes.first.id.startsWith('eu-e-voce-be.'));
    final l = eu.licoes.first;
    final t = l.trechos.first;
    expect(h.para(Faixa(chave: chaveDaFrase(t), en: t.cod, licaoId: l.id))!.autoral, isFalse);
    await _assentar();
    expect(b.pedidos, contains(_arq('eu-e-voce-be')));
  });

  test('carregando: verdadeiro enquanto o índice ou o arquivo da trilha estão a caminho', () async {
    final b = _bundle();
    final portaoIndice = b.portoes[HistoriasLicoesRepo.indice] = Completer<void>();
    final portaoTrilha = b.portoes[_arq('primeiro-contato')] = Completer<void>();
    final h = HistoriasLicoes(_trilhas, bundle: b);
    expect(h.carregando(_oi), isFalse, reason: 'ninguém pediu nada ainda');
    final pronto = h.prepararLicao(_oi);
    expect(h.carregando(_oi), isTrue, reason: 'o índice está a caminho');
    portaoIndice.complete();
    await _assentar();
    expect(h.carregando(_oi), isTrue, reason: 'a trilha está no índice e o arquivo não chegou');
    expect(h.para(_faixa(_oi, 0))!.autoral, isFalse);
    portaoTrilha.complete();
    await pronto;
    expect(h.carregando(_oi), isFalse);
    expect(h.temAutoral(_oi), isTrue);
    // a trilha que não está no índice nunca "carrega"
    final eu = _trilhas.firstWhere((t) => t.licoes.isNotEmpty && t.licoes.first.id.startsWith('ele-ela-nos-eles.'));
    expect(h.carregando(eu.licoes.first.id), isFalse);
  });

  test('falha (arquivo ausente) não lança: fica a automática; o próximo preparar tenta de novo', () async {
    final b = _bundle()..arquivos.remove(_arq('primeiro-contato'));
    final h = HistoriasLicoes(_trilhas, bundle: b);
    await h.preparar(_faixa(_oi, 0));
    expect(h.temAutoral(_oi), isFalse);
    expect(h.carregando(_oi), isFalse, reason: 'falhou: o palco não espera');
    expect(h.para(_faixa(_oi, 1))!.autoral, isFalse);
    // o `para` não martela o arquivo que falhou
    final pedidos = b.pedidos.where((p) => p == _arq('primeiro-contato')).length;
    h.para(_faixa(_oi, 2));
    await _assentar();
    expect(b.pedidos.where((p) => p == _arq('primeiro-contato')), hasLength(pedidos));
    // o arquivo volta (rede de volta) e o preparar seguinte acha
    b.arquivos[_arq('primeiro-contato')] = _primeiroContato;
    await h.preparar(_faixa(_oi, 0));
    expect(h.temAutoral(_oi), isTrue);
    expect(h.para(_faixa(_oi, 3))!.autoral, isTrue);
  });

  test('sem índice (asset ausente): nada lança e tudo fica na automática', () async {
    final h = HistoriasLicoes(_trilhas, bundle: _Bundle({}));
    await h.preparar(_faixa(_oi, 0));
    await h.preparar(const Faixa(chave: 'x', en: 'Hello.'));
    expect(h.temAutoral(_oi), isFalse);
    expect(h.carregando(_oi), isFalse);
    expect(h.para(_faixa(_oi, 1))!.autoral, isFalse);
  });

  test('a tabela encenacao_auto.json corrige a automática a partir da faixa seguinte', () async {
    final h = HistoriasLicoes(_trilhas, bundle: _bundle(comTabela: true));
    final f0 = _faixa(_treze, 0), f1 = _faixa(_treze, 1);
    expect(h.para(f0)!.cenas.single.cenario, CenarioHistoria.loja, reason: 'a heurística, antes da tabela');
    await h.preparar(f0);
    expect(h.para(f0)!.cenas.single.cenario, CenarioHistoria.loja, reason: 'a mesma faixa não muda');
    final corrigida = h.para(f1)!;
    expect(corrigida.autoral, isFalse);
    expect(corrigida.cenas.single.cenario, CenarioHistoria.restaurante);
    expect(corrigida.cenas.single.hora, HoraHistoria.noite);
  });
}
