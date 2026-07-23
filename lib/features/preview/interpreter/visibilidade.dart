import 'parser.dart';

/// O parser aceita coisas como `Wrap(children: itens)` — sintaticamente
/// perfeitas, mas `itens` é uma variável que o builder não conhece: o
/// resultado era uma prévia "AO VIVO" com a tela EM BRANCO (0×0).
/// Esta checagem responde: "se eu construir esta árvore, algum pixel
/// aparece?" — considerando os mocks do builder (GridView vira grade de
/// amostra, ListView.builder gera 3 itens, SizedBox vira caixinha…).
bool temFolhaVisivel(Node n) {
  switch (n.t) {
    case 'call':
      final base = n.base;
      if (base == 'Text' || base == 'RichText') {
        // Text(variavel) vira texto VAZIO no builder — só string literal pinta
        if (n.pos.isNotEmpty && n.pos.first.t == 'str') return true;
      } else if (base == 'SizedBox' && n.name == 'SizedBox.shrink') {
        // encolhida de propósito: 0x0 por definição
      } else if (base == 'ListView') {
        // as listas SEMPRE mostram algo (mock de 3 itens quando preciso)
        return true;
      } else if (base == 'Container' || base == 'AnimatedContainer') {
        // Container "vazio" não pinta; com cor/decoração, pinta
        if (n.named.containsKey('color') || n.named.containsKey('decoration')) {
          return true;
        }
      } else if (_sempreVisiveis.contains(base)) {
        return true;
      }
      for (final f in n.pos) {
        if (temFolhaVisivel(f)) return true;
      }
      for (final f in n.named.values) {
        if (temFolhaVisivel(f)) return true;
      }
      return false;
    case 'list':
      return n.pos.any(temFolhaVisivel);
    case 'lambda':
      final corpo = n.corpo;
      return corpo != null && temFolhaVisivel(corpo);
    default:
      // str/num/bool/ident não pintam nada sozinhos
      return false;
  }
}

/// Widgets que SEMPRE deixam pixel na tela quando o builder os constrói
/// (seja de verdade, seja pelo mock de amostra).
const _sempreVisiveis = {
  'Text', 'RichText', 'Icon', 'Image', 'FlutterLogo', 'CircleAvatar',
  'Chip', 'ActionChip', 'FilterChip', 'ChoiceChip', 'InputChip',
  'ElevatedButton', 'TextButton', 'OutlinedButton', 'FilledButton',
  'IconButton', 'FloatingActionButton', 'TextField', 'TextFormField',
  'Checkbox', 'Switch', 'Slider', 'Radio', 'CircularProgressIndicator',
  'LinearProgressIndicator', 'Divider', 'VerticalDivider', 'Card',
  'GridView', 'DropdownButton', 'AlertDialog', 'SnackBar', 'Badge',
  'Tooltip', 'ListTile', 'AppBar', 'BottomNavigationBar', 'NavigationBar',
  'TabBar', 'Placeholder', 'SizedBox', 'AspectRatio',
  'FractionallySizedBox', 'Drawer',
};
