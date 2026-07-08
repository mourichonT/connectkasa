import 'package:connect_kasa/core/repositories/auth_repository.dart';
import 'package:connect_kasa/core/repositories/firebase_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return FirebaseAuthRepository();
});
