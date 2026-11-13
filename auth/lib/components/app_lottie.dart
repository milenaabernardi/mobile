import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'app_logo.dart';

/// EXERCÍCIO 2: animação Lottie no topo das telas de autenticação.
/// Troque assets/animations/login.json por uma animação do LottieFiles
/// (confira a licença). Se o arquivo falhar, cai no AppLogo.
class AppLottie extends StatelessWidget {
  const AppLottie({super.key, this.height = 150});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/login.json',
      height: height,
      repeat: true,
      errorBuilder: (context, error, stackTrace) =>
          AppLogo(height: height * 0.7),
    );
  }
}
