import 'dart:math';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/movie_images.dart';
import '../services/favorites_store.dart';
import '../services/giphy_service.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_picker_sheet.dart';
import '../widgets/movie_card.dart';

class DetailScreen extends StatefulWidget {
  final Movie movie;
  const DetailScreen({super.key, required this.movie});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _giphy = GiphyService();
  final _tmdb = TmdbService();

  List<String> _gifs = [];
  String? _gifAtual;
  bool _carregandoGif = true;

  // Imagens escolhidas pelo usuário
  late String? _posterPath = widget.movie.posterPath;
  late String? _backdropPath = widget.movie.backdropPath;

  // Imagens alternativas
  Future<MovieImages>? _imagesFuture;

  Movie get movie => widget.movie;

  // O filme com o pôster e o backdrop atualmente escolhidos.
  Movie get _current => Movie(
        id: movie.id,
        title: movie.title,
        overview: movie.overview,
        posterPath: _posterPath,
        backdropPath: _backdropPath,
        voteAverage: movie.voteAverage,
        releaseDate: movie.releaseDate,
      );

  @override
  void initState() {
    super.initState();
    _carregarGifs();
  }

  Future<void> _carregarGifs() async {
    final gifs = await _giphy.searchGifs('${movie.title} movie');
    if (!mounted) return;
    setState(() {
      _gifs = gifs;
      _gifAtual = gifs.isEmpty ? null : gifs[Random().nextInt(gifs.length)];
      _carregandoGif = false;
    });
  }

  Future<MovieImages> _loadImages() {
    final future = _imagesFuture ??= _tmdb.movieImages(movie.id);
    future.catchError((_) {
      _imagesFuture = null;
      return MovieImages.empty;
    });
    return future;
  }

  // ---------- Botão: Trocar pôster ----------
  void _trocarPoster() {
    showImagePickerSheet(
      context: context,
      title: 'Escolha um pôster',
      imagesFuture: _loadImages().then((i) => i.posters),
      selectedPath: _posterPath,
      backdrop: false,
      onSelected: (path) {
        setState(() => _posterPath = path);
        _salvarSeFavorito();
      },
    );
  }

  // ---------- Botão: Trocar backdrop ----------
  void _trocarBackdrop() {
    showImagePickerSheet(
      context: context,
      title: 'Escolha um backdrop',
      imagesFuture: _loadImages().then((i) => i.backdrops),
      selectedPath: _backdropPath,
      backdrop: true,
      onSelected: (path) {
        setState(() => _backdropPath = path);
        _salvarSeFavorito();
      },
    );
  }

  // Se o filme já é favorito, guarda também as imagens escolhidas.
  void _salvarSeFavorito() {
    if (FavoritesStore.instance.isFavorite(movie)) {
      FavoritesStore.instance.update(_current);
    }
  }

  // ---------- Botão: Outro GIF ----------
  void _outroGif() {
    if (_gifs.length < 2) {
      _mostrarAviso('Não há outros GIFs para este filme.');
      return;
    }
    String novo;
    do {
      novo = _gifs[Random().nextInt(_gifs.length)];
    } while (novo == _gifAtual);
    setState(() => _gifAtual = novo);
  }

  // ---------- Botão: Favoritar ----------
  void _favoritar() {
    final favoritou = FavoritesStore.instance.toggle(_current);
    _mostrarAviso(
        favoritou ? 'Adicionado aos favoritos.' : 'Removido dos favoritos.');
  }

  void _mostrarAviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final atual = _current;
    return Scaffold(
      appBar: AppBar(title: Text(movie.title, overflow: TextOverflow.ellipsis)),
      body: ListView(
        children: [
          if (atual.backdropUrl != null)
            SizedBox(
              height: 190,
              child: Image.network(
                atual.backdropUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.superficie),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(atual),
                const SizedBox(height: 16),
                Text(
                  movie.overview.isEmpty
                      ? 'Este filme ainda não tem sinopse em português.'
                      : movie.overview,
                  style: const TextStyle(height: 1.45),
                ),
                const SizedBox(height: 16),
                _buildFavoriteButton(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _trocarPoster,
                        icon: const Icon(Icons.photo_outlined,
                            color: AppColors.laranja),
                        label: const Text('Trocar pôster'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _trocarBackdrop,
                        icon: const Icon(Icons.wallpaper_outlined,
                            color: AppColors.laranja),
                        label: const Text('Trocar backdrop'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('GIF',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _buildGifSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Movie atual) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          height: 165,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: MoviePoster(url: atual.posterUrl),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie.title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(movie.year,
                  style: const TextStyle(color: AppColors.textoSecundario)),
              const SizedBox(height: 10),
              StarRating(stars: movie.stars),
              const SizedBox(height: 4),
              Text(
                movie.voteAverage > 0
                    ? '${movie.voteAverage.toStringAsFixed(1)} / 10'
                    : 'Sem nota ainda',
                style: const TextStyle(
                    color: AppColors.textoSecundario, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return SizedBox(
      width: double.infinity,
      child: ValueListenableBuilder<List<Movie>>(
        valueListenable: FavoritesStore.instance.favorites,
        builder: (context, _, __) {
          final fav = FavoritesStore.instance.isFavorite(movie);
          return FilledButton.icon(
            onPressed: _favoritar,
            icon: Icon(fav ? Icons.favorite : Icons.favorite_border),
            label: Text(fav ? 'Favoritado' : 'Favoritar'),
          );
        },
      ),
    );
  }

  Widget _buildGifSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGif(),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _carregandoGif ? null : _outroGif,
            icon: const Icon(Icons.gif_box_outlined, color: AppColors.azul),
            label: const Text('Outro GIF'),
          ),
        ),
      ],
    );
  }

  Widget _buildGif() {
    if (_carregandoGif) {
      return const SizedBox(
        height: 100,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.verde)),
      );
    }
    if (_gifAtual == null) {
      return const Text(
        'Nenhum GIF encontrado para este filme (confira a chave do GIPHY).',
        style: TextStyle(color: AppColors.textoSecundario),
      );
    }
    // GIF pequeno e centralizado
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 140, maxWidth: 260),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            _gifAtual!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(
              height: 80,
              child: Center(child: Text('Não foi possível carregar o GIF.')),
            ),
          ),
        ),
      ),
    );
  }
}

// Abre a tela de detalhes de um filme (usada por todas as telas).
void abrirDetalhes(BuildContext context, Movie movie) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => DetailScreen(movie: movie)),
  );
}
