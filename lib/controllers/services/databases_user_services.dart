import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/generate_ref_user_app.dart';
import 'package:connect_kasa/controllers/features/income_entry.dart';
import 'package:connect_kasa/controllers/features/job_entry.dart';
import 'package:connect_kasa/models/pages_models/demande_loc.dart';
import 'package:connect_kasa/models/pages_models/guarantor_info.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/models/pages_models/user_temp.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class DataBasesUserServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<UserTemp> setUser(
      UserTemp newUser,
      String? lotId,
      String? companyName,
      String? intentedFor,
      String? statutResident,
      bool? informationsCorrectes,
      String? fcmToken) async {
    try {
      // Génère `refUserApp` unique
      String refUserApp = await generateUniqueRefUserApp(db, newUser);

      // Ajoute refUserApp à l'objet utilisateur
      Map<String, dynamic> userData = newUser.toMap();
      userData['refUserApp'] = refUserApp; // ✅ Ajout de `refUserApp`
// Fusionner les données utilisateur et le champ informationsCorrectes
      Map<String, dynamic> fullUserData = {
        ...userData,
        "informationsCorrectes": informationsCorrectes,
        if (fcmToken != null) 'token': fcmToken,
      };

// Envoi vers Firestore avec fusion
      await db.collection("User").doc(newUser.uid).set(
            fullUserData,
            SetOptions(merge: true),
          );
      // Ajoute les informations sur le lot si `lotId` est défini
      if (lotId != null) {
        await db
            .collection("User")
            .doc(newUser.uid)
            .collection("lots")
            .doc(lotId)
            .set({
          "colorSelected": "ff48775b",
          "nameLot": "",
          "lotId": lotId,
          if (companyName != null) "companyName": companyName,
          if (intentedFor != null) "intendedFor": intentedFor,
          "StatutResident": statutResident,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Impossible de mettre à jour l'utilisateur: $e");
    }

    return newUser;
  }

  static Future<void> updateUserField({
    required String uid,
    required String field,
    String? value,
    bool? newBool,
  }) async {
    try {
      // Récupérer l'utilisateur avec getUserById
      User? user = await getUserById(uid);

      // Vérifier si l'utilisateur existe
      if (user == null) {
        throw Exception('Utilisateur non trouvé');
      }

      // Choisir la valeur à mettre à jour
      final newValue = value ?? newBool;

      if (newValue == null) {
        throw Exception('Aucune valeur spécifiée pour la mise à jour.');
      }

      // Mise à jour du champ dans Firestore
      await FirebaseFirestore.instance.collection('User').doc(uid).update({
        field: newValue,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du champ $field: $e');
    }
  }

  static Future<User?> getUserById(String uid) async {
    User? user;
    try {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await FirebaseFirestore.instance.collection("User").doc(uid).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        user = User.fromMap(docSnapshot.data()!);
      } else {
        throw Exception('Utilisateur non trouvé');
      }
    } catch (e) {
      print("Erreur lors de la récupération de l'utilisateur : $e");
    }

    return user;
  }

  static Future<UserInfo?> getUserInfosById(String uid) async {
    UserInfo? user;
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection("User")
              .doc(uid)
              .collection("profil_locataire")
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        user = UserInfo.fromMap(data);
      } else {
        throw Exception('Aucun profil locataire trouvé pour cet utilisateur');
      }
    } catch (e) {
      print("Erreur lors de la récupération de l'utilisateur : $e");
    }

    return user;
  }

  Future<String?> getImageUrl(String pathImage) async {
    if (pathImage.isNotEmpty) {
      try {
        // Récupérer la référence de l'image depuis Firebase Storage
        final ref = FirebaseStorage.instance.ref().child(pathImage);
        // Obtenir l'URL de téléchargement de l'image
        final imageUrl = await ref.getDownloadURL();
        return imageUrl;
      } catch (e) {
        // Gérer les erreurs, par exemple l'image n'existe pas
        print("Erreur lors de la récupération de l'URL de l'image: $e");
        return null;
      }
    } else {
      return null; // Pas de chemin d'image défini
    }
  }

  Future<List<Lot?>> getLotByIdUser(String numUser) async {
    List<Lot?> lots = []; // Liste de lots
    try {
      // Commencer une transaction Firestore
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Récupérer la référence de la collection "Residence"
        CollectionReference residenceRef =
            FirebaseFirestore.instance.collection("Residence");

        // Récupérer les documents de la collection "Residence"
        QuerySnapshot<Map<String, dynamic>> querySnapshot =
            await residenceRef.get() as QuerySnapshot<Map<String, dynamic>>;

        // Parcourir chaque document de la collection "Residence"
        for (QueryDocumentSnapshot<Map<String, dynamic>> residenceDoc
            in querySnapshot.docs) {
          String residenceId = residenceDoc.id; // Identifiant du document
          // Ajouter l'identifiant du document à la liste
          //lots.add(residenceId);

          // Récupérer les lots de chaque résidence
          QuerySnapshot<Map<String, dynamic>> lotQuerySnapshot =
              await residenceDoc.reference.collection("lot").get();

          // Récupérer les données du document de la résidence
          Map<String, dynamic> residenceData = residenceDoc.data();

          // Vérifier si idProprietaire ou idLocataire contient numUser
          // et récupérer les lots correspondants
          for (QueryDocumentSnapshot<Map<String, dynamic>> doc
              in lotQuerySnapshot.docs) {
            dynamic idProprietaire = doc.data()["idProprietaire"];
            dynamic idLocataire = doc.data()["idLocataire"];

            if ((idProprietaire is List && idProprietaire.contains(numUser)) ||
                (idLocataire is List && idLocataire.contains(numUser)) ||
                (idProprietaire is String && idProprietaire == numUser) ||
                (idLocataire is String && idLocataire == numUser)) {
              Lot? lot = Lot.fromMap(doc.data());
              // Ajouter les données de la résidence à chaque lot
              lot.residenceData = residenceData;
              lot.residenceId = residenceId;
              lots.add(lot); // Ajouter le lot correspondant à la liste
            }
          }
        }
      });
    } catch (e) {
      print("Error completing in getLotByIduser2 function: $e");
    }

    return lots;
  }

  Future<List<String>> getNumUsersByResidence(
      String residenceId, String uid) async {
    List<String> users = [];

    try {
      // Récupérer la référence de la collection "Residence" basée sur le nom de la résidence
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection("Residence")
              .doc(residenceId)
              .get();

      // Vérifier si une résidence correspondant au nom existe
      if (documentSnapshot.exists) {
        // Récupérer la référence de la résidence trouvée
        DocumentSnapshot<Map<String, dynamic>> residenceDoc = documentSnapshot;

        // Récupérer les lots de la résidence spécifique
        QuerySnapshot<Map<String, dynamic>> lotQuerySnapshot =
            await residenceDoc.reference.collection("lot").get();

        // Parcourir chaque document de la collection "lot"
        for (QueryDocumentSnapshot<Map<String, dynamic>> lotDoc
            in lotQuerySnapshot.docs) {
          // Récupérer les idLocataire et idProprietaire de chaque lot
          List<String> idLocataire = List.from(lotDoc.data()["idLocataire"]);
          List<String> idProprietaire =
              List.from(lotDoc.data()["idProprietaire"]);

          // Ajouter chaque élément de idLocataire et idProprietaire à la liste si non nuls
          users.addAll(idLocataire);
          if ((!idLocataire.contains(uid))) {
            users.addAll(idProprietaire);
          }
        }
      } else {
        print(
            "Aucune résidence correspondant au nom '$residenceId' n'a été trouvée.");
      }
    } catch (e) {
      print("Impossible de récupérer les lots - erreur : $e");
    }
    return users;
  }

  Future<UserInfo?> getUserWithInfo(String userId) async {
    try {
      // Rechercher l'utilisateur dans Firestore
      QuerySnapshot<Map<String, dynamic>> userDocRef =
          await db.collection("User").where("uid", isEqualTo: userId).get();

      if (userDocRef.docs.isNotEmpty) {
        DocumentSnapshot<Map<String, dynamic>> userDoc = userDocRef.docs.first;
        Map<String, dynamic> userMap = userDoc.data()!;

        User user = User.fromMap(userMap);

        // Récupération des informations supplémentaires
        QuerySnapshot<Map<String, dynamic>> userInfoQuerySnapshot =
            await userDoc.reference.collection("profil_locataire").get();

        Map<String, dynamic> userInfoMap = userInfoQuerySnapshot.docs.isNotEmpty
            ? userInfoQuerySnapshot.docs.first.data()
            : {};

        return UserInfo(
          privacyPolicy: user.privacyPolicy,
          name: user.name,
          surname: user.surname,
          email: user.email,
          uid: user.uid,
          pseudo: user.pseudo,
          // profession: userInfoMap['profession'] ?? "",
          profilPic: user.profilPic ?? "",
          approved: user.approved,
          birthday: user.birthday,
          incomes: (userInfoMap['revenus'] as List<dynamic>?)
                  ?.map(
                      (e) => IncomeEntry.fromMap(Map<String, dynamic>.from(e)))
                  .toList() ??
              [],
          jobIncomes: (userInfoMap['activities'] as List<dynamic>?)
                  ?.map((e) => JobEntry.fromMap(Map<String, dynamic>.from(e)))
                  .toList() ??
              [],
          dependent: userInfoMap['dependent'] ?? 0,
          familySituation: userInfoMap['familySituation'] ?? "",
          nationality: user.nationality,
          phone: userInfoMap['phone'] ?? "",
          //typeContract: userInfoMap['typeContract'] ?? "",
          // entryJobDate: userInfoMap['entryJobDate'] ??
          //     Timestamp.fromDate(DateTime(1900, 1, 1)),
          sex: user.sex,
          placeOfborn: user.placeOfborn,
        );
      } else {
        print("Aucun utilisateur trouvé avec l'ID '$userId'.");
      }
    } catch (e) {
      print("Erreur lors de la récupération de l'utilisateur : $e");
    }

    return null;
  }

  static Future<void> removeUserById(String uid) async {
    try {
      final userRef = FirebaseFirestore.instance.collection("User").doc(uid);

      final userSnapshot = await userRef.get();

      if (!userSnapshot.exists) {
        print('Aucun utilisateur trouvé avec l\'ID $uid');
        return; // Sortir de la fonction si l'utilisateur n'existe pas
      }

      // Liste des sous-collections à plat à supprimer
      final List<String> subcollections = [
        'documents',
        'lots',
        'demandes_loc',
      ];

      for (String subCol in subcollections) {
        final subColRef = userRef.collection(subCol);
        final subColSnapshot = await subColRef.get();

        for (final doc in subColSnapshot.docs) {
          await doc.reference.delete();
          print("🗑️ ${subCol}/${doc.id} supprimé");
        }
      }

      // profil_locataire contient une sous-collection garants à vider
      // avant de pouvoir supprimer chaque document profil_locataire
      final profilLocataireSnapshot =
          await userRef.collection('profil_locataire').get();
      for (final profilDoc in profilLocataireSnapshot.docs) {
        final garantsSnapshot =
            await profilDoc.reference.collection('garants').get();
        for (final garantDoc in garantsSnapshot.docs) {
          await garantDoc.reference.delete();
        }
        await profilDoc.reference.delete();
        print("🗑️ profil_locataire/${profilDoc.id} supprimé");
      }

      // Supprime le document principal après avoir vidé les sous-collections
      await userRef.delete();
      print("✅ Utilisateur et ses sous-collections supprimés avec succès");
    } catch (e) {
      print('❌ Erreur lors de la suppression de l\'utilisateur: $e');
      rethrow;
    }
  }

  /// Supprime intégralement le compte d'un utilisateur : sa photo de profil
  /// (Storage), toutes ses données Firestore (User + sous-collections), puis
  /// son compte Firebase Auth. Le compte Auth est supprimé en dernier car
  /// cette opération met fin à la session authentifiée.
  static Future<void> deleteAccountCompletely(String uid) async {
    try {
      final user = await getUserById(uid);
      final profilPic = user?.profilPic;
      if (profilPic != null && profilPic.isNotEmpty) {
        await FirebaseStorage.instance.ref().child(profilPic).delete();
      }
    } catch (e) {
      print("Erreur lors de la suppression de la photo de profil : $e");
    }

    await removeUserById(uid);

    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      await currentUser.delete();
    }
  }

  Future<Map<String, dynamic>?> getLotDetails(
      String userID, String refLot) async {
    print("REFLOT: $refLot");
    print("USER: $userID");
    try {
      // Référence du document dans la sous-collection "lots"
      DocumentReference lotRef = FirebaseFirestore.instance
          .collection("User")
          .doc(userID)
          .collection("lots")
          .doc(refLot);

      // Récupération du document
      DocumentSnapshot snapshot = await lotRef.get();

      if (snapshot.exists) {
        // Accès aux champs spécifiques
        var data = snapshot.data() as Map<String, dynamic>;
        return {
          "colorSelected": data["colorSelected"],
          "nameLot": data["nameLot"],
        };
      } else {
        print("Detail non trouvé.");
        return null;
      }
    } catch (e) {
      print("Erreur lors de la récupération du lot : $e");
      return null;
    }
  }

  Future<bool> updateUserInfo(UserInfo updatedUser) async {
    try {
      // 1. Rechercher le document "User" correspondant à l'UID
      QuerySnapshot<Map<String, dynamic>> userQuery = await db
          .collection("User")
          .where("uid", isEqualTo: updatedUser.uid)
          .get();

      if (userQuery.docs.isEmpty) {
        print("Aucun utilisateur trouvé avec l'UID '${updatedUser.uid}'.");
        return false;
      }

      DocumentReference<Map<String, dynamic>> userDocRef =
          userQuery.docs.first.reference;

      // 2. Mettre à jour les données basiques dans la collection "User"
      await userDocRef.update({
        "email": updatedUser.email,
        "name": updatedUser.name,
        "surname": updatedUser.surname,
        "pseudo": updatedUser.pseudo,
        "approved": updatedUser.approved,
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

      // 3. Préparer les données spécifiques à "profil_locataire"
      Map<String, dynamic> profilLocataireData = {
        "revenus": updatedUser.incomes.map((e) => e.toMap()).toList(),
        "activities": updatedUser.jobIncomes.map((e) => e.toMap()).toList(),
        "dependent": updatedUser.dependent,
        "familySituation": updatedUser.familySituation,
        "phone": updatedUser.phone,
      };

      // 4. Accéder à la sous-collection "profil_locataire" et mettre à jour ou créer le document
      QuerySnapshot<Map<String, dynamic>> profilLocataireQuery =
          await userDocRef.collection("profil_locataire").get();

      if (profilLocataireQuery.docs.isNotEmpty) {
        // Mettre à jour le premier document existant
        await profilLocataireQuery.docs.first.reference
            .update(profilLocataireData);
      } else {
        // Créer un nouveau document
        await userDocRef
            .collection("profil_locataire")
            .add(profilLocataireData);
      }

      return true;
    } catch (e) {
      print("Erreur lors de la mise à jour de l'utilisateur : $e");
      return false;
    }
  }

  static Future<String?> updateSingleGarant({
    required GuarantorInfo garant,
    required String uid,
    String? garantDocId,
  }) async {
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection("User")
          .where("uid", isEqualTo: uid)
          .get();

      if (userQuery.docs.isEmpty) {
        print("Utilisateur non trouvé");
        return null;
      }

      final userDocRef = userQuery.docs.first.reference;

      final profilLocataireSnapshot =
          await userDocRef.collection("profil_locataire").get();

      if (profilLocataireSnapshot.docs.isEmpty) {
        print("Aucun profil locataire trouvé");
        return null;
      }

      final profilLocataireDocRef =
          profilLocataireSnapshot.docs.first.reference;
      final garantsCollection = profilLocataireDocRef.collection("garants");

      if (garantDocId != null && garantDocId.isNotEmpty) {
        await garantsCollection.doc(garantDocId).update(garant.toMap());
        return garantDocId;
      } else {
        final newDocRef = await garantsCollection.add(garant.toMap());

        // 💡 Ajout de l'ID dans le document après création
        await newDocRef.update({'id': newDocRef.id});

        return newDocRef.id;
      }
    } catch (e) {
      print("Erreur lors de l’ajout ou la mise à jour du garant : $e");
      return null;
    }
  }

  static Future<void> removeListElementTenant({
    required String uid,
    required String docId,
    required String field, // Le champ contenant la liste, ex: 'documents'
    required dynamic element, // L’élément à supprimer
  }) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .collection('profil_locataire')
          .doc(docId);

      await docRef.update({
        field: FieldValue.arrayRemove([element]),
      });

      print("Élément '$element' supprimé de la liste '$field'.");
    } catch (e) {
      print("Erreur lors de la suppression de l’élément : $e");
      rethrow;
    }
  }

  static Future<String?> getFirstDocId(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("User")
          .doc(uid)
          .collection("profil_locataire")
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
    } catch (e) {
      print("Erreur récupération docId profil_locataire : $e");
    }
    return null;
  }

  static Future<List<GuarantorInfo>> getGarants(
      String uid, String docId) async {
    final List<GuarantorInfo> garants = [];

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('User')
          .where('uid', isEqualTo: uid)
          .get();

      if (userQuery.docs.isEmpty) return [];

      final userDocRef = userQuery.docs.first.reference;

      final garantDocs = await userDocRef
          .collection('profil_locataire')
          .doc(docId)
          .collection('garants')
          .get();

      for (var doc in garantDocs.docs) {
        garants.add(
            GuarantorInfo.fromMap(doc.data())); // <-- on passe le docId ici
      }
    } catch (e) {
      print('Erreur lors de la récupération des garants : $e');
    }

    return garants;
  }

  static Future<GuarantorInfo?> getUniqueGarant(
      String uid, String garantId) async {
    try {
      // Récupérer le document User correspondant au uid
      final userQuery = await FirebaseFirestore.instance
          .collection('User')
          .where('uid', isEqualTo: uid)
          .get();

      if (userQuery.docs.isEmpty) return null;

      final userDocRef = userQuery.docs.first.reference;

      // Récupérer un seul document dans la sous-collection 'profil_locataire'
      final profilQuery =
          await userDocRef.collection('profil_locataire').limit(1).get();

      if (profilQuery.docs.isEmpty) return null;

      final profilDocRef = profilQuery.docs.first.reference;

      // Accéder à la sous-collection 'garants' de ce profil, et récupérer le garant par son ID
      final garantDoc =
          await profilDocRef.collection('garants').doc(garantId).get();

      if (!garantDoc.exists) return null;

      return GuarantorInfo.fromMap(garantDoc.data()!);
    } catch (e) {
      print('Erreur lors de la récupération du garant unique : $e');
      return null;
    }
  }

  static Future<GuarantorInfo?> getGarantWithInfo(String uid) async {
    try {
      // Rechercher l'utilisateur dans Firestore
      QuerySnapshot<Map<String, dynamic>> userDocRef = await FirebaseFirestore
          .instance
          .collection("User")
          .where("uid", isEqualTo: uid)
          .get();

      if (userDocRef.docs.isNotEmpty) {
        DocumentSnapshot<Map<String, dynamic>> userDoc = userDocRef.docs.first;
        Map<String, dynamic> userMap = userDoc.data()!;

        User user = User.fromMap(userMap);

        // Récupération des informations supplémentaires
        QuerySnapshot<Map<String, dynamic>> userInfoQuerySnapshot =
            await userDoc.reference.collection("profil_locataire").get();

        Map<String, dynamic> userInfoMap = userInfoQuerySnapshot.docs.isNotEmpty
            ? userInfoQuerySnapshot.docs.first.data()
            : {};

        return GuarantorInfo(
          name: user.name,
          surname: user.surname,
          email: user.email,
          birthday: user.birthday,
          incomes: (userInfoMap['revenus'] as List<dynamic>?)
                  ?.map(
                      (e) => IncomeEntry.fromMap(Map<String, dynamic>.from(e)))
                  .toList() ??
              [],
          jobIncomes: (userInfoMap['activities'] as List<dynamic>?)
                  ?.map((e) => JobEntry.fromMap(Map<String, dynamic>.from(e)))
                  .toList() ??
              [],
          dependent: userInfoMap['dependent'] ?? 0,
          familySituation: userInfoMap['familySituation'] ?? "",
          nationality: user.nationality,
          phone: userInfoMap['phone'] ?? "",
          sex: user.sex,
          placeOfborn: user.placeOfborn,
        );
      } else {
        print("Aucun utilisateur trouvé avec l'ID '$uid'.");
      }
    } catch (e) {
      print("Erreur lors de la récupération de l'utilisateur : $e");
    }

    return null;
  }

  static Future<bool> deleteGarant(String uid, String garantId) async {
    try {
      final profilSnapshot = await FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .collection('profil_locataire')
          .limit(1)
          .get();

      if (profilSnapshot.docs.isEmpty) {
        print("Aucun profil locataire trouvé.");
        return false;
      }

      final profilDocId = profilSnapshot.docs.first.id;

      print("Suppression du garant $garantId dans profil $profilDocId");

      await FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .collection('profil_locataire')
          .doc(profilDocId)
          .collection('garants')
          .doc(garantId)
          .delete();

      print('Garant supprimé avec succès');
      return true;
    } catch (e) {
      print('Erreur lors de la suppression du garant : $e');
      return false;
    }
  }

  static Future<void> shareFile(DemandeLoc demande, String uid) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .collection('demandes_loc')
          .doc(); // Firestore génère un ID unique

      await docRef.set(demande.toJson());

      print('DemandeLoc ajoutée avec succès avec l\'ID ${docRef.id}');
    } catch (e) {
      print('Erreur lors de l\'ajout de la demande de location : $e');
    }
  }

  static Future<List<DemandeLoc>> getDemande(String uid) async {
    List<DemandeLoc> demandes = [];
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .collection('demandes_loc')
          .get();

      for (var doc in querySnapshot.docs) {
        demandes.add(DemandeLoc.fromJson(doc.data(), id: doc.id));
      }

      print("demande : $demandes");
      return demandes;
    } catch (e) {
      print('Erreur lors de la récupération des demandes de location : $e');
      return []; // retourne une liste vide en cas d'erreur
    }
  }

  static Future<void> deleteDemande(String uid, String demandeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .collection('demandes_loc')
          .doc(demandeId)
          .delete();
      print('Demande supprimée avec succès : $demandeId');
    } catch (e) {
      print('Erreur lors de la suppression de la demande : $e');
      // Tu peux aussi propager l'erreur si besoin avec throw
    }
  }

  static Future<User?> getUserWithEmailOrRefApp(
      String? destinataireEmail, String? refAPP) async {
    try {
      // Recherche par email si fourni
      if (destinataireEmail != null && destinataireEmail.isNotEmpty) {
        QuerySnapshot<Map<String, dynamic>> emailQuery = await FirebaseFirestore
            .instance
            .collection("User")
            .where("email", isEqualTo: destinataireEmail)
            .limit(1)
            .get();

        if (emailQuery.docs.isNotEmpty) {
          print("UTITLISATEUR TROUVE");
          return User.fromMap(emailQuery.docs.first.data());
        }
      }

      // Sinon recherche par refAPP si fourni
      if (refAPP != null && refAPP.isNotEmpty) {
        QuerySnapshot<Map<String, dynamic>> refAppQuery =
            await FirebaseFirestore.instance
                .collection("User")
                .where("refUserApp", isEqualTo: refAPP)
                .limit(1)
                .get();

        if (refAppQuery.docs.isNotEmpty) {
          return User.fromMap(refAppQuery.docs.first.data());
        }
      }

      // Si rien trouvé
      return null;
    } catch (e) {
      print("UTITLISATEUR NON TROUVE");
      print("Erreur lors de la recherche de l'utilisateur : $e");
      return null;
    }
  }

  static Future<void> addLotToUser({
    required String userId,
    required String lotId,
    String? companyName,
    String? intendedFor,
    String? statutResident,
    Timestamp? entryDate,
    String colorSelected = "ff48775b",
    String nameLot = "",
  }) async {
    try {
      final userLotRef = FirebaseFirestore.instance
          .collection("User")
          .doc(userId)
          .collection("lots")
          .doc(lotId);

      Map<String, dynamic> lotData = {
        "lotId": lotId,
        "colorSelected": colorSelected,
        "nameLot": nameLot,
        if (companyName != null) "companyName": companyName,
        if (intendedFor != null) "intendedFor": intendedFor,
        if (statutResident != null) "StatutResident": statutResident,
        if (entryDate != null) "entryDate": entryDate,
      };

      await userLotRef.set(lotData, SetOptions(merge: true));

      print(
          "Lot $lotId ajouté ou mis à jour avec succès pour l'utilisateur $userId.");
    } catch (e) {
      print("Erreur lors de l'ajout du lot à l'utilisateur : $e");
      rethrow;
    }
  }

  static Future<void> markDemandeAsRead(String userId, String demandeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('User')
          .doc(userId)
          .collection('demandes_loc')
          .doc(demandeId)
          .update({'open': true});

      print('le champs open a été mise a jour');
    } catch (e) {
      print('Erreur lors de la mise à jour de open : $e');
    }
  }
}
