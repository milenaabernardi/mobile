import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/imagens/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.superficie),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dot(AppColors.laranja),
                _dot(AppColors.verde),
                _dot(AppColors.azul),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(Color cor) => Container(
    width: size * 0.18,
    height: size * 0.18,
    margin: EdgeInsets.symmetric(horizontal: size * 0.02),
    decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
  );
}
