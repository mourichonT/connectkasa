import 'package:camera/camera.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_usertemp.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/vues/widget_view/camera_files_choices.dart';
import 'package:flutter/material.dart';

class Step4 extends StatefulWidget {
  final String userId;
  final String emailUser;
  final Residence residence;
  final String residentType;
  final Function(String, String, String, String, String)
      recupererInformationsStep4;
  final int currentPage;
  final PageController progressController;

  final String name;
  final String surname;
  final String pseudo;
  final bool compagnyBuy;
  final String intendedFor;
  final String refLot;
  final String typeLot;
  final String kbisPath;

  const Step4({
    super.key,
    required this.residence,
    required this.residentType,
    required this.recupererInformationsStep4,
    required this.currentPage,
    required this.progressController,
    required this.name,
    required this.surname,
    required this.pseudo,
    required this.compagnyBuy,
    required this.kbisPath,
    required this.intendedFor,
    required this.refLot,
    required this.userId,
    required this.typeLot, 
    required this.emailUser,
  });

  @override
  _Step4State createState() => _Step4State();
}

class _Step4State extends State<Step4> {
  late CameraDescription firstCamera;

  bool visible = false;
  bool visibleID = false;
  bool visibleJustif = false;
  String imagePathIDrecto = "";
  String imagePathIDverso = "";
  String imagePathJustif = "";
  String justifChoice = "";
  String? idChoice = "";

  List<String> idType = [
    "Carte d'identité",
    "Permis de conduire",
    "Passeport",
    "Titre de séjour",
  ];

  List<String> justifTypeProp = [
    "Attestation de propriété ",
  ];
  List<String> justifTypeLoc = [
    "Facture d'eau",
    "Facture téléphone",
    "Facture d'electricité",
    "Contrat de bail",
  ];

  String getIdType() {
    return idChoice!;
  }

  String getKbis() {
    return idChoice!;
  }

  String getPathIdrect() {
    return imagePathIDrecto;
  }

  String getPathIdvers() {
    return imagePathIDverso;
  }

  String getJustifType() {
    return justifChoice;
  }

  String getJustifPath() {
    return imagePathJustif;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: MyTextStyle.lotName(
                  "A présent veuillez nous fournir une pièce d'identité et un justificatif de domicile du bien de la residence ${widget.residence.name}",
                  Colors.black54),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyTextStyle.lotName("Type de document: ", Colors.black54),
                  DropdownMenu<String>(
                    //initialSelection: typeDeclaration,
                    hintText: "Choisir...",
                    onSelected: (String? value) {
                      // This is called when the user selects an item.
                      setState(() {
                        idChoice = value;
                        visibleID = true;
                      });
                    },
                    dropdownMenuEntries:
                        idType.map<DropdownMenuEntry<String>>((String value) {
                      return DropdownMenuEntry<String>(
                          value: value, label: value);
                    }).toList(),
                    width: width / 2,
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Visibility(
              visible: visibleID,
              child: Column(
                children: [
                  const Divider(),
                  CameraOrFiles(
                    racineFolder: 'user',
                    residence: widget.userId,
                    folderName: 'documentID',
                    title: idChoice!,
                    onImageUploaded: (downloadUrl) =>
                        downloadImagePathID(downloadUrl, true),
                    cardOverlay: true,
                  ),
                ],
              ),
            ),
            Visibility(
              visible: imagePathIDrecto != "",
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    child: MyTextStyle.lotName(
                        "Merci de prendre l'autre coté de la carte",
                        Colors.black54),
                  ),
                  CameraOrFiles(
                    racineFolder: 'user',
                    residence: widget.userId,
                    folderName: 'documentID',
                    title: idChoice!,
                    onImageUploaded: (downloadUrl) =>
                        downloadImagePathID(downloadUrl, false),
                    cardOverlay: true,
                  ),
                ],
              ),
            ),
            Visibility(
              visible: imagePathIDverso != "",
              child: Column(
                children: [
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 20),
                    child: MyTextStyle.lotName(
                        "Maintenant fournissez un justificatif de domicile, attention ce document dois être au nom du document d'identité fournis",
                        Colors.black54),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MyTextStyle.lotName(
                            "Type de document: ", Colors.black54),
                        DropdownMenu<String>(
                          //initialSelection: typeDeclaration,
                          hintText: "Choisir...",
                          onSelected: (String? value) {
                            // This is called when the user selects an item.
                            setState(() {
                              justifChoice = value!;
                              visibleJustif = true;
                            });
                          },
                          dropdownMenuEntries: widget.residentType ==
                                  "Locataire"
                              ? justifTypeLoc.map<DropdownMenuEntry<String>>(
                                  (String value) {
                                  return DropdownMenuEntry<String>(
                                      value: value, label: value);
                                }).toList()
                              : justifTypeProp.map<DropdownMenuEntry<String>>(
                                  (String value) {
                                  return DropdownMenuEntry<String>(
                                      value: value, label: value);
                                }).toList(),
                          width: width / 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Visibility(
                    visible: visibleJustif,
                    child: Column(
                      children: [
                        const Divider(),
                        CameraOrFiles(
                          racineFolder: 'user',
                          residence: widget.userId,
                          folderName: 'justificatifDom',
                          title: idChoice!,
                          onImageUploaded: downloadImagePathJustif,
                          cardOverlay: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Visibility(
        visible: getJustifPath().isNotEmpty,
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
                    String IdDoc = getIdType();
                    String pathIdrecto = getPathIdrect();
                    String pathIdverso = getPathIdvers();
                    String justifChoice = getJustifType();
                    String pathJustif = getJustifType();

                    SubmitUser.submitUser(
                      emailUser:widget.emailUser,
                      name: widget.name,
                      surname: widget.surname,
                      pseudo: widget.pseudo,
                      newUserId: widget.userId,
                      statutResident: widget.residentType,
                      typeChoice: widget.typeLot,
                      intendedFor: widget.intendedFor,
                      compagnyBuy: widget.compagnyBuy,
                      kbisPath: widget.kbisPath,
                      residence: widget.residence,
                      lotId: widget.refLot,
                      docTypeID: idChoice,
                      docTypeJustif: justifChoice,
                      imagepathIDrecto:
                          imagePathIDrecto, // Passage en tant qu'argument nommé
                      imagepathIDverso:
                          imagePathIDverso, // Passage en tant qu'argument nommé
                      justifChoice:
                          justifChoice, // Passage en tant qu'argument nommé
                      imagepathJustif: imagePathJustif,
                    );
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

  void downloadImagePathID(String downloadUrl, bool isRecto) {
    setState(() {
      if (isRecto) {
        imagePathIDrecto = downloadUrl;
      } else {
        imagePathIDverso = downloadUrl;
      }
    });
  }

  void downloadImagePathJustif(String downloadUrl) {
    setState(() {
      //widget.updateUrl(downloadUrl);
      imagePathJustif = downloadUrl;
    });
  }
}
