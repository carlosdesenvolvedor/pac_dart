import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/historias_licoes_repo.dart';
import 'package:pac_dart/features/ingles/domain/assistir/encenador_licao.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historia_licao.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historias_licoes.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart' show chaveDaFrase;
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';

/// 📺 O conteúdo das historinhas das lições (plano §9, integração): tudo o que está em
/// `assets/ingles/historias/` passa no validador OFICIAL do Dart contra o currículo real. É o teste que a
/// receita dos lotes manda rodar depois de copiar uma trilha nova (RECEITA §10.2 passo 6).

const _pasta = 'assets/ingles/historias';

final _trilhas = (jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
    .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
    .toList();

/// slug → trilha do curso (a própria não tem desenho).
final _porSlug = {
  for (final t in _trilhas)
    if (!t.propria && t.licoes.isNotEmpty) slugDaLicao(t.licoes.first.id): t,
};

final _licoesDoCurso = {
  for (final t in _porSlug.values)
    for (final l in t.licoes)
      if (l.id.isNotEmpty) l.id: (t: t, l: l),
};

Map<String, dynamic> _json(String nome) =>
    jsonDecode(File('$_pasta/$nome').readAsStringSync()) as Map<String, dynamic>;

/// Os arquivos de trilha presentes na pasta (tudo menos o índice e a tabela).
List<String> _arquivosDeTrilha() {
  final nomes = [
    for (final f in Directory(_pasta).listSync().whereType<File>())
      f.uri.pathSegments.last,
  ]..sort();
  return [
    for (final n in nomes)
      if (n.endsWith('.json') && n != 'indice.json' && n != 'encenacao_auto.json') n,
  ];
}

T? _porNome<T extends Enum>(List<T> valores, Object? v) {
  for (final e in valores) {
    if (e.name == v) return e;
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('o currículo tem as 602 lições do curso (a base dos testes abaixo)', () {
    expect(_licoesDoCurso.length, 602);
  });

  test('a pasta é declarada no pubspec (senão o app nunca acha os arquivos)', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/ingles/historias/'));
    expect(HistoriasLicoesRepo.pasta, '$_pasta/');
  });

  group('indice.json', () {
    test('versão 1 e lista EXATAMENTE os arquivos de trilha presentes', () {
      final j = _json('indice.json');
      expect(j.keys.toSet(), {'versao', 'trilhas'});
      expect(j['versao'], 1);
      final trilhas = (j['trilhas'] as Map).cast<String, Object?>();
      expect(trilhas.keys.toSet(), {for (final n in _arquivosDeTrilha()) n.substring(0, n.length - 5)},
          reason: 'cada trilha do índice tem o seu arquivo e cada arquivo está no índice');
      for (final e in trilhas.entries) {
        expect(e.value, isA<int>(), reason: '${e.key}: a versão do arquivo é inteira');
        expect(e.value as int, greaterThanOrEqualTo(1), reason: e.key);
        expect(_porSlug, contains(e.key), reason: '${e.key}: não é uma trilha do curso');
      }
    });

    test('o piloto (fase 1) está lá', () {
      final trilhas = (_json('indice.json')['trilhas'] as Map).keys;
      expect(trilhas, containsAll(['primeiro-contato', 'numeros-horas-soletrar']));
    });
  });

  group('arquivos de trilha', () {
    final arquivos = _arquivosDeTrilha();

    test('há pelo menos o piloto', () {
      expect(arquivos, containsAll(['primeiro-contato.json', 'numeros-horas-soletrar.json']));
    });

    for (final nome in arquivos) {
      test('$nome: parse estrito + validarHistoriasDaTrilha sem erro', () {
        final slug = nome.substring(0, nome.length - 5);
        final trilha = _porSlug[slug];
        expect(trilha, isNotNull, reason: "'$slug' não é o slug de uma trilha do curso");
        final j = _json(nome);
        expect(j['trilha'], slug, reason: 'o campo trilha = o nome do arquivo');
        final h = HistoriasDaTrilha.fromJson(j, trilha: trilha!, estrito: true);
        final avisos = <String>[];
        expect(validarHistoriasDaTrilha(h, trilha, avisos: avisos), isEmpty);
        expect(h.licoes, isNotEmpty);
        for (final hl in h.licoes.values) {
          expect(hl.autoral, isTrue);
          expect(hl.titulo, isNotNull, reason: '${hl.licaoId}: a autoral tem título (selo ✨, D21)');
          // Toda frase da lição tem âncora (o 📺 nunca cai na automática por falta de frase).
          final licao = _licoesDoCurso[hl.licaoId]!.l;
          expect(hl.ancoras.keys.toList(), [for (final t in licao.trechos) chaveDaFrase(t)], reason: hl.licaoId);
          // Nada do Turismo nas lições.
          for (final c in hl.cenas) {
            expect(cenariosSoDoTurismo, isNot(contains(c.cenario)), reason: hl.licaoId);
            for (final a in c.elenco) {
              expect(const {'max', 'kim'}, isNot(contains(a.quem)), reason: hl.licaoId);
            }
          }
        }
        // O modo do app (tolerante) não descarta nenhuma lição boa.
        final motivos = <String>[];
        final tolerante = HistoriasDaTrilha.fromJson(j, trilha: trilha, estrito: false, aviso: motivos.add);
        expect(motivos, isEmpty);
        expect(tolerante.licoes.keys.toSet(), h.licoes.keys.toSet());
      });
    }

    test('o piloto cobre as 12 lições das trilhas 1 e 2 (plano §17)', () {
      final ids = <String>{};
      for (final slug in ['primeiro-contato', 'numeros-horas-soletrar']) {
        final h = HistoriasDaTrilha.fromJson(_json('$slug.json'), trilha: _porSlug[slug]!);
        ids.addAll(h.licoes.keys);
        expect(h.licoes.keys.toSet(), {for (final l in _porSlug[slug]!.licoes) l.id}, reason: slug);
      }
      expect(ids.length, 12);
    });
  });

  group('encenacao_auto.json', () {
    final j = _json('encenacao_auto.json');
    final licoes = (j['licoes'] as Map).cast<String, Object?>();

    test('versão 1 e uma entrada para CADA uma das 602 lições, só ids que existem', () {
      expect(j.keys.toSet(), {'versao', 'licoes'});
      expect(j['versao'], 1);
      expect(licoes.keys.where((id) => !_licoesDoCurso.containsKey(id)), isEmpty);
      expect(licoes.keys.toSet(), _licoesDoCurso.keys.toSet());
    });

    test('enums válidos, nada do Turismo, hora permitida, listas de quem existe', () {
      final erros = <String>[];
      for (final e in licoes.entries) {
        final id = e.key;
        final m = (e.value as Map).cast<String, Object?>();
        final desconhecidas = m.keys.toSet().difference(const {'cenario', 'hora', 'remotos', 'entram', 'mudos'});
        if (desconhecidas.isNotEmpty) erros.add('$id: chaves desconhecidas $desconhecidas');
        final cenario = _porNome(CenarioHistoria.values, m['cenario']);
        final hora = _porNome(HoraHistoria.values, m['hora']);
        if (cenario == null) erros.add("$id: cenario '${m['cenario']}' inválido");
        if (hora == null) erros.add("$id: hora '${m['hora']}' inválida");
        if (cenario != null && cenariosSoDoTurismo.contains(cenario)) erros.add('$id: cenário do Turismo');
        if (cenario != null && hora != null && !horasPermitidas(cenario).contains(hora)) {
          erros.add('$id: hora ${hora.name} não permitida em ${cenario.name}');
        }
        final falam = {for (final t in _licoesDoCurso[id]!.l.trechos) quemNoPalco(t.quem)};
        final remotos = m['remotos'];
        if (remotos != null) {
          if (remotos is! Map) {
            erros.add('$id: remotos não é objeto');
          } else {
            for (final r in remotos.entries) {
              if (_porNome(ViaRemota.values, r.value) == null) erros.add("$id: via '${r.value}' inválida");
              if (!falam.contains(r.key) && !elencoDasLicoes.contains(r.key)) {
                erros.add("$id: remoto '${r.key}' fora do elenco");
              }
            }
          }
        }
        for (final campo in ['entram', 'mudos']) {
          final v = m[campo];
          if (v == null) continue;
          if (v is! List || v.any((x) => x is! String)) {
            erros.add('$id: $campo não é lista de ids');
            continue;
          }
          for (final q in v.cast<String>()) {
            final valido = elencoDasLicoes.contains(q) || falam.contains(q) || figurantesConhecidos.contains(q);
            if (!valido || q == 'max' || q == 'kim') erros.add("$id: $campo '$q' fora do elenco");
          }
        }
      }
      expect(erros, isEmpty);
    });

    test('com a tabela, as 602 encenações automáticas validam e respeitam o cenário/hora da tabela', () {
      final problemas = <String>[];
      for (final e in licoes.entries) {
        final (:t, :l) = _licoesDoCurso[e.key]!;
        final manual = EncenacaoManual.fromJson((e.value as Map).cast<String, dynamic>());
        final h = EncenadorLicao.encenar(l, etapa: t.etapa, manual: manual);
        final erros = validarHistoriaLicao(h, l);
        if (erros.isNotEmpty) problemas.add('${e.key}: ${erros.first}');
        if (h.cenas.first.cenario != manual.cenario) problemas.add('${e.key}: cenário ≠ tabela');
        if (h.cenas.first.hora != manual.hora) problemas.add('${e.key}: hora ≠ tabela');
      }
      expect(problemas, isEmpty);
    });
  });

  group('pelo bundle de verdade (o caminho do app)', () {
    Faixa faixaDe(String licaoId, int i) {
      final (:t, :l) = _licoesDoCurso[licaoId]!;
      final tr = l.trechos[i];
      return Faixa(
        chave: chaveDaFrase(tr),
        en: tr.cod,
        quem: tr.quem,
        licaoId: l.id,
        licaoNome: l.nome,
        etapa: t.etapa,
      );
    }

    test('o índice, a tabela e a trilha do piloto chegam pelo rootBundle', () async {
      HistoriasLicoesRepo.limparCache();
      final indice = await HistoriasLicoesRepo.trilhasComHistoria(bundle: rootBundle);
      expect(indice.keys, containsAll(['primeiro-contato', 'numeros-horas-soletrar']));
      final tabela = await HistoriasLicoesRepo.encenacaoAuto(bundle: rootBundle);
      expect(tabela.length, 602);
      final pc = await HistoriasLicoesRepo.trilha('primeiro-contato', bundle: rootBundle);
      expect(pc?['trilha'], 'primeiro-contato');
      HistoriasLicoesRepo.limparCache();
    });

    test('preparar → a 1ª faixa do piloto já sai autoral; uma lição fora do piloto sai automática com a tabela',
        () async {
      HistoriasLicoesRepo.limparCache();
      final s = HistoriasLicoes(_trilhas, bundle: rootBundle);
      final f = faixaDe('primeiro-contato.oi-tudo-bem', 0);
      await s.preparar(f);
      final h = s.para(f);
      expect(h, isNotNull);
      expect(h!.autoral, isTrue);
      expect(h.titulo?.en, isNotEmpty);
      expect(s.temAutoral('primeiro-contato.oi-tudo-bem'), isTrue);
      expect(s.carregando('primeiro-contato.oi-tudo-bem'), isFalse);

      // uma lição do B1 (o A1 e o A2 já têm histórias escritas; o B1 ainda usa só a automática)
      const fora = 'ja-fui-x-fui.ja-foi-quando-foi';
      final f2 = faixaDe(fora, 0);
      await s.preparar(f2);
      final auto = s.para(f2);
      expect(auto, isNotNull);
      expect(auto!.autoral, isFalse);
      final linha = (_json('encenacao_auto.json')['licoes'] as Map)[fora] as Map;
      expect(auto.cenas.first.cenario.name, linha['cenario']);
      HistoriasLicoesRepo.limparCache();
    });
  });
}
