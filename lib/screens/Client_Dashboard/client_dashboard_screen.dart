import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:libot_vsu1/screens/Client_Dashboard/activity_screen.dart';
import 'package:libot_vsu1/screens/Client_Dashboard/message_screen.dart';
import 'package:libot_vsu1/screens/Client_Dashboard/Request_Screens/request_delivery_screen.dart';
import 'package:libot_vsu1/screens/Client_Dashboard/Request_Screens/request_ride_screen.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String greeting = 'Hello';
  String fullName = 'User';
  String selectedTab = 'Ride';

  // Add state variable to track current view
  bool showRequestScreen = false;
  Widget? currentContent;
  String requestType = '';

  List<Map<String, dynamic>> availableDrivers = [];
  List<String> savedPlaces = [];
  final TextEditingController destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setGreeting();
    _fetchUserProfile();
    _fetchAvailableDrivers();
    _loadSavedPlaces();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
  }

  void _fetchUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      fullName = doc['fullName'] ?? 'User';
    });
  }

  void _fetchAvailableDrivers() async {
    final query =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Rider')
            .where('status', isEqualTo: 'online')
            .get();

    setState(() {
      availableDrivers = query.docs.map((doc) => doc.data()).toList();
    });
  }

  void _loadSavedPlaces() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final List<dynamic> places = doc.data()?['savedPlaces'] ?? [];
    setState(() {
      savedPlaces = List<String>.from(places);
    });
  }

  void _addNewSavedPlace(String place) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || place.trim().isEmpty) return;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    await userDoc.update({
      'savedPlaces': FieldValue.arrayUnion([place]),
    });

    setState(() {
      savedPlaces.add(place);
    });
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () {},
        leading: const CircleAvatar(
          backgroundImage: AssetImage('assets/images/default_profile.png'),
        ),
        title: Text(driver['fullName'] ?? 'Unnamed'),
        subtitle: Text(driver['vehicle'] ?? 'Kawasaki Rouser'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.star, color: Colors.amber, size: 18),
            SizedBox(width: 4),
            Text('4.9'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00843D),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFF00843D)),
                  ),
                  const SizedBox(width: 12),
                  // Wrap the name section in Flexible to avoid overflow
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        RichText(
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$fullName ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const TextSpan(
                                text: '(Client)',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 0),
                      IconButton(
                        onPressed: () {},
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // NAVBAR
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF00843D),
                        unselectedLabelColor: Colors.grey,
                        indicator: const BoxDecoration(),
                        tabs: const [
                          Tab(icon: Icon(Icons.home), text: 'Home'),
                          Tab(icon: Icon(Icons.show_chart), text: 'Activity'),
                          Tab(icon: Icon(Icons.message), text: 'Messages'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // First tab content with conditional display
                            _buildHomeTabContent(),
                            const ActivityScreen(),
                            const MessageScreen(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ), // End of Navbar
          ],
        ),
      ),
    );
  }

  // For showing the request screen or the home tab content
  Widget _buildHomeTabContent() {
    if (showRequestScreen) {
      return Column(
        children: [
          // Back button row
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    showRequestScreen = false;
                  });
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0x1A00843D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF00843D),
                    size: 24,
                  ),
                ),
              ),
              Text(
                '$requestType Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // Request screen content
          Expanded(child: currentContent ?? Container()),
        ],
      );
    } else {
      // Show regular home tab
      return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      // ✅ FIX: makes content scrollable on keyboard
      padding: const EdgeInsets.only(bottom: 20), // ✅ Add padding for safety
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => selectedTab = 'Ride'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedTab == 'Ride'
                            ? const Color(0xFF00A651)
                            : Colors.grey.shade200,
                    foregroundColor:
                        selectedTab == 'Ride' ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Ride'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => selectedTab = 'Delivery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedTab == 'Delivery'
                            ? const Color(0xFF00A651)
                            : Colors.grey.shade200,
                    foregroundColor:
                        selectedTab == 'Delivery' ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Delivery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (selectedTab == 'Ride')
            TypeAheadField<String>(
              controller: destinationController,
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on),
                    hintText: 'Destination',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              suggestionsCallback: (pattern) {
                final suggestions = [
                  'VSU Market',
                  'Upper Oval',
                  'Tambaan Farm Cafe',
                  'Dlabs',
                  'DCST',
                  'Upper Utod',
                  'Lower Utod',
                  'Lower Oval',
                  'Gabas',
                  'Bunga',
                  'Marcos',
                  'Patag',
                  'Pangasugan',
                  'Baybay proper',
                  'Kilim',
                  'San Agustin',
                  'Candadam',
                  'Sta. Cruz',
                ];
                return suggestions
                    .where(
                      (place) =>
                          place.toLowerCase().contains(pattern.toLowerCase()),
                    )
                    .toList();
              },
              itemBuilder: (context, String suggestion) {
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(suggestion),
                );
              },
              onSelected: (String suggestion) {
                setState(() {
                  destinationController.text = suggestion;
                });
              },
            ),
          const SizedBox(height: 20),
          const Text(
            'Available Drivers Nearby',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (availableDrivers.isEmpty)
            const Text('No available riders at the moment')
          else
            Column(children: availableDrivers.map(_buildDriverCard).toList()),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Saved Places',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final newPlace = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        title: const Text('Add New Place'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Enter place name',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed:
                                () => Navigator.pop(
                                  context,
                                  controller.text.trim(),
                                ),
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                  if (newPlace != null && newPlace.isNotEmpty) {
                    _addNewSavedPlace(newPlace);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (savedPlaces.isEmpty)
            const Text('No saved places yet')
          else
            Column(
              children:
                  savedPlaces
                      .map(
                        (place) => ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(place),
                          onTap: () {
                            destinationController.text = place;
                          },
                        ),
                      )
                      .toList(),
            ),
          const SizedBox(height: 16),

          // Modified Request Ride or Delivery Button
          ElevatedButton(
            onPressed: () {
              // Set the content based on selected tab
              setState(() {
                if (selectedTab == 'Ride') {
                  currentContent = const RequestRideScreen();
                  requestType = 'Ride';
                } else {
                  currentContent = const RequestDeliveryScreen();
                  requestType = 'Delivery';
                }
                showRequestScreen = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A651),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              selectedTab == 'Ride' ? 'Request Ride' : 'Request Delivery',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
