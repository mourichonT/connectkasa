import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/current_user_provider.dart';
import 'package:konodal/core/providers/docs_repository_provider.dart';
import 'package:konodal/core/providers/lot_repository_provider.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/models/pages_models/document_model.dart';
import 'package:konodal/models/pages_models/residence.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/camera_files_choices.dart';
import 'package:konodal/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:konodal/vues/widget_view/page_widget/have_not_account_widget/step1.dart';
import 'package:konodal/vues/widget_view/page_widget/have_not_account_widget/step2.dart';
import 'package:konodal/vues/widget_view/page_widget/have_not_account_widget/step3.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/vues/widget_view/components/app_loader.dart';

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
/// Le lot nouvellement rattaché démarre avec `isApprovedLot: false` sur
/// users/{uid}/lots/{lotId} (cf. addLotToUser) : c'est ce champ, propre à ce
/// lot, qui gate son usage tant qu'une personne n'a pas revérifié les
/// documents déposés — le compte lui-même (`isApproved`, global) n'est plus
/// touché ici, pour ne pas suspendre l'accès aux autres lots déjà validés
/// de l'utilisateur.
class AttachExistingLotPage extends ConsumerStatefulWidget {
  final String uid;

  const AttachExistingLotPage({
    super.key,
    required this.uid,
  });

  @override
  ConsumerState<AttachExistingLotPage> createState() =>
      _AttachExistingLotPageState();
}

class _AttachExistingLotPageState
    extends ConsumerState<AttachExistingLotPage> {
  final PageController _pageController = PageController();

  Residence? _residence;
  String _typeResident = "";
  bool _compagnyBuy = false;
  String _intendedFor = "";
  String _kbisPath = "";
  String _kbisExtension = "";
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

  void _onRoleDefined(String typeResident, bool compagnyBuy,
      String intendedFor, String kbisPath, String kbisExtension) {
    setState(() {
      _typeResident = typeResident;
      _compagnyBuy = compagnyBuy;
      _intendedFor = intendedFor;
      _kbisPath = kbisPath;
      _kbisExtension = kbisExtension;
    });
  }

  void _onLotFound(
      String typeBien, String batiment, String numLot, String refLot) {
    setState(() {
      _batiment = batiment;
      _numLot = numLot;
    });
  }

  Future<void> _submit(
      String docTypeJustif, String justifPath, String justifExtension) async {
    if (_residence == null || _isSaving) return;
    setState(() => _isSaving = true);

    // Step3 ne renvoie que le refLot (référence métier), pas l'ID Firestore
    // du document nécessaire à addLotToUser/setDocument : on le retrouve ici.
    final lot = await ref
        .read(lotRepositoryProvider)
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

    await ref
        .read(userRepositoryProvider)
        .addLotToUser(
          userId: widget.uid,
          lotId: lot!.id!,
          residenceId: _residence!.id,
          intendedFor: _intendedFor,
          statutResident: _typeResident,
        )
        .then((result) => result.when(
            success: (_) {}, failure: (error) => throw error));

    // Le lot part avec isApprovedLot: false (addLotToUser) : l'inscription
    // dans idProprietaire/idLocataire côté résidence (ce qui donne l'accès
    // réel) n'est plus faite ici. Elle est déclenchée côté serveur
    // (sync_lot_approval, functions_python/main.py) uniquement quand
    // isApprovedLot passe à true - validation manuelle (Console pour
    // l'instant, futur backoffice gérance/syndic/admin) - et seulement si
    // le compte est déjà isApproved.
    final docsRepository = ref.read(docsRepositoryProvider);

    if (docTypeJustif.isNotEmpty && justifPath.isNotEmpty) {
      await docsRepository.setDocument(
        DocumentModel(
          type: docTypeJustif,
          extension: justifExtension,
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
          extension: _kbisExtension,
          residenceId: _residence!.id,
          timeStamp: Timestamp.now(),
          documentPathRecto: _kbisPath,
          lotId: lot.refLot,
        ),
        widget.uid,
        lot.id,
      );
    }

    // Le lot part avec isApprovedLot: false (cf. addLotToUser) : pas de
    // remise à false du compte ni de déconnexion forcée, seul ce nouveau
    // lot reste bloqué tant qu'une personne n'a pas revérifié les documents.
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        content: MyTextStyle.lotDesc(
          "Votre demande a été transmise à notre équipe. Ce lot sera "
          "accessible une fois les documents vérifiés.", SizeFont.h2.size,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (mounted) Navigator.of(context).pop(true);
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
                title: MyTextStyle.lotName("Vous ne trouvez pas votre résidence ?",
                    Colors.black87, SizeFont.h2.size),
                content: MyTextStyle.annonceDesc(
                    "Contactez notre support, votre résidence n'a peut-être "
                    "pas encore été créée dans l'application.",
                    SizeFont.h3.size,
                    3),
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
          ? const Center(child: AppLoader())
          : PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Step1(
                  currentPage: 0,
                  progressController: _pageController,
                  recupererInformationsStep1: _onResidenceFound,
                  onNoResidence: () {},
                  showNoResidenceOption: false,
                ),
                if (_residence != null)
                  Step2(
                    currentPage: 1,
                    progressController: _pageController,
                    onCameraStateChanged: (_) {},
                    recupererInformationsStep2: _onRoleDefined,
                    userId: widget.uid,
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
  final Future<void> Function(
      String docTypeJustif, String justifPath, String justifExtension) onSubmit;

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
  String justifExtension = "";
  bool visibleJustif = false;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final items = widget.typeResident == "Locataire"
        ? TypeList.justifTypeLocs
        : TypeList.justifTypeProps;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MyTextStyle.lotName(
                  "Fournissez un justificatif de domicile pour ce lot",
                  Colors.black54,
                  null,
                  null,
                  null,
                  null,
                  TextAlign.center),
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
                  onExtensionResolved: (ext) =>
                      setState(() => justifExtension = ext),
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
            ButtonAdd(
              color: Theme.of(context).primaryColor.withValues(
                  alpha:
                      (visibleJustif && imagePathJustif.isNotEmpty) ? 1.0 : 0.5),
              text: "Soumettre",
              horizontal: 20,
              vertical: 5,
              size: SizeFont.h2.size,
              function: (visibleJustif && imagePathJustif.isNotEmpty)
                  ? () => widget.onSubmit(
                      justifChoice, imagePathJustif, justifExtension)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
