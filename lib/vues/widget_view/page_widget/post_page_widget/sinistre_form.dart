import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/submit_post_controller.dart';
import 'package:konodal/core/repositories/residence_repository.dart';
import 'package:konodal/core/utils/media_type.dart';
import 'package:konodal/core/repositories/firestore_residence_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/lot.dart';
import 'package:konodal/models/pages_models/structure_residence.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/camera_files_choices.dart';
import 'package:konodal/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:konodal/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:flutter/material.dart';

class SinistreForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SinistreFormState();
  final Lot? preferedLot;
  final String racineFolder;
  final String uid;
  final String idPost;
  final Function(String) updateUrl; // Fonction pour mettre à jour imagePath
  final String folderName;

  const SinistreForm({
    super.key,
    required this.racineFolder,
    required this.preferedLot,
    required this.uid,
    required this.idPost,
    required this.updateUrl,
    required this.folderName,
  });
}

class SinistreFormState extends State<SinistreForm> {
  late TextEditingController title;
  late TextEditingController desc;
  final IResidenceRepository _resServices = FirestoreResidenceRepository();
  List<Map<String, String>> itemsLocalisation = [];
  List<String> itemsEtage = [];
  List<String> itemsElements = [];
  String? localisationId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    title = TextEditingController();
    desc = TextEditingController();
    _loadLocalisations();
  }

  Future<void> _loadLocalisations() async {
    if (widget.preferedLot != null) {
      final locs = await _resServices
          .getAllLocalisation(widget.preferedLot!.residenceId)
          .then((result) =>
              result.when(success: (v) => v, failure: (_) => <Map<String, String>>[]));
      setState(() {
        itemsLocalisation = locs;
      });
    }
  }

  Future<void> _getLocDetails() async {
    if (widget.preferedLot != null && localisationId != null) {
      final StructureResidence? loc = await _resServices
          .getDetailLocalisation(
              widget.preferedLot!.residenceId, localisationId!)
          .then((result) =>
              result.when(success: (v) => v, failure: (_) => null));

      if (loc != null) {
        setState(() {
          itemsEtage = loc.etage ?? [];
          itemsElements = loc.elements ?? []; // ou ce que tu veux faire avec
        });
      }
    }
  }

  String localisation = "";
  String etage = "";
  String imagePath = "";
  bool isVideoMedia = false;
  bool anonymPost = false;
  List<String> filters = [];

  void updateItem(String updatedElement) {
    setState(() {});
  }

  void updateBool(bool updatedBool) {
    setState(() {
      anonymPost = updatedBool;
    });
  }

  void downloadImagePath(String downloadUrl) {
    setState(() {
      widget.updateUrl(downloadUrl);
      imagePath = downloadUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        const SizedBox(height: 15),

        /// **Localisation**
        MyDropDownMenu(
          width,
          "Localisation",
          "Choisir une localisation",
          false,
          preferedLot: widget.preferedLot!,
          items: itemsLocalisation.map((e) => e['label']!).toList(),
          onValueChanged: (String value) async {
            final selected =
                itemsLocalisation.firstWhere((e) => e['label'] == value);
            final selectedId = selected['id'];

            setState(() {
              localisation = value;
              localisationId = selectedId;
              updateItem(localisation);
              itemsEtage =
                  []; // vider temporairement pendant le chargement si besoin
            });

            await _getLocDetails(); // Récupère les étages dynamiquement ici
          },
        ),
        const SizedBox(height: 15),

        ///  **Étage**
        Visibility(
          visible: localisationId != null,
          child: Column(
            children: [
              MyDropDownMenu(
                width,
                "Etage",
                "Choisir un étage",
                false,
                preferedLot: widget.preferedLot!,
                items: itemsEtage,
                onValueChanged: (String value) {
                  setState(() {
                    etage = value;
                    updateItem(etage);
                  });
                },
              ),

              ///  **Sélection d'éléments**
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: MyTextStyle.lotName(
                    "Apportez des précisions pour localiser le sinistre:",
                    Colors.black87,
                    SizeFont.h3.size),
              ),
              Center(
                child: Wrap(
                  spacing: 5.0,
                  children: itemsElements.map((String itemsElement) {
                    return FilterChip(
                      label:
                          MyTextStyle.lotDesc(itemsElement, SizeFont.h3.size),
                      selected: filters.contains(itemsElement),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            filters.add(itemsElement);
                          } else {
                            filters.remove(itemsElement);
                          }
                        });
                      },
                      backgroundColor: Color(
                          0xFFF5F6F9), // couleur de fond quand non sélectionné
                      selectedColor: Theme.of(context)
                          .primaryColor, // couleur quand sélectionné
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20), // angle arrondi
                      ),
                      side: BorderSide(
                        color: filters.contains(itemsElement)
                            ? Theme.of(context).primaryColor
                            : Color(0xFFF5F6F9), // couleur de la bordure
                        width: 2, // épaisseur de la bordure
                      ),
                    );
                  }).toList(),
                ),
              ),

              /// 📸 **Ajout de photo**
              Center(
                child: CameraOrFiles(
                  residence: widget.preferedLot!.residenceId,
                  racineFolder: widget.racineFolder,
                  folderName: widget.folderName,
                  title: title.text,
                  onImageUploaded: downloadImagePath,
                  allowVideo: true,
                  onExtensionResolved: (ext) =>
                      setState(() => isVideoMedia = isVideoExtension(ext)),
                  cardOverlay: false,
                ),
              ),

              ///  **Titre (Remplacé par CustomTextFieldWidget)**
              CustomTextFieldWidget(
                label: "Titre",
                text: "Définissez un titre pour votre post",
                controller: title,
                isEditable: true,
                minLines: 1,
                maxLines: 1,
              ),

              ///  **Description (Remplacé par CustomTextFieldWidget)**
              CustomTextFieldWidget(
                  label: "Description",
                  controller: desc,
                  isEditable: true,
                  minLines: 6,
                  maxLines: 6,
                  text: "Donnez des précisions sur la déclaration"),

              /// 🔄 **Anonymat**
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyTextStyle.lotDesc(
                        "Publier anonymement?  ", SizeFont.h3.size),
                    Switch(
                      value: anonymPost,
                      onChanged: (bool value) {
                        setState(() {
                          anonymPost = value;
                          updateBool(anonymPost);
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              /// **Bouton Soumettre**
              Center(
                child: ButtonAdd(
                  color: Theme.of(context).primaryColor,
                  text: "Soumettre",
                  horizontal: 20,
                  vertical: 5,
                  size: SizeFont.h2.size,
                  function: _isSubmitting
                      ? null
                      : () async {
                          if (localisation.isEmpty ||
                              etage.isEmpty ||
                              title.text.isEmpty ||
                              desc.text.isEmpty ||
                              imagePath.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(
                                  'Tous les champs sont requis!',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => _isSubmitting = true);
                          try {
                            await SubmitPostController.addPostAfterChecking(
                              uid: widget.uid,
                              docRes: widget.preferedLot!.residenceId,
                              idPost: widget.idPost,
                              selectedLabel: widget.folderName,
                              imagePath: imagePath,
                              isVideo: isVideoMedia,
                              title: title,
                              desc: desc,
                              anonymPost: anonymPost,
                              localisation: localisation,
                              etage: etage,
                              element: filters,
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            setState(() => _isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text("Erreur lors de l'envoi : $e"),
                              ),
                            );
                            return;
                          }

                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 50),
      ],
    );
  }
}
