import 'dart:async';

import 'package:pac_dart/features/ingles/data/preferencia_cena_licao.dart';
import 'package:pac_dart/features/ingles/data/vozes_aula.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';

/// Roda antes de cada arquivo de teste.
///
/// 🎬 A cena da historinha no cartão da lição de inglês nasce LIGADA no app; os testes antigos medem o cartão,
/// as posições e o foco com o rosto de quem fala (e não carregam as historinhas). Aqui o padrão volta ao rosto;
/// os testes da cena ligam no `setUp` (`PreferenciaCenaLicao.padrao = true`) ou pela pref `en_cena_licao`.
///
/// 🎓 A aula do professor abre sozinha na 1ª visita de cada lição no app; os testes antigos não a esperam:
/// aqui ela fica desligada (os testes da aula ligam `PalcoIngles.aulaSozinha = true`). A voz dela vem do site:
/// nos testes, sem rede (nenhuma trilha com voz; a voz do aparelho, muda, assume).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PreferenciaCenaLicao.padrao = false;
  PalcoIngles.aulaSozinha = false;
  VozesAula.fixas = const {};
  await testMain();
}
