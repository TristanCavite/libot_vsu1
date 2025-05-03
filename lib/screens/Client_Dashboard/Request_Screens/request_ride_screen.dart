import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // date formatting
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:libot_vsu1/utils/fare_calculator.dart';
import 'package:libot_vsu1/widgets/osm_map.dart'; // 🧭 Step 3B: import OSM map widget
import 'package:latlong2/latlong.dart'; // 🆕 For LatLng
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Optional: attach riderId or clientId
import 'package:libot_vsu1/screens/Client_Dashboard/Request_Screens/pending_screen.dart'; // ✅ Import pending screen
import 'package:libot_vsu1/screens/Client_Dashboard/client_dashboard_screen.dart';


class RequestRideScreen extends StatefulWidget {
  final String destination;
  final List<Map<String, dynamic>> placesList;
  const RequestRideScreen({
    super.key,
    required this.destination,
    required this.placesList,
  });

  @override
  State<RequestRideScreen> createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen> {
  // Controllers for text fields
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _pickupLocationController =
      TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  String _selectedPaymentMethod = 'Cash'; // ✅ Default payment

  // Selected pickup option
  String _selectedPickupOption = 'Now';
  String fare = '0'; // fare price variable

  // 🆕 Holds map pin coordinates from OsmMap
  LatLng? _pinLocation; // 🧭 NEW: to store final pickup coordinates

  @override
  void initState() {
    super.initState();
    _destinationController.text = widget.destination;
    if (_selectedPickupOption == 'Now') _setCurrentDateTime();
  }

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // Method to set current date and time
  void _setCurrentDateTime() {
    final now = DateTime.now();
    _dateController.text = DateFormat('MMM d, yyyy').format(now);
    _timeController.text = DateFormat('h:mm a').format(now);
  }

  // Method to clear date and time fields
  void _clearDateTime() {
    _dateController.clear();
    _timeController.clear();
  }

  // Show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00843D)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('MMM d, yyyy').format(picked);
      });
    }
  }

  // Show time picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF00843D)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      setState(() {
        _timeController.text = DateFormat('h:mm a').format(selectedDateTime);
      });
    }
  }

  void _updateFare() {
    final pickup = _pickupLocationController.text.trim();
    final destination = _destinationController.text.trim();
    final pickupCampusCategory = _findCampusCategory(pickup);
    final destinationCampusCategory = _findCampusCategory(destination);

    final calculatedFare = calculateFare(
      pickup,
      destination,
      pickupCampusCategory,
      destinationCampusCategory,
    );
    setState(() {
      fare = calculatedFare;
    });
  }

  String? _findCampusCategory(String placeName) {
    final match = widget.placesList.firstWhere(
      (place) =>
          (place['name'] as String).toLowerCase() == placeName.toLowerCase(),
      orElse: () => {},
    );
    if (match.isEmpty) return null;
    return match['campusCategory'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 Pickup location field
            TypeAheadField<String>(
              controller: _pickupLocationController,
              builder:
                  (context, controller, focusNode) => TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.circle_rounded,
                        color: Color(0xFF00843D),
                        size: 15,
                      ),
                      hintText: 'Pickup Location',
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
              suggestionsCallback: (pattern) {
                return widget.placesList
                    .where(
                      (place) => (place['name'] as String)
                          .toLowerCase()
                          .contains(pattern.toLowerCase()),
                    )
                    .map((place) => place['name'] as String)
                    .toList(); // 🛠️ Return List<String> for suggestions
              },
              itemBuilder:
                  (context, suggestion) => ListTile(title: Text(suggestion)),
              onSelected: (suggestion) {
                _pickupLocationController.text = suggestion;
                _updateFare(); // 🛠️ Update fare when pickup is selected
              },
            ),
            const SizedBox(height: 12),

            // 🔥 Destination field
            TypeAheadField<String>(
              controller: _destinationController,
              builder:
                  (context, controller, focusNode) => TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.circle_rounded,
                        color: Color(0xFF424242),
                        size: 15,
                      ),
                      hintText: 'Destination',
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
              suggestionsCallback: (pattern) {
                return widget.placesList
                    .where(
                      (place) => (place['name'] as String)
                          .toLowerCase()
                          .contains(pattern.toLowerCase()),
                    )
                    .map((place) => place['name'] as String)
                    .toList();
              },
              itemBuilder:
                  (context, suggestion) => ListTile(title: Text(suggestion)),
              onSelected: (suggestion) {
                _destinationController.text = suggestion;
                _updateFare();
              },
            ),
            const SizedBox(height: 12),

            // Need logic para automatic na ma fill and exact fee
            // 🔥 Fare display field
            TextField(
              enabled: false,
              controller: TextEditingController(text: 'Fare: ₱$fare'),
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.attach_money_outlined,
                  color: Colors.black,
                ),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            // Insert mapa ari
            const SizedBox(height: 12),

            // 🌍 Replaced static image with OSMMap widget
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: OsmMap(
                  onLocationChanged: (LatLng location) {
                    setState(() {
                      _pinLocation = location; // ✅ Store pin location from map
                    });
                  },
                ), // 🧭 Step 3B: inserted map here
              ),
            ),

            // 🕒 Pickup Time
            const SizedBox(height: 16),
            const Text(
              'Pickup Time',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPickupOption = 'Now';
                        _setCurrentDateTime(); // ⏱️ Sets the current time automatically
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color:
                            _selectedPickupOption == 'Now'
                                ? const Color(0xFF00843D)
                                : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Now',
                        style: TextStyle(
                          color:
                              _selectedPickupOption == 'Now'
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedPickupOption == 'Schedule'
                              ? const Color(0xFF00843D)
                              : const Color(0xFFF5F5F5),
                      foregroundColor:
                          _selectedPickupOption == 'Schedule'
                              ? Colors.white
                              : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedPickupOption = 'Schedule';
                        _clearDateTime(); // 🧹 Clears default time when scheduling
                      });
                    },
                    child: const Text('Schedule'),
                  ),
                ),
              ],
            ),

            // ✅ Conditionally show Date & Time fields only if “Schedule” is selected
            if (_selectedPickupOption == 'Schedule') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'Date',
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _timeController,
                readOnly: true,
                onTap: () => _selectTime(context),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.access_time),
                  hintText: 'Time',
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            //Payment method
            const SizedBox(height: 16),
            const Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.account_balance_wallet_outlined),
                ),
                value: _selectedPaymentMethod,
                items:
                    ['Cash', 'GCash', 'Credit Card']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(
                      () => _selectedPaymentMethod = value,
                    ); // ✅ Update on change
                  }
                },
              ),
            ),

            // Bottom button
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00843D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User not logged in')),
    );
    return;
  }

  final requestData = {
    'clientId': user.uid,
    'pickupLocation': _pickupLocationController.text,
    'destination': _destinationController.text,
    'pickupTime': _selectedPickupOption == 'Now'
        ? 'Now'
        : '${_dateController.text}, ${_timeController.text}',
    'pin': {
      'lat': _pinLocation?.latitude,
      'lng': _pinLocation?.longitude,
    },
    'paymentMethod': _selectedPaymentMethod,
    'status': 'pending',
    'timestamp': FieldValue.serverTimestamp(),
  };

  try {
    final docRef = await FirebaseFirestore.instance
        .collection('ride_requests')
        .add(requestData);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'pendingRequestId': docRef.id});

    if (!mounted) return;

    // ✅ Don't pop, just inject directly
    final dashboardState = context.findAncestorStateOfType<ClientDashboardScreenState>();
    if (dashboardState != null) {
      dashboardState.setState(() {
        dashboardState.currentContent = PendingScreen(requestId: docRef.id);
        dashboardState.requestType = 'Pending';
        dashboardState.showRequestScreen = true;
      });
    }
  } catch (e) {
    print('[ERROR] $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send request: $e')),
    );
  }
},


                child: const Text(
                  'Confirm Ride Request',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
