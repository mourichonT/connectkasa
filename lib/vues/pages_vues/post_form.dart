import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/vues/widget_view/incivilite_form.dart';
import 'package:connect_kasa/vues/widget_view/sinistre_form.dart';
import 'package:connect_kasa/vues/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/pages_models/lot.dart';

class PostForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => PostFormState();
  final String racineFolder;
  final Lot preferedLot;
  final String uid;
  final Function(String) updateUrl; // Fonction pour mettre à jour imagePath
  final Function(String)
      updateFolderName; // Fonction pour mettre à jour folderName
  const PostForm({
    super.key,
    required this.racineFolder,
    required this.preferedLot,
    required this.uid,
    required this.updateUrl,
    required this.updateFolderName,
  });
}

class PostFormState extends State<PostForm> {
  // Initialisé à une chaîne vide

  final TypeList _typeList = TypeList();
  late List<String> itemsType;

  @override
  void initState() {
    super.initState();
  }

  String idPost = const Uuid().v1();
  String declaration = "";
  String selectedLabel = "";

  @override
  Widget build(BuildContext context) {
    List<List<String>> declarationType = _typeList.typeDeclaration();
    List<String> labelsType = declarationType.asMap().entries.map((entry) {
      return entry.value[0];
    }).toList();

    final double width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(children: [
        const Divider(),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              child: MyTextStyle.lotName(
                  "Vous postez dans la residence : ", Colors.black87),
            ),
            const SizedBox(
              height: 15,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      MyTextStyle.lotName(
                          "${widget.preferedLot.residenceData["name"]}",
                          Colors.black87),
                      Container(padding: const EdgeInsets.only(left: 2)),
                    ]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    MyTextStyle.lotDesc(
                        widget.preferedLot.residenceData["numero"], 13),
                    Container(padding: const EdgeInsets.only(left: 2)),
                    MyTextStyle.lotDesc(
                        widget.preferedLot.residenceData["street"], 13),
                    Container(padding: const EdgeInsets.only(left: 2)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    MyTextStyle.lotDesc(
                        widget.preferedLot.residenceData["zipCode"], 13),
                    Container(padding: const EdgeInsets.only(left: 2)),
                    MyTextStyle.lotDesc(
                        widget.preferedLot.residenceData["city"], 13),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          ],
        ),
        const Divider(),
        const SizedBox(
          height: 15,
        ),
        MyDropDownMenu(
          width,
          "Type d'annonce",
          "Choisir un type",
          preferedLot: widget.preferedLot,
          items: labelsType,
          onValueChanged: (String value) {
            setState(() {
              declaration = value;
              selectedLabel = declarationType.firstWhere(
                  (element) => element[0] == declaration,
                  orElse: () => ["", ""])[1];
              //updateItem(declaration);
              widget.updateFolderName(selectedLabel);
            });
          },
        ),
        const SizedBox(
          height: 15,
        ),
        Visibility(
          visible: selectedLabel == 'sinistres',
          child: SinistreForm(
            racineFolder: widget.racineFolder,
            preferedLot: widget.preferedLot,
            uid: widget.uid,
            idPost: idPost,
            updateUrl: widget.updateUrl,
            folderName: selectedLabel,
          ),
        ),
        Visibility(
          visible: selectedLabel == 'incivilites',
          child: InciviliteForm(
            racineFolder: widget.racineFolder,
            preferedLot: widget.preferedLot,
            uid: widget.uid,
            idPost: idPost,
            updateUrl: widget.updateUrl,
            folderName: selectedLabel,
          ),
        )
      ]),
    ));
  }
}
