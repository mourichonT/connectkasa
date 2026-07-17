import 'dart:math';

import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/submit_post_controller.dart';
import 'package:konodal/core/repositories/residence_repository.dart';
import 'package:konodal/core/repositories/firestore_residence_repository.dart';
import 'package:konodal/core/repositories/firestore_storage_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/models/pages_models/residence.dart';
import 'package:konodal/vues/widget_view/components/network_video_player.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:konodal/core/utils/app_logger.dart';
import 'package:konodal/core/utils/text_formatting.dart';

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
  final FirestoreStorageRepository _storageServices = FirestoreStorageRepository();
  final TypeList _typeList = TypeList();
  final IResidenceRepository residenceServices =
      FirestoreResidenceRepository();
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
  // Ce formulaire ne permet de remplacer l'image que par une autre image
  // (ImagePicker.pickImage, jamais de vidéo) : préservé tel quel tant que
  // l'utilisateur ne remplace pas le média, remis à false s'il le fait.
  bool isVideoMedia = false;
  bool anonymPost = false;
  bool showAllFilters = false;
  bool removeImage = false;
  late List<String> labelsType;

  @override
  void initState() {
    super.initState();
    // Récupération des types de déclaration
    List<List<String>> declarationType = _typeList.typeDeclaration();
    labelsType = declarationType.map((e) => e[1]).toSet().toList();

    textEditingController = TextEditingController();

    // Récupération de la résidence depuis la base
    getResidence = residenceServices
        .getResidenceByRef(widget.post.refResidence)
        .then((result) =>
            result.when(success: (v) => v, failure: (error) => throw error));

    getResidence.then((residence) {
      setState(() {
        // Liste des bâtiments (noms des structures)
        locationElements = residence.structures?.values
                .map((structure) => '${structure.type} ${structure.name}')
                .toList() ??
            [];
        appLog(locationElements);

        locationsFloor = residence.structures?.values
                .expand((structure) => structure.etage ?? [])
                .map((e) => e.toString()) // <- cast explicite en String
                .toSet()
                .toList() ??
            [];

        locationDetails = residence.structures?.values
                .expand((structure) => structure.elements ?? [])
                .map((e) => e.toString()) // <- cast explicite en String
                .toSet()
                .toList() ??
            [];

        // Initialisation des valeurs sélectionnées en fonction du post actuel
        type = labelsType.contains(widget.post.type) ? widget.post.type : null;
        localisation = locationElements.contains(widget.post.locationElement)
            ? widget.post.locationElement
            : null;
        etage = locationsFloor.contains(widget.post.locationFloor)
            ? widget.post.locationFloor
            : null;
      });
    });

    title = TextEditingController(text: widget.post.title);
    desc = TextEditingController(text: widget.post.description);
    imagePath = widget.post.pathImage ?? "";
    isVideoMedia = widget.post.isVideo;
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
                      profilTile(widget.post.user, 22, 19, 22, true,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: DropdownButtonFormField<String>(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                      style: TextStyle(fontSize: fontSize),
                                    ),
                                  );
                                })
                                .take(2)
                                .toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: DropdownButtonFormField<String>(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                  style: TextStyle(fontSize: fontSize),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: DropdownButtonFormField<String>(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                  style: TextStyle(fontSize: fontSize),
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
                          selected: widget.post.locationDetails!
                              .contains(itemsElement),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                widget.post.locationDetails!.add(itemsElement);
                              } else {
                                widget.post.locationDetails!
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
                      children: widget.post.locationDetails!
                          .map((String itemsElement) {
                        return FilterChip(
                          label: Text(itemsElement),
                          selected: widget.post.locationDetails!
                              .contains(itemsElement),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                widget.post.locationDetails!.add(itemsElement);
                              } else {
                                widget.post.locationDetails!
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
                        child: isVideoMedia
                            ? NetworkVideoPlayer(url: imagePath)
                            : Image.network(
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
                              color: Colors.black.withValues(alpha: 0.5),
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
              onPressed: () async {
                try {
                  await SubmitPostController.updatePost(
                    like: widget.post.like,
                    uid: widget.uid,
                    idPost: widget.post.id,
                    selectedLabel: type!,
                    imagePath: imagePath,
                    isVideo: isVideoMedia,
                    title: capitalizeFirstLetter(title.text),
                    desc: capitalizeFirstLetter(desc.text),
                    anonymPost: anonymPost,
                    docRes: widget.post.refResidence,
                    localisation: localisation,
                    etage: etage,
                    element: widget.post.locationDetails!,
                    // Ce formulaire ne permet pas d'éditer le statut du
                    // workflow (Stepper dédié, icon_modify_or_delette.dart)
                    // ni la date de déclaration/transmission - sans les
                    // reporter explicitement ici, updatePost() les recevait
                    // à null puis toUpdateMap() les effaçait
                    // (FieldValue.delete()) à chaque simple modification de
                    // titre/description/image.
                    statut: widget.post.statut,
                    timeStamp: widget.post.creationDate,
                    declaredDate: widget.post.declaredDate,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text("Erreur lors de la modification : $e"),
                    ),
                  );
                  return;
                }
                if (!context.mounted) return;
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

      _storageServices
          .uploadImg(returnedImage, "residences", widget.residence,
              widget.post.type, fileName)
          .then((result) => result.when(
              success: (downloadUrl) => updateUrl(downloadUrl),
              failure: (_) => null));
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
      _storageServices
          .uploadImg(returnedImage, "residences", widget.residence,
              widget.post.type, fileName)
          .then((result) => result.when(
              success: (downloadUrl) => updateUrl(downloadUrl),
              failure: (_) => null));
    });
  }

  void updateUrl(String newImagePath) {
    setState(() {
      // oldImagePath = imagePath;
      imagePath = newImagePath;
      isVideoMedia = false;

      _storageServices.removeFileFromUrl(widget.post.pathImage!);
      //oldImagePath = "";
    });
  }
}
