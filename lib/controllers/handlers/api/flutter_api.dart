import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/pages_controllers/tenant_controller.dart';
import 'package:connect_kasa/main.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/vues/pages_vues/manage_app/tenant_detail.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static const String _vapidKey =
      "BG_OprJybgUBAf865Blg9KlRh9WYVpcavQVgSLbAgp7qW1GI8ETEVmsFlYADOOS4nhWefnG1kbLLriCT6JCY6Qw";

  Future<void> initNotification(BuildContext context) async {
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _firebaseMessaging.getToken(vapidKey: _vapidKey);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      try {
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
        } else if (data['type'] == 'demande_loc') {
          final tenantId = data['tenantId'];
          final senderUid = data['senderUid'];

          if (tenantId != null && senderUid != null) {
            final userDoc = await FirebaseFirestore.instance
                .collection('User')
                .doc(tenantId)
                .get();
            if (!userDoc.exists) return;

            final tenant = UserInfo.fromMap(userDoc.data()!);

            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => TenantController(
                  tenant: tenant,
                  uid: senderUid,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('Erreur lors du traitement de la notification : $e');
      }
    });
  }

  static Future<String?> getToken() async {
    return FirebaseMessaging.instance.getToken(vapidKey: _vapidKey);
  }
}
