import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connect_kasa/controllers/features/load_user_controller.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/providers/message_provider.dart';
import 'package:connect_kasa/core/repositories/firestore_docs_repository.dart';
import 'package:connect_kasa/core/repositories/firestore_lot_repository.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/document_model.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/vues/widget_view/components/camera_files_choices.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/have_not_account_widget/step1.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/have_not_account_widget/step2.dart';
import 'package:connect_kasa/vues/widget_view/page_widget/have_not_account_widget/step3.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Rattache un utilisateur déjà existant (connecté) à une résidence/un lot
/// déjà créés en base, via recherche. Réutilise Step1/Step2/Step3 du
/// parcours de création de compte (UI pures, sans dépendance à la création
/// de compte Firebase Auth), dans un conteneur dédié : ProgressWidget (le
/// conteneur habituel de ces steps) supprime le compte Firebase Auth si
/// l'utilisateur revient en arrière avant la fin — logique volontairement
/// absente ici, elle n'a pas sa place pour un compte existant.
///
/// Contrairement au parcours de création (Step4 + SubmitUser, qui recrée
/// tout le profil : identité, pièce d'identité...), la soumission finale ici
/// ne fait que rattacher le lot et déposer le justificatif de domicile :
/// l'utilisateur a déjà un profil complet, inutile de le lui refaire saisir.
///
/// Si [resetApproval] est vrai (cas par défaut : utilisateur bloqué sans
/// aucun lot, cf. my_nav_bar.dart), le compte repasse en `approved: false`
/// à la fin et l'utilisateur est déconnecté : un premier rattachement doit
/// être revalidé par une personne, comme à l'inscription. Si faux (cas
/// ManagementProperty : un utilisateur déjà actif qui rattache un lot
/// supplémentaire à son compte), on ne touche pas à `approved` — il n'y a
/// pas lieu de re-suspendre l'accès d'un utilisateur déjà validé.
class AttachExistingLotPage extends StatefulWidget {
  final String uid;
  final bool resetApproval;

  const AttachExistingLotPage({
    super.key,
    required this.uid,
    this.resetApproval = true,
  });

  @override
  State<AttachExistingLotPage> createState() => _AttachExistingLotPageState();
}

class _AttachExistingLotPageState extends State<AttachExistingLotPage> {
  final PageController _pageController = PageController();
  final LoadUserController _loadUserController = LoadUserController();

  Residence? _residence;
  String _typeResident = "";
  bool _compagnyBuy = false;
  String _intendedFor = "";
  String _kbisPath = "";
  String _batiment = "";
  String _numLot = "";
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onResidenceFound(Residence residence) {
    setState(() => _residence = residence);
  }

  void _onRoleDefined(
      String typeResident, bool compagnyBuy, String intendedFor, String kbisPath) {
    setState(() {
      _typeResident = typeResident;
      _compagnyBuy = compagnyBuy;
      _intendedFor = intendedFor;
      _kbisPath = kbisPath;
    });
  }

  void _onLotFound(
      String typeBien, String batiment, String numLot, String refLot) {
    setState(() {
      _batiment = batiment;
      _numLot = numLot;
    });
  }

  Future<void> _submit(String docTypeJustif, String justifPath) async {
    if (_residence == null || _isSaving) return;
    setState(() => _isSaving = true);

    // Step3 ne renvoie que le refLot (référence métier), pas l'ID Firestore
    // du document nécessaire à addLotToUser/setDocument : on le retrouve ici.
    final lot = await FirestoreLotRepository()
        .getUniqueLot(_residence!.id, _batiment, _numLot)
        .then((result) =>
            result.when(success: (v) => v, failure: (_) => null));

    if (lot?.id == null) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lot introuvable, réessayez.")),
        );
      }
      return;
    }

    await DataBasesUserServices.addLotToUser(
      userId: widget.uid,
      lotId: lot!.id!,
      residenceId: _residence!.id,
      intendedFor: _intendedFor,
      statutResident: _typeResident,
    );

    // addLotToUser ne dénormalise que côté User/{uid}/lots : le lot
    // Residence/{id}/lot/{id} lui-même (idLocataire/idProprietaire, lu par
    // ex. par getNumUsersByResidence pour "Mes voisins") doit être mis à
    // jour séparément, comme le fait _applyTenantChange pour le flux
    // "propriétaire ajoute un locataire".
    final lotRef = FirebaseFirestore.instance
        .collection("Residence")
        .doc(_residence!.id)
        .collection("lot")
        .doc(lot.id);
    final field =
        _typeResident == "Propriétaire" ? "idProprietaire" : "idLocataire";
    await lotRef.update({
      field: FieldValue.arrayUnion([widget.uid]),
    });

    final docsRepository = FirestoreDocsRepository();

    if (docTypeJustif.isNotEmpty && justifPath.isNotEmpty) {
      await docsRepository.setDocument(
        DocumentModel(
          type: docTypeJustif,
          residenceId: _residence!.id,
          timeStamp: Timestamp.now(),
          documentPathRecto: justifPath,
          lotId: lot.refLot,
        ),
        widget.uid,
        lot.id,
      );
    }

    if (_compagnyBuy && _kbisPath.isNotEmpty) {
      await docsRepository.setDocument(
        DocumentModel(
          type: "Kbis",
          residenceId: _residence!.id,
          timeStamp: Timestamp.now(),
          documentPathRecto: _kbisPath,
          lotId: lot.refLot,
        ),
        widget.uid,
        lot.id,
      );
    }

    if (!widget.resetApproval) {
      // Utilisateur déjà actif (ManagementProperty) rattachant un lot
      // supplémentaire : pas de revalidation à déclencher, il n'y a pas
      // lieu de re-suspendre un compte déjà approuvé.
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    // Un nouveau rattachement de lot doit être revalidé, comme à
    // l'inscription : on ne conserve pas l'accès complet acquis avant ce
    // rattachement tant qu'une personne n'a pas revérifié la situation.
    // approved n'est volontairement pas modifiable par le client
    // (firestore.rules) : seule cette Cloud Function, via le SDK Admin,
    // est autorisée à le repasser à false.
    await FirebaseFunctions.instance
        .httpsCallable('reset_approval_after_self_attach')
        .call();

    if (!mounted) return;

    // approved n'est vérifié qu'au moment de la connexion
    // (authentification_process.dart), jamais en cours de session : sans
    // déconnexion explicite ici, l'utilisateur garderait l'accès complet
    // dans cette session malgré approved repassé à false. On déconnecte
    // donc immédiatement pour forcer une nouvelle connexion, qui affichera
    // correctement NoApprovalPage.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: MyTextStyle.lotDesc(
          "Votre demande a été transmise à notre équipe. Vous allez être "
          "déconnecté le temps de la validation.", SizeFont.h2.size,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (!mounted) return;
    context.read<MessageProvider>().reset();
    await _loadUserController.handleGoogleSignOut();
    if (!mounted) return;
    Navigator.of(context).popUntil(ModalRoute.withName('/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName("Rattacher mon compte", Colors.black87, SizeFont.h1.size),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Vous ne trouvez pas votre résidence ?"),
                content: const Text(
                    "Contactez notre support, votre résidence n'a peut-être "
                    "pas encore été créée dans l'application."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Fermer"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Step1(
                  currentPage: 0,
                  progressController: _pageController,
                  recupererInformationsStep1: _onResidenceFound,
                ),
                if (_residence != null)
                  Step2(
                    currentPage: 1,
                    progressController: _pageController,
                    onCameraStateChanged: (_) {},
                    recupererInformationsStep2: _onRoleDefined,
                  )
                else
                  const SizedBox.shrink(),
                if (_residence != null && _typeResident.isNotEmpty)
                  Step3(
                    residence: _residence!,
                    typeResident: _typeResident,
                    currentPage: 2,
                    progressController: _pageController,
                    recupererInformationsStep3: _onLotFound,
                  )
                else
                  const SizedBox.shrink(),
                if (_batiment.isNotEmpty && _numLot.isNotEmpty)
                  _JustificatifStep(
                    typeResident: _typeResident,
                    userId: widget.uid,
                    onSubmit: _submit,
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
    );
  }
}

/// Dernière étape : justificatif de domicile, avant soumission finale.
/// Contrairement à Step4 (parcours de création), ne redemande aucune
/// information déjà connue pour un compte existant (identité, pièce
/// d'identité...) — uniquement ce qui concerne le nouveau rattachement.
class _JustificatifStep extends StatefulWidget {
  final String typeResident;
  final String userId;
  final Future<void> Function(String docTypeJustif, String justifPath) onSubmit;

  const _JustificatifStep({
    required this.typeResident,
    required this.userId,
    required this.onSubmit,
  });

  @override
  State<_JustificatifStep> createState() => _JustificatifStepState();
}

class _JustificatifStepState extends State<_JustificatifStep> {
  String justifChoice = "";
  String imagePathJustif = "";
  bool visibleJustif = false;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final items = widget.typeResident == "Locataire"
        ? TypeList.justifTypeLocs
        : TypeList.justifTypeProps;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MyTextStyle.lotName(
                  "Fournissez un justificatif de domicile pour ce lot",
                  Colors.black54),
              const SizedBox(height: 30),
              MyDropDownMenu(
                width,
                "Type de document",
                "Choisir un type de document",
                false,
                items: items,
                onValueChanged: (String value) {
                  setState(() {
                    justifChoice = value;
                    visibleJustif = true;
                  });
                },
              ),
              const SizedBox(height: 30),
              Visibility(
                visible: visibleJustif,
                child: CameraOrFiles(
                  racineFolder: 'user',
                  residence: widget.userId,
                  folderName: 'justificatifDom',
                  title: justifChoice,
                  cardOverlay: true,
                  onCameraStateChanged: (_) {},
                  onImageUploaded: (downloadUrl) {
                    setState(() => imagePathJustif = downloadUrl);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        surfaceTintColor: Colors.white,
        padding: const EdgeInsets.all(2),
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: (visibleJustif && imagePathJustif.isNotEmpty)
                  ? () => widget.onSubmit(justifChoice, imagePathJustif)
                  : null,
              child: const Text("Soumettre"),
            ),
          ],
        ),
      ),
    );
  }
}
