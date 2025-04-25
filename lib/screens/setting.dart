import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                borderRadius: BorderRadius.only(
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
              color: Color(0x1A00843D),
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
            _buildContactInfo(Icons.email, 'johndoe@example.com'),
            const SizedBox(height: 8),
            _buildContactInfo(Icons.phone, '09248782378'),
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
              child: Image.network(
                'https://i.pravatar.cc/300', // Replace with your image URL
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16), // Space between image and text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'John Doe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2), // Space between name and role
                Text(
                  'Rider',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () {}, // Add edit functionality here
          icon: const Icon(Icons.mode_edit, color: Colors.black54, size: 26),
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
                // Perform logout logic here
                Navigator.pop(context); // Close dialog
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ), // 20% of screen height
      alignment: Alignment.bottomCenter,
      // 20% of screen height// 20% of screen height
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
