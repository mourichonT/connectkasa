import 'package:konodal/core/providers/current_user_provider.dart';
import 'package:konodal/models/pages_models/demande_loc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Demandes de location envoyées par ce locataire, tous bailleurs
/// destinataires confondus ("Mes demandes en cours"). ref.invalidate(...)
/// force un rafraîchissement après retrait d'une demande.
final sentDemandesProvider =
    FutureProvider.family<List<DemandeLoc>, String>((ref, tenantUid) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getSentDemandes(tenantUid).then((result) => result.when(
      success: (v) => v, failure: (error) => throw error));
});
