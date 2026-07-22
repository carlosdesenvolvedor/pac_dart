import 'package:equatable/equatable.dart';

/// Usuário do app, desacoplado do tipo do Firebase.
class AppUser extends Equatable {
  final String uid;
  final String? email;

  const AppUser({required this.uid, this.email});

  /// Nome curto para exibir (parte antes do @ do e-mail).
  String get apelido {
    final e = email;
    if (e == null || e.isEmpty) return 'você';
    final at = e.indexOf('@');
    return at > 0 ? e.substring(0, at) : e;
  }

  @override
  List<Object?> get props => [uid, email];
}
