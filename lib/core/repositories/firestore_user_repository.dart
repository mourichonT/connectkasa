import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/core/errors/app_exceptions.dart';
import 'package:connect_kasa/core/repositories/user_repository.dart';
import 'package:connect_kasa/core/result/result.dart';
import 'package:connect_kasa/models/pages_models/user.dart';

class FirestoreUserRepository implements IUserRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<User>> getUserById(String uid) async {
    try {
      final snapshot = await _firestore.collection('User').doc(uid).get();

      if (!snapshot.exists || snapshot.data() == null) {
        return Result.failure(
            NotFoundException('Utilisateur $uid introuvable'));
      }

      return Result.success(User.fromMap(snapshot.data()!));
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Stream<Result<User>> watchUserById(String uid) {
    return _firestore.collection('User').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return Result<User>.failure(
            NotFoundException('Utilisateur $uid introuvable'));
      }
      return Result.success(User.fromMap(snapshot.data()!));
    }).handleError((Object e) => Result<User>.failure(AppException.from(e)));
  }
}
