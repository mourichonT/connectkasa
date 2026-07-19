import 'dart:math';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/controllers/features/submit_post_controller.dart';
import 'package:konodal/core/providers/storage_repository_provider.dart';
import 'package:konodal/core/repositories/storage_repository.dart';
import 'package:konodal/core/utils/text_formatting.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/enum/type_list.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ModifyAnnonceForm extends ConsumerStatefulWidget {
  final Post post;
  final String residence;
  final String uid;

  const ModifyAnnonceForm(
      {super.key,
      required this.post,
      required this.residence,
      required this.uid});

  @override
  ConsumerState<ModifyAnnonceForm> createState() => ModifyAnnonceFormState();
}

class ModifyAnnonceFormState extends ConsumerState<ModifyAnnonceForm> {
  late final IStorageRepository _storageServices;
  final TypeList _catList = TypeList();

  late TextEditingController textEditingController;
  TextEditingController title = TextEditingController();
  TextEditingController desc = TextEditingController();
  TextEditingController price = TextEditingController();
  String? categorie;
  String? imagePath = "";
  bool anonymPost = false;
  bool showAllFilters = false;
  bool removeImage = false;
  bool _isSubmitting = false;
  late List<String> labelsCat;

  final ValueNotifier<double> priceNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<double> feesNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _storageServices = ref.read(storageRepositoryProvider);
    List<String> declarationType = _catList.categoryAnnonce();
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
                      profilTile(widget.post.user, 30, 26, 30, true,
                          Colors.black87, SizeFont.h2.size),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        DropdownButtonFormField<String>(
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
                              Row(
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
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setState(() => _isSubmitting = true);
                            try {
                              await SubmitPostController.updatePost(
                                  subtype: categorie,
                                  like: widget.post.like,
                                  uid: widget.uid,
                                  selectedLabel: widget.post.type,
                                  idPost: widget.post.id,
                                  imagePath: imagePath!,
                                  title: capitalizeFirstLetter(title.text),
                                  desc: capitalizeFirstLetter(desc.text),
                                  anonymPost: anonymPost,
                                  docRes: widget.post.refResidence,
                                  price: int.parse(price.text));
                            } catch (e) {
                              if (!context.mounted) return;
                              setState(() => _isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(
                                      "Erreur lors de la modification : $e"),
                                ),
                              );
                              return;
                            }
                            if (!context.mounted) return;
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
      String fileName = "${Random().nextInt(10000)}";
      _storageServices
          .uploadImg(returnedImage, "residences", widget.residence,
              "${widget.post.type}/${widget.post.id}", fileName)
          .then((result) => result.when(
              success: (downloadUrl) => updateUrl(downloadUrl),
              failure: (_) => null));
    });
  }

  Future _pickImageFromCamera() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnedImage == null) return;
    setState(() {
      removeImage = false;
      String fileName = "${Random().nextInt(10000)}";
      _storageServices
          .uploadImg(returnedImage, "residences", widget.residence,
              "${widget.post.type}/${widget.post.id}", fileName)
          .then((result) => result.when(
              success: (downloadUrl) => updateUrl(downloadUrl),
              failure: (_) => null));
    });
  }

  void updateUrl(String newImagePath) {
    setState(() {
      imagePath = newImagePath;
      _storageServices.removeFileFromUrl(widget.post.pathImage!);
    });
  }
}
