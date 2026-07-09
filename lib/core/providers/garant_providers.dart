import 'package:connect_kasa/core/providers/current_user_provider.dart';
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
