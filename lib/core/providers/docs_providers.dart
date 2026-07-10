import 'package:connect_kasa/core/providers/docs_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Documents/justificatifs d'un locataire (MyInfosRent). ref.invalidate(...)
/// force un rafraîchissement après upload/suppression d'un document.
final tenantDocumentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  final repository = ref.watch(docsRepositoryProvider);
  return repository.fetchTenantDocuments(uid).then((result) => result.when(
      success: (docs) => docs, failure: (error) => throw error));
});
