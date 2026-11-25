import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_message.dart';
import '../widgets/movie_card.dart';
import 'detail_screen.dart';

/// Aba "Buscar": campo de pesquisa + resultados da API.
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

  // Sugestões enquanto o usuário digita
  Timer? _debounce;
  int _consulta = 0;
  List<Movie> _sugestoes = [];
  bool _buscandoSugestoes = false;

  @override
  void dispose() {
    _debounce?.cancel();
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

    // A busca completa substitui as sugestões.
    _debounce?.cancel();
    _consulta++;
    _sugestoes = [];
    _buscandoSugestoes = false;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _tmdb.searchMovies(_controller.text.trim());
      if (!mounted) return;
      setState(() {
        _movies = result;
        _searched = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _movies = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Sugestões de filmes enquanto digita ----------
  void _aoDigitar(String texto) {
    final busca = texto.trim();
    _debounce?.cancel();

    if (busca.length < 2) {
      _consulta++;
      setState(() {
        _sugestoes = [];
        _buscandoSugestoes = false;
      });
      return;
    }
    // Espera o usuário parar de digitar antes de consultar a API.
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _buscarSugestoes(busca),
    );
  }

  Future<void> _buscarSugestoes(String busca) async {
    final minhaConsulta = ++_consulta;
    setState(() => _buscandoSugestoes = true);
    try {
      final filmes = await _tmdb.searchMovies(busca);
      if (!mounted || minhaConsulta != _consulta) return;
      setState(() => _sugestoes = filmes.take(8).toList());
    } catch (_) {
      // Sem internet: sem sugestões. O botão Buscar mostra a mensagem de erro.
      if (!mounted || minhaConsulta != _consulta) return;
      setState(() => _sugestoes = []);
    } finally {
      if (mounted && minhaConsulta == _consulta) {
        setState(() => _buscandoSugestoes = false);
      }
    }
  }

  void _escolherSugestao(Movie filme) {
    _debounce?.cancel();
    _consulta++;
    _controller.value = TextEditingValue(
      text: filme.title,
      selection: TextSelection.collapsed(offset: filme.title.length),
    );
    setState(() {
      _sugestoes = [];
      _buscandoSugestoes = false;
    });
    FocusScope.of(context).unfocus();
    abrirDetalhes(context, filme);
  }

  // ---------- Botão: Limpar ----------
  void _limpar() {
    _debounce?.cancel();
    _consulta++;
    _controller.clear();
    _formKey.currentState?.reset();
    setState(() {
      _sugestoes = [];
      _buscandoSugestoes = false;
      _movies = [];
      _error = null;
      _searched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buscar',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
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
                onChanged: _aoDigitar,
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
            const SizedBox(height: 14),
            SizedBox(
              height: 2,
              child: _buscandoSugestoes
                  ? const LinearProgressIndicator(
                      minHeight: 2,
                      color: AppColors.verde,
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSugestoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sugestões',
          style: TextStyle(color: AppColors.textoSecundario, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.separated(
            itemCount: _sugestoes.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.borda),
            itemBuilder: (context, i) {
              final f = _sugestoes[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 40,
                  height: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: MoviePoster(
                      url: f.posterPath == null
                          ? null
                          : Movie.imageUrl(f.posterPath!, size: 'w92'),
                    ),
                  ),
                ),
                title: Text(
                  f.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  f.voteAverage > 0
                      ? '${f.year}  •  ${f.voteAverage.toStringAsFixed(1)} / 10'
                      : f.year,
                  style: const TextStyle(color: AppColors.textoSecundario),
                ),
                onTap: () => _escolherSugestao(f),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.verde),
      );
    }
    if (_error != null) {
      return EmptyMessage(icon: Icons.error_outline, text: _error!);
    }
    if (_sugestoes.isNotEmpty) return _buildSugestoes();
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
