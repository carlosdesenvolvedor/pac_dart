import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/tutor_service.dart';

class MsgTutor extends Equatable {
  final bool doAluno;
  final String texto;
  const MsgTutor({required this.doAluno, required this.texto});

  MsgTutor copyWith({String? texto}) => MsgTutor(doAluno: doAluno, texto: texto ?? this.texto);

  @override
  List<Object?> get props => [doAluno, texto];
}

class TutorState extends Equatable {
  final List<MsgTutor> mensagens;

  /// O professor está "escrevendo" (resposta chegando em streaming).
  final bool digitando;

  const TutorState({this.mensagens = const [], this.digitando = false});

  TutorState copyWith({List<MsgTutor>? mensagens, bool? digitando}) =>
      TutorState(mensagens: mensagens ?? this.mensagens, digitando: digitando ?? this.digitando);

  @override
  List<Object?> get props => [mensagens, digitando];
}

/// O chat com o Prof. Dash. Cada pergunta leva junto o [contexto] fresco do
/// que o aluno está estudando — por isso ele "sempre sabe do que você fala".
class TutorCubit extends Cubit<TutorState> {
  final TutorService service;

  TutorCubit({required this.service}) : super(const TutorState());

  /// O tutor vive no ramo autenticado; em árvores sem ele (testes antigos)
  /// tudo some silenciosamente.
  static TutorCubit? de(BuildContext context) {
    try {
      return context.read<TutorCubit>();
    } catch (_) {
      return null;
    }
  }

  /// Últimas mensagens no formato "quem: texto" (memória curta da conversa).
  String _historico() => [
        for (final m in state.mensagens.takeLast(6))
          '${m.doAluno ? 'Aluno' : 'Prof. Dash'}: ${m.texto}',
      ].join('\n');

  Future<void> perguntar(String pergunta, String contexto) async {
    final limpa = pergunta.trim();
    if (limpa.isEmpty || state.digitando) return;
    final historico = _historico();
    emit(state.copyWith(
      mensagens: [
        ...state.mensagens,
        MsgTutor(doAluno: true, texto: limpa),
        const MsgTutor(doAluno: false, texto: ''),
      ],
      digitando: true,
    ));
    try {
      await for (final pedaco in service.perguntar(
          contexto: contexto, historico: historico, pergunta: limpa)) {
        final msgs = [...state.mensagens];
        msgs[msgs.length - 1] = msgs.last.copyWith(texto: msgs.last.texto + pedaco);
        emit(state.copyWith(mensagens: msgs));
      }
      if (state.mensagens.last.texto.isEmpty) {
        _troca('Hmm, fiquei sem palavras — pergunta de novo? 🐦');
      }
    } catch (e) {
      _troca(_erroAmigavel('$e'));
    }
    emit(state.copyWith(digitando: false));
  }

  void _troca(String texto) {
    final msgs = [...state.mensagens];
    msgs[msgs.length - 1] = msgs.last.copyWith(texto: texto);
    emit(state.copyWith(mensagens: msgs));
  }

  String _erroAmigavel(String erro) {
    final curto = erro.length > 180 ? '${erro.substring(0, 180)}…' : erro;
    final config = erro.contains('firebasevertexai') ||
        erro.contains('PERMISSION_DENIED') ||
        erro.contains('403') ||
        erro.contains('not been used') ||
        erro.contains('API key');
    return config
        ? '😴 Ainda não me ligaram na tomada: ative o **Firebase AI Logic** no '
            'console do Firebase (Build → AI Logic → Get started) e tente de novo.\n\n'
            '`$curto`'
        : '😵 Não consegui falar com a central agora — confere a internet e '
            'tenta de novo?\n\n`$curto`';
  }

  void limpar() => emit(const TutorState());
}

extension<T> on List<T> {
  Iterable<T> takeLast(int n) => length <= n ? this : sublist(length - n);
}
