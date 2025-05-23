import 'package:cloud_firestore/cloud_firestore.dart';

class ChatController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getChatInfo({
    required String residenceId,
    required String idUserFrom,
    required String otherUserId,
    required String chatId,
  }) async {
    try {
      // L'ID du chat peut être une combinaison des deux uids
      //final chatId = generateChatId(idUserFrom, otherUserId);

      final chatDoc = await _firestore
          .collection("Residence")
          .doc(residenceId)
          .collection("chat")
          .doc(chatId)
          .get();

      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        final unreadMessages = idUserFrom == data["from_id"]
            ? (data["from_msg_num"] ?? 0)
            : (data["to_msg_num"] ?? 0);

        return {
          "last_msg": data["last_msg"] ?? "",
          "last_time": data["last_time"],
          "unread_count": unreadMessages,
        };
      } else {
        return null;
      }
    } catch (e) {
      print("Erreur dans getChatInfo: $e");
      return null;
    }
  }

  static Future<void> clearMessage({
    required String userId,
    required String otherUserId,
    required String residence,
  }) async {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    String champAAffacer = (ids[0] == userId) ? "to_msg_num" : "from_msg_num";

    final docRef = FirebaseFirestore.instance
        .collection("Residence")
        .doc(residence)
        .collection("chat")
        .doc(chatRoomId);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.update({champAAffacer: 0});
    } else {
      // Crée le document avec la valeur souhaitée
      await docRef.set({champAAffacer: 0}, SetOptions(merge: true));
    }
  }

  String generateChatId(String uid1, String uid2) {
    // Tri pour garder un ordre stable
    final sorted = [uid1, uid2]..sort();
    return sorted.join("_");
  }

  Stream<Map<String, dynamic>?> chatInfoStream({
    required String residenceId,
    required String chatId,
  }) {
    return FirebaseFirestore.instance
        .collection("Residence")
        .doc(residenceId)
        .collection("chat")
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data()!;
      return {
        "last_msg": data["last_msg"] ?? "",
        "last_time": data["last_time"],
        "from_id": data["from_id"],
        "to_id": data["to_id"],
        "from_msg_num": data["from_msg_num"] ?? 0,
        "to_msg_num": data["to_msg_num"] ?? 0,
      };
    });
  }
}
