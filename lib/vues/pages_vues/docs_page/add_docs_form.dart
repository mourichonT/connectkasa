import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_doc_controller.dart';
import 'package:connect_kasa/controllers/services/databases_user_services.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/lot.dart';
import 'package:connect_kasa/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:connect_kasa/vues/widget_view/components/my_dropdown_menu_cb.dart';
import 'package:connect_kasa/vues/widget_view/components/profil_tile.dart';
import 'package:connect_kasa/vues/widget_view/components/import_docs.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AddDocsForm extends StatefulWidget {
  final Lot lotSelected;
  final String uid;
  final bool isDocCopro;

  AddDocsForm(
      {super.key,
      required this.uid,
      required this.lotSelected,
      required this.isDocCopro});

  @override
  State<StatefulWidget> createState() => AddDocsFormState();
}

class AddDocsFormState extends State<AddDocsForm> {
  double fontSize = 12;
  final TypeList _CatList = TypeList();

  late TextEditingController textEditingController;
  TextEditingController docName = TextEditingController();
  String imagePath = "";
  String fileExtension = "";
  String type = "";
  String desti = "";
  bool removeImage = false;
  bool isSelected = true;
  List<String> destinatairesLabels = []; // Pour le dropdown
  Map<String, List<String>> destinatairesMap = {}; // label → liste des UID
  List<String> destinatairesReal = []; // les uids du destinataire sélectionné

  String idPost = const Uuid().v1();

  @override
  void initState() {
    super.initState();
    fetchDestinataires();
    docName.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (imagePath.isNotEmpty) {
      // Si un fichier a été téléchargé et que l'on quitte la page sans soumettre, on le supprime
      _removeDocument(imagePath);
    }
    super.dispose();
  }

  Future<void> _removeDocument(String downloadUrl) async {
    try {
      if (!widget.isDocCopro) {
        // Supposons que tu utilises le service de stockage Firebase pour supprimer le fichier
        await StorageServices().removeFile(
          "user", // Remplace par le bon dossier/racine si nécessaire
          widget.uid, // L'ID utilisateur ou autre identifiant nécessaire
          "documentsLot", // Le dossier dans lequel le fichier a été téléchargé
          idPost: "$idPost.$fileExtension", // Le nom du fichier avec extension
        );
        print("Fichier supprimé avec succès : $downloadUrl");
      } else {
        // Supposons que tu utilises le service de stockage Firebase pour supprimer le fichier
        await StorageServices().removeFile(
          "residences",
          widget.lotSelected.residenceId, // on passe une liste avec un seul nom
          "documents_copro",
          idPost: "$idPost.$fileExtension", // Le nom du fichier avec extension
        );
        print("Fichier supprimé avec succès : $downloadUrl");
      }
    } catch (e) {
      print("Erreur lors de la suppression du fichier : $e");
    }
  }

  bool isFormValid() {
    final valid = docName.text.isNotEmpty &&
        type.isNotEmpty &&
        imagePath.isNotEmpty &&
        destinatairesReal.isNotEmpty;

    if (widget.isDocCopro) {
      print(
          "VALID ? $valid - docName: ${docName.text}, type: $type, imagePath: $imagePath, dests: $destinatairesReal");
      // Pour les documents de copro : pas de destinataires
      return docName.text.isNotEmpty && type.isNotEmpty && imagePath.isNotEmpty;
    } else {
      // Pour les documents individuels : destinataires requis
      return docName.text.isNotEmpty &&
          type.isNotEmpty &&
          imagePath.isNotEmpty &&
          destinatairesReal.isNotEmpty;
    }
  }

  Future<void> fetchDestinataires() async {
    destinatairesLabels.add("Moi-même");
    destinatairesMap["Moi-même"] = [widget.uid];

    final locataires = widget.lotSelected.idLocataire;

    if (locataires != null && locataires.isNotEmpty) {
      for (String locataireId in locataires) {
        try {
          final user = await DataBasesUserServices.getUserById(locataireId);
          if (user != null) {
            final fullName = "${user.name} ${user.surname}".trim();
            destinatairesLabels.add(fullName);
            destinatairesMap[fullName] = [locataireId];
            destinatairesReal.add(locataireId);
          }
        } catch (e) {
          print(
              "Erreur lors de la récupération du locataire $locataireId : $e");
        }
      }
    }

    setState(() {
      isSelected = false;
    });
  }

  void downloadImagePath(String downloadUrl, String extension) {
    setState(() {
      imagePath = downloadUrl;
      fileExtension = extension;
    });
  }

  void updateItem(String updatedElement) {
    setState(() {});
  }

  final WidgetStateProperty<Icon?> thumbIcon =
      WidgetStateProperty.resolveWith<Icon?>(
    (Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return const Icon(Icons.check);
      }
      return const Icon(Icons.close);
    },
  );

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: MyTextStyle.lotName(
            "Ajouter un document", Colors.black87, SizeFont.h1.size),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // Espace pour bouton
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ProfilTile(
                    widget.uid,
                    22,
                    19,
                    22,
                    true,
                    Colors.black87,
                    SizeFont.h2.size,
                  ),
                ],
              ),
              Visibility(
                visible: !widget.isDocCopro,
                child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: MyMultiSelectDropdownInline(
                      width: width,
                      items: destinatairesLabels,
                      selectedItems: [],
                      onSelectionChanged: (selectedLabels) {
                        setState(() {
                          destinatairesReal = selectedLabels
                              .expand((label) => destinatairesMap[label] ?? [])
                              .cast<String>()
                              .toSet()
                              .toList();
                        });
                        isSelected = destinatairesReal.isNotEmpty;
                      },
                    )),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: CustomTextFieldWidget(
                  label: "Nom du document",
                  text: "Quel est le nom de votre document",
                  controller: docName,
                  isEditable: true,
                  minLines: 1,
                  maxLines: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: MyDropDownMenu(
                  width,
                  "Catégorie",
                  "Quelle est la catégorie de votre document",
                  false,
                  preferedLot: widget.lotSelected,
                  items: _CatList.categoryDocs(),
                  onValueChanged: (String value) {
                    setState(() {
                      type = value;
                      updateItem(type);
                    });
                  },
                ),
              ),
              widget.isDocCopro
                  ? ImportDocs(
                      racineFolder: "residences",
                      filename: [widget.lotSelected.residenceId],
                      folderName: "documents_copro",
                      title: docName.text,
                      onDocumentUploaded: downloadImagePath,
                    )
                  : Visibility(
                      visible: isSelected,
                      child: ImportDocs(
                        racineFolder: "user",
                        filename: destinatairesReal,
                        folderName: "documentsLot",
                        title: docName.text,
                        onDocumentUploaded: downloadImagePath,
                        reflot:
                            "${widget.lotSelected.residenceData['id']}-${widget.lotSelected.refLot}",
                      ),
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: ElevatedButton(
          onPressed: isFormValid() ? _handleSubmit : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: MyTextStyle.lotName(
            "Ajouter",
            Colors.white,
            SizeFont.h3.size,
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (widget.isDocCopro) {
      SubmitDocController.submitFormCopro(
        residenceId: widget.lotSelected.residenceId,
        docExtension: fileExtension,
        docName: docName.text,
        category: type,
        docPath: imagePath,
      );
    } else {
      SubmitDocController.submitFormIndividuel(
        residenceId: widget.lotSelected.residenceId,
        docExtension: fileExtension,
        docName: docName.text,
        category: type,
        docPath: imagePath,
        uid: destinatairesReal,
        refLot:
            "${widget.lotSelected.residenceData['id']}-${widget.lotSelected.refLot}",
      );
    }

    Navigator.pop(context);
  }
}
