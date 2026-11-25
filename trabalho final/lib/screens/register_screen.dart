import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/registro_repository.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/auth_text_field.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmar = TextEditingController();
  final _auth = AuthService();

  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  String? _validarConfirmacao(String? v) {
    if (v == null || v.isEmpty) return 'Confirme a senha.';
    if (v != _senha.text) return 'As senhas não coincidem.';
    return null;
  }

  // ---------- Botão: Criar conta ----------
  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await _auth.cadastrar(_nome.text, _email.text, _senha.text);
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
      appBar: AppBar(title: const Text('Criar conta')),
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
                    AuthTextField(
                      controller: _nome,
                      label: 'Nome completo',
                      icon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                      action: TextInputAction.next,
                      enabled: !_carregando,
                      validator: Validators.nomeCompleto,
                    ),
                    const SizedBox(height: 14),
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
                      action: TextInputAction.next,
                      enabled: !_carregando,
                      validator: Validators.senha,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _confirmar,
                      label: 'Confirmar senha',
                      icon: Icons.lock_reset_outlined,
                      senha: true,
                      action: TextInputAction.done,
                      enabled: !_carregando,
                      validator: _validarConfirmacao,
                      onSubmitted: (_) => _cadastrar(),
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
                      onPressed: _carregando ? null : _cadastrar,
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
                          : const Text('Criar conta'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _carregando
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Já tenho conta'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sua conta é criada no Firebase Authentication.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 12,
                      ),
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
