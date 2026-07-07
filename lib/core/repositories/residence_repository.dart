import 'package:connect_kasa/core/result/result.dart';
import 'package:connect_kasa/models/pages_models/contact.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/models/pages_models/structure_residence.dart';

/// Remplace DataBasesResidenceServices (Phase 2 du chantier architecture).
abstract interface class IResidenceRepository {
  Future<Result<List<Contact>>> getEmergenciesContacts();

  Future<Result<List<Contact>>> getContactByResidence(String residence);

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

  Future<Result<void>> addContact(String residenceId, Contact contact);

  Future<Result<void>> updateContact(String residenceId, Contact contact);

  Future<Result<void>> removeContact(String residenceId, String contactDocId);

  Future<Result<void>> saveStructure(
      String residenceId, StructureResidence structure);

  Future<Result<void>> removeStructure(
      String residenceId, String structureId);
}
