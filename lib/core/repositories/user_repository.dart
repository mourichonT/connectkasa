import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/result/result.dart';
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
