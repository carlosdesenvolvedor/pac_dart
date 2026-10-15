import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../data/auth_repository.dart' show AuthException;
import 'auth_cubit.dart';

/// "Excluir minha conta": diz o que some, pede a senha e só então apaga (progresso,
/// ranking e login). Exigido pela Apple e pelo Google para app com cadastro.
Future<void> mostrarExcluirConta(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(value: context.read<AuthCubit>(), child: const _ExcluirContaDialog()),
    );

class _ExcluirContaDialog extends StatefulWidget {
  const _ExcluirContaDialog();

  @override
  State<_ExcluirContaDialog> createState() => _ExcluirContaDialogState();
}

class _ExcluirContaDialogState extends State<_ExcluirContaDialog> {
  final _senha = TextEditingController();
  bool _apagando = false;
  String? _erro;

  @override
  void dispose() {
    _senha.dispose();
    super.dispose();
  }

  Future<void> _excluir() async {
    if (_senha.text.isEmpty) {
      setState(() => _erro = 'Digite sua senha para confirmar.');
      return;
    }
    final cubit = context.read<AuthCubit>();
    final navegador = Navigator.of(context);
    setState(() {
      _apagando = true;
      _erro = null;
    });
    try {
      await cubit.excluirConta(_senha.text);
      // o login some, o app volta sozinho para a entrada; só fecha este diálogo
      if (navegador.mounted && navegador.canPop()) navegador.pop();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _apagando = false;
          _erro = e.mensagem;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _apagando = false;
          _erro = 'Não deu certo. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select((AuthCubit c) => c.state.user?.email);
    return AlertDialog(
      backgroundColor: Mixart.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        side: BorderSide(color: Mixart.border),
      ),
      title: Text('Excluir minha conta', style: Mixart.display(size: 20)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Isso apaga para sempre${email == null ? '' : ' a conta $email'}: seu login, todo o progresso '
            'dos cursos (Dart, C# e Inglês), a fila de revisão e seu lugar no ranking. '
            'Não dá para desfazer.',
            style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _senha,
            obscureText: true,
            enabled: !_apagando,
            autofocus: true,
            onSubmitted: (_) => _excluir(),
            style: Mixart.ui(size: 14, color: Mixart.text),
            decoration: InputDecoration(
              labelText: 'Sua senha, para confirmar',
              labelStyle: Mixart.ui(size: 13, color: Mixart.textMuted),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Mixart.border)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Mixart.danger)),
            ),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 10),
            Text(_erro!, style: Mixart.ui(size: 12.5, weight: FontWeight.w600, color: Mixart.danger)),
          ],
        ]),
      ),
      actions: [
        TextButton(
          onPressed: _apagando ? null : () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: Mixart.ui(size: 13.5, weight: FontWeight.w600, color: Mixart.textMuted)),
        ),
        FilledButton(
          onPressed: _apagando ? null : _excluir,
          style: FilledButton.styleFrom(backgroundColor: Mixart.danger, foregroundColor: Colors.white),
          child: _apagando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Excluir definitivamente', style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    );
  }
}
