import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';

class CameraOrFiles extends StatefulWidget {
  final String racineFolder;
  final String residence;
  final String folderName;
  final String title;
  final Function(bool)? onCameraStateChanged;
  final Function(String) onImageUploaded;
  final bool cardOverlay;

  const CameraOrFiles({
    super.key,
    required this.racineFolder,
    required this.residence,
    required this.folderName,
    required this.title,
    required this.onImageUploaded,
    required this.cardOverlay,
    this.onCameraStateChanged,
  });

  @override
  CameraOrFilesState createState() => CameraOrFilesState();
}

class CameraOrFilesState extends State<CameraOrFiles> {
  final ImagePicker _picker = ImagePicker();
  final StorageServices _storageServices = StorageServices();
  String fileName = const Uuid().v4();
  File? _selectedImage;
  bool isCameraOpen = false;

  @override
  void dispose() {
    _selectedImage = null; // Libérer la mémoire
    super.dispose();
  }

  void openCamera() async {
    setState(() {
      isCameraOpen = true;
      widget.onCameraStateChanged?.call(true);
    });

    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      isCameraOpen = false;
      widget.onCameraStateChanged
          ?.call(false); // Inverser ici pour indiquer que la caméra est fermée
    });

    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });

    _storageServices.removeFile(
      widget.racineFolder,
      widget.residence,
      widget.folderName,
      idPost: fileName,
    );

    try {
      final downloadUrl = await _storageServices.uploadImg(
        pickedFile,
        widget.racineFolder,
        widget.residence,
        widget.folderName,
        fileName,
      );
      if (downloadUrl != null) {
        widget.onImageUploaded(downloadUrl);
      }
    } catch (e) {
      print("Erreur lors de l'upload de l'image: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      isCameraOpen = true;
    });
    widget.onCameraStateChanged?.call(
        true); // Indiquer que l'option de sélection de fichier est activée

    final XFile? pickedFile = await _picker.pickImage(source: source);

    setState(() {
      isCameraOpen = false;
    });
    widget.onCameraStateChanged
        ?.call(false); // Indiquer que la sélection est terminée

    if (pickedFile == null) return;

    if (mounted) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }

    _uploadImage(pickedFile);
  }

  void _uploadImage(XFile pickedFile) {
    _storageServices.removeFile(
      widget.racineFolder,
      widget.residence,
      widget.folderName,
      idPost: fileName,
    );

    _storageServices
        .uploadImg(
      pickedFile,
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
  }

  Future<void> _removeImage() async {
    try {
      if (_selectedImage != null) {
        setState(() {
          _selectedImage = null;
        });
        await _storageServices.removeFile(
          widget.racineFolder,
          widget.residence,
          widget.folderName,
          idPost: fileName,
        );
      }
    } catch (e) {
      print("Erreur lors de la suppression de l'image: $e");
    }
  }

  /// Affiche la boîte de dialogue pour choisir l’image
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
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: MyTextStyle.postDesc(
                  'Supprimer l\'image',
                  SizeFont.h3.size,
                  Colors.black87,
                ),
                onTap: () {
                  _removeImage();
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Stack(
        children: [
          _selectedImage != null
              ? SizedBox(
                  width: width,
                  height: width * 0.5,
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : _buildAddImageButton(width),
          if (_selectedImage != null)
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: _removeImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          if (isCameraOpen)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Bouton pour ajouter une image
  Widget _buildAddImageButton(double width) {
    return GestureDetector(
      onTap: () => _showImageSourceActionSheet(context),
      child: Container(
        width: width,
        height: width * 0.5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFFF5F6F9),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_rounded,
              size: 60,
              color: Colors.black54,
            ),
            const SizedBox(height: 10),
            Text(
              "Ajouter une image",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
