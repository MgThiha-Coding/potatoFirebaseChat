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
  bool _scrollToBottom = false; // Flag to manage when to scroll to the bottom

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    markMessagesAsRead();
  }

  void reactToMessage(String messageId, String emoji) {
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(_getChatRoomId())
        .collection('messages')
        .doc(messageId)
        .update({
      'currentReaction': emoji, // Update the reaction
    }).then((value) {
      print("Reaction updated successfully!");
    }).catchError((error) {
      print("Error updating reaction: $error");
    });
  }

  // Scroll listener to track if the user is at the bottom
  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _scrollToBottom = true; // Set flag to true when the user is at the bottom
    } else {
      _scrollToBottom =
          false; // Reset the flag when the user is not at the bottom
    }
  }

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

  String _getChatRoomId() {
    List<String> ids = [
      _firebaseAuth.currentUser!.uid,
      widget.receiverUserID,
    ];
    ids.sort();
    return ids.join("_");
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      String chatRoomId = _getChatRoomId();
      // Add message to Firestore
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
        'reactions': [],
      });

      _messageController.clear();

      // Trigger a scroll to the bottom after message is sent
      if (_scrollController.hasClients) {
        // Delay scroll until the message is rendered
        Future.delayed(Duration(milliseconds: 300), () {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    var format = DateFormat('hh:mm a');
    return format.format(timestamp.toDate());
  }

  Widget _buildMessageList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(_getChatRoomId())
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No messages yet"));
          }

          var messageCount = snapshot.data!.docs.length;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollToBottom && _scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
              _scrollToBottom = false; // Reset flag after scrolling
            }
          });

          return ListView.builder(
            controller: _scrollController,
            itemCount: messageCount,
            itemBuilder: (context, index) {
              var document = snapshot.data!.docs[index];
              return _buildMessageItem(document);
            },
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
    String currentReaction = data['currentReaction'] ?? '';
    String senderId = data['senderId'] ?? '';

    var alignment = (senderId == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;
    var color = (senderId == _firebaseAuth.currentUser!.uid)
        ? Colors.blue
        : Colors.green;

    double screenWidth = MediaQuery.of(context).size.width;

    // Reverse the color of the email text based on the container color
    Color? emailTextColor = (color == Colors.blue)
        ? const Color.fromARGB(255, 255, 252, 252)
        : Colors.yellow[300];

    return Container(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisAlignment: (senderId == _firebaseAuth.currentUser!.uid)
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            // Only show the delete button for the sender
            if (senderId == _firebaseAuth.currentUser!.uid)
              GestureDetector(
                onTap: () {
                  deleteMessage(messageId);
                },
                child: Icon(
                  Icons.delete,
                  color: Colors.grey, // Color of the delete icon
                ),
              ),
            // Message Box
            SizedBox(
              width: 7,
            ),
            Container(
              constraints: BoxConstraints(
                maxWidth:
                    screenWidth * 0.75, // Set a max width for the message box
              ),
              decoration: BoxDecoration(
                color: color, // Set the container color (sender or receiver)
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(17), // Top-left rounded corner
                  topRight: Radius.circular(4), // Sharp top-right corner
                  bottomLeft: Radius.circular(4), // Sharp bottom-left corner
                  bottomRight:
                      Radius.circular(17), // Bottom-right rounded corner
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderEmail,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.bold,
                      color: emailTextColor, // Set the reversed color here
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.white,
                    ),
                    maxLines: null,
                    overflow: TextOverflow.visible,
                  ),
                  SizedBox(height: 1),
                  // Current Reaction Display
                  Row(
                    children: [
                      if (currentReaction.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            if (currentReaction.isNotEmpty) {
                              reactToMessage(messageId, ''); // Remove reaction
                            }
                          },
                          child: Text(
                            currentReaction,
                            style: TextStyle(fontSize: screenWidth * 0.038),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        formatTimestamp(timestamp),
                        style: TextStyle(
                          fontSize: screenWidth * 0.030,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(width: 20),
                      // Add reactions only for messages from others
                      if (senderId != _firebaseAuth.currentUser!.uid) ...[
                        GestureDetector(
                          onTap: () {
                            if (currentReaction == '❤️') {
                              reactToMessage(
                                  messageId, ''); // Remove love reaction
                            } else {
                              reactToMessage(
                                  messageId, '❤️'); // Add love reaction
                            }
                          },
                          child: Text('❤️'),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (currentReaction == '😂') {
                              reactToMessage(
                                  messageId, ''); // Remove haha reaction
                            } else {
                              reactToMessage(
                                  messageId, '😂'); // Add haha reaction
                            }
                          },
                          child: Text('😂'),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (currentReaction == '😞') {
                              reactToMessage(
                                  messageId, ''); // Remove sad reaction
                            } else {
                              reactToMessage(
                                  messageId, '😞'); // Add sad reaction
                            }
                          },
                          child: Text('😞'),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (currentReaction == '😢') {
                              reactToMessage(
                                  messageId, ''); // Remove cry reaction
                            } else {
                              reactToMessage(
                                  messageId, '😢'); // Add cry reaction
                            }
                          },
                          child: Text('😢'),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (currentReaction == '🙏') {
                              reactToMessage(
                                  messageId, ''); // Remove praying reaction
                            } else {
                              reactToMessage(
                                  messageId, '🙏'); // Add praying reaction
                            }
                          },
                          child: Text('🙏'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(_getChatRoomId())
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.receiverUserEmail,
          style: TextStyle(fontSize: 15),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04),
                  ),
                ),
                SizedBox(
                  width: 6,
                ),
                GestureDetector(
                  onTap: sendMessage,
                  child: Icon(
                    Icons.send,
                    size: MediaQuery.of(context).size.width * 0.08,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
