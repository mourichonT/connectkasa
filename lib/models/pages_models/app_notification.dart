import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification persistée (users/{uid}/notifications/{id}), écrite
/// uniquement par les Cloud Functions (functions/index.js) en plus du push
/// FCM déjà envoyé - jamais par l'app, sauf pour marquer "read".
class AppNotification {
  final String id;
  final String type; // "post" | "demande_loc"
  final String title;
  final String body;
  final bool read;
  final Timestamp? createdAt;
  final String? residenceId;
  final String? postId;
  final String? postType;
  final String? tenantId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    this.createdAt,
    this.residenceId,
    this.postId,
    this.postType,
    this.tenantId,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      read: map['read'] ?? false,
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'] : null,
      residenceId: map['residenceId'],
      postId: map['postId'],
      postType: map['postType'],
      tenantId: map['tenantId'],
    );
  }
}
