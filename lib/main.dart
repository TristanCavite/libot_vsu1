import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'utils/lifecycle_watcher.dart'; // 👈 import it
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:libot_vsu1/services/ably_service.dart';

//import 'screens/temp_add_place_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: 'https://ehokbzfksrznyhfbdwjy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVob2tiemZrc3J6bnloZmJkd2p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3MzE3MTYsImV4cCI6MjA2MDMwNzcxNn0.2YaIQLq7O4V0PsDgoRyLn8Yt7xyuGBMUO8TkTJ1fIrQ',
  );

  await AblyService.initialize('MDBIsw.cI0DgA:kpaYPJXITjJd7GbiI7S4xuhINEqKQzkJHP4NQJE7pYA');

   
  // ✅ Request notification permission (Android 13+)
  if (await Permission.notification.isDenied ||
      await Permission.notification.isPermanentlyDenied) {
    await Permission.notification.request();
  }

  // ✅ Initialize local notifications
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('ic_stat_logo');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('Notification tapped: ${response.payload}');
    },
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
