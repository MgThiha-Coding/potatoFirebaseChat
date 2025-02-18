import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserID;

  const ChatPage({
    super.key,
    required this.receiverUserEmail,
    required this.receiverUserID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    markMessagesAsRead();
  }

  // Mark messages as read when the chat page is opened
  void markMessagesAsRead() async {
    var chatRoomId = _getChatRoomId();
    var messagesRef = FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages');

    var unreadMessages =
        await messagesRef.where('isRead', isEqualTo: false).get();

    for (var message in unreadMessages.docs) {
      await message.reference.update({'isRead': true});
    }
  }

  // Get the chat room ID based on the sender and receiver IDs
  String _getChatRoomId() {
    List<String> ids = [
      _firebaseAuth.currentUser!.uid,
      widget.receiverUserID,
    ];
    ids.sort();
    return ids.join("_");
  }

  // Send a message
  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      String chatRoomId = _getChatRoomId();
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'message': _messageController.text,
        'senderId': _firebaseAuth.currentUser!.uid,
        'receiverId': widget.receiverUserID,
        'senderEmail': _firebaseAuth.currentUser!.email,
        'timestamp': Timestamp.now(),
        'isRead': false,
      });

      _messageController.clear();

      // Scroll to the bottom after sending a message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  // Format the timestamp
  String formatTimestamp(Timestamp timestamp) {
    var format = DateFormat('hh:mm a');
    return format.format(timestamp.toDate());
  }

  // Build the message list
  Widget _buildMessageList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(_getChatRoomId())
            .collection('messages')
            .orderBy('timestamp')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Scroll to the bottom when new data is received
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
            }
          });

          return ListView(
            controller: _scrollController,
            children: snapshot.data!.docs
                .map((document) => _buildMessageItem(document))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    String message = data['message'] ?? 'No message content';
    String senderEmail = data['senderEmail'] ?? 'Unknown Sender';
    Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
    String messageId = document.id;

    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;
    var color = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Colors.blue
        : Colors.green;

    return Container(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisAlignment:
              (data['senderId'] == _firebaseAuth.currentUser!.uid)
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
          children: [
            // Only show the delete option for the sender
            if (data['senderId'] == _firebaseAuth.currentUser!.uid)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert),
                onSelected: (String value) {
                  if (value == 'Delete') {
                    // Debugging: print messageId before deletion
                    print("Deleting message with ID: $messageId");
                    deleteMessage(messageId);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'Delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    0.75, // Limit width to 75% of screen width
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender email (optional)
                  Text(
                    senderEmail,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  // Message content with overflow handling
                  Text(
                    message,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                    maxLines: null, // Allow multiple lines
                    overflow:
                        TextOverflow.visible, // Handle overflow gracefully
                  ),
                  SizedBox(height: 5),
                  // Timestamp
                  Text(
                    formatTimestamp(timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Delete the message
  void deleteMessage(String messageId) async {
    try {
      // Ensure the correct document is being deleted
      print("Attempting to delete message with ID: $messageId");

      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(_getChatRoomId())
          .collection('messages')
          .doc(messageId)
          .delete();

      // Provide feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message deleted successfully')),
      );
    } catch (e) {
      // Handle the error and provide feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverUserEmail),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
