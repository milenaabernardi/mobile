import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/app_lottie.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../components/social_button.dart';
import '../utils/validators.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showAlert('Digite seu email primeiro.');
      return;
    }
    // EXERCÍCIO 1: valida o formato antes de chamar o Firebase.
    if (!isValidEmail(email)) {
      showAlert('Digite um email válido.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      showAlert('Enviamos um link para seu email!');
    } on FirebaseAuthException {
      if (!mounted) return;
      showAlert('Não foi possível enviar o link. Tente novamente.');
    }
  }

  Future<void> signIn() async {
    final email = emailController.text.trim();

    // EXERCÍCIO 1: validar formato de email antes do login.
    if (email.isEmpty) {
      showAlert('Digite seu email.');
      return;
    }
    if (!isValidEmail(email)) {
      showAlert('Digite um email válido.');
      return;
    }
    if (passwordController.text.isEmpty) {
      showAlert('Digite sua senha.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator()),
    );
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: passwordController.text);
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showAlert(switch (e.code) {
        'invalid-credential' => 'Email ou senha incorretos.',
        'invalid-email' => 'Digite um email válido.',
        _ => 'Não foi possível entrar. Tente novamente.',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(children: [
              // EXERCÍCIO 2: Lottie no lugar do ícone de cadeado.
              const AppLottie(height: 150),
              const SizedBox(height: 20),
              const Text('Bem-vindo de volta!',
                  style: TextStyle(fontSize: 26,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              MyTextField(controller: emailController,
                  hintText: 'Email', icon: Icons.email_outlined),
              const SizedBox(height: 15),
              MyTextField(controller: passwordController,
                  hintText: 'Senha', icon: Icons.lock_outline,
                  isPassword: true),
              TextButton(onPressed: forgotPassword,
                  child: const Text('Esqueceu a senha?')),
              MyButton(onTap: signIn, text: 'Entrar',
                  icon: Icons.login),
              const SizedBox(height: 25),
              const Text('ou continue com'),
              const SizedBox(height: 15),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(children: [
                    SocialButton(icon: Icons.g_mobiledata,
                        label: 'Google', onTap: () {}),
                    const SizedBox(width: 12),
                    SocialButton(icon: Icons.apple,
                        label: 'Apple', onTap: () {}),
                  ])),
              TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterPage())),
                  child: const Text('Registre-se agora')),
            ]),
          ),
        ),
      ),
    );
  }
}
