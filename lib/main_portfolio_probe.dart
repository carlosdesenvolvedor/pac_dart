// Entrypoint de PROVA VISUAL do app inteiro SEM Firebase: usuário de mentira
// já logado, progresso local, ranking em memória e um Prof. Dash que responde
// na hora. Serve pra fotografar as telas (portfólio) sem credenciais.
//   flutter build web -t lib/main_portfolio_probe.dart --output=build/probe_app
import 'package:flutter/material.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/app_user.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/curso/data/progresso_repository.dart';
import 'features/ranking/data/ranking_repository.dart';
import 'features/ranking/domain/jogador_ranking.dart';
import 'features/tutor/data/tutor_service.dart';
import 'main.dart';

void main() => runApp(PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoBuilder: (_) => LocalProgressoRepository(),
      rankingBuilder: () => _RankingFake(),
      tutorBuilder: () => _TutorFake(),
    ));

class _AuthFake implements AuthRepository {
  static const _user = AppUser(uid: 'carlos', email: 'carlos@cgmixart.com.br');
  @override
  Stream<AppUser?> get mudancas => Stream.value(_user);
  @override
  AppUser? get atual => _user;
  @override
  Future<void> entrar(String email, String senha) async {}
  @override
  Future<void> cadastrar(String email, String senha) async {}
  @override
  Future<void> redefinirSenha(String email) async {}
  @override
  Future<void> sair() async {}
}

class _RankingFake implements RankingRepository {
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async {}
  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async => true;
  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

class _TutorFake implements TutorService {
  @override
  Stream<String> perguntar({
    required String contexto,
    required String historico,
    required String pergunta,
  }) async* {
    const partes = [
      'Piu! Boa pergunta. ',
      'Nesse trecho, `final` diz que a variável recebe valor uma vez só. ',
      'O objeto por dentro ainda pode mudar, o que não pode é apontar pra outro. ',
      '\n\n```dart\nfinal nomes = <String>[];\nnomes.add(\'Dash\'); // ok\n// nomes = []; // erro: final não recebe de novo\n```\n\n',
      'Quer que eu mostre a diferença pra `const`? 🐦',
    ];
    for (final p in partes) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      yield p;
    }
  }
}
