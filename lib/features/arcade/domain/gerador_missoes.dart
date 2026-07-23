import 'dart:math' as math;

import 'missao.dart';

/// Gerador do LÓGICA ANIMADA.
///
/// As missões saem de GABARITOS parametrizados: nomes, números e listas são
/// sorteados de forma DETERMINÍSTICA por (trilha, índice) — a missão 7 da
/// trilha 2 é sempre a mesma, mas o estoque de combinações passa fácil dos
/// milhares. A resposta certa e o roteiro da animação são COMPUTADOS dos
/// mesmos parâmetros do código: nunca desmentem um ao outro.
Missao missaoPara(int trilha, int indice) {
  final rnd = math.Random(trilha * 1000003 + indice * 7919 + 13);
  final gabaritos = _gabaritosDa(trilha);
  final nivel = trilha <= 7
      ? (1 + indice ~/ 6).clamp(1, 3)
      : (2 + indice ~/ 10).clamp(2, 3);
  return gabaritos[indice % gabaritos.length](rnd, nivel);
}

typedef _Gabarito = Missao Function(math.Random rnd, int nivel);

/// Quais gabaritos servem cada trilha do mapa (as 8 base têm cardápio
/// próprio; as avançadas rotacionam 6 conjuntos em nível alto).
List<_Gabarito> _gabaritosDa(int t) => switch (t) {
      0 => [_mCracha, _mChave, _mPortaFor, _mCofreSenha, _mCofreUpper],
      1 => [_mBlitzIdade, _mPortaFor, _mSemaforoTernario, _mFogueteContagem],
      2 => [_mColheitaAdd, _mColheitaSoma, _mColheitaWhere, _mMercadoTotal, _mMercadoPreco],
      3 => [_mCracha, _mBlitzCinto, _mSemaforoSwitch, _mMercadoEstoque],
      4 => [_mFogueteCombustivel, _mPontePranchas, _mPortaWhileEnergia],
      5 => [_mSemaforoSwitch, _mPortaTurbo, _mColheitaAdd, _mSemaforoTernario],
      6 => [_mPontePranchas, _mBlitzVelocidade, _mFogueteCombustivel, _mPortaWhileEnergia],
      7 => [_mColheitaWhere, _mBlitzVelocidade, _mFogueteContagem],
      _ => _conjAvancados[t % _conjAvancados.length],
    };

const _conjAvancados = <List<_Gabarito>>[
  [_mPortaWhileEnergia, _mFogueteCombustivel, _mBlitzVelocidade, _mColheitaWhere, _mMercadoPreco],
  [_mBlitzIdade, _mPontePranchas, _mSemaforoTernario, _mColheitaSoma, _mCofreSenha],
  [_mFogueteContagem, _mBlitzCinto, _mPortaTurbo, _mColheitaAdd, _mCofreNull, _mCofreUpper],
  [_mSemaforoSwitch, _mPortaFor, _mBlitzVelocidade, _mPontePranchas, _mMercadoTotal],
  [_mColheitaWhere, _mFogueteCombustivel, _mBlitzIdade, _mSemaforoTernario, _mMercadoEstoque],
  [_mPontePranchas, _mColheitaSoma, _mPortaWhileEnergia, _mBlitzCinto, _mCofreNull],
];

// ---------------------------------------------------------------- utilidades

const _nomes = ['Ana', 'Bia', 'Caio', 'Duda', 'Leo', 'Rita', 'Igor', 'Mel', 'Noa', 'Gil'];
const _frutas = ['uva', 'kiwi', 'figo', 'manga', 'pera', 'caju', 'banana', 'amora'];
const _frutaEmoji = {'uva': '🍇', 'kiwi': '🥝', 'figo': '🍈', 'manga': '🥭', 'pera': '🍐', 'caju': '🍊', 'banana': '🍌', 'amora': '🫐'};

T _sorteia<T>(math.Random rnd, List<T> pool) => pool[rnd.nextInt(pool.length)];

/// 3 opções numéricas com a certa no meio de distratores vizinhos.
(List<String>, int) _opcoesNum(math.Random rnd, int certa, {int minimo = 0, String sufixo = ''}) {
  final valores = <int>{certa};
  var passo = 1;
  while (valores.length < 3) {
    final v = certa + (rnd.nextBool() ? passo : -passo);
    if (v >= minimo) valores.add(v);
    passo = valores.length < 3 && passo > 4 ? 1 : passo + (valores.length < 2 ? 0 : 1);
    if (passo > 9) valores.add(certa + valores.length + 1);
  }
  final lista = valores.toList()..shuffle(rnd);
  return ([for (final v in lista) '$v$sufixo'], lista.indexOf(certa));
}

int _pontosBase(int nivel) => 25 + nivel * 5;

// ------------------------------------------------------------------- 🚪 porta

Missao _mCracha(math.Random rnd, int nivel) {
  final nome = _sorteia(rnd, _nomes);
  final idade = 7 + rnd.nextInt(70);
  final frase = '$nome, $idade anos';
  final opcoes = [frase, r'$nome, $idade anos', 'nome, idade anos']..shuffle(rnd);
  return Missao(
    cena: Cena.porta,
    titulo: 'O Crachá Mágico',
    historia: 'A porta só abre para quem apresenta o crachá certo. As variáveis '
        'guardam os dados — e a interpolação monta a frase. Preveja o crachá!',
    codigo: "var nome = '$nome';\nvar idade = $idade;\nprint('\$nome, \$idade anos');",
    pergunta: 'O que o crachá vai mostrar?',
    opcoes: opcoes,
    certa: opcoes.indexOf(frase),
    explica: r'Dentro de aspas, $variavel é trocado pelo VALOR: '
        '\$nome vira $nome e \$idade vira $idade.',
    dicas: [
      '🔮 O símbolo \$ dentro de uma string puxa o VALOR da variável, não o nome dela…',
      '🔮 Onde está \$nome entra "$nome"; onde está \$idade entra $idade…',
      '🔮 O crachá mostra exatamente: $frase',
    ],
    passos: [
      PassoCena('O leitor puxa a variável nome → "$nome"', {'placa': nome}),
      PassoCena('Agora a idade → $idade', {'placa': '$nome, $idade'}),
      PassoCena('Crachá válido: "$frase" — a porta ABRE! ✅',
          {'placa': frase, 'aberta': true, 'avanco': 4}),
    ],
    dados: const {'total': 4, 'avanco': 3, 'aberta': false, 'placa': '···'},
    pontos: _pontosBase(nivel),
  );
}

Missao _mChave(math.Random rnd, int nivel) {
  final tem = rnd.nextBool();
  final variavel = _sorteia(rnd, ['temChave', 'achouChave', 'temCartao']);
  final metodo = _sorteia(rnd, ['abrir', 'destravar']);
  final msg = _sorteia(rnd, ['preciso da chave!', 'cadê a chave?', 'porta trancada!']);
  final opcoes = ['Sim, abre', 'Não abre', 'Dá erro']..shuffle(rnd);
  final certaTexto = tem ? 'Sim, abre' : 'Não abre';
  return Missao(
    cena: Cena.porta,
    titulo: 'A Chave Booleana',
    historia: 'O herói ${tem ? 'achou' : 'NÃO achou'} a chave no caminho. '
        'O if decide o destino da porta usando um bool.',
    codigo: 'var $variavel = $tem;\n'
        'if ($variavel) {\n'
        '  porta.$metodo();\n'
        '} else {\n'
        "  print('$msg');\n"
        '}',
    pergunta: 'A porta abre?',
    opcoes: opcoes,
    certa: opcoes.indexOf(certaTexto),
    explica: tem
        ? '$variavel é true → o if entra no primeiro ramo e chama porta.$metodo().'
        : '$variavel é false → o if pula pro else e a porta continua trancada.',
    dicas: [
      '🔮 O if só executa o primeiro bloco quando a condição é true…',
      '🔮 Olhe a primeira linha: $variavel = $tem…',
      '🔮 ${tem ? 'true entra no if → abre!' : 'false cai no else → não abre.'}',
    ],
    passos: [
      PassoCena('$variavel guarda $tem'),
      PassoCena(tem
          ? 'if ($tem) → entra no ramo do SIM'
          : 'if ($tem) → pula pro else'),
      if (tem)
        PassoCena('porta.$metodo() — destrancada! ✅', const {'aberta': true, 'avanco': 4})
      else
        PassoCena('"$msg" — segue trancada ⛔', const {'placa': 'sem chave'}),
    ],
    dados: const {'total': 4, 'avanco': 3, 'aberta': false, 'placa': '···'},
    pontos: _pontosBase(nivel),
  );
}

Missao _mPortaFor(math.Random rnd, int nivel) {
  final n = 3 + rnd.nextInt(3 + nivel); // 3..5+nivel
  final cont = _sorteia(rnd, ['passo', 'i', 'volta']);
  final quem = _sorteia(rnd, ['heroi', 'jogador', 'explorador']);
  final acao = _sorteia(rnd, ['abrir', 'destrancar']);
  final (opcoes, certa) = _opcoesNum(rnd, n, minimo: 1);
  return Missao(
    cena: Cena.porta,
    titulo: 'Passos até a Porta',
    historia: 'A porta está a $n passos e o herói só anda dentro do laço. '
        'Faça o for levar ele até lá!',
    codigo: 'for (var $cont = 1; $cont <= $n; $cont++) {\n'
        '  $quem.anda();\n'
        '}\n'
        'porta.$acao();',
    pergunta: 'Quantos passos o laço faz o herói andar?',
    opcoes: opcoes,
    certa: certa,
    explica: 'O contador vai de 1 até $n (o <= inclui o $n): são $n voltas, $n passos.',
    dicas: [
      '🔮 Conte de quanto até quanto o contador anda — o <= INCLUI o limite…',
      '🔮 $cont = 1, 2, …, $n — cada volta é um anda()…',
      '🔮 São exatamente $n passos.',
    ],
    passos: [
      for (var k = 1; k <= n; k++)
        PassoCena('$cont = $k → $quem.anda()  ($k de $n)', {'avanco': k}),
      PassoCena('Laço encerrado → porta.$acao() ✅', const {'aberta': true}),
    ],
    dados: {'total': n, 'avanco': 0, 'aberta': false, 'placa': ''},
    pontos: _pontosBase(nivel),
  );
}

Missao _mPortaWhileEnergia(math.Random rnd, int nivel) {
  final custo = 1 + rnd.nextInt(3); // 1..3
  final voltas = 2 + rnd.nextInt(3 + nivel); // 2..4+nivel
  final energia = custo * voltas - rnd.nextInt(custo); // ceil(e/c) == voltas
  final varE = _sorteia(rnd, ['energia', 'bateria', 'folego']);
  final quem = _sorteia(rnd, ['heroi', 'jogador']);
  final (opcoes, certa) = _opcoesNum(rnd, voltas, minimo: 1);
  final passos = <PassoCena>[];
  var e = energia;
  for (var k = 1; k <= voltas; k++) {
    final sobra = e - custo;
    passos.add(PassoCena('energia $e > 0 → anda (sobram ${sobra < 0 ? 0 : sobra})',
        {'avanco': k}));
    e = sobra;
  }
  passos.add(PassoCena('energia $e — o while para. Chegou? ✅', const {'aberta': true}));
  return Missao(
    cena: Cena.porta,
    titulo: 'Energia Contada',
    historia: 'O herói tem $energia de energia e cada passo gasta $custo. '
        'O while anda enquanto a energia durar.',
    codigo: 'var $varE = $energia;\n'
        'while ($varE > 0) {\n'
        '  $quem.anda();\n'
        '  $varE -= $custo;\n'
        '}',
    pergunta: 'Quantos passos ele dá antes de a energia acabar?',
    opcoes: opcoes,
    certa: certa,
    explica: 'A energia cai de $custo em $custo a partir de $energia: '
        'dá $voltas voltas até não sobrar nada positivo.',
    dicas: [
      '🔮 Vá descontando $custo de $energia e conte as voltas enquanto for > 0…',
      '🔮 $energia, ${energia - custo}, ${energia - 2 * custo}… quantos números positivos?',
      '🔮 São $voltas passos.',
    ],
    passos: passos,
    dados: {'total': voltas, 'avanco': 0, 'aberta': false, 'placa': ''},
    pontos: _pontosBase(nivel),
  );
}

Missao _mPortaTurbo(math.Random rnd, int nivel) {
  final p = 2 + rnd.nextInt(4); // 2..5
  final turbo = rnd.nextBool();
  final mult = 2 + rnd.nextInt(2); // x2 ou x3
  final varP = _sorteia(rnd, ['passos', 'pulos']);
  final total = turbo ? p * mult : p;
  final (opcoes, certa) = _opcoesNum(rnd, total, minimo: 1);
  return Missao(
    cena: Cena.porta,
    titulo: 'Botas de Turbo',
    historia: 'As botas ${turbo ? 'ESTÃO' : 'não estão'} carregadas (turbo = $turbo). '
        'Se o if ligar, os passos dobram.',
    codigo: 'var $varP = $p;\n'
        'var turbo = $turbo;\n'
        'if (turbo) {\n'
        '  $varP = $varP * $mult;\n'
        '}\n'
        'heroi.anda($varP);',
    pergunta: 'Com quantos passos ele chega na porta?',
    opcoes: opcoes,
    certa: certa,
    explica: turbo
        ? 'turbo é true → passos vira $p × $mult = $total antes do anda().'
        : 'turbo é false → o if não roda e ficam os $p passos originais.',
    dicas: [
      '🔮 O if só mexe nos passos se turbo for true…',
      '🔮 turbo = $turbo, então passos ${turbo ? 'dobra' : 'fica igual'}…',
      '🔮 anda($total) — são $total passos.',
    ],
    passos: [
      PassoCena('$varP começa em $p'),
      PassoCena(turbo ? 'turbo true → $varP = $p × $mult = $total 🔥' : 'turbo false → segue $p'),
      PassoCena('heroi.anda($total) → chegou! ✅', {'avanco': total, 'aberta': true}),
    ],
    dados: {'total': total, 'avanco': 0, 'aberta': false, 'placa': ''},
    pontos: _pontosBase(nivel),
  );
}

// ------------------------------------------------------------------- 🚓 blitz

Missao _mBlitzIdade(math.Random rnd, int nivel) {
  final qtd = 3 + (nivel > 1 ? rnd.nextInt(2) : 0);
  final idades = <int>[];
  while (idades.length < qtd) {
    final i = 13 + rnd.nextInt(12);
    if (!idades.contains(i)) idades.add(i);
  }
  final liberados = idades.where((i) => i >= 18).length;
  final varL = _sorteia(rnd, ['liberados', 'aprovados']);
  final (opcoes, certa) = _opcoesNum(rnd, liberados);
  return Missao(
    cena: Cena.blitz,
    titulo: 'Blitz da Maioridade',
    historia: 'O guarda parou ${idades.length} motoristas com idades $idades. '
        'Só passa quem tem 18 ou mais — o if decide.',
    codigo: 'final idades = $idades;\n'
        'var $varL = 0;\n'
        'for (final idade in idades) {\n'
        '  if (idade >= 18) {\n'
        '    $varL++;\n'
        '  }\n'
        '}\n'
        "print('\$$varL liberados');",
    pergunta: 'Quantos motoristas a blitz libera?',
    opcoes: opcoes,
    certa: certa,
    explica: 'O >= 18 aprova ${idades.where((i) => i >= 18).toList()} '
        'e barra ${idades.where((i) => i < 18).toList()}: $liberados liberado(s).',
    dicas: [
      '🔮 Passe idade por idade perguntando: é 18 ou mais?',
      '🔮 O >= INCLUI o próprio 18…',
      '🔮 Aprovados: ${idades.where((i) => i >= 18).toList()} → $liberados.',
    ],
    passos: [
      for (final (i, idade) in idades.indexed)
        PassoCena(
            '🚗 motorista de $idade anos: $idade >= 18? '
            '${idade >= 18 ? 'SIM → liberado ✅' : 'NÃO → barrado ⛔'}',
            {'atual': i, 'v$i': idade >= 18}),
      PassoCena('print → "$liberados liberados"', const {'atual': -1}),
    ],
    dados: {'rotulos': [for (final i in idades) '$i anos'], 'atual': -1},
    pontos: _pontosBase(nivel),
  );
}

Missao _mBlitzVelocidade(math.Random rnd, int nivel) {
  final limite = _sorteia(rnd, [40, 50, 60, 70, 80]);
  final qtd = 3 + (nivel > 1 ? rnd.nextInt(2) : 0);
  final vels = <int>[];
  while (vels.length < qtd) {
    final v = limite - 25 + rnd.nextInt(55);
    if (!vels.contains(v)) vels.add(v);
  }
  final multas = vels.where((v) => v > limite).length;
  final (opcoes, certa) = _opcoesNum(rnd, multas);
  return Missao(
    cena: Cena.blitz,
    titulo: 'Radar Esperto',
    historia: 'O radar marca limite de $limite km/h e mediu $vels. '
        'Multa só ACIMA do limite — repare que é > , não >=.',
    codigo: 'final velocidades = $vels;\n'
        'var multas = 0;\n'
        'for (final v in velocidades) {\n'
        '  if (v > $limite) {\n'
        '    multas++;\n'
        '  }\n'
        '}\n'
        "print('\$multas multas');",
    pergunta: 'Quantas multas o radar emite?',
    opcoes: opcoes,
    certa: certa,
    explica: 'Só conta quem passou de $limite: '
        '${vels.where((v) => v > limite).toList()} → $multas multa(s). '
        'Quem cravou $limite exato NÃO leva (o > exclui o igual).',
    dicas: [
      '🔮 Compare cada velocidade com $limite — o > NÃO inclui o empate…',
      '🔮 Acima do limite: ${vels.where((v) => v > limite).toList()}…',
      '🔮 São $multas multas.',
    ],
    passos: [
      for (final (i, v) in vels.indexed)
        PassoCena(
            '🚗 a $v km/h: $v > $limite? '
            '${v > limite ? 'SIM → multado ⛔' : 'NÃO → segue ✅'}',
            {'atual': i, 'v$i': v <= limite}),
      PassoCena('print → "$multas multas"', const {'atual': -1}),
    ],
    dados: {'rotulos': [for (final v in vels) '$v km/h'], 'atual': -1},
    pontos: _pontosBase(nivel),
  );
}

Missao _mBlitzCinto(math.Random rnd, int nivel) {
  final pares = [for (var i = 0; i < 3; i++) (rnd.nextBool(), rnd.nextBool())];
  final liberados = pares.where((p) => p.$1 && p.$2).length;
  final (opcoes, certa) = _opcoesNum(rnd, liberados);
  String b(bool v) => v ? 'true' : 'false';
  return Missao(
    cena: Cena.blitz,
    titulo: 'Cinto E Documento',
    historia: 'Nesta blitz só passa quem está de cinto E com documento. '
        'O && exige os DOIS ao mesmo tempo.',
    codigo: 'final motoristas = [\n'
        '${[for (final p in pares) '  [${b(p.$1)}, ${b(p.$2)}],'].join('\n')}\n'
        '];\n'
        'var liberados = 0;\n'
        'for (final m in motoristas) {\n'
        '  if (m[0] && m[1]) {\n'
        '    liberados++;\n'
        '  }\n'
        '}\n'
        'print(liberados);',
    pergunta: 'Quantos motoristas passam na blitz?',
    opcoes: opcoes,
    certa: certa,
    explica: 'O && só é true com true dos dois lados: $liberados motorista(s) '
        'cumpriam as duas regras.',
    dicas: [
      '🔮 true && false dá false — basta UM não pra reprovar…',
      '🔮 Procure as duplas [true, true]…',
      '🔮 São $liberados com cinto E documento.',
    ],
    passos: [
      for (final (i, p) in pares.indexed)
        PassoCena(
            '🚗 cinto ${p.$1 ? '✔' : '✘'} · documento ${p.$2 ? '✔' : '✘'} → '
            '${p.$1 && p.$2 ? 'liberado ✅' : 'barrado ⛔'}',
            {'atual': i, 'v$i': p.$1 && p.$2}),
      PassoCena('print → $liberados', const {'atual': -1}),
    ],
    dados: {
      'rotulos': [
        for (final p in pares) '${p.$1 ? '🥋' : '✘'} ${p.$2 ? '📄' : '✘'}'
      ],
      'atual': -1,
    },
    pontos: _pontosBase(nivel),
  );
}

// ---------------------------------------------------------------- 🍇 colheita

Missao _mColheitaAdd(math.Random rnd, int nivel) {
  final pool = [..._frutas]..shuffle(rnd);
  final base = pool.take(1 + rnd.nextInt(2)).toList();
  final novas = pool.skip(base.length).take(2 + rnd.nextInt(2)).toList();
  final total = base.length + novas.length;
  final varC = _sorteia(rnd, ['cesta', 'sacola', 'caixa']);
  final (opcoes, certa) = _opcoesNum(rnd, total, minimo: 1);
  return Missao(
    cena: Cena.colheita,
    titulo: 'Cesta Crescente',
    historia: 'A cesta começa com $base e o pomar ainda dá ${novas.length} '
        'fruta(s). Cada add() aumenta o length.',
    codigo: "final $varC = [${base.map((f) => "'$f'").join(', ')}];\n"
        '${[for (final f in novas) "$varC.add('$f');"].join('\n')}\n'
        'print($varC.length);',
    pergunta: 'Quantas frutas terminam na cesta?',
    opcoes: opcoes,
    certa: certa,
    explica: '${base.length} inicial(is) + ${novas.length} add(s) = $total — '
        'length conta os elementos.',
    dicas: [
      '🔮 Some o que a cesta já tinha com cada add()…',
      '🔮 Começou com ${base.length}, entraram mais ${novas.length}…',
      '🔮 length = $total.',
    ],
    passos: [
      for (final (i, f) in novas.indexed)
        PassoCena("$varC.add('$f') → ${base.length + i + 1} na cesta",
            {'colhidas': base.length + i + 1}),
      PassoCena('print(cesta.length) → $total 🧺'),
    ],
    dados: {
      'total': total,
      'colhidas': base.length,
      'emoji': _frutaEmoji[novas.first] ?? '🍎',
    },
    pontos: _pontosBase(nivel),
  );
}

Missao _mColheitaWhere(math.Random rnd, int nivel) {
  final pool = [..._frutas]..shuffle(rnd);
  final frutas = pool.take(4 + (nivel > 1 ? 1 : 0)).toList();
  final corte = 3 + rnd.nextInt(2); // 3..4
  final grandes = frutas.where((f) => f.length > corte).toList();
  final varF = _sorteia(rnd, ['frutas', 'pomar']);
  final varG = _sorteia(rnd, ['grandes', 'escolhidas']);
  final (opcoes, certa) = _opcoesNum(rnd, grandes.length);
  return Missao(
    cena: Cena.colheita,
    titulo: 'Filtro do Pomar',
    historia: 'Só entram na cesta frutas com nome de MAIS de $corte letras. '
        'O where filtra a lista inteira de uma vez.',
    codigo: "final $varF = [${frutas.map((f) => "'$f'").join(', ')}];\n"
        'final $varG = $varF.where((f) => f.length > $corte).toList();\n'
        'print($varG.length);',
    pergunta: 'Quantas frutas passam no filtro?',
    opcoes: opcoes,
    certa: certa,
    explica: 'Contando letras: '
        '${[for (final f in frutas) '$f(${f.length})'].join(' · ')} — '
        'passam ${grandes.length}.',
    dicas: [
      '🔮 Conte as letras de cada fruta e compare com $corte (o > exclui o empate)…',
      '🔮 ${frutas.first} tem ${frutas.first.length} letras — e as outras?',
      '🔮 Passam: $grandes.',
    ],
    passos: [
      for (final (i, f) in frutas.indexed)
        PassoCena(
            '"$f" tem ${f.length} letras > $corte? '
            '${f.length > corte ? 'SIM → colhe ✅' : 'NÃO → fica 🍂'}',
            {'colhidas': frutas.take(i + 1).where((x) => x.length > corte).length}),
      PassoCena('print → ${grandes.length} na cesta 🧺'),
    ],
    dados: {
      'total': grandes.length,
      'colhidas': 0,
      'emoji': _frutaEmoji[frutas.first] ?? '🍎',
    },
    pontos: _pontosBase(nivel),
  );
}

Missao _mColheitaSoma(math.Random rnd, int nivel) {
  final cestos = [for (var i = 0; i < 3 + (nivel > 1 ? 1 : 0); i++) 1 + rnd.nextInt(5 + nivel)];
  final total = cestos.fold<int>(0, (a, b) => a + b);
  final varT = _sorteia(rnd, ['total', 'soma']);
  final varCe = _sorteia(rnd, ['cestos', 'caixas']);
  final (opcoes, certa) = _opcoesNum(rnd, total, minimo: 1);
  return Missao(
    cena: Cena.colheita,
    titulo: 'Soma da Colheita',
    historia: 'Cada cesto do pomar tem uma quantidade: $cestos. '
        'O for-in soma tudo num total só.',
    codigo: 'final $varCe = $cestos;\n'
        'var $varT = 0;\n'
        'for (final c in $varCe) {\n'
        '  $varT += c;\n'
        '}\n'
        "print('\$$varT frutas');",
    pergunta: 'Quantas frutas no total?',
    opcoes: opcoes,
    certa: certa,
    explica: '${cestos.join(' + ')} = $total — o += acumula cesto a cesto.',
    dicas: [
      '🔮 O total começa em 0 e cada volta soma um cesto…',
      '🔮 Vá somando: ${cestos.join(', ')}…',
      '🔮 Dá $total.',
    ],
    passos: [
      for (var i = 0; i < cestos.length; i++)
        PassoCena(
            '$varT += ${cestos[i]} → ${cestos.take(i + 1).fold<int>(0, (a, b) => a + b)}',
            {'colhidas': cestos.take(i + 1).fold<int>(0, (a, b) => a + b)}),
      PassoCena('print → "$total frutas" 🧺'),
    ],
    dados: {'total': total, 'colhidas': 0, 'emoji': '🍎'},
    pontos: _pontosBase(nivel),
  );
}

// ---------------------------------------------------------------- 🚦 semáforo

Missao _mSemaforoSwitch(math.Random rnd, int nivel) {
  final cor = _sorteia(rnd, ['verde', 'amarelo', 'vermelho']);
  final acao = switch (cor) { 'verde' => 'siga', 'amarelo' => 'atencao', _ => 'pare' };
  final rotulo = switch (cor) { 'verde' => 'Segue viagem', 'amarelo' => 'Fica atento', _ => 'Para tudo' };
  final varCor = _sorteia(rnd, ['cor', 'sinal', 'luz']);
  final veic = _sorteia(rnd, ['carro', 'onibus', 'trem']);
  final comDefault = rnd.nextBool();
  final opcoes = ['Segue viagem', 'Fica atento', 'Para tudo']..shuffle(rnd);
  return Missao(
    cena: Cena.semaforo,
    titulo: 'O Cruzamento',
    historia: 'O semáforo acendeu $cor. O switch escolhe UM caso — '
        'qual comando o carro recebe?',
    codigo: "var $varCor = '$cor';\n"
        'switch ($varCor) {\n'
        "  case 'verde':\n"
        '    $veic.siga();\n'
        "  case 'amarelo':\n"
        '    $veic.atencao();\n'
        '${comDefault ? '  default:' : "  case 'vermelho':"}\n'
        '    $veic.pare();\n'
        '}',
    pergunta: 'O que o carro faz?',
    opcoes: opcoes,
    certa: opcoes.indexOf(rotulo),
    explica: "cor é '$cor' → o switch casa com "
        "${cor != 'vermelho' ? "case '$cor'" : (comDefault ? 'o default' : "case 'vermelho'")} e chama $veic.$acao().",
    dicas: [
      '🔮 O switch compara a cor com cada case, na ordem…',
      "🔮 A variável guarda '$cor'…",
      '🔮 Cai em $veic.$acao() → $rotulo.',
    ],
    passos: [
      PassoCena("$varCor = '$cor' — o semáforo acende", {'cor': cor}),
      PassoCena(cor != 'vermelho'
          ? "switch casa com case '$cor'"
          : (comDefault ? 'Nenhum case casou → vai pro default' : "switch casa com case 'vermelho'")),
      PassoCena('$veic.$acao() → $rotulo ${cor == 'verde' ? '✅' : ''}',
          {'acao': acao}),
    ],
    dados: const {'cor': 'apagado', 'acao': ''},
    pontos: _pontosBase(nivel),
  );
}

Missao _mSemaforoTernario(math.Random rnd, int nivel) {
  final fila = 2 + rnd.nextInt(9);
  final corte = 4 + rnd.nextInt(4);
  final (longo, curto) = _sorteia(rnd, [(30, 10), (25, 10), (40, 15), (30, 12)]);
  final tempo = fila > corte ? longo : curto;
  final opcoes = ['$longo segundos', '$curto segundos', '0 segundos']..shuffle(rnd);
  return Missao(
    cena: Cena.semaforo,
    titulo: 'Verde Sob Medida',
    historia: 'Há $fila carro(s) na fila. Se passar de $corte, o verde dura ${longo}s; '
        'senão, ${curto}s. Tudo numa linha: o ternário.',
    codigo: 'var fila = $fila;\n'
        'var verde = fila > $corte ? $longo : $curto;\n'
        "print('verde por \$verde s');",
    pergunta: 'Quantos segundos de verde?',
    opcoes: opcoes,
    certa: opcoes.indexOf('$tempo segundos'),
    explica: '$fila > $corte é ${fila > corte} → o ternário devolve o '
        '${fila > corte ? 'primeiro' : 'segundo'} valor: $tempo.',
    dicas: [
      '🔮 condição ? valorSeSim : valorSeNão…',
      '🔮 Compare: $fila > $corte…',
      '🔮 Dá $tempo segundos.',
    ],
    passos: [
      PassoCena('fila = $fila carros na espera'),
      PassoCena('$fila > $corte? ${fila > corte ? 'SIM → $longo' : 'NÃO → $curto'}'),
      PassoCena('Verde aceso por ${tempo}s ✅', {'cor': 'verde', 'acao': 'siga'}),
    ],
    dados: const {'cor': 'vermelho', 'acao': ''},
    pontos: _pontosBase(nivel),
  );
}

// ------------------------------------------------------------------ 🚀 foguete

Missao _mFogueteContagem(math.Random rnd, int nivel) {
  final n = 3 + rnd.nextInt(2 + nivel);
  final cont = _sorteia(rnd, ['i', 't', 'n']);
  final grito = _sorteia(rnd, ['DECOLAR!', 'PARTIU!', 'VOAR!', 'IGNICAO!', 'JA!']);
  final (opcoes, certa) = _opcoesNum(rnd, n, minimo: 1);
  return Missao(
    cena: Cena.foguete,
    titulo: 'Contagem Regressiva',
    historia: 'A torre grita a contagem de $n até 1 e o foguete parte. '
        'É um for de trás pra frente (i--).',
    codigo: 'for (var $cont = $n; $cont >= 1; $cont--) {\n'
        '  print($cont);\n'
        '}\n'
        "print('$grito');",
    pergunta: 'Quantos números a torre grita antes do voo?',
    opcoes: opcoes,
    certa: certa,
    explica: 'De $n descendo até 1 (o >= inclui o 1): são $n gritos, aí vem o DECOLAR.',
    dicas: [
      '🔮 O contador começa em $n e desce de 1 em 1…',
      '🔮 Pare quando i < 1 — o 1 ainda entra…',
      '🔮 $n números: $n, ${n - 1}, …, 1.',
    ],
    passos: [
      for (var i = n; i >= 1; i--) PassoCena('print($i)  📢', {'contagem': i}),
      PassoCena('$grito 🚀', const {'contagem': 0, 'altura': 1.0}),
    ],
    dados: {'contagem': n, 'altura': 0.0},
    pontos: _pontosBase(nivel),
  );
}

Missao _mFogueteCombustivel(math.Random rnd, int nivel) {
  final custo = 2 + rnd.nextInt(3); // 2..4
  final estagios = 2 + rnd.nextInt(2 + nivel);
  final tanque = custo * estagios + rnd.nextInt(custo); // e ~/ c == estagios
  final varComb = _sorteia(rnd, ['combustivel', 'tanque']);
  final (opcoes, certa) = _opcoesNum(rnd, estagios, minimo: 1);
  final passos = <PassoCena>[];
  var c = tanque;
  for (var k = 1; k <= estagios; k++) {
    passos.add(PassoCena(
        'combustível $c >= $custo → sobe estágio $k (sobra ${c - custo})',
        {'altura': k / estagios, 'contagem': 0}));
    c -= custo;
  }
  passos.add(PassoCena('combustível $c < $custo — órbita alcançada! 🛰️'));
  return Missao(
    cena: Cena.foguete,
    titulo: 'Tanque Calculado',
    historia: 'O foguete tem $tanque de combustível e cada estágio queima $custo. '
        'O while sobe enquanto der.',
    codigo: 'var $varComb = $tanque;\n'
        'var estagios = 0;\n'
        'while ($varComb >= $custo) {\n'
        '  estagios++;\n'
        '  $varComb -= $custo;\n'
        '}\n'
        'print(estagios);',
    pergunta: 'Quantos estágios ele sobe?',
    opcoes: opcoes,
    certa: certa,
    explica: '$tanque ÷ $custo dá $estagios queimas inteiras — o resto '
        '(${tanque - custo * estagios}) não paga outro estágio.',
    dicas: [
      '🔮 Cada volta desconta $custo — enquanto sobrar pelo menos $custo…',
      '🔮 $tanque, ${tanque - custo}, ${tanque - 2 * custo}… até ficar menor que $custo…',
      '🔮 São $estagios estágios.',
    ],
    passos: passos,
    dados: const {'contagem': 0, 'altura': 0.0},
    pontos: _pontosBase(nivel),
  );
}

// -------------------------------------------------------------------- 🌉 ponte

Missao _mPontePranchas(math.Random rnd, int nivel) {
  final prancha = 2 + rnd.nextInt(3); // 2..4
  final pranchas = 2 + rnd.nextInt(2 + nivel);
  final vao = prancha * pranchas - rnd.nextInt(prancha); // ceil == pranchas
  final varCob = _sorteia(rnd, ['coberto', 'construido']);
  final varPr = _sorteia(rnd, ['pranchas', 'tabuas']);
  final (opcoes, certa) = _opcoesNum(rnd, pranchas, minimo: 1);
  final passos = <PassoCena>[];
  var coberto = 0;
  for (var k = 1; k <= pranchas; k++) {
    coberto += prancha;
    passos.add(PassoCena(
        'coberto ${coberto - prancha} < $vao → prancha $k (agora ${coberto > vao ? vao : coberto} m)',
        {'colocadas': k}));
  }
  passos.add(const PassoCena('Vão coberto — travessia! 🎉', {'travessia': 1.0}));
  return Missao(
    cena: Cena.ponte,
    titulo: 'Ponte Sob Medida',
    historia: 'O abismo tem $vao m e cada prancha cobre $prancha m. '
        'O while coloca pranchas até dar pra atravessar.',
    codigo: 'var $varCob = 0;\n'
        'var $varPr = 0;\n'
        'while ($varCob < $vao) {\n'
        '  $varPr++;\n'
        '  $varCob += $prancha;\n'
        '}\n'
        'print($varPr);',
    pergunta: 'Quantas pranchas a ponte precisa?',
    opcoes: opcoes,
    certa: certa,
    explica: '$vao ÷ $prancha arredondando PRA CIMA dá $pranchas — a última '
        'prancha pode sobrar um pedacinho, mas precisa existir.',
    dicas: [
      '🔮 Some $prancha em $prancha até alcançar $vao…',
      '🔮 Se sobrar um restinho, ainda precisa de mais uma prancha…',
      '🔮 $pranchas pranchas.',
    ],
    passos: passos,
    dados: {'pranchas': pranchas, 'colocadas': 0, 'travessia': 0.0},
    pontos: _pontosBase(nivel),
  );
}

// ------------------------------------------------------------------ 🛒 mercado

const _mercadorias = [
  ('pao', '🍞'),
  ('leite', '🥛'),
  ('queijo', '🧀'),
  ('suco', '🧃'),
  ('bolo', '🍰'),
  ('mel', '🍯'),
];

Missao _mMercadoPreco(math.Random rnd, int nivel) {
  final itens = ([..._mercadorias]..shuffle(rnd)).take(4).toList();
  final naLista = itens.take(3).toList();
  final precos = [for (final _ in naLista) 2 + rnd.nextInt(8)];
  final acha = rnd.nextBool();
  final consultaIdx = rnd.nextInt(3);
  final consulta = acha ? naLista[consultaIdx].$1 : itens[3].$1;
  final valor = acha ? precos[consultaIdx] : 0;
  final mapa =
      '{${[for (final (i, p) in naLista.indexed) "'${p.$1}': ${precos[i]}"].join(', ')}}';
  final opcoes = <String>{'$valor', 'null', acha ? '0' : '${precos[0]}'}.toList()
    ..shuffle(rnd);
  return Missao(
    cena: Cena.mercado,
    titulo: 'Visor do Caixa',
    historia: 'O caixa consulta o preço de "$consulta" no Map. Se a chave não '
        'existir, o ?? salva o visor com um 0.',
    codigo: 'final precos = $mapa;\n'
        "print(precos['$consulta'] ?? 0);",
    pergunta: 'O que aparece no visor do caixa?',
    opcoes: opcoes,
    certa: opcoes.indexOf('$valor'),
    explica: acha
        ? "A chave '$consulta' existe no Map e vale $valor — o ?? nem é usado."
        : "'$consulta' NÃO está no Map → precos['$consulta'] é null → o ?? entrega o 0.",
    dicas: [
      '🔮 Procure a chave entre as chaves do Map, letra por letra…',
      "🔮 '$consulta' ${acha ? 'ESTÁ' : 'NÃO está'} na lista…",
      '🔮 O visor mostra $valor.',
    ],
    passos: [
      PassoCena("procura a chave '$consulta' no Map…",
          {'atual': acha ? consultaIdx : -1, 'display': '?'}),
      PassoCena(
          acha
              ? "achou! precos['$consulta'] = $valor"
              : "não achou → null… mas o ?? segura: 0",
          {'display': '$valor'}),
      PassoCena('visor: $valor ✅'),
    ],
    dados: {
      'rotulos': [
        for (final (i, p) in naLista.indexed) '${p.$2} ${p.$1} · ${precos[i]}'
      ],
      'atual': -1,
      'display': '···',
      'valor': valor,
    },
    pontos: _pontosBase(nivel),
  );
}

Missao _mMercadoTotal(math.Random rnd, int nivel) {
  final itens = ([..._mercadorias]..shuffle(rnd)).take(3).toList();
  final precos = [for (final _ in itens) 2 + rnd.nextInt(7 + nivel)];
  final total = precos.fold<int>(0, (a, b) => a + b);
  final varT = _sorteia(rnd, ['total', 'conta']);
  final mapa =
      '{${[for (final (i, p) in itens.indexed) "'${p.$1}': ${precos[i]}"].join(', ')}}';
  final (opcoes, certa) = _opcoesNum(rnd, total, minimo: 1);
  return Missao(
    cena: Cena.mercado,
    titulo: 'Conta da Feira',
    historia: 'Hora de fechar a compra: o for-in percorre os VALORES do Map '
        'e soma tudo no caixa.',
    codigo: 'final precos = $mapa;\n'
        'var $varT = 0;\n'
        'for (final p in precos.values) {\n'
        '  $varT += p;\n'
        '}\n'
        'print($varT);',
    pergunta: 'Qual o total da compra?',
    opcoes: opcoes,
    certa: certa,
    explica: '${precos.join(' + ')} = $total — .values entrega só os preços, '
        'sem as chaves.',
    dicas: [
      '🔮 Ignore os nomes: some só os números do Map…',
      '🔮 ${precos.join(', ')} — vá acumulando…',
      '🔮 Dá $total.',
    ],
    passos: [
      for (var i = 0; i < precos.length; i++)
        PassoCena(
            '$varT += ${precos[i]} → ${precos.take(i + 1).fold<int>(0, (a, b) => a + b)}',
            {'atual': i, 'display': '${precos.take(i + 1).fold<int>(0, (a, b) => a + b)}'}),
      PassoCena('visor final: $total ✅', const {'atual': -1}),
    ],
    dados: {
      'rotulos': [
        for (final (i, p) in itens.indexed) '${p.$2} ${p.$1} · ${precos[i]}'
      ],
      'atual': -1,
      'display': '···',
      'total': total,
    },
    pontos: _pontosBase(nivel),
  );
}

Missao _mMercadoEstoque(math.Random rnd, int nivel) {
  final itens = ([..._mercadorias]..shuffle(rnd)).take(3).toList();
  final naLista = itens.take(2).toList();
  final precos = [for (final _ in naLista) 2 + rnd.nextInt(8)];
  final tem = rnd.nextBool();
  final alvo = tem ? naLista[rnd.nextInt(2)].$1 : itens[2].$1;
  final mapa =
      '{${[for (final (i, p) in naLista.indexed) "'${p.$1}': ${precos[i]}"].join(', ')}}';
  final opcoes = ['tem $alvo!', 'em falta', 'dá erro']..shuffle(rnd);
  final certaTexto = tem ? 'tem $alvo!' : 'em falta';
  return Missao(
    cena: Cena.mercado,
    titulo: 'Tem no Estoque?',
    historia: 'O freguês quer "$alvo". O containsKey pergunta ao Map se a '
        'chave existe — sem risco de null.',
    codigo: 'final precos = $mapa;\n'
        "if (precos.containsKey('$alvo')) {\n"
        "  print('tem $alvo!');\n"
        '} else {\n'
        "  print('em falta');\n"
        '}',
    pergunta: 'O que o caixa responde?',
    opcoes: opcoes,
    certa: opcoes.indexOf(certaTexto),
    explica: tem
        ? "'$alvo' é uma das chaves → containsKey devolve true → primeiro ramo."
        : "'$alvo' não está entre as chaves → false → cai no else.",
    dicas: [
      '🔮 containsKey só olha as CHAVES, não os valores…',
      "🔮 As chaves são: ${naLista.map((p) => p.$1).join(' e ')}…",
      '🔮 Resposta: $certaTexto',
    ],
    passos: [
      PassoCena("containsKey('$alvo') vasculha as chaves…", const {'display': '?'}),
      PassoCena(tem ? 'true → primeiro ramo' : 'false → else'),
      PassoCena('visor: "$certaTexto" ${tem ? '✅' : '🍂'}', {'display': certaTexto}),
    ],
    dados: {
      'rotulos': [
        for (final (i, p) in naLista.indexed) '${p.$2} ${p.$1} · ${precos[i]}'
      ],
      'atual': -1,
      'display': '···',
    },
    pontos: _pontosBase(nivel),
  );
}

// -------------------------------------------------------------------- 🔐 cofre

const _senhas = ['manga', 'kiwi', 'tesouro', 'segredo', 'pacman', 'widget', 'dardo', 'amora', 'futuro', 'codigo', 'pixel', 'cometa'];

Missao _mCofreSenha(math.Random rnd, int nivel) {
  final senha = _sorteia(rnd, _senhas);
  final varS = _sorteia(rnd, ['senha', 'codigo', 'chave']);
  final (opcoes, certa) = _opcoesNum(rnd, senha.length, minimo: 1);
  return Missao(
    cena: Cena.cofre,
    titulo: 'Senha do Cofre',
    historia: 'O painel do cofre pede um dígito para CADA letra da senha '
        '"$senha". O length conta por você.',
    codigo: "final $varS = '$senha';\n"
        'print($varS.length);',
    pergunta: 'Quantos dígitos o painel vai pedir?',
    opcoes: opcoes,
    certa: certa,
    explica: '"$senha" tem ${senha.length} letras — length conta os '
        'caracteres da String.',
    dicas: [
      '🔮 Conte as letras da palavra entre aspas…',
      '🔮 ${senha.split('').join(' · ')} …',
      '🔮 São ${senha.length}.',
    ],
    passos: [
      for (var k = 1; k <= senha.length; k++)
        PassoCena('conta "${senha[k - 1]}" → $k', {'display': '*' * k}),
      PassoCena('length = ${senha.length} — o cofre ABRE! 💎',
          {'display': '${senha.length}', 'aberto': true}),
    ],
    dados: {'display': '···', 'aberto': false, 'senha': senha},
    pontos: _pontosBase(nivel),
  );
}

Missao _mCofreUpper(math.Random rnd, int nivel) {
  final senha = _sorteia(rnd, _senhas);
  final varS = _sorteia(rnd, ['senha', 'palavra']);
  final grito = senha.toUpperCase();
  final capitalizada = senha[0].toUpperCase() + senha.substring(1);
  final opcoes = [grito, senha, capitalizada]..shuffle(rnd);
  return Missao(
    cena: Cena.cofre,
    titulo: 'Cofre aos Gritos',
    historia: 'Este cofre só entende a senha GRITADA. O toUpperCase '
        'transforma o texto inteiro.',
    codigo: "final $varS = '$senha';\n"
        'print($varS.toUpperCase());',
    pergunta: 'O que aparece no painel?',
    opcoes: opcoes,
    certa: opcoes.indexOf(grito),
    explica: 'toUpperCase() põe TODAS as letras em maiúsculas: "$grito". '
        '(Só a primeira seria outra função.)',
    dicas: [
      '🔮 toUpperCase não escolhe letra: pega TODAS…',
      '🔮 "$senha" vira tudo maiúsculo…',
      '🔮 Painel: $grito',
    ],
    passos: [
      PassoCena('lê "$senha"…', {'display': senha}),
      PassoCena('toUpperCase() grita cada letra', {'display': grito}),
      PassoCena('"$grito" aceito — ABRE! 💎', const {'aberto': true}),
    ],
    dados: const {'display': '···', 'aberto': false},
    pontos: _pontosBase(nivel),
  );
}

Missao _mCofreNull(math.Random rnd, int nivel) {
  final temBilhete = rnd.nextBool();
  final escrita = _sorteia(rnd, ['sesamo', 'abracadabra', 'plimplim', 'alakazan', 'shazam', 'bibidi']);
  final reserva = _sorteia(rnd, ['chave mestra', 'plano B', 'senha reserva']);
  final resultado = temBilhete ? escrita : reserva;
  final opcoes = [escrita, reserva, 'null']..shuffle(rnd);
  return Missao(
    cena: Cena.cofre,
    titulo: 'Bilhete Perdido',
    historia: temBilhete
        ? 'O bilhete com a senha FOI encontrado. O ?? só age quando o valor é null.'
        : 'O bilhete com a senha se perdeu (a variável ficou null). Sorte que '
            'o ?? tem um plano B.',
    codigo: temBilhete
        ? "String? bilhete = '$escrita';\n"
            "final senha = bilhete ?? '$reserva';\n"
            'print(senha);'
        : 'String? bilhete;\n'
            "final senha = bilhete ?? '$reserva';\n"
            'print(senha);',
    pergunta: 'Qual senha vai pro painel?',
    opcoes: opcoes,
    certa: opcoes.indexOf(resultado),
    explica: temBilhete
        ? 'bilhete NÃO é null ("$escrita") → o ?? nem é consultado.'
        : 'bilhete é null → o ?? entrega o valor reserva: "$reserva".',
    dicas: [
      '🔮 O ?? só entra em cena quando o lado esquerdo é null…',
      '🔮 bilhete ${temBilhete ? 'tem valor' : 'está null'}…',
      '🔮 Painel: $resultado',
    ],
    passos: [
      PassoCena(temBilhete ? 'bilhete = "$escrita"' : 'bilhete = null 😱',
          {'display': temBilhete ? escrita : 'null'}),
      PassoCena(temBilhete ? 'não é null → ?? fica quieto' : 'null → ?? aciona o plano B'),
      PassoCena('senha "$resultado" — ABRE! 💎',
          {'display': resultado, 'aberto': true}),
    ],
    dados: const {'display': '···', 'aberto': false},
    pontos: _pontosBase(nivel),
  );
}
