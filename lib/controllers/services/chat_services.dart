import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/message.dart';
import 'package:flutter/material.dart';

class ChatServices extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //SEND MESSAGE

  Future<void> sendMessage(String senderId, String receiverId, String message,
      String residence) async {
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
        message: message,
        userIdFrom: senderId,
        userIdTo: receiverId,
        timestamp: timestamp);

    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");
    await _firestore
        .collection("Residence")
        .doc(residence)
        .collection("chat")
        .doc(chatRoomId)
        .collection("messages")
        .add(newMessage.toMap());
  }
  // GET MESSAGE

  Stream<QuerySnapshot> getMessages(
    String userId,
    String otherUserId,
    String residence,
  ) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection("Residence")
        .doc(residence)
        .collection("chat")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }
}
