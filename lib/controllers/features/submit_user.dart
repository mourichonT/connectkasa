import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/databases_docs_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/models/pages_models/user_temp.dart';
import 'package:flutter/material.dart';

import '../../models/pages_models/residence.dart';

class SubmitUser {
  static submitUser({
    required String emailUser,
    required String name,
    required String surname,
    required String newUserId,
    required String statutResident,
    required String intendedFor,
    required String typeChoice,
    required bool compagnyBuy,
    required Timestamp birthday,
    required String sex,
    required String nationality,
    required String placeOfborn,
    String? companyName,
    String? pseudo,

    // pour la class Document
    required Residence residence,
    required String lotId,
    String? docTypeID,
    String? docTypeJustif,
    String? docId,
    String? docBail,
    String? docinvest,
    String? imagepathIDrecto,
    String? imagepathIDverso,
    String? justifChoice,
    String? imagepathJustif,
    String? kbisPath,
  }) {
    DataBasesUserServices dataBasesUserServices = DataBasesUserServices();
    UserTemp newUser = UserTemp(
      email: emailUser,
      name: name,
      surname: surname,
      uid: newUserId,
      pseudo: pseudo,
      approved: false,
      //statutResident: statutResident,
      typeLot: typeChoice,
      birthday: birthday,
      sex: sex,
      nationality: nationality,
      placeOfborn: placeOfborn,
      //compagnyBuy: compagnyBuy,
    );
    print("----- Données reçues pour la création d'un utilisateur -----");
    print("Email: $emailUser");
    print("Nom: $name");
    print("Prénom: $surname");
    print("Pseudo: ${pseudo ?? "Non défini"}");
    print("ID Utilisateur: $newUserId");
    print("Statut Résident: $statutResident");
    print("Intended For: $intendedFor");
    print("Type de Lot: $typeChoice");
    print("Achat via Société: ${compagnyBuy ? "Oui" : "Non"}");
    print("Nom de la Société: ${companyName ?? "Non défini"}");
    print("Date de naissance: $birthday");
    print("Sexe: $sex");
    print("Nationalité: $nationality");
    print("Lieu de naissance: $placeOfborn");
    print("Résidence: ${residence.id} - ${residence.name}");
    print("Lot ID: $lotId");
    print("Type de Document ID: ${docTypeID ?? "Non défini"}");
    print("Type de Document Justificatif: ${docTypeJustif ?? "Non défini"}");
    print("Chemin ID Recto: ${imagepathIDrecto ?? "Non défini"}");
    print("Chemin ID Verso: ${imagepathIDverso ?? "Non défini"}");
    print("Justificatif: ${justifChoice ?? "Non défini"}");
    print("Chemin Justificatif: ${imagepathJustif ?? "Non défini"}");
    print("Kbis Path: ${kbisPath ?? "Non défini"}");
    print("----------------------------------------------------------");
    dataBasesUserServices.setUser(
        newUser, "${residence.id}-$lotId", compagnyBuy, companyName);

    DataBasesDocsServices dataBasesDocsIdServices = DataBasesDocsServices();
    DocumentModel newDocId = DocumentModel(
        type: docTypeID!,
        residenceId: residence.id,
        timeStamp: Timestamp.now(),
        documentPathRecto: imagepathIDrecto!,
        documentPathVerso: imagepathIDverso!,
        lotId: lotId);

    dataBasesDocsIdServices.setDocument(
        newDocId, newUserId, '${residence.id}-$lotId');

    DataBasesDocsServices dataBasesDocsJustifServices = DataBasesDocsServices();
    DocumentModel newDocJustif = DocumentModel(
        type: docTypeJustif!,
        residenceId: residence.id,
        timeStamp: Timestamp.now(),
        documentPathRecto: imagepathJustif!,
        lotId: lotId);

    dataBasesDocsJustifServices.setDocument(
        newDocJustif, newUserId, '${residence.id}-$lotId');

    if (compagnyBuy == true) {
      DataBasesDocsServices dataBasesDocsJustifServices =
          DataBasesDocsServices();
      DocumentModel newDocJustif = DocumentModel(
          type: "Kbis",
          residenceId: residence.id,
          timeStamp: Timestamp.now(),
          documentPathRecto: kbisPath!,
          lotId: lotId);

      dataBasesDocsJustifServices.setDocument(
          newDocJustif, newUserId, '${residence.id}-$lotId');
    }
  }

  static UpdateUser(
      {required BuildContext context,
      required String uid,
      required String field,
      required String label,
      String? value,
      bool? newBool}) async {
    try {
      await DataBasesUserServices.updateUserField(
          uid: uid, field: field, value: value, newBool: newBool);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label mis à jour avec succès!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour du champ private: $e'),
        ),
      );
    }
  }
}
