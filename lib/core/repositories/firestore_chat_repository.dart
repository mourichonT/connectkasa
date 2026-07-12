import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/chat_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/message.dart';

class FirestoreChatRepository implements IChatRepository {
  final FirebaseFirestore _firestore;

  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<void>> sendMessage(
    String senderId,
    String receiverId,
    String message,
    String residence,
  ) async {
    try {
      final Timestamp timestamp = Timestamp.now();

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
          .collection("residences")
          .doc(residence)
          .collection("chats")
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

      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Stream<Result<Message?>> getLastMessageBetweenUsers({
    required String residenceId,
    required String userA,
    required String userB,
  }) {
    List<String> ids = [userA, userB];
    ids.sort();
    String chatId = ids.join("_");

    return _firestore
        .collection('residences')
        .doc(residenceId)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map<Result<Message?>>((snapshot) {
      if (snapshot.docs.isEmpty) return const Result.success(null);
      return Result.success(Message.fromFirestore(snapshot.docs.first));
    }).handleError(
        (Object e) => Result<Message?>.failure(AppException.from(e)));
  }

  @override
  Stream<Result<QuerySnapshot>> getMessages(
    String userId,
    String otherUserId,
    String residence,
  ) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection("residences")
        .doc(residence)
        .collection("chats")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots()
        .map<Result<QuerySnapshot>>((snapshot) => Result.success(snapshot))
        .handleError(
            (Object e) => Result<QuerySnapshot>.failure(AppException.from(e)));
  }
}
