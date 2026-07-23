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

/// Dica da fase (cicla a lista, uma por fase).
String dicaDaFase(int fase) => dicasDart[(fase - 1) % dicasDart.length];
