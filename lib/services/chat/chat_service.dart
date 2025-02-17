/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  Future<void> sentMessage(String receiverId, String message) async {

  }
}*/
/*

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:potato/model/message.dart';


class ChatService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sentMessage(String receiverId, String message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
        senderEmail: currentUserEmail,
        senderId: currentUserId,
        receiverId: receiverId,
        message: message,
        timestamp: timestamp);
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");
    return _firestore
        .collection('chat_room')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:potato/model/message.dart';

class ChatService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message
  Future<void> sentMessage(String receiverId, String message) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception("User not logged in or email not available");
      }

      final String currentUserId = currentUser.uid;
      final String currentUserEmail = currentUser.email!;
      final Timestamp timestamp = Timestamp.now();

      Message newMessage = Message(
        senderEmail: currentUserEmail,
        senderId: currentUserId,
        receiverId: receiverId,
        message: message,
        timestamp: timestamp,
      );

      List<String> ids = [currentUserId, receiverId];
      ids.sort();
      String chatRoomId = ids.join("_");

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage.toMap());
    } catch (e) {
      print("Error sending message: $e");
      rethrow; // You can propagate the error or handle it differently
    }
  }

  // Get messages for a specific chat room
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection(
            'chat_rooms') // Ensure this matches the collection name everywhere
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Optional: Create a chat room if not exists (to ensure the chat room is created before sending the first message)
  Future<void> createChatRoomIfNotExists(String receiverId) async {
    final currentUserId = _firebaseAuth.currentUser!.uid;
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    // Check if the chat room already exists
    var chatRoomDoc =
        await _firestore.collection('chat_rooms').doc(chatRoomId).get();

    if (!chatRoomDoc.exists) {
      // If the chat room does not exist, create it
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .set({'chatRoomId': chatRoomId});
    }
  }
}
