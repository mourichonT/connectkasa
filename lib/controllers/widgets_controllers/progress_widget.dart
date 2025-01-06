import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/databases_lot_services.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/vues/widget_view/have_not_account_widget/step0.dart';
import 'package:connect_kasa/vues/widget_view/have_not_account_widget/step1.dart';
import 'package:connect_kasa/vues/widget_view/have_not_account_widget/step2.dart';
import 'package:connect_kasa/vues/widget_view/have_not_account_widget/step3.dart';
import 'package:connect_kasa/vues/widget_view/have_not_account_widget/step4.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProgressWidget extends StatefulWidget {
  final String userId;
  final String? emailUser;

  ProgressWidget({required this.userId, this.emailUser, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ProgressWidgetState();
}

class ProgressWidgetState extends State<ProgressWidget>  with WidgetsBindingObserver {
  double _progress = 0;
  int currentPage = 0;
  final PageController _progressController = PageController(initialPage: 0);

  String emailUser="";
  String name = "";
  String surname = "";
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progress = 1 / 5; // Assuming you have 5 steps
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressController.dispose();
    super.dispose();
  }

@override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      // Supprimer l'utilisateur si l'application est fermée ou inactive
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == widget.userId) {
          await currentUser.delete();
          await DataBasesUserServices.removeUserById(currentUser.uid);
          Navigator.popUntil( context, ModalRoute.withName('/'));
          print("Utilisateur supprimé après fermeture de l'application : ${widget.userId}");
        }
      } catch (e) {
        print("Erreur lors de la suppression de l'utilisateur après fermeture : $e");
      }
    }
  }

  void getInformationsStep0(
      String email, String newName, String newSurname, String? newPseudo) {
    // Faites ce que vous voulez avec les valeurs récupérées
    print('Nom: $newName, Prénom: $newSurname, Pseudo: $newPseudo');
    email=emailUser;
    name = newName;
    surname = newSurname;
    pseudo = newPseudo??"";
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
    icon: Icon(Icons.arrow_back),
    onPressed: () async {
      if (currentPage > 0) {
        _progressController.previousPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Supprimer l'utilisateur de Firebase Auth
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && currentUser.uid == widget.userId) {
            await currentUser.delete();
            await DataBasesUserServices.removeUserById(currentUser.uid); // Supprime l'utilisateur de Firebase Auth
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
            preferredSize: Size.fromHeight(5),
            child: LinearProgressIndicator(
              minHeight: 5.0,
              value: _progress,
              color: Theme.of(context).primaryColor,
              backgroundColor: Colors.grey[300],
            ),
          ),
        ),
        body: PageView(
          physics: NeverScrollableScrollPhysics(),
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
              emailUser : widget.emailUser??"",
              userId: widget.userId,
              recupererInformationsStep0: getInformationsStep0,
              currentPage: currentPage,
              progressController: _progressController,
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
            ),
          ],
        ),
      ),
    );
  }
}
