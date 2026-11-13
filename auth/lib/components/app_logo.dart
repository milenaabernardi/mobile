import 'package:flutter/material.dart';

/// Parte 7: logo do app (assets/logo.png) reutilizado no login e no cadastro.
/// Entra com uma animação de escala + opacidade (TweenAnimationBuilder).
/// Se o arquivo não existir, mostra o cadeado como alternativa.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 100});

  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, scale, child) => Opacity(
        opacity: scale.clamp(0.0, 1.0).toDouble(),
        child: Transform.scale(scale: scale, child: child),
      ),
      child: Image.asset(
        'assets/logo.png',
        height: height,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.lock_rounded, size: height * 0.9),
      ),
    );
  }
}
