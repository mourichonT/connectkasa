import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/agency_dept.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

Future<AgencyDept?> getDeptByRefId(String refId) async {
  AgencyDept? deptDetails; // Déclarer comme nullable
  try {
    // Récupérer la référence de la collection "Gerance"
    CollectionReference geranceRef = db.collection("Gerance");

    // Récupérer les documents de la collection "Gerance"
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await geranceRef.get() as QuerySnapshot<Map<String, dynamic>>;

    // Parcourir chaque document de la collection "Gerance"
    for (QueryDocumentSnapshot<Map<String, dynamic>> geranceDoc
        in querySnapshot.docs) {
      // Vérifier si le champ "ref" correspond
      if (geranceDoc.data()['ref'] == refId) {
        // Récupérer les depts de chaque résidence
        QuerySnapshot<Map<String, dynamic>> deptQuerySnapshot =
            await geranceDoc.reference.collection("dept").get();

        // Récupérer les données du document de la résidence
        Map<String, dynamic> geranceData = geranceDoc.data();
        // Utiliser les données récupérées pour construire ou mettre à jour deptDetails
        // Exemple :
        // deptDetails = AgencyDept.fromMap(geranceData);

        // Break out de la boucle si le document correspondant est trouvé
        break;
      }
    }
  } catch (e) {
    print("Impossible de récupérer l'id $e");
  }
  return deptDetails;
}
