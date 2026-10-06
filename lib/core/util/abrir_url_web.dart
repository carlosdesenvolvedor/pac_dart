import 'package:web/web.dart' as web;

bool abrirUrl(String url) {
  web.window.open(url, '_blank');
  return true;
}
