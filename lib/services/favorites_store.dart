import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

// Guarda os favoritos e salva no aparelho.
class FavoritesStore {
  FavoritesStore._();
  static final FavoritesStore instance = FavoritesStore._();

  static const String _key = 'favoritos';

  final ValueNotifier<List<Movie>> favorites = ValueNotifier([]);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      favorites.value = list
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Se algo falhar, o app apenas começa com a lista vazia.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(favorites.value.map((m) => m.toJson()).toList());
      await prefs.setString(_key, raw);
    } catch (_) {}
  }

  bool isFavorite(Movie movie) =>
      favorites.value.any((m) => m.id == movie.id);

  // Adiciona ou remove. Retorna true se ficou favoritado.
  bool toggle(Movie movie) {
    final current = List<Movie>.from(favorites.value);
    final index = current.indexWhere((m) => m.id == movie.id);
    final favoritou = index < 0;
    if (favoritou) {
      current.add(movie);
    } else {
      current.removeAt(index);
    }
    favorites.value = current;
    _save();
    return favoritou;
  }

  // Atualiza um favorito já salvo (ex: pôster ou backdrop trocado).
  void update(Movie movie) {
    final current = List<Movie>.from(favorites.value);
    final index = current.indexWhere((m) => m.id == movie.id);
    if (index < 0) return;
    current[index] = movie;
    favorites.value = current;
    _save();
  }

  void clear() {
    favorites.value = [];
    _save();
  }
}
