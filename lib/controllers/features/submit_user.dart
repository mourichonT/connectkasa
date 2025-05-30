import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/handlers/api/flutter_api.dart';
import 'package:connect_kasa/controllers/services/databases_docs_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/models/pages_models/user_temp.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/pages_models/residence.dart';

class SubmitUser {
  static submitUser({
    required bool privacyPolicy,
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
    required Residence residence,
    required String lotId,
    required String docTypeID,
    String? companyName,
    String? pseudo,
    String? docTypeJustif,
    String? imagepathIDrecto,
    String? imagepathIDverso,
    String? imagepathJustif,
    String? kbisPath,
    bool? informationsCorrectes,
    String? fcmToken,
  }) {
    final dataBasesUserServices = DataBasesUserServices();
    final dataBasesDocsServices = DataBasesDocsServices();

    final newUser = UserTemp(
      privacyPolicy: privacyPolicy,
      email: emailUser,
      name: name,
      surname: surname,
      uid: newUserId,
      pseudo: pseudo,
      approved: false,
      typeLot: typeChoice,
      birthday: birthday,
      sex: sex,
      nationality: nationality,
      placeOfborn: placeOfborn,
    );

    dataBasesUserServices.setUser(
        newUser,
        "${residence.id}-$lotId",
        companyName,
        intendedFor,
        statutResident,
        informationsCorrectes,
        fcmToken);

    // Document pièce d'identité
    if (docTypeID != null &&
        imagepathIDrecto != null &&
        imagepathIDverso != null) {
      final newDocId = DocumentModel(
        type: docTypeID,
        timeStamp: Timestamp.now(),
        documentPathRecto: imagepathIDrecto,
        documentPathVerso: imagepathIDverso,
      );
      dataBasesDocsServices.setDocument(
          newDocId, newUserId, '${residence.id}-$lotId');
    } else {
      print("le document ID n'a pas était importé dans la collection");
    }

    // Document justificatif
    if (docTypeJustif != null && imagepathJustif != null) {
      final newDocJustif = DocumentModel(
        type: docTypeJustif,
        residenceId: residence.id,
        timeStamp: Timestamp.now(),
        documentPathRecto: imagepathJustif,
        lotId: lotId,
      );
      dataBasesDocsServices.setDocument(
        newDocJustif,
        newUserId,
        '${residence.id}-$lotId',
      );
    } else {
      print("le document justif n'a pas était importé dans la collection");
    }

    // Kbis (si société)
    if (compagnyBuy && kbisPath != null) {
      final newDocKbis = DocumentModel(
        type: "Kbis",
        residenceId: residence.id,
        timeStamp: Timestamp.now(),
        documentPathRecto: kbisPath,
        lotId: lotId,
      );
      dataBasesDocsServices.setDocument(
          newDocKbis, newUserId, '${residence.id}-$lotId');
    } else {
      print("le document société n'a pas était importé dans la collection");
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

  static Future<void> submitTenantInfo({
    required BuildContext context,
    required UserInfo user,
    required TextEditingController profession,
    required String contactType,
    required TextEditingController entryJobDate,
    // tu peux ajouter ici d'autres paramètres comme la liste des revenus etc.
  }) async {
    final dataBasesUserServices = DataBasesUserServices();
    if (user == null) return;

    UserInfo updatedUser = user.copyWith(
      profession: profession.text,
      typeContract: contactType.isNotEmpty ? contactType : user.typeContract,
      entryJobDate: entryJobDate.text.isNotEmpty
          ? Timestamp.fromDate(
              DateFormat('dd/MM/yyyy').parse(entryJobDate.text))
          : user.entryJobDate,
    );

    bool success = await dataBasesUserServices.updateUserInfo(updatedUser);

    if (success) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informations enregistrées avec succès.")),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'enregistrement.")),
      );
    }
  }
}
