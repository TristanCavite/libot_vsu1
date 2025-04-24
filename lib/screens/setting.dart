import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00843D), // Match the background color
      body: Stack(
        children: [
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
                borderRadius: BorderRadius.circular(32), // Rounded corners
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          ); // Go back to the previous screen
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 24,
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
                  ),
                  const SizedBox(height: 16), // Space between title and content
                  //This is another container for the profile image and name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(
                        16,
                      ), // Add padding inside the container
                      decoration: BoxDecoration(
                        color: Colors.grey[200], // Light grey background color
                        borderRadius: BorderRadius.circular(
                          16,
                        ), // Rounded corners
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Profile Image
                              ClipOval(
                                child: Image.network(
                                  'https://i.pravatar.cc/300', // Replace with your image URL
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(
                                width: 16,
                              ), // Space between image and text
                              // Name and Role
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
                                  SizedBox(
                                    height: 2,
                                  ), // Space between name and role
                                  Text(
                                    'Rider',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.email,
                                color: Colors.black54,
                                size: 20,
                              ),
                              const SizedBox(
                                width: 8,
                              ), // Space between icon and text
                              const Text(
                                'johndoe@example.com',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ), // Space between image and contact info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.phone,
                                color: Colors.black54,
                                size: 20,
                              ),
                              const SizedBox(
                                width: 8,
                              ), // Space between icon and text
                              const Text(
                                '09248782378',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16), // Space below the image row
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
