import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:potato/core/const/app_images.dart';

import 'package:potato/services/chat/chat_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  // Method to delete user data from Firestore (including chat data)
  Future<void> deleteUserData(String userId) async {
    try {
      // Delete user document from Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // Use ChatService to delete user's chat data
      ChatService chatService = ChatService();

      // Delete all chat rooms associated with the user
      var userChats = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participants', arrayContains: userId)
          .get();

      for (var chatDoc in userChats.docs) {
        await FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(chatDoc.id)
            .delete();
      }

      print("User data deleted successfully from Firestore and chat rooms.");
    } catch (e) {
      print("Error deleting user data: $e");
    }
  }

  // Method to delete the user account from Firebase Authentication
  Future<void> deleteUserAccount() async {
    try {
      // Get the current user
      User? user = _auth.currentUser;

      if (user != null) {
        // Delete user data from Firestore
        await deleteUserData(user.uid);

        // Delete the user account from Firebase Auth
        await user.delete();

        // Sign out the user (even though the account is deleted, ensure logout)
        await _auth.signOut();

        // Redirect them to the login screen (since the account is deleted, they should not remain logged in)
        Navigator.pushReplacementNamed(context, '/login');

        print("Account deleted successfully");
      }
    } catch (e) {
      print("Error deleting user account: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.orange,
          title: Text(
            'Potato',
            style: TextStyle(
              fontSize: 24, // Adjust the font size
              fontWeight: FontWeight.w500, // Make it bold
              color: Colors.white, // Choose your color (white for this example)
            ),
          )),
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: const BoxDecoration(color: Colors.white24),
              ),
              Positioned(
                bottom: -50,
                left: 30,
                child: CircleAvatar(
                  radius: 50,
                  child: Image.asset(AppImages.potato),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  _user?.email ?? 'No Email',
                  style: const TextStyle(fontSize: 18, color: Colors.blue),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )),
                    onPressed: () async {
                      await _auth.signOut();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )),
                    onPressed: () async {
                      // Show confirmation dialog before deleting
                      bool confirmDelete = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text(
                              "Are you sure you want to delete your account?"),
                          content: const Text(
                              "This action cannot be undone. Your data will be permanently deleted."),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false); // No
                              },
                              child: const Text("No"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true); // Yes
                                deleteUserAccount();
                              },
                              child: const Text("Yes"),
                            ),
                          ],
                        ),
                      );

                      if (confirmDelete == true) {
                        await deleteUserAccount(); // Call the delete account method
                      }
                    },
                    child: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Divider(),
                SizedBox(
                  height: 20,
                ),
                Text(
                  'On Potato App, there\'s no shortage of "အာလူးဖုတ်" moments — where talking too much is the real fun! Share endless chats, silly reactions, and enjoy all the laughs with your friends. Potato App – the place to talk, just like you would over a plate of potatoes!',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
