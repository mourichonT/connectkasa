// ignore_for_file: prefer_const_constructors_in_immutables

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

  CameraOrFiles(
      {super.key,
      required this.racineFolder,
      required this.residence,
      required this.folderName,
      required this.title,
      required this.onImageUploaded,
      required this.cardOverlay});
  @override
  CameraOrFilesState createState() => CameraOrFilesState();
}

class CameraOrFilesState extends State<CameraOrFiles> {
  String fileName = const Uuid().v4();
  File? _selectedImage;
  final StorageServices _storageServices = StorageServices();
  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Stack(
        children: [
          _selectedImage != null
              ? SizedBox(
                  width: width / 2.2,
                  height: width / 2.2,
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
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
          if (_selectedImage != null)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImage = null;
                    _storageServices.removeFile(
                      widget.racineFolder,
                      widget.residence,
                      widget.folderName,
                      idPost: fileName,
                    );
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
      ),
    );
  }

  Future _pickImageFromGallery() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    // Votre code pour traiter l'image sélectionnée
    if (returnedImage == null) return;
    setState(() {
      _selectedImage = File(returnedImage.path);
      _storageServices
          .uploadFile(returnedImage, widget.racineFolder, widget.residence,
              widget.folderName, fileName)
          .then((downloadUrl) {
        if (downloadUrl != null) {
          widget.onImageUploaded(downloadUrl);
        }
      });
    });
  }

  Future _pickImageFromCamera() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    // Votre code pour traiter l'image sélectionnée
    if (returnedImage == null) return;
    setState(() {
      _selectedImage = File(returnedImage.path);
      _storageServices
          .uploadFile(returnedImage, widget.racineFolder, widget.residence,
              widget.folderName, fileName)
          .then((downloadUrl) {
        if (downloadUrl != null) {
          widget.onImageUploaded(downloadUrl);
        }
      });
    });
  }
}
