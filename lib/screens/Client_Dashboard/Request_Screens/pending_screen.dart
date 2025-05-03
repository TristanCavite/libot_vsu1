import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:libot_vsu1/screens/Client_Dashboard/client_dashboard_screen.dart';

class PendingScreen extends StatefulWidget {
  final String requestId;
  const PendingScreen({super.key, required this.requestId});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  int _onlineRiders = 0;
  bool _hasTimedOut = false;
  Timer? _timeoutTimer;
  StreamSubscription<DocumentSnapshot>? _requestListener;

  @override
  void initState() {
    super.initState();
    _listenToRiders();
    _startTimeoutWatcher();
    _watchRequestStatus();
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

  void _startTimeoutWatcher() {
    _timeoutTimer = Timer(const Duration(minutes: 1), () async {
      final doc =
          await FirebaseFirestore.instance
              .collection('ride_requests')
              .doc(widget.requestId)
              .get();

      if (doc.exists && doc['status'] == 'pending' && mounted) {
        setState(() {
          _hasTimedOut = true;
        });

        // Auto-cancel request on timeout
        await _cancelRequest();
      }
    });
  }

  void _watchRequestStatus() {
    _requestListener = FirebaseFirestore.instance
        .collection('ride_requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((doc) {
          if (doc.exists && doc['status'] != 'pending') {
            _timeoutTimer?.cancel(); // ✅ Stop timeout if accepted
            if (mounted) {
              Navigator.pop(context); // Replace this with next screen if needed
            }
          }
        });
  }

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

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _requestListener?.cancel();
    super.dispose();
  }
@override
Widget build(BuildContext context) {
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
            // Header with time or error icon
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

            // Card body
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

                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _hasTimedOut
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

                  // Buttons
                  _hasTimedOut
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => ClientDashboardScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A651),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Book Again',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => ClientDashboardScreen(),
                              ),
                              (route) => false,
                            );
                            await _cancelRequest();
                            if (mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel Request',
                            style: TextStyle(color: Colors.white),
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
