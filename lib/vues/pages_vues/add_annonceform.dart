import 'dart:io';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_post_controller.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:connect_kasa/vues/widget_view/camera_files_choices.dart';
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
  final StorageServices _storageServices = StorageServices();
  File? _selectedImage;
  final TypeList _CatList = TypeList();

  late TextEditingController textEditingController;
  TextEditingController title = TextEditingController();
  TextEditingController desc = TextEditingController();
  TextEditingController price = TextEditingController();
  String? categorie;
  String imagePath = "";
  bool anonymPost = false;
  bool showAllFilters = false;
  bool removeImage = false;
  late List<String> labelsCat;
  String idPost = const Uuid().v1();

  @override
  void initState() {
    super.initState();
    List<String> declarationType = _CatList.categoryAnnonce();
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
                      ProfilTile(widget.uid, 22, 19, 22, true, Colors.black87,
                          SizeFont.h2.size),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          child: DropdownButtonFormField<String>(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
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
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
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
                              Container(
                                child: Row(
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 10),
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
                                          enabledBorder: const OutlineInputBorder(
                                            borderSide:
                                                BorderSide(color: Colors.grey),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 10),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 20),
                                      child: MyTextStyle.lotDesc(
                                          price.text.isNotEmpty
                                              ? "Kasas"
                                              : "Kasa",
                                          SizeFont.h3.size,
                                          FontStyle.normal,
                                          FontWeight.bold),
                                    ),
                                  ],
                                ),
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
                      title: title.text,
                      onImageUploaded: downloadImagePath,
                      cardOverlay: false),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      SubmitPostController.submitForm(
                          uid: widget.uid,
                          idPost: idPost,
                          selectedLabel: "annonces",
                          imagePath: imagePath,
                          subtype: categorie,
                          price: int.parse(price.text),
                          title: title,
                          desc: desc,
                          anonymPost: anonymPost,
                          docRes: widget.residence);
                      Navigator.pop(context);
                    },
                    child: MyTextStyle.lotName("Ajouter",
                        Theme.of(context).primaryColor, SizeFont.h3.size),
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
