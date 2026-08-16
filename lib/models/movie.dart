class Movie {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String overview;
  final String releaseDate;
  final double voteAverage;
  final List<int>? genreIds;

  Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    required this.releaseDate,
    required this.voteAverage,
    this.genreIds,
  });

  String get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=500&q=80';

  String get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/original$backdropPath'
      : 'https://images.unsplash.com/photo-1518676590629-3dcbd9c5a5c9?w=1200&q=80';

  String get releaseYear => releaseDate.isNotEmpty ? releaseDate.split('-')[0] : '2026';

  int get matchScore => (voteAverage * 10).round();

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int? ?? 0,
      title: (json['title'] ?? json['name'] ?? 'Untitled') as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: (json['overview'] ?? '') as String,
      releaseDate: (json['release_date'] ?? json['first_air_date'] ?? '') as String,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 7.5,
      genreIds: (json['genre_ids'] as List<dynamic>?)?.map((e) => e as int).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'poster_path': posterPath,
    'backdrop_path': backdropPath,
    'overview': overview,
    'release_date': releaseDate,
    'vote_average': voteAverage,
  };
}
