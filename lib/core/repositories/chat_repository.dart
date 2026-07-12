import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/message.dart';

/// Remplace ChatServices (Phase 2 du chantier architecture).
abstract interface class IChatRepository {
  Future<Result<void>> sendMessage(
    String senderId,
    String receiverId,
    String message,
    String residence,
  );

  Stream<Result<Message?>> getLastMessageBetweenUsers({
    required String residenceId,
    required String userA,
    required String userB,
  });

  Stream<Result<QuerySnapshot>> getMessages(
    String userId,
    String otherUserId,
    String residence,
  );
}
