import 'dart:io';
import 'dart:convert';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:connect_kasa/controllers/services/storage_services.dart';

class PhotoForId extends StatefulWidget {
  final String racineFolder;
  final String residence;
  final String folderName;
  final String title;
  final Function(String) onImageUploaded;
  final Function(Map<String, String>) onIdDataExtracted;
  final Function(bool)? onCameraStateChanged;
  final bool cardOverlay;

  const PhotoForId({
    super.key,
    required this.racineFolder,
    required this.residence,
    required this.folderName,
    required this.title,
    required this.onImageUploaded,
    required this.onIdDataExtracted,
    this.onCameraStateChanged,
    required this.cardOverlay,
  });

  @override
  PhotoForIdState createState() => PhotoForIdState();
}

class PhotoForIdState extends State<PhotoForId> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  final StorageServices _storageServices = StorageServices();
  final apiKey = dotenv.env['API_KEY'];
  final baseUrl = dotenv.env['BASE_URL'];
  String fileName = const Uuid().v4();
  File? _selectedImage;
  bool isCameraOpen = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _selectedImage = null;
    super.dispose();
  }

  void openCamera() async {
    setState(() => isCameraOpen = true);
    widget.onCameraStateChanged?.call(true);
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _processImage(File(pickedFile.path));
    }
    setState(() => isCameraOpen = false);
    widget.onCameraStateChanged?.call(false);
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => isCameraOpen = true);
    widget.onCameraStateChanged?.call(true);
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      _processImage(File(pickedFile.path));
    }
    setState(() => isCameraOpen = false);
    widget.onCameraStateChanged?.call(false);
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _selectedImage = imageFile;
      _isProcessing = true;
    });

    try {
      // Extraction des informations de la carte d'identité
      final extractedData = await extractDataFromIdCard(imageFile);

      // Vérification des données extraites
      if (extractedData.isEmpty ||
          extractedData.values.any((value) => value.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Échec de la reconnaissance des informations. Veuillez réessayer."),
            backgroundColor: Colors.red,
          ),
        );
        return; // Arrêter l'exécution si les données ne sont pas valides
      }

      widget.onIdDataExtracted(extractedData);

      // Upload de l'image
      _storageServices
          .uploadFile(
        XFile(imageFile.path),
        widget.racineFolder,
        widget.residence,
        widget.folderName,
        fileName,
      )
          .then((downloadUrl) {
        if (mounted && downloadUrl != null) {
          widget.onImageUploaded(downloadUrl);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du traitement de l\'image: $e')),
      );
      print('Erreur lors du traitement de l\'image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<Map<String, String>> extractDataFromIdCard(File imageFile) async {
    if (apiKey!.isEmpty) {
      throw Exception("Clé API OpenAI non trouvée !");
    }

    // 1️⃣ - Upload de l'image sur Firebase Storage
    String? imageUrl = await _storageServices.uploadFile(
      XFile(imageFile.path),
      widget.racineFolder,
      widget.residence,
      widget.folderName,
      fileName,
    );

    if (imageUrl == null) {
      throw Exception("Échec de l'upload de l'image");
    }

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "model": "gpt-4-turbo",
      "messages": [
        {
          "role": "system",
          "content":
              "Tu es un assistant qui extrait des informations ${widget.title}. Retourne uniquement les données en JSON."
        },
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text":
                  "Analyse cette image et renvoie uniquement les informations sous forme de JSON avec Nom, Prénom, Sexe, Nationalite, Lieu de naissance et Date de naissance."
            },
            {
              "type": "image_url",
              "image_url": {
                "url": imageUrl
              } // ✅ On utilise l'URL au lieu de base64
            }
          ]
        }
      ],
      "max_tokens": 300
    });

    try {
      final response =
          await http.post(Uri.parse(baseUrl!), headers: headers, body: body);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // 🔹 Vérifions ce que contient exactement "content"
        print(
            "🔹 Contenu OpenAI : ${jsonResponse['choices'][0]['message']['content']}");

        // Nettoyage du contenu pour gérer les caractères mal encodés et enlever les backticks
        final content = jsonResponse['choices'][0]['message']['content'];

        // Retirer les backticks et autres caractères indésirables
        String cleanedContent =
            content.replaceAll(RegExp(r'```json|```|\n'), '');

        // Décodage manuel des caractères mal encodés
        String decodedContent = utf8.decode(cleanedContent.runes.toList());

        // Essayer de décoder le JSON après nettoyage
        try {
          // Conversion forcée en Map<String, String>
          Map<String, dynamic> parsedJson = jsonDecode(decodedContent);

          // Conversion en Map<String, String>
          Map<String, String> finalResult = {};
          parsedJson.forEach((key, value) {
            finalResult[key] = value.toString();
          });

          return finalResult; // ✅ Retourne un Map<String, String>
        } catch (e) {
          print("❌ Erreur lors du parsing JSON : $e");
          return {}; // Retourne un map vide en cas d'erreur
        }
      } else {
        print("❌ Erreur OpenAI : ${response.body}");
        return {};
      }
    } catch (e) {
      print("❌ Erreur lors de la requête : $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => _showImageSourceActionSheet(context),
      child: Container(
        width: width,
        height: width * 0.5,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: _isProcessing
            ? const Center(child: CircularProgressIndicator())
            : _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: MyTextStyle.postDesc(
                'Prendre une photo',
                SizeFont.h3.size,
                Colors.black87,
              ),
              onTap: () {
                Navigator.of(context).pop();
                openCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: MyTextStyle.postDesc(
                'Choisir depuis la galerie',
                SizeFont.h3.size,
                Colors.black87,
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
