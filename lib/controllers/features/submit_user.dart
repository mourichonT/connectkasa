import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/core/repositories/docs_repository.dart';
import 'package:konodal/core/repositories/firestore_docs_repository.dart';
import 'package:konodal/core/repositories/user_repository.dart';
import 'package:konodal/core/repositories/firestore_user_repository.dart';
import 'package:konodal/models/pages_models/document_model.dart';
import 'package:konodal/models/pages_models/user_info.dart';
import 'package:konodal/models/pages_models/user_temp.dart';
import 'package:flutter/material.dart';

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
    required Residence? residence,
    required String? lotId,
    required String docTypeID,
    String? companyName,
    String? pseudo,
    String? docTypeJustif,
    String? imagepathIDrecto,
    String? imagepathIDverso,
    String? idExtension,
    String? imagepathJustif,
    String? justifExtension,
    String? kbisPath,
    String? kbisExtension,
    bool? informationsCorrectes,
    String? fcmToken,
  }) async {
    final IUserRepository dataBasesUserServices = FirestoreUserRepository();
    final IDocsRepository docsRepository = FirestoreDocsRepository();

    // Résout l'ID réel du document residences/{id}/lot/{docId} à partir du
    // refLot saisi à l'inscription — plus de clé composite reconstruite.
    // Absent si l'inscription se fait sans résidence (cf step1.dart "Je n'ai
    // pas encore de résidence" / step4_bis.dart) : aucune résidence/lot à
    // résoudre dans ce cas, l'utilisateur se rattachera plus tard.
    String? realLotId;
    if (residence != null && lotId != null) {
      final lotQuery = await FirebaseFirestore.instance
          .collection('residences')
          .doc(residence.id)
          .collection('lots')
          .where('refLot', isEqualTo: lotId)
          .limit(1)
          .get();
      realLotId = lotQuery.docs.isNotEmpty ? lotQuery.docs.first.id : null;
    }

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
      isInfoCorrect: informationsCorrectes ?? false,
      compagnyBuy: compagnyBuy,
    );

    await dataBasesUserServices
        .setUser(
            newUser,
            realLotId,
            residence?.id,
            companyName,
            intendedFor,
            statutResident,
            fcmToken)
        .then((result) => result.when(
            success: (_) {}, failure: (error) => throw error));

    // Document pièce d'identité
    if (imagepathIDrecto != null && imagepathIDverso != null) {
      final newDocId = DocumentModel(
        type: docTypeID,
        extension: idExtension,
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
        extension: justifExtension,
        residenceId: residence?.id,
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
        extension: kbisExtension,
        residenceId: residence?.id,
        timeStamp: Timestamp.now(),
        documentPathRecto: kbisPath,
        lotId: lotId,
      );
      await docsRepository.setDocument(
          newDocKbis, newUserId, realLotId);
    }
  }

  static updateUser(
      {required BuildContext context,
      required String uid,
      required String field,
      required String label,
      String? value,
      bool? newBool}) async {
    try {
      await FirestoreUserRepository()
          .updateUserField(
              uid: uid, field: field, value: value, newBool: newBool)
          .then((result) => result.when(
              success: (_) {}, failure: (error) => throw error));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label mis à jour avec succès!'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
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
    final IUserRepository dataBasesUserServices = FirestoreUserRepository();

    bool success = await dataBasesUserServices
        .updateUserInfo(user)
        .then((result) => result.when(success: (v) => v, failure: (_) => false));

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
