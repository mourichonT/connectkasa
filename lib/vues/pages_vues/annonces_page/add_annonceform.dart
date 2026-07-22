import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/submit_post_controller.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/custom_textfield_widget.dart';
import 'package:konodal/vues/widget_view/components/my_dropdown_menu.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:konodal/vues/widget_view/components/camera_files_choices.dart';
import 'package:konodal/vues/widget_view/components/thumbnail_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class AddAnnonceForm extends StatefulWidget {
  final String residence;
  final String uid;

  const AddAnnonceForm({super.key, required this.residence, required this.uid});

  @override
  State<StatefulWidget> createState() => AddAnnonceFormState();
}

class AddAnnonceFormState extends State<AddAnnonceForm> {
  final TypeList _catList = TypeList();

  late TextEditingController textEditingController;
  TextEditingController title = TextEditingController();
  TextEditingController desc = TextEditingController();
  TextEditingController price = TextEditingController();
  String? categorie;
  String imagePath = "";
  bool anonymPost = false;
  bool showAllFilters = false;
  bool removeImage = false;
  bool _isUploadingImage = false;
  bool _isSubmitting = false;
  late List<String> labelsCat;
  String idPost = const Uuid().v1();
  List<String> thumbnails = [];

  @override
  void initState() {
    super.initState();
    List<String> declarationType = _catList.categoryAnnonce();
    labelsCat = declarationType.asMap().entries.map((entry) {
      return entry.value;
    }).toList();
  }

  void updateBool(bool updatedBool) {
    setState(() {
      anonymPost = updatedBool;
    });
  }

  void downloadImagePath(String downloadUrl) {
    setState(() {
      imagePath = downloadUrl;
      _isUploadingImage = false;
    });
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
            "Nouvelle Annonce", Colors.black87, SizeFont.h1.size),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      profilTile(widget.uid, 22, 19, 22, true, Colors.black87,
                          SizeFont.h2.size),
                    ],
                  ),
                  const SizedBox(height: 15),

                  /// **Catégorie**
                  MyDropDownMenu(
                    width,
                    "Catégorie",
                    "Choisir une catégorie",
                    false,
                    items: labelsCat,
                    onValueChanged: (String value) {
                      setState(() => categorie = value);
                    },
                  ),

                  /// **Photo principale**
                  Center(
                    child: CameraOrFiles(
                        racineFolder: "residences",
                        residence: widget.residence,
                        folderName: "annonces",
                        fileName: idPost,
                        title: title.text,
                        onImageUploaded: downloadImagePath,
                        onUploadStart: () =>
                            setState(() => _isUploadingImage = true),
                        onUploadError: () =>
                            setState(() => _isUploadingImage = false),
                        cardOverlay: false),
                  ),
                  if (_isUploadingImage)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        "Envoi de l'image en cours...",
                        style: TextStyle(
                            color: Colors.black54, fontStyle: FontStyle.italic),
                      ),
                    ),

                  /// **Titre**
                  CustomTextFieldWidget(
                    label: "Titre",
                    text: "Saisissez le titre de votre post",
                    controller: title,
                    isEditable: true,
                    minLines: 1,
                    maxLines: 1,
                  ),

                  /// **Description**
                  CustomTextFieldWidget(
                    label: "Description",
                    text: "Saisissez une description",
                    controller: desc,
                    isEditable: true,
                    minLines: 4,
                    maxLines: 4,
                  ),

                  /// **Prix**
                  CustomTextFieldWidget(
                    label: "Prix",
                    text: "0",
                    controller: price,
                    isEditable: true,
                    minLines: 1,
                    maxLines: 1,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    suffixText: "€",
                  ),

                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MyTextStyle.lotName("Photos supplémentaires (max 3) :",
                        Colors.black87, SizeFont.h3.size),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ThumbnailPicker(
                      initialThumbnails: thumbnails,
                      residence: widget.residence,
                      folderName: "annonces/$idPost",
                      onChanged: (updated) => thumbnails = updated,
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// **Bouton Ajouter**
                  Center(
                    child: ButtonAdd(
                      color: Theme.of(context).primaryColor,
                      text: "Ajouter",
                      horizontal: 20,
                      vertical: 5,
                      size: SizeFont.h2.size,
                      function: (_isUploadingImage || _isSubmitting)
                          ? null
                          : () async {
                        setState(() => _isSubmitting = true);
                        try {
                          await SubmitPostController.submitForm(
                              uid: widget.uid,
                              idPost: idPost,
                              selectedLabel: "annonces",
                              imagePath: imagePath,
                              subtype: categorie,
                              price: int.tryParse(price.text) ?? 0,
                              title: title,
                              desc: desc,
                              anonymPost: anonymPost,
                              docRes: widget.residence,
                              thumbnails: thumbnails);
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() => _isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                  "Erreur lors de l'ajout de l'annonce : $e"),
                            ),
                          );
                          return;
                        }
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
