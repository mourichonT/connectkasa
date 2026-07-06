import 'package:connect_kasa/core/result/result.dart';
import 'package:connect_kasa/models/pages_models/user.dart';

/// Premier exemple de référence pour la convention XxxRepository
/// (Phase 2 du chantier architecture : renommer et unifier les services
/// existants sur ce modèle — méthodes d'instance, injection de
/// dépendance, `Result<T>` au lieu de print+null/print+false).
abstract interface class IUserRepository {
  Future<Result<User>> getUserById(String uid);

  /// Flux temps réel du document User/{uid} (utilisé par le provider
  /// Riverpod de l'utilisateur connecté).
  Stream<Result<User>> watchUserById(String uid);
}
