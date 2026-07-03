import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';

class DataBasesLotServices {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  Future<List<Lot>> _fetchLotsByUser(String userID) async {
    List<Lot> lots = [];
    try {
      // Une seule lecture de User/{uid}/lots, puis un accès direct par ID à
      // chaque résidence/lot concerné — plus de parcours de toutes les
      // résidences et tous leurs lots (O(nombre de lots de l'utilisateur)
      // au lieu de O(résidences × lots)).
      QuerySnapshot<Map<String, dynamic>> userLotsSnapshot = await db
          .collection("User")
          .doc(userID)
          .collection("lots")
          .get();

      for (QueryDocumentSnapshot<Map<String, dynamic>> userLotDoc
          in userLotsSnapshot.docs) {
        final userLotData = userLotDoc.data();
        final String? residenceId = userLotData['residenceId'];
        final String lotId = userLotDoc.id;

        if (residenceId == null) {
          print("Lot $lotId sans residenceId, ignoré.");
          continue;
        }

        final residenceSnapshot =
            await db.collection("Residence").doc(residenceId).get();
        final lotSnapshot = await db
            .collection("Residence")
            .doc(residenceId)
            .collection("lot")
            .doc(lotId)
            .get();

        if (!residenceSnapshot.exists || !lotSnapshot.exists) {
          print("Résidence ou lot introuvable pour $lotId ($residenceId).");
          continue;
        }

        Lot lot = Lot.fromMap(lotSnapshot.data()!);
        lot.residenceData = residenceSnapshot.data() ?? {};
        lot.residenceId = residenceId;
        // colorSelected/nameLot sont déjà dans le doc User/lots, pas besoin
        // d'un second aller-retour vers getLotDetails.
        lot.userLotDetails = {
          "colorSelected": userLotData['colorSelected'],
          "nameLot": userLotData['nameLot'],
        };

        lots.add(lot);
      }

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
      String userUid, String id, Color newColor) async {
    try {
      DocumentReference lotRef =
          db.collection("User").doc(userUid).collection("lots").doc(id);

      String hexColor = extractHexFromColor(newColor);

      await lotRef.update({'colorSelected': hexColor});

    } catch (e) {
      print('Erreur lors de la mise à jour de la couleur du lot $id : $e');
      rethrow;
    }
  }

  Future<void> updateNameLot(
      String userUid, String id, String newName) async {
    print(" USER : $userUid, ID: $id, newName : $newName ");

    try {
      DocumentReference lotRef =
          db.collection("User").doc(userUid).collection("lots").doc(id);

      await lotRef.update({'nameLot': newName});

      print('Le nom $newName du lot $id mise à jour avec succès.');
    } catch (e) {
      print('Erreur lors de la mise à jour de la couleur du lot $id : $e');

      rethrow;
    }
  }

  Future<bool> updateLot(
      String residenceId, String idLot, String field, dynamic upDate) async {
    try {
      DocumentReference lotRef = db
          .collection("Residence")
          .doc(residenceId)
          .collection("lot")
          .doc(idLot);

      final snapshot = await lotRef.get();

      if (snapshot.exists) {
        await lotRef.update({field: upDate});

        print(
            'Le champ $field du lot $idLot mis à jour avec succès par $upDate.');
        return true;
      } else {
        print(
            'Aucun lot trouvé avec l\'id $idLot dans la résidence $residenceId.');
        return false;
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du champ du lot $idLot : $e');
      rethrow;
    }
  }

  // Applique la décision de remplacement ou d'ajout de locataire au lot
  Future<void> _applyTenantChange(
      DocumentReference lotRef,
      String residenceId,
      String idLot,
      String tenantId,
      bool replace) async {
    await DataBasesUserServices.addLotToUser(
        userId: tenantId,
        lotId: idLot,
        residenceId: residenceId,
        statutResident: "Locataire",
        entryDate: Timestamp.now());

    if (replace) {
      await lotRef.update({'idLocataire': [tenantId]});
    } else {
      await lotRef.update({'idLocataire': FieldValue.arrayUnion([tenantId])});
    }

    // Dénormalisé pour firestore.rules : permet au(x) propriétaire(s) de ce
    // lot de consulter le dossier locataire (identité, profil, garants).
    await _recomputeSharedWithLandlords(tenantId);
  }

  // Reconstruit entièrement User/{tenantId}.sharedWithLandlords à partir des
  // lots où tenantId est effectivement dans idLocataire, plutôt qu'un
  // arrayUnion/Remove incrémental : évite les incohérences si un même
  // propriétaire partage plusieurs lots avec ce locataire.
  Future<void> _recomputeSharedWithLandlords(String tenantId) async {
    final lots = await _fetchLotsByUser(tenantId);
    final Set<String> landlordUids = {};

    for (final lot in lots) {
      final isTenantHere = lot.idLocataire?.contains(tenantId) ?? false;
      if (isTenantHere && lot.idProprietaire != null) {
        landlordUids.addAll(lot.idProprietaire!);
      }
    }

    await db.collection("User").doc(tenantId).set({
      "sharedWithLandlords": landlordUids.toList(),
    }, SetOptions(merge: true));
  }

  // Reconstruit entièrement User/{userId}.residencesIds à partir de
  // User/{userId}/lots, pour rester cohérent avec firestore.rules après un
  // retrait de lot (voir removeIdLocataire / removeIdProprietaire /
  // removeUserFromAllLots).
  Future<void> _recomputeResidencesIds(String userId) async {
    final userLotsSnapshot =
        await db.collection("User").doc(userId).collection("lots").get();

    final residenceIds = userLotsSnapshot.docs
        .map((doc) => doc.data()['residenceId'] as String?)
        .whereType<String>()
        .toSet();

    await db.collection("User").doc(userId).set({
      "residencesIds": residenceIds.toList(),
    }, SetOptions(merge: true));
  }

  // La décision remplacer/ajouter est prise par la vue (BuildContext requis pour le dialog)
  Future<bool> addTenant(BuildContext context, String residenceId,
      String idLot, String tenantId) async {
    try {
      final lotRef = db
          .collection("Residence")
          .doc(residenceId)
          .collection("lot")
          .doc(idLot);

      final lotDoc = await lotRef.get();

      if (!lotDoc.exists) return false;

      final currentLocataires = List<dynamic>.from(lotDoc.get('idLocataire') ?? []);

      if (currentLocataires.contains(tenantId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ce locataire est déjà ajouté.")),
        );
        return false;
      }

      if (currentLocataires.isNotEmpty) {
        final result = await showDialog<String>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: MyTextStyle.lotName(
                  "Locataire déjà présent", Colors.black87, SizeFont.h2.size),
              content: MyTextStyle.lotName(
                  "Souhaitez-vous remplacer le locataire actuel ou ajouter un colocataire ?",
                  Colors.black87,
                  SizeFont.h3.size,
                  FontWeight.normal),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'replace'),
                  child: const Text("Remplacer"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, 'add'),
                  child: const Text("Ajouter"),
                ),
              ],
            );
          },
        );

        if (result == 'replace') {
          await _applyTenantChange(lotRef, residenceId, idLot, tenantId, true);
          return true;
        } else if (result == 'add') {
          await _applyTenantChange(lotRef, residenceId, idLot, tenantId, false);
          return true;
        }
        return false;
      } else {
        await _applyTenantChange(lotRef, residenceId, idLot, tenantId, false);
        return true;
      }
    } catch (e) {
      print("Erreur lors de l'ajout du locataire : $e");
      rethrow;
    }
  }

  String extractHexFromColor(Color color) {
    return color.value.toRadixString(16).padLeft(8, '0');
  }

  Future<void> removeUserFromAllLots(String userID) async {
    List<Lot> lots = await getLotByIdUser(userID);

    for (Lot lot in lots) {
      // Vérifie que l'utilisateur est bien dans la liste des locataires
      if (lot.idLocataire != null &&
          ((lot.idLocataire is List && lot.idLocataire!.contains(userID)) ||
              (lot.idLocataire is String && lot.idLocataire == userID))) {
        // Appelle la méthode de suppression
        await removeIdLocataire(lot.residenceId!, lot.id!, userID);
      }

      // Vérifie que l'utilisateur est bien dans la liste des propriétaires
      if (lot.idProprietaire != null &&
          ((lot.idProprietaire is List &&
                  lot.idProprietaire!.contains(userID)) ||
              (lot.idProprietaire is String &&
                  lot.idProprietaire == userID))) {
        await removeIdProprietaire(lot.residenceId!, lot.id!, userID);
      }
    }

    // Dénormalisé pour firestore.rules : residencesIds doit refléter les
    // lots restants de l'utilisateur une fois les retraits ci-dessus faits
    // (sharedWithLandlords est déjà recalculé par removeIdLocataire).
    await _recomputeResidencesIds(userID);
  }

  Future<void> removeIdLocataire(
      String residenceId, String idLot, String idLocataireToRemove) async {
    try {
      // Accès direct au document du lot par son ID
      DocumentReference lotRef = db
          .collection("Residence")
          .doc(residenceId)
          .collection("lot")
          .doc(idLot);

      final lotSnapshot = await lotRef.get();

      if (lotSnapshot.exists) {
        // Récupère les données actuelles du document
        Map<String, dynamic> lotData =
            lotSnapshot.data() as Map<String, dynamic>;

        // Récupère la liste actuelle des ID de locataires
        List<dynamic> idLocataires = List.from(lotData['idLocataire'] ?? []);

        // Supprime l'ID à retirer
        idLocataires.remove(idLocataireToRemove);

        // Met à jour le champ 'idLocataire' avec la nouvelle liste
        await lotRef.update({'idLocataire': idLocataires});

        // Dénormalisé pour firestore.rules : ce locataire n'a peut-être plus
        // aucun lot commun avec le(s) propriétaire(s) de celui-ci.
        await _recomputeSharedWithLandlords(idLocataireToRemove);

        print(
            'L\'ID $idLocataireToRemove a été supprimé de la liste des locataires du lot $idLot.');
      } else {
        print(
            'Aucun lot trouvé avec l\'id $idLot dans la résidence $residenceId.');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du lot $idLot : $e');
      rethrow;
    }
  }

  Future<void> removeIdProprietaire(String residenceId, String idLot,
      String idProprietaireToRemove) async {
    try {
      // Accès direct au document du lot par son ID
      DocumentReference lotRef = db
          .collection("Residence")
          .doc(residenceId)
          .collection("lot")
          .doc(idLot);

      final lotSnapshot = await lotRef.get();

      if (lotSnapshot.exists) {
        // Récupère les données actuelles du document
        Map<String, dynamic> lotData =
            lotSnapshot.data() as Map<String, dynamic>;

        // Récupère la liste actuelle des ID de propriétaires
        List<dynamic> idProprietaires =
            List.from(lotData['idProprietaire'] ?? []);

        // Supprime l'ID à retirer
        idProprietaires.remove(idProprietaireToRemove);

        // Met à jour le champ 'idProprietaire' avec la nouvelle liste
        await lotRef.update({'idProprietaire': idProprietaires});

        // Dénormalisé pour firestore.rules : les locataires actuels de ce
        // lot ne doivent plus voir ce propriétaire dans sharedWithLandlords.
        final idLocataires = List<String>.from(lotData['idLocataire'] ?? []);
        for (final tenantId in idLocataires) {
          await _recomputeSharedWithLandlords(tenantId);
        }

        print(
            'L\'ID $idProprietaireToRemove a été supprimé de la liste des propriétaires du lot $idLot.');
      } else {
        print(
            'Aucun lot trouvé avec l\'id $idLot dans la résidence $residenceId.');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du lot $idLot : $e');
      rethrow;
    }
  }

  Future<void> createOrUpdateLot(String residenceId, Lot lot) async {
    try {
      final lotRef = FirebaseFirestore.instance
          .collection("Residence")
          .doc(residenceId)
          .collection("lot");

      // Vérifier si un lot avec le même idLot existe déjà
      final query =
          await lotRef.where("id", isEqualTo: lot.id).limit(1).get();

      if (query.docs.isNotEmpty) {
        // Mise à jour
        final docId = query.docs.first.id;
        await lotRef.doc(docId).update(lot.toJsonForDb());
      } else {
        // Création : on reporte l'ID du document généré dans son propre champ id
        final newDocRef = await lotRef.add(lot.toJsonForDb());
        await newDocRef.update({'id': newDocRef.id});
      }
    } catch (e) {
      print("Erreur Firestore createOrUpdateLot: $e");
      rethrow;
    }
  }

  Future<void> deleteLot(String residenceId, String idLot) async {
    try {
      final lotRef = FirebaseFirestore.instance
          .collection("Residence")
          .doc(residenceId)
          .collection("lot");

      // Trouver le document à supprimer par idLot
      final query =
          await lotRef.where("id", isEqualTo: idLot).limit(1).get();

      if (query.docs.isNotEmpty) {
        final docId = query.docs.first.id;
        await lotRef.doc(docId).delete();
        print("Lot avec l'id '$idLot' supprimé.");
      } else {
        print("Aucun lot trouvé avec l'id '$idLot'.");
      }
    } catch (e) {
      print("Erreur Firestore deleteLot: $e");
      rethrow;
    }
  }
}
