import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Mensagem central com ícone (estado vazio, erro, etc.).
class EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyMessage({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textoSecundario),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}
