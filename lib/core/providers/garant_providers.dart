import 'package:connect_kasa/core/providers/current_user_provider.dart';
import 'package:connect_kasa/core/providers/docs_repository_provider.dart';
import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Garants d'un utilisateur (ManagementGarants). ref.invalidate(...)
/// force un rafraîchissement explicite (retour d'ajout/modification de
/// garant).
final garantsByUserProvider =
    FutureProvider.family<List<GuarantorInfo?>, String>((ref, uid) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getGarants(uid).then((result) => result.when(
      success: (v) => v, failure: (error) => throw error));
});

/// Détail d'un garant donné (GuarantorDetail).
final uniqueGarantProvider = FutureProvider.family<GuarantorInfo?,
    ({String tenantUid, String garantId})>((ref, args) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository
      .getUniqueGarant(args.tenantUid, args.garantId)
      .then((result) => result.when(
          success: (v) => v, failure: (error) => throw error));
});

/// Documents/justificatifs d'un garant donné (GuarantorDetail).
/// ref.invalidate(...) force un rafraîchissement après suppression d'un
/// document.
final garantDocumentsProvider = FutureProvider.family<
    List<Map<String, dynamic>>,
    ({String tenantUid, String garantId})>((ref, args) async {
  final repository = ref.watch(docsRepositoryProvider);
  return repository
      .fetchGarantDocuments(args.tenantUid, args.garantId)
      .then((result) => result.when(
          success: (docs) => docs, failure: (error) => throw error));
});
