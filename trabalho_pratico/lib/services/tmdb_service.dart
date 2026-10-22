import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/movie.dart';
import '../models/movie_images.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class TmdbService {
  static const String _base = 'https://api.themoviedb.org/3';

  // ---------- Pesquisa ----------
  Future<List<Movie>> searchMovies(String query) {
    final uri = Uri.parse('$_base/search/movie').replace(queryParameters: {
      'api_key': ApiKeys.tmdb,
      'query': query,
      'language': 'pt-BR',
      'include_adult': 'false',
    });
    return _fetchMovies(uri);
  }

  // ---------- Listas da tela inicial ----------
  // Mais vistos do momento.
  Future<List<Movie>> popular() => _list('/movie/popular');

  // Em cartaz nos cinemas do Brasil.
  Future<List<Movie>> nowPlaying() => _list('/movie/now_playing', region: 'BR');

  ///Próximos lançamentos.
  Future<List<Movie>> upcoming() => _list('/movie/upcoming', region: 'BR');

  // Mais bem avaliados de todos os tempos.
  Future<List<Movie>> topRated() => _list('/movie/top_rated');

  // Sorteia um filme entre os populares (botão "Surpreenda-me").
  Future<Movie> randomPopularMovie() async {
    final page = Random().nextInt(10) + 1;
    final movies = await _list('/movie/popular', page: page);
    if (movies.isEmpty) {
      throw ApiException('Não foi possível sortear um filme agora.');
    }
    return movies[Random().nextInt(movies.length)];
  }

  // ---------- Imagens alternativas (pôsteres e backdrops) ----------
  Future<MovieImages> movieImages(int movieId) async {
    final uri =
        Uri.parse('$_base/movie/$movieId/images').replace(queryParameters: {
      'api_key': ApiKeys.tmdb,
      'include_image_language': 'pt,en,null',
    });
    final data = await _getJson(uri);
    return MovieImages(
      posters: _paths(data['posters']),
      backdrops: _paths(data['backdrops']),
    );
  }

  List<String> _paths(dynamic raw) {
    final list = (raw as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => e['file_path'])
        .whereType<String>()
        .toList();
    return list.take(30).toList();
  }

  // ---------- Auxiliares ----------
  Future<List<Movie>> _list(String path, {String? region, int page = 1}) {
    final params = {
      'api_key': ApiKeys.tmdb,
      'language': 'pt-BR',
      'page': '$page',
    };
    if (region != null) params['region'] = region;
    final uri = Uri.parse('$_base$path').replace(queryParameters: params);
    return _fetchMovies(uri);
  }

  Future<List<Movie>> _fetchMovies(Uri uri) async {
    final data = await _getJson(uri);
    final results = (data['results'] as List<dynamic>? ?? []);
    return results
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Faz a requisição e trata os erros mais comuns.
  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    if (!ApiKeys.tmdbConfigurada) {
      throw ApiException(
          'Chave da TMDB não configurada. Edite lib/config/api_keys.dart.');
    }
    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode == 401) {
        throw ApiException('Chave da TMDB inválida.');
      }
      if (response.statusCode != 200) {
        throw ApiException('Erro na TMDB (código ${response.statusCode}).');
      }
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
          'Sem conexão ou a TMDB não respondeu. Verifique a internet.');
    }
  }
}
