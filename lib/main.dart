import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:potato/firebase_options.dart';
import 'package:potato/services/auth/auth_gate.dart';
import 'package:potato/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Firebase initialized successfully");
  // Set language code for FirebaseAuth
  await setLanguageCode();
  // Initialize Remote Config
  await setupRemoteConfig();
  // Lock screen orientation
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

// 🔹 Setup Firebase Remote Config
Future<void> setupRemoteConfig() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  // hello
  // hi
  try {
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await remoteConfig.fetchAndActivate();
    // Get the latest app version from Firebase
    String latestVersion = remoteConfig.getString("latest_version");
    print("Latest app version: $latestVersion");
  } catch (e) {
    print("Failed to fetch remote config: $e");
  }
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
      home: AuthGate(),
    );
  }
}
