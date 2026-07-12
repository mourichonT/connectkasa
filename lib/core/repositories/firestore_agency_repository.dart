import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/services/firestore_paths.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/agency_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/agency.dart';
import 'package:konodal/models/pages_models/agency_dept.dart';
import 'package:konodal/models/pages_models/gerance_ref.dart';

class FirestoreAgencyRepository implements IAgencyRepository {
  final FirebaseFirestore _firestore;

  FirestoreAgencyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<List<Agency>>> searchByEmail(
    String emailPart, {
    required String serviceType,
  }) async {
    if (emailPart.isEmpty) return const Result.success([]);

    try {
      // Recherche par sous-chaîne (n'importe où dans le mail, pas seulement
      // en préfixe) dans l'index gerances/{id}/contacts, filtré par type de
      // service ("serviceSyndic", "geranceLocative", ...). Même approche que
      // rechercheFirestore (recherche de résidence à l'inscription) :
      // Firestore ne fait pas de recherche par sous-chaîne nativement, donc
      // on filtre côté client après récupération par serviceType. Cet index
      // est généré automatiquement (Cloud Function sync_gerance_contacts) à
      // partir du champ gerances/{id}.services : jamais écrit à la main.
      final contactsSnapshot = await _firestore
          .collectionGroup(FirestorePaths.contacts)
          .where('serviceType', isEqualTo: serviceType)
          .get();

      final matchingDocs = contactsSnapshot.docs.where((doc) {
        final mail = (doc.data()['mail'] as String?)?.toLowerCase() ?? '';
        return mail.contains(emailPart.toLowerCase());
      }).toList();

      if (matchingDocs.isEmpty) return const Result.success([]);

      // Un même cabinet peut matcher plusieurs contacts (service + agents) ;
      // on ne relit chaque document gerances parent qu'une seule fois.
      final geranceIds =
          matchingDocs.map((doc) => doc.reference.parent.parent!.id).toSet();
      final geranceDocs = await Future.wait(geranceIds.map(
          (id) => _firestore.collection(FirestorePaths.gerance).doc(id).get()));
      final geranceById = {
        for (final doc in geranceDocs)
          if (doc.exists) doc.id: doc.data()!
      };

      final results = <Agency>[];
      for (final contactDoc in matchingDocs) {
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
      return Result.success(results);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<Agency?>> resolveRef(GeranceRef ref) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.gerance)
          .doc(ref.geranceId)
          .get();
      if (!doc.exists) return const Result.success(null);

      final data = doc.data()!;
      final services = data['services'] as Map<String, dynamic>?;
      final serviceData = services?[ref.serviceType] as Map<String, dynamic>?;
      if (serviceData == null) return const Result.success(null);

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

      return Result.success(Agency(
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
      ));
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
