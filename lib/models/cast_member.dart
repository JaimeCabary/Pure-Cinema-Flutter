class CastMember {
  final int id;
  final String name;
  final String character;
  final String? profilePath;

  CastMember({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });

  String get profileUrl => profilePath != null
      ? 'https://image.tmdb.org/t/p/w185$profilePath'
      : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=185&q=80';

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? 'Unknown Actor') as String,
      character: (json['character'] ?? 'Cast') as String,
      profilePath: json['profile_path'] as String?,
    );
  }
}
