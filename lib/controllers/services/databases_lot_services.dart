import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:flutter/material.dart';

class DataBasesLotServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;

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

      print("Successfully completed");
    } catch (e) {
      print("Error completing in getLotByIduser2 function: $e");
    }

    return lots;
  }

  Future<List<Lot>> getLotByResidence(String residenceId) async {
    List<Lot> lots = [];
    try {
      // Récupérer la référence de la collection "Residence" basée sur le nom de la résidence
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection("Residence")
              .where("id", isEqualTo: residenceId)
              .get();

      // Vérifier si une résidence correspondant au nom existe
      if (querySnapshot.docs.isNotEmpty) {
        // Récupérer la référence de la résidence trouvée
        DocumentSnapshot<Map<String, dynamic>> residenceDoc =
            querySnapshot.docs.first;

        // Récupérer les lots de la résidence spécifique
        QuerySnapshot<Map<String, dynamic>> lotQuerySnapshot =
            await residenceDoc.reference.collection("lot").get();

        // Parcourir chaque document de la collection "lot"
        for (QueryDocumentSnapshot<Map<String, dynamic>> lotDoc
            in lotQuerySnapshot.docs) {
          // Convertir chaque document en objet Lot
          lots.add(Lot.fromMap(lotDoc.data()));
        }
      } else {
        print(
            "Aucune résidence correspondant au nom '$residenceId' n'a été trouvée.");
      }
    } catch (e) {
      print("Impossible de récupérer les lots - erreur : $e");
    }
    return lots;
  }

  Future<Lot?> getUniqueLot(
      String residenceId, String bat, String numlot) async {
    Lot? lot;

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection("Residence")
        .where("id", isEqualTo: residenceId)
        .get();

    // Vérifier si une résidence correspondant au nom existe
    if (querySnapshot.docs.isNotEmpty) {
      // Récupérer la référence de la résidence trouvée
      DocumentSnapshot<Map<String, dynamic>> residenceDoc =
          querySnapshot.docs.first;

      QuerySnapshot<Map<String, dynamic>> lotQuerySnapshot = await residenceDoc
          .reference
          .collection("lot")
          .where("batiment", isEqualTo: bat)
          .where('lot', isEqualTo: numlot)
          .get();

      if (lotQuerySnapshot.docs.isNotEmpty) {
        // Construction de l'objet Lot à partir des données récupérées
        lot = Lot.fromMap(lotQuerySnapshot.docs.first.data());
      }
    }
    return lot;
  }

  Future<int> countLocatairesExcludingUser(String numUser) async {
    // Récupérer les lots par ID d'utilisateur
    List<Lot?> lots = await getLotByIdUser(numUser);

    int count = 0; // Compteur de locataires

    // Parcourir chaque lot
    for (Lot? lot in lots) {
      if (lot != null) {
        dynamic idLocataire = lot.idLocataire;

        if (idLocataire is List) {
          // Si idLocataire est une liste, comptez les locataires en excluant numUser
          count += idLocataire.where((id) => id != numUser).length;
        } else if (idLocataire is String) {
          // Si idLocataire est une chaîne, vérifiez si elle n'est pas égale à numUser
          if (idLocataire != numUser) {
            count++;
          }
        }
      }
    }

    return count; // Retourner le nombre de locataires
  }

  Future<void> updateLotColor(
      String residenceId, String refLot, Color newColor) async {
    try {
      // Récupérer la référence du lot à mettre à jour
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("Residence")
          .doc(residenceId)
          .collection("lot")
          .where('refLot', isEqualTo: refLot)
          .get();

      // Vérifier si un document correspondant a été trouvé
      if (querySnapshot.docs.isNotEmpty) {
        // Récupérer la référence du document du lot
        DocumentReference lotRef = querySnapshot.docs[0].reference;

        // Extraire le code hexadécimal de la couleur
        String hexColor = extractHexFromColor(newColor);

        // Mettre à jour le champ colorSelected du document
        await lotRef.update({
          'colorSelected': hexColor,
        });

        print('Couleur $hexColor du lot $refLot mise à jour avec succès.');
      } else {
        print(
            'Aucun lot trouvé avec la référence $refLot dans la résidence $residenceId.');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de la couleur du lot $refLot : $e');
      throw e; // Vous pouvez gérer l'erreur comme nécessaire
    }
  }

  String extractHexFromColor(Color color) {
    return color.value.toRadixString(16).padLeft(8, '0');
  }
}
