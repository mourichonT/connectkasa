import 'package:connect_kasa/core/result/result.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
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

  /// Décision remplacer/ajouter prise par l'appelant (BuildContext requis
  /// pour le dialog) : conservé tel quel pour cette migration, seul
  /// share_rent_folder.dart l'utilise.
  Future<Result<bool>> addTenant(BuildContext context, String residenceId,
      String idLot, String tenantId);

  Future<Result<void>> removeUserFromAllLots(String userID);

  Future<Result<void>> removeIdLocataire(
      String residenceId, String idLot, String idLocataireToRemove);

  Future<Result<void>> removeIdProprietaire(
      String residenceId, String idLot, String idProprietaireToRemove);

  Future<Result<void>> createOrUpdateLot(String residenceId, Lot lot);

  Future<Result<void>> deleteLot(String residenceId, String idLot);
}
