import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pac_dart/core/voz/voz_natural.dart';
import 'package:pac_dart/features/curso/presentation/bloc/voz_cubit.dart';

/// Na VM não há Web Audio: o VozNatural precisa desistir NA HORA (sem nem
/// tocar a rede) para o fallback do sistema assumir.
class _ClientQueExplode extends http.BaseClient {
  bool usado = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    usado = true;
    throw StateError('não era pra chamar a rede fora da web!');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fora da web: devolve false sem gastar rede', () async {
    final client = _ClientQueExplode();
    final voz = VozNatural(client: client);
    expect(await voz.falar('map devolve um Iterable preguiçoso.'), isFalse);
    expect(client.usado, isFalse);
    voz.parar(); // não explode
  });

  test('texto vazio nem tenta', () async {
    final voz = VozNatural(client: _ClientQueExplode());
    expect(await voz.falar('   '), isFalse);
  });

  test('VozCubit segue inteiro com o fallback (plataforma sem TTS)', () async {
    final cubit = VozCubit(natural: VozNatural(client: _ClientQueExplode()));
    cubit.alternar();
    expect(cubit.state, isTrue);
    await cubit.falar('oi'); // MissingPlugin do flutter_tts é engolido
    await cubit.falarSempre('oi de novo');
    cubit.alternar();
    expect(cubit.state, isFalse);
    await cubit.close();
  });
}
