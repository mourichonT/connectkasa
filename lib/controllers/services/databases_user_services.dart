import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/models/pages_models/user_temp.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DataBasesUserServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<UserTemp> setUserTemp(UserTemp newUser) async {
    try {
      // Si aucun post correspondant n'est trouvé, ajouter le nouveau post à la collection
      await db.collection("UserTemp").add(newUser.toMap());
    } catch (e) {
      print("Impossible de poster le nouvel user: $e");
    }

    return newUser;
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
          String idProprietaire = lotDoc.data()["idProprietaire"];

          // Ajouter chaque élément de idLocataire et idProprietaire à la liste si non nuls
          if (idLocataire != null) {
            users.addAll(idLocataire);
          }
          if (idProprietaire != null &&
              (idLocataire == null || !idLocataire.contains(uid))) {
            users.add(idProprietaire);
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
}
