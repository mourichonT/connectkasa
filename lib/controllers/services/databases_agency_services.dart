import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/agency.dart';

class DatabasesAgencyServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getDeptByRefId(
      String docId, String dept) async {
    List<DocumentSnapshot<Map<String, dynamic>>> deptDetails = [];

    try {
      CollectionReference geranceRef = db.collection("Gerance");

      await _getDeptRecursivelyByDocId(geranceRef, docId, dept, deptDetails);
    } catch (e) {
      print("Erreur lors de la récupération de la gérance : $e");
    }

    return deptDetails;
  }

  Future<void> _getDeptRecursivelyByDocId(
      CollectionReference collectionRef,
      String docId,
      String dept,
      List<DocumentSnapshot<Map<String, dynamic>>> deptDetails) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await collectionRef.get() as QuerySnapshot<Map<String, dynamic>>;

      for (QueryDocumentSnapshot<Map<String, dynamic>> doc
          in querySnapshot.docs) {
        if (doc.id == docId) {
          deptDetails.add(doc);
          // Optionnel : ajouter le parent si tu veux
          if (collectionRef.parent != null) {
            final parentDoc = await collectionRef.parent!.get();
            if (parentDoc.exists) deptDetails.add(parentDoc);
          }
        }

        // Appel récursif dans les sous-collections
        final subCollectionRef = doc.reference.collection(dept);
        await _getDeptRecursivelyByDocId(
            subCollectionRef, docId, dept, deptDetails);
      }
    } catch (e) {
      print("Erreur récursive : $e");
    }
  }

  Future<List<Agency>> searchAgencyByEmail(String emailPart) async {
    if (emailPart.isEmpty) return [];

    try {
      final querySnapshot = await db
          .collectionGroup('serviceSyndic')
          .where('mail', isGreaterThanOrEqualTo: emailPart)
          .where('mail', isLessThanOrEqualTo: emailPart + '\uf8ff')
          .limit(10)
          .get();

      List<Agency> results = [];

      for (final doc in querySnapshot.docs) {
        final parentRef = doc.reference.parent.parent;
        Map<String, dynamic>? parentData;

        if (parentRef != null) {
          final parentSnap = await parentRef.get();
          parentData = parentSnap.data() as Map<String, dynamic>?;
        }

        results.add(Agency(
          id: parentRef?.id ?? '',
          name: parentData?['name'] ?? '',
          city: parentData?['city'] ?? '',
          numeros: parentData?['numeros'] ?? '',
          street: parentData?['street'] ?? '',
          voie: parentData?['voie'] ?? '',
          zipCode: parentData?['zipCode'] ?? '',
        ));
      }
      print("AGENCE TROUVEE : ${results[0].name}");

      return results;
    } catch (e) {
      print("Erreur recherche agence: $e");
      return [];
    }
  }

  // Future<List<DocumentSnapshot<Map<String, dynamic>>>> getDeptByRefId(
  //     String refId, String dept) async {
  //   List<DocumentSnapshot<Map<String, dynamic>>> deptDetails =
  //       []; // Liste pour stocker les documents correspondants
  //   try {
  //     // Récupérer la référence de la collection "Gerance"
  //     CollectionReference geranceRef = db.collection("Gerance");

  //     // Appeler une fonction récursive pour parcourir les sous-collections
  //     await _getDeptRecursively(geranceRef, refId, dept, deptDetails);
  //   } catch (e) {
  //     print("Impossible de récupérer l'id $e");
  //   }
  //   return deptDetails;
  // }

  // Future<void> _getDeptRecursively(
  //     CollectionReference collectionRef,
  //     String refId,
  //     String dept,
  //     List<DocumentSnapshot<Map<String, dynamic>>> deptDetails) async {
  //   try {
  //     // Récupérer les documents de la collection actuelle
  //     QuerySnapshot<Map<String, dynamic>> querySnapshot =
  //         await collectionRef.get() as QuerySnapshot<Map<String, dynamic>>;

  //     // Parcourir chaque document de la collection actuelle
  //     for (QueryDocumentSnapshot<Map<String, dynamic>> doc
  //         in querySnapshot.docs) {
  //       // Vérifier si le champ "id" correspond à "refId"
  //       if (doc.data()['id'] == refId) {
  //         deptDetails.add(doc);
  //         // Récupérer le document parent
  //         DocumentSnapshot<Map<String, dynamic>> parentDoc =
  //             await collectionRef.parent!.get();
  //         deptDetails.add(parentDoc);
  //       }
  //     }

  //     // Parcourir chaque sous-collection de la collection actuelle
  //     for (QueryDocumentSnapshot<Map<String, dynamic>> doc
  //         in querySnapshot.docs) {
  //       // Si le document a une sous-collection
  //       if (doc.reference.collection(dept).id == dept) {
  //         // Appeler récursivement cette fonction pour cette sous-collection
  //         await _getDeptRecursively(
  //             doc.reference.collection(dept), refId, dept, deptDetails);
  //       }
  //     }
  //   } catch (e) {
  //     print("Impossible de récupérer l'id $e");
  //   }
  // }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getDeptByResidence(
      String refId) async {
    List<DocumentSnapshot<Map<String, dynamic>>> deptDetails = [];
    try {
      // Récupérer la référence de la collection "Gerance"
      QuerySnapshot<Map<String, dynamic>> residenceRef = db
          .collection("Residence")
          .where('id', isEqualTo: refId)
          .get() as QuerySnapshot<Map<String, dynamic>>;

      for (QueryDocumentSnapshot<Map<String, dynamic>> doc
          in residenceRef.docs) {
        deptDetails.add(doc);
      }
    } catch (e) {
      print(
          'Une erreur s\'est produite lors de la récupération de la residence: $e');
      // Vous pouvez choisir de renvoyer une liste vide ou de lancer l'erreur
      throw Exception('Impossible de récupérer la résidence');
    }

    return deptDetails;
  }
}
