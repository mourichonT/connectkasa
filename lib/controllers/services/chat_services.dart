import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/message.dart';
import 'package:flutter/material.dart';

class ChatServices extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getTokenFromUserId(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    if (doc.exists) {
      return doc.data()?['token'];
    }
    return null;
  }

  Future<void> sendMessage(
    String senderId,
    String receiverId,
    String message,
    String residence,
  ) async {
    final Timestamp timestamp = Timestamp.now();

    // Crée le message
    Message newMessage = Message(
      message: message,
      userIdFrom: senderId,
      userIdTo: receiverId,
      timestamp: timestamp,
    );

    // Crée le chatId trié pour cohérence
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatId = ids.join("_");

    final chatDocRef = _firestore
        .collection("Residence")
        .doc(residence)
        .collection("chat")
        .doc(chatId);

    // Ajoute le message dans la sous-collection
    await chatDocRef.collection("messages").add(newMessage.toMap());

    // Récupère les données du document de chat
    final chatSnapshot = await chatDocRef.get();

    int fromMsgNum = 0;
    int toMsgNum = 0;

    if (chatSnapshot.exists) {
      final data = chatSnapshot.data()!;
      fromMsgNum = data["from_msg_num"] ?? 0;
      toMsgNum = data["to_msg_num"] ?? 0;

      if (senderId == data["from_id"]) {
        toMsgNum += 1;
      } else {
        fromMsgNum += 1;
      }

      await chatDocRef.update({
        "last_msg": message,
        "last_time": timestamp,
        "from_msg_num": fromMsgNum,
        "to_msg_num": toMsgNum,
      });
    } else {
      // Nouveau chat : initialisation
      await chatDocRef.set({
        "from_id": senderId,
        "to_id": receiverId,
        "from_msg_num": 0,
        "to_msg_num": 1,
        "last_msg": message,
        "last_time": timestamp,
      });
    }
  }

  static Stream<Message?> getLastMessageBetweenUsers({
    required String residenceId,
    required String userA,
    required String userB,
  }) {
    List<String> ids = [userA, userB];
    ids.sort();
    String chatId = ids.join("_");

    return FirebaseFirestore.instance
        .collection('Residence')
        .doc(residenceId)
        .collection('chat')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return Message.fromFirestore(snapshot.docs.first);
    });
  }

  // // GET MESSAGE
  // static Stream<Message?> getLastMessageBetweenUsers({
  //   required String residenceId,
  //   required String userA,
  //   required String userB,
  // }) {
  //   return FirebaseFirestore.instance
  //       .collection('residences')
  //       .doc(residenceId)
  //       .collection('messages')
  //       .where('participants', arrayContainsAny: [userA, userB])
  //       .orderBy('timestamp', descending: true)
  //       .limit(1)
  //       .snapshots()
  //       .map((snapshot) {
  //         if (snapshot.docs.isEmpty) return null;
  //         return Message.fromFirestore(snapshot.docs.first);
  //       });
  // }

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
