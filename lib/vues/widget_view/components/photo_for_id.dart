import 'dart:io';
import 'dart:convert';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:file_picker/file_picker.dart';
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

    final pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    // final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      _processImage(File(pickedFile.files.single.path!));
    }
    setState(() => isCameraOpen = false);
    widget.onCameraStateChanged?.call(false);
  }

  Future<bool> _isValidImage(File file) async {
    try {
      final decoded = await decodeImageFromList(await file.readAsBytes());
      return decoded != null;
    } catch (e) {
      debugPrint("📛 Image invalide ou non décodable : $e");
      return false;
    }
  }

  Future<void> _deleteInvalidFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        debugPrint("🗑️ Fichier supprimé : ${file.path}");
      }
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      debugPrint("❌ Erreur suppression fichier : $e");
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _selectedImage = imageFile;
      _isProcessing = true;
    });

    try {
      // Vérifie si c’est un fichier image supporté
      final isImageValid = await _isValidImage(imageFile);
      if (!isImageValid) {
        await _deleteInvalidFile(imageFile);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Fichier non supporté ou corrompu. Veuillez choisir une image au format png, jpg ou jpeg."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final extractedData = await extractDataFromIdCard(imageFile);
      final cleanedData = cleanExtractedData(extractedData);

      final isValid = cleanedData.isNotEmpty &&
          cleanedData.values.every((v) => v.trim().isNotEmpty);

      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Échec de la reconnaissance des informations. Veuillez réessayer."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      widget.onIdDataExtracted(cleanedData);

      // Ré-upload (si nécessaire)
      final downloadUrl = await _storageServices.uploadImg(
        XFile(imageFile.path),
        widget.racineFolder,
        widget.residence,
        widget.folderName,
        fileName,
      );

      if (mounted && downloadUrl != null) {
        widget.onImageUploaded(downloadUrl);
      }
    } catch (e) {
      print("❌ Erreur globale : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du traitement de l\'image: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<Map<String, String>> extractDataFromIdCard(File imageFile) async {
    if (apiKey?.isEmpty ?? true) {
      throw Exception("Clé API OpenAI non trouvée !");
    }

    // Upload de l'image vers Firebase
    final imageUrl = await _storageServices.uploadImg(
      XFile(imageFile.path),
      widget.racineFolder,
      widget.residence,
      widget.folderName,
      fileName,
    );

    if (imageUrl == null) {
      throw Exception("Échec de l'upload de l'image");
    }

    final prompt = {
      "model": "gpt-4-turbo",
      "messages": [
        {
          "role": "system",
          "content":
              """ Tu es un expert en lecture de  ${widget.title}. Ne pas inventer d'informations. Si un champ est manquant ou mal lisible, indique-le comme vide.
                  Tu dois extraire : Nom, Prénom, Sexe, Nationalité, Lieu de naissance, Date de naissance. 
                  Si plusieurs prénoms ou noms sont reconnus, utilise uniquement ceux les plus proches de leur champ d'origine sur la carte (ne pas mélanger).
                  les noms et les prénom ne seront jamais sur la meme ligne prend cela en considération
                  Si la nationnalité est etrangère traduit la moi en Français (ex: Venezuela => Vénézuelienne)

                  Corrige les erreurs fréquentes d'OCR : 
                  - Séparation de mots collés (ex: 'JohnDoe' → 'John Doe'),
                  - Les Noms et Prénoms ne sont jamais sur la même ligne, ne les regroupent pas ensemble
                  - Correction de lettres confondues (B vs M, P vs F),
                  - Ne jamais fusionner les prénoms avec les noms ou inversement.

                  Retourne seulement un JSON propre avec les champs exacts. """
        },
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text":
                  "Voici un document de  ${widget.title}. Retourne les données sous forme de JSON avec les champs attendus."
            },
            {
              "type": "image_url",
              "image_url": {"url": imageUrl}
            }
          ]
        }
      ],
      "max_tokens": 300
    };

    try {
      final response = await http.post(
        Uri.parse(baseUrl!),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(prompt),
      );

      if (response.statusCode != 200) {
        print("❌ Erreur OpenAI : ${response.body}");
        return {};
      }

      final content =
          jsonDecode(response.body)['choices'][0]['message']['content'];

      // Nettoyage du contenu JSON brut
      final cleanedContent = content
          .replaceAll(RegExp(r'```json|```|\n'), '')
          .replaceAll(RegExp(r'\\n|\\t'), ' ')
          .trim();

      final decodedContent = utf8.decode(cleanedContent.runes.toList());

      // Tentative de parsing
      final Map<String, dynamic> rawJson = jsonDecode(decodedContent);

      return rawJson.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print("❌ Erreur lors de l'extraction : $e");
      return {};
    }
  }

  Map<String, String> cleanExtractedData(Map<String, String> data) {
    final Map<String, String> cleaned = {};

    data.forEach((key, value) {
      String fixed = value.trim();

      // Espaces manquants entre lettres
      fixed = fixed.replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}');

      // Mise en forme des champs
      if (key.toLowerCase() == 'nom') {
        fixed = fixed.toUpperCase();
      } else if (key.toLowerCase().contains('prénom')) {
        fixed = fixed
            .split(' ')
            .map((e) => e.isNotEmpty
                ? e[0].toUpperCase() + e.substring(1).toLowerCase()
                : '')
            .join(' ');
      }

      cleaned[key] = fixed;
    });

    return cleaned;
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
