import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/vues/widget_view/components/camera_files_choices.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';
import 'package:connect_kasa/models/enum/statut_list.dart';

class Step2 extends StatefulWidget {
  final Function(String, bool, String, String) recupererInformationsStep2;
  final int currentPage;
  final PageController progressController;
  final Function(bool) onCameraStateChanged;

  const Step2({
    super.key,
    required this.recupererInformationsStep2,
    required this.currentPage,
    required this.progressController,
    required this.onCameraStateChanged,
  });

  @override
  _Step2State createState() => _Step2State();
}

class _Step2State extends State<Step2> {
  bool compagnyBuy = false;
  bool visible = false;
  String typeResident = "";
  String? intendedFor = "";
  String? pathKbis = "";

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: MyTextStyle.lotName(
                    "Dites-nous si vous êtes propriétaire ou locataire ?",
                    Colors.black54),
              ),
              const SizedBox(height: 30),
              MyDropDownMenu(
                width,
                "Votre statut",
                "Votre statut",
                false,
                items: ImmoList.typeList(),
                onValueChanged: (value) {
                  setState(() {
                    typeResident = value;
                  });
                },
              ),
              Visibility(
                visible: typeResident == "Locataire",
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    MyTextStyle.lotName(
                        "Quel est le type de votre Bail ?", Colors.black54),
                    const SizedBox(height: 30),
                    MyDropDownMenu(
                      width,
                      "Type de bail",
                      "Type de bail",
                      false,
                      items: ImmoList.locaTypeList(),
                      onValueChanged: (value) {
                        setState(() {
                          intendedFor = value;
                          visible = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: typeResident == "Propriétaire",
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: MyTextStyle.lotDesc(
                              "Avez-vous acquis votre bien par l'intermédiaire d'une société ?",
                              SizeFont.h3.size),
                        ),
                        Switch(
                          value: compagnyBuy,
                          onChanged: (value) {
                            setState(() {
                              compagnyBuy = value;
                            });
                          },
                        ),
                      ],
                    ),
                    Visibility(
                      visible: compagnyBuy,
                      child: CameraOrFiles(
                        racineFolder: 'user',
                        residence: 'document',
                        folderName: 'documentID',
                        title: pathKbis ?? "",
                        onImageUploaded: (downloadUrl) {
                          setState(() {
                            pathKbis = downloadUrl;
                          });
                        },
                        cardOverlay: true,
                        onCameraStateChanged: (bool isOpen) {
                          widget.onCameraStateChanged(isOpen);
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: MyTextStyle.lotName(
                          "Veuillez nous indiquer l'utilisation prévue de votre bien.",
                          Colors.black54),
                    ),
                    const SizedBox(height: 30),
                    MyDropDownMenu(
                      width,
                      "Votre objectif",
                      "Votre objectif",
                      false,
                      items: ImmoList.bienTypeList(),
                      onValueChanged: (value) {
                        setState(() {
                          intendedFor = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Visibility(
        visible: intendedFor != null && intendedFor!.isNotEmpty,
        child: BottomAppBar(
          surfaceTintColor: Colors.white,
          padding: const EdgeInsets.all(2),
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  widget.recupererInformationsStep2(
                    typeResident,
                    compagnyBuy,
                    intendedFor ?? "",
                    pathKbis ?? "",
                  );
                  if (widget.currentPage < 5) {
                    widget.progressController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease,
                    );
                  }
                },
                child: const Text('Suivant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
