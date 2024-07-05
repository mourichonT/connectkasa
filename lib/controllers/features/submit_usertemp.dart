import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/services/databases_docs_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';
import 'package:connect_kasa/models/pages_models/user_temp.dart';

import '../../models/pages_models/residence.dart';

class SubmitUser {
  static submitUserTemp({
    required String name,
    required String surname,
    required String newUserId,
    required String statutResident,
    required String intendedFor,
    required String typeChoice,
    required bool compagnyBuy,
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
      name: name,
      surname: surname,
      uid: newUserId,
      pseudo: pseudo,
      approved: false,
      statutResident: statutResident,
      typeLot: typeChoice,
      compagnyBuy: compagnyBuy,
    );

    dataBasesUserServices.setUserTemp(newUser);

    DataBasesDocsServices dataBasesDocsIdServices = DataBasesDocsServices();
    DocumentModel newDocId = DocumentModel(
        type: docTypeID!,
        residenceId: residence.id,
        timeStamp: Timestamp.now(),
        documentPathRecto: imagepathIDrecto!,
        documentPathVerso: imagepathIDverso!,
        lotId: lotId);

    dataBasesDocsIdServices.setDocument(newDocId, newUserId);

    DataBasesDocsServices dataBasesDocsJustifServices = DataBasesDocsServices();
    DocumentModel newDocJustif = DocumentModel(
        type: docTypeJustif!,
        residenceId: residence.id,
        timeStamp: Timestamp.now(),
        documentPathRecto: imagepathJustif!,
        lotId: lotId);

    dataBasesDocsJustifServices.setDocument(newDocJustif, newUserId);

    if (compagnyBuy == true) {
      DataBasesDocsServices dataBasesDocsJustifServices =
          DataBasesDocsServices();
      DocumentModel newDocJustif = DocumentModel(
          type: "Kbis",
          residenceId: residence.id,
          timeStamp: Timestamp.now(),
          documentPathRecto: kbisPath!,
          lotId: lotId);

      dataBasesDocsJustifServices.setDocument(newDocJustif, newUserId);
    }
  }
}
