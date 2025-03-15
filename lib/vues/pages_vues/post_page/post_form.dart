import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/vues/pages_vues/post_page/asking_neighbords_form.dart';
import 'package:connect_kasa/vues/widget_view/incivilite_form.dart';
import 'package:connect_kasa/vues/widget_view/sinistre_form.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/pages_models/lot.dart';

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
  final TypeList _typeList = TypeList();
  late List<String> itemsType;
  String idPost = const Uuid().v1();
  String declaration = "";
  String selectedLabel = "";
  String? selectedDeclaration;
  List<String> filters = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<List<String>> declarationType = _typeList.typeDeclaration();
    List<String> labelsType = declarationType
        .asMap()
        .entries
        .map((entry) {
          return entry.value[0];
        })
        .take(3)
        .toList();

    final double width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          Colors.black87,
                          SizeFont.h2.size),
                      Container(padding: const EdgeInsets.only(left: 2)),
                    ]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    MyTextStyle.lotDesc(
                        widget.preferedLot.residenceData["numero"],
                        SizeFont.h3.size),
                    Container(padding: const EdgeInsets.only(left: 2)),
                    MyTextStyle.lotDesc(
                        widget.preferedLot.residenceData["street"],
                        SizeFont.h3.size),
                    Container(padding: const EdgeInsets.only(left: 2)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    MyTextStyle.lotDesc(
                        widget.preferedLot.residenceData["zipCode"],
                        SizeFont.h3.size),
                    Container(padding: const EdgeInsets.only(left: 2)),
                    MyTextStyle.lotDesc(
                        widget.preferedLot.residenceData["city"],
                        SizeFont.h3.size),
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
        Center(
          child: Wrap(
            spacing: 5.0,
            children: labelsType.map((String itemElement) {
              return ChoiceChip(
                label: Text(itemElement),
                selected: selectedDeclaration == itemElement,
                side: const BorderSide(
                  color: Colors
                      .black12, // Changez `Colors.blue` et `Colors.grey` selon vos besoins
                  width: 1.0, // Changez la largeur de la bordure si nécessaire
                ),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      selectedDeclaration = itemElement;
                      selectedLabel = declarationType.firstWhere(
                          (element) => element[0] == selectedDeclaration,
                          orElse: () => ["", ""])[1];
                    } else {
                      selectedDeclaration = null;
                      selectedLabel = "";
                    }
                    widget.updateFolderName(selectedLabel);
                  });
                },
              );
            }).toList(),
          ),
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
        ),
        Visibility(
          visible: selectedLabel == 'communication',
          child: AskingNeighbordsForm(
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
