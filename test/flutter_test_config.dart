import 'dart:async';

import 'package:pac_dart/features/ingles/data/preferencia_cena_licao.dart';

/// Roda antes de cada arquivo de teste.
///
/// 🎬 A cena da historinha no cartão da lição de inglês nasce LIGADA no app; os testes antigos medem o cartão,
/// as posições e o foco com o rosto de quem fala (e não carregam as historinhas). Aqui o padrão volta ao rosto;
/// os testes da cena ligam no `setUp` (`PreferenciaCenaLicao.padrao = true`) ou pela pref `en_cena_licao`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PreferenciaCenaLicao.padrao = false;
  await testMain();
}
