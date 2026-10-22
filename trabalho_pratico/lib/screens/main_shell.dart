import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/favorites_store.dart';
import 'discover_screen.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';

// Tela principal com o menu inferior (Início, Buscar, Favoritos).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    DiscoverScreen(),
    SearchScreen(),
    FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
            icon: ValueListenableBuilder<List<Movie>>(
              valueListenable: FavoritesStore.instance.favorites,
              builder: (context, favs, _) => Badge(
                label: Text('${favs.length}'),
                isLabelVisible: favs.isNotEmpty,
                child: const Icon(Icons.favorite_border),
              ),
            ),
            selectedIcon: const Icon(Icons.favorite),
            label: 'Favoritos',
          ),
        ],
      ),
    );
  }
}
