import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/handlers/api/flutter_api.dart';
import 'package:connect_kasa/core/repositories/docs_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_docs_repository.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';
import 'package:connect_kasa/models/pages_models/user.dart';
import 'package:connect_kasa/models/pages_models/user_info.dart';
import 'package:connect_kasa/models/pages_models/user_temp.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/pages_models/residence.dart';

class SubmitUser {
  static Future<void> submitUser({
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
  }) async {
    final dataBasesUserServices = DataBasesUserServices();
    final IDocsRepository docsRepository = FirestoreDocsRepository();

    // Résout l'ID réel du document Residence/{id}/lot/{docId} à partir du
    // refLot saisi à l'inscription — plus de clé composite reconstruite.
    final lotQuery = await FirebaseFirestore.instance
        .collection('Residence')
        .doc(residence.id)
        .collection('lot')
        .where('refLot', isEqualTo: lotId)
        .limit(1)
        .get();
    final String? realLotId =
        lotQuery.docs.isNotEmpty ? lotQuery.docs.first.id : null;

    final newUser = UserTemp(
      createdDate: Timestamp.now(),
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

    await dataBasesUserServices.setUser(
        newUser,
        realLotId,
        residence.id,
        companyName,
        intendedFor,
        statutResident,
        informationsCorrectes,
        fcmToken);

    // Document pièce d'identité
    if (imagepathIDrecto != null && imagepathIDverso != null) {
      final newDocId = DocumentModel(
        type: docTypeID,
        timeStamp: Timestamp.now(),
        documentPathRecto: imagepathIDrecto,
        documentPathVerso: imagepathIDverso,
      );
      await docsRepository.setDocument(
          newDocId, newUserId, realLotId);
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
      await docsRepository.setDocument(
        newDocJustif,
        newUserId,
        realLotId,
      );
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
      await docsRepository.setDocument(
          newDocKbis, newUserId, realLotId);
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

    // tu peux ajouter ici d'autres paramètres comme la liste des revenus etc.
  }) async {
    final dataBasesUserServices = DataBasesUserServices();
    if (user == null) return;

    bool success = await dataBasesUserServices.updateUserInfo(user);

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
