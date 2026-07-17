import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/residence.dart';
import 'package:konodal/models/pages_models/structure_residence.dart';

/// Remplace DataBasesResidenceServices (Phase 2 du chantier architecture).
abstract interface class IResidenceRepository {
  Future<Result<List<Residence>>> rechercheFirestore(String saisie);

  Future<Result<Residence>> getResidenceByRef(String residenceId);

  Future<Result<bool>> updateResidence(
      String refResidence, Map<String, dynamic> updatedData);

  Future<Result<bool>> updateField(
      String refResidence, String field, dynamic value);

  Future<Result<List<Map<String, String>>>> getAllLocalisation(
      String residenceId);

  Future<Result<StructureResidence?>> getDetailLocalisation(
      String residenceId, String locId);

  Future<Result<List<StructureResidence>>> getStructuresByResidence(
      String residenceId);

  Future<Result<void>> removeCsMember(String residenceId, String uidToRemove);

  Future<Result<void>> addCsMember(String residenceId, String uidToAdd);

  Future<Result<void>> saveStructure(
      String residenceId, StructureResidence structure);

  Future<Result<void>> removeStructure(
      String residenceId, String structureId);
}
