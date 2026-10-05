class MovieImages {
  final List<String> posters;
  final List<String> backdrops;

  const MovieImages({required this.posters, required this.backdrops});

  static const MovieImages empty = MovieImages(posters: [], backdrops: []);
}
