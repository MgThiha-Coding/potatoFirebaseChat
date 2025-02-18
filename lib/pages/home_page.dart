import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:potato/core/const/app_images.dart';
import 'package:potato/pages/chat_page.dart';
import 'package:potato/pages/profile_page.dart';
import 'package:potato/services/auth_service.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void signOut() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: Row(
          children: [
            Image.asset(
              AppImages.potato,
              scale: 17,
            ),
            SizedBox(
              width: 8,
            ),
            Text('Potato'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: IconButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ProfilePage()));
                },
                icon: CircleAvatar(
                    child: const Icon(
                  Icons.person,
                  color: Colors.orange,
                ))),
          )
        ],
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: const Text('Error fetching data'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: const Text('Loading...'));
        }

        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildUserListItem(doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    if (_auth.currentUser!.email != data['email']) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
        child: Card(
          elevation: 2, // Slight elevation for modern feel
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
                horizontal: 4, vertical: 4), // Added padding inside ListTile
            minVerticalPadding: 10, // Added padding to adjust height

            leading: Padding(
              padding: const EdgeInsets.all(5.0),
              child: CircleAvatar(
                radius: 30, // Slightly larger circle for better look
                backgroundColor: Colors.blueAccent, // Colorful background
                child: Icon(
                  Icons.person_2_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),

            subtitle: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text(
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                '${data['email']}',
                style: TextStyle(color: Colors.grey[800], fontSize: 14),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    receiverUserEmail: data['email'],
                    receiverUserID: data['uid'],
                  ),
                ),
              );
            },
            // Add a red notification dot if there's an unread message
            isThreeLine: true,
            trailing: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc('${_auth.currentUser!.uid}_${data['uid']}')
                  .collection('messages')
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SizedBox.shrink(); // No unread messages
                } else {
                  return Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
