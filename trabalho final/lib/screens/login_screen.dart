import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/registro_repository.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/brand_logo.dart';
import 'forgot_password_screen.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _auth = AuthService();

  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  // ---------- Botão: Entrar ----------
  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await _auth.entrar(_email.text, _senha.text);
      final uid = _auth.usuario?.uid;
      if (uid != null) RegistroRepository.instance.iniciar(uid);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on AuthException catch (e) {
      setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    const Center(child: BrandLogo(size: 84)),
                    const SizedBox(height: 16),
                    const Text(
                      'Bem-vindo ao Cineboxd',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Entre para ver o seu diário de filmes',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textoSecundario),
                    ),
                    const SizedBox(height: 28),
                    AuthTextField(
                      controller: _email,
                      label: 'E-mail',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      action: TextInputAction.next,
                      enabled: !_carregando,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _senha,
                      label: 'Senha',
                      icon: Icons.lock_outline,
                      senha: true,
                      action: TextInputAction.done,
                      enabled: !_carregando,
                      validator: Validators.senha,
                      onSubmitted: (_) => _entrar(),
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_erro!)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _carregando ? null : _entrar,
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
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 6),
                    // ---------- Botão de texto: Recuperar senha ----------
                    TextButton(
                      onPressed: _carregando
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                      child: const Text('Esqueci minha senha'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Ainda não tem conta?',
                          style: TextStyle(color: AppColors.textoSecundario),
                        ),
                        // ---------- Botão de texto: Cadastre-se aqui ----------
                        TextButton(
                          onPressed: _carregando
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                          child: const Text('Cadastre-se aqui'),
                        ),
                      ],
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
