// 🎬 `HistoriasLicoes.daLicao`: a história da LIÇÃO para a cena da frase (só leitura). A autoral quando a trilha
// chegou e tem a âncora; a automática sem ela; null fora do curso. Nunca mexe nas faixas fixadas pelo palco do 📺.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/historias_licoes_repo.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historias_licoes.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart' show chaveDaFrase;
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';

/// Os arquivos de verdade (assets/), lidos do disco; [faltando] some (como um asset ausente).
class _Disco extends CachingAssetBundle {
  _Disco({this.faltando = const {}});
  final Set<String> faltando;

  @override
  Future<ByteData> load(String key) async {
    if (faltando.contains(key)) throw StateError('asset $key ausente');
    return ByteData.sublistView(File(key).readAsBytesSync());
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final b = await load(key);
    return utf8.decode(b.buffer.asUint8List(b.offsetInBytes, b.lengthInBytes));
  }
}

final _trilhas = (jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
    .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
    .toList();

const _oi = 'primeiro-contato.oi-tudo-bem';

Licao _licao(String id) => _trilhas.expand((t) => t.licoes).firstWhere((l) => l.id == id);

Faixa _faixa(String licaoId, int i) {
  final t = _licao(licaoId).trechos[i];
  return Faixa(chave: chaveDaFrase(t), en: t.cod, pt: t.dicaPlana, quem: t.quem, licaoId: licaoId);
}

void main() {
  final debugPrintOriginal = debugPrint;
  setUp(() {
    HistoriasLicoesRepo.limparCache();
    debugPrint = (String? m, {int? wrapWidth}) {};
  });
  tearDown(() => debugPrint = debugPrintOriginal);

  test('antes de a trilha chegar: a automática (memo); depois: a autoral com a âncora', () async {
    final h = HistoriasLicoes(_trilhas, bundle: _Disco());
    final chave = chaveDaFrase(_licao(_oi).trechos[2]);
    final auto = h.daLicao(_oi, chave: chave)!;
    expect(auto.autoral, isFalse);
    expect(auto.licaoId, _oi);
    expect(h.daLicao(_oi), same(auto), reason: 'a automática é memoizada por lição');
    await h.prepararLicao(_oi);
    final autoral = h.daLicao(_oi, chave: chave)!;
    expect(autoral.autoral, isTrue);
    expect(autoral.ancoras, contains(chave));
    expect(h.daLicao(_oi), same(autoral));
    // uma frase que a autoral não tem (frase nova no currículo): a automática da lição
    expect(h.daLicao(_oi, chave: 'f-nao-existe')!.autoral, isFalse);
  });

  test('null fora do curso: id vazio, lição desconhecida, trilha própria', () {
    final h = HistoriasLicoes(_trilhas, bundle: _Disco());
    expect(h.daLicao(''), isNull);
    expect(h.daLicao('nao.existe'), isNull);
    const propria = Trilha(nivel: 'Meu texto', emoji: '📝', textoId: 't1', licoes: [
      Licao(nome: 'Parte 1', emoji: '📝', id: 'meu-texto.parte-1', trechos: [
        Trecho(id: 'f-p1', cod: 'My text.', dica: 'Meu texto.', out: ''),
      ]),
    ]);
    expect(HistoriasLicoes(const [propria], bundle: _Disco()).daLicao('meu-texto.parte-1'), isNull);
  });

  test('não mexe nas faixas fixadas do 📺 (a cena da lição pede à vontade)', () async {
    final h = HistoriasLicoes(_trilhas, bundle: _Disco());
    final f = [for (var i = 0; i < 3; i++) _faixa(_oi, i)];
    final fixadas = [for (final x in f) h.para(x)!];
    expect(fixadas.every((x) => !x.autoral), isTrue);
    await h.prepararLicao(_oi);
    // a lição pede a cena de várias frases (e de outras lições) muitas vezes
    for (var i = 0; i < 5; i++) {
      h.daLicao(_oi, chave: f[i % 3].chave);
      h.daLicao('situacao-hotel.na-imigracao-o-passaporte');
      h.daLicao('primeiro-contato.prazer-ate-amanha');
    }
    for (var i = 0; i < 3; i++) {
      expect(h.para(f[i]), same(fixadas[i]), reason: 'a faixa $i continua com a mesma história');
    }
  });

  test('índice indisponível: a automática, sem lançar', () async {
    final h = HistoriasLicoes(_trilhas, bundle: _Disco(faltando: {HistoriasLicoesRepo.indice}));
    await h.prepararLicao(_oi);
    expect(h.carregando(_oi), isFalse);
    expect(h.daLicao(_oi)!.autoral, isFalse);
  });
}
