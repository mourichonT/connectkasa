import 'package:connect_kasa/core/result/result.dart';
import 'package:connect_kasa/models/pages_models/agency.dart';
import 'package:connect_kasa/models/pages_models/gerance_ref.dart';

/// Remplace DatabasesAgencyServices (Phase 2 du chantier architecture).
abstract interface class IAgencyRepository {
  Future<Result<List<Agency>>> searchByEmail(
    String emailPart, {
    required String serviceType,
  });

  /// Résout une référence enregistrée (GeranceRef) vers les données à jour
  /// du cabinet dans Gerance. Succès avec `null` si le cabinet ou le
  /// service référencé n'existe plus (supprimé côté référentiel
  /// entretemps) : ce n'est pas une erreur, juste une donnée absente.
  Future<Result<Agency?>> resolveRef(GeranceRef ref);
}
