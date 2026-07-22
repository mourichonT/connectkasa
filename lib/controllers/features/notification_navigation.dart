import 'dart:async';

import 'package:konodal/core/repositories/firestore_post_repository.dart';
import 'package:konodal/core/repositories/post_repository.dart';
import 'package:konodal/core/repositories/notification_repository.dart';
import 'package:konodal/core/repositories/firestore_notification_repository.dart';
import 'package:konodal/models/pages_models/app_notification.dart';
import 'package:konodal/models/pages_models/user_info.dart';
import 'package:konodal/controllers/pages_controllers/tenant_controller.dart';
import 'package:konodal/vues/pages_vues/annonces_page/annonce_page_details.dart';
import 'package:konodal/vues/pages_vues/event_page/event_page_details.dart';
import 'package:konodal/vues/pages_vues/post_page/communication_detail.dart';
import 'package:konodal/vues/pages_vues/post_page/post_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Marque [notification] comme lue puis ouvre sa cible :
/// - "demande_loc" : même navigation que FirebaseApi.onMessageOpenedApp pour
///   ce type (flutter_api.dart), pour rester cohérent avec le tap sur le
///   push système.
/// - "post" : résout le post via son id métier (fiable depuis le correctif
///   addPost de cette session - il correspond désormais toujours à l'id du
///   doc Firestore) puis bascule sur la page de détail selon son type. Post
///   introuvable (supprimé entre-temps...) : ne fait rien, pas de crash.
Future<void> openNotificationTarget(
  BuildContext context,
  String uid,
  AppNotification notification,
) async {
  final INotificationRepository notifRepo = FirestoreNotificationRepository();
  unawaited(notifRepo.markAsRead(uid, notification.id));

  if (notification.type == 'demande_loc') {
    final tenantId = notification.tenantId;
    if (tenantId == null || tenantId.isEmpty) return;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(tenantId).get();
    if (!userDoc.exists || !context.mounted) return;
    final tenant = UserInfo.fromMap(userDoc.data()!);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TenantController(
          tenant: tenant,
          uid: uid,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
    return;
  }

  if (notification.type == 'post') {
    final residenceId = notification.residenceId;
    final postId = notification.postId;
    final postType = notification.postType ?? '';
    if (residenceId == null || postId == null) return;

    final IPostRepository postRepo = FirestorePostRepository();
    final post = await postRepo
        .getPost(residenceId, postId)
        .then((result) => result.when(success: (v) => v, failure: (_) => null));
    if (post == null || !context.mounted) return;

    final colorStatut = Theme.of(context).primaryColor;
    switch (postType) {
      case 'sinistres':
      case 'incivilites':
      case 'rapport':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostView(
              postOrigin: post,
              residence: residenceId,
              uid: uid,
              postSelected: post,
              returnHomePage: false,
            ),
          ),
        );
        break;
      case 'events':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventPageDetails(
              post: post,
              uid: uid,
              residence: residenceId,
              colorStatut: colorStatut,
              scrollController: 0,
              returnHomePage: false,
            ),
          ),
        );
        break;
      case 'annonces':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnnoncePageDetails(
              post: post,
              uid: uid,
              residence: residenceId,
              colorStatut: colorStatut,
              returnHomePage: false,
            ),
          ),
        );
        break;
      case 'communication':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommunicationDetails(
              post: post,
              uid: uid,
              residenceId: residenceId,
            ),
          ),
        );
        break;
    }
  }
}
