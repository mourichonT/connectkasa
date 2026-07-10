import 'package:connect_kasa/core/result/result.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';

/// Remplace DataBasesDocsServices (Phase 2 du chantier architecture).
abstract interface class IDocsRepository {
  Future<Result<DocumentModel>> setDocument(
      DocumentModel newDoc, String userId, String? lotId);

  Future<Result<DocumentModel>> setDocumentTenant(
      DocumentModel newDoc, String userId);

  Future<Result<DocumentModel>> setDocumentGarant({
    required DocumentModel newDoc,
    required String userId,
    required String garantId,
  });

  Future<Result<List<DocumentModel>>> getAllDocs(String residenceId);

  Future<Result<List<Map<String, dynamic>>>> getAllDocsWithId(
      String residenceId);

  Future<Result<List<Map<String, dynamic>>>> getDocByUser(
      String uid, String lotId);

  Future<Result<void>> deleteDocument({
    String? userId,
    List<String>? recipientUids,
    required String? lotId,
    required String documentId,
    required String? residenceId,
    required String documentType,
    required bool isCopro,
  });

  Future<Result<void>> deleteTenantDocument({
    required String userId,
    required String documentId,
    String? fileExtension,
  });

  Future<Result<void>> deleteGarantDocuments(
      String uid, String garantId, String documentId);

  Future<Result<List<Map<String, dynamic>>>> fetchGarantDocuments(
      String uid, String garantId);

  Future<Result<List<Map<String, dynamic>>>> fetchTenantDocuments(String uid);
}
