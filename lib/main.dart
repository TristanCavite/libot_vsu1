import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'utils/lifecycle_watcher.dart'; // 👈 import it

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LifecycleWatcher(child: LibotVSUApp())); // 👈 wrap here
}

class LibotVSUApp extends StatelessWidget {
  const LibotVSUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LibotVSU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
