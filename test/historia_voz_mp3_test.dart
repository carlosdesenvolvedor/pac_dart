// 🎙️ D15: a fala da história toca o mp3 do PERSONAGEM (voz Chirp, `assets/ingles/vozes_historia.json`) com a
// boca do Rhubarb; sem mp3, a voz sintética com o perfil dele. Aqui: o roteiro passa quem fala, o perfil e a
// velocidade; e com a VozIngles de verdade o mp3 da história é anunciado como gravação.
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/elenco_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/roteiro_historia.dart';
import 'package:pac_dart/features/ingles/data/audio_nativo.dart';
import 'package:pac_dart/features/ingles/data/bocas_ingles.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'historia_player_test.dart' show capitulo;

/// Guarda o que o roteiro pediu na voz da história.
class _VozDaHistoria extends VozIngles {
  final pedidos = <({String frase, String quem, PerfilVoz perfil, double fator})>[];

  @override
  Future<FimDaFala> falarNaHistoria(String frase,
      {required double fator, required String quem, required PerfilVoz perfil}) {
    pedidos.add((frase: frase, quem: quem, perfil: perfil, fator: fator));
    return Future.value(FimDaFala.acabou);
  }

  @override
  Future<void> parar() async {}

  @override
  bool get somLiberado => true;
}

RoteiroHistoria _roteiro(VozIngles voz, {double? velocidade}) => RoteiroHistoria(
      cenas: capitulo.parte(ParteDoCapitulo.intro),
      nivel: capitulo.nivel,
      voz: voz,
      vozLigada: true,
      lenta: false,
      velocidade: velocidade,
      mostrarPt: true,
      reduzir: false,
    );

void _rodar(RoteiroHistoria r, double s) {
  for (var t = 0.0; t < s; t += .05) {
    r.tick(.05);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AudioNativo.limpar();
    BocasIngles.limpar();
    VozIngles.falando.value = null;
  });
  tearDown(() {
    AudioNativo.limpar();
    BocasIngles.limpar();
    VozIngles.falando.value = null;
  });

  test('o roteiro pede a voz da história com quem fala, o perfil dele e a velocidade', () {
    final voz = _VozDaHistoria();
    final r = _roteiro(voz, velocidade: .7)..tocar();
    final falas = [
      for (final c in capitulo.parte(ParteDoCapitulo.intro))
        for (final f in c.falas)
          if (f.en != null) f,
    ];
    _rodar(r, 4); // o título e a 1ª fala
    for (var i = 1; i < falas.length; i++) {
      r.irParaFala(i);
      _rodar(r, 1);
    }
    expect(voz.pedidos, isNotEmpty);
    for (final p in voz.pedidos) {
      final f = falas.firstWhere((f) => f.en == p.frase);
      expect(p.quem, f.quem, reason: p.frase);
      expect(p.perfil, ElencoTurismo.perfilDeVoz(f.quem), reason: p.frase);
      expect(p.fator, .7);
    }
    expect(voz.pedidos.map((p) => p.frase).toSet(), falas.map((f) => f.en).toSet());
    r.dispose();
  });

  test('com o mp3 da história registrado, a voz de verdade anuncia a boca do Rhubarb (gravação)', () async {
    final primeira = capitulo.parte(ParteDoCapitulo.intro).first.falas.firstWhere((f) => f.en != null);
    const mp3 = 'assets/ingles/voz_historia/teste.mp3';
    AudioNativo.registrarHistoria({'${primeira.quem}|${primeira.en}': mp3});
    BocasIngles.registrar({mp3: '0X 10B 30C 120X'});
    final perfis = <PerfilVoz>[];
    final anuncios = <FalaEmCurso>[];
    void ouvir() {
      final f = VozIngles.falando.value;
      if (f != null) anuncios.add(f);
    }

    VozIngles.falando.addListener(ouvir);
    addTearDown(() => VozIngles.falando.removeListener(ouvir));
    final voz = VozIngles(falarComPerfil: (_, _, p) async => perfis.add(p));
    final r = _roteiro(voz)..tocar();
    _rodar(r, 4); // o título e a 1ª fala
    await pumpEventQueue();
    final daPrimeira = anuncios.where((a) => a.frase == primeira.en).toList();
    expect(daPrimeira.first.gravacao, isTrue, reason: 'o mp3 do personagem é anunciado com a boca do Rhubarb');
    // na VM o mp3 não toca: a sintética com o perfil do personagem assume (a reserva)
    expect(perfis.first, ElencoTurismo.perfilDeVoz(primeira.quem));
    r.dispose();
  });

  test('duracaoNaHistoria: a boca do mp3 da história; sem ele, a estimativa pelo texto', () {
    const mp3 = 'assets/ingles/voz_historia/teste.mp3';
    AudioNativo.registrarHistoria({'max|Copy that!': mp3});
    BocasIngles.registrar({mp3: '0X 10B 30C 250X'});
    expect(VozIngles.duracaoNaHistoria('max', 'Copy that!'), closeTo(2.5, 1e-9));
    expect(VozIngles.duracaoNaHistoria('voce', 'Copy that!'), VozIngles.duracaoDe('Copy that!'));
  });
}
