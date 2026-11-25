import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _auth = AuthService();

  bool _carregando = false;
  String? _mensagem;
  bool _sucesso = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  // ---------- Botão: Enviar link ----------
  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _mensagem = null;
    });
    try {
      await _auth.recuperarSenha(_email.text);
      setState(() {
        _sucesso = true;
        _mensagem = 'Se o e-mail estiver cadastrado, você receberá um link para redefinir a senha. Confira também o spam.';
      });
    } on AuthException catch (e) {
      setState(() {
        _sucesso = false;
        _mensagem = e.message;
      });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _sucesso ? AppColors.verde : Colors.redAccent;
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Informe o e-mail da sua conta. O Firebase enviará um link para você criar uma nova senha.',
                      style: TextStyle(color: AppColors.textoSecundario),
                    ),
                    const SizedBox(height: 20),
                    AuthTextField(
                      controller: _email,
                      label: 'E-mail',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      action: TextInputAction.done,
                      enabled: !_carregando,
                      validator: Validators.email,
                      onSubmitted: (_) => _enviar(),
                    ),
                    if (_mensagem != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cor.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: cor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _sucesso
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              color: cor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_mensagem!)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _carregando ? null : _enviar,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _carregando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text('Enviar link'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _carregando
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Voltar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
