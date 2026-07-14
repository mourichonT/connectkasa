import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/dependent_entry.dart';
import 'package:konodal/controllers/features/generate_ref_user_app.dart';
import 'package:konodal/controllers/features/income_entry.dart';
import 'package:konodal/controllers/features/job_entry.dart';
import 'package:konodal/core/errors/app_exceptions.dart';
import 'package:konodal/core/repositories/user_repository.dart';
import 'package:konodal/core/result/result.dart';
import 'package:konodal/models/pages_models/address.dart';
import 'package:konodal/models/pages_models/conjoint_info.dart';
import 'package:konodal/models/pages_models/demande_loc.dart';
import 'package:konodal/models/pages_models/guarantor_info.dart';
import 'package:konodal/models/pages_models/user.dart';
import 'package:konodal/models/pages_models/user_info.dart';
import 'package:konodal/models/pages_models/user_temp.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreUserRepository implements IUserRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<User>> getUserById(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();

      if (!snapshot.exists || snapshot.data() == null) {
        return Result.failure(
            NotFoundException('Utilisateur $uid introuvable'));
      }

      return Result.success(User.fromMap(snapshot.data()!));
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Stream<Result<User>> watchUserById(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return Result<User>.failure(
            NotFoundException('Utilisateur $uid introuvable'));
      }
      return Result.success(User.fromMap(snapshot.data()!));
    }).handleError((Object e) => Result<User>.failure(AppException.from(e)));
  }

  @override
  Future<Result<UserTemp>> setUser(
    UserTemp newUser,
    String? lotId,
    String? residenceId,
    String? companyName,
    String? intentedFor,
    String? statutResident,
    String? fcmToken,
  ) async {
    try {
      String refUserApp = await generateUniqueRefUserApp(_firestore, newUser);

      Map<String, dynamic> userData = newUser.toMap();
      userData['refUserApp'] = refUserApp;

      await _firestore.collection("users").doc(newUser.uid).set(
            userData,
            SetOptions(merge: true),
          );

      if (fcmToken != null) {
        await updateFcmToken(uid: newUser.uid, token: fcmToken);
      }

      if (lotId != null) {
        await _firestore
            .collection("users")
            .doc(newUser.uid)
            .collection("lots")
            .doc(lotId)
            .set({
          "colorSelected": "ff48775b",
          "nameLot": "",
          if (residenceId != null) "residenceId": residenceId,
          if (companyName != null) "companyName": companyName,
          if (intentedFor != null) "intendedFor": intentedFor,
          "statutResident": statutResident,
          // Tant qu'une personne n'a pas revérifié les documents déposés
          // pour ce lot, il reste bloqué (cf. isApprovedLot dans Lot).
          "isApprovedLot": false,
        }, SetOptions(merge: true));

        if (residenceId != null) {
          await _firestore.collection("users").doc(newUser.uid).set({
            "residencesIds": FieldValue.arrayUnion([residenceId]),
          }, SetOptions(merge: true));
        }
      }

      return Result.success(newUser);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> updateFcmToken({
    required String uid,
    required String token,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('private')
          .doc('fcm')
          .set({'token': token}, SetOptions(merge: true));
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> updateUserField({
    required String uid,
    required String field,
    String? value,
    bool? newBool,
  }) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      if (!snapshot.exists) {
        return Result.failure(NotFoundException('Utilisateur $uid introuvable'));
      }

      final newValue = value ?? newBool;
      if (newValue == null) {
        return Result.failure(
            UnknownException('Aucune valeur spécifiée pour la mise à jour.'));
      }

      // users/{uid} regroupe name/surname/... sous 'user' et pseudo/bio/
      // private/profilPic/phone sous 'profil' (cf. User.fromMap/toMap) :
      // une clé plate ("pseudo", "bio"...) ne correspond à aucun champ relu
      // nulle part et restait donc silencieusement sans effet une fois
      // écrite. On cible ici le bon sous-champ via la notation pointée.
      const profilGroupFields = {
        'pseudo', 'bio', 'private', 'profilPic', 'phone'
      };
      const userGroupFields = {
        'name', 'surname', 'birthday', 'sex', 'nationality', 'placeOfborn',
        'isInfoCorrect'
      };
      final key = profilGroupFields.contains(field)
          ? 'profil.$field'
          : userGroupFields.contains(field)
              ? 'user.$field'
              : field;

      await _firestore.collection('users').doc(uid).update({key: newValue});
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<String?>> getImageUrl(String pathImage) async {
    if (pathImage.isEmpty) {
      return const Result.success(null);
    }
    try {
      final ref = FirebaseStorage.instance.ref().child(pathImage);
      final imageUrl = await ref.getDownloadURL();
      return Result.success(imageUrl);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<String>>> getNumUsersByResidence(
      String residenceId, String uid) async {
    List<String> users = [];
    try {
      final documentSnapshot =
          await _firestore.collection("residences").doc(residenceId).get();

      if (documentSnapshot.exists) {
        final lotQuerySnapshot =
            await documentSnapshot.reference.collection("lots").get();

        for (final lotDoc in lotQuerySnapshot.docs) {
          List<String> idLocataire =
              List.from(lotDoc.data()["idLocataire"] ?? []);
          List<String> idProprietaire =
              List.from(lotDoc.data()["idProprietaire"] ?? []);

          users.addAll(idLocataire);
          if (!idLocataire.contains(uid)) {
            users.addAll(idProprietaire);
          }
        }
      }
      return Result.success(users);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<UserInfo?>> getUserWithInfo(String userId) async {
    try {
      final userDocRef = await _firestore
          .collection("users")
          .where("uid", isEqualTo: userId)
          .get();

      if (userDocRef.docs.isEmpty) {
        return const Result.success(null);
      }

      final userDoc = userDocRef.docs.first;
      final userMap = userDoc.data();
      final user = User.fromMap(userMap);

      final userInfoDoc = await userDoc.reference
          .collection("private")
          .doc("profilLocataire")
          .get();
      final userInfoMap = userInfoDoc.data() ?? {};

      return Result.success(UserInfo(
        privacyPolicy: user.privacyPolicy,
        name: user.name,
        surname: user.surname,
        email: user.email,
        uid: user.uid,
        pseudo: user.pseudo,
        profilPic: user.profilPic ?? "",
        isApproved: user.isApproved,
        birthday: user.birthday,
        incomes: (userInfoMap['revenus'] as List<dynamic>?)
                ?.map((e) => IncomeEntry.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        jobIncomes: (userInfoMap['activities'] as List<dynamic>?)
                ?.map((e) => JobEntry.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        dependents: ((userInfoMap['dependents'] as List<dynamic>?) ?? [])
            .map((entry) => DependentEntry.fromMap(Map<String, dynamic>.from(entry)))
            .toList(),
        familySituation: userInfoMap['familySituation'] ?? "",
        nationality: user.nationality,
        // phone est un champ de compte (users/{uid}.profil.phone), pas du
        // dossier locataire - cf. User.phone, modifié depuis "Modifier mes
        // informations".
        phone: user.phone,
        address: Address.fromJson(userInfoMap['address'] as Map<String, dynamic>?),
        conjoint: ConjointInfo.fromJson(userInfoMap['conjoint'] as Map<String, dynamic>?),
        sex: user.sex,
        placeOfborn: user.placeOfborn,
      ));
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<Map<String, dynamic>?>> getLotDetails(
      String userID, String refLot) async {
    try {
      final lotRef = _firestore
          .collection("users")
          .doc(userID)
          .collection("lots")
          .doc(refLot);

      final snapshot = await lotRef.get();

      if (!snapshot.exists) {
        return const Result.success(null);
      }
      final data = snapshot.data() as Map<String, dynamic>;
      return Result.success({
        "colorSelected": data["colorSelected"],
        "nameLot": data["nameLot"],
      });
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<bool>> updateUserInfo(UserInfo updatedUser) async {
    try {
      final userQuery = await _firestore
          .collection("users")
          .where("uid", isEqualTo: updatedUser.uid)
          .get();

      if (userQuery.docs.isEmpty) {
        return const Result.success(false);
      }

      final userDocRef = userQuery.docs.first.reference;

      await userDocRef.update({
        "email": updatedUser.email,
        "name": updatedUser.name,
        "surname": updatedUser.surname,
        "pseudo": updatedUser.pseudo,
        "profilPic": updatedUser.profilPic,
        "privacyPolicy": updatedUser.privacyPolicy,
        "birthday": updatedUser.birthday,
        "sex": updatedUser.sex,
        "nationality": updatedUser.nationality,
        "placeOfborn": updatedUser.placeOfborn,
        "private": updatedUser.private,
        "bio": updatedUser.bio,
        "createdDate": updatedUser.createdDate,
      });

      Map<String, dynamic> profilLocataireData = {
        "revenus": updatedUser.incomes.map((e) => e.toMap()).toList(),
        "activities": updatedUser.jobIncomes.map((e) => e.toMap()).toList(),
        "dependents": updatedUser.dependents.map((e) => e.toMap()).toList(),
        "familySituation": updatedUser.familySituation,
        "address": updatedUser.address.toJson(),
        "conjoint": updatedUser.conjoint.toJson(),
      };

      // Distinct de users/{uid}.createdDate (date de création du compte) :
      // ce createdDate marque la création du profil locataire lui-même
      // (revenus/activités), qui peut arriver bien après la création du
      // compte. Écrit une seule fois - si le document ou le champ existe
      // déjà, on ne le touche pas, pour ne jamais l'écraser lors des
      // sauvegardes suivantes.
      final profilLocataireRef =
          userDocRef.collection("private").doc("profilLocataire");
      final existingProfilLocataire = await profilLocataireRef.get();
      if (existingProfilLocataire.data()?["createdDate"] == null) {
        profilLocataireData["createdDate"] = FieldValue.serverTimestamp();
      }

      await profilLocataireRef.set(profilLocataireData, SetOptions(merge: true));

      return const Result.success(true);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<String?>> updateSingleGarant({
    required GuarantorInfo garant,
    required String uid,
    String? garantDocId,
  }) async {
    try {
      final userQuery = await _firestore
          .collection("users")
          .where("uid", isEqualTo: uid)
          .get();

      if (userQuery.docs.isEmpty) {
        return const Result.success(null);
      }

      final userDocRef = userQuery.docs.first.reference;
      final garantsCollection = userDocRef.collection("garants");

      if (garantDocId != null && garantDocId.isNotEmpty) {
        await garantsCollection.doc(garantDocId).update(garant.toMap());
        return Result.success(garantDocId);
      } else {
        final newDocRef = await garantsCollection.add(garant.toMap());
        await newDocRef.update({'id': newDocRef.id});
        return Result.success(newDocRef.id);
      }
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<GuarantorInfo>>> getGarants(String uid) async {
    final List<GuarantorInfo> garants = [];
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('uid', isEqualTo: uid)
          .get();

      if (userQuery.docs.isEmpty) return Result.success(garants);

      final userDocRef = userQuery.docs.first.reference;
      final garantDocs = await userDocRef.collection('garants').get();

      for (var doc in garantDocs.docs) {
        garants.add(GuarantorInfo.fromMap(doc.data()));
      }
      return Result.success(garants);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<GuarantorInfo?>> getUniqueGarant(
      String uid, String garantId) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('uid', isEqualTo: uid)
          .get();

      if (userQuery.docs.isEmpty) return const Result.success(null);

      final userDocRef = userQuery.docs.first.reference;
      final garantDoc =
          await userDocRef.collection('garants').doc(garantId).get();

      if (!garantDoc.exists) return const Result.success(null);

      return Result.success(GuarantorInfo.fromMap(garantDoc.data()!));
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<bool>> deleteGarant(String uid, String garantId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('garants')
          .doc(garantId)
          .delete();
      return const Result.success(true);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> shareFile(DemandeLoc demande, String uid) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('demandes_loc')
          .doc();
      await docRef.set(demande.toJson());
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<List<DemandeLoc>>> getDemande(String uid) async {
    List<DemandeLoc> demandes = [];
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('demandes_loc')
          .get();

      for (var doc in querySnapshot.docs) {
        demandes.add(DemandeLoc.fromJson(doc.data(), id: doc.id));
      }
      return Result.success(demandes);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> deleteDemande(String uid, String demandeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('demandes_loc')
          .doc(demandeId)
          .delete();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<User?>> getUserWithEmailOrRefApp(
      String? destinataireEmail, String? refAPP) async {
    try {
      if (destinataireEmail != null && destinataireEmail.isNotEmpty) {
        final emailQuery = await _firestore
            .collection("users")
            .where("email", isEqualTo: destinataireEmail)
            .limit(1)
            .get();

        if (emailQuery.docs.isNotEmpty) {
          return Result.success(User.fromMap(emailQuery.docs.first.data()));
        }
      }

      if (refAPP != null && refAPP.isNotEmpty) {
        final refAppQuery = await _firestore
            .collection("users")
            .where("refUserApp", isEqualTo: refAPP)
            .limit(1)
            .get();

        if (refAppQuery.docs.isNotEmpty) {
          return Result.success(User.fromMap(refAppQuery.docs.first.data()));
        }
      }

      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> addLotToUser({
    required String userId,
    required String lotId,
    String? residenceId,
    String? companyName,
    String? intendedFor,
    String? statutResident,
    Timestamp? entryDate,
    String colorSelected = "ff48775b",
    String nameLot = "",
  }) async {
    try {
      final userLotRef = _firestore
          .collection("users")
          .doc(userId)
          .collection("lots")
          .doc(lotId);

      Map<String, dynamic> lotData = {
        "colorSelected": colorSelected,
        "nameLot": nameLot,
        if (residenceId != null) "residenceId": residenceId,
        if (companyName != null) "companyName": companyName,
        if (intendedFor != null) "intendedFor": intendedFor,
        if (statutResident != null) "statutResident": statutResident,
        if (entryDate != null) "entryDate": entryDate,
        // Tant qu'une personne n'a pas revérifié les documents déposés
        // pour ce lot, il reste bloqué (cf. isApprovedLot dans Lot).
        "isApprovedLot": false,
      };

      await userLotRef.set(lotData, SetOptions(merge: true));

      if (residenceId != null) {
        await _firestore.collection("users").doc(userId).set({
          "residencesIds": FieldValue.arrayUnion([residenceId]),
        }, SetOptions(merge: true));
      }

      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }

  @override
  Future<Result<void>> markDemandeAsRead(
      String userId, String demandeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('demandes_loc')
          .doc(demandeId)
          .update({'open': true});
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.from(e));
    }
  }
}
