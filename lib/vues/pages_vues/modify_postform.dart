import 'dart:io';
import 'dart:math';

import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_post_controller.dart';
import 'package:connect_kasa/controllers/services/databases_residence_services.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/models/pages_models/residence.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ModifyPostForm extends StatefulWidget {
  final Post post;
  final String residence;
  final String uid;

  const ModifyPostForm(
      {super.key,
      required this.post,
      required this.residence,
      required this.uid});

  @override
  State<StatefulWidget> createState() => ModifyPostFormState();
}

class ModifyPostFormState extends State<ModifyPostForm> {
  double fontSize = SizeFont.para.size;
  final StorageServices _storageServices = StorageServices();
  File? _selectedImage;
  final TypeList _typeList = TypeList();
  final DataBasesResidenceServices residenceServices =
      DataBasesResidenceServices();
  late Future<Residence> getResidence;
  late TextEditingController textEditingController;
  late List<String> locationElements = [];
  late List<String> locationsFloor = [];
  late List<String> locationDetails = [];
  String? localisation;
  String? etage;
  String? type;
  TextEditingController title = TextEditingController();
  TextEditingController desc = TextEditingController();
  String imagePath = "";
  bool anonymPost = false;
  bool showAllFilters = false;
  bool removeImage = false;
  late List<String> labelsType;

  @override
  void initState() {
    super.initState();
    List<List<String>> declarationType = _typeList.typeDeclaration();
    labelsType = declarationType.asMap().entries.map((entry) {
      return entry.value[1];
    }).toList();
    labelsType = labelsType.toSet().toList();
    textEditingController = TextEditingController();
    getResidence =
        residenceServices.getResidenceByRef(widget.post.refResidence);
    getResidence.then((residence) {
      setState(() {
        locationElements = residence.localisation!;
        locationsFloor = residence.etage!;
        locationDetails = residence.elements!;
      });

      // Ensure initial values are valid
      if (!labelsType.contains(widget.post.type)) {
        type = null;
      } else {
        type = widget.post.type;
      }

      if (!locationElements.contains(widget.post.location_element)) {
        localisation = null;
      } else {
        localisation = widget.post.location_element;
      }

      if (!locationsFloor.contains(widget.post.location_floor)) {
        etage = null;
      } else {
        etage = widget.post.location_floor;
      }
    });

    title = TextEditingController(text: widget.post.title);
    desc = TextEditingController(text: widget.post.description);
    imagePath = widget.post.pathImage ?? "";
    anonymPost = widget.post.hideUser;
  }

  void updateBool(bool updatedBool) {
    setState(() {
      anonymPost = updatedBool;
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
            "Modification du post", Colors.black87, SizeFont.h1.size),
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
                      ProfilTile(widget.post.user, 22, 19, 22, true,
                          Colors.black87, SizeFont.h2.size),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          MyTextStyle.annonceDesc(
                              "Rendre anonyme  ", SizeFont.h3.size, 1),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              thumbIcon: thumbIcon,
                              value: anonymPost,
                              onChanged: (bool value) {
                                setState(() {
                                  anonymPost = value;
                                  updateBool(anonymPost);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
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
                            value: type,
                            onChanged: (String? newValue) {
                              setState(() {
                                type = newValue;
                              });
                            },
                            items: labelsType
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
                                })
                                .take(2)
                                .toList(),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          //padding: EdgeInsets.symmetric(horizontal: 1),
                          child: DropdownButtonFormField<String>(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.only(
                                  left: 5, top: 5, bottom: 5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            value: localisation,
                            onChanged: (String? newValue) {
                              setState(() {
                                localisation = newValue;
                              });
                            },
                            items: locationElements
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
                        Expanded(
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
                            value: etage,
                            onChanged: (String? newValue) {
                              setState(() {
                                etage = newValue;
                              });
                            },
                            items: locationsFloor
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
                      ],
                    ),
                  ),
                  if (showAllFilters)
                    Wrap(
                      spacing: 5.0,
                      children: (showAllFilters
                              ? locationDetails
                              : locationDetails.take(3))
                          .map((String itemsElement) {
                        return FilterChip(
                          label: Text(itemsElement),
                          selected: widget.post.location_details!
                              .contains(itemsElement),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                widget.post.location_details!.add(itemsElement);
                              } else {
                                widget.post.location_details!
                                    .remove(itemsElement);
                              }
                            });
                          },
                        );
                      }).toList(),
                    )
                  else
                    Wrap(
                      spacing: 5.0,
                      children: widget.post.location_details!
                          .map((String itemsElement) {
                        return FilterChip(
                          label: Text(itemsElement),
                          selected: widget.post.location_details!
                              .contains(itemsElement),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                widget.post.location_details!.add(itemsElement);
                              } else {
                                widget.post.location_details!
                                    .remove(itemsElement);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        showAllFilters =
                            !showAllFilters; // Inversez l'état pour afficher/masquer tous les filtres
                      });
                    },
                    child: Text(showAllFilters
                        ? "Réduire"
                        : "Voir plus"), // Texte dynamique en fonction de l'état
                  ),
                  const Divider(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyTextStyle.lotName(
                          "Titre : ", Colors.black87, SizeFont.h3.size),
                      const SizedBox(
                        height: 15,
                      ),
                      TextField(
                        controller: title,
                        maxLines: 1,
                        decoration: const InputDecoration.collapsed(
                            hintText: "Saisissez le titre de votre post"),
                      ),
                    ],
                  ),
                  const Divider(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyTextStyle.lotName(
                          "Description : ", Colors.black87, SizeFont.h3.size),
                      const SizedBox(
                        height: 15,
                      ),
                      TextField(
                        controller: desc,
                        maxLines: 4,
                        decoration: const InputDecoration.collapsed(
                            hintText: "Saisissez une description"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            !removeImage
                ? Stack(
                    children: [
                      SizedBox(
                        width: width,
                        height: 250,
                        child: Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              removeImage = !removeImage;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        ElevatedButton(
                            onPressed: () {
                              _pickImageFromCamera();
                            },
                            child: MyTextStyle.lotName("Prendre une photo",
                                Colors.black54, SizeFont.h3.size)),
                        TextButton(
                            onPressed: () {
                              _pickImageFromGallery();
                            },
                            child: MyTextStyle.annonceDesc(
                                "Choisir une image", SizeFont.h3.size, 3)),
                      ]),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: () {
                SubmitPostController.UpdatePost(
                  like: widget.post.like,
                  uid: widget.uid,
                  idPost: widget.post.id,
                  selectedLabel: type!,
                  imagePath: imagePath,
                  title: title,
                  desc: desc,
                  anonymPost: anonymPost,
                  docRes: widget.post.refResidence,
                  localisation: localisation,
                  etage: etage,
                  element: widget.post.location_details!,
                );
                Navigator.pop(context);
              },
              child: MyTextStyle.lotName(
                  "Modifier", Theme.of(context).primaryColor, SizeFont.h3.size),
            ),
            const SizedBox(
              height: 15,
            ),
          ],
        ),
      ),
    );
  }

  Future _pickImageFromGallery() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    // Votre code pour traiter l'image sélectionnée
    if (returnedImage == null) return;
    setState(() {
      removeImage = !removeImage;
      String fileName = "${widget.post.id}-${Random().nextInt(10000)}";

      _selectedImage = File(returnedImage.path);
      _storageServices
          .uploadFile(returnedImage, "residences", widget.residence,
              widget.post.type, fileName)
          .then((downloadUrl) {
        if (downloadUrl != null) {
          updateUrl(downloadUrl);
        }
      });
    });
  }

  Future _pickImageFromCamera() async {
    String fileName = "${widget.post.id}-${Random().nextInt(10000)}";
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    // Votre code pour traiter l'image sélectionnée
    if (returnedImage == null) return;
    setState(() {
      removeImage = !removeImage;
      _selectedImage = File(returnedImage.path);
      _storageServices
          .uploadFile(returnedImage, "residences", widget.residence,
              widget.post.type, fileName)
          .then((downloadUrl) {
        if (downloadUrl != null) {
          updateUrl(downloadUrl);
        }
      });
    });
  }

  void updateUrl(String newImagePath) {
    setState(() {
      // oldImagePath = imagePath;
      imagePath = newImagePath;

      _storageServices.removeFileFromUrl(widget.post.pathImage!);
      //oldImagePath = "";
    });
  }
}
