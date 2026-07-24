import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/services/firestore_paths.dart';
import 'package:konodal/models/pages_models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nom de la gérance (cabinet) à laquelle appartient un compte agent/agence,
/// pour l'affichage strict "{prenom}\n{nomAgence}" / "{nomAgence}" - un
/// agent peut être rattaché au service syndic ou à la gérance locative (ou
/// les deux en théorie), d'où les deux requêtes. En flux (pas un simple
/// .get()) : un renommage du cabinet fait depuis le BO ne se répercutait
/// jamais dans l'app tant qu'elle n'était pas totalement relancée (Future
/// mis en cache indéfiniment par Riverpod, jamais invalidé).
final agentAgencyNameProvider =
    StreamProvider.family<String?, String>((ref, uid) {
  final firestore = FirebaseFirestore.instance;
  final controller = StreamController<String?>();
  QuerySnapshot<Map<String, dynamic>>? syndicSnap;
  QuerySnapshot<Map<String, dynamic>>? locativeSnap;

  String? nameFrom(QuerySnapshot<Map<String, dynamic>>? snap) {
    if (snap == null || snap.docs.isEmpty) return null;
    final name = snap.docs.first.data()['name'];
    return (name is String && name.isNotEmpty) ? name : null;
  }

  void emit() {
    if (controller.isClosed) return;
    controller.add(nameFrom(syndicSnap) ?? nameFrom(locativeSnap));
  }

  final sub1 = firestore
      .collection(FirestorePaths.gerance)
      .where('serviceSyndicAgentUids', arrayContains: uid)
      .limit(1)
      .snapshots()
      .listen((snap) {
    syndicSnap = snap;
    emit();
  });
  final sub2 = firestore
      .collection(FirestorePaths.gerance)
      .where('geranceLocativeAgentUids', arrayContains: uid)
      .limit(1)
      .snapshots()
      .listen((snap) {
    locativeSnap = snap;
    emit();
  });

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Nom à afficher pour l'auteur d'un post/commentaire/like : un compte
/// agent/agence (backoffice, invite_agency_account) n'a jamais de pseudo ni
/// de nom complet renseigné - affichage strict sur 2 lignes "{prenom}\n
/// {nomAgence}" pour un agent (le "\n" plutôt qu'un "{prenom} - {nomAgence}"
/// sur une seule ligne évite le débordement horizontal constaté avec des
/// noms de cabinet longs, ex: "Théophile" / "CABINET PECOUL IMMOBILIER"),
/// "{nomAgence}" seul pour l'agence (pas une personne précise). Pour un
/// résident, [residentDisplayName] reste inchangé - ce helper ne fait que
/// court-circuiter le cas professionnel. Le rendu (maxLines/overflow) reste
/// à la charge de l'appelant.
String displayNameFor(
  WidgetRef ref,
  User user,
  String Function(User user) residentDisplayName,
) {
  if (user.accountType == 'agent' || user.accountType == 'agence') {
    final agencyName =
        ref.watch(agentAgencyNameProvider(user.uid)).valueOrNull ?? '';
    if (user.accountType == 'agence') {
      return agencyName.isNotEmpty ? agencyName : user.name;
    }
    return agencyName.isNotEmpty ? '${user.name}\n$agencyName' : user.name;
  }
  return residentDisplayName(user);
}
