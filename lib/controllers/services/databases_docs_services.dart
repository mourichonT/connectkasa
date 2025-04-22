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

  Future<List<Map<String, dynamic>>> getAllDocsWithId(
      String residenceId) async {
    List<Map<String, dynamic>> docs = [];

    try {
      final querySnapshot = await db
          .collection("Residence")
          .doc(residenceId)
          .collection("documents_copro")
          .get();

      for (var docSnapshot in querySnapshot.docs) {
        docs.add({
          "data": DocumentModel.fromJson(docSnapshot.data()),
          "id": docSnapshot.id,
        });
      }
    } catch (e) {
      print("Erreur getAllDocsWithId: $e");
    }

    return docs;
  }

  Future<List<Map<String, dynamic>>> getDocByUser(
      String uid, String refLot) async {
    print("REFLOT: $refLot");
    print("UID: $uid");

    List<Map<String, dynamic>> docs = [];

    try {
      print("Début de la fonction getDocByUser");

      // Référence à la collection de documents du lot spécifique de l'utilisateur
      CollectionReference documentsRef = FirebaseFirestore.instance
          .collection("User")
          .doc(uid)
          .collection("lots")
          .doc(refLot)
          .collection("documents");

      // Récupération de tous les documents sans filtre
      QuerySnapshot docQuerySnapshot = await documentsRef.get();

      for (QueryDocumentSnapshot doc in docQuerySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        DocumentModel document = DocumentModel.fromJson(data);

        docs.add({
          'id': doc.id,
          'data': document,
        });
      }
    } catch (e) {
      print("Erreur dans getDocByUser : $e");
    }

    return docs;
  }

  Future<void> deleteDocument({
    String? userId,
    List<List<String>>? userIdsMatrix, // ✅ Matrice de UID
    required String? lotId,
    required String documentId,
    required String? residenceId,
    required String documentType,
    required bool isCopro,
  }) async {
    try {
      if (isCopro && residenceId != null) {
        print("Residence => $residenceId => documents_copro => $documentId");
        await db
            .collection("Residence")
            .doc(residenceId)
            .collection("documents_copro")
            .doc(documentId)
            .delete();
        print("Document copro supprimé avec succès !");
      } else if (TypeList.idTypes.contains(documentType)) {
        // Cas document d'identité
        await db
            .collection("User")
            .doc(userId)
            .collection("documents")
            .doc(documentId)
            .delete();
        print("Document ID supprimé avec succès !");
      } else if (lotId != null) {
        if (userIdsMatrix != null && userIdsMatrix.isNotEmpty) {
          // ✅ Cas plusieurs groupes de users
          for (var userList in userIdsMatrix) {
            for (String uid in userList) {
              print(
                  "Suppression document pour User => $uid => lots => $lotId => documents => $documentId");
              await db
                  .collection("User")
                  .doc(uid)
                  .collection("lots")
                  .doc(lotId)
                  .collection("documents")
                  .doc(documentId)
                  .delete();
            }
          }
          print(
              "Document supprimé pour tous les utilisateurs (groupes) avec succès !");
        } else if (userId != null) {
          // Cas classique avec un seul user
          print(
              "User => $userId => lots => $lotId => documents => $documentId");
          await db
              .collection("User")
              .doc(userId)
              .collection("lots")
              .doc(lotId)
              .collection("documents")
              .doc(documentId)
              .delete();
          print("Document perso supprimé avec succès !");
        } else {
          throw Exception("Aucun utilisateur fourni pour la suppression.");
        }
      } else {
        throw Exception("Impossible de déterminer l'emplacement du document.");
      }
    } catch (e) {
      print("Erreur lors de la suppression du document : $e");
      rethrow;
    }
  }
}
