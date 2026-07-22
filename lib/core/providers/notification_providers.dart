import 'package:konodal/core/repositories/notification_repository.dart';
import 'package:konodal/core/repositories/firestore_notification_repository.dart';
import 'package:konodal/models/pages_models/app_notification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return FirestoreNotificationRepository();
});

/// Notifications de l'utilisateur courant, triées récent -> ancien. La
/// cloche (my_nav_bar.dart) dérive sa pastille de ce même flux
/// (any((n) => !n.read)) plutôt que d'écouter un flux séparé.
final notificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, uid) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchNotifications(uid);
});
