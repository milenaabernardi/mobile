class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String releaseDate;

  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: (json['title'] ?? 'Sem titulo') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: ((json['vote_average'] ?? 0) as num).toDouble(),
      releaseDate: (json['release_date'] ?? '') as String,
    );
  }

  /// Usado para salvar o filme nos favoritos (mesmas chaves da TMDB).
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'overview': overview,
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'vote_average': voteAverage,
        'release_date': releaseDate,
      };

  static const String _imgBase = 'https://image.tmdb.org/t/p';

  /// Monta a URL de uma imagem da TMDB (ex: size 'w185', 'w500', 'w780').
  static String imageUrl(String path, {String size = 'w500'}) =>
      '$_imgBase/$size$path';

  String? get posterUrl =>
      posterPath == null ? null : '$_imgBase/w500$posterPath';

  String? get backdropUrl =>
      backdropPath == null ? null : '$_imgBase/w780$backdropPath';

  /// Ano de lancamento (ex: "2010"), ou "—" se nao houver data.
  String get year =>
      releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '—';

  /// Nota de 0 a 10 convertida para 0 a 5 estrelas
  double get stars => voteAverage / 2;
}
