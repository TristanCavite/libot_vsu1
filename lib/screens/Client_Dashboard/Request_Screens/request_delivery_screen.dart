import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libot_vsu1/utils/fare_calculator.dart';
import 'package:libot_vsu1/widgets/osm_map.dart'; // 🗺️ OSM map widget
import 'package:latlong2/latlong.dart'; // 🧭 For LatLng
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libot_vsu1/screens/Client_Dashboard/client_dashboard_screen.dart';
import 'package:libot_vsu1/screens/Client_Dashboard/Request_Screens/pending_screen.dart'; // ✅ Import pending screen

class RequestDeliveryScreen extends StatefulWidget {
  const RequestDeliveryScreen({super.key});

  @override
  State<RequestDeliveryScreen> createState() => _RequestDeliveryScreenState();
}

class _RequestDeliveryScreenState extends State<RequestDeliveryScreen> {
  // Controllers for text fields
  final TextEditingController _ordersController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  List<Map<String, dynamic>> _cachedPlacesList = [];
  LatLng? _pickupPin;
  LatLng? _destinationPin;

  bool _placesLoaded = false;
  String deliveryFee = '0';

  // Selected pickup option
  String _selectedPickupOption = 'Now';

  @override
  void initState() {
    super.initState();
    // Set current date and time
    if (_selectedPickupOption == 'Now') {
      _setCurrentDateTime();
    }

    _loadPlacesOnce();
  }

  @override
  void dispose() {
    _ordersController.dispose();
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

  // 🔍 Filter cached places based on input pattern
  Future<List<String>> _fetchPlaceSuggestions(String pattern) async {
    final lowerPattern = pattern.toLowerCase();
    return _cachedPlacesList
        .map((place) => place['name'] as String)
        .where((name) => name.toLowerCase().contains(lowerPattern))
        .toList();
  }

  // ✅ Load places from Firebase only once
  Future<void> _loadPlacesOnce() async {
    if (_placesLoaded) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('places').get();

    setState(() {
      _cachedPlacesList =
          snapshot.docs
              .map(
                (doc) => {
                  'name': doc['name'],
                  'campusCategory': doc['campusCategory'],
                },
              )
              .toList();
      _placesLoaded = true;
    });
  }

  void _updateDeliveryFee() {
    final pickup = _pickupController.text.trim();
    final destination = _destinationController.text.trim();
    final pickupCampusCategory = _findCampusCategory(pickup);
    final destinationCampusCategory = _findCampusCategory(destination);

    final calculated = calculateFare(
      pickup,
      destination,
      pickupCampusCategory,
      destinationCampusCategory,
    );
    setState(() {
      deliveryFee = calculated;
    });
  }

  String? _findCampusCategory(String placeName) {
    final match = _cachedPlacesList.firstWhere(
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
            TextField(
              controller: _ordersController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter your orders here...',
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Pickup using new TypeAheadField builder API
            TypeAheadField<String>(
              controller: _pickupController,
              builder:
                  (context, controller, focusNode) => TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF424242),
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
              suggestionsCallback: _fetchPlaceSuggestions,
              itemBuilder:
                  (context, suggestion) => ListTile(title: Text(suggestion)),
              onSelected: (suggestion) {
                _pickupController.text = suggestion;
                _updateDeliveryFee(); // 💸 Update fee on selection
              },
            ),

            const SizedBox(height: 12),

            // ✅ Destination using new TypeAheadField builder API
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
              suggestionsCallback: _fetchPlaceSuggestions,
              itemBuilder:
                  (context, suggestion) => ListTile(title: Text(suggestion)),
              onSelected: (suggestion) {
                _destinationController.text = suggestion;
                _updateDeliveryFee(); // 💸 Update fee on selection
              },
            ),

            const SizedBox(height: 12),

            TextField(
              enabled: false,
              controller: TextEditingController(
                text: 'Delivery fee: ₱$deliveryFee',
              ),
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
            // 🌍 Map with pin selection (replacing static image)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: OsmMap(
                  onPickupChanged: (LatLng pickupLocation) {
                    setState(() {
                      _pickupPin = pickupLocation;
                    });
                  },
                  onDestinationChanged: (LatLng destinationLocation) {
                    setState(() {
                      _destinationPin = destinationLocation;
                    });
                  },
                ),
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
                value: 'Cash',
                items:
                    ['Cash', 'GCash', 'Credit Card']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (value) {},
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

                  // ✅ VALIDATION CHECK (Added here)
                  if (_ordersController.text.trim().isEmpty ||
                      _pickupController.text.trim().isEmpty ||
                      _destinationController.text.trim().isEmpty ||
                      _pickupPin == null ||
                      _destinationPin == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please complete all fields: orders, locations, and map pins.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final requestData = {
                    'clientId': user.uid,
                    'orders': _ordersController.text.trim(),
                    'pickupLocation': _pickupController.text,
                    'destination': _destinationController.text,
                    'deliveryFee': deliveryFee,
                    'pickupTime':
                        _selectedPickupOption == 'Now'
                            ? DateFormat(
                              'MMM dd, yyyy, hh:mm a',
                            ).format(DateTime.now())
                            : '${_dateController.text}, ${_timeController.text}',
                    'pickupPin': {
                      'lat': _pickupPin?.latitude,
                      'lng': _pickupPin?.longitude,
                    },
                    'destinationPin': {
                      'lat': _destinationPin?.latitude,
                      'lng': _destinationPin?.longitude,
                    },
                    'paymentMethod': 'Cash',
                    'status': 'pending',
                    'timestamp': FieldValue.serverTimestamp(),
                  };

                  try {
                    final docRef = await FirebaseFirestore.instance
                        .collection('delivery_requests')
                        .add(requestData);
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'pendingRequestId': docRef.id});

                    if (!mounted) return;

                    final dashboardState =
                        context
                            .findAncestorStateOfType<
                              ClientDashboardScreenState
                            >();
                    if (dashboardState != null) {
                      dashboardState.setState(() {
                        dashboardState.currentContent = PendingScreen(
                          requestId: docRef.id,
                        );
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
                  'Confirm Delivery Request',
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
