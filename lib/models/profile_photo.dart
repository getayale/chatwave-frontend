class ProfilePhoto {
  final String id;
  final String imageUrl;
  final String storageKey;
  final String userId;
  final DateTime createdAt;

  const ProfilePhoto({
    required this.id,
    required this.imageUrl,
    required this.storageKey,
    required this.userId,
    required this.createdAt,
  });

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(
      id: json['id'],
      imageUrl: json['imageUrl'],
      storageKey: json['storageKey'],
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
