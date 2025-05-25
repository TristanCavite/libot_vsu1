import 'package:flutter/material.dart';
import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libot_vsu1/models/chat_message.dart';
import 'package:libot_vsu1/services/ably_service.dart';

class ChatScreen extends StatefulWidget {
  final String channelName; // Format: clientId_riderId
  final String receiverId;  // Opposite user's UID
  final String displayName;

  const ChatScreen({
    super.key,
    required this.channelName,
    required this.receiverId,
     required this.displayName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  late ably.RealtimeChannel _channel;
  final _currentUser = FirebaseAuth.instance.currentUser;


@override
void initState() {
  super.initState();

  _channel = AblyService.getChannel(widget.channelName);

  // ✅ Load past messages from Firestore
  _loadPreviousMessages();

  // ✅ Listen for new real-time messages from Ably
  _channel.subscribe(name: 'chat').listen((ably.Message message) {
    debugPrint("📥 Raw message: ${message.data}");

    try {
      final raw = message.data;
      final data = Map<String, dynamic>.from(raw as Map); // Cast safely
      final chatMessage = ChatMessage.fromMap(data);

      // Avoid duplicates if sender is current user and it's already in local list
      final exists = _messages.any((m) =>
          m.text == chatMessage.text &&
          m.senderId == chatMessage.senderId &&
          m.timestamp == chatMessage.timestamp);

      if (!exists) {
        setState(() => _messages.insert(0, chatMessage));
        debugPrint("✅ Message added to UI");
      } else {
        debugPrint("⚠️ Duplicate ignored");
      }
    } catch (e) {
      debugPrint("❌ Failed to parse message: $e");
    }
  });
}


Future<void> _loadPreviousMessages() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('chat_channels')
        .doc(widget.channelName)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .get();

    final messages = snapshot.docs.map((doc) {
      return ChatMessage.fromMap(doc.data());
    }).toList();

    setState(() {
      _messages.addAll(messages);
    });

    debugPrint("✅ Loaded ${messages.length} messages from Firestore");
  } catch (e) {
    debugPrint("❌ Failed to load messages: $e");
  }
}



Future<void> _sendMessage() async {
  final messageText = _controller.text.trim();
  if (messageText.isEmpty || _currentUser == null) return;

  final msg = ChatMessage(
    senderId: _currentUser.uid,
    receiverId: widget.receiverId,
    text: messageText,
    timestamp: DateTime.now(),
  );

  // ✅ Store message in Firestore
  await FirebaseFirestore.instance
      .collection('chat_channels')
      .doc(widget.channelName)
      .collection('messages')
      .add(msg.toMap());

  // ✅ Send to Ably for real-time display
  _channel.publish(name: 'chat', data: msg.toMap());

  _controller.clear();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayName),
        backgroundColor: const Color(0xFF00843D),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final msg = _messages[index];
                final isMe = msg.senderId == _currentUser?.uid;

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 10,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF00843D)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('hh:mm a').format(msg.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: const Color(0xFF00843D),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}