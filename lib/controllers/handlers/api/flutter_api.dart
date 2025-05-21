import 'package:connect_kasa/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi {
  // Instance de Firebase Messaging
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    // Demande la permission de l'utilisateur (nécessaire sur iOS et Android 13+)
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Récupère le token FCM de l'appareil
      final fcmToken = await _firebaseMessaging.getToken(
          vapidKey:
              "BG_OprJybgUBAf865Blg9KlRh9WYVpcavQVgSLbAgp7qW1GI8ETEVmsFlYADOOS4nhWefnG1kbLLriCT6JCY6Qw");
      print('Token : $fcmToken');
    } else {
      print('Permission de notification refusée.');
    }

    // Gérer les messages en arrière-plan, premier lancement ou en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message reçu en foreground : ${message.notification?.title}');
    });
// permet l'ouverture a l'endroit de la notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final data = message.data;

      if (data['type'] == 'message') {
        final idUserFrom = data['idUserFrom'];
        final idUserTo = data['idUserTo'];
        final residence = data['residenceId'];

        if (idUserFrom != null && idUserTo != null && residence != null) {
          navigatorKey.currentState?.pushNamed(
            '/ChatPage',
            arguments: {
              'idUserFrom': idUserFrom,
              'idUserTo': idUserTo,
              'residence': residence,
            },
          );
        }
      }
    });
  }

  static Future<String?> getToken() async {
    return FirebaseMessaging.instance.getToken(
        vapidKey:
            "BG_OprJybgUBAf865Blg9KlRh9WYVpcavQVgSLbAgp7qW1GI8ETEVmsFlYADOOS4nhWefnG1kbLLriCT6JCY6Qw");
  }
}
