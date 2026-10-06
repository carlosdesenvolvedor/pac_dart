import '../../../core/linguagem/linguagem.dart';
import 'palavras_ingles.dart';

/// Dicas-relâmpago de Dart/Flutter mostradas entre as fases dos jogos —
/// até a telinha de "passou de fase" ensina alguma coisa.
const List<String> dicasDart = [
  'var deixa o Dart adivinhar o tipo; final trava o valor depois da primeira atribuição.',
  'const é mais forte que final: o valor já nasce pronto em tempo de COMPILAÇÃO.',
  'String se interpola com \$: print("Oi, \$nome!") — sem somar pedacinhos com +.',
  'O operador ?? dá um valor reserva quando algo é null: apelido ?? "sem nome".',
  'O acesso seguro ?. só chama o método se o objeto não for null — sem quebrar o app.',
  'Listas usam [ ], Sets e Maps usam { } — e Set nunca guarda item repetido.',
  'where filtra, map transforma, toList materializa: o trio mais usado das coleções.',
  '~/ é a divisão inteira: 7 ~/ 2 é 3. O resto fica com o %: 7 % 2 é 1.',
  'Função de uma expressão vira flecha: int dobro(int n) => n * 2;',
  'O cascade .. chama vários métodos no MESMO objeto: lista..add(2)..sort().',
  'O spread ... despeja uma lista dentro da outra: [0, ...resto].',
  'await só funciona dentro de função marcada com async — e espera o Future terminar.',
  'extends herda implementação; implements assina o contrato e te obriga a reescrever tudo.',
  'mixin entra na classe com with: class Pato with Nadador — habilidade emprestada.',
  'No Flutter, TUDO é widget: até o padding é um widget chamado Padding.',
  'setState avisa o Flutter que o estado mudou — sem ele, a tela não redesenha.',
  'Column empilha, Row enfileira, Expanded divide o espaço que sobrou.',
  'is testa o tipo e ainda promove a variável dentro do if: if (x is String) x.length.',
  'late promete: "vou atribuir antes de usar" — o Dart cobra em tempo de execução.',
  'Prefira const nos widgets que não mudam: o Flutter reaproveita e o app voa.',
];

/// Dicas-relâmpago de C#/.NET (vertente PAC·C#).
const List<String> dicasCSharp = [
  'var deixa o compilador deduzir o tipo — mas a variável continua com tipo fixo.',
  'const é valor de compilação; readonly é atribuído uma vez (no construtor) e trava.',
  r'String se interpola com $: $"Oi, {nome}!" — e {total:F2} já formata com 2 casas.',
  'O operador ?? dá um valor reserva quando algo é null: apelido ?? "sem nome".',
  'O ?. só chama o membro se o objeto não for null: cliente?.Endereco?.Cidade.',
  'decimal é o tipo do dinheiro: 0.1m + 0.2m é exatamente 0.3m (double erra por pouco).',
  'Divisão entre inteiros corta a parte decimal: 7 / 2 é 3. Use 7 / 2.0 para 3,5.',
  'List<T> cresce sozinha; array tem tamanho fixo; Dictionary<K,V> acha pela chave.',
  'LINQ é preguiçoso: Where e Select só rodam quando você percorre ou chama ToList().',
  'record compara por valor: dois records com os mesmos dados são iguais (==).',
  'struct é copiado na atribuição; class compartilha a mesma referência.',
  'using var fecha o recurso sozinho no fim do bloco — adeus Dispose esquecido.',
  'async Task não bloqueia a thread: await libera e volta quando a tarefa termina.',
  'Nunca use .Result ou .Wait() em código async: é o caminho mais curto para um deadlock.',
  'switch expression devolve valor: var nota = pontos switch { >= 90 => "A", _ => "B" };',
  'Interfaces definem o contrato; injeção de dependência escolhe a implementação.',
  'SOLID começa pelo S: uma classe, um motivo para mudar.',
  'Em jogos, multiplique o movimento por Time.deltaTime: mesma velocidade em qualquer FPS.',
  'No Unity 6, Rigidbody.velocity virou linearVelocity.',
  'Teste bom é AAA: Arrange (prepara), Act (executa), Assert (confere).',
];

/// Dica da fase (cicla a lista, uma por fase) na vertente em uso.
String dicaDaFase(int fase) {
  final lista = switch (Linguagem.atual) {
    Linguagem.csharp => dicasCSharp,
    Linguagem.ingles => dicasIngles,
    Linguagem.dart => dicasDart,
  };
  return lista[(fase - 1) % lista.length];
}
