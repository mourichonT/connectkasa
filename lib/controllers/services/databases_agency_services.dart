import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/agency_dept.dart';

class DatabasesAgencyServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getDeptByRefId(
      String refId, String dept) async {
    List<DocumentSnapshot<Map<String, dynamic>>> deptDetails =
        []; // Liste pour stocker les documents correspondants
    try {
      // Récupérer la référence de la collection "Gerance"
      CollectionReference geranceRef = db.collection("Gerance");

      // Appeler une fonction récursive pour parcourir les sous-collections
      await _getDeptRecursively(geranceRef, refId, dept, deptDetails);
    } catch (e) {
      print("Impossible de récupérer l'id $e");
    }
    return deptDetails;
  }

  Future<void> _getDeptRecursively(
      CollectionReference collectionRef,
      String refId,
      String dept,
      List<DocumentSnapshot<Map<String, dynamic>>> deptDetails) async {
    try {
      // Récupérer les documents de la collection actuelle
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await collectionRef.get() as QuerySnapshot<Map<String, dynamic>>;

      // Parcourir chaque document de la collection actuelle
      for (QueryDocumentSnapshot<Map<String, dynamic>> doc
          in querySnapshot.docs) {
        // Vérifier si le champ "id" correspond à "refId"
        if (doc.data()['id'] == refId) {
          deptDetails.add(doc);
          // Récupérer le document parent
          DocumentSnapshot<Map<String, dynamic>> parentDoc =
              await collectionRef.parent!.get();
          deptDetails.add(parentDoc);
        }
      }

      // Parcourir chaque sous-collection de la collection actuelle
      for (QueryDocumentSnapshot<Map<String, dynamic>> doc
          in querySnapshot.docs) {
        // Si le document a une sous-collection
        if (doc.reference.collection(dept).id == dept) {
          // Appeler récursivement cette fonction pour cette sous-collection
          await _getDeptRecursively(
              doc.reference.collection(dept), refId, dept, deptDetails);
        }
      }
    } catch (e) {
      print("Impossible de récupérer l'id $e");
    }
  }
}
