import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/firestore_paths.dart';
import 'package:connect_kasa/models/pages_models/agency.dart';
import 'package:connect_kasa/models/pages_models/agency_dept.dart';
import 'package:connect_kasa/models/pages_models/gerance_ref.dart';

class DatabasesAgencyServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  /// Recherche par préfixe d'email dans l'index Gerance/{id}/contacts,
  /// filtré par type de service ("serviceSyndic", "geranceLocative", ...).
  /// Cet index est généré automatiquement (Cloud Function sync_gerance_contacts)
  /// à partir du champ Gerance/{id}.services : jamais écrit à la main.
  Future<List<Agency>> searchByEmail(
      String emailPart, {
    required String serviceType,
  }) async {
    if (emailPart.isEmpty) return [];

    try {
      final contactsSnapshot = await db
          .collectionGroup(FirestorePaths.contacts)
          .where('serviceType', isEqualTo: serviceType)
          .where('mail', isGreaterThanOrEqualTo: emailPart)
          .where('mail', isLessThanOrEqualTo: '$emailPart')
          .limit(10)
          .get();

      if (contactsSnapshot.docs.isEmpty) return [];

      // Un même cabinet peut matcher plusieurs contacts (service + agents) ;
      // on ne relit chaque document Gerance parent qu'une seule fois.
      final geranceIds = contactsSnapshot.docs
          .map((doc) => doc.reference.parent.parent!.id)
          .toSet();
      final geranceDocs = await Future.wait(geranceIds
          .map((id) => db.collection(FirestorePaths.gerance).doc(id).get()));
      final geranceById = {
        for (final doc in geranceDocs)
          if (doc.exists) doc.id: doc.data()!
      };

      final results = <Agency>[];
      for (final contactDoc in contactsSnapshot.docs) {
        final geranceId = contactDoc.reference.parent.parent!.id;
        final geranceData = geranceById[geranceId];
        if (geranceData == null) continue; // cabinet supprimé entretemps

        final services = geranceData['services'] as Map<String, dynamic>?;
        final serviceData = services?[serviceType] as Map<String, dynamic>?;
        if (serviceData == null) continue;

        results.add(Agency(
          id: geranceId,
          name: geranceData['name'] ?? '',
          city: geranceData['city'] ?? '',
          numeros: geranceData['numeros'] ?? '',
          street: geranceData['street'] ?? '',
          voie: geranceData['voie'] ?? '',
          zipCode: geranceData['zipCode'] ?? '',
          syndic: AgencyDept.fromJson(serviceData),
        ));
      }
      return results;
    } catch (e) {
      print("Erreur recherche agence: $e");
      return [];
    }
  }

  /// Résout une référence enregistrée (GeranceRef) vers les données à jour
  /// du cabinet dans Gerance. Renvoie null si le cabinet ou le service
  /// référencé n'existe plus (supprimé côté référentiel entretemps).
  Future<Agency?> resolveRef(GeranceRef ref) async {
    try {
      final doc =
          await db.collection(FirestorePaths.gerance).doc(ref.geranceId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final services = data['services'] as Map<String, dynamic>?;
      final serviceData = services?[ref.serviceType] as Map<String, dynamic>?;
      if (serviceData == null) return null;

      String mail = serviceData['mail'] ?? '';
      String phone = serviceData['phone'] ?? '';
      final agentsJson =
          (serviceData['agents'] as List<dynamic>? ?? []).cast<dynamic>();

      if (ref.agentMail != null) {
        final agentJson = agentsJson.cast<Map<String, dynamic>>().firstWhere(
              (a) => a['mail'] == ref.agentMail,
              orElse: () => <String, dynamic>{},
            );
        if (agentJson.isNotEmpty) {
          mail = agentJson['mail'] ?? mail;
          phone = agentJson['phone'] ?? phone;
        }
      }

      return Agency(
        id: ref.geranceId,
        name: data['name'] ?? '',
        city: data['city'] ?? '',
        numeros: data['numeros'] ?? '',
        street: data['street'] ?? '',
        voie: data['voie'] ?? '',
        zipCode: data['zipCode'] ?? '',
        syndic: AgencyDept(
          agents: agentsJson
              .map((a) => Agent.fromJson(a as Map<String, dynamic>))
              .toList(),
          mail: mail,
          phone: phone,
        ),
      );
    } catch (e) {
      print("Erreur résolution GeranceRef: $e");
      return null;
    }
  }
}
