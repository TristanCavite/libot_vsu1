import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libot_vsu1/screens/welcome_screen.dart';
import 'package:libot_vsu1/screens/Client_Dashboard/client_dashboard_screen.dart';
import 'package:libot_vsu1/screens/Rider_Dashboard/rider_dashboard_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // 🔁 Realtime user state
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const WelcomeScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = userSnapshot.data?.get('role');

            if (role == 'Rider') {
              return const RiderDashboardScreen();
            } else {
              return const ClientDashboardScreen();
            }
          },
        );
      },
    );
  }
}
