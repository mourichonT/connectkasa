import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/enum/add_tenant_outcome.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:flutter/material.dart';

/// Remplace DataBasesLotServices (Phase 2 du chantier architecture).
abstract interface class ILotRepository {
  Future<Result<List<Lot>>> getLotByIdUser(String numUser);

  Future<Result<Lot>> getFirstLotByUserId(String numUser);

  Future<Result<List<Lot>>> getLotByResidence(String residenceId);

  Future<Result<Lot?>> getUniqueLot(
      String residenceId, String bat, String numlot);

  Future<Result<int>> countLocatairesExcludingUser(String numUser);

  Future<Result<void>> updateLotColor(
      String userUid, String id, Color newColor);

  Future<Result<void>> updateNameLot(
      String userUid, String id, String newName);

  Future<Result<bool>> updateLot(
      String residenceId, String idLot, String field, dynamic upDate);

  /// N'affiche plus aucune UI (SnackBar/dialog) : renvoie un verdict
  /// (AddTenantOutcome) à charge pour l'appelant. Si le lot a déjà un
  /// locataire différent, renvoie needsReplaceOrAddDecision SANS rien écrire
  /// - l'appelant doit alors demander à l'utilisateur remplacer/ajouter,
  /// puis rappeler avec [replace] renseigné pour effectuer l'écriture.
  Future<Result<AddTenantOutcome>> addTenant(
      String residenceId, String idLot, String tenantId,
      {bool? replace});

  Future<Result<void>> removeUserFromAllLots(String userID);

  Future<Result<void>> removeIdLocataire(
      String residenceId, String idLot, String idLocataireToRemove);

  Future<Result<void>> removeIdProprietaire(
      String residenceId, String idLot, String idProprietaireToRemove);

  Future<Result<void>> createOrUpdateLot(String residenceId, Lot lot);

  Future<Result<void>> deleteLot(String residenceId, String idLot);

  /// Rattache idLot à parentLotId (même résidence) - idProprietaire/
  /// idLocataire sont ensuite alignés sur le parent côté serveur
  /// (sync_lot_tenants). Démarre toujours groupé (locataire commun) ;
  /// utiliser setGroupedWithParent pour dégrouper ensuite.
  Future<Result<void>> linkLotToParent(
      String residenceId, String idLot, String parentLotId);

  /// Supprime le lien de parenté - idProprietaire/idLocataire actuels sont
  /// conservés tels quels, mais redeviennent gérables indépendamment.
  Future<Result<void>> unlinkLot(String residenceId, String idLot);

  /// Bascule le partage du locataire avec le lot parent (idProprietaire
  /// reste toujours aligné, indépendamment de cette bascule).
  Future<Result<void>> setGroupedWithParent(
      String residenceId, String idLot, bool grouped);

  /// Lots de la résidence ayant idLot comme parentLotId.
  Future<Result<List<Lot>>> getChildLots(String residenceId, String idLot);
}
