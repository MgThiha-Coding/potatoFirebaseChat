import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:potato/firebase_options.dart';
import 'package:potato/services/auth/auth_gate.dart';
import 'package:potato/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth package

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set language code to avoid the warning
  await setLanguageCode();

  runApp(ChangeNotifierProvider(
    create: (context) => AuthService(),
    child: MyApp(),
  ));
}

Future<void> setLanguageCode() async {
  await FirebaseAuth.instance.setLanguageCode(
      'en'); // Set language code to English (or your preferred language)
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: AuthGate());
  }
}
