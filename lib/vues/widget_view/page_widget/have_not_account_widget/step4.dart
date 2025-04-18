import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_user.dart';
import 'package:connect_kasa/controllers/handlers/progress_widget.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/vues/widget_view/components/camera_files_choices.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';

class Step4 extends StatefulWidget {
  final String userId;
  final String emailUser;
  final Residence residence;
  final String residentType;
  final Function(String, String, String, String) recupererInformationsStep4;
  final int currentPage;
  final PageController progressController;
  final String docTypeId;

  final String name;
  final String surname;
  final String pseudo;
  final Timestamp birthday;
  final String imagepathIDrecto;
  final String imagepathIDverso;
  final bool compagnyBuy;
  final String intendedFor;
  final String refLot;
  final String typeLot;
  final String kbisPath;
  final String sex;
  final String nationality;
  final String placeOfBorn;
  final Function(bool) onCameraStateChanged;
  final VoidCallback cancelDeletionTimer;

  const Step4({
    super.key,
    required this.residence,
    required this.residentType,
    required this.recupererInformationsStep4,
    required this.currentPage,
    required this.progressController,
    required this.name,
    required this.surname,
    required this.birthday,
    required this.imagepathIDrecto,
    required this.imagepathIDverso,
    required this.pseudo,
    required this.compagnyBuy,
    required this.kbisPath,
    required this.intendedFor,
    required this.refLot,
    required this.userId,
    required this.typeLot,
    required this.emailUser,
    required this.sex,
    required this.nationality,
    required this.placeOfBorn,
    required this.onCameraStateChanged,
    required this.docTypeId,
    required this.cancelDeletionTimer,
  });

  @override
  _Step4State createState() => _Step4State();
}

class _Step4State extends State<Step4> {
  late CameraDescription firstCamera;

  bool visible = false;
  bool visibleID = false;
  bool visibleJustif = false;
  String imagePathJustif = "";
  String justifChoice = "";
  String idChoice = "";

  final List<String> idType = TypeList.idTypes;

  final List<String> justifTypeProp = TypeList.justifTypeProps;
  final List<String> justifTypeLoc = TypeList.justifTypeLocs;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: MyTextStyle.lotName(
                        "Maintenant fournissez un justificatif de domicile, attention ce document dois être au nom du document d'identité fournis",
                        Colors.black54),
                  ),
                  MyDropDownMenu(
                    // Replacing DropdownMenu with MyDropDownMenu
                    width,
                    "Type de document",
                    "Choisir un type de document",
                    false,
                    items: widget.residentType == "Locataire"
                        ? justifTypeLoc
                        : justifTypeProp,
                    onValueChanged: (String value) {
                      setState(() {
                        justifChoice = value;
                        visibleJustif = true;
                      });
                    },
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Visibility(
                    visible: visibleJustif,
                    child: Column(
                      children: [
                        CameraOrFiles(
                          racineFolder: 'user',
                          residence: widget.userId,
                          folderName: 'justificatifDom',
                          title: justifChoice,
                          onCameraStateChanged: (bool isOpen) {
                            widget.onCameraStateChanged(isOpen);
                          },
                          onImageUploaded: (downloadUrl) =>
                              downloadPath(downloadUrl, false),
                          cardOverlay: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Visibility(
        visible: visibleJustif,
        child: BottomAppBar(
          surfaceTintColor: Colors.white,
          padding: const EdgeInsets.all(2),
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor),
                  onPressed: () {
                    SubmitUser.submitUser(
                      privacyPolicy: false,
                      emailUser: widget.emailUser,
                      name: widget.name,
                      surname: widget.surname,
                      sex: widget.sex,
                      nationality: widget.nationality,
                      placeOfborn: widget.placeOfBorn,
                      pseudo: widget.pseudo,
                      newUserId: widget.userId,
                      statutResident: widget.residentType,
                      typeChoice: widget.typeLot,
                      intendedFor: widget.intendedFor,
                      compagnyBuy: widget.compagnyBuy,
                      kbisPath: widget.kbisPath,
                      residence: widget.residence,
                      lotId: widget.refLot,
                      docTypeID: widget.docTypeId,
                      docTypeJustif: justifChoice,
                      imagepathIDrecto: widget
                          .imagepathIDrecto, // Passage en tant qu'argument nommé
                      imagepathIDverso: widget
                          .imagepathIDverso, // Passage en tant qu'argument nommé
                      // justifChoice:
                      //     justifChoice, // Passage en tant qu'argument nommé
                      imagepathJustif: imagePathJustif,
                      birthday: widget.birthday,
                    );
                    print("UTILISATEUR CREE");
                    widget.cancelDeletionTimer();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: const Text(
                            'Merci, votre demande a été transmise à notre équipe. Vous recevrez un mail pour vous avertir de la création et du rattachement de votre compte.',
                            textAlign: TextAlign.justify,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.popUntil(
                                    context, ModalRoute.withName('/'));
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('Soumettre',
                      style: TextStyle(
                        color: Colors.white,
                      ))),
            ],
          ),
        ),
      ),
    );
  }

  void downloadPath(String downloadUrl, bool isRecto) {
    setState(() {
      imagePathJustif = downloadUrl;
    });
  }
}
