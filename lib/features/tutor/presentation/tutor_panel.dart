import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../arcade/domain/personagem.dart';
import '../../arcade/presentation/widgets/arcade_ui.dart';
import '../../arcade/presentation/widgets/avatares.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../curso/presentation/bloc/typing_bloc.dart';
import '../domain/contexto_estudo.dart';
import 'tutor_cubit.dart';

/// 🐦 O painel do Prof. Dash: um chat que SEMPRE enxerga o que o aluno está
/// estudando (o contexto fresco vai junto de cada pergunta). Usado como
/// barra lateral esquerda (telas largas) e como folha inferior (estreitas).
class TutorPanel extends StatefulWidget {
  const TutorPanel({super.key});

  @override
  State<TutorPanel> createState() => _TutorPanelState();
}

class _TutorPanelState extends State<TutorPanel> {
  final _ctrl = TextEditingController();
  final _rolagem = ScrollController();

  static const _sugestoes = [
    'O que esse trecho faz?',
    'Explica como se eu tivesse 10 anos',
    'Me dá outro exemplo disso',
    'Onde eu usaria isso num app de verdade?',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  void _enviar([String? texto]) {
    final pergunta = (texto ?? _ctrl.text).trim();
    if (pergunta.isEmpty) return;
    final contexto = contextoDoEstudo(
      context.read<CursoBloc>().state,
      context.read<TypingBloc>().state,
    );
    context.read<TutorCubit>().perguntar(pergunta, contexto);
    _ctrl.clear();
    // rola pro fim quando a resposta começar a chegar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rolagem.hasClients) {
        _rolagem.animateTo(_rolagem.position.maxScrollExtent + 200,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final curso = context.watch<CursoBloc>().state;
    final chat = context.watch<TutorCubit>().state;
    // o campo do chat vive em harmonia com o campo oculto do CodeView:
    // TextFieldTapRegion impede o "rouba-foco" entre eles
    return TextFieldTapRegion(
      child: Container(
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border(right: BorderSide(color: Mixart.border)),
        ),
        child: Column(children: [
          _cabecalho(chat),
          _chipContexto(curso),
          Expanded(child: _mensagens(chat)),
          if (chat.mensagens.isEmpty) _sugestoesChips(),
          _entrada(chat),
        ]),
      ),
    );
  }

  Widget _cabecalho(TutorState chat) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
        decoration:
            BoxDecoration(border: Border(bottom: BorderSide(color: Mixart.border))),
        child: Row(children: [
          const AvatarPersonagem(tamanho: 34, personagem: Personagem.dash),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Prof. Dash', style: Mixart.display(size: 16)),
              Text(
                chat.digitando ? 'pensando…' : 'tutor de Dart · vê o seu estudo',
                style: Mixart.ui(
                    size: 10.5,
                    color: chat.digitando ? Mixart.brand : Mixart.textMuted),
              ),
            ]),
          ),
          if (chat.mensagens.isNotEmpty)
            IconButton(
              tooltip: 'Limpar conversa',
              onPressed: () => context.read<TutorCubit>().limpar(),
              icon: Icon(Icons.delete_sweep_outlined, size: 18, color: Mixart.textFaint),
            ),
        ]),
      );

  Widget _chipContexto(CursoState curso) {
    if (curso.status != CursoStatus.pronto) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      color: Mixart.brandSub,
      child: Text(
        '👀 vendo: ${curso.trilha.emoji} ${curso.licao.nome} · '
        'trecho ${curso.trechoIdx + 1}/${curso.licao.trechos.length}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Mixart.ui(size: 10.5, weight: FontWeight.w600, color: Mixart.brand),
      ),
    );
  }

  Widget _mensagens(TutorState chat) {
    if (chat.mensagens.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const AvatarPersonagem(tamanho: 56, personagem: Personagem.dash),
            const SizedBox(height: 12),
            Text('Piu! Eu sou o Prof. Dash 🐦',
                textAlign: TextAlign.center, style: Mixart.display(size: 15)),
            const SizedBox(height: 6),
            Text(
              'Eu enxergo a lição e o trecho que você está digitando. '
              'Pergunta qualquer coisa — do "que raio é isso?" ao "me dá mais exemplos".',
              textAlign: TextAlign.center,
              style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.5),
            ),
          ]),
        ),
      );
    }
    return ListView.builder(
      controller: _rolagem,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      itemCount: chat.mensagens.length,
      itemBuilder: (_, i) => _bolha(chat.mensagens[i],
          escrevendo: chat.digitando && i == chat.mensagens.length - 1),
    );
  }

  Widget _bolha(MsgTutor m, {required bool escrevendo}) {
    final doAluno = m.doAluno;
    return Align(
      alignment: doAluno ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: const BoxConstraints(maxWidth: 270),
        decoration: BoxDecoration(
          color: doAluno ? Mixart.brand : Mixart.surfaceHi,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(doAluno ? 14 : 3),
            bottomRight: Radius.circular(doAluno ? 3 : 14),
          ),
          border: doAluno ? null : Border.all(color: Mixart.border),
        ),
        child: m.texto.isEmpty && escrevendo
            ? SizedBox(
                width: 34,
                height: 16,
                child: Center(
                  child: Text('…', style: Mixart.display(size: 15, color: Mixart.brand)),
                ),
              )
            : doAluno
                ? Text(m.texto,
                    style: Mixart.ui(size: 12.5, color: Mixart.onBrand)
                        .copyWith(height: 1.45))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _renderizaResposta(m.texto)),
      ),
    );
  }

  /// Markdown de bolso: blocos ```code``` viram cartão com destaque,
  /// `inline` vira mono, **negrito** vira negrito. O resto é texto.
  List<Widget> _renderizaResposta(String texto) {
    final blocos = <Widget>[];
    final partes = texto.split('```');
    for (var i = 0; i < partes.length; i++) {
      if (partes[i].trim().isEmpty) continue;
      if (i.isOdd) {
        var cod = partes[i].trim();
        for (final ling in ['dart', 'Dart']) {
          if (cod.startsWith('$ling\n')) cod = cod.substring(ling.length + 1);
        }
        blocos.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: CartaoCodigo(cod),
        ));
      } else {
        blocos.add(_paragrafo(partes[i].trim()));
      }
    }
    return blocos.isEmpty ? [_paragrafo(texto)] : blocos;
  }

  Widget _paragrafo(String texto) {
    final spans = <TextSpan>[];
    // corta em `inline` e **negrito**, na ordem em que aparecem
    final regex = RegExp(r'`([^`]+)`|\*\*([^*]+)\*\*');
    var cursor = 0;
    for (final m in regex.allMatches(texto)) {
      if (m.start > cursor) spans.add(TextSpan(text: texto.substring(cursor, m.start)));
      if (m.group(1) != null) {
        spans.add(TextSpan(
          text: m.group(1),
          style: Mixart.mono(size: 11.5, color: Mixart.brand),
        ));
      } else {
        spans.add(TextSpan(
            text: m.group(2), style: const TextStyle(fontWeight: FontWeight.w700)));
      }
      cursor = m.end;
    }
    if (cursor < texto.length) spans.add(TextSpan(text: texto.substring(cursor)));
    return Text.rich(
      TextSpan(children: spans),
      style: Mixart.ui(size: 12.5, color: Mixart.text).copyWith(height: 1.5),
    );
  }

  Widget _sugestoesChips() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final s in _sugestoes)
            InkWell(
              onTap: () => _enviar(s),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Mixart.surfaceHi,
                  border: Border.all(color: Mixart.border),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(s, style: Mixart.ui(size: 10.5, color: Mixart.textMuted)),
              ),
            ),
        ]),
      );

  Widget _entrada(TutorState chat) => Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Mixart.border))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                onSubmitted: (_) => _enviar(),
                textInputAction: TextInputAction.send,
                style: Mixart.ui(size: 12.5),
                decoration: InputDecoration(
                  hintText: 'Pergunte sobre a lição…',
                  hintStyle: Mixart.ui(size: 12, color: Mixart.textHint),
                  isDense: true,
                  filled: true,
                  fillColor: Mixart.bg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: Mixart.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: Mixart.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: Mixart.brand),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Enviar',
              onPressed: chat.digitando ? null : _enviar,
              icon: Icon(Icons.send_rounded,
                  size: 19, color: chat.digitando ? Mixart.textFaint : Mixart.brand),
              style: IconButton.styleFrom(backgroundColor: Mixart.brandSub),
            ),
          ]),
          const SizedBox(height: 4),
          Text('IA pode escorregar — na dúvida, rode o código 😉',
              style: Mixart.ui(size: 9.5, color: Mixart.textFaint)),
        ]),
      );
}

/// Botão flutuante do tutor (telas estreitas): abre o painel numa folha.
class BotaoTutor extends StatelessWidget {
  const BotaoTutor({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Prof. Dash',
      child: Material(
        color: Mixart.surface,
        shape: CircleBorder(side: BorderSide(color: Mixart.brand, width: 2)),
        elevation: 6,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (sheetCtx) => FractionallySizedBox(
              heightFactor: 0.86,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: const TutorPanel(),
              ),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(9),
            child: AvatarPersonagem(tamanho: 40, personagem: Personagem.dash),
          ),
        ),
      ),
    );
  }
}
