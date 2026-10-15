import 'dart:async';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// No Android/iOS abre [url] no navegador do aparelho (o app não cria uma tela de
/// navegação só para os créditos). No desktop e nos testes da VM devolve false —
/// quem chama mostra o plano B.
bool abrirUrl(String url) {
  if (!(Platform.isAndroid || Platform.isIOS)) return false;
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  unawaited(launchUrl(uri, mode: LaunchMode.externalApplication).catchError((Object _) => false));
  return true;
}
