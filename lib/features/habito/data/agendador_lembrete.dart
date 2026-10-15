import '../domain/lembrete.dart';

/// Quem fala com o sistema operacional para mostrar o lembrete. O app só conhece esta interface:
/// no celular é o `AgendadorDoCelular` (plugin); no navegador, no desktop e nos testes, o [AgendadorNulo]
/// (ou um falso do teste).
abstract interface class AgendadorDeLembrete {
  /// Este aparelho sabe agendar notificações (Android e iOS). Falso ⇒ a tela esconde o interruptor.
  bool get disponivel;

  /// Pede a permissão de notificar (no momento em que a pessoa liga o lembrete). Nunca lança: erro = false.
  Future<bool> pedirPermissao();

  /// Cancela os lembretes que o app agendou antes e agenda [lembretes] no lugar. Nunca lança.
  Future<void> substituir(List<LembreteAgendado> lembretes);

  /// Cancela todos os lembretes do app. Nunca lança.
  Future<void> cancelarTodos();
}

/// Sem agendamento (web, desktop, testes): tudo é "não disponível" e nada acontece.
class AgendadorNulo implements AgendadorDeLembrete {
  const AgendadorNulo();

  @override
  bool get disponivel => false;
  @override
  Future<bool> pedirPermissao() async => false;
  @override
  Future<void> substituir(List<LembreteAgendado> lembretes) async {}
  @override
  Future<void> cancelarTodos() async {}
}
