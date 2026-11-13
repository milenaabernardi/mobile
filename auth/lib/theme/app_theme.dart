import 'package:flutter/material.dart';

class AppTheme {
  static const bg = Color(0xFF0B1220);
  static const card = Color(0xFF151E31);
  static const accent = Color(0xFF6C63FF);

  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.dark(primary: accent),
    useMaterial3: true,
  );
}
