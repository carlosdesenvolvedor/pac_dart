import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/auth/data/exclusao_de_conta.dart';
import 'package:pac_dart/features/ingles/data/audio_usuario.dart';
import 'package:pac_dart/features/ingles/data/audio_usuario_repository.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/audio_usuario.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/audio_da_frase.dart';

/// Bytes com o cabeçalho de cada formato (o resto é enchimento).
Uint8List _com(List<int> cabecalho, {int total = 64, int offset = 0}) {
  final b = Uint8List(total);
  b.setRange(offset, offset + cabecalho.length, cabecalho);
  return b;
}

List<int> _txt(String s) => s.codeUnits;

Uint8List mp3Id3([int total = 64]) => _com(_txt('ID3'), total: total);
Uint8List mp3Quadro() => _com([0xFF, 0xFB, 0x90, 0x00]);
Uint8List wav() => _com([..._txt('RIFF'), 0, 0, 0, 0, ..._txt('WAVE')]);
Uint8List ogg() => _com(_txt('OggS'));
Uint8List flac() => _com(_txt('fLaC'));
Uint8List m4a() => _com(_txt('ftyp'), offset: 4);
Uint8List webm() => _com([0x1A, 0x45, 0xDF, 0xA3]);

/// Repositório lento para provar a corrida de duas falas seguidas.
class _RepoLento extends MemoriaAudioUsuarioRepository {
  final Completer<void> liberar = Completer<void>();
  @override
  Future<ClipeAudio?> carregar(String chave) async {
    await liberar.future;
    return super.carregar(chave);
  }
}

class _RepoQueQuebra implements AudioUsuarioRepository {
  bool quebraIndice = false, quebraCarregar = false, quebraSalvar = false, quebraRemover = false;
  final MemoriaAudioUsuarioRepository _m = MemoriaAudioUsuarioRepository();
  @override
  Future<Map<String, InfoAudio>> indice() async => quebraIndice ? throw Exception('x') : _m.indice();
  @override
  Future<ClipeAudio?> carregar(String c) async => quebraCarregar ? throw Exception('x') : _m.carregar(c);
  @override
  Future<void> salvar(String c, ClipeAudio a) async => quebraSalvar ? throw Exception('x') : _m.salvar(c, a);
  @override
  Future<void> remover(String c) async => quebraRemover ? throw Exception('x') : _m.remover(c);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(AudioUsuario.limpar);
  tearDown(AudioUsuario.limpar);

  group('FormatosAudio: conferência pelo CONTEÚDO do arquivo', () {
    test('reconhece cada formato pelos primeiros bytes', () {
      expect(FormatosAudio.detectar(mp3Id3()), 'audio/mpeg');
      expect(FormatosAudio.detectar(mp3Quadro()), 'audio/mpeg');
      expect(FormatosAudio.detectar(wav()), 'audio/wav');
      expect(FormatosAudio.detectar(ogg()), 'audio/ogg');
      expect(FormatosAudio.detectar(flac()), 'audio/flac');
      expect(FormatosAudio.detectar(m4a()), 'audio/mp4');
      expect(FormatosAudio.detectar(webm()), 'audio/webm');
    });

    test('o que não é áudio (foto, texto, vazio, curto demais) não passa', () {
      expect(FormatosAudio.detectar(_com([0xFF, 0xD8, 0xFF, 0xE0])), isNull, reason: 'JPEG');
      expect(FormatosAudio.detectar(_com([0x89, 0x50, 0x4E, 0x47])), isNull, reason: 'PNG');
      expect(FormatosAudio.detectar(_com(_txt('%PDF-1.7'))), isNull, reason: 'PDF');
      expect(FormatosAudio.detectar(_com(_txt('hello world, not audio'))), isNull);
      expect(FormatosAudio.detectar(Uint8List(0)), isNull);
      expect(FormatosAudio.detectar(Uint8List.fromList([0x49, 0x44, 0x33])), isNull, reason: 'curto demais');
      expect(FormatosAudio.detectar(_com([0xFF, 0xE0, 0, 0])), isNull, reason: 'sincronia sem camada MPEG válida');
    });

    test('validar: mensagens em português para vazio, grande demais e não-áudio; null quando serve', () {
      expect(FormatosAudio.validar(mp3Id3()), isNull);
      expect(FormatosAudio.validar(Uint8List(0)), 'O arquivo está vazio.');
      expect(FormatosAudio.validar(mp3Id3(FormatosAudio.maxBytes)), isNull, reason: 'exatamente no limite serve');
      final grande = FormatosAudio.validar(mp3Id3(FormatosAudio.maxBytes + 1))!;
      expect(grande, contains('800 KB'));
      expect(grande, contains('máximo'));
      expect(FormatosAudio.validar(_com(_txt('hello world, not audio'))), contains('não parece um arquivo de áudio'));
    });

    test('rótulos e o índice ida e volta', () {
      expect({for (final m in FormatosAudio.mimes) m: FormatosAudio.rotulo(m)},
          {'audio/mpeg': 'MP3', 'audio/mp4': 'M4A', 'audio/wav': 'WAV', 'audio/ogg': 'OGG', 'audio/webm': 'WEBM', 'audio/flac': 'FLAC'});
      const i = InfoAudio('audio/mpeg', 12345);
      expect(InfoAudio.decodificar(i.codificar()), i);
      expect(i.formato, 'MP3');
      for (final ruim in ['', 'lixo', 'audio/mpeg|x', 'audio/mpeg|0', 'audio/mpeg|-5', 'video/mp4|10', 'audio/mpeg|1|2', null]) {
        expect(InfoAudio.decodificar(ruim), isNull, reason: '$ruim');
      }
    });
  });

  group('repositórios', () {
    test('memória: guarda, lista, baixa, troca e remove', () async {
      final r = MemoriaAudioUsuarioRepository();
      expect(await r.indice(), isEmpty);
      expect(await r.carregar('a'), isNull);
      await r.salvar('a', ClipeAudio(mp3Id3(100), 'audio/mpeg'));
      await r.salvar('a', ClipeAudio(wav(), 'audio/wav'));
      final i = await r.indice();
      expect(i['a'], const InfoAudio('audio/wav', 64), reason: 'trocar substitui');
      expect((await r.carregar('a'))!.mime, 'audio/wav');
      await r.remover('a');
      expect(await r.indice(), isEmpty);
    });

    group('Firestore (users/{uid}/audio)', () {
      late FakeFirebaseFirestore db;
      late FirestoreAudioUsuarioRepository repo;
      setUp(() {
        db = FakeFirebaseFirestore();
        repo = FirestoreAudioUsuarioRepository('u1', db: db);
      });

      test('guarda os bytes COMO VIERAM e o índice numa leitura só', () async {
        final bytes = Uint8List.fromList([for (var i = 0; i < 300; i++) i % 256]);
        await repo.salvar('k1', ClipeAudio(Uint8List.fromList([..._txt('ID3'), ...bytes]), 'audio/mpeg'));
        await repo.salvar('k2', ClipeAudio(wav(), 'audio/wav'));
        final indice = await FirestoreAudioUsuarioRepository('u1', db: db).indice();
        expect(indice.keys.toSet(), {'k1', 'k2'});
        expect(indice['k1']!.mime, 'audio/mpeg');
        expect(indice['k1']!.tamanho, 303);
        final k1 = (await repo.carregar('k1'))!;
        expect(k1.mime, 'audio/mpeg');
        expect(k1.bytes, [..._txt('ID3'), ...bytes], reason: 'idêntico ao que foi enviado, sem converter');
        expect(await repo.carregar('nao-existe'), isNull);
      });

      test('trocar substitui o áudio e o índice; remover tira os dois; o resto do índice fica', () async {
        await repo.salvar('k1', ClipeAudio(mp3Id3(100), 'audio/mpeg'));
        await repo.salvar('k2', ClipeAudio(wav(), 'audio/wav'));
        await repo.salvar('k1', ClipeAudio(flac(), 'audio/flac'));
        expect((await repo.indice())['k1']!.mime, 'audio/flac');
        expect((await repo.carregar('k1'))!.mime, 'audio/flac');
        await repo.remover('k1');
        expect((await repo.indice()).keys, ['k2']);
        expect(await repo.carregar('k1'), isNull);
        await repo.remover('k1'); // de novo: nada quebra
      });

      test('cada conta tem os seus; índice vazio ou com lixo vira mapa vazio/ignora o lixo', () async {
        await repo.salvar('k1', ClipeAudio(mp3Id3(), 'audio/mpeg'));
        expect(await FirestoreAudioUsuarioRepository('u2', db: db).indice(), isEmpty);
        await db.collection('users').doc('u1').collection('audio').doc('_idx').set({
          'i': {'k1': 'audio/mpeg|64', 'ruim': 'lixo', 'x': 5},
        });
        expect((await repo.indice()).keys, ['k1']);
        await db.collection('users').doc('u1').collection('audio').doc('k9').set({'b': Blob(mp3Id3()), 'm': 'application/pdf'});
        expect(await repo.carregar('k9'), isNull, reason: 'tipo que não é de áudio não toca');
        await db.collection('users').doc('u1').collection('audio').doc('k8').set({'b': 'texto', 'm': 'audio/mpeg'});
        expect(await repo.carregar('k8'), isNull, reason: 'sem bytes de verdade');
      });
    });
  });

  group('AudioUsuario (o registro)', () {
    test('sem repositório: indisponível, nada toca, adicionar avisa', () async {
      expect(AudioUsuario.disponivel, isFalse);
      expect(AudioUsuario.tem('Hello.'), isFalse);
      expect(await AudioUsuario.clipeDe('Hello.'), isNull);
      expect(await AudioUsuario.adicionar('Hello.', mp3Id3()), contains('não está disponível'));
      expect(await AudioUsuario.remover('Hello.'), contains('não está disponível'));
    });

    test('iniciar carrega o índice; a chave ignora espaços nas pontas', () async {
      final repo = MemoriaAudioUsuarioRepository();
      await repo.salvar(AudioUsuario.chaveDe('Nice to meet you.'), ClipeAudio(mp3Id3(100), 'audio/mpeg'));
      await AudioUsuario.iniciar(repo);
      expect(AudioUsuario.disponivel, isTrue);
      expect(AudioUsuario.tem('Nice to meet you.'), isTrue);
      expect(AudioUsuario.tem('  Nice to meet you.  '), isTrue);
      expect(AudioUsuario.tem('How are you?'), isFalse);
      expect(AudioUsuario.infoDe('Nice to meet you.')!.tamanho, 100);
    });

    test('adicionar valida pelo conteúdo, guarda, atualiza o índice e avisa as telas', () async {
      final repo = MemoriaAudioUsuarioRepository();
      await AudioUsuario.iniciar(repo);
      var avisos = 0;
      void ouvinte() => avisos++;
      AudioUsuario.versao.addListener(ouvinte);
      addTearDown(() => AudioUsuario.versao.removeListener(ouvinte));

      expect(await AudioUsuario.adicionar('Hello.', _com(_txt('not audio at all, sorry'))), contains('não parece um arquivo de áudio'));
      expect(AudioUsuario.tem('Hello.'), isFalse);
      expect(await repo.indice(), isEmpty, reason: 'o inválido nem chega a ser guardado');
      expect(avisos, 0);

      expect(await AudioUsuario.adicionar('Hello.', wav()), isNull);
      expect(AudioUsuario.tem('Hello.'), isTrue);
      expect(AudioUsuario.infoDe('Hello.'), const InfoAudio('audio/wav', 64));
      expect((await repo.indice()).length, 1);
      expect(avisos, 1);
      // a MESMA frase com outro formato troca o áudio
      expect(await AudioUsuario.adicionar('Hello.', mp3Id3(200)), isNull);
      expect(AudioUsuario.infoDe('Hello.'), const InfoAudio('audio/mpeg', 200));
    });

    test('o áudio só é baixado na 1ª vez; depois vem da memória', () async {
      final repo = MemoriaAudioUsuarioRepository();
      await repo.salvar(AudioUsuario.chaveDe('Hello.'), ClipeAudio(mp3Id3(100), 'audio/mpeg'));
      await AudioUsuario.iniciar(repo);
      expect((await AudioUsuario.clipeDe('Hello.'))!.tamanho, 100);
      expect((await AudioUsuario.clipeDe('Hello.'))!.tamanho, 100);
      expect(repo.downloads, 1);
      expect(await AudioUsuario.clipeDe('Sem áudio.'), isNull);
      expect(repo.downloads, 1, reason: 'frase sem áudio nem consulta a nuvem');
    });

    test('remover tira do índice e da memória; a frase volta a não ter áudio', () async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      await AudioUsuario.adicionar('Hello.', mp3Id3());
      expect(await AudioUsuario.remover('Hello.'), isNull);
      expect(AudioUsuario.tem('Hello.'), isFalse);
      expect(await AudioUsuario.clipeDe('Hello.'), isNull);
    });

    test('trocar de conta (iniciar de novo) esquece o que era da anterior', () async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      await AudioUsuario.adicionar('Hello.', mp3Id3());
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      expect(AudioUsuario.tem('Hello.'), isFalse);
    });

    test('falhas da nuvem: índice que quebra = tudo toca como antes; salvar/remover devolvem recado; baixar devolve null', () async {
      final repo = _RepoQueQuebra()..quebraIndice = true;
      await AudioUsuario.iniciar(repo);
      expect(AudioUsuario.disponivel, isTrue);
      expect(AudioUsuario.tem('Hello.'), isFalse);

      repo
        ..quebraIndice = false
        ..quebraSalvar = true;
      await AudioUsuario.iniciar(repo);
      expect(await AudioUsuario.adicionar('Hello.', mp3Id3()), contains('Não consegui guardar'));
      expect(AudioUsuario.tem('Hello.'), isFalse, reason: 'não finge que guardou');

      repo.quebraSalvar = false;
      expect(await AudioUsuario.adicionar('Hello.', mp3Id3()), isNull);
      repo.quebraRemover = true;
      expect(await AudioUsuario.remover('Hello.'), contains('Não consegui remover'));
      expect(AudioUsuario.tem('Hello.'), isTrue, reason: 'continua tendo');

      // o cache cobre um download que depois quebra; sem cache, devolve null
      repo.quebraCarregar = true;
      expect(await AudioUsuario.clipeDe('Hello.'), isNotNull);
      await AudioUsuario.iniciar(repo);
      expect(await AudioUsuario.clipeDe('Hello.'), isNull);
    });
  });

  group('VozIngles: o áudio do aluno vem na frente', () {
    test('frase COM áudio toca os bytes do aluno, no formato dele, e devagar usa a velocidade lenta', () async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      await AudioUsuario.adicionar('Hello.', wav());
      final tocou = <(int, String, double)>[];
      final voz = VozIngles(tocarClipe: (bytes, mime, v) async {
        tocou.add((bytes.length, mime, v));
        return true;
      });
      await voz.falar('Hello.', lenta: false);
      await voz.falar('Hello.', lenta: true);
      expect(tocou, [(64, 'audio/wav', VozIngles.velocidadeGravada), (64, 'audio/wav', VozIngles.velocidadeGravadaLenta)]);
    });

    test('frase SEM áudio do aluno não chama o player do aluno (segue a voz de antes)', () async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      var chamou = false;
      await VozIngles(tocarClipe: (_, _, _) async => chamou = true).falar('Sem áudio.');
      expect(chamou, isFalse);
    });

    test('se o navegador/aparelho não consegue tocar aquele formato, não fica mudo: cai na voz de antes sem lançar', () async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      await AudioUsuario.adicionar('Hello.', flac());
      var tentou = 0;
      await VozIngles(tocarClipe: (_, _, _) async {
        tentou++;
        return false;
      }).falar('Hello.');
      expect(tentou, 1);
    });

    test('duas falas seguidas: a que chegou primeiro e ainda esperava o áudio baixar NÃO atropela a nova', () async {
      final lento = _RepoLento();
      await lento.salvar(AudioUsuario.chaveDe('Primeira.'), ClipeAudio(mp3Id3(), 'audio/mpeg'));
      await lento.salvar(AudioUsuario.chaveDe('Segunda.'), ClipeAudio(wav(), 'audio/wav'));
      await AudioUsuario.iniciar(lento);
      final tocadas = <String>[];
      final voz = VozIngles(tocarClipe: (_, mime, _) async {
        tocadas.add(mime);
        return true;
      });
      final a = voz.falar('Primeira.');
      final b = voz.falar('Segunda.'); // chega depois e vale
      lento.liberar.complete();
      await Future.wait([a, b]);
      expect(tocadas, ['audio/wav'], reason: 'só a mais nova toca');
    });

    test('parar() derruba a fala que ainda esperava o áudio', () async {
      final lento = _RepoLento();
      await lento.salvar(AudioUsuario.chaveDe('Primeira.'), ClipeAudio(mp3Id3(), 'audio/mpeg'));
      await AudioUsuario.iniciar(lento);
      var tocou = false;
      final voz = VozIngles(tocarClipe: (_, _, _) async => tocou = true);
      final a = voz.falar('Primeira.');
      await voz.parar();
      lento.liberar.complete();
      await a;
      expect(tocou, isFalse);
    });
  });

  group('exclusão de conta leva os áudios (achados pelo índice)', () {
    test('apaga os áudios, o índice e o resto; o outro usuário fica intacto', () async {
      final db = FakeFirebaseFirestore();
      for (final uid in ['u1', 'u2']) {
        await db.collection('users').doc(uid).set({'concluidas': []});
        final repo = FirestoreAudioUsuarioRepository(uid, db: db);
        await repo.salvar('k1', ClipeAudio(mp3Id3(), 'audio/mpeg'));
        await repo.salvar('k2', ClipeAudio(wav(), 'audio/wav'));
      }
      await apagarDadosDoUsuario(db, 'u1');
      expect((await db.collection('users').doc('u1').get()).exists, isFalse);
      expect((await db.collection('users').doc('u1').collection('audio').get()).docs, isEmpty);
      expect((await FirestoreAudioUsuarioRepository('u2', db: db).indice()).keys.toSet(), {'k1', 'k2'});
      expect(await FirestoreAudioUsuarioRepository('u2', db: db).carregar('k1'), isNotNull);
    });

    test('mais de 500 operações: apaga tudo em vários lotes', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('users').doc('u1').set({'concluidas': []});
      final audios = db.collection('users').doc('u1').collection('audio');
      final indice = <String, String>{};
      for (var i = 0; i < 620; i++) {
        indice['k$i'] = 'audio/mpeg|64';
        await audios.doc('k$i').set({'b': Blob(mp3Id3()), 'm': 'audio/mpeg', 'n': 64});
      }
      await audios.doc('_idx').set({'i': indice});
      await apagarDadosDoUsuario(db, 'u1');
      expect((await audios.get()).docs, isEmpty);
      expect((await db.collection('users').doc('u1').get()).exists, isFalse);
    });

    test('conta sem nenhum áudio também funciona', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('users').doc('u1').set({'concluidas': []});
      await apagarDadosDoUsuario(db, 'u1');
      expect((await db.collection('users').doc('u1').get()).exists, isFalse);
    });
  });

  group('o botão 🎧 e a folha "Seu áudio desta frase"', () {
    Future<void> abrir(WidgetTester tester, {SeletorAudio? seletor, VozIngles? voz, String frase = 'Hello.', bool redondo = false}) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: BotaoAudioDaFrase(frase: frase, seletor: seletor, voz: voz, redondo: redondo))),
      ));
    }

    SeletorAudio escolhe(Uint8List bytes, [String nome = 'meu.mp3']) =>
        () async => (nome: nome, bytes: bytes);

    testWidgets('sem onde guardar, o botão some', (tester) async {
      await abrir(tester);
      expect(find.byKey(const Key('audio-da-frase')), findsNothing);
    });

    testWidgets('com onde guardar aparece; escolher um arquivo válido anexa, mostra o formato e realça o botão', (tester) async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      await abrir(tester, seletor: escolhe(mp3Id3(2048)));
      expect(find.byKey(const Key('audio-da-frase')), findsOneWidget);
      expect(find.byIcon(Icons.headphones_outlined), findsOneWidget);

      await tester.tap(find.byKey(const Key('audio-da-frase')));
      await tester.pumpAndSettle();
      expect(find.text('Seu áudio desta frase'), findsOneWidget);
      expect(find.text('Hello.'), findsWidgets);
      expect(find.byKey(const Key('info-audio')), findsNothing);
      expect(find.byKey(const Key('remover-audio')), findsNothing);

      await tester.tap(find.byKey(const Key('escolher-audio')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ok-audio')), findsOneWidget);
      expect(find.text('Tocando o seu áudio: MP3 · 2 KB.'), findsOneWidget);
      expect(find.byKey(const Key('remover-audio')), findsOneWidget);
      expect(find.text('Trocar o arquivo'), findsOneWidget);
      expect(AudioUsuario.tem('Hello.'), isTrue);

      // fecha a folha: o botão ficou "ligado"
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);
    });

    testWidgets('arquivo que não é áudio ou grande demais: mostra o motivo e NÃO anexa', (tester) async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      await abrir(tester, seletor: escolhe(_com(_txt('this is plain text, not audio')), 'foto.mp3'));
      await tester.tap(find.byKey(const Key('audio-da-frase')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('escolher-audio')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('erro-audio')), findsOneWidget);
      expect(find.textContaining('não parece um arquivo de áudio'), findsOneWidget);
      expect(AudioUsuario.tem('Hello.'), isFalse);

      await tester.pumpWidget(const SizedBox());
      await abrir(tester, seletor: escolhe(mp3Id3(FormatosAudio.maxBytes + 10)));
      await tester.tap(find.byKey(const Key('audio-da-frase')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('escolher-audio')));
      await tester.pumpAndSettle();
      expect(find.textContaining('o máximo é 800 KB'), findsOneWidget);
      expect(AudioUsuario.tem('Hello.'), isFalse);
    });

    testWidgets('cancelar a janela de arquivos não muda nada e não mostra erro', (tester) async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      await abrir(tester, seletor: () async => null);
      await tester.tap(find.byKey(const Key('audio-da-frase')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('escolher-audio')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('erro-audio')), findsNothing);
      expect(find.byKey(const Key('ok-audio')), findsNothing);
      expect(AudioUsuario.tem('Hello.'), isFalse);
    });

    testWidgets('o seletor que quebra vira recado, não exceção', (tester) async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      await abrir(tester, seletor: () async => throw Exception('permissão negada'));
      await tester.tap(find.byKey(const Key('audio-da-frase')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('escolher-audio')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Não consegui abrir o arquivo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('frase que já tem áudio: mostra, ouve (toca o áudio dele), troca e remove', (tester) async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      await AudioUsuario.adicionar('Hello.', wav());
      final tocou = <String>[];
      final voz = VozIngles(tocarClipe: (_, mime, _) async {
        tocou.add(mime);
        return true;
      });
      await abrir(tester, seletor: escolhe(flac(), 'novo.flac'), voz: voz);
      expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);
      await tester.tap(find.byKey(const Key('audio-da-frase')));
      await tester.pumpAndSettle();
      expect(find.text('Tocando o seu áudio: WAV · 0 KB.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ouvir-meu-audio')));
      await tester.pump();
      expect(tocou, ['audio/wav']);

      await tester.tap(find.byKey(const Key('escolher-audio')));
      await tester.pumpAndSettle();
      expect(AudioUsuario.infoDe('Hello.')!.mime, 'audio/flac');
      expect(find.textContaining('FLAC'), findsOneWidget);

      await tester.tap(find.byKey(const Key('remover-audio')));
      await tester.pumpAndSettle();
      expect(AudioUsuario.tem('Hello.'), isFalse);
      expect(find.byKey(const Key('info-audio')), findsNothing);
      expect(find.text('Removido: a frase volta à voz de antes.'), findsOneWidget);
      expect(find.text('Escolher arquivo de áudio'), findsOneWidget);
    });

    testWidgets('estilo redondo (junto dos botões do cartão da tradução)', (tester) async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      await abrir(tester, redondo: true);
      expect(find.byKey(const Key('audio-da-frase')), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
      await tester.tap(find.byKey(const Key('audio-da-frase')));
      await tester.pumpAndSettle();
      expect(find.text('Seu áudio desta frase'), findsOneWidget);
    });
  });
}
