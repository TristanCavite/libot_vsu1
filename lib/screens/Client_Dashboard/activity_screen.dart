import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libot_vsu1/screens/Client_Dashboard/Request_Screens/pending_screen.dart';
import 'package:libot_vsu1/screens/Client_Dashboard/client_dashboard_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // --- Data Management ---
  List<Map<String, dynamic>> _activeRequests = [];
  List<Map<String, dynamic>> _completedRequests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final active = <Map<String, dynamic>>[];
    final completed = <Map<String, dynamic>>[];

    // 🔹 Ride Requests
    final rideSnap =
        await firestore
            .collection('ride_requests')
            .where('clientId', isEqualTo: user.uid)
            .get();

    for (final doc in rideSnap.docs) {
      final data = doc.data();
      final mapped = {
        ...data,
        'id': doc.id,
        'requestType': 'Passenger',
        'estimatedFare': data['fare'] ?? 0,
      };
      if ((data['status'] as String?)?.toLowerCase() == 'completed') {
        completed.add(mapped);
      } else {
        active.add(mapped);
      }
    }

    // 🔹 Delivery Requests
    final deliverySnap =
        await firestore
            .collection('delivery_requests')
            .where('clientId', isEqualTo: user.uid)
            .get();

    for (final doc in deliverySnap.docs) {
      final data = doc.data();
      final mapped = {
        ...data,
        'id': doc.id,
        'requestType': 'Delivery',
        'estimatedFare': double.tryParse(data['deliveryFee'].toString()) ?? 0,
      };
      if ((data['status'] as String?)?.toLowerCase() == 'completed') {
        completed.add(mapped);
      } else {
        active.add(mapped);
      }
    }

    // 🔹 Accepted Requests
    final acceptedSnap =
        await firestore
            .collection('accepted_requests')
            .where('clientId', isEqualTo: user.uid)
            .get();

    for (final doc in acceptedSnap.docs) {
      final data = doc.data();
      final riderId = data['riderId'];
      String? riderName;
      String? riderAvatar;

      if (riderId != null) {
        final riderDoc = await firestore.collection('users').doc(riderId).get();
        riderName = riderDoc.data()?['fullName'];
        riderAvatar = riderDoc.data()?['profileUrl'];
      }

      final mapped = {
        ...data,
        'id': doc.id,
        'requestType': data['requestType'] == 'Ride' ? 'Passenger' : 'Delivery',
        'estimatedFare': data['fare'] ?? 0,
        'riderName': riderName ?? 'Rider Unavailable',
        'riderAvatar': riderAvatar ?? '',
        'completionTimestamp':
            (data['completedAt'] is Timestamp)
                ? (data['completedAt'] as Timestamp).toDate()
                : null,
      };

      if ((data['status'] as String?)?.toLowerCase() == 'completed') {
        completed.add(mapped);
      } else {
        active.add(mapped);
      }
    }

    if (mounted) {
      setState(() {
        _activeRequests = active;
        _completedRequests = completed;
      });
    }
  }

  // --- UI Helper Methods for Modals ---
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
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  // Modal bottom sheet with details for a completed request.
  void _showCompletedRequestDetails(Map<String, dynamic> request) {
    String formattedCompletionTime = "N/A";
    if (request['completionTimestamp'] != null &&
        request['completionTimestamp'] is DateTime) {
      formattedCompletionTime = DateFormat(
        'MMM dd, yyyy - hh:mm a',
      ).format(request['completionTimestamp']);
    }

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
                    'Completed Request Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Client's Request Details Section
                  const Text(
                    'Your Request',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const Divider(height: 10, thickness: 0.5),
                  _buildDetailRow(
                    iconData:
                        request['requestType'] == 'Delivery'
                            ? Icons.delivery_dining_outlined
                            : Icons.directions_car_outlined,
                    label: 'Request Type',
                    value: request['requestType'],
                  ),
                  if (request['requestType'] == 'Delivery' &&
                      request['item'] != null)
                    _buildDetailRow(
                      iconData: Icons.inventory_2_outlined,
                      label: 'Item',
                      value: request['item'],
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
                            ? 'Delivered To'
                            : 'Destination',
                    value: request['destination'],
                  ),
                  _buildDetailRow(
                    iconData: Icons.payment_outlined,
                    label: 'Paid via',
                    value: request['paymentMethod'] ?? 'N/A',
                  ),
                  _buildDetailRow(
                    iconData: Icons.monetization_on_outlined,
                    label: 'Final Fare',
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
                  const SizedBox(height: 20),

                  // Rider Details Section
                  const Text(
                    'Rider Information',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const Divider(height: 10, thickness: 0.5),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(
                        request['riderAvatar'] ??
                            'assets/images/default_profile.png',
                      ),
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      onBackgroundImageError: (exception, stackTrace) {},
                      child:
                          (request['riderAvatar'] == null ||
                                  request['riderAvatar'].isEmpty)
                              ? const Icon(
                                Icons.person_outline,
                                color: Colors.grey,
                                size: 24,
                              )
                              : null,
                    ),
                    title: Text(
                      request['riderName'] ?? 'Rider Unavailable',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _buildDetailRow(
                    iconData: Icons.calendar_today_outlined,
                    label: 'Completed On',
                    value: formattedCompletionTime,
                  ),
                  const SizedBox(height: 24),

                  // Action Button (Leave Review - Placeholder for now (could be changed to a different action))
                  ElevatedButton.icon(
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Leave a Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // Leave a review logic (not implemented)
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Leave a review (not implemented).'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('My Active Requests'),
            const SizedBox(height: 10),
            _activeRequests.isEmpty
                ? _buildEmptyState('You have no active requests.')
                : Column(
                  children:
                      _activeRequests
                          .map(
                            (request) => GestureDetector(
                              onTap: () {
                                final dashboardState =
                                    context
                                        .findAncestorStateOfType<
                                          ClientDashboardScreenState
                                        >();

                                if (dashboardState != null) {
                                  dashboardState.setState(() {
                                    dashboardState.currentContent =
                                        PendingScreen(requestId: request['id']);
                                    dashboardState.requestType =
                                        'Pending'; // title on top
                                    dashboardState.showRequestScreen = true;
                                  });
                                } else {
                                  // fallback just in case
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => PendingScreen(
                                            requestId: request['id'],
                                          ),
                                    ),
                                  );
                                }
                              },

                              child: _buildRequestTile(request, isActive: true),
                            ),
                          )
                          .toList(),
                ),
            const SizedBox(height: 24),
            _buildSectionHeader('Completed Requests'),
            const SizedBox(height: 10),
            _completedRequests.isEmpty
                ? _buildEmptyState('You have no completed requests yet.')
                : Column(
                  children:
                      _completedRequests
                          .map(
                            (request) => GestureDetector(
                              onTap:
                                  () => _showCompletedRequestDetails(request),
                              child: _buildRequestTile(
                                request,
                                isActive: false,
                              ),
                            ),
                          )
                          .toList(),
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
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold, // Bolder
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(
    Map<String, dynamic> request, {
    required bool isActive,
  }) {
    String subtitleText;
    IconData leadingIconData;

    if (request['requestType'] == 'Passenger') {
      subtitleText =
          '${request['pickupLocation']} to ${request['destination']}';
      leadingIconData = Icons.directions_car_filled_outlined;
    } else if (request['requestType'] == 'Delivery') {
      subtitleText =
          'Item: ${request['item'] ?? 'Package'} - ${request['pickupLocation']} to ${request['destination']}';
      leadingIconData = Icons.delivery_dining_outlined;
    } else {
      subtitleText =
          '${request['pickupLocation']} to ${request['destination']}';
      leadingIconData = Icons.help_outline;
    }

    String requestStatus = request['status'] ?? 'Unknown';

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor:
              isActive ? Colors.blue.shade100 : Colors.green.shade100,
          foregroundColor:
              isActive ? Colors.blue.shade700 : Colors.green.shade700,
          radius: 24,
          child: Icon(leadingIconData, size: 24),
        ),
        title: Text(
          request['requestType'] == 'Passenger'
              ? 'Passenger Ride'
              : 'Delivery Service',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitleText,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (isActive)
              Text(
                'Status: $requestStatus',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:
                      requestStatus.toLowerCase() == 'accepted'
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                ),
              )
            else
              Text(
                'Completed: ${DateFormat('MMM dd, hh:mm a').format(request['completionTimestamp'] ?? DateTime.now())}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Php ${request[isActive ? 'estimatedFare' : 'fare']?.toStringAsFixed(0) ?? 'N/A'}',
              style: TextStyle(
                color: Colors.blueGrey.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (isActive)
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
