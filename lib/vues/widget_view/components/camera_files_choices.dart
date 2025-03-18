import 'dart:io';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CameraOrFiles extends StatefulWidget {
  final String racineFolder;
  final String residence;
  final String folderName;
  final String title;
  final Function(String) onImageUploaded;
  final bool cardOverlay;

  CameraOrFiles({
    super.key,
    required this.racineFolder,
    required this.residence,
    required this.folderName,
    required this.title,
    required this.onImageUploaded,
    required this.cardOverlay,
  });

  @override
  CameraOrFilesState createState() => CameraOrFilesState();
}

class CameraOrFilesState extends State<CameraOrFiles> {
  final ImagePicker _picker = ImagePicker();
  final StorageServices _storageServices = StorageServices();
  String fileName = const Uuid().v4();
  File? _selectedImage;

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
        ],
      ),
    );
  }

  /// Bouton plein écran avec icône pour ajouter une image
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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });

    _storageServices.removeFile(
        widget.racineFolder, widget.residence, widget.folderName,
        idPost: fileName);

    _storageServices
        .uploadFile(pickedFile, widget.racineFolder, widget.residence,
            widget.folderName, fileName)
        .then((downloadUrl) {
      if (downloadUrl != null) {
        widget.onImageUploaded(downloadUrl);
      }
    });
  }

  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
    });

    _storageServices.removeFile(
        widget.racineFolder, widget.residence, widget.folderName,
        idPost: fileName);
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
                _pickImage(ImageSource.camera);
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
}
