import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/config_ouvir.dart';
import '../ouvir_cubit.dart';
import '../ouvir_state.dart';

/// O que o 📺 precisa lembrar da fila, vivo enquanto o cubit vive (D17). Puro (sem widgets).
///
/// Uma por `OuvirCubit` (Expando): assina o `stream` UMA vez (na 1ª chamada de [de]) e guarda, por índice,
/// se já houve tradução depois da última FalaEn ([viuTraducao]), qual foi a faixa da última FalaEn
/// ([ultimaFalaEnIndice]) e o `vez` dela ([vezVista]). Minimizar o "Tocando agora" (o palco e o seguidor
/// morrem) não apaga nada: o seguidor novo lê daqui ao nascer.
class MemoriaAssistir {
  MemoriaAssistir._();

  @visibleForTesting
  MemoriaAssistir.paraTeste();

  static final _porCubit = Expando<MemoriaAssistir>('MemoriaAssistir');

  /// Uma por cubit (Expando). Assina cubit.stream na 1ª chamada; cancela no cubit.close (onDone).
  static MemoriaAssistir de(OuvirCubit cubit) {
    final ja = _porCubit[cubit];
    if (ja != null) return ja;
    final m = MemoriaAssistir._();
    _porCubit[cubit] = m;
    m.registrar(cubit.state);
    if (!cubit.isClosed) {
      m._assinatura = cubit.stream.listen(m.registrar, onDone: m._cancelar);
    }
    return m;
  }

  StreamSubscription<OuvirState>? _assinatura;

  int? _indice;
  bool _viuTraducao = false;
  int? _ultimaFalaEn;
  int? _vez;

  /// Ainda escuta o cubit (false depois do `close`).
  @visibleForTesting
  bool get assinando => _assinatura != null;

  void _cancelar() {
    _assinatura?.cancel();
    _assinatura = null;
  }

  /// Alimentada pelo stream (e chamável no teste).
  void registrar(OuvirState st) {
    if (st.indice != _indice) {
      _indice = st.indice;
      _viuTraducao = false;
    }
    if (st.status != StatusOuvir.tocando) return;
    final f = st.atual;
    final temPt = f != null && f.pt.trim().isNotEmpty;
    final modo = temPt ? st.config.modo : ModoOuvir.soIngles;
    switch (st.fase) {
      case FaseOuvir.ouvindo:
        // uma FalaEn desta faixa (o `vez` dela vale daqui em diante)
        _ultimaFalaEn = st.indice;
        _vez = st.vez;
        _viuTraducao = false;
      case FaseOuvir.traducao || FaseOuvir.pense:
        if (modo == ModoOuvir.portuguesIngles) {
          // no "português → inglês" a tradução vem ANTES do inglês: a FalaEn desta passada ainda não veio
          // (o `ouvindo` que o irPara/continuar emitem leva o `vez` velho)
          if (_ultimaFalaEn == st.indice) {
            _ultimaFalaEn = null;
            _vez = null;
          }
        } else if (st.fase == FaseOuvir.traducao) {
          _viuTraducao = true;
        }
      case FaseOuvir.respiro || FaseOuvir.suaVez:
        break;
    }
  }

  /// Já houve tradução depois da última FalaEn da faixa [indice]? (zera quando o índice muda)
  bool viuTraducao(int indice) => indice == _indice && _viuTraducao;

  int? get ultimaFalaEnIndice => _ultimaFalaEn;

  /// O `vez` da última FalaEn da faixa [ultimaFalaEnIndice].
  int? get vezVista => _vez;
}
