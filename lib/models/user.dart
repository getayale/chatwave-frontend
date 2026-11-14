class User {
  final String id;
  final String username;
  final String? email;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final DateTime? createdAt;
  final String profileVisibility;

  const User({
    required this.id,
    required this.username,
    this.email,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.createdAt,
    this.profileVisibility = 'PUBLIC',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      displayName: json['displayName'],
      bio: json['bio'],
      avatarUrl: json['avatarUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      profileVisibility: json['profileVisibility'] ?? 'PUBLIC',
    );
  }
}
