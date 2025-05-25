// lib/utils/channel_utils.dart

/// Generates a consistent chat channel name between two users
/// regardless of order (e.g., "abc_123" is the same as "123_abc")
String generateChatChannel(String userA, String userB) {
  final ids = [userA, userB]..sort(); // sort alphabetically
  return '${ids[0]}_${ids[1]}';
}
