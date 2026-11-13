import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/app_lottie.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../utils/validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void showAlert(String message) {
    showDialog(context: context,
        builder: (_) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK')),
          ],
        ));
  }

  Future<void> register() async {
    final email = emailController.text.trim();

    // Validações antes de chamar o Firebase (return evita a chamada de rede).
    if (!isValidEmail(email)) {
      showAlert('Digite um email válido.');
      return;
    }
    if (passwordController.text.length < 6) {
      showAlert('A senha precisa ter pelo menos 6 caracteres.');
      return;
    }
    if (passwordController.text != confirmController.text) {
      showAlert('Senhas não conferem!');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: passwordController.text);
      if (!mounted) return;
      Navigator.pop(context); // fecha o loading
      Navigator.pop(context); // fecha a RegisterPage
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // com erro, fecha só o loading
      showAlert(switch (e.code) {
        'email-already-in-use' =>
        'Já existe um usuário com esse email!',
        'weak-password' => 'Escolha uma senha mais forte.',
        'invalid-email' => 'Digite um email válido.',
        _ => 'Não foi possível cadastrar. Tente novamente.',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(),
          title: const Text('Crie sua conta')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(children: [
            // EXERCÍCIO 2: Lottie também na tela de cadastro.
            const AppLottie(height: 120),
            const SizedBox(height: 20),
            MyTextField(controller: emailController,
                hintText: 'Email', icon: Icons.email_outlined),
            const SizedBox(height: 15),
            MyTextField(controller: passwordController,
                hintText: 'Senha', icon: Icons.lock_outline,
                isPassword: true),
            const SizedBox(height: 15),
            MyTextField(controller: confirmController,
                hintText: 'Confirmar senha',
                icon: Icons.lock_outline, isPassword: true),
            const SizedBox(height: 25),
            MyButton(onTap: register, text: 'Registrar',
                icon: Icons.person_add),
          ]),
        ),
      ),
    );
  }
}
