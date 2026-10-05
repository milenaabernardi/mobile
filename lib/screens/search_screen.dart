import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_message.dart';
import '../widgets/movie_card.dart';
import 'detail_screen.dart';

// Aba "Buscar"
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _tmdb = TmdbService();

  List<Movie> _movies = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------- Validação do campo de pesquisa ----------
  String? _validarBusca(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Digite o nome de um filme.';
    if (text.length < 2) return 'Digite pelo menos 2 caracteres.';
    return null;
  }

  // ---------- Botão: Buscar ----------
  Future<void> _buscar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _tmdb.searchMovies(_controller.text.trim());
      setState(() {
        _movies = result;
        _searched = true;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _movies = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Botão: Limpar ----------
  void _limpar() {
    _controller.clear();
    _formKey.currentState?.reset();
    setState(() {
      _movies = [];
      _error = null;
      _searched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                validator: _validarBusca,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _buscar(),
                decoration: const InputDecoration(
                  hintText: 'Busque um filme (ex: Interestelar)',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    key: const Key('btn_buscar'),
                    onPressed: _loading ? null : _buscar,
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _limpar,
                    icon: const Icon(Icons.close),
                    label: const Text('Limpar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.verde));
    }
    if (_error != null) {
      return EmptyMessage(icon: Icons.error_outline, text: _error!);
    }
    if (!_searched) {
      return const EmptyMessage(
        icon: Icons.local_movies_outlined,
        text: 'Busque um filme para ver o pôster, a nota e um GIF.',
      );
    }
    if (_movies.isEmpty) {
      return const EmptyMessage(
        icon: Icons.search_off,
        text: 'Nenhum filme encontrado. Tente outro nome.',
      );
    }
    return GridView.builder(
      itemCount: _movies.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        childAspectRatio: 0.52,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, i) => MovieCard(
        movie: _movies[i],
        onTap: () => abrirDetalhes(context, _movies[i]),
      ),
    );
  }
}
