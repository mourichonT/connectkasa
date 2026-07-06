import 'package:firebase_auth/firebase_auth.dart';

/// Erreurs applicatives typées, pour remplacer le mélange actuel de
/// print+null / print+false / rethrow / catch silencieux selon les
/// fichiers de services. Portées par [Result.failure] plutôt que
/// propagées comme des Object bruts.
sealed class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, {this.cause});

  @override
  String toString() => '$runtimeType: $message';

  /// Convertit une erreur brute (FirebaseException, etc.) en AppException
  /// typée. Les repositories catchent l'erreur d'origine et appellent ceci
  /// avant de la porter dans un Result.failure.
  factory AppException.from(Object error) {
    if (error is AppException) return error;

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return PermissionDeniedException(
              error.message ?? 'Accès refusé', cause: error);
        case 'not-found':
          return NotFoundException(
              error.message ?? 'Ressource introuvable', cause: error);
        case 'unavailable':
        case 'network-request-failed':
        case 'deadline-exceeded':
          return NetworkException(
              error.message ?? 'Problème réseau', cause: error);
        default:
          return UnknownException(
              error.message ?? 'Erreur Firestore inattendue', cause: error);
      }
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'network-request-failed':
          return NetworkException(
              error.message ?? 'Problème réseau', cause: error);
        case 'user-not-found':
          return NotFoundException(
              error.message ?? 'Utilisateur introuvable', cause: error);
        default:
          return UnknownException(
              error.message ?? 'Erreur d\'authentification inattendue',
              cause: error);
      }
    }

    return UnknownException(error.toString(), cause: error);
  }
}

final class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}

final class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message, {super.cause});
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

final class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause});
}
