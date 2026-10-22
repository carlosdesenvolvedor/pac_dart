// 🎬 O roteiro da cena da frase (o cartão da lição de inglês): SALTA para a âncora da frase pela linha do tempo
// da SimulacaoCena (a escada revisita as frases fora de ordem, sem repassar a história), anima a ação uma vez,
// para sozinho, respeita o "reduzir" e nunca mostra o balão (EN escondido, sem PT, boca só com a voz).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/simulacao_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/roteiro_historia.dart' show EstadoRoteiro;
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/domain/assistir/compasso_assistir.dart';
import 'package:pac_dart/features/ingles/domain/assistir/encenador_licao.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historia_licao.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart' show chaveDaFrase;
import 'package:pac_dart/features/ingles/presentation/widgets/roteiro_da_frase.dart';

final _trilhas = (jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
    .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
    .toList();

const _quarto = 'situacao-hotel.probleminhas-no-quarto';

/// A história AUTORAL de [licaoId] (do arquivo da trilha em assets).
HistoriaLicao _autoral(String licaoId) {
  final slug = slugDaLicao(licaoId);
  final trilha = _trilhas.firstWhere((t) => t.licoes.any((l) => l.id == licaoId));
  final j = jsonDecode(File('assets/ingles/historias/$slug.json').readAsStringSync()) as Map<String, dynamic>;
  return HistoriasDaTrilha.fromJson(j, trilha: trilha, estrito: false).licoes[licaoId]!;
}

Licao _licao(String id) => _trilhas.expand((t) => t.licoes).firstWhere((l) => l.id == id);

/// O que importa de um estado da cena.
Map<String, Object?> _resumo(EstadoCena e) => {
      'cenario': e.cenario,
      'hora': e.hora,
      for (final a in e.atores.values) a.quem: (a.pos, a.visivel, a.emocao, a.segura, a.remoto),
    };

void main() {
  test('salta para a âncora (outra cena e de volta), sem passar pelos passos do meio', () {
    final h = _autoral(_quarto);
    expect(h.cenas.length, 2, reason: 'a fixture tem duas cenas');
    final linhas = [for (final c in h.cenas) SimulacaoCena.linhaDoTempo(c)];
    final trechos = _licao(_quarto).trechos;
    final ancoras = [for (final t in trechos) h.ancoras[chaveDaFrase(t)]!];
    final naCena1 = ancoras.lastWhere((a) => a.$1 == 1 && a.$2 > 0);
    final naCena0 = ancoras.firstWhere((a) => a.$1 == 0 && a.$2 > 0);

    final r = RoteiroDaFrase();
    var avisos = 0;
    r.addListener(() => avisos++);
    r.irPara(h, naCena1);
    expect(avisos, 1);
    expect((r.cena, r.passo), naCena1);
    expect(r.tPasso, 0);
    expect(_resumo(r.antes), _resumo(linhas[1][naCena1.$2]), reason: 'já com as entradas dos passos de antes');
    expect(_resumo(r.depois), _resumo(linhas[1][naCena1.$2 + 1]));
    expect(r.falaAtual, same(h.cenas[1].falas[naCena1.$2]));
    expect(r.en, h.cenas[1].falas[naCena1.$2].en);

    // a escada volta a uma frase de antes (outra cena): direto no estado dela
    r.tick(1);
    r.irPara(h, naCena0);
    expect((r.cena, r.passo), naCena0);
    expect(r.tPasso, 0);
    expect(_resumo(r.antes), _resumo(linhas[0][naCena0.$2]));
    expect(_resumo(r.depois), _resumo(linhas[0][naCena0.$2 + 1]));
    expect(r.falaAnterior, same(h.cenas[0].falas[naCena0.$2 - 1]));

    // a mesma frase de novo: a ação recomeça (uma vez)
    r.tick(1.5);
    expect(r.tPasso, 1.5);
    r.irPara(h, naCena0);
    expect(r.tPasso, 0);
  });

  test('a ação anima uma vez e para (o relógio pode parar); o último tique fecha na pose final', () {
    final h = _autoral(_quarto);
    final a = h.ancoras[chaveDaFrase(_licao(_quarto).trechos.first)]!;
    final f = h.cenas[a.$1].falas[a.$2];
    final r = RoteiroDaFrase()..irPara(h, a);
    expect(r.animacao, closeTo(CompassoAssistir.duracaoMuda(f).clamp(2.6, double.infinity) + .4, 1e-9));
    var avisos = 0;
    r.addListener(() => avisos++);
    expect(r.animando, isTrue);
    var t = 0.0;
    while (r.animando && t < 20) {
      expect(r.tick(.1), isTrue);
      t += .1;
    }
    expect(r.animando, isFalse);
    expect(r.tPasso, closeTo(r.animacao, 1e-9));
    final depois = avisos;
    expect(r.tick(.1), isFalse, reason: 'parado: nenhum aviso (nenhum quadro)');
    expect(avisos, depois);
  });

  test('reduzir: já no estado final (sem animar), também ao ligar no meio', () {
    final h = EncenadorLicao.encenar(_licao('primeiro-contato.oi-tudo-bem'), etapa: 'A1 · Fundação');
    final a = h.ancoras.values.first;
    final r = RoteiroDaFrase(reduzir: true)..irPara(h, a);
    expect(r.animando, isFalse);
    expect(r.tPasso, r.animacao);
    final r2 = RoteiroDaFrase()..irPara(h, a);
    expect(r2.animando, isTrue);
    r2.reduzir = true;
    expect(r2.animando, isFalse);
  });

  test('sem balão: a fala com texto fica em "lendo", a boca só com a voz, EN escondido, sem PT/véu/título', () {
    final h = _autoral(_quarto);
    final trecho = _licao(_quarto).trechos.first;
    final r = RoteiroDaFrase()..irPara(h, h.ancoras[chaveDaFrase(trecho)]!);
    expect(r.estadoVisivel, EstadoRoteiro.lendo);
    expect(r.en, trecho.cod, reason: 'o mesmo texto que a voz da lição fala (lip-sync por texto exato)');
    expect(r.falaComVoz, isTrue);
    expect(r.esconderEn, isTrue);
    expect(r.mostrarPt, isFalse);
    expect(r.noTitulo, isFalse);
    expect(r.escurecimento, 0);
    expect(r.tSaida, isNull);
    expect(r.iconeDaFala, isNull);
    expect(r.tFala, 0);
  });

  test('as âncoras de todas as frases (autoral e automática) caem dentro da história', () {
    for (final id in ['primeiro-contato.oi-tudo-bem', 'situacao-hotel.na-imigracao-o-passaporte', _quarto]) {
      final licao = _licao(id);
      for (final h in [_autoral(id), EncenadorLicao.encenar(licao, etapa: 'A1 · Fundação')]) {
        final r = RoteiroDaFrase();
        for (final t in licao.trechos) {
          final a = h.ancoras[chaveDaFrase(t)];
          expect(a, isNotNull, reason: '$id ${t.id} (${h.autoral ? 'autoral' : 'automática'})');
          r.irPara(h, a!);
          expect(r.en, t.cod, reason: '$id ${t.id}');
        }
      }
    }
  });
}
