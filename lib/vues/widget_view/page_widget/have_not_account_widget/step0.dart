import 'dart:async';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/vues/widget_view/components/camera_files_choices.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:connect_kasa/vues/widget_view/components/photo_for_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Step0 extends StatefulWidget {
  final String userId;
  final String emailUser;
  final Function(String, String, String, String, String, String, String, String,
      String, String) recupererInformationsStep0;
  final int currentPage;
  final PageController progressController;
  // final bool isCameraOpen;
  final Function(bool) onCameraStateChanged;

  const Step0({
    super.key,
    required this.emailUser,
    required this.userId,
    required this.recupererInformationsStep0,
    required this.currentPage,
    required this.progressController,
    // required this.isCameraOpen,
    required this.onCameraStateChanged,
  });

  @override
  _Step0State createState() => _Step0State();
}

class _Step0State extends State<Step0> with WidgetsBindingObserver {
  Map<String, String> idData = {};
  String _name = "";
  String _surname = "";
  String _birthday = "";
  String _sex = "";
  String _nationality = "";
  String _placeOfBorn = "";
  TextEditingController _pseudoController = TextEditingController();
  String imagePathIDrecto = "";
  String imagePathIDverso = "";
  Timer? _deleteTimer;
  String? idChoice = "";
  bool visibleID = false;

  // Méthode pour mettre à jour les informations extraites
  // Méthode pour mettre à jour les informations extraites
  void _updateIdData(Map<String, String> extractedData) {
    setState(() {
      idData = extractedData;
      print("VOICI LE TEXT OCR : $idData");
      _name = extractedData['Nom'] ?? '';
      _surname = extractedData['Prénom'] ?? '';
      _birthday = extractedData['Date de naissance'] ?? '';
      _sex = extractedData['Sexe'] ?? '';
      _nationality = extractedData['Nationalité'] ?? '';
      _placeOfBorn = extractedData['Lieu de naissance'] ?? '';

      print("Nom mis à jour: $_name");
      print("Prénom mis à jour: $_surname");
      print("Date de naissance mise à jour: $_birthday");
      print("sexe mise à jour: $_sex");
      print("Nationalite mise à jour: $_nationality");
      print("Lieu de naissance mise à jour: $_placeOfBorn");
    });
  }

  @override
  void initState() {
    super.initState();
  }

  void downloadImagePathID(String downloadUrl, bool isRecto) {
    setState(() {
      if (isRecto) {
        imagePathIDrecto = downloadUrl;
      } else {
        imagePathIDverso = downloadUrl;
      }
    });
  }

  String getPathIdrect() {
    return imagePathIDrecto;
  }

  String getPathIdvers() {
    return imagePathIDverso;
  }

  List<String> idType = [
    "Carte d'identité",
    "Permis de conduire",
    "Passeport",
    "Titre de séjour",
  ];

  String getIdType() {
    return idChoice!;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MyTextStyle.lotName(
                    """Vous venez de vous installer dans une résidence du réseau ConnectKasa. Commençons par renseigner quelques informations. """,
                    Colors.black54),
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: MyDropDownMenu(
                    width,
                    "Type de document",
                    "Choisir...",
                    false,
                    items: idType,
                    onValueChanged: (String value) {
                      setState(() {
                        idChoice = value;
                        visibleID = true;
                      });
                    },
                  ),
                ),
                Visibility(
                  visible: visibleID,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: PhotoForId(
                            racineFolder: 'user',
                            residence: widget.userId,
                            folderName: 'documentID',
                            title: idChoice!,
                            onImageUploaded: (downloadUrl) =>
                                downloadImagePathID(downloadUrl, true),
                            cardOverlay: true,
                            onCameraStateChanged: (bool isOpen) {
                              widget.onCameraStateChanged(isOpen);
                            },
                            onIdDataExtracted: (data) {
                              _updateIdData(
                                  data); // Met à jour les données extraites
                            }),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: imagePathIDrecto != "",
                  child: Column(
                    children: [
                      MyTextStyle.lotName(
                          "Merci de prendre l'autre coté de la carte",
                          Colors.black54),
                      CameraOrFiles(
                        racineFolder: 'user',
                        residence: widget.userId,
                        folderName: 'documentID',
                        title: idChoice!,
                        onCameraStateChanged: (bool isOpen) {
                          widget.onCameraStateChanged(isOpen);
                        },
                        onImageUploaded: (downloadUrl) =>
                            downloadImagePathID(downloadUrl, false),
                        cardOverlay: true,
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: imagePathIDverso.isNotEmpty,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: CustomTextFieldWidget(
                          label: "Nom de famille:",
                          value:
                              _name, // Utilisation du controller pour afficher le nom extrait
                          isEditable: false, // Rendre le champ non éditable
                        ),
                      ),
                      CustomTextFieldWidget(
                        label: "Prénom:",
                        value:
                            _surname, // Utilisation du controller pour afficher le prénom extrait
                        isEditable: false, // Rendre le champ non éditable
                      ),
                      CustomTextFieldWidget(
                        label: "Date de naissance:",
                        value:
                            _birthday, // Utilisation du controller pour afficher le prénom extrait
                        isEditable: false, // Rendre le champ non éditable
                      ),
                    ],
                  ),
                ),
                CustomTextFieldWidget(
                  label: "Pseudo :",
                  controller: _pseudoController,
                  isEditable: true,
                  minLines: 1,
                  maxLines: 1,
                  text: "Pseudo",
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Visibility(
        visible: imagePathIDverso.isNotEmpty,
        child: BottomAppBar(
          surfaceTintColor: Colors.white,
          padding: const EdgeInsets.all(2),
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  widget.recupererInformationsStep0(
                      widget.emailUser,
                      _name,
                      _surname,
                      _birthday,
                      _sex,
                      _nationality,
                      _placeOfBorn,
                      _pseudoController.text,
                      imagePathIDrecto,
                      imagePathIDverso);
                  if (widget.currentPage < 5) {
                    widget.progressController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease,
                    );
                  }
                },
                child: const Text(
                  'Suivant',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
