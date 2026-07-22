import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/app_notification.dart';

abstract interface class INotificationRepository {
  /// Notifications de l'utilisateur, triées de la plus récente à la plus
  /// ancienne. Le badge (pastille non-lu) se dérive de ce même flux côté UI.
  Stream<List<AppNotification>> watchNotifications(String uid);

  Future<Result<void>> markAsRead(String uid, String notificationId);
}
