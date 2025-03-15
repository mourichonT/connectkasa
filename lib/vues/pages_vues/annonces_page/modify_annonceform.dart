import 'dart:io';
import 'dart:math';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/features/submit_post_controller.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:connect_kasa/models/enum/type_list.dart';
import 'package:connect_kasa/models/pages_models/post.dart';
import 'package:connect_kasa/vues/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ModifyAnnonceForm extends StatefulWidget {
  final Post post;
  final String residence;
  final String uid;

  const ModifyAnnonceForm(
      {super.key,
      required this.post,
      required this.residence,
      required this.uid});

  @override
  State<StatefulWidget> createState() => ModifyAnnonceFormState();
}

class ModifyAnnonceFormState extends State<ModifyAnnonceForm> {
  final StorageServices _storageServices = StorageServices();
  File? _selectedImage;
  final TypeList _CatList = TypeList();

  late TextEditingController textEditingController;
  TextEditingController title = TextEditingController();
  TextEditingController desc = TextEditingController();
  TextEditingController price = TextEditingController();
  String? categorie;
  String? imagePath = "";
  bool anonymPost = false;
  bool showAllFilters = false;
  bool removeImage = false;
  late List<String> labelsCat;

  final ValueNotifier<double> priceNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<double> feesNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    List<String> declarationType = _CatList.categoryAnnonce();
    labelsCat = declarationType.asMap().entries.map((entry) {
      return entry.value;
    }).toList();
    labelsCat = labelsCat.toSet().toList();
    title = TextEditingController(text: widget.post.title);
    desc = TextEditingController(text: widget.post.description);
    price = TextEditingController(text: widget.post.price.toString());
    imagePath = widget.post.pathImage ?? "";
    anonymPost = widget.post.hideUser;
    feesNotifier.value = priceNotifier.value * 0.95;

    price.addListener(() {
      double? newPrice = double.tryParse(price.text);
      if (newPrice != null) {
        priceNotifier.value = newPrice;
        feesNotifier.value = newPrice * 0.95;
      } else {
        priceNotifier.value = 0.0;
        feesNotifier.value = 0.0;
      }
    });

    // Ensure initial values are valid
    if (!labelsCat.contains(widget.post.subtype)) {
      categorie = null;
    } else {
      categorie = widget.post.subtype;
    }
  }

  void updateBool(bool updatedBool) {
    setState(() {
      anonymPost = updatedBool;
    });
  }

  @override
  void dispose() {
    price.dispose();
    priceNotifier.dispose();
    feesNotifier.dispose();
    super.dispose();
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
            "Modification du post '${widget.post.title}'",
            Colors.black87,
            SizeFont.h1.size),
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
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
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
                                    fontSize: SizeFont.h3.size,
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
                                  decoration: const InputDecoration.collapsed(
                                      hintText:
                                          "Saisissez le titre de votre post"),
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
                                  decoration: const InputDecoration.collapsed(
                                      hintText: "Saisissez une description"),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 0),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ValueListenableBuilder<double>(
                            valueListenable: feesNotifier,
                            builder: (context, fees, child) {
                              if (priceNotifier.value == 0) {
                                return const SizedBox
                                    .shrink(); // Returns an empty widget if price is 0
                              }
                              return MyTextStyle.lotDesc(
                                "*Pour ${priceNotifier.value.toStringAsFixed(2)}€, vous recevrez sur votre compte Kasa ${fees.toStringAsFixed(2)}€",
                                SizeFont.para.size,
                                FontStyle.italic,
                                FontWeight.normal,
                              );
                            },
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                  if (imagePath != null &&
                      imagePath!.isNotEmpty &&
                      !removeImage)
                    Stack(
                      children: [
                        SizedBox(
                          width: width,
                          height: 250,
                          child: Image.network(
                            imagePath!,
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
                                imagePath = "";
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
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: _pickImageFromCamera,
                          child: MyTextStyle.lotName("Prendre une photo",
                              Colors.black54, SizeFont.h3.size),
                        ),
                        TextButton(
                          onPressed: _pickImageFromGallery,
                          child: MyTextStyle.annonceDesc(
                              "Choisir une image", SizeFont.h3.size, 3),
                        ),
                      ],
                    ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      SubmitPostController.UpdatePost(
                          subtype: categorie,
                          like: widget.post.like,
                          uid: widget.uid,
                          selectedLabel: widget.post.type,
                          idPost: widget.post.id,
                          imagePath: imagePath!,
                          title: title.text,
                          desc: desc.text,
                          anonymPost: anonymPost,
                          docRes: widget.post.refResidence,
                          price: int.parse(price.text));
                      Navigator.pop(context);
                    },
                    child: MyTextStyle.lotName("Modifier",
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

  Future _pickImageFromGallery() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;
    setState(() {
      removeImage = false;
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
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnedImage == null) return;
    setState(() {
      removeImage = false;
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

  void updateUrl(String newImagePath) {
    setState(() {
      imagePath = newImagePath;
      _storageServices.removeFileFromUrl(widget.post.pathImage!);
    });
  }
}
