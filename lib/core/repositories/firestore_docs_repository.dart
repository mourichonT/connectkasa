import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/core/errors/app_exceptions.dart';
import 'package:connect_kasa/core/repositories/docs_repository.dart';
import 'package:connect_kasa/core/result/result.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';

class FirestoreDocsRepository implements IDocsRepository {
  final FirebaseFirestore _firestore;

  FirestoreDocsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<DocumentModel>> setDocument(
      DocumentModel newDoc, String userId, String? lotId) async {
    final List<String> idType = TypeList.idTypes;

    try {
      if (idType.contains(newDoc.type)) {
        // Cas ID : stocké dans User/{userId}/documents (lotId pas utilisé)
        DocumentReference<Map<String, dynamic>> userDocRef =
            _firestore.collection("User").doc(userId);
        await userDocRef.collection("documents").add(newDoc.toJson());
      } else {
        // Cas non-ID : stocké dans User/{userId}/lots/{lotId}/documents
        if (lotId == null) {
          throw Exception("lotId requis pour un document rattaché à un lot.");
        }
        DocumentReference<Map<String, dynamic>> userLotRef = _firestore
            .collection("User")
            .doc(userId)
            .collection("lots")
            .doc(lotId);
        await userLotRef.collection("documents").add(newDoc.toJson());
      }
      return Result.success(newDoc);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<DocumentModel>> setDocumentTenant(
      DocumentModel newDoc, String userId) async {
    try {
      DocumentReference<Map<String, dynamic>> userDocRef =
          _firestore.collection("User").doc(userId);
      await userDocRef.collection("documents").add(newDoc.toJson());
      return Result.success(newDoc);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<DocumentModel>> setDocumentGarant({
    required DocumentModel newDoc,
    required String userId,
    required String garantId,
  }) async {
    try {
      final garantDocRef = _firestore
          .collection("User")
          .doc(userId)
          .collection("garants")
          .doc(garantId)
          .collection("documents");

      await garantDocRef.add(newDoc.toJson());
      return Result.success(newDoc);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<DocumentModel>>> getAllDocs(String residenceId) async {
    List<DocumentModel> docs = [];

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection("Residence")
          .doc(residenceId)
          .collection("documents_copro")
          .get();
      for (var docSnapshot in querySnapshot.docs) {
        docs.add(DocumentModel.fromJson(docSnapshot.data()));
      }
      return Result.success(docs);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getAllDocsWithId(
      String residenceId) async {
    List<Map<String, dynamic>> docs = [];

    try {
      final querySnapshot = await _firestore
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
      return Result.success(docs);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getDocByUser(
      String uid, String refLot) async {
    List<Map<String, dynamic>> docs = [];

    try {
      CollectionReference documentsRef = _firestore
          .collection("User")
          .doc(uid)
          .collection("lots")
          .doc(refLot)
          .collection("documents");

      QuerySnapshot docQuerySnapshot = await documentsRef.get();

      for (QueryDocumentSnapshot doc in docQuerySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DocumentModel document = DocumentModel.fromJson(data);

        docs.add({
          'id': doc.id,
          'data': document,
        });
      }
      return Result.success(docs);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> deleteDocument({
    String? userId,
    List<List<String>>? userIdsMatrix,
    required String? lotId,
    required String documentId,
    required String? residenceId,
    required String documentType,
    required bool isCopro,
  }) async {
    try {
      if (isCopro && residenceId != null) {
        await _firestore
            .collection("Residence")
            .doc(residenceId)
            .collection("documents_copro")
            .doc(documentId)
            .delete();
      } else if (TypeList.idTypes.contains(documentType)) {
        // Cas document d'identité
        await _firestore
            .collection("User")
            .doc(userId)
            .collection("documents")
            .doc(documentId)
            .delete();
      } else if (lotId != null) {
        if (userIdsMatrix != null && userIdsMatrix.isNotEmpty) {
          // Cas plusieurs groupes de users
          for (var userList in userIdsMatrix) {
            for (String uid in userList) {
              await _firestore
                  .collection("User")
                  .doc(uid)
                  .collection("lots")
                  .doc(lotId)
                  .collection("documents")
                  .doc(documentId)
                  .delete();
            }
          }
        } else if (userId != null) {
          // Cas classique avec un seul user
          await _firestore
              .collection("User")
              .doc(userId)
              .collection("lots")
              .doc(lotId)
              .collection("documents")
              .doc(documentId)
              .delete();
        } else {
          throw Exception("Aucun utilisateur fourni pour la suppression.");
        }
      } else {
        throw Exception("Impossible de déterminer l'emplacement du document.");
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> deleteTenantDocument({
    required String userId,
    required String documentId,
    String? fileExtension,
  }) async {
    try {
      await _firestore
          .collection("User")
          .doc(userId)
          .collection("documents")
          .doc(documentId)
          .delete();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> deleteGarantDocuments(
    String uid,
    String garantId,
    String documentId,
  ) async {
    if (garantId.isEmpty || documentId.isEmpty) {
      return Result.failure(
          const UnknownException("IDs invalides pour la suppression."));
    }
    try {
      await _firestore
          .collection('User')
          .doc(uid)
          .collection('garants')
          .doc(garantId)
          .collection('documents')
          .doc(documentId)
          .delete();

      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> fetchGarantDocuments(
      String uid, String garantId) async {
    try {
      final docSnapshot = await _firestore
          .collection('User')
          .doc(uid)
          .collection('garants')
          .doc(garantId)
          .collection('documents')
          .get();

      final docs = docSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'document': DocumentModel.fromJson(doc.data()),
        };
      }).toList();

      return Result.success(docs);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> fetchTenantDocuments(
      String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection('User')
          .doc(uid)
          .collection('documents')
          .get();

      final docs = docSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'document': DocumentModel.fromJson(doc.data()),
        };
      }).toList();

      return Result.success(docs);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
