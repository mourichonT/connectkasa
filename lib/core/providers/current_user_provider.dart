import 'package:connect_kasa/core/repositories/firestore_user_repository.dart';
import 'package:connect_kasa/core/repositories/user_repository.dart';
import 'package:connect_kasa/core/result/result.dart';
import 'package:connect_kasa/models/pages_models/user.dart' as app_user;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  return FirestoreUserRepository();
});

final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Utilisateur connecté (document User/{uid}), mis à jour en temps réel.
/// `null` tant qu'aucun utilisateur n'est authentifié.
///
/// Fondation posée ici (Phase 1) mais pas encore câblée dans les écrans
/// existants (Phase 2/3) : ceux-ci continuent d'utiliser
/// DataBasesUserServices.getUserById() jusqu'à leur migration.
final currentUserProvider = StreamProvider<Result<app_user.User>?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);

  return authState.when(
    data: (firebaseUser) {
      if (firebaseUser == null) {
        return Stream<Result<app_user.User>?>.value(null);
      }
      final repository = ref.watch(userRepositoryProvider);
      return repository.watchUserById(firebaseUser.uid);
    },
    loading: () => Stream<Result<app_user.User>?>.value(null),
    error: (error, stackTrace) => Stream<Result<app_user.User>?>.value(null),
  );
});
