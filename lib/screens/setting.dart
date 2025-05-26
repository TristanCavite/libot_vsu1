import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Rename your model to avoid conflict with Firebase User
class AppUser {
  final String name;
  final String email;
  final String phone;
  final String role;
  final String imageUrl;

  AppUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.imageUrl,
  });
}

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  User? user; // Firebase user
  AppUser? appUser; // Your custom user model

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _fetchUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        appUser = AppUser(
          name: data['fullName'] ?? '',
          email: data['email'] ?? '',
          phone: data['mobile'] ?? '',
          role: data['role'] ?? '',
          imageUrl: data['profileUrl'] ?? '', // <-- Use empty string fallback
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (appUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: const Color(0xFF00843D), // Background color
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 16), // Space at the top
          _buildLogo(), // Logo at the top
          Align(
            alignment: Alignment.bottomCenter, // Align to the bottom center
            child: Container(
              width: double.infinity,
              height:
                  MediaQuery.of(context).size.height *
                  0.8, // 80% of screen height
              padding: const EdgeInsets.all(16), // Add padding inside the box
              decoration: BoxDecoration(
                color: Colors.white, // White background
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ), // Rounded corners
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildProfileDetails(),
                  const SizedBox(height: 16),
                  _buildAboutButton(),
                  _buildMainButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed:
              () => Navigator.pop(context), // Go back to the previous screen
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
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200], // Light grey background color
          borderRadius: BorderRadius.circular(16), // Rounded corners
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildContactInfo(Icons.email, appUser!.email),
            const SizedBox(height: 8),
            _buildContactInfo(Icons.phone, appUser!.phone),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Center(
        child: Image.asset(
          'assets/logo.png', // Replace with your logo asset path
          width: 215,
          height: 100,
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipOval(
              child:
                  (appUser!.imageUrl.isNotEmpty)
                      ? Image.network(
                        appUser!.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
            ),
            const SizedBox(width: 16), // Space between image and text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appUser!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2), // Space between name and role
                Text(
                  appUser!.role,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 26),
        const SizedBox(width: 8), // Space between icon and text
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }

  Widget _buildAboutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity, // Make the button span the full width
        child: TextButton(
          onPressed: () {
            // Perform an action
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(16), // Light grey background
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ), // Align content to the left
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info,
                    color: Colors.black54,
                    size: 26,
                  ), // Info icon
                  const SizedBox(width: 8), // Space between icon and text
                  const Text(
                    'About',
                    style: TextStyle(fontSize: 20, color: Colors.black54),
                  ),
                ],
              ),
              const Icon(
                Icons.arrow_forward_ios, // Forward arrow icon
                color: Colors.black54,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deleteAccountButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity, // Make the button span the full width
        child: TextButton.icon(
          onPressed: () {
            // Perform an action
            _showConfirmationDialog(
              context,
              title: "Delete Account",
              content:
                  "Are you sure you want to delete your account? \n\nThis action cannot be undone.",
              confirmButtonText: "Delete",
              confirmButtonColor: Colors.red,
              onConfirm: () {
                // Perform delete account logic here
                Navigator.pop(context); // Close dialog
              },
            );
          },
          icon: const Icon(Icons.delete, color: Colors.white, size: 26),
          label: const Text(
            'Delete Account',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          style: TextButton.styleFrom(
            alignment: Alignment.center, // Align content to the left
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Rounded corners
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity, // Make the button span the full width
        child: TextButton.icon(
          onPressed: () {
            // Perform an action
            _showConfirmationDialog(
              context,
              title: "Logout",
              content: "Are you sure you want to logout?",
              confirmButtonText: "Logout",
              confirmButtonColor: Colors.black,
              onConfirm: () {
                _logout();
              },
            );
          },
          icon: const Icon(Icons.logout, color: Colors.black, size: 26),
          label: const Text(
            'Logout',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          style: TextButton.styleFrom(
            alignment: Alignment.center, // Align content to the left
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.grey[200],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Rounded corners
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLogoutButton(context),
          const SizedBox(height: 5), // Space between buttons
          _deleteAccountButton(context),
        ],
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmButtonText,
    required Color confirmButtonColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            content: Text(
              content,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmButtonColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: onConfirm,
                child: Text(confirmButtonText),
              ),
            ],
          ),
    );
  }
}
