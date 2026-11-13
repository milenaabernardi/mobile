import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import '../theme/app_theme.dart';
import '../view/auth_page.dart';

void main() async {
  // Prepara o motor antes de qualquer await que use plugins.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const AuthPage(),
  ));
}
