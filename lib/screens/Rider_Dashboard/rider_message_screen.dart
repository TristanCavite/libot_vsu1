import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libot_vsu1/models/user_profile.dart';
import 'package:libot_vsu1/screens/chat_screen.dart';
import 'package:libot_vsu1/utils/channel_utils.dart';

class RiderMessageScreen extends StatefulWidget {
  const RiderMessageScreen({super.key});

  @override
  State<RiderMessageScreen> createState() => _RiderMessageScreenState();
}

class _RiderMessageScreenState extends State<RiderMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _clients = [];
  List<UserProfile> _filteredClients = [];

  @override
  void initState() {
    super.initState();
    _fetchClients();

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredClients = _clients
            .where((client) => client.name.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  Future<void> _fetchClients() async {
    final riderId = FirebaseAuth.instance.currentUser?.uid;
    if (riderId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Client') // ✅ Ensure field match
          .get();

      final clients = snapshot.docs.map((doc) {
        return UserProfile.fromMap(doc.id, doc.data());
      }).toList();

      setState(() {
        _clients = clients;
        _filteredClients = clients;
      });
    } catch (e) {
      debugPrint("❌ Error fetching clients: $e");
    }
  }

  void _openChat(UserProfile client) {
    final riderId = FirebaseAuth.instance.currentUser?.uid;
    if (riderId == null) return;

    // ✅ Consistent channel naming: always clientId_riderId
    final channelName = generateChatChannel(client.id, riderId);


    // ✅ Send correct receiverId to ChatScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          channelName: channelName,
          receiverId: client.id,
          displayName: client.name,
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
                  hintText: 'Search clients...',
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

          // List of Clients
          Expanded(
            child: _filteredClients.isEmpty
                ? const Center(child: Text('No clients found.'))
                : ListView.builder(
                    itemCount: _filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = _filteredClients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: client.avatar.isNotEmpty
                              ? NetworkImage(client.avatar)
                              : const AssetImage('assets/images/default_profile.png')
                                  as ImageProvider,
                        ),
                        title: Text(client.name),
                        subtitle: const Text('Tap to chat...'),
                        onTap: () => _openChat(client), // ✅ Opens real-time chat
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
