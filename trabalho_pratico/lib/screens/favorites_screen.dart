import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/favorites_store.dart';
import '../widgets/empty_message.dart';
import '../widgets/movie_card.dart';
import 'detail_screen.dart';

// Aba "Favoritos": filmes salvos pelo usuário.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  // ---------- Botão: Limpar favoritos ----------
  Future<void> _confirmarLimpar(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar favoritos?'),
        content: const Text('Todos os filmes salvos serão removidos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmou == true) FavoritesStore.instance.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus favoritos',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          ValueListenableBuilder<List<Movie>>(
            valueListenable: FavoritesStore.instance.favorites,
            builder: (context, favs, _) => favs.isEmpty
                ? const SizedBox.shrink()
                : TextButton.icon(
                    onPressed: () => _confirmarLimpar(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Limpar'),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ValueListenableBuilder<List<Movie>>(
        valueListenable: FavoritesStore.instance.favorites,
        builder: (context, favs, _) {
          if (favs.isEmpty) {
            return const EmptyMessage(
              icon: Icons.favorite_border,
              text:
                  'Nenhum favorito ainda. Abra um filme e toque em Favoritar.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favs.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              childAspectRatio: 0.52,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, i) => MovieCard(
              movie: favs[i],
              onTap: () => abrirDetalhes(context, favs[i]),
            ),
          );
        },
      ),
    );
  }
}
