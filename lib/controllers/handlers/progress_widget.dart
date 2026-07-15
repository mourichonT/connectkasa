import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/repositories/firestore_storage_repository.dart';
import 'package:konodal/models/pages_models/residence.dart';
import 'package:konodal/vues/widget_view/page_widget/have_not_account_widget/step0.dart';
import 'package:konodal/vues/widget_view/page_widget/have_not_account_widget/step1.dart';
import 'package:konodal/vues/widget_view/page_widget/have_not_account_widget/step2.dart';
import 'package:konodal/vues/widget_view/page_widget/have_not_account_widget/step3.dart';
import 'package:konodal/vues/widget_view/page_widget/have_not_account_widget/step4.dart';
import 'package:konodal/vues/widget_view/page_widget/have_not_account_widget/step4_bis.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:konodal/core/utils/app_logger.dart';

class ProgressWidget extends StatefulWidget {
  final String userId;
  final String? emailUser;
  final String? password;
  final String? providerId;

  const ProgressWidget(
      {required this.userId,
      this.emailUser,
      super.key,
      this.password,
      this.providerId});

  @override
  State<StatefulWidget> createState() => ProgressWidgetState();
}

class ProgressWidgetState extends State<ProgressWidget>
    with WidgetsBindingObserver {
  double _progress = 0;
  int currentPage = 0;
  final PageController _progressController = PageController(initialPage: 0);
  final currentUser = FirebaseAuth.instance.currentUser;
  String emailUser = "";
  String name = "";
  String surname = "";
  Timestamp birthday = Timestamp.now();
  String sex = "";
  String imagePathIDrecto = "";
  String imagePathIDverso = "";
  String idExtension = "";
  String nationality = "";
  String placeOfBorn = "";
  String pseudo = "";
  Residence? residence;
  // Positionné par Step1 ("Je n'ai pas encore de résidence") : saute Step2 et
  // Step3 (type de résident/lot, sans objet sans résidence) et affiche
  // Step4Bis (page 5 du PageView) à la place de Step4.
  bool noResidence = false;
  String residentType = "";
  bool compagnyBuy = false;
  String kbisPath = "";
  String kbisExtension = "";
  String intendedFor = "";
  String typeLot = "";
  String batType = "";
  String lotChoice = "";
  // ID du document Firestore residences/{id}/lots/{lotDocId}, résolu par
  // Step3 (getUniqueLot) - à ne pas confondre avec refLot (référence
  // métier) : sert à ranger les documents dépendant du lot dans Storage
  // (justificatifDom/compagnyDoc) par leur vrai identifiant.
  String? lotDocId = "";
  String idType = "";
  String pathIdRect = "";
  String pathIdVers = "";
  String justifType = "";
  String pathJustif = "";
  String? refLot = "";
  List<String> pendingChildLotIds = [];
  bool isUserCompleted = false;
  Timer? _deleteTimer;
  bool isCameraOpen = false;
  bool informationsCorrectes = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progress = 1 / 5; // Assuming you have 5 steps
    //_startDeletionTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressController.dispose();
    if (!isUserCompleted &&
        currentUser != null &&
        currentUser!.uid == widget.userId) {
      // Le nettoyage Firestore (users/{uid} et sous-collections) est
      // désormais fait automatiquement côté serveur (Cloud Function
      // cleanupUserData, functions/index.js) dès que le compte Auth est
      // supprimé — impossible à faire depuis le client une fois
      // déconnecté (firestore.rules exige request.auth).
      _deleteUser();
      _deleteStorage();
      appLog("Utilisateur supprimé dans la fonction dispose : ${widget.userId}");
    }
    super.dispose();
  }

  // Fonction pour supprimer l'utilisateur de Firebase Authentication
  Future<void> _deleteUser() async {
    final user = FirebaseAuth.instance.currentUser;

    // Vérifier le fournisseur d'authentification
    if (widget.providerId == "password") {
      // Si l'utilisateur s'est authentifié via mot de passe
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: widget.password!,
      );

      try {
        await user.reauthenticateWithCredential(cred);
        await user.delete(); // Suppression de l'utilisateur
        appLog("Utilisateur supprimé après re-auth avec mot de passe");
      } catch (e) {
        appLog("Erreur lors de la suppression avec mot de passe: $e");
      }
    } else if (widget.providerId == "google.com") {
      // Si l'utilisateur s'est authentifié via Google
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signInSilently();

      if (googleUser == null) {
        appLog("⚠️ Reconnexion silencieuse échouée.");
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        await user!.reauthenticateWithCredential(credential);
        await user.delete(); // Suppression de l'utilisateur
        appLog("Utilisateur supprimé après re-auth avec Google");
      } catch (e) {
        appLog("Erreur lors de la suppression avec Google: $e");
      }
    }
  }

  void _deleteStorage() async {
    final storageServices = FirestoreStorageRepository();
    storageServices.removeFolder("user", widget.userId);
  }

  // void _startDeletionTimer() {
  //   try {
  //     if (currentUser != null && currentUser!.uid == widget.userId) {
  //       // Définir un timer pour la suppression après 10 minutes d'inactivité
  //       _deleteTimer = Timer(Duration(minutes: 10), () {
  //         // Supprimer l'utilisateur de la base de données et du stockage
  //         _deleteUser();
  //         _deleteStorage();

  //         // Supprimer également l'utilisateur de Firebase Authentication
  //         DataBasesUserServices.removeUserById(widget.userId);

  //         appLog("Utilisateur supprimé automatiquement après 10 minutes.");
  //         // Vous pouvez aussi rediriger l'utilisateur à l'écran d'accueil
  //         Navigator.popUntil(context, ModalRoute.withName('/'));
  //       });
  //     }
  //   } catch (e) {
  //     appLog(
  //         "Erreur lors de l'initialisation du timer de suppression automatique: $e");
  //   }
  // }

  void _cancelDeletionTimer() {
    if (_deleteTimer != null && _deleteTimer!.isActive) {
      _deleteTimer!.cancel();
      _deleteTimer = null;
      appLog("Timer de suppression annulé");
    }
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) async {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached) &&
        !isCameraOpen) {
      appLog("Supprimer l'utilisateur si l'application est fermée ou inactive");
      try {
        if (currentUser != null && currentUser!.uid == widget.userId) {
          await currentUser!.delete();
          _deleteStorage();
          if (!mounted) return;
          Navigator.popUntil(context, ModalRoute.withName('/'));
          appLog(
              "Utilisateur supprimé après fermeture de l'application : ${widget.userId}");
        }
      } catch (e) {
        appLog(
            "Erreur lors de la suppression de l'utilisateur après fermeture : $e");
      }
    }
  }

  Future<bool> silentReauthAndDelete() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      appLog("⚠️ Aucune session active.");
      return false;
    }

    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signInSilently();

    if (googleUser == null) {
      appLog("⚠️ Reconnexion silencieuse échouée.");
      return false;
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      await user.delete(); // ✅ Suppression après re-auth
      appLog("✅ Compte supprimé !");
      return true;
    } catch (e) {
      appLog("❌ Erreur lors de la re-auth: $e");
      return false;
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
    String newimagePathIDverso,
    String docTypeId,
    String newIdExtension,
    bool? newInformationsCorrectes,
  ) {
    // Faites ce que vous voulez avec les valeurs récupérées
    appLog(
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
    idType = docTypeId;
    idExtension = newIdExtension;
    informationsCorrectes = newInformationsCorrectes ?? false;
  }

  Timestamp formatBirthday(String date) {
    final formats = [
      DateFormat("dd MM yyyy"),
      DateFormat("dd/MM/yyyy"),
      DateFormat("dd-MM-yyyy"),
      DateFormat("yyyy-MM-dd"),
      DateFormat("yyyy/MM/dd"),
      DateFormat("MM/dd/yyyy"),
      DateFormat("MM-dd-yyyy"),
      DateFormat("dd.MM.yyyy"),
      DateFormat("d MMM yyyy", 'fr_FR'), // ex : 5 janv. 2023
      DateFormat("d MMMM yyyy", 'fr_FR'), // ex : 5 janvier 2023
      DateFormat("d MMM yyyy", 'en_US'), // ex : 10 May 1988
      DateFormat("d MMMM yyyy", 'en_US'), // ex : 10 May 1988 (long)
      DateFormat("dd MMM yyyy", 'en_US'), // ex : 05 May 1988
      DateFormat("dd MMMM yyyy", 'en_US'), // ex : 05 May 1988 (long)
      DateFormat("d MMM yyyy", 'en_GB'), // variante UK
      DateFormat("d MMMM yyyy", 'en_GB'),
    ];

    DateTime? localDate;

    for (var format in formats) {
      try {
        localDate = format.parseStrict(date);
        break;
      } catch (e) {
        // Ignore and try next format
      }
    }

    if (localDate == null) {
      throw FormatException("Unrecognized date format: $date");
    }

    final utcPlus3Date = localDate.add(const Duration(hours: 3));

    return Timestamp.fromMillisecondsSinceEpoch(
      utcPlus3Date.millisecondsSinceEpoch,
    );
  }

  void getInformationsStep1(Residence newResidence) {
    // Faites ce que vous voulez avec les valeurs récupérées
    appLog('residence : $newResidence');
    setState(() {
      residence = newResidence;
    });
  }

  // Step1 "Je n'ai pas encore de résidence" : saute Step2/Step3 (résidence,
  // type de résident, lot - tous sans objet ici) et va directement sur
  // Step4Bis (page 5), plutôt que Step4 (page 4) atteinte par nextPage().
  void _skipToNoResidence() {
    setState(() {
      noResidence = true;
      residence = null;
    });
    _progressController.jumpToPage(5);
  }

  void getInformationsStep2(String newResidentType, bool newCompagnyBuy,
      String newIntendedFor, String newKbisPath, String newKbisExtension,
      List<String> newPendingChildLotIds) {
    // Faites ce que vous voulez avec les valeurs récupérées
    appLog(
        'Type resident: $newResidentType, achat par société: $newCompagnyBuy, destiné a : $newIntendedFor');

    residentType = newResidentType;
    compagnyBuy = newCompagnyBuy;
    intendedFor = newIntendedFor;
    kbisPath = newKbisPath;
    kbisExtension = newKbisExtension;
    pendingChildLotIds = newPendingChildLotIds;
  }

  void getInformationsStep3(String newTypeLot, String newBatType,
      String newLotChoice, String newrefLot, String newLotDocId) {
    // Faites ce que vous voulez avec les valeurs récupérées
    appLog(
        'Type resident: $newTypeLot, achat par société: $newBatType, destiné a : $newLotChoice, refLOT $newrefLot, lotDocId $newLotDocId');

    typeLot = newTypeLot;
    batType = newBatType;
    lotChoice = newLotChoice;
    refLot = newrefLot;
    lotDocId = newLotDocId;
  }

  void getInformationsStep4(bool newIsUserCompleted) {
    isUserCompleted = newIsUserCompleted;
    appLog("isUserCompleted : $isUserCompleted");
  }

  @override
  Widget build(BuildContext context) {
    appLog(
        "Utilisateur après push dans progress widget: ${FirebaseAuth.instance.currentUser?.uid}");
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (noResidence && currentPage == 5) {
                // Step4Bis (page 5) n'a pas été atteinte par nextPage() mais
                // par jumpToPage() depuis Step1 (page 1) : previousPage()
                // renverrait vers Step4 (page 4), qui n'a pas de sens dans ce
                // parcours - retour direct à Step1.
                setState(() => noResidence = false);
                _progressController.jumpToPage(1);
              } else if (currentPage > 0) {
                appLog("PASSWORD; ${widget.password}");
                _progressController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                // Supprimer l'utilisateur de Firebase Auth
                try {
                  if (currentUser != null &&
                      currentUser!.uid == widget.userId) {
                    _deleteUser();
                    appLog("Utilisateur supprimé : ${widget.userId}");
                  }
                } catch (e) {
                  appLog("Erreur lors de la suppression de l'utilisateur : $e");
                }
                // Ferme la page
                Navigator.of(context).pop();
              }
            },
          ),
          title: MyTextStyle.lotName(
              "Vous êtes à l'étape ${noResidence ? 5 : currentPage + 1} / 5",
              Colors.black54),
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
              // page 5 = Step4Bis, atteinte via jumpToPage (pas nextPage) :
              // (page+1)/5 dépasserait 1.0, invalide pour LinearProgressIndicator.
              _progress = page == 5 ? 1.0 : (page + 1) / 5;
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
              onNoResidence: _skipToNoResidence,
              currentPage: currentPage,
              progressController: _progressController,
            ),
            Step3(
              residence: residence ??
                  Residence(
                    name: '',
                    street: '',
                    zipCode: '',
                    city: '',
                    id: '',
                  ),
              recupererInformationsStep3: getInformationsStep3,
              currentPage: currentPage,
              progressController: _progressController,
            ),
            Step2(
              recupererInformationsStep2: getInformationsStep2,
              currentPage: currentPage,
              progressController: _progressController,
              onCameraStateChanged: _handleCameraState,
              userId: widget.userId,
              lotId: lotDocId,
              residence: residence ??
                  Residence(
                    name: '',
                    street: '',
                    zipCode: '',
                    city: '',
                    id: '',
                  ),
            ),
            Step4(
              informationsCorrectes: informationsCorrectes,
              userId: widget.userId,
              emailUser: widget.emailUser!,
              name: name,
              surname: surname,
              docTypeId: idType,
              sex: sex,
              nationality: nationality,
              imagepathIDrecto: imagePathIDrecto,
              imagepathIDverso: imagePathIDverso,
              idExtension: idExtension,
              placeOfBorn: placeOfBorn,
              pseudo: pseudo,
              compagnyBuy: compagnyBuy,
              kbisPath: kbisPath,
              kbisExtension: kbisExtension,
              typeLot: typeLot,
              intendedFor: intendedFor,
              residentType: residentType,
              residence: residence ??
                  Residence(
                    name: '',
                    street: '',
                    zipCode: '',
                    city: '',
                    id: '',
                  ),
              refLot: refLot!,
              lotDocId: lotDocId,
              pendingChildLotIds: pendingChildLotIds,
              recupererInformationsStep4: getInformationsStep4,
              currentPage: currentPage,
              progressController: _progressController,
              onCameraStateChanged: _handleCameraState,
              birthday: birthday,
              cancelDeletionTimer: _cancelDeletionTimer,
            ),
            Step4Bis(
              userId: widget.userId,
              emailUser: widget.emailUser ?? "",
              docTypeId: idType,
              name: name,
              surname: surname,
              pseudo: pseudo,
              birthday: birthday,
              imagepathIDrecto: imagePathIDrecto,
              imagepathIDverso: imagePathIDverso,
              idExtension: idExtension,
              sex: sex,
              nationality: nationality,
              placeOfBorn: placeOfBorn,
              informationsCorrectes: informationsCorrectes,
              cancelDeletionTimer: _cancelDeletionTimer,
              recupererInformationsStep4: getInformationsStep4,
            ),
          ],
        ),
      ),
    );
  }
}
