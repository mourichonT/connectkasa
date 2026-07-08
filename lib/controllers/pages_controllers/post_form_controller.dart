// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';

import '../../vues/pages_vues/post_page/post_form.dart';
import '../../core/repositories/firestore_storage_repository.dart';

class PostFormController extends StatelessWidget {
  final Lot preferedLot;
  final String uid;
  final String racineFolder;
  PostFormController({
    super.key,
    required this.preferedLot,
    required this.uid,
    required this.racineFolder,
  });

  final FirestoreStorageRepository _storageServices = FirestoreStorageRepository();
  String url = "";
  String folderName = "";

  void updateUrl(String updatedUrl) {
    url = updatedUrl;
  }

  // Fonction pour mettre à jour folderName
  void updateFolderName(String updatedFolderName) {
    folderName = updatedFolderName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
            'Publier dans votre résidence', Colors.black87, SizeFont.h1.size),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _storageServices.removeFile(
                "residences", preferedLot.residenceId, folderName,
                url: url);
            Navigator.of(context).pop();
          },
        ),
      ),
      body: PostForm(
        racineFolder: racineFolder,
        preferedLot: preferedLot,
        uid: uid,
        updateUrl: updateUrl,
        updateFolderName: updateFolderName,
      ),
    );
  }
}
