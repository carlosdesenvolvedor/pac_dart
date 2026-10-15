import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/escrita.dart';
import 'ia_cubit.dart';

/// O que deu errado na última tentativa (a tela mostra a mensagem certa).
enum ErroEscrita { nenhum, semTexto, semCota, falhou }

class EscritaState extends Equatable {
  /// Esperando o Prof. Dash.
  final bool aguardando;
  final ErroEscrita erro;

  /// O texto que gerou o [resultado] (a tela mostra o aviso de corte).
  final TextoEscrito? enviado;
  final ResultadoEscrita? resultado;

  const EscritaState({this.aguardando = false, this.erro = ErroEscrita.nenhum, this.enviado, this.resultado});

  @override
  List<Object?> get props => [aguardando, erro, enviado, resultado];
}

/// Uma correção de escrita: 1 uso da cota de IA pelo [IaCubit] (erro, vazio e "sem saldo" nunca
/// gastam). Nada é salvo se a pessoa sair: só os cartões que ela salvar ficam no baralho.
/// Não toca em agenda, hábito nem ranking.
class EscritaCubit extends Cubit<EscritaState> {
  final IaCubit ia;
  EscritaCubit({required this.ia}) : super(const EscritaState());

  /// Corrige [bruto]. O mesmo texto de antes mostra o resultado que já existe, sem chamar a IA.
  Future<void> corrigir(String bruto) async {
    if (state.aguardando) return;
    final t = TextoEscrito.preparar(bruto);
    if (t == null) {
      emit(EscritaState(erro: ErroEscrita.semTexto, enviado: state.enviado, resultado: state.resultado));
      return;
    }
    final antes = state.enviado;
    if (state.resultado != null && antes != null && antes.chave == t.chave) {
      emit(EscritaState(enviado: t, resultado: state.resultado));
      return;
    }
    // o resultado antigo sai de cena: não fica ao lado de um erro de outro texto
    emit(const EscritaState(aguardando: true));
    final p = pedidoDeCorrecao(t);
    final r = await ia.consultar(contexto: p.contexto, pergunta: p.pergunta);
    if (isClosed) return;
    switch (r.status) {
      case StatusIa.ok:
        emit(EscritaState(enviado: t, resultado: ResultadoEscrita.interpretar(r.texto, original: t)));
      case StatusIa.semCota:
        emit(const EscritaState(erro: ErroEscrita.semCota));
      case StatusIa.falhou:
        emit(const EscritaState(erro: ErroEscrita.falhou));
    }
  }

  /// "Escrever outro texto": limpa o resultado.
  void recomecar() => emit(const EscritaState());
}
