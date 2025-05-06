import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:libot_vsu1/screens/Rider_Dashboard/rider_activity_screen.dart';
import 'package:libot_vsu1/screens/Rider_Dashboard/rider_message_screen.dart';
import 'package:libot_vsu1/screens/setting.dart';
import 'package:libot_vsu1/screens/Profile/rider_Profile_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String greeting = 'Hello';
  String fullName = 'User';
  String selectedTab = 'Ride';
  String profileUrl = '';

  // Add state variable to track current view
  bool showRequestScreen = false;
  Widget? currentContent;
  String requestType = '';

  List<Map<String, dynamic>> availableDrivers = [];
  List<String> savedPlaces = [];
  final TextEditingController destinationController = TextEditingController();

  // Add passenger and delivery requests lists
  List<Map<String, dynamic>> passengerRequests = [];
  List<Map<String, dynamic>> deliveryRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setGreeting();
    _fetchUserProfile();
    _loadRequestsData(); // Combined loading function
  }

  void _loadRequestsData() {
    _fetchPassengerRequest();
    _fetchDeliveryRequest();
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
    final data = doc.data();

    if (data != null) {
      setState(() {
        fullName = data['fullName'] ?? 'User';
        profileUrl = data['profileUrl'] ?? ''; // ✅ Get profile picture
      });
    }
  }



 void _fetchPassengerRequest() async {
  final rideRequestSnapshot = await FirebaseFirestore.instance
      .collection('ride_requests')
      .where('status', isEqualTo: 'pending')
      .get();

  final List<Map<String, dynamic>> fetchedRequests = [];

  for (var doc in rideRequestSnapshot.docs) {
    final data = doc.data();
    final clientId = data['clientId']; // ✅ Correct field

    // Get user info (name + profile picture)
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(clientId)
        .get();
    final userData = userDoc.data();

    if (userData != null) {
      fetchedRequests.add({
        'name': userData['fullName'] ?? 'Unknown',
        'pickup': data['pickupLocation'] ?? 'Unknown',
        'destination': data['destination'] ?? 'Unknown',
        'profileUrl': userData['profileUrl'] ?? '',
        'avatarColor': Colors.blue,
      });
    }
  }

  setState(() {
    passengerRequests = fetchedRequests;
  });
}



  // Sample data for delivery requests
  final deliveryData = [
    {
      'name': 'John Doe',
      'item': 'Book',
      'destination': 'Library',
      'avatarColor': Colors.blue,
    },
    {
      'name': 'Jane Smith',
      'item': 'Folder',
      'destination': 'DLABS',
      'avatarColor': Colors.orange,
    },
  ];

  void _fetchDeliveryRequest() {
    // Fetching delivery data logic here
    setState(() {
      deliveryRequests = deliveryData;
    });
  }

  void _showConfirmationDialog(String type, Map<String, dynamic> request) {
    String name = request['name'] ?? 'Unknown';

    String contentText;
    if (type == 'passenger') {
      String pickup = request['pickup'] ?? 'Unknown';
      String destination = request['destination'] ?? 'Unknown';
      contentText =
          "Do you want to accept this passenger request from $name?\n\nRoute: $pickup → $destination";
    } else if (type == 'delivery') {
      String item = request['item'] ?? 'Item';
      String destination = request['destination'] ?? 'Unknown';
      contentText =
          "Do you want to accept this delivery request from $name?\n\n Item: $item \n To be delivered at $destination";
    } else {
      contentText = "Do you want to accept the request from $name?";
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Confirm Request",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF00843D),
            ),
          ),
          content: Text(contentText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Handle accept logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('You accepted the request from $name.'),
                  ),
                );
              },
              child: const Text(
                "Accept",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RiderProfileScreen(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          profileUrl.isNotEmpty
                              ? NetworkImage(profileUrl)
                              : null,
                      child:
                          profileUrl.isEmpty
                              ? const Icon(
                                Icons.person,
                                color: Color(0xFF00843D),
                              )
                              : null,
                    ),
                  ),

                  const SizedBox(width: 12),
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
                                text: '(Rider)',
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingScreen(),
                            ),
                          );
                        },
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

            // Main content area
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
                            _buildHomeTabContent(),
                            const RiderActivityScreen(),
                            const RiderMessageScreen(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTabContent() {
    return Container(
      color: Colors.white, // Ensure a base color
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ride/Delivery toggle buttons
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

          // Title section
          Text(
            selectedTab == 'Ride'
                ? 'Available Passengers Requests'
                : 'Available Delivery Requests',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // Request List - Key fix: wrapping in Expanded
          Expanded(
            child:
                selectedTab == 'Ride'
                    ? _buildPassengerList()
                    : _buildDeliveryList(),
          ),
        ],
      ),
    );
  }

  // Passenger List Builder
  Widget _buildPassengerList() {
    // If list is empty, show a message
    if (passengerRequests.isEmpty) {
      return const Center(child: Text('No passenger requests available'));
    }

    // If list has data
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: passengerRequests.length,
      itemBuilder: (context, index) {
        final request = passengerRequests[index];
        return _buildRequestCard(type: 'passenger', request: request);
      },
    );
  }

  // Delivery List Builder
  Widget _buildDeliveryList() {
    //If list is empty, show a message
    if (deliveryRequests.isEmpty) {
      return const Center(child: Text('No delivery requests available'));
    }

    //If list has data
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: deliveryRequests.length,
      itemBuilder: (context, index) {
        final request = deliveryRequests[index];
        return _buildRequestCard(type: 'delivery', request: request);
      },
    );
  }

  Widget _buildRequestCard({
    required String type, // "passenger" or "delivery"
    required Map<String, dynamic> request,
  }) {
    // Common fields
    final String name = request['name'];
    final Color avatarColor = request['avatarColor'] ?? Colors.grey;

    // Get initials from name
    // Placeholder since wala pay picture
    String initials =
        name
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => part[0])
            .take(2)
            .join();

    // Dynamic fields
    String titleText = '';
    String subtitleText = '';

    if (type == 'passenger') {
      final String pickup = request['pickup'] ?? 'Unknown';
      final String destination = request['destination'] ?? 'Unknown';
      titleText = name;
      subtitleText = '$pickup → $destination';
      //
    } else if (type == 'delivery') {
      final String item = request['item'] ?? 'Item';
      final String destination = request['destination'] ?? 'Unknown';
      titleText = name;
      subtitleText = '$item to be delivered at $destination';
    }

    return InkWell(
      onTap: () => _showConfirmationDialog(type, request),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
  radius: 20,
  backgroundColor: avatarColor,
  backgroundImage: request['profileUrl'] != ''
      ? NetworkImage(request['profileUrl'])
      : null,
  child: request['profileUrl'] == ''
      ? Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        )
      : null,
),

              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subtitleText,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
