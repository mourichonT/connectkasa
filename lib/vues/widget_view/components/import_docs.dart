import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:connect_kasa/controllers/features/my_texts_styles.dart';
import 'package:connect_kasa/controllers/services/storage_services.dart';
import 'package:connect_kasa/models/enum/font_setting.dart';

class ImportDocs extends StatefulWidget {
  final String racineFolder;
  final List<String> filename;
  final String folderName;
  final String title;
  final String? reflot;
  final Function(String downloadUrl, String extension) onDocumentUploaded;

  const ImportDocs(
      {super.key,
      required this.racineFolder,
      required this.filename,
      required this.folderName,
      required this.title,
      required this.onDocumentUploaded,
      this.reflot});

  @override
  State<ImportDocs> createState() => _ImportDocsState();
}

class _ImportDocsState extends State<ImportDocs> {
  final StorageServices _storageServices = StorageServices();
  final String fileName = const Uuid().v4();
  File? _selectedFile;
  String? _fileDisplayName;
  String? _fileExtension;

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final displayName = result.files.single.name;
      final extension = result.files.single.extension?.toLowerCase();

      // Vérifie si l'extension est valide
      final List<String> allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
      if (extension == null || !allowedExtensions.contains(extension)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Format de document non autorisé. Formats acceptés : PDF, JPG, JPEG, PNG."),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      setState(() {
        _selectedFile = file;
        _fileDisplayName = displayName;
        _fileExtension = extension;
      });

      _uploadDocument(file);
    }
  }

  Future<void> _uploadDocument(File file) async {
    // Suppression dans tous les répertoires concernés

    for (String userId in widget.filename) {
      await _storageServices.removeFile(
          widget.racineFolder,
          userId, // On passe une liste avec un seul élément ici
          widget.folderName,
          idPost: "$fileName.${_fileExtension!}",
          reflot: widget.reflot);
    }

    try {
      String? finalDownloadUrl;

      for (String userId in widget.filename) {
        final downloadUrl = await _storageServices.uploadDocFile(
          file,
          widget.racineFolder,
          userId, // On passe une liste avec un seul élément
          widget.folderName,
          fileName,
          widget.reflot,
        );

        // On conserve le dernier downloadUrl (c’est le même si même fichier)
        finalDownloadUrl = downloadUrl;
      }

      if (finalDownloadUrl != null && _fileExtension != null) {
        widget.onDocumentUploaded(finalDownloadUrl, _fileExtension!);
      }
    } catch (e) {
      print("Erreur lors de l'upload du document : $e");
    }
  }

  Future<void> _removeDocument() async {
    if (_selectedFile == null) return;

    try {
      for (String userId in widget.filename) {
        await _storageServices.removeFile(
          widget.racineFolder,
          userId, // on passe une liste avec un seul nom
          widget.folderName,
          idPost: "$fileName.${_fileExtension!}",
          reflot: widget.reflot,
        );
      }

      setState(() {
        _selectedFile = null;
        _fileDisplayName = null;
        _fileExtension = null;
      });
    } catch (e) {
      print("Erreur lors de la suppression du fichier : $e");
    }
  }

  Icon _getFileIcon() {
    if (_fileExtension == 'pdf') {
      return const Icon(Icons.picture_as_pdf, size: 50, color: Colors.black54);
    } else if (_fileExtension == 'docx') {
      return const Icon(Icons.description, size: 50, color: Colors.black54);
    } else if (_fileExtension == 'jpg' ||
        _fileExtension == 'jpeg' ||
        _fileExtension == 'png') {
      return const Icon(Icons.description, size: 50, color: Colors.black54);
    } else {
      return const Icon(Icons.file_upload_outlined,
          size: 50, color: Colors.black54);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      width: width,
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickDocument,
            child: Container(
              width: width,
              height: width * 0.5,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color(0xFFF5F6F9),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _getFileIcon(),
                    const SizedBox(height: 10),
                    MyTextStyle.postDesc(
                      _fileDisplayName ??
                          "Ajouter un document PDF ou de type image",
                      SizeFont.h3.size,
                      Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedFile != null)
            TextButton.icon(
              onPressed: _removeDocument,
              icon: const Icon(Icons.delete_forever, color: Colors.black54),
              label: MyTextStyle.postDesc(
                  "Supprimer le document", SizeFont.h3.size, Colors.black54),
            ),
        ],
      ),
    );
  }
}
