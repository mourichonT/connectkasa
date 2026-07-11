import 'dart:io';
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:connect_kasa/core/repositories/firestore_storage_repository.dart';
import 'package:connect_kasa/core/utils/app_logger.dart';

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
  final FirestoreStorageRepository _storageServices = FirestoreStorageRepository();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
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
      appLog("📛 Image invalide ou non décodable : $e");
      return false;
    }
  }

  Future<void> _deleteInvalidFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        appLog("🗑️ Fichier supprimé : ${file.path}");
      }
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      appLog("❌ Erreur suppression fichier : $e");
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
      final downloadUrl = await _storageServices
          .uploadImg(
            XFile(imageFile.path),
            widget.racineFolder,
            widget.residence,
            widget.folderName,
            fileName,
          )
          .then((result) =>
              result.when(success: (v) => v, failure: (_) => null));

      if (mounted && downloadUrl != null) {
        widget.onImageUploaded(downloadUrl);
      }
    } catch (e) {
      appLog("❌ Erreur globale : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du traitement de l\'image: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<Map<String, String>> extractDataFromIdCard(File imageFile) async {
    // Encode l'image en base64 : l'API vision d'OpenAI attend soit une URL
    // publiquement accessible, soit une data URL "data:<mime>;base64,...".
    // On utilise le base64 directement plutôt que l'URL Firebase Storage
    // pour ne pas dépendre de son accessibilité externe (règles de
    // sécurité / App Check).
    final bytes = await imageFile.readAsBytes();
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
    final imageDataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

    try {
      // L'appel à OpenAI (et la clé API) vit côté serveur
      // (functions_python/main.py: extract_id_card_data) : jamais exposé
      // dans le bundle client.
      final result =
          await _functions.httpsCallable('extract_id_card_data').call({
        'title': widget.title,
        'image_data_url': imageDataUrl,
      });

      final rawJson = Map<String, dynamic>.from(result.data as Map);
      return rawJson.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      appLog("❌ Erreur lors de l'extraction : $e");
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
