import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/ingles/data/historias_licoes_repo.dart';
import 'package:pac_dart/features/ingles/data/preferencia_assistir.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 📺 O repositório das historinhas (índice, tabela da encenação e o JSON de cada trilha, sob demanda) e a
/// preferência `en_ouvir_assistir` (plano §6.10, §6.11).

/// Um bundle de mentira: [arquivos] respondem; o resto lança. Conta os pedidos; [travar] nunca responde.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.arquivos);

  final Map<String, String> arquivos;
  final pedidos = <String>[];
  final travar = <String>{};

  @override
  Future<ByteData> load(String key) async {
    pedidos.add(key);
    if (travar.contains(key)) return Completer<ByteData>().future;
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

const _indice = '{"versao":1,"trilhas":{"primeiro-contato":1,"numeros-horas-soletrar":2}}';
const _trilha = '{"versao":1,"trilha":"primeiro-contato","licoes":{}}';
const _tabela = '''
{"versao":1,"licoes":{
  "numeros-horas-soletrar.treze-a-dezenove-o-teen": {"cenario": "loja", "hora": "tarde"},
  "primeiro-contato.nao-entendi-pode-repetir": {"cenario": "videochamada", "hora": "dia", "mudos": ["sarah"]},
  "numeros-horas-soletrar.cem-mil-e-os-precos": {"cenario": "loja", "hora": "dia", "remotos": {"ana": "celular"}},
  "x.enum-ruim": {"cenario": "nave", "hora": "madrugada", "entram": ["ben"]}
}}''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── a preferência com o armazenamento quebrado (antes de qualquer setMockInitialValues) ──
  group('PreferenciaAssistir sem armazenamento', () {
    setUp(() {
      PreferenciaAssistir.reiniciar();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (call) => throw PlatformException(code: 'quebrado'),
      );
    });
    tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/shared_preferences'), null));

    test('erro → false em tudo, sem lançar; o valor fica false no carregar e muda na hora no salvar', () async {
      await PreferenciaAssistir.carregar();
      expect(PreferenciaAssistir.valor.value, isFalse);
      expect(await PreferenciaAssistir.ligado(), isFalse);
      expect(await PreferenciaAssistir.mostrarNovidade(), isFalse);
      await PreferenciaAssistir.marcarNovidadeVista();
      await PreferenciaAssistir.salvar(true);
      expect(PreferenciaAssistir.valor.value, isTrue, reason: 'o salvar atualiza o valor mesmo sem gravar');
      expect(await PreferenciaAssistir.ligado(), isFalse);
    });
  });

  group('PreferenciaAssistir', () {
    setUp(() {
      PreferenciaAssistir.reiniciar();
      SharedPreferences.setMockInitialValues({});
    });

    test('as chaves são do inglês', () {
      expect(PreferenciaAssistir.chave, 'en_ouvir_assistir');
      expect(PreferenciaAssistir.chaveNovidade, 'en_ouvir_assistir_visto');
    });

    test('sem pref: desligado; liga e desliga; o valor muda na hora (antes de gravar)', () async {
      expect(await PreferenciaAssistir.ligado(), isFalse);
      await PreferenciaAssistir.carregar();
      expect(PreferenciaAssistir.valor.value, isFalse);
      final gravando = PreferenciaAssistir.salvar(true);
      expect(PreferenciaAssistir.valor.value, isTrue);
      await gravando;
      expect(await PreferenciaAssistir.ligado(), isTrue);
      expect((await SharedPreferences.getInstance()).getBool('en_ouvir_assistir'), isTrue);
      await PreferenciaAssistir.salvar(false);
      expect(PreferenciaAssistir.valor.value, isFalse);
      expect(await PreferenciaAssistir.ligado(), isFalse);
    });

    test('carregar lê a pref salva uma vez (idempotente)', () async {
      SharedPreferences.setMockInitialValues({'en_ouvir_assistir': true});
      final a = PreferenciaAssistir.carregar();
      expect(identical(a, PreferenciaAssistir.carregar()), isTrue);
      await a;
      expect(PreferenciaAssistir.valor.value, isTrue);
    });

    test('selo "novo" até o 1º uso', () async {
      expect(await PreferenciaAssistir.mostrarNovidade(), isTrue);
      await PreferenciaAssistir.marcarNovidadeVista();
      expect(await PreferenciaAssistir.mostrarNovidade(), isFalse);
    });
  });

  group('HistoriasLicoesRepo', () {
    setUp(HistoriasLicoesRepo.limparCache);

    test('caminhos', () {
      expect(HistoriasLicoesRepo.pasta, 'assets/ingles/historias/');
      expect(HistoriasLicoesRepo.indice, 'assets/ingles/historias/indice.json');
      expect(HistoriasLicoesRepo.encenacao, 'assets/ingles/historias/encenacao_auto.json');
    });

    test('índice ausente → {} sem lançar, e a falha não fica em cache', () async {
      final b = _Bundle({});
      expect(await HistoriasLicoesRepo.trilhasComHistoria(bundle: b), isEmpty);
      b.arquivos[HistoriasLicoesRepo.indice] = _indice;
      expect(await HistoriasLicoesRepo.trilhasComHistoria(bundle: b), {'primeiro-contato': 1, 'numeros-horas-soletrar': 2});
      expect(b.pedidos.where((p) => p == HistoriasLicoesRepo.indice), hasLength(2));
      // sucesso fica em cache
      await HistoriasLicoesRepo.trilhasComHistoria(bundle: b);
      expect(b.pedidos.where((p) => p == HistoriasLicoesRepo.indice), hasLength(2));
    });

    test('índice inválido → {}', () async {
      expect(await HistoriasLicoesRepo.trilhasComHistoria(bundle: _Bundle({HistoriasLicoesRepo.indice: '[1, 2]'})), isEmpty);
      HistoriasLicoesRepo.limparCache();
      expect(await HistoriasLicoesRepo.trilhasComHistoria(bundle: _Bundle({HistoriasLicoesRepo.indice: '{oops'})), isEmpty);
    });

    test('o índice vazio do projeto (Phase 0) é aceito', () async {
      final b = _Bundle({HistoriasLicoesRepo.indice: '{"versao":1,"trilhas":{}}'});
      expect(await HistoriasLicoesRepo.trilhasComHistoria(bundle: b), isEmpty);
    });

    test('trilha: lê o JSON cru da trilha do índice', () async {
      final b = _Bundle({
        HistoriasLicoesRepo.indice: _indice,
        '${HistoriasLicoesRepo.pasta}primeiro-contato.json': _trilha,
      });
      final j = await HistoriasLicoesRepo.trilha('primeiro-contato', bundle: b);
      expect(j, isNotNull);
      expect(j!['trilha'], 'primeiro-contato');
    });

    test('trilha fora do índice → null sem pedir o arquivo', () async {
      final b = _Bundle({HistoriasLicoesRepo.indice: _indice});
      expect(await HistoriasLicoesRepo.trilha('eu-e-voce-be', bundle: b), isNull);
      expect(b.pedidos, [HistoriasLicoesRepo.indice]);
    });

    test('trilha no índice, arquivo ausente ou inválido → null; falha não fica em cache', () async {
      final b = _Bundle({HistoriasLicoesRepo.indice: _indice});
      expect(await HistoriasLicoesRepo.trilha('primeiro-contato', bundle: b), isNull);
      b.arquivos['${HistoriasLicoesRepo.pasta}primeiro-contato.json'] = 'não é json';
      expect(await HistoriasLicoesRepo.trilha('primeiro-contato', bundle: b), isNull);
      b.arquivos['${HistoriasLicoesRepo.pasta}primeiro-contato.json'] = _trilha;
      expect(await HistoriasLicoesRepo.trilha('primeiro-contato', bundle: b), isNotNull);
    });

    test('timeout → null', () async {
      final b = _Bundle({HistoriasLicoesRepo.indice: _indice});
      b.travar.add('${HistoriasLicoesRepo.pasta}numeros-horas-soletrar.json');
      final j = await HistoriasLicoesRepo.trilha('numeros-horas-soletrar',
          bundle: b, timeout: const Duration(milliseconds: 30));
      expect(j, isNull);
    });

    test('índice e tabela travados (a rede não responde nem falha): a trilha estoura e o próximo pedido tenta de novo', () async {
      final b = _Bundle({HistoriasLicoesRepo.indice: _indice, HistoriasLicoesRepo.encenacao: _tabela});
      b.travar.addAll({HistoriasLicoesRepo.indice, HistoriasLicoesRepo.encenacao});
      const curto = Duration(milliseconds: 30);
      expect(await HistoriasLicoesRepo.trilha('primeiro-contato', bundle: b, timeout: curto), isNull,
          reason: 'o índice travado não segura a trilha além do timeout');
      unawaited(HistoriasLicoesRepo.encenacaoAuto(bundle: b, timeout: curto));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(HistoriasLicoesRepo.emVooTravado(timeout: curto), isTrue);
      // a rede volta: o pedido travado é abandonado (não ficou preso no cache)
      b.travar.clear();
      b.arquivos['${HistoriasLicoesRepo.pasta}primeiro-contato.json'] = _trilha;
      expect(await HistoriasLicoesRepo.trilha('primeiro-contato', bundle: b, timeout: curto), isNotNull);
      expect(await HistoriasLicoesRepo.encenacaoAuto(bundle: b, timeout: curto), hasLength(4));
      expect(b.pedidos.where((p) => p == HistoriasLicoesRepo.indice), hasLength(2));
      expect(b.pedidos.where((p) => p == HistoriasLicoesRepo.encenacao), hasLength(2));
      expect(HistoriasLicoesRepo.emVooTravado(timeout: curto), isFalse);
    });

    test('encenacaoAuto: lê a tabela (tolerante nos enums); ausente → {} e tenta de novo', () async {
      final b = _Bundle({});
      expect(await HistoriasLicoesRepo.encenacaoAuto(bundle: b), isEmpty);
      b.arquivos[HistoriasLicoesRepo.encenacao] = _tabela;
      final t = await HistoriasLicoesRepo.encenacaoAuto(bundle: b);
      expect(t, hasLength(4));
      final teen = t['numeros-horas-soletrar.treze-a-dezenove-o-teen']!;
      expect(teen.cenario, CenarioHistoria.loja);
      expect(teen.hora, HoraHistoria.tarde);
      expect(t['primeiro-contato.nao-entendi-pode-repetir']!.mudos, {'sarah'});
      expect(t['numeros-horas-soletrar.cem-mil-e-os-precos']!.remotos, {'ana': ViaRemota.celular});
      final ruim = t['x.enum-ruim']!;
      expect(ruim.cenario, isNull);
      expect(ruim.hora, isNull);
      expect(ruim.entram, {'ben'});
      // em cache depois do sucesso
      final antes = b.pedidos.length;
      await HistoriasLicoesRepo.encenacaoAuto(bundle: b);
      expect(b.pedidos.length, antes);
    });

    test('os assets do projeto existem: o piloto no índice e a tabela com as 602 lições (integração)', () async {
      // o bundle de verdade dos testes lê do disco
      final idx = await HistoriasLicoesRepo.trilhasComHistoria();
      // o índice cresce a cada lote escrito (A1 inteiro já está lá): só o
      // piloto é fixo, e toda trilha listada tem versão ≥ 1 e um arquivo
      expect(idx, containsPair('primeiro-contato', 1));
      expect(idx, containsPair('numeros-horas-soletrar', 1));
      for (final e in idx.entries) {
        expect(e.value, greaterThanOrEqualTo(1), reason: e.key);
        final t = await HistoriasLicoesRepo.trilha(e.key);
        expect(t, isNotNull, reason: 'assets/ingles/historias/${e.key}.json');
      }
      expect(await HistoriasLicoesRepo.encenacaoAuto(), hasLength(602));
    });
  });
}
