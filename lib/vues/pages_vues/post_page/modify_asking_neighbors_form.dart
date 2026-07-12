import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:konodal/core/providers/storage_repository_provider.dart';
import 'package:konodal/core/utils/text_formatting.dart';
import 'package:konodal/core/repositories/storage_repository.dart';
import 'package:konodal/models/enum/font_setting.dart';
import 'package:konodal/models/pages_models/post.dart';
import 'package:konodal/models/pages_models/post_style.dart';
import 'package:konodal/vues/widget_view/components/profil_tile.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:konodal/controllers/features/submit_post_controller.dart';
import 'package:konodal/vues/widget_view/components/button_add.dart';
import 'package:konodal/controllers/features/my_texts_styles.dart';
import 'package:konodal/core/utils/app_logger.dart';

class ModifyAskingNeighborsForm extends ConsumerStatefulWidget {
  final Post post;
  final String residence;
  final String uid;

  const ModifyAskingNeighborsForm(
      {super.key,
      required this.post,
      required this.residence,
      required this.uid});

  @override
  ConsumerState<ModifyAskingNeighborsForm> createState() =>
      ModifyAskingNeighborsFormState();
}

class ModifyAskingNeighborsFormState
    extends ConsumerState<ModifyAskingNeighborsForm> {
  late final IStorageRepository _storageRepository;
  TextEditingController desc = TextEditingController();
  final ButtonStyle style =
      ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
  final List<Color> _colors = [
    Colors.white,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple
  ];

  String getColorName(Color color) {
    if (color == Colors.blue) {
      return 'Colors.blue';
    } else if (color == Colors.red) {
      return 'Colors.red';
    } else if (color == Colors.green) {
      return 'Colors.green';
    } else if (color == Colors.yellow) {
      return 'Colors.yellow';
    } else if (color == Colors.purple) {
      return 'Colors.purple';
    }
    // Ajoutez d'autres couleurs au besoin
    return 'Unknown color';
  }

  Color? getColorFromString(String? colorString) {
    switch (colorString) {
      case 'Colors.blue':
        return Colors.blue;
      case 'Colors.red':
        return Colors.red;
      case 'Colors.green':
        return Colors.green;
      case 'Colors.yellow':
        return Colors.yellow;
      case 'Colors.purple':
        return Colors.purple;
      // Ajoutez d'autres couleurs au besoin
      default:
        return null; // Retourne null si la couleur n'est pas trouvée
    }
  }

  Color getFontColorFromString(String colorString) {
    // Retire la partie "Color(" et la parenthèse de fermeture ")"
    String valueString = colorString.split('(0x')[1].split(')')[0];
    // Convertit la valeur hexadécimale en int
    int value = int.parse(valueString, radix: 16);
    // Retourne un objet de type Color
    return Color(value);
  }

  final List<String> _imagePaths = [
    "images/fond_posts/fondbulle.png",
    "images/fond_posts/fonddegrade.png",
    "images/fond_posts/fondenfant.png",
    "images/fond_posts/fondlover.png",
  ];

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

  Color? _selectedColor;
  String? _selectedImagePath;
  String _selectedText = '';
  double _selectedFontSize = 20.0;
  FontWeight _selectedFontWeight = FontWeight.normal;
  FontStyle _selectedFontStyle = FontStyle.normal;
  Color _selectedFontColor = Colors.black87;
  bool _fontSize = false;
  bool _fontItalic = false;
  bool _fontBold = false;
  String imagePath = "";
  bool anonymPost = false;
  final GlobalKey _globalKey = GlobalKey();
  // String _backgroundColor = "";
  // String _backgroundImage = "";

  @override
  void initState() {
    super.initState();
    _storageRepository = ref.read(storageRepositoryProvider);
    _selectedColor = _selectedColor =
        getColorFromString(widget.post.style?.backgroundColor ?? "");
    _selectedImagePath = widget.post.style?.backgroundImage ?? "";
    desc = TextEditingController(text: widget.post.description);
    _selectedText = widget.post.description;
    anonymPost = widget.post.hideUser;
    _selectedFontSize =
        widget.post.style?.fontSize ?? 20.0; // 20.0 est une valeur par défaut
    _selectedFontColor = getFontColorFromString(
        widget.post.style?.fontColor ?? ""); // Couleur de texte par défaut
    _selectedFontWeight =
        getFontWeightFromString(widget.post.style?.fontWeight);
    _selectedFontStyle = getFontStyleFromString(widget.post.style?.fontStyle);

    if (widget.post.style?.fontSize != null) {
      _fontSize = true;
    }
    if (widget.post.style?.fontStyle != "") {
      _fontItalic = true;
    }
    if (widget.post.style?.fontWeight != "") {
      _fontBold = true;
    }
  }

  FontWeight getFontWeightFromString(String? fontWeightString) {
    switch (fontWeightString) {
      case 'FontWeight.bold':
        return FontWeight.bold;
      case 'FontWeight.normal':
        return FontWeight.normal;
      // Ajoutez d'autres cas si nécessaire
      default:
        return FontWeight.normal; // Valeur par défaut
    }
  }

  FontStyle getFontStyleFromString(String? fontStyleString) {
    switch (fontStyleString) {
      case 'FontStyle.italic':
        return FontStyle.italic;
      case 'FontStyle.normal':
        return FontStyle.normal;
      // Ajoutez d'autres cas si nécessaire
      default:
        return FontStyle.normal; // Valeur par défaut
    }
  }

  @override
  void dispose() {
    desc.dispose();
    super.dispose();
  }

  Future<Uint8List> _capturePng() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      RenderRepaintBoundary? boundary = _globalKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("Boundary is null");
      }

      // Récupérez l'instance ui.Image à partir de RenderRepaintBoundary
      ui.Image image = await boundary.toImage(
          pixelRatio: 1.0); // Ajustez le pixelRatio selon vos besoins

      // Convertissez ui.Image en ByteData au format png
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } catch (e) {
      appLog(e);
      rethrow;
    }
  }

  Future<File> _saveImage(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, '${DateTime.now()}.png');
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                profilTile(widget.post.user, 22, 19, 22, true, Colors.black87,
                    SizeFont.h2.size),
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
            const Divider(),
            Visibility(
              visible: _selectedColor != null &&
                      _selectedColor != Colors.white ||
                  _selectedImagePath != null && _selectedImagePath!.isNotEmpty,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.format_size_rounded,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          _fontSize = !_fontSize;
                        });
                      },
                    ),
                    Visibility(
                      visible: _fontSize,
                      child: SizedBox(
                        width: width / 2.5,
                        child: Slider(
                          value: _selectedFontSize,
                          min: 10,
                          max: 50,
                          onChanged: (value) {
                            setState(() {
                              _selectedFontSize = value;
                            });
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.format_color_text_rounded,
                        color: _selectedFontColor,
                        size: 30,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              actions: [
                                ButtonAdd(
                                    function: () => Navigator.pop(context),
                                    color: Theme.of(context).primaryColor,
                                    text: "Ok",
                                    horizontal: 20,
                                    vertical: 10,
                                    size: 16)
                              ],
                              title: MyTextStyle.lotName(
                                  'Choisir une couleur de texte',
                                  Colors.black87,
                                  SizeFont.h2.size),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  labelTypes: const [],
                                  pickerColor: _selectedFontColor,
                                  onColorChanged: (color) {
                                    setState(() {
                                      _selectedFontColor = color;
                                      appLog("color : $_selectedFontColor");
                                    });
                                  },
                                  pickerAreaHeightPercent: 0.8,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: _fontBold
                          ? const Icon(
                              Icons.format_bold_rounded,
                              size: 30,
                              color: Colors.black38,
                            )
                          : const Icon(
                              Icons.format_bold_rounded,
                              size: 30,
                            ),
                      onPressed: () {
                        setState(() {
                          _fontBold = !_fontBold;
                          _selectedFontWeight =
                              _fontBold ? FontWeight.bold : FontWeight.normal;
                        });
                      },
                    ),
                    IconButton(
                      icon: _fontItalic
                          ? const Icon(
                              Icons.format_clear_rounded,
                              size: 30,
                              color: Colors.black38,
                            )
                          : const Icon(
                              Icons.format_italic_rounded,
                              size: 30,
                            ),
                      onPressed: () {
                        setState(() {
                          _fontItalic = !_fontItalic;
                          _selectedFontStyle =
                              _fontItalic ? FontStyle.italic : FontStyle.normal;
                        });
                      },
                    ),
                  ],
                ),
            ),
            RepaintBoundary(
              key: _globalKey,
              child: Container(
                height: width,
                width: width,
                decoration: BoxDecoration(
                  color:
                      _selectedImagePath == null || _selectedImagePath!.isEmpty
                          ? _selectedColor
                          : null,
                  image: _selectedImagePath != null &&
                          _selectedImagePath!.isNotEmpty
                      ? DecorationImage(
                          image: AssetImage(_selectedImagePath!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  alignment: _selectedColor != null &&
                              _selectedColor != Colors.white ||
                          _selectedImagePath != null &&
                              _selectedImagePath!.isNotEmpty
                      ? Alignment.center
                      : Alignment.topLeft,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 20),
                      child: TextField(
                        controller: desc,
                        onChanged: (value) {
                          setState(() {
                            _selectedText = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Quoi de neuf?',
                          border: InputBorder.none,
                        ),
                        textAlign: _selectedColor != null &&
                                    _selectedColor != Colors.white ||
                                _selectedImagePath != null &&
                                    _selectedImagePath!.isNotEmpty
                            ? TextAlign.center
                            : TextAlign.start,
                        style: TextStyle(
                          color: _selectedFontColor,
                          fontSize: _selectedFontSize,
                          fontWeight: _selectedFontWeight,
                          fontStyle: _selectedFontStyle,
                        ),
                        maxLines: 6,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 15,
              children: [
                ..._colors.map((color) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                          _selectedImagePath = null;
                        });
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: _selectedColor == color &&
                                _selectedImagePath == null
                            ? Icon(Icons.check,
                                color: color == Colors.white
                                    ? Colors.black87
                                    : Colors.white)
                            : null,
                      ),
                    ),
                  );
                }),
                ..._imagePaths.map((path) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImagePath = path;
                          _selectedColor = null;
                        });
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                          image: DecorationImage(
                            image: AssetImage(path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: _selectedImagePath == path
                            ? const Icon(Icons.check, color: Colors.black87)
                            : null,
                      ),
                    ),
                  );
                }),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: ElevatedButton(
                style: style,
                onPressed: () async {
                  String? imageUrl = "";

                  if (_selectedText.isEmpty) {
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

                  try {
                    if (_selectedColor != null &&
                            _selectedColor != Colors.white ||
                        _selectedImagePath != null) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Uint8List pngBytes = await _capturePng();
                      File file = await _saveImage(pngBytes);

                      imageUrl = await _storageRepository
                          .uploadImg(
                            XFile(file.path),
                            "residences",
                            widget.residence,
                            widget.post.type,
                            widget.post.id,
                          )
                          .then((result) => result.when(
                              success: (v) => v,
                              failure: (error) => throw error));
                    }

                    await SubmitPostController.updatePost(
                        uid: widget.uid,
                        like: widget.post.like,
                        idPost: widget.post.id,
                        selectedLabel: widget.post.type,
                        imagePath: imageUrl,
                        desc: capitalizeFirstLetter(desc.text),
                        anonymPost: anonymPost,
                        docRes: widget.residence,
                        style: PostStyle(
                          backgroundColor: _selectedColor.toString(),
                          backgroundImage: _selectedImagePath,
                          fontColor: _selectedFontColor.toString(),
                          fontStyle: _selectedFontStyle.toString(),
                          fontSize: _selectedFontSize,
                          fontWeight: _selectedFontWeight.toString(),
                        ));
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    appLog("Erreur lors de la mise à jour du post: $e");
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text("Erreur lors de la modification : $e"),
                      ),
                    );
                  }
                },
                child: MyTextStyle.lotName("Mettre à jour",
                    Theme.of(context).primaryColor, SizeFont.h2.size),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
