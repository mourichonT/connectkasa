import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_post_controller.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/components/camera_files_choices.dart';
import 'package:connect_kasa/vues/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';

class SinistreForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SinistreFormState();
  final Lot preferedLot;
  final String racineFolder;
  final String uid;
  final String idPost;
  final Function(String) updateUrl; // Fonction pour mettre à jour imagePath
  final String folderName;

  const SinistreForm({
    super.key,
    required this.racineFolder,
    required this.preferedLot,
    required this.uid,
    required this.idPost,
    required this.updateUrl,
    required this.folderName,
  });
}

class SinistreFormState extends State<SinistreForm> {
  late List<String> itemsType;
  late TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
  }

  final ButtonStyle style =
      ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
  final MaterialStateProperty<Icon?> thumbIcon =
      MaterialStateProperty.resolveWith<Icon?>(
    (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.check);
      }
      return const Icon(Icons.close);
    },
  );
  String localisation = "";
  String etage = "";
  //String element = "";
  TextEditingController title = TextEditingController();
  TextEditingController desc = TextEditingController();
  String imagePath = "";
  String fileName = '';
  bool anonymPost = false;
  Set<String> filters = <String>{};

  void updateItem(String updatedElement) {
    String item = "";
    setState(() {
      item = updatedElement;
    });
  }

  void updateBool(bool updatedBool) {
    setState(() {
      anonymPost = updatedBool;
    });
  }

  void downloadImagePath(String downloadUrl) {
    setState(() {
      widget.updateUrl(downloadUrl);
      imagePath = downloadUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> itemsLocalisation =
        List<String>.from(widget.preferedLot.residenceData["localistation"]);

    List<String> itemsEtage =
        List<String>.from(widget.preferedLot.residenceData["etage"]);

    List<String> itemsElements =
        List<String>.from(widget.preferedLot.residenceData["elements"]);

    final double width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(
              height: 15,
            ),
            MyDropDownMenu(
              width,
              "Localisation",
              "Choisir une localisation",
              preferedLot: widget.preferedLot,
              items: itemsLocalisation,
              onValueChanged: (String value) {
                setState(() {
                  localisation = value;
                  updateItem(localisation);
                });
              },
            ),
            const SizedBox(
              height: 15,
            ),
            MyDropDownMenu(
              width,
              "Etage",
              "Choisir un étage",
              preferedLot: widget.preferedLot,
              items: itemsEtage,
              onValueChanged: (String value) {
                setState(() {
                  etage = value;
                  updateItem(etage);
                });
              },
            ),
            const SizedBox(
              height: 15,
            ),
            const Divider(),
            const SizedBox(
              height: 15,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyTextStyle.lotName(
                    "Apportez des précisions pour localiser le sinistre:",
                    Colors.black87),
                const SizedBox(
                  height: 15,
                ),
                Center(
                  child: Wrap(
                    spacing: 5.0,
                    children: itemsElements.map((String itemsElement) {
                      return FilterChip(
                        label: Text(itemsElement),
                        selected: filters.contains(itemsElement),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              filters.add(itemsElement);
                            } else {
                              filters.remove(itemsElement);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            const Divider(),
            Center(
              child: CameraOrFiles(
                residence: widget.preferedLot.residenceId,
                racineFolder: widget.racineFolder,
                folderName: widget.folderName,
                title: title.text,
                onImageUploaded:
                    downloadImagePath, // Passer la fonction de rappel
              ),
            ),
            const Divider(),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyTextStyle.lotName("Titre : ", Colors.black87),
                const SizedBox(
                  height: 15,
                ),
                TextField(
                  controller: title,
                  maxLines: 1,
                  decoration: const InputDecoration.collapsed(
                      hintText: "Saisissez le titre de votre post"),
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            const Divider(),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyTextStyle.lotName("Description : ", Colors.black87),
                const SizedBox(
                  height: 15,
                ),
                TextField(
                  controller: desc,
                  maxLines: 6,
                  decoration: const InputDecoration.collapsed(
                      hintText: "Saisissez une description"),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(
              height: 15,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MyTextStyle.lotName("Publier anonymement?  ", Colors.black87),
                Switch(
                  thumbIcon: thumbIcon,
                  value: anonymPost,
                  onChanged: (bool value) {
                    setState(() {
                      anonymPost = value;
                      updateBool(anonymPost);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 40,
            ),
            Center(
              child: ElevatedButton(
                style: style,
                onPressed: () {
                  SubmitPostController.submitForm(
                    widget.uid,
                    widget.idPost,
                    widget.folderName,
                    imagePath,
                    title,
                    desc,
                    anonymPost,
                    widget.preferedLot.residenceId,
                    localisation: localisation,
                    etage: etage,
                    element: filters,
                  );
                  Navigator.pop(context);
                },
                child: MyTextStyle.lotName(
                    "Soumettre", Theme.of(context).primaryColor),
              ),
            ),
            const SizedBox(
              height: 50,
            ),
          ],
        ),
      ],
    );
  }
}
