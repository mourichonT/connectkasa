import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/generate_ref_user_app.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/models/pages_models/user_temp.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class DataBasesUserServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<UserTemp> setUser(UserTemp newUser, String? lotId, String? companyName,
      String? intentedFor, String? statutResident) async {
    try {
      // Génère `refUserApp` unique
      String refUserApp = await generateUniqueRefUserApp(db, newUser.uid);

      // Ajoute refUserApp à l'objet utilisateur
      Map<String, dynamic> userData = newUser.toMap();
      userData['refUserApp'] = refUserApp; // ✅ Ajout de `refUserApp`

      // Met à jour ou crée l'utilisateur dans Firestore
      await db.collection("User").doc(newUser.uid).set(
            userData,
            SetOptions(merge: true), // Fusionner au lieu d'écraser
          );

      // Ajoute les informations sur le lot si `lotId` est défini
      if (lotId != null) {
        await db
            .collection("User")
            .doc(newUser.uid)
            .collection("lots")
            .doc(lotId)
            .set({
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

  static Future<void> updateUserField(
      {required String uid,
      required String field,
      String? value,
      bool? newBool}) async {
    try {
      // Utilise .where() pour filtrer l'utilisateur par son UID
      var querySnapshot = await FirebaseFirestore.instance
          .collection('User')
          .where('uid', isEqualTo: uid) // Filtrage par l'UID
          .get();

      // Vérifie s'il y a des utilisateurs correspondants
      if (querySnapshot.docs.isNotEmpty) {
        // On récupère le premier document trouvé
        var doc = querySnapshot.docs.first;
        // Mise à jour du champ spécifique
        await doc.reference.update({field: value ?? newBool});
      } else {
        throw Exception('Utilisateur non trouvé');
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du champ $field: $e');
    }
  }

  Future<User?> getUserById(String numUser) async {
    User? user;
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection("User")
              .where("uid", isEqualTo: numUser)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        // S'il y a des documents correspondants, prenez le premier
        user = User.fromMap(querySnapshot.docs.first.data());
      }
    } catch (e) {
      print("Error completing: $e");
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

        // Récupérer l'utilisateur depuis Firebase Auth
        String? email;
        auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;

        if (firebaseUser != null && firebaseUser.uid == userId) {
          email = firebaseUser.email;
        } else {
          print(
              "L'utilisateur courant n'est pas celui recherché. Tentative de récupération directe...");
          // Tentative de récupération de l'e-mail à partir de Firebase Admin (si autorisé).
          // Nécessite un contexte serveur ou une configuration spéciale pour accéder à admin.auth().
          // Exemple à adapter si Firebase Admin est disponible.
        }

        // Récupération des informations supplémentaires de la sous-collection
        QuerySnapshot<Map<String, dynamic>> userInfoQuerySnapshot =
            await userDoc.reference.collection("informationConf").get();

        Map<String, dynamic> userInfoMap = userInfoQuerySnapshot.docs.isNotEmpty
            ? userInfoQuerySnapshot.docs.first.data()
            : {};

        return UserInfo(
          privacyPolicy: user.privacyPolicy,
          name: user.name,
          surname: user.surname,
          email: email ?? "Non spécifié",
          uid: user.uid,
          pseudo: user.pseudo,
          profession: user.profession,
          profilPic: user.profilPic ?? "",
          approved: user.approved,
          birthday: userInfoMap['Birthday'] ??
              Timestamp.fromDate(DateTime(1900, 1, 1)),
          amountFamilyAllowance: userInfoMap['amount_FamilyAllowance'] ?? "",
          amountAdditionalRevenu: userInfoMap['amount_additionalRevenu'] ?? "",
          amountHousingAllowance: userInfoMap['amount_housingAllowance'] ?? "",
          dependent: userInfoMap['dependent'] ?? 0,
          familySituation: userInfoMap['familySituation'] ?? "",
          nationality: user.nationality,
          phone: userInfoMap['phone'] ?? "",
          salary: userInfoMap['salary'] ?? "",
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
        throw Exception('Aucun utilisateur trouvé avec l\'ID $uid');
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
      rethrow;
    }
  }
}
