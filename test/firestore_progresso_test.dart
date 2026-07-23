import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/data/firestore_progresso_repository.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreProgressoRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreProgressoRepository('user-1', db: db);
  });

  test('usuário novo começa vazio', () async {
    expect(await repo.concluidas(), isEmpty);
    expect(await repo.quizNotas(), isEmpty);
    expect(await repo.projetosFeitos(), isEmpty);
    expect(await repo.posicao(), (0, 0));
    expect(await repo.recorde(), 0);
  });

  test('projetos feitos acumulam sem duplicar', () async {
    await repo.marcarProjetoFeito('proj:0:0');
    await repo.marcarProjetoFeito('master:2');
    await repo.marcarProjetoFeito('proj:0:0'); // repetido
    expect(await repo.projetosFeitos(), {'proj:0:0', 'master:2'});
    expect(await repo.concluidas(), isEmpty); // não mistura com as lições
  });

  test('marcarConcluida acumula sem duplicar (arrayUnion)', () async {
    await repo.marcarConcluida('0:0');
    await repo.marcarConcluida('0:1');
    await repo.marcarConcluida('0:0'); // repetida
    expect(await repo.concluidas(), {'0:0', '0:1'});
  });

  test('posição é salva e lida', () async {
    await repo.salvarPosicao(3, 5);
    expect(await repo.posicao(), (3, 5));
  });

  test('quiz guarda só a melhor nota e faz merge por chave', () async {
    await repo.salvarQuizNota('0:0', 7);
    await repo.salvarQuizNota('0:0', 5); // pior, ignora
    await repo.salvarQuizNota('0:0', 9); // melhor, atualiza
    await repo.salvarQuizNota('1:2', 8); // outra chave não some
    final notas = await repo.quizNotas();
    expect(notas['0:0'], 9);
    expect(notas['1:2'], 8);
  });

  test('recorde só sobe', () async {
    await repo.salvarRecorde(100);
    await repo.salvarRecorde(50);
    expect(await repo.recorde(), 100);
    await repo.salvarRecorde(150);
    expect(await repo.recorde(), 150);
  });

  test('dados de usuários diferentes ficam isolados', () async {
    await repo.marcarConcluida('0:0');
    final outro = FirestoreProgressoRepository('user-2', db: db);
    expect(await outro.concluidas(), isEmpty);
    expect(await repo.concluidas(), {'0:0'});
  });
}
