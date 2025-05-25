// models/chat_message.dart

class ChatMessage {
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      text: map['text'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
