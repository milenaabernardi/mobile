import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.borda),
              ),
              clipBehavior: Clip.antiAlias,
              width: double.infinity,
              child: MoviePoster(url: movie.posterUrl),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            movie.year,
            style:
                const TextStyle(color: AppColors.textoSecundario, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Poster com placeholder quando nao ha imagem ou ela falha ao carregar.
class MoviePoster extends StatelessWidget {
  final String? url;
  const MoviePoster({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) return _placeholder();
    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.verde),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.superficie,
      alignment: Alignment.center,
      child: const Icon(Icons.movie_outlined,
          color: AppColors.textoSecundario, size: 36),
    );
  }
}

// Estrelas verdes (0 a 5), no estilo Letterboxd.
class StarRating extends StatelessWidget {
  final double stars;
  const StarRating({super.key, required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData icon;
        if (stars >= i + 1) {
          icon = Icons.star;
        } else if (stars >= i + 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, color: AppColors.verde, size: 20);
      }),
    );
  }
}
