import 'package:flutter/material.dart';
import 'screens/main_shell.dart';
import 'services/favorites_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FavoritesStore.instance.load();
  runApp(const CineDiarioApp());
}

class CineDiarioApp extends StatelessWidget {
  const CineDiarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cineboxd',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}
