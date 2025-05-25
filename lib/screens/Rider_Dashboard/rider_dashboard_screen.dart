import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:libot_vsu1/screens/Rider_Dashboard/rider_activity_screen.dart';
import 'package:libot_vsu1/screens/Rider_Dashboard/rider_message_screen.dart';
import 'package:libot_vsu1/screens/setting.dart';
import 'package:libot_vsu1/screens/Profile/rider_Profile_screen.dart';
import 'package:libot_vsu1/widgets/osm_map.dart'; // 🗺️ OSM map widget
import 'package:latlong2/latlong.dart'; // 🌐 For LatLng

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

  // --- State variables for Confirmation Screen ---
  bool _isShowingConfirmationScreen = false;
  Map<String, dynamic>? _selectedRequestData;
  String? _selectedRequestType;

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

    // Add listener to reset confirmation screen state if user navigates away from Home tab
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      // 🔄 Reset confirmation when leaving Home tab
      if (_tabController.index != 0 && _isShowingConfirmationScreen) {
        setState(() {
          _isShowingConfirmationScreen = false;
          _selectedRequestData = null;
          _selectedRequestType = null;
        });
      }

      // ✅ Fetch fresh requests every time Home tab is selected
      if (_tabController.index == 0) {
        _loadRequestsData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index != 0 && _isShowingConfirmationScreen) {
      if (mounted) {
        setState(() {
          _isShowingConfirmationScreen = false;
          _selectedRequestData = null;
          _selectedRequestType = null;
        });
      }
    }
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

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();

      if (mounted && data != null) {
        setState(() {
          fullName = data['fullName'] ?? 'User';
          profileUrl = data['profileUrl'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        print("Error fetching user profile: $e");
      }
    }
  }

  void _fetchPassengerRequest() async {
    try {
      final rideRequestSnapshot =
          await FirebaseFirestore.instance
              .collection('ride_requests')
              .where('status', isEqualTo: 'pending')
              .get();

      final List<Map<String, dynamic>> fetchedRequests = [];

      // Using Future.wait for potentially faster user data fetching if many requests
      List<Future<void>> userFetchFutures = [];

      for (var doc in rideRequestSnapshot.docs) {
        final data = doc.data();
        final clientId = data['clientId'];

        if (clientId != null) {
          // Add a future to fetch user data and add to the list
          userFetchFutures.add(
            FirebaseFirestore.instance
                .collection('users')
                .doc(clientId)
                .get()
                .then((userDoc) {
                  final userData = userDoc.data();
                  if (userData != null) {
                    fetchedRequests.add({
                      'id': doc.id,
                      'name': userData['fullName'] ?? 'Unknown',
                      'pickup': data['pickupLocation'] ?? 'Unknown',
                      'destination': data['destination'] ?? 'Unknown',
                      'pickupTime': data['pickupTime'] ?? '',
                      'paymentMethod': data['paymentMethod'] ?? '',
                      'pickupPin': data['pickupPin'],
                      'destinationPin': data['destinationPin'],
                      'profileUrl': userData['profileUrl'] ?? '',
                      'avatarColor': Colors.blue,
                    });
                  }
                })
                .catchError((e) {
                  print("Error fetching user data for client $clientId: $e");
                }),
          );
        }
      }

      await Future.wait(userFetchFutures);

      if (mounted) {
        // Check again if widget is still mounted
        setState(() {
          passengerRequests = fetchedRequests;
        });
      }
    } catch (e) {
      if (mounted) {
        print("Error fetching passenger requests: $e");
      }
    }
  }

  void _fetchDeliveryRequest() async {
    try {
      final deliverySnapshot =
          await FirebaseFirestore.instance
              .collection('delivery_requests')
              .where('status', isEqualTo: 'pending')
              .get();

      final List<Map<String, dynamic>> fetchedDeliveries = [];

      List<Future<void>> fetches = [];

      for (var doc in deliverySnapshot.docs) {
        final data = doc.data();
        final clientId = data['clientId'];

        if (clientId != null) {
          fetches.add(
            FirebaseFirestore.instance
                .collection('users')
                .doc(clientId)
                .get()
                .then((userDoc) {
                  final userData = userDoc.data();
                  if (userData != null) {
                    fetchedDeliveries.add({
                      'id': doc.id,
                      'name': userData['fullName'] ?? 'Unknown',
                      'profileUrl': userData['profileUrl'] ?? '',
                      'avatarColor': Colors.orange,
                      'pickup': data['pickupLocation'] ?? 'Unknown',
                      'destination': data['destination'] ?? 'Unknown',
                      'pickupTime': data['pickupTime'] ?? '',
                      'paymentMethod': data['paymentMethod'] ?? '',
                      'pickupPin': data['pickupPin'],
                      'destinationPin': data['destinationPin'],
                      'orders': data['orders'] ?? '',
                    });
                  }
                }),
          );
        }
      }

      await Future.wait(fetches);

      if (mounted) {
        setState(() {
          deliveryRequests = fetchedDeliveries;
        });
      }
    } catch (e) {
      print("Error fetching delivery requests: $e");
    }
  }

  // --- Function to handle accepting a request ---
  void _acceptRequest(String type, Map<String, dynamic> request) async {
    final rider = FirebaseAuth.instance.currentUser;
    if (rider == null) return;

    final String requestId = request['id'];
    final String collection =
        type == 'passenger' ? 'ride_requests' : 'delivery_requests';

    try {
      // 1. Fetch the original request data
      final requestDoc =
          await FirebaseFirestore.instance
              .collection(collection)
              .doc(requestId)
              .get();
      if (!requestDoc.exists) return;

      final requestData = requestDoc.data()!;

      // 2. Add riderId to the request
      final updatedData = {
        ...requestData,
        'riderId': rider.uid,
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      };

      // 3. Store in 'accepted_requests' collection
      await FirebaseFirestore.instance
          .collection('accepted_requests')
          .doc(requestId)
          .set(updatedData);

      // 4. Delete from original collection
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(requestId)
          .delete();

      // 5. Refresh UI
      if (mounted) {
        setState(() {
          _isShowingConfirmationScreen = false;
          if (type == 'passenger') {
            passengerRequests.removeWhere((r) => r['id'] == requestId);
          } else {
            deliveryRequests.removeWhere((r) => r['id'] == requestId);
          }
          _selectedRequestData = null;
          _selectedRequestType = null;
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Request accepted successfully!')));
    } catch (e) {
      print('[ERROR] Accepting request: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to accept request: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Main Scaffold and Top Bar  ---
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

            // --- Main content area ---
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
                      // --- TabBar ---
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
                      // --- TabBarView ---
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // --- Home Tab Content ---
                            _buildHomeTabContent(),
                            // --- Other Tabs ---
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

  // --- Build content for the Home tab ---
  Widget _buildHomeTabContent() {
    // If _isShowingConfirmationScreen is true, build the confirmation view
    if (_isShowingConfirmationScreen &&
        _selectedRequestData != null &&
        _selectedRequestType != null) {
      return _buildConfirmationScreen(); // Call the new function
    }

    // --- Otherwise, build the original Home tab content ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ride/Delivery toggle buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (selectedTab != 'Ride') {
                    setState(() => selectedTab = 'Ride');
                  }
                },
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
                onPressed: () {
                  if (selectedTab != 'Delivery') {
                    setState(() => selectedTab = 'Delivery');
                  }
                },
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

        Expanded(
          child:
              selectedTab == 'Ride'
                  ? _buildPassengerList()
                  : _buildDeliveryList(),
        ),
      ],
    );
  }

  // --- Confirmation Screen Widget ---
  Widget _buildConfirmationScreen() {
    final request = _selectedRequestData!;
    final type = _selectedRequestType!;

    // Determine details based on type
    String name = request['name'] ?? 'Unknown';
    String profilePicUrl = request['profileUrl'] ?? '';
    Color avatarColor =
        request['avatarColor'] ?? Colors.grey; // Use stored color or default

    String initials =
        name.isNotEmpty
            ? name
                .split(' ')
                .where((part) => part.isNotEmpty)
                .map((part) => part[0])
                .take(2)
                .join()
                .toUpperCase()
            : '?';

    String detailsTitle =
        type == 'passenger'
            ? 'Accept Passenger Request '
            : 'Accept Delivery Request ';

    String detailLine1 = '';
    String detailLine2 = '';
    IconData icon1 = Icons.route;
    IconData icon2 = Icons.pin_drop_outlined;

    if (type == 'passenger') {
      detailLine1 = "From: ${request['pickup'] ?? 'Unknown'}";
      detailLine2 = "To: ${request['destination'] ?? 'Unknown'}";
      icon1 = Icons.location_on_outlined;
      icon2 = Icons.flag_outlined;
    } else if (type == 'delivery') {
      detailLine1 = "Item: ${request['orders'] ?? 'Unknown'}";
      detailLine2 = "Deliver To: ${request['destination'] ?? 'Unknown'}";
      icon1 = Icons.inventory_2_outlined;
      icon2 = Icons.location_on_outlined;
    }

    return Column(
      children: [
        // --- Back button and Title Row ---
        Row(
          children: [
            IconButton(
              onPressed: () {
                // Go back to the list view
                setState(() {
                  _isShowingConfirmationScreen = false;
                  _selectedRequestData = null;
                  _selectedRequestType = null;
                });
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0x1A00843D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF00843D),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // --- Title Text ---
            Expanded(
              child: Text(
                detailsTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // --- Request Details Section ---
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---  Label ---
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      "Requester:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  // --- Requester Info Card ---
                  Card(
                    color: Colors.grey[100],
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: avatarColor,
                            backgroundImage:
                                profilePicUrl.isNotEmpty
                                    ? NetworkImage(profilePicUrl)
                                    : null,
                            child:
                                profilePicUrl.isEmpty
                                    ? Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ---  Label ---
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      "Details:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),

                  // --- Specific Request Details ---
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon1, color: Colors.grey[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            detailLine1,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon2, color: Colors.grey[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            detailLine2,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Add more details as needed
                  // Pickup time
                  if (request['pickupTime'] != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 20,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pickup Time: ${request['pickupTime']}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Payment method
                  if (request['paymentMethod'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.payment,
                          size: 20,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Payment: ${request['paymentMethod']}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // OSM Map Preview
                  if (request['pickupPin'] != null &&
                      request['destinationPin'] != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Route Preview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 200,
                        child: OsmMap(
                          // 🧭 You’ll need to modify OsmMap to support static pin rendering
                          initialPickupPin: LatLng(
                            request['pickupPin']['lat'],
                            request['pickupPin']['lng'],
                          ),
                          initialDestinationPin: LatLng(
                            request['destinationPin']['lat'],
                            request['destinationPin']['lng'],
                          ),
                          isReadOnly:
                              true, // Optional: disable tap-to-move if needed
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // --- Confirmation Buttons ---
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isShowingConfirmationScreen = false;
                      _selectedRequestData = null;
                      _selectedRequestType = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Decline",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    _acceptRequest(type, request);
                  },
                  child: const Text(
                    "Accept",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Passenger List Builder  ---
  Widget _buildPassengerList() {
    if (passengerRequests.isEmpty) {
      return const Center(child: Text('No passenger requests available'));
    }
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

  // --- Delivery List Builder ---
  Widget _buildDeliveryList() {
    if (deliveryRequests.isEmpty) {
      return const Center(child: Text('No delivery requests available'));
    }
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

  // --- Request Card Widget ---
  Widget _buildRequestCard({
    required String type,
    required Map<String, dynamic> request,
  }) {
    final String name =
        request['name'] ?? 'Unknown'; // Handle potential null name
    final Color avatarColor = request['avatarColor'] ?? Colors.grey;
    final String profilePicUrl = request['profileUrl'] ?? '';

    String initials =
        name.isNotEmpty
            ? name
                .split(' ')
                .where((part) => part.isNotEmpty)
                .map((part) => part[0])
                .take(2)
                .join()
                .toUpperCase()
            : '?';

    String titleText = name;
    String subtitleText = '';

    if (type == 'passenger') {
      final String pickup = request['pickup'] ?? 'Unknown';
      final String destination = request['destination'] ?? 'Unknown';
      subtitleText = '$pickup → $destination';
    } else if (type == 'delivery') {
      final String pickup = request['pickup'] ?? 'Unknown';
      final String destination = request['destination'] ?? 'Unknown';
      subtitleText = 'Delivery from $pickup to $destination';
    }

    return InkWell(
      // --- UPDATED onTap: Show Confirmation Screen ---
      onTap: () {
        setState(() {
          _selectedRequestData = request;
          _selectedRequestType = type;
          _isShowingConfirmationScreen =
              true; // Set flag to show the confirmation screen
        });
      },
      // --- End UPDATED onTap ---
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
                backgroundImage:
                    profilePicUrl.isNotEmpty
                        ? NetworkImage(profilePicUrl)
                        : null,
                child:
                    profilePicUrl.isEmpty
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subtitleText,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14.0),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
