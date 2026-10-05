import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_section.dart';
import 'detail_screen.dart';

// Aba "Início": faixas de filmes por categoria.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _tmdb = TmdbService();
  bool _sorteando = false;

  // ---------- Botão: Surpreenda-me ----------
  Future<void> _sortear() async {
    setState(() => _sorteando = true);
    try {
      final movie = await _tmdb.randomPopularMovie();
      if (!mounted) return;
      abrirDetalhes(context, movie);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sorteando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Dot(Color.fromARGB(255, 244, 64, 229)),
            _Dot(Color.fromARGB(255, 249, 250, 250)),
            _Dot(Color.fromARGB(255, 255, 128, 1)),
            SizedBox(width: 10),
            Text(
              'Cineboxd',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'O que assistir hoje?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sorteando ? null : _sortear,
                    icon: _sorteando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.casino_outlined),
                    label: const Text('Surpreenda-me'),
                  ),
                ),
              ],
            ),
          ),
          MovieSection(
            title: 'Mais vistos',
            loader: _tmdb.popular,
            onTap: (m) => abrirDetalhes(context, m),
          ),
          MovieSection(
            title: 'Em cartaz',
            loader: _tmdb.nowPlaying,
            onTap: (m) => abrirDetalhes(context, m),
          ),
          MovieSection(
            title: 'Em breve',
            loader: _tmdb.upcoming,
            onTap: (m) => abrirDetalhes(context, m),
          ),
          MovieSection(
            title: 'Mais bem avaliados',
            loader: _tmdb.topRated,
            onTap: (m) => abrirDetalhes(context, m),
          ),
        ],
      ),
    );
  }
}

// Bolinha colorida usada ao lado do nome do app.
class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(right: 3),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
