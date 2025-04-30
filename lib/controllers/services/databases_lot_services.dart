import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';

class DataBasesLotServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  Future<List<Lot>> _fetchLotsByUser(String userID) async {
    List<Lot> lots = [];
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        CollectionReference residenceRef =
            FirebaseFirestore.instance.collection("Residence");

        QuerySnapshot<Map<String, dynamic>> querySnapshot =
            await residenceRef.get() as QuerySnapshot<Map<String, dynamic>>;

        for (QueryDocumentSnapshot<Map<String, dynamic>> residenceDoc
            in querySnapshot.docs) {
          Map<String, dynamic> residenceData = residenceDoc.data();
          String residenceId = residenceDoc.id;

          QuerySnapshot<Map<String, dynamic>> lotQuerySnapshot =
              await residenceDoc.reference.collection("lot").get();

          for (QueryDocumentSnapshot<Map<String, dynamic>> doc
              in lotQuerySnapshot.docs) {
            dynamic idProprietaire = doc.data()["idProprietaire"];
            dynamic idLocataire = doc.data()["idLocataire"];

            if ((idProprietaire is List && idProprietaire.contains(userID)) ||
                (idLocataire is List && idLocataire.contains(userID)) ||
                (idProprietaire is String && idProprietaire == userID) ||
                (idLocataire is String && idLocataire == userID)) {
              Lot? lot = Lot.fromMap(doc.data());
              lot.residenceData = residenceData;
              lot.residenceId = residenceId;

              // Construction correcte du idLot à partir de residenceData['id']
              String idLot = "${residenceData['id']}-${doc.data()['refLot']}";

              // Récupération des détails utilisateur du lot
              Map<String, dynamic>? userLotDetails =
                  await DataBasesUserServices().getLotDetails(userID, idLot);

              if (userLotDetails != null) {
                lot.userLotDetails =
                    userLotDetails; // Assure-toi que ce champ existe dans Lot
              }

              lots.add(lot);
            }
          }
        }
      });

      print("Lots récupérés avec succès.");
    } catch (e) {
      print("Erreur lors de la récupération des lots utilisateur : $e");
    }

    return lots;
  }

  Future<List<Lot>> getLotByIdUser(String numUser) async {
    return await _fetchLotsByUser(numUser);
  }

  Future<Lot> getFirstLotByUserId(String numUser) async {
    List<Lot> lots = await _fetchLotsByUser(numUser);
    if (lots.isNotEmpty) {
      return lots.first;
    } else {
      throw Exception("Aucun lot trouvé pour l'utilisateur $numUser");
    }
  }

  Future<List<Lot>> getLotByResidence(String residenceId) async {
    List<Lot> lots = [];
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .where("id", isEqualTo: residenceId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot<Map<String, dynamic>> residenceDoc =
            querySnapshot.docs.first;

        QuerySnapshot<Map<String, dynamic>> lotQuerySnapshot =
            await residenceDoc.reference.collection("lot").get();

        for (var lotDoc in lotQuerySnapshot.docs) {
          lots.add(Lot.fromMap(lotDoc.data()));
        }
      } else {
        print("Aucune résidence correspondant à l'id '$residenceId' trouvée.");
      }
    } catch (e) {
      print("Impossible de récupérer les lots - erreur : $e");
    }
    return lots;
  }

  Future<Lot?> getUniqueLot(
      String residenceId, String bat, String numlot) async {
    Lot? lot;

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await db
          .collection("Residence")
          .where("id", isEqualTo: residenceId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot<Map<String, dynamic>> residenceDoc =
            querySnapshot.docs.first;

        QuerySnapshot<Map<String, dynamic>> lotQuerySnapshot =
            await residenceDoc.reference
                .collection("lot")
                .where("batiment", isEqualTo: bat)
                .where("lot", isEqualTo: numlot)
                .get();

        if (lotQuerySnapshot.docs.isNotEmpty) {
          lot = Lot.fromMap(lotQuerySnapshot.docs.first.data());
        }
      }
    } catch (e) {
      print("Erreur dans getUniqueLot : $e");
    }

    return lot;
  }

  Future<int> countLocatairesExcludingUser(String numUser) async {
    List<Lot> lots = await _fetchLotsByUser(numUser);

    int count = 0;
    for (Lot lot in lots) {
      dynamic idLocataire = lot.idLocataire;

      if (idLocataire is List) {
        count += idLocataire.where((id) => id != numUser).length;
      } else if (idLocataire is String && idLocataire != numUser) {
        count++;
      }
    }

    return count;
  }

  Future<void> updateLotColor(
      String userUid, String refLot, Color newColor) async {
    print(" USER : $userUid, REFLOT: $refLot, newCOLOR : $newColor ");
    try {
      DocumentReference lotRef =
          db.collection("User").doc(userUid).collection("lots").doc(refLot);

      String hexColor = extractHexFromColor(newColor);

      await lotRef.update({'colorSelected': hexColor});

      print('Couleur $hexColor du lot $refLot mise à jour avec succès.');
    } catch (e) {
      print('Erreur lors de la mise à jour de la couleur du lot $refLot : $e');
      rethrow;
    }
  }

  Future<void> updateNameLot(
      String userUid, String refLot, String newName) async {
    print(" USER : $userUid, REFLOT: $refLot, newName : $newName ");

    try {
      DocumentReference lotRef =
          db.collection("User").doc(userUid).collection("lots").doc(refLot);

      await lotRef.update({'nameLot': newName});

      print('Le nom $newName du lot $refLot mise à jour avec succès.');
    } catch (e) {
      print('Erreur lors de la mise à jour de la couleur du lot $refLot : $e');

      rethrow;
    }
  }

  Future<void> updateLot(
      String residenceId, String refLot, String field, String upDate) async {
    try {
      QuerySnapshot querySnapshot = await db
          .collection("Residence")
          .doc(residenceId)
          .collection("lot")
          .where('refLot', isEqualTo: refLot)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentReference lotRef = querySnapshot.docs[0].reference;

        await lotRef.update({field: upDate});

        print(
            'Le champ $field du lot $refLot mis à jour avec succès par $upDate.');
      } else {
        print(
            'Aucun lot trouvé avec la référence $refLot dans la résidence $residenceId.');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du champ du lot $refLot : $e');
      rethrow;
    }
  }

  String extractHexFromColor(Color color) {
    return color.value.toRadixString(16).padLeft(8, '0');
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:connect_kasa/models/pages_models/lot.dart';
// import 'package:flutter/material.dart';

// class DataBasesLotServices {
//   final FirebaseFirestore db = FirebaseFirestore.instance;

//   Future<List<Lot?>> getLotByIdUser(String numUser) async {
//     List<Lot?> lots = []; // Liste de lots
//     try {
//       // Commencer une transaction Firestore
//       await FirebaseFirestore.instance.runTransaction((transaction) async {
//         // Récupérer la référence de la collection "Residence"
//         CollectionReference residenceRef =
//             FirebaseFirestore.instance.collection("Residence");

//         // Récupérer les documents de la collection "Residence"
//         QuerySnapshot<Map<String, dynamic>> querySnapshot =
//             await residenceRef.get() as QuerySnapshot<Map<String, dynamic>>;

//         // Parcourir chaque document de la collection "Residence"
//         for (QueryDocumentSnapshot<Map<String, dynamic>> residenceDoc
//             in querySnapshot.docs) {
//           String residenceId = residenceDoc.id; // Identifiant du document
//           // Ajouter l'identifiant du document à la liste
//           //lots.add(residenceId);

//           // Récupérer les lots de chaque résidence
//           QuerySnapshot<Map<String, dynamic>> lotQuerySnapshot =
//               await residenceDoc.reference.collection("lot").get();

//           // Récupérer les données du document de la résidence
//           Map<String, dynamic> residenceData = residenceDoc.data();

//           // Vérifier si idProprietaire ou idLocataire contient numUser
//           // et récupérer les lots correspondants
//           for (QueryDocumentSnapshot<Map<String, dynamic>> doc
//               in lotQuerySnapshot.docs) {
//             dynamic idProprietaire = doc.data()["idProprietaire"];
//             dynamic idLocataire = doc.data()["idLocataire"];

//             if ((idProprietaire is List && idProprietaire.contains(numUser)) ||
//                 (idLocataire is List && idLocataire.contains(numUser)) ||
//                 (idProprietaire is String && idProprietaire == numUser) ||
//                 (idLocataire is String && idLocataire == numUser)) {
//               Lot? lot = Lot.fromMap(doc.data());
//               // Ajouter les données de la résidence à chaque lot
//               lot.residenceData = residenceData;
//               lot.residenceId = residenceId;
//               lots.add(lot); // Ajouter le lot correspondant à la liste
//             }
//           }
//         }
//       });

//       print("Successfully completed");
//     } catch (e) {
//       print("Error completing in getLotByIduser2 function: $e");
//     }

//     return lots;
//   }

//   Future<List<Lot>> getLotByResidence(String residenceId) async {
//     List<Lot> lots = [];
//     try {
//       // Récupérer la référence de la collection "Residence" basée sur le nom de la résidence
//       QuerySnapshot<Map<String, dynamic>> querySnapshot =
//           await FirebaseFirestore.instance
//               .collection("Residence")
//               .where("id", isEqualTo: residenceId)
//               .get();

//       // Vérifier si une résidence correspondant au nom existe
//       if (querySnapshot.docs.isNotEmpty) {
//         // Récupérer la référence de la résidence trouvée
//         DocumentSnapshot<Map<String, dynamic>> residenceDoc =
//             querySnapshot.docs.first;

//         // Récupérer les lots de la résidence spécifique
//         QuerySnapshot<Map<String, dynamic>> lotQuerySnapshot =
//             await residenceDoc.reference.collection("lot").get();

//         // Parcourir chaque document de la collection "lot"
//         for (QueryDocumentSnapshot<Map<String, dynamic>> lotDoc
//             in lotQuerySnapshot.docs) {
//           // Convertir chaque document en objet Lot
//           lots.add(Lot.fromMap(lotDoc.data()));
//         }
//       } else {
//         print(
//             "Aucune résidence correspondant au nom '$residenceId' n'a été trouvée.");
//       }
//     } catch (e) {
//       print("Impossible de récupérer les lots - erreur : $e");
//     }
//     return lots;
//   }

//   Future<Lot?> getUniqueLot(
//       String residenceId, String bat, String numlot) async {
//     Lot? lot;

//     QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
//         .instance
//         .collection("Residence")
//         .where("id", isEqualTo: residenceId)
//         .get();

//     // Vérifier si une résidence correspondant au nom existe
//     if (querySnapshot.docs.isNotEmpty) {
//       // Récupérer la référence de la résidence trouvée
//       DocumentSnapshot<Map<String, dynamic>> residenceDoc =
//           querySnapshot.docs.first;

//       QuerySnapshot<Map<String, dynamic>> lotQuerySnapshot = await residenceDoc
//           .reference
//           .collection("lot")
//           .where("batiment", isEqualTo: bat)
//           .where('lot', isEqualTo: numlot)
//           .get();

//       if (lotQuerySnapshot.docs.isNotEmpty) {
//         // Construction de l'objet Lot à partir des données récupérées
//         lot = Lot.fromMap(lotQuerySnapshot.docs.first.data());
//       }
//     }
//     return lot;
//   }

//   Future<int> countLocatairesExcludingUser(String numUser) async {
//     // Récupérer les lots par ID d'utilisateur
//     List<Lot?> lots = await getLotByIdUser(numUser);

//     int count = 0; // Compteur de locataires

//     // Parcourir chaque lot
//     for (Lot? lot in lots) {
//       if (lot != null) {
//         dynamic idLocataire = lot.idLocataire;

//         if (idLocataire is List) {
//           // Si idLocataire est une liste, comptez les locataires en excluant numUser
//           count += idLocataire.where((id) => id != numUser).length;
//         } else if (idLocataire is String) {
//           // Si idLocataire est une chaîne, vérifiez si elle n'est pas égale à numUser
//           if (idLocataire != numUser) {
//             count++;
//           }
//         }
//       }
//     }

//     return count; // Retourner le nombre de locataires
//   }

//   Future<void> updateLotColor(
//       String residenceId, String refLot, Color newColor) async {
//     try {
//       // Récupérer la référence du lot à mettre à jour
//       QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//           .collection("Residence")
//           .doc(residenceId)
//           .collection("lot")
//           .where('refLot', isEqualTo: refLot)
//           .get();

//       // Vérifier si un document correspondant a été trouvé
//       if (querySnapshot.docs.isNotEmpty) {
//         // Récupérer la référence du document du lot
//         DocumentReference lotRef = querySnapshot.docs[0].reference;

//         // Extraire le code hexadécimal de la couleur
//         String hexColor = extractHexFromColor(newColor);

//         // Mettre à jour le champ colorSelected du document
//         await lotRef.update({
//           'colorSelected': hexColor,
//         });

//         print('Couleur $hexColor du lot $refLot mise à jour avec succès.');
//       } else {
//         print(
//             'Aucun lot trouvé avec la référence $refLot dans la résidence $residenceId.');
//       }
//     } catch (e) {
//       print('Erreur lors de la mise à jour de la couleur du lot $refLot : $e');
//       rethrow; // Vous pouvez gérer l'erreur comme nécessaire
//     }
//   }

//   String extractHexFromColor(Color color) {
//     return color.value.toRadixString(16).padLeft(8, '0');
//   }

//   Future<void> updateLot(
//       String residenceId, String refLot, String field, String upDate) async {
//     try {
//       // Récupérer la référence du lot à mettre à jour
//       QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//           .collection("Residence")
//           .doc(residenceId)
//           .collection("lot")
//           .where('refLot', isEqualTo: refLot)
//           .get();

//       // Vérifier si un document correspondant a été trouvé
//       if (querySnapshot.docs.isNotEmpty) {
//         // Récupérer la référence du document du lot
//         DocumentReference lotRef = querySnapshot.docs[0].reference;

//         // Extraire le code hexadécimal de la couleur

//         // Mettre à jour le champ colorSelected du document
//         await lotRef.update({
//           field: upDate,
//         });

//         print(
//             'Le champ $field du lot $refLot mise à jour par $upDate avec succès.');
//       } else {
//         print(
//             'Aucun lot trouvé avec la référence $refLot dans la résidence $residenceId.');
//       }
//     } catch (e) {
//       print('Erreur lors de la mise à jour de la couleur du lot $refLot : $e');
//       rethrow; // Vous pouvez gérer l'erreur comme nécessaire
//     }
//   }

//   Future<Lot> getFirstLotByUserId(String numUser) async {
//     try {
//       // Commencer une transaction Firestore
//       return await FirebaseFirestore.instance
//           .runTransaction((transaction) async {
//         // Récupérer la référence de la collection "Residence"
//         CollectionReference residenceRef =
//             FirebaseFirestore.instance.collection("Residence");

//         // Récupérer les documents de la collection "Residence"
//         QuerySnapshot<Map<String, dynamic>> querySnapshot =
//             await residenceRef.get() as QuerySnapshot<Map<String, dynamic>>;

//         // Parcourir chaque document de la collection "Residence"
//         for (QueryDocumentSnapshot<Map<String, dynamic>> residenceDoc
//             in querySnapshot.docs) {
//           String residenceId = residenceDoc.id; // Identifiant du document

//           // Récupérer les lots de chaque résidence
//           QuerySnapshot<Map<String, dynamic>> lotQuerySnapshot =
//               await residenceDoc.reference.collection("lot").get();

//           // Récupérer les données du document de la résidence
//           Map<String, dynamic> residenceData = residenceDoc.data();

//           // Vérifier si idProprietaire ou idLocataire contient numUser
//           // et récupérer le premier lot correspondant
//           for (QueryDocumentSnapshot<Map<String, dynamic>> doc
//               in lotQuerySnapshot.docs) {
//             dynamic idProprietaire = doc.data()["idProprietaire"];
//             dynamic idLocataire = doc.data()["idLocataire"];

//             if ((idProprietaire is List && idProprietaire.contains(numUser)) ||
//                 (idLocataire is List && idLocataire.contains(numUser)) ||
//                 (idProprietaire is String && idProprietaire == numUser) ||
//                 (idLocataire is String && idLocataire == numUser)) {
//               Lot lot = Lot.fromMap(doc.data());
//               // Ajouter les données de la résidence au lot
//               lot.residenceData = residenceData;
//               lot.residenceId = residenceId;
//               return lot; // Retourne le premier lot trouvé
//             }
//           }
//         }
//         throw Exception(
//             "Aucun lot trouvé pour l'utilisateur $numUser"); // Lancer une exception si aucun lot n'est trouvé
//       });
//     } catch (e) {
//       print("Erreur dans getFirstLotByUserId: $e");
//       throw Exception(
//           "Erreur lors de la récupération du lot : $e"); // Gérer l'erreur proprement
//     }
//   }
// }
