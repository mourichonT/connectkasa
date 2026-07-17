import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/providers/lot_repository_provider.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/residence.dart';
import 'package:konodal/vues/widget_view/components/camera_files_choices.dart';
import 'package:konodal/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:konodal/vues/widget_view/page_widget/have_not_account_widget/child_lot_picker_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konodal/models/enum/statut_list.dart';

class Step2 extends ConsumerStatefulWidget {
  final Function(String, bool, String, String, String, List<String>)
      recupererInformationsStep2;
  final int currentPage;
  final PageController progressController;
  final Function(bool) onCameraStateChanged;
  final String userId;
  // ID du document Firestore du lot déjà sélectionné (Step3 s'exécute
  // désormais avant Step2) : permet de ranger le Kbis dans son sous-dossier
  // de lot dans Storage.
  final String? lotId;
  // Résidence du lot principal - utilisée pour proposer les lots enfants
  // (parking/cave...) de la même résidence à rattacher.
  final Residence residence;

  const Step2({
    super.key,
    required this.recupererInformationsStep2,
    required this.currentPage,
    required this.progressController,
    required this.onCameraStateChanged,
    required this.userId,
    required this.residence,
    this.lotId,
  });

  @override
  ConsumerState<Step2> createState() => _Step2State();
}

class _Step2State extends ConsumerState<Step2> {
  bool compagnyBuy = false;
  bool visible = false;
  String typeResident = "";
  String? intendedFor = "";
  String? pathKbis = "";
  String kbisExtension = "";
  Lot? _principalLot;
  final List<Lot> _pendingChildLots = [];

  @override
  void initState() {
    super.initState();
    if (widget.lotId != null && widget.lotId!.isNotEmpty) {
      ref
          .read(lotRepositoryProvider)
          .getLotById(widget.residence.id, widget.lotId!)
          .then((result) => result.when(
                success: (lot) {
                  if (mounted) setState(() => _principalLot = lot);
                },
                failure: (_) {},
              ));
    }
  }

  Future<void> _addChildLot() async {
    final candidate = await showChildLotPicker(context, widget.residence);
    if (candidate == null) return;
    // showChildLotPicker ouvre un bottom sheet : le widget peut avoir été
    // démonté pendant ce temps (navigation, retour en arrière) - couvre
    // aussi bien la branche "conflit" ci-dessous que le setState final.
    if (!mounted) return;

    final mainIds = <String>{...?_principalLot?.idLocataire};
    final childIds = <String>{...?candidate.idLocataire};
    final conflict =
        mainIds.isNotEmpty && childIds.isNotEmpty && !setEquals(mainIds, childIds);

    if (conflict) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "Un locataire différent est présent, les lots ne peuvent être "
          "rattachés. Ajoutez votre lot principal, puis une fois connecté "
          "ajoutez un lot supplémentaire depuis votre espace "
          "'Gestion des biens'.",
        ),
      ));
      return;
    }

    if (_pendingChildLots.any((l) => l.id == candidate.id)) return;
    setState(() => _pendingChildLots.add(candidate));
  }

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
                        residence: widget.userId,
                        folderName: 'compagnyDoc',
                        lotId: widget.lotId,
                        title: pathKbis ?? "",
                        onImageUploaded: (downloadUrl) {
                          setState(() {
                            pathKbis = downloadUrl;
                          });
                        },
                        onExtensionResolved: (ext) =>
                            setState(() => kbisExtension = ext),
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
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: MyTextStyle.lotName(
                          "Un lot (parking, cave, garage) est rattaché à ce bien ?",
                          Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    for (final childLot in _pendingChildLots)
                      ListTile(
                        dense: true,
                        title: Text(
                            "${childLot.typeLot} - ${childLot.batiment ?? ''} ${childLot.lot ?? ''}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(
                              () => _pendingChildLots.remove(childLot)),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: _addChildLot,
                      icon: const Icon(Icons.add),
                      label: const Text("Ajouter un lot"),
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
                    kbisExtension,
                    _pendingChildLots.map((l) => l.id!).toList(),
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
