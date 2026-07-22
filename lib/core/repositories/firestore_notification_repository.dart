import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/notification_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/app_notification.dart';

class FirestoreNotificationRepository implements INotificationRepository {
  final FirebaseFirestore _firestore;

  FirestoreNotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<AppNotification>> watchNotifications(String uid) {
    if (uid.isEmpty) return Stream.value(const []);
    return _firestore
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<Result<void>> markAsRead(String uid, String notificationId) async {
    try {
      await _firestore
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .doc(notificationId)
          .update({"read": true});
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
