// ignore_for_file: must_be_immutable

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:flutter/material.dart';

import '../../vues/pages_vues/post_form.dart';
import '../services/storage_services.dart';

class PostFormController extends StatelessWidget {
  final Lot preferedLot;
  final String uid;
  final String racineFolder;
  final Function() onPostAdded;
  PostFormController(
      {super.key,
      required this.preferedLot,
      required this.uid,
      required this.racineFolder, 
      required this.onPostAdded});

  final StorageServices _storageServices = StorageServices();
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
        onPostAdded: onPostAdded,
        racineFolder: racineFolder,
        preferedLot: preferedLot,
        uid: uid,
        updateUrl: updateUrl,
        updateFolderName: updateFolderName,
      ),
    );
  }
}
