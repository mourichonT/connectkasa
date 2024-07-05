import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/vues/widget_view/camera_files_choices.dart';
import 'package:flutter/material.dart';

class Step2 extends StatefulWidget {
  final Function(String, bool, String, String) recupererInformationsStep2;
  final int currentPage;
  final PageController progressController;

  const Step2({
    Key? key,
    required this.recupererInformationsStep2,
    required this.currentPage,
    required this.progressController,
  }) : super(key: key);

  @override
  _Step2State createState() => _Step2State();
}

class _Step2State extends State<Step2> {
  final MaterialStateProperty<Icon?> thumbIcon =
      MaterialStateProperty.resolveWith<Icon?>(
    (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.check);
      }
      return const Icon(Icons.close);
    },
  );

  String getKbisPath() {
    return pathKbis!;
  }

  String getResidentType() {
    return typeResident;
  }

  bool getValueCompagny() {
    return compagnyBuy;
  }

  String getIntendedFor() {
    return intendedFor!;
  }

  bool compagnyBuy = false;
  List<String> type = ["Propriétaire", "Locataire"];
  List<String> locaType = [
    "Bail unique (personne seule)",
    "Bail co-titulaire (en concubinage)",
    "Bail en colocation"
  ];
  List<String> bienType = [
    "Résidence Principale ou secondaire",
    "Investissement Locatif",
  ];
  bool visible = false;
  String typeResident = "";
  String? intendedFor = "";
  String? pathKbis = "";

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: MyTextStyle.lotName(
                  "Dites nous si vous êtes propriétaire ou locataire?",
                  Colors.black54),
            ),
            const SizedBox(
              height: 30,
            ),
            DropdownMenu<String>(
              //initialSelection: typeDeclaration,
              hintText: "Votre statut",
              onSelected: (String? value) {
                // This is called when the user selects an item.
                setState(() {
                  typeResident = value!;
                });
              },
              dropdownMenuEntries:
                  type.map<DropdownMenuEntry<String>>((String value) {
                return DropdownMenuEntry<String>(value: value, label: value);
              }).toList(),
              width: width / 1.5,
            ),
            Visibility(
              visible: typeResident == "Locataire",
              child: Column(
                children: [
                  const SizedBox(
                    height: 30,
                  ),
                  MyTextStyle.lotName(
                      "Quel est le type de votre Bail?", Colors.black54),
                  Container(
                    padding: EdgeInsets.only(top: 30),
                    child: DropdownMenu<String>(
                      //initialSelection: typeDeclaration,
                      hintText: "Type de bail ",
                      onSelected: (String? value) {
                        // This is called when the user selects an item.
                        setState(() {
                          intendedFor = value;
                          visible = true;
                        });
                      },
                      dropdownMenuEntries: locaType
                          .map<DropdownMenuEntry<String>>((String value) {
                        return DropdownMenuEntry<String>(
                            value: value, label: value);
                      }).toList(),
                      width: width / 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: typeResident == "Propriétaire",
              child: Column(
                children: [
                  const SizedBox(
                    height: 30,
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 30, bottom: 30, left: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: width * 0.7,
                          child: MyTextStyle.lotName(
                              "Avez-vous achetez votre bien via une société?",
                              Colors.black54),
                        ),
                        Switch(
                          thumbIcon: thumbIcon,
                          value: compagnyBuy,
                          onChanged: (bool value) {
                            setState(() {
                              compagnyBuy = value;
                              updateBool(compagnyBuy);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: MyTextStyle.annonceDesc(
                        "Merci de fournir votre extrait de KBIS", 14, 3),
                  ),
                  compagnyBuy == true
                      ? CameraOrFiles(
                          racineFolder: 'user',
                          residence: 'document',
                          folderName: 'documentID',
                          title: pathKbis!,
                          onImageUploaded: (downloadUrl) =>
                              downloadImagePathKbis(downloadUrl),
                          cardOverlay: true,
                        )
                      : Container(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: MyTextStyle.lotName(
                        "Merci de nous préciser quelle est la destination de votre bien",
                        Colors.black54),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 30),
                    child: DropdownMenu<String>(
                      //initialSelection: typeDeclaration,
                      hintText: "Votre objectif ",
                      onSelected: (String? value) {
                        // This is called when the user selects an item.
                        setState(() {
                          visible = true;
                          intendedFor = value;
                        });
                      },
                      dropdownMenuEntries: bienType
                          .map<DropdownMenuEntry<String>>((String value) {
                        return DropdownMenuEntry<String>(
                            value: value, label: value);
                      }).toList(),
                      width: width / 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Visibility(
        visible: getIntendedFor().isNotEmpty,
        child: BottomAppBar(
            surfaceTintColor: Colors.white,
            padding: EdgeInsets.all(2),
            height: 70,
            child: Container(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  TextButton(
                    onPressed: () {
                      String typeResident = getResidentType();
                      bool valueOfCompagnyBuy = getValueCompagny();
                      String newIntendedFor = getIntendedFor();
                      String kbisPath = getKbisPath();
                      widget.recupererInformationsStep2(typeResident,
                          valueOfCompagnyBuy, newIntendedFor, kbisPath);
                      // Action à effectuer lorsque le bouton "Suivant" est pressé
                      if (widget.currentPage < 5) {
                        widget.progressController.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      }
                    },
                    child: Text(
                      'Suivant',
                    ),
                  ),
                ]))),
      ),
    );
  }

  void downloadImagePathKbis(String downloadUrl) {
    setState(() {
      //widget.updateUrl(downloadUrl);
      pathKbis = downloadUrl;
    });
  }

  void updateBool(bool updatedBool) {
    setState(() {
      compagnyBuy = updatedBool;
    });
  }
}
