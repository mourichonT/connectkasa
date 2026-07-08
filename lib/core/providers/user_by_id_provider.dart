import 'package:connect_kasa/core/providers/current_user_provider.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Utilisateur par uid, mis en cache et partagé par tous les widgets qui
/// consomment le même uid (ProfilTile, tuiles de commentaires/chat...).
/// Deux tuiles affichant le même auteur ne déclenchent qu'UNE lecture
/// Firestore (partagée), au lieu d'une par tuile.
final userByIdProvider =
    FutureProvider.family<User?, String>((ref, uid) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository
      .getUserById(uid)
      .then((result) => result.when(success: (v) => v, failure: (_) => null));
});
