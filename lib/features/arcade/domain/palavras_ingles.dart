// Vocabulário de inglês para os jogos de digitação (Chuva, Rali e Turismo)
// na vertente PAC·ENGLISH: palavras de alta frequência (a base do que se
// ouve e lê), só letras [A-Za-z], em minúsculas — exceto dias, meses e
// nomes que em inglês SEMPRE começam com maiúscula.

/// 3–5 letras (nível 1).
const List<String> palavrasCurtasEn = [
  'the', 'and', 'you', 'have', 'that', 'with', 'this', 'from', 'they', 'what',
  'know', 'want', 'like', 'time', 'good', 'make', 'work', 'call', 'need', 'help',
  'home', 'water', 'food', 'today', 'night', 'happy', 'thank', 'sorry', 'where', 'when',
  'think', 'about', 'right', 'there', 'could', 'would', 'every', 'house', 'money', 'later',
  'early', 'again', 'small', 'big', 'fast', 'slow', 'open', 'close', 'buy', 'sell',
  'eat', 'drink', 'sleep', 'walk', 'talk', 'read', 'write', 'learn', 'teach', 'Monday',
];

/// 6–8 letras (nível 2).
const List<String> palavrasMediasEn = [
  'because', 'people', 'little', 'should', 'before', 'after', 'always', 'never', 'really',
  'thing', 'friend', 'family', 'mother', 'father', 'brother', 'sister', 'morning', 'evening',
  'weekend', 'kitchen', 'weather', 'travel', 'airport', 'ticket', 'coffee', 'dinner', 'breakfast',
  'meeting', 'project', 'manager', 'company', 'office', 'problem', 'answer', 'question', 'change',
  'better', 'enough', 'without', 'through', 'already', 'usually', 'tonight', 'tomorrow',
  'remember', 'believe', 'explain', 'improve', 'deliver', 'English', 'Friday', 'January',
];

/// 9+ letras (nível 3 — os chefões).
const List<String> palavrasLongasEn = [
  'beautiful', 'different', 'important', 'something', 'everybody', 'yesterday', 'interview',
  'available', 'excellent', 'necessary', 'restaurant', 'experience', 'understand', 'definitely',
  'afternoon', 'apartment', 'neighborhood', 'environment', 'opportunity', 'information',
  'comfortable', 'appointment', 'development', 'requirement', 'unfortunately', 'immediately',
  'responsibility', 'communication', 'September', 'Wednesday', 'deployment', 'documentation',
];

/// Curiosidades de inglês entre as fases do Arcade (no lugar das dicas de
/// código). Texto puro, curtinho.
const List<String> dicasIngles = [
  'Em inglês o sujeito é obrigatório: "It is raining." — nunca só "Is raining."',
  'Para existir, use there is / there are: "There is a problem." (e não "Have a problem.")',
  'Idade usa be, não have: "I am 30 years old."',
  'Actually = na verdade (e não "atualmente", que é currently).',
  'Pretend = fingir. "Pretender" em inglês é intend ou plan.',
  'Adjetivo vem antes do nome e não vai para o plural: "two big cars".',
  'Na 3ª pessoa do presente, o verbo ganha -s: "She works from home."',
  'Perguntas no presente pedem do/does: "Do you like coffee?"',
  'Push = empurrar (é o contrário do que parece!). Pull = puxar.',
  'Library = biblioteca. Livraria é bookstore.',
  'Parents = pais (pai e mãe). Parentes são relatives.',
  'In para meses e anos, on para dias, at para horas: "at 9 a.m. on Monday".',
  'Make = fabricar/causar; do = realizar tarefa: make a cake, do homework.',
  'People já é plural: "People are nice." (nunca "people is").',
  'Information e advice não vão para o plural: "some information", "a piece of advice".',
  'Say é dizer algo; tell é contar PARA alguém: "Tell me the truth."',
];

/// Tradução curta (o que aparece EMBAIXO da palavra nos jogos) de cada palavra
/// das três listas acima — a reserva quando a palavra não veio das lições.
/// Chave em minúsculas.
const Map<String, String> traducoesEn = {
  'the': 'o', 'and': 'e', 'you': 'você', 'have': 'ter', 'that': 'que', 'with': 'com', 'this': 'este',
  'from': 'de', 'they': 'eles', 'what': 'o que', 'know': 'saber', 'want': 'querer', 'like': 'gostar',
  'time': 'tempo', 'good': 'bom', 'make': 'fazer', 'work': 'trabalhar', 'call': 'ligar', 'need': 'precisar',
  'help': 'ajudar', 'home': 'casa', 'water': 'água', 'food': 'comida', 'today': 'hoje', 'night': 'noite',
  'happy': 'feliz', 'thank': 'agradecer', 'sorry': 'desculpe', 'where': 'onde', 'when': 'quando',
  'think': 'pensar', 'about': 'sobre', 'right': 'certo', 'there': 'lá', 'could': 'poderia', 'would': 'iria',
  'every': 'cada', 'house': 'casa', 'money': 'dinheiro', 'later': 'mais tarde', 'early': 'cedo',
  'again': 'de novo', 'small': 'pequeno', 'big': 'grande', 'fast': 'rápido', 'slow': 'lento',
  'open': 'abrir', 'close': 'fechar', 'buy': 'comprar', 'sell': 'vender', 'eat': 'comer', 'drink': 'beber',
  'sleep': 'dormir', 'walk': 'andar', 'talk': 'falar', 'read': 'ler', 'write': 'escrever',
  'learn': 'aprender', 'teach': 'ensinar', 'monday': 'segunda-feira', 'because': 'porque',
  'people': 'pessoas', 'little': 'pequeno', 'should': 'deveria', 'before': 'antes', 'after': 'depois de',
  'always': 'sempre', 'never': 'nunca', 'really': 'realmente', 'thing': 'coisa', 'friend': 'amigo',
  'family': 'família', 'mother': 'mãe', 'father': 'pai', 'brother': 'irmão', 'sister': 'irmã',
  'morning': 'manhã', 'evening': 'fim de tarde', 'weekend': 'fim de semana', 'kitchen': 'cozinha',
  'weather': 'tempo', 'travel': 'viajar', 'airport': 'aeroporto', 'ticket': 'passagem', 'coffee': 'café',
  'dinner': 'jantar', 'breakfast': 'café da manhã', 'meeting': 'reunião', 'project': 'projeto',
  'manager': 'gerente', 'company': 'empresa', 'office': 'escritório', 'problem': 'problema',
  'answer': 'resposta', 'question': 'pergunta', 'change': 'mudar', 'better': 'melhor',
  'enough': 'suficiente', 'without': 'sem', 'through': 'através de', 'already': 'já',
  'usually': 'normalmente', 'tonight': 'hoje à noite', 'tomorrow': 'amanhã', 'remember': 'lembrar',
  'believe': 'acreditar', 'explain': 'explicar', 'improve': 'melhorar', 'deliver': 'entregar',
  'english': 'inglês', 'friday': 'sexta-feira', 'january': 'janeiro', 'beautiful': 'bonito',
  'different': 'diferente', 'important': 'importante', 'something': 'algo', 'everybody': 'todo mundo',
  'yesterday': 'ontem', 'interview': 'entrevista', 'available': 'disponível', 'excellent': 'excelente',
  'necessary': 'necessário', 'restaurant': 'restaurante', 'experience': 'experiência',
  'understand': 'entender', 'definitely': 'com certeza', 'afternoon': 'tarde', 'apartment': 'apartamento',
  'neighborhood': 'bairro', 'environment': 'ambiente', 'opportunity': 'oportunidade',
  'information': 'informação', 'comfortable': 'confortável', 'appointment': 'compromisso',
  'development': 'desenvolvimento', 'requirement': 'requisito', 'unfortunately': 'infelizmente',
  'immediately': 'imediatamente', 'responsibility': 'responsabilidade', 'communication': 'comunicação',
  'september': 'setembro', 'wednesday': 'quarta-feira', 'deployment': 'implantação',
  'documentation': 'documentação',
};

/// Fichas na pista do Dart Turismo no inglês (no lugar dos símbolos de código):
/// o MESMO tamanho de `fichasDart` (12), para o sorteio da pista ser igual.
const List<String> fichasIngles = [
  'hi', 'yes', 'ok', 'wow', '?', '!', 'and', 'the', 'you', 'I am', 'go', 'cool',
];
