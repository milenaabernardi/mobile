class ApiKeys {
  static const String tmdb = '7ad24047c04f1397e1058df7a384f7f8';
  static const String giphy = '2eFNgCQAWCZAJ4BDB65diJi3tEETvwIh';

  static bool get tmdbConfigurada => !tmdb.startsWith('COLE_');
  static bool get giphyConfigurada => !giphy.startsWith('COLE_');
}
