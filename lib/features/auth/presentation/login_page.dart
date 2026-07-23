import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/brand/logo_pacdart.dart';
import '../../../core/theme/mixart.dart';
import '../../../core/theme/seletor_tema.dart';
import 'auth_cubit.dart';
import '../data/auth_repository.dart';

/// Tela de entrada: login ou cadastro por e-mail e senha.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _Modo { entrar, cadastrar }

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _Modo _modo = _Modo.entrar;
  bool _carregando = false;
  bool _verSenha = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  bool get _ehEntrar => _modo == _Modo.entrar;

  Future<void> _enviar() async {
    setState(() => _erro = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    final auth = context.read<AuthCubit>();
    try {
      if (_ehEntrar) {
        await auth.entrar(_email.text, _senha.text);
      } else {
        await auth.cadastrar(_email.text, _senha.text);
      }
      // sucesso: o AuthCubit troca de estado e o gate mostra o app
    } on AuthException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Algo deu errado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _esqueci() async {
    setState(() => _erro = null);
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _erro = 'Digite seu e-mail acima para redefinir a senha.');
      return;
    }
    try {
      await context.read<AuthCubit>().redefinirSenha(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Mixart.surfaceHi,
            content: Text(
              'Enviamos um link de redefinição para $email',
              style: Mixart.ui(size: 13, color: Mixart.text),
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: Stack(
        children: [
          Positioned(
            top: 12,
            right: 16,
            child: SafeArea(child: SeletorTema(compacto: true)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _cabecalho(),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Mixart.surface,
                        border: Border.all(color: Mixart.border),
                        borderRadius: BorderRadius.circular(Mixart.radiusLg),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 50,
                            offset: Offset(0, 20),
                            spreadRadius: -28,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _seletorModo(),
                            const SizedBox(height: 20),
                            _campo(
                              controle: _email,
                              rotulo: 'E-mail',
                              icone: Icons.mail_outline,
                              teclado: TextInputType.emailAddress,
                              validar: (v) => (v == null || !v.contains('@'))
                                  ? 'E-mail inválido'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _campo(
                              controle: _senha,
                              rotulo: 'Senha',
                              icone: Icons.lock_outline,
                              senha: true,
                              validar: (v) => (v == null || v.length < 6)
                                  ? 'Mínimo de 6 caracteres'
                                  : null,
                              aoEnviar: (_) => _enviar(),
                            ),
                            if (_ehEntrar) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _carregando ? null : _esqueci,
                                  child: Text(
                                    'Esqueci a senha',
                                    style: Mixart.ui(
                                      size: 12,
                                      weight: FontWeight.w600,
                                      color: Mixart.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (_erro != null) ...[
                              const SizedBox(height: 12),
                              _banerErro(_erro!),
                            ],
                            const SizedBox(height: 18),
                            _botaoPrincipal(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Seu progresso fica salvo na sua conta ☁️',
                      style: Mixart.ui(size: 12, color: Mixart.textFaint),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cabecalho() => Column(
    children: [
      const LogoPacDart(tamanho: 96),
      const SizedBox(height: 18),
      RichText(
        text: TextSpan(
          style: Mixart.display(size: 30),
          children: [
            TextSpan(text: 'PAC'),
            TextSpan(
              text: '·',
              style: TextStyle(color: Mixart.brand),
            ),
            TextSpan(text: 'DART'),
          ],
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Aprenda Dart & Flutter digitando código',
        style: Mixart.ui(size: 13, color: Mixart.textMuted),
      ),
    ],
  );

  Widget _seletorModo() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Mixart.bg,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _abaModo('Entrar', _Modo.entrar),
          _abaModo('Criar conta', _Modo.cadastrar),
        ],
      ),
    );
  }

  Widget _abaModo(String texto, _Modo modo) {
    final ativo = _modo == modo;
    return Expanded(
      child: GestureDetector(
        onTap: _carregando
            ? null
            : () => setState(() {
                _modo = modo;
                _erro = null;
              }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ativo ? Mixart.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            texto,
            style: Mixart.ui(
              size: 13.5,
              weight: FontWeight.w700,
              color: ativo ? Mixart.onBrand : Mixart.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controle,
    required String rotulo,
    required IconData icone,
    bool senha = false,
    TextInputType? teclado,
    String? Function(String?)? validar,
    void Function(String)? aoEnviar,
  }) {
    return TextFormField(
      controller: controle,
      obscureText: senha && !_verSenha,
      keyboardType: teclado,
      autocorrect: false,
      enableSuggestions: false,
      style: Mixart.ui(size: 14, color: Mixart.text),
      onFieldSubmitted: aoEnviar,
      validator: validar,
      decoration: InputDecoration(
        labelText: rotulo,
        labelStyle: Mixart.ui(size: 13, color: Mixart.textMuted),
        prefixIcon: Icon(icone, size: 18, color: Mixart.textMuted),
        suffixIcon: senha
            ? IconButton(
                onPressed: () => setState(() => _verSenha = !_verSenha),
                icon: Icon(
                  _verSenha ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: Mixart.textFaint,
                ),
              )
            : null,
        filled: true,
        fillColor: Mixart.bg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          borderSide: BorderSide(color: Mixart.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          borderSide: BorderSide(color: Mixart.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          borderSide: BorderSide(color: Mixart.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          borderSide: BorderSide(color: Mixart.danger, width: 1.5),
        ),
        errorStyle: Mixart.ui(size: 11.5, color: Mixart.danger),
      ),
    );
  }

  Widget _banerErro(String erro) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Mixart.danger.withValues(alpha: .12),
      border: Border.all(color: Mixart.danger.withValues(alpha: .4)),
      borderRadius: BorderRadius.circular(Mixart.radiusMd),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, size: 16, color: Mixart.danger),
        const SizedBox(width: 10),
        Expanded(
          child: Text(erro, style: Mixart.ui(size: 12.5, color: Mixart.danger)),
        ),
      ],
    ),
  );

  Widget _botaoPrincipal() => SizedBox(
    height: 50,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Mixart.brand,
        foregroundColor: Mixart.onBrand,
        disabledBackgroundColor: Mixart.surfaceHi,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        textStyle: Mixart.ui(size: 15, weight: FontWeight.w700),
      ),
      onPressed: _carregando ? null : _enviar,
      child: _carregando
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Mixart.onBrand,
              ),
            )
          : Text(_ehEntrar ? 'Entrar' : 'Criar conta e começar'),
    ),
  );
}
