import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
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

  Future<DocumentModel> setDocumentTenant(
      DocumentModel newDoc, String userId) async {
    try {
      // ➤ Cas ID : stocké dans User/{userId}/documents
      DocumentReference<Map<String, dynamic>> userDocRef =
          db.collection("User").doc(userId);

      await userDocRef.collection("documents").add(newDoc.toJson());
      print("Document ID ajouté avec succès dans User/{userId}/documents !");
    } catch (e) {
      print("Erreur lors de l'ajout du document : $e");
    }

    return newDoc;
  }

  Future<DocumentModel> setDocumentGarant({
    required DocumentModel newDoc,
    required String userId,
    required String garantId,
  }) async {
    try {
      // 1. Récupérer le seul doc de 'profil_locataire'
      final profilSnapshot = await db
          .collection("User")
          .doc(userId)
          .collection("profil_locataire")
          .limit(1)
          .get();

      if (profilSnapshot.docs.isEmpty) {
        throw Exception(
            "Aucun document 'profil_locataire' trouvé pour l'utilisateur $userId.");
      }

      final profilDocId = profilSnapshot.docs.first.id;

      // 2. Ajouter le document dans le bon chemin Firestore
      final garantDocRef = db
          .collection("User")
          .doc(userId)
          .collection("profil_locataire")
          .doc(profilDocId)
          .collection("garants")
          .doc(garantId)
          .collection("documents");

      await garantDocRef.add(newDoc.toJson());

      print("Document ajouté avec succès dans le garant !");
    } catch (e) {
      print("Erreur lors de l'ajout du document du garant : $e");
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

  Future<void> deleteTenantDocument({
    required String userId,
    required String documentId,
    String? fileExtension,
  }) async {
    try {
      final StorageServices _storageServices = StorageServices();
      // Suppression du document Firestore
      print("Suppression du document dans User/$userId/documents/$documentId");
      await db
          .collection("User")
          .doc(userId)
          .collection("documents")
          .doc(documentId)
          .delete();
      print("Document supprimé avec succès !");
    } catch (e) {
      print("Erreur lors de la suppression du document/fichier : $e");
      rethrow;
    }
  }

  Future<bool> deleteGarantDocuments(
    String uid,
    String garantId,
    String documentId,
  ) async {
    if (garantId.isEmpty || documentId.isEmpty) {
      print("IDs invalides pour la suppression.");
      return false;
    }
    try {
      final profilSnapshot = await FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .collection('profil_locataire')
          .limit(1)
          .get();

      if (profilSnapshot.docs.isEmpty) {
        print("Aucun profil locataire trouvé.");
        return false;
      }

      final profilDocId = profilSnapshot.docs.first.id;

      print(
          "Suppression du document $documentId pour garant $garantId dans profil $profilDocId");

      await FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .collection('profil_locataire')
          .doc(profilDocId)
          .collection('garants')
          .doc(garantId)
          .collection('documents')
          .doc(documentId)
          .delete();

      return true;
    } catch (e) {
      print("Erreur lors de la suppression du document : $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchGarantDocuments(
      String uid, String garantId) async {
    try {
      // 1. Récupérer le seul doc de 'profil_locataire'
      final profilSnapshot = await FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .collection('profil_locataire')
          .limit(1) // ← on s'assure qu'il n'y en a qu’un
          .get();

      if (profilSnapshot.docs.isEmpty) {
        return []; // Aucun profil locataire
      }

      final profilDocId = profilSnapshot.docs.first.id;

      // 2. Récupérer les documents du garant
      final docSnapshot = await FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .collection('profil_locataire')
          .doc(profilDocId)
          .collection('garants')
          .doc(garantId)
          .collection('documents')
          .get();

      // 3. Mapper les documents
      return docSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'document': DocumentModel.fromJson(doc.data()),
        };
      }).toList();
    } catch (e) {
      print("Erreur lors du fetch des documents du garant : $e");
      return [];
    }
  }
}
