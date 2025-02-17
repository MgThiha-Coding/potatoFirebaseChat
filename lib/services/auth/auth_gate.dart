import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:potato/pages/home_page.dart';
import 'package:potato/services/auth/login_or_register.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child:
                    CircularProgressIndicator()); // Show loading while waiting
          }

          if (snapshot.hasData) {
            print('Firebase response ${snapshot.data}'); // Print the user data
            return HomePage();
          } else {
            return LoginOrRegister();
          }
        },
      ),
    );
  }
}
