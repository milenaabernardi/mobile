import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import 'movie_card.dart';

// Faixa horizontal com título e filmes (ex: "Em cartaz").
// Cada faixa carrega os próprios dados e tem botão "Tentar de novo" em caso de erro.
class MovieSection extends StatefulWidget {
  final String title;
  final Future<List<Movie>> Function() loader;
  final void Function(Movie movie) onTap;

  const MovieSection({
    super.key,
    required this.title,
    required this.loader,
    required this.onTap,
  });

  @override
  State<MovieSection> createState() => _MovieSectionState();
}

class _MovieSectionState extends State<MovieSection> {
  late Future<List<Movie>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Movie>> _load() async {
    final movies = await widget.loader();
    // Filmes sem pôster ficam feios na faixa, então são ignorados aqui.
    return movies.where((m) => m.posterPath != null).toList();
  }

  void _tentarDeNovo() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            widget.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 215,
          child: FutureBuilder<List<Movie>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.verde),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: AppColors.textoSecundario),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _tentarDeNovo,
                        child: const Text('Tentar de novo'),
                      ),
                    ],
                  ),
                );
              }
              final movies = snapshot.data ?? [];
              if (movies.isEmpty) {
                return const Center(
                  child: Text('Nenhum filme nesta lista.',
                      style: TextStyle(color: AppColors.textoSecundario)),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: movies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => SizedBox(
                  width: 112,
                  child: MovieCard(
                    movie: movies[i],
                    onTap: () => widget.onTap(movies[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
