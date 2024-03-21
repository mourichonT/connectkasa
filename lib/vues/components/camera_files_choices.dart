// ignore_for_file: prefer_const_constructors_in_immutables

import 'dart:io';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CameraOrFiles extends StatefulWidget {
  final String racineFolder;
  final String residence;
  final String folderName;
  final String title;
  final Function(String) onImageUploaded;

  CameraOrFiles(
      {super.key,
      required this.racineFolder,
      required this.residence,
      required this.folderName,
      required this.title,
      required this.onImageUploaded});
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

    return Container(
      padding: EdgeInsets.symmetric(vertical: height / 20),
      child: Stack(
        children: [
          _selectedImage != null
              ? Image.file(_selectedImage!)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      ElevatedButton(
                          onPressed: () {
                            _pickImageFromCamera();
                          },
                          child: MyTextStyle.lotName(
                              "Prendre une photo", Colors.black54)),
                      TextButton(
                          onPressed: () {
                            _pickImageFromGallery();
                          },
                          child:
                              MyTextStyle.annonceDesc("Choisir une image", 14)),
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
