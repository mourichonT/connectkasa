import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/submit_post_controller.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:konodal/vues/widget_view/components/camera_files_choices.dart';
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
  double fontSize = 12;
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
                  Padding(
                    padding: const EdgeInsets.only(top: 40, bottom: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        DropdownButtonFormField<String>(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            value: categorie,
                            onChanged: (String? newValue) {
                              setState(() {
                                categorie = newValue;
                              });
                            },
                            items: labelsCat
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 50),
                          child: Row(
                            children: [
                              MyTextStyle.lotName(
                                  "Titre : ", Colors.black87, SizeFont.h3.size),
                              const SizedBox(width: 15),
                              Expanded(
                                child: TextField(
                                  controller: title,
                                  maxLines: 1,
                                  decoration: InputDecoration.collapsed(
                                      hintText:
                                          "Saisissez le titre de votre post",
                                      hintStyle: TextStyle(
                                          fontSize: SizeFont.h3.size,
                                          fontStyle: FontStyle.italic)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyTextStyle.lotName("Description : ",
                                  Colors.black87, SizeFont.h3.size),
                              const SizedBox(width: 15),
                              Expanded(
                                child: TextField(
                                  controller: desc,
                                  maxLines: 4,
                                  decoration: InputDecoration.collapsed(
                                      hintText: "Saisissez une description",
                                      hintStyle: TextStyle(
                                          fontSize: SizeFont.h3.size,
                                          fontStyle: FontStyle.italic)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              MyTextStyle.lotName(
                                  "Prix : ", Colors.black87, SizeFont.h3.size),
                              const SizedBox(width: 15),
                              Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      width: width / 3,
                                      height: 40,
                                      child: TextField(
                                        controller: price,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        textAlign: TextAlign.right,
                                        decoration: InputDecoration(
                                          hintText: "0",
                                          border:
                                              const OutlineInputBorder(), // Adds a border to the TextField
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Theme.of(context)
                                                    .primaryColor),
                                          ),
                                          enabledBorder:
                                              const OutlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.grey),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 5, horizontal: 10),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: MyTextStyle.lotDesc(
                                          "€",
                                          SizeFont.header.size,
                                          FontStyle.normal,
                                          FontWeight.bold),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                  CameraOrFiles(
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
                  if (_isUploadingImage)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        "Envoi de l'image en cours...",
                        style: TextStyle(
                            color: Colors.black54, fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 30),
                  ButtonAdd(
                    color: Theme.of(context).primaryColor,
                    text: "Ajouter",
                    horizontal: 20,
                    vertical: 5,
                    size: SizeFont.h3.size,
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
                            docRes: widget.residence);
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
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
