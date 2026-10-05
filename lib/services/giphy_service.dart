import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class GiphyService {
  static const String _base = 'https://api.giphy.com/v1/gifs/search';

  // Retorna ate 15 URLs de GIFs relacionados ao termo.
  // Se der erro ou nao houver GIFs, retorna lista vazia.
  Future<List<String>> searchGifs(String term) async {
    if (!ApiKeys.giphyConfigurada) return [];
    try {
      final uri = Uri.parse(_base).replace(queryParameters: {
        'api_key': ApiKeys.giphy,
        'q': term,
        'limit': '15',
        'rating': 'pg-13',
        'lang': 'pt',
      });
      final response =
          await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['data'] as List<dynamic>? ?? []);
      return list
          .map((g) => (g['images']?['fixed_height']?['url']) as String?)
          .whereType<String>()
          .toList();
    } catch (_) {
      return [];
    }
  }
}
