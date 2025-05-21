import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:libot_vsu1/widgets/osm_map.dart'; // ✅ Add this import
import 'package:latlong2/latlong.dart'; // ✅ Required for LatLng

class RiderActivityScreen extends StatefulWidget {
  const RiderActivityScreen({super.key});

  @override
  State<RiderActivityScreen> createState() => _RiderActivityScreenState();
}

class _RiderActivityScreenState extends State<RiderActivityScreen> {
  // --- Data Management ---
  List<Map<String, dynamic>> _acceptedRequests = [];
  List<Map<String, dynamic>> _completedRequests = [];

  @override
  void initState() {
    super.initState();
     _cleanupOldCompletedRequests();
    _loadRequests();
  }

  void _loadRequests() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  print("👤 Loading requests for: ${user.uid}");

  final acceptedSnap = await FirebaseFirestore.instance
      .collection('accepted_requests')
      .where('riderId', isEqualTo: user.uid)
      .get();

  final accepted = <Map<String, dynamic>>[];
  final completed = <Map<String, dynamic>>[];

  for (final doc in acceptedSnap.docs) {
    final data = doc.data();
    final clientId = data['clientId'];
    if (clientId == null) continue;

    final clientDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(clientId)
        .get();

    final enriched = {
      ...data,
      'id': doc.id,
      'name': clientDoc.data()?['fullName'] ?? 'Unknown',
      'avatar': clientDoc.data()?['profileUrl'] ?? '',
    };

    if ((data['status'] as String?)?.toLowerCase() == 'completed') {
      completed.add(enriched);
    } else {
      accepted.add(enriched);
    }
  }

  if (mounted) {
    setState(() {
      _acceptedRequests = accepted;
      _completedRequests = completed;
    });
  }
}


 void _cleanupOldCompletedRequests() async {
  final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));

  final snapshot = await FirebaseFirestore.instance
      .collection('accepted_requests')
      .where('status', isEqualTo: 'Completed')
      .where('completedAt', isLessThan: Timestamp.fromDate(twoDaysAgo))
      .get();

  for (final doc in snapshot.docs) {
    await doc.reference.delete();
    debugPrint('🧹 Deleted expired completed request: ${doc.id}');
  }
}



  // --- UI Helper Methods for Modals ---

  // Helper to build a row with an icon, label, and value for modal details.
  Widget _buildDetailRow({
    required IconData iconData,
    required String label,
    required String value,
    Color? valueColor,
    FontWeight valueFontWeight = FontWeight.normal,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: Colors.blueGrey.shade600, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: valueColor ?? Colors.black54,
                fontWeight: valueFontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Shows a modal bottom sheet with details for an accepted request.
  void _showRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Wrap(
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Route Preview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // OSM Map Preview using pickupPin and destinationPin
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
                          initialPickupPin: LatLng(
                            request['pickupPin']['lat'] ?? 0.0,
                            request['pickupPin']['lng'] ?? 0.0,
                          ),
                          initialDestinationPin: LatLng(
                            request['destinationPin']['lat'] ?? 0.0,
                            request['destinationPin']['lng'] ?? 0.0,
                          ),
                          isReadOnly: true,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Route Preview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No Map Data',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  const Text(
                    'Request Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ✅ Added null safety fallback to avoid crash on modal detail rows
                  _buildDetailRow(
                    iconData:
                        request['requestType'] == 'Delivery'
                            ? Icons.delivery_dining_outlined
                            : Icons.directions_car_outlined,
                    label: 'Request Type',
                    value: request['requestType'] ?? 'Unknown', // ✅ check
                  ),

                  if (request['requestType'] == 'Delivery' &&
                      request['orders'] != null)
                    _buildDetailRow(
                      iconData: Icons.inventory_2_outlined,
                      label: 'Order Details',
                      value:
                          request['orders'] ??
                          'Not provided', // ✅ updated field
                    ),

                  _buildDetailRow(
                    iconData: Icons.my_location_outlined,
                    label: 'Pickup',
                    value: request['pickupLocation'] ?? 'Unknown', // ✅ check
                  ),

                  _buildDetailRow(
                    iconData: Icons.flag_outlined,
                    label:
                        request['requestType'] == 'Delivery'
                            ? 'Deliver To'
                            : 'Destination',
                    value: request['destination'] ?? 'Unknown', // ✅ check
                  ),

                  _buildDetailRow(
                    iconData: Icons.access_time_outlined,
                    label: 'Time',
                    value: request['pickupTime'] ?? 'Unspecified', // ✅ check
                  ),

                  _buildDetailRow(
                    iconData: Icons.payment_outlined,
                    label: 'Payment',
                    value: request['paymentMethod'] ?? 'Unknown', // ✅ check
                  ),

                  _buildDetailRow(
                    iconData: Icons.monetization_on_outlined,
                    label: 'Fare',
                    value:
                        request['fare'] != null
                            ? 'Php ${(request['fare'] as num).toStringAsFixed(2)}'
                            : 'Php N/A', // ✅ check
                  ),

                  const SizedBox(height: 24),

                  // --- CHAT NOW BUTTON ---
                  ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      _chat(); // Chat functionality
                    },
                  ),

                  // --- END OF CHAT NOW BUTTON ---
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      _completeRequest(request);
                    },
                    child: const Text(
                      'Complete Request',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompletedRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Wrap(
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Route Preview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Map Placeholder',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Request Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow(
                    iconData:
                        request['requestType'] == 'Delivery'
                            ? Icons.delivery_dining_outlined
                            : Icons.directions_car_outlined,
                    label: 'Request Type',
                    value: request['requestType'],
                  ),

                  if (request['requestType'] == 'Delivery' &&
                      request['orders'] != null)
                    _buildDetailRow(
                      iconData: Icons.inventory_2_outlined,
                      label: 'Order Details',
                      value:
                          request['orders'] ??
                          'Not provided', // ✅ updated field
                    ),

                  _buildDetailRow(
                    iconData: Icons.my_location_outlined,
                    label: 'Pickup',
                    value: request['pickupLocation'],
                  ),

                  _buildDetailRow(
                    iconData: Icons.flag_outlined,
                    label:
                        request['requestType'] == 'Delivery'
                            ? 'Deliver To'
                            : 'Destination',
                    value: request['destination'],
                  ),

                  _buildDetailRow(
                    iconData: Icons.access_time_outlined,
                    label: 'Time',
                    value: request['pickupTime'],
                  ),

                  _buildDetailRow(
                    iconData: Icons.payment_outlined,
                    label: 'Payment',
                    value: request['paymentMethod'],
                  ),

                  _buildDetailRow(
                    iconData: Icons.monetization_on_outlined,
                    label: 'Fare',
                    value:
                        'Php ${request['fare']?.toStringAsFixed(2) ?? 'N/A'}',
                  ),

                  _buildDetailRow(
                    iconData: Icons.check_circle_outline,
                    label: 'Status',
                    value: request['status'],
                    valueColor: Colors.green.shade700,
                    valueFontWeight: FontWeight.bold,
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      _deleteCompletedRequest(request);
                    },
                    child: const Text(
                      'Delete Request',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

// --- Action Methods ---
Future<void> _completeRequest(Map<String, dynamic> request) async {
  try {
    final id = request['id'];

    // ✅ Update the request in Firestore to mark as completed
    await FirebaseFirestore.instance
        .collection('accepted_requests')
        .doc(id)
        .update({
          'status': 'Completed',
          'completedAt': FieldValue.serverTimestamp(),
        });

    // ✅ Update local UI: move from accepted to completed
    if (mounted) {
      setState(() {
        _acceptedRequests.removeWhere((r) => r['id'] == id);
        request['status'] = 'Completed';
        request['completedAt'] = DateTime.now(); // local fallback
        _completedRequests.add(request);
      });
    }

    Navigator.pop(context);
  } catch (e) {
    debugPrint('❌ Failed to mark request as completed: $e');
  }
}

  void _deleteCompletedRequest(Map<String, dynamic> request) {
    setState(() {
      _completedRequests.removeWhere((r) => r['id'] == request['id']);
    });
    Navigator.pop(context);
  }

  void _chat() {
    // Placeholder for chat functionality
    // Edit this method to implement the chat feature.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat feature is not implemented yet.')),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Accepted Requests'),
            const SizedBox(height: 10),
            _acceptedRequests.isEmpty
                ? _buildEmptyState('No accepted requests yet.')
                : SizedBox(
                  height: 260,
                  child: ListView.builder(
                    itemCount: _acceptedRequests.length,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    itemBuilder: (context, index) {
                      final request = _acceptedRequests[index];
                      return GestureDetector(
                        onTap: () => _showRequestDetails(request),
                        child: _buildRequestTile(request),
                      );
                    },
                  ),
                ),
            const SizedBox(height: 20),
            _buildSectionHeader('Completed Requests'),
            const SizedBox(height: 10),
            _completedRequests.isEmpty
                ? _buildEmptyState('No completed requests yet.')
                : SizedBox(
                  height: 260,
                  child: ListView.builder(
                    itemCount: _completedRequests.length,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    itemBuilder: (context, index) {
                      final request = _completedRequests[index];
                      return GestureDetector(
                        onTap: () => _showCompletedRequestDetails(request),
                        child: _buildRequestTile(request),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // --- UI Building Helper Widgets ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Column(
        // Added an icon for empty state
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list_alt_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(Map<String, dynamic> request) {
    String subtitleText;
    if (request['requestType'] == 'Passenger') {
      subtitleText =
          '${request['pickupLocation']} to ${request['destination']}';
    } else if (request['requestType'] == 'Delivery') {
      subtitleText =
          '${request['item'] ?? 'Item'} - ${request['pickupLocation']} to ${request['destination']}';
    } else {
      subtitleText =
          '${request['pickupLocation']} to ${request['destination']}';
    }

    final String avatarUrl = request['avatar'] ?? '';

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200,
          backgroundImage:
              (avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
          child:
              avatarUrl.isEmpty
                  ? const Icon(Icons.person_outline, color: Colors.grey)
                  : null,
        ),
        title: Text(
          request['name'] ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            subtitleText,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Php ${request['fare']?.toStringAsFixed(0) ?? 'N/A'}',
              style: TextStyle(
                color: Colors.blueGrey.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
