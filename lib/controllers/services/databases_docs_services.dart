import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';

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

  Future<List<DocumentModel>> getAllDocs(String residenceId) async {
    List<DocumentModel> docs = [];

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .doc(residenceId)
          .collection("documents_copro")
          .get();
      for (var docSnapshot in querySnapshot.docs) {
        // Convertir chaque document en objet Post
        docs.add(DocumentModel.fromJson(docSnapshot.data()));
      }
    } catch (e) {
      print("Error completing in getAllDocs: $e");
    }

    return docs;
  }

  Future<List<DocumentModel>> getDocByUser(
      String residenceId, String lotId, List<String> numUser) async {
    List<DocumentModel> docs = [];

    try {
      print("Début de la fonction getDocByUser");

      // Récupérer la référence de la collection "Residence"
      CollectionReference residenceRef =
          FirebaseFirestore.instance.collection("Residence");

      // Récupérer le document de la résidence spécifique
      DocumentReference residenceDocRef = residenceRef.doc(residenceId);

      // Récupérer la collection "lot" pour la résidence spécifique
      QuerySnapshot lotQuerySnapshot = await residenceDocRef
          .collection("lot")
          .where("refLot", isEqualTo: lotId)
          .get();

      // Parcourir chaque document de la collection "lot"
      for (QueryDocumentSnapshot lotDoc in lotQuerySnapshot.docs) {
        // Récupérer les documents de chaque lot et filtrer par "numUser"
        QuerySnapshot docQuerySnapshot = await lotDoc.reference
            .collection("documents")
            .where("destinataire", arrayContainsAny: numUser)
            .get();

        for (QueryDocumentSnapshot doc in docQuerySnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          DocumentModel document = DocumentModel.fromJson(data);
          docs.add(document);
        }
      }
    } catch (e) {
      print("Erreur dans getDocByUser : $e");
    }

    return docs;
  }
}
