import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'utils/lifecycle_watcher.dart'; // 👈 import it
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: 'https://ehokbzfksrznyhfbdwjy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVob2tiemZrc3J6bnloZmJkd2p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3MzE3MTYsImV4cCI6MjA2MDMwNzcxNn0.2YaIQLq7O4V0PsDgoRyLn8Yt7xyuGBMUO8TkTJ1fIrQ',
  );

  runApp(const LifecycleWatcher(child: LibotVSUApp()));
}

class LibotVSUApp extends StatelessWidget {
  const LibotVSUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LibotVSU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
      home: const WelcomeScreen(),
    );
  }
}
