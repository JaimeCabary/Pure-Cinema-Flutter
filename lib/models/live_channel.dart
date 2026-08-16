class LiveChannel {
  final String id;
  final String name;
  final String logo;
  final String group;
  final String streamUrl;
  final String? country;
  final String? currentProgram;
  final String? badge;

  LiveChannel({
    required this.id,
    required this.name,
    required this.logo,
    required this.group,
    required this.streamUrl,
    this.country,
    this.currentProgram,
    this.badge,
  });

  factory LiveChannel.fromJson(Map<String, dynamic> json) {
    return LiveChannel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      logo: json['logo'] ?? '',
      group: json['group'] ?? 'General',
      streamUrl: json['streamUrl'] ?? '',
      country: json['country'],
      currentProgram: json['currentProgram'],
      badge: json['badge'],
    );
  }
}
