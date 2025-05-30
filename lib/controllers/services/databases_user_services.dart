import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/generate_ref_user_app.dart';
import 'package:connect_kasa/models/enum/income_entry.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/models/pages_models/user_temp.dart';
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
      String refUserApp = await generateUniqueRefUserApp(db, newUser.uid);

      // Ajoute refUserApp à l'objet utilisateur
      Map<String, dynamic> userData = newUser.toMap();
      userData['refUserApp'] = refUserApp; // ✅ Ajout de `refUserApp`
// Fusionner les données utilisateur et le champ informationsCorrectes
      Map<String, dynamic> fullUserData = {
        ...userData,
        "informationsCorrectes": informationsCorrectes,
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
          if (fcmToken != null) 'token': fcmToken,
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
          profession: userInfoMap['profession'] ?? "",
          profilPic: user.profilPic ?? "",
          approved: user.approved,
          birthday: user.birthday,
          incomes: (userInfoMap['revenus'] as List<dynamic>?)
                  ?.map(
                      (e) => IncomeEntry.fromMap(Map<String, dynamic>.from(e)))
                  .toList() ??
              [],
          dependent: userInfoMap['dependent'] ?? 0,
          familySituation: userInfoMap['familySituation'] ?? "",
          nationality: user.nationality,
          phone: userInfoMap['phone'] ?? "",
          typeContract: userInfoMap['typeContract'] ?? "",
          entryJobDate: userInfoMap['entryJobDate'] ??
              Timestamp.fromDate(DateTime(1900, 1, 1)),
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

      // Liste des sous-collections à supprimer — à adapter selon ton modèle
      final List<String> subcollections = [
        'documents',
        'lots'
        // ajoute ici toutes les sous-collections possibles
      ];

      for (String subCol in subcollections) {
        final subColRef = userRef.collection(subCol);
        final subColSnapshot = await subColRef.get();

        for (final doc in subColSnapshot.docs) {
          await doc.reference.delete();
          print("🗑️ ${subCol}/${doc.id} supprimé");
        }
      }

      // Supprime le document principal après avoir vidé les sous-collections
      await userRef.delete();
      print("✅ Utilisateur et ses sous-collections supprimés avec succès");
    } catch (e) {
      print('❌ Erreur lors de la suppression de l\'utilisateur: $e');
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
        "profession": updatedUser.profession ?? "",
        "revenus": updatedUser.incomes.map((e) => e.toMap()).toList(),
        "dependent": updatedUser.dependent,
        "familySituation": updatedUser.familySituation,
        "phone": updatedUser.phone,
        "typeContract": updatedUser.typeContract,
        "entryJobDate": updatedUser.entryJobDate,
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
}
