class UserProfile {
  final String id;
  final String name;
  final String avatar;
  final bool isOnline;

  UserProfile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.isOnline,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      name: data['fullName'] ?? 'Unknown',
      avatar: data['profileUrl'] ?? '',
      isOnline: data['status'] == 'online',
    );
  }
}
