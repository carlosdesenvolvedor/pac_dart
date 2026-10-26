import 'dart:async';

import 'package:pac_dart/features/curso/presentation/pages/inicio_page.dart';
import 'package:pac_dart/features/ingles/data/preferencia_cena_licao.dart';
import 'package:pac_dart/features/ingles/data/vozes_aula.dart';
import 'package:pac_dart/features/ingles/domain/roteiro.dart';
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
///
/// 🏠 A tela Início abre por cima da lição no app (e a lição fica com o cabeçalho limpo, o mapa sem as
/// ferramentas); os testes antigos abrem direto na lição com o cabeçalho cheio: aqui ela fica desligada (os
/// testes do Início ligam `Inicio.ligado = true`).
///
/// 🪜 As partes (sub-lições de ~10 digitações) pausam a lição no app; os testes antigos fazem a lição de uma vez: aqui
/// ficam desligadas (os testes das partes ligam `EtapasDaLicao.ligadas = true`).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Inicio.ligado = false;
  EtapasDaLicao.ligadas = false;
  PreferenciaCenaLicao.padrao = false;
  PalcoIngles.aulaSozinha = false;
  VozesAula.fixas = const {};
  await testMain();
}
