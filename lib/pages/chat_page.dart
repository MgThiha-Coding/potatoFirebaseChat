import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:potato/components/my_text_field.dart';
import 'package:potato/services/chat/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserID;
  const ChatPage(
      {super.key,
      required this.receiverUserEmail,
      required this.receiverUserID});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void sentMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sentMessage(
          widget.receiverUserID, _messageController.text);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.receiverUserEmail,
          style: TextStyle(color: Colors.blueGrey),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
          SizedBox(
            height: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: StreamBuilder(
          stream: _chatService.getMessages(
              widget.receiverUserID, _firebaseAuth.currentUser!.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            return ListView(
                children: snapshot.data!.docs
                    .map((document) => _buildMessageItem(document))
                    .toList());
          }),
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    // Safe null check to avoid runtime error
    String senderEmail = data['senderEmail'] ?? 'Unknown Sender';
    String message = data['message'] ?? 'No message content';

    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;
    var color = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Colors.blue
        : Colors.green;
    return Container(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Column(
          crossAxisAlignment:
              (data['senderId'] == _firebaseAuth.currentUser!.uid)
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
          mainAxisAlignment:
              (data['senderId'] == _firebaseAuth.currentUser!.uid)
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(width: 1, color: Colors.green)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderEmail,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '   ${message}',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),

            // ChatBubble(message: message),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              width: 2,
              color: Colors.green,
            )),
        child: Row(
          children: [
            Expanded(
                child: MyTextField(
              controller: _messageController,
              hintText: 'Enter Message',
            )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FloatingActionButton(
                shape: CircleBorder(),
                onPressed: () {
                  sentMessage();
                },
                child: Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
