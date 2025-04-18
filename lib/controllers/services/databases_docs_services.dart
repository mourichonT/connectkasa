import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';

class DataBasesDocsServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<DocumentModel> setDocument(
      DocumentModel newDoc, String userId, String lotId) async {
    final List<String> idType = TypeList.idTypes;

    try {
      if (idType.contains(newDoc.type)) {
        // ➤ Cas ID : stocké dans User/{userId}/documents
        DocumentReference<Map<String, dynamic>> userDocRef =
            db.collection("User").doc(userId);

        await userDocRef.collection("documents").add(newDoc.toJson());
        print("Document ID ajouté avec succès dans User/{userId}/documents !");
      } else {
        // ➤ Cas non-ID : stocké dans User/{userId}/Lots/{lotId}/documents
        DocumentReference<Map<String, dynamic>> userLotRef =
            db.collection("User").doc(userId).collection("lots").doc(lotId);

        await userLotRef.collection("documents").add(newDoc.toJson());
      }
    } catch (e) {
      print("Erreur lors de l'ajout du document : $e");
    }

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
