import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:libot_vsu1/screens/Client_Dashboard/client_dashboard_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:libot_vsu1/main.dart' show flutterLocalNotificationsPlugin;
import 'package:libot_vsu1/screens/chat_screen.dart';
import 'package:libot_vsu1/utils/channel_utils.dart';

class PendingScreen extends StatefulWidget {
  final String requestId;
  const PendingScreen({super.key, required this.requestId});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  int _onlineRiders = 0;
  bool _hasTimedOut = false;
  String _requestStatus = 'pending'; // can be 'pending', 'accepted'
  Map<String, dynamic>? _riderInfo;

  Timer? _timeoutTimer;
  StreamSubscription<DocumentSnapshot>? _acceptedRequestListener;

  @override
  void initState() {
    super.initState();
    _listenToRiders(); // 🔁 Live count of online riders
    _startTimeoutWatcher(); // ⏳ Cancel if timeout
    _watchAcceptedStatus(); // 👀 Check if request was accepted
  }

  void _listenToRiders() {
    FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Rider')
        .where('status', isEqualTo: 'online')
        .snapshots()
        .listen((snapshot) {
          setState(() {
            _onlineRiders = snapshot.docs.length;
          });
        });
  }

  // ⏳ Auto-timeout after 2 minutes if not accepted
  void _startTimeoutWatcher() {
    _timeoutTimer = Timer(const Duration(minutes: 2), () async {
      final doc =
          await FirebaseFirestore.instance
              .collection('ride_requests')
              .doc(widget.requestId)
              .get();

      if (doc.exists && doc['status'] == 'pending' && mounted) {
        setState(() {
          _hasTimedOut = true;
        });

        // 🔔 Send timeout notification
        await _showNotification(
          title: 'Request Timed Out',
          body: 'No riders accepted your request. Please try again later.',
        );

        await _cancelRequest();
      }
    });
  }

  // 🔄 Listen to accepted_requests to detect if a rider accepted the request
  void _watchAcceptedStatus() {
    _acceptedRequestListener = FirebaseFirestore.instance
        .collection('accepted_requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((doc) async {
          if (doc.exists && mounted) {
            final data = doc.data()!;
            final riderId = data['riderId'];

            // ✅ If rider info is found
            if (riderId != null) {
              final riderDoc =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(riderId)
                      .get();

              if (riderDoc.exists) {
                setState(() {
                  _riderInfo = riderDoc.data();
                  _requestStatus = 'accepted';
                  _timeoutTimer?.cancel(); // 🛑 Stop timer if accepted
                });

                // 🔔 Send accepted notification
                await _showNotification(
                  title: 'Ride Accepted',
                  body: 'A rider has accepted your request!',
                );
              }
            }
          }
        });
  }

  void _openChatWithRider() {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null || _riderInfo == null) return;

  final clientId = currentUser.uid;
  final riderId = _riderInfo!['uid'];
  final riderName = _riderInfo!['fullName'] ?? 'Rider';

  // Generate channelName using helper
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



  // ❌ Cancel request & clean up user state
  Future<void> _cancelRequest() async {
    try {
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(widget.requestId)
          .delete();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'pendingRequestId': FieldValue.delete()});
      }
    } catch (e) {
      debugPrint('Failed to cancel request: $e');
    }
  }

  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'ride_status_channel', // 🔑 Channel ID
          'Ride Status', // 📛 Channel Name
          icon: 'ic_stat_logo',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // ✅ Use the correct instance from main.dart
    await flutterLocalNotificationsPlugin.show(
      0, // 🆔 Notification ID
      title,
      body,
      platformDetails,
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _acceptedRequestListener?.cancel(); // cancel listener
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget screen =
        _requestStatus == 'accepted' && _riderInfo != null
            ? _buildAcceptedConfirmation()
            : _buildWaitingOrTimeoutScreen();

    // 🔍 Check if we're embedded inside another screen like ClientDashboard
    final bool isEmbedded = Scaffold.maybeOf(context) != null;

    return isEmbedded
        ? screen
        : Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("Pending Details"),
            backgroundColor: const Color(0xFF00843D),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: screen,
        );
  }

  // ⌛ UI for waiting or timeout state
  Widget _buildWaitingOrTimeoutScreen() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: _hasTimedOut ? Colors.red : Colors.blue,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Icon(
                  _hasTimedOut ? Icons.error : Icons.access_time,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  children: [
                    Text(
                      _hasTimedOut
                          ? 'Sorry, request has timed out.'
                          : 'Waiting for a rider to confirm request',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasTimedOut
                          ? 'Oops—it seems that there are no riders available at the moment.'
                          : 'Be patient — riders are students too, just like you.',
                      style: const TextStyle(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _hasTimedOut
                                ? Colors.red.shade50
                                : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: _hasTimedOut ? Colors.red : Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _hasTimedOut
                                  ? 'No riders currently available.'
                                  : 'Waiting for available riders ($_onlineRiders online)',
                              style: TextStyle(
                                color: _hasTimedOut ? Colors.red : Colors.blue,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_hasTimedOut) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Looking for nearby riders\n$_onlineRiders riders are currently online',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => ClientDashboardScreen(),
                          ),
                          (route) => false,
                        );
                        await _cancelRequest();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _hasTimedOut ? const Color(0xFF00A651) : Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _hasTimedOut ? 'Book Again' : 'Cancel Request',
                        style: const TextStyle(color: Colors.white),
                      ),
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

  // ✅ UI after request is accepted by a rider
  Widget _buildAcceptedConfirmation() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: const BoxDecoration(
                  color: Color(0xFF00A651),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  children: [
                    const Text(
                      'Great! A rider has accepted your request.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please wait patiently at the pick up point — rider will be on the way.',
                      style: TextStyle(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Rider will be on the way.',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    // 🧑 Rider info
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey,
                        backgroundImage:
                            _riderInfo!['profileUrl'] != null &&
                                    _riderInfo!['profileUrl']
                                        .toString()
                                        .isNotEmpty
                                ? NetworkImage(_riderInfo!['profileUrl'])
                                : null,
                        child:
                            _riderInfo!['profileUrl'] == null ||
                                    _riderInfo!['profileUrl'].toString().isEmpty
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                      ),
                      title: Text(_riderInfo!['fullName'] ?? 'Rider'),
                      subtitle: Text(_riderInfo!['vehicle'] ?? 'On a ride'),
                      trailing: IconButton(
                        icon: const Icon(Icons.chat_bubble_outline),
                        onPressed: () => _openChatWithRider(),
                      ),
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
