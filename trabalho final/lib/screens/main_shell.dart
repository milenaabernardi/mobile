import 'package:flutter/material.dart';
import '../services/registro_repository.dart';
import 'calendar_screen.dart';
import 'diario_screen.dart';
import 'discover_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// Tela principal com o menu inferior.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;

  final List<Widget> _pages = const [
    DiscoverScreen(),
    SearchScreen(),
    DiarioScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Ao voltar para o app, confere a conexão e envia o que estiver pendente.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      RegistroRepository.instance.sincronizar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = RegistroRepository.instance;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: ListenableBuilder(
              listenable: repo,
              builder: (context, _) => Badge(
                label: Text('${repo.pendentes}'),
                isLabelVisible: repo.pendentes > 0,
                child: const Icon(Icons.menu_book_outlined),
              ),
            ),
            selectedIcon: const Icon(Icons.menu_book),
            label: 'Diário',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendário',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
