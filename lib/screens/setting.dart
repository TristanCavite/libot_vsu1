import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libot_vsu1/screens/auth_gate.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String fullName = '';
  String email = '';
  String phone = '';
  String role = '';
  String profileUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      setState(() {
        fullName = data['fullName'] ?? '';
        email = data['email'] ?? '';
        phone = data['mobile'] ?? '';
        role = data['role'] ?? '';
        profileUrl = data['profileUrl'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00843D),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 16),
          _buildLogo(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
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

  Widget _buildLogo() => Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Center(
          child: Image.asset(
            'assets/logo.png',
            width: 215,
            height: 100,
          ),
        ),
      );

  Widget _buildHeader(BuildContext context) => Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x1A00843D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF00843D), size: 24),
            ),
          ),
          const Text(
            'Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
          ),
        ],
      );

  Widget _buildProfileDetails() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 16),
              _buildContactInfo(Icons.email, email),
              const SizedBox(height: 8),
              _buildContactInfo(Icons.phone, phone),
            ],
          ),
        ),
      );

  Widget _buildProfileHeader() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: profileUrl.isNotEmpty
                    ? Image.network(profileUrl, width: 80, height: 80, fit: BoxFit.cover)
                    : Image.asset('assets/images/default_profile.png', width: 80, height: 80),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.mode_edit, color: Colors.black54, size: 26),
          ),
        ],
      );

  Widget _buildContactInfo(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: Colors.black54, size: 26),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      );

  Widget _buildAboutButton() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerLeft,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info, color: Colors.black54, size: 26),
                    SizedBox(width: 8),
                    Text('About', style: TextStyle(fontSize: 20, color: Colors.black54)),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 20),
              ],
            ),
          ),
        ),
      );

  Widget _buildMainButtons(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLogoutButton(context),
            const SizedBox(height: 5),
            _deleteAccountButton(context),
          ],
        ),
      );

  Widget _buildLogoutButton(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              _showConfirmationDialog(
                context,
                title: "Logout",
                content: "Are you sure you want to logout?",
                confirmButtonText: "Logout",
                confirmButtonColor: Colors.black,
                onConfirm: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthGate()),
                    (route) => false,
                  );
                },
              );
            },
            icon: const Icon(Icons.logout, color: Colors.black, size: 26),
            label: const Text('Logout', style: TextStyle(fontSize: 16, color: Colors.black)),
            style: TextButton.styleFrom(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      );

  Widget _deleteAccountButton(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              _showConfirmationDialog(
                context,
                title: "Delete Account",
                content: "Are you sure you want to delete your account? \n\nThis action cannot be undone.",
                confirmButtonText: "Delete",
                confirmButtonColor: Colors.red,
                onConfirm: () {
                  Navigator.pop(context);
                  // Add delete logic here
                },
              );
            },
            icon: const Icon(Icons.delete, color: Colors.white, size: 26),
            label: const Text('Delete Account', style: TextStyle(fontSize: 16, color: Colors.white)),
            style: TextButton.styleFrom(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      );

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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
        content: Text(content, style: const TextStyle(fontSize: 16, color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
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
