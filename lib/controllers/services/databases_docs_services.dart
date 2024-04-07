import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';

class DataBasesDocsServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<DocumentModel> setDocument(DocumentModel newDoc, String userId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection("UserTemp")
              .where("uid", isEqualTo: userId)
              .get();

      // Vérifier si un utilisateur correspondant à l'ID existe
      if (querySnapshot.docs.isNotEmpty) {
        // Récupérer le premier document correspondant trouvé
        DocumentSnapshot<Map<String, dynamic>> userDoc =
            querySnapshot.docs.first;

        // Ajouter le nouveau document à la collection "documents" de l'utilisateur
        await userDoc.reference.collection("documents").add(newDoc.toJson());
      }
    } catch (e) {
      // Afficher une erreur en cas d'échec
      print("Impossible d'ajouter le nouveau document: $e");
    }

    // Retourner le nouveau document, même s'il n'a pas été ajouté à la base de données
    return newDoc;
  }
}
