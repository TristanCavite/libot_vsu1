class UserProfile {
  final String id;
  final String name;
  final String avatar;
  final bool isOnline;
  final String? lastMessage;

  UserProfile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.isOnline,
    this.lastMessage,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      name: data['fullName'] ?? 'Unknown',
      avatar: data['profileUrl'] ?? '',
      isOnline: data['status'] == 'online',
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? avatar,
    bool? isOnline,
    String? lastMessage,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
