import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/demande_historique.dart';
import 'package:konodal/models/pages_models/demande_loc.dart';
import 'package:konodal/models/pages_models/guarantor_info.dart';
import 'package:konodal/models/pages_models/user.dart';
import 'package:konodal/models/pages_models/user_info.dart';
import 'package:konodal/models/pages_models/user_temp.dart';

/// Remplace DataBasesUserServices (Phase 2 du chantier architecture,
/// dernier service - le plus gros). getUserById/watchUserById existaient
/// déjà depuis la Phase 1 (premier exemple de référence de la convention).
abstract interface class IUserRepository {
  Future<Result<User>> getUserById(String uid);

  /// Flux temps réel du document users/{uid} (utilisé par le provider
  /// Riverpod de l'utilisateur connecté).
  Stream<Result<User>> watchUserById(String uid);

  Future<Result<UserTemp>> setUser(
    UserTemp newUser,
    String? lotId,
    String? residenceId,
    String? companyName,
    String? intentedFor,
    String? statutResident,
    String? fcmToken,
  );

  Future<Result<void>> updateFcmToken({
    required String uid,
    required String token,
  });

  Future<Result<void>> updateUserField({
    required String uid,
    required String field,
    String? value,
    bool? newBool,
  });

  Future<Result<String?>> getImageUrl(String pathImage);

  Future<Result<List<String>>> getNumUsersByResidence(
      String residenceId, String uid);

  Future<Result<UserInfo?>> getUserWithInfo(String userId);

  Future<Result<Map<String, dynamic>?>> getLotDetails(
      String userID, String refLot);

  Future<Result<bool>> updateUserInfo(UserInfo updatedUser);

  Future<Result<String?>> updateSingleGarant({
    required GuarantorInfo garant,
    required String uid,
    String? garantDocId,
  });

  Future<Result<List<GuarantorInfo>>> getGarants(String uid);

  Future<Result<GuarantorInfo?>> getUniqueGarant(String uid, String garantId);

  Future<Result<bool>> deleteGarant(String uid, String garantId);

  Future<Result<void>> shareFile(DemandeLoc demande, String uid);

  Future<Result<List<DemandeLoc>>> getDemande(String uid);

  Future<Result<void>> deleteDemande(String uid, String demandeId);

  /// Refuse une demande sans supprimer le document (contrairement à
  /// deleteDemande) : le locataire doit voir le statut "Refusé" dans "Mes
  /// demandes en cours" au lieu de la voir disparaître silencieusement.
  /// Écrit aussi une copie figée dans demandes_historique (persiste même si
  /// le locataire retire ensuite sa demande) - cf. DemandeHistorique.
  Future<Result<void>> refuseDemande({
    required String uid,
    required String demandeId,
    required String reason,
  });

  /// Historique des demandes refusées par ce bailleur (onglet "Historique"
  /// de ManagementTenant), indépendant de demandes_loc (survit à un retrait
  /// de demande côté locataire).
  Future<Result<List<DemandeHistorique>>> getDemandeHistorique(String uid);

  /// Toutes les demandes envoyées par ce locataire, tous bailleurs
  /// destinataires confondus (requête collectionGroup sur demandes_loc,
  /// filtrée par tenantId) - pour "Mes demandes en cours".
  Future<Result<List<DemandeLoc>>> getSentDemandes(String tenantUid);

  /// Retire une demande envoyée : supprime le document chez le bailleur
  /// destinataire et révoque son accès au dossier (pendingDemandeLandlords).
  Future<Result<void>> withdrawDemande({
    required String tenantUid,
    required String landlordId,
    required String demandeId,
  });

  Future<Result<User?>> getUserWithEmailOrRefApp(
      String? destinataireEmail, String? refAPP);

  Future<Result<void>> addLotToUser({
    required String userId,
    required String lotId,
    String? residenceId,
    String? companyName,
    String? intendedFor,
    String? statutResident,
    Timestamp? entryDate,
    String colorSelected,
    String nameLot,
  });

  Future<Result<void>> markDemandeAsRead(String userId, String demandeId);
}
