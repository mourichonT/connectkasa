import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/have_not_account_widget/step0.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/have_not_account_widget/step1.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/have_not_account_widget/step2.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/have_not_account_widget/step3.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/have_not_account_widget/step4.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProgressWidget extends StatefulWidget {
  final String userId;
  final String? emailUser;

  const ProgressWidget({required this.userId, this.emailUser, super.key});

  @override
  State<StatefulWidget> createState() => ProgressWidgetState();
}

class ProgressWidgetState extends State<ProgressWidget>
    with WidgetsBindingObserver {
  double _progress = 0;
  int currentPage = 0;
  final PageController _progressController = PageController(initialPage: 0);

  String emailUser = "";
  String name = "";
  String surname = "";
  Timestamp birthday = Timestamp.now();
  String sex = "";
  String imagePathIDrecto = "";
  String imagePathIDverso = "";
  String nationality = "";
  String placeOfBorn = "";
  String pseudo = "";
  Residence? residence;
  String residentType = "";
  bool compagnyBuy = false;
  String kbisPath = "";
  String intendedFor = "";
  String typeLot = "";
  String batType = "";
  String lotChoice = "";
  String idType = "";
  String pathIdRect = "";
  String pathIdVers = "";
  String justifType = "";
  String pathJustif = "";
  String? refLot = "";
  Timer? _deleteTimer;
  bool isCameraOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progress = 1 / 5; // Assuming you have 5 steps
    _startDeletionTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressController.dispose();
    super.dispose();
  }

  void _startDeletionTimer() {
    _deleteTimer = Timer(Duration(minutes: 10), () {
      DataBasesUserServices.removeUserById(widget.userId);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        !isCameraOpen) {
      // Supprimer l'utilisateur si l'application est fermée ou inactive
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == widget.userId) {
          await currentUser.delete();
          await DataBasesUserServices.removeUserById(currentUser.uid);
          Navigator.popUntil(context, ModalRoute.withName('/'));
          print(
              "Utilisateur supprimé après fermeture de l'application : ${widget.userId}");
        }
      } catch (e) {
        print(
            "Erreur lors de la suppression de l'utilisateur après fermeture : $e");
      }
    }
  }

  void _handleCameraState(bool isOpen) {
    setState(() {
      isCameraOpen = isOpen;
    });
  }

  void getInformationsStep0(
      String email,
      String newName,
      String newSurname,
      String newBirthday,
      String newSex,
      String newNationality,
      String newPlaceOfBorn,
      String? newPseudo,
      String newImagePathIDrecto,
      String newimagePathIDverso) {
    // Faites ce que vous voulez avec les valeurs récupérées
    print(
        'Nom: $newName, Prénom: $newSurname, Pseudo: $newPseudo, imagepath: $newimagePathIDverso');
    email = emailUser;
    name = newName;
    sex = newSex;
    birthday = formatBirthday(newBirthday);
    imagePathIDrecto = newImagePathIDrecto;
    imagePathIDverso = newimagePathIDverso;
    nationality = newNationality;
    placeOfBorn = newPlaceOfBorn;
    surname = newSurname;
    pseudo = newPseudo ?? "";
  }

  Timestamp formatBirthday(String date) {
    DateFormat format = DateFormat("dd MM yyyy");
    DateTime localDate = format.parse(date);
    DateTime utcPlus3Date = localDate.add(Duration(hours: 3));
    return Timestamp.fromMillisecondsSinceEpoch(
        utcPlus3Date.millisecondsSinceEpoch);
  }

  void getInformationsStep1(Residence newResidence) {
    // Faites ce que vous voulez avec les valeurs récupérées
    print('residence : $newResidence');
    setState(() {
      residence = newResidence;
    });
  }

  void getInformationsStep2(String newResidentType, bool newCompagnyBuy,
      String newIntendedFor, String newKbisPath) {
    // Faites ce que vous voulez avec les valeurs récupérées
    print(
        'Type resident: $newResidentType, achat par société: $newCompagnyBuy, destiné a : $newIntendedFor');

    residentType = newResidentType;
    compagnyBuy = newCompagnyBuy;
    intendedFor = newIntendedFor;
    kbisPath = newKbisPath;
  }

  void getInformationsStep3(String newTypeLot, String newBatType,
      String newLotChoice, String newrefLot) {
    // Faites ce que vous voulez avec les valeurs récupérées
    print(
        'Type resident: $newTypeLot, achat par société: $newBatType, destiné a : $newLotChoice, refLOT $newrefLot');

    typeLot = newTypeLot;
    batType = newBatType;
    lotChoice = newLotChoice;
    refLot = newrefLot;
  }

  void getInformationsStep4(String newIdType, String newImagePathIdrect,
      String newImagePathIdvers, String newJustifType, String newPathJustif) {
    // Faites ce que vous voulez avec les valeurs récupérées
    print(
        'Type id: $newIdType, path id recto: $newImagePathIdrect, path id verso: $newImagePathIdvers');

    idType = newIdType;
    pathIdRect = newImagePathIdrect;
    pathIdVers = newImagePathIdvers;
    justifType = newJustifType;
    pathJustif = newPathJustif;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (currentPage > 0) {
                _progressController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                // Supprimer l'utilisateur de Firebase Auth
                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null && currentUser.uid == widget.userId) {
                    await currentUser.delete();
                    await DataBasesUserServices.removeUserById(currentUser
                        .uid); // Supprime l'utilisateur de Firebase Auth
                    print("Utilisateur supprimé : ${widget.userId}");
                  }
                } catch (e) {
                  print("Erreur lors de la suppression de l'utilisateur : $e");
                }
                // Ferme la page
                Navigator.of(context).pop();
              }
            },
          ),
          title: MyTextStyle.lotName(
              "Vous êtes à l'étape ${currentPage + 1} / 5", Colors.black54),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(5),
            child: LinearProgressIndicator(
              minHeight: 5.0,
              value: _progress,
              color: Theme.of(context).primaryColor,
              backgroundColor: Colors.grey[300],
            ),
          ),
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _progressController,
          onPageChanged: (int page) {
            setState(() {
              currentPage = page;
              _progress = (currentPage + 1) /
                  5; // Update the progress based on the current page
            });
          },
          children: [
            Step0(
              emailUser: widget.emailUser ?? "",
              userId: widget.userId,
              recupererInformationsStep0: getInformationsStep0,
              currentPage: currentPage,
              progressController: _progressController,
              onCameraStateChanged: _handleCameraState,
            ),
            Step1(
              recupererInformationsStep1: getInformationsStep1,
              currentPage: currentPage,
              progressController: _progressController,
            ),
            Step2(
              recupererInformationsStep2: getInformationsStep2,
              currentPage: currentPage,
              progressController: _progressController,
              onCameraStateChanged: _handleCameraState,
            ),
            Step3(
              typeResident: residentType,
              residence: residence ??
                  Residence(
                      name: '',
                      numero: '',
                      voie: '',
                      street: '',
                      zipCode: '',
                      city: '',
                      refGerance: '',
                      id: ''),
              recupererInformationsStep3: getInformationsStep3,
              currentPage: currentPage,
              progressController: _progressController,
            ),
            Step4(
              userId: widget.userId,
              emailUser: widget.emailUser!,
              name: name,
              surname: surname,
              sex: sex,
              nationality: nationality,
              imagepathIDrecto: imagePathIDrecto,
              imagepathIDverso: imagePathIDverso,
              placeOfBorn: placeOfBorn,
              pseudo: pseudo,
              compagnyBuy: compagnyBuy,
              kbisPath: kbisPath,
              typeLot: typeLot,
              intendedFor: intendedFor,
              residentType: residentType,
              residence: residence ??
                  Residence(
                      name: '',
                      numero: '',
                      voie: '',
                      street: '',
                      zipCode: '',
                      city: '',
                      refGerance: '',
                      id: ''),
              refLot: refLot!,
              recupererInformationsStep4: getInformationsStep4,
              currentPage: currentPage,
              progressController: _progressController,
              onCameraStateChanged: _handleCameraState,
              birthday: birthday,
            ),
          ],
        ),
      ),
    );
  }
}
