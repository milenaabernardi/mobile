import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/registro_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// Tela de abertura: mostra a marca e decide para onde ir (login ou app).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _seguir();
  }

  Future<void> _seguir() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final usuario = AuthService().usuario;
    final Widget destino;
    if (usuario != null) {
      RegistroRepository.instance.iniciar(usuario.uid);
      destino = const MainShell();
    } else {
      destino = const LoginScreen();
    }
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => destino));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOut,
          builder: (context, valor, child) => Opacity(
            opacity: valor,
            child: Transform.scale(scale: 0.85 + 0.15 * valor, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(size: 110),
              const SizedBox(height: 20),
              const Text(
                'Cineboxd',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'seu diário de filmes',
                style: TextStyle(color: AppColors.textoSecundario),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.verde,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
