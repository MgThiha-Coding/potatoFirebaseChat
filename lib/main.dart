import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:potato/firebase_options.dart';
import 'package:potato/services/auth/auth_gate.dart';
import 'package:potato/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth package

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Optionally, you could show a loading screen or alert to the user.
  }

  // Set language code for FirebaseAuth
  await setLanguageCode();

  // Lock screen orientation to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MyApp(),
    ),
  );
}

// Set language code for FirebaseAuth
Future<void> setLanguageCode() async {
  try {
    await FirebaseAuth.instance.setLanguageCode('en');
    print("Language code set to English");
  } catch (e) {
    print("Error setting language code: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(), // This widget handles authentication states
    );
  }
}
