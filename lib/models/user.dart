class User {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final String role;
  final String? token;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.role = 'USER',
    this.token,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isVip => true;

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? (json['email'] != null ? json['email'].toString().split('@')[0] : 'User'),
      avatar: json['avatar'] as String?,
      role: json['role']?.toString() ?? 'USER',
      token: token ?? json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'role': role,
      'token': token,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    String? role,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      token: token ?? this.token,
    );
  }
}
