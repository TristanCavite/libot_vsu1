import 'package:flutter/material.dart';

class RiderMessageScreen extends StatelessWidget {
  const RiderMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    //Mock data for messages
    final List<Map<String, dynamic>> messages = [
      {
        'name': 'David Bombal',
        'message': 'Hey, are you available to give me a ride?',
        'time': '12:41 AM',
        'online': true,
        'avatar': 'assets/images/default_profile.png',
        'isRead': true,
        'unreadCount': 0,
      },
      {
        'name': 'Sam Garcia',
        'message': 'Can you deliver the document I have right now?',
        'time': '12:08 PM',
        'online': false,
        'avatar': 'assets/images/default_profile.png',
        'isRead': true,
        'unreadCount': 0,
      },
      {
        'name': 'David Kim',
        'message': 'Hey, are you available to give me a ride?',
        'time': '12:41 AM',
        'online': true,
        'avatar': 'assets/images/default_profile.png',
        'isRead': false,
        'unreadCount': 2,
      },
      {
        'name': 'Sam Garcia',
        'message': 'Can you deliver the document I have right now?',
        'time': '12:08 PM',
        'online': false,
        'avatar': 'assets/images/default_profile.png',
        'isRead': true,
        'unreadCount': 0,
      },
      {
        'name': 'Serge Garcia',
        'message': 'Can you deliver the document I have right now?',
        'time': '12:08 PM',
        'online': false,
        'avatar': 'assets/images/default_profile.png',
        'isRead': false,
        'unreadCount': 5,
      },
      {
        'name': 'Jhon Doe',
        'message': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        'time': '2:08 PM',
        'online': false,
        'avatar': 'assets/images/default_profile.png',
        'isRead': false,
        'unreadCount': 1,
      },
    ];

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    // Add message logic ngari
                  },
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search messages...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // Message List
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final bool isRead = msg['isRead'] ?? false;

                  return Container(
                    color:
                        isRead
                            ? Colors.white
                            : const Color(0xFFF1F1F1), // Highlight if unread
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: AssetImage(msg['avatar']),
                          ),
                          if (msg['online'])
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        msg['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        msg['message'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            msg['time'],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (msg['unreadCount'] != null &&
                              msg['unreadCount'] > 0)
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF00843D),
                              child: Text(
                                '${msg['unreadCount']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {},
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
