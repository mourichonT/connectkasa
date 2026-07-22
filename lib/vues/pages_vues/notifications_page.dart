import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/notification_navigation.dart';
import 'package:konodal/core/providers/notification_providers.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/app_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

class NotificationsPage extends ConsumerWidget {
  final String uid;

  const NotificationsPage({super.key, required this.uid});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return MyTextStyle.completDate(timestamp);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
            'Notifications', Colors.black87, SizeFont.h1.size),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (error, stackTrace) => Center(child: Text('Erreur: $error')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text("Aucune notification pour le moment"),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: notifications.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Colors.black12),
            itemBuilder: (context, index) {
              final AppNotification notification = notifications[index];
              return ListTile(
                tileColor: notification.read
                    ? null
                    : Theme.of(context).primaryColor.withValues(alpha: 0.06),
                leading: Icon(
                  notification.type == 'demande_loc'
                      ? Icons.key_outlined
                      : Icons.campaign_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                title: MyTextStyle.lotName(
                    notification.title,
                    Colors.black87,
                    SizeFont.h3.size,
                    notification.read ? FontWeight.normal : FontWeight.bold),
                subtitle: Text(notification.body),
                trailing: Text(
                  _formatDate(notification.createdAt),
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
                onTap: () => openNotificationTarget(context, uid, notification),
              );
            },
          );
        },
      ),
    );
  }
}
