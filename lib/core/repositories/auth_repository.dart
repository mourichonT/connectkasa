import 'package:connect_kasa/core/result/result.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Remplace AuthentificationService (Phase 2 du chantier architecture) :
/// mêmes opérations, mais `Result<T>` au lieu d'exceptions jetées, suivant
/// le patron posé par IUserRepository en Phase 1.
abstract interface class IAuthRepository {
  Future<Result<UserCredential>> signInWithGoogle();
  Future<Result<UserCredential>> signUpWithGoogle();
  Future<Result<void>> signOutWithGoogle();
}
