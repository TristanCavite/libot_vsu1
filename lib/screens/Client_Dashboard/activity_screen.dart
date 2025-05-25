import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libot_vsu1/widgets/osm_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:libot_vsu1/screens/chat_screen.dart'; // make sure this is imported
import 'package:libot_vsu1/utils/channel_utils.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<Map<String, dynamic>> _activeRequests = [];
  List<Map<String, dynamic>> _completedRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final active = <Map<String, dynamic>>[];
    final completed = <Map<String, dynamic>>[];

    // Helper function to determine collection name for cancellation
    String getRequestCollectionName(String requestType, String status) {
      if (status.toLowerCase() == 'accepted' ||
          status.toLowerCase() == 'on the way' ||
          status.toLowerCase() == 'arrived') {
        return 'accepted_requests';
      }
      return requestType == 'Passenger' ? 'ride_requests' : 'delivery_requests';
    }

    // 🔹 Ride Requests (Pending/Searching)
    final rideSnap =
        await firestore
            .collection('ride_requests')
            .where('clientId', isEqualTo: user.uid)
            .get();

    for (final doc in rideSnap.docs) {
      final data = doc.data();
      final status = (data['status'] as String?)?.toLowerCase() ?? 'unknown';
      final mapped = {
        ...data,
        'id': doc.id,
        'requestType': 'Passenger',
        'estimatedFare': data['fare'] ?? 0,
        'firestoreCollectionName': getRequestCollectionName(
          'Passenger',
          status,
        ),
      };
      if (status == 'completed') {
        completed.add(mapped);
      } else if (status != 'cancelled') {
        active.add(mapped);
      }
    }

    // 🔹 Delivery Requests (Pending/Searching)
    final deliverySnap =
        await firestore
            .collection('delivery_requests')
            .where('clientId', isEqualTo: user.uid)
            .get();

    for (final doc in deliverySnap.docs) {
      final data = doc.data();
      final status = (data['status'] as String?)?.toLowerCase() ?? 'unknown';
      final mapped = {
        ...data,
        'id': doc.id,
        'requestType': 'Delivery',
        'estimatedFare': double.tryParse(data['deliveryFee'].toString()) ?? 0,
        'firestoreCollectionName': getRequestCollectionName('Delivery', status),
      };
      if (status == 'completed') {
        completed.add(mapped);
      } else if (status != 'cancelled') {
        active.add(mapped);
      }
    }

    // 🔹 Accepted Requests (Can be active or completed)
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
        try {
          final riderDoc =
              await firestore.collection('users').doc(riderId).get();
          if (riderDoc.exists) {
            riderName = riderDoc.data()?['fullName'];
            riderAvatar = riderDoc.data()?['profileUrl'];
          }
        } catch (e) {
          // Handle error if needed
          print('Error fetching rider data: $e');
        }
      }
      final status = (data['status'] as String?)?.toLowerCase() ?? 'unknown';
      final originalRequestType =
          data['requestType'] == 'Ride' ? 'Passenger' : 'Delivery';

      final mapped = {
        ...data,
        'id': doc.id, // This is the ID from accepted_requests
        'originalRequestId':
            data['originalRequestId'], // ID from ride_requests or delivery_requests
        'requestType': originalRequestType,
        'estimatedFare': data['fare'] ?? 0,
        'riderName': riderName ?? 'Rider Unavailable',
        'riderAvatar': riderAvatar ?? '',
        'completionTimestamp':
            (data['completedAt'] is Timestamp)
                ? (data['completedAt'] as Timestamp).toDate()
                : null,
        'firestoreCollectionName': 'accepted_requests',
      };

      if (status != 'completed' && status != 'cancelled') {
        active.removeWhere(
          (r) =>
              r['id'] == data['originalRequestId'] &&
              r['firestoreCollectionName'] != 'accepted_requests',
        );
        active.add(mapped);
      } else if (status == 'completed') {
        completed.add(mapped);
      }
    }
    // Sort active requests: accepted ones first, then by timestamp if available
    active.sort((a, b) {
      int statusCompare = _statusPriority(
        a['status'],
      ).compareTo(_statusPriority(b['status']));
      if (statusCompare != 0) return statusCompare;
      Timestamp? tsA = a['timestamp'];
      Timestamp? tsB = b['timestamp'];
      if (tsA != null && tsB != null) return tsB.compareTo(tsA); // Newest first
      return 0;
    });

    // Sort completed requests by completionTimestamp, newest first
    completed.sort((a, b) {
      DateTime? timeA = a['completionTimestamp'];
      DateTime? timeB = b['completionTimestamp'];
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1; // Place nulls at the end
      if (timeB == null) return -1; // Place nulls at the end
      return timeB.compareTo(timeA); // Newest first
    });

    if (mounted) {
      setState(() {
        _activeRequests = active;
        _completedRequests = completed;
        _isLoading = false;
      });
    }
  }

  int _statusPriority(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return 0;
      case 'on the way':
        return 1;
      case 'arrived':
        return 2;
      case 'pending':
        return 3;
      case 'searching':
        return 4;
      default:
        return 5;
    }
  }

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
            // Use Wrap to handle content overflow better
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
                    value:
                        request['pickupLocationName'] ??
                        request['pickupLocation'] ??
                        'N/A',
                  ),
                  _buildDetailRow(
                    iconData: Icons.flag_outlined,
                    label:
                        request['requestType'] == 'Delivery'
                            ? 'Delivered To'
                            : 'Destination',
                    value:
                        request['destinationName'] ??
                        request['destination'] ??
                        'N/A',
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
                    value: request['status'] ?? 'Completed',
                    valueColor: Colors.green.shade700,
                    valueFontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 20),
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
                      backgroundImage:
                          (request['riderAvatar'] != null &&
                                  request['riderAvatar'].isNotEmpty)
                              ? NetworkImage(request['riderAvatar'])
                              : const AssetImage(
                                    'assets/images/default_profile.png',
                                  )
                                  as ImageProvider,
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

  // --- MODAL FOR ACTIVE REQUESTS ---
  void _showActiveRequestDetails(Map<String, dynamic> request) {
    final String requestStatus =
        (request['status'] as String?)?.toLowerCase() ?? 'unknown';
    final bool isAccepted =
        requestStatus == 'accepted' ||
        requestStatus == 'on the way' ||
        requestStatus == 'arrived';
    final bool isPending =
        requestStatus == 'pending' || requestStatus == 'searching';

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
            // Use Wrap for better overflow handling
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Active Request Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (request['pickupPin'] != null &&
                      request['destinationPin'] != null) ...[
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 10),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.map, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No map data'),
                        ],
                      ),
                    ),
                  ],

                  // Request Details Section
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
                    value:
                        request['pickupLocationName'] ??
                        request['pickupLocation'] ??
                        'N/A',
                  ),
                  _buildDetailRow(
                    iconData: Icons.flag_outlined,
                    label:
                        request['requestType'] == 'Delivery'
                            ? 'Deliver To'
                            : 'Destination',
                    value:
                        request['destinationName'] ??
                        request['destination'] ??
                        'N/A',
                  ),
                  _buildDetailRow(
                    iconData: Icons.payment_outlined,
                    label: 'Payment',
                    value: request['paymentMethod'] ?? 'N/A',
                  ),
                  _buildDetailRow(
                    iconData: Icons.monetization_on_outlined,
                    label: 'Est. Fare',
                    value:
                        'Php ${request['estimatedFare']?.toStringAsFixed(2) ?? 'N/A'}',
                  ),
                  _buildDetailRow(
                    iconData: Icons.info_outline,
                    label: 'Status',
                    value: request['status'] ?? 'Unknown',
                    valueColor:
                        isAccepted
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                    valueFontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 20),

                  // Rider Details Section (Only if accepted)
                  if (isAccepted) ...[
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
                        backgroundImage:
                            (request['riderAvatar'] != null &&
                                    request['riderAvatar'].isNotEmpty)
                                ? NetworkImage(request['riderAvatar'])
                                : const AssetImage(
                                      'assets/images/default_profile.png',
                                    )
                                    as ImageProvider,
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        onBackgroundImageError: (exception, stackTrace) {
                          /* Handle error */
                        },
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
                      // can add subtitle for rider's vehicle
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: 24),

                  // Action Button
                  if (isPending)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmCancelRequest(request);
                      },
                    ),
                  if (isAccepted)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat with Rider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _chatWithRider(request);
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

  void _confirmCancelRequest(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Request?'),
          content: const Text('Are you sure you want to cancel this request?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                _cancelRequest(request);
              },
            ),
          ],
        );
      },
    );
  }

  void _cancelRequest(Map<String, dynamic> request) async {
    final String docId = request['id'];
    // The collection name should be determined by where the PENDING request lives
    // It's unlikely an 'accepted_request' would have a 'pending' status to be cancelled by client
    final String collectionName =
        request['firestoreCollectionName'] ??
        (request['requestType'] == 'Passenger'
            ? 'ride_requests'
            : 'delivery_requests');

    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(docId)
          .update({
            'status': 'cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
          }); // or .delete() if appropriate

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled successfully.')),
      );
      _loadRequests(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to cancel request: $e')));
    }
  }

 void _chatWithRider(Map<String, dynamic> request) {
  final riderId = request['riderId'];
  final riderName = request['riderName'] ?? 'Rider';

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null || riderId == null) return;

  final clientId = currentUser.uid;
  final channelName = generateChatChannel(clientId, riderId);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChatScreen(
        channelName: channelName,
        receiverId: riderId,
        displayName: riderName,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Lighter background
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  _loadRequests();
                },
                child: SingleChildScrollView(
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
                                      (request) => _buildRequestTile(
                                        request,
                                        isActive: true,
                                      ),
                                    )
                                    .toList(),
                          ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Completed Requests'),
                      const SizedBox(height: 10),
                      _completedRequests.isEmpty
                          ? _buildEmptyState(
                            'You have no completed requests yet.',
                          )
                          : Column(
                            children:
                                _completedRequests
                                    .map(
                                      (request) => _buildRequestTile(
                                        request,
                                        isActive: false,
                                      ),
                                    )
                                    .toList(),
                          ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600, // Bolder
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ), // More padding
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08), // Softer shadow
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_outlined,
            size: 56, // Larger icon
            color: Colors.grey.shade300, // Lighter icon color
          ),
          const SizedBox(height: 16),
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
    String titleText;
    String subtitleText;
    IconData leadingIconData;
    String statusText =
        (request['status'] as String?)?.toUpperCase() ?? 'UNKNOWN';
    Color statusColor = Colors.grey.shade700;

    if (request['requestType'] == 'Passenger') {
      titleText = 'Passenger Ride';
      subtitleText =
          '${request['pickupLocationName'] ?? request['pickupLocation']} to ${request['destinationName'] ?? request['destination']}';
      leadingIconData = Icons.directions_car_filled_outlined;
    } else if (request['requestType'] == 'Delivery') {
      titleText = 'Delivery Service';
      subtitleText =
          'Item: ${request['item'] ?? 'Package'} - ${request['pickupLocationName'] ?? request['pickupLocation']} to ${request['destinationName'] ?? request['destination']}';
      leadingIconData = Icons.delivery_dining_outlined;
    } else {
      titleText = 'Unknown Request';
      subtitleText =
          '${request['pickupLocationName'] ?? request['pickupLocation']} to ${request['destinationName'] ?? request['destination']}';
      leadingIconData = Icons.help_outline;
    }

    if (isActive) {
      switch (statusText.toLowerCase()) {
        case 'pending':
        case 'searching':
          statusColor = Colors.orange.shade700;
          break;
        case 'accepted':
        case 'on the way':
        case 'arrived':
          statusColor = Colors.green.shade700;
          break;
        default:
          statusColor = Colors.blueGrey.shade700;
      }
    }

    return Card(
      elevation: 1.5, // Softer elevation
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        // Make the card tappable
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isActive) {
            _showActiveRequestDetails(request);
          } else {
            _showCompletedRequestDetails(request);
          }
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12, // Increased vertical padding
          ),
          leading: CircleAvatar(
            backgroundColor:
                isActive
                    ? Colors.blue.shade50
                    : Colors.green.shade50, // Softer background
            foregroundColor:
                isActive ? Colors.blue.shade700 : Colors.green.shade700,
            radius: 24,
            child: Icon(leadingIconData, size: 24),
          ),
          title: Text(
            titleText,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16.5,
            ), // Slightly larger
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(
                subtitleText,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (isActive)
                Text(
                  'Status: $statusText',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                )
              else if (request['completionTimestamp'] != null)
                Text(
                  'Completed: ${DateFormat('MMM dd, hh:mm a').format(request['completionTimestamp'])}',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                )
              else
                Text(
                  'Completed: N/A', // Fallback if timestamp is null
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
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
                  fontSize: 15, // Slightly larger
                ),
              ),
              SizedBox(height: isActive ? 4 : 0),
              if (isActive)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
