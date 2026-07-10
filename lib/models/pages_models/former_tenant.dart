import 'package:cloud_firestore/cloud_firestore.dart';

/// Un ancien locataire d'un lot (Lot.idLocataireOld), conservé pour
/// l'historique affiché dans "Gestion des locataires" -> onglet
/// "Historique". Écrit une fois, jamais modifié après coup - une nouvelle
/// entrée est ajoutée à chaque révocation, même si le même uid revient
/// plus tard (deux passages distincts, deux entrées distinctes).
class FormerTenant {
  final String uid;
  final Timestamp leftAt;

  FormerTenant({required this.uid, required this.leftAt});

  factory FormerTenant.fromMap(Map<String, dynamic> map) {
    return FormerTenant(
      uid: map['uid'] ?? '',
      leftAt: map['leftAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'leftAt': leftAt,
    };
  }
}
