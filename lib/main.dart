import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart'; // ✅ import your welcome screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LibotVSUApp());
}

class LibotVSUApp extends StatelessWidget {
  const LibotVSUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LibotVSU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto', // optional: for consistency
        useMaterial3: true,
      ),
      home: const WelcomeScreen(), // 👈 your custom page here
    );
  }
}
