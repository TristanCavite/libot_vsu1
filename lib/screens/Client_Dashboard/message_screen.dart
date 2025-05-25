import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libot_vsu1/models/user_profile.dart';
import 'package:libot_vsu1/screens/chat_screen.dart';
import 'package:libot_vsu1/utils/channel_utils.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => MessageScreenState();
}

class MessageScreenState extends State<MessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _allRiders = [];
  List<UserProfile> _filteredRiders = [];

  @override
  void initState() {
    super.initState();
    _loadRiders();

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredRiders = _allRiders
            .where((rider) => rider.name.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  Future<void> _loadRiders() async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Rider')
        .get();

    final riders = query.docs.map((doc) {
      return UserProfile.fromMap(doc.id, doc.data());
    }).toList();

    setState(() {
      _allRiders = riders;
      _filteredRiders = riders;
    });
  }

  void _openChat(UserProfile rider) {
    final clientId = FirebaseAuth.instance.currentUser?.uid;
    if (clientId == null) return;

    // 👇 Updated: make sure channel is always clientId_riderId regardless of who starts it
       final channelName = generateChatChannel(clientId, rider.id);


    // 👇 Pass both channelName and receiverId to ChatScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          channelName: channelName,
          receiverId: rider.id, // ✅ Needed for receiver tracking
          displayName: rider.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
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
                controller: _searchController,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search riders...',
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

          // Rider List
          Expanded(
            child: _filteredRiders.isEmpty
                ? const Center(child: Text('No riders found'))
                : ListView.builder(
                    itemCount: _filteredRiders.length,
                    itemBuilder: (context, index) {
                      final rider = _filteredRiders[index];
                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: rider.avatar.isNotEmpty
                                  ? NetworkImage(rider.avatar)
                                  : const AssetImage(
                                      'assets/images/default_profile.png',
                                    ) as ImageProvider,
                            ),
                            if (rider.isOnline)
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
                        title: Text(rider.name),
                        subtitle: const Text('Tap to chat...'),
                        onTap: () => _openChat(rider), // ✅ Navigates to ChatScreen
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}